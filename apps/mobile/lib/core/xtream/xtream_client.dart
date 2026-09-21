import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

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
class XtreamCredentials {
  XtreamCredentials({required String baseUrl, required this.username, required this.password})
      : baseUrl = normalizeXtreamBaseUrl(baseUrl);

  final String baseUrl;
  final String username;
  final String password;

  String get _auth => 'username=${_p(username)}&password=${_p(password)}';

  String playerApi([String? action, Map<String, String> params = const {}]) {
    final buf = StringBuffer('$baseUrl/player_api.php?$_auth');
    if (action != null) buf.write('&action=$action');
    params.forEach((k, v) => buf.write('&$k=${_p(v)}'));
    return buf.toString();
  }

  String get xmltvUrl => '$baseUrl/xmltv.php?$_auth';

  String m3uUrl({String output = 'ts'}) => '$baseUrl/get.php?$_auth&type=m3u_plus&output=$output';

  String liveUrl(String streamId, {String extension = 'ts'}) =>
      '$baseUrl/live/${_p(username)}/${_p(password)}/$streamId.$extension';

  String movieUrl(String streamId, String? containerExtension) =>
      '$baseUrl/movie/${_p(username)}/${_p(password)}/$streamId.${_ext(containerExtension, 'mp4')}';

  String seriesUrl(String episodeId, String? containerExtension) =>
      '$baseUrl/series/${_p(username)}/${_p(password)}/$episodeId.${_ext(containerExtension, 'mp4')}';

  /// Catch-up: `start` in local server time, [durationMinutes] of archive to play.
  String timeshiftUrl(String streamId, DateTime start, int durationMinutes) {
    String two(int n) => n.toString().padLeft(2, '0');
    final s = '${start.year}-${two(start.month)}-${two(start.day)}:${two(start.hour)}-${two(start.minute)}';
    return '$baseUrl/timeshift/${_p(username)}/${_p(password)}/$durationMinutes/$s/$streamId.ts';
  }

  static String _p(String s) => Uri.encodeComponent(s);
  static String _ext(String? ext, String fallback) {
    final e = (ext ?? '').replaceAll('.', '').trim();
    return e.isEmpty ? fallback : e;
  }
}

/// Accepts `host:port`, `http://host:port/`, `http://host/player_api.php?...`, `get.php` URLs.
String normalizeXtreamBaseUrl(String input) {
  var s = input.trim();
  if (!s.contains('://')) s = 'http://$s';
  final uri = Uri.parse(s);
  final port = uri.hasPort ? ':${uri.port}' : '';
  var path = uri.path;
  for (final marker in ['/player_api.php', '/get.php', '/xmltv.php', '/c/', '/live/', '/movie/', '/series/']) {
    final i = path.indexOf(marker);
    if (i >= 0) path = path.substring(0, i);
  }
  path = path.replaceAll(RegExp(r'/+$'), '');
  return '${uri.scheme}://${uri.host}$port$path';
}

