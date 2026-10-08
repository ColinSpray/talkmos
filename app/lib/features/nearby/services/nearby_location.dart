import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';

class NearbyLocation {
  NearbyLocation._();

  static const LocationAccuracy _accuracy = LocationAccuracy.low;

  /// Bounded so a cold fix indoors, where this feature is most used, cannot
  /// leave the caller hanging.
  static const Duration _timeout = Duration(seconds: 10);

  static Future<Position?> current() async {
    try {
      if (!await Geolocator.isLocationServiceEnabled()) return null;

      final permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        return null;
      }

      return await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: _accuracy,
          timeLimit: _timeout,
        ),
      );
    } catch (e) {
      debugPrint('[Nearby] location unavailable: $e');
      return null;
    }
  }

  static Future<Position?> lastKnown() async {
    try {
      if (!await hasPermission()) return null;
      return await Geolocator.getLastKnownPosition();
    } catch (e) {
      debugPrint('[Nearby] last known position unavailable: $e');
      return null;
    }
  }

  static Future<bool> serviceEnabled() async {
    try {
      return await Geolocator.isLocationServiceEnabled();
    } catch (e) {
      debugPrint('[Nearby] location service check failed: $e');
      return false;
    }
  }

  /// Checks without prompting, so opening the screen never puts a dialog in
  /// front of someone who has already refused.
  static Future<bool> hasPermission() async {
    try {
      final permission = await Geolocator.checkPermission();
      return permission == LocationPermission.always ||
          permission == LocationPermission.whileInUse;
    } catch (e) {
      debugPrint('[Nearby] permission check failed: $e');
      return false;
    }
  }

  static Future<bool> canPrompt() async {
    try {
      return await Geolocator.checkPermission() !=
          LocationPermission.deniedForever;
    } catch (e) {
      debugPrint('[Nearby] prompt availability check failed: $e');
      return false;
    }
  }

  static Future<void> openSettings() async {
    try {
      await Geolocator.openAppSettings();
    } catch (e) {
      debugPrint('[Nearby] could not open settings: $e');
    }
  }

  /// Asks for permission, for the one place it should be asked: the moment
  /// the user turns Nearby on and is being told what it does.
  static Future<bool> requestPermission() async {
    try {
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      return permission == LocationPermission.always ||
          permission == LocationPermission.whileInUse;
    } catch (e) {
      debugPrint('[Nearby] permission request failed: $e');
      return false;
    }
  }
}
