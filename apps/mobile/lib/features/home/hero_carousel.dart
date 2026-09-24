import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../app/responsive.dart';
import '../../app/router.dart';
import '../../app/theme.dart';
import '../../core/db/database.dart';
import '../../core/images/artwork_cache.dart';
import '../../core/log/app_logger.dart';
import '../../core/settings/settings.dart';
import '../../core/xtream/xtream_client.dart';
import '../../l10n/generated/app_localizations.dart';
import '../../widgets/common.dart';
import '../../widgets/format.dart';
import '../content/content_providers.dart';
import '../movies/movie_detail_screen.dart';
import '../player/play.dart';
import '../playlists/playlists_provider.dart';
import 'featured_provider.dart';

/// Series metadata (backdrop, genre, plot) fetched lazily from the Xtream panel.
final seriesInfoProvider = FutureProvider.family<XtreamSeriesInfo?, String>((ref, id) async {
  final p = ref.watch(activePlaylistProvider);
  if (p == null || p.type != PlaylistType.xtream) return null;
  final client = XtreamClient(XtreamCredentials(baseUrl: p.url, username: p.username ?? '', password: p.password ?? ''));
  try {
    return await client.seriesInfo(id);
  } catch (_) {
    return null;
  }
});

/// Full-bleed featured carousel: blurred/backdrop art, title, meta line and pill actions.
class HeroCarousel extends ConsumerStatefulWidget {
  const HeroCarousel({super.key, required this.items, required this.playlistId, required this.form});
  final List<HeroItem> items;
  final String playlistId;
  final FormFactor form;

  static const rotate = Duration(seconds: 8);

  @override
  ConsumerState<HeroCarousel> createState() => _HeroCarouselState();
}

class _HeroCarouselState extends ConsumerState<HeroCarousel> {
  int _index = 0;
  Timer? _timer;
  Timer? _clock;
  bool _paused = false;
  final _playNode = FocusNode(debugLabel: 'hero-play');
  final _infoNode = FocusNode(debugLabel: 'hero-info');

  @override
  void initState() {
    super.initState();
    _schedule();
    // Event badges flip from "date" to "now" on their own; re-evaluate once a minute.
    _clock = Timer.periodic(const Duration(minutes: 1), (_) {
      if (mounted && TickerMode.valuesOf(context).enabled && widget.items.any((h) => h.eventAt != null)) setState(() {});
    });
  }

  @override
  void didUpdateWidget(covariant HeroCarousel old) {
    super.didUpdateWidget(old);
    if (_index >= widget.items.length) _index = 0;
  }

  void _schedule() {
    _timer?.cancel();
    if (widget.items.length < 2) return;
    _timer = Timer.periodic(HeroCarousel.rotate, (_) {
      // Home stays mounted behind other tabs: do not rotate (and prefetch art) while offstage.
      if (!_paused && mounted && TickerMode.valuesOf(context).enabled) _go(_index + 1);
    });
  }

  void _go(int i) {
    if (widget.items.isEmpty) return;
    final next = i % widget.items.length;
    if (next == _index) return;
    setState(() => _index = next);
    _precache(next + 1);
  }

  void _precache(int i) {
    if (widget.items.isEmpty) return;
    final item = widget.items[i % widget.items.length];
    final url = _artFor(item, listen: false).$1;
    if (AppImage.isValid(url)) precacheImage(CachedNetworkImageProvider(url!, maxWidth: 1280, cacheManager: ArtworkCache.instance), context).ignore();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _clock?.cancel();
    _playNode.dispose();
    _infoNode.dispose();
    super.dispose();
  }

