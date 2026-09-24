import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../api/portal_api.dart';
import '../db/database.dart';
import '../device/device_identity.dart';
import '../log/telemetry.dart';
import '../settings/settings.dart';
import 'dns_http_overrides.dart';
import 'dns_models.dart';
import 'dns_resolver.dart';
import 'local_proxy.dart';

/// Admin-managed DNS presets, served stale-while-revalidate (same pattern as `FeaturedEntries`):
/// the built-in list appears instantly, refreshed from `app-info` in the background.
class DnsServers extends AsyncNotifier<List<DnsServer>> {
  static const _refreshEvery = Duration(hours: 6);
  static const _cacheKey = 'dnsServers';
  Timer? _timer;

  @override
  Future<List<DnsServer>> build() async {
    final prefs = ref.watch(sharedPreferencesProvider);
    _timer?.cancel();
    _timer = Timer(_refreshEvery, ref.invalidateSelf);
    ref.onDispose(() => _timer?.cancel());

    final cached = _readCache(prefs);
    if (cached != null) {
      unawaited(_refresh(prefs));
      return cached;
    }
    return await _fetch(prefs) ?? kBuiltinDnsServers;
  }

  Future<void> _refresh(SharedPreferences prefs) async {
    final fresh = await _fetch(prefs);
    if (fresh != null && ref.mounted) state = AsyncData(fresh);
  }

  Future<List<DnsServer>?> _fetch(SharedPreferences prefs) async {
    try {
      await ref.read(deviceIdentityProvider.future);
      final info = await ref.read(portalApiProvider).appInfo().timeout(const Duration(seconds: 10));
      if (info.dnsServers.isEmpty) return null;
      await prefs.setString(_cacheKey, jsonEncode(info.dnsServers.map((e) => e.toJson()).toList()));
      return info.dnsServers;
    } catch (e) {
      debugPrint('dnsServers: $e');
      Telemetry.breadcrumb('dns', 'dns server list refresh failed: $e');
      return null;
    }
  }

  static List<DnsServer>? _readCache(SharedPreferences prefs) {
    final raw = prefs.getString(_cacheKey);
    if (raw == null) return null;
    try {
      return (jsonDecode(raw) as List).whereType<Map>().map((e) => DnsServer.fromJson(e.cast<String, dynamic>())).toList();
    } catch (_) {
      return null;
    }
  }
}

final dnsServersProvider = AsyncNotifierProvider<DnsServers, List<DnsServer>>(DnsServers.new);

List<InternetAddress> _addressesOf(DnsServer s) =>
    [...s.ipv4, ...s.ipv6].map(InternetAddress.tryParse).whereType<InternetAddress>().toList();

DnsResolver? _resolverFor(DnsServer s) {
  final resolvers = <DnsResolver>[
    if (s.dohUrl != null) DohResolver(s.dohUrl!),
    if (_addressesOf(s).isNotEmpty) UdpResolver(_addressesOf(s)),
  ];
  return resolvers.isEmpty ? null : CachingResolver(ChainResolver(resolvers));
}

/// Host used to pick the fastest DNS in `auto` mode: the active playlist's own host, since that
/// is exactly what needs to bypass the operator's DNS to load the playlist/streams.
final dnsProbeHostProvider = FutureProvider<String?>((ref) async {
  final playlistId = ref.watch(settingsProvider.select((s) => s.activePlaylistId));
  if (playlistId == null) return null;
  final playlist = await ref.watch(databaseProvider).getPlaylist(playlistId);
  final url = playlist?.url;
  if (url == null || url.isEmpty) return null;
  return Uri.tryParse(url)?.host;
});

/// Builds the resolver implied by the current settings (null = use the system/operator DNS).
/// `auto` probes every enabled server against [dnsProbeHostProvider] and keeps the fastest one.
final activeDnsResolverProvider = FutureProvider<DnsResolver?>((ref) async {
  final settings = ref.watch(settingsProvider);
  final resolver = await _buildResolver(ref, settings);
  Telemetry.breadcrumb('dns', 'active resolver: ${resolver ?? 'system'} (mode ${settings.dnsMode.name})');
  Telemetry.context('dns', {
    'mode': settings.dnsMode.name,
    'server_id': settings.dnsServerId,
    'custom_addresses': settings.dnsCustomAddresses,
    'resolver': '${resolver ?? 'system'}',
  });
  return resolver;
});

