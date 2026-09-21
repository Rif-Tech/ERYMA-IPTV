import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/responsive.dart';
import '../../app/router.dart';
import '../../core/db/database.dart';
import '../../core/playlist/playlist_importer.dart';
import '../../core/settings/settings.dart';
import '../../l10n/generated/app_localizations.dart';
import '../../widgets/common.dart';
import '../../widgets/format.dart';
import '../content/content_providers.dart';
import '../player/play.dart';
import '../playlists/playlists_provider.dart';

final _countsProvider = FutureProvider<(int, int, int)>((ref) async {
  final p = ref.watch(activePlaylistProvider);
  if (p == null) return (0, 0, 0);
  final db = ref.watch(databaseProvider);
  // Re-run after an import completes.
  ref.watch(playlistImportProvider);
  return (await db.countChannels(p.id), await db.countMovies(p.id), await db.countSeries(p.id));
});

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final playlist = ref.watch(activePlaylistProvider);
    final counts = ref.watch(_countsProvider).value ?? (0, 0, 0);
    final settings = ref.watch(settingsProvider);
    final theme = Theme.of(context);

    if (playlist == null) {
      return EmptyState(
        icon: Icons.playlist_remove,
        message: l10n.noPlaylistTitle,
        action: FilledButton(onPressed: () => context.go(Routes.noPlaylist), child: Text(l10n.addPlaylist)),
      );
    }

    final account = decodeAccountInfo(playlist.accountInfo);
    final exp = account['exp_date'] != null && account['exp_date'] != 'null' ? DateTime.tryParse(account['exp_date']!) : playlist.expiresAt;

    return Responsive(
      builder: (context, form) => ListView(
        padding: const EdgeInsets.symmetric(vertical: 12),
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(playlist.name, style: theme.textTheme.headlineSmall),
                      if (exp != null)
                        Text(l10n.accountExpires(formatDate(context, exp)), style: theme.textTheme.bodySmall),
                      if (account['max_connections'] != null)
                        Text(l10n.activeConnections(account['active_cons'] ?? '?', account['max_connections']!),
                            style: theme.textTheme.bodySmall),
                    ],
                  ),
                ),
                _Clock(use24h: settings.use24hClock),
                IconButton(
                  tooltip: l10n.changePlaylist,
                  icon: const Icon(Icons.playlist_play),
                  onPressed: () => context.push(Routes.playlists),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: GridView.count(
              crossAxisCount: form.isMobile ? 1 : 3,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              childAspectRatio: form.isMobile ? 4 : 2.2,
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              children: [
                _HubTile(icon: Icons.live_tv, label: l10n.liveTv, count: counts.$1, color: Colors.blue, autofocus: true, onTap: () => context.go(Routes.live)),
                _HubTile(icon: Icons.movie, label: l10n.movies, count: counts.$2, color: Colors.deepOrange, onTap: () => context.go(Routes.movies)),
                _HubTile(icon: Icons.video_library, label: l10n.series, count: counts.$3, color: Colors.purple, onTap: () => context.go(Routes.series)),
              ],
            ),
          ),
          _ContinueWatchingRow(playlistId: playlist.id, form: form),
          _RecentChannelsRow(playlistId: playlist.id),
        ],
      ),
    );
  }
}

class _HubTile extends StatelessWidget {
  const _HubTile({required this.icon, required this.label, required this.count, required this.color, required this.onTap, this.autofocus = false});
  final IconData icon;
  final String label;
  final int count;
  final Color color;
  final VoidCallback onTap;
  final bool autofocus;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return FocusableCard(
      autofocus: autofocus,
      onTap: onTap,
      scale: 1.03,
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(colors: [color.withValues(alpha: 0.85), color.withValues(alpha: 0.45)]),
        ),
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(icon, size: 40, color: Colors.white),
            const SizedBox(width: 16),
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: theme.textTheme.titleLarge?.copyWith(color: Colors.white)),
                Text('$count', style: theme.textTheme.bodyMedium?.copyWith(color: Colors.white70)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _Clock extends StatefulWidget {
  const _Clock({required this.use24h});
  final bool use24h;
  @override
  State<_Clock> createState() => _ClockState();
}

class _ClockState extends State<_Clock> {
  late Timer _timer;
  DateTime _now = DateTime.now();

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 15), (_) => setState(() => _now = DateTime.now()));
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Text(formatTime(context, _now, use24h: widget.use24h), style: Theme.of(context).textTheme.headlineSmall),
    );
  }
}

