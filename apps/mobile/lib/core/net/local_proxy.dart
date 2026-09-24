import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:sentry_flutter/sentry_flutter.dart' show SentryLevel;

import '../log/telemetry.dart';
import 'dns_resolver.dart';

/// Tiny loopback HTTP(S) forward proxy: mpv/ffmpeg resolve hostnames with `getaddrinfo` (the OS/
/// operator DNS) and cannot be handed a custom [DnsResolver] directly. Pointing the player's
/// `http-proxy` at this server lets every request (including HLS sub-playlists/segments and
/// redirects) go through the resolver picked in Réglages → Réseau / DNS instead.
///
/// Supports `CONNECT` tunnelling for HTTPS and absolute-form requests for plain HTTP, per RFC 7230.
class LocalDnsProxy {
  LocalDnsProxy(this.resolver);
  final DnsResolver resolver;
  ServerSocket? _server;

  int? get port => _server?.port;

  /// Across every proxy instance of this run, reported with each playback: zero requests while a
  /// custom DNS is active means mpv never went through the proxy at all.
  static int requests = 0;
  static int failures = 0;
  static String? lastError;
  static final _seenHosts = <String>{};

  Future<int> start() async {
    final server = await ServerSocket.bind(InternetAddress.loopbackIPv4, 0);
    _server = server;
    server.listen((client) {
      unawaited(_handle(client).catchError((_) => client.destroy()));
    });
    return server.port;
  }

  Future<void> stop() async {
    await _server?.close();
    _server = null;
  }

  Future<InternetAddress> _resolve(String host) async {
    final literal = InternetAddress.tryParse(host);
    if (literal != null) return literal;
    final addresses = await resolver.lookup(host);
    if (addresses.isEmpty) throw SocketException('DNS resolution failed for $host');
    return addresses.first;
  }

  Future<void> _handle(Socket client) async {
    // mpv resets connections it no longer needs (seek, zap, close): the resulting write error
    // surfaces on `done`, and unhandled it reached Sentry as fatal (FLUTTER-J/K).
    client.done.then((_) {}, onError: (Object _) {});
    final buffer = BytesBuilder();
    late final StreamSubscription<Uint8List> sub;
    final headerReceived = Completer<void>();
    var headerEnd = -1;

    sub = client.listen(
      (chunk) {
        if (headerEnd != -1) return; // handed off to the pipe below
        buffer.add(chunk);
        final bytes = buffer.toBytes();
        final idx = _indexAfterHeader(bytes);
        if (idx != -1) {
          headerEnd = idx;
          if (!headerReceived.isCompleted) headerReceived.complete();
        }
      },
      onDone: () {
        if (!headerReceived.isCompleted) headerReceived.completeError(const SocketException('closed before header'));
      },
      onError: (Object e) {
        if (!headerReceived.isCompleted) headerReceived.completeError(e);
      },
    );

    try {
      await headerReceived.future.timeout(const Duration(seconds: 10));
    } catch (_) {
      await sub.cancel();
      client.destroy();
      return;
    }
    sub.pause();

    final all = buffer.toBytes();
    final headerText = ascii.decode(all.sublist(0, headerEnd), allowInvalid: true);
    final lines = headerText.split('\r\n')..removeWhere((l) => l.isEmpty);
    final requestLine = lines.isNotEmpty ? lines.first : '';
    final parts = requestLine.split(' ');
    final leftover = all.sublist(headerEnd);

    if (parts.length < 2) {
      client.destroy();
      return;
    }
    final method = parts[0];

    requests++;
    String? targetHost;
    Socket upstream;
    try {
      if (method == 'CONNECT') {
        final hostPort = parts[1].split(':');
        final host = hostPort[0];
        targetHost = host;
        final port = hostPort.length > 1 ? int.tryParse(hostPort[1]) ?? 443 : 443;
        final address = await _resolve(host);
        upstream = await Socket.connect(address, port);
        upstream.done.then((_) {}, onError: (Object _) {});
        client.add(ascii.encode('HTTP/1.1 200 Connection Established\r\n\r\n'));
      } else {
        final url = Uri.parse(parts[1]);
        targetHost = url.host;
        final address = await _resolve(url.host);
        upstream = await Socket.connect(address, url.hasPort ? url.port : 80);
        upstream.done.then((_) {}, onError: (Object _) {});
        final path = url.path.isEmpty ? '/' : url.path;
        final query = url.hasQuery ? '?${url.query}' : '';
        final version = parts.length > 2 ? parts[2] : 'HTTP/1.1';
        final rewritten = StringBuffer('$method $path$query $version\r\n');
        for (final line in lines.skip(1)) {
          if (line.isEmpty) continue;
          if (line.toLowerCase().startsWith('proxy-connection')) continue;
          rewritten.write('$line\r\n');
        }
        rewritten.write('\r\n');
        upstream.add(ascii.encode(rewritten.toString()));
      }
      if (_seenHosts.add(targetHost)) {
        Telemetry.breadcrumb('dns', 'proxy: first $method to $targetHost via $resolver', data: {'port': port});
      }
    } catch (e) {
      failures++;
      lastError = '$method $targetHost: $e';
      Telemetry.breadcrumb('dns', 'proxy: $method $targetHost failed: $e', level: SentryLevel.error);
      unawaited(Telemetry.capture(
        'dns',
        'DNS proxy could not reach $targetHost',
        level: SentryLevel.error,
        data: {'method': method, 'host': targetHost, 'resolver': '$resolver', 'error': '$e', 'port': port, 'requests': requests, 'failures': failures},
        fingerprint: ['dns-proxy-failure', '$targetHost', '${e.runtimeType}'],
      ));
      await sub.cancel();
      client.destroy();
      return;
    }

    if (leftover.isNotEmpty) upstream.add(leftover);

    final done = Completer<void>();
    sub
      ..onData(upstream.add)
      ..onDone(() => upstream.destroy())
      ..onError((Object _) => upstream.destroy())
      ..resume();
    upstream.listen(
      client.add,
      onDone: () {
        client.destroy();
        if (!done.isCompleted) done.complete();
      },
      onError: (Object _) {
        client.destroy();
        if (!done.isCompleted) done.complete();
      },
    );
    await done.future;
    await sub.cancel();
  }

  /// Index right after the terminating `\r\n\r\n`, or -1 if the header is not fully buffered yet.
  static int _indexAfterHeader(Uint8List bytes) {
    for (var i = 0; i + 3 < bytes.length; i++) {
      if (bytes[i] == 13 && bytes[i + 1] == 10 && bytes[i + 2] == 13 && bytes[i + 3] == 10) return i + 4;
    }
    return -1;
  }
}
