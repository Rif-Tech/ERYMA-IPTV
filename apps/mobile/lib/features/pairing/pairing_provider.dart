import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/config.dart';
import '../../core/api/portal_api.dart';
import '../../core/device/device_identity.dart';
import '../playlists/playlists_provider.dart';

enum PairingKind { device, playlist }

enum PairingPhase { pending, confirmed, expired, error }

@immutable
class PairingFlow {
  const PairingFlow({required this.kind, this.ticket, this.phase = PairingPhase.pending, this.error});
  final PairingKind kind;
  final PairingTicket? ticket;
  final PairingPhase phase;
  final String? error;

  /// URL embedded in the QR code; prefers the server-computed one so a portal move needs no app update.
  String? get url {
    final t = ticket;
    if (t == null) return null;
    if (t.url != null && t.url!.isNotEmpty) return t.url;
    return kind == PairingKind.device ? AppConfig.activateUrl(t.token) : AppConfig.addPlaylistUrl(t.token);
  }

  PairingFlow copyWith({PairingPhase? phase, String? error}) =>
      PairingFlow(kind: kind, ticket: ticket, phase: phase ?? this.phase, error: error ?? this.error);
}

/// Creates a temporary pairing session and polls it until the portal confirms it.
///
/// Device pairing: the install secret is generated locally, only its hash travels; once confirmed
/// the pending secret is committed and the account session reloads. Playlist pairing: the web form
/// adds the playlist to the account; the session reloads so the mirror picks it up.
class PairingNotifier extends AsyncNotifier<PairingFlow> {
  PairingNotifier(this.kind);
  final PairingKind kind;

  static const pollInterval = Duration(seconds: 2);
  Timer? _timer;
  bool _polling = false;

  @override
  Future<PairingFlow> build() async {
    ref.onDispose(_stop);
    final api = ref.read(portalApiProvider);
    final device = await ref.read(deviceIdentityProvider.future);
    try {
      final PairingTicket ticket;
      if (kind == PairingKind.device) {
        final secret = await ref.read(installCredentialsProvider).pendingSecret();
        ticket = await api.createDevicePairing(device.toPairingJson(), secretHash: sha256Hex(secret));
      } else {
        ticket = await api.createPlaylistPairing(device.toPairingJson());
      }
      _timer = Timer.periodic(pollInterval, (_) => _poll());
      return PairingFlow(kind: kind, ticket: ticket);
    } on PortalApiException catch (e) {
      if (e.unpaired) await ref.read(installSecretProvider.notifier).clear();
      return PairingFlow(kind: kind, phase: PairingPhase.error, error: e.message);
    } catch (e) {
      return PairingFlow(kind: kind, phase: PairingPhase.error, error: e.toString());
    }
  }

  /// Abandons the current code and asks for a new one (also rotates the proposed secret).
  Future<void> restart() async {
    _stop();
    if (kind == PairingKind.device) await ref.read(installCredentialsProvider).rotatePending();
    ref.invalidateSelf();
  }

  void _stop() {
    _timer?.cancel();
    _timer = null;
  }

  Future<void> _poll() async {
    if (_polling) return;
    final flow = state.value;
    final ticket = flow?.ticket;
    if (flow == null || ticket == null || flow.phase != PairingPhase.pending) return _stop();
    if (DateTime.now().isAfter(ticket.expiresAt)) {
      _stop();
      state = AsyncData(flow.copyWith(phase: PairingPhase.expired));
      return;
    }
    _polling = true;
    try {
      final status = await ref.read(portalApiProvider).pairingStatus(ticket);
      if (!ref.mounted) return;
      if (status.confirmed) {
        _stop();
        if (kind == PairingKind.device) await ref.read(installSecretProvider.notifier).commitPending();
        state = AsyncData(flow.copyWith(phase: PairingPhase.confirmed));
        // Reload account, profiles and playlists now that the server knows us / has the playlist.
        unawaited(ref.read(deviceSessionProvider.notifier).refresh());
      } else if (status.finished) {
        _stop();
        state = AsyncData(flow.copyWith(phase: PairingPhase.expired));
      }
    } on PortalApiException catch (e) {
      // 404/410: the session vanished (expired server-side or consumed elsewhere).
      if (e.statusCode == 404 || e.statusCode == 410) {
        _stop();
        if (ref.mounted) state = AsyncData(flow.copyWith(phase: PairingPhase.expired));
      } else {
        debugPrint('pairing poll: $e');
      }
    } catch (e) {
      debugPrint('pairing poll: $e');
    } finally {
      _polling = false;
    }
  }
}

final pairingProvider = AsyncNotifierProvider.family<PairingNotifier, PairingFlow, PairingKind>(PairingNotifier.new);
