import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/responsive.dart';
import '../../app/router.dart';
import '../../app/theme.dart';
import '../../l10n/generated/app_localizations.dart';
import '../../widgets/common.dart';
import '../content/content_providers.dart';
import '../player/play.dart';

class _Query extends Notifier<String> {
  @override
  String build() => '';
  void set(String v) => state = v;
}

final _queryProvider = NotifierProvider<_Query, String>(_Query.new);

class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({super.key});

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> {
  late final _controller = TextEditingController(text: ref.read(_queryProvider));
  Timer? _debounce;

  @override
  void dispose() {
    _debounce?.cancel();
    _controller.dispose();
    super.dispose();
  }

  // Three table scans per keystroke is what made typing stutter; wait for a pause instead.
  void _onChanged(String v) {
    _debounce?.cancel();
    if (v.isEmpty) {
      ref.read(_queryProvider.notifier).set('');
      return;
    }
    _debounce = Timer(const Duration(milliseconds: 300), () {
      if (mounted) ref.read(_queryProvider.notifier).set(v);
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final query = ref.watch(_queryProvider);
    final results = ref.watch(searchProvider(query));
    final top = MediaQuery.paddingOf(context).top;
    final g = context.tokens.pageGutter;

    return Responsive(
      builder: (context, form) => Column(
        children: [
          Padding(
            padding: EdgeInsets.fromLTRB(g, top + 12, g, 8),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 720),
              child: TextField(
                autofocus: true,
                controller: _controller,
                style: Theme.of(context).textTheme.titleMedium,
                decoration: InputDecoration(
                  hintText: l10n.searchHint,
                  prefixIcon: const Icon(Icons.search_rounded),
                  border: const OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(999)), borderSide: BorderSide.none),
                  enabledBorder: const OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(999)), borderSide: BorderSide.none),
                  focusedBorder: const OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(999)), borderSide: BorderSide(color: Colors.white, width: 2)),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                  suffixIcon: query.isEmpty
                      ? null
                      : IconButton(
                          icon: const Icon(Icons.clear_rounded),
                          onPressed: () {
                            _controller.clear();
                            ref.read(_queryProvider.notifier).set('');
                          },
                        ),
                ),
                onChanged: _onChanged,
              ),
            ),
          ),
          Expanded(
            child: results.when(
              skipLoadingOnReload: true,
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => EmptyState(icon: Icons.error_outline, message: e.toString()),
              data: (r) {
                if (query.trim().length < 2) return const SizedBox.shrink();
                if (r.isEmpty) return EmptyState(icon: Icons.search_off_rounded, message: l10n.noResults);
                final posterW = form.isMobile ? 120.0 : 160.0;
                final channelW = form.isMobile ? 150.0 : 190.0;
                return ListView(
                  padding: EdgeInsets.only(bottom: 32 + MediaQuery.paddingOf(context).bottom),
                  children: [
                    if (r.channels.isNotEmpty)
                      Shelf(
                        title: l10n.liveTv,
                        itemCount: r.channels.length,
                        itemWidth: channelW,
                        height: channelW * 9 / 16,
                        itemBuilder: (context, i) {
                          final c = r.channels[i];
                          return FocusableCard(
                            onTap: () => playChannels(context, ref, r.channels, i),
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
                      ),
                    if (r.movies.isNotEmpty)
                      Shelf(
                        title: l10n.movies,
                        itemCount: r.movies.length,
                        itemWidth: posterW,
                        height: posterW * 3 / 2 + 40,
                        itemBuilder: (context, i) {
                          final m = r.movies[i];
                          return PosterCard(
                            title: m.name,
                            subtitle: m.year?.toString(),
                            imageUrl: m.poster,
                            onTap: () => context.push(Routes.movie(m.streamId)),
                          );
                        },
                      ),
                    if (r.series.isNotEmpty)
                      Shelf(
                        title: l10n.series,
                        itemCount: r.series.length,
                        itemWidth: posterW,
                        height: posterW * 3 / 2 + 40,
                        itemBuilder: (context, i) {
                          final s = r.series[i];
                          return PosterCard(
                            title: s.name,
                            subtitle: s.year?.toString(),
                            imageUrl: s.cover,
                            onTap: () => context.push(Routes.seriesDetail(s.seriesId)),
                          );
                        },
                      ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
