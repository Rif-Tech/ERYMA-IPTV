import 'package:flutter_test/flutter_test.dart';
import 'package:multiptv/core/log/telemetry.dart';
import 'package:sentry_flutter/sentry_flutter.dart';

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

  test('messageKind: one kind of log problem, one issue', () {
    expect(Telemetry.messageKind('hardware failed (decoder error: Could not open codec.) → restarting with software'),
        'hardware failed (decoder error: Could not open codec.) → restarting with software');
    expect(Telemetry.messageKind('open failed on direct: http://p.example.com:8080/live/u/p/42.ts (code 403)'),
        'open failed on direct: http://p.example.com:#/….ts (code #)');
    expect(Telemetry.messageKind('x' * 300), hasLength(120));
  });

  test('breadcrumbTrail: one readable line per breadcrumb, URLs scrubbed', () {
    final trail = Telemetry.breadcrumbTrail([
      Breadcrumb(timestamp: DateTime.utc(2026, 9, 26, 10), category: 'dpad', message: 'Arrow Down: a → b'),
      Breadcrumb(
        timestamp: DateTime.utc(2026, 9, 26, 10, 0, 1),
        category: 'player',
        message: 'open',
        data: {'url': 'http://p.example.com/live/u/p/1.ts'},
      ),
    ]);
    expect(trail.split('\n'), [
      '2026-09-26T10:00:00.000Z info [dpad] Arrow Down: a → b',
      '2026-09-26T10:00:01.000Z info [player] open {"url":"http://p.example.com/….ts"}',
    ]);
  });

  test('hostOf / extensionOf never expose the path', () {
    const url = 'http://panel.example.com:8080/series/john/s3cret/987.mkv';
    expect(Telemetry.hostOf(url), 'panel.example.com:8080');
    expect(Telemetry.extensionOf(url), 'mkv');
    expect(Telemetry.extensionOf('http://h/live/u/p/1'), isNull);
  });
}
