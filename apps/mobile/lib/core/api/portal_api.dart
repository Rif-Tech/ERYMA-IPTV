import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/config.dart';
import '../device/device_identity.dart';
import 'portal_models.dart';

export 'portal_models.dart';

class PortalApiException implements Exception {
  const PortalApiException(this.message, {this.statusCode});
  final String message;
  final int? statusCode;

  /// The server no longer recognises this install (revoked, deleted or never paired).
  bool get unpaired => statusCode == 401 && message == 'UNPAIRED';

  @override
  String toString() => 'PortalApiException($statusCode): $message';
}

/// Install credentials attached to every device call (`x-device-id` / `x-device-secret`).
typedef InstallAuth = ({String uuid, String? secret});

/// Client for the Supabase Edge Functions consumed by the app.
///
/// Device endpoints are authenticated with the install identity supplied by [auth]; it is read
/// per request so a pairing or a revocation takes effect without rebuilding the client.
class PortalApi {
  PortalApi({Dio? dio, String? baseUrl, InstallAuth? Function()? auth})
      : _auth = auth ?? (() => null),
        _dio = dio ??
            Dio(BaseOptions(
              baseUrl: baseUrl ?? AppConfig.apiBaseUrl,
              connectTimeout: const Duration(seconds: 8),
              receiveTimeout: const Duration(seconds: 20),
              headers: {
                'Content-Type': 'application/json',
                if (AppConfig.apiAnonKey.isNotEmpty) 'apikey': AppConfig.apiAnonKey,
                if (AppConfig.apiAnonKey.isNotEmpty) 'Authorization': 'Bearer ${AppConfig.apiAnonKey}',
              },
            ));

  final Dio _dio;
  final InstallAuth? Function() _auth;

  // ---- Pairing ------------------------------------------------------------

  /// Opens a device pairing session. [secretHash] is the SHA-256 of the secret this install will
  /// present once the pairing is confirmed; the secret itself never leaves the device.
  Future<PairingTicket> createDevicePairing(Map<String, dynamic> device, {required String secretHash}) async {
    final json = await _post('/pairing-create', {'kind': 'device', ...device, 'secret_hash': secretHash});
    return PairingTicket.fromJson(json);
  }

  /// Opens a playlist pairing session for this (already paired) device.
  Future<PairingTicket> createPlaylistPairing(Map<String, dynamic> device) async {
    final json = await _post('/pairing-create', {'kind': 'playlist', ...device});
    return PairingTicket.fromJson(json);
  }

  Future<PairingState> pairingStatus(PairingTicket ticket) async {
    final json = await _get('/pairing-status', {'session_id': ticket.sessionId, 'token': ticket.token});
    return PairingState.fromJson(json);
  }

  // ---- Session ------------------------------------------------------------

  Future<SessionSnapshot> deviceSession() async => SessionSnapshot.fromJson(await _get('/device-session'));

  /// Remembers the profile/playlist in use so another launch (or the portal) can show it.
  Future<void> setContext({String? profileId, String? playlistId}) async {
    await _request('PUT', '/device-context', body: {'profile_id': profileId, 'playlist_id': playlistId});
  }

  Future<AppInfo> appInfo() async => AppInfo.fromJson(await _get('/app-info'));

  // ---- Watch progress -----------------------------------------------------

  Future<List<RemoteProgress>> pullProgress({required String profileId, required String playlistId, DateTime? since}) async {
    final json = await _get('/device-progress', {
      'profile_id': profileId,
      'playlist_id': playlistId,
      if (since != null) 'since': since.toUtc().toIso8601String(),
    });
    return (json['items'] as List? ?? const []).whereType<Map>().map((e) => RemoteProgress.fromJson(e.cast<String, dynamic>())).toList();
  }

  Future<void> pushProgress({required String profileId, required String playlistId, required List<RemoteProgress> items}) async {
    await _request('PUT', '/device-progress', body: {
      'profile_id': profileId,
      'playlist_id': playlistId,
      'items': items.map((e) => e.toJson()).toList(),
    });
  }

  // ---- Content helpers ----------------------------------------------------

  /// `mode`: `curated` | `popular` | `tmdb`.
  Future<List<FeaturedEntry>> featured({required String mode, required String lang}) async {
    final json = await _get('/featured', {'mode': mode, 'lang': lang});
    return (json['items'] as List? ?? const []).whereType<Map>().map((e) => FeaturedEntry.fromJson(e.cast<String, dynamic>())).toList();
  }

  /// `kind`: `movie` | `tv`. Returns null when TMDB is not configured or the id is unknown.
  Future<TmdbSummary?> tmdbDetails({required String kind, required int id, required String lang}) async {
    try {
      final json = await _get('/tmdb', {'action': 'details', 'type': kind, 'id': '$id', 'lang': lang});
      return json['tmdb_id'] == null ? null : TmdbSummary.fromJson(json);
    } on PortalApiException {
      return null;
    }
  }

  /// Anonymous playback statistic; failures are ignored by callers.
  Future<void> reportWatch({
    required String kind,
    required String titleKey,
    required String title,
    int? year,
    int? tmdbId,
  }) async {
    await _post('/watch-events', {
      'kind': kind,
      'title_key': titleKey,
      'title': title,
      'year': ?year,
      'tmdb_id': ?tmdbId,
    });
  }

  Future<Map<String, dynamic>> _get(String path, [Map<String, String>? query]) =>
      _request('GET', path, query: query);

  Future<Map<String, dynamic>> _post(String path, Map<String, dynamic> body) => _request('POST', path, body: body);

  Future<Map<String, dynamic>> _request(String method, String path,
      {Map<String, String>? query, Map<String, dynamic>? body}) async {
    final auth = _auth();
    try {
      final res = await _dio.request<dynamic>(
        path,
        queryParameters: query,
        data: body,
        options: Options(method: method, headers: {
          if (auth != null) 'x-device-id': auth.uuid,
          if (auth?.secret != null) 'x-device-secret': auth!.secret!,
        }),
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

final portalApiProvider = Provider<PortalApi>((ref) {
  return PortalApi(auth: () {
    final uuid = ref.read(deviceIdentityProvider).value?.uuid;
    if (uuid == null) return null;
    return (uuid: uuid, secret: ref.read(installSecretProvider).value);
  });
});
