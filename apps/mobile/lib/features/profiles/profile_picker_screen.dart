import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/responsive.dart';
import '../../app/router.dart';
import '../../app/theme.dart';
import '../../core/api/portal_api.dart';
import '../../l10n/generated/app_localizations.dart';
import '../../widgets/common.dart';
import '../playlists/playlists_provider.dart';
import '../splash/session_navigation.dart';

/// Avatar colours, mirroring the portal's palette.
const profileColors = <String, Color>{
  'blue': Color(0xFF3B82F6),
  'red': Color(0xFFEF4444),
  'green': Color(0xFF10B981),
  'orange': Color(0xFFF97316),
  'purple': Color(0xFF8B5CF6),
  'pink': Color(0xFFEC4899),
  'teal': Color(0xFF14B8A6),
  'yellow': Color(0xFFFACC15),
};

Color profileColor(String key) => profileColors[key] ?? profileColors['blue']!;

/// "Who's watching?" — one tile per viewer profile of the account.
class ProfilePickerScreen extends ConsumerWidget {
  const ProfilePickerScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final profiles = ref.watch(profilesProvider);
    final activeId = ref.watch(activeProfileProvider)?.id;
    final syncing = ref.watch(deviceSessionProvider).isLoading;
    // TV: the remote's own Back key is the only way back everywhere in the app.
    final canGoBack = activeId != null && context.canPop() && !ref.watch(isTelevisionProvider);

    return Scaffold(
      appBar: AppBar(
        leading: canGoBack ? IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => context.pop()) : null,
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            tooltip: l10n.refreshPlaylists,
            icon: syncing ? const SizedBox.square(dimension: 20, child: CircularProgressIndicator(strokeWidth: 2)) : const Icon(Icons.sync),
            onPressed: syncing ? null : () => ref.read(deviceSessionProvider.notifier).refresh(),
          ),
          IconButton(tooltip: l10n.settings, icon: const Icon(Icons.settings), onPressed: () => context.push(Routes.settings)),
        ],
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1000),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(l10n.whoIsWatching, style: theme.textTheme.displaySmall),
              const SizedBox(height: 40),
              if (profiles.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 32),
                  child: syncing ? const CircularProgressIndicator() : Text(l10n.manageProfilesHint, style: theme.textTheme.bodyLarge),
                )
              else
                Wrap(
                  spacing: 28,
                  runSpacing: 28,
                  alignment: WrapAlignment.center,
                  children: [
                    for (var i = 0; i < profiles.length; i++)
                      ProfileTile(
                        profile: profiles[i],
                        autofocus: profiles[i].id == activeId || (activeId == null && i == 0),
                        selected: profiles[i].id == activeId,
                        onTap: () => _pick(context, ref, profiles[i]),
                      ),
                  ],
                ),
              const SizedBox(height: 40),
              Text(l10n.manageProfilesHint, style: theme.textTheme.bodySmall?.copyWith(color: context.tokens.textFaint)),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _pick(BuildContext context, WidgetRef ref, ViewerProfile profile) async {
    await ref.read(profileControllerProvider.notifier).select(profile);
    if (!context.mounted) return;
    await resumeNavigation(context, ref);
  }
}

class ProfileTile extends StatelessWidget {
  const ProfileTile({super.key, required this.profile, this.onTap, this.autofocus = false, this.selected = false, this.size = 132});
  final ViewerProfile profile;
  final VoidCallback? onTap;
  final bool autofocus;
  final bool selected;
  final double size;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    return SizedBox(
      width: size + 24,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          FocusableCard(
            autofocus: autofocus,
            selected: selected,
            borderRadius: 18,
            onTap: onTap,
            child: Container(
              width: size,
              height: size,
              decoration: BoxDecoration(color: profileColor(profile.avatar), borderRadius: BorderRadius.circular(18)),
              alignment: Alignment.center,
              child: Text(
                profile.name.isEmpty ? '?' : profile.name.characters.first.toUpperCase(),
                style: theme.textTheme.displayMedium?.copyWith(color: Colors.white, fontWeight: FontWeight.w700),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Text(profile.name, style: theme.textTheme.titleMedium, maxLines: 1, overflow: TextOverflow.ellipsis, textAlign: TextAlign.center),
          if (profile.isKids) Text(l10n.kidsProfile, style: theme.textTheme.bodySmall?.copyWith(color: context.tokens.textMuted)),
        ],
      ),
    );
  }
}
