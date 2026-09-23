import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:crypto/crypto.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../settings/settings.dart';

enum DeviceType { mobile, tablet, tv }

@immutable
class DeviceIdentity {
  const DeviceIdentity({
    required this.uuid,
    required this.type,
    required this.platform,
    required this.appVersion,
    this.manufacturer,
    this.model,
    this.os,
    this.osVersion,
  });

  /// Random id generated once per installation; the account-side identity of this install.
  final String uuid;
  final DeviceType type;
  final String platform;
  final String appVersion;
  final String? manufacturer;
  final String? model;
  final String? os;
  final String? osVersion;

  /// Fields sent to `pairing-create`.
  Map<String, dynamic> toPairingJson() => {
        'device_uuid': uuid,
        'device_type': type.name,
        'platform': platform,
        'app_version': appVersion,
        'manufacturer': ?manufacturer,
        'model': ?model,
        'os': ?os,
        'os_version': ?osVersion,
      };

  /// Human readable hardware label (`Xiaomi MIBOX4`).
  String get hardwareLabel => [manufacturer, model].whereType<String>().where((s) => s.isNotEmpty).join(' ');
}

/// RFC 4122 version 4 UUID from a secure random source.
String generateUuidV4([Random? random]) {
  final rnd = random ?? Random.secure();
  final b = List<int>.generate(16, (_) => rnd.nextInt(256));
  b[6] = (b[6] & 0x0f) | 0x40;
  b[8] = (b[8] & 0x3f) | 0x80;
  final hex = b.map((e) => e.toRadixString(16).padLeft(2, '0')).join();
  return '${hex.substring(0, 8)}-${hex.substring(8, 12)}-${hex.substring(12, 16)}-${hex.substring(16, 20)}-${hex.substring(20)}';
}

/// 32 random bytes, URL-safe base64 without padding: the install secret sent as `x-device-secret`.
String generateInstallSecret([Random? random]) {
  final rnd = random ?? Random.secure();
  return base64Url.encode(List<int>.generate(32, (_) => rnd.nextInt(256))).replaceAll('=', '');
}

String sha256Hex(String value) => sha256.convert(utf8.encode(value)).toString();

/// Small key/value store backed by secure storage with a SharedPreferences fallback
/// (secure storage is unavailable on some TV boxes / emulators).
class _FallbackStore {
  _FallbackStore(this._storage, this.prefs);
  final FlutterSecureStorage _storage;
  final SharedPreferences? prefs;

  Future<String?> read(String key) async {
    try {
      final v = await _storage.read(key: key);
      if (v != null) return v;
    } catch (e) {
      debugPrint('secure storage read failed: $e');
    }
    return prefs?.getString(key);
  }

  Future<void> write(String key, String value) async {
    try {
      await _storage.write(key: key, value: value);
    } catch (e) {
      debugPrint('secure storage write failed: $e');
    }
    await prefs?.setString(key, value);
  }

  Future<void> delete(String key) async {
    try {
      await _storage.delete(key: key);
    } catch (e) {
      debugPrint('secure storage delete failed: $e');
    }
    await prefs?.remove(key);
  }
}

/// Persists the install secret that proves this install was paired with an account.
///
/// The secret is generated locally, only its SHA-256 is sent to the server at pairing time, and it
/// becomes valid once the account owner confirms the pairing on the web.
class InstallCredentialsStore {
  InstallCredentialsStore({FlutterSecureStorage? storage, SharedPreferences? prefs})
      : _store = _FallbackStore(storage ?? const FlutterSecureStorage(), prefs);

  static const _secretKey = 'install.secret';
  static const _pendingKey = 'install.secret.pending';
  final _FallbackStore _store;

  /// Secret of a confirmed pairing, or null when the install is unpaired.
  Future<String?> readSecret() => _store.read(_secretKey);

  /// Secret currently proposed to the server (pairing in progress). Reused across app restarts so a
  /// pairing confirmed while the app was closed still works.
  Future<String> pendingSecret() async {
    final existing = await _store.read(_pendingKey);
    if (existing != null) return existing;
    final fresh = generateInstallSecret();
    await _store.write(_pendingKey, fresh);
    return fresh;
  }

  Future<void> rotatePending() => _store.delete(_pendingKey);

  /// Promotes the pending secret once the server confirmed the pairing.
  Future<void> commitPending() async {
    final pending = await _store.read(_pendingKey);
    if (pending == null) return;
    await _store.write(_secretKey, pending);
    await _store.delete(_pendingKey);
  }

