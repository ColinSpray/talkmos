import 'package:shared_preferences/shared_preferences.dart';

class NearbyPrefs {
  const NearbyPrefs._();

  static const _key = 'nearby_enabled';

  static Future<bool> isEnabled() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getBool(_key) ?? false;
    } catch (_) {
      return false;
    }
  }

  static Future<void> setEnabled(bool value) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_key, value);
    } catch (_) {
      // Best effort: the server stays the source of truth, and a drifted flag
      // costs at most one wasted wake or one skipped prompt.
    }
  }
}
