import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../app/router.dart';
import '../../core/db/database.dart';
import '../../core/log/app_logger.dart';
import '../../core/player/playback.dart';
import '../../core/settings/settings.dart';
import '../../core/sync/progress_sync.dart';
import '../../l10n/generated/app_localizations.dart';
import '../../widgets/pin_dialog.dart';
import '../content/content_providers.dart';
import '../content/metadata_providers.dart';
import '../home/featured_provider.dart';
import '../playlists/playlists_provider.dart';

/// Resolver bound to the active playlist and current settings.
final streamResolverProvider = Provider<StreamResolver?>((ref) {
  final p = ref.watch(activePlaylistProvider);
  if (p == null) return null;
  return StreamResolver(p, ref.watch(settingsProvider));
});

DateTime? _lastPlayerPush;

/// A held OK key repeats the activation, and playMovie/playEpisodes both await a DB read before
/// this runs: two of those activations landing close together pushed two `/player` routes, each
/// with its own mpv instance — its overlay controls briefly doubled up on screen (Sentry: reported
/// from the app, VOD open). 700 ms is far longer than a double activation but short enough to never
/// hold up an intentional next push (a different title tapped right after).
Future<void> openPlayer(BuildContext context, PlaybackRequest request) {
  final now = DateTime.now();
  if (_lastPlayerPush != null && now.difference(_lastPlayerPush!) < const Duration(milliseconds: 700)) {
    return Future.value();
  }
  _lastPlayerPush = now;
  return context.push(Routes.player, extra: request);
}

/// Xtream panels store either a YouTube id or a full URL.
Future<void> openTrailer(String trailer) {
  final url = trailer.startsWith('http') ? trailer : 'https://www.youtube.com/watch?v=$trailer';
  return launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
}

/// Reports a failure that would otherwise leave the OK press looking entirely ignored (a DB read
/// or navigation throwing between the button and the player actually opening). Logged (not just
/// shown) so a pattern of failures is visible without the user reporting it by hand.
void _reportPlaybackFailure(BuildContext context, WidgetRef ref, {String reason = 'unknown', Object? error}) {
  ref.read(appLoggerProvider).error('playback', 'could not start playback ($reason)', context: error == null ? null : {'error': '$error'});
  if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(AppLocalizations.of(context).playbackError)));
}

/// Plays [channels] starting at [index]; asks for the parental PIN when the channel is locked.
Future<void> playChannels(BuildContext context, WidgetRef ref, List<Channel> channels, int index) async {
  try {
    final resolver = ref.read(streamResolverProvider);
    if (resolver == null) return _reportPlaybackFailure(context, ref, reason: 'no resolver');
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
  } catch (e) {
    // _reportPlaybackFailure itself checks context.mounted before touching it; the analyzer
    // cannot see that across the function boundary.
    // ignore: use_build_context_synchronously
    _reportPlaybackFailure(context, ref, reason: 'channels', error: e);
  }
}

Future<void> playMovie(BuildContext context, WidgetRef ref, Movie movie, {bool resume = true}) async {
  try {
    final resolver = ref.read(streamResolverProvider);
    if (resolver == null) return _reportPlaybackFailure(context, ref, reason: 'no resolver');
    int? position;
    if (resume) {
      final h = await ref.read(databaseProvider).getHistory(resolver.playlist.id, ContentKind.vod, movie.streamId);
      if (h != null && h.positionMs > 0 && !ProgressSync.isCompleted(h.positionMs, h.durationMs)) {
        position = h.positionMs;
      }
    }
    if (!context.mounted) return;
    // Panel info is only used when already cached; never delay playback for it.
    final tmdb = int.tryParse(ref.read(movieInfoProvider(movie.streamId)).value?.tmdbId ?? '');
    reportWatch(ref, kind: 'movie', title: movie.name, year: movie.year, tmdbId: tmdb);
    await openPlayer(context, PlaybackRequest(items: [resolver.movie(movie)], startPositionMs: position));
  } catch (e) {
    // ignore: use_build_context_synchronously
    _reportPlaybackFailure(context, ref, reason: 'movie', error: e);
  }
}

Future<void> playEpisodes(
  BuildContext context,
  WidgetRef ref,
  List<Episode> episodes,
  int index, {
  required String seriesName,
  bool resume = true,
}) async {
  try {
    final resolver = ref.read(streamResolverProvider);
    if (resolver == null) return _reportPlaybackFailure(context, ref, reason: 'no resolver');
    int? position;
    if (resume) {
      final h = await ref.read(databaseProvider).getHistory(resolver.playlist.id, ContentKind.series, episodes[index].episodeId);
      if (h != null && h.positionMs > 0 && !ProgressSync.isCompleted(h.positionMs, h.durationMs)) {
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
  } catch (e) {
    // ignore: use_build_context_synchronously
    _reportPlaybackFailure(context, ref, reason: 'episodes', error: e);
  }
}
