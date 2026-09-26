import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/responsive.dart';
import '../../core/db/database.dart';
import '../../core/settings/settings.dart';
import '../../l10n/generated/app_localizations.dart';
import '../../widgets/pin_dialog.dart';
import '../content/content_providers.dart';
import '../playlists/playlists_provider.dart';

/// Parental control: PIN management, hidden categories and locked channels.
class ParentalScreen extends ConsumerWidget {
  const ParentalScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final settings = ref.watch(settingsProvider);
    final playlist = ref.watch(activePlaylistProvider);

    return Scaffold(
      // TV: the remote's own Back key is the only way back everywhere in the app.
      appBar: AppBar(title: Text(l10n.parentalControl), automaticallyImplyLeading: !ref.watch(isTelevisionProvider)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          ListTile(
            autofocus: true,
            leading: const Icon(Icons.password),
            title: Text(settings.hasParentalPin ? l10n.changeParentalPin : l10n.setParentalPin),
            onTap: () async {
              final pin = await showPinDialog(context, title: l10n.setParentalPin, confirm: true);
              if (pin == null) return;
              await ref.read(settingsProvider.notifier).setParentalPin(pin);
              if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l10n.pinChanged)));
            },
          ),
          if (settings.hasParentalPin)
            ListTile(
              leading: const Icon(Icons.lock_open),
              title: Text('${l10n.delete} · ${l10n.parentalPin}'),
              onTap: () => ref.read(settingsProvider.notifier).setParentalPin(null),
            ),
          if (playlist != null) ...[
            const Divider(),
            _HiddenCategories(playlistId: playlist.id, kind: ContentKind.live, title: l10n.hideLiveCategories),
            _HiddenCategories(playlistId: playlist.id, kind: ContentKind.vod, title: l10n.hideMovieCategories),
            _HiddenCategories(playlistId: playlist.id, kind: ContentKind.series, title: l10n.hideSeriesCategories),
            const Divider(),
            _LockedChannels(playlistId: playlist.id),
          ],
        ],
      ),
    );
  }
}

final _allCategoriesProvider = StreamProvider.family<List<ContentCategory>, CategoryQuery>((ref, q) {
  return ref.watch(databaseProvider).watchCategories(q.playlistId, q.kind);
});

class _HiddenCategories extends ConsumerWidget {
  const _HiddenCategories({required this.playlistId, required this.kind, required this.title});
  final String playlistId;
  final ContentKind kind;
  final String title;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final q = CategoryQuery(playlistId, kind);
    final cats = ref.watch(_allCategoriesProvider(q)).value ?? const [];
    final hidden = ref.watch(hiddenCategoriesProvider(q)).value ?? const {};
    return ExpansionTile(
      leading: const Icon(Icons.visibility_off_outlined),
      title: Text(title),
      subtitle: Text('${hidden.length} / ${cats.length}'),
      children: [
        for (final c in cats)
          CheckboxListTile(
            dense: true,
            value: hidden.contains(c.externalId),
            title: Text(c.name),
            onChanged: (_) => ref.read(databaseProvider).toggleHiddenCategory(playlistId, kind, c.externalId),
          ),
      ],
    );
  }
}

class _LockedChannels extends ConsumerWidget {
  const _LockedChannels({required this.playlistId});
  final String playlistId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final locked = ref.watch(lockedChannelsProvider(playlistId)).value ?? const {};
    final channels = ref.watch(allChannelsProvider(playlistId)).value ?? const [];
    final lockedChannels = channels.where((c) => locked.contains(c.streamId)).toList();
    return ExpansionTile(
      leading: const Icon(Icons.lock_outline),
      title: Text(l10n.lockedChannels),
      subtitle: Text('${lockedChannels.length}'),
      children: [
        for (final c in lockedChannels)
          ListTile(
            dense: true,
            title: Text(c.name),
            trailing: IconButton(
              icon: const Icon(Icons.lock_open),
              tooltip: l10n.unlockChannel,
              onPressed: () => ref.read(databaseProvider).toggleLockedChannel(playlistId, c.streamId),
            ),
          ),
      ],
    );
  }
}
