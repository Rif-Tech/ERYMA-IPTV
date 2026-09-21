import 'package:flutter_test/flutter_test.dart';
import 'package:multiptv/core/m3u/m3u_parser.dart';

void main() {
  const sample = '''
#EXTM3U url-tvg="http://epg.example.com/guide.xml.gz"
#EXTINF:-1 tvg-id="tf1.fr" tvg-name="TF1" tvg-logo="http://logo/tf1.png" group-title="France, Généralistes",TF1 HD
http://host:8080/live/u/p/1.ts
#EXTINF:-1 tvg-id="" group-title="Movies" catchup="default" catchup-days="3",Inception (2010)
http://host:8080/movie/u/p/42.mkv
#EXTGRP:Séries
#EXTINF:-1,Breaking Bad S01 E02
http://host:8080/series/u/p/7.mp4
#EXTINF:0,Bare
http://host/live.m3u8
''';

  test('parses header, attributes and titles with commas', () {
    final p = parseM3u(sample);
    expect(p.epgUrl, 'http://epg.example.com/guide.xml.gz');
    expect(p.entries, hasLength(4));

    final tf1 = p.entries[0];
    expect(tf1.title, 'TF1 HD');
    expect(tf1.tvgId, 'tf1.fr');
    expect(tf1.tvgLogo, 'http://logo/tf1.png');
    expect(tf1.group, 'France, Généralistes');
    expect(tf1.url, 'http://host:8080/live/u/p/1.ts');

    final movie = p.entries[1];
    expect(movie.tvgId, isNull);
    expect(movie.hasCatchup, isTrue);
    expect(movie.catchupDays, 3);

    expect(p.entries[2].group, 'Séries');
    expect(p.entries[3].title, 'Bare');
  });

  test('classifies entries', () {
    final p = parseM3u(sample);
    expect(classifyEntry(p.entries[0]), M3uEntryKind.live);
    expect(classifyEntry(p.entries[1]), M3uEntryKind.vod);
    expect(classifyEntry(p.entries[2]), M3uEntryKind.series);
    expect(classifyEntry(p.entries[3]), M3uEntryKind.live);
  });

  test('parses series titles', () {
    final a = parseSeriesTitle('Breaking Bad S01 E02')!;
    expect(a.series, 'Breaking Bad');
    expect(a.season, 1);
    expect(a.episode, 2);

    final b = parseSeriesTitle('Dark - 2x03 Titre')!;
    expect(b.series, 'Dark');
    expect(b.season, 2);
    expect(b.episode, 3);

    expect(parseSeriesTitle('TF1 HD'), isNull);
  });

  test('rejects garbage', () {
    expect(() => parseM3u(''), throwsA(isA<M3uFormatException>()));
    expect(() => parseM3u('<html>not a playlist</html>'), throwsA(isA<M3uFormatException>()));
  });
}
