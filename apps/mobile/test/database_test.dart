import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:multiptv/core/db/database.dart';

void main() {
  late AppDatabase db;

  setUp(() async {
    db = AppDatabase(NativeDatabase.memory());
    await db.upsertPlaylist(PlaylistsCompanion.insert(
      id: 'p1',
      name: 'Test',
      type: PlaylistType.m3u,
      source: PlaylistSource.local,
      url: 'http://x/list.m3u',
    ));
  });

  tearDown(() => db.close());

  test('saveHistory upserts on (playlist, kind, item)', () async {
    await db.saveHistory(playlistId: 'p1', kind: ContentKind.vod, itemId: '42', positionMs: 1000, durationMs: 5000);
    await db.saveHistory(playlistId: 'p1', kind: ContentKind.vod, itemId: '42', positionMs: 2000, durationMs: 5000);
    final rows = await db.watchHistory('p1', ContentKind.vod).first;
    expect(rows, hasLength(1));
    expect(rows.single.positionMs, 2000);
  });

  test('toggleFavorite adds then removes', () async {
    await db.toggleFavorite('p1', ContentKind.live, 'c1');
    expect(await db.watchIsFavorite('p1', ContentKind.live, 'c1').first, isTrue);
    await db.toggleFavorite('p1', ContentKind.live, 'c1');
    expect(await db.watchIsFavorite('p1', ContentKind.live, 'c1').first, isFalse);
  });

  test('deleting a playlist cascades to its content', () async {
    await db.into(db.channels).insert(ChannelsCompanion.insert(playlistId: 'p1', streamId: 's1', name: 'Ch', streamUrl: const Value('http://x/1.ts')));
    await db.saveHistory(playlistId: 'p1', kind: ContentKind.live, itemId: 's1');
    await db.deletePlaylist('p1');
    expect(await db.countChannels('p1'), 0);
    expect(await db.watchHistory('p1', ContentKind.live).first, isEmpty);
  });
}
