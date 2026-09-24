import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/responsive.dart';
import '../../app/router.dart';
import '../../app/theme.dart';
import '../../core/db/database.dart';
import '../../core/playlist/playlist_importer.dart';
import '../../core/settings/settings.dart';
import '../../l10n/generated/app_localizations.dart';
import '../../widgets/common.dart';
import '../../widgets/format.dart';
import '../content/content_providers.dart';
import '../player/play.dart';
import '../playlists/playlists_provider.dart';
import '../shell/app_shell.dart' show bodyScopeProvider, topLeftFocusable;
import 'featured_provider.dart';
import 'hero_carousel.dart';

/// One stable FocusScope per shelf, in page order, so Up/Down can jump straight to the next
/// *visible* one instead of trusting Flutter's geometric traversal across rows of very different
/// heights (poster shelves vs. the short channel-logo row) — see [_shelfBoundary]. Continue
/// watching and Recent channels are conditional (empty when nothing has been watched yet); an
/// empty shelf's scope simply has no traversal descendants and is skipped by [visibleShelfScopes].
final _continueWatchingScopeProvider = Provider<FocusScopeNode>((ref) {
  final node = FocusScopeNode(debugLabel: 'home-continue-watching');
  ref.onDispose(node.dispose);
  return node;
});
final _recentChannelsScopeProvider = Provider<FocusScopeNode>((ref) {
  final node = FocusScopeNode(debugLabel: 'home-recent-channels');
  ref.onDispose(node.dispose);
  return node;
});
final _newMoviesScopeProvider = Provider<FocusScopeNode>((ref) {
  final node = FocusScopeNode(debugLabel: 'home-new-movies');
  ref.onDispose(node.dispose);
  return node;
});
final _newSeriesScopeProvider = Provider<FocusScopeNode>((ref) {
  final node = FocusScopeNode(debugLabel: 'home-new-series');
  ref.onDispose(node.dispose);
  return node;
});

/// Focus node for the footer's "Changer de playlist" button, so Down from the last visible shelf
/// can target it directly (see the reciprocal Up handling in [_Footer]).
final _footerButtonFocusProvider = Provider<FocusNode>((ref) {
  final node = FocusNode(debugLabel: 'home-footer-button');
  ref.onDispose(node.dispose);
  return node;
});

/// All shelf scopes in page order (some possibly empty right now — see [visibleShelfScopes]).
List<FocusScopeNode> _shelfScopes(WidgetRef ref) => [
  ref.read(_continueWatchingScopeProvider),
  ref.read(_recentChannelsScopeProvider),
  ref.read(_newMoviesScopeProvider),
  ref.read(_newSeriesScopeProvider),
];

/// [_shelfScopes] filtered to the ones currently holding a focusable card. Used by [HeroCarousel]
/// (Down from Lire/Infos must land on the first *visible* shelf, which may not be Continue
/// watching) and by [_Footer] (Up must land on the last visible one).
List<FocusScopeNode> visibleShelfScopes(WidgetRef ref) => _shelfScopes(ref).where((s) => s.traversalDescendants.isNotEmpty).toList();

/// The node a shelf should receive focus on: whichever card it last held, or its top-left one.
FocusNode? shelfEntryFocus(FocusScopeNode scope) {
  final remembered = scope.focusedChild;
  return (remembered != null && remembered.canRequestFocus) ? remembered : topLeftFocusable(scope);
}

