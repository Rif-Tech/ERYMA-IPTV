import 'package:flutter/material.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/router.dart';
import '../../app/theme.dart';
import '../../core/db/database.dart';
import '../../core/settings/settings.dart';
import '../../l10n/generated/app_localizations.dart';
import '../../widgets/common.dart';
import '../../widgets/pin_dialog.dart';
import '../playlists/device_info_card.dart';
import '../playlists/playlists_provider.dart';

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
        32 + MediaQuery.paddingOf(context).bottom,
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
                const DeviceInfoCard(showQr: false),
                const SizedBox(height: 16),
        _Section(l10n.myPlaylists, [
          ListTile(
            leading: const Icon(Icons.playlist_play),
            title: Text(l10n.changePlaylist),
            subtitle: playlist != null ? Text(playlist.name) : null,
            onTap: () => context.push(Routes.playlists),
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
          ListTile(
            leading: const Icon(Icons.format_size),
            title: Text(l10n.subtitleSize),
            subtitle: Slider(
              value: s.subtitleScale,
              min: 0.6,
              max: 2.0,
              divisions: 14,
              label: '${(s.subtitleScale * 100).round()} %',
              onChanged: n.setSubtitleScale,
            ),
          ),
          ListTile(
            leading: const Icon(Icons.color_lens_outlined),
            title: Text(l10n.subtitleColor),
            trailing: Wrap(
              spacing: 6,
              children: [
                for (final c in const [0xFFFFFFFF, 0xFFFFEB3B, 0xFF4FC3F7, 0xFF81C784, 0xFFFF8A65])
                  InkWell(
                    onTap: () => n.setSubtitleColor(c),
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      width: 24,
                      height: 24,
                      decoration: BoxDecoration(
                        color: Color(c),
                        shape: BoxShape.circle,
                        border: Border.all(color: s.subtitleColor == c ? Colors.white : Colors.transparent, width: 2),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          SwitchListTile(
            secondary: const Icon(Icons.format_color_fill),
            title: Text(l10n.subtitleBackground),
            value: s.subtitleBackground,
            onChanged: n.setSubtitleBackground,
          ),
        ]),
        _Section(l10n.about, [
          ListTile(
            leading: const Icon(Icons.cleaning_services_outlined),
            title: Text(l10n.clearCache),
            onTap: () async {
              await DefaultCacheManager().emptyCache();
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
              RadioGroup<T>(
                groupValue: value,
                onChanged: (v) => Navigator.pop(context, (v as T,)),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    for (final v in values) RadioListTile<T>(autofocus: v == value, value: v, title: Text(label(v))),
                  ],
                ),
              ),
            ],
          ),
        );
        if (picked != null) onChanged(picked.$1);
      },
    );
  }
}
