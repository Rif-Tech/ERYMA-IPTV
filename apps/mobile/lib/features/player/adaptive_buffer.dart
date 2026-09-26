import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:media_kit/media_kit.dart';

import '../../core/log/telemetry.dart';
import 'buffer_policy.dart';

/// Applies a [BufferPlan] to each stream and lengthens mpv's resume threshold
/// (`cache-pause-wait`) after each stall, so a link slower than the stream pauses rarely instead
/// of every few seconds. Nothing runs between stalls: mpv is read once per stall.
class AdaptiveBuffer {
  AdaptiveBuffer(this._player, {required this.ramMb, this.availMb}) {
    _subs.addAll([
      _player.stream.width.listen((w) {
        if ((w ?? 0) > 0) _started = true;
      }),
      _player.stream.buffering.listen((b) {
        if (b) unawaited(_onBuffering());
      }),
    ]);
  }

  final Player _player;
  final int? ramMb;
  final int? availMb;
  final _subs = <StreamSubscription>[];

  BufferPlan? _plan;
  bool _live = false;
  bool _started = false;
  double _wait = 1;
  int _stalls = 0;
  DateTime? _seekAt;
  DateTime? _lastStall;

  BufferPlan? get plan => _plan;
  double get pauseWait => _wait;
  int get stalls => _stalls;

  NativePlayer? get _native => _player.platform is NativePlayer ? _player.platform as NativePlayer : null;

  /// Before `player.open`: the plan for this stream (options read when its demuxer is created).
  Future<void> prepare({required bool live}) async {
    final plan = bufferPlan(ramMb: ramMb, availMb: availMb, live: live);
    _plan = plan;
    _live = live;
    _started = false;
    _stalls = 0;
    _lastStall = null;
    _seekAt = null;
    _wait = plan.initialWait;
    final native = _native;
    if (native == null) return;
    try {
      await Future.wait([
        native.setProperty('demuxer-max-bytes', '${plan.maxBytes}'),
        native.setProperty('demuxer-max-back-bytes', '${plan.backBytes}'),
        native.setProperty('cache-secs', '${plan.cacheSecs}'),
        native.setProperty('cache-pause-wait', _format(_wait)),
      ]);
    } catch (e) {
      debugPrint('buffer plan failed: $e');
    }
  }

  /// A user seek: the rebuffer that follows is expected, not a network stall.
  void seeked() => _seekAt = DateTime.now();

  Future<void> _onBuffering() async {
    final native = _native;
    final plan = _plan;
    if (native == null || plan == null || !_started) return;
    final now = DateTime.now();
    if (_seekAt != null && now.difference(_seekAt!) < const Duration(seconds: 3)) return;
    try {
      // media_kit also reports `core-idle` (a user pause, the end of a seek) as buffering.
      if (await native.getProperty('paused-for-cache', waitForInitialization: false) != 'yes') return;
      final values = await Future.wait([
        native.getProperty('cache-speed', waitForInitialization: false),
        native.getProperty('video-bitrate', waitForInitialization: false),
        native.getProperty('audio-bitrate', waitForInitialization: false),
      ]);
      final received = (double.tryParse(values[0]) ?? 0) * 8;
      final needed = (double.tryParse(values[1]) ?? 0) + (double.tryParse(values[2]) ?? 0);
      final calm = _lastStall == null ? Duration.zero : now.difference(_lastStall!);
      final before = relaxedPauseWait(_wait, initial: plan.initialWait, calm: calm);
      final next = nextPauseWait(before, live: _live, received: received > 0 ? received : null, needed: needed > 0 ? needed : null);
      _stalls++;
      _lastStall = now;
      if (next == _wait) return;
      _wait = next;
      await native.setProperty('cache-pause-wait', _format(next));
      Telemetry.breadcrumb('player', 'buffer: resume after ${_format(before)} s → ${_format(next)} s (stall $_stalls, '
          'received ${_mbps(received)} for ${_mbps(needed)})', data: {'cache_max_mb': plan.maxMb});
    } catch (e) {
      debugPrint('adaptive buffer: $e');
    }
  }

  static String _format(double s) => s == s.roundToDouble() ? '${s.round()}' : s.toStringAsFixed(1);

  static String _mbps(double bits) => bits > 0 ? '${(bits / 1e6).toStringAsFixed(1)} Mb/s' : '?';

  void dispose() {
    for (final s in _subs) {
      s.cancel();
    }
  }
}
