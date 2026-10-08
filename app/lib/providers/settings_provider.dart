import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../core/services/data_usage_store.dart';
import '../core/services/media_visibility_store.dart';

class SettingsProvider extends ChangeNotifier {
  static const String _keyThemeMode = 'settings_theme_mode';
  static const String _keyPrimaryColor = 'settings_primary_color';
  static const String _keyChatWallpaperColor = 'settings_chat_wallpaper_color';
  static const String _keyShowDoodles = 'settings_show_doodles';
  static const String _keyChatWallpaperImagePath =
      'settings_chat_wallpaper_image_path';
  static const String _keyChatWallpaperOpacity =
      'settings_chat_wallpaper_opacity';

  static const String _keyReceiveNotifications =
      'settings_receive_notifications';
  static const String _keyNotificationAudio = 'settings_notification_audio';
  static const String _keyVibrate = 'settings_vibrate';
  static const String _keyShowPreview = 'settings_show_preview';

  // Privacy states
  static const String _keyReadReceipts = 'settings_read_receipts';
  static const String _keyLastSeenVisibility = 'settings_last_seen_visibility';
  static const String _keyProfilePhotoVisibility =
      'settings_profile_photo_visibility';

  ThemeMode _themeMode;
  Color _primaryColor = const Color(
    0xFF0266FA,
  ); // Default Talkmos primary (#0266fa)
  Color _chatWallpaperColor = const Color(
    0xFFFAF9FF,
  ); // Default Chat Background Color
  bool _showDoodles = true;
  String? _chatWallpaperImagePath;
  double _chatWallpaperOpacity = 0.4;

  bool _receiveNotifications = true;
  String _notificationAudio = 'default';
  bool _vibrate = true;
  bool _showPreview = true;

  bool _readReceipts = true;
  String _lastSeenVisibility = 'Everyone'; // Everyone, Contacts, Nobody
  String _profilePhotoVisibility = 'Everyone'; // Everyone, Contacts, Nobody

  bool get saveToPhotos => MediaVisibilityStore.instance.saveToPhotos;

  // Data and Storage. Owned by [DataUsageStore] for the same reason: the media
  // picker and the receive path both need these without a BuildContext.
  MediaUploadQuality get mediaUploadQuality =>
      DataUsageStore.instance.uploadQuality;
  bool get autoSaveWifiOnly => DataUsageStore.instance.autoSaveWifiOnly;

  // Getters
  ThemeMode get themeMode => _themeMode;
  Color get primaryColor => _primaryColor;
  Color get chatWallpaperColor => _chatWallpaperColor;
  bool get showDoodles => _showDoodles;
  String? get chatWallpaperImagePath => _chatWallpaperImagePath;
  double get chatWallpaperOpacity => _chatWallpaperOpacity;

  bool get receiveNotifications => _receiveNotifications;
  String get notificationAudio => _notificationAudio;
  bool get vibrate => _vibrate;
  bool get showPreview => _showPreview;

  bool get readReceipts => _readReceipts;
  String get lastSeenVisibility => _lastSeenVisibility;
  String get profilePhotoVisibility => _profilePhotoVisibility;

  SettingsProvider({ThemeMode? initialThemeMode})
    : _themeMode = initialThemeMode ?? ThemeMode.light {
    _loadSettings();
  }

  static Future<ThemeMode> loadPersistedThemeMode() async {
    final prefs = await SharedPreferences.getInstance();
    final themeIndex = prefs.getInt(_keyThemeMode);
    return themeIndex != null ? ThemeMode.values[themeIndex] : ThemeMode.light;
  }

  Future<void> _loadSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // Theme Mode
      final themeIndex = prefs.getInt(_keyThemeMode);
      if (themeIndex != null) {
        _themeMode = ThemeMode.values[themeIndex];
      }

      // Colors (saved as ARGB ints)
      final primaryVal = prefs.getInt(_keyPrimaryColor);
      if (primaryVal != null) {
        _primaryColor = Color(primaryVal);
      }

      final wallpaperVal = prefs.getInt(_keyChatWallpaperColor);
      if (wallpaperVal != null) {
        _chatWallpaperColor = Color(wallpaperVal);
      } else {
        // Fallback wallpaper matching default theme mode brightness
        _chatWallpaperColor = _themeMode == ThemeMode.dark
            ? const Color(0xFF000000)
            : const Color(0xFFFAF9FF);
      }

