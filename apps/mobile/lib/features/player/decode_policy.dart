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