/// Nearest focusable strictly below/above [origin] within [body], excluding [exclude] (the shelf
/// [origin] itself belongs to). Used only to escape *above* the first visible shelf, to whatever
/// Flutter's geometric traversal finds there (the hero's Lire/Infos, or the quick-links tiles when
/// there is no hero) — every other jump in the shelf chain has an explicit next/previous scope and
/// does not need this. A same-row sibling is excluded by scope membership rather than by comparing
/// `rect.top` because the focus-zoom effect on cards shifts the focused one's top edge by a few
/// pixels, which was enough for a sibling to spuriously look "below".
FocusNode? _nearestVertical(FocusScopeNode body, FocusNode origin, FocusScopeNode exclude, {required bool below}) {
  final o = origin.rect;
  final excluded = exclude.traversalDescendants.toSet();
  FocusNode? best;
  for (final n in body.traversalDescendants) {
    if (n == origin || excluded.contains(n)) continue;
    final isCandidate = below ? n.rect.top > o.top + 1 : n.rect.top < o.top - 1;
    if (!isCandidate) continue;
    final closerRow = best == null || (below ? n.rect.top < best.rect.top - 1 : n.rect.top > best.rect.top + 1);
    final sameRowCloserX = best != null && (n.rect.top - best.rect.top).abs() < 1 && (n.rect.left - o.left).abs() < (best.rect.left - o.left).abs();
    if (closerRow || sameRowCloserX) best = n;
  }
  return best;
}

/// The card's own onFocusChange (in [Shelf]) already scrolls it into view, but for a jump between
/// shelves of very different card heights that scroll can overshoot and leave the newly focused
/// card off-screen — reissue it once the first scroll has settled, using fresh (not stale) geometry.
void _correctScroll(FocusNode target) {
  Future.delayed(const Duration(milliseconds: 260), () {
    final ctx = target.context;
    if (ctx == null || !target.hasFocus) return;
    // ignore: use_build_context_synchronously
    Scrollable.ensureVisible(ctx, alignment: 0.5, duration: const Duration(milliseconds: 220), curve: Curves.easeOutCubic);
  });
}

