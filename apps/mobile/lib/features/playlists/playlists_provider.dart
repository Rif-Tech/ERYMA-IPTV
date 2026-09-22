import 'dart:async';
import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../app/config.dart';
import '../../core/api/portal_api.dart';
import '../../core/db/database.dart';
import '../../core/device/device_identity.dart';
import '../../core/playlist/playlist_importer.dart';
import '../../core/settings/settings.dart';
import '../../core/xtream/xtream_client.dart';

final playlistImporterProvider = Provider<PlaylistImporter>((ref) => PlaylistImporter(ref.watch(databaseProvider)));

/// Every playlist stored locally (portal mirror + legacy local ones), regardless of profile access.
final allPlaylistsProvider = StreamProvider<List<Playlist>>((ref) => ref.watch(databaseProvider).watchPlaylists());

/// Playlists the active profile may open. Portal playlists are filtered by the profile's access
/// list (`profile_playlists`); legacy local playlists stay visible to everyone on the device.
final playlistsProvider = Provider<AsyncValue<List<Playlist>>>((ref) {
  final all = ref.watch(allPlaylistsProvider);
  final profile = ref.watch(activeProfileProvider);
  return all.whenData((list) => visibleForProfile(list, profile));
});

/// Applies a profile's playlist access to the local list; no profile = everything (legacy/offline).
List<Playlist> visibleForProfile(List<Playlist> all, ViewerProfile? profile) {
  if (profile == null) return all;
  final allowed = profile.playlistIds.map((id) => 'portal-$id').toSet();
  return all.where((p) => p.source != PlaylistSource.portal || allowed.contains(p.id)).toList();
}

/// The playlist currently browsed; falls back to the first one when the saved id vanished.
final activePlaylistProvider = Provider<Playlist?>((ref) {
  final playlists = ref.watch(playlistsProvider).value ?? const [];
  if (playlists.isEmpty) return null;
  final id = ref.watch(settingsProvider.select((s) => s.activePlaylistId));
  return playlists.firstWhere((p) => p.id == id, orElse: () => playlists.first);
});

/// Convenience: the active playlist id, or throws for providers that require one.
String requirePlaylistId(Ref ref) {
  final p = ref.watch(activePlaylistProvider);
  if (p == null) throw StateError('No active playlist');
  return p.id;
}

// ---------------------------------------------------------------------------

enum SessionPhase {
  /// No confirmed install secret (never paired, revoked or deleted): show the pairing screen.
  unpaired,

  /// `device-session` answered: account status, profiles and playlists are fresh.
  ready,

  /// Network/portal error: local data is used, cached profiles keep the picker working.
  offline,
}

@immutable
class DeviceSession {
  const DeviceSession({required this.phase, this.status = DeviceStatus.offline, this.appInfo, this.error, this.snapshot});

  const DeviceSession.unpaired({this.appInfo})
      : phase = SessionPhase.unpaired,
        status = DeviceStatus.offline,
        error = null,
        snapshot = null;

  final SessionPhase phase;
  final DeviceStatus status;
  final AppInfo? appInfo;
  final String? error;
  final SessionSnapshot? snapshot;

  bool get online => phase == SessionPhase.ready;
  bool get unpaired => phase == SessionPhase.unpaired;

  /// Subscription lapsed: playback is blocked until the admin renews it.
  bool get blocked => online && status.expired;
  String? get deviceName => snapshot?.deviceName;
}

/// Loads the account session for this install and mirrors its playlists into the local database.
class DeviceSessionNotifier extends AsyncNotifier<DeviceSession> {
  static const _profilesCacheKey = 'profilesCache';
  static const portalUrlCacheKey = 'portalUrlCache';

  @override
  Future<DeviceSession> build() => _load();

  Future<DeviceSession> refresh() async {
    state = const AsyncLoading();
    final session = await _load();
    if (ref.mounted) state = AsyncData(session);
    return session;
  }

