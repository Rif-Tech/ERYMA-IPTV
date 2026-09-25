// RadioListTile's per-tile groupValue/onChanged is deprecated in favor of a RadioGroup ancestor —
// deliberately not used here, see SettingsEnumTile (settings_tiles.dart).
// ignore_for_file: deprecated_member_use

import 'dart:async';
import 'dart:io' show InternetAddress;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/log/telemetry.dart';
import '../../core/net/dns_models.dart';
import '../../core/net/dns_providers.dart';
import '../../core/settings/settings.dart';
import '../../l10n/generated/app_localizations.dart';

// Réglages → Réseau / DNS rows: server picker, custom addresses, resolver test.

/// Picks one of the admin-managed DNS presets (falls back to the built-in list while offline).
class DnsServerPickerTile extends ConsumerWidget {
  const DnsServerPickerTile({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final s = ref.watch(settingsProvider);
    final servers = ref.watch(dnsServersProvider).value ?? kBuiltinDnsServers;
    final selected = servers.where((d) => d.id == s.dnsServerId).firstOrNull ?? servers.where((d) => d.isDefault).firstOrNull;
    return ListTile(
      leading: const Icon(Icons.public),
      title: Text(l10n.dnsServer),
      subtitle: Text(selected?.name ?? l10n.dnsModeSystem),
      onTap: () async {
        final picked = await showDialog<(String,)>(
          context: context,
          builder: (context) => SimpleDialog(
            title: Text(l10n.dnsServer),
            children: [
              // See SettingsEnumTile: no RadioGroup ancestor, so Up/Down only move focus.
              for (final d in servers)
                RadioListTile<String>(
                  autofocus: d.id == selected?.id,
                  value: d.id,
                  groupValue: selected?.id ?? '',
                  onChanged: (picked) => Navigator.pop(context, (picked as String,)),
                  title: Text(d.name),
                  subtitle: d.addresses.isNotEmpty ? Text(d.addresses.first) : null,
                ),
            ],
          ),
        );
        if (picked != null) await ref.read(settingsProvider.notifier).setDnsServerId(picked.$1);
      },
    );
  }
}

/// Free-form resolver IPs (comma or space separated) for `DnsMode.custom`.
class DnsCustomAddressesTile extends ConsumerWidget {
  const DnsCustomAddressesTile({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final s = ref.watch(settingsProvider);
    return ListTile(
      leading: const Icon(Icons.edit_outlined),
      title: Text(l10n.dnsCustomAddresses),
      subtitle: Text(s.dnsCustomAddresses?.isNotEmpty == true ? s.dnsCustomAddresses! : l10n.dnsCustomAddressesHint),
      onTap: () async {
        final controller = TextEditingController(text: s.dnsCustomAddresses ?? '');
        final value = await showDialog<String>(
          context: context,
          builder: (context) => AlertDialog(
            title: Text(l10n.dnsCustomAddresses),
            content: TextField(
              controller: controller,
              autofocus: true,
              decoration: InputDecoration(hintText: l10n.dnsCustomAddressesHint),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(context), child: Text(l10n.cancel)),
              FilledButton(onPressed: () => Navigator.pop(context, controller.text), child: Text(l10n.save)),
            ],
          ),
        );
        if (value != null) await ref.read(settingsProvider.notifier).setDnsCustomAddresses(value.trim());
      },
    );
  }
}

/// Probes the system resolver and every enabled DNS server against the active playlist's host.
class DnsTestTile extends ConsumerStatefulWidget {
  const DnsTestTile({super.key});

  @override
  ConsumerState<DnsTestTile> createState() => _DnsTestTileState();
}

class _DnsTestTileState extends ConsumerState<DnsTestTile> {
  bool _running = false;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return ListTile(
      leading: _running ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2)) : const Icon(Icons.wifi_tethering),
      title: Text(l10n.dnsTest),
      subtitle: Text(l10n.dnsTestHint),
      onTap: _running ? null : _run,
    );
  }

  Future<void> _run() async {
    setState(() => _running = true);
    try {
      final host = await ref.read(dnsProbeHostProvider.future);
      if (host == null) {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(AppLocalizations.of(context).dnsTestNoPlaylist)));
        return;
      }
      // A playlist reached by IP never uses DNS: the test then checks the servers on the app's
      // own API host and says so, instead of showing every server as failed (Sentry FLUTTER-A).
      final ipHost = InternetAddress.tryParse(host) != null;
      final target = dnsProbeTarget(host);
      final servers = ref.read(dnsServersProvider).value ?? kBuiltinDnsServers;
      final results = await probeDns(target, servers);
      // A log line, not an issue: the test is a user action, and failures already raise their own
      // `dns` events from the resolvers.
      Telemetry.breadcrumb(
        'dns',
        'DNS test run (${results.where((r) => r.ok).length}/${results.length} ok)',
        data: {'host': host, 'probed_host': target, 'ip_playlist': ipHost, for (final r in results) r.label: r.ok ? '${r.latency?.inMilliseconds} ms' : 'failed'},
      );
      if (!mounted) return;
      await showDialog<void>(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(AppLocalizations.of(context).dnsTest),
          // Seven servers do not fit a 540 dp-high TV screen (Sentry FLUTTER-C, 6 px overflow).
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (ipHost)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Text(AppLocalizations.of(context).dnsTestIpHost(host), style: Theme.of(context).textTheme.bodySmall),
                  ),
                for (final r in results)
                  ListTile(
                    dense: true,
                    leading: Icon(r.ok ? Icons.check_circle : Icons.cancel, color: r.ok ? Colors.greenAccent : Colors.redAccent),
                    title: Text(r.label),
                    trailing: r.latency != null ? Text('${r.latency!.inMilliseconds} ms') : null,
                  ),
              ],
            ),
          ),
          // Nothing else in the dialog is focusable: without autofocus the first D-pad press was
          // spent reaching Close.
          actions: [TextButton(autofocus: true, onPressed: () => Navigator.pop(context), child: Text(AppLocalizations.of(context).close))],
        ),
      );
    } finally {
      if (mounted) setState(() => _running = false);
    }
  }
}
