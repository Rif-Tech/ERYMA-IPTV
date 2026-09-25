import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/theme.dart';
import '../../core/db/database.dart';
import '../../core/log/trace_tag.dart';
import '../../l10n/generated/app_localizations.dart';
import '../../widgets/common.dart';
import '../../widgets/format.dart';
import '../content/metadata_providers.dart';
import '../player/play.dart';
import '../playlists/playlists_provider.dart';

final _movieProvider = FutureProvider.family<Movie?, String>((ref, id) {
  final p = ref.watch(activePlaylistProvider);
  if (p == null) return Future.value(null);
  return ref.watch(databaseProvider).getMovie(p.id, id);
});

final _historyProvider = FutureProvider.family<HistoryData?, (ContentKind, String)>((ref, key) {
  final p = ref.watch(activePlaylistProvider);
  if (p == null) return Future.value(null);
  return ref.watch(databaseProvider).getHistory(p.id, key.$1, key.$2);
});

class MovieDetailScreen extends ConsumerWidget {
  const MovieDetailScreen({super.key, required this.streamId});
  final String streamId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final movie = ref.watch(_movieProvider(streamId));
    return Scaffold(
      body: AsyncView(
        value: movie,
        builder: (m) {
          if (m == null) return EmptyState(icon: Icons.movie, message: l10n.noMovies);
          final info = ref.watch(movieInfoProvider(streamId)).value;
          final tmdbId = int.tryParse(info?.tmdbId ?? '');
          // Panel backdrops are often dead links; prefer TMDB art when the panel exposes an id.
          final tmdb = tmdbId == null ? null : ref.watch(tmdbArtProvider(('movie', tmdbId))).value;
          final history = ref.watch(_historyProvider((ContentKind.vod, streamId))).value;
          final playlist = ref.watch(activePlaylistProvider)!;
          final isFav = ref.watch(isFavoriteProvider((playlist.id, ContentKind.vod, streamId))).value ?? false;

          return DetailLayout(
            poster: m.poster,
            backdrop: tmdb?.backdropUrl ?? info?.backdrop,
            title: m.name,
            meta: [
              if (info?.releaseDate != null) info!.releaseDate!.split('-').first,
              if (m.year != null && info?.releaseDate == null) '${m.year}',
              if (info?.genre != null) info!.genre!,
              if (info?.durationSecs != null) formatDuration(Duration(seconds: info!.durationSecs!)),
              if ((info?.rating ?? m.rating) != null && (info?.rating ?? m.rating)! > 0) '★ ${(info?.rating ?? m.rating)!.toStringAsFixed(1)}',
            ],
            badges: [
              if (info?.resolution != null) info!.resolution!,
              if (info?.videoCodec != null) info!.videoCodec!.toUpperCase(),
            ],
            plot: info?.plot,
            facts: {
              if (info?.director != null) l10n.director: info!.director!,
              if (info?.cast != null) l10n.cast: info!.cast!,
            },
            actions: [
              PillButton(
                primary: true,
                autofocus: true,
                icon: Icons.play_arrow_rounded,
                onPressed: () => playMovie(context, ref, m),
                label: history != null && history.positionMs > 0
                    ? l10n.resumeFrom(formatDuration(Duration(milliseconds: history.positionMs)))
                    : l10n.play,
              ),
              if (history != null && history.positionMs > 0)
                PillButton(icon: Icons.replay_rounded, label: l10n.startOver, onPressed: () => playMovie(context, ref, m, resume: false)),
              PillButton(
                icon: isFav ? Icons.check_rounded : Icons.add_rounded,
                label: isFav ? l10n.removeFromFavorites : l10n.addToFavorites,
                onPressed: () => ref.read(databaseProvider).toggleFavorite(playlist.id, ContentKind.vod, streamId),
              ),
              if (info?.youtubeTrailer != null && info!.youtubeTrailer!.isNotEmpty)
                PillButton(icon: Icons.ondemand_video_rounded, label: l10n.watchTrailer, onPressed: () => openTrailer(info.youtubeTrailer!)),
            ],
          );
        },
      ),
    );
  }
}

