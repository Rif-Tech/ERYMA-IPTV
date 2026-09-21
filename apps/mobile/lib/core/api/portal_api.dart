import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/config.dart';
import '../device/device_identity.dart';

@immutable
class DeviceStatus {
  const DeviceStatus({
    required this.registered,
    required this.activated,
    required this.isTrial,
    required this.expired,
    this.trialEndsAt,
    this.expiresAt,
  });

  final bool registered;
  final bool activated;
  final bool isTrial;

  /// True when neither an active trial nor a valid activation exists.
  final bool expired;
  final DateTime? trialEndsAt;
  final DateTime? expiresAt;

  bool get canPlay => !expired;

  int get trialDaysLeft {
    if (trialEndsAt == null) return 0;
    final d = trialEndsAt!.difference(DateTime.now()).inHours;
    return d <= 0 ? 0 : (d / 24).ceil();
  }

  factory DeviceStatus.fromJson(Map<String, dynamic> j) => DeviceStatus(
        registered: j['registered'] == true,
        activated: j['activated'] == true,
        isTrial: j['is_trial'] == true,
        expired: j['expired'] == true,
        trialEndsAt: _date(j['trial_ends_at']),
        expiresAt: _date(j['expires_at']),
      );

  static const offline = DeviceStatus(registered: false, activated: false, isTrial: false, expired: false);
}

@immutable
class PortalPlaylist {
  const PortalPlaylist({
    required this.id,
    required this.name,
    required this.type,
    required this.url,
    this.username,
    this.password,
    this.epgUrl,
    this.isProtected = false,
    this.pinCode,
    this.expiresAt,
    this.position = 0,
  });

  final String id;
  final String name;

  /// `m3u` or `xtream`.
  final String type;
  final String url;
  final String? username;
  final String? password;
  final String? epgUrl;
  final bool isProtected;
  final String? pinCode;
  final DateTime? expiresAt;
  final int position;

  factory PortalPlaylist.fromJson(Map<String, dynamic> j) => PortalPlaylist(
        id: j['id'].toString(),
        name: (j['name'] ?? '').toString(),
        type: (j['type'] ?? 'm3u').toString(),
        url: (j['url'] ?? '').toString(),
        username: j['username'] as String?,
        password: j['password'] as String?,
        epgUrl: j['epg_url'] as String?,
        isProtected: j['is_protected'] == true,
        pinCode: j['pin_code'] as String?,
        expiresAt: _date(j['expires_at']),
        position: (j['position'] as num?)?.toInt() ?? 0,
      );
}

@immutable
class AppInfo {
  const AppInfo({this.latestVersion, this.minVersion, this.apkLink, this.status = 'ok', this.message});
  final String? latestVersion;
  final String? minVersion;
  final String? apkLink;

  /// `ok` | `maintenance`.
  final String status;
  final String? message;

  factory AppInfo.fromJson(Map<String, dynamic> j) => AppInfo(
        latestVersion: j['latest_version'] as String?,
        minVersion: j['min_version'] as String?,
        apkLink: j['apk_link'] as String?,
        status: (j['app_status'] ?? 'ok').toString(),
        message: j['message'] as String?,
      );

  bool requiresUpdate(String current) => minVersion != null && compareVersions(current, minVersion!) < 0;
}

/// Compares dotted versions (`1.2.10` > `1.2.9`).
int compareVersions(String a, String b) {
  final pa = a.split(RegExp(r'[.+-]')).map((e) => int.tryParse(e) ?? 0).toList();
  final pb = b.split(RegExp(r'[.+-]')).map((e) => int.tryParse(e) ?? 0).toList();
  for (var i = 0; i < 3; i++) {
    final x = i < pa.length ? pa[i] : 0;
    final y = i < pb.length ? pb[i] : 0;
    if (x != y) return x.compareTo(y);
  }
  return 0;
}

DateTime? _date(dynamic v) => v == null ? null : DateTime.tryParse(v.toString())?.toLocal();

