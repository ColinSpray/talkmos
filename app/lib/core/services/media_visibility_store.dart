import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite/sqflite.dart';

import '../database/database_helper.dart';

enum MediaVisibility {
  /// Defer to the global "Save to Photos" switch.
  followGlobal,

  /// Always save this chat's incoming photos and videos, even with the
  /// global switch off.
  always,

  /// Never save this chat's incoming photos and videos, even with the
  /// global switch on.
  never,
}

class MediaVisibilityStore {
  MediaVisibilityStore._();
  static final MediaVisibilityStore instance = MediaVisibilityStore._();

  /// Shared with [SettingsProvider], which reads and writes it through this
  /// class rather than touching the key itself.
  static const String keySaveToPhotos = 'settings_save_to_photos';

  final DatabaseHelper _db = DatabaseHelper.instance;

  bool _saveToPhotos = false;

  final Map<String, MediaVisibility> _overrides = {};

  bool _loaded = false;
  Future<void>? _loading;

  bool _overridesLoaded = false;

  /// True if the global switch is on. Only meaningful after [load].
  bool get saveToPhotos => _saveToPhotos;

  Future<void> load() {
    if (_loaded) return Future.value();
    return _loading ??= _load();
  }

  Future<void> _load() async {
    var globalOk = false;
    try {
      final prefs = await SharedPreferences.getInstance();
      _saveToPhotos = prefs.getBool(keySaveToPhotos) ?? false;
      globalOk = true;
    } catch (e) {
      // Leave it off. A failed read must not start writing to the gallery.
      _saveToPhotos = false;
      debugPrint('Failed to load the Save to Photos setting: $e');
    }

    try {
      final db = await _db.database;
      final rows = await db.query(DatabaseHelper.tableChatPrefs);
      _overrides.clear();
      for (final row in rows) {
        final chatId = row[DatabaseHelper.colChatPrefChatId] as String?;
        final raw = row[DatabaseHelper.colChatPrefMediaVisibility] as int?;
        if (chatId == null || chatId.isEmpty || raw == null) continue;
        _overrides[chatId] = raw == 1
            ? MediaVisibility.always
            : MediaVisibility.never;
      }
      _overridesLoaded = true;
    } catch (e) {
      // An unknown override set can't be treated as "no overrides" — see
      // [_overridesLoaded]. Nothing saves until this read succeeds.
      _overrides.clear();
      _overridesLoaded = false;
      debugPrint('Failed to load per-chat media visibility: $e');
    }

    _loaded = globalOk && _overridesLoaded;
    _loading = null;
  }

  /// The chat's own setting, independent of the global switch.
  MediaVisibility visibilityFor(String chatId) =>
      _overrides[chatId] ?? MediaVisibility.followGlobal;

  bool shouldSaveFor(String chatId) {
    // Without a complete override set there's no way to tell an un-overridden
    // chat from one set to Never, so don't save either.
    if (!_overridesLoaded) return false;

    switch (visibilityFor(chatId)) {
      case MediaVisibility.always:
        return true;
      case MediaVisibility.never:
        return false;
      case MediaVisibility.followGlobal:
        return _saveToPhotos;
    }
  }

  Future<void> setSaveToPhotos(bool value) async {
    _saveToPhotos = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(keySaveToPhotos, value);
  }

  Future<void> setVisibilityFor(String chatId, MediaVisibility value) async {
    if (chatId.isEmpty) return;

    if (value == MediaVisibility.followGlobal) {
      _overrides.remove(chatId);
    } else {
      _overrides[chatId] = value;
    }

    try {
      final db = await _db.database;
      if (value == MediaVisibility.followGlobal) {
        await db.delete(
          DatabaseHelper.tableChatPrefs,
          where: '${DatabaseHelper.colChatPrefChatId} = ?',
          whereArgs: [chatId],
        );
      } else {
        await db.insert(DatabaseHelper.tableChatPrefs, {
          DatabaseHelper.colChatPrefChatId: chatId,
          DatabaseHelper.colChatPrefMediaVisibility:
              value == MediaVisibility.always ? 1 : 0,
        }, conflictAlgorithm: ConflictAlgorithm.replace);
      }
    } catch (e) {
      debugPrint('Failed to save media visibility for $chatId: $e');
    }
  }

  void reset() {
    _overrides.clear();
    _overridesLoaded = false;
    _loaded = false;
  }
}
