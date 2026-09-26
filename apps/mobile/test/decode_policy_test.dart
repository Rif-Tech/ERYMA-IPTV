import 'package:flutter_test/flutter_test.dart';
import 'package:multiptv/core/player/playback.dart';
import 'package:multiptv/core/settings/settings.dart';
import 'package:multiptv/features/player/decode_policy.dart';
import 'package:multiptv/features/player/playback_telemetry.dart';

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
    // Sentry FLUTTER-1H: one bad packet at the start of a TS channel, playback goes on.
    expect(isTransientMpvError('Error decoding audio.'), isTrue);
    expect(isTransientMpvError('tcp: Connection reset by peer'), isTrue);
    expect(isTransientMpvError('Failed to open http://host/stream.ts'), isFalse);
    expect(isTransientMpvError('Could not open codec.'), isFalse);
  });

  test('frame cadence: judder when the display rate is not a multiple of the frame rate', () {
    expect(PlaybackTelemetry.frameCadence(25, 50), 'even');
    expect(PlaybackTelemetry.frameCadence(50, 50), 'even');
    expect(PlaybackTelemetry.frameCadence(59.94, 60), 'even');
    expect(PlaybackTelemetry.frameCadence(23.976, 24), 'even');
    expect(PlaybackTelemetry.frameCadence(25, 60), 'judder');
    expect(PlaybackTelemetry.frameCadence(50, 60), 'judder');
    expect(PlaybackTelemetry.frameCadence(23.976, 60), 'judder');
    expect(PlaybackTelemetry.frameCadence(60, 30), 'judder');
    expect(PlaybackTelemetry.frameCadence(null, 60), isNull);
  });

  test('video output: native on Android TV by default, the built-in one elsewhere', () {
    expect(usesNativeOutput(VideoOutput.auto, isAndroid: true, isTv: true), isTrue);
    expect(usesNativeOutput(VideoOutput.auto, isAndroid: true, isTv: false), isFalse);
    expect(usesNativeOutput(VideoOutput.native, isAndroid: true, isTv: false), isTrue);
    expect(usesNativeOutput(VideoOutput.flutter, isAndroid: true, isTv: true), isFalse);
    expect(usesNativeOutput(VideoOutput.native, isAndroid: false, isTv: true), isFalse);
  });

  group('decoderErrorOutcome', () {
    DecoderErrorOutcome outcome(DecodePath path, {bool frames = true, String? hwdec, bool lowEnd = false, int width = 1920}) =>
        decoderErrorOutcome(path: path, hasFrames: frames, hwdecCurrent: hwdec, lowEnd: lowEnd, width: width);

    test('direct: kept only when the hardware decoder recovered', () {
      expect(outcome(DecodePath.direct, hwdec: 'mediacodec'), DecoderErrorOutcome.keep);
      expect(outcome(DecodePath.direct, frames: false, hwdec: 'mediacodec'), DecoderErrorOutcome.fallback);
      // mpv switched to software: mediacodec_embed cannot show those frames.
      expect(outcome(DecodePath.direct, hwdec: 'no'), DecoderErrorOutcome.fallback);
    });

    test("hardware: mpv's own software switch is kept (Sentry FLUTTER-E/1R, HEVC 4K)", () {
      expect(outcome(DecodePath.hardware, hwdec: 'no', width: 3840), DecoderErrorOutcome.keep);
      expect(outcome(DecodePath.hardware, hwdec: 'mediacodec-copy'), DecoderErrorOutcome.keep);
      expect(outcome(DecodePath.hardware, frames: false, hwdec: 'no'), DecoderErrorOutcome.fallback);
    });

    test('hardware: software 4K on a weak box is refused, below 4K it plays', () {
      expect(outcome(DecodePath.hardware, hwdec: 'no', lowEnd: true, width: 3840), DecoderErrorOutcome.refuse);
      expect(outcome(DecodePath.hardware, hwdec: 'no', lowEnd: true, width: 1920), DecoderErrorOutcome.keep);
    });
  });
}
