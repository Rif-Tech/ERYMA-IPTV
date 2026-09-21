import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:media_kit/media_kit.dart';
import 'package:media_kit_video/media_kit_video.dart';

import '../../app/responsive.dart';
import '../../app/theme.dart';
import '../../core/db/database.dart';
import '../../core/player/playback.dart';
import '../../core/settings/settings.dart';
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

class _PlayerScreenState extends ConsumerState<PlayerScreen> {
  late final Player _player;
  late final VideoController _controller;
  late int _index;
  final _subs = <StreamSubscription>[];

  bool _overlay = true;
  bool _showList = false;
  String? _error;
  bool _buffering = true;
  bool _playing = false;
  Tracks _tracks = const Tracks();
  Track _track = const Track();
  double _rate = 1.0;
  int? _videoWidth;
  int? _videoHeight;
  Timer? _hideTimer;
  Timer? _saveTimer;
  int? _pendingStartMs;

  // High-frequency values live in notifiers so only the progress bar repaints.
  final _position = ValueNotifier(Duration.zero);
  final _duration = ValueNotifier(Duration.zero);

  /// Accumulated, not yet committed seek offset (D-pad taps / long press).
  final _pendingSeek = ValueNotifier<Duration?>(null);
  Timer? _seekCommitTimer;
  int _seekRepeats = 0;

  PlayableItem get _item => widget.request.items[_index];
  bool get _isLive => _item.kind == ContentKind.live;

  // Captured at init: `ref` must not be used from dispose().
  late final AppDatabase _db;
  late final String? _playlistId;
  late final bool _isTv;

