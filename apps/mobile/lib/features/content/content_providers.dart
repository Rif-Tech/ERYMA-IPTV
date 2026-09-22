import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/db/database.dart';
import '../../core/playlist/playlist_importer.dart';
import '../../core/settings/settings.dart';
import '../../core/text/normalize.dart';
import '../playlists/playlists_provider.dart';

/// Pseudo category ids used by the UI on top of provider categories.
abstract final class SpecialCategory {
  static const all = '__all__';
  static const favorites = '__favorites__';
  static const recent = '__recent__';
  static const groupPrefix = '__group__';
}

@immutable
class CategoryQuery {
  const CategoryQuery(this.playlistId, this.kind);
  final String playlistId;
  final ContentKind kind;

  @override
  bool operator ==(Object other) => other is CategoryQuery && other.playlistId == playlistId && other.kind == kind;
  @override
  int get hashCode => Object.hash(playlistId, kind);
}

@immutable
class ContentQuery {
  const ContentQuery(this.playlistId, this.kind, this.categoryId);
  final String playlistId;
  final ContentKind kind;
  final String categoryId;

  @override
  bool operator ==(Object other) =>
      other is ContentQuery && other.playlistId == playlistId && other.kind == kind && other.categoryId == categoryId;
  @override
  int get hashCode => Object.hash(playlistId, kind, categoryId);
}

final hiddenCategoriesProvider = StreamProvider.family<Set<String>, CategoryQuery>((ref, q) {
  return ref.watch(databaseProvider).watchHiddenCategories(q.playlistId, q.kind);
});

/// Visible categories (hidden ones filtered out unless parental control is unlocked in session).
final categoriesProvider = FutureProvider.family<List<ContentCategory>, CategoryQuery>((ref, q) async {
  final db = ref.watch(databaseProvider);
  final hidden = await ref.watch(hiddenCategoriesProvider(q).future);
  final all = await db.getCategories(q.playlistId, q.kind);
  return all.where((c) => !hidden.contains(c.externalId)).toList();
});

final lockedChannelsProvider = StreamProvider.family<Set<String>, String>((ref, playlistId) {
  return ref.watch(databaseProvider).watchLockedChannels(playlistId);
});

final favoriteIdsProvider = StreamProvider.family<Set<String>, CategoryQuery>((ref, q) {
  return ref.watch(databaseProvider).watchFavorites(q.playlistId, q.kind).map((l) => l.map((f) => f.itemId).toSet());
});

/// Live view of the watch history so "recently viewed" lists update as soon as playback starts.
final historyProvider = StreamProvider.family<List<HistoryData>, CategoryQuery>((ref, q) {
  return ref.watch(databaseProvider).watchHistory(q.playlistId, q.kind);
});

final channelsProvider = AsyncNotifierProvider.autoDispose.family<PagedContent<Channel>, Paged<Channel>, ContentQuery>(PagedContent<Channel>.new);
final moviesProvider = AsyncNotifierProvider.autoDispose.family<PagedContent<Movie>, Paged<Movie>, ContentQuery>(PagedContent<Movie>.new);
final seriesProvider = AsyncNotifierProvider.autoDispose.family<PagedContent<SeriesItem>, Paged<SeriesItem>, ContentQuery>(PagedContent<SeriesItem>.new);

/// One loaded window of a listing. `hasMore` drives infinite scrolling in the grids.
@immutable
class Paged<T> {
  const Paged(this.items, {required this.hasMore});
  final List<T> items;
  final bool hasMore;

  static const empty = Paged<Never>([], hasMore: false);
}

/// Catalogue listing loaded page by page straight from SQLite; filtering and sorting never run in
/// Dart, so a 30 000-title playlist costs the same as a 300-title one.
class PagedContent<T> extends AsyncNotifier<Paged<T>> {
  PagedContent(this.query);
  final ContentQuery query;

  static const pageSize = 200;
  bool _loadingMore = false;
  late ContentFilter _filter;

