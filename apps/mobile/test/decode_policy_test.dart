import 'package:flutter_test/flutter_test.dart';
import 'package:multiptv/core/player/playback.dart';
import 'package:multiptv/core/settings/settings.dart';
import 'package:multiptv/features/player/decode_policy.dart';

DecodePath _start(VideoDecoder decoder, {bool emulator = false, bool tv = false, bool copyFailed = false}) =>
    defaultDecodePath(decoder: decoder, isEmulator: emulator, isTv: tv, hardwareCopyUnsupported: copyFailed);

void main() {
  group('defaultDecodePath', () {
    test('an emulator always starts on the direct path', () {
      for (final d in VideoDecoder.values) {
        expect(_start(d, emulator: true), DecodePath.direct);
      }
    });

    test('an explicit setting is followed as is', () {
      expect(_start(VideoDecoder.direct), DecodePath.direct);
      expect(_start(VideoDecoder.compat), DecodePath.hardware);
      expect(_start(VideoDecoder.software, tv: true), DecodePath.software);
    });

    test('auto: direct on TV, even after a hardware-copy failure', () {
      expect(_start(VideoDecoder.auto, tv: true), DecodePath.direct);
      expect(_start(VideoDecoder.auto, tv: true, copyFailed: true), DecodePath.direct);
    });

    test('auto on a handheld: hardware copy until it failed once, then software', () {
      expect(_start(VideoDecoder.auto), DecodePath.hardware);
      expect(_start(VideoDecoder.auto, copyFailed: true), DecodePath.software);
    });
  });

  group('nextDecodePath', () {
    test('ladder: direct → hardware → software → nothing', () {
      expect(nextDecodePath(DecodePath.direct, lowEnd: false), DecodePath.hardware);
      expect(nextDecodePath(DecodePath.hardware, lowEnd: false), DecodePath.software);
      expect(nextDecodePath(DecodePath.software, lowEnd: false), isNull);
    });

    test('a low-end device skips the hardware copy', () {
      expect(nextDecodePath(DecodePath.direct, lowEnd: true), DecodePath.software);
      expect(nextDecodePath(DecodePath.hardware, lowEnd: true), DecodePath.software);
    });
  });

  test('mpv error classification', () {
    expect(isBenignMpvError('Cannot seek in this stream.'), isTrue);
    expect(isBenignMpvError('Could not open codec.'), isFalse);
    expect(isDecoderMpvError('Could not open codec.'), isTrue);
    expect(isDecoderMpvError('Failed to initialize a decoder for codec hevc'), isTrue);
    expect(isDecoderMpvError('Failed to open http://host/stream.ts'), isFalse);
  });
}
