import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../api/portal_api.dart';
import '../db/database.dart';
import '../device/device_identity.dart';
import '../settings/settings.dart';

/// Two-way sync between the local `history` table and the server `watch_progress` table.
///
/// Progress is always keyed by (profile, playlist, kind, item): a title watched in one playlist is
/// never matched to a title of another playlist, even with an identical name. Local playlists
/// (`local-*`) have no server counterpart and are never synced. Uploads are debounced so a playing
/// video costs one request every [debounce] at most; the rest is done at open/close.
class ProgressSync {
  ProgressSync(this.ref);
  final Ref ref;

  static const debounce = Duration(seconds: 20);
  Timer? _timer;
  String? _pendingPlaylist;

  /// Schedules an upload of the pending rows of [localPlaylistId].
  void schedule(String localPlaylistId) {
    _pendingPlaylist = localPlaylistId;
    _timer?.cancel();
    _timer = Timer(debounce, flush);
  }

  /// Uploads now whatever is pending (called when playback stops).
  Future<void> flush() async {
    _timer?.cancel();
    _timer = null;
    final id = _pendingPlaylist;
    _pendingPlaylist = null;
    if (id != null) await push(id);
  }

  (String profileId, String playlistId)? _scope(String localPlaylistId) {
    final profileId = ref.read(settingsProvider).activeProfileId;
    if (profileId == null || !localPlaylistId.startsWith('portal-')) return null;
    if (ref.read(installSecretProvider).value == null) return null;
    return (profileId, localPlaylistId.substring('portal-'.length));
  }

  Future<void> push(String localPlaylistId) async {
    final scope = _scope(localPlaylistId);
    if (scope == null) return;
    final db = ref.read(databaseProvider);
    final rows = await db.pendingHistory(localPlaylistId);
    if (rows.isEmpty) return;
    final now = DateTime.now();
    try {
      await ref.read(portalApiProvider).pushProgress(
            profileId: scope.$1,
            playlistId: scope.$2,
            items: rows.map(_toRemote).toList(),
          );
      await db.markHistorySynced(rows.map((r) => r.id), now);
    } on PortalApiException catch (e) {
      // Offline or expired subscription: keep the rows pending, retry on the next schedule.
      debugPrint('progress push: $e');
    } catch (e) {
      debugPrint('progress push: $e');
    }
  }

  /// Merges the server copy into the local table (newer `last_watched_at` wins), then uploads
  /// anything the device recorded while offline.
  Future<void> pull(String localPlaylistId) async {
    final scope = _scope(localPlaylistId);
    if (scope == null) return;
    final db = ref.read(databaseProvider);
    try {
      final items = await ref.read(portalApiProvider).pullProgress(profileId: scope.$1, playlistId: scope.$2);
      for (final r in items) {
        final kind = ContentKind.values.firstWhere((k) => k.name == r.kind, orElse: () => ContentKind.vod);
        final local = await db.getHistory(localPlaylistId, kind, r.itemId);
        if (local != null && !r.lastWatchedAt.isAfter(local.watchedAt)) continue;
        await db.saveHistory(
          playlistId: localPlaylistId,
          kind: kind,
          itemId: r.itemId,
          parentId: r.parentId,
          positionMs: r.positionMs,
          durationMs: r.durationMs,
          watchedAt: r.lastWatchedAt,
          synced: true,
        );
      }
    } on PortalApiException catch (e) {
      debugPrint('progress pull: $e');
    } catch (e) {
      debugPrint('progress pull: $e');
    }
    await push(localPlaylistId);
  }

  static RemoteProgress _toRemote(HistoryData h) => RemoteProgress(
        kind: h.kind.name,
        itemId: h.itemId,
        parentId: h.parentId,
        positionMs: h.positionMs,
        durationMs: h.durationMs,
        completed: isCompleted(h.positionMs, h.durationMs),
        lastWatchedAt: h.watchedAt,
      );

  /// A title counts as finished past 95 % (credits), matching the server's convention.
  static bool isCompleted(int positionMs, int durationMs) => durationMs > 0 && positionMs >= durationMs * 0.95;
}

final progressSyncProvider = Provider<ProgressSync>((ref) {
  final sync = ProgressSync(ref);
  ref.onDispose(() => sync._timer?.cancel());
  return sync;
});
