import 'package:flutter_test/flutter_test.dart';
import 'package:multiptv/core/player/playback.dart';
import 'package:multiptv/features/player/mpv_tuning.dart';

void main() {
  group('native video output', () {
    test('no picture until a surface arrives, hwdec per decode path', () {
      expect(nativeOutputSetup(DecodePath.direct)['vo'], 'null');
      expect(nativeOutputSetup(DecodePath.direct)['hwdec'], 'mediacodec');
      expect(nativeOutputSetup(DecodePath.hardware)['hwdec'], 'mediacodec-copy');
      expect(nativeOutputSetup(DecodePath.software)['hwdec'], 'no');
    });

    test('attaching: vo off, size and wid, then the vo (and the track again for direct)', () {
      expect(nativeSurfaceSteps(DecodePath.direct, wid: 42, width: 1920, height: 1080), [
        ('vo', 'null'),
        ('android-surface-size', '1920x1080'),
        ('wid', '42'),
        ('vo', 'mediacodec_embed'),
        ('vid', 'auto'),
      ]);
      expect(nativeSurfaceSteps(DecodePath.software, wid: 42, width: 1920, height: 1080).last, ('vo', 'gpu'));
    });

    test('detaching turns the vo off before dropping the surface', () {
      expect(nativeSurfaceSteps(DecodePath.direct, wid: 0, width: 0, height: 0), [('vo', 'null'), ('wid', '0')]);
    });
  });
}
