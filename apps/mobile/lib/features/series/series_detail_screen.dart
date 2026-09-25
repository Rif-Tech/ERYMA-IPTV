import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/responsive.dart';
import '../../app/theme.dart';
import '../../core/db/database.dart';
import '../../core/sync/progress_sync.dart';
import '../../l10n/generated/app_localizations.dart';
import '../../widgets/common.dart';
import '../../widgets/format.dart';
import '../content/content_providers.dart';
import '../content/metadata_providers.dart';
import '../movies/movie_detail_screen.dart';
import '../player/play.dart';
import '../playlists/playlists_provider.dart';

final _seriesProvider = FutureProvider.family<SeriesItem?, String>((ref, id) {
  final p = ref.watch(activePlaylistProvider);
  if (p == null) return Future.value(null);
  // Refresh plot once episodes (and series info) were fetched.
  ref.watch(episodesProvider(id));
  return ref.watch(databaseProvider).getSeriesItem(p.id, id);
});

final _seriesHistoryProvider = StreamProvider.family<List<HistoryData>, String>((ref, seriesId) {
  final p = ref.watch(activePlaylistProvider);
  if (p == null) return const Stream.empty();
  return ref.watch(databaseProvider).watchHistory(p.id, ContentKind.series, limit: 500).map(
        (l) => l.where((h) => h.parentId == seriesId).toList(),
      );
});

class _SeasonSelection extends Notifier<int?> {
  @override
  int? build() => null;
  void set(int? v) => state = v;
}

final _seasonProvider = NotifierProvider<_SeasonSelection, int?>(_SeasonSelection.new);

class SeriesDetailScreen extends ConsumerWidget {
  const SeriesDetailScreen({super.key, required this.seriesId});
  final String seriesId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final series = ref.watch(_seriesProvider(seriesId));
    final episodes = ref.watch(episodesProvider(seriesId));
    final history = ref.watch(_seriesHistoryProvider(seriesId)).value ?? const [];
    final playlist = ref.watch(activePlaylistProvider);

