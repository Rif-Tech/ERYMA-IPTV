import 'dart:async';
import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:media_kit/media_kit.dart';
import 'package:media_kit_video/media_kit_video.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

import '../../app/responsive.dart';
import '../../app/router.dart';
import '../../app/theme.dart';
import '../../core/db/database.dart';
import '../../core/log/app_logger.dart';
import '../../core/net/dns_providers.dart';
import '../../core/platform/native_platform.dart';
import '../../core/player/playback.dart';
import '../../core/settings/settings.dart';
import '../../core/sync/progress_sync.dart';
import '../../l10n/generated/app_localizations.dart';
import '../../widgets/common.dart';
import '../../widgets/format.dart';
import '../content/content_providers.dart';
import '../playlists/playlists_provider.dart';

/// Skip applied per D-pad tap; repeats accelerate while the key is held.
const _seekStep = Duration(seconds: 15);
const _seekCommitDelay = Duration(milliseconds: 350);

class PlayerScreen extends ConsumerStatefulWidget {
  const PlayerScreen({super.key, required this.request});
  final PlaybackRequest request;

  @override
  ConsumerState<PlayerScreen> createState() => _PlayerScreenState();
}

class _PlayerScreenState extends ConsumerState<PlayerScreen> with WidgetsBindingObserver {
  late final Player _player;
  late final VideoController _controller;
  late int _index;
  final _subs = <StreamSubscription>[];

  bool _overlay = true;
  bool _showList = false;
  String? _error;
  Tracks _tracks = const Tracks();
  Track _track = const Track();
  double _rate = 1.0;
  int? _videoWidth;
  int? _videoHeight;
  Timer? _hideTimer;
  Timer? _saveTimer;
  int? _pendingStartMs;

  // High-frequency values live in notifiers so only the widgets showing them repaint. Buffering
  // flips many times a minute on a weak network; a setState there rebuilt the whole overlay.
  final _position = ValueNotifier(Duration.zero);
  final _duration = ValueNotifier(Duration.zero);
  final _buffering = ValueNotifier(true);
  final _playing = ValueNotifier(false);

  /// Accumulated, not yet committed seek offset (D-pad taps / long press).
  final _pendingSeek = ValueNotifier<Duration?>(null);
  Timer? _seekCommitTimer;
  Stopwatch? _seekHold;

  /// Lightweight scrub bar shown while a D-pad seek key is held; unlike [_overlay] it never reveals
  /// the full transport controls (back/play/etc. would be noise during a fast seek).
  final _scrubVisible = ValueNotifier(false);

  PlayableItem get _item => widget.request.items[_index];
  bool get _isLive => _item.kind == ContentKind.live;

  // Captured at init: `ref` must not be used from dispose().
  late final AppDatabase _db;
  late final ProgressSync _sync;
  late final String? _playlistId;
  late final bool _isTv;