/// One "À la une" entry from the `featured` function (admin pick, TMDB trend or popular title).
@immutable
class FeaturedEntry {
  const FeaturedEntry({
    required this.id,
    required this.kind,
    required this.title,
    this.tmdbId,
    this.subtitle,
    this.overview,
    this.year,
    this.posterUrl,
    this.backdropUrl,
    this.linkKind,
    this.linkQuery,
    this.requireMatch = true,
    this.eventAt,
    this.eventEndAt,
  });

  final String id;

  /// `movie` | `tv` | `live` | `custom`.
  final String kind;
  final int? tmdbId;
  final String title;
  final String? subtitle;
  final String? overview;
  final int? year;
  final String? posterUrl;
  final String? backdropUrl;

  /// Explicit target for custom banners: `channel` | `movie` | `series` | `url`.
  final String? linkKind;
  final String? linkQuery;
  final bool requireMatch;

  /// Scheduled event window (custom banners); null when the banner is not time-bound.
  final DateTime? eventAt;
  final DateTime? eventEndAt;

  factory FeaturedEntry.fromJson(Map<String, dynamic> j) => FeaturedEntry(
        id: j['id'].toString(),
        kind: (j['kind'] ?? 'custom').toString(),
        tmdbId: (j['tmdb_id'] as num?)?.toInt(),
        title: (j['title'] ?? '').toString(),
        subtitle: j['subtitle'] as String?,
        overview: j['overview'] as String?,
        year: (j['year'] as num?)?.toInt(),
        posterUrl: j['poster_url'] as String?,
        backdropUrl: j['backdrop_url'] as String?,
        linkKind: j['link_kind'] as String?,
        linkQuery: j['link_query'] as String?,
        requireMatch: j['require_match'] != false,
        eventAt: _date(j['event_at']),
        eventEndAt: _date(j['event_end_at']),
      );
}

/// TMDB details relayed by the `tmdb` function (artwork + synopsis).
@immutable
class TmdbSummary {
  const TmdbSummary({required this.tmdbId, required this.title, this.year, this.overview, this.posterUrl, this.backdropUrl, this.rating});
  final int tmdbId;
  final String title;
  final int? year;
  final String? overview;
  final String? posterUrl;
  final String? backdropUrl;
  final double? rating;

  factory TmdbSummary.fromJson(Map<String, dynamic> j) => TmdbSummary(
        tmdbId: (j['tmdb_id'] as num).toInt(),
        title: (j['title'] ?? '').toString(),
        year: (j['year'] as num?)?.toInt(),
        overview: j['overview'] as String?,
        posterUrl: j['poster_url'] as String?,
        backdropUrl: j['backdrop_url'] as String?,
        rating: (j['rating'] as num?)?.toDouble(),
      );
}

class PortalApiException implements Exception {
  const PortalApiException(this.message, {this.statusCode});
  final String message;
  final int? statusCode;
  @override
  String toString() => 'PortalApiException($statusCode): $message';
}

/// Client for the Supabase Edge Functions consumed by the app.
class PortalApi {
  PortalApi({Dio? dio, String? baseUrl})
      : _dio = dio ??
            Dio(BaseOptions(
              baseUrl: baseUrl ?? AppConfig.apiBaseUrl,
              connectTimeout: const Duration(seconds: 15),
              receiveTimeout: const Duration(seconds: 30),
              headers: {
                'Content-Type': 'application/json',
                if (AppConfig.apiAnonKey.isNotEmpty) 'apikey': AppConfig.apiAnonKey,
                if (AppConfig.apiAnonKey.isNotEmpty) 'Authorization': 'Bearer ${AppConfig.apiAnonKey}',
              },
            ));

  final Dio _dio;

  Future<DeviceStatus> register(DeviceIdentity device) async {
    final json = await _post('/device-register', device.toJson());
    return DeviceStatus.fromJson(json);
  }

