import 'dart:convert';

import 'package:flutter/foundation.dart';

// JSON models of the Xtream Codes API (player_api.php) and the loose accessors that read them.
// Re-exported by xtream_client.dart, so importers of the client get them too.

/// Loose JSON helpers: Xtream panels return numbers as strings and vice-versa.
String jStr(dynamic v, [String fallback = '']) => v == null ? fallback : v.toString();
String? jStrOrNull(dynamic v) => (v == null || v.toString().isEmpty) ? null : v.toString();
int jInt(dynamic v, [int fallback = 0]) {
  if (v == null) return fallback;
  if (v is int) return v;
  if (v is double) return v.toInt();
  return int.tryParse(v.toString()) ?? double.tryParse(v.toString())?.toInt() ?? fallback;
}

double? jDouble(dynamic v) {
  if (v == null) return null;
  if (v is num) return v.toDouble();
  return double.tryParse(v.toString());
}

bool jBool(dynamic v) {
  if (v == null) return false;
  if (v is bool) return v;
  final s = v.toString().toLowerCase();
  return s == '1' || s == 'true' || s == 'yes';
}

DateTime? jUnix(dynamic v) {
  final secs = jInt(v, -1);
  if (secs <= 0) return null;
  return DateTime.fromMillisecondsSinceEpoch(secs * 1000);
}

// ---------------------------------------------------------------------------

@immutable
class XtreamAccount {
  const XtreamAccount({
    required this.authenticated,
    required this.status,
    this.expiresAt,
    this.isTrial = false,
    this.activeConnections = 0,
    this.maxConnections = 0,
    this.allowedOutputFormats = const [],
    this.serverTimezone,
    this.raw = const {},
  });

  final bool authenticated;
  final String status;
  final DateTime? expiresAt;
  final bool isTrial;
  final int activeConnections;
  final int maxConnections;
  final List<String> allowedOutputFormats;
  final String? serverTimezone;
  final Map<String, dynamic> raw;

  bool get isExpired => expiresAt != null && expiresAt!.isBefore(DateTime.now());

  factory XtreamAccount.fromJson(Map<String, dynamic> json) {
    final user = (json['user_info'] as Map?)?.cast<String, dynamic>() ?? const {};
    final server = (json['server_info'] as Map?)?.cast<String, dynamic>() ?? const {};
    return XtreamAccount(
      authenticated: jInt(user['auth']) == 1 || jBool(user['auth']),
      status: jStr(user['status'], 'Unknown'),
      expiresAt: jUnix(user['exp_date']),
      isTrial: jBool(user['is_trial']),
      activeConnections: jInt(user['active_cons']),
      maxConnections: jInt(user['max_connections']),
      allowedOutputFormats: (user['allowed_output_formats'] as List?)?.map((e) => e.toString()).toList() ?? const [],
      serverTimezone: jStrOrNull(server['timezone']),
      raw: {'user_info': user, 'server_info': server},
    );
  }
}

@immutable
class XtreamCategory {
  const XtreamCategory({required this.id, required this.name, this.parentId = 0});
  final String id;
  final String name;
  final int parentId;

  factory XtreamCategory.fromJson(Map<String, dynamic> j) => XtreamCategory(
        id: jStr(j['category_id']),
        name: jStr(j['category_name']),
        parentId: jInt(j['parent_id']),
      );
}

@immutable
class XtreamLiveStream {
  const XtreamLiveStream({
    required this.streamId,
    required this.name,
    this.icon,
    this.categoryId,
    this.epgChannelId,
    this.number,
    this.tvArchive = false,
    this.tvArchiveDuration = 0,
    this.addedAt,
  });
  final String streamId;
  final String name;
  final String? icon;
  final String? categoryId;
  final String? epgChannelId;
  final int? number;
  final bool tvArchive;
  final int tvArchiveDuration;
  final DateTime? addedAt;

  factory XtreamLiveStream.fromJson(Map<String, dynamic> j) => XtreamLiveStream(
        streamId: jStr(j['stream_id']),
        name: jStr(j['name']),
        icon: jStrOrNull(j['stream_icon']),
        categoryId: jStrOrNull(j['category_id']),
        epgChannelId: jStrOrNull(j['epg_channel_id']),
        number: j['num'] == null ? null : jInt(j['num']),
        tvArchive: jBool(j['tv_archive']),
        tvArchiveDuration: jInt(j['tv_archive_duration']),
        addedAt: jUnix(j['added']),
      );
}