Future<DnsResolver?> _buildResolver(Ref ref, AppSettings settings) async {
  switch (settings.dnsMode) {
    case DnsMode.system:
      return null;
    case DnsMode.custom:
      final addrs = (settings.dnsCustomAddresses ?? '')
          .split(RegExp(r'[\s,]+'))
          .map((s) => s.trim())
          .where((s) => s.isNotEmpty)
          .map(InternetAddress.tryParse)
          .whereType<InternetAddress>()
          .toList();
      return addrs.isEmpty ? null : CachingResolver(UdpResolver(addrs));
    case DnsMode.server:
      final servers = await ref.watch(dnsServersProvider.future);
      final server = servers.where((s) => s.id == settings.dnsServerId).firstOrNull ??
          servers.where((s) => s.isDefault).firstOrNull ??
          servers.firstOrNull;
      return server == null ? null : _resolverFor(server);
    case DnsMode.auto:
      final host = await ref.watch(dnsProbeHostProvider.future);
      if (host == null) return null;
      final servers = await ref.watch(dnsServersProvider.future);
      final results = await probeDns(host, servers);
      final winner = results.where((r) => r.ok).toList().sortedByLatency.firstOrNull;
      Telemetry.breadcrumb('dns', 'auto mode picked ${winner?.label ?? 'nothing (all failed)'}');
      if (winner == null || winner.label == 'Système') return null;
      final server = servers.where((s) => s.name == winner.label).firstOrNull;
      return server == null ? null : _resolverFor(server);
  }
}

/// Keeps [DnsRuntime.resolver] (read by [AppHttpOverrides]) in sync with the active setting.
final dnsRuntimeSyncProvider = Provider<void>((ref) {
  ref.listen(activeDnsResolverProvider, (_, next) => DnsRuntime.resolver.value = next.value, fireImmediately: true);
});

/// Loopback proxy mpv/ffmpeg are pointed at (`http-proxy`) so stream playback also honours the
/// selected DNS; only runs while a non-system resolver is active.
class DnsProxy extends AsyncNotifier<int?> {
  LocalDnsProxy? _proxy;

  @override
  Future<int?> build() async {
    final resolver = await ref.watch(activeDnsResolverProvider.future);
    final old = _proxy;
    ref.onDispose(() => old?.stop());
    if (resolver == null) {
      await old?.stop();
      _proxy = null;
      Telemetry.tags({'dns_proxy_port': null});
      return null;
    }
    final proxy = LocalDnsProxy(resolver);
    final int port;
    try {
      port = await proxy.start();
    } catch (e, st) {
      Telemetry.exception(e, st, category: 'dns', data: {'resolver': '$resolver'});
      rethrow;
    }
    await old?.stop();
    _proxy = proxy;
    // Any settings change restarts the proxy on a new port (see the roadmap), while an open
    // player keeps the old one: the player compares this with the port it was given.
    Telemetry.breadcrumb('dns', 'proxy listening on $port (previous ${old?.port ?? 'none'})', data: {'resolver': '$resolver'});
    Telemetry.tags({'dns_proxy_port': port});
    return port;
  }
}

final dnsProxyProvider = AsyncNotifierProvider<DnsProxy, int?>(DnsProxy.new);

/// One resolution attempt result for the "Tester" button and DNS-mode `auto`.
class DnsProbeResult {
  const DnsProbeResult({required this.label, required this.ok, this.latency});
  final String label;
  final bool ok;
  final Duration? latency;
}

extension _SortByLatency on List<DnsProbeResult> {
  List<DnsProbeResult> get sortedByLatency => [...this]
    ..sort((a, b) => (a.latency ?? const Duration(seconds: 999)).compareTo(b.latency ?? const Duration(seconds: 999)));
}

/// Resolves+connects [host]:80 through the system resolver and every enabled server, in parallel.
Future<List<DnsProbeResult>> probeDns(String host, List<DnsServer> servers) async {
  Future<DnsProbeResult> run(String label, DnsResolver resolver) async {
    final sw = Stopwatch()..start();
    try {
      final addresses = await resolver.lookup(host).timeout(const Duration(seconds: 3));
      if (addresses.isEmpty) return DnsProbeResult(label: label, ok: false);
      final socket = await Socket.connect(addresses.first, 80, timeout: const Duration(seconds: 3));
      socket.destroy();
      return DnsProbeResult(label: label, ok: true, latency: sw.elapsed);
    } catch (_) {
      return DnsProbeResult(label: label, ok: false);
    }
  }

  final results = await Future.wait([
    run('Système', const SystemResolver()),
    for (final s in servers.where((s) => s.dohUrl != null || s.addresses.isNotEmpty))
      run(s.name, _resolverFor(s) ?? const SystemResolver()),
  ]);
  Telemetry.breadcrumb('dns', 'probe of $host', data: {
    for (final r in results) r.label: r.ok ? '${r.latency?.inMilliseconds} ms' : 'failed',
  });
  return results;
}