  @override
  Future<Paged<T>> build() async {
    // Only a finished import changes the catalogue; progress ticks must not trigger reloads.
    ref.watch(playlistImportProvider.select((s) => (s.playlistId, s.progress?.stage == ImportStage.done)));
    // The pseudo-categories depend on live tables: favourites and history streams.
    if (query.categoryId == SpecialCategory.favorites) ref.watch(favoriteIdsProvider(CategoryQuery(query.playlistId, query.kind)));
    if (query.categoryId == SpecialCategory.recent) ref.watch(historyProvider(CategoryQuery(query.playlistId, query.kind)));
    final hidden = await ref.watch(hiddenCategoriesProvider(CategoryQuery(query.playlistId, query.kind)).future);
    final sort = ref.watch(settingsProvider.select((s) => s.sortOrder));
    _filter = ContentFilter(
      categoryId: switch (query.categoryId) {
        SpecialCategory.all || SpecialCategory.favorites || SpecialCategory.recent => null,
        final id => id,
      },
      hiddenCategories: hidden,
      favoritesOnly: query.categoryId == SpecialCategory.favorites,
      recentOnly: query.categoryId == SpecialCategory.recent,
      sort: switch (sort) {
        SortOrder.defaultOrder => ContentSort.position,
        SortOrder.az => ContentSort.az,
        SortOrder.za => ContentSort.za,
        SortOrder.added => ContentSort.added,
        SortOrder.rating => ContentSort.rating,
      },
      limit: pageSize,
    );
    final items = await _fetch(0);
    return Paged(items, hasMore: items.length >= pageSize);
  }

  Future<void> loadMore() async {
    final current = state.value;
    if (current == null || !current.hasMore || _loadingMore) return;
    _loadingMore = true;
    try {
      final next = await _fetch(current.items.length);
      if (!ref.mounted) return;
      state = AsyncData(Paged([...current.items, ...next], hasMore: next.length >= pageSize));
    } finally {
      _loadingMore = false;
    }
  }

  Future<List<T>> _fetch(int offset) async {
    final db = ref.read(databaseProvider);
    if (query.categoryId.startsWith(SpecialCategory.groupPrefix)) {
      if (offset > 0) return const [];
      final groupId = int.parse(query.categoryId.substring(SpecialCategory.groupPrefix.length));
      return (await db.getGroupChannels(query.playlistId, groupId)).cast<T>();
    }
    final filter = _filter.page(offset);
    final rows = switch (query.kind) {
      ContentKind.live => await db.queryChannels(query.playlistId, filter),
      ContentKind.vod => await db.queryMovies(query.playlistId, filter),
      ContentKind.series => await db.querySeries(query.playlistId, filter),
    };
    return rows.cast<T>();
  }
}

/// Every channel of the playlist, for management screens (parental locks, groups) only.
final allChannelsProvider = FutureProvider.autoDispose.family<List<Channel>, String>((ref, playlistId) {
  ref.watch(playlistImportProvider.select((s) => (s.playlistId, s.progress?.stage == ImportStage.done)));
  return ref.watch(databaseProvider).getChannels(playlistId);
});

// ---------------------------------------------------------------------------

@immutable
class NowNextQuery {
  const NowNextQuery(this.playlistId, this.epgChannelId);
  final String playlistId;
  final String epgChannelId;
  @override
  bool operator ==(Object other) =>
      other is NowNextQuery && other.playlistId == playlistId && other.epgChannelId == epgChannelId;
  @override
  int get hashCode => Object.hash(playlistId, epgChannelId);
}

final nowNextProvider = FutureProvider.autoDispose.family<List<EpgProgram>, NowNextQuery>((ref, q) {
  return ref.watch(databaseProvider).getNowNext(q.playlistId, q.epgChannelId);
});

/// Now/next for every channel currently listed under [query], fetched in one query and refreshed
/// when the earliest programme ends (instead of one query and one provider per visible row).
final nowNextMapProvider = FutureProvider.autoDispose.family<Map<String, List<EpgProgram>>, ContentQuery>((ref, query) async {
  final page = await ref.watch(channelsProvider(query).future);
  final ids = [for (final c in page.items) if (c.epgChannelId != null && c.epgChannelId!.isNotEmpty) c.epgChannelId!];
  if (ids.isEmpty) return const {};
  final now = DateTime.now();
  final map = await ref.watch(databaseProvider).getNowNextForChannels(query.playlistId, ids, now: now);
  DateTime? nextChange;
  for (final programs in map.values) {
    final end = programs.firstOrNull?.end;
    if (end != null && (nextChange == null || end.isBefore(nextChange))) nextChange = end;
  }
  if (nextChange != null) {
    final delay = nextChange.difference(now);
    final timer = Timer(delay < const Duration(seconds: 30) ? const Duration(seconds: 30) : delay, ref.invalidateSelf);
    ref.onDispose(timer.cancel);
  }
  return map;
});