/// Wraps a shelf so Up/Down jump straight to the previous/next *visible* shelf (see
/// [visibleShelfScopes]) instead of trusting Flutter's geometric traversal, which — confined to a
/// single-row scope — can spuriously "succeed" by bouncing to a same-row sibling, and even when it
/// does cross into the next shelf can overshoot past it into a farther one. Down from the last
/// visible shelf goes to the footer button; Up from the first visible one escapes to whatever is
/// above the shelf chain (the hero, or quick-links when there is no hero).
Widget _shelfBoundary({
  required WidgetRef ref,
  required FocusScopeNode scope,
  required FocusScopeNode bodyScope,
  required FocusNode footerFocus,
  required Widget child,
}) {
  return Focus(
    canRequestFocus: false,
    skipTraversal: true,
    onKeyEvent: (_, event) {
      if (event is! KeyDownEvent && event is! KeyRepeatEvent) return KeyEventResult.ignored;
      final down = event.logicalKey == LogicalKeyboardKey.arrowDown;
      final up = event.logicalKey == LogicalKeyboardKey.arrowUp;
      if (!down && !up) return KeyEventResult.ignored;
      final current = FocusManager.instance.primaryFocus;
      if (current == null || !scope.traversalDescendants.contains(current)) return KeyEventResult.ignored;
      final visible = visibleShelfScopes(ref);
      final i = visible.indexOf(scope);
      if (i < 0) return KeyEventResult.ignored;
      final FocusNode? target;
      if (down) {
        target = i + 1 < visible.length ? shelfEntryFocus(visible[i + 1]) : footerFocus;
      } else if (i > 0) {
        target = shelfEntryFocus(visible[i - 1]);
      } else {
        target = _nearestVertical(bodyScope, current, scope, below: false);
      }
      if (target == null) return KeyEventResult.ignored;
      target.requestFocus();
      _correctScroll(target);
      return KeyEventResult.handled;
    },
    child: child,
  );
}

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final playlist = ref.watch(activePlaylistProvider);
    final settings = ref.watch(settingsProvider);

    if (playlist == null) {
      // The DB stream has not emitted yet: a blank frame beats a flash of "no playlist".
      if (ref.watch(playlistsProvider).isLoading) return const SizedBox.shrink();
      return EmptyState(
        icon: Icons.playlist_remove,
        message: l10n.noPlaylistTitle,
        action: FilledButton(onPressed: () => context.go(Routes.noPlaylist), child: Text(l10n.addPlaylist)),
      );
    }

    final hero = ref.watch(featuredHeroProvider((playlist.id, l10n.series)));
    final continueWatchingScope = ref.watch(_continueWatchingScopeProvider);
    final recentChannelsScope = ref.watch(_recentChannelsScopeProvider);
    final newMoviesScope = ref.watch(_newMoviesScopeProvider);
    final newSeriesScope = ref.watch(_newSeriesScopeProvider);
    final bodyScope = ref.watch(bodyScopeProvider);
    final footerFocus = ref.watch(_footerButtonFocusProvider);
    final account = decodeAccountInfo(playlist.accountInfo);
    final exp = account['exp_date'] != null && account['exp_date'] != 'null' ? DateTime.tryParse(account['exp_date']!) : playlist.expiresAt;
    final topInset = MediaQuery.paddingOf(context).top;

    Widget boundary(FocusScopeNode scope, Widget child) =>
        _shelfBoundary(ref: ref, scope: scope, bodyScope: bodyScope, footerFocus: footerFocus, child: FocusScope(node: scope, child: child));

    return Responsive(
      builder: (context, form) {
        final heroItems = hero.value ?? const <HeroItem>[];
        return CustomScrollView(
          // The hero draws under the top bar; only pad when there is no hero to sit behind it.
          slivers: [
            SliverToBoxAdapter(
              child: hero.isLoading && heroItems.isEmpty
                  ? SizedBox(height: form.isMobile ? 300 : 420, child: const _HeroSkeleton())
                  : heroItems.isEmpty
                      ? SizedBox(height: topInset)
                      : HeroCarousel(items: heroItems, playlistId: playlist.id, form: form),
            ),
            if (heroItems.isEmpty && !hero.isLoading)
              SliverToBoxAdapter(child: _QuickLinks(form: form)),
            SliverToBoxAdapter(child: boundary(continueWatchingScope, _ContinueWatchingShelf(playlistId: playlist.id, form: form))),
            SliverToBoxAdapter(child: boundary(recentChannelsScope, _RecentChannelsShelf(playlistId: playlist.id, form: form))),
            SliverToBoxAdapter(child: boundary(newMoviesScope, _PosterShelf(playlistId: playlist.id, form: form, series: false))),
            SliverToBoxAdapter(child: boundary(newSeriesScope, _PosterShelf(playlistId: playlist.id, form: form, series: true))),
            SliverToBoxAdapter(
              child: _Footer(
                playlist: playlist,
                expires: exp,
                account: account,
                use24h: settings.use24hClock,
                shelfScopes: _shelfScopes(ref),
                buttonFocus: footerFocus,
                // Generous bottom room: TV overscan and the focus-scroll of the last shelf must never clip it.
                padding: EdgeInsets.fromLTRB(context.tokens.pageGutter, 28, context.tokens.pageGutter, 72 + MediaQuery.paddingOf(context).bottom),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _HeroSkeleton extends StatelessWidget {
  const _HeroSkeleton();
  @override
  Widget build(BuildContext context) {
    final g = context.tokens.pageGutter;
    return Stack(
      children: [
        const Positioned.fill(child: Skeleton(radius: 0)),
        Positioned(
          left: g,
          bottom: 40,
          child: const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Skeleton(width: 360, height: 40),
              SizedBox(height: 12),
              Skeleton(width: 220, height: 16),
              SizedBox(height: 20),
              Skeleton(width: 140, height: 44, radius: 22),
            ],
          ),
        ),
      ],
    );
  }
}

/// Shown instead of the hero on freshly imported playlists with no VOD.
class _QuickLinks extends ConsumerWidget {
  const _QuickLinks({required this.form});
  final FormFactor form;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final tiles = [
      (Icons.live_tv_rounded, l10n.liveTv, Routes.live),
      (Icons.movie_rounded, l10n.movies, Routes.movies),
      (Icons.video_library_rounded, l10n.series, Routes.series),
    ];
    return Padding(
      padding: EdgeInsets.fromLTRB(context.tokens.pageGutter, 24, context.tokens.pageGutter, 0),
      child: Row(
        children: [
          for (final (i, t) in tiles.indexed) ...[
            Expanded(
              child: SizedBox(
                height: form.isMobile ? 72 : 110,
                child: FocusableCard(
                  autofocus: i == 0,
                  onTap: () => context.go(t.$3),
                  child: GlassPanel(
                    radius: 12,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(t.$1, size: form.isMobile ? 24 : 32),
                        const SizedBox(width: 12),
                        Text(t.$2, style: Theme.of(context).textTheme.titleMedium),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            if (i < tiles.length - 1) const SizedBox(width: 16),
          ],
        ],
      ),
    );
  }
}

class _Footer extends StatelessWidget {
  const _Footer({
    required this.playlist,
    required this.expires,
    required this.account,
    required this.use24h,
    required this.padding,
    required this.lastShelfScope,
    required this.buttonFocus,
  });
  final Playlist playlist;
  final DateTime? expires;
  final Map<String, String?> account;
  final bool use24h;
  final EdgeInsets padding;
  final FocusScopeNode lastShelfScope;
  final FocusNode buttonFocus;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final text = Theme.of(context).textTheme;
    final t = context.tokens;
    return Focus(
      canRequestFocus: false,
      skipTraversal: true,
      // When the button below gains focus, bring the whole padded footer (not just the button) into
      // view so the last lines are never hidden behind the TV's overscan.
      onFocusChange: (f) {
        if (f) Scrollable.ensureVisible(context, alignment: 1, duration: const Duration(milliseconds: 220), curve: Curves.easeOutCubic);
      },
      // The "Changer de playlist" pill sits at the row's right edge; Flutter's directional
      // traversal is geometric (nearest overlap in the pressed direction), so when nothing in the
      // shelf above happens to overlap that x-band it falls back to a horizontal-proximity
      // heuristic that can land on the hero's Info button instead of the row directly above.
      // Redirect Up explicitly to that row rather than leaving the choice to the heuristic.
      onKeyEvent: (_, event) {
        if (event is! KeyDownEvent && event is! KeyRepeatEvent) return KeyEventResult.ignored;
        if (event.logicalKey != LogicalKeyboardKey.arrowUp) return KeyEventResult.ignored;
        final remembered = lastShelfScope.focusedChild;
        final child = (remembered != null && remembered.canRequestFocus) ? remembered : topLeftFocusable(lastShelfScope);
        if (child == null) return KeyEventResult.ignored;
        child.requestFocus();
        return KeyEventResult.handled;
      },
      child: Padding(
        padding: padding,
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(playlist.name, style: text.titleSmall),
                  if (expires != null) Text(l10n.accountExpires(formatDate(context, expires!)), style: text.bodySmall?.copyWith(color: t.textFaint)),
                  if (account['max_connections'] != null)
                    Text(l10n.activeConnections(account['active_cons'] ?? '?', account['max_connections']!), style: text.bodySmall?.copyWith(color: t.textFaint)),
                ],
              ),
            ),
            _Clock(use24h: use24h),
            const SizedBox(width: 8),
            PillButton(
              compact: true,
              focusNode: buttonFocus,
              icon: Icons.playlist_play_rounded,
              label: l10n.changePlaylist,
              onPressed: () => context.push(Routes.playlists),
            ),
          ],
        ),
      ),
    );
  }
}

class _Clock extends StatefulWidget {
  const _Clock({required this.use24h});
  final bool use24h;
  @override
  State<_Clock> createState() => _ClockState();
}

class _ClockState extends State<_Clock> {
  late Timer _timer;
  DateTime _now = DateTime.now();

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 15), (_) => setState(() => _now = DateTime.now()));
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Text(formatTime(context, _now, use24h: widget.use24h), style: Theme.of(context).textTheme.titleSmall?.copyWith(color: context.tokens.textMuted));
  }
}

