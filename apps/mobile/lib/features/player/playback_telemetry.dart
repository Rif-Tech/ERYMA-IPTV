import 'dart:async';

import 'package:media_kit/media_kit.dart';
import 'package:sentry_flutter/sentry_flutter.dart';

import '../../core/log/telemetry.dart';
import '../../core/net/local_proxy.dart';
import '../../core/player/playback.dart';

/// Sentry diagnostics of one [PlayerScreen]: what was played (container, codec, profile,
/// resolution, HDR/Dolby Vision, bit depth, decoder actually used), how it went (time to first
/// frame, stalls, dropped frames, mpv errors) and whether the custom DNS proxy was really used.
///
/// Tags set here (`video_codec`, `resolution`, `hdr`, `decode_path`, `hwdec`…) make every event
/// of the session filterable by format, e.g. "all failures on 4K HEVC Main 10 PQ with hwdec off".
class PlaybackTelemetry {
  PlaybackTelemetry(
    this._player, {
    required this.dnsMode,
    required this.proxyPort,
    required this.proxyState,
    required this.currentProxyPort,
    required this.isBenign,
    required this.isDecoderError,
  }) {
    if (!Telemetry.enabled) return;
    _subs.addAll([
      _player.stream.width.listen(_onWidth),
      _player.stream.buffering.listen(_onBuffering),
      _player.stream.error.listen(_onError),
      _player.stream.log.listen(_onLog),
    ]);
    _sampler = Timer.periodic(const Duration(seconds: 10), (_) => unawaited(_sample()));
  }

  final Player _player;
  final String dnsMode;

  /// Port of the loopback DNS proxy given to mpv (`http-proxy`), null = mpv resolves by itself.
  final int? proxyPort;
  final String proxyState;
  final int? Function() currentProxyPort;
  final bool Function(String) isBenign;
  final bool Function(String) isDecoderError;

  final _subs = <StreamSubscription>[];
  Timer? _sampler;
  Timer? _startTimeout;

  PlayableItem? _item;
  DecodePath? _path;
  Stopwatch? _sinceOpen;
  int? _firstFrameMs;
  int _stalls = 0;
  Duration _stallTime = Duration.zero;
  Stopwatch? _stall;
  bool _stallFromSeek = false;
  DateTime? _lastSeek;
  int _seekBuffers = 0;
  int _proxyRequestsAtOpen = 0;
  String? _lastLog;
  Map<String, String> _stats = const {};

  bool get _active => Telemetry.enabled && _item != null;

