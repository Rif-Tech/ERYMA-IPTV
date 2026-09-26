import 'dart:async';
import 'dart:io' show InternetAddress, Platform;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../app/responsive.dart';
import '../../app/router.dart';
import '../../app/theme.dart';
import '../../core/db/database.dart';
import '../../core/images/artwork_cache.dart';
import '../../core/log/app_logger.dart';
import '../../core/log/telemetry.dart';
import '../../core/log/trace_tag.dart';
import '../../core/platform/native_platform.dart';
import '../../core/settings/settings.dart';
import '../../l10n/generated/app_localizations.dart';
import '../../widgets/pin_dialog.dart';
import '../playlists/playlists_provider.dart';
import 'account_card.dart';
import 'dns_settings_tiles.dart';
import 'settings_tiles.dart';

/// Refresh rates the display offers at its current resolution (see [AppSettings.matchFrameRate]).
final _displayRatesProvider = FutureProvider.autoDispose<Set<String>>((ref) async {
  try {
    return NativePlatform.refreshRatesAtCurrentSize(await NativePlatform.displayInfo());
  } catch (_) {
    return const {};
  }
});

/// "59.940" → "59,94" in French: the rate as the user reads it.
String _rateLabel(String rate, Locale locale) {
  final value = double.tryParse(rate);
  if (value == null) return rate;
  return NumberFormat('0.##', locale.toLanguageTag()).format(value);
}

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final s = ref.watch(settingsProvider);
    final n = ref.read(settingsProvider.notifier);
    final playlist = ref.watch(activePlaylistProvider);

    return TraceTag('settings', child: ListView(
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
        SettingsSection(l10n.myPlaylists, [
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
          SettingsEnumTile<AutoUpdate>(
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
        SettingsSection(l10n.appearance, [
          SettingsEnumTile<Locale?>(
            icon: Icons.language,
            title: l10n.language,
            value: s.locale,
            values: const [null, Locale('fr'), Locale('en')],
            label: (v) => switch (v?.languageCode) { 'fr' => 'Français', 'en' => 'English', _ => l10n.languageSystem },
            onChanged: n.setLocale,
          ),
          SettingsEnumTile<AppThemeMode>(
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
          SettingsEnumTile<ContentLayout>(
            icon: Icons.grid_view,
            title: l10n.layout,
            value: s.layout,
            values: ContentLayout.values,
            label: (v) => v == ContentLayout.grid ? l10n.layoutGrid : l10n.layoutList,
            onChanged: n.setLayout,
          ),
          SettingsEnumTile<SortOrder>(
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
          SettingsEnumTile<FeaturedSource>(
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
        SettingsSection(l10n.parentalControl, [
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
        SettingsSection(l10n.playback, [
          SettingsEnumTile<LiveFormat>(
            icon: Icons.stream,
            title: l10n.liveStreamFormat,
            value: s.liveFormat,
            values: LiveFormat.values,
            label: (v) => v == LiveFormat.ts ? l10n.formatTs : l10n.formatHls,
            onChanged: n.setLiveFormat,
          ),
          SettingsEnumTile<VideoFit>(
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
          SettingsEnumTile<VideoDecoder>(
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
          if (Platform.isAndroid)
            SettingsEnumTile<VideoOutput>(
              icon: Icons.tv_rounded,
              title: l10n.videoOutput,
              value: s.videoOutput,
              values: VideoOutput.values,
              label: (v) => switch (v) {
                VideoOutput.auto => l10n.videoOutputAuto,
                VideoOutput.flutter => l10n.videoOutputFlutter,
                VideoOutput.native => l10n.videoOutputNative,
              },
              onChanged: n.setVideoOutput,
            ),
          if (Platform.isAndroid && ref.watch(isTelevisionProvider))
            Builder(builder: (context) {
              // A display that offers one refresh rate (the Mi TV box: 59.94 Hz only) leaves the
              // switch nothing to do: greyed out, though still switchable off.
              final rates = ref.watch(_displayRatesProvider).value ?? const <String>{};
              final unavailable = rates.length == 1;
              return SwitchListTile(
                secondary: const Icon(Icons.slow_motion_video_rounded),
                title: Text(l10n.matchFrameRate),
                subtitle: Text(unavailable ? l10n.matchFrameRateUnavailable(_rateLabel(rates.single, Localizations.localeOf(context))) : l10n.matchFrameRateHint),
                value: s.matchFrameRate,
                onChanged: unavailable && !s.matchFrameRate ? null : n.setMatchFrameRate,
              );
            }),
          SettingsEnumTile<PerformanceMode>(
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
          SettingsSliderTile(
            icon: Icons.format_size,
            title: l10n.subtitleSize,
            value: s.subtitleScale,
            min: 0.6,
            max: 2.0,
            divisions: 14,
            label: '${(s.subtitleScale * 100).round()} %',
            onChanged: n.setSubtitleScale,
          ),
          SubtitleColorTile(
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
        SettingsSection(l10n.networkDns, [
          SettingsEnumTile<DnsMode>(
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
          if (s.dnsMode == DnsMode.server) const DnsServerPickerTile(),
          if (s.dnsMode == DnsMode.custom) const DnsCustomAddressesTile(),
          // Changing DNS stays allowed, but say plainly when it cannot affect this playlist.
          if (playlist != null && InternetAddress.tryParse(Uri.tryParse(playlist.url)?.host ?? '') != null)
            ListTile(
              enabled: false,
              leading: const Icon(Icons.info_outline),
              title: Text(l10n.dnsIpPlaylistNote),
            ),
          const DnsTestTile(),
        ]),
        SettingsSection(l10n.about, [
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
                final id = await Telemetry.feedback('Problem reported from settings');
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
    ));
  }
}
