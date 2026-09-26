import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/responsive.dart';
import '../../app/router.dart';
import '../../app/theme.dart';
import '../../l10n/generated/app_localizations.dart';
import '../../widgets/common.dart';
import 'search_provider.dart';
import '../player/play.dart';
import '../../core/log/remote_key_tracker.dart';
import '../../core/log/trace_tag.dart';
import '../../widgets/row_focus_chain.dart';

class _Query extends Notifier<String> {
  @override
  String build() => '';
  void set(String v) => state = v;
}

final _queryProvider = NotifierProvider<_Query, String>(_Query.new);

/// Clears the search field and its results; the Search tab is never disposed (kept mounted like
/// every other tab, see [_BranchStack] in router.dart), so without this, returning to it from
/// elsewhere in the app shows the previous query/results instead of a blank search bar.
void resetSearch(WidgetRef ref) => ref.read(_queryProvider.notifier).set('');

class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({super.key});

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> {
  late final _controller = TextEditingController(text: ref.read(_queryProvider));
  // The results' own scope, so Down from the field can target its first card directly: the field
  // is narrower than and centered differently from the rails below it, so Flutter's geometric
  // `focusInDirection` can land on the 2nd/3rd card instead of the 1st.
  final _resultsScope = FocusScopeNode(debugLabel: 'search-results');
  // One scope per result row, chained below the field by RowFocusChain (same model as home).
  final _channelsScope = FocusScopeNode(debugLabel: 'search-channels');
  final _moviesScope = FocusScopeNode(debugLabel: 'search-movies');
  final _seriesScope = FocusScopeNode(debugLabel: 'search-series');
  // A focused TextField swallows the vertical arrows (cursor to line start/end), which strands a
  // D-pad user in the field: hand them to focus traversal so DOWN reaches the results.
  late final _fieldFocus = FocusNode(
    debugLabel: 'search',
    onKeyEvent: (node, event) {
      if (event is! KeyDownEvent && event is! KeyRepeatEvent) return KeyEventResult.ignored;
      if (event.logicalKey == LogicalKeyboardKey.arrowDown) {
        final ok = _focusFirstResult();
        RemoteKeyTracker.note(ok ? 'search: field → first result row' : 'search: field, no results below');
        return ok ? KeyEventResult.handled : KeyEventResult.ignored;
      }
      // OK brings the keyboard back on a field that kept the focus without it (_onFieldFocus).
      if (event is KeyDownEvent && event.logicalKey == LogicalKeyboardKey.select) {
        final editable = node.context?.findAncestorStateOfType<EditableTextState>();
        if (editable != null) {
          RemoteKeyTracker.note('search: OK → keyboard');
          editable.requestKeyboard();
          return KeyEventResult.handled;
        }
      }
      // Up: unhandled here, so the tab bridge takes it straight to the tab bar.
      return KeyEventResult.ignored;
    },
  );
  Timer? _debounce;
  // Set by the keyboard's search key while the results of the submitted query are loading.
  bool _focusResultsWhenReady = false;

  @override
  void initState() {
    super.initState();
    _fieldFocus.addListener(_onFieldFocus);
  }

  bool _focusFirstResult() {
    for (final row in [_channelsScope, _moviesScope, _seriesScope]) {
      final target = rowEntryOf(row);
      if (target == null) continue;
      target.requestFocus();
      return true;
    }
    return false;
  }

  // Android closes the input connection when its keyboard is dismissed, and Flutter then drops the
  // field's focus onto the page's bare scope: nothing highlighted, the next arrow went anywhere and
  // Down from the tabs came back to that scope (Sentry FLUTTER-1W). The field keeps the focus
  // instead, keyboard down: OK opens it again.
  void _onFieldFocus() {
    if (_fieldFocus.hasFocus) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || _fieldFocus.hasFocus || !_fieldFocus.canRequestFocus) return;
      final current = FocusManager.instance.primaryFocus;
      // Only a scope of this page: not a route opened above it, not another tab, not the tabs.
      if (current is! FocusScopeNode || !RemoteKeyTracker.isLost(current) || !_fieldFocus.ancestors.contains(current)) return;
      _fieldFocus.requestFocus();
      // requestFocus hands the field a keyboard token: spend it so the keyboard stays closed.
      _fieldFocus.consumeKeyboardToken();
    });
  }

  // The keyboard's search key: search now (no debounce), then move to the results once shown.
  void _submit(String v) {
    _debounce?.cancel();
    if (v == ref.read(_queryProvider)) {
      _focusFirstResult();
      return;
    }
    ref.read(_queryProvider.notifier).set(v);
    _focusResultsWhenReady = true;
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _controller.dispose();
    _fieldFocus.dispose();
    _resultsScope.dispose();
    _channelsScope.dispose();
    _moviesScope.dispose();
    _seriesScope.dispose();
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
    // An external reset() (leaving and coming back to this tab) only clears the provider; sync
    // the text field, which otherwise keeps showing the stale query it was built with.
    ref.listen<String>(_queryProvider, (prev, next) {
      if (next.isEmpty && _controller.text.isNotEmpty) _controller.clear();
    });
    final query = ref.watch(_queryProvider);
    final results = ref.watch(searchProvider(query));
    if (_focusResultsWhenReady && results.hasValue && !results.isLoading) {
      _focusResultsWhenReady = false;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _focusFirstResult();
      });
    }
    final top = MediaQuery.paddingOf(context).top;
    final g = context.tokens.pageGutter;

    return Responsive(
      builder: (context, form) => TraceTag('search', child: RowFocusChain(
        name: 'search-chain',
        rows: [_fieldFocus, _channelsScope, _moviesScope, _seriesScope],
        child: Column(
        children: [
          Padding(
            padding: EdgeInsets.fromLTRB(g, top + 12, g, 8),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 720),
              child: TextField(
                autofocus: true,
                focusNode: _fieldFocus,
                controller: _controller,
                textInputAction: TextInputAction.search,
                // Non-null so the search key keeps the focus (by default it unfocuses the field).
                onEditingComplete: () {},
                onSubmitted: _submit,
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
                            // The button disappears with the query: keep the cursor in the field.
                            _fieldFocus.requestFocus();
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
                return FocusScope(
                  node: _resultsScope,
                  child: FocusTraversalGroup(
                    child: ListView(
                      padding: EdgeInsets.only(bottom: 32 + MediaQuery.paddingOf(context).bottom),
                      children: [
                    if (r.channels.isNotEmpty)
                      TraceTag('live', child: FocusScope(node: _channelsScope, child: Shelf(
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
                      ))),
                    if (r.movies.isNotEmpty)
                      TraceTag('movies', child: FocusScope(node: _moviesScope, child: Shelf(
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
                      ))),
                    if (r.series.isNotEmpty)
                      TraceTag('series', child: FocusScope(node: _seriesScope, child: Shelf(
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
                      ))),
                    ],
                  ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
      )),
    );
  }
}
