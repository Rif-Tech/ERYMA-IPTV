import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:multiptv/core/net/dns_resolver.dart';
import 'package:multiptv/core/net/local_proxy.dart';

void main() {
  test('LocalDnsProxy forwards a plain HTTP absolute-form request', () async {
    final origin = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    origin.listen((req) {
      req.response.write('hello from origin');
      req.response.close();
    });
    addTearDown(origin.close);

    final proxy = LocalDnsProxy(const SystemResolver());
    final port = await proxy.start();
    addTearDown(proxy.stop);

    final client = HttpClient();
    client.findProxy = (_) => 'PROXY 127.0.0.1:$port';
    final request = await client.getUrl(Uri.parse('http://127.0.0.1:${origin.port}/'));
    final response = await request.close();
    final body = await response.transform(const SystemEncoding().decoder).join();

    expect(response.statusCode, 200);
    expect(body, 'hello from origin');
    client.close(force: true);
  });

  test('LocalDnsProxy tunnels HTTPS via CONNECT', () async {
    final context = SecurityContext()
      ..useCertificateChainBytes(_testCertPem)
      ..usePrivateKeyBytes(_testKeyPem);
    final origin = await HttpServer.bindSecure(InternetAddress.loopbackIPv4, 0, context);
    origin.listen((req) {
      req.response.write('secure hello');
      req.response.close();
    });
    addTearDown(origin.close);

    final proxy = LocalDnsProxy(const SystemResolver());
    final port = await proxy.start();
    addTearDown(proxy.stop);

    final client = HttpClient(context: SecurityContext(withTrustedRoots: false))
      ..badCertificateCallback = (cert, host, p) => true;
    client.findProxy = (_) => 'PROXY 127.0.0.1:$port';
    final request = await client.getUrl(Uri.parse('https://127.0.0.1:${origin.port}/'));
    final response = await request.close();
    final body = await response.transform(const SystemEncoding().decoder).join();

    expect(response.statusCode, 200);
    expect(body, 'secure hello');
    client.close(force: true);
  }, skip: 'Requires a signed test certificate; exercised manually against real IPTV panels.');
}

final _testCertPem = <int>[];
final _testKeyPem = <int>[];
