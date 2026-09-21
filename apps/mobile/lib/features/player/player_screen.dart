import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:media_kit/media_kit.dart';
import 'package:media_kit_video/media_kit_video.dart';

import '../../app/responsive.dart';
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
                      padding: const EdgeInsets.all(24),
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
    final theme = Theme.of(context);
    final item = _item;
    final res = _resolution;
    return Column(
      children: [
        Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Colors.black87, Colors.transparent]),
          ),
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
          child: Row(
            children: [
              IconButton(icon: const Icon(Icons.arrow_back, color: Colors.white), onPressed: () => context.pop()),
              if (item.logo != null)
                Padding(
                  padding: const EdgeInsets.only(right: 12),
                  child: SizedBox(width: 48, height: 48, child: AppImage(item.logo, fit: BoxFit.contain, icon: Icons.tv)),
                ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(item.title, style: theme.textTheme.titleLarge?.copyWith(color: Colors.white), maxLines: 1, overflow: TextOverflow.ellipsis),
                    if (item.subtitle != null)
                      Text(item.subtitle!, style: theme.textTheme.bodyMedium?.copyWith(color: Colors.white70), maxLines: 1, overflow: TextOverflow.ellipsis),
                  ],
                ),
              ),
              if (res != null) _Badge(res),
              if (_isLive)
                IconButton(
                  tooltip: l10n.channelList,
                  icon: const Icon(Icons.list, color: Colors.white),
                  onPressed: () => setState(() => _showList = true),
                ),
            ],
          ),
        ),
        const Spacer(),
        Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(begin: Alignment.bottomCenter, end: Alignment.topCenter, colors: [Colors.black87, Colors.transparent]),
          ),
          padding: const EdgeInsets.fromLTRB(16, 32, 16, 12),
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
              Row(
                children: [
                  IconButton(
                    tooltip: _isLive ? l10n.previousChannel : null,
                    icon: const Icon(Icons.skip_previous, color: Colors.white),
                    onPressed: widget.request.items.length > 1 ? _previous : null,
                  ),
                  if (!_isLive)
                    IconButton(icon: const Icon(Icons.replay, color: Colors.white), onPressed: () => _seekBy(-_seekStep)),
                  IconButton(
                    autofocus: true,
                    iconSize: 40,
                    icon: Icon(_playing ? Icons.pause_circle : Icons.play_circle, color: Colors.white),
                    onPressed: _togglePlay,
                  ),
                  if (!_isLive)
                    IconButton(icon: const Icon(Icons.forward, color: Colors.white), onPressed: () => _seekBy(_seekStep)),
                  IconButton(
                    tooltip: _isLive ? l10n.nextChannel : l10n.nextEpisode,
                    icon: const Icon(Icons.skip_next, color: Colors.white),
                    onPressed: widget.request.items.length > 1 ? _next : null,
                  ),
                  const Spacer(),
                  if (res != null && !_isLive) Padding(padding: const EdgeInsets.only(right: 8), child: _Badge(res)),
                  if (_tracks.audio.length > 2)
                    _TrackButton<AudioTrack>(
                      icon: Icons.audiotrack,
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
                      icon: Icons.subtitles,
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
                      icon: Text('${_rate}x', style: const TextStyle(color: Colors.white)),
                      onSelected: (r) => _player.setRate(r),
                      itemBuilder: (_) => [for (final r in const [0.5, 0.75, 1.0, 1.25, 1.5, 2.0]) PopupMenuItem(value: r, child: Text('${r}x'))],
                    ),
                  IconButton(
                    tooltip: l10n.videoFit,
                    icon: const Icon(Icons.aspect_ratio, color: Colors.white),
                    onPressed: () {
                      final values = VideoFit.values;
                      final next = values[(values.indexOf(settings.videoFit) + 1) % values.length];
                      ref.read(settingsProvider.notifier).setVideoFit(next);
                      _showOverlay();
                    },
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
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        width: 360,
        color: Colors.black.withValues(alpha: 0.85),
        child: FocusScope(
          autofocus: true,
          child: ListView.builder(
            padding: const EdgeInsets.all(8),
            itemCount: items.length,
            itemExtent: 64,
            controller: ScrollController(initialScrollOffset: (_index * 64.0 - 128).clamp(0, double.infinity)),
            itemBuilder: (context, i) {
              final it = items[i];
              return Padding(
                padding: const EdgeInsets.only(bottom: 4),
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
      ),
    );
  }
}

/// Progress slider driven by notifiers: repaints ~10×/s without rebuilding the whole player.
class _ProgressBar extends StatelessWidget {
  const _ProgressBar({required this.position, required this.duration, required this.onScrub, required this.onScrubEnd});
  final ValueNotifier<Duration> position;
  final ValueNotifier<Duration> duration;
  final ValueChanged<Duration> onScrub;
  final ValueChanged<Duration> onScrubEnd;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<Duration>(
      valueListenable: duration,
      builder: (context, dur, _) => ValueListenableBuilder<Duration>(
        valueListenable: position,
        builder: (context, pos, _) {
          final total = dur.inMilliseconds;
          final value = pos.inMilliseconds.clamp(0, total > 0 ? total : 1).toDouble();
          return Row(
            children: [
              Text(formatDuration(pos), style: const TextStyle(color: Colors.white)),
              Expanded(
                child: Slider(
                  value: total > 0 ? value : 0,
                  max: total > 0 ? total.toDouble() : 1,
                  onChanged: total > 0 ? (v) => onScrub(Duration(milliseconds: v.round())) : null,
                  onChangeEnd: total > 0 ? (v) => onScrubEnd(Duration(milliseconds: v.round())) : null,
                ),
              ),
              Text(formatDuration(dur), style: const TextStyle(color: Colors.white)),
            ],
          );
        },
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
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
              decoration: BoxDecoration(color: Colors.black.withValues(alpha: 0.7), borderRadius: BorderRadius.circular(16)),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(secs < 0 ? Icons.fast_rewind : Icons.fast_forward, color: Colors.white, size: 36),
                  const SizedBox(width: 12),
                  Text(
                    '${secs > 0 ? '+' : '−'}${secs.abs()} s  ·  ${formatDuration(position.value)}',
                    style: const TextStyle(color: Colors.white, fontSize: 26, fontWeight: FontWeight.w600),
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

class _Badge extends StatelessWidget {
  const _Badge(this.text);
  final String text;
  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 4),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(border: Border.all(color: Colors.white70), borderRadius: BorderRadius.circular(6)),
      child: Text(text, style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600)),
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
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '${l10n.nowPlaying} · ${formatTime(context, now.start, use24h: use24h)} – ${formatTime(context, now.end, use24h: use24h)}  ${now.title}',
            style: const TextStyle(color: Colors.white),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          if (total > 0)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: LinearProgressIndicator(value: (elapsed / total).clamp(0, 1), minHeight: 3),
            ),
          if (next != null)
            Text(
              '${l10n.next} · ${formatTime(context, next.start, use24h: use24h)}  ${next.title}',
              style: const TextStyle(color: Colors.white70),
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
      icon: Icon(icon, color: Colors.white),
      onSelected: onSelected,
      itemBuilder: (_) => [
        for (final t in tracks)
          PopupMenuItem(
            value: t,
            child: Row(
              children: [
                Icon(t == current ? Icons.radio_button_checked : Icons.radio_button_off, size: 18),
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
    return Center(
      child: Card(
        color: Colors.black87,
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, color: Colors.redAccent, size: 48),
              const SizedBox(height: 12),
              Text(l10n.playbackError, style: Theme.of(context).textTheme.titleLarge?.copyWith(color: Colors.white)),
              const SizedBox(height: 4),
              Text(l10n.playbackErrorDescription, style: const TextStyle(color: Colors.white70), textAlign: TextAlign.center),
              const SizedBox(height: 4),
              Text(message, style: const TextStyle(color: Colors.white38, fontSize: 12), textAlign: TextAlign.center, maxLines: 3),
              const SizedBox(height: 16),
              Wrap(
                spacing: 12,
                children: [
                  FilledButton.icon(autofocus: true, onPressed: onRetry, icon: const Icon(Icons.refresh), label: Text(l10n.retry)),
                  OutlinedButton(onPressed: onExit, child: Text(l10n.exit)),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
