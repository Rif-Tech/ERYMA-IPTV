import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/theme.dart';
import '../../l10n/generated/app_localizations.dart';
import '../../widgets/common.dart';
import '../../widgets/format.dart';
import '../content/content_providers.dart';
import '../playlists/playlists_provider.dart';
import 'playback_measure.dart';

// Presentational pieces of the player overlay. State, timers and key handling stay in
// player_screen.dart; these widgets only render what they are given.

/// Live numbers of a measurement ([PlaybackMeasure]), top-right, shown whether the controls are
/// or not. Technical values stay as mpv reports them (bt.709, mediacodec…).
class PlayerMeasurePanel extends StatelessWidget {
  const PlayerMeasurePanel({super.key, required this.snapshot});
  final ValueListenable<MeasureSnapshot?> snapshot;

  static String _n(double? v, [int digits = 2]) => v == null ? '?' : v.toStringAsFixed(digits);

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final text = Theme.of(context).textTheme;
    return ValueListenableBuilder<MeasureSnapshot?>(
      valueListenable: snapshot,
      builder: (context, s, _) {
        if (s == null) return const SizedBox.shrink();
        final size = s.height == null ? '?' : '${s.width}×${s.height}${s.interlaced == true ? 'i' : 'p'}';
        final rows = [
          (l10n.measureVideo, '${s.codec ?? '?'} $size'),
          (l10n.measureColors, '${s.primaries ?? '?'} · ${s.colorMatrix ?? '?'} · ${s.gamma ?? '?'}'),
          (l10n.measureOutput, '${s.output} · ${s.vo ?? '?'} · ${s.hwdec ?? '?'}'),
          (l10n.measureDisplay, '${_n(s.displayHz)} Hz · ${s.cadence ?? '?'}'),
          // Native output: the box shows the frames, Flutter cannot count them.
          (l10n.measureFrames, '${_n(s.contentFps)} · ${_n(s.decodedFps, 1)} · ${s.shownFps ?? '—'}'),
          (l10n.measureDrops, '${s.dropsVo} · ${s.dropsDecoder} · ${s.delayed}'),
          (l10n.measureSync, '${_n(s.avsyncMs, 0)} ms'),
          (l10n.measureBuffer, '${_n(s.cacheSeconds, 1)} s · ${s.videoKbps == null ? '?' : (s.videoKbps! / 1000).toStringAsFixed(1)} Mb/s'),
        ];
        return Align(
          alignment: Alignment.topRight,
          child: Container(
            margin: EdgeInsets.fromLTRB(16, MediaQuery.paddingOf(context).top + 72, 24, 16),
            padding: const EdgeInsets.all(12),
            constraints: const BoxConstraints(maxWidth: 420),
            decoration: BoxDecoration(color: const Color(0xCC000000), borderRadius: BorderRadius.circular(12)),
            child: DefaultTextStyle(
              style: text.labelSmall!.copyWith(color: Colors.white, height: 1.4),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(l10n.measureRunning(s.seconds), style: text.labelMedium?.copyWith(color: Colors.white, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 6),
                  for (final (label, value) in rows)
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(width: 190, child: Text(label, style: const TextStyle(color: Color(0xB3FFFFFF)))),
                        Expanded(child: Text(value)),
                      ],
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

/// Subtitles for the native video output, where media_kit's own view (part of its texture
/// widget) is not used: the lines mpv decodes ([Player.stream.subtitle]) in the user's style.
class PlayerSubtitles extends StatelessWidget {
  const PlayerSubtitles({super.key, required this.lines, required this.style, required this.padding});
  final Stream<List<String>> lines;
  final TextStyle style;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: StreamBuilder<List<String>>(
        stream: lines,
        builder: (context, snapshot) {
          final text = (snapshot.data ?? const []).where((l) => l.trim().isNotEmpty).join('\n');
          if (text.isEmpty) return const SizedBox.shrink();
          return Padding(
            padding: padding,
            child: Align(
              alignment: Alignment.bottomCenter,
              child: Text(text, textAlign: TextAlign.center, style: style),
            ),
          );
        },
      ),
    );
  }
}

/// Translucent rounded group holding the transport buttons.
class PlayerControlPill extends StatelessWidget {
  const PlayerControlPill({super.key, required this.children});
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
class PlayerProgressBar extends StatefulWidget {
  const PlayerProgressBar({
    super.key,
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
  State<PlayerProgressBar> createState() => _PlayerProgressBarState();
}

class _PlayerProgressBarState extends State<PlayerProgressBar> {
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
/// own (that stays in [PlayerScreen]'s key handler), just a live cursor so a long-press fast seek is
/// visible without popping the full transport controls.
class PlayerScrubBar extends StatelessWidget {
  const PlayerScrubBar({super.key, required this.position, required this.duration});
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
class PlayerSeekIndicator extends StatelessWidget {
  const PlayerSeekIndicator({super.key, required this.pending, required this.position});
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

class PlayerEpgLine extends ConsumerWidget {
  const PlayerEpgLine({super.key, required this.epgChannelId, required this.use24h});
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

class PlayerTrackButton<T> extends StatelessWidget {
  const PlayerTrackButton({
    super.key,
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

class PlayerErrorBanner extends StatelessWidget {
  const PlayerErrorBanner({super.key, required this.message, required this.onRetry, required this.onExit});
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