  @override
  void initState() {
    super.initState();
    _db = ref.read(databaseProvider);
    _sync = ref.read(progressSyncProvider);
    _playlistId = ref.read(activePlaylistProvider)?.id;
    _isTv = ref.read(isTelevisionProvider);
    _index = widget.request.startIndex;
    _pendingStartMs = widget.request.startPositionMs;
    _player = Player(
      configuration: PlayerConfiguration(
        title: 'MultIPTV',
        // Demuxer RAM cache; 32 MB is a noticeable slice of a 2 GB box shared with the OS.
        bufferSize: (ref.read(isLowEndDeviceProvider) ? 16 : 32) * 1024 * 1024,
        logLevel: kDebugMode ? MPVLogLevel.warn : MPVLogLevel.error,
      ),
    );
    // Decode path ladder: direct (no copy) → hardware copy → software. Failures are remembered per
    // install so `auto` does not retry a path this box already rejected.
    _path = widget.request.decodePath ?? _defaultPath();
    _controller = VideoController(
      _player,
      configuration: switch (_path) {
        DecodePath.direct => const VideoControllerConfiguration(vo: 'mediacodec_embed', hwdec: 'mediacodec'),
        DecodePath.hardware => const VideoControllerConfiguration(vo: 'gpu', hwdec: 'mediacodec-copy'),
        DecodePath.software => const VideoControllerConfiguration(vo: 'gpu', hwdec: 'no', enableHardwareAcceleration: false),
      },
    );
    _tunePlayer();
    unawaited(WakelockPlus.enable());
    WidgetsBinding.instance.addObserver(this);

    void safeSet(VoidCallback fn) {
      if (mounted) setState(fn);
    }

    _subs.addAll([
      if (kDebugMode) _player.stream.log.listen((l) => debugPrint('mpv[${l.level}] ${l.prefix}: ${l.text}')),
      _player.stream.error.listen((e) {
        if (_isBenignError(e)) return;
        if (_path != DecodePath.software && _isDecoderError(e)) {
          _fallback('decoder error: $e');
          return;
        }
        safeSet(() => _error = e);
      }),
      _player.stream.buffering.listen((b) => _buffering.value = b),
      _player.stream.playing.listen((p) {
        _playing.value = p;
        if (p) _armWatchdog();
      }),
      // While a seek is pending, keep showing the target instead of the stale playback position.
      _player.stream.position.listen((p) {
        if (_pendingSeek.value == null) _position.value = p;
      }),
      _player.stream.duration.listen((d) => _duration.value = d),
      _player.stream.width.listen((w) => safeSet(() => _videoWidth = w)),
      _player.stream.height.listen((h) => safeSet(() => _videoHeight = h)),
      _player.stream.tracks.listen((t) => safeSet(() => _tracks = t)),
      _player.stream.track.listen((t) => safeSet(() => _track = t)),
      _player.stream.rate.listen((r) => safeSet(() => _rate = r)),
      _player.stream.completed.listen((done) {
        if (done && !_isLive && mounted) _next();
      }),
    ]);

    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    if (!_isTv) {
      SystemChrome.setPreferredOrientations([DeviceOrientation.landscapeLeft, DeviceOrientation.landscapeRight]);
    }
    _saveTimer = Timer.periodic(const Duration(seconds: 10), (_) => _saveProgress());
    _open();
    // `_overlay` starts true (the controls show briefly on launch), so unlike every later call,
    // `_showOverlay()` never runs its "was hidden" branch here and never focuses Play — nothing
    // owns the D-pad yet, which is why the on-launch controls don't respond until they've been
    // hidden and re-shown once. Focus it explicitly for this first display.
    if (_isTv) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _playFocus.requestFocus();
      });
    }
    _scheduleHide();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _hideTimer?.cancel();
    _saveTimer?.cancel();
    _seekCommitTimer?.cancel();
    _watchdog?.cancel();
    _progressFocus.dispose();
    _playFocus.dispose();
    _backFocus.dispose();
    _prevFocus.dispose();
    _nextFocus.dispose();
    _listToggleFocus.dispose();
    _replayFocus.dispose();
    _forwardFocus.dispose();
    _saveProgress(flush: true);
    for (final s in _subs) {
      s.cancel();
    }
    _player.dispose();
    _position.dispose();
    _duration.dispose();
    _buffering.dispose();
    _playing.dispose();
    _pendingSeek.dispose();
    _scrubVisible.dispose();
    unawaited(WakelockPlus.disable());
    SystemChrome.setPreferredOrientations(DeviceOrientation.values);
    if (!_isTv) {
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    }
    super.dispose();
  }

  /// Handheld only: switch to Picture-in-Picture instead of stopping playback when backgrounded.
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.inactive || _isTv || !Platform.isAndroid || !_playing.value) return;
    final w = _videoWidth ?? 16;
    final h = _videoHeight ?? 9;
    unawaited(NativePlatform.enterPip(width: w, height: h));
  }

  Future<void> _open() async {
    if (!mounted) return;
    setState(() {
      _error = null;
      _videoWidth = null;
      _videoHeight = null;
    });
    _buffering.value = true;
    _pendingSeek.value = null;
    final start = _pendingStartMs;
    _pendingStartMs = null;
    await _tuned;
    try {
      await _player.open(
        Media(_item.url, httpHeaders: const {'User-Agent': 'MultIPTV/1.0'}, start: start == null ? null : Duration(milliseconds: start)),
      );
    } catch (e) {
      // Does not cover a native crash (segfault in mpv/MediaCodec/the GPU driver): those never
      // reach Dart at all. This only catches what mpv/media_kit itself reports as a Dart error.
      ref.read(appLoggerProvider).error('player', 'open failed on ${_path.name}: $e', context: {'kind': _item.kind.name});
      if (mounted) setState(() => _error = '$e');
      return;
    }
    if (_isLive) _saveProgress();
  }

  late final Future<void> _tuned;

  static const _directUnsupportedKey = 'directDecodeUnsupported';
  static const _hardwareUnsupportedKey = 'hardwareCopyUnsupported';
  late final DecodePath _path;
  bool _fellBack = false;
  Timer? _watchdog;
  final _progressFocus = FocusNode(debugLabel: 'progress');
  final _playFocus = FocusNode(debugLabel: 'play');
  // Overlay-visible Up routing needs to know which button is focused: back (top-left), the
  // channel-list toggle (live, top-right), and the transport row's outer buttons.
  final _backFocus = FocusNode(debugLabel: 'back');
  final _prevFocus = FocusNode(debugLabel: 'prev');
  final _nextFocus = FocusNode(debugLabel: 'next');
  final _listToggleFocus = FocusNode(debugLabel: 'list-toggle');
  final _replayFocus = FocusNode(debugLabel: 'replay');
  final _forwardFocus = FocusNode(debugLabel: 'forward');

  DecodePath _defaultPath() {
    // Emulators cannot create mpv's EGL context (vo=gpu): only the direct path shows a picture.
    if (ref.read(isEmulatorProvider)) return DecodePath.direct;
    final prefs = ref.read(sharedPreferencesProvider);
    return switch (ref.read(settingsProvider).videoDecoder) {
      VideoDecoder.direct => DecodePath.direct,
      VideoDecoder.compat => DecodePath.hardware,
      VideoDecoder.software => DecodePath.software,
      // `direct` (zero-copy, vo=mediacodec_embed) used to be the TV default here, but on weak
      // GPU/driver combos (e.g. Mi Box S) it can decode a rejected profile into garbage (green
      // tiles, partially black frame) *with* a valid frame size reported — the black-screen
      // watchdog below only fires on a frame size that never arrives, so that failure mode never
      // triggers the fallback to `hardware`. `hardware` (vo=gpu, hwdec=mediacodec-copy) is the
      // safer default everywhere; the user can still force `direct` in Settings.
      VideoDecoder.auto => (prefs.getBool(_directUnsupportedKey) ?? false)
          ? ((prefs.getBool(_hardwareUnsupportedKey) ?? false) ? DecodePath.software : DecodePath.hardware)
          : DecodePath.hardware,
    };
  }

  /// mpv reports the decoder re-init done by `vo=mediacodec_embed` as a failed seek on live
  /// (unseekable) streams; playback is unaffected, so it must not raise the error banner.
  static bool _isBenignError(String e) => e.contains('Cannot seek in this stream') || e.contains('force-seekable');

  /// A rejected stream (unsupported profile, 10-bit, old firmware) leaves audio without picture on
  /// the hardware paths; these messages are mpv's ways of saying so.
  static bool _isDecoderError(String e) {
    final s = e.toLowerCase();
    return s.contains('could not open codec') || s.contains('hardware decod') || s.contains('video chain') || s.contains('mediacodec') || s.contains('failed to initialize');
  }

  /// Black screen without any error (decoder produces nothing): if audio is playing for a while
  /// and no video frame size was ever reported, treat it as a decoder failure.
  void _armWatchdog() {
    if (_path == DecodePath.software || _fellBack || _videoWidth != null) return;
    _watchdog?.cancel();
    _watchdog = Timer(const Duration(seconds: 8), () {
      if (!mounted || _fellBack || _videoWidth != null || !_playing.value || _error != null) return;
      _fallback('no video frame after 8 s');
    });
  }

  /// Restarts this screen one rung down the ladder at the current position and remembers that
  /// this box cannot use the failed path, so the next playback skips the detour.
  Future<void> _fallback(String reason) async {
    if (_fellBack || !mounted) return;
    final next = switch (_path) {
      DecodePath.direct => DecodePath.hardware,
      DecodePath.hardware => DecodePath.software,
      DecodePath.software => null,
    };
    if (next == null) return;
    // Emulators have no other working path: keep the current one and let the error show.
    if (ref.read(isEmulatorProvider)) return;
    // Software decode of a 4K stream on a weak box (~2 GB RAM, no hardware help) is far more
    // likely to hit a native OOM crash than to just play slowly — that native crash is invisible
    // to any Dart try/catch (see openPlayer below), so refuse the combination up front and show a
    // clear error instead of trading a black screen for a crash. Only known ≥4K streams are
    // blocked (a stream whose dimensions were never reported might simply be fully unsupported,
    // and software is still worth trying there).
    if (next == DecodePath.software && ref.read(isLowEndDeviceProvider) && (_videoWidth ?? 0) >= 3840) {
      _fellBack = true;
      _watchdog?.cancel();
      ref.read(appLoggerProvider).error(
        'player',
        '${_path.name} failed ($reason) → refusing software fallback for 4K on a low-end device',
        context: {'width': _videoWidth, 'height': _videoHeight, 'kind': _item.kind.name},
      );
      setState(() => _error = AppLocalizations.of(context).qualityNotSupportedLowEnd);
      return;
    }
    _fellBack = true;
    _watchdog?.cancel();
    ref.read(appLoggerProvider).warn(
      'player',
      '${_path.name} failed ($reason) → restarting with ${next.name}',
      context: {'width': _videoWidth, 'height': _videoHeight, 'kind': _item.kind.name},
    );
    if (ref.read(settingsProvider).videoDecoder == VideoDecoder.auto) {
      final prefs = ref.read(sharedPreferencesProvider);
      await prefs.setBool(_path == DecodePath.direct ? _directUnsupportedKey : _hardwareUnsupportedKey, true);
    }
    if (!mounted) return;
    final position = _isLive ? null : _position.value.inMilliseconds;
    context.pushReplacement(
      Routes.player,
      extra: widget.request.copyWith(startIndex: _index, startPositionMs: position, decodePath: next),
    );
  }

  /// mpv options media_kit hard-codes for desktop that hurt weak Android devices.
  void _tunePlayer() {
    final native = _player.platform;
    if (native is! NativePlayer) {
      _tuned = Future.value();
      return;
    }
    final lowEnd = ref.read(isLowEndDeviceProvider);
    // mpv/ffmpeg resolve hostnames themselves; route them through the loopback proxy so a custom
    // DNS (Réglages → Réseau / DNS) also applies to playlist streams, not just Dio/API calls.
    final dnsProxyPort = ref.read(dnsProxyProvider).value;
    _tuned = Future.wait([
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
      if (dnsProxyPort != null) native.setProperty('http-proxy', 'http://127.0.0.1:$dnsProxyPort'),
      // Live TS: start decoding as soon as the first packets arrive instead of probing 5 s of data.
      if (_isLive) ...[
        native.setProperty('demuxer-lavf-analyzeduration', '1'),
        native.setProperty('demuxer-lavf-probesize', '500000'),
        native.setProperty('demuxer-readahead-secs', '3'),
      ] else
        native.setProperty('demuxer-readahead-secs', '20'),
      if (_path != DecodePath.direct && lowEnd) ...[
        // Mali-400/450 class GPUs: plain bilinear scaling, no dithering/gamma passes.
        native.setProperty('gpu-dumb-mode', 'yes'),
        native.setProperty('vd-lavc-fast', 'yes'),
      ],
      if (_path == DecodePath.software) ...[
        native.setProperty('vd-lavc-skiploopfilter', lowEnd ? 'all' : 'nonkey'),
        native.setProperty('vd-lavc-threads', '0'),
      ] else if (lowEnd)
        // Hardware decoding leaves the CPU idle; extra software threads only cost RAM on 2 GB boxes.
        native.setProperty('vd-lavc-threads', '2'),
    ]).then((_) {}, onError: (Object e) => debugPrint('mpv tuning failed: $e'));
  }

  Future<void> _saveProgress({bool flush = false}) async {
    final playlistId = _playlistId;
    if (playlistId == null) return;
    try {
      if (_isLive) {
        if (_item.id.contains('@')) return; // catch-up playback is not a "recent channel"
        await _db.saveHistory(playlistId: playlistId, kind: ContentKind.live, itemId: _item.id);
      } else {
        final pos = _position.value;
        if (pos < const Duration(seconds: 5)) return;
        await _db.saveHistory(
          playlistId: playlistId,
          kind: _item.kind,
          itemId: _item.id,
          parentId: _item.parentId,
          positionMs: pos.inMilliseconds,
          durationMs: _duration.value.inMilliseconds,
        );
      }
      // Mirror to the account (profile + playlist scoped); debounced while playing, immediate on exit.
      _sync.schedule(playlistId);
      if (flush) unawaited(_sync.flush());
    } catch (e) {
      debugPrint('saveHistory failed: $e');
    }
  }

  void _goTo(int index) {
    if (index < 0 || index >= widget.request.items.length) return;
    _saveProgress();
    setState(() {
      _index = index;
      _showList = false;
    });
    _open();
    _showOverlay();
  }

  void _next() => _goTo(_index + 1 < widget.request.items.length ? _index + 1 : (_isLive ? 0 : _index));
  void _previous() => _goTo(_index > 0 ? _index - 1 : (_isLive ? widget.request.items.length - 1 : 0));

  void _showOverlay() {
    if (!_overlay) {
      setState(() => _overlay = true);
      // Land the D-pad on Play so the first press does something visible.
      if (_isTv) WidgetsBinding.instance.addPostFrameCallback((_) => _playFocus.requestFocus());
    }
    _scheduleHide();
  }

  void _scheduleHide() {
    _hideTimer?.cancel();
    _hideTimer = Timer(const Duration(seconds: 5), () {
      if (mounted && !_showList && _pendingSeek.value == null) setState(() => _overlay = false);
    });
  }

  void _toggleOverlay() {
    if (_overlay) {
      _hideTimer?.cancel();
      setState(() => _overlay = false);
    } else {
      _showOverlay();
    }
  }

  // ---- Seeking -----------------------------------------------------------

  Duration _clamp(Duration t) {
    if (t < Duration.zero) return Duration.zero;
    final d = _duration.value;
    return d > Duration.zero && t > d ? d : t;
  }

  /// Accumulates [delta]; the actual seek is committed once taps stop (or the key is released).
  /// [showOverlay] is false for a D-pad seek starting from a hidden overlay: only the seek pill
  /// (and, while a key is held, the scrub bar) should appear, not the full transport controls.
  void _seekBy(Duration delta, {bool commitNow = false, bool showOverlay = true}) {
    if (_isLive) return;
    final pending = (_pendingSeek.value ?? Duration.zero) + delta;
    _pendingSeek.value = pending;
    _position.value = _clamp(_position.value + delta);
    if (showOverlay) _showOverlay();
    _seekCommitTimer?.cancel();
    if (commitNow) {
      _commitSeek();
    } else {
      _seekCommitTimer = Timer(_seekCommitDelay, _commitSeek);
    }
  }

  Future<void> _commitSeek() async {
    _seekCommitTimer?.cancel();
    if (_pendingSeek.value == null) return;
    final target = _position.value;
    await _player.seek(target);
    _pendingSeek.value = null;
    _seekHold = null;
    _scrubVisible.value = false;
  }

  /// Long press: the step grows the longer the key is held (10s → 60s over ~2.5s), so scrubbing far
  /// across a long video is quick while a first tap still moves by the flat [_seekStep].
  Duration _repeatStep() {
    final hold = _seekHold ??= Stopwatch()..start();
    final heldMs = hold.elapsedMilliseconds.clamp(0, 2500);
    final seconds = 10 + (60 - 10) * heldMs / 2500;
    return Duration(seconds: seconds.round());
  }

  void _togglePlay() {
    _player.playOrPause();
    _showOverlay();
  }

  // ---- Keys ---------------------------------------------------------------

  KeyEventResult _onKey(FocusNode node, KeyEvent event) {
    // Self-heal a lost focus instead of leaving the D-pad "stuck": a button's own rebuild (e.g.
    // skip_next's ValueListenableBuilder rebuilding after _next() zaps the channel while it was
    // focused) can leave primaryFocus null, with nothing left to receive the next key event's
    // bubble chain — the overlay then stops responding to the D-pad until it is hidden and
    // re-shown (which happens to refocus Play). Catch it here instead, on whichever key notices.
    if (_overlay && FocusManager.instance.primaryFocus == null) {
      _playFocus.requestFocus();
    }
    final key = event.logicalKey;
    final isLeft = key == LogicalKeyboardKey.arrowLeft || key == LogicalKeyboardKey.mediaRewind;
    final isRight = key == LogicalKeyboardKey.arrowRight || key == LogicalKeyboardKey.mediaFastForward;
    final isMediaSeek = key == LogicalKeyboardKey.mediaRewind || key == LogicalKeyboardKey.mediaFastForward;
    final isArrow = isLeft || isRight || key == LogicalKeyboardKey.arrowUp || key == LogicalKeyboardKey.arrowDown;
    // With the overlay up, left/right only scrub when the progress bar has focus; elsewhere the
    // D-pad walks the buttons like any other screen. Hidden overlay: the whole remote drives playback.
    final scrubKeys = !_isLive && (isLeft || isRight) && (isMediaSeek || !_overlay || _progressFocus.hasFocus);

    // Key release ends a long-press scrub: commit immediately.
    if (event is KeyUpEvent) {
      if ((isLeft || isRight) && !_isLive && _pendingSeek.value != null) {
        _commitSeek();
        return KeyEventResult.handled;
      }
      return KeyEventResult.ignored;
    }
    if (_showList) return KeyEventResult.ignored;
    final repeat = event is KeyRepeatEvent;

    if (scrubKeys) {
      final step = repeat ? _repeatStep() : _seekStep;
      // A short tap (from a hidden overlay) only nudges the seek pill; a held key additionally
      // opens the lightweight scrub bar. Neither reveals the full transport controls unless the
      // overlay was already up (e.g. scrubbing via the focused progress bar).
      if (repeat) _scrubVisible.value = true;
      _seekBy(isRight ? step : -step, showOverlay: _overlay);
      return KeyEventResult.handled;
    }
    if (repeat) return KeyEventResult.ignored;

    // Overlay visible + Up: route to a specific button instead of Flutter's default geometric
    // traversal, which is unpredictable across this row (transport pill, progress bar, top row).
    if (_overlay && key == LogicalKeyboardKey.arrowUp) {
      final current = FocusManager.instance.primaryFocus;
      FocusNode? target;
      if (_isLive) {
        if (current == _playFocus || current == _prevFocus) {
          target = _backFocus;
        } else if (current == _nextFocus) {
          target = _listToggleFocus;
        }
      } else {
        if (current == _progressFocus) {
          target = _backFocus;
        } else if (current == _playFocus || current == _prevFocus || current == _replayFocus || current == _forwardFocus || current == _nextFocus) {
          target = _progressFocus;
        }
      }
      if (target != null) {
        target.requestFocus();
        _scheduleHide();
        return KeyEventResult.handled;
      }
    }

    if (_overlay && isArrow) {
      // Keep the controls visible while the user moves between them; traversal does the rest.
      _scheduleHide();
      return KeyEventResult.ignored;
    }

    // CH+/CH- zap regardless of the D-pad remap below, matching a physical remote's dedicated keys.
    if (key == LogicalKeyboardKey.channelUp || key == LogicalKeyboardKey.channelDown) {
      if (_isLive && !_overlay) {
        key == LogicalKeyboardKey.channelUp ? _previous() : _next();
        return KeyEventResult.handled;
      }
    } else if (key == LogicalKeyboardKey.arrowLeft || key == LogicalKeyboardKey.arrowRight) {
      // Live, hidden overlay: left/right zap within the current category's list (wraps at the ends).
      if (_isLive && !_overlay) {
        key == LogicalKeyboardKey.arrowLeft ? _previous() : _next();
        return KeyEventResult.handled;
      }
    } else if ((key == LogicalKeyboardKey.arrowUp || key == LogicalKeyboardKey.arrowDown) && !_overlay) {
      _showOverlay();
      return KeyEventResult.handled;
    } else if ((key == LogicalKeyboardKey.select || key == LogicalKeyboardKey.enter || key == LogicalKeyboardKey.gameButtonA) && !_overlay) {
      // A single press both pauses and reveals the controls, instead of needing a second press on Play.
      _togglePlay();
      return KeyEventResult.handled;
    } else if (key == LogicalKeyboardKey.mediaPlayPause || key == LogicalKeyboardKey.mediaPlay || key == LogicalKeyboardKey.mediaPause || key == LogicalKeyboardKey.space) {
      _togglePlay();
      return KeyEventResult.handled;
    } else if (key == LogicalKeyboardKey.mediaTrackNext || key == LogicalKeyboardKey.mediaSkipForward) {
      _isLive ? _next() : _seekBy(const Duration(seconds: 60), commitNow: true);
      return KeyEventResult.handled;
    } else if (key == LogicalKeyboardKey.mediaTrackPrevious || key == LogicalKeyboardKey.mediaSkipBackward) {
      _isLive ? _previous() : _seekBy(const Duration(seconds: -60), commitNow: true);
      return KeyEventResult.handled;
    } else if (key == LogicalKeyboardKey.contextMenu || key == LogicalKeyboardKey.info || key == LogicalKeyboardKey.guide) {
      setState(() => _showList = !_showList);
      return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  }

  Future<bool> _onBack() async {
    if (_showList) {
      setState(() => _showList = false);
      return false;
    }
    if (_overlay && _isTv) {
      _hideTimer?.cancel();
      setState(() => _overlay = false);
      return false;
    }
    return true;
  }

  String? get _resolution => (_videoWidth ?? 0) > 0 && (_videoHeight ?? 0) > 0 ? '$_videoWidth×$_videoHeight' : null;

  // ---- UI -----------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(settingsProvider);
    final l10n = AppLocalizations.of(context);
    final fit = switch (settings.videoFit) {
      VideoFit.contain => BoxFit.contain,
      VideoFit.cover => BoxFit.cover,
      VideoFit.fill => BoxFit.fill,
    };

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        if (await _onBack() && context.mounted) context.pop();
      },
      child: Scaffold(
        backgroundColor: Colors.black,
        body: Focus(
          // A screen-sized fallback target: if a directional move fails to find its next candidate,
          // or the initial autofocus race lands here instead of on a transport button, default
          // traversal has nowhere useful to go from a node this size — every subsequent arrow key
          // looks "stuck" until the overlay is hidden and re-shown (which explicitly refocuses
          // Play). Rather than opting out of focus entirely (which left nothing focused at all, so
          // key events never reached this handler in the first place), immediately hand focus to
          // Play whenever this node ends up holding it.
          autofocus: true,
          onFocusChange: (hasFocus) {
            if (hasFocus) _playFocus.requestFocus();
          },
          onKeyEvent: _onKey,
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: _toggleOverlay,
            onDoubleTapDown: (d) {
              final w = MediaQuery.sizeOf(context).width;
              _seekBy(d.globalPosition.dx < w / 2 ? -_seekStep : _seekStep);
            },
            onVerticalDragEnd: _isLive
                ? (d) {
                    final v = d.primaryVelocity ?? 0;
                    if (v < -300) _next();
                    if (v > 300) _previous();
                  }
                : null,
            child: Stack(
              fit: StackFit.expand,
              children: [
                RepaintBoundary(
                  child: Video(
                    controller: _controller,
                    controls: NoVideoControls,
                    fit: fit,
                    subtitleViewConfiguration: SubtitleViewConfiguration(
                      style: TextStyle(
                        color: Color(settings.subtitleColor),
                        fontSize: 32 * settings.subtitleScale,
                        backgroundColor: settings.subtitleBackground ? Colors.black87 : Colors.transparent,
                        shadows: settings.subtitleBackground ? null : const [Shadow(blurRadius: 6, color: Colors.black)],
                      ),
                      // Lift subtitles above the transport controls while the overlay is visible.
                      padding: EdgeInsets.fromLTRB(24, 24, 24, _overlay && !_isLive ? 150 : 40),
                    ),
                  ),
                ),
                if (_error == null)
                  ValueListenableBuilder<bool>(
                    valueListenable: _buffering,
                    builder: (_, buffering, _) => buffering ? const Center(child: CircularProgressIndicator()) : const SizedBox.shrink(),
                  ),
                if (_error != null) _ErrorBanner(message: _error!, onRetry: _open, onExit: () => context.pop()),
                if (!_isLive) _SeekIndicator(pending: _pendingSeek, position: _position),
                if (!_isLive)
                  ValueListenableBuilder<bool>(
                    valueListenable: _scrubVisible,
                    builder: (_, visible, child) => visible ? child! : const SizedBox.shrink(),
                    child: _ScrubBar(position: _position, duration: _duration),
                  ),
                AnimatedOpacity(
                  opacity: _overlay ? 1 : 0,
                  duration: const Duration(milliseconds: 200),
                  child: IgnorePointer(
                    ignoring: !_overlay,
                    // Invisible controls must not catch the D-pad.
                    child: ExcludeFocus(excluding: !_overlay, child: _buildOverlay(context, l10n, settings)),
                  ),
                ),
                if (_showList) _buildList(context),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildOverlay(BuildContext context, AppLocalizations l10n, AppSettings settings) {
    final text = Theme.of(context).textTheme;
    final item = _item;
    final res = _resolution;
    final gutter = MediaQuery.sizeOf(context).width >= 900 ? 48.0 : 16.0;
    final top = MediaQuery.paddingOf(context).top;
    final bottom = MediaQuery.paddingOf(context).bottom;
    return Column(
      children: [
        Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Color(0xCC000000), Colors.transparent]),
          ),
          padding: EdgeInsets.fromLTRB(gutter - 8, top + 12, gutter, 40),
          child: Row(
            children: [
              IconButton(focusNode: _backFocus, icon: const Icon(Icons.arrow_back_rounded), onPressed: () => context.pop()),
              const SizedBox(width: 8),
              if (item.logo != null)
                Container(
                  width: 64,
                  height: 40,
                  margin: const EdgeInsets.only(right: 14),
                  padding: const EdgeInsets.all(5),
                  decoration: BoxDecoration(color: const Color(0x33FFFFFF), borderRadius: BorderRadius.circular(8)),
                  child: AppImage(item.logo, fit: BoxFit.contain, icon: Icons.tv, decodeWidth: 200),
                ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(item.title, style: text.titleLarge, maxLines: 1, overflow: TextOverflow.ellipsis),
                    if (item.subtitle != null)
                      Text(item.subtitle!, style: text.bodySmall, maxLines: 1, overflow: TextOverflow.ellipsis),
                  ],
                ),
              ),
              if (_isLive) const Padding(padding: EdgeInsets.only(left: 8), child: MetaBadge('LIVE', filled: true)),
              if (res != null) Padding(padding: const EdgeInsets.only(left: 8), child: MetaBadge(res)),
              if (_isLive)
                Padding(
                  padding: const EdgeInsets.only(left: 8),
                  child: IconButton(
                    focusNode: _listToggleFocus,
                    tooltip: l10n.channelList,
                    icon: const Icon(Icons.view_list_rounded),
                    onPressed: () => setState(() => _showList = true),
                  ),
                ),
            ],
          ),
        ),
        const Spacer(),
        Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(begin: Alignment.bottomCenter, end: Alignment.topCenter, colors: [Color(0xE6000000), Colors.transparent]),
          ),
          padding: EdgeInsets.fromLTRB(gutter, 48, gutter, 16 + bottom),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (_isLive && item.epgChannelId != null) _EpgLine(epgChannelId: item.epgChannelId!, use24h: settings.use24hClock),
              if (!_isLive)
                _ProgressBar(
                  focusNode: _progressFocus,
                  position: _position,
                  duration: _duration,
                  onScrub: (t) {
                    _pendingSeek.value = t - _position.value;
                    _position.value = t;
                  },
                  onScrubEnd: (t) {
                    _position.value = t;
                    _pendingSeek.value = Duration.zero;
                    _commitSeek();
                  },
                  onFocus: _scheduleHide,
                ),
              const SizedBox(height: 10),
              Row(
                children: [
                  // Left cluster keeps the row balanced with the right-hand tools.
                  Expanded(
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: !_isLive
                          ? ValueListenableBuilder<Duration>(
                              valueListenable: _position,
                              builder: (_, pos, _) => Text(formatDuration(pos), style: text.labelLarge),
                            )
                          : const SizedBox.shrink(),
                    ),
                  ),
                  _ControlPill(
                    children: [
                      IconButton(
                        focusNode: _prevFocus,
                        tooltip: _isLive ? l10n.previousChannel : null,
                        icon: const Icon(Icons.skip_previous_rounded),
                        onPressed: widget.request.items.length > 1 ? _previous : null,
                      ),
                      if (!_isLive) IconButton(focusNode: _replayFocus, icon: const Icon(Icons.replay_rounded), onPressed: () => _seekBy(-_seekStep)),
                      ValueListenableBuilder<bool>(
                        valueListenable: _playing,
                        builder: (_, playing, _) => IconButton(
                          focusNode: _playFocus,
                          autofocus: true,
                          iconSize: 34,
                          icon: Icon(playing ? Icons.pause_rounded : Icons.play_arrow_rounded),
                          onPressed: _togglePlay,
                        ),
                      ),
                      if (!_isLive) IconButton(focusNode: _forwardFocus, icon: const Icon(Icons.forward_rounded), onPressed: () => _seekBy(_seekStep)),
                      IconButton(
                        focusNode: _nextFocus,
                        tooltip: _isLive ? l10n.nextChannel : l10n.nextEpisode,
                        icon: const Icon(Icons.skip_next_rounded),
                        onPressed: widget.request.items.length > 1 ? _next : null,
                      ),
                    ],
                  ),
                  Expanded(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        if (!_isLive)
                          ValueListenableBuilder<Duration>(
                            valueListenable: _duration,
                            builder: (_, dur, _) => ValueListenableBuilder<Duration>(
                              valueListenable: _position,
                              builder: (_, pos, _) => Padding(
                                padding: const EdgeInsets.only(right: 12),
                                child: Text(dur > pos ? '−${formatDuration(dur - pos)}' : formatDuration(dur), style: text.labelLarge),
                              ),
                            ),
                          ),
                        if (_tracks.audio.length > 2)
                          _TrackButton<AudioTrack>(
                            icon: Icons.audiotrack_rounded,
                            tooltip: l10n.audioTrack,
                            tracks: _tracks.audio.where((t) => t.id != 'auto').toList(),
                            current: _track.audio,
                            label: (t) => t.id == 'no' ? l10n.off : [t.title, t.language, t.id].whereType<String>().where((s) => s.isNotEmpty).join(' · '),
                            onSelected: (t) {
                              _player.setAudioTrack(t);
                              _showOverlay();
                            },
                          ),
                        if (_tracks.subtitle.length > 1)
                          _TrackButton<SubtitleTrack>(
                            icon: Icons.subtitles_rounded,
                            tooltip: l10n.subtitleTrack,
                            tracks: _tracks.subtitle.where((t) => t.id != 'auto').toList(),
                            current: _track.subtitle,
                            label: (t) => t.id == 'no' ? l10n.off : [t.title, t.language, t.id].whereType<String>().where((s) => s.isNotEmpty).join(' · '),
                            onSelected: (t) {
                              _player.setSubtitleTrack(t);
                              _showOverlay();
                            },
                          ),
                        if (!_isLive)
                          PopupMenuButton<double>(
                            tooltip: l10n.playbackSpeed,
                            onSelected: (r) => _player.setRate(r),
                            itemBuilder: (_) => [for (final r in const [0.5, 0.75, 1.0, 1.25, 1.5, 2.0]) PopupMenuItem(value: r, child: Text('${r}x'))],
                            child: Padding(padding: const EdgeInsets.symmetric(horizontal: 10), child: Text('${_rate}x', style: text.labelLarge)),
                          ),
                        IconButton(
                          tooltip: l10n.videoFit,
                          icon: const Icon(Icons.aspect_ratio_rounded),
                          onPressed: () {
                            final values = VideoFit.values;
                            final next = values[(values.indexOf(settings.videoFit) + 1) % values.length];
                            ref.read(settingsProvider.notifier).setVideoFit(next);
                            _showOverlay();
                          },
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildList(BuildContext context) {
    final items = widget.request.items;
    final l10n = AppLocalizations.of(context);
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        width: 380,
        decoration: const BoxDecoration(
          gradient: LinearGradient(begin: Alignment.centerLeft, end: Alignment.centerRight, colors: [Color(0xF20A0A0A), Color(0xD90A0A0A)]),
        ),
        padding: EdgeInsets.only(top: MediaQuery.paddingOf(context).top),
        child: FocusScope(
          autofocus: true,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
                child: Text(l10n.channelList, style: Theme.of(context).textTheme.titleMedium),
              ),
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.fromLTRB(12, 0, 12, 24),
                  itemCount: items.length,
                  itemExtent: 64,
                  addAutomaticKeepAlives: false,
                  controller: ScrollController(initialScrollOffset: (_index * 64.0 - 128).clamp(0, double.infinity)),
                  itemBuilder: (context, i) {
                    final it = items[i];
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 6),
                      child: ChannelTile(
                        name: it.title,
                        logo: it.logo,
                        dense: true,
                        number: i + 1,
                        selected: i == _index,
                        autofocus: i == _index,
                        onTap: () => _goTo(i),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Translucent rounded group holding the transport buttons.
class _ControlPill extends StatelessWidget {
  const _ControlPill({required this.children});
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(color: const Color(0x2EFFFFFF), borderRadius: BorderRadius.circular(999)),
      child: Row(mainAxisSize: MainAxisSize.min, children: children),
    );
  }
}

/// Thin scrubber (thickens while dragging or focused) driven by notifiers: repaints ~10×/s
/// without rebuilding the whole player. Focusable so the D-pad can land on it; left/right are
/// handled by the screen (accelerating seek) while it has focus.
class _ProgressBar extends StatefulWidget {
  const _ProgressBar({
    required this.focusNode,
    required this.position,
    required this.duration,
    required this.onScrub,
    required this.onScrubEnd,
    this.onFocus,
  });
  final FocusNode focusNode;
  final ValueNotifier<Duration> position;
  final ValueNotifier<Duration> duration;
  final ValueChanged<Duration> onScrub;
  final ValueChanged<Duration> onScrubEnd;
  final VoidCallback? onFocus;

  @override
  State<_ProgressBar> createState() => _ProgressBarState();
}

class _ProgressBarState extends State<_ProgressBar> {
  bool _dragging = false;
  bool _focused = false;

  Duration _at(double dx, double width) {
    final total = widget.duration.value.inMilliseconds;
    if (total <= 0) return Duration.zero;
    return Duration(milliseconds: ((dx / width).clamp(0.0, 1.0) * total).round());
  }

  @override
  Widget build(BuildContext context) {
    return Focus(
      focusNode: widget.focusNode,
      onFocusChange: (f) {
        setState(() => _focused = f);
        if (f) widget.onFocus?.call();
      },
      child: LayoutBuilder(
        builder: (context, c) => GestureDetector(
          behavior: HitTestBehavior.opaque,
          onHorizontalDragStart: (d) => setState(() => _dragging = true),
          onHorizontalDragUpdate: (d) => widget.onScrub(_at(d.localPosition.dx, c.maxWidth)),
          onHorizontalDragEnd: (_) {
            setState(() => _dragging = false);
            widget.onScrubEnd(widget.position.value);
          },
          onTapUp: (d) => widget.onScrubEnd(_at(d.localPosition.dx, c.maxWidth)),
          child: SizedBox(
            height: 28,
            width: double.infinity,
            child: ValueListenableBuilder<Duration>(
              valueListenable: widget.duration,
              builder: (context, dur, _) => ValueListenableBuilder<Duration>(
                valueListenable: widget.position,
                builder: (context, pos, _) {
                  final total = dur.inMilliseconds;
                  final value = total > 0 ? (pos.inMilliseconds / total).clamp(0.0, 1.0) : 0.0;
                  return CustomPaint(painter: _BarPainter(value: value, thick: _dragging || _focused, focused: _focused));
                },
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _BarPainter extends CustomPainter {
  const _BarPainter({required this.value, required this.thick, this.focused = false});
  final double value;
  final bool thick;
  final bool focused;

  @override
  void paint(Canvas canvas, Size size) {
    final h = thick ? 8.0 : 4.0;
    final y = size.height / 2;
    final track = RRect.fromRectAndRadius(Rect.fromLTWH(0, y - h / 2, size.width, h), Radius.circular(h / 2));
    canvas.drawRRect(track, Paint()..color = const Color(0x4DFFFFFF));
    final w = size.width * value;
    if (w > 0) {
      canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(0, y - h / 2, w, h), Radius.circular(h / 2)), Paint()..color = Colors.white);
    }
    if (focused) {
      // Halo + accent ring: the D-pad is on the bar, left/right will scrub.
      canvas.drawCircle(Offset(w, y), 16, Paint()..color = const Color(0x4D0A84FF));
      canvas.drawCircle(Offset(w, y), 11, Paint()..color = const Color(0xFF0A84FF));
    }
    canvas.drawCircle(Offset(w, y), thick ? 9 : 6, Paint()..color = Colors.white);
  }

  @override
  bool shouldRepaint(_BarPainter old) => old.value != value || old.thick != thick || old.focused != focused;
}

/// Display-only progress bar shown while a D-pad seek key is held: no focus/drag handling of its
/// own (that stays in [_PlayerScreenState._onKey]), just a live cursor so a long-press fast seek is
/// visible without popping the full transport controls.
class _ScrubBar extends StatelessWidget {
  const _ScrubBar({required this.position, required this.duration});
  final ValueNotifier<Duration> position;
  final ValueNotifier<Duration> duration;

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.paddingOf(context).bottom;
    return IgnorePointer(
      child: Align(
        alignment: Alignment.bottomCenter,
        child: Padding(
          padding: EdgeInsets.fromLTRB(48, 0, 48, 32 + bottom),
          child: SizedBox(
            height: 16,
            child: ValueListenableBuilder<Duration>(
              valueListenable: duration,
              builder: (context, dur, _) => ValueListenableBuilder<Duration>(
                valueListenable: position,
                builder: (context, pos, _) {
                  final total = dur.inMilliseconds;
                  final value = total > 0 ? (pos.inMilliseconds / total).clamp(0.0, 1.0) : 0.0;
                  return CustomPaint(painter: _BarPainter(value: value, thick: true));
                },
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Centered "+45 s → 01:12:30" feedback while taps accumulate.
class _SeekIndicator extends StatelessWidget {
  const _SeekIndicator({required this.pending, required this.position});
  final ValueNotifier<Duration?> pending;
  final ValueNotifier<Duration> position;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<Duration?>(
      valueListenable: pending,
      builder: (context, p, _) {
        if (p == null || p == Duration.zero) return const SizedBox.shrink();
        final secs = p.inSeconds;
        return IgnorePointer(
          child: Center(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 26, vertical: 14),
              decoration: BoxDecoration(color: const Color(0xB3000000), borderRadius: BorderRadius.circular(999)),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(secs < 0 ? Icons.fast_rewind_rounded : Icons.fast_forward_rounded, color: Colors.white, size: 32),
                  const SizedBox(width: 12),
                  Text(
                    '${secs > 0 ? '+' : '−'}${secs.abs()} s  ·  ${formatDuration(position.value)}',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _EpgLine extends ConsumerWidget {
  const _EpgLine({required this.epgChannelId, required this.use24h});
  final String epgChannelId;
  final bool use24h;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final playlist = ref.watch(activePlaylistProvider);
    if (playlist == null) return const SizedBox.shrink();
    final programs = ref.watch(nowNextProvider(NowNextQuery(playlist.id, epgChannelId))).value ?? const [];
    if (programs.isEmpty) return const SizedBox.shrink();
    final now = programs.first;
    final next = programs.length > 1 ? programs[1] : null;
    final total = now.end.difference(now.start).inSeconds;
    final elapsed = DateTime.now().difference(now.start).inSeconds;
    final text = Theme.of(context).textTheme;
    final t = context.tokens;
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(child: Text(now.title, style: text.titleMedium, maxLines: 1, overflow: TextOverflow.ellipsis)),
              Text(
                '${formatTime(context, now.start, use24h: use24h)} – ${formatTime(context, now.end, use24h: use24h)}',
                style: text.labelMedium?.copyWith(color: t.textMuted),
              ),
            ],
          ),
          if (total > 0)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: ClipRRect(borderRadius: BorderRadius.circular(2), child: ProgressStrip((elapsed / total).clamp(0, 1), height: 4)),
            ),
          if (next != null)
            Text(
              '${l10n.nextLabel}  ${formatTime(context, next.start, use24h: use24h)}  ${next.title}',
              style: text.bodySmall?.copyWith(color: t.textMuted),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
        ],
      ),
    );
  }
}

class _TrackButton<T> extends StatelessWidget {
  const _TrackButton({
    required this.icon,
    required this.tooltip,
    required this.tracks,
    required this.current,
    required this.label,
    required this.onSelected,
  });
  final IconData icon;
  final String tooltip;
  final List<T> tracks;
  final T current;
  final String Function(T) label;
  final ValueChanged<T> onSelected;

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<T>(
      tooltip: tooltip,
      icon: Icon(icon),
      onSelected: onSelected,
      itemBuilder: (_) => [
        for (final t in tracks)
          PopupMenuItem(
            value: t,
            child: Row(
              children: [
                Icon(t == current ? Icons.check_rounded : null, size: 18),
                const SizedBox(width: 8),
                Text(label(t)),
              ],
            ),
          ),
      ],
    );
  }
}

class _ErrorBanner extends StatelessWidget {
  const _ErrorBanner({required this.message, required this.onRetry, required this.onExit});
  final String message;
  final VoidCallback onRetry;
  final VoidCallback onExit;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final text = Theme.of(context).textTheme;
    final t = context.tokens;
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 460),
        child: GlassPanel(
          strong: true,
          radius: 20,
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.error_outline_rounded, color: Theme.of(context).colorScheme.error, size: 44),
              const SizedBox(height: 12),
              Text(l10n.playbackError, style: text.titleLarge),
              const SizedBox(height: 6),
              Text(l10n.playbackErrorDescription, style: text.bodyMedium?.copyWith(color: t.textMuted), textAlign: TextAlign.center),
              const SizedBox(height: 6),
              Text(message, style: text.bodySmall?.copyWith(color: t.textFaint), textAlign: TextAlign.center, maxLines: 3),
              const SizedBox(height: 20),
              Wrap(
                spacing: 10,
                children: [
                  PillButton(primary: true, autofocus: true, icon: Icons.refresh_rounded, label: l10n.retry, onPressed: onRetry),
                  PillButton(label: l10n.exit, onPressed: onExit),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
