import 'dart:math' as math;

/// mpv's stream cache for one stream, sized from the device's RAM rather than a fixed 16 MB: the
/// Mi TV box held ~4 s of a 35 Mb/s 4K film and stalled 13 times in 159 s (Sentry FLUTTER-2E).
///
/// [maxBytes] only caps the RAM: [cacheSecs] stops mpv earlier on a light stream, so an SD
/// channel never fills 80 MB. mpv allocates packets as they arrive, never the whole cap up front.
class BufferPlan {
  const BufferPlan({required this.maxBytes, required this.backBytes, required this.cacheSecs, required this.initialWait});

  /// `demuxer-max-bytes`: read-ahead cap.
  final int maxBytes;

  /// `demuxer-max-back-bytes`: already played data kept for a short seek back. media_kit sets it
  /// to the read-ahead cap, doubling the RAM for little use.
  final int backBytes;

  /// `cache-secs`: read-ahead target in seconds.
  final int cacheSecs;

  /// `cache-pause-wait` at open: seconds buffered before the first picture and after a stall.
  final double initialWait;

  int get maxMb => maxBytes >> 20;
}

const _mb = 1024 * 1024;

/// [ramMb] is the device's total RAM (`ActivityManager.MemoryInfo.totalMem`), [availMb] the free
/// RAM seen at start-up; both null off Android (desktop, tests), where the 2 GB tier applies.
BufferPlan bufferPlan({required int? ramMb, int? availMb, required bool live}) {
  final ram = ramMb ?? 2048;
  var cap = ram <= 1200
      ? 32
      : ram <= 2500
          ? 80
          : ram <= 4500
              ? 128
              : 192;
  // A box already short of memory at start-up must not be pushed into the low-memory killer.
  if (availMb != null && availMb > 0) cap = math.max(16, math.min(cap, availMb ~/ 5));
  return BufferPlan(
    maxBytes: cap * _mb,
    backBytes: live ? 4 * _mb : math.min(cap ~/ 8, 16) * _mb,
    cacheSecs: live ? 30 : 120,
    // A channel starts after 1 s (zapping stays quick); a film can afford one more second to
    // start with a cushion.
    initialWait: live ? 1 : 2,
  );
}

/// Longest wait after a stall: a film can wait for a real cushion, a channel should not lag
/// several seconds behind the broadcast.
double maxPauseWait({required bool live}) => live ? 6 : 12;

/// `cache-pause-wait` to use after a stall, from the [current] one. [received] and [needed] are
/// the network's rate and the stream's bitrate (bits/s) read at the stall, when mpv knows them.
///
/// mpv's default resumes after 1 s of cache: on a link barely slower than the stream the picture
/// then stops every few seconds. Waiting longer turns those into rare, longer pauses: at a
/// [received]/[needed] ratio r, a wait of 90 s × (1 − r) plays about 90 s before running dry.
double nextPauseWait(double current, {required bool live, double? received, double? needed}) {
  final ceiling = maxPauseWait(live: live);
  var next = math.max(current * 2, 3.0);
  if (received != null && needed != null && received > 0 && needed > 0 && received < needed) {
    next = math.max(next, 90 * (1 - received / needed));
  }
  return math.min(next, ceiling);
}

/// Wait after [calm] without a stall: halved every 3 minutes, never below [initial].
double relaxedPauseWait(double current, {required double initial, required Duration calm}) {
  var wait = current;
  for (var t = calm.inMinutes; t >= 3 && wait > initial; t -= 3) {
    wait /= 2;
  }
  return math.max(wait, initial);
}
