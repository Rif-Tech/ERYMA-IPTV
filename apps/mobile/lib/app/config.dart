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

  /// Public URL of the web portal shown to the user (QR code, login link).
  static const portalUrl = String.fromEnvironment(
    'PORTAL_URL',
    defaultValue: 'http://localhost:3000',
  );

  static String portalLoginUrl(String mac, String key) =>
      '$portalUrl/manage-playlists/login?mac=${Uri.encodeQueryComponent(mac)}&key=${Uri.encodeQueryComponent(key)}';

  static const appName = 'MultIPTV';
}
