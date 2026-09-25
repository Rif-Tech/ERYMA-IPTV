import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/responsive.dart';
import '../../app/router.dart';
import '../../core/db/database.dart';
import '../../core/settings/settings.dart';
import '../../l10n/generated/app_localizations.dart';
import '../../widgets/common.dart';
import '../content/category_browser.dart';
import '../content/content_providers.dart';
import '../player/play.dart';
import '../playlists/playlists_provider.dart';

/// Shared category + poster grid browser for VOD and series.
class ContentBrowser extends ConsumerWidget {
  const ContentBrowser({super.key, required this.kind});
  final ContentKind kind;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final playlist = ref.watch(activePlaylistProvider);
    if (playlist == null) {
      if (ref.watch(playlistsProvider).isLoading) return const SizedBox.shrink();
      return EmptyState(icon: Icons.movie, message: kind == ContentKind.vod ? l10n.noMovies : l10n.noSeries);
    }
    final selected = ref.watch(selectedCategoryProvider(kind));
    final query = ContentQuery(playlist.id, kind, selected);

    return Responsive(
      builder: (context, form) {
        final grid = kind == ContentKind.vod
            ? AsyncView(
                value: ref.watch(moviesProvider(query)),
                builder: (page) => _MovieGrid(items: page.items, form: form, onNearEnd: () => ref.read(moviesProvider(query).notifier).loadMore()),
              )
            : AsyncView(
                value: ref.watch(seriesProvider(query)),
                builder: (page) => _SeriesGrid(items: page.items, form: form, onNearEnd: () => ref.read(seriesProvider(query).notifier).loadMore()),
              );
        return BrowserScaffold(kind: kind, form: form, child: grid);
      },
    );
  }
}

/// Fires `onNearEnd` while the builder lays out one of the last rows, so the next page is
/// requested before the user reaches the bottom.
void requestMoreIfNearEnd(int index, int count, VoidCallback onNearEnd, {int threshold = 40}) {
  if (index >= count - threshold) onNearEnd();
}

EdgeInsets _gridPadding(BuildContext context, FormFactor form) =>
    EdgeInsets.fromLTRB(form.isMobile ? 12 : 4, form.isMobile ? 4 : 12, form.isMobile ? 12 : 4, 32 + MediaQuery.paddingOf(context).bottom);

SliverGridDelegate _posterDelegate(FormFactor form, double width) => SliverGridDelegateWithFixedCrossAxisCount(
      crossAxisCount: form.posterColumns(width),
      // 2:3 poster plus the caption block below it.
      childAspectRatio: 0.56,
      crossAxisSpacing: form.isMobile ? 12 : 18,
      mainAxisSpacing: form.isMobile ? 12 : 22,
    );

class MoviesScreen extends StatelessWidget {
  const MoviesScreen({super.key});
  @override
  Widget build(BuildContext context) => const ContentBrowser(kind: ContentKind.vod);
}

class _MovieGrid extends ConsumerWidget {
  const _MovieGrid({required this.items, required this.form, required this.onNearEnd});
  final List<Movie> items;
  final FormFactor form;
  final VoidCallback onNearEnd;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    if (items.isEmpty) return EmptyState(icon: Icons.movie, message: l10n.noMovies);
    final layout = ref.watch(settingsProvider.select((s) => s.layout));
    if (layout == ContentLayout.list) {
      return ListView.builder(
        padding: _gridPadding(context, form),
        itemCount: items.length,
        itemExtent: 72,
        addAutomaticKeepAlives: false,
        addRepaintBoundaries: false,
        itemBuilder: (context, i) {
          requestMoreIfNearEnd(i, items.length, onNearEnd);
          final m = items[i];
          return Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: FocusableCard(
              scale: 1.01,
              onTap: () => context.push(Routes.movie(m.streamId)),
              onLongPress: () => playMovie(context, ref, m),
              child: GlassPanel(
                radius: 12,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                child: Row(
                  children: [
                    ClipRRect(borderRadius: BorderRadius.circular(6), child: AppImage(m.poster, icon: Icons.movie, width: 34, height: 50, decodeWidth: 120)),
                    const SizedBox(width: 14),
                    Expanded(child: Text(m.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: Theme.of(context).textTheme.titleSmall)),
                    if (m.year != null) Padding(padding: const EdgeInsets.only(left: 12), child: MetaBadge('${m.year}')),
                    if (m.rating != null && m.rating! > 0)
                      Padding(padding: const EdgeInsets.only(left: 8), child: MetaBadge(m.rating!.toStringAsFixed(1), icon: Icons.star_rounded)),
                  ],
                ),
              ),
            ),
          );
        },
      );
    }
    return LayoutBuilder(
      builder: (context, constraints) => GridView.builder(
        padding: _gridPadding(context, form),
        gridDelegate: _posterDelegate(form, constraints.maxWidth),
        itemCount: items.length,
        addAutomaticKeepAlives: false,
        addRepaintBoundaries: false,
        itemBuilder: (context, i) {
          requestMoreIfNearEnd(i, items.length, onNearEnd);
          final m = items[i];
          return PosterCard(
            title: m.name,
            subtitle: m.year?.toString(),
            imageUrl: m.poster,
            badge: m.rating != null && m.rating! > 0 ? _RatingBadge(m.rating!) : null,
            onTap: () => context.push(Routes.movie(m.streamId)),
            onLongPress: () => playMovie(context, ref, m),
          );
        },
      ),
    );
  }
}

class _SeriesGrid extends ConsumerWidget {
  const _SeriesGrid({required this.items, required this.form, required this.onNearEnd});
  final List<SeriesItem> items;
  final FormFactor form;
  final VoidCallback onNearEnd;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    if (items.isEmpty) return EmptyState(icon: Icons.video_library, message: l10n.noSeries);
    return LayoutBuilder(
      builder: (context, constraints) => GridView.builder(
        padding: _gridPadding(context, form),
        gridDelegate: _posterDelegate(form, constraints.maxWidth),
        itemCount: items.length,
        addAutomaticKeepAlives: false,
        addRepaintBoundaries: false,
        itemBuilder: (context, i) {
          requestMoreIfNearEnd(i, items.length, onNearEnd);
          final s = items[i];
          return PosterCard(
            title: s.name,
            subtitle: s.year?.toString(),
            imageUrl: s.cover,
            badge: s.rating != null && s.rating! > 0 ? _RatingBadge(s.rating!) : null,
            onTap: () => context.push(Routes.seriesDetail(s.seriesId)),
          );
        },
      ),
    );
  }
}

class _RatingBadge extends StatelessWidget {
  const _RatingBadge(this.rating);
  final double rating;
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      decoration: BoxDecoration(color: const Color(0xB3000000), borderRadius: BorderRadius.circular(6)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.star_rounded, size: 12, color: Colors.white),
          const SizedBox(width: 2),
          Text(rating.toStringAsFixed(1), style: Theme.of(context).textTheme.labelSmall),
        ],
      ),
    );
  }
}
