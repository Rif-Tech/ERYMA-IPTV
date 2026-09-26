import 'package:flutter/foundation.dart';
import 'package:media_kit/media_kit.dart';

import '../../core/player/playback.dart';

/// mpv options media_kit hard-codes for desktop that hurt weak Android devices. The returned future
/// completes once every property is set (a failure is only logged); `player.open` must wait for it.
Future<void> tuneMpv(NativePlayer native, {required bool isLive, required DecodePath path, required bool lowEnd, int? dnsProxyPort}) {
  return Future.wait([
    // media_kit sets hr-seek-framedrop=no: every frame between the keyframe and the seek target
    // is decoded *and displayed*, so a +15 s skip replays a burst of video while audio runs
    // ahead. Dropping those frames makes seeks land instantly and in sync.
    native.setProperty('hr-seek-framedrop', 'yes'),
    // Stream cache on slow eMMC/flash stalls playback; RAM (demuxer-max-bytes) is enough.
    native.setProperty('cache-on-disk', 'no'),
    // Start once a little is buffered (cache-pause-wait, 1 s): a stream started on its very first
    // packets ran dry right after its first picture and froze ~1.1 s (Sentry: one live zap in
    // three, on the Mi TV box).
    native.setProperty('cache-pause-initial', 'yes'),
    // Never let video fall behind audio: drop frames instead of playing in slow motion when the
    // SoC cannot keep up. Decoder-side dropping only helps a CPU decoder; with MediaCodec it cut
    // frames that would have been on time (4K HEVC on direct: 6 decoder drops in 10 s; 1080p on
    // the hardware copy: 188 in 27 s, Sentry FLUTTER-5): mpv's default `vo` there.
    native.setProperty('video-sync', 'audio'),
    native.setProperty('framedrop', path == DecodePath.software ? 'decoder+vo' : 'vo'),
    // Subtitles are opt-in from the player menu; never auto-select a track.
    native.setProperty('sid', 'no'),
    native.setProperty('sub-auto', 'no'),
    // Flaky operator networks / weak Wi-Fi on TV boxes: reconnect instead of surfacing an error.
    native.setProperty('network-timeout', '10'),
    native.setProperty('stream-lavf-o', 'reconnect=1,reconnect_streamed=1,reconnect_delay_max=5'),
    // mpv/ffmpeg resolve hostnames themselves; route them through the loopback proxy so a custom
    // DNS (Réglages → Réseau / DNS) also applies to playlist streams, not just Dio/API calls.
    if (dnsProxyPort != null) native.setProperty('http-proxy', 'http://127.0.0.1:$dnsProxyPort'),
    // Live TS: start decoding as soon as the first packets arrive instead of probing 5 s of data.
    // (Read-ahead itself is AdaptiveBuffer.prepare()'s job: demuxer-max-bytes/cache-secs, sized
    // from the device's RAM — demuxer-readahead-secs has no effect once those are set.)
    if (isLive) ...[
      native.setProperty('demuxer-lavf-analyzeduration', '1'),
      native.setProperty('demuxer-lavf-probesize', '500000'),
    ],
    if (path != DecodePath.direct && lowEnd) ...[
      // Mali-400/450 class GPUs: plain bilinear scaling, no dithering/gamma passes.
      native.setProperty('gpu-dumb-mode', 'yes'),
      native.setProperty('vd-lavc-fast', 'yes'),
    ],
    if (path == DecodePath.software) ...[
      native.setProperty('vd-lavc-skiploopfilter', lowEnd ? 'all' : 'nonkey'),
      native.setProperty('vd-lavc-threads', '0'),
    ] else if (lowEnd)
      // Hardware decoding leaves the CPU idle; extra software threads only cost RAM on 2 GB boxes.
      native.setProperty('vd-lavc-threads', '2'),
  ]).then((_) {}, onError: (Object e) => debugPrint('mpv tuning failed: $e'));
}

/// mpv set-up for [VideoOutput.native], where no media_kit VideoController exists: what its
/// Android controller sets for the texture, with no picture until a surface arrives
/// ([nativeSurfaceSteps]).
Map<String, String> nativeOutputSetup(DecodePath path) => {
      'vo': 'null',
      'hwdec': switch (path) {
        DecodePath.direct => 'mediacodec',
        DecodePath.hardware => 'mediacodec-copy',
        DecodePath.software => 'no',
      },
      'vid': 'auto',
      'opengl-es': 'yes',
      'force-window': 'yes',
      'gpu-context': 'android',
      'sub-use-margins': 'no',
      'sub-font-provider': 'none',
      'sub-scale-with-window': 'yes',
      'hwdec-codecs': 'h264,hevc,mpeg4,mpeg2video,vp8,vp9,av1',
    };

/// Properties attaching mpv to the native surface [wid] (0 detaches it), in order: `vo=null`
/// first and the real vo last, as media_kit does (a vo started before its `wid` crashes mpv).
List<(String, String)> nativeSurfaceSteps(DecodePath path, {required int wid, required int width, required int height}) {
  if (wid == 0) return const [('vo', 'null'), ('wid', '0')];
  final vo = path == DecodePath.direct ? 'mediacodec_embed' : 'gpu';
  return [
    ('vo', 'null'),
    ('android-surface-size', '${width}x$height'),
    ('wid', '$wid'),
    ('vo', vo),
    // mediacodec_embed only opens its decoder once the video track is selected again.
    if (vo == 'mediacodec_embed') ('vid', 'auto'),
  ];
}
