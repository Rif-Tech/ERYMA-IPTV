import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

part 'database.g.dart';

enum PlaylistType { m3u, xtream }

enum PlaylistSource { portal, local }

enum ContentKind { live, vod, series }

class Playlists extends Table {
  TextColumn get id => text()();
  TextColumn get name => text()();
  TextColumn get type => textEnum<PlaylistType>()();
  TextColumn get source => textEnum<PlaylistSource>()();

  /// M3U: playlist URL or `file://` path. Xtream: server base URL.
  TextColumn get url => text()();
  TextColumn get username => text().nullable()();
  TextColumn get password => text().nullable()();
  TextColumn get epgUrl => text().nullable()();
  BoolColumn get isProtected => boolean().withDefault(const Constant(false))();
  TextColumn get pinCode => text().nullable()();
  DateTimeColumn get expiresAt => dateTime().nullable()();
  IntColumn get position => integer().withDefault(const Constant(0))();
  DateTimeColumn get lastSyncedAt => dateTime().nullable()();

  /// Xtream `user_info` snapshot (exp_date, max_connections…) as JSON.
  TextColumn get accountInfo => text().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

@DataClassName('ContentCategory')
class Categories extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get playlistId => text().customConstraint('NOT NULL REFERENCES playlists (id) ON DELETE CASCADE')();
  TextColumn get externalId => text()();
  TextColumn get kind => textEnum<ContentKind>()();
  TextColumn get name => text()();
  IntColumn get position => integer().withDefault(const Constant(0))();

  @override
  List<Set<Column>> get uniqueKeys => [
        {playlistId, kind, externalId},
      ];
}

class Channels extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get playlistId => text().customConstraint('NOT NULL REFERENCES playlists (id) ON DELETE CASCADE')();
  TextColumn get streamId => text()();
  TextColumn get name => text()();
  TextColumn get logo => text().nullable()();
  TextColumn get categoryId => text().nullable()();
  TextColumn get epgChannelId => text().nullable()();

  /// Full stream URL (M3U). Empty for Xtream: built at play time from the settings.
  TextColumn get streamUrl => text().withDefault(const Constant(''))();
  IntColumn get number => integer().nullable()();
  BoolColumn get tvArchive => boolean().withDefault(const Constant(false))();
  IntColumn get tvArchiveDuration => integer().withDefault(const Constant(0))();
  IntColumn get position => integer().withDefault(const Constant(0))();

  @override
  List<Set<Column>> get uniqueKeys => [
        {playlistId, streamId},
      ];
}

@DataClassName('Movie')
class Movies extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get playlistId => text().customConstraint('NOT NULL REFERENCES playlists (id) ON DELETE CASCADE')();
  TextColumn get streamId => text()();
  TextColumn get name => text()();
  TextColumn get poster => text().nullable()();
  TextColumn get categoryId => text().nullable()();
  TextColumn get streamUrl => text().withDefault(const Constant(''))();
  TextColumn get containerExtension => text().nullable()();
  RealColumn get rating => real().nullable()();
  IntColumn get year => integer().nullable()();
  DateTimeColumn get addedAt => dateTime().nullable()();
  IntColumn get position => integer().withDefault(const Constant(0))();

  @override
  List<Set<Column>> get uniqueKeys => [
        {playlistId, streamId},
      ];
}

class SeriesItems extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get playlistId => text().customConstraint('NOT NULL REFERENCES playlists (id) ON DELETE CASCADE')();
  TextColumn get seriesId => text()();
  TextColumn get name => text()();
  TextColumn get cover => text().nullable()();
  TextColumn get categoryId => text().nullable()();
  TextColumn get plot => text().nullable()();
  RealColumn get rating => real().nullable()();
  IntColumn get year => integer().nullable()();
  DateTimeColumn get addedAt => dateTime().nullable()();
  IntColumn get position => integer().withDefault(const Constant(0))();

  @override
  List<Set<Column>> get uniqueKeys => [
        {playlistId, seriesId},
      ];
}

