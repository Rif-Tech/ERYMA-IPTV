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
    // Never let video fall behind audio: drop frames (in the decoder too) instead of playing in
    // slow motion when the SoC cannot keep up.
    native.setProperty('video-sync', 'audio'),
    native.setProperty('framedrop', 'decoder+vo'),
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
    if (isLive) ...[
      native.setProperty('demuxer-lavf-analyzeduration', '1'),
      native.setProperty('demuxer-lavf-probesize', '500000'),
      native.setProperty('demuxer-readahead-secs', '3'),
    ] else
      native.setProperty('demuxer-readahead-secs', '20'),
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