  Future<DeviceSession> _load() async {
    final api = ref.read(portalApiProvider);
    final db = ref.read(databaseProvider);
    final prefs = ref.read(sharedPreferencesProvider);

    AppInfo? appInfo;
    try {
      await ref.read(deviceIdentityProvider.future);
      final secret = await ref.read(installSecretProvider.future);
      final infoFuture = api.appInfo().then((info) async {
        await _applyPortalUrl(prefs, info);
        return info;
      }).catchError((_) => const AppInfo());
      if (secret == null) return DeviceSession.unpaired(appInfo: await infoFuture);

      // Awaited separately (not `.wait`): a ParallelWaitError would hide the 401 UNPAIRED signal.
      final snapshot = await api.deviceSession();
      appInfo = await infoFuture;
      await _mirrorPortalPlaylists(db, snapshot.playlists);
      await prefs.setString(_profilesCacheKey, jsonEncode(snapshot.profiles.map(_profileToJson).toList()));
      return DeviceSession(phase: SessionPhase.ready, status: snapshot.status, appInfo: appInfo, snapshot: snapshot);
    } on PortalApiException catch (e) {
      debugPrint('Portal error: $e');
      if (e.unpaired) {
        // The server forgot this install (revoked/deleted): drop the secret so the pairing screen
        // shows, and remove the account's playlists from this device (their history stays server-side).
        await ref.read(installSecretProvider.notifier).clear();
        try {
          await _mirrorPortalPlaylists(db, const []);
        } catch (err) {
          debugPrint('unpaired cleanup failed: $err');
        }
        debugPrint('session: unpaired, local account playlists removed');
        return DeviceSession.unpaired(appInfo: appInfo);
      }
      return DeviceSession(phase: SessionPhase.offline, appInfo: appInfo, error: e.message);
    } catch (e) {
      debugPrint('Portal error: $e');
      return DeviceSession(phase: SessionPhase.offline, appInfo: appInfo, error: e.toString());
    }
  }

  /// The admin-configured portal URL replaces the build-time one and survives offline launches.
  static Future<void> _applyPortalUrl(SharedPreferences prefs, AppInfo info) async {
    final url = info.portalUrl;
    if (url == null) return;
    AppConfig.runtimePortalUrl = url;
    await prefs.setString(portalUrlCacheKey, url);
  }

  /// Restores the last known portal URL before any screen renders a QR code.
  static void restorePortalUrl(SharedPreferences prefs) {
    final cached = prefs.getString(portalUrlCacheKey);
    if (cached != null && cached.isNotEmpty) AppConfig.runtimePortalUrl = cached;
  }

  static Map<String, dynamic> _profileToJson(ViewerProfile p) => {
        'id': p.id,
        'name': p.name,
        'avatar': p.avatar,
        'is_kids': p.isKids,
        'position': p.position,
        'playlist_ids': p.playlistIds,
      };

  /// Profiles from the last successful session, for offline launches.
  static List<ViewerProfile> cachedProfiles(SharedPreferences prefs) {
    final raw = prefs.getString(_profilesCacheKey);
    if (raw == null) return const [];
    try {
      return (jsonDecode(raw) as List).whereType<Map>().map((e) => ViewerProfile.fromJson(e.cast<String, dynamic>())).toList();
    } catch (_) {
      return const [];
    }
  }

  Future<void> _mirrorPortalPlaylists(AppDatabase db, List<PortalPlaylist> remote) async {
    final local = await db.watchPlaylists().first;
    final remoteIds = remote.map((p) => 'portal-${p.id}').toSet();
    for (final p in local.where((p) => p.source == PlaylistSource.portal)) {
      if (!remoteIds.contains(p.id)) await db.deletePlaylist(p.id);
    }
    final localById = {for (final p in local) p.id: p};
    for (final r in remote) {
      final id = 'portal-${r.id}';
      final existing = localById[id];

      // A get.php URL is an Xtream account in disguise: use the API (VOD, series, EPG) instead of the raw M3U.
      var type = r.type == 'xtream' ? PlaylistType.xtream : PlaylistType.m3u;
      var url = r.url;
      var username = r.username;
      var password = r.password;
      final creds = type == PlaylistType.m3u ? credentialsFromM3uUrl(r.url) : null;
      if (creds != null) {
        type = PlaylistType.xtream;
        url = creds.baseUrl;
        username = creds.username;
        password = creds.password;
      } else if (type == PlaylistType.xtream) {
        url = normalizeXtreamBaseUrl(r.url);
      }

      final changed = existing == null ||
          existing.url != url ||
          existing.username != username ||
          existing.password != password ||
          existing.epgUrl != r.epgUrl;
      await db.upsertPlaylist(PlaylistsCompanion(
        id: Value(id),
        name: Value(r.name),
        type: Value(type),
        source: const Value(PlaylistSource.portal),
        url: Value(url),
        username: Value(username),
        password: Value(password),
        epgUrl: Value(r.epgUrl),
        isProtected: Value(r.isProtected),
        pinCode: Value(r.pinCode),
        expiresAt: Value(r.expiresAt),
        position: Value(r.position),
        // Credentials changed: force a re-import on next open.
        lastSyncedAt: changed ? const Value(null) : Value(existing.lastSyncedAt),
        accountInfo: changed ? const Value(null) : Value(existing.accountInfo),
      ));
    }
  }
}

