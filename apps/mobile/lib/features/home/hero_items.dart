import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/db/database.dart';
import '../content/content_providers.dart';

// Home hero slides built from local data (resume items, newest titles). Remote "À la une" entries
// are matched into the same HeroItem in featured_provider.dart.

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