  /// Art resolution order: remote backdrop → TMDB (panel `tmdb_id`) → panel backdrop → poster.
  /// Returns (url, isBackdrop).
  (String?, bool) _artFor(HeroItem h, {bool listen = true}) {
    if (AppImage.isValid(h.backdropUrl)) return (h.backdropUrl, true);
    final movie = h.movie;
    final series = h.series;
    if (movie != null) {
      final p = movieInfoProvider(movie.streamId);
      final info = (listen ? ref.watch(p) : ref.read(p)).value;
      final tmdbId = h.tmdbId ?? int.tryParse(info?.tmdbId ?? '');
      if (tmdbId != null) {
        final tp = tmdbArtProvider(('movie', tmdbId));
        final tmdb = (listen ? ref.watch(tp) : ref.read(tp)).value;
        if (AppImage.isValid(tmdb?.backdropUrl)) return (tmdb!.backdropUrl, true);
      }
      return info?.backdrop != null ? (info!.backdrop, true) : (h.posterUrl ?? movie.poster, false);
    }
    if (series != null) {
      final p = seriesInfoProvider(series.seriesId);
      final info = (listen ? ref.watch(p) : ref.read(p)).value;
      if (h.tmdbId != null) {
        final tp = tmdbArtProvider(('tv', h.tmdbId!));
        final tmdb = (listen ? ref.watch(tp) : ref.read(tp)).value;
        if (AppImage.isValid(tmdb?.backdropUrl)) return (tmdb!.backdropUrl, true);
      }
      return info?.backdrop != null ? (info!.backdrop, true) : (h.posterUrl ?? series.cover, false);
    }
    return (h.posterUrl, false);
  }

