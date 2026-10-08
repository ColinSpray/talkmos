import 'dart:io';
import 'package:flutter/material.dart';
import '../data/chat_wallpapers.dart';

/// Renders the selected chat wallpaper, transparently handling both bundled
/// assets and images the user picked from their gallery.
class ChatWallpaperImage extends StatelessWidget {
  /// Either an `assets/wallpapers/...` path or an absolute file path.
  final String path;
  final double opacity;
  final BoxFit fit;

  const ChatWallpaperImage({
    super.key,
    required this.path,
    this.opacity = 1.0,
    this.fit = BoxFit.cover,
  });

  @override
  Widget build(BuildContext context) {
    final isBundled = ChatWallpapers.isBundledWallpaper(path);

    return Opacity(
      opacity: opacity,
      child: isBundled
          ? Image.asset(path, fit: fit, errorBuilder: _onError)
          : Image.file(File(path), fit: fit, errorBuilder: _onError),
    );
  }

  /// A wallpaper that fails to load (deleted gallery file, missing asset)
  /// should just fall away rather than break the chat background.
  static Widget _onError(BuildContext _, Object __, StackTrace? ___) =>
      const SizedBox.shrink();
}
