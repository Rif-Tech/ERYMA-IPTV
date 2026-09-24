import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sentry_flutter/sentry_flutter.dart';

import '../core/device/device_identity.dart';
import '../core/log/layout_audit.dart';
import '../core/log/remote_key_tracker.dart';
import '../core/log/telemetry.dart';
import '../core/settings/settings.dart';
import '../features/playlists/playlists_provider.dart';
import 'router.dart';

/// Navigation breadcrumbs + `route` tag, for every location change (tabs included: go_router's
/// navigator observers do not see StatefulShellRoute branch switches). Also triggers the layout
/// audit of each new screen. Watched once at the app root.
final telemetryRouteProvider = Provider<void>((ref) {
  if (!Telemetry.enabled) return;
  final router = ref.watch(routerProvider);
  RemoteKeyTracker.onIdle = LayoutAudit.schedule;
  void onChange() {
    final location = router.routerDelegate.currentConfiguration.uri.path;
    if (location == RemoteKeyTracker.route) return;
    Telemetry.breadcrumb('navigation', location, data: {'from': RemoteKeyTracker.route, 'to': location}, type: 'navigation');
    RemoteKeyTracker.route = location;
    Telemetry.tags({'route': Telemetry.routeTemplate(location)});
    LayoutAudit.schedule();
  }

  router.routerDelegate.addListener(onChange);
  ref.onDispose(() => router.routerDelegate.removeListener(onChange));
});

/// Who and what an event comes from: install, server device, account status, profile, playlist
/// type and the settings that change playback/network behaviour. Never titles or credentials.
final telemetryScopeProvider = Provider<void>((ref) {
  if (!Telemetry.enabled) return;
  final identity = ref.watch(deviceIdentityProvider).value;
  final session = ref.watch(deviceSessionProvider).value;
  final profile = ref.watch(activeProfileProvider);
  final playlist = ref.watch(activePlaylistProvider);
  final s = ref.watch(settingsProvider);
  final snapshot = session?.snapshot;
  final status = session?.status;

  Telemetry.user(identity == null
      ? null
      : SentryUser(
          // The install uuid is what device-logs / app_logs are keyed on, so both sides join.
          id: identity.uuid,
          ipAddress: '{{auto}}',
          name: snapshot?.deviceName,
          data: {
            if (snapshot != null) 'server_device_id': snapshot.deviceId,
            'app_version': identity.appVersion,
          },
        ));
  Telemetry.tags({
    'device_uuid': identity?.uuid,
    'server_device_id': snapshot?.deviceId,
    'session': session?.phase.name,
    'plan': status?.plan,
    'account_expired': status == null ? null : '${status.expired}',
    'trial': status == null ? null : '${status.isTrial}',
    'profile_id': profile?.id,
    'kids_profile': profile == null ? null : '${profile.isKids}',
    'playlist_type': playlist?.type.name,
    'playlist_source': playlist?.source.name,
    'playlist_host': Telemetry.hostOf(playlist?.url),
    'dns_mode': s.dnsMode.name,
    'video_decoder': s.videoDecoder.name,
    'live_format': s.liveFormat.name,
    'locale': s.locale?.languageCode ?? 'system',
  });
  Telemetry.context('account', status == null
      ? null
      : {
          'phase': session!.phase.name,
          'plan': status.plan,
          'plan_name': status.planName,
          'expired': status.expired,
          'is_trial': status.isTrial,
          'trial_ends_at': status.trialEndsAt?.toIso8601String(),
          'expires_at': status.expiresAt?.toIso8601String(),
          'max_devices': status.maxDevices,
          'max_profiles': status.maxProfiles,
          'max_playlists': status.maxPlaylists,
          'profiles': snapshot?.profiles.length,
          'playlists': snapshot?.playlists.length,
          'error': session.error,
        });
  Telemetry.context('device_identity', identity == null
      ? null
      : {
          'type': identity.type.name,
          'platform': identity.platform,
          'manufacturer': identity.manufacturer,
          'model': identity.model,
          'os': identity.os,
          'os_version': identity.osVersion,
        });
  Telemetry.context('playlist', playlist == null
      ? null
      : {
          'id': playlist.id,
          'type': playlist.type.name,
          'source': playlist.source.name,
          'host': Telemetry.hostOf(playlist.url),
          'has_epg': playlist.epgUrl?.isNotEmpty == true,
          'protected': playlist.isProtected,
          'expires_at': playlist.expiresAt?.toIso8601String(),
          'last_synced_at': playlist.lastSyncedAt?.toIso8601String(),
        });
  Telemetry.context('settings', {
    'video_decoder': s.videoDecoder.name,
    'video_fit': s.videoFit.name,
    'live_format': s.liveFormat.name,
    'performance_mode': s.performanceMode.name,
    'layout': s.layout.name,
    'theme': s.themeMode.name,
    'dns_mode': s.dnsMode.name,
    'dns_server_id': s.dnsServerId,
    'dns_custom': s.dnsCustomAddresses,
    'parental_pin_set': s.parentalPin != null,
  });
});
