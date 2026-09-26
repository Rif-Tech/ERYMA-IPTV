import 'dart:async';
import 'dart:convert';
import 'dart:ui' show FramePhase, FrameTiming, TimingsCallback;

import 'package:flutter/foundation.dart';
import 'package:flutter/scheduler.dart';
import 'package:media_kit/media_kit.dart';
import 'package:sentry_flutter/sentry_flutter.dart';

import '../../core/log/telemetry.dart';
import '../../core/platform/native_platform.dart';
import 'playback_telemetry.dart';

/// What the measurement panel shows, refreshed every second.
@immutable
class MeasureSnapshot {
  const MeasureSnapshot({
    required this.seconds,
    this.codec,
    this.width,
    this.height,
    this.interlaced,
    this.contentFps,
    this.decodedFps,
    this.shownFps,
    this.primaries,
    this.colorMatrix,
    this.gamma,
    this.hwdec,
    this.vo,
    required this.output,
    this.displayHz,
    this.cadence,
    this.dropsVo = 0,
    this.dropsDecoder = 0,
    this.delayed = 0,
    this.avsyncMs,
    this.cacheSeconds,
    this.videoKbps,
  });

  final int seconds;
  final String? codec;
  final int? width;
  final int? height;
  final bool? interlaced;
  final double? contentFps;
  final double? decodedFps;

  /// Frames Flutter composited in the last second: with the built-in output, the video frames
  /// really shown (each new video frame triggers one).
  final int? shownFps;
  final String? primaries;
  final String? colorMatrix;
  final String? gamma;
  final String? hwdec;
  final String? vo;
  final String output;
  final double? displayHz;
  final String? cadence;
  final int dropsVo;
  final int dropsDecoder;
  final int delayed;
  final double? avsyncMs;
  final double? cacheSeconds;
  final int? videoKbps;
}

/// Player measurements started from the controls ("Mesures"): every second, mpv's playback
/// counters, the display (refresh rate, mode) and the pacing of the frames Flutter composites,
/// shown live and sent to Sentry as one event when stopped: the summary in the `details` context,
/// every second in a CSV attachment and as a Sentry Log. Lets streams, boxes and settings be
/// compared with numbers rather than impressions.
class PlaybackMeasure {
  PlaybackMeasure(this._player, {required this.facts});

  final Player _player;

  /// Facts of the playback the player knows (kind, item id, decode path, output, settings).
  final Map<String, Object?> Function() facts;

  /// Null while not measuring.
  final snapshot = ValueNotifier<MeasureSnapshot?>(null);

  bool get active => _timer != null;

  static const _counters = ['frame-drop-count', 'decoder-frame-drop-count', 'vo-delayed-frame-count', 'mistimed-frame-count'];
  static const _gauges = [
    'estimated-vf-fps',
    'avsync',
    'demuxer-cache-duration',
    'video-bitrate',
    'paused-for-cache',
    'hwdec-current',
    'current-vo',
    'estimated-display-fps',
    'vsync-jitter',
  ];
  static const _format = [
    'video-format',
    'current-tracks/video/codec-profile',
    'video-params/w',
    'video-params/h',
    'video-params/pixelformat',
    'video-params/primaries',
    'video-params/colormatrix',
    'video-params/colorlevels',
    'video-params/gamma',
    'video-params/sig-peak',
    'video-frame-info/interlaced',
    'video-frame-info/tff',
    'container-fps',
    'file-format',
    'audio-codec-name',
  ];
  static const _csvColumns = [
    't',
    'decoded_fps',
    'shown_frames',
    'shown_1v',
    'shown_2v',
    'shown_3v',
    'shown_4v+',
    'drop_vo',
    'drop_decoder',
    'delayed',
    'mistimed',
    'avsync_ms',
    'cache_s',
    'video_kbps',
    'stalled',
    'display_hz',
    'raster_max_ms',
  ];
  static const _maxDuration = Duration(minutes: 5);