class Episodes extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get playlistId => text().customConstraint('NOT NULL REFERENCES playlists (id) ON DELETE CASCADE')();
  TextColumn get seriesId => text()();
  TextColumn get episodeId => text()();
  IntColumn get season => integer()();
  IntColumn get episodeNum => integer()();
  TextColumn get title => text()();
  TextColumn get streamUrl => text().withDefault(const Constant(''))();
  TextColumn get containerExtension => text().nullable()();
  TextColumn get poster => text().nullable()();
  IntColumn get durationSecs => integer().nullable()();
  TextColumn get plot => text().nullable()();

  /// e.g. `1920×1080`, when the provider exposes stream info.
  TextColumn get resolution => text().nullable()();

  @override
  List<Set<Column>> get uniqueKeys => [
        {playlistId, episodeId},
      ];
}

@TableIndex(name: 'epg_channel_start', columns: {#playlistId, #channelId, #start})
class EpgPrograms extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get playlistId => text().customConstraint('NOT NULL REFERENCES playlists (id) ON DELETE CASCADE')();
  TextColumn get channelId => text()();
  DateTimeColumn get start => dateTime()();
  DateTimeColumn get end => dateTime()();
  TextColumn get title => text()();
  TextColumn get description => text().nullable()();
}

class Favorites extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get playlistId => text().customConstraint('NOT NULL REFERENCES playlists (id) ON DELETE CASCADE')();
  TextColumn get kind => textEnum<ContentKind>()();
  TextColumn get itemId => text()();
  DateTimeColumn get addedAt => dateTime().withDefault(currentDateAndTime)();

  @override
  List<Set<Column>> get uniqueKeys => [
        {playlistId, kind, itemId},
      ];
}

class History extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get playlistId => text().customConstraint('NOT NULL REFERENCES playlists (id) ON DELETE CASCADE')();
  TextColumn get kind => textEnum<ContentKind>()();

  /// Channel streamId, movie streamId or episodeId.
  TextColumn get itemId => text()();

  /// For episodes: the parent series id, so "continue watching" can group by series.
  TextColumn get parentId => text().nullable()();
  IntColumn get positionMs => integer().withDefault(const Constant(0))();
  IntColumn get durationMs => integer().withDefault(const Constant(0))();
  DateTimeColumn get watchedAt => dateTime().withDefault(currentDateAndTime)();

  @override
  List<Set<Column>> get uniqueKeys => [
        {playlistId, kind, itemId},
      ];
}

class ChannelGroups extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get playlistId => text().customConstraint('NOT NULL REFERENCES playlists (id) ON DELETE CASCADE')();
  TextColumn get name => text()();
}

class GroupChannels extends Table {
  IntColumn get groupId => integer().customConstraint('NOT NULL REFERENCES channel_groups (id) ON DELETE CASCADE')();
  TextColumn get streamId => text()();
  IntColumn get position => integer().withDefault(const Constant(0))();

  @override
  Set<Column> get primaryKey => {groupId, streamId};
}

class LockedChannels extends Table {
  TextColumn get playlistId => text().customConstraint('NOT NULL REFERENCES playlists (id) ON DELETE CASCADE')();
  TextColumn get streamId => text()();

  @override
  Set<Column> get primaryKey => {playlistId, streamId};
}

class HiddenCategories extends Table {
  TextColumn get playlistId => text().customConstraint('NOT NULL REFERENCES playlists (id) ON DELETE CASCADE')();
  TextColumn get kind => textEnum<ContentKind>()();
  TextColumn get categoryId => text()();

  @override
  Set<Column> get primaryKey => {playlistId, kind, categoryId};
}

@DriftDatabase(tables: [
  Playlists,
  Categories,
  Channels,
  Movies,
  SeriesItems,
  Episodes,
  EpgPrograms,
  Favorites,
  History,
  ChannelGroups,
  GroupChannels,
  LockedChannels,
  HiddenCategories,
])
class AppDatabase extends _$AppDatabase {
  AppDatabase([QueryExecutor? executor]) : super(executor ?? _open());

