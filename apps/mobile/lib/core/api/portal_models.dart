import 'package:flutter/foundation.dart';

import '../net/dns_models.dart';

// JSON models of the Edge Function responses consumed by the app (see docs/api.md). Re-exported
// by portal_api.dart, so importers of the client get them too.

@immutable
class DeviceStatus {
  const DeviceStatus({
    required this.registered,
    required this.activated,
    required this.isTrial,
    required this.expired,
    this.trialEndsAt,
    this.expiresAt,
    this.plan = 'trial',
    this.planName,
    this.maxDevices = 0,
    this.maxProfiles = 0,
    this.maxPlaylists = 0,
  });

  final bool registered;
  final bool activated;
  final bool isTrial;

  /// True when neither an active trial nor a valid activation exists.
  final bool expired;
  final DateTime? trialEndsAt;
  final DateTime? expiresAt;

  /// Subscription plan id / display name (`trial`, `standard`).
  final String plan;
  final String? planName;
  final int maxDevices;
  final int maxProfiles;
  final int maxPlaylists;

  bool get canPlay => !expired;

  int get trialDaysLeft {
    if (trialEndsAt == null) return 0;
    final d = trialEndsAt!.difference(DateTime.now()).inHours;
    return d <= 0 ? 0 : (d / 24).ceil();
  }

  /// Accepts both the legacy device status and the account status returned by `device-session`.
  factory DeviceStatus.fromJson(Map<String, dynamic> j) => DeviceStatus(
        registered: j['registered'] != false,
        activated: j['activated'] == true,
        isTrial: j['is_trial'] == true,
        expired: j['expired'] == true,
        trialEndsAt: _date(j['trial_ends_at']),
        expiresAt: _date(j['expires_at']),
        plan: (j['plan'] ?? 'trial').toString(),
        planName: j['plan_name'] as String?,
        maxDevices: (j['max_devices'] as num?)?.toInt() ?? 0,
        maxProfiles: (j['max_profiles'] as num?)?.toInt() ?? 0,
        maxPlaylists: (j['max_playlists'] as num?)?.toInt() ?? 0,
      );

  static const offline = DeviceStatus(registered: false, activated: false, isTrial: false, expired: false);
}

/// A viewer profile of the account (Netflix-style "who's watching?").
@immutable
class ViewerProfile {
  const ViewerProfile({
    required this.id,
    required this.name,
    required this.avatar,
    this.isKids = false,
    this.position = 0,
    this.playlistIds = const [],
  });

  final String id;
  final String name;

  /// Avatar colour key (`blue`, `red`, …) chosen on the portal.
  final String avatar;
  final bool isKids;
  final int position;

  /// Portal playlist ids (server uuids) this profile may open.
  final List<String> playlistIds;

  factory ViewerProfile.fromJson(Map<String, dynamic> j) => ViewerProfile(
        id: j['id'].toString(),
        name: (j['name'] ?? '').toString(),
        avatar: (j['avatar'] ?? 'blue').toString(),
        isKids: j['is_kids'] == true,
        position: (j['position'] as num?)?.toInt() ?? 0,
        playlistIds: (j['playlist_ids'] as List? ?? const []).map((e) => e.toString()).toList(),
      );
}

/// Snapshot returned by `device-session`: everything the app needs after boot.
@immutable
class SessionSnapshot {
  const SessionSnapshot({
    required this.deviceId,
    required this.deviceName,
    required this.status,
    required this.profiles,
    required this.playlists,
    this.activeProfileId,
    this.activePlaylistId,
  });

  final String deviceId;
  final String? deviceName;
  final DeviceStatus status;
  final List<ViewerProfile> profiles;
  final List<PortalPlaylist> playlists;

  /// Context remembered server-side (last profile/playlist used on this device).
  final String? activeProfileId;
  final String? activePlaylistId;

  factory SessionSnapshot.fromJson(Map<String, dynamic> j) {
    final device = (j['device'] as Map?)?.cast<String, dynamic>() ?? const {};
    final context = (j['context'] as Map?)?.cast<String, dynamic>() ?? const {};
    return SessionSnapshot(
      deviceId: device['id'].toString(),
      deviceName: device['name'] as String?,
      status: DeviceStatus.fromJson((j['account'] as Map?)?.cast<String, dynamic>() ?? const {}),
      profiles: (j['profiles'] as List? ?? const []).whereType<Map>().map((e) => ViewerProfile.fromJson(e.cast<String, dynamic>())).toList(),
      playlists: (j['playlists'] as List? ?? const []).whereType<Map>().map((e) => PortalPlaylist.fromJson(e.cast<String, dynamic>())).toList(),
      activeProfileId: context['profile_id'] as String?,
      activePlaylistId: context['playlist_id'] as String?,
    );
  }
}

