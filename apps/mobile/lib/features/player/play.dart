import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../app/router.dart';
import '../../core/db/database.dart';
import '../../core/player/playback.dart';
import '../../core/settings/settings.dart';
import '../../l10n/generated/app_localizations.dart';
import '../../widgets/pin_dialog.dart';
import '../content/content_providers.dart';
import '../home/featured_provider.dart';
import '../movies/movie_detail_screen.dart' show movieInfoProvider;
import '../playlists/playlists_provider.dart';

/// Resolver bound to the active playlist and current settings.
final streamResolverProvider = Provider<StreamResolver?>((ref) {
  final p = ref.watch(activePlaylistProvider);
  if (p == null) return null;
  return StreamResolver(p, ref.watch(settingsProvider));
});

Future<void> openPlayer(BuildContext context, PlaybackRequest request) =>
    context.push(Routes.player, extra: request);

/// Xtream panels store either a YouTube id or a full URL.
Future<void> openTrailer(String trailer) {
  final url = trailer.startsWith('http') ? trailer : 'https://www.youtube.com/watch?v=$trailer';
  return launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
}

/// Plays [channels] starting at [index]; asks for the parental PIN when the channel is locked.
Future<void> playChannels(BuildContext context, WidgetRef ref, List<Channel> channels, int index) async {
  final resolver = ref.read(streamResolverProvider);
  if (resolver == null) return;
  final locked = ref.read(lockedChannelsProvider(resolver.playlist.id)).value ?? const {};
  if (locked.contains(channels[index].streamId)) {
    final l10n = AppLocalizations.of(context);
    final ok = await requirePin(context, ref.read(settingsProvider).parentalPin, title: l10n.channelLocked);
    if (!ok || !context.mounted) return;
  }
  // Locked channels are skipped while zapping.
  final playable = <Channel>[];
  var startIndex = 0;
  for (final (i, c) in channels.indexed) {
    if (locked.contains(c.streamId) && i != index) continue;
    if (i == index) startIndex = playable.length;
    playable.add(c);
  }
  reportWatch(ref, kind: 'live', title: channels[index].name);
  await openPlayer(context, PlaybackRequest(items: playable.map(resolver.channel).toList(), startIndex: startIndex));
}

Future<void> playMovie(BuildContext context, WidgetRef ref, Movie movie, {bool resume = true}) async {
  final resolver = ref.read(streamResolverProvider);
  if (resolver == null) return;
  int? position;
  if (resume) {
    final h = await ref.read(databaseProvider).getHistory(resolver.playlist.id, ContentKind.vod, movie.streamId);
    if (h != null && h.positionMs > 0 && (h.durationMs == 0 || h.positionMs < h.durationMs * 0.95)) {
      position = h.positionMs;
    }
  }
  if (!context.mounted) return;
  // Panel info is only used when already cached; never delay playback for it.
  final tmdb = int.tryParse(ref.read(movieInfoProvider(movie.streamId)).value?.tmdbId ?? '');
  reportWatch(ref, kind: 'movie', title: movie.name, year: movie.year, tmdbId: tmdb);
  await openPlayer(context, PlaybackRequest(items: [resolver.movie(movie)], startPositionMs: position));
}

Future<void> playEpisodes(
  BuildContext context,
  WidgetRef ref,
  List<Episode> episodes,
  int index, {
  required String seriesName,
  bool resume = true,
}) async {
  final resolver = ref.read(streamResolverProvider);
  if (resolver == null) return;
  int? position;
  if (resume) {
    final h = await ref.read(databaseProvider).getHistory(resolver.playlist.id, ContentKind.series, episodes[index].episodeId);
    if (h != null && h.positionMs > 0 && (h.durationMs == 0 || h.positionMs < h.durationMs * 0.95)) {
      position = h.positionMs;
    }
  }
  if (!context.mounted) return;
  reportWatch(ref, kind: 'tv', title: seriesName);
  await openPlayer(
    context,
    PlaybackRequest(
      items: episodes.map((e) => resolver.episode(e, seriesName: seriesName)).toList(),
      startIndex: index,
      startPositionMs: position,
    ),
  );
}
