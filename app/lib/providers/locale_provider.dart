import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LocaleProvider extends ChangeNotifier {
  static const _prefsKey = 'settings_locale';

  static const List<Locale> supportedLocales = [
    Locale('en'),
    Locale('hi'),
    Locale('bn'),
  ];

  Locale? _locale;
  Locale? get locale => _locale;

  LocaleProvider() {
    _load();
  }

  Future<void> _load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final code = prefs.getString(_prefsKey);
      if (code != null && code.isNotEmpty) {
        final match = supportedLocales.where((l) => l.languageCode == code);
        if (match.isNotEmpty) {
          _locale = match.first;
          notifyListeners();
        }
      }
    } catch (e) {
      debugPrint('[Locale] load failed: $e');
    }
  }

  /// Sets the language, or pass null to go back to following the device.
  Future<void> setLocale(Locale? locale) async {
    _locale = locale;
    notifyListeners();
    try {
      final prefs = await SharedPreferences.getInstance();
      if (locale == null) {
        await prefs.remove(_prefsKey);
      } else {
        await prefs.setString(_prefsKey, locale.languageCode);
      }
    } catch (e) {
      debugPrint('[Locale] save failed: $e');
    }
  }
}