double _posterWidth(FormFactor form) => form.isMobile ? 120 : form.isTablet ? 150 : 170;

class _ContinueWatchingShelf extends ConsumerWidget {
  const _ContinueWatchingShelf({required this.playlistId, required this.form});
  final String playlistId;
  final FormFactor form;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final items = ref.watch(continueWatchingProvider(playlistId)).value ?? const [];
    if (items.isEmpty) return const SizedBox.shrink();
    final w = _posterWidth(form);
    return Shelf(
      title: l10n.continueWatching,
      itemCount: items.length,
      itemWidth: w,
      height: w * 3 / 2 + 40,
      itemBuilder: (context, i) {
        final (h, item) = items[i];
        final progress = h.durationMs > 0 ? h.positionMs / h.durationMs : null;
        final resumeAt = formatDuration(Duration(milliseconds: h.positionMs));
        if (item is Movie) {
          return PosterCard(
            title: item.name,
            imageUrl: item.poster,
            subtitle: resumeAt,
            progress: progress,
            onTap: () => playMovie(context, ref, item),
            onLongPress: () => context.push(Routes.movie(item.streamId)),
          );
        }
        final s = item as SeriesItem;
        return PosterCard(
          title: s.name,
          imageUrl: s.cover,
          subtitle: '${l10n.series} · $resumeAt',
          progress: progress,
          onTap: () => context.push(Routes.seriesDetail(s.seriesId)),
        );
      },
    );
  }
}

