import 'package:flutter_test/flutter_test.dart';
import 'package:multiptv/features/player/buffer_policy.dart';

void main() {
  group('bufferPlan', () {
    test('caps rise with RAM tiers', () {
      expect(bufferPlan(ramMb: 1024, live: false).maxMb, 32);
      expect(bufferPlan(ramMb: 2048, live: false).maxMb, 80); // the Mi TV box: 2 GB
      expect(bufferPlan(ramMb: 4000, live: false).maxMb, 128);
      expect(bufferPlan(ramMb: 6000, live: false).maxMb, 192);
    });

    test('null RAM (off Android, tests) falls back to the 2 GB tier', () {
      expect(bufferPlan(ramMb: null, live: false).maxMb, 80);
    });

    test('a box already low on free memory gets a smaller cap, never below 16 MB', () {
      expect(bufferPlan(ramMb: 4000, availMb: 200, live: false).maxMb, 40); // 200/5
      expect(bufferPlan(ramMb: 4000, availMb: 50, live: false).maxMb, 16); // floor
    });

    test('live keeps a small back buffer; VOD scales with the cap but stays small', () {
      final live = bufferPlan(ramMb: 2048, live: true);
      final vod = bufferPlan(ramMb: 2048, live: false);
      expect(live.backBytes, 4 * 1024 * 1024);
      expect(vod.backBytes, (80 ~/ 8) * 1024 * 1024);
    });

    test('cache-secs and the initial wait differ for live vs VOD', () {
      expect(bufferPlan(ramMb: 2048, live: true).cacheSecs, 30);
      expect(bufferPlan(ramMb: 2048, live: false).cacheSecs, 120);
      expect(bufferPlan(ramMb: 2048, live: true).initialWait, 1);
      expect(bufferPlan(ramMb: 2048, live: false).initialWait, 2);
    });
  });

  group('nextPauseWait', () {
    test('doubles (floor 3 s) with no throughput data, capped per live/VOD', () {
      expect(nextPauseWait(1, live: false), 3);
      expect(nextPauseWait(3, live: false), 6);
      expect(nextPauseWait(6, live: false), 12);
      expect(nextPauseWait(12, live: false), 12); // VOD ceiling
      expect(nextPauseWait(3, live: true), 6);
      expect(nextPauseWait(6, live: true), 6); // live ceiling
    });

    test('a link slower than the stream waits longer, toward ~90 s of playback before the next stall', () {
      // Sentry FLUTTER-2E: Sonic 4K received ~28 Mb/s of a 35 Mb/s stream.
      final wait = nextPauseWait(1, live: false, received: 28e6, needed: 35e6);
      expect(wait, closeTo(12, 0.01)); // 90 * (1 - 28/35) = 18, capped at the VOD ceiling
    });

    test('a link at or above the stream rate does not extend the wait beyond the default ladder', () {
      expect(nextPauseWait(1, live: false, received: 40e6, needed: 35e6), 3);
    });
  });

  group('relaxedPauseWait', () {
    test('halves every 3 calm minutes, never below the initial wait', () {
      expect(relaxedPauseWait(12, initial: 2, calm: const Duration(minutes: 3)), 6);
      expect(relaxedPauseWait(12, initial: 2, calm: const Duration(minutes: 6)), 3);
      expect(relaxedPauseWait(12, initial: 2, calm: const Duration(minutes: 9)), 2);
      expect(relaxedPauseWait(12, initial: 2, calm: const Duration(minutes: 30)), 2);
    });

    test('no calm time yet: unchanged', () {
      expect(relaxedPauseWait(6, initial: 1, calm: Duration.zero), 6);
    });
  });
}