  /// A new item starts (first open, zap, next episode, retry). Summarises the previous one first.
  void opened(PlayableItem item, DecodePath path, {required int index, required int total, int? startMs}) {
    if (!Telemetry.enabled) return;
    if (_item != null) _summarise('switched');
    _item = item;
    _path = path;
    _sinceOpen = Stopwatch()..start();
    _firstFrameMs = null;
    _stalls = 0;
    _stallTime = Duration.zero;
    _stall = null;
    _seekBuffers = 0;
    _stats = const {};
    _proxyRequestsAtOpen = LocalDnsProxy.requests;
    final container = Telemetry.extensionOf(item.url);
    final uri = Uri.tryParse(item.url);
    Telemetry.tags({
      'content_kind': item.kind.name,
      'container': container ?? 'none',
      'decode_path': path.name,
      'stream_scheme': uri?.scheme,
      'stream_host': Telemetry.hostOf(item.url),
      // Cleared until the new stream reports its own format.
      'video_codec': null, 'resolution': null, 'hdr': null, 'bit_depth': null, 'hwdec': null,
    });
    Telemetry.context('playback', {
      'kind': item.kind.name,
      'item_id': item.id,
      'parent_id': item.parentId,
      'catchup': item.id.contains('@'),
      'container': container,
      'scheme': uri?.scheme,
      'host': Telemetry.hostOf(item.url),
      'decode_path': path.name,
      'index': index,
      'playlist_size': total,
      'start_ms': startMs,
      'dns_mode': dnsMode,
      'dns_proxy_port': proxyPort,
      'dns_proxy_state': proxyState,
    });
    Telemetry.context('media', null);
    Telemetry.breadcrumb('player', 'open ${item.kind.name} .${container ?? '?'} on ${path.name}', data: {'item_id': item.id, 'host': Telemetry.hostOf(item.url)});

    if (dnsMode != 'system' && proxyPort == null) {
      // mpv resolves hostnames itself: without the proxy the chosen DNS does not apply to streams.
      unawaited(Telemetry.capture(
        'dns',
        'Playback started without the DNS proxy although DNS mode is $dnsMode',
        level: SentryLevel.error,
        data: {'dns_proxy_state': proxyState},
        fingerprint: ['dns-proxy-missing', dnsMode, proxyState],
      ));
    }
    _startTimeout?.cancel();
    _startTimeout = Timer(const Duration(seconds: 20), () {
      if (_firstFrameMs != null || !_active) return;
      unawaited(Telemetry.capture(
        'player',
        'No picture 20 s after opening (${item.kind.name}, .${container ?? '?'}, ${path.name})',
        data: {
          'buffering': _player.state.buffering,
          'playing': _player.state.playing,
          'audio_only': _player.state.tracks.video.where((t) => t.id != 'auto' && t.id != 'no').isEmpty,
          'dns_proxy_requests': LocalDnsProxy.requests - _proxyRequestsAtOpen,
          'dns_proxy_last_error': LocalDnsProxy.lastError,
        },
        fingerprint: ['player-no-picture', item.kind.name, container ?? '?', path.name],
      ));
    });
  }

  void _onWidth(int? width) {
    if (!_active || _firstFrameMs != null || (width ?? 0) <= 0) return;
    _firstFrameMs = _sinceOpen?.elapsedMilliseconds;
    _startTimeout?.cancel();
    Telemetry.breadcrumb('player', 'first frame after $_firstFrameMs ms');
    // Codec/HDR properties settle once the decoder and the VO are up.
    Timer(const Duration(seconds: 1), () => unawaited(_probe()));
    if (proxyPort != null) {
      Timer(const Duration(seconds: 5), () {
        if (_active && LocalDnsProxy.requests == _proxyRequestsAtOpen) {
          unawaited(Telemetry.capture(
            'dns',
            'Stream played without going through the DNS proxy',
            level: SentryLevel.error,
            data: {'dns_proxy_port': proxyPort, 'scheme': Uri.tryParse(_item!.url)?.scheme},
            fingerprint: ['dns-proxy-bypassed'],
          ));
        }
      });
    }
  }

  /// Called by the player on each committed seek (D-pad or touch).
  void seeked(Duration target) {
    if (!_active) return;
    _lastSeek = DateTime.now();
    Telemetry.breadcrumb('player', 'seek to ${target.inSeconds} s', level: SentryLevel.debug);
  }

  void _onBuffering(bool buffering) {
    if (!_active || _firstFrameMs == null) return;
    if (buffering) {
      if (_stall == null) {
        _stall = Stopwatch()..start();
        // Refilling the buffer right after a user seek is expected, not a network stall.
        _stallFromSeek = _lastSeek != null && DateTime.now().difference(_lastSeek!) < const Duration(seconds: 3);
      }
      return;
    }
    final stall = _stall;
    if (stall == null) return;
    _stall = null;
    if (_stallFromSeek) {
      _seekBuffers++;
      Telemetry.breadcrumb('player', 'rebuffer after seek ${stall.elapsedMilliseconds} ms', level: SentryLevel.debug);
      return;
    }
    _stalls++;
    _stallTime += stall.elapsed;
    if (stall.elapsed > const Duration(seconds: 2)) {
      Telemetry.breadcrumb('player', 'stall ${stall.elapsedMilliseconds} ms', data: {'stalls': _stalls}, level: SentryLevel.warning);
    }
  }