  @override
  void initState() {
    super.initState();
    _db = ref.read(databaseProvider);
    _playlistId = ref.read(activePlaylistProvider)?.id;
    _isTv = ref.read(isTelevisionProvider);
    _index = widget.request.startIndex;
    _pendingStartMs = widget.request.startPositionMs;
    _player = Player(
      configuration: PlayerConfiguration(
        title: 'MultIPTV',
        bufferSize: 32 * 1024 * 1024,
        logLevel: kDebugMode ? MPVLogLevel.warn : MPVLogLevel.error,
      ),
    );
    // Emulators cannot create mpv's EGL context (vo=gpu): decode straight into the surface instead.
    _controller = VideoController(
      _player,
      configuration: ref.read(isEmulatorProvider)
          ? const VideoControllerConfiguration(vo: 'mediacodec_embed', hwdec: 'mediacodec')
          : const VideoControllerConfiguration(),
    );

    void safeSet(VoidCallback fn) {
      if (mounted) setState(fn);
    }

    _subs.addAll([
      if (kDebugMode) _player.stream.log.listen((l) => debugPrint('mpv[${l.level}] ${l.prefix}: ${l.text}')),
      _player.stream.error.listen((e) => safeSet(() => _error = e)),
      _player.stream.buffering.listen((b) => safeSet(() => _buffering = b)),
      _player.stream.playing.listen((p) => safeSet(() => _playing = p)),
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
    _scheduleHide();
  }

  @override
  void dispose() {
    _hideTimer?.cancel();
    _saveTimer?.cancel();
    _seekCommitTimer?.cancel();
    _saveProgress();
    for (final s in _subs) {
      s.cancel();
    }
    _player.dispose();
    _position.dispose();
    _duration.dispose();
    _pendingSeek.dispose();
    SystemChrome.setPreferredOrientations(DeviceOrientation.values);
    if (!_isTv) {
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    }
    super.dispose();
  }

  Future<void> _open() async {
    if (!mounted) return;
    setState(() {
      _error = null;
      _buffering = true;
      _videoWidth = null;
      _videoHeight = null;
    });
    _pendingSeek.value = null;
    final start = _pendingStartMs;
    _pendingStartMs = null;
    await _player.open(
      Media(_item.url, httpHeaders: const {'User-Agent': 'MultIPTV/1.0'}, start: start == null ? null : Duration(milliseconds: start)),
    );
    if (_isLive) _saveProgress();
  }

  Future<void> _saveProgress() async {
    final playlistId = _playlistId;
    if (playlistId == null) return;
    try {
      if (_isLive) {
        if (_item.id.contains('@')) return; // catch-up playback is not a "recent channel"
        await _db.saveHistory(playlistId: playlistId, kind: ContentKind.live, itemId: _item.id);
        return;
      }
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
    if (!_overlay) setState(() => _overlay = true);
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
  void _seekBy(Duration delta, {bool commitNow = false}) {
    if (_isLive) return;
    final pending = (_pendingSeek.value ?? Duration.zero) + delta;
    _pendingSeek.value = pending;
    _position.value = _clamp(_position.value + delta);
    _showOverlay();
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
    _seekRepeats = 0;
  }

  /// Long press: repeats grow the step (15s → 30s → 60s) so scrubbing far is quick.
  Duration _repeatStep() {
    _seekRepeats++;
    if (_seekRepeats > 20) return _seekStep * 4;
    if (_seekRepeats > 8) return _seekStep * 2;
    return _seekStep;
  }

  void _togglePlay() {
    _player.playOrPause();
    _showOverlay();
  }

  // ---- Keys ---------------------------------------------------------------

  KeyEventResult _onKey(FocusNode node, KeyEvent event) {
    final key = event.logicalKey;
    final isLeft = key == LogicalKeyboardKey.arrowLeft || key == LogicalKeyboardKey.mediaRewind;
    final isRight = key == LogicalKeyboardKey.arrowRight || key == LogicalKeyboardKey.mediaFastForward;

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

    if (!_isLive && (isLeft || isRight)) {
      final step = repeat ? _repeatStep() : _seekStep;
      _seekBy(isRight ? step : -step);
      return KeyEventResult.handled;
    }
    if (repeat) return KeyEventResult.ignored;

    if (key == LogicalKeyboardKey.arrowUp || key == LogicalKeyboardKey.channelUp) {
      if (_isLive && !_overlay) {
        _previous();
        return KeyEventResult.handled;
      }
    } else if (key == LogicalKeyboardKey.arrowDown || key == LogicalKeyboardKey.channelDown) {
      if (_isLive && !_overlay) {
        _next();
        return KeyEventResult.handled;
      }
    } else if ((key == LogicalKeyboardKey.select || key == LogicalKeyboardKey.enter || key == LogicalKeyboardKey.gameButtonA) && !_overlay) {
      _showOverlay();
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
          autofocus: true,
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
                if (_buffering && _error == null) const Center(child: CircularProgressIndicator()),
                if (_error != null) _ErrorBanner(message: _error!, onRetry: _open, onExit: () => context.pop()),
                if (!_isLive) _SeekIndicator(pending: _pendingSeek, position: _position),
                AnimatedOpacity(
                  opacity: _overlay ? 1 : 0,
                  duration: const Duration(milliseconds: 200),
                  child: IgnorePointer(ignoring: !_overlay, child: _buildOverlay(context, l10n, settings)),
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
              IconButton(icon: const Icon(Icons.arrow_back_rounded), onPressed: () => context.pop()),
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
                        tooltip: _isLive ? l10n.previousChannel : null,
                        icon: const Icon(Icons.skip_previous_rounded),
                        onPressed: widget.request.items.length > 1 ? _previous : null,
                      ),
                      if (!_isLive) IconButton(icon: const Icon(Icons.replay_rounded), onPressed: () => _seekBy(-_seekStep)),
                      IconButton(
                        autofocus: true,
                        iconSize: 34,
                        icon: Icon(_playing ? Icons.pause_rounded : Icons.play_arrow_rounded),
                        onPressed: _togglePlay,
                      ),
                      if (!_isLive) IconButton(icon: const Icon(Icons.forward_rounded), onPressed: () => _seekBy(_seekStep)),
                      IconButton(
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

/// Thin scrubber (thickens while dragging) driven by notifiers: repaints ~10×/s without
/// rebuilding the whole player.
class _ProgressBar extends StatefulWidget {
  const _ProgressBar({required this.position, required this.duration, required this.onScrub, required this.onScrubEnd});
  final ValueNotifier<Duration> position;
  final ValueNotifier<Duration> duration;
  final ValueChanged<Duration> onScrub;
  final ValueChanged<Duration> onScrubEnd;

  @override
  State<_ProgressBar> createState() => _ProgressBarState();
}

class _ProgressBarState extends State<_ProgressBar> {
  bool _dragging = false;

  Duration _at(double dx, double width) {
    final total = widget.duration.value.inMilliseconds;
    if (total <= 0) return Duration.zero;
    return Duration(milliseconds: ((dx / width).clamp(0.0, 1.0) * total).round());
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
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
                return CustomPaint(painter: _BarPainter(value: value, thick: _dragging));
              },
            ),
          ),
        ),
      ),
    );
  }
}

class _BarPainter extends CustomPainter {
  const _BarPainter({required this.value, required this.thick});
  final double value;
  final bool thick;

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
    canvas.drawCircle(Offset(w, y), thick ? 9 : 6, Paint()..color = Colors.white);
  }

  @override
  bool shouldRepaint(_BarPainter old) => old.value != value || old.thick != thick;
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
