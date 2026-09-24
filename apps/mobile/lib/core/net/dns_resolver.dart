import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:sentry_flutter/sentry_flutter.dart' show SentryLevel;

import '../log/telemetry.dart';
import 'dns_message.dart';

/// Resolves hostnames to addresses; implementations may bypass the OS/operator DNS entirely.
abstract class DnsResolver {
  Future<List<InternetAddress>> lookup(String host);
}

/// Delegates to the platform resolver (whatever the device/operator normally uses).
class SystemResolver implements DnsResolver {
  const SystemResolver();

  @override
  Future<List<InternetAddress>> lookup(String host) => InternetAddress.lookup(host);

  @override
  String toString() => 'system';
}

/// Plain UDP DNS (port 53) against one or more resolver IPs, IPv4 first then IPv6, first reply wins.
class UdpResolver implements DnsResolver {
  UdpResolver(this.servers, {this.timeout = const Duration(seconds: 3)});

  final List<InternetAddress> servers;
  final Duration timeout;

  @override
  Future<List<InternetAddress>> lookup(String host) async {
    for (final server in servers) {
      try {
        final results = await Future.wait([
          _query(server, host, type: 1),
          _query(server, host, type: 28),
        ]).timeout(timeout);
        final all = [...results[0], ...results[1]];
        if (all.isNotEmpty) return all;
        Telemetry.breadcrumb('dns', 'udp ${server.address}: no answer for $host', level: SentryLevel.warning);
      } catch (e) {
        // Try the next configured server.
        Telemetry.breadcrumb('dns', 'udp ${server.address} failed for $host: $e', level: SentryLevel.warning);
      }
    }
    return const [];
  }

  @override
  String toString() => 'udp(${servers.map((s) => s.address).join(',')})';

  Future<List<InternetAddress>> _query(InternetAddress server, String host, {required int type}) async {
    final socket = await RawDatagramSocket.bind(InternetAddress.anyIPv4, 0);
    try {
      final query = DnsMessage.encodeQuery(host, type: type);
      socket.send(query, server, 53);
      final completer = Completer<List<InternetAddress>>();
      late final StreamSubscription sub;
      sub = socket.listen((event) {
        if (event != RawSocketEvent.read) return;
        final datagram = socket.receive();
        if (datagram == null) return;
        try {
          completer.complete(DnsMessage.decodeResponse(datagram.data).answers);
        } catch (e) {
          completer.completeError(e);
        } finally {
          sub.cancel();
        }
      });
      return await completer.future.timeout(timeout);
    } finally {
      socket.close();
    }
  }
}

/// DNS-over-HTTPS (RFC 8484 wire format), used against a bootstrap-by-IP `doh_url` so there is no
/// DNS chicken-and-egg problem (the well-known providers issue certificates with an IP SAN).
class DohResolver implements DnsResolver {
  DohResolver(this.url, {this.timeout = const Duration(seconds: 3)});

  final String url;
  final Duration timeout;

  @override
  Future<List<InternetAddress>> lookup(String host) async {
    final results = await Future.wait([_query(host, type: 1), _query(host, type: 28)]);
    return [...results[0], ...results[1]];
  }

  Future<List<InternetAddress>> _query(String host, {required int type}) async {
    final client = HttpClient();
    try {
      final query = DnsMessage.encodeQuery(host, type: type);
      final param = base64Url.encode(query).replaceAll('=', '');
      final uri = Uri.parse('$url?dns=$param');
      final request = await client.getUrl(uri).timeout(timeout);
      request.headers.set('accept', 'application/dns-message');
      final response = await request.close().timeout(timeout);
      if (response.statusCode != 200) {
        Telemetry.breadcrumb('dns', 'doh $url: HTTP ${response.statusCode} for $host (type $type)', level: SentryLevel.warning);
        return const [];
      }
      final bytes = await response.fold<List<int>>([], (acc, chunk) => acc..addAll(chunk));
      return DnsMessage.decodeResponse(Uint8List.fromList(bytes)).answers;
    } catch (e) {
      Telemetry.breadcrumb('dns', 'doh $url failed for $host (type $type): $e', level: SentryLevel.warning);
      return const [];
    } finally {
      client.close(force: true);
    }
  }

  @override
  String toString() => 'doh($url)';
}

/// Wraps a resolver with a short-lived in-memory cache (per-app-run; ISP DNS blocks change rarely).
class CachingResolver implements DnsResolver {
  CachingResolver(this._inner, {this.ttl = const Duration(minutes: 5)});

  final DnsResolver _inner;
  final Duration ttl;
  final _cache = <String, (DateTime, List<InternetAddress>)>{};

  @override
  Future<List<InternetAddress>> lookup(String host) async {
    final cached = _cache[host];
    if (cached != null && DateTime.now().isBefore(cached.$1)) return cached.$2;
    final sw = Stopwatch()..start();
    final result = await _inner.lookup(host);
    Telemetry.breadcrumb(
      'dns',
      result.isEmpty ? '$host: resolution failed via $_inner' : '$host resolved via $_inner',
      data: {'ms': sw.elapsedMilliseconds, 'addresses': result.take(3).map((a) => a.address).toList()},
      level: result.isEmpty ? SentryLevel.error : SentryLevel.info,
    );
    if (result.isNotEmpty) _cache[host] = (DateTime.now().add(ttl), result);
    return result;
  }

  @override
  String toString() => '$_inner';
}

/// Tries resolvers in order and returns the first non-empty result.
class ChainResolver implements DnsResolver {
  ChainResolver(this.resolvers);
  final List<DnsResolver> resolvers;

  @override
  Future<List<InternetAddress>> lookup(String host) async {
    for (final r in resolvers) {
      try {
        final result = await r.lookup(host);
        if (result.isNotEmpty) return result;
      } catch (e) {
        // Try the next resolver.
        Telemetry.breadcrumb('dns', '$r failed for $host: $e', level: SentryLevel.warning);
      }
    }
    return const [];
  }

  @override
  String toString() => resolvers.join(' → ');
}