  void _onError(String error) {
    if (!_active) return;
    final benign = isBenign(error);
    Telemetry.breadcrumb('player', 'mpv error: $error', level: benign ? SentryLevel.debug : SentryLevel.error);
    if (benign) return;
    unawaited(Telemetry.capture(
      'player',
      'Playback error: ${Telemetry.scrub(error)}',
      level: SentryLevel.error,
      data: {'error': error, 'decoder_error': isDecoderError(error), 'first_frame_ms': _firstFrameMs, ..._stats},
      fingerprint: ['player-error', _item!.kind.name, Telemetry.extensionOf(_item!.url) ?? '?', _path!.name, _normalise(error)],
    ));
  }

  void _onLog(PlayerLog log) {
    if (!_active) return;
    final line = '${log.prefix}: ${log.text.trim()}';
    if (line == _lastLog) return;
    _lastLog = line;
    Telemetry.breadcrumb('mpv', line, level: log.level == 'error' || log.level == 'fatal' ? SentryLevel.error : SentryLevel.warning);
  }

  static const _probeProperties = [
    'file-format',
    'video-format',
    'video-codec',
    'current-tracks/video/codec-profile',
    'current-tracks/video/dolby-vision-profile',
    'current-tracks/video/dolby-vision-level',
    'video-params/w',
    'video-params/h',
    'video-params/pixelformat',
    'video-params/hw-pixelformat',
    'video-params/colormatrix',
    'video-params/primaries',
    'video-params/gamma',
    'video-params/sig-peak',
    'video-params/max-cll',
    'hwdec-current',
    'current-vo',
    'container-fps',
    'estimated-vf-fps',
    'video-bitrate',
    'current-tracks/video/hls-bitrate',
    'audio-codec-name',
    'audio-params/format',
    'audio-params/channel-count',
    'audio-params/samplerate',
    'audio-bitrate',
    'track-list/count',
  ];

  static const _sampleProperties = ['frame-drop-count', 'decoder-frame-drop-count', 'vo-delayed-frame-count', 'demuxer-cache-duration', 'estimated-vf-fps', 'video-bitrate'];

  Future<Map<String, String>> _read(List<String> names) async {
    final native = _player.platform;
    if (native is! NativePlayer) return const {};
    final out = <String, String>{};
    for (final name in names) {
      try {
        final value = await native.getProperty(name, waitForInitialization: false);
        if (value.isNotEmpty) out[name] = value;
      } catch (_) {
        // Property unknown to this libmpv build: nothing to report.
      }
    }
    return out;
  }

  Future<void> _probe() async {
    if (!_active) return;
    final item = _item;
    final p = await _read(_probeProperties);
    if (!_active || item != _item) return;
    final width = int.tryParse(p['video-params/w'] ?? '') ?? _player.state.width ?? 0;
    final height = int.tryParse(p['video-params/h'] ?? '') ?? _player.state.height ?? 0;
    final gamma = p['video-params/gamma'] ?? '';
    final dolbyVision = p['current-tracks/video/dolby-vision-profile'] != null || (p['video-format'] ?? '').startsWith('dv');
    final hdr = dolbyVision ? 'dolby_vision' : (gamma == 'pq' ? 'hdr10_pq' : (gamma == 'hlg' ? 'hlg' : 'sdr'));
    final pixelFormat = p['video-params/pixelformat'] ?? '';
    // yuv420p10 / p010 → 10-bit, yuv420p12 → 12-bit; nv12 / yuv420p are 8-bit.
    final bitDepth = pixelFormat.isEmpty
        ? null
        : RegExp(r'p010|p10|10[lb]e').hasMatch(pixelFormat)
            ? '10'
            : RegExp(r'p12|12[lb]e').hasMatch(pixelFormat)
                ? '12'
                : '8';
    final resolution = width >= 3800 || height >= 2100
        ? '4K'
        : height >= 1000 || width >= 1900
            ? 'FHD'
            : height >= 700 || width >= 1260
                ? 'HD'
                : height > 0
                    ? 'SD'
                    : 'unknown';
    Telemetry.tags({
      'video_codec': p['video-format'] ?? 'none',
      'codec_profile': p['current-tracks/video/codec-profile'],
      'resolution': resolution,
      'hdr': hdr,
      'bit_depth': bitDepth,
      'hwdec': p['hwdec-current'] ?? 'no',
      'audio_codec': p['audio-codec-name'],
    });
    Telemetry.context('media', {
      ...p,
      'resolution': resolution,
      'hdr': hdr,
      'bit_depth': bitDepth,
      'first_frame_ms': _firstFrameMs,
      'tracks_video': _player.state.tracks.video.length,
      'tracks_audio': _player.state.tracks.audio.length,
      'tracks_subtitle': _player.state.tracks.subtitle.length,
    });
    Telemetry.breadcrumb('player', 'media: ${p['video-format'] ?? '?'} ${p['current-tracks/video/codec-profile'] ?? ''} ${width}x$height $hdr ${bitDepth ?? '?'}-bit, hwdec=${p['hwdec-current'] ?? 'no'}, vo=${p['current-vo'] ?? '?'}');
    // Asked for a hardware path but mpv silently decodes in software: the usual cause of 4K/HEVC
    // stutter on boxes whose MediaCodec rejects the profile.
    if (_path != DecodePath.software && (p['hwdec-current'] ?? 'no') == 'no' && p['video-format'] != null) {
      unawaited(Telemetry.capture(
        'player',
        'Hardware decoding not used for ${p['video-format']} $resolution $hdr on ${_path!.name}',
        data: {...p},
        fingerprint: ['player-hwdec-off', p['video-format']!, resolution, hdr, _path!.name],
      ));
    }
  }

