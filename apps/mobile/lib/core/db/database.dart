// TableMigration (schema v4 rebuild) is still flagged experimental by drift.
// ignore_for_file: experimental_member_use

import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

part 'database.g.dart';

enum PlaylistType { m3u, xtream }

enum PlaylistSource { portal, local }

enum ContentKind { live, vod, series }

enum ContentSort { position, az, za, added, rating }

/// One page of a catalogue listing; every predicate is evaluated by SQLite.
class ContentFilter {
  const ContentFilter({
    this.categoryId,
    this.hiddenCategories = const {},
    this.favoritesOnly = false,
    this.recentOnly = false,
    this.sort = ContentSort.position,
    this.limit = 200,
    this.offset = 0,
  });

  final String? categoryId;
  final Set<String> hiddenCategories;
  final bool favoritesOnly;
  final bool recentOnly;
  final ContentSort sort;
  final int limit;
  final int offset;

  ContentFilter page(int offset) => ContentFilter(
        categoryId: categoryId,
        hiddenCategories: hiddenCategories,
        favoritesOnly: favoritesOnly,
        recentOnly: recentOnly,
        sort: sort,
        limit: limit,
        offset: offset,
      );
}

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
@TableIndex(name: 'categories_playlist_kind', columns: {#playlistId, #kind, #position})
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

@TableIndex(name: 'channels_playlist_category', columns: {#playlistId, #categoryId, #position})
@TableIndex(name: 'channels_name_key', columns: {#playlistId, #nameKey})
class Channels extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get playlistId => text().customConstraint('NOT NULL REFERENCES playlists (id) ON DELETE CASCADE')();
  TextColumn get streamId => text()();
  TextColumn get name => text()();

  /// [normalizeTitle] of [name]; lets matching and search stay in SQL.
  TextColumn get nameKey => text().withDefault(const Constant(''))();
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
@TableIndex(name: 'movies_playlist_category', columns: {#playlistId, #categoryId, #position})
@TableIndex(name: 'movies_added', columns: {#playlistId, #addedAt})
@TableIndex(name: 'movies_name_key', columns: {#playlistId, #nameKey})
class Movies extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get playlistId => text().customConstraint('NOT NULL REFERENCES playlists (id) ON DELETE CASCADE')();
  TextColumn get streamId => text()();
  TextColumn get name => text()();
  TextColumn get nameKey => text().withDefault(const Constant(''))();
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

@TableIndex(name: 'series_playlist_category', columns: {#playlistId, #categoryId, #position})
@TableIndex(name: 'series_added', columns: {#playlistId, #addedAt})
@TableIndex(name: 'series_name_key', columns: {#playlistId, #nameKey})
class SeriesItems extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get playlistId => text().customConstraint('NOT NULL REFERENCES playlists (id) ON DELETE CASCADE')();
  TextColumn get seriesId => text()();
  TextColumn get name => text()();
  TextColumn get nameKey => text().withDefault(const Constant(''))();
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

@TableIndex(name: 'episodes_series', columns: {#playlistId, #seriesId, #season, #episodeNum})
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
@TableIndex(name: 'epg_channel_end', columns: {#playlistId, #channelId, #end})
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

  /// Viewer profile (server id); '' for rows written before profiles existed.
  TextColumn get profileId => text().withDefault(const Constant(''))();
  TextColumn get kind => textEnum<ContentKind>()();
  TextColumn get itemId => text()();
  DateTimeColumn get addedAt => dateTime().withDefault(currentDateAndTime)();

  @override
  List<Set<Column>> get uniqueKeys => [
        {profileId, playlistId, kind, itemId},
      ];
}

@TableIndex(name: 'history_recent', columns: {#profileId, #playlistId, #kind, #watchedAt})
class History extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get playlistId => text().customConstraint('NOT NULL REFERENCES playlists (id) ON DELETE CASCADE')();

  /// Viewer profile (server id); '' for rows written before profiles existed.
  TextColumn get profileId => text().withDefault(const Constant(''))();
  TextColumn get kind => textEnum<ContentKind>()();

  /// Channel streamId, movie streamId or episodeId.
  TextColumn get itemId => text()();

  /// For episodes: the parent series id, so "continue watching" can group by series.
  TextColumn get parentId => text().nullable()();
  IntColumn get positionMs => integer().withDefault(const Constant(0))();
  IntColumn get durationMs => integer().withDefault(const Constant(0))();
  DateTimeColumn get watchedAt => dateTime().withDefault(currentDateAndTime)();

  /// Last time this row was uploaded to `watch_progress`; null = pending upload.
  DateTimeColumn get syncedAt => dateTime().nullable()();

  @override
  List<Set<Column>> get uniqueKeys => [
        {profileId, playlistId, kind, itemId},
      ];
}

class ChannelGroups extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get playlistId => text().customConstraint('NOT NULL REFERENCES playlists (id) ON DELETE CASCADE')();
  TextColumn get profileId => text().withDefault(const Constant(''))();
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
  TextColumn get profileId => text().withDefault(const Constant(''))();
  TextColumn get streamId => text()();

  @override
  Set<Column> get primaryKey => {profileId, playlistId, streamId};
}

class HiddenCategories extends Table {
  TextColumn get playlistId => text().customConstraint('NOT NULL REFERENCES playlists (id) ON DELETE CASCADE')();
  TextColumn get profileId => text().withDefault(const Constant(''))();
  TextColumn get kind => textEnum<ContentKind>()();
  TextColumn get categoryId => text()();

  @override
  Set<Column> get primaryKey => {profileId, playlistId, kind, categoryId};
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

  /// Viewer profile whose favourites/history/parental settings are read and written. '' until a
  /// profile is picked (and for data created before profiles existed).
  String profileId = '';

  @override
  int get schemaVersion => 4;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onUpgrade: (m, from, to) async {
          if (from < 2) await m.addColumn(episodes, episodes.resolution);
          if (from < 3) {
            await m.addColumn(channels, channels.nameKey);
            await m.addColumn(movies, movies.nameKey);
            await m.addColumn(seriesItems, seriesItems.nameKey);
            for (final index in allSchemaEntities.whereType<Index>()) {
              if (index.entityName != 'epg_channel_start') await m.createIndex(index);
            }
            // name_key is filled at import time: force a refresh of every playlist.
            await update(playlists).write(const PlaylistsCompanion(lastSyncedAt: Value(null)));
          }
          if (from < 4) {
            // Per-profile scoping: existing rows keep profile_id = '' and are claimed by the first
            // profile selected on this device (see [claimLegacyProfileData]). Primary/unique keys
            // change, so the tables are rebuilt in place with their data.
            await m.alterTable(TableMigration(favorites, newColumns: [favorites.profileId]));
            await m.alterTable(TableMigration(history, newColumns: [history.profileId, history.syncedAt]));
            await m.alterTable(TableMigration(lockedChannels, newColumns: [lockedChannels.profileId]));
            await m.alterTable(TableMigration(hiddenCategories, newColumns: [hiddenCategories.profileId]));
            await m.addColumn(channelGroups, channelGroups.profileId);
            await m.createIndex(historyRecent);
          }
        },
        beforeOpen: (details) async {
          await customStatement('PRAGMA foreign_keys = ON');
        },
      );

  static QueryExecutor _open() => driftDatabase(name: 'multiptv');

  /// Attributes rows written before profiles existed (profile_id = '') to [profile]. Runs once,
  /// when the first profile is chosen on this install, so nobody loses their history.
  Future<void> claimLegacyProfileData(String profile) => transaction(() async {
        final tables = <TableInfo>[favorites, history, lockedChannels, hiddenCategories, channelGroups];
        for (final table in tables) {
          await customUpdate(
            'UPDATE ${table.actualTableName} SET profile_id = ? WHERE profile_id = \'\'',
            variables: [Variable.withString(profile)],
            updates: {table},
          );
        }
      });

  /// Whether any legacy (unscoped) personal data still exists.
  Future<bool> hasLegacyProfileData() async {
    final n = await (selectOnly(history)
          ..addColumns([countAll()])
          ..where(history.profileId.equals('')))
        .map((r) => r.read(countAll()) ?? 0)
        .getSingle();
    if (n > 0) return true;
    final f = await (selectOnly(favorites)
          ..addColumns([countAll()])
          ..where(favorites.profileId.equals('')))
        .map((r) => r.read(countAll()) ?? 0)
        .getSingle();
    return f > 0;
  }

  // ---- Playlists -------------------------------------------------------

  Stream<List<Playlist>> watchPlaylists() =>
      (select(playlists)..orderBy([(p) => OrderingTerm.asc(p.position), (p) => OrderingTerm.asc(p.name)]))
          .watch();

  Future<Playlist?> getPlaylist(String id) =>
      (select(playlists)..where((p) => p.id.equals(id))).getSingleOrNull();

  Future<void> upsertPlaylist(PlaylistsCompanion companion) =>
      into(playlists).insertOnConflictUpdate(companion);

  Future<void> deletePlaylist(String id) => (delete(playlists)..where((p) => p.id.equals(id))).go();

  /// Removes imported content of a playlist (one [kind] or all), keeping user data (favorites, history…).
  Future<void> clearPlaylistContent(String playlistId, {ContentKind? kind}) => transaction(() async {
        final cats = delete(categories)..where((t) => t.playlistId.equals(playlistId));
        if (kind != null) cats.where((t) => t.kind.equalsValue(kind));
        await cats.go();
        if (kind == null || kind == ContentKind.live) {
          await (delete(channels)..where((t) => t.playlistId.equals(playlistId))).go();
        }
        if (kind == null || kind == ContentKind.vod) {
          await (delete(movies)..where((t) => t.playlistId.equals(playlistId))).go();
        }
        if (kind == null || kind == ContentKind.series) {
          await (delete(seriesItems)..where((t) => t.playlistId.equals(playlistId))).go();
          await (delete(episodes)..where((t) => t.playlistId.equals(playlistId))).go();
        }
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

  // ---- Paged, filtered, sorted content (everything stays in SQL) ----------

  Future<List<Channel>> queryChannels(String playlistId, ContentFilter f) =>
      _queryContent<Channels, Channel>(channels, ContentKind.live, playlistId, f,
          idColumn: channels.streamId, name: channels.name, position: channels.position, category: channels.categoryId);

  Future<List<Movie>> queryMovies(String playlistId, ContentFilter f) => _queryContent<Movies, Movie>(movies, ContentKind.vod, playlistId, f,
      idColumn: movies.streamId, name: movies.name, position: movies.position, category: movies.categoryId, added: movies.addedAt, rating: movies.rating);

  Future<List<SeriesItem>> querySeries(String playlistId, ContentFilter f) =>
      _queryContent<SeriesItems, SeriesItem>(seriesItems, ContentKind.series, playlistId, f,
          idColumn: seriesItems.seriesId,
          name: seriesItems.name,
          position: seriesItems.position,
          category: seriesItems.categoryId,
          added: seriesItems.addedAt,
          rating: seriesItems.rating);

  Future<List<D>> _queryContent<T extends Table, D>(
    TableInfo<T, D> table,
    ContentKind kind,
    String playlistId,
    ContentFilter f, {
    required GeneratedColumn<String> idColumn,
    required GeneratedColumn<String> name,
    required GeneratedColumn<int> position,
    required GeneratedColumn<String> category,
    GeneratedColumn<DateTime>? added,
    GeneratedColumn<double>? rating,
  }) async {
    final playlistCol = table.columnsByName['playlist_id']! as GeneratedColumn<String>;
    final joins = <Join>[];
    Expression<bool> where = playlistCol.equals(playlistId);
    if (f.categoryId != null) where = where & category.equals(f.categoryId!);
    if (f.hiddenCategories.isNotEmpty) where = where & (category.isNull() | category.isNotIn(f.hiddenCategories));
    if (f.favoritesOnly) {
      joins.add(innerJoin(
        favorites,
        favorites.profileId.equals(profileId) & favorites.playlistId.equalsExp(playlistCol) & favorites.kind.equalsValue(kind) & favorites.itemId.equalsExp(idColumn),
        useColumns: false,
      ));
    }
    if (f.recentOnly) {
      // Series are keyed by the parent id of the watched episode.
      final key = kind == ContentKind.series ? history.parentId : history.itemId;
      joins.add(innerJoin(
        history,
        history.profileId.equals(profileId) & history.playlistId.equalsExp(playlistCol) & history.kind.equalsValue(kind) & key.equalsExp(idColumn),
        useColumns: false,
      ));
    }
    // "Tout" (no category picked) groups by bouquet order, like the playlist itself, instead of
    // raw import order: join each item's category to read its position.
    final byBouquet = f.categoryId == null && !f.recentOnly && f.sort == ContentSort.position;
    if (byBouquet) {
      joins.add(leftOuterJoin(
        categories,
        categories.playlistId.equalsExp(playlistCol) & categories.kind.equalsValue(kind) & categories.externalId.equalsExp(category),
        useColumns: false,
      ));
    }
    final order = <OrderingTerm>[
      if (f.recentOnly)
        OrderingTerm.desc(history.watchedAt)
      else if (byBouquet)
        OrderingTerm(expression: categories.position, mode: OrderingMode.asc, nulls: NullsOrder.last)
      else
        switch (f.sort) {
          ContentSort.position => OrderingTerm.asc(position),
          ContentSort.az => OrderingTerm.asc(name.collate(Collate.noCase)),
          ContentSort.za => OrderingTerm.desc(name.collate(Collate.noCase)),
          ContentSort.added => added == null ? OrderingTerm.asc(position) : OrderingTerm(expression: added, mode: OrderingMode.desc, nulls: NullsOrder.last),
          ContentSort.rating => rating == null ? OrderingTerm.asc(position) : OrderingTerm(expression: rating, mode: OrderingMode.desc, nulls: NullsOrder.last),
        },
      OrderingTerm.asc(position),
    ];
    final q = select(table).join(joins)
      ..where(where)
      ..orderBy(order)
      ..limit(f.limit, offset: f.offset);
    final rows = await q.get();
    return rows.map((r) => r.readTable(table)).toList();
  }

  /// Rows whose normalised title is exactly one of [keys] (featured matching).
  Future<List<Movie>> moviesByNameKeys(String playlistId, Iterable<String> keys) =>
      (select(movies)..where((m) => m.playlistId.equals(playlistId) & m.nameKey.isIn(keys))).get();

  Future<List<SeriesItem>> seriesByNameKeys(String playlistId, Iterable<String> keys) =>
      (select(seriesItems)..where((s) => s.playlistId.equals(playlistId) & s.nameKey.isIn(keys))).get();

  Future<List<Channel>> channelsByNameKeys(String playlistId, Iterable<String> keys) =>
      (select(channels)..where((c) => c.playlistId.equals(playlistId) & c.nameKey.isIn(keys))).get();

  /// First channel whose normalised name contains every word of [key] (`bein sports 1`).
  Future<Channel?> channelContainingWords(String playlistId, String key) {
    final words = key.split(' ').where((w) => w.isNotEmpty);
    if (words.isEmpty) return Future.value(null);
    Expression<bool> where = channels.playlistId.equals(playlistId);
    for (final w in words) {
      where = where & channels.nameKey.like('%$w%');
    }
    return (select(channels)
          ..where((_) => where)
          ..orderBy([(c) => OrderingTerm.asc(c.position)])
          ..limit(1))
        .getSingleOrNull();
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

  /// Newest movies by provider `added` date (falls back to import order when dates are missing).
  Future<List<Movie>> getRecentMovies(String playlistId, {int limit = 20}) =>
      (select(movies)
            ..where((m) => m.playlistId.equals(playlistId))
            ..orderBy([(m) => OrderingTerm.desc(m.addedAt), (m) => OrderingTerm.asc(m.position)])
            ..limit(limit))
          .get();

  Future<List<SeriesItem>> getRecentSeries(String playlistId, {int limit = 20}) =>
      (select(seriesItems)
            ..where((s) => s.playlistId.equals(playlistId))
            ..orderBy([(s) => OrderingTerm.desc(s.addedAt), (s) => OrderingTerm.asc(s.position)])
            ..limit(limit))
          .get();

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

  /// Accent/tag-insensitive search on `name_key`; prefix matches rank first. [key] must already be
  /// normalised and free of `%`/`_`.
  Future<List<Channel>> searchChannels(String playlistId, String key, {int limit = 50}) =>
      (select(channels)
            ..where((c) => c.playlistId.equals(playlistId) & c.nameKey.like('%$key%'))
            ..orderBy([(c) => OrderingTerm.asc(_prefixRank(c.nameKey, key)), (c) => OrderingTerm.asc(c.position)])
            ..limit(limit))
          .get();

  Future<List<Movie>> searchMovies(String playlistId, String key, {int limit = 50}) =>
      (select(movies)
            ..where((m) => m.playlistId.equals(playlistId) & m.nameKey.like('%$key%'))
            ..orderBy([(m) => OrderingTerm.asc(_prefixRank(m.nameKey, key)), (m) => OrderingTerm.asc(m.position)])
            ..limit(limit))
          .get();

  Future<List<SeriesItem>> searchSeries(String playlistId, String key, {int limit = 50}) =>
      (select(seriesItems)
            ..where((s) => s.playlistId.equals(playlistId) & s.nameKey.like('%$key%'))
            ..orderBy([(s) => OrderingTerm.asc(_prefixRank(s.nameKey, key)), (s) => OrderingTerm.asc(s.position)])
            ..limit(limit))
          .get();

  static Expression<int> _prefixRank(GeneratedColumn<String> col, String key) =>
      CaseWhenExpression<int>(cases: [CaseWhen(col.like('$key%'), then: const Constant(0))], orElse: const Constant(1));

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

  /// Now/next for many channels in one round trip (one list screen = one query, not one per row).
  Future<Map<String, List<EpgProgram>>> getNowNextForChannels(String playlistId, Iterable<String> channelIds, {DateTime? now}) async {
    final t = now ?? DateTime.now();
    final ids = channelIds.where((id) => id.isNotEmpty).toSet().toList();
    final out = <String, List<EpgProgram>>{};
    // Stay well under SQLite's bound-parameter limit on older Android builds.
    for (var i = 0; i < ids.length; i += 400) {
      final chunk = ids.sublist(i, (i + 400).clamp(0, ids.length));
      final rows = await (select(epgPrograms)
            ..where((p) => p.playlistId.equals(playlistId) & p.channelId.isIn(chunk) & p.end.isBiggerThanValue(t))
            ..orderBy([(p) => OrderingTerm.asc(p.channelId), (p) => OrderingTerm.asc(p.start)]))
          .get();
      for (final r in rows) {
        final list = out[r.channelId] ??= [];
        if (list.length < 2) list.add(r);
      }
    }
    return out;
  }

  /// Drops programmes outside the retention window so the EPG table cannot grow unbounded.
  Future<int> purgeEpg({Duration keepPast = const Duration(days: 2), Duration keepFuture = const Duration(days: 7)}) {
    final now = DateTime.now();
    return (delete(epgPrograms)
          ..where((p) => p.end.isSmallerThanValue(now.subtract(keepPast)) | p.start.isBiggerThanValue(now.add(keepFuture))))
        .go();
  }

  Future<DateTime?> lastEpgUpdate(String playlistId) async {
    final exp = epgPrograms.start.max();
    final row = await (selectOnly(epgPrograms)
          ..addColumns([exp])
          ..where(epgPrograms.playlistId.equals(playlistId)))
        .getSingle();
    return row.read(exp);
  }

  // ---- Favorites / history (scoped to [profileId]) ----------------------

  Stream<List<Favorite>> watchFavorites(String playlistId, ContentKind kind) =>
      (select(favorites)
            ..where((f) => f.profileId.equals(profileId) & f.playlistId.equals(playlistId) & f.kind.equalsValue(kind))
            ..orderBy([(f) => OrderingTerm.desc(f.addedAt)]))
          .watch();

  Stream<bool> watchIsFavorite(String playlistId, ContentKind kind, String itemId) =>
      (select(favorites)
            ..where((f) => f.profileId.equals(profileId) & f.playlistId.equals(playlistId) & f.kind.equalsValue(kind) & f.itemId.equals(itemId)))
          .watchSingleOrNull()
          .map((f) => f != null);

  Future<void> toggleFavorite(String playlistId, ContentKind kind, String itemId) async {
    final existing = await (select(favorites)
          ..where((f) => f.profileId.equals(profileId) & f.playlistId.equals(playlistId) & f.kind.equalsValue(kind) & f.itemId.equals(itemId)))
        .getSingleOrNull();
    if (existing != null) {
      await (delete(favorites)..where((f) => f.id.equals(existing.id))).go();
    } else {
      await into(favorites).insert(FavoritesCompanion.insert(playlistId: playlistId, profileId: Value(profileId), kind: kind, itemId: itemId));
    }
  }

  Stream<List<HistoryData>> watchHistory(String playlistId, ContentKind kind, {int limit = 30}) =>
      (select(history)
            ..where((h) => h.profileId.equals(profileId) & h.playlistId.equals(playlistId) & h.kind.equalsValue(kind))
            ..orderBy([(h) => OrderingTerm.desc(h.watchedAt)])
            ..limit(limit))
          .watch();

  Future<HistoryData?> getHistory(String playlistId, ContentKind kind, String itemId) =>
      (select(history)
            ..where((h) => h.profileId.equals(profileId) & h.playlistId.equals(playlistId) & h.kind.equalsValue(kind) & h.itemId.equals(itemId)))
          .getSingleOrNull();

  /// Upserts a history row for the current profile. [watchedAt] defaults to now; [synced] marks
  /// rows that came from the server (nothing to upload).
  Future<void> saveHistory({
    required String playlistId,
    required ContentKind kind,
    required String itemId,
    String? parentId,
    int positionMs = 0,
    int durationMs = 0,
    DateTime? watchedAt,
    bool synced = false,
  }) {
    final at = watchedAt ?? DateTime.now();
    final syncedAt = synced ? Value(at) : const Value<DateTime?>(null);
    return into(history).insert(
      HistoryCompanion.insert(
        playlistId: playlistId,
        profileId: Value(profileId),
        kind: kind,
        itemId: itemId,
        parentId: Value(parentId),
        positionMs: Value(positionMs),
        durationMs: Value(durationMs),
        watchedAt: Value(at),
        syncedAt: syncedAt,
      ),
      onConflict: DoUpdate(
        (_) => HistoryCompanion(
          parentId: Value(parentId),
          positionMs: Value(positionMs),
          durationMs: Value(durationMs),
          watchedAt: Value(at),
          syncedAt: syncedAt,
        ),
        target: [history.profileId, history.playlistId, history.kind, history.itemId],
      ),
    );
  }

  /// History rows of the current profile not yet uploaded to the server.
  Future<List<HistoryData>> pendingHistory(String playlistId, {int limit = 200}) =>
      (select(history)
            ..where((h) => h.profileId.equals(profileId) & h.playlistId.equals(playlistId) & h.syncedAt.isNull())
            ..orderBy([(h) => OrderingTerm.desc(h.watchedAt)])
            ..limit(limit))
          .get();

  Future<void> markHistorySynced(Iterable<int> ids, DateTime at) =>
      (update(history)..where((h) => h.id.isIn(ids))).write(HistoryCompanion(syncedAt: Value(at)));

  Future<void> clearHistory(String playlistId) =>
      (delete(history)..where((h) => h.profileId.equals(profileId) & h.playlistId.equals(playlistId))).go();

  // ---- Parental (scoped to [profileId]) -----------------------------------

  Stream<Set<String>> watchLockedChannels(String playlistId) =>
      (select(lockedChannels)..where((l) => l.profileId.equals(profileId) & l.playlistId.equals(playlistId)))
          .watch()
          .map((rows) => rows.map((r) => r.streamId).toSet());

  Future<void> toggleLockedChannel(String playlistId, String streamId) async {
    final deleted = await (delete(lockedChannels)
          ..where((l) => l.profileId.equals(profileId) & l.playlistId.equals(playlistId) & l.streamId.equals(streamId)))
        .go();
    if (deleted == 0) {
      await into(lockedChannels).insert(LockedChannelsCompanion.insert(playlistId: playlistId, profileId: Value(profileId), streamId: streamId));
    }
  }

  Stream<Set<String>> watchHiddenCategories(String playlistId, ContentKind kind) =>
      (select(hiddenCategories)..where((h) => h.profileId.equals(profileId) & h.playlistId.equals(playlistId) & h.kind.equalsValue(kind)))
          .watch()
          .map((rows) => rows.map((r) => r.categoryId).toSet());

  Future<void> toggleHiddenCategory(String playlistId, ContentKind kind, String categoryId) async {
    final deleted = await (delete(hiddenCategories)
          ..where((h) => h.profileId.equals(profileId) & h.playlistId.equals(playlistId) & h.kind.equalsValue(kind) & h.categoryId.equals(categoryId)))
        .go();
    if (deleted == 0) {
      await into(hiddenCategories)
          .insert(HiddenCategoriesCompanion.insert(playlistId: playlistId, profileId: Value(profileId), kind: kind, categoryId: categoryId));
    }
  }

  // ---- Groups (scoped to [profileId]) -------------------------------------

  Stream<List<ChannelGroup>> watchGroups(String playlistId) =>
      (select(channelGroups)..where((g) => g.profileId.equals(profileId) & g.playlistId.equals(playlistId))).watch();

  Future<int> createGroup(String playlistId, String name) =>
      into(channelGroups).insert(ChannelGroupsCompanion.insert(playlistId: playlistId, profileId: Value(profileId), name: name));

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
