import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/api/portal_api.dart';
import '../../core/db/database.dart';
import '../../core/device/device_identity.dart';
import '../../core/playlist/playlist_ids.dart';
import '../../core/settings/settings.dart';
import '../../core/xtream/xtream_client.dart';
import '../playlists/playlists_provider.dart';

// Per-title metadata shared by the home hero, the detail pages and the player: panel info
// (Xtream), TMDB art and the favourite flag.

/// Extended metadata, fetched from the Xtream panel on demand.
final movieInfoProvider = FutureProvider.family<XtreamVodInfo?, String>((ref, id) async {
  final p = ref.watch(activePlaylistProvider);
  if (p == null || p.type != PlaylistType.xtream) return null;
  final client = XtreamClient(p.xtreamCredentials);
  try {
    return await client.vodInfo(id);
  } catch (_) {
    return null;
  }
});

/// Series metadata (backdrop, genre, plot) fetched lazily from the Xtream panel.
final seriesInfoProvider = FutureProvider.family<XtreamSeriesInfo?, String>((ref, id) async {
  final p = ref.watch(activePlaylistProvider);
  if (p == null || p.type != PlaylistType.xtream) return null;
  final client = XtreamClient(p.xtreamCredentials);
  try {
    return await client.seriesInfo(id);
  } catch (_) {
    return null;
  }
});

/// TMDB language for the current UI locale.
final tmdbLangProvider = Provider<String>((ref) {
  final code = ref.watch(settingsProvider.select((s) => s.locale?.languageCode)) ?? PlatformDispatcher.instance.locale.languageCode;
  return code == 'fr' ? 'fr-FR' : 'en-US';
});

/// TMDB artwork/synopsis for a local item whose panel exposes a `tmdb_id`.
final tmdbArtProvider = FutureProvider.family<TmdbSummary?, (String, int)>((ref, key) async {
  await ref.watch(deviceIdentityProvider.future);
  final lang = ref.watch(tmdbLangProvider);
  ref.keepAlive();
  return ref.read(portalApiProvider).tmdbDetails(kind: key.$1, id: key.$2, lang: lang);
});

/// Favourite flag of one title: (playlist id, kind, item id).
final isFavoriteProvider = StreamProvider.family<bool, (String, ContentKind, String)>((ref, key) {
  return ref.watch(databaseProvider).watchIsFavorite(key.$1, key.$2, key.$3);
});
