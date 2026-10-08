import 'package:flutter/material.dart';
import 'package:talkmos/l10n/gen/app_localizations.dart';
import '../data/chat_wallpapers.dart';

/// Horizontal strip of the wallpapers bundled with the app, plus a "None"
/// option that clears the current selection.
class WallpaperGalleryPicker extends StatelessWidget {
  /// Currently selected wallpaper path — bundled asset, gallery file, or null.
  final String? selectedPath;
  final bool isDarkMode;
  final Color accentColor;

  /// Fires with the chosen asset path, or null for "None".
  final ValueChanged<String?> onSelected;

  const WallpaperGalleryPicker({
    super.key,
    required this.selectedPath,
    required this.isDarkMode,
    required this.accentColor,
    required this.onSelected,
  });

  static const double _tileWidth = 68;
  static const double _tileHeight = 104;

  @override
  Widget build(BuildContext context) {
    final wallpapers = ChatWallpapers.orderedFor(isDarkMode: isDarkMode);

    return SizedBox(
      height: _tileHeight + 26,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(vertical: 2),
        itemCount: wallpapers.length + 1,
        separatorBuilder: (_, __) => const SizedBox(width: 10),
        itemBuilder: (context, index) {
          if (index == 0) {
            return _WallpaperTile(
              label: AppLocalizations.of(context).wallpaperPickerNone,
              isSelected: selectedPath == null,
              accentColor: accentColor,
              onTap: () => onSelected(null),
              child: Container(
                color: isDarkMode
                    ? const Color(0xFF000814)
                    : const Color(0xFFF1F5F9),
                child: Icon(
                  Icons.block_rounded,
                  size: 22,
                  color: isDarkMode ? Colors.white38 : const Color(0xFF94A3B8),
                ),
              ),
            );
          }

          final wallpaper = wallpapers[index - 1];
          return _WallpaperTile(
            label: wallpaper.name,
            isSelected: selectedPath == wallpaper.assetPath,
            accentColor: accentColor,
            onTap: () => onSelected(wallpaper.assetPath),
            child: Image.asset(
              wallpaper.assetPath,
              fit: BoxFit.cover,
              // Thumbnails only need a fraction of the source resolution.
              cacheWidth: 160,
              errorBuilder: (_, __, ___) =>
                  Container(color: wallpaper.backdropColor),
            ),
          );
        },
      ),
    );
  }
}

class _WallpaperTile extends StatelessWidget {
  final String label;
  final bool isSelected;
  final Color accentColor;
  final VoidCallback onTap;
  final Widget child;

  const _WallpaperTile({
    required this.label,
    required this.isSelected,
    required this.accentColor,
    required this.onTap,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: WallpaperGalleryPicker._tileWidth,
            height: WallpaperGalleryPicker._tileHeight,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isSelected ? accentColor : Colors.black12,
                width: isSelected ? 2.5 : 1,
              ),
            ),
            clipBehavior: Clip.antiAlias,
            child: Stack(
              fit: StackFit.expand,
              children: [
                child,
                if (isSelected)
                  Align(
                    alignment: Alignment.bottomRight,
                    child: Container(
                      margin: const EdgeInsets.all(4),
                      padding: const EdgeInsets.all(2),
                      decoration: BoxDecoration(
                        color: accentColor,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.check_rounded,
                        size: 12,
                        color: Colors.white,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 5),
          SizedBox(
            width: WallpaperGalleryPicker._tileWidth,
            child: Text(
              label,
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 11,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                color: isSelected ? accentColor : null,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