/// Cinematic detail layout: full-width backdrop fading into black, then title, badges, pills and plot.
class DetailLayout extends StatelessWidget {
  const DetailLayout({
    super.key,
    required this.title,
    required this.actions,
    this.poster,
    this.backdrop,
    this.meta = const [],
    this.badges = const [],
    this.plot,
    this.facts = const {},
    this.below,
  });

  final String title;
  final String? poster;
  final String? backdrop;
  final List<String> meta;

  /// Short technical labels rendered as bordered badges (resolution, codec, "Series").
  final List<String> badges;
  final String? plot;
  final Map<String, String> facts;
  final List<Widget> actions;
  final Widget? below;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final text = theme.textTheme;
    final t = context.tokens;
    final size = MediaQuery.sizeOf(context);
    final top = MediaQuery.paddingOf(context).top;
    final wide = size.width >= 700;
    final g = t.pageGutter;
    final artHeight = wide ? (size.height * 0.58).clamp(320.0, 640.0) : (size.height * 0.42).clamp(240.0, 420.0);

    // Shared by the movie and series screens: the route in the trace tells them apart.
    return TraceTag('detail', child: CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: SizedBox(
            height: artHeight,
            child: Stack(
              fit: StackFit.expand,
              children: [
                BackdropArt(backdrop: backdrop, poster: poster, showPoster: !wide || poster == null),
                const DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      stops: [0, 0.3, 0.7, 1],
                      colors: [Color(0x990A0A0A), Color(0x000A0A0A), Color(0x990A0A0A), Color(0xFF0A0A0A)],
                    ),
                  ),
                ),
                const DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                      stops: [0, 0.6],
                      colors: [Color(0x990A0A0A), Color(0x000A0A0A)],
                    ),
                  ),
                ),
                Positioned(
                  top: top + 8,
                  left: 8,
                  child: TraceTag('back', child: IconButton(
                    onPressed: () => Navigator.of(context).maybePop(),
                    icon: const Icon(Icons.arrow_back_rounded),
                    style: IconButton.styleFrom(backgroundColor: const Color(0x66000000)),
                  )),
                ),
                Positioned(
                  left: g,
                  right: g,
                  bottom: 0,
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      if (wide && poster != null)
                        Padding(
                          padding: const EdgeInsets.only(right: 28),
                          child: SizedBox(
                            width: 170,
                            child: AspectRatio(
                              aspectRatio: 2 / 3,
                              child: ClipRRect(borderRadius: BorderRadius.circular(12), child: AppImage(poster, icon: Icons.movie, decodeWidth: 360)),
                            ),
                          ),
                        ),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(title, maxLines: 2, overflow: TextOverflow.ellipsis, style: wide ? text.displaySmall : text.headlineMedium),
                            const SizedBox(height: 10),
                            Wrap(
                              spacing: 8,
                              runSpacing: 6,
                              crossAxisAlignment: WrapCrossAlignment.center,
                              children: [
                                if (meta.isNotEmpty) Text(meta.join('  ·  '), style: text.bodyMedium?.copyWith(color: t.textMuted)),
                                for (final b in badges) MetaBadge(b),
                              ],
                            ),
                            const SizedBox(height: 18),
                            Wrap(spacing: 10, runSpacing: 10, children: [
                              for (final (i, a) in actions.indexed) TraceTag('actions/$i', child: a),
                            ]),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        SliverPadding(
          // Room for TV overscan so the last row (episodes list on a series) is never clipped.
          padding: EdgeInsets.fromLTRB(g, 24, g, 72 + MediaQuery.paddingOf(context).bottom),
          sliver: SliverList.list(
            children: [
              if (plot != null && plot!.isNotEmpty)
                ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 820),
                  child: Text(plot!, style: text.bodyLarge?.copyWith(color: t.textMuted, height: 1.5)),
                ),
              if (facts.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 20),
                  child: Wrap(
                    spacing: 40,
                    runSpacing: 12,
                    children: [
                      for (final f in facts.entries)
                        ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 380),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(f.key.toUpperCase(), style: text.labelSmall?.copyWith(color: t.textFaint, letterSpacing: 1)),
                              const SizedBox(height: 4),
                              Text(f.value, style: text.bodyMedium),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
              if (below != null) ...[const SizedBox(height: 28), below!],
            ],
          ),
        ),
      ],
    ));
  }
}