@immutable
class XtreamVodStream {
  const XtreamVodStream({
    required this.streamId,
    required this.name,
    this.icon,
    this.categoryId,
    this.containerExtension,
    this.rating,
    this.year,
    this.addedAt,
  });
  final String streamId;
  final String name;
  final String? icon;
  final String? categoryId;
  final String? containerExtension;
  final double? rating;
  final int? year;
  final DateTime? addedAt;

  factory XtreamVodStream.fromJson(Map<String, dynamic> j) => XtreamVodStream(
        streamId: jStr(j['stream_id']),
        name: jStr(j['name']),
        icon: jStrOrNull(j['stream_icon']),
        categoryId: jStrOrNull(j['category_id']),
        containerExtension: jStrOrNull(j['container_extension']),
        rating: jDouble(j['rating']) ?? jDouble(j['rating_5based']),
        year: _yearOf(j['year'] ?? j['releaseDate'] ?? j['release_date']),
        addedAt: jUnix(j['added']),
      );
}

/// `info.video` is an ffprobe-like stream object; returns `1920×1080` or null.
String? resolutionOf(dynamic video) {
  if (video is! Map) return null;
  final w = jInt(video['width']);
  final h = jInt(video['height']);
  return w > 0 && h > 0 ? '$w×$h' : null;
}

@immutable
class XtreamVodInfo {
  const XtreamVodInfo({
    this.plot,
    this.cast,
    this.director,
    this.genre,
    this.releaseDate,
    this.durationSecs,
    this.rating,
    this.backdrop,
    this.youtubeTrailer,
    this.tmdbId,
    this.containerExtension,
    this.resolution,
    this.videoCodec,
    this.bitrate,
  });
  final String? plot;
  final String? cast;
  final String? director;
  final String? genre;
  final String? releaseDate;
  final int? durationSecs;
  final double? rating;
  final String? backdrop;
  final String? youtubeTrailer;
  final String? tmdbId;
  final String? containerExtension;
  final String? resolution;
  final String? videoCodec;
  final int? bitrate;

  factory XtreamVodInfo.fromJson(Map<String, dynamic> j) {
    final info = (j['info'] as Map?)?.cast<String, dynamic>() ?? const {};
    final movie = (j['movie_data'] as Map?)?.cast<String, dynamic>() ?? const {};
    final backdrops = info['backdrop_path'];
    final video = info['video'];
    return XtreamVodInfo(
      plot: jStrOrNull(info['plot'] ?? info['description']),
      cast: jStrOrNull(info['cast'] ?? info['actors']),
      director: jStrOrNull(info['director']),
      genre: jStrOrNull(info['genre']),
      releaseDate: jStrOrNull(info['releasedate'] ?? info['release_date']),
      durationSecs: info['duration_secs'] == null ? null : jInt(info['duration_secs']),
      rating: jDouble(info['rating']),
      backdrop: backdrops is List && backdrops.isNotEmpty ? backdrops.first.toString() : jStrOrNull(backdrops),
      youtubeTrailer: jStrOrNull(info['youtube_trailer']),
      tmdbId: jStrOrNull(info['tmdb_id']),
      containerExtension: jStrOrNull(movie['container_extension']),
      resolution: resolutionOf(video),
      videoCodec: video is Map ? jStrOrNull(video['codec_name']) : null,
      bitrate: info['bitrate'] == null ? null : jInt(info['bitrate']),
    );
  }
}

@immutable
class XtreamSeries {
  const XtreamSeries({
    required this.seriesId,
    required this.name,
    this.cover,
    this.categoryId,
    this.plot,
    this.rating,
    this.year,
    this.lastModified,
  });
  final String seriesId;
  final String name;
  final String? cover;
  final String? categoryId;
  final String? plot;
  final double? rating;
  final int? year;
  final DateTime? lastModified;

  factory XtreamSeries.fromJson(Map<String, dynamic> j) => XtreamSeries(
        seriesId: jStr(j['series_id']),
        name: jStr(j['name']),
        cover: jStrOrNull(j['cover']),
        categoryId: jStrOrNull(j['category_id']),
        plot: jStrOrNull(j['plot']),
        rating: jDouble(j['rating']) ?? jDouble(j['rating_5based']),
        year: _yearOf(j['year'] ?? j['releaseDate'] ?? j['release_date']),
        lastModified: jUnix(j['last_modified']),
      );
}

