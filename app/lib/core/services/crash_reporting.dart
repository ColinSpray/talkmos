import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';

class CrashReporting {
  CrashReporting._();

  static bool _ready = false;

  static bool get isReady => _ready;

  static Future<void> initialize({bool forceEnable = false}) async {
    final collect = forceEnable || !kDebugMode;

    try {
      await FirebaseCrashlytics.instance.setCrashlyticsCollectionEnabled(
        collect,
      );
      _ready = collect;
    } catch (e) {
      // Firebase missing or misconfigured. Leave the handlers uninstalled and
      // let the app carry on rather than dying at startup over telemetry.
      debugPrint('Crashlytics could not be enabled: $e');
      return;
    }

    // Errors the Flutter framework catches — failed builds, layout overflows
    // that throw, bad state in a widget lifecycle.
    final previousOnError = FlutterError.onError;
    FlutterError.onError = (details) {
      previousOnError?.call(details);
      if (!_ready || !isWorthReporting(details)) return;
      FirebaseCrashlytics.instance.recordFlutterFatalError(details);
    };

    PlatformDispatcher.instance.onError = (error, stack) {
      if (_ready) {
        FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
      }
      // Handled — returning false rethrows and takes the process down.
      return true;
    };
  }

  /// Whether a framework error says anything about this app. A remote image
  /// that 404s arrives here too, and would land as a fatal crash it never was.
  @visibleForTesting
  static bool isWorthReporting(FlutterErrorDetails details) =>
      details.library != 'image resource service';

  static Future<void> recordError(
    Object error,
    StackTrace? stack, {
    String? reason,
    bool fatal = false,
  }) async {
    if (!_ready) return;
    try {
      await FirebaseCrashlytics.instance.recordError(
        error,
        stack,
        reason: reason,
        fatal: fatal,
      );
    } catch (e) {
      debugPrint('Could not record error to Crashlytics: $e');
    }
  }

  /// Adds a breadcrumb to the next report — the trail of what the user was
  /// doing before a crash is usually worth more than the stack trace alone.
  static Future<void> log(String message) async {
    if (!_ready) return;
    try {
      await FirebaseCrashlytics.instance.log(message);
    } catch (e) {
      debugPrint('Could not log to Crashlytics: $e');
    }
  }

  /// Attaches a value shown on every subsequent report.
  static Future<void> setCustomKey(String key, Object value) async {
    if (!_ready) return;
    try {
      await FirebaseCrashlytics.instance.setCustomKey(key, value);
    } catch (e) {
      debugPrint('Could not set a Crashlytics key: $e');
    }
  }

  @visibleForTesting
  static void resetForTest() => _ready = false;
}
