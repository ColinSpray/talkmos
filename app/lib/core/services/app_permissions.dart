import 'dart:io';

import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:permission_handler/permission_handler.dart';

enum AppPermission {
  camera,
  microphone,

  /// Reading the device's photos and videos. Which OS permission that means
  /// depends on the Android version — see [_galleryPermissions].
  gallery,

  contacts,

  /// Location while the app is in use.
  location,

  /// Location at all times, for Nearby's background updates. Android only
  /// grants this after [location], and from Android 11 only through Settings.
  locationAlways,

  notifications,

  /// Android 12+ splits Bluetooth into scan/connect; earlier versions had one
  /// permission covered by [Permission.bluetooth].
  bluetooth,
}

/// The outcome of asking, flattened to the four cases a caller actually
/// behaves differently for.
enum PermissionOutcome {
  granted,

  /// Refused this time; asking again will still show the system dialog.
  denied,

  /// Refused for good (or blocked by policy). Only a trip to Settings fixes
  /// this — [AppPermissions.openSettings] is the only useful next step.
  permanentlyDenied,

  /// No such permission on this platform, so treat the feature as available
  /// rather than blocking on an answer that will never come.
  notApplicable,
}

extension PermissionOutcomeX on PermissionOutcome {
  bool get isGranted => this == PermissionOutcome.granted;

  /// True when the only route left is the Settings app.
  bool get needsSettings => this == PermissionOutcome.permanentlyDenied;
}

class AppPermissions {
  AppPermissions._();

  /// Cached because it costs a platform channel round-trip and the answer
  /// cannot change while the app is running.
  static int? _androidSdk;

  @visibleForTesting
  static set androidSdkForTest(int? value) => _androidSdk = value;

  static Future<int> _sdkInt() async {
    if (_androidSdk != null) return _androidSdk!;
    if (!Platform.isAndroid) return _androidSdk = 0;
    try {
      final info = await DeviceInfoPlugin().androidInfo;
      return _androidSdk = info.version.sdkInt;
    } catch (e) {
      debugPrint('[Permissions] could not read the Android version: $e');
      return _androidSdk = 33;
    }
  }

  // ─── Asking ───────────────────────────────────────────────────────────────

  /// Requests [permission], prompting if the OS still will.
  static Future<PermissionOutcome> request(AppPermission permission) async {
    final targets = await _targetsFor(permission);
    if (targets.isEmpty) return PermissionOutcome.notApplicable;

    try {
      final statuses = await targets.request();
      return _combine(statuses.values);
    } catch (e) {
      debugPrint('[Permissions] request for $permission failed: $e');
      return PermissionOutcome.denied;
    }
  }

  /// The current answer, without ever prompting.
  static Future<PermissionOutcome> status(AppPermission permission) async {
    final targets = await _targetsFor(permission);
    if (targets.isEmpty) return PermissionOutcome.notApplicable;

    try {
      final statuses = <PermissionStatus>[];
      for (final target in targets) {
        statuses.add(await target.status);
      }
      return _combine(statuses);
    } catch (e) {
      debugPrint('[Permissions] status for $permission failed: $e');
      return PermissionOutcome.denied;
    }
  }

  static Future<bool> isGranted(AppPermission permission) async =>
      (await status(permission)).isGranted;

  /// Grants-or-asks in one call, for a caller that only needs a yes/no —
  /// "can I open the camera?" rather than "why not?".
  static Future<bool> ensure(AppPermission permission) async {
    if (await isGranted(permission)) return true;
    return (await request(permission)).isGranted;
  }

  // ─── Named shorthands, so call sites read as English ──────────────────────

  static Future<bool> ensureCamera() => ensure(AppPermission.camera);
  static Future<bool> ensureMicrophone() => ensure(AppPermission.microphone);
  static Future<bool> ensureGallery() => ensure(AppPermission.gallery);
  static Future<bool> ensureContacts() => ensure(AppPermission.contacts);
  static Future<bool> ensureLocation() => ensure(AppPermission.location);
  static Future<bool> ensureBluetooth() => ensure(AppPermission.bluetooth);

  /// Both are needed before a video call can show anything or be heard.
  static Future<bool> ensureCallMedia({required bool video}) async {
    final mic = await ensureMicrophone();
    if (!video) return mic;
    final camera = await ensureCamera();
    return mic && camera;
  }

  static Future<PermissionOutcome> requestLocationAlways() async {
    if (!await isGranted(AppPermission.location)) {
      final first = await request(AppPermission.location);
      if (!first.isGranted) return first;
    }
    return request(AppPermission.locationAlways);
  }

  /// Opens this app's page in the system settings. The only way back from
  /// [PermissionOutcome.permanentlyDenied].
  static Future<bool> openSettings() async {
    try {
      return await openAppSettings();
    } catch (e) {
      debugPrint('[Permissions] could not open settings: $e');
      return false;
    }
  }

  // ─── Mapping ──────────────────────────────────────────────────────────────

  static Future<List<Permission>> _targetsFor(AppPermission permission) async {
    switch (permission) {
      case AppPermission.camera:
        return const [Permission.camera];
      case AppPermission.microphone:
        return const [Permission.microphone];
      case AppPermission.gallery:
        return _galleryPermissions(await _sdkInt(), Platform.isAndroid);
      case AppPermission.contacts:
        return const [Permission.contacts];
      case AppPermission.location:
        return const [Permission.locationWhenInUse];
      case AppPermission.locationAlways:
        return const [Permission.locationAlways];
      case AppPermission.notifications:
        if (Platform.isAndroid && await _sdkInt() < 33) return const [];
        return const [Permission.notification];
      case AppPermission.bluetooth:
        return _bluetoothPermissions(await _sdkInt(), Platform.isAndroid);
    }
  }

  @visibleForTesting
  static List<Permission> galleryPermissionsFor(
    int sdkInt, {
    bool isAndroid = true,
  }) => _galleryPermissions(sdkInt, isAndroid);

  static List<Permission> _galleryPermissions(int sdkInt, bool isAndroid) {
    if (!isAndroid) return const [Permission.photos];
    if (sdkInt >= 33) return const [Permission.photos, Permission.videos];
    return const [Permission.storage];
  }

  @visibleForTesting
  static List<Permission> bluetoothPermissionsFor(
    int sdkInt, {
    bool isAndroid = true,
  }) => _bluetoothPermissions(sdkInt, isAndroid);

  static List<Permission> _bluetoothPermissions(int sdkInt, bool isAndroid) {
    if (!isAndroid) return const [Permission.bluetooth];
    // Android 12 split it; the old one is not granted on 31+.
    if (sdkInt >= 31) {
      return const [Permission.bluetoothScan, Permission.bluetoothConnect];
    }
    return const [Permission.bluetooth];
  }

  @visibleForTesting
  static PermissionOutcome combine(Iterable<PermissionStatus> statuses) =>
      _combine(statuses);

  static PermissionOutcome _combine(Iterable<PermissionStatus> statuses) {
    if (statuses.isEmpty) return PermissionOutcome.notApplicable;
    var sawDenied = false;
    for (final status in statuses) {
      if (status.isPermanentlyDenied || status.isRestricted) {
        return PermissionOutcome.permanentlyDenied;
      }
      if (!status.isGranted && !status.isLimited) sawDenied = true;
    }
    return sawDenied ? PermissionOutcome.denied : PermissionOutcome.granted;
  }
}