final _continueProvider = FutureProvider.family<List<(HistoryData, Object)>, String>((ref, playlistId) async {
  final db = ref.watch(databaseProvider);
  final movies = await db.watchHistory(playlistId, ContentKind.vod, limit: 10).first;
  final episodes = await db.watchHistory(playlistId, ContentKind.series, limit: 10).first;
  final items = <(HistoryData, Object)>[];
  for (final h in [...movies, ...episodes]..sort((a, b) => b.watchedAt.compareTo(a.watchedAt))) {
    if (h.durationMs > 0 && h.positionMs >= h.durationMs * 0.95) continue;
    final Object? item = h.kind == ContentKind.vod
        ? await db.getMovie(playlistId, h.itemId)
        : (h.parentId == null ? null : await db.getSeriesItem(playlistId, h.parentId!));
    if (item != null) items.add((h, item));
    if (items.length >= 12) break;
  }
  return items;
});

class _ContinueWatchingRow extends ConsumerWidget {
  const _ContinueWatchingRow({required this.playlistId, required this.form});
  final String playlistId;
  final FormFactor form;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final items = ref.watch(_continueProvider(playlistId)).value ?? const [];
    if (items.isEmpty) return const SizedBox.shrink();
    final height = form.isMobile ? 190.0 : 240.0;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeader(l10n.continueWatching),
        SizedBox(
          height: height,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: items.length,
            separatorBuilder: (_, _) => const SizedBox(width: 12),
            itemBuilder: (context, i) {
              final (h, item) = items[i];
              final progress = h.durationMs > 0 ? h.positionMs / h.durationMs : null;
              if (item is Movie) {
                return SizedBox(
                  width: height * 0.62,
                  child: PosterCard(
                    title: item.name,
                    imageUrl: item.poster,
                    progress: progress,
                    onTap: () => playMovie(context, ref, item),
                    onLongPress: () => context.push(Routes.movie(item.streamId)),
                  ),
                );
              }
              final s = item as SeriesItem;
              return SizedBox(
                width: height * 0.62,
                child: PosterCard(
                  title: s.name,
                  imageUrl: s.cover,
                  progress: progress,
                  onTap: () => context.push(Routes.seriesDetail(s.seriesId)),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _RecentChannelsRow extends ConsumerWidget {
  const _RecentChannelsRow({required this.playlistId});
  final String playlistId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final channels = ref.watch(channelsProvider(ContentQuery(playlistId, ContentKind.live, SpecialCategory.recent))).value ?? const [];
    if (channels.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeader(l10n.recentChannels),
        SizedBox(
          height: 110,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: channels.length,
            separatorBuilder: (_, _) => const SizedBox(width: 12),
            itemBuilder: (context, i) {
              final c = channels[i];
              return SizedBox(
                width: 140,
                child: FocusableCard(
                  onTap: () => playChannels(context, ref, channels, i),
                  child: Container(
                    color: Theme.of(context).colorScheme.surfaceContainer,
                    padding: const EdgeInsets.all(8),
                    child: Column(
                      children: [
                        Expanded(child: AppImage(c.logo, fit: BoxFit.contain, icon: Icons.live_tv)),
                        const SizedBox(height: 4),
                        Text(c.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: Theme.of(context).textTheme.bodySmall),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
