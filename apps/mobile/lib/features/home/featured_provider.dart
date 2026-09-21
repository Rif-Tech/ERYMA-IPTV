import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/api/portal_api.dart';
import '../../core/db/database.dart';
import '../../core/device/device_identity.dart';
import '../../core/settings/settings.dart';
import '../content/content_providers.dart';
import '../playlists/playlists_provider.dart';

// ---------------------------------------------------------------------------
// Title normalisation shared by matching and anonymous watch statistics.

const _tags = {
  'fr', 'en', 'vf', 'vff', 'vfq', 'vo', 'vost', 'vostfr', 'multi', 'truefrench', 'french', 'subfrench',
  '4k', 'uhd', 'hd', 'fhd', 'sd', 'hdr', 'hevc', 'x264', 'x265', 'h264', 'h265', '1080p', '720p', '2160p', '480p',
};

const _accents = {
  'à': 'a', 'â': 'a', 'ä': 'a', 'á': 'a', 'ã': 'a', 'å': 'a',
  'ç': 'c',
  'é': 'e', 'è': 'e', 'ê': 'e', 'ë': 'e',
  'î': 'i', 'ï': 'i', 'í': 'i', 'ì': 'i',
  'ô': 'o', 'ö': 'o', 'ó': 'o', 'ò': 'o', 'õ': 'o',
  'û': 'u', 'ü': 'u', 'ù': 'u', 'ú': 'u',
  'ÿ': 'y', 'ñ': 'n', 'œ': 'oe', 'æ': 'ae', 'ß': 'ss',
};

/// `|FR| Mocro Maffia: Taxi (2024) VF 4K` → `mocro maffia taxi`.
String normalizeTitle(String raw) {
  var s = raw.toLowerCase();
  s = s.replaceAll(RegExp(r'[\[\]|{}]'), ' ');
  s = s.replaceAll(RegExp(r'\((19|20)\d{2}\)'), ' ');
  s = s.replaceAll('&amp;', '&');
  s = s.split('').map((c) => _accents[c] ?? c).join();
  s = s.replaceAll('&', ' and ');
  s = s.replaceAll(RegExp(r'[^a-z0-9]+'), ' ');
  final words = s.split(' ').where((w) => w.isNotEmpty && !_tags.contains(w)).toList();
  // A standalone trailing year duplicates the year field.
  if (words.length > 1 && RegExp(r'^(19|20)\d{2}$').hasMatch(words.last)) words.removeLast();
  return words.join(' ');
}

/// Year embedded in a provider title, e.g. `Kolbe (2025)`.
int? yearFromTitle(String raw) {
  final m = RegExp(r'\((19|20)(\d{2})\)').firstMatch(raw);
  return m == null ? null : int.parse('${m.group(1)}${m.group(2)}');
}

// ---------------------------------------------------------------------------
// Matching remote entries against the local catalogue.

/// Case-folded lookup tables built once per playlist.
class LocalCatalog {
  LocalCatalog({required List<Movie> movies, required List<SeriesItem> series, required List<Channel> channels}) {
    for (final m in movies) {
      (_movies[normalizeTitle(m.name)] ??= []).add(m);
    }
    for (final s in series) {
      (_series[normalizeTitle(s.name)] ??= []).add(s);
    }
    for (final c in channels) {
      final key = normalizeTitle(c.name);
      _channels[key] ??= c;
      _channelList.add((key, c));
    }
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

/// TMDB language for the current UI locale.
final tmdbLangProvider = Provider<String>((ref) {
  final code = ref.watch(settingsProvider.select((s) => s.locale?.languageCode)) ?? PlatformDispatcher.instance.locale.languageCode;
  return code == 'fr' ? 'fr-FR' : 'en-US';
});

final _catalogProvider = FutureProvider.family<LocalCatalog, String>((ref, playlistId) async {
  ref.watch(playlistImportProvider);
  final db = ref.watch(databaseProvider);
  return LocalCatalog(
    movies: await db.getMovies(playlistId),
    series: await db.getSeries(playlistId),
    channels: await db.getChannels(playlistId),
  );
});

/// Remote entries for the selected source; empty when offline or unconfigured.
final _featuredEntriesProvider = FutureProvider<List<FeaturedEntry>>((ref) async {
  final source = ref.watch(settingsProvider.select((s) => s.featuredSource));
  final lang = ref.watch(tmdbLangProvider);
  final device = await ref.watch(deviceIdentityProvider.future);
  // Refresh at most every 15 minutes while the screen stays alive.
  final link = ref.keepAlive();
  final timer = Timer(const Duration(minutes: 15), link.close);
  ref.onDispose(timer.cancel);
  try {
    return await ref.read(portalApiProvider).featured(device, mode: source.name, lang: lang).timeout(const Duration(seconds: 10));
  } catch (e) {
    debugPrint('featured: $e');
    return const [];
  }
});

/// Hero slides: matched remote entries, else the local mix (resume + newest).
final featuredHeroProvider = FutureProvider.family<List<HeroItem>, (String, String)>((ref, key) async {
  final (playlistId, seriesBadge) = key;
  final entries = await ref.watch(_featuredEntriesProvider.future);
  if (entries.isNotEmpty) {
    final catalog = await ref.watch(_catalogProvider(playlistId).future);
    final matched = matchFeatured(entries, catalog, seriesBadge: seriesBadge);
    if (matched.isNotEmpty) return matched.take(10).toList();
  }
  return ref.watch(heroItemsProvider(playlistId).future);
});

/// TMDB artwork/synopsis for a local item whose panel exposes a `tmdb_id`.
final tmdbArtProvider = FutureProvider.family<TmdbSummary?, (String, int)>((ref, key) async {
  final device = await ref.watch(deviceIdentityProvider.future);
  final lang = ref.watch(tmdbLangProvider);
  ref.keepAlive();
  return ref.read(portalApiProvider).tmdbDetails(device, kind: key.$1, id: key.$2, lang: lang);
});

/// Fire-and-forget anonymous playback statistic.
void reportWatch(WidgetRef ref, {required String kind, required String title, int? year, int? tmdbId}) {
  final device = ref.read(deviceIdentityProvider).value;
  if (device == null) return;
  final key = normalizeTitle(title);
  if (key.isEmpty) return;
  ref
      .read(portalApiProvider)
      .reportWatch(device, kind: kind, titleKey: key, title: title, year: year ?? yearFromTitle(title), tmdbId: tmdbId)
      .catchError((Object e) => debugPrint('reportWatch: $e'));
}