  Timer? _timer;
  DateTime? _startedAt;
  final _rows = <Map<String, Object?>>[];
  Map<String, int> _first = const {};
  Map<String, int> _previous = const {};
  Map<String, String> _format0 = const {};
  Map<String, Object?> _displayAtStart = const {};
  final _frames = <FrameTiming>[];
  final _cadenceTotal = <int, int>{};
  TimingsCallback? _onTimings;
  bool _sampling = false;
  bool _starting = false;

  Future<void> start() async {
    if (active || _starting) return;
    _starting = true;
    try {
      await _start();
    } finally {
      _starting = false;
    }
  }

  Future<void> _start() async {
    _rows.clear();
    _frames.clear();
    _cadenceTotal.clear();
    _startedAt = DateTime.now();
    final counters = await _counterValues();
    _first = counters;
    _previous = counters;
    _format0 = await _read(_format);
    _displayAtStart = await _display();
    _onTimings = _frames.addAll;
    SchedulerBinding.instance.addTimingsCallback(_onTimings!);
    _timer = Timer.periodic(const Duration(seconds: 1), (_) => unawaited(_sample()));
    Telemetry.breadcrumb('player', 'measurement started', data: {..._format0, 'display': _displayAtStart});
    unawaited(_sample());
  }

  /// Stops and sends the report ([reason]: stopped by the viewer, stream switched, player
  /// closed…). Returns whether a report was sent.
  Future<bool> stop({String reason = 'stopped'}) async {
    if (!active) return false;
    _timer?.cancel();
    _timer = null;
    if (_onTimings != null) SchedulerBinding.instance.removeTimingsCallback(_onTimings!);
    _onTimings = null;
    snapshot.value = null;
    if (_rows.isEmpty) return false;
    await _send(reason);
    return Telemetry.enabled;
  }

  void dispose() {
    _timer?.cancel();
    if (_onTimings != null) SchedulerBinding.instance.removeTimingsCallback(_onTimings!);
    snapshot.dispose();
  }

  Future<void> _sample() async {
    if (!active || _sampling) return;
    _sampling = true;
    try {
      final counters = await _counterValues();
      final gauges = await _read(_gauges);
      final display = await _display();
      if (!active) return;
      final elapsed = DateTime.now().difference(_startedAt!);
      final hz = (display['refreshRate'] as num?)?.toDouble();

      // Frames Flutter composited since the last sample, by how many display refreshes each
      // stayed on screen: an even cadence is one bar (2 for 25 fps on 50 Hz), judder two (2 and
      // 3 for 25 fps on 60 Hz), a compositor that misses frames shows 3+.
      final frames = List.of(_frames)..sort((a, b) => a.timestampInMicroseconds(FramePhase.vsyncStart).compareTo(b.timestampInMicroseconds(FramePhase.vsyncStart)));
      _frames.clear();
      final cadence = <int, int>{};
      var rasterMax = 0.0;
      if (hz != null && hz > 0) {
        final period = 1e6 / hz;
        for (var i = 1; i < frames.length; i++) {
          final delta = frames[i].timestampInMicroseconds(FramePhase.vsyncStart) - frames[i - 1].timestampInMicroseconds(FramePhase.vsyncStart);
          final refreshes = (delta / period).round().clamp(1, 4);
          cadence[refreshes] = (cadence[refreshes] ?? 0) + 1;
          _cadenceTotal[refreshes] = (_cadenceTotal[refreshes] ?? 0) + 1;
        }
      }
      for (final f in frames) {
        final ms = f.rasterDuration.inMicroseconds / 1000;
        if (ms > rasterMax) rasterMax = ms;
      }

      int delta(String key) => (counters[key] ?? 0) - (_previous[key] ?? 0);
      final row = <String, Object?>{
        't': elapsed.inSeconds,
        'decoded_fps': _double(gauges['estimated-vf-fps']),
        'shown_frames': frames.length,
        'shown_1v': cadence[1] ?? 0,
        'shown_2v': cadence[2] ?? 0,
        'shown_3v': cadence[3] ?? 0,
        'shown_4v+': cadence[4] ?? 0,
        'drop_vo': delta('frame-drop-count'),
        'drop_decoder': delta('decoder-frame-drop-count'),
        'delayed': delta('vo-delayed-frame-count'),
        'mistimed': delta('mistimed-frame-count'),
        'avsync_ms': _ms(gauges['avsync']),
        'cache_s': _double(gauges['demuxer-cache-duration']),
        'video_kbps': _kbps(gauges['video-bitrate']),
        'stalled': gauges['paused-for-cache'] == 'yes',
        'display_hz': hz,
        'raster_max_ms': double.parse(rasterMax.toStringAsFixed(1)),
      };
      _previous = counters;
      _rows.add(row);
      Telemetry.trace('measure', 'measure sample', row);

      final fps = _double(_format0['container-fps']);
      int total(String key) => (counters[key] ?? 0) - (_first[key] ?? 0);
      snapshot.value = MeasureSnapshot(
        seconds: elapsed.inSeconds,
        codec: _format0['video-format'],
        width: int.tryParse(_format0['video-params/w'] ?? ''),
        height: int.tryParse(_format0['video-params/h'] ?? ''),
        interlaced: _flag(_format0['video-frame-info/interlaced']),
        contentFps: fps,
        decodedFps: _double(gauges['estimated-vf-fps']),
        shownFps: facts()['video_output'] == 'native' ? null : frames.length,
        primaries: _format0['video-params/primaries'],
        colorMatrix: _format0['video-params/colormatrix'],
        gamma: _format0['video-params/gamma'],
        hwdec: gauges['hwdec-current'],
        vo: gauges['current-vo'],
        output: '${facts()['video_output'] ?? '?'}',
        displayHz: hz,
        cadence: PlaybackTelemetry.frameCadence(fps, hz),
        dropsVo: total('frame-drop-count'),
        dropsDecoder: total('decoder-frame-drop-count'),
        delayed: total('vo-delayed-frame-count'),
        avsyncMs: _ms(gauges['avsync']),
        cacheSeconds: _double(gauges['demuxer-cache-duration']),
        videoKbps: _kbps(gauges['video-bitrate']),
      );
      if (elapsed >= _maxDuration) unawaited(stop(reason: 'time limit'));
    } finally {
      _sampling = false;
    }
  }

