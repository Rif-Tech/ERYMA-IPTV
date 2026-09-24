// RadioListTile's per-tile groupValue/onChanged (used in _EnumTile / _DnsServerPickerTile below)
// is deprecated in favor of a RadioGroup ancestor — deliberately not used here, see the comment
// on _EnumTile's dialog: RadioGroup binds D-pad Up/Down to immediate selection, not just focus.
// ignore_for_file: deprecated_member_use

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:sentry_flutter/sentry_flutter.dart' show SentryLevel;

import '../../app/router.dart';
import '../../app/theme.dart';
import '../../core/db/database.dart';
import '../../core/images/artwork_cache.dart';
import '../../core/log/app_logger.dart';
import '../../core/log/telemetry.dart';
import '../../core/net/dns_models.dart';
import '../../core/net/dns_providers.dart';
import '../../core/settings/settings.dart';
import '../../l10n/generated/app_localizations.dart';
import '../../widgets/common.dart';
import '../../widgets/pin_dialog.dart';
import '../playlists/playlists_provider.dart';
import 'account_card.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final s = ref.watch(settingsProvider);
    final n = ref.read(settingsProvider.notifier);
    final playlist = ref.watch(activePlaylistProvider);

    return ListView(
      padding: EdgeInsets.fromLTRB(
        context.tokens.pageGutter,
        MediaQuery.paddingOf(context).top + 12,
        context.tokens.pageGutter,
        // Room for TV overscan so the last tile is never clipped when focused.
        88 + MediaQuery.paddingOf(context).bottom,
      ),
      children: [
        Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 820),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(l10n.settings, style: Theme.of(context).textTheme.headlineMedium),
                const SizedBox(height: 20),
                const AccountCard(),
                const SizedBox(height: 16),
        _Section(l10n.myPlaylists, [
          if (ref.watch(profilesProvider).length > 1)
            ListTile(
              leading: const Icon(Icons.switch_account_rounded),
              title: Text(l10n.switchProfile),
              subtitle: ref.watch(activeProfileProvider) != null ? Text(ref.watch(activeProfileProvider)!.name) : null,
              onTap: () => context.push(Routes.profiles),
            ),
          ListTile(
            leading: const Icon(Icons.playlist_play),
            title: Text(l10n.changePlaylist),
            subtitle: playlist != null ? Text(playlist.name) : null,
            onTap: () => context.push(Routes.playlists),
          ),
          ListTile(
            leading: const Icon(Icons.playlist_add_rounded),
            title: Text(l10n.addPlaylistTitle),
            onTap: () => context.push(Routes.noPlaylist),
          ),
          if (playlist != null)
            ListTile(
              leading: const Icon(Icons.refresh),
              title: Text(l10n.refreshPlaylists),
              onTap: () => context.go(Routes.import(playlist.id)),
            ),
          _EnumTile<AutoUpdate>(
            icon: Icons.update,
            title: l10n.autoUpdatePlaylist,
            value: s.autoUpdate,
            values: AutoUpdate.values,
            label: (v) => switch (v) {
              AutoUpdate.never => l10n.autoUpdateNever,
              AutoUpdate.daily => l10n.autoUpdateDaily,
              AutoUpdate.always => l10n.autoUpdateAlways,
            },
            onChanged: n.setAutoUpdate,
          ),
        ]),
        _Section(l10n.appearance, [
          _EnumTile<Locale?>(
            icon: Icons.language,
            title: l10n.language,
            value: s.locale,
            values: const [null, Locale('fr'), Locale('en')],
            label: (v) => switch (v?.languageCode) { 'fr' => 'Français', 'en' => 'English', _ => l10n.languageSystem },
            onChanged: n.setLocale,
          ),
          _EnumTile<AppThemeMode>(
            icon: Icons.palette_outlined,
            title: l10n.theme,
            value: s.themeMode,
            values: AppThemeMode.values,
            label: (v) => switch (v) {
              AppThemeMode.dark => l10n.themeDark,
              AppThemeMode.amoled => l10n.themeAmoled,
            },
            onChanged: n.setThemeMode,
          ),
          _EnumTile<ContentLayout>(
            icon: Icons.grid_view,
            title: l10n.layout,
            value: s.layout,
            values: ContentLayout.values,
            label: (v) => v == ContentLayout.grid ? l10n.layoutGrid : l10n.layoutList,
            onChanged: n.setLayout,
          ),
          _EnumTile<SortOrder>(
            icon: Icons.sort,
            title: l10n.sortOrder,
            value: s.sortOrder,
            values: SortOrder.values,
            label: (v) => switch (v) {
              SortOrder.defaultOrder => l10n.sortDefault,
              SortOrder.az => l10n.sortAz,
              SortOrder.za => l10n.sortZa,
              SortOrder.added => l10n.sortAdded,
              SortOrder.rating => l10n.sortRating,
            },
            onChanged: n.setSortOrder,
          ),
          SwitchListTile(
            secondary: const Icon(Icons.schedule),
            title: Text(l10n.timeFormat),
            subtitle: Text(s.use24hClock ? l10n.timeFormat24 : l10n.timeFormat12),
            value: s.use24hClock,
            onChanged: n.setUse24hClock,
          ),
          _EnumTile<FeaturedSource>(
            icon: Icons.star_outline_rounded,
            title: l10n.featuredSource,
            value: s.featuredSource,
            values: FeaturedSource.values,
            label: (v) => switch (v) {
              FeaturedSource.curated => l10n.featuredCurated,
              FeaturedSource.popular => l10n.featuredPopular,
              FeaturedSource.tmdb => l10n.featuredTmdb,
            },
            onChanged: n.setFeaturedSource,
          ),
        ]),
        _Section(l10n.parentalControl, [
          ListTile(
            leading: const Icon(Icons.lock_outline),
            title: Text(l10n.parentalControl),
            subtitle: Text(s.hasParentalPin ? l10n.parentalPin : l10n.setParentalPin),
            onTap: () async {
              if (await requirePin(context, s.parentalPin) && context.mounted) context.push(Routes.parental);
            },
          ),
          ListTile(
            leading: const Icon(Icons.folder_special_outlined),
            title: Text(l10n.myGroups),
            onTap: () => context.push(Routes.groups),
          ),
        ]),
        _Section(l10n.playback, [
          _EnumTile<LiveFormat>(
            icon: Icons.stream,
            title: l10n.liveStreamFormat,
            value: s.liveFormat,
            values: LiveFormat.values,
            label: (v) => v == LiveFormat.ts ? l10n.formatTs : l10n.formatHls,
            onChanged: n.setLiveFormat,
          ),
          _EnumTile<VideoFit>(
            icon: Icons.aspect_ratio,
            title: l10n.videoFit,
            value: s.videoFit,
            values: VideoFit.values,
            label: (v) => switch (v) {
              VideoFit.contain => l10n.fitContain,
              VideoFit.cover => l10n.fitCover,
              VideoFit.fill => l10n.fitStretch,
            },
            onChanged: n.setVideoFit,
          ),
          _EnumTile<VideoDecoder>(
            icon: Icons.memory,
            title: l10n.videoDecoder,
            value: s.videoDecoder,
            values: VideoDecoder.values,
            label: (v) => switch (v) {
              VideoDecoder.auto => l10n.decoderAuto,
              VideoDecoder.direct => l10n.decoderDirect,
              VideoDecoder.compat => l10n.decoderCompat,
              VideoDecoder.software => l10n.decoderSoftware,
            },
            onChanged: n.setVideoDecoder,
          ),
          _EnumTile<PerformanceMode>(
            icon: Icons.speed_rounded,
            title: l10n.performanceMode,
            value: s.performanceMode,
            values: PerformanceMode.values,
            label: (v) => switch (v) {
              PerformanceMode.auto => l10n.performanceAuto,
              PerformanceMode.on => l10n.performanceOn,
              PerformanceMode.off => l10n.performanceOff,
            },
            onChanged: n.setPerformanceMode,
          ),
          _SliderTile(
            icon: Icons.format_size,
            title: l10n.subtitleSize,
            value: s.subtitleScale,
            min: 0.6,
            max: 2.0,
            divisions: 14,
            label: '${(s.subtitleScale * 100).round()} %',
            onChanged: n.setSubtitleScale,
          ),
          _SubtitleColorTile(
            colors: const [0xFFFFFFFF, 0xFFFFEB3B, 0xFF4FC3F7, 0xFF81C784, 0xFFFF8A65],
            value: s.subtitleColor,
            onChanged: n.setSubtitleColor,
          ),
          SwitchListTile(
            secondary: const Icon(Icons.format_color_fill),
            title: Text(l10n.subtitleBackground),
            value: s.subtitleBackground,
            onChanged: n.setSubtitleBackground,
          ),
        ]),
        _Section(l10n.networkDns, [
          _EnumTile<DnsMode>(
            icon: Icons.dns_outlined,
            title: l10n.dnsMode,
            value: s.dnsMode,
            values: DnsMode.values,
            label: (v) => switch (v) {
              DnsMode.system => l10n.dnsModeSystem,
              DnsMode.auto => l10n.dnsModeAuto,
              DnsMode.server => l10n.dnsModeServer,
              DnsMode.custom => l10n.dnsModeCustom,
            },
            onChanged: n.setDnsMode,
          ),
          if (s.dnsMode == DnsMode.server) const _DnsServerPickerTile(),
          if (s.dnsMode == DnsMode.custom) const _DnsCustomAddressesTile(),
          const _DnsTestTile(),
        ]),
        _Section(l10n.about, [
          ListTile(
            leading: const Icon(Icons.cleaning_services_outlined),
            title: Text(l10n.clearCache),
            onTap: () async {
              await ArtworkCache.instance.emptyCache();
              PaintingBinding.instance.imageCache.clear();
              if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l10n.cleared)));
            },
          ),
          if (playlist != null)
            ListTile(
              leading: const Icon(Icons.history_toggle_off),
              title: Text(l10n.clearHistory),
              onTap: () async {
                await ref.read(databaseProvider).clearHistory(playlist.id);
                if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l10n.cleared)));
              },
            ),
          if (Telemetry.enabled)
            ListTile(
              leading: const Icon(Icons.bug_report_outlined),
              title: Text(l10n.reportProblem),
              subtitle: Text(l10n.reportProblemHint),
              onTap: () async {
                unawaited(ref.read(appLoggerProvider).flush());
                final id = await Telemetry.capture(
                  'user_report',
                  'Problem reported from settings',
                  level: SentryLevel.info,
                  fingerprint: ['user-report', '${DateTime.now().microsecondsSinceEpoch}'],
                );
                if (context.mounted && id != null) {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l10n.problemReported('$id'.substring(0, 8)))));
                }
              },
            ),
          ListTile(leading: const Icon(Icons.info_outline), title: Text(l10n.appName), subtitle: Text(l10n.disclaimer)),
        ]),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _Section extends StatelessWidget {
  const _Section(this.title, this.children);
  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: Text(
              title.toUpperCase(),
              style: Theme.of(context).textTheme.labelSmall?.copyWith(color: context.tokens.textFaint, letterSpacing: 1),
            ),
          ),
          GlassPanel(
            padding: const EdgeInsets.symmetric(vertical: 4),
            // Ink (focus highlight) must paint above the panel background, not on the page Material below it.
            child: Material(
              type: MaterialType.transparency,
              child: Column(
                children: [
                  for (final (i, c) in children.indexed) ...[
                    if (i > 0) Divider(indent: 56, endIndent: 16, color: context.tokens.glass),
                    c,
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Slider row for the D-pad: left/right adjust the value, up/down keep moving through the list.
///
/// Flutter's [Slider] binds all four arrows to value changes, which traps the focus on TV.
class _SliderTile extends StatefulWidget {
  const _SliderTile({
    required this.icon,
    required this.title,
    required this.value,
    required this.min,
    required this.max,
    required this.divisions,
    required this.label,
    required this.onChanged,
  });
  final IconData icon;
  final String title;
  final double value;
  final double min;
  final double max;
  final int divisions;
  final String label;
  final ValueChanged<double> onChanged;

  @override
  State<_SliderTile> createState() => _SliderTileState();
}

class _SliderTileState extends State<_SliderTile> {
  late final FocusNode _node = FocusNode(debugLabel: 'slider-tile', onKeyEvent: _onKey);

  @override
  void initState() {
    super.initState();
    _node.addListener(_onFocus);
  }

  @override
  void dispose() {
    _node.removeListener(_onFocus);
    _node.dispose();
    super.dispose();
  }

  void _onFocus() => setState(() {});

  KeyEventResult _onKey(FocusNode node, KeyEvent event) {
    if (event is KeyUpEvent) return KeyEventResult.ignored;
    final key = event.logicalKey;
    if (key == LogicalKeyboardKey.arrowUp || key == LogicalKeyboardKey.arrowDown) {
      // Runs before the slider's own shortcuts: hand the key back to focus traversal.
      final moved = node.focusInDirection(key == LogicalKeyboardKey.arrowUp ? TraversalDirection.up : TraversalDirection.down);
      return moved ? KeyEventResult.handled : KeyEventResult.ignored;
    }
    return KeyEventResult.ignored;
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return ListTile(
      leading: Icon(widget.icon),
      title: Text(widget.title),
      trailing: Text(widget.label, style: Theme.of(context).textTheme.labelLarge),
      selected: _node.hasFocus,
      selectedTileColor: scheme.primary.withValues(alpha: 0.12),
      subtitle: Slider(
        value: widget.value,
        min: widget.min,
        max: widget.max,
        divisions: widget.divisions,
        label: widget.label,
        focusNode: _node,
        onChanged: widget.onChanged,
      ),
    );
  }
}

/// Color swatch row for the D-pad, same pattern as [_SliderTile]: the [FocusNode] sits on the
/// whole [ListTile] (a full-width target, like the slider), not on the narrow trailing swatches
/// themselves — a focus node confined to that small trailing area is not reliably reachable by
/// directional traversal from the rows above/below. Left/right immediately picks the next/
/// previous color; up/down keep moving through the list.
class _SubtitleColorTile extends StatefulWidget {
  const _SubtitleColorTile({required this.colors, required this.value, required this.onChanged});
  final List<int> colors;
  final int value;
  final ValueChanged<int> onChanged;

  @override
  State<_SubtitleColorTile> createState() => _SubtitleColorTileState();
}

class _SubtitleColorTileState extends State<_SubtitleColorTile> {
  late final FocusNode _node = FocusNode(debugLabel: 'subtitle-color', onKeyEvent: _onKey);

  @override
  void initState() {
    super.initState();
    _node.addListener(_onFocus);
  }

  @override
  void dispose() {
    _node.removeListener(_onFocus);
    _node.dispose();
    super.dispose();
  }

  void _onFocus() => setState(() {});

  KeyEventResult _onKey(FocusNode node, KeyEvent event) {
    if (event is KeyUpEvent) return KeyEventResult.ignored;
    final key = event.logicalKey;
    if (key == LogicalKeyboardKey.arrowUp || key == LogicalKeyboardKey.arrowDown) {
      // Runs before default traversal would even see this node as one stop: hand the key back.
      final moved = node.focusInDirection(key == LogicalKeyboardKey.arrowUp ? TraversalDirection.up : TraversalDirection.down);
      return moved ? KeyEventResult.handled : KeyEventResult.ignored;
    }
    if (key == LogicalKeyboardKey.arrowLeft || key == LogicalKeyboardKey.arrowRight) {
      final i = widget.colors.indexOf(widget.value);
      final next = i + (key == LogicalKeyboardKey.arrowRight ? 1 : -1);
      if (next < 0 || next >= widget.colors.length) return KeyEventResult.ignored;
      widget.onChanged(widget.colors[next]);
      return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context);
    return Material(
      color: Colors.transparent,
      child: InkWell(
        focusNode: _node,
        canRequestFocus: true,
        onTap: () {},
        child: ListTile(
      selected: _node.hasFocus,
      selectedTileColor: scheme.primary.withValues(alpha: 0.12),
      leading: const Icon(Icons.color_lens_outlined),
      title: Text(l10n.subtitleColor),
      trailing: Wrap(
        spacing: 12,
        children: [
          for (final c in widget.colors)
            GestureDetector(
              onTap: () => widget.onChanged(c),
              child: Container(
                width: 28,
                height: 28,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: widget.value == c && _node.hasFocus ? Border.all(color: Colors.white, width: 2.5) : null,
                ),
                child: Container(
                  width: 22,
                  height: 22,
                  decoration: BoxDecoration(
                    color: Color(c),
                    shape: BoxShape.circle,
                    border: Border.all(color: widget.value == c ? Colors.white : Colors.transparent, width: 2),
                  ),
                ),
              ),
            ),
        ],
      ),
        ),
      ),
    );
  }
}

/// ListTile opening a radio dialog; works with D-pad and touch alike.
class _EnumTile<T> extends StatelessWidget {
  const _EnumTile({
    required this.icon,
    required this.title,
    required this.value,
    required this.values,
    required this.label,
    required this.onChanged,
  });
  final IconData icon;
  final String title;
  final T value;
  final List<T> values;
  final String Function(T) label;
  final ValueChanged<T> onChanged;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon),
      title: Text(title),
      subtitle: Text(label(value)),
      onTap: () async {
        final picked = await showDialog<(T,)>(
          context: context,
          builder: (context) => SimpleDialog(
            title: Text(title),
            children: [
              // No RadioGroup ancestor on purpose (hence the deprecated per-tile groupValue/
              // onChanged below, see the ignore_for_file at the top of this file): RadioGroup
              // binds arrow keys to select-and-advance (see radio_group.dart), which would
              // confirm and close the dialog on the first D-pad press instead of just moving
              // focus. Do not "fix" this deprecation warning by migrating to RadioGroup without
              // re-solving that problem first.
              for (final v in values)
                RadioListTile<T>(
                  autofocus: v == value,
                  value: v,
                  groupValue: value,
                  onChanged: (picked) => Navigator.pop(context, (picked as T,)),
                  title: Text(label(v)),
                ),
            ],
          ),
        );
        if (picked != null) onChanged(picked.$1);
      },
    );
  }
}

/// Picks one of the admin-managed DNS presets (falls back to the built-in list while offline).
class _DnsServerPickerTile extends ConsumerWidget {
  const _DnsServerPickerTile();

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
              // See _EnumTile: no RadioGroup ancestor, so Up/Down only move focus.
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
class _DnsCustomAddressesTile extends ConsumerWidget {
  const _DnsCustomAddressesTile();

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
class _DnsTestTile extends ConsumerStatefulWidget {
  const _DnsTestTile();

  @override
  ConsumerState<_DnsTestTile> createState() => _DnsTestTileState();
}

class _DnsTestTileState extends ConsumerState<_DnsTestTile> {
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
      final servers = ref.read(dnsServersProvider).value ?? kBuiltinDnsServers;
      final results = await probeDns(host, servers);
      unawaited(Telemetry.capture(
        'dns',
        'DNS test run (${results.where((r) => r.ok).length}/${results.length} ok)',
        level: SentryLevel.info,
        data: {'host': host, for (final r in results) r.label: r.ok ? '${r.latency?.inMilliseconds} ms' : 'failed'},
        fingerprint: ['dns-test'],
        throttle: const Duration(minutes: 1),
      ));
      if (!mounted) return;
      await showDialog<void>(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(AppLocalizations.of(context).dnsTest),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (final r in results)
                ListTile(
                  dense: true,
                  leading: Icon(r.ok ? Icons.check_circle : Icons.cancel, color: r.ok ? Colors.greenAccent : Colors.redAccent),
                  title: Text(r.label),
                  trailing: r.latency != null ? Text('${r.latency!.inMilliseconds} ms') : null,
                ),
            ],
          ),
          actions: [TextButton(onPressed: () => Navigator.pop(context), child: Text(AppLocalizations.of(context).close))],
        ),
      );
    } finally {
      if (mounted) setState(() => _running = false);
    }
  }
}