  @override
  int get schemaVersion => 2;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onUpgrade: (m, from, to) async {
          if (from < 2) await m.addColumn(episodes, episodes.resolution);
        },
        beforeOpen: (details) async {
          await customStatement('PRAGMA foreign_keys = ON');
        },
      );

  static QueryExecutor _open() => driftDatabase(name: 'multiptv');

  // ---- Playlists -------------------------------------------------------

  Stream<List<Playlist>> watchPlaylists() =>
      (select(playlists)..orderBy([(p) => OrderingTerm.asc(p.position), (p) => OrderingTerm.asc(p.name)]))
          .watch();

  Future<Playlist?> getPlaylist(String id) =>
      (select(playlists)..where((p) => p.id.equals(id))).getSingleOrNull();

  Future<void> upsertPlaylist(PlaylistsCompanion companion) =>
      into(playlists).insertOnConflictUpdate(companion);

  Future<void> deletePlaylist(String id) => (delete(playlists)..where((p) => p.id.equals(id))).go();

  /// Removes all imported content of a playlist, keeping user data (favorites, history…).
  Future<void> clearPlaylistContent(String playlistId) => transaction(() async {
        await (delete(categories)..where((t) => t.playlistId.equals(playlistId))).go();
        await (delete(channels)..where((t) => t.playlistId.equals(playlistId))).go();
        await (delete(movies)..where((t) => t.playlistId.equals(playlistId))).go();
        await (delete(seriesItems)..where((t) => t.playlistId.equals(playlistId))).go();
        await (delete(episodes)..where((t) => t.playlistId.equals(playlistId))).go();
      });

  Future<void> clearEpg(String playlistId) =>
      (delete(epgPrograms)..where((t) => t.playlistId.equals(playlistId))).go();

  // ---- Content queries --------------------------------------------------

  Future<List<ContentCategory>> getCategories(String playlistId, ContentKind kind) =>
      (select(categories)
            ..where((c) => c.playlistId.equals(playlistId) & c.kind.equalsValue(kind))
            ..orderBy([(c) => OrderingTerm.asc(c.position)]))
          .get();

  Future<List<Channel>> getChannels(String playlistId, {String? categoryId}) {
    final q = select(channels)..where((c) => c.playlistId.equals(playlistId));
    if (categoryId != null) q.where((c) => c.categoryId.equals(categoryId));
    q.orderBy([(c) => OrderingTerm.asc(c.position)]);
    return q.get();
  }

  Future<Channel?> getChannel(String playlistId, String streamId) =>
      (select(channels)..where((c) => c.playlistId.equals(playlistId) & c.streamId.equals(streamId)))
          .getSingleOrNull();

  Future<List<Movie>> getMovies(String playlistId, {String? categoryId}) {
    final q = select(movies)..where((m) => m.playlistId.equals(playlistId));
    if (categoryId != null) q.where((m) => m.categoryId.equals(categoryId));
    q.orderBy([(m) => OrderingTerm.asc(m.position)]);
    return q.get();
  }

  Future<Movie?> getMovie(String playlistId, String streamId) =>
      (select(movies)..where((m) => m.playlistId.equals(playlistId) & m.streamId.equals(streamId)))
          .getSingleOrNull();

  Future<List<SeriesItem>> getSeries(String playlistId, {String? categoryId}) {
    final q = select(seriesItems)..where((s) => s.playlistId.equals(playlistId));
    if (categoryId != null) q.where((s) => s.categoryId.equals(categoryId));
    q.orderBy([(s) => OrderingTerm.asc(s.position)]);
    return q.get();
  }

  Future<SeriesItem?> getSeriesItem(String playlistId, String seriesId) =>
      (select(seriesItems)..where((s) => s.playlistId.equals(playlistId) & s.seriesId.equals(seriesId)))
          .getSingleOrNull();

  Future<List<Episode>> getEpisodes(String playlistId, String seriesId) =>
      (select(episodes)
            ..where((e) => e.playlistId.equals(playlistId) & e.seriesId.equals(seriesId))
            ..orderBy([(e) => OrderingTerm.asc(e.season), (e) => OrderingTerm.asc(e.episodeNum)]))
          .get();

  Future<Episode?> getEpisode(String playlistId, String episodeId) =>
      (select(episodes)..where((e) => e.playlistId.equals(playlistId) & e.episodeId.equals(episodeId)))
          .getSingleOrNull();

  Future<List<Channel>> searchChannels(String playlistId, String query, {int limit = 50}) =>
      (select(channels)
            ..where((c) => c.playlistId.equals(playlistId) & c.name.like('%$query%'))
            ..limit(limit))
          .get();

  Future<List<Movie>> searchMovies(String playlistId, String query, {int limit = 50}) =>
      (select(movies)
            ..where((m) => m.playlistId.equals(playlistId) & m.name.like('%$query%'))
            ..limit(limit))
          .get();

  Future<List<SeriesItem>> searchSeries(String playlistId, String query, {int limit = 50}) =>
      (select(seriesItems)
            ..where((s) => s.playlistId.equals(playlistId) & s.name.like('%$query%'))
            ..limit(limit))
          .get();

  Future<int> countChannels(String playlistId) => _count(channels, playlistId);
  Future<int> countMovies(String playlistId) => _count(movies, playlistId);
  Future<int> countSeries(String playlistId) => _count(seriesItems, playlistId);

  Future<int> _count<T extends Table, D>(TableInfo<T, D> table, String playlistId) async {
    final col = table.columnsByName['playlist_id']! as GeneratedColumn<String>;
    final exp = countAll();
    final row = await (selectOnly(table)
          ..addColumns([exp])
          ..where(col.equals(playlistId)))
        .getSingle();
    return row.read(exp) ?? 0;
  }

  // ---- EPG --------------------------------------------------------------

  Future<List<EpgProgram>> getPrograms(String playlistId, String channelId, {DateTime? from, DateTime? to}) {
    final q = select(epgPrograms)..where((p) => p.playlistId.equals(playlistId) & p.channelId.equals(channelId));
    if (from != null) q.where((p) => p.end.isBiggerThanValue(from));
    if (to != null) q.where((p) => p.start.isSmallerThanValue(to));
    q.orderBy([(p) => OrderingTerm.asc(p.start)]);
    return q.get();
  }

  /// Current and next programme for a channel.
  Future<List<EpgProgram>> getNowNext(String playlistId, String channelId, {DateTime? now}) async {
    final t = now ?? DateTime.now();
    return (select(epgPrograms)
          ..where((p) => p.playlistId.equals(playlistId) & p.channelId.equals(channelId) & p.end.isBiggerThanValue(t))
          ..orderBy([(p) => OrderingTerm.asc(p.start)])
          ..limit(2))
        .get();
  }

  Future<DateTime?> lastEpgUpdate(String playlistId) async {
    final exp = epgPrograms.start.max();
    final row = await (selectOnly(epgPrograms)
          ..addColumns([exp])
          ..where(epgPrograms.playlistId.equals(playlistId)))
        .getSingle();
    return row.read(exp);
  }

  // ---- Favorites / history ---------------------------------------------

  Stream<List<Favorite>> watchFavorites(String playlistId, ContentKind kind) =>
      (select(favorites)
            ..where((f) => f.playlistId.equals(playlistId) & f.kind.equalsValue(kind))
            ..orderBy([(f) => OrderingTerm.desc(f.addedAt)]))
          .watch();

  Stream<bool> watchIsFavorite(String playlistId, ContentKind kind, String itemId) =>
      (select(favorites)
            ..where((f) => f.playlistId.equals(playlistId) & f.kind.equalsValue(kind) & f.itemId.equals(itemId)))
          .watchSingleOrNull()
          .map((f) => f != null);

  Future<void> toggleFavorite(String playlistId, ContentKind kind, String itemId) async {
    final existing = await (select(favorites)
          ..where((f) => f.playlistId.equals(playlistId) & f.kind.equalsValue(kind) & f.itemId.equals(itemId)))
        .getSingleOrNull();
    if (existing != null) {
      await (delete(favorites)..where((f) => f.id.equals(existing.id))).go();
    } else {
      await into(favorites).insert(FavoritesCompanion.insert(playlistId: playlistId, kind: kind, itemId: itemId));
    }
  }

  Stream<List<HistoryData>> watchHistory(String playlistId, ContentKind kind, {int limit = 30}) =>
      (select(history)
            ..where((h) => h.playlistId.equals(playlistId) & h.kind.equalsValue(kind))
            ..orderBy([(h) => OrderingTerm.desc(h.watchedAt)])
            ..limit(limit))
          .watch();

  Future<HistoryData?> getHistory(String playlistId, ContentKind kind, String itemId) =>
      (select(history)
            ..where((h) => h.playlistId.equals(playlistId) & h.kind.equalsValue(kind) & h.itemId.equals(itemId)))
          .getSingleOrNull();

  Future<void> saveHistory({
    required String playlistId,
    required ContentKind kind,
    required String itemId,
    String? parentId,
    int positionMs = 0,
    int durationMs = 0,
  }) =>
      into(history).insert(
        HistoryCompanion.insert(
          playlistId: playlistId,
          kind: kind,
          itemId: itemId,
          parentId: Value(parentId),
          positionMs: Value(positionMs),
          durationMs: Value(durationMs),
          watchedAt: Value(DateTime.now()),
        ),
        onConflict: DoUpdate(
          (_) => HistoryCompanion(
            parentId: Value(parentId),
            positionMs: Value(positionMs),
            durationMs: Value(durationMs),
            watchedAt: Value(DateTime.now()),
          ),
          target: [history.playlistId, history.kind, history.itemId],
        ),
      );

  Future<void> clearHistory(String playlistId) => (delete(history)..where((h) => h.playlistId.equals(playlistId))).go();

  // ---- Parental ---------------------------------------------------------

  Stream<Set<String>> watchLockedChannels(String playlistId) =>
      (select(lockedChannels)..where((l) => l.playlistId.equals(playlistId)))
          .watch()
          .map((rows) => rows.map((r) => r.streamId).toSet());

  Future<void> toggleLockedChannel(String playlistId, String streamId) async {
    final deleted = await (delete(lockedChannels)
          ..where((l) => l.playlistId.equals(playlistId) & l.streamId.equals(streamId)))
        .go();
    if (deleted == 0) {
      await into(lockedChannels).insert(LockedChannelsCompanion.insert(playlistId: playlistId, streamId: streamId));
    }
  }

  Stream<Set<String>> watchHiddenCategories(String playlistId, ContentKind kind) =>
      (select(hiddenCategories)..where((h) => h.playlistId.equals(playlistId) & h.kind.equalsValue(kind)))
          .watch()
          .map((rows) => rows.map((r) => r.categoryId).toSet());

  Future<void> toggleHiddenCategory(String playlistId, ContentKind kind, String categoryId) async {
    final deleted = await (delete(hiddenCategories)
          ..where((h) => h.playlistId.equals(playlistId) & h.kind.equalsValue(kind) & h.categoryId.equals(categoryId)))
        .go();
    if (deleted == 0) {
      await into(hiddenCategories)
          .insert(HiddenCategoriesCompanion.insert(playlistId: playlistId, kind: kind, categoryId: categoryId));
    }
  }

  // ---- Groups -----------------------------------------------------------

  Stream<List<ChannelGroup>> watchGroups(String playlistId) =>
      (select(channelGroups)..where((g) => g.playlistId.equals(playlistId))).watch();

  Future<int> createGroup(String playlistId, String name) =>
      into(channelGroups).insert(ChannelGroupsCompanion.insert(playlistId: playlistId, name: name));

  Future<void> deleteGroup(int groupId) => (delete(channelGroups)..where((g) => g.id.equals(groupId))).go();

  Future<List<Channel>> getGroupChannels(String playlistId, int groupId) async {
    final ids = await (select(groupChannels)
          ..where((g) => g.groupId.equals(groupId))
          ..orderBy([(g) => OrderingTerm.asc(g.position)]))
        .get();
    if (ids.isEmpty) return [];
    final rows = await (select(channels)
          ..where((c) => c.playlistId.equals(playlistId) & c.streamId.isIn(ids.map((e) => e.streamId))))
        .get();
    final byId = {for (final c in rows) c.streamId: c};
    return [for (final g in ids) if (byId[g.streamId] != null) byId[g.streamId]!];
  }

  Future<void> setGroupChannels(int groupId, List<String> streamIds) => transaction(() async {
        await (delete(groupChannels)..where((g) => g.groupId.equals(groupId))).go();
        await batch((b) {
          b.insertAll(groupChannels, [
            for (var i = 0; i < streamIds.length; i++)
              GroupChannelsCompanion.insert(groupId: groupId, streamId: streamIds[i], position: Value(i)),
          ]);
        });
      });
}

final databaseProvider = Provider<AppDatabase>((ref) {
  final db = AppDatabase();
  ref.onDispose(db.close);
  return db;
});