class _RecentChannelsShelf extends ConsumerWidget {
  const _RecentChannelsShelf({required this.playlistId, required this.form});
  final String playlistId;
  final FormFactor form;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final channels = ref.watch(channelsProvider(ContentQuery(playlistId, ContentKind.live, SpecialCategory.recent))).value?.items ?? const [];
    if (channels.isEmpty) return const SizedBox.shrink();
    final w = form.isMobile ? 150.0 : 190.0;
    return Shelf(
      title: l10n.recentChannels,
      itemCount: channels.length,
      itemWidth: w,
      height: w * 9 / 16,
      itemBuilder: (context, i) {
        final c = channels[i];
        return FocusableCard(
          onTap: () => playChannels(context, ref, channels, i),
          child: GlassPanel(
            radius: 12,
            padding: const EdgeInsets.all(12),
            child: Column(
              children: [
                Expanded(child: AppImage(c.logo, fit: BoxFit.contain, icon: Icons.live_tv, decodeWidth: 240)),
                const SizedBox(height: 6),
                Text(c.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: Theme.of(context).textTheme.labelSmall),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _PosterShelf extends ConsumerWidget {
  const _PosterShelf({required this.playlistId, required this.form, required this.series});
  final String playlistId;
  final FormFactor form;
  final bool series;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final w = _posterWidth(form);
    if (series) {
      final items = ref.watch(recentSeriesProvider(playlistId)).value ?? const <SeriesItem>[];
      if (items.isEmpty) return const SizedBox.shrink();
      return Shelf(
        title: l10n.recentlyAddedSeries,
        action: l10n.seeAll,
        onAction: () => context.go(Routes.series),
        itemCount: items.length,
        itemWidth: w,
        height: w * 3 / 2 + 40,
        itemBuilder: (context, i) {
          final s = items[i];
          return PosterCard(
            title: s.name,
            imageUrl: s.cover,
            subtitle: s.year?.toString(),
            onTap: () => context.push(Routes.seriesDetail(s.seriesId)),
          );
        },
      );
    }
    final items = ref.watch(recentMoviesProvider(playlistId)).value ?? const <Movie>[];
    if (items.isEmpty) return const SizedBox.shrink();
    return Shelf(
      title: l10n.recentlyAddedMovies,
      action: l10n.seeAll,
      onAction: () => context.go(Routes.movies),
      itemCount: items.length,
      itemWidth: w,
      height: w * 3 / 2 + 40,
      itemBuilder: (context, i) {
        final m = items[i];
        return PosterCard(
          title: m.name,
          imageUrl: m.poster,
          subtitle: m.year?.toString(),
          onTap: () => context.push(Routes.movie(m.streamId)),
          onLongPress: () => playMovie(context, ref, m),
        );
      },
    );
  }
}
