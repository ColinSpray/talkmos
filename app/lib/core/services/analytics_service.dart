import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter/foundation.dart';

class AnalyticsService {
  AnalyticsService._();

  static bool _ready = false;

  static final FirebaseAnalyticsObserver observer = FirebaseAnalyticsObserver(
    analytics: FirebaseAnalytics.instance,
  );

  static Future<void> initialize({bool forceEnable = false}) async {
    final collect = forceEnable || !kDebugMode;
    try {
      await FirebaseAnalytics.instance.setAnalyticsCollectionEnabled(collect);
      _ready = collect;
    } catch (e) {
      debugPrint('Firebase Analytics could not be enabled: $e');
    }
  }

  /// Logs a custom event with optional parameters.
  static Future<void> logEvent(
    String name, {
    Map<String, Object>? parameters,
  }) async {
    if (!_ready) return;
    try {
      await FirebaseAnalytics.instance.logEvent(
        name: name,
        parameters: parameters,
      );
    } catch (e) {
      debugPrint('Could not log analytics event "$name": $e');
    }
  }

  /// Associates subsequent events with a signed-in user, or clears the
  /// association on sign-out when [userId] is null.
  static Future<void> setUserId(String? userId) async {
    if (!_ready) return;
    try {
      await FirebaseAnalytics.instance.setUserId(id: userId);
    } catch (e) {
      debugPrint('Could not set analytics user id: $e');
    }
  }

  @visibleForTesting
  static void resetForTest() => _ready = false;
}
