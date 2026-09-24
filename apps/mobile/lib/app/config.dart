/// Build-time configuration. Override with `--dart-define=KEY=value`.
abstract final class AppConfig {
  /// Base URL of the Supabase Edge Functions (device / portal API).
  static const apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'https://zeproepijcixdmszlkmf.supabase.co/functions/v1',
  );

  /// Supabase publishable key (sent as `apikey`, harmless if functions skip JWT check).
  static const apiAnonKey = String.fromEnvironment(
    'API_ANON_KEY',
    defaultValue: 'sb_publishable_TYELYS4jPwntkdewcn1t_Q_7pTrgEXX',
  );

  /// Build-time portal URL, used only until the server tells us the real one (`app-info.portal_url`).
  static const _portalUrlDefine = String.fromEnvironment(
    'PORTAL_URL',
    defaultValue: 'http://100.88.208.52:3000',
  );

  /// Portal URL received from the server (admin config), remembered across launches.
  static String? runtimePortalUrl;

  /// Public URL of the web portal shown to the user (QR code, pairing instructions).
  ///
  /// The server value wins: a TV box must never show a `localhost` or stale build-time address.
  static String get portalUrl => (runtimePortalUrl ?? _portalUrlDefine).replaceFirst(RegExp(r'/+$'), '');

  /// Host shown to the user (`portail.example.com`), without scheme.
  static String get portalHost => portalUrl.replaceFirst(RegExp(r'^https?://'), '');

  /// Web page that links a device to an account; the QR code embeds the one-time pairing token.
  static String activateUrl(String token) => '$portalUrl/activate?token=${Uri.encodeQueryComponent(token)}';

  /// Web page that adds a playlist to the account of an already paired device.
  static String addPlaylistUrl(String token) => '$portalUrl/add-playlist?token=${Uri.encodeQueryComponent(token)}';

  /// Account area of the portal (devices, profiles, playlists).
  static String get accountUrl => '$portalUrl/account';

  /// Playlists page of the account, opening straight on the "add" form.
  static String get playlistsPageUrl => '$portalUrl/account/playlists?add=1';

  /// [playlistsPageUrl] without scheme/query, short enough to type from a TV screen.
  static String get playlistsPageLabel => '$portalHost/account/playlists';

  static const appName = 'MultIPTV';

  /// Sentry DSN for native crash / Dart exception reporting. Empty disables it entirely (no
  /// account is provisioned by default — see docs/api.md for how to set one up).
  static const sentryDsn = String.fromEnvironment('SENTRY_DSN');

  /// Attaches a screenshot to Sentry events. Off by default: a screenshot shows playlist content
  /// (titles, posters), which otherwise never leaves the device. Meant for test boxes.
  static const sentryScreenshots = bool.fromEnvironment('SENTRY_SCREENSHOTS');
}
