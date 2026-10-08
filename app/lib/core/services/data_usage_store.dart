import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum MediaUploadQuality {
  dataSaver(65, 'Data saver'),
  standard(85, 'Standard'),
  high(95, 'High');

  const MediaUploadQuality(this.imageQuality, this.label);

  final int imageQuality;
  final String label;

  static MediaUploadQuality fromName(String? name) {
    return MediaUploadQuality.values.firstWhere(
      (q) => q.name == name,
      orElse: () => MediaUploadQuality.standard,
    );
  }
}

class DataUsageStore {
  DataUsageStore._();
  static final DataUsageStore instance = DataUsageStore._();

  static const String keyUploadQuality = 'settings_media_upload_quality';
  static const String keyAutoSaveWifiOnly = 'settings_auto_save_wifi_only';

  /// Injectable so tests can drive the network state instead of the device's.
  @visibleForTesting
  Future<List<ConnectivityResult>> Function() checkConnectivity =
      Connectivity().checkConnectivity;

  MediaUploadQuality _uploadQuality = MediaUploadQuality.standard;

  bool _autoSaveWifiOnly = true;

  bool _loaded = false;
  Future<void>? _loading;

  MediaUploadQuality get uploadQuality => _uploadQuality;
  bool get autoSaveWifiOnly => _autoSaveWifiOnly;

  /// `imageQuality` to hand to `image_picker`.
  int get imageQuality => _uploadQuality.imageQuality;

  Future<void> load() {
    if (_loaded) return Future.value();
    return _loading ??= _load();
  }

  Future<void> _load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _uploadQuality = MediaUploadQuality.fromName(
        prefs.getString(keyUploadQuality),
      );
      _autoSaveWifiOnly = prefs.getBool(keyAutoSaveWifiOnly) ?? true;
      _loaded = true;
    } catch (e) {
      // Defaults stand. Both of them are the cheaper option, so a failed read
      // can't quietly start spending more of someone's data.
      debugPrint('Failed to load data usage settings: $e');
    } finally {
      _loading = null;
    }
  }

  Future<void> setUploadQuality(MediaUploadQuality value) async {
    _uploadQuality = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(keyUploadQuality, value.name);
  }

  Future<void> setAutoSaveWifiOnly(bool value) async {
    _autoSaveWifiOnly = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(keyAutoSaveWifiOnly, value);
  }

  Future<bool> canAutoDownloadNow() async {
    if (!_autoSaveWifiOnly) return true;
    try {
      final result = await checkConnectivity();
      return result.contains(ConnectivityResult.wifi) ||
          result.contains(ConnectivityResult.ethernet);
    } catch (e) {
      debugPrint('Connectivity check failed, treating as metered: $e');
      return false;
    }
  }

  @visibleForTesting
  void reset() {
    _uploadQuality = MediaUploadQuality.standard;
    _autoSaveWifiOnly = true;
    _loaded = false;
  }
}