@immutable
class XtreamEpisode {
  const XtreamEpisode({
    required this.id,
    required this.season,
    required this.episodeNum,
    required this.title,
    this.containerExtension,
    this.poster,
    this.durationSecs,
    this.plot,
    this.resolution,
  });
  final String id;
  final int season;
  final int episodeNum;
  final String title;
  final String? containerExtension;
  final String? poster;
  final int? durationSecs;
  final String? plot;
  final String? resolution;
}

@immutable
class XtreamSeriesInfo {
  const XtreamSeriesInfo({
    required this.episodes,
    this.plot,
    this.cast,
    this.director,
    this.genre,
    this.youtubeTrailer,
    this.backdrop,
    this.releaseDate,
    this.rating,
  });
  final List<XtreamEpisode> episodes;
  final String? plot;
  final String? cast;
  final String? director;
  final String? genre;
  final String? youtubeTrailer;
  final String? backdrop;
  final String? releaseDate;
  final double? rating;

  factory XtreamSeriesInfo.fromJson(Map<String, dynamic> j) {
    final info = (j['info'] as Map?)?.cast<String, dynamic>() ?? const {};
    final episodes = <XtreamEpisode>[];
    final eps = j['episodes'];
    // Panels return either {"1": [..], "2": [..]} or [[..], [..]].
    final seasons = eps is Map ? eps.entries.map((e) => (e.key.toString(), e.value)) : eps is List ? eps.indexed.map((e) => ('${e.$1 + 1}', e.$2)) : const <(String, dynamic)>[];
    for (final (seasonKey, list) in seasons) {
      if (list is! List) continue;
      for (final raw in list) {
        if (raw is! Map) continue;
        final e = raw.cast<String, dynamic>();
        final ei = (e['info'] as Map?)?.cast<String, dynamic>() ?? const {};
        episodes.add(XtreamEpisode(
          id: jStr(e['id']),
          season: jInt(e['season'], jInt(seasonKey)),
          episodeNum: jInt(e['episode_num']),
          title: jStr(e['title'], 'Episode ${jStr(e['episode_num'])}'),
          containerExtension: jStrOrNull(e['container_extension']),
          poster: jStrOrNull(ei['movie_image'] ?? ei['cover_big']),
          durationSecs: ei['duration_secs'] == null ? null : jInt(ei['duration_secs']),
          plot: jStrOrNull(ei['plot']),
          resolution: resolutionOf(ei['video']),
        ));
      }
    }
    episodes.sort((a, b) => a.season != b.season ? a.season.compareTo(b.season) : a.episodeNum.compareTo(b.episodeNum));
    final backdrops = info['backdrop_path'];
    return XtreamSeriesInfo(
      episodes: episodes,
      plot: jStrOrNull(info['plot']),
      cast: jStrOrNull(info['cast']),
      director: jStrOrNull(info['director']),
      genre: jStrOrNull(info['genre']),
      youtubeTrailer: jStrOrNull(info['youtube_trailer']),
      backdrop: backdrops is List && backdrops.isNotEmpty ? backdrops.first.toString() : jStrOrNull(backdrops),
      releaseDate: jStrOrNull(info['releaseDate'] ?? info['release_date']),
      rating: info['rating'] == null ? null : double.tryParse(info['rating'].toString()),
    );
  }
}

@immutable
class XtreamEpgEntry {
  const XtreamEpgEntry({required this.title, required this.description, required this.start, required this.end, this.hasArchive = false});
  final String title;
  final String description;
  final DateTime start;
  final DateTime end;
  final bool hasArchive;

  factory XtreamEpgEntry.fromJson(Map<String, dynamic> j) {
    String decode(dynamic v) {
      final s = jStr(v);
      try {
        return utf8.decode(base64Decode(s), allowMalformed: true);
      } catch (_) {
        return s;
      }
    }

    return XtreamEpgEntry(
      title: decode(j['title']),
      description: decode(j['description']),
      start: jUnix(j['start_timestamp']) ?? DateTime.now(),
      end: jUnix(j['stop_timestamp']) ?? DateTime.now(),
      hasArchive: jBool(j['has_archive']),
    );
  }
}

int? _yearOf(dynamic v) {
  if (v == null) return null;
  final m = RegExp(r'(19|20)\d{2}').firstMatch(v.toString());
  return m == null ? null : int.parse(m.group(0)!);
}