    return Scaffold(
      body: AsyncView(
        value: series,
        builder: (s) {
          if (s == null || playlist == null) return EmptyState(icon: Icons.video_library, message: l10n.noSeries);
          final info = ref.watch(seriesInfoProvider(seriesId)).value;
          final isFav = ref.watch(isFavoriteProvider((playlist.id, ContentKind.series, seriesId))).value ?? false;
          final eps = episodes.value ?? const <Episode>[];
          final seasons = eps.map((e) => e.season).toSet().toList()..sort();
          final selectedSeason = ref.watch(_seasonProvider) ?? (seasons.isNotEmpty ? seasons.first : null);
          final visible = eps.where((e) => e.season == selectedSeason).toList();
          final histById = {for (final h in history) h.itemId: h};

          // Resume: the most recently watched, unfinished episode; else the first one.
          HistoryData? last;
          for (final h in history) {
            if (ProgressSync.isCompleted(h.positionMs, h.durationMs)) continue;
            if (last == null || h.watchedAt.isAfter(last.watchedAt)) last = h;
          }
          final resumeIndex = last == null ? -1 : eps.indexWhere((e) => e.episodeId == last!.itemId);
          final resumeEp = resumeIndex >= 0 ? eps[resumeIndex] : null;

          return DetailLayout(
            poster: s.cover,
            backdrop: info?.backdrop,
            title: s.name,
            meta: [
              if (s.year != null) '${s.year}',
              if (info?.genre != null) info!.genre!,
              if (seasons.isNotEmpty) l10n.seasonsCount(seasons.length),
              if (s.rating != null && s.rating! > 0) '★ ${s.rating!.toStringAsFixed(1)}',
            ],
            badges: [l10n.series],
            plot: s.plot ?? info?.plot,
            facts: {
              if (info?.director != null) l10n.director: info!.director!,
              if (info?.cast != null) l10n.cast: info!.cast!,
            },
            actions: [
              if (eps.isNotEmpty)
                PillButton(
                  primary: true,
                  autofocus: true,
                  icon: Icons.play_arrow_rounded,
                  onPressed: () => playEpisodes(context, ref, eps, resumeIndex >= 0 ? resumeIndex : 0, seriesName: s.name),
                  label: resumeEp != null ? '${l10n.resume} · S${resumeEp.season} E${resumeEp.episodeNum}' : l10n.play,
                ),
              PillButton(
                icon: isFav ? Icons.check_rounded : Icons.add_rounded,
                label: isFav ? l10n.removeFromFavorites : l10n.addToFavorites,
                onPressed: () => ref.read(databaseProvider).toggleFavorite(playlist.id, ContentKind.series, seriesId),
              ),
              if (info?.youtubeTrailer != null && info!.youtubeTrailer!.isNotEmpty)
                PillButton(icon: Icons.ondemand_video_rounded, label: l10n.watchTrailer, onPressed: () => openTrailer(info.youtubeTrailer!)),
            ],
            below: Responsive(
              builder: (context, form) => Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (episodes.isLoading) const Padding(padding: EdgeInsets.only(bottom: 12), child: LinearProgressIndicator()),
                  if (episodes.hasError) Text(l10n.importFailed, style: TextStyle(color: Theme.of(context).colorScheme.error)),
                  Row(
                    children: [
                      Text(l10n.episodesTitle, style: Theme.of(context).textTheme.titleMedium),
                      const Spacer(),
                      if (seasons.length > 1)
                        Flexible(
                          child: SizedBox(
                            height: 40,
                            child: ListView.separated(
                              scrollDirection: Axis.horizontal,
                              reverse: true,
                              shrinkWrap: true,
                              itemCount: seasons.length,
                              separatorBuilder: (_, _) => const SizedBox(width: 8),
                              itemBuilder: (context, i) {
                                final season = seasons[seasons.length - 1 - i];
                                return ChoiceChip(
                                  label: Text(l10n.season(season)),
                                  selected: season == selectedSeason,
                                  onSelected: (_) => ref.read(_seasonProvider.notifier).set(season),
                                );
                              },
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  if (eps.isEmpty && !episodes.isLoading) Text(l10n.noEpisodes),
                  if (form.isMobile)
                    for (final e in visible)
                      _EpisodeTile(
                        episode: e,
                        history: histById[e.episodeId],
                        onTap: () => playEpisodes(context, ref, eps, eps.indexOf(e), seriesName: s.name),
                      )
                  else
                    _EpisodeShelf(
                      episodes: visible,
                      history: histById,
                      fallbackImage: s.cover,
                      onTap: (e) => playEpisodes(context, ref, eps, eps.indexOf(e), seriesName: s.name),
                    ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

/// Horizontal 16:9 episode cards (tablet/TV).
class _EpisodeShelf extends StatelessWidget {
  const _EpisodeShelf({required this.episodes, required this.history, required this.onTap, this.fallbackImage});
  final List<Episode> episodes;
  final Map<String, HistoryData> history;
  final ValueChanged<Episode> onTap;
  final String? fallbackImage;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    const w = 300.0;
    const gap = 16.0;
    return SizedBox(
      height: w * 9 / 16 + 24,
      child: FocusTraversalGroup(
        child: ListView.builder(
          scrollDirection: Axis.horizontal,
          clipBehavior: Clip.none,
          padding: const EdgeInsets.symmetric(vertical: 12),
          itemCount: episodes.length,
          itemExtent: w + gap,
          addAutomaticKeepAlives: false,
          itemBuilder: (context, i) {
            final e = episodes[i];
            final h = history[e.episodeId];
            final progress = h != null && h.durationMs > 0 ? h.positionMs / h.durationMs : null;
            return Padding(
              padding: const EdgeInsets.only(right: gap),
              child: LandscapeCard(
                title: e.title,
                overline: l10n.episodeNumber(e.episodeNum),
                subtitle: [
                  if (e.durationSecs != null) formatDuration(Duration(seconds: e.durationSecs!)),
                  if (e.resolution != null) e.resolution!,
                ].join('  ·  '),
                imageUrl: AppImage.isValid(e.poster) ? e.poster : fallbackImage,
                icon: Icons.play_circle_outline_rounded,
                progress: progress,
                onTap: () => onTap(e),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _EpisodeTile extends StatelessWidget {
  const _EpisodeTile({required this.episode, required this.onTap, this.history});
  final Episode episode;
  final HistoryData? history;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final progress = history != null && history!.durationMs > 0 ? history!.positionMs / history!.durationMs : null;
    final t = context.tokens;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: FocusableCard(
        scale: 1.01,
        onTap: onTap,
        child: GlassPanel(
          radius: 12,
          padding: const EdgeInsets.all(10),
          child: Row(
            children: [
              SizedBox(
                width: 128,
                height: 72,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      AppImage(episode.poster, icon: Icons.play_circle_outline_rounded, decodeWidth: 300),
                      if (progress != null) Positioned(left: 0, right: 0, bottom: 0, child: ProgressStrip(progress)),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(l10n.episodeNumber(episode.episodeNum), style: theme.textTheme.labelSmall?.copyWith(color: t.textFaint)),
                    Text(episode.title, maxLines: 1, overflow: TextOverflow.ellipsis, style: theme.textTheme.titleSmall),
                    if (episode.durationSecs != null || episode.resolution != null)
                      Text(
                        [
                          if (episode.durationSecs != null) formatDuration(Duration(seconds: episode.durationSecs!)),
                          if (episode.resolution != null) episode.resolution!,
                        ].join('  ·  '),
                        style: theme.textTheme.bodySmall,
                      ),
                    if (episode.plot != null)
                      Text(episode.plot!, maxLines: 2, overflow: TextOverflow.ellipsis, style: theme.textTheme.bodySmall),
                  ],
                ),
              ),
              Icon(Icons.play_arrow_rounded, color: t.textMuted),
            ],
          ),
        ),
      ),
    );
  }
}