  @override
  Widget build(BuildContext context) {
    if (widget.items.isEmpty) return const SizedBox.shrink();
    final l10n = AppLocalizations.of(context);
    final text = Theme.of(context).textTheme;
    final t = context.tokens;
    final size = MediaQuery.sizeOf(context);
    final height = widget.form.isMobile ? (size.height * 0.42).clamp(260.0, 420.0) : (size.height * 0.7).clamp(400.0, 760.0);
    final h = widget.items[_index];
    final movie = h.movie;
    final series = h.series;
    final (art, isBackdrop) = _artFor(h);
    final gutter = t.pageGutter;
    final lite = ref.watch(performanceModeProvider);

    final meta = <String>[];
    String? plot = h.overview;
    String? resolution;
    if (movie != null) {
      final info = ref.watch(movieInfoProvider(movie.streamId)).value;
      final year = h.year?.toString() ?? info?.releaseDate?.split('-').first ?? movie.year?.toString();
      if (year != null && year.isNotEmpty) meta.add(year);
      if (info?.genre != null) meta.add(info!.genre!.split(',').first.trim());
      if (info?.durationSecs != null) meta.add(formatDuration(Duration(seconds: info!.durationSecs!)));
      final rating = info?.rating ?? movie.rating;
      if (rating != null && rating > 0) meta.add('★ ${rating.toStringAsFixed(1)}');
      plot ??= info?.plot;
      resolution = info?.resolution;
    } else if (series != null) {
      final info = ref.watch(seriesInfoProvider(series.seriesId)).value;
      final year = h.year ?? series.year;
      if (year != null) meta.add('$year');
      if (info?.genre != null) meta.add(info!.genre!.split(',').first.trim());
      if (series.rating != null && series.rating! > 0) meta.add('★ ${series.rating!.toStringAsFixed(1)}');
      plot ??= series.plot ?? info?.plot;
    } else {
      if (h.year != null) meta.add('${h.year}');
      if (h.subtitle != null && h.subtitle!.isNotEmpty) meta.add(h.subtitle!);
    }
    final badge = h.badge ?? (series != null ? l10n.series : null);
    final now = DateTime.now();
    final eventLive = h.isLiveAt(now);
    final use24h = ref.watch(settingsProvider.select((s) => s.use24hClock));
    final progress = h.history != null && h.history!.durationMs > 0 ? h.history!.positionMs / h.history!.durationMs : null;
    final canPlay = h.target != HeroTarget.none;
    final canOpen = movie != null || series != null;
    final playLabel = h.isResume
        ? l10n.resumeFrom(formatDuration(Duration(milliseconds: h.history!.positionMs)))
        : switch (h.target) {
            HeroTarget.channel => l10n.watchNow,
            HeroTarget.url => l10n.openLink,
            _ => l10n.play,
          };
    final kicker = h.isResume
        ? l10n.continueWatching
        : h.subtitle != null && !canOpen && h.channel == null
            ? h.subtitle!
            : l10n.featured;

    return Focus(
      canRequestFocus: false,
      skipTraversal: true,
      onFocusChange: (f) => _paused = f,
      onKeyEvent: (_, e) {
        if (e is! KeyDownEvent) return KeyEventResult.ignored;
        // Up/Down are routed by the home page's focus chain (HomeFocusChain, home_screen.dart).
        // Right from Play moves to Infos, left from Infos moves back to Play; right on the last
        // button / left on the first one flips the featured item. All four transitions are handled
        // explicitly: Flutter's default directional traversal is not reliable enough at this
        // boundary (it can escape the hero entirely and land on the header tab bar instead).
        if (e.logicalKey != LogicalKeyboardKey.arrowRight && e.logicalKey != LogicalKeyboardKey.arrowLeft) {
          return KeyEventResult.ignored;
        }
        final first = canPlay ? _playNode : _infoNode;
        final last = canOpen ? _infoNode : _playNode;
        if (e.logicalKey == LogicalKeyboardKey.arrowRight) {
          if (first != last && first.hasFocus) {
            last.requestFocus();
            return KeyEventResult.handled;
          }
          if (last.hasFocus && widget.items.length > 1) {
            _go(_index + 1);
            return KeyEventResult.handled;
          }
        } else {
          if (first != last && last.hasFocus) {
            first.requestFocus();
            return KeyEventResult.handled;
          }
          if (first.hasFocus && widget.items.length > 1) {
            _go(_index - 1);
            return KeyEventResult.handled;
          }
        }
        return KeyEventResult.ignored;
      },
      child: GestureDetector(
        onHorizontalDragEnd: (d) {
          if (d.primaryVelocity == null || d.primaryVelocity == 0) return;
          _go(d.primaryVelocity! < 0 ? _index + 1 : _index - 1);
        },
        child: SizedBox(
          height: height,
          child: Stack(
            fit: StackFit.expand,
            children: [
              // Art: cross-fades between items; a poster fallback is enlarged and softly blurred.
              // The cross-fade composites two full-screen images: on weak GPUs swap quickly instead.
              AnimatedSwitcher(
                duration: Duration(milliseconds: lite ? 120 : 450),
                switchInCurve: Curves.easeOut,
                switchOutCurve: Curves.easeIn,
                // Default layout is a loose Stack, which would let the image shrink to its decoded size.
                layoutBuilder: (current, previous) => Stack(fit: StackFit.expand, children: [if (!lite) ...previous, ?current]),
                child: KeyedSubtree(
                  key: ValueKey(art ?? h.id),
                  child: BackdropArt(backdrop: isBackdrop ? art : null, poster: isBackdrop ? h.posterUrl : art),
                ),
              ),
              const DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                    stops: [0, 0.55, 1],
                    colors: [Color(0xE60A0A0A), Color(0x660A0A0A), Color(0x000A0A0A)],
                  ),
                ),
              ),
              const DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    stops: [0, 0.35, 0.75, 1],
                    colors: [Color(0x800A0A0A), Color(0x000A0A0A), Color(0x800A0A0A), Color(0xFF0A0A0A)],
                  ),
                ),
              ),
              Positioned(
                left: gutter,
                right: gutter,
                bottom: widget.form.isMobile ? 20 : 40,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Text(kicker.toUpperCase(), style: text.labelMedium?.copyWith(color: t.textMuted, letterSpacing: 1.2)),
                    ),
                    ConstrainedBox(
                      constraints: BoxConstraints(maxWidth: widget.form.isMobile ? size.width : size.width * 0.55),
                      child: Text(
                        h.title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: widget.form.isMobile ? text.headlineMedium : text.displayMedium,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        if (eventLive) ...[LiveBadge(l10n.eventNow), const SizedBox(width: 10)],
                        if (h.eventAt != null && !eventLive) ...[
                          Icon(Icons.event_rounded, size: 16, color: t.textMuted),
                          const SizedBox(width: 6),
                          Text(_eventLabel(context, h.eventAt!, use24h: use24h), style: text.bodyMedium?.copyWith(color: Colors.white, fontWeight: FontWeight.w600)),
                          const SizedBox(width: 10),
                        ],
                        if (meta.isNotEmpty)
                          Text(meta.join('  ·  '), style: text.bodyMedium?.copyWith(color: t.textMuted)),
                        if (resolution != null) ...[const SizedBox(width: 10), MetaBadge(resolution)],
                        // Scheduled events carry their own state (date, then pulsing "now"); the static LIVE tag would be noise.
                        if (badge != null && !(badge == 'LIVE' && h.eventAt != null)) ...[const SizedBox(width: 10), MetaBadge(badge, filled: badge == 'LIVE')],
                      ],
                    ),
                    if (plot != null && plot.isNotEmpty && !widget.form.isMobile)
                      Padding(
                        padding: const EdgeInsets.only(top: 10),
                        child: ConstrainedBox(
                          constraints: BoxConstraints(maxWidth: size.width * 0.45),
                          child: Text(plot, maxLines: 2, overflow: TextOverflow.ellipsis, style: text.bodyMedium?.copyWith(color: t.textMuted)),
                        ),
                      ),
                    if (progress != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 12),
                        child: SizedBox(width: 260, child: ClipRRect(borderRadius: BorderRadius.circular(2), child: ProgressStrip(progress, height: 4))),
                      ),
                    const SizedBox(height: 18),
                    Row(
                      children: [
                        if (canPlay)
                          PillButton(
                            primary: true,
                            autofocus: true,
                            focusNode: _playNode,
                            icon: h.target == HeroTarget.url ? Icons.open_in_new_rounded : Icons.play_arrow_rounded,
                            label: playLabel,
                            onPressed: () => _play(context, h),
                          ),
                        if (canPlay && canOpen) const SizedBox(width: 10),
                        if (canOpen)
                          PillButton(
                            focusNode: _infoNode,
                            autofocus: !canPlay,
                            icon: Icons.info_outline_rounded,
                            label: l10n.moreInfo,
                            onPressed: () => _open(context, h),
                          ),
                        if (widget.items.length > 1) ...[
                          const SizedBox(width: 20),
                          _Dots(count: widget.items.length, index: _index),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// "Today 20:45" / "Tomorrow 20:45" / "Sun 28 Sep · 20:45".
  String _eventLabel(BuildContext context, DateTime at, {required bool use24h}) {
    final l10n = AppLocalizations.of(context);
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final day = DateTime(at.year, at.month, at.day);
    final time = formatTime(context, at, use24h: use24h);
    if (day == today) return l10n.todayAt(time);
    if (day == today.add(const Duration(days: 1))) return l10n.tomorrowAt(time);
    final locale = Localizations.localeOf(context).toString();
    return '${DateFormat.MMMEd(locale).format(at)} · $time';
  }

  void _open(BuildContext context, HeroItem h) {
    if (h.movie != null) {
      context.push(Routes.movie(h.movie!.streamId));
    } else if (h.series != null) {
      context.push(Routes.seriesDetail(h.series!.seriesId));
    }
  }

  // The OK press otherwise looks entirely ignored on a failure: the episode fetch below can throw
  // (flaky panel/network) or return empty, and nothing awaits this callback to report it.
  Future<void> _play(BuildContext context, HeroItem h) async {
    try {
      switch (h.target) {
        case HeroTarget.movie:
          return await playMovie(context, ref, h.movie!);
        case HeroTarget.channel:
          return await playChannels(context, ref, [h.channel!], 0);
        case HeroTarget.url:
          await launchUrl(Uri.parse(h.url!), mode: LaunchMode.externalApplication);
          return;
        case HeroTarget.series:
          final s = h.series!;
          final eps = await ref.read(episodesProvider(s.seriesId).future);
          if (!context.mounted) return;
          if (eps.isEmpty) throw StateError('no episodes');
          var index = 0;
          if (h.history != null) {
            final i = eps.indexWhere((e) => e.episodeId == h.history!.itemId);
            if (i >= 0) index = i;
          }
          return await playEpisodes(context, ref, eps, index, seriesName: s.name);
        case HeroTarget.none:
          return;
      }
    } catch (e) {
      ref.read(appLoggerProvider).error('playback', 'hero play failed (${h.target.name}): $e');
      if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(AppLocalizations.of(context).playbackError)));
    }
  }
}

class _Dots extends StatelessWidget {
  const _Dots({required this.count, required this.index});
  final int count;
  final int index;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var i = 0; i < count; i++)
          AnimatedContainer(
            duration: const Duration(milliseconds: 250),
            margin: const EdgeInsets.symmetric(horizontal: 3),
            width: i == index ? 18 : 6,
            height: 6,
            decoration: BoxDecoration(
              color: i == index ? Colors.white : const Color(0x66FFFFFF),
              borderRadius: BorderRadius.circular(3),
            ),
          ),
      ],
    );
  }
}
