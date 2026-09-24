import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:sentry_flutter/sentry_flutter.dart' show SentryLevel;

import '../log/telemetry.dart';
import 'dns_resolver.dart';

/// Mutable holder so the active resolver can change at runtime without recreating [HttpClient]s;
/// [AppHttpOverrides.createHttpClient] reads it on every connection attempt.
class DnsRuntime {
  DnsRuntime._();
  static final ValueNotifier<DnsResolver?> resolver = ValueNotifier(null);
}

/// Installed once via `HttpOverrides.global`; makes every `dart:io` HTTP client (Dio, image cache,
/// package:http) honour the resolver picked in Réglages → Réseau / DNS.
class AppHttpOverrides extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) {
    final client = super.createHttpClient(context);
    client.connectionFactory = (Uri uri, String? proxyHost, int? proxyPort) async {
      final resolver = DnsRuntime.resolver.value;
      final literal = InternetAddress.tryParse(uri.host);
      Future<Socket> connect() async {
        if (resolver == null || literal != null) {
          return Socket.connect(uri.host, uri.port);
        }
        final addresses = await resolver.lookup(uri.host);
        if (addresses.isEmpty) {
          unawaited(Telemetry.capture(
            'dns',
            'DNS resolution failed for ${uri.host}',
            level: SentryLevel.error,
            data: {'host': uri.host, 'scheme': uri.scheme, 'resolver': '$resolver', 'path': 'dart-http'},
            fingerprint: ['dns-resolution-failed', uri.host],
          ));
          throw SocketException('DNS resolution failed for ${uri.host}', address: literal);
        }
        return Socket.connect(addresses.first, uri.port);
      }

      final future = connect().then<Socket>((socket) {
        if (!uri.isScheme('https')) return socket;
        return SecureSocket.secure(socket, host: uri.host, context: context);
      });
      // Connection attempts made through a custom resolver cannot be cancelled mid-flight; the
      // outer HttpClient.connectionTimeout still applies via a Future.timeout around this task.
      return ConnectionTask.fromSocket(future, () {});
    };
    return client;
  }
}
