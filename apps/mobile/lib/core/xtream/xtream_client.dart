import 'dart:convert';
import 'dart:isolate';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import 'xtream_models.dart';

export 'xtream_models.dart';

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

  Future<List<XtreamCategory>> liveCategories() => _getListMapped('get_live_categories', XtreamCategory.fromJson);
  Future<List<XtreamCategory>> vodCategories() => _getListMapped('get_vod_categories', XtreamCategory.fromJson);
  Future<List<XtreamCategory>> seriesCategories() => _getListMapped('get_series_categories', XtreamCategory.fromJson);

  Future<List<XtreamLiveStream>> liveStreams({String? categoryId}) =>
      _getListMapped('get_live_streams', XtreamLiveStream.fromJson, categoryId == null ? const {} : {'category_id': categoryId});

  Future<List<XtreamVodStream>> vodStreams({String? categoryId}) =>
      _getListMapped('get_vod_streams', XtreamVodStream.fromJson, categoryId == null ? const {} : {'category_id': categoryId});

  Future<List<XtreamSeries>> series({String? categoryId}) =>
      _getListMapped('get_series', XtreamSeries.fromJson, categoryId == null ? const {} : {'category_id': categoryId});

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

  /// Catalogue endpoints return megabytes of JSON: decode and map them off the UI isolate so the
  /// import screen keeps animating. Small answers are handled inline (spawning costs more).
  Future<List<T>> _getListMapped<T>(String action, T Function(Map<String, dynamic>) fromJson, [Map<String, String> params = const {}]) async {
    final String text;
    try {
      final res = await _dio.get<String>(credentials.playerApi(action, params), options: Options(responseType: ResponseType.plain));
      text = res.data ?? '';
    } on DioException catch (e) {
      final code = e.response?.statusCode;
      if (code == 401 || code == 403) throw const XtreamException('Access denied', isAuthError: true);
      throw XtreamException(e.message ?? 'Network error');
    }
    if (text.trim().isEmpty) return const [];
    List<T> decode() {
      final dynamic data;
      try {
        data = jsonDecode(text);
      } catch (_) {
        throw const XtreamException('Server returned a non-JSON response');
      }
      if (data is List) return [for (final e in data) if (e is Map) fromJson(e.cast<String, dynamic>())];
      if (data is Map && data.containsKey('user_info')) throw const XtreamException('Authentication failed', isAuthError: true);
      return const [];
    }
    return text.length < 256 * 1024 ? decode() : Isolate.run(decode);
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
