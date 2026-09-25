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
import '../../core/db/database.dart';
import '../../core/log/app_logger.dart';
import '../../core/log/remote_key_tracker.dart';
import '../../core/log/telemetry.dart';
import '../../core/log/trace_tag.dart';
import '../../core/net/dns_providers.dart';
import '../../core/platform/native_platform.dart';
import '../../core/player/playback.dart';
import '../../core/settings/settings.dart';
import '../../core/sync/progress_sync.dart';
import '../../l10n/generated/app_localizations.dart';
import '../../widgets/common.dart';
import '../../widgets/format.dart';
import '../playlists/playlists_provider.dart';
import 'decode_policy.dart';
import 'mpv_tuning.dart';
import 'playback_telemetry.dart';
import 'player_controls.dart';

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
        // Warnings carry the decoder story (hwdec rejected, profile unsupported): kept as Sentry
        // breadcrumbs when it is configured.
        logLevel: kDebugMode || Telemetry.enabled ? MPVLogLevel.warn : MPVLogLevel.error,
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
    final dnsProxy = ref.read(dnsProxyProvider);
    _telemetry = PlaybackTelemetry(
      _player,
      dnsMode: ref.read(settingsProvider).dnsMode.name,
      proxyPort: dnsProxy.value,
      proxyState: dnsProxy.hasError ? 'error: ${dnsProxy.error}' : (dnsProxy.isLoading ? 'loading' : 'ready'),
      currentProxyPort: () => mounted ? ref.read(dnsProxyProvider).value : null,
      isBenign: isBenignMpvError,
      isDecoderError: isDecoderMpvError,
    );
    unawaited(WakelockPlus.enable());
    WidgetsBinding.instance.addObserver(this);

    void safeSet(VoidCallback fn) {
      if (mounted) setState(fn);
    }

    _subs.addAll([
      if (kDebugMode) _player.stream.log.listen((l) => debugPrint('mpv[${l.level}] ${l.prefix}: ${l.text}')),
      _player.stream.error.listen((e) {
        if (isBenignMpvError(e)) return;
        if (_path != DecodePath.software && isDecoderMpvError(e)) {
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
    _keyFocus.dispose();
    _playFocus.dispose();
    _backFocus.dispose();
    _prevFocus.dispose();
    _nextFocus.dispose();
    _listToggleFocus.dispose();
    _replayFocus.dispose();
    _forwardFocus.dispose();
    _saveProgress(flush: true);
    _telemetry.dispose(_closeReason);
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
    if (!mounted) return;
    _telemetry.opened(_item, _path, index: _index, total: widget.request.items.length, startMs: start);
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
  late final PlaybackTelemetry _telemetry;
  String _closeReason = 'closed';

  late final DecodePath _path;
  bool _fellBack = false;
  Timer? _watchdog;
  final _progressFocus = TraceTag.name(FocusNode(debugLabel: 'progress'), 'player-progress');
  // Holds focus while the controls are hidden, so every key reaches [_onKey]. Without it focus
  // fell back to the route's scope: the first press after the controls hid was lost (Right did
  // not zap) or OK paused instead of only showing the controls (Sentry FLUTTER-4, FLUTTER-7).
  final _keyFocus = TraceTag.name(FocusNode(debugLabel: 'player-keys'), 'player-keys');
  final _playFocus = TraceTag.name(FocusNode(debugLabel: 'play'), 'player-play');
  // Overlay-visible Up routing needs to know which button is focused: back (top-left), the
  // channel-list toggle (live, top-right), and the transport row's outer buttons.
  final _backFocus = TraceTag.name(FocusNode(debugLabel: 'back'), 'player-back');
  final _prevFocus = TraceTag.name(FocusNode(debugLabel: 'prev'), 'player-prev');
  final _nextFocus = TraceTag.name(FocusNode(debugLabel: 'next'), 'player-next');
  final _listToggleFocus = TraceTag.name(FocusNode(debugLabel: 'list-toggle'), 'player-list-toggle');
  final _replayFocus = TraceTag.name(FocusNode(debugLabel: 'replay'), 'player-replay');
  final _forwardFocus = TraceTag.name(FocusNode(debugLabel: 'forward'), 'player-forward');

  DecodePath _defaultPath() => defaultDecodePath(
        decoder: ref.read(settingsProvider).videoDecoder,
        isEmulator: ref.read(isEmulatorProvider),
        isTv: _isTv,
        hardwareCopyUnsupported: ref.read(sharedPreferencesProvider).getBool(hardwareCopyUnsupportedKey) ?? false,
      );

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
    // Software is a weak box's second chance for everything short of 4K (refused below).
    final next = nextDecodePath(_path, lowEnd: ref.read(isLowEndDeviceProvider));
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
    // Only a hardware-copy failure is remembered for the whole install: `direct` failures are
    // per stream (one SD channel refused by the decoder must not disable it for every channel).
    if (ref.read(settingsProvider).videoDecoder == VideoDecoder.auto && _path == DecodePath.hardware) {
      await ref.read(sharedPreferencesProvider).setBool(hardwareCopyUnsupportedKey, true);
    }
    if (!mounted) return;
    _closeReason = 'fallback to ${next.name}';
    final position = _isLive ? null : _position.value.inMilliseconds;
    context.pushReplacement(
      Routes.player,
      extra: widget.request.copyWith(startIndex: _index, startPositionMs: position, decodePath: next),
    );
  }

  /// Applies [tuneMpv] to the native player; [_open] waits for [_tuned].
  void _tunePlayer() {
    final native = _player.platform;
    if (native is! NativePlayer) {
      _tuned = Future.value();
      return;
    }
    _tuned = tuneMpv(native, isLive: _isLive, path: _path, lowEnd: ref.read(isLowEndDeviceProvider), dnsProxyPort: ref.read(dnsProxyProvider).value);
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
      if (mounted && !_showList && _pendingSeek.value == null) _hideOverlay();
    });
  }

  void _hideOverlay() {
    _hideTimer?.cancel();
    setState(() => _overlay = false);
    _keyFocus.requestFocus();
  }

  void _toggleOverlay() {
    if (_overlay) {
      _hideOverlay();
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
    _telemetry.seeked(target);
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
    final result = _handleKey(event);
    if (result == KeyEventResult.handled && event is KeyDownEvent) {
      RemoteKeyTracker.note('player: ${event.logicalKey.keyLabel} (overlay ${_overlay ? 'shown' : 'hidden'}${_isLive ? ', live' : ''})');
    }
    return result;
  }

  KeyEventResult _handleKey(KeyEvent event) {
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
      _hideOverlay();
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
          // While the controls are hidden this node keeps focus on purpose (see _keyFocus).
          focusNode: _keyFocus,
          autofocus: true,
          onFocusChange: (hasFocus) {
            if (hasFocus && _overlay) _playFocus.requestFocus();
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
                if (_error != null) PlayerErrorBanner(message: _error!, onRetry: _open, onExit: () => context.pop()),
                if (!_isLive) PlayerSeekIndicator(pending: _pendingSeek, position: _position),
                if (!_isLive)
                  ValueListenableBuilder<bool>(
                    valueListenable: _scrubVisible,
                    builder: (_, visible, child) => visible ? child! : const SizedBox.shrink(),
                    child: PlayerScrubBar(position: _position, duration: _duration),
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
              if (_isLive && item.epgChannelId != null) PlayerEpgLine(epgChannelId: item.epgChannelId!, use24h: settings.use24hClock),
              if (!_isLive)
                PlayerProgressBar(
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
                  PlayerControlPill(
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
                          PlayerTrackButton<AudioTrack>(
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
                          PlayerTrackButton<SubtitleTrack>(
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
