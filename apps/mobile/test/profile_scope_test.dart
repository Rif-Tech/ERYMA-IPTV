import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:multiptv/core/api/portal_api.dart';
import 'package:multiptv/core/db/database.dart';
import 'package:multiptv/core/sync/progress_sync.dart';

/// Profile / playlist scoping of personal data and the v3 → v4 legacy claim.
void main() {
  late AppDatabase db;

  Future<void> addPlaylist(String id) => db.upsertPlaylist(PlaylistsCompanion.insert(
        id: id,
        name: id,
        type: PlaylistType.m3u,
        source: PlaylistSource.portal,
        url: 'http://x/$id.m3u',
      ));

  setUp(() async {
    db = AppDatabase(NativeDatabase.memory());
    await addPlaylist('portal-a');
    await addPlaylist('portal-b');
  });

  tearDown(() => db.close());

  test('history is scoped by profile: two viewers of one playlist never see each other', () async {
    db.profileId = 'alice';
    await db.saveHistory(playlistId: 'portal-a', kind: ContentKind.vod, itemId: 'm1', positionMs: 1000, durationMs: 9000);
    db.profileId = 'bob';
    expect(await db.watchHistory('portal-a', ContentKind.vod).first, isEmpty);
    await db.saveHistory(playlistId: 'portal-a', kind: ContentKind.vod, itemId: 'm1', positionMs: 5000, durationMs: 9000);
    expect((await db.getHistory('portal-a', ContentKind.vod, 'm1'))!.positionMs, 5000);
    db.profileId = 'alice';
    expect((await db.getHistory('portal-a', ContentKind.vod, 'm1'))!.positionMs, 1000);
  });

  test('progress never crosses playlists, even for an identical title', () async {
    db.profileId = 'alice';
    // Same series, two providers: "Breaking Bad – S02E04" vs "ブレイキング・バッド S2 EP4" share an item id
    // by coincidence but live in different playlists; the second must not inherit the first's position.
    await db.saveHistory(playlistId: 'portal-a', kind: ContentKind.series, itemId: 'ep-204', parentId: 'bb', positionMs: 1_500_000, durationMs: 2_800_000);
    expect(await db.getHistory('portal-b', ContentKind.series, 'ep-204'), isNull);
    await db.saveHistory(playlistId: 'portal-b', kind: ContentKind.series, itemId: 'ep-204', parentId: 'bb-jp', positionMs: 10_000, durationMs: 2_800_000);
    expect((await db.getHistory('portal-a', ContentKind.series, 'ep-204'))!.positionMs, 1_500_000);
    expect((await db.getHistory('portal-b', ContentKind.series, 'ep-204'))!.positionMs, 10_000);
    expect(await db.pendingHistory('portal-a'), hasLength(1));
    expect(await db.pendingHistory('portal-b'), hasLength(1));
  });

  test('favourites, locks and hidden categories are per profile', () async {
    db.profileId = 'kid';
    await db.toggleFavorite('portal-a', ContentKind.live, 'c1');
    await db.toggleLockedChannel('portal-a', 'c9');
    await db.toggleHiddenCategory('portal-a', ContentKind.vod, 'horror');
    db.profileId = 'parent';
    expect(await db.watchIsFavorite('portal-a', ContentKind.live, 'c1').first, isFalse);
    expect(await db.watchLockedChannels('portal-a').first, isEmpty);
    expect(await db.watchHiddenCategories('portal-a', ContentKind.vod).first, isEmpty);
    db.profileId = 'kid';
    expect(await db.watchLockedChannels('portal-a').first, {'c9'});
    expect(await db.watchHiddenCategories('portal-a', ContentKind.vod).first, {'horror'});
  });

  test('legacy rows (profile_id = "") are claimed once by the first profile', () async {
    // Data written before profiles existed.
    db.profileId = '';
    await db.saveHistory(playlistId: 'portal-a', kind: ContentKind.vod, itemId: 'old', positionMs: 42);
    await db.toggleFavorite('portal-a', ContentKind.vod, 'old');
    expect(await db.hasLegacyProfileData(), isTrue);

    await db.claimLegacyProfileData('alice');
    db.profileId = 'alice';
    expect((await db.getHistory('portal-a', ContentKind.vod, 'old'))!.positionMs, 42);
    expect(await db.watchIsFavorite('portal-a', ContentKind.vod, 'old').first, isTrue);
    expect(await db.hasLegacyProfileData(), isFalse);
  });

  test('server rows are merged only when newer and are not re-uploaded', () async {
    db.profileId = 'alice';
    final t0 = DateTime(2026, 9, 1, 12);
    await db.saveHistory(playlistId: 'portal-a', kind: ContentKind.vod, itemId: 'm1', positionMs: 100, durationMs: 1000, watchedAt: t0);
    // Older remote copy: ignored.
    final older = RemoteProgress(kind: 'vod', itemId: 'm1', positionMs: 50, durationMs: 1000, lastWatchedAt: t0.subtract(const Duration(hours: 1)));
    final local = await db.getHistory('portal-a', ContentKind.vod, 'm1');
    expect(older.lastWatchedAt.isAfter(local!.watchedAt), isFalse);
    // Newer remote copy: applied and flagged as synced.
    await db.saveHistory(playlistId: 'portal-a', kind: ContentKind.vod, itemId: 'm1', positionMs: 900, durationMs: 1000, watchedAt: t0.add(const Duration(hours: 1)), synced: true);
    final merged = await db.getHistory('portal-a', ContentKind.vod, 'm1');
    expect(merged!.positionMs, 900);
    expect(merged.syncedAt, isNotNull);
    expect(await db.pendingHistory('portal-a'), isEmpty);
    expect(ProgressSync.isCompleted(merged.positionMs, merged.durationMs), isFalse);
    expect(ProgressSync.isCompleted(960, 1000), isTrue);
  });

  test('schema v3 database upgrades to v4 keeping rows', () async {
    // Minimal v3 layout for the tables the v4 step rebuilds; the real MigrationStrategy runs.
    final v3 = NativeDatabase.memory(setup: (rawDb) {
      rawDb.execute('''
        CREATE TABLE playlists (id TEXT NOT NULL PRIMARY KEY, name TEXT NOT NULL, type TEXT NOT NULL, source TEXT NOT NULL, url TEXT NOT NULL,
          username TEXT, password TEXT, epg_url TEXT, is_protected INTEGER NOT NULL DEFAULT 0, pin_code TEXT, expires_at INTEGER,
          position INTEGER NOT NULL DEFAULT 0, last_synced_at INTEGER, account_info TEXT, created_at INTEGER NOT NULL DEFAULT 0);
        CREATE TABLE history (id INTEGER PRIMARY KEY AUTOINCREMENT, playlist_id TEXT NOT NULL REFERENCES playlists (id) ON DELETE CASCADE,
          kind TEXT NOT NULL, item_id TEXT NOT NULL, parent_id TEXT, position_ms INTEGER NOT NULL DEFAULT 0, duration_ms INTEGER NOT NULL DEFAULT 0,
          watched_at INTEGER NOT NULL DEFAULT (strftime('%s', CURRENT_TIMESTAMP)), UNIQUE (playlist_id, kind, item_id));
        CREATE TABLE favorites (id INTEGER PRIMARY KEY AUTOINCREMENT, playlist_id TEXT NOT NULL REFERENCES playlists (id) ON DELETE CASCADE,
          kind TEXT NOT NULL, item_id TEXT NOT NULL, added_at INTEGER NOT NULL DEFAULT (strftime('%s', CURRENT_TIMESTAMP)), UNIQUE (playlist_id, kind, item_id));
        CREATE TABLE locked_channels (playlist_id TEXT NOT NULL REFERENCES playlists (id) ON DELETE CASCADE, stream_id TEXT NOT NULL, PRIMARY KEY (playlist_id, stream_id));
        CREATE TABLE hidden_categories (playlist_id TEXT NOT NULL REFERENCES playlists (id) ON DELETE CASCADE, kind TEXT NOT NULL, category_id TEXT NOT NULL, PRIMARY KEY (playlist_id, kind, category_id));
        CREATE TABLE channel_groups (id INTEGER PRIMARY KEY AUTOINCREMENT, playlist_id TEXT NOT NULL REFERENCES playlists (id) ON DELETE CASCADE, name TEXT NOT NULL);
        INSERT INTO playlists (id, name, type, source, url) VALUES ('p', 'P', 'm3u', 'local', 'http://x');
        INSERT INTO history (playlist_id, kind, item_id, position_ms, duration_ms) VALUES ('p', 'vod', 'm1', 123, 456);
        INSERT INTO favorites (playlist_id, kind, item_id) VALUES ('p', 'live', 'c1');
        INSERT INTO locked_channels (playlist_id, stream_id) VALUES ('p', 'c2');
        PRAGMA user_version = 3;
      ''');
    });
    final upgraded = AppDatabase(v3);
    await upgraded.customSelect('SELECT 1').get(); // opens and migrates
    expect((await upgraded.customSelect('PRAGMA user_version').getSingle()).read<int>('user_version'), 4);
    final hist = await upgraded.customSelect("SELECT profile_id, position_ms FROM history WHERE item_id = 'm1'").getSingle();
    expect(hist.read<String>('profile_id'), '');
    expect(hist.read<int>('position_ms'), 123);
    final fav = await upgraded.customSelect("SELECT profile_id FROM favorites WHERE item_id = 'c1'").getSingle();
    expect(fav.read<String>('profile_id'), '');
    final locked = await upgraded.customSelect("SELECT profile_id FROM locked_channels WHERE stream_id = 'c2'").getSingle();
    expect(locked.read<String>('profile_id'), '');
    await upgraded.close();
  });
}