final programsProvider = FutureProvider.autoDispose.family<List<EpgProgram>, NowNextQuery>((ref, q) {
  final now = DateTime.now();
  return ref.watch(databaseProvider).getPrograms(
        q.playlistId,
        q.epgChannelId,
        from: now.subtract(const Duration(hours: 2)),
        to: now.add(const Duration(hours: 24)),
      );
});

final episodesProvider = FutureProvider.autoDispose.family<List<Episode>, String>((ref, seriesId) async {
  final playlist = ref.watch(activePlaylistProvider);
  if (playlist == null) return const [];
  final db = ref.watch(databaseProvider);
  final cached = await db.getEpisodes(playlist.id, seriesId);
  if (cached.isNotEmpty) return cached;
  return ref.read(playlistImporterProvider).loadEpisodes(playlist, seriesId);
});

final channelGroupsProvider = StreamProvider.family<List<ChannelGroup>, String>((ref, playlistId) {
  return ref.watch(databaseProvider).watchGroups(playlistId);
});

// ---------------------------------------------------------------------------
// Home shelves

final recentMoviesProvider = FutureProvider.family<List<Movie>, String>((ref, playlistId) {
  ref.watch(playlistImportProvider.select((s) => (s.playlistId, s.progress?.stage == ImportStage.done)));
  return ref.watch(databaseProvider).getRecentMovies(playlistId);
});

final recentSeriesProvider = FutureProvider.family<List<SeriesItem>, String>((ref, playlistId) {
  ref.watch(playlistImportProvider.select((s) => (s.playlistId, s.progress?.stage == ImportStage.done)));
  return ref.watch(databaseProvider).getRecentSeries(playlistId);
});

/// Unfinished movies/episodes, most recent first, paired with the item to display.
final continueWatchingProvider = FutureProvider.family<List<(HistoryData, Object)>, String>((ref, playlistId) async {
  final db = ref.watch(databaseProvider);
  final movies = (await ref.watch(historyProvider(CategoryQuery(playlistId, ContentKind.vod)).future)).take(10);
  final episodes = (await ref.watch(historyProvider(CategoryQuery(playlistId, ContentKind.series)).future)).take(10);
  final items = <(HistoryData, Object)>[];
  final seenSeries = <String>{};
  for (final h in [...movies, ...episodes]..sort((a, b) => b.watchedAt.compareTo(a.watchedAt))) {
    if (h.durationMs > 0 && h.positionMs >= h.durationMs * 0.95) continue;
    Object? item;
    if (h.kind == ContentKind.vod) {
      item = await db.getMovie(playlistId, h.itemId);
    } else if (h.parentId != null && seenSeries.add(h.parentId!)) {
      item = await db.getSeriesItem(playlistId, h.parentId!);
    }
    if (item != null) items.add((h, item));
    if (items.length >= 12) break;
  }
  return items;
});

/// Featured carousel from local data: a few resume items first, then the newest movies/series.
final heroItemsProvider = FutureProvider.family<List<HeroItem>, String>((ref, playlistId) async {
  final resume = await ref.watch(continueWatchingProvider(playlistId).future);
  final movies = await ref.watch(recentMoviesProvider(playlistId).future);
  final series = await ref.watch(recentSeriesProvider(playlistId).future);
  return buildHeroItems(resume: resume, movies: movies, series: series);
});

/// What pressing "Play" on a hero entry does.
enum HeroTarget { movie, series, channel, url, none }