  Future<void> _send(String reason) async {
    // From the samples only: when the stream was switched, mpv already plays the next one.
    final format = _format0;
    final displayAtEnd = await _display();
    final counters = _previous;
    int total(String key) => (counters[key] ?? 0) - (_first[key] ?? 0);
    final seconds = _rows.length;
    double? average(String key) {
      final values = _rows.map((r) => r[key]).whereType<num>().toList();
      return values.isEmpty ? null : double.parse((values.reduce((a, b) => a + b) / values.length).toStringAsFixed(2));
    }

    final fps = _double(format['container-fps']);
    final hzStart = (_displayAtStart['refreshRate'] as num?)?.toDouble();
    final hzEnd = (displayAtEnd['refreshRate'] as num?)?.toDouble();
    final facts = this.facts();
    final shownFrames = _cadenceTotal.values.fold(0, (a, b) => a + b);
    // Flutter composites the video only with the built-in output: with the native one its frames
    // are the controls' own, which say nothing about the picture.
    final composited = facts['video_output'] != 'native';
    final summary = <String, Object?>{
      'reason': reason,
      'duration_s': seconds,
      ...facts,
      'codec': format['video-format'],
      'profile': format['current-tracks/video/codec-profile'],
      'size': '${format['video-params/w']}x${format['video-params/h']}',
      'interlaced': _flag(format['video-frame-info/interlaced']),
      'pixel_format': format['video-params/pixelformat'],
      'primaries': format['video-params/primaries'],
      'color_matrix': format['video-params/colormatrix'],
      'color_levels': format['video-params/colorlevels'],
      'gamma': format['video-params/gamma'],
      'sig_peak': format['video-params/sig-peak'],
      'container': format['file-format'],
      'audio_codec': format['audio-codec-name'],
      'content_fps': fps,
      'decoded_fps_avg': average('decoded_fps'),
      if (composited) ...{
        'shown_fps_avg': average('shown_frames'),
        'shown_cadence': {for (final e in (_cadenceTotal.entries.toList()..sort((a, b) => a.key.compareTo(b.key)))) '${e.key}v': e.value},
        'shown_frames': shownFrames,
      },
      'display_hz_start': hzStart,
      'display_hz_end': hzEnd,
      'display_mode': displayAtEnd['mode'],
      'display_modes': displayAtEnd['modes'],
      'display_hdr': displayAtEnd['hdr'],
      'cadence': PlaybackTelemetry.frameCadence(fps, hzEnd),
      'drops_vo': total('frame-drop-count'),
      'drops_decoder': total('decoder-frame-drop-count'),
      'delayed': total('vo-delayed-frame-count'),
      'mistimed': total('mistimed-frame-count'),
      'avsync_max_ms': _rows.map((r) => (r['avsync_ms'] as num?)?.abs() ?? 0).fold<num>(0, (a, b) => a > b ? a : b),
      'cache_min_s': _rows.map((r) => r['cache_s']).whereType<num>().fold<num?>(null, (a, b) => a == null || b < a ? b : a),
      'stalled_s': _rows.where((r) => r['stalled'] == true).length,
      'video_kbps_avg': average('video_kbps'),
      'raster_max_ms': _rows.map((r) => r['raster_max_ms'] as num? ?? 0).fold<num>(0, (a, b) => a > b ? a : b),
    };
    final csv = StringBuffer()..writeln(_csvColumns.join(','));
    for (final row in _rows) {
      csv.writeln(_csvColumns.map((c) => row[c] ?? '').join(','));
    }
    // No format at all: the stream never produced a picture (e.g. the panel answered 503).
    final video = format['video-params/h'] == null
        ? 'no video'
        : '${format['video-params/h']}${summary['interlaced'] == true ? 'i' : 'p'} ${format['video-format'] ?? '?'} ${fps?.toStringAsFixed(2) ?? '?'} fps';
    Telemetry.breadcrumb('player', 'measurement sent', data: {'reason': reason, 'seconds': seconds});
    await Telemetry.capture(
      'player',
      'Player measurement (${facts['kind']}, $video, ${hzEnd?.toStringAsFixed(2) ?? '?'} Hz, ${facts['decode_path']}/${facts['video_output']})',
      level: SentryLevel.info,
      data: summary,
      fingerprint: ['player-measurement', '${facts['kind']}', '${facts['decode_path']}', '${facts['video_output']}'],
      throttle: Duration.zero,
      attachments: [SentryAttachment.fromUint8List(Uint8List.fromList(utf8.encode(csv.toString())), 'measure.csv', contentType: 'text/csv')],
    );
  }