  Future<void> _sample() async {
    if (!_active || _firstFrameMs == null) return;
    _stats = await _read(_sampleProperties);
    Telemetry.breadcrumb('player', 'stats', data: {..._stats, 'stalls': _stalls, 'stall_ms': _stallTime.inMilliseconds}, level: SentryLevel.debug);
    final current = currentProxyPort();
    if (proxyPort != null && current != proxyPort) {
      unawaited(Telemetry.capture(
        'dns',
        'DNS proxy restarted during playback: mpv still points at the old port',
        level: SentryLevel.error,
        data: {'player_port': proxyPort, 'current_port': current},
        fingerprint: ['dns-proxy-stale-port'],
      ));
    }
  }

  void _summarise(String reason) {
    final item = _item;
    if (item == null) return;
    final watched = _sinceOpen?.elapsed ?? Duration.zero;
    final drops = int.tryParse(_stats['frame-drop-count'] ?? '') ?? 0;
    final decoderDrops = int.tryParse(_stats['decoder-frame-drop-count'] ?? '') ?? 0;
    final summary = {
      'reason': reason,
      'watched_s': watched.inSeconds,
      'first_frame_ms': _firstFrameMs,
      'stalls': _stalls,
      'seek_rebuffers': _seekBuffers,
      'stall_ms': _stallTime.inMilliseconds,
      'frame_drops': drops,
      'decoder_frame_drops': decoderDrops,
    };
    Telemetry.breadcrumb('player', 'close (${item.kind.name}, $reason)', data: summary);
    final degraded = _stalls >= 5 || _stallTime > const Duration(seconds: 20) || drops + decoderDrops > 300;
    if (degraded) {
      unawaited(Telemetry.capture(
        'player',
        'Degraded playback (${item.kind.name}, .${Telemetry.extensionOf(item.url) ?? '?'}, ${_path?.name})',
        data: summary,
        fingerprint: ['player-degraded', item.kind.name, _path?.name ?? '?'],
        throttle: const Duration(minutes: 30),
      ));
    }
    _item = null;
  }

  /// Error message without numbers/URLs, so the same failure groups into one Sentry issue.
  static String _normalise(String error) => Telemetry.scrub(error).replaceAll(RegExp(r'\d+'), '#').trim();

  void dispose(String reason) {
    _startTimeout?.cancel();
    _sampler?.cancel();
    for (final s in _subs) {
      s.cancel();
    }
    if (_active) _summarise(reason);
  }
}
