import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/responsive.dart';
import '../../app/router.dart';
import '../../core/db/database.dart';
import '../../core/settings/settings.dart';
import '../../l10n/generated/app_localizations.dart';
import '../../widgets/common.dart';
import '../content/content_providers.dart';
import '../live/live_screen.dart';
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
    if (playlist == null) return EmptyState(icon: Icons.movie, message: kind == ContentKind.vod ? l10n.noMovies : l10n.noSeries);
    final selected = ref.watch(selectedCategoryProvider(kind));
    final query = ContentQuery(playlist.id, kind, selected);

    return Responsive(
      builder: (context, form) {
        final grid = kind == ContentKind.vod
            ? AsyncView(value: ref.watch(moviesProvider(query)), builder: (items) => _MovieGrid(items: items, form: form))
            : AsyncView(value: ref.watch(seriesProvider(query)), builder: (items) => _SeriesGrid(items: items, form: form));
        if (form.isMobile) {
          return Column(children: [CategoryBar(kind: kind), Expanded(child: grid)]);
        }
        return Row(
          children: [
            SizedBox(width: form.isTv ? 280 : 240, child: CategoryPane(kind: kind)),
            const VerticalDivider(width: 1),
            Expanded(child: grid),
          ],
        );
      },
    );
  }
}

class MoviesScreen extends StatelessWidget {
  const MoviesScreen({super.key});
  @override
  Widget build(BuildContext context) => const ContentBrowser(kind: ContentKind.vod);
}

class _MovieGrid extends ConsumerWidget {
  const _MovieGrid({required this.items, required this.form});
  final List<Movie> items;
  final FormFactor form;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    if (items.isEmpty) return EmptyState(icon: Icons.movie, message: l10n.noMovies);
    final layout = ref.watch(settingsProvider.select((s) => s.layout));
    if (layout == ContentLayout.list) {
      return ListView.builder(
        padding: const EdgeInsets.all(8),
        itemCount: items.length,
        itemBuilder: (context, i) {
          final m = items[i];
          return FocusableCard(
            scale: 1.01,
            autofocus: i == 0,
            onTap: () => context.push(Routes.movie(m.streamId)),
            child: ListTile(
              leading: SizedBox(width: 40, height: 56, child: AppImage(m.poster, icon: Icons.movie)),
              title: Text(m.name),
              subtitle: m.year != null ? Text('${m.year}') : null,
              trailing: m.rating != null ? Text('★ ${m.rating!.toStringAsFixed(1)}') : null,
            ),
          );
        },
      );
    }
    return LayoutBuilder(
      builder: (context, constraints) => GridView.builder(
        padding: const EdgeInsets.all(12),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: form.posterColumns(constraints.maxWidth),
          childAspectRatio: 0.58,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
        ),
        itemCount: items.length,
        itemBuilder: (context, i) {
          final m = items[i];
          return PosterCard(
            autofocus: i == 0,
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
  const _SeriesGrid({required this.items, required this.form});
  final List<SeriesItem> items;
  final FormFactor form;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    if (items.isEmpty) return EmptyState(icon: Icons.video_library, message: l10n.noSeries);
    return LayoutBuilder(
      builder: (context, constraints) => GridView.builder(
        padding: const EdgeInsets.all(12),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: form.posterColumns(constraints.maxWidth),
          childAspectRatio: 0.58,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
        ),
        itemCount: items.length,
        itemBuilder: (context, i) {
          final s = items[i];
          return PosterCard(
            autofocus: i == 0,
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
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(color: Colors.black54, borderRadius: BorderRadius.circular(6)),
      child: Text('★ ${rating.toStringAsFixed(1)}', style: const TextStyle(color: Colors.amber, fontSize: 12)),
    );
  }
}