  Future<Map<String, int>> _counterValues() async {
    final values = await _read(_counters);
    return {for (final e in values.entries) e.key: int.tryParse(e.value) ?? 0};
  }

  Future<Map<String, String>> _read(List<String> names) async {
    final native = _player.platform;
    if (native is! NativePlayer) return const {};
    final out = <String, String>{};
    for (final name in names) {
      try {
        final value = await native.getProperty(name, waitForInitialization: false);
        if (value.isNotEmpty) out[name] = value;
      } catch (_) {
        // Unknown to this libmpv build, or not available on this output (display sync only).
      }
    }
    return out;
  }

  static Future<Map<String, Object?>> _display() async {
    try {
      return await NativePlatform.displayInfo();
    } catch (_) {
      return const {};
    }
  }

  static double? _double(String? v) {
    final d = double.tryParse(v ?? '');
    return d == null ? null : double.parse(d.toStringAsFixed(3));
  }

  static double? _ms(String? seconds) {
    final d = double.tryParse(seconds ?? '');
    return d == null ? null : double.parse((d * 1000).toStringAsFixed(1));
  }

  static int? _kbps(String? bitsPerSecond) {
    final d = double.tryParse(bitsPerSecond ?? '');
    return d == null ? null : (d / 1000).round();
  }

  static bool? _flag(String? v) => v == null ? null : v == 'yes';
}
