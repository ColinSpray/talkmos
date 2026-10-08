import 'package:shared_preferences/shared_preferences.dart';

class TokenManager {
  static String? _token;

  /// Retrieve the current global authentication token.
  static String? get token => _token;

  /// Set the global authentication token synchronously (schedules disk write in background).
  static set token(String? value) {
    _token = value;
    SharedPreferences.getInstance().then((prefs) {
      if (value != null) {
        prefs.setString('auth_token', value);
      } else {
        prefs.remove('auth_token');
      }
    });
  }

  /// Initialize the TokenManager by loading the token from SharedPreferences.
  static Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    _token = prefs.getString('auth_token');
  }

  /// Set the global authentication token and persist it asynchronously.
  static Future<void> setToken(String? value) async {
    _token = value;
    final prefs = await SharedPreferences.getInstance();
    if (value != null) {
      await prefs.setString('auth_token', value);
    } else {
      await prefs.remove('auth_token');
    }
  }

  /// Clear the global authentication token.
  static Future<void> clear() async {
    await setToken(null);
  }
}