/// Parses an Xtream `get.php` URL into credentials, if possible.
XtreamCredentials? credentialsFromM3uUrl(String url) {
  final uri = Uri.tryParse(url.trim());
  if (uri == null) return null;
  final u = uri.queryParameters['username'];
  final p = uri.queryParameters['password'];
  if (u == null || p == null) return null;
  return XtreamCredentials(baseUrl: url, username: u, password: p);
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
  const XtreamSeriesInfo({required this.episodes, this.plot, this.cast, this.director, this.genre, this.youtubeTrailer});
  final List<XtreamEpisode> episodes;
  final String? plot;
  final String? cast;
  final String? director;
  final String? genre;
  final String? youtubeTrailer;

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
    return XtreamSeriesInfo(
      episodes: episodes,
      plot: jStrOrNull(info['plot']),
      cast: jStrOrNull(info['cast']),
      director: jStrOrNull(info['director']),
      genre: jStrOrNull(info['genre']),
      youtubeTrailer: jStrOrNull(info['youtube_trailer']),
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

// ---------------------------------------------------------------------------

class XtreamException implements Exception {
  const XtreamException(this.message, {this.isAuthError = false});
  final String message;
  final bool isAuthError;
  @override
  String toString() => 'XtreamException: $message';
}

class XtreamClient {
  XtreamClient(this.credentials, {Dio? dio})
      : _dio = dio ??
            Dio(BaseOptions(
              connectTimeout: const Duration(seconds: 20),
              receiveTimeout: const Duration(seconds: 60),
              headers: {'User-Agent': 'MultIPTV/1.0'},
              responseType: ResponseType.json,
            ));

  final XtreamCredentials credentials;
  final Dio _dio;

  Future<XtreamAccount> login() async {
    final json = await _getMap(credentials.playerApi());
    final account = XtreamAccount.fromJson(json);
    if (!account.authenticated) {
      throw XtreamException('Authentication failed (${account.status})', isAuthError: true);
    }
    return account;
  }

  Future<List<XtreamCategory>> liveCategories() =>
      _getList('get_live_categories').then((l) => l.map(XtreamCategory.fromJson).toList());
  Future<List<XtreamCategory>> vodCategories() =>
      _getList('get_vod_categories').then((l) => l.map(XtreamCategory.fromJson).toList());
  Future<List<XtreamCategory>> seriesCategories() =>
      _getList('get_series_categories').then((l) => l.map(XtreamCategory.fromJson).toList());

  Future<List<XtreamLiveStream>> liveStreams({String? categoryId}) => _getList('get_live_streams',
          categoryId == null ? const {} : {'category_id': categoryId})
      .then((l) => l.map(XtreamLiveStream.fromJson).toList());

  Future<List<XtreamVodStream>> vodStreams({String? categoryId}) => _getList('get_vod_streams',
          categoryId == null ? const {} : {'category_id': categoryId})
      .then((l) => l.map(XtreamVodStream.fromJson).toList());

  Future<List<XtreamSeries>> series({String? categoryId}) =>
      _getList('get_series', categoryId == null ? const {} : {'category_id': categoryId})
          .then((l) => l.map(XtreamSeries.fromJson).toList());

  Future<XtreamVodInfo> vodInfo(String vodId) =>
      _getMap(credentials.playerApi('get_vod_info', {'vod_id': vodId})).then(XtreamVodInfo.fromJson);

  Future<XtreamSeriesInfo> seriesInfo(String seriesId) =>
      _getMap(credentials.playerApi('get_series_info', {'series_id': seriesId})).then(XtreamSeriesInfo.fromJson);

  Future<List<XtreamEpgEntry>> shortEpg(String streamId, {int limit = 10}) async {
    final json = await _getMap(credentials.playerApi('get_short_epg', {'stream_id': streamId, 'limit': '$limit'}));
    return _epgList(json);
  }

  /// Full archive listing used by catch-up.
  Future<List<XtreamEpgEntry>> simpleDataTable(String streamId) async {
    final json = await _getMap(credentials.playerApi('get_simple_data_table', {'stream_id': streamId}));
    return _epgList(json);
  }

  List<XtreamEpgEntry> _epgList(Map<String, dynamic> json) {
    final list = json['epg_listings'];
    if (list is! List) return const [];
    return list.whereType<Map>().map((e) => XtreamEpgEntry.fromJson(e.cast<String, dynamic>())).toList();
  }

  Future<Map<String, dynamic>> _getMap(String url) async {
    final data = await _get(url);
    if (data is Map) return data.cast<String, dynamic>();
    throw const XtreamException('Unexpected response');
  }

  Future<List<Map<String, dynamic>>> _getList(String action, [Map<String, String> params = const {}]) async {
    final data = await _get(credentials.playerApi(action, params));
    if (data is List) return data.whereType<Map>().map((e) => e.cast<String, dynamic>()).toList();
    // Some panels answer `{}` or an auth object when the account is invalid.
    if (data is Map && data.containsKey('user_info')) {
      throw const XtreamException('Authentication failed', isAuthError: true);
    }
    return const [];
  }

  Future<dynamic> _get(String url) async {
    try {
      final res = await _dio.get<dynamic>(url);
      var data = res.data;
      if (data is String) {
        try {
          data = jsonDecode(data);
        } catch (_) {
          throw const XtreamException('Server returned a non-JSON response');
        }
      }
      return data;
    } on DioException catch (e) {
      final code = e.response?.statusCode;
      if (code == 401 || code == 403) throw const XtreamException('Access denied', isAuthError: true);
      throw XtreamException(e.message ?? 'Network error');
    }
  }
}
