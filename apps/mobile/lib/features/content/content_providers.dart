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
    final hist = await db.watchHistory(q.playlistId, ContentKind.live).first;
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
    final hist = await db.watchHistory(q.playlistId, ContentKind.vod).first;
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
    final hist = await db.watchHistory(q.playlistId, ContentKind.series).first;
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
