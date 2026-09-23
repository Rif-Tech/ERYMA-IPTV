import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

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
      } catch (_) {
        // Try the next configured server.
      }
    }
    return const [];
  }

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
      if (response.statusCode != 200) return const [];
      final bytes = await response.fold<List<int>>([], (acc, chunk) => acc..addAll(chunk));
      return DnsMessage.decodeResponse(Uint8List.fromList(bytes)).answers;
    } catch (_) {
      return const [];
    } finally {
      client.close(force: true);
    }
  }
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
    final result = await _inner.lookup(host);
    if (result.isNotEmpty) _cache[host] = (DateTime.now().add(ttl), result);
    return result;
  }
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
      } catch (_) {
        // Try the next resolver.
      }
    }
    return const [];
  }
}
