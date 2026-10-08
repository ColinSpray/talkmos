import 'dart:io';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../calls/services/call_notification_service.dart';
import '../../nearby/services/nearby_location.dart';
import '../../nearby/services/nearby_prefs.dart';
import '../widgets/permission_sheet.dart';
import 'splash_gate.dart';
import '../../../core/services/app_permissions.dart';

class StartupPermissions {
  StartupPermissions._();

  /// Once per launch. The checks are cheap but the sheets are not — a user who
  /// said "not now" must not be asked again when they tab back to Home.
  static bool _ranThisLaunch = false;

  /// When the full-screen-intent permission was last raised. A refusal has to
  /// be revisitable: without it every call rings to a dark screen.
  static const _kFullScreenIntentAskedKey = 'perm_asked_full_screen_intent_at';
  static const _kFullScreenIntentAskAgainAfter = Duration(days: 7);

  @visibleForTesting
  static void resetForTest() => _ranThisLaunch = false;

  @visibleForTesting
  static const startupPermissions = [
    AppPermission.camera,
    AppPermission.microphone,
    AppPermission.contacts,
    AppPermission.location,
  ];

  static Future<void> ensure(BuildContext context) async {
    if (_ranThisLaunch) return;
    _ranThisLaunch = true;

    await SplashGate.whenFinished;
    if (!context.mounted) return;

    await _ensureNotifications(context);
    if (!context.mounted) return;
    await _ensureFullScreenCalls(context);
    if (!context.mounted) return;
    await _requestStartupPermissions();
    if (!context.mounted) return;
    await _ensureNearbyLocation(context);
  }

  static Future<void> _requestStartupPermissions() async {
    for (final permission in startupPermissions) {
      final current = await AppPermissions.status(permission);
      if (current.isGranted || current.needsSettings) continue;
      await AppPermissions.request(permission);
    }
  }

  static Future<void> _ensureNotifications(BuildContext context) async {
    final outcome = Platform.isIOS
        ? await _requestIosNotifications()
        : await AppPermissions.request(AppPermission.notifications);

    if (!await shouldOfferSettings(outcome)) return;
    if (!context.mounted) return;

    final openSettings = await PermissionSheet.show(
      context,
      icon: Icons.notifications_off_outlined,
      title: 'Notifications are off',
      body:
          "You won't be told about new messages or incoming calls while "
          'Talkmos is closed. You can turn them back on in Settings.',
    );
    if (openSettings) await _openAppSettings();
  }

  /// Without this, Android 14+ turns an incoming call into a heads-up banner:
  /// the phone rings, the screen stays dark, and there is no call to answer
  /// until it is unlocked.
  static Future<void> _ensureFullScreenCalls(BuildContext context) async {
    if (!Platform.isAndroid) return;
    if (await CallNotificationService.canUseFullScreenIntent()) return;
    if (!await _shouldAskAgain(
      _kFullScreenIntentAskedKey,
      _kFullScreenIntentAskAgainAfter,
    )) {
      return;
    }
    if (!context.mounted) return;

    final openSettings = await PermissionSheet.show(
      context,
      icon: Icons.phone_in_talk_outlined,
      title: 'Calls can’t ring on your screen',
      body:
          'Talkmos needs permission to show full-screen notifications. '
          'Without it an incoming call only makes a sound — your screen '
          'stays off and there is nothing to answer.',
      actionLabel: 'Allow',
    );
    await _markAsked(_kFullScreenIntentAskedKey);
    if (openSettings) {
      await CallNotificationService.requestFullScreenIntentPermission();
    }
  }

  static Future<bool> _shouldAskAgain(String key, Duration after) async {
    final prefs = await SharedPreferences.getInstance();
    final askedAt = prefs.getInt(key);
    if (askedAt == null) return true;
    final since = DateTime.now().difference(
      DateTime.fromMillisecondsSinceEpoch(askedAt),
    );
    return since >= after;
  }

  static Future<void> _markAsked(String key) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(key, DateTime.now().millisecondsSinceEpoch);
  }

  @visibleForTesting
  static Future<bool> shouldOfferSettings(PermissionOutcome outcome) async {
    if (outcome.isGranted || outcome == PermissionOutcome.denied) return false;
    if (outcome == PermissionOutcome.notApplicable) {
      return !await _notificationsEnabled();
    }
    return true;
  }

  /// iOS: request through FirebaseMessaging so APNs registration happens with
  /// it, and map the answer onto the same outcomes as everything else.
  static Future<PermissionOutcome> _requestIosNotifications() async {
    try {
      final messaging = FirebaseMessaging.instance;
      var settings = await messaging.getNotificationSettings();
      if (settings.authorizationStatus == AuthorizationStatus.notDetermined) {
        settings = await messaging.requestPermission(
          alert: true,
          badge: true,
          sound: true,
          // Lets a call ring over DND.
          criticalAlert: true,
        );
      }
      return switch (settings.authorizationStatus) {
        AuthorizationStatus.authorized ||
        AuthorizationStatus.provisional => PermissionOutcome.granted,
        // iOS asks once and once only, so a refusal is already permanent.
        AuthorizationStatus.denied => PermissionOutcome.permanentlyDenied,
        AuthorizationStatus.notDetermined => PermissionOutcome.denied,
      };
    } catch (e) {
      debugPrint('[Permissions] notification request failed: $e');
      return PermissionOutcome.denied;
    }
  }

  /// Whether the OS will show this app's notifications at all — the switch
  /// that exists on every Android version, permission or not.
  static Future<bool> _notificationsEnabled() async {
    try {
      final settings = await FirebaseMessaging.instance
          .getNotificationSettings();
      return settings.authorizationStatus != AuthorizationStatus.denied;
    } catch (e) {
      debugPrint('[Permissions] notification check failed: $e');
      // Unknown is not a reason to send someone to Settings.
      return true;
    }
  }

  static Future<void> _ensureNearbyLocation(BuildContext context) async {
    if (!await NearbyPrefs.isEnabled()) return;

    // Device location switched off: Nearby stays quiet rather than opening a
    // sheet about it on the way into the app.
    if (!await NearbyLocation.serviceEnabled()) return;

    if (!await NearbyLocation.hasPermission()) {
      if (!await NearbyLocation.requestPermission()) {
        if (!context.mounted) return;
        final openSettings = await PermissionSheet.show(
          context,
          icon: Icons.lock_outline_rounded,
          title: 'Nearby needs location',
          body:
              'Without it Nearby cannot work out who is close by, so nobody '
              'will appear. Your exact position is never shown to anyone.',
        );
        if (openSettings) await NearbyLocation.openSettings();
      }
    }
  }

  /// Opens this app's page in system settings, through the same service every
  /// other permission goes through.
  static Future<void> _openAppSettings() => AppPermissions.openSettings();
}