      _showDoodles = prefs.getBool(_keyShowDoodles) ?? true;
      _chatWallpaperImagePath = prefs.getString(_keyChatWallpaperImagePath);
      _chatWallpaperOpacity = prefs.getDouble(_keyChatWallpaperOpacity) ?? 0.4;

      // Notifications
      _receiveNotifications = prefs.getBool(_keyReceiveNotifications) ?? true;
      _notificationAudio = prefs.getString(_keyNotificationAudio) ?? 'default';
      _vibrate = prefs.getBool(_keyVibrate) ?? true;
      _showPreview = prefs.getBool(_keyShowPreview) ?? true;

      // Privacy preferences
      _readReceipts = prefs.getBool(_keyReadReceipts) ?? true;
      _lastSeenVisibility =
          prefs.getString(_keyLastSeenVisibility) ?? 'Everyone';
      _profilePhotoVisibility =
          prefs.getString(_keyProfilePhotoVisibility) ?? 'Everyone';

      // Media visibility (global switch + per-chat overrides). Loaded here so
      // the receive path can consult it without waiting on a first read.
      await MediaVisibilityStore.instance.load();

      // Data and Storage — loaded here so the media picker and the receive
      // path see the user's choices rather than the defaults.
      await DataUsageStore.instance.load();

      notifyListeners();
    } catch (e) {
      debugPrint('Failed to load settings: $e');
    }
  }

  // Setters
  Future<void> setThemeMode(ThemeMode mode) async {
    _themeMode = mode;
    // Set fallback wallpaper color if not customized yet
    final prefs = await SharedPreferences.getInstance();
    if (prefs.getInt(_keyChatWallpaperColor) == null) {
      _chatWallpaperColor = mode == ThemeMode.dark
          ? const Color(0xFF000000)
          : const Color(0xFFFAF9FF);
    }
    notifyListeners();
    await prefs.setInt(_keyThemeMode, mode.index);
  }

  Future<void> toggleThemeMode() async {
    final newMode = _themeMode == ThemeMode.dark
        ? ThemeMode.light
        : ThemeMode.dark;
    await setThemeMode(newMode);
  }

  Future<void> setPrimaryColor(Color color) async {
    _primaryColor = color;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_keyPrimaryColor, color.toARGB32());
  }

  Future<void> setChatWallpaperColor(Color color) async {
    _chatWallpaperColor = color;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_keyChatWallpaperColor, color.toARGB32());
  }

  Future<void> setShowDoodles(bool value) async {
    _showDoodles = value;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyShowDoodles, value);
  }

  Future<void> setReceiveNotifications(bool value) async {
    _receiveNotifications = value;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyReceiveNotifications, value);
  }

  Future<void> setNotificationAudio(String tone) async {
    _notificationAudio = tone;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyNotificationAudio, tone);
  }

  Future<void> setVibrate(bool value) async {
    _vibrate = value;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyVibrate, value);
  }

  Future<void> setShowPreview(bool value) async {
    _showPreview = value;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyShowPreview, value);
  }

  Future<void> setReadReceipts(bool value) async {
    _readReceipts = value;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyReadReceipts, value);
  }

  Future<void> setLastSeenVisibility(String val) async {
    _lastSeenVisibility = val;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyLastSeenVisibility, val);
  }

  Future<void> setProfilePhotoVisibility(String val) async {
    _profilePhotoVisibility = val;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyProfilePhotoVisibility, val);
  }

  /// Turns the global "Save to Photos" switch on or off. Per-chat overrides
  /// are unaffected — a chat set to Never stays Never after this.
  Future<void> setSaveToPhotos(bool value) async {
    await MediaVisibilityStore.instance.setSaveToPhotos(value);
    notifyListeners();
  }

  Future<void> setMediaUploadQuality(MediaUploadQuality value) async {
    await DataUsageStore.instance.setUploadQuality(value);
    notifyListeners();
  }

  Future<void> setAutoSaveWifiOnly(bool value) async {
    await DataUsageStore.instance.setAutoSaveWifiOnly(value);
    notifyListeners();
  }

  Future<void> setChatWallpaperImagePath(String? path) async {
    _chatWallpaperImagePath = path;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    if (path != null) {
      await prefs.setString(_keyChatWallpaperImagePath, path);
    } else {
      await prefs.remove(_keyChatWallpaperImagePath);
    }
  }

  Future<void> setChatWallpaperOpacity(double val) async {
    _chatWallpaperOpacity = val;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(_keyChatWallpaperOpacity, val);
  }
}
