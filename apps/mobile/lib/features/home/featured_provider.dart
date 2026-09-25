import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/api/portal_api.dart';
import '../../core/db/database.dart';
import '../../core/device/device_identity.dart';
import '../../core/playlist/playlist_importer.dart';
import '../../core/settings/settings.dart';
import '../../core/text/normalize.dart';
import '../content/metadata_providers.dart';
import '../playlists/playlists_provider.dart';
import 'hero_items.dart';

export '../../core/text/normalize.dart' show normalizeTitle, yearFromTitle;

// ---------------------------------------------------------------------------
// Matching remote entries against the local catalogue.

/// Case-folded lookup tables built once per playlist.
class LocalCatalog {
  LocalCatalog({required List<Movie> movies, required List<SeriesItem> series, required List<Channel> channels}) {
    for (final m in movies) {
      (_movies[_key(m.nameKey, m.name)] ??= []).add(m);
    }
    for (final s in series) {
      (_series[_key(s.nameKey, s.name)] ??= []).add(s);
    }
    for (final c in channels) {
      final key = _key(c.nameKey, c.name);
      _channels[key] ??= c;
      _channelList.add((key, c));
    }
  }

  // Rows imported before schema v3 carry an empty name_key until their playlist is refreshed.
  static String _key(String stored, String name) => stored.isNotEmpty ? stored : normalizeTitle(name);

  /// Loads only the rows that can match [entries] (exact `name_key`, plus word-contains for
  /// channels), instead of the whole catalogue.
  static Future<LocalCatalog> forEntries(AppDatabase db, String playlistId, List<FeaturedEntry> entries) async {
    final movieKeys = <String>{};
    final seriesKeys = <String>{};
    final channelKeys = <String>{};
    for (final e in entries) {
      final key = normalizeTitle(e.linkQuery ?? e.title);
      if (key.isEmpty) continue;
      switch (e.kind) {
        case 'movie':
          movieKeys.add(key);
        case 'tv':
          seriesKeys.add(key);
        case 'live':
          channelKeys.add(key);
        default:
          switch (e.linkKind) {
            case 'channel':
              channelKeys.add(key);
            case 'movie':
              movieKeys.add(key);
            case 'series':
              seriesKeys.add(key);
          }
      }
    }
    final movies = movieKeys.isEmpty ? const <Movie>[] : await db.moviesByNameKeys(playlistId, movieKeys);
    final series = seriesKeys.isEmpty ? const <SeriesItem>[] : await db.seriesByNameKeys(playlistId, seriesKeys);
    final channels = channelKeys.isEmpty ? <Channel>[] : await db.channelsByNameKeys(playlistId, channelKeys);
    final exact = {for (final c in channels) c.nameKey};
    for (final key in channelKeys.where((k) => !exact.contains(k))) {
      final c = await db.channelContainingWords(playlistId, key);
      if (c != null) channels.add(c);
    }
    return LocalCatalog(movies: movies, series: series, channels: channels);
  }

  final _movies = <String, List<Movie>>{};
  final _series = <String, List<SeriesItem>>{};
  final _channels = <String, Channel>{};
  final _channelList = <(String, Channel)>[];

  bool get isEmpty => _movies.isEmpty && _series.isEmpty && _channels.isEmpty;

  Movie? movie(String title, int? year) => _pick(_movies[normalizeTitle(title)], year, (m) => m.year ?? yearFromTitle(m.name));

  SeriesItem? series(String title, int? year) => _pick(_series[normalizeTitle(title)], year, (s) => s.year ?? yearFromTitle(s.name));

  /// Exact name first, then the first channel containing every query word.
  Channel? channel(String query) {
    final key = normalizeTitle(query);
    if (key.isEmpty) return null;
    final exact = _channels[key];
    if (exact != null) return exact;
    final words = key.split(' ');
    for (final (k, c) in _channelList) {
      final have = k.split(' ').toSet();
      if (words.every(have.contains)) return c;
    }
    return null;
  }

  static T? _pick<T>(List<T>? candidates, int? year, int? Function(T) yearOf) {
    if (candidates == null || candidates.isEmpty) return null;
    if (year == null) return candidates.first;
    for (final c in candidates) {
      final y = yearOf(c);
      if (y == null || (y - year).abs() <= 1) return c;
    }
    return null;
  }
}