/// A pairing session created by the device; the user confirms it on the portal.
@immutable
class PairingTicket {
  const PairingTicket({required this.sessionId, required this.code, required this.token, required this.expiresAt, this.url});
  final String sessionId;

  /// Short code typed on the portal (`GT3H39`).
  final String code;

  /// One-time token embedded in the QR code URL; also authorises status polling.
  final String token;
  final DateTime expiresAt;

  /// Portal URL computed by the server, when `PORTAL_URL` is configured there.
  final String? url;

  factory PairingTicket.fromJson(Map<String, dynamic> j) => PairingTicket(
        sessionId: j['session_id'].toString(),
        code: (j['code'] ?? '').toString(),
        token: (j['token'] ?? '').toString(),
        expiresAt: _date(j['expires_at']) ?? DateTime.now().add(const Duration(minutes: 10)),
        url: j['url'] as String?,
      );
}

/// `pending` | `confirmed` | `expired` | `cancelled`, plus the confirmation payload.
@immutable
class PairingState {
  const PairingState({required this.status, this.deviceId, this.playlistId});
  final String status;
  final String? deviceId;
  final String? playlistId;

  bool get confirmed => status == 'confirmed';
  bool get finished => status != 'pending';

  factory PairingState.fromJson(Map<String, dynamic> j) {
    final result = (j['result'] as Map?)?.cast<String, dynamic>() ?? const {};
    return PairingState(
      status: (j['status'] ?? 'pending').toString(),
      deviceId: result['device_id'] as String?,
      playlistId: result['playlist_id'] as String?,
    );
  }
}

/// One row of `watch_progress` (server) ↔ `history` (local), always scoped to profile + playlist.
@immutable
class RemoteProgress {
  const RemoteProgress({
    required this.kind,
    required this.itemId,
    this.parentId,
    this.positionMs = 0,
    this.durationMs = 0,
    this.completed = false,
    required this.lastWatchedAt,
  });
  final String kind;
  final String itemId;
  final String? parentId;
  final int positionMs;
  final int durationMs;
  final bool completed;
  final DateTime lastWatchedAt;

  factory RemoteProgress.fromJson(Map<String, dynamic> j) => RemoteProgress(
        kind: (j['kind'] ?? 'vod').toString(),
        itemId: j['item_id'].toString(),
        parentId: j['parent_id'] as String?,
        positionMs: (j['position_ms'] as num?)?.toInt() ?? 0,
        durationMs: (j['duration_ms'] as num?)?.toInt() ?? 0,
        completed: j['completed'] == true,
        lastWatchedAt: _date(j['last_watched_at']) ?? DateTime.now(),
      );

  Map<String, dynamic> toJson() => {
        'kind': kind,
        'item_id': itemId,
        'parent_id': parentId,
        'position_ms': positionMs,
        'duration_ms': durationMs,
        'completed': completed,
        'last_watched_at': lastWatchedAt.toUtc().toIso8601String(),
      };
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
  const AppInfo({
    this.latestVersion,
    this.minVersion,
    this.apkLink,
    this.status = 'ok',
    this.message,
    this.portalUrl,
    this.dnsServers = const [],
  });
  final String? latestVersion;
  final String? minVersion;
  final String? apkLink;

  /// `ok` | `maintenance`.
  final String status;
  final String? message;

  /// Public portal URL configured by the admin (QR codes, instructions).
  final String? portalUrl;

  /// Admin-managed DNS presets (Google, Cloudflare, ...) offered in Réglages → Réseau / DNS.
  final List<DnsServer> dnsServers;

  factory AppInfo.fromJson(Map<String, dynamic> j) => AppInfo(
        latestVersion: j['latest_version'] as String?,
        minVersion: j['min_version'] as String?,
        apkLink: j['apk_link'] as String?,
        status: (j['app_status'] ?? 'ok').toString(),
        message: j['message'] as String?,
        portalUrl: (j['portal_url'] as String?)?.trim().isNotEmpty == true ? (j['portal_url'] as String).trim() : null,
        dnsServers: (j['dns_servers'] as List?)?.whereType<Map>().map((e) => DnsServer.fromJson(e.cast<String, dynamic>())).toList() ??
            const [],
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

  Map<String, dynamic> toJson() => {
        'id': id,
        'kind': kind,
        'tmdb_id': tmdbId,
        'title': title,
        'subtitle': subtitle,
        'overview': overview,
        'year': year,
        'poster_url': posterUrl,
        'backdrop_url': backdropUrl,
        'link_kind': linkKind,
        'link_query': linkQuery,
        'require_match': requireMatch,
        'event_at': eventAt?.toUtc().toIso8601String(),
        'event_end_at': eventEndAt?.toUtc().toIso8601String(),
      };
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
