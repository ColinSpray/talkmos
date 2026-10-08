import 'package:flutter/material.dart';

/// A wallpaper that ships with the app, as opposed to one the user picked
/// from their gallery.
class ChatWallpaper {
  final String id;
  final String name;
  final String assetPath;

  final Color backdropColor;

  /// Whether the artwork is designed for dark mode. Used to surface the
  /// matching set first rather than to restrict the choice.
  final bool isDark;

  const ChatWallpaper({
    required this.id,
    required this.name,
    required this.assetPath,
    required this.backdropColor,
    required this.isDark,
  });
}

class ChatWallpapers {
  const ChatWallpapers._();

  static const String _dir = 'assets/wallpapers';

  static const List<ChatWallpaper> all = [
    ChatWallpaper(
      id: 'cosmic',
      name: 'Cosmic',
      assetPath: '$_dir/cosmic_dark.png',
      backdropColor: Color(0xFF0B1023),
      isDark: true,
    ),
    ChatWallpaper(
      id: 'forest',
      name: 'Forest',
      assetPath: '$_dir/forest_dark.png',
      backdropColor: Color(0xFF061309),
      isDark: true,
    ),
    ChatWallpaper(
      id: 'rhythm',
      name: 'Rhythm',
      assetPath: '$_dir/rhythm_dark.png',
      backdropColor: Color(0xFF16040F),
      isDark: true,
    ),
    ChatWallpaper(
      id: 'breeze',
      name: 'Breeze',
      assetPath: '$_dir/breeze_light.png',
      backdropColor: Color(0xFFF7FBFF),
      isDark: false,
    ),
    ChatWallpaper(
      id: 'lavender',
      name: 'Lavender',
      assetPath: '$_dir/lavender_light.png',
      backdropColor: Color(0xFFF6F0FE),
      isDark: false,
    ),
  ];

  /// Bundled wallpapers ordered so the ones suiting [isDarkMode] come first.
  static List<ChatWallpaper> orderedFor({required bool isDarkMode}) {
    final matching = all.where((w) => w.isDark == isDarkMode);
    final rest = all.where((w) => w.isDark != isDarkMode);
    return [...matching, ...rest];
  }

  /// True when [path] refers to a bundled asset rather than a file on disk.
  /// Callers use this to choose between `Image.asset` and `Image.file`.
  static bool isBundledWallpaper(String path) => path.startsWith('$_dir/');

  static ChatWallpaper? byAssetPath(String? path) {
    if (path == null) return null;
    for (final wallpaper in all) {
      if (wallpaper.assetPath == path) return wallpaper;
    }
    return null;
  }
}
