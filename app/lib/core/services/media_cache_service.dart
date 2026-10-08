import 'dart:io';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

class MediaCacheService {
  static final MediaCacheService _instance = MediaCacheService._internal();
  factory MediaCacheService() => _instance;
  MediaCacheService._internal();

  static const String _cacheKey = 'talkmosMediaCache';
  static const Duration _stalePeriod = Duration(days: 30);
  static const int _maxObjects = 500;

  /// Shared cache manager — construct once and reuse everywhere so every
  /// caller reads and writes the same bounded store.
  static final CacheManager manager = CacheManager(
    Config(
      _cacheKey,
      stalePeriod: _stalePeriod,
      maxNrOfCacheObjects: _maxObjects,
    ),
  );

  Future<File> getCachedFile(String url, {String? fileName}) async {
    if (url.isEmpty) throw ArgumentError('URL cannot be empty');
    final file = await manager.getSingleFile(url, key: fileName ?? url);
    return File(file.path);
  }

  /// True if [url] is already on disk, without triggering a download —
  /// lets a caller skip a loading spinner before starting playback.
  Future<bool> isFileCached(String url, {String? fileName}) async {
    if (url.isEmpty) return false;
    final info = await manager.getFileFromCache(fileName ?? url);
    return info != null;
  }

  /// Total bytes currently on disk across every cached media file.
  Future<int> getCacheSize() async {
    final baseDir = await getTemporaryDirectory();
    final cacheDir = Directory(p.join(baseDir.path, _cacheKey));
    if (!await cacheDir.exists()) return 0;
    var total = 0;
    await for (final entity in cacheDir.list(recursive: true)) {
      if (entity is File) total += await entity.length();
    }
    return total;
  }

  /// Wipes every cached media file — every image routed through [manager],
  /// plus every cached voice note and video.
  Future<void> clearCache() => manager.emptyCache();
}
