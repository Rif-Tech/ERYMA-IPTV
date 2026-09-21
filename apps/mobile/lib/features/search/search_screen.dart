import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/router.dart';
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

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final query = ref.watch(_queryProvider);
    final results = ref.watch(searchProvider(query));

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(12),
          child: TextField(
            autofocus: true,
            controller: _controller,
            decoration: InputDecoration(
              hintText: l10n.searchHint,
              prefixIcon: const Icon(Icons.search),
              suffixIcon: query.isEmpty
                  ? null
                  : IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        _controller.clear();
                        ref.read(_queryProvider.notifier).set('');
                      },
                    ),
            ),
            onChanged: (v) => ref.read(_queryProvider.notifier).set(v),
          ),
        ),
        Expanded(
          child: results.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => EmptyState(icon: Icons.error_outline, message: e.toString()),
            data: (r) {
              if (query.trim().length < 2) return const SizedBox.shrink();
              if (r.isEmpty) return EmptyState(icon: Icons.search_off, message: l10n.noResults);
              return ListView(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                children: [
                  if (r.channels.isNotEmpty) SectionHeader(l10n.liveTv),
                  for (final (i, c) in r.channels.indexed)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: ChannelTile(name: c.name, logo: c.logo, dense: true, onTap: () => playChannels(context, ref, r.channels, i)),
                    ),
                  if (r.movies.isNotEmpty) SectionHeader(l10n.movies),
                  for (final m in r.movies)
                    FocusableCard(
                      scale: 1.01,
                      onTap: () => context.push(Routes.movie(m.streamId)),
                      child: ListTile(
                        leading: SizedBox(width: 40, height: 56, child: AppImage(m.poster, icon: Icons.movie)),
                        title: Text(m.name),
                        subtitle: m.year != null ? Text('${m.year}') : null,
                      ),
                    ),
                  if (r.series.isNotEmpty) SectionHeader(l10n.series),
                  for (final s in r.series)
                    FocusableCard(
                      scale: 1.01,
                      onTap: () => context.push(Routes.seriesDetail(s.seriesId)),
                      child: ListTile(
                        leading: SizedBox(width: 40, height: 56, child: AppImage(s.cover, icon: Icons.video_library)),
                        title: Text(s.name),
                        subtitle: s.year != null ? Text('${s.year}') : null,
                      ),
                    ),
                ],
              );
            },
          ),
        ),
      ],
    );
  }
}
