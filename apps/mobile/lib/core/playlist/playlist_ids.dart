import '../db/database.dart';
import '../xtream/xtream_client.dart';

/// Portal playlists are mirrored locally under `portal-<server uuid>` (see `device-session`).
const _portalPrefix = 'portal-';

/// Local id of the mirror of the server playlist [serverId].
String portalPlaylistId(String serverId) => '$_portalPrefix$serverId';

/// Server uuid behind the local id [localId], null for ids that are not portal mirrors.
String? serverIdOf(String localId) => localId.startsWith(_portalPrefix) ? localId.substring(_portalPrefix.length) : null;

/// Server uuid of a mirrored playlist, null for legacy local playlists.
String? serverPlaylistId(Playlist p) => p.source == PlaylistSource.portal ? p.id.replaceFirst(_portalPrefix, '') : null;

extension PlaylistXtreamCredentials on Playlist {
  /// Panel credentials of an Xtream playlist, as stored locally (never persisted in stream URLs).
  XtreamCredentials get xtreamCredentials => XtreamCredentials(baseUrl: url, username: username ?? '', password: password ?? '');
}
