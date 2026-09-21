import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/db/database.dart';
import '../../core/settings/settings.dart';
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

final channelsProvider = FutureProvider.family<List<Channel>, ContentQuery>((ref, q) async {
  final db = ref.watch(databaseProvider);
  final sort = ref.watch(settingsProvider.select((s) => s.sortOrder));
  final hidden = await ref.watch(hiddenCategoriesProvider(CategoryQuery(q.playlistId, ContentKind.live)).future);
  List<Channel> list;
  if (q.categoryId == SpecialCategory.all) {
    list = await db.getChannels(q.playlistId);
  } else if (q.categoryId == SpecialCategory.favorites) {
    final favs = await ref.watch(favoriteIdsProvider(CategoryQuery(q.playlistId, ContentKind.live)).future);
    list = (await db.getChannels(q.playlistId)).where((c) => favs.contains(c.streamId)).toList();
  } else if (q.categoryId == SpecialCategory.recent) {
    final hist = await ref.watch(historyProvider(CategoryQuery(q.playlistId, ContentKind.live)).future);
    final ids = hist.map((h) => h.itemId).toList();
    final all = await db.getChannels(q.playlistId);
    final byId = {for (final c in all) c.streamId: c};
    list = [for (final id in ids) if (byId[id] != null) byId[id]!];
    return list;
  } else if (q.categoryId.startsWith(SpecialCategory.groupPrefix)) {
    final groupId = int.parse(q.categoryId.substring(SpecialCategory.groupPrefix.length));
    return db.getGroupChannels(q.playlistId, groupId);
  } else {
    list = await db.getChannels(q.playlistId, categoryId: q.categoryId);
  }
  list = list.where((c) => c.categoryId == null || !hidden.contains(c.categoryId)).toList();
  return _sort(list, sort, (c) => c.name, added: null, rating: null);
});

final moviesProvider = FutureProvider.family<List<Movie>, ContentQuery>((ref, q) async {
  final db = ref.watch(databaseProvider);
  final sort = ref.watch(settingsProvider.select((s) => s.sortOrder));
  final hidden = await ref.watch(hiddenCategoriesProvider(CategoryQuery(q.playlistId, ContentKind.vod)).future);
  List<Movie> list;
  if (q.categoryId == SpecialCategory.all) {
    list = await db.getMovies(q.playlistId);
  } else if (q.categoryId == SpecialCategory.favorites) {
    final favs = await ref.watch(favoriteIdsProvider(CategoryQuery(q.playlistId, ContentKind.vod)).future);
    list = (await db.getMovies(q.playlistId)).where((m) => favs.contains(m.streamId)).toList();
  } else if (q.categoryId == SpecialCategory.recent) {
    final hist = await ref.watch(historyProvider(CategoryQuery(q.playlistId, ContentKind.vod)).future);
    final all = await db.getMovies(q.playlistId);
    final byId = {for (final m in all) m.streamId: m};
    return [for (final h in hist) if (byId[h.itemId] != null) byId[h.itemId]!];
  } else {
    list = await db.getMovies(q.playlistId, categoryId: q.categoryId);
  }
  list = list.where((m) => m.categoryId == null || !hidden.contains(m.categoryId)).toList();
  return _sort(list, sort, (m) => m.name, added: (m) => m.addedAt, rating: (m) => m.rating);
});

final seriesProvider = FutureProvider.family<List<SeriesItem>, ContentQuery>((ref, q) async {
  final db = ref.watch(databaseProvider);
  final sort = ref.watch(settingsProvider.select((s) => s.sortOrder));
  final hidden = await ref.watch(hiddenCategoriesProvider(CategoryQuery(q.playlistId, ContentKind.series)).future);
  List<SeriesItem> list;
  if (q.categoryId == SpecialCategory.all) {
    list = await db.getSeries(q.playlistId);
  } else if (q.categoryId == SpecialCategory.favorites) {
    final favs = await ref.watch(favoriteIdsProvider(CategoryQuery(q.playlistId, ContentKind.series)).future);
    list = (await db.getSeries(q.playlistId)).where((s) => favs.contains(s.seriesId)).toList();
  } else if (q.categoryId == SpecialCategory.recent) {
    final hist = await ref.watch(historyProvider(CategoryQuery(q.playlistId, ContentKind.series)).future);
    final all = await db.getSeries(q.playlistId);
    final byId = {for (final s in all) s.seriesId: s};
    final seen = <String>{};
    return [
      for (final h in hist)
        if (h.parentId != null && byId[h.parentId] != null && seen.add(h.parentId!)) byId[h.parentId]!,
    ];
  } else {
    list = await db.getSeries(q.playlistId, categoryId: q.categoryId);
  }
  list = list.where((s) => s.categoryId == null || !hidden.contains(s.categoryId)).toList();
  return _sort(list, sort, (s) => s.name, added: (s) => s.addedAt, rating: (s) => s.rating);
});

List<T> _sort<T>(
  List<T> list,
  SortOrder order,
  String Function(T) name, {
  DateTime? Function(T)? added,
  double? Function(T)? rating,
}) {
  final copy = List<T>.of(list);
  int cmpName(T a, T b) => name(a).toLowerCase().compareTo(name(b).toLowerCase());
  switch (order) {
    case SortOrder.defaultOrder:
      break;
    case SortOrder.az:
      copy.sort(cmpName);
    case SortOrder.za:
      copy.sort((a, b) => cmpName(b, a));
    case SortOrder.added:
      if (added != null) {
        copy.sort((a, b) => (added(b) ?? DateTime(0)).compareTo(added(a) ?? DateTime(0)));
      }
    case SortOrder.rating:
      if (rating != null) {
        copy.sort((a, b) => (rating(b) ?? 0).compareTo(rating(a) ?? 0));
      }
  }
  return copy;
}

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

final nowNextProvider = FutureProvider.family<List<EpgProgram>, NowNextQuery>((ref, q) {
  return ref.watch(databaseProvider).getNowNext(q.playlistId, q.epgChannelId);
});

final programsProvider = FutureProvider.family<List<EpgProgram>, NowNextQuery>((ref, q) {
  final now = DateTime.now();
  return ref.watch(databaseProvider).getPrograms(
        q.playlistId,
        q.epgChannelId,
        from: now.subtract(const Duration(hours: 2)),
        to: now.add(const Duration(hours: 24)),
      );
});

final episodesProvider = FutureProvider.family<List<Episode>, String>((ref, seriesId) async {
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
  ref.watch(playlistImportProvider);
  return ref.watch(databaseProvider).getRecentMovies(playlistId);
});

final recentSeriesProvider = FutureProvider.family<List<SeriesItem>, String>((ref, playlistId) {
  ref.watch(playlistImportProvider);
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

final searchProvider = FutureProvider.family<SearchResults, String>((ref, query) async {
  final playlist = ref.watch(activePlaylistProvider);
  final q = query.trim();
  if (playlist == null || q.length < 2) return const SearchResults();
  final db = ref.watch(databaseProvider);
  final results = await Future.wait<List<dynamic>>([
    db.searchChannels(playlist.id, q),
    db.searchMovies(playlist.id, q),
    db.searchSeries(playlist.id, q),
  ]);
  return SearchResults(
    channels: results[0].cast<Channel>(),
    movies: results[1].cast<Movie>(),
    series: results[2].cast<SeriesItem>(),
  );
});
