import 'package:flutter_test/flutter_test.dart';
import 'package:multiptv/core/xtream/xtream_client.dart';

void main() {
  group('normalizeXtreamBaseUrl', () {
    test('accepts bare host', () {
      expect(normalizeXtreamBaseUrl('example.com:8080'), 'http://example.com:8080');
    });
    test('strips trailing slash and api paths', () {
      expect(normalizeXtreamBaseUrl('http://example.com:8080/'), 'http://example.com:8080');
      expect(normalizeXtreamBaseUrl('http://example.com/player_api.php?username=a'), 'http://example.com');
      expect(normalizeXtreamBaseUrl('https://example.com/sub/get.php?x=1'), 'https://example.com/sub');
    });
  });

  group('XtreamCredentials urls', () {
    final c = XtreamCredentials(baseUrl: 'http://h:8080', username: 'us er', password: 'p&w');

    test('player api', () {
      expect(c.playerApi(), 'http://h:8080/player_api.php?username=us%20er&password=p%26w');
      expect(c.playerApi('get_live_streams', {'category_id': '5'}), contains('&action=get_live_streams&category_id=5'));
    });
    test('streams', () {
      expect(c.liveUrl('12'), 'http://h:8080/live/us%20er/p%26w/12.ts');
      expect(c.liveUrl('12', extension: 'm3u8'), endsWith('/12.m3u8'));
      expect(c.movieUrl('7', 'mkv'), 'http://h:8080/movie/us%20er/p%26w/7.mkv');
      expect(c.movieUrl('7', null), endsWith('/7.mp4'));
      expect(c.seriesUrl('99', '.avi'), endsWith('/99.avi'));
      expect(c.timeshiftUrl('3', DateTime(2024, 1, 31, 20, 5), 60), 'http://h:8080/timeshift/us%20er/p%26w/60/2024-01-31:20-05/3.ts');
      expect(c.xmltvUrl, 'http://h:8080/xmltv.php?username=us%20er&password=p%26w');
    });
  });

  test('credentialsFromM3uUrl', () {
    final c = credentialsFromM3uUrl('http://h:8080/get.php?username=a&password=b&type=m3u_plus')!;
    expect(c.baseUrl, 'http://h:8080');
    expect(c.username, 'a');
    expect(c.password, 'b');
    expect(credentialsFromM3uUrl('http://h/list.m3u'), isNull);
  });

  test('parses account json with string numbers', () {
    final a = XtreamAccount.fromJson({
      'user_info': {'auth': '1', 'status': 'Active', 'exp_date': '1893456000', 'is_trial': '0', 'active_cons': '1', 'max_connections': '2'},
      'server_info': {'timezone': 'Europe/Paris'},
    });
    expect(a.authenticated, isTrue);
    expect(a.maxConnections, 2);
    expect(a.expiresAt!.year, 2030);
    expect(a.serverTimezone, 'Europe/Paris');
  });

  test('parses series info with map or list seasons', () {
    final info = XtreamSeriesInfo.fromJson({
      'info': {'plot': 'p'},
      'episodes': {
        '2': [
          {'id': '20', 'episode_num': '1', 'title': 'E1', 'container_extension': 'mkv', 'info': {'duration_secs': 100}},
        ],
        '1': [
          {'id': '10', 'episode_num': 2, 'title': 'E2'},
          {'id': '11', 'episode_num': 1, 'title': 'E1'},
        ],
      },
    });
    expect(info.episodes.map((e) => e.id), ['11', '10', '20']);
    expect(info.episodes.last.season, 2);
    expect(info.episodes.last.durationSecs, 100);
  });
}