/// One carousel slide. Metadata may come from the portal/TMDB while the target is always local.
@immutable
class HeroItem {
  const HeroItem({
    required this.id,
    required this.title,
    this.subtitle,
    this.overview,
    this.year,
    this.posterUrl,
    this.backdropUrl,
    this.tmdbId,
    this.badge,
    this.movie,
    this.series,
    this.channel,
    this.url,
    this.history,
    this.eventAt,
    this.eventEndAt,
  });

  factory HeroItem.forMovie(Movie m, {HistoryData? history}) =>
      HeroItem(id: 'm:${m.streamId}', title: m.name, year: m.year, posterUrl: m.poster, movie: m, history: history);

  factory HeroItem.forSeries(SeriesItem s, {HistoryData? history}) =>
      HeroItem(id: 's:${s.seriesId}', title: s.name, year: s.year, posterUrl: s.cover, overview: s.plot, series: s, history: history);

  final String id;
  final String title;
  final String? subtitle;
  final String? overview;
  final int? year;
  final String? posterUrl;
  final String? backdropUrl;
  final int? tmdbId;

  /// Small label shown next to the meta line (e.g. "Series", "LIVE").
  final String? badge;
  final Movie? movie;
  final SeriesItem? series;
  final Channel? channel;
  final String? url;
  final HistoryData? history;

  /// Scheduled event window for banners (match, live show…).
  final DateTime? eventAt;
  final DateTime? eventEndAt;

  bool get isResume => history != null;

  /// End of the event window; three hours after the start when the admin left it open.
  DateTime? get eventEnd => eventEndAt ?? eventAt?.add(const Duration(hours: 3));

  /// "Live" state starts 15 minutes before the event and lasts until its end.
  bool isLiveAt(DateTime now) =>
      eventAt != null && !now.isBefore(eventAt!.subtract(const Duration(minutes: 15))) && now.isBefore(eventEnd!);

  bool isOverAt(DateTime now) => eventAt != null && !now.isBefore(eventEnd!);

  /// Kept for callers that only need the local object (movie or series).
  Object? get item => movie ?? series ?? channel;

  HeroTarget get target => movie != null
      ? HeroTarget.movie
      : series != null
          ? HeroTarget.series
          : channel != null
              ? HeroTarget.channel
              : url != null
                  ? HeroTarget.url
                  : HeroTarget.none;
}

/// Pure mixing logic, kept separate so it can be unit-tested.
List<HeroItem> buildHeroItems({
  required List<(HistoryData, Object)> resume,
  required List<Movie> movies,
  required List<SeriesItem> series,
  int max = 8,
  int maxResume = 3,
}) {
  final out = <HeroItem>[];
  final ids = <String>{};
  void add(HeroItem h) {
    if (out.length < max && ids.add(h.id)) out.add(h);
  }

  for (final (h, item) in resume.take(maxResume)) {
    add(item is Movie ? HeroItem.forMovie(item, history: h) : HeroItem.forSeries(item as SeriesItem, history: h));
  }
  var i = 0;
  while (out.length < max && (i < movies.length || i < series.length)) {
    if (i < movies.length) add(HeroItem.forMovie(movies[i]));
    if (i < series.length) add(HeroItem.forSeries(series[i]));
    i++;
  }
  return out;
}

@immutable
class SearchResults {
  const SearchResults({this.channels = const [], this.movies = const [], this.series = const []});
  final List<Channel> channels;
  final List<Movie> movies;
  final List<SeriesItem> series;
  bool get isEmpty => channels.isEmpty && movies.isEmpty && series.isEmpty;
}

final searchProvider = FutureProvider.autoDispose.family<SearchResults, String>((ref, query) async {
  final playlist = ref.watch(activePlaylistProvider);
  // Same normalisation as `name_key`, so "Bein" finds "|FR| beIN Sports 1" and `%`/`_` cannot leak into LIKE.
  final key = normalizeTitle(query);
  if (playlist == null || key.length < 2) return const SearchResults();
  final db = ref.watch(databaseProvider);
  final results = await Future.wait<List<dynamic>>([
    db.searchChannels(playlist.id, key),
    db.searchMovies(playlist.id, key),
    db.searchSeries(playlist.id, key),
  ]);
  return SearchResults(
    channels: results[0].cast<Channel>(),
    movies: results[1].cast<Movie>(),
    series: results[2].cast<SeriesItem>(),
  );
});
