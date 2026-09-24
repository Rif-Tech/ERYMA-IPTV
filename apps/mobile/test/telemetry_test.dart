import 'package:flutter_test/flutter_test.dart';
import 'package:multiptv/core/log/telemetry.dart';

void main() {
  group('Telemetry.scrub', () {
    test('drops Xtream credentials from the path, keeps host and container', () {
      final out = Telemetry.scrub('Failed to open http://panel.example.com:8080/live/john/s3cret/12345.ts.');
      expect(out, 'Failed to open http://panel.example.com:8080/….ts.');
      expect(out, isNot(contains('john')));
      expect(out, isNot(contains('s3cret')));
    });

    test('drops query credentials (get.php / player_api)', () {
      final out = Telemetry.scrub('GET https://p.example.org/player_api.php?username=john&password=s3cret&action=get_live_streams');
      expect(out, 'GET https://p.example.org/….php');
    });

    test('handles several URLs and non-http schemes', () {
      final out = Telemetry.scrub('a rtmp://h1/app/key b udp://239.0.0.1:1234');
      expect(out, 'a rtmp://h1/… b udp://239.0.0.1:1234/…');
    });

    test('leaves text without URLs untouched', () {
      expect(Telemetry.scrub('Could not open codec hevc'), 'Could not open codec hevc');
    });
  });

  test('routeTemplate groups per screen, not per title', () {
    expect(Telemetry.routeTemplate('/movies/12345'), '/movies/:id');
    expect(Telemetry.routeTemplate('/import/portal-3f1c2a9e-1b2c-4d5e-8f90-123456789abc'), '/import/:id');
    expect(Telemetry.routeTemplate('/settings/parental'), '/settings/parental');
  });

  test('hostOf / extensionOf never expose the path', () {
    const url = 'http://panel.example.com:8080/series/john/s3cret/987.mkv';
    expect(Telemetry.hostOf(url), 'panel.example.com:8080');
    expect(Telemetry.extensionOf(url), 'mkv');
    expect(Telemetry.extensionOf('http://h/live/u/p/1'), isNull);
  });
}
