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
import '../shell/app_shell.dart' show topLeftFocusable;
import 'featured_provider.dart';
import 'hero_carousel.dart';

FocusScopeNode _scope(Ref ref, String label) {
  final node = FocusScopeNode(debugLabel: label);
  ref.onDispose(node.dispose);
  return node;
}

/// One stable FocusScope per row of the page. A scope confines Left/Right to its own row and
/// remembers the last focused card, so coming back to a row lands where the user left it.
final _heroScopeProvider = Provider<FocusScopeNode>((ref) => _scope(ref, 'home-hero'));
final _quickLinksScopeProvider = Provider<FocusScopeNode>((ref) => _scope(ref, 'home-quick-links'));
final _continueWatchingScopeProvider = Provider<FocusScopeNode>((ref) => _scope(ref, 'home-continue-watching'));
final _recentChannelsScopeProvider = Provider<FocusScopeNode>((ref) => _scope(ref, 'home-recent-channels'));
final _newMoviesScopeProvider = Provider<FocusScopeNode>((ref) => _scope(ref, 'home-new-movies'));
final _newSeriesScopeProvider = Provider<FocusScopeNode>((ref) => _scope(ref, 'home-new-series'));

/// The footer's "Changer de playlist" button: the last row of the chain.
final _footerButtonFocusProvider = Provider<FocusNode>((ref) {
  final node = FocusNode(debugLabel: 'home-footer-button');
  ref.onDispose(node.dispose);
  return node;
});

/// Where focus lands when entering [row]: the card it last held, else its top-left one, else the
/// row itself when it is a plain node (footer button). Null when the row has nothing to focus
/// (an empty conditional shelf, the hero while it loads): the chain skips it.
FocusNode? _entryOf(FocusNode row) {
  if (row is FocusScopeNode) {
    final remembered = row.focusedChild;
    if (remembered != null && remembered.canRequestFocus && row.traversalDescendants.contains(remembered)) return remembered;
    return topLeftFocusable(row);
  }
  return row.canRequestFocus && row.context != null ? row : null;
}

/// A card's own onFocusChange (in [Shelf]) scrolls it into view, but between shelves of very
/// different heights that scroll can overshoot; reissue it once the first one has settled.
void _correctScroll(FocusNode target) {
  Future.delayed(const Duration(milliseconds: 260), () {
    final ctx = target.context;
    if (ctx == null || !target.hasFocus) return;
    // ignore: use_build_context_synchronously
    Scrollable.ensureVisible(ctx, alignment: 0.5, duration: const Duration(milliseconds: 220), curve: Curves.easeOutCubic);
  });
}

