import 'package:flutter/foundation.dart';
import 'package:gal/gal.dart';

class GallerySaveService {
  GallerySaveService._();
  static final GallerySaveService instance = GallerySaveService._();

  /// Album that received media is filed under, so it stays separable from the
  /// user's own camera photos.
  static const String albumName = 'Talkmos';

  /// True once the user has granted gallery-write access, without prompting.
  Future<bool> hasAccess() async {
    try {
      return await Gal.hasAccess(toAlbum: true);
    } on GalException catch (e) {
      debugPrint('Gallery access check failed: ${e.type.message}');
      return false;
    }
  }

  Future<bool> requestAccess() async {
    try {
      return await Gal.requestAccess(toAlbum: true);
    } on GalException catch (e) {
      debugPrint('Gallery access request failed: ${e.type.message}');
      return false;
    }
  }

  Future<bool> save({required String path, required bool isVideo}) async {
    try {
      if (!await hasAccess()) return false;

      if (isVideo) {
        await Gal.putVideo(path, album: albumName);
      } else {
        await Gal.putImage(path, album: albumName);
      }
      return true;
    } on GalException catch (e) {
      debugPrint('Gallery save failed (${e.type.name}): ${e.type.message}');
      return false;
    } catch (e) {
      debugPrint('Gallery save failed: $e');
      return false;
    }
  }
}
