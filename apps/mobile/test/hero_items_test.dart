import 'package:flutter_test/flutter_test.dart';
import 'package:multiptv/core/api/portal_api.dart';
import 'package:multiptv/core/db/database.dart';
import 'package:multiptv/features/content/content_providers.dart';
import 'package:multiptv/features/home/featured_provider.dart';

Movie _movie(String id, String name, {int? year}) =>
    Movie(id: 0, playlistId: 'p', streamId: id, name: name, nameKey: normalizeTitle(name), streamUrl: '', position: 0, year: year);
SeriesItem _series(String id, String name, {int? year}) =>
    SeriesItem(id: 0, playlistId: 'p', seriesId: id, name: name, nameKey: normalizeTitle(name), position: 0, year: year);
Channel _channel(String id, String name) =>
    Channel(id: 0, playlistId: 'p', streamId: id, name: name, nameKey: normalizeTitle(name), streamUrl: '', position: 0, tvArchive: false, tvArchiveDuration: 0);
HistoryData _hist(String id, {String? parent}) => HistoryData(
      id: 0,
      playlistId: 'p',
      profileId: '',
      kind: parent == null ? ContentKind.vod : ContentKind.series,
      itemId: id,
      parentId: parent,
      positionMs: 1000,
      durationMs: 10000,
      watchedAt: DateTime(2026),
    );

void main() {
  group('local hero mix', () {
    test('resume first, then newest movies/series, without duplicates', () {
      final items = buildHeroItems(
        resume: [(_hist('1'), _movie('1', 'A')), (_hist('e', parent: 's1'), _series('s1', 'S'))],
        movies: [_movie('1', 'A'), _movie('2', 'B'), _movie('3', 'C')],
        series: [_series('s1', 'S'), _series('s2', 'T')],
      );
      expect(items.map((h) => h.id).toList(), ['m:1', 's:s1', 'm:2', 's:s2', 'm:3']);
      expect(items[0].isResume, isTrue);
      expect(items[0].target, HeroTarget.movie);
      expect(items[1].target, HeroTarget.series);
      expect(items[2].isResume, isFalse);
    });

    test('caps resume entries and total size', () {
      final items = buildHeroItems(
        resume: [for (var i = 0; i < 6; i++) (_hist('r$i'), _movie('r$i', 'R$i'))],
        movies: [for (var i = 0; i < 20; i++) _movie('$i', 'M$i')],
        series: const [],
        max: 5,
        maxResume: 2,
      );
      expect(items, hasLength(5));
      expect(items.where((h) => h.isResume), hasLength(2));
    });
  });

  group('normalizeTitle', () {
    test('strips provider tags, year and punctuation', () {
      expect(normalizeTitle('|FR| Mocro Maffia: Taxi (2024)'), 'mocro maffia taxi');
      expect(normalizeTitle('[4K] Maximilien Kolbe VF 2025'), 'maximilien kolbe');
      expect(normalizeTitle('Crime / Action &amp; Adventure'), 'crime action and adventure');
      expect(normalizeTitle('Élémentaire (2023) VOSTFR'), 'elementaire');
    });

    test('extracts embedded year', () {
      expect(yearFromTitle('|FR| Kolbe (2025)'), 2025);
      expect(yearFromTitle('Kolbe'), isNull);
    });
  });

  group('matchFeatured', () {
    final catalog = LocalCatalog(
      movies: [_movie('10', '|FR| Mocro Maffia: Taxi (2024)'), _movie('11', 'Dune (1984)', year: 1984), _movie('12', 'Dune', year: 2021)],
      series: [_series('20', '|FR| Mocro Maffia', year: 2018)],
      channels: [_channel('30', '|FR| TF1 HD'), _channel('31', 'beIN Sports 1 FHD')],
    );

    FeaturedEntry entry({String kind = 'movie', String title = '', int? year, String? linkKind, String? linkQuery, bool requireMatch = true}) =>
        FeaturedEntry(id: title, kind: kind, title: title, year: year, linkKind: linkKind, linkQuery: linkQuery, requireMatch: requireMatch);

    test('matches movies by normalized title and year ±1', () {
      final out = matchFeatured([entry(title: 'Mocro Maffia: Taxi', year: 2024), entry(title: 'Dune', year: 2021)], catalog, seriesBadge: 'Séries');
      expect(out.map((h) => h.movie!.streamId), ['10', '12']);
    });

    test('drops unmatched entries when required, keeps them otherwise', () {
      final out = matchFeatured([entry(title: 'Missing'), entry(title: 'Missing', requireMatch: false)], catalog, seriesBadge: 'S');
      expect(out, hasLength(1));
      expect(out.single.target, HeroTarget.none);
    });

    test('matches series and channels, custom links and URLs', () {
      final out = matchFeatured(
        [
          entry(kind: 'tv', title: 'Mocro Maffia', year: 2018),
          entry(kind: 'custom', title: 'Ligue 1', linkKind: 'channel', linkQuery: 'beIN Sports 1'),
          entry(kind: 'custom', title: 'Site', linkKind: 'url', linkQuery: 'https://example.com'),
          entry(kind: 'live', title: 'TF1'),
        ],
        catalog,
        seriesBadge: 'Séries',
      );
      expect(out[0].series!.seriesId, '20');
      expect(out[0].badge, 'Séries');
      expect(out[1].channel!.streamId, '31');
      expect(out[1].badge, 'LIVE');
      expect(out[2].target, HeroTarget.url);
      expect(out[3].channel!.streamId, '30');
    });

    test('scheduled events: live 15 min before, hidden after the end', () {
      final start = DateTime(2026, 9, 28, 20, 45);
      final match = FeaturedEntry(
        id: 'm',
        kind: 'custom',
        title: 'PSG – OM',
        linkKind: 'channel',
        linkQuery: 'beIN Sports 1',
        eventAt: start,
      );
      final before = matchFeatured([match], catalog, seriesBadge: 'S', now: start.subtract(const Duration(hours: 2))).single;
      expect(before.isLiveAt(start.subtract(const Duration(hours: 2))), isFalse);
      expect(before.isLiveAt(start.subtract(const Duration(minutes: 14))), isTrue);
      expect(before.isLiveAt(start.add(const Duration(hours: 2))), isTrue);
      expect(before.isLiveAt(start.add(const Duration(hours: 3, minutes: 1))), isFalse);
      expect(before.eventEnd, start.add(const Duration(hours: 3)));
      // After the (default 3 h) window the banner is dropped entirely.
      expect(matchFeatured([match], catalog, seriesBadge: 'S', now: start.add(const Duration(hours: 4))), isEmpty);
    });
  });
}