/// Turns portal entries into slides, dropping those the device cannot play when required.
List<HeroItem> matchFeatured(List<FeaturedEntry> entries, LocalCatalog catalog, {required String seriesBadge, DateTime? now}) {
  final clock = now ?? DateTime.now();
  final out = <HeroItem>[];
  for (final e in entries) {
    // The server already drops finished events; guard again for cached responses.
    final end = e.eventEndAt ?? e.eventAt?.add(const Duration(hours: 3));
    if (end != null && !clock.isBefore(end)) continue;
    Movie? movie;
    SeriesItem? series;
    Channel? channel;
    String? url;
    var needsMatch = true;

    switch (e.kind) {
      case 'movie':
        movie = catalog.movie(e.linkQuery ?? e.title, e.year);
      case 'tv':
        series = catalog.series(e.linkQuery ?? e.title, e.year);
      case 'live':
        channel = catalog.channel(e.linkQuery ?? e.title);
      default:
        switch (e.linkKind) {
          case 'channel':
            channel = catalog.channel(e.linkQuery ?? e.title);
          case 'movie':
            movie = catalog.movie(e.linkQuery ?? e.title, e.year);
          case 'series':
            series = catalog.series(e.linkQuery ?? e.title, e.year);
          case 'url':
            url = e.linkQuery;
            needsMatch = false;
          default:
            needsMatch = false;
        }
    }

    final matched = movie != null || series != null || channel != null;
    if (needsMatch && e.requireMatch && !matched) continue;

    out.add(HeroItem(
      id: 'f:${e.id}',
      title: e.title,
      subtitle: e.subtitle,
      overview: e.overview ?? series?.plot,
      year: e.year ?? movie?.year ?? series?.year,
      posterUrl: e.posterUrl ?? movie?.poster ?? series?.cover ?? channel?.logo,
      backdropUrl: e.backdropUrl,
      tmdbId: e.tmdbId,
      badge: e.kind == 'tv' || series != null
          ? seriesBadge
          : e.kind == 'live' || channel != null
              ? 'LIVE'
              : null,
      movie: movie,
      series: series,
      channel: channel,
      url: url,
      eventAt: e.eventAt,
      eventEndAt: e.eventEndAt,
    ));
  }
  return out;
}

// ---------------------------------------------------------------------------
// Providers

/// Remote entries for the selected source, served stale-while-revalidate from a local cache so
/// the hero appears at once on launch instead of waiting for the network.
class FeaturedEntries extends AsyncNotifier<List<FeaturedEntry>> {
  static const _refreshEvery = Duration(minutes: 15);
  Timer? _timer;

  @override
  Future<List<FeaturedEntry>> build() async {
    final source = ref.watch(settingsProvider.select((s) => s.featuredSource));
    final lang = ref.watch(tmdbLangProvider);
    final prefs = ref.watch(sharedPreferencesProvider);
    final cacheKey = 'featured:${source.name}:$lang';
    _timer?.cancel();
    _timer = Timer(_refreshEvery, ref.invalidateSelf);
    ref.onDispose(() => _timer?.cancel());

    final cached = _readCache(prefs, cacheKey);
    if (cached != null) {
      // Refresh in the background; the UI already has something to show.
      unawaited(_refresh(cacheKey, prefs));
      return cached;
    }
    return await _fetch(cacheKey, prefs) ?? const [];
  }

  Future<void> _refresh(String cacheKey, SharedPreferences prefs) async {
    final fresh = await _fetch(cacheKey, prefs);
    if (fresh != null && ref.mounted) state = AsyncData(fresh);
  }

  /// Null when the portal could not be reached (the cached value, if any, stays in place).
  Future<List<FeaturedEntry>?> _fetch(String cacheKey, SharedPreferences prefs) async {
    try {
      await ref.read(deviceIdentityProvider.future);
      final source = ref.read(settingsProvider).featuredSource;
      final lang = ref.read(tmdbLangProvider);
      final entries = await ref.read(portalApiProvider).featured(mode: source.name, lang: lang).timeout(const Duration(seconds: 10));
      await prefs.setString(cacheKey, jsonEncode(entries.map((e) => e.toJson()).toList()));
      return entries;
    } catch (e) {
      debugPrint('featured: $e');
      return null;
    }
  }

  static List<FeaturedEntry>? _readCache(SharedPreferences prefs, String key) {
    final raw = prefs.getString(key);
    if (raw == null) return null;
    try {
      return (jsonDecode(raw) as List).whereType<Map>().map((e) => FeaturedEntry.fromJson(e.cast<String, dynamic>())).toList();
    } catch (_) {
      return null;
    }
  }
}

final _featuredEntriesProvider = AsyncNotifierProvider<FeaturedEntries, List<FeaturedEntry>>(FeaturedEntries.new);

/// Hero slides: matched remote entries, else the local mix (resume + newest).
final featuredHeroProvider = FutureProvider.family<List<HeroItem>, (String, String)>((ref, key) async {
  final (playlistId, seriesBadge) = key;
  final entries = await ref.watch(_featuredEntriesProvider.future);
  if (entries.isNotEmpty) {
    // Only a finished import changes the catalogue; progress ticks must not trigger rebuilds.
    ref.watch(playlistImportProvider.select((s) => (s.playlistId, s.progress?.stage == ImportStage.done)));
    final catalog = await LocalCatalog.forEntries(ref.watch(databaseProvider), playlistId, entries);
    final matched = matchFeatured(entries, catalog, seriesBadge: seriesBadge);
    if (matched.isNotEmpty) return matched.take(10).toList();
  }
  return ref.watch(heroItemsProvider(playlistId).future);
});

/// Fire-and-forget anonymous playback statistic.
void reportWatch(WidgetRef ref, {required String kind, required String title, int? year, int? tmdbId}) {
  if (ref.read(deviceIdentityProvider).value == null) return;
  final key = normalizeTitle(title);
  if (key.isEmpty) return;
  ref
      .read(portalApiProvider)
      .reportWatch(kind: kind, titleKey: key, title: title, year: year ?? yearFromTitle(title), tmdbId: tmdbId)
      .catchError((Object e) => debugPrint('reportWatch: $e'));
}
