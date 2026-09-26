import '../../core/player/playback.dart';
import '../../core/settings/settings.dart';

// Which decode path a playback starts on and where it falls back to. Pure functions: the player
// screen reads the device facts and applies the result.

/// SharedPreferences flag set once the hardware-copy path failed on this install (auto mode).
const hardwareCopyUnsupportedKey = 'hardwareCopyUnsupported';

/// First decode path for a playback, from the user setting and what is known of the device.
DecodePath defaultDecodePath({
  required VideoDecoder decoder,
  required bool isEmulator,
  required bool isTv,
  required bool hardwareCopyUnsupported,
}) {
  // Emulators cannot create mpv's EGL context (vo=gpu): only the direct path shows a picture.
  if (isEmulator) return DecodePath.direct;
  return switch (decoder) {
    VideoDecoder.direct => DecodePath.direct,
    VideoDecoder.compat => DecodePath.hardware,
    VideoDecoder.software => DecodePath.software,
    // TV: `direct` (zero-copy). Measured on a Mi Box S gen 2 once video renders through a
    // SurfaceTexture (MainActivity): 1-2 dropped frames per minute in 1080p and 4K HEVC, where
    // `hardware` (mediacodec-copy + vo=gpu) dropped 2 frames out of 3 and hit ANRs in 4K
    // (Sentry FLUTTER-5/6). The green frames that once ruled `direct` out came from Flutter's
    // ImageReader surface, not from the decoder. Handhelds keep `hardware`.
    VideoDecoder.auto => isTv ? DecodePath.direct : (hardwareCopyUnsupported ? DecodePath.software : DecodePath.hardware),
  };
}

/// Whether the picture goes to a native SurfaceView ([VideoOutput.native]) rather than Flutter's
/// texture: Android only, and on TV by default.
bool usesNativeOutput(VideoOutput output, {required bool isAndroid, required bool isTv}) {
  if (!isAndroid) return false;
  return switch (output) {
    VideoOutput.native => true,
    VideoOutput.flutter => false,
    VideoOutput.auto => isTv,
  };
}

/// Next rung of the ladder after [failed] (direct → hardware copy → software), null at the bottom.
/// A weak box cannot afford `hardware`'s GPU copy (see [defaultDecodePath]): software is the
/// better second chance there.
DecodePath? nextDecodePath(DecodePath failed, {required bool lowEnd}) => switch (failed) {
      DecodePath.direct => lowEnd ? DecodePath.software : DecodePath.hardware,
      DecodePath.hardware => DecodePath.software,
      DecodePath.software => null,
    };

/// mpv reports the decoder re-init done by `vo=mediacodec_embed` as a failed seek on live
/// (unseekable) streams; playback is unaffected, so it must not raise the error banner.
bool isBenignMpvError(String e) => e.contains('Cannot seek in this stream') || e.contains('force-seekable');

/// A rejected stream (unsupported profile, 10-bit, old firmware) leaves audio without picture on
/// the hardware paths; these messages are mpv's ways of saying so.
bool isDecoderMpvError(String e) {
  final s = e.toLowerCase();
  return s.contains('could not open codec') || s.contains('hardware decod') || s.contains('video chain') || s.contains('mediacodec') || s.contains('failed to initialize');
}

/// One bad packet (a TS stream joined mid-frame: "Error decoding audio.") or a connection mpv
/// reconnects by itself: playback goes on, so these only matter if nothing plays at all.
bool isTransientMpvError(String e) {
  final s = e.toLowerCase();
  return s.startsWith('error decoding') || s.contains('error while decoding') || s.startsWith('tcp:');
}

/// What a hardware path does once a decoder error has had a moment to resolve itself.
enum DecoderErrorOutcome {
  /// Frames are being shown: a decoder re-opened (surface change) or, under `vo=gpu`, mpv's own
  /// switch to software decoding. Restarting would only cost a black screen.
  keep,

  /// Nothing shows: restart one rung down the ladder ([nextDecodePath]).
  fallback,

  /// Software-decoded 4K on a weak box: too likely to end in a native out-of-memory crash.
  refuse,
}

/// [hasFrames]: decoded video frames exist (video-params reported); [hwdecCurrent]: mpv's
/// `hwdec-current`, `no` once it decodes in software.
DecoderErrorOutcome decoderErrorOutcome({
  required DecodePath path,
  required bool hasFrames,
  required String? hwdecCurrent,
  required bool lowEnd,
  required int width,
}) {
  final hardwareDecoding = hwdecCurrent != null && hwdecCurrent.startsWith('mediacodec');
  // `vo=mediacodec_embed` cannot show a software frame: only a recovered hardware decoder counts.
  if (path == DecodePath.direct) return hasFrames && hardwareDecoding ? DecoderErrorOutcome.keep : DecoderErrorOutcome.fallback;
  if (!hasFrames) return DecoderErrorOutcome.fallback;
  if (!hardwareDecoding && lowEnd && width >= 3840) return DecoderErrorOutcome.refuse;
  return DecoderErrorOutcome.keep;
}