final deviceSessionProvider = AsyncNotifierProvider<DeviceSessionNotifier, DeviceSession>(DeviceSessionNotifier.new);

// ---------------------------------------------------------------------------

/// Viewer profiles of the account: fresh from the session when online, cached otherwise.
final profilesProvider = Provider<List<ViewerProfile>>((ref) {
  final session = ref.watch(deviceSessionProvider).value;
  final live = session?.snapshot?.profiles;
  if (live != null) return live;
  if (session != null && session.unpaired) return const [];
  return DeviceSessionNotifier.cachedProfiles(ref.watch(sharedPreferencesProvider));
});

/// The profile picked on this device, or null when none is selected / it was deleted.
final activeProfileProvider = Provider<ViewerProfile?>((ref) {
  final id = ref.watch(settingsProvider.select((s) => s.activeProfileId));
  if (id == null) return null;
  for (final p in ref.watch(profilesProvider)) {
    if (p.id == id) return p;
  }
  return null;
});

/// Profile selection side effects, callable from widgets and providers alike.
class ProfileController extends Notifier<void> {
  @override
  void build() {}

  /// Makes [profile] the active viewer: scopes the local database, claims pre-profile data once,
  /// persists the choice and tells the server (best effort) so the portal can show it.
  Future<void> select(ViewerProfile profile) async {
    final db = ref.read(databaseProvider);
    db.profileId = profile.id;
    if (await db.hasLegacyProfileData()) await db.claimLegacyProfileData(profile.id);
    await ref.read(settingsProvider.notifier).setActiveProfileId(profile.id);
    _pushContext(profile.id);
  }

  /// Re-applies the persisted profile to the database scope at boot (no network).
  void restore() {
    ref.read(databaseProvider).profileId = ref.read(settingsProvider).activeProfileId ?? '';
  }

  /// Remembers the playlist in use server-side (best effort).
  void rememberPlaylist() {
    final profileId = ref.read(settingsProvider).activeProfileId;
    if (profileId != null) _pushContext(profileId);
  }

  void _pushContext(String profileId) {
    final id = ref.read(settingsProvider).activePlaylistId;
    final playlistId = id != null && id.startsWith('portal-') ? id.substring('portal-'.length) : null;
    unawaited(ref.read(portalApiProvider).setContext(profileId: profileId, playlistId: playlistId).catchError((Object e) => debugPrint('setContext: $e')));
  }
}

final profileControllerProvider = NotifierProvider<ProfileController, void>(ProfileController.new);

/// Server uuid of a mirrored playlist (`portal-<uuid>`), null for legacy local playlists.
String? serverPlaylistId(Playlist p) => p.source == PlaylistSource.portal ? p.id.replaceFirst('portal-', '') : null;

// ---------------------------------------------------------------------------

@immutable
class ImportState {
  const ImportState({this.playlistId, this.progress, this.error, this.isAuthError = false});
  final String? playlistId;
  final ImportProgress? progress;
  final String? error;
  final bool isAuthError;

  bool get isRunning => progress != null && progress!.stage != ImportStage.done && error == null;
}

class PlaylistImportController extends Notifier<ImportState> {
  @override
  ImportState build() => const ImportState();

  Future<bool> import(Playlist playlist) async {
    if (state.isRunning && state.playlistId == playlist.id) return false;
    state = ImportState(playlistId: playlist.id, progress: const ImportProgress(ImportStage.connecting));
    try {
      await ref.read(playlistImporterProvider).import(
            playlist,
            onProgress: (p) => state = ImportState(playlistId: playlist.id, progress: p),
          );
      state = ImportState(playlistId: playlist.id, progress: const ImportProgress(ImportStage.done));
      return true;
    } on ImportException catch (e) {
      state = ImportState(playlistId: playlist.id, error: e.message, isAuthError: e.isAuthError);
      return false;
    } catch (e) {
      state = ImportState(playlistId: playlist.id, error: e.toString());
      return false;
    }
  }

  void reset() => state = const ImportState();
}

final playlistImportProvider = NotifierProvider<PlaylistImportController, ImportState>(PlaylistImportController.new);

/// Whether the playlist needs (re)importing according to the auto-update setting.
bool needsImport(Playlist p, AutoUpdate policy) {
  final last = p.lastSyncedAt;
  if (last == null) return true;
  return switch (policy) {
    AutoUpdate.never => false,
    AutoUpdate.always => true,
    AutoUpdate.daily => DateTime.now().difference(last) > const Duration(hours: 24),
  };
}