  Future<(DeviceStatus, List<PortalPlaylist>)> playlists(DeviceIdentity device) async {
    final json = await _get('/device-playlists', {'mac': device.mac, 'key': device.key});
    final status = DeviceStatus.fromJson((json['status'] as Map?)?.cast<String, dynamic>() ?? json);
    final list = (json['playlists'] as List? ?? const [])
        .whereType<Map>()
        .map((e) => PortalPlaylist.fromJson(e.cast<String, dynamic>()))
        .toList();
    return (status, list);
  }

  Future<AppInfo> appInfo() async => AppInfo.fromJson(await _get('/app-info'));

  Future<PortalPlaylist> createPlaylist(DeviceIdentity device, Map<String, dynamic> body) async {
    final json = await _post('/device-playlists', {'mac': device.mac, 'key': device.key, ...body});
    return PortalPlaylist.fromJson((json['playlist'] as Map).cast<String, dynamic>());
  }

  Future<PortalPlaylist> updatePlaylist(DeviceIdentity device, String playlistId, Map<String, dynamic> body) async {
    final json = await _request('PUT', '/device-playlists', body: {'mac': device.mac, 'key': device.key, 'id': playlistId, ...body});
    return PortalPlaylist.fromJson((json['playlist'] as Map).cast<String, dynamic>());
  }

  Future<void> deletePlaylist(DeviceIdentity device, String playlistId) async {
    await _request('DELETE', '/device-playlists', body: {'mac': device.mac, 'key': device.key, 'id': playlistId});
  }

  /// `mode`: `curated` | `popular` | `tmdb`.
  Future<List<FeaturedEntry>> featured(DeviceIdentity device, {required String mode, required String lang}) async {
    final json = await _get('/featured', {'mac': device.mac, 'key': device.key, 'mode': mode, 'lang': lang});
    return (json['items'] as List? ?? const []).whereType<Map>().map((e) => FeaturedEntry.fromJson(e.cast<String, dynamic>())).toList();
  }

  /// `kind`: `movie` | `tv`. Returns null when TMDB is not configured or the id is unknown.
  Future<TmdbSummary?> tmdbDetails(DeviceIdentity device, {required String kind, required int id, required String lang}) async {
    try {
      final json = await _get('/tmdb', {'mac': device.mac, 'key': device.key, 'action': 'details', 'type': kind, 'id': '$id', 'lang': lang});
      return json['tmdb_id'] == null ? null : TmdbSummary.fromJson(json);
    } on PortalApiException {
      return null;
    }
  }

  /// Anonymous playback statistic; failures are ignored by callers.
  Future<void> reportWatch(
    DeviceIdentity device, {
    required String kind,
    required String titleKey,
    required String title,
    int? year,
    int? tmdbId,
  }) =>
      _post('/watch-events', {
        'mac': device.mac,
        'key': device.key,
        'kind': kind,
        'title_key': titleKey,
        'title': title,
        'year': ?year,
        'tmdb_id': ?tmdbId,
      });

  Future<Map<String, dynamic>> _get(String path, [Map<String, String>? query]) =>
      _request('GET', path, query: query);

  Future<Map<String, dynamic>> _post(String path, Map<String, dynamic> body) => _request('POST', path, body: body);

  Future<Map<String, dynamic>> _request(String method, String path,
      {Map<String, String>? query, Map<String, dynamic>? body}) async {
    try {
      final res = await _dio.request<dynamic>(
        path,
        queryParameters: query,
        data: body,
        options: Options(method: method),
      );
      final data = res.data;
      if (data is Map) return data.cast<String, dynamic>();
      return const {};
    } on DioException catch (e) {
      final data = e.response?.data;
      final message = data is Map && data['error'] != null ? data['error'].toString() : (e.message ?? 'Network error');
      throw PortalApiException(message, statusCode: e.response?.statusCode);
    }
  }
}

final portalApiProvider = Provider<PortalApi>((ref) => PortalApi());
