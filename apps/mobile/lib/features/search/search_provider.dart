import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/db/database.dart';
import '../../core/text/normalize.dart';
import '../playlists/playlists_provider.dart';

// Global search over the active playlist (channels, movies, series).

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
