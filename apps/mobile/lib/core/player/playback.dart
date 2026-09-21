import 'package:flutter/foundation.dart';

import '../db/database.dart';
import '../settings/settings.dart';
import '../xtream/xtream_client.dart';

@immutable
class PlayableItem {
  const PlayableItem({
    required this.id,
    required this.kind,
    required this.title,
    required this.url,
    this.subtitle,
    this.logo,
    this.epgChannelId,
    this.parentId,
    this.tvArchive = false,
  });

  final String id;
  final ContentKind kind;
  final String title;
  final String url;
  final String? subtitle;
  final String? logo;
  final String? epgChannelId;

  /// Series id for episodes.
  final String? parentId;
  final bool tvArchive;
}

@immutable
class PlaybackRequest {
  const PlaybackRequest({required this.items, this.startIndex = 0, this.startPositionMs});
  final List<PlayableItem> items;
  final int startIndex;
  final int? startPositionMs;

  PlayableItem get current => items[startIndex];
}

/// Builds playable URLs from database rows for either playlist type.
class StreamResolver {
  const StreamResolver(this.playlist, this.settings);
  final Playlist playlist;
  final AppSettings settings;

  XtreamCredentials? get _creds => playlist.type == PlaylistType.xtream
      ? XtreamCredentials(baseUrl: playlist.url, username: playlist.username ?? '', password: playlist.password ?? '')
      : null;

  PlayableItem channel(Channel c) {
    final creds = _creds;
    final url = c.streamUrl.isNotEmpty
        ? c.streamUrl
        : creds?.liveUrl(c.streamId, extension: settings.liveFormat == LiveFormat.m3u8 ? 'm3u8' : 'ts') ?? '';
    return PlayableItem(
      id: c.streamId,
      kind: ContentKind.live,
      title: c.name,
      url: url,
      logo: c.logo,
      epgChannelId: c.epgChannelId,
      tvArchive: c.tvArchive,
    );
  }

  PlayableItem movie(Movie m) {
    final url = m.streamUrl.isNotEmpty ? m.streamUrl : _creds?.movieUrl(m.streamId, m.containerExtension) ?? '';
    return PlayableItem(id: m.streamId, kind: ContentKind.vod, title: m.name, url: url, logo: m.poster);
  }

  PlayableItem episode(Episode e, {String? seriesName}) {
    final url = e.streamUrl.isNotEmpty ? e.streamUrl : _creds?.seriesUrl(e.episodeId, e.containerExtension) ?? '';
    return PlayableItem(
      id: e.episodeId,
      kind: ContentKind.series,
      title: seriesName ?? e.title,
      subtitle: 'S${e.season.toString().padLeft(2, '0')}E${e.episodeNum.toString().padLeft(2, '0')} · ${e.title}',
      url: url,
      logo: e.poster,
      parentId: e.seriesId,
    );
  }

  /// Catch-up URL for an archived programme (Xtream only).
  PlayableItem? catchup(Channel c, EpgProgram program) {
    final creds = _creds;
    if (creds == null) return null;
    final minutes = program.end.difference(program.start).inMinutes;
    return PlayableItem(
      id: '${c.streamId}@${program.start.millisecondsSinceEpoch}',
      kind: ContentKind.live,
      title: c.name,
      subtitle: program.title,
      url: creds.timeshiftUrl(c.streamId, program.start, minutes <= 0 ? 60 : minutes),
      logo: c.logo,
    );
  }
}
