import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/db/database.dart';
import '../../core/xtream/xtream_client.dart';
import '../../l10n/generated/app_localizations.dart';
import '../../widgets/common.dart';
import '../../widgets/format.dart';
import '../player/play.dart';
import '../playlists/playlists_provider.dart';

final _movieProvider = FutureProvider.family<Movie?, String>((ref, id) {
  final p = ref.watch(activePlaylistProvider);
  if (p == null) return Future.value(null);
  return ref.watch(databaseProvider).getMovie(p.id, id);
});

/// Extended metadata, fetched from the Xtream panel on demand.
final movieInfoProvider = FutureProvider.family<XtreamVodInfo?, String>((ref, id) async {
  final p = ref.watch(activePlaylistProvider);
  if (p == null || p.type != PlaylistType.xtream) return null;
  final client = XtreamClient(XtreamCredentials(baseUrl: p.url, username: p.username ?? '', password: p.password ?? ''));
  try {
    return await client.vodInfo(id);
  } catch (_) {
    return null;
  }
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
      appBar: AppBar(title: Text(movie.value?.name ?? '')),
      body: AsyncView(
        value: movie,
        builder: (m) {
          if (m == null) return EmptyState(icon: Icons.movie, message: l10n.noMovies);
          final info = ref.watch(movieInfoProvider(streamId)).value;
          final history = ref.watch(_historyProvider((ContentKind.vod, streamId))).value;
          final playlist = ref.watch(activePlaylistProvider)!;
          final isFav = ref.watch(_favProvider((playlist.id, ContentKind.vod, streamId))).value ?? false;

          return DetailLayout(
            poster: m.poster,
            backdrop: info?.backdrop,
            title: m.name,
            meta: [
              if (info?.releaseDate != null) info!.releaseDate!,
              if (m.year != null && info?.releaseDate == null) '${m.year}',
              if (info?.genre != null) info!.genre!,
              if (info?.durationSecs != null) formatDuration(Duration(seconds: info!.durationSecs!)),
              if (info?.resolution != null) info!.resolution!,
              if (info?.videoCodec != null) info!.videoCodec!.toUpperCase(),
              if ((info?.rating ?? m.rating) != null) '★ ${(info?.rating ?? m.rating)!.toStringAsFixed(1)}',
            ],
            plot: info?.plot,
            facts: {
              if (info?.director != null) l10n.director: info!.director!,
              if (info?.cast != null) l10n.cast: info!.cast!,
            },
            actions: [
              FilledButton.icon(
                autofocus: true,
                onPressed: () => playMovie(context, ref, m),
                icon: const Icon(Icons.play_arrow),
                label: Text(history != null && history.positionMs > 0
                    ? l10n.resumeFrom(formatDuration(Duration(milliseconds: history.positionMs)))
                    : l10n.play),
              ),
              if (history != null && history.positionMs > 0)
                OutlinedButton.icon(
                  onPressed: () => playMovie(context, ref, m, resume: false),
                  icon: const Icon(Icons.replay),
                  label: Text(l10n.startOver),
                ),
              OutlinedButton.icon(
                onPressed: () => ref.read(databaseProvider).toggleFavorite(playlist.id, ContentKind.vod, streamId),
                icon: Icon(isFav ? Icons.star : Icons.star_border),
                label: Text(isFav ? l10n.removeFromFavorites : l10n.addToFavorites),
              ),
              if (info?.youtubeTrailer != null && info!.youtubeTrailer!.isNotEmpty)
                OutlinedButton.icon(
                  onPressed: () => openTrailer(info.youtubeTrailer!),
                  icon: const Icon(Icons.ondemand_video),
                  label: Text(l10n.watchTrailer),
                ),
            ],
          );
        },
      ),
    );
  }
}

final _favProvider = StreamProvider.family<bool, (String, ContentKind, String)>((ref, key) {
  return ref.watch(databaseProvider).watchIsFavorite(key.$1, key.$2, key.$3);
});

/// Poster + metadata layout shared by movie and series details; adapts to width.
class DetailLayout extends StatelessWidget {
  const DetailLayout({
    super.key,
    required this.title,
    required this.actions,
    this.poster,
    this.backdrop,
    this.meta = const [],
    this.plot,
    this.facts = const {},
    this.below,
  });

  final String title;
  final String? poster;
  final String? backdrop;
  final List<String> meta;
  final String? plot;
  final Map<String, String> facts;
  final List<Widget> actions;
  final Widget? below;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return LayoutBuilder(
      builder: (context, constraints) {
        final wide = constraints.maxWidth >= 700;
        final posterWidget = SizedBox(
          width: wide ? 220 : 140,
          child: AspectRatio(
            aspectRatio: 2 / 3,
            child: ClipRRect(borderRadius: BorderRadius.circular(12), child: AppImage(poster, icon: Icons.movie)),
          ),
        );
        final details = Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: wide ? theme.textTheme.headlineMedium : theme.textTheme.headlineSmall),
            if (meta.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Text(meta.join('  ·  '), style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
              ),
            const SizedBox(height: 16),
            Wrap(spacing: 8, runSpacing: 8, children: actions),
            if (plot != null && plot!.isNotEmpty) ...[
              const SizedBox(height: 16),
              Text(plot!, style: theme.textTheme.bodyLarge),
            ],
            for (final f in facts.entries)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text.rich(TextSpan(children: [
                  TextSpan(text: '${f.key}: ', style: const TextStyle(fontWeight: FontWeight.bold)),
                  TextSpan(text: f.value),
                ])),
              ),
          ],
        );

        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            if (backdrop != null && wide)
              Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: SizedBox(height: 220, child: AppImage(backdrop, icon: Icons.image)),
                ),
              ),
            if (wide)
              Row(crossAxisAlignment: CrossAxisAlignment.start, children: [posterWidget, const SizedBox(width: 24), Expanded(child: details)])
            else
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Center(child: posterWidget), const SizedBox(height: 16), details]),
            if (below != null) ...[const SizedBox(height: 24), below!],
          ],
        );
      },
    );
  }
}
