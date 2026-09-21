import 'dart:async';

import 'package:drift/drift.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/api/portal_api.dart';
import '../../core/db/database.dart';
import '../../core/device/device_identity.dart';
import '../../core/playlist/playlist_importer.dart';
import '../../core/settings/settings.dart';
import '../../core/xtream/xtream_client.dart';

final playlistImporterProvider = Provider<PlaylistImporter>((ref) => PlaylistImporter(ref.watch(databaseProvider)));

final playlistsProvider = StreamProvider<List<Playlist>>((ref) => ref.watch(databaseProvider).watchPlaylists());

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

@immutable
class DeviceSession {
  const DeviceSession({required this.status, this.online = true, this.appInfo, this.error, this.keyConflict = false});
  final DeviceStatus status;
  final bool online;
  final AppInfo? appInfo;
  final String? error;

  /// The MAC is registered on the portal with another key (reinstall / clone).
  final bool keyConflict;
}

/// Registers the device, checks app info and mirrors portal playlists into the local database.
class DeviceSessionNotifier extends AsyncNotifier<DeviceSession> {
  @override
  Future<DeviceSession> build() => _load();

  Future<DeviceSession> refresh() async {
    state = const AsyncLoading();
    final session = await _load();
    state = AsyncData(session);
    return session;
  }

  Future<DeviceSession> _load() async {
    final api = ref.read(portalApiProvider);
    final db = ref.read(databaseProvider);

    try {
      final device = await ref.read(deviceIdentityProvider.future);
      final appInfo = await api.appInfo().catchError((_) => const AppInfo());
      await api.register(device);
      final (status, remote) = await api.playlists(device);
      await _mirrorPortalPlaylists(db, remote);
      return DeviceSession(status: status, appInfo: appInfo);
    } on PortalApiException catch (e) {
      debugPrint('Portal error: $e');
      return DeviceSession(
        status: DeviceStatus.offline,
        online: false,
        error: e.message,
        keyConflict: e.statusCode == 409,
      );
    } catch (e) {
      debugPrint('Portal error: $e');
      return DeviceSession(status: DeviceStatus.offline, online: false, error: e.toString());
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

// ---------------------------------------------------------------------------

/// Local (on-device) playlist creation helpers.
class LocalPlaylists {
  LocalPlaylists(this.db);
  final AppDatabase db;

  Future<Playlist> addM3u({required String name, required String url, String? epgUrl, String? pin}) async {
    final id = 'local-${DateTime.now().microsecondsSinceEpoch}';
    await db.upsertPlaylist(PlaylistsCompanion.insert(
      id: id,
      name: name,
      type: PlaylistType.m3u,
      source: PlaylistSource.local,
      url: url,
      epgUrl: Value(epgUrl?.isEmpty == true ? null : epgUrl),
      isProtected: Value(pin != null && pin.isNotEmpty),
      pinCode: Value(pin),
      position: const Value(1000),
    ));
    return (await db.getPlaylist(id))!;
  }

  Future<Playlist> addXtream({
    required String name,
    required String serverUrl,
    required String username,
    required String password,
    String? pin,
  }) async {
    final id = 'local-${DateTime.now().microsecondsSinceEpoch}';
    await db.upsertPlaylist(PlaylistsCompanion.insert(
      id: id,
      name: name,
      type: PlaylistType.xtream,
      source: PlaylistSource.local,
      url: serverUrl,
      username: Value(username),
      password: Value(password),
      isProtected: Value(pin != null && pin.isNotEmpty),
      pinCode: Value(pin),
      position: const Value(1000),
    ));
    return (await db.getPlaylist(id))!;
  }

  /// Rewrites a local playlist; a changed source forces a re-import.
  Future<Playlist> update(
    Playlist p, {
    required String name,
    required String url,
    String? username,
    String? password,
    String? epgUrl,
    String? pin,
  }) async {
    final sourceChanged = p.url != url || p.username != username || p.password != password || p.epgUrl != epgUrl;
    await (db.update(db.playlists)..where((t) => t.id.equals(p.id))).write(PlaylistsCompanion(
      name: Value(name),
      url: Value(url),
      username: Value(username?.isEmpty == true ? null : username),
      password: Value(password?.isEmpty == true ? null : password),
      epgUrl: Value(epgUrl?.isEmpty == true ? null : epgUrl),
      isProtected: Value(pin != null && pin.isNotEmpty),
      pinCode: Value(pin?.isEmpty == true ? null : pin),
      lastSyncedAt: sourceChanged ? const Value(null) : Value(p.lastSyncedAt),
    ));
    return (await db.getPlaylist(p.id))!;
  }
}

final localPlaylistsProvider = Provider<LocalPlaylists>((ref) => LocalPlaylists(ref.watch(databaseProvider)));
