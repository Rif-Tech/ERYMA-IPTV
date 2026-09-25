import 'package:flutter/foundation.dart';

/// Admin-managed DNS preset (`dns_servers` table, mirrored by the `app-info` edge function).
@immutable
class DnsServer {
  const DnsServer({
    required this.id,
    required this.name,
    this.provider,
    this.ipv4 = const [],
    this.ipv6 = const [],
    this.dohUrl,
    this.dotHost,
    this.isDefault = false,
  });

  final String id;
  final String name;
  final String? provider;
  final List<String> ipv4;
  final List<String> ipv6;
  final String? dohUrl;
  final String? dotHost;
  final bool isDefault;

  factory DnsServer.fromJson(Map<String, dynamic> j) => DnsServer(
        id: j['id'] as String,
        name: j['name'] as String,
        provider: j['provider'] as String?,
        ipv4: (j['ipv4'] as List?)?.cast<String>() ?? const [],
        ipv6: (j['ipv6'] as List?)?.cast<String>() ?? const [],
        dohUrl: j['doh_url'] as String?,
        dotHost: j['dot_host'] as String?,
        isDefault: j['is_default'] == true,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'provider': provider,
        'ipv4': ipv4,
        'ipv6': ipv6,
        'doh_url': dohUrl,
        'dot_host': dotHost,
        'is_default': isDefault,
      };

  /// All resolver addresses (IPv4 first) used for the UDP fallback.
  List<String> get addresses => [...ipv4, ...ipv6];
}

/// Bundled so the DNS feature still works offline / before the first successful `app-info` fetch.
const kBuiltinDnsServers = [
  DnsServer(
    id: 'builtin-google',
    name: 'Google Public DNS',
    provider: 'Google',
    ipv4: ['8.8.8.8', '8.8.4.4'],
    ipv6: ['2001:4860:4860::8888', '2001:4860:4860::8844'],
    dohUrl: 'https://8.8.8.8/dns-query',
    isDefault: true,
  ),
  DnsServer(
    id: 'builtin-cloudflare',
    name: 'Cloudflare',
    provider: 'Cloudflare',
    ipv4: ['1.1.1.1', '1.0.0.1'],
    ipv6: ['2606:4700:4700::1111', '2606:4700:4700::1001'],
    dohUrl: 'https://1.1.1.1/dns-query',
  ),
  DnsServer(
    id: 'builtin-quad9',
    name: 'Quad9',
    provider: 'Quad9',
    ipv4: ['9.9.9.9', '149.112.112.112'],
    ipv6: ['2620:fe::fe', '2620:fe::9'],
    dohUrl: 'https://9.9.9.9/dns-query',
  ),
  DnsServer(
    id: 'builtin-opendns',
    name: 'OpenDNS',
    provider: 'Cisco',
    ipv4: ['208.67.222.222', '208.67.220.220'],
    ipv6: ['2620:119:35::35', '2620:119:53::53'],
  ),
  DnsServer(
    id: 'builtin-adguard',
    name: 'AdGuard DNS',
    provider: 'AdGuard',
    ipv4: ['94.140.14.14', '94.140.15.15'],
    ipv6: ['2a10:50c0::ad1:ff', '2a10:50c0::ad2:ff'],
    dohUrl: 'https://94.140.14.14/dns-query',
  ),
];