  Future<void> clear() async {
    await _store.delete(_secretKey);
    await _store.delete(_pendingKey);
  }
}

class DeviceIdentityService {
  DeviceIdentityService({FlutterSecureStorage? storage, this.prefs})
      : _store = _FallbackStore(storage ?? const FlutterSecureStorage(), prefs);

  static const _uuidKey = 'device.uuid';
  final _FallbackStore _store;

  /// Fallback store: secure storage is unavailable on some TV boxes / emulators.
  final SharedPreferences? prefs;

  Future<DeviceIdentity> load() async {
    final info = DeviceInfoPlugin();
    final package = await PackageInfo.fromPlatform();

    var uuid = await _store.read(_uuidKey);
    var type = DeviceType.mobile;
    var platform = defaultTargetPlatform.name;
    String? manufacturer;
    String? model;
    String? os;
    String? osVersion;

    if (!kIsWeb && Platform.isAndroid) {
      final android = await info.androidInfo;
      platform = 'android';
      type = await _androidDeviceType(android);
      manufacturer = android.manufacturer;
      model = android.model;
      os = android.systemFeatures.contains('android.software.leanback') ? 'Android TV' : 'Android';
      osVersion = android.version.release;
    } else if (!kIsWeb && Platform.isIOS) {
      final ios = await info.iosInfo;
      platform = 'ios';
      type = ios.model.toLowerCase().contains('ipad') ? DeviceType.tablet : DeviceType.mobile;
      manufacturer = 'Apple';
      model = ios.utsname.machine;
      os = ios.systemName;
      osVersion = ios.systemVersion;
    }
    uuid ??= generateUuidV4();
    await _store.write(_uuidKey, uuid);

    return DeviceIdentity(
      uuid: uuid,
      type: type,
      platform: platform,
      appVersion: package.version,
      manufacturer: manufacturer,
      model: model,
      os: os,
      osVersion: osVersion,
    );
  }

  Future<DeviceType> _androidDeviceType(AndroidDeviceInfo android) async {
    if (await isAndroidTelevision()) return DeviceType.tv;
    final view = WidgetsBinding.instance.platformDispatcher.views.firstOrNull;
    if (view != null) {
      final shortest = view.physicalSize.shortestSide / view.devicePixelRatio;
      if (shortest >= 600) return DeviceType.tablet;
    }
    return DeviceType.mobile;
  }
}

/// Uses Android system features exposed by device_info_plus to detect leanback devices.
Future<bool> isAndroidTelevision() async {
  if (kIsWeb || !Platform.isAndroid) return false;
  try {
    final android = await DeviceInfoPlugin().androidInfo;
    final features = android.systemFeatures;
    return features.contains('android.software.leanback') ||
        features.contains('android.hardware.type.television');
  } on PlatformException {
    return false;
  }
}

Future<bool> isAndroidEmulator() async {
  if (kIsWeb || !Platform.isAndroid) return false;
  try {
    return !(await DeviceInfoPlugin().androidInfo).isPhysicalDevice;
  } on PlatformException {
    return false;
  }
}

/// 32-bit-only or old Android devices: the class of hardware where every effect must be cheap.
Future<bool> isLowEndDevice() async {
  if (kIsWeb || !Platform.isAndroid) return false;
  try {
    final android = await DeviceInfoPlugin().androidInfo;
    return android.supported64BitAbis.isEmpty || android.version.sdkInt < 28 || android.isLowRamDevice;
  } on PlatformException {
    return false;
  }
}

final deviceIdentityProvider = FutureProvider<DeviceIdentity>((ref) {
  return DeviceIdentityService(prefs: ref.watch(sharedPreferencesProvider)).load();
});

final installCredentialsProvider = Provider<InstallCredentialsStore>((ref) {
  return InstallCredentialsStore(prefs: ref.watch(sharedPreferencesProvider));
});

/// The confirmed install secret; null = this install must be paired. Kept in memory so every
/// request can attach it synchronously; updated by the pairing flow and on 401 UNPAIRED.
class InstallSecretNotifier extends AsyncNotifier<String?> {
  @override
  Future<String?> build() => ref.watch(installCredentialsProvider).readSecret();

  Future<void> commitPending() async {
    final store = ref.read(installCredentialsProvider);
    await store.commitPending();
    state = AsyncData(await store.readSecret());
  }

  Future<void> clear() async {
    await ref.read(installCredentialsProvider).clear();
    state = const AsyncData(null);
  }
}

final installSecretProvider = AsyncNotifierProvider<InstallSecretNotifier, String?>(InstallSecretNotifier.new);
