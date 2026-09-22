import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/db/database.dart';
import '../../l10n/generated/app_localizations.dart';
import '../../widgets/common.dart';
import '../content/content_providers.dart';
import '../playlists/playlists_provider.dart';

/// "My groups": user-defined channel lists.
class GroupsScreen extends ConsumerWidget {
  const GroupsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final playlist = ref.watch(activePlaylistProvider);
    if (playlist == null) return Scaffold(appBar: AppBar(title: Text(l10n.myGroups)));
    final groups = ref.watch(channelGroupsProvider(playlist.id)).value ?? const [];
    final db = ref.read(databaseProvider);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.myGroups)),
      floatingActionButton: FloatingActionButton.extended(
        autofocus: groups.isEmpty,
        onPressed: () async {
          final name = await _askName(context, l10n);
          if (name != null && name.isNotEmpty) await db.createGroup(playlist.id, name);
        },
        icon: const Icon(Icons.add),
        label: Text(l10n.addGroup),
      ),
      body: groups.isEmpty
          ? EmptyState(icon: Icons.folder_special_outlined, message: l10n.myGroups)
          : ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: groups.length,
              itemBuilder: (context, i) {
                final g = groups[i];
                return Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  child: ListTile(
                    autofocus: i == 0,
                    leading: const Icon(Icons.folder_special),
                    title: Text(g.name),
                    onTap: () => _editChannels(context, ref, playlist.id, g),
                    trailing: IconButton(
                      tooltip: l10n.removeGroup,
                      icon: const Icon(Icons.delete_outline),
                      onPressed: () => db.deleteGroup(g.id),
                    ),
                  ),
                );
              },
            ),
    );
  }

  Future<String?> _askName(BuildContext context, AppLocalizations l10n) {
    final controller = TextEditingController();
    return showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.addGroup),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: InputDecoration(labelText: l10n.groupName),
          onSubmitted: (v) => Navigator.pop(context, v.trim()),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text(l10n.cancel)),
          FilledButton(onPressed: () => Navigator.pop(context, controller.text.trim()), child: Text(l10n.save)),
        ],
      ),
    );
  }

  Future<void> _editChannels(BuildContext context, WidgetRef ref, String playlistId, ChannelGroup g) async {
    final db = ref.read(databaseProvider);
    final all = await ref.read(allChannelsProvider(playlistId).future);
    final current = (await db.getGroupChannels(playlistId, g.id)).map((c) => c.streamId).toSet();
    if (!context.mounted) return;
    final selected = Set<String>.of(current);
    var filter = '';
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          final l10n = AppLocalizations.of(context);
          final visible = filter.isEmpty ? all : all.where((c) => c.name.toLowerCase().contains(filter.toLowerCase())).toList();
          return AlertDialog(
            title: Text('${g.name} · ${l10n.addChannels}'),
            content: SizedBox(
              width: 500,
              height: 500,
              child: Column(
                children: [
                  TextField(
                    autofocus: true,
                    decoration: InputDecoration(prefixIcon: const Icon(Icons.search), hintText: l10n.search),
                    onChanged: (v) => setState(() => filter = v),
                  ),
                  const SizedBox(height: 8),
                  Expanded(
                    child: ListView.builder(
                      itemCount: visible.length,
                      itemBuilder: (context, i) {
                        final c = visible[i];
                        return CheckboxListTile(
                          dense: true,
                          value: selected.contains(c.streamId),
                          title: Text(c.name, maxLines: 1, overflow: TextOverflow.ellipsis),
                          onChanged: (v) => setState(() => v == true ? selected.add(c.streamId) : selected.remove(c.streamId)),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(context, false), child: Text(l10n.cancel)),
              FilledButton(onPressed: () => Navigator.pop(context, true), child: Text(l10n.save)),
            ],
          );
        },
      ),
    );
    if (result == true) {
      // Keep the existing order, append new picks.
      final ordered = [...current.where(selected.contains), ...selected.where((id) => !current.contains(id))];
      await db.setGroupChannels(g.id, ordered);
    }
  }
}