/// Vertical D-pad navigation of the home page, as an explicit chain rather than Flutter's
/// geometric traversal (which, across rows of very different heights, skipped shelves or got
/// stuck): hero (Voir/Infos) or quick links → Continue watching → Recent channels → New movies →
/// New series → Changer de playlist, and back. Rows with nothing to focus are skipped. Up from the
/// first row is left unhandled so the shell's bridge takes it to the tab bar.
@visibleForTesting
class HomeFocusChain extends StatelessWidget {
  const HomeFocusChain({super.key, required this.rows, required this.child});
  final List<FocusNode> rows;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Focus(
      canRequestFocus: false,
      skipTraversal: true,
      onKeyEvent: (_, event) {
        if (event is! KeyDownEvent && event is! KeyRepeatEvent) return KeyEventResult.ignored;
        final key = event.logicalKey;
        final current = FocusManager.instance.primaryFocus;
        if (current == null) return KeyEventResult.ignored;
        final i = rows.indexWhere((r) => r == current || current.ancestors.contains(r));
        if (i < 0) return KeyEventResult.ignored;
        // The footer button is alone on its row: Left/Right must not wander into a shelf.
        if ((key == LogicalKeyboardKey.arrowLeft || key == LogicalKeyboardKey.arrowRight) && rows[i] is! FocusScopeNode) {
          return KeyEventResult.handled;
        }
        final down = key == LogicalKeyboardKey.arrowDown;
        if (!down && key != LogicalKeyboardKey.arrowUp) return KeyEventResult.ignored;
        for (var j = down ? i + 1 : i - 1; j >= 0 && j < rows.length; j += down ? 1 : -1) {
          final target = _entryOf(rows[j]);
          if (target == null) continue;
          target.requestFocus();
          _correctScroll(target);
          return KeyEventResult.handled;
        }
        // Down on the last row: stay put. Up on the first row: the tab bar (_TvFocusBridge).
        return down ? KeyEventResult.handled : KeyEventResult.ignored;
      },
      child: child,
    );
  }
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
    final heroScope = ref.watch(_heroScopeProvider);
    final quickLinksScope = ref.watch(_quickLinksScopeProvider);
    final continueWatchingScope = ref.watch(_continueWatchingScopeProvider);
    final recentChannelsScope = ref.watch(_recentChannelsScopeProvider);
    final newMoviesScope = ref.watch(_newMoviesScopeProvider);
    final newSeriesScope = ref.watch(_newSeriesScopeProvider);
    final footerFocus = ref.watch(_footerButtonFocusProvider);
    final account = decodeAccountInfo(playlist.accountInfo);
    final exp = account['exp_date'] != null && account['exp_date'] != 'null' ? DateTime.tryParse(account['exp_date']!) : playlist.expiresAt;
    final topInset = MediaQuery.paddingOf(context).top;

    return Responsive(
      builder: (context, form) {
        final heroItems = hero.value ?? const <HeroItem>[];
        return HomeFocusChain(
          rows: [heroScope, quickLinksScope, continueWatchingScope, recentChannelsScope, newMoviesScope, newSeriesScope, footerFocus],
          child: CustomScrollView(
            // The hero draws under the top bar; only pad when there is no hero to sit behind it.
            slivers: [
              SliverToBoxAdapter(
                child: hero.isLoading && heroItems.isEmpty
                    ? SizedBox(height: form.isMobile ? 300 : 420, child: const _HeroSkeleton())
                    : heroItems.isEmpty
                        ? SizedBox(height: topInset)
                        : FocusScope(node: heroScope, child: HeroCarousel(items: heroItems, playlistId: playlist.id, form: form)),
              ),
              if (heroItems.isEmpty && !hero.isLoading)
                SliverToBoxAdapter(child: FocusScope(node: quickLinksScope, child: _QuickLinks(form: form))),
              SliverToBoxAdapter(child: FocusScope(node: continueWatchingScope, child: _ContinueWatchingShelf(playlistId: playlist.id, form: form))),
              SliverToBoxAdapter(child: FocusScope(node: recentChannelsScope, child: _RecentChannelsShelf(playlistId: playlist.id, form: form))),
              SliverToBoxAdapter(child: FocusScope(node: newMoviesScope, child: _PosterShelf(playlistId: playlist.id, form: form, series: false))),
              SliverToBoxAdapter(child: FocusScope(node: newSeriesScope, child: _PosterShelf(playlistId: playlist.id, form: form, series: true))),
              SliverToBoxAdapter(
                child: _Footer(
                  playlist: playlist,
                  expires: exp,
                  account: account,
                  use24h: settings.use24hClock,
                  buttonFocus: footerFocus,
                  // Generous bottom room: TV overscan and the focus-scroll of the last shelf must never clip it.
                  padding: EdgeInsets.fromLTRB(context.tokens.pageGutter, 28, context.tokens.pageGutter, 72 + MediaQuery.paddingOf(context).bottom),
                ),
              ),
            ],
          ),
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
    required this.buttonFocus,
  });
  final Playlist playlist;
  final DateTime? expires;
  final Map<String, String?> account;
  final bool use24h;
  final EdgeInsets padding;
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
      // Up/Down are routed by HomeFocusChain.
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
