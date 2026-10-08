import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:in_app_update/in_app_update.dart';

class AppUpdateService {
  const AppUpdateService._();

  /// Starts a background download if Play has a newer build. Returns whether
  /// there was one — the manual check reports "you're up to date" on false.
  static Future<bool> startIfAvailable() async {
    if (!Platform.isAndroid) return false;
    try {
      final info = await InAppUpdate.checkForUpdate();
      if (info.updateAvailability != UpdateAvailability.updateAvailable) {
        return false;
      }
      if (!info.flexibleUpdateAllowed) {
        debugPrint('[AppUpdate] Play offers no flexible update for this build');
        return false;
      }

      // Play puts up its own consent sheet; this completes once the download
      // has finished, and reports a refusal rather than throwing.
      final result = await InAppUpdate.startFlexibleUpdate();
      if (result != AppUpdateResult.success) {
        debugPrint('[AppUpdate] flexible update did not run: $result');
        return false;
      }
      return true;
    } catch (e) {
      // Not installed from Play, no Play services, offline — none of it is
      // worth a word to the user.
      debugPrint('[AppUpdate] check failed: $e');
      return false;
    }
  }

  /// Installs what was downloaded, which restarts the app.
  static Future<void> install() async {
    if (!Platform.isAndroid) return;
    try {
      await InAppUpdate.completeFlexibleUpdate();
    } catch (e) {
      debugPrint('[AppUpdate] install failed: $e');
    }
  }
}
