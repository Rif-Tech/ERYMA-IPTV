import 'dart:async';

import 'package:flutter/material.dart';
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
import 'featured_provider.dart';
import 'hero_carousel.dart';

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
    final account = decodeAccountInfo(playlist.accountInfo);
    final exp = account['exp_date'] != null && account['exp_date'] != 'null' ? DateTime.tryParse(account['exp_date']!) : playlist.expiresAt;
    final topInset = MediaQuery.paddingOf(context).top;

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
            SliverToBoxAdapter(child: _ContinueWatchingShelf(playlistId: playlist.id, form: form)),
            SliverToBoxAdapter(child: _RecentChannelsShelf(playlistId: playlist.id, form: form)),
            SliverToBoxAdapter(child: _PosterShelf(playlistId: playlist.id, form: form, series: false)),
            SliverToBoxAdapter(child: _PosterShelf(playlistId: playlist.id, form: form, series: true)),
            SliverToBoxAdapter(
              child: _Footer(
                playlist: playlist,
                expires: exp,
                account: account,
                use24h: settings.use24hClock,
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
  const _Footer({required this.playlist, required this.expires, required this.account, required this.use24h, required this.padding});
  final Playlist playlist;
  final DateTime? expires;
  final Map<String, String?> account;
  final bool use24h;
  final EdgeInsets padding;

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
            PillButton(compact: true, icon: Icons.playlist_play_rounded, label: l10n.changePlaylist, onPressed: () => context.push(Routes.playlists)),
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
