import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:multiptv/core/net/dns_resolver.dart';

class _Failing implements DnsResolver {
  int calls = 0;
  @override
  Future<List<InternetAddress>> lookup(String host) async {
    calls++;
    return const [];
  }
}

void main() {
  test('an IP host is returned as is, without asking any DNS server', () async {
    final inner = _Failing();
    final result = await CachingResolver(inner).lookup('84.17.42.75');
    expect(result.single.address, '84.17.42.75');
    expect(inner.calls, 0);
  });

  test('an IPv6 resolver neither throws nor leaks an unhandled socket error', () async {
    // Nothing listens there: the lookup must just come back empty (it used to raise errno 97
    // from an IPv4-bound socket, reported to Sentry as a fatal unhandled error).
    final resolver = UdpResolver([InternetAddress('::1'), InternetAddress('127.0.0.1')], timeout: const Duration(milliseconds: 300));
    expect(await resolver.lookup('example.invalid'), isEmpty);
  });
}
