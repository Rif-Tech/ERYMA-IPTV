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

  group('SQL-side listing', () {
    Future<void> seedMovies() async {
      await db.batch((b) => b.insertAll(db.movies, [
            for (var i = 0; i < 5; i++)
              MoviesCompanion.insert(
                playlistId: 'p1',
                streamId: 'm$i',
                name: ['Zorro', 'alpha', 'Beta', 'gamma', 'Delta'][i],
                nameKey: Value(['zorro', 'alpha', 'beta', 'gamma', 'delta'][i]),
                categoryId: Value(i.isEven ? 'c0' : 'c1'),
                rating: Value(i == 2 ? null : i.toDouble()),
                addedAt: Value(i == 4 ? null : DateTime(2026, 1, i + 1)),
                position: Value(i),
              ),
          ]));
    }

    test('pages, filters hidden categories and sorts case-insensitively', () async {
      await seedMovies();
      final az = await db.queryMovies('p1', const ContentFilter(sort: ContentSort.az));
      expect(az.map((m) => m.name), ['alpha', 'Beta', 'Delta', 'gamma', 'Zorro']);

      final page = await db.queryMovies('p1', const ContentFilter(limit: 2, offset: 2));
      expect(page.map((m) => m.streamId), ['m2', 'm3']);

      final visible = await db.queryMovies('p1', const ContentFilter(hiddenCategories: {'c1'}));
      expect(visible.map((m) => m.streamId), ['m0', 'm2', 'm4']);

      final byRating = await db.queryMovies('p1', const ContentFilter(sort: ContentSort.rating));
      expect(byRating.map((m) => m.streamId), ['m4', 'm3', 'm1', 'm0', 'm2'], reason: 'nulls last');

      final byAdded = await db.queryMovies('p1', const ContentFilter(sort: ContentSort.added));
      expect(byAdded.last.streamId, 'm4', reason: 'missing dates sink to the end');
    });

    test('favourites and recent are joins, ordered by recency', () async {
      await seedMovies();
      await db.toggleFavorite('p1', ContentKind.vod, 'm3');
      await db.toggleFavorite('p1', ContentKind.vod, 'm1');
      final favs = await db.queryMovies('p1', const ContentFilter(favoritesOnly: true));
      expect(favs.map((m) => m.streamId), ['m1', 'm3']);

      // Drift stores DateTime at second precision: set explicit timestamps.
      await db.into(db.history).insert(HistoryCompanion.insert(playlistId: 'p1', kind: ContentKind.vod, itemId: 'm0', watchedAt: Value(DateTime(2026, 1, 1))));
      await db.into(db.history).insert(HistoryCompanion.insert(playlistId: 'p1', kind: ContentKind.vod, itemId: 'm4', watchedAt: Value(DateTime(2026, 1, 2))));
      final recent = await db.queryMovies('p1', const ContentFilter(recentOnly: true));
      expect(recent.map((m) => m.streamId), ['m4', 'm0']);
    });

    test('recent series resolve through the episode parent id', () async {
      await db.into(db.seriesItems).insert(SeriesItemsCompanion.insert(playlistId: 'p1', seriesId: 's1', name: 'Show', nameKey: const Value('show')));
      await db.saveHistory(playlistId: 'p1', kind: ContentKind.series, itemId: 'ep1', parentId: 's1');
      final recent = await db.querySeries('p1', const ContentFilter(recentOnly: true));
      expect(recent.map((s) => s.seriesId), ['s1']);
    });

    test('search uses name_key and ranks prefix matches first', () async {
      await db.batch((b) => b.insertAll(db.channels, [
            ChannelsCompanion.insert(playlistId: 'p1', streamId: 'a', name: '|FR| beIN Sports 1', nameKey: const Value('bein sports 1'), position: const Value(0)),
            ChannelsCompanion.insert(playlistId: 'p1', streamId: 'b', name: 'Sports Bein Max', nameKey: const Value('sports bein max'), position: const Value(1)),
            ChannelsCompanion.insert(playlistId: 'p1', streamId: 'c', name: 'TF1', nameKey: const Value('tf1'), position: const Value(2)),
          ]));
      final hits = await db.searchChannels('p1', 'bein');
      expect(hits.map((c) => c.streamId), ['a', 'b']);
      expect((await db.channelContainingWords('p1', 'max bein'))?.streamId, 'b');
      expect((await db.channelsByNameKeys('p1', ['tf1'])).single.streamId, 'c');
    });
  });

  group('EPG', () {
    test('now/next for many channels comes back grouped, two per channel', () async {
      final now = DateTime(2026, 9, 22, 12);
      await db.batch((b) => b.insertAll(db.epgPrograms, [
            for (final ch in ['x', 'y'])
              for (var i = -1; i < 3; i++)
                EpgProgramsCompanion.insert(
                  playlistId: 'p1',
                  channelId: ch,
                  start: now.add(Duration(hours: i)),
                  end: now.add(Duration(hours: i + 1)),
                  title: '$ch$i',
                ),
          ]));
      final map = await db.getNowNextForChannels('p1', ['x', 'y', 'missing'], now: now.add(const Duration(minutes: 30)));
      expect(map.keys, unorderedEquals(['x', 'y']));
      expect(map['x']!.map((p) => p.title), ['x0', 'x1']);
    });

    test('purgeEpg drops rows outside the retention window', () async {
      final now = DateTime.now();
      await db.batch((b) => b.insertAll(db.epgPrograms, [
            EpgProgramsCompanion.insert(playlistId: 'p1', channelId: 'x', start: now.subtract(const Duration(days: 5)), end: now.subtract(const Duration(days: 4)), title: 'old'),
            EpgProgramsCompanion.insert(playlistId: 'p1', channelId: 'x', start: now, end: now.add(const Duration(hours: 1)), title: 'now'),
            EpgProgramsCompanion.insert(playlistId: 'p1', channelId: 'x', start: now.add(const Duration(days: 10)), end: now.add(const Duration(days: 10, hours: 1)), title: 'far'),
          ]));
      expect(await db.purgeEpg(), 2);
      expect((await db.getPrograms('p1', 'x')).single.title, 'now');
    });
  });
}
