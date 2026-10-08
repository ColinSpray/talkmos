import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../translation/app_language.dart';

class TranslationPreferenceStore {
  TranslationPreferenceStore._();
  static final TranslationPreferenceStore instance =
      TranslationPreferenceStore._();

  static const String _keyTargetLanguage =
      'settings_translation_target_language';

  AppLanguage? _targetLanguage;
  bool _loaded = false;
  Future<void>? _loading;

  AppLanguage? get targetLanguage => _targetLanguage;

  Future<void> load() {
    if (_loaded) return Future.value();
    return _loading ??= _load();
  }

  Future<void> _load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final name = prefs.getString(_keyTargetLanguage);
      for (final language in AppLanguage.values) {
        if (language.name == name) {
          _targetLanguage = language;
          break;
        }
      }
      _loaded = true;
    } catch (e) {
      debugPrint('Failed to load translation preference: $e');
    } finally {
      _loading = null;
    }
  }

  Future<void> setTargetLanguage(AppLanguage language) async {
    _targetLanguage = language;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyTargetLanguage, language.name);
  }
}
