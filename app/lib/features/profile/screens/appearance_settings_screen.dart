import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import '../../../core/utils/image_picker_utils.dart';
import '../../../providers/settings_provider.dart';
import '../../../../core/theme/app_theme.dart';
import '../../chats/data/chat_wallpapers.dart';
import '../../chats/widgets/chat_wallpaper_image.dart';
import '../widgets/settings_section.dart';
import 'package:talkmos/l10n/gen/app_localizations.dart';

class AppearanceSettingsScreen extends StatelessWidget {
  const AppearanceSettingsScreen({super.key});

  static const List<Map<String, dynamic>> _brandColors = [
    {'color': Color(0xFF0066FF), 'name': 'Indigo'},
    {'color': Color(0xFF00A884), 'name': 'Green'},
    {'color': Color(0xFF8B5CF6), 'name': 'Purple'},
    {'color': Color(0xFFEC4899), 'name': 'Rose'},
    {'color': Color(0xFF06B6D4), 'name': 'Cyan'},
    {'color': Color(0xFFF59E0B), 'name': 'Amber'},
  ];

  static List<Color> _backdropColors(bool isDark) => [
    isDark ? const Color(0xFF000000) : const Color(0xFFFAF9FF),
    isDark ? const Color(0xFF1E1E2C) : const Color(0xFFF1F5F9),
    isDark ? const Color(0xFF18251C) : const Color(0xFFE5F1E8),
    isDark ? const Color(0xFF281E1E) : const Color(0xFFF9EBEB),
    isDark ? const Color(0xFF1E2830) : const Color(0xFFE6F2F7),
    isDark ? const Color(0xFF2B2516) : const Color(0xFFFBF4E6),
  ];

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final settings = context.watch<SettingsProvider>();
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final surface = isDark ? AppTheme.darkBg : const Color(0xFFFAF9FF);

    return Scaffold(
      backgroundColor: surface,
      appBar: AppBar(
        backgroundColor: surface,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_rounded, color: theme.primaryColor),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          l10n.appearanceSettingsScreenTitle,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: isDark ? AppTheme.darkText : AppTheme.lightText,
          ),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Interface theme ──────────────────────────────────────────
              SettingsSectionHeader(
                title: l10n.appearanceSettingsScreenInterfaceTheme,
                isDark: isDark,
              ),
              _ThemeModeSelector(
                current: settings.themeMode,
                isDark: isDark,
                onChanged: settings.setThemeMode,
              ),

              const SizedBox(height: 28),

              // ── Brand colour ─────────────────────────────────────────────
              SettingsSectionHeader(
                title: l10n.appearanceSettingsScreenBrandPrimaryColor,
                isDark: isDark,
              ),
              Padding(
                padding: const EdgeInsets.only(left: 4, bottom: 12),
                child: Text(
                  l10n.appearanceSettingsScreenBrandColorDesc,
                  style: TextStyle(
                    fontSize: 12,
                    color: isDark
                        ? AppTheme.darkTextSecondary
                        : AppTheme.lightTextSecondary,
                  ),
                ),
              ),
              SettingsCard(
                isDark: isDark,
                children: [
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Wrap(
                      spacing: 14,
                      runSpacing: 14,
                      children: [
                        for (final entry in _brandColors)
                          _ColorSwatch(
                            color: entry['color'] as Color,
                            isSelected:
                                settings.primaryColor.toARGB32() ==
                                (entry['color'] as Color).toARGB32(),
                            onTap: () => settings.setPrimaryColor(
                              entry['color'] as Color,
                            ),
                          ),
                        _CustomColorSwatch(
                          currentColor: settings.primaryColor,
                          // Selected (filled, not the rainbow ring) once the
                          // active color isn't one of the fixed presets above.
                          isSelected: !_brandColors.any(
                            (entry) =>
                                (entry['color'] as Color).toARGB32() ==
                                settings.primaryColor.toARGB32(),
                          ),
                          onTap: () =>
                              _openColorPicker(context, settings, l10n, isDark),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 28),

              // ── Chat wallpaper ───────────────────────────────────────────
              SettingsSectionHeader(
                title: l10n.appearanceSettingsScreenChatWallpaperStyle,
                isDark: isDark,
              ),
              SettingsCard(
                isDark: isDark,
                children: [
                  _CardBlock(
                    title: l10n.appearanceSettingsScreenColorBackdrop,
                    isDark: isDark,
                    child: SizedBox(
                      height: 44,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        itemCount: _backdropColors(isDark).length,
                        separatorBuilder: (_, __) => const SizedBox(width: 12),
                        itemBuilder: (_, i) {
                          final color = _backdropColors(isDark)[i];
                          return _BackdropSwatch(
                            color: color,
                            isSelected:
                                settings.chatWallpaperColor.toARGB32() ==
                                color.toARGB32(),
                            onTap: () => settings.setChatWallpaperColor(color),
                          );
                        },
                      ),
                    ),
                  ),

                  SettingsToggleRow(
                    title: l10n.appearanceSettingsScreenBackgroundDoodles,
                    subtitle:
                        l10n.appearanceSettingsScreenBackgroundDoodlesDesc,
                    value: settings.showDoodles,
                    isDark: isDark,
                    onChanged: settings.setShowDoodles,
                  ),

                  _CardBlock(
                    title: l10n.appearanceSettingsScreenWallpaperGallery,
                    isDark: isDark,
                    child: _WallpaperGallery(
                      selectedPath: settings.chatWallpaperImagePath,
                      isDark: isDark,
                      accentColor: theme.primaryColor,
                      onSelected: (path) {
                        settings.setChatWallpaperImagePath(path);
                        // Bundled art is designed to sit at full strength; the
                        // low default would render it nearly invisible.
                        if (path != null &&
                            settings.chatWallpaperOpacity < 0.6) {
                          settings.setChatWallpaperOpacity(1.0);
                        }
                      },
                      onPickFromGallery: () =>
                          _pickWallpaperImage(context, settings),
                    ),
                  ),

                  // Opacity only means something once there's an image.
                  if (settings.chatWallpaperImagePath != null)
                    _OpacityBlock(
                      value: settings.chatWallpaperOpacity,
                      isDark: isDark,
                      onChanged: settings.setChatWallpaperOpacity,
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _pickWallpaperImage(
    BuildContext context,
    SettingsProvider settings,
  ) async {
    final pickedFile = await pickImageFrom(ImageSource.gallery);
    if (pickedFile == null) return;

    final directory = await getApplicationDocumentsDirectory();
    final timestamp = DateTime.now().millisecondsSinceEpoch.toString();
    final localImage = await File(
      pickedFile.path,
    ).copy('${directory.path}/chat_wallpaper_$timestamp.png');
    await settings.setChatWallpaperImagePath(localImage.path);
  }

  Future<void> _openColorPicker(
    BuildContext context,
    SettingsProvider settings,
    AppLocalizations l10n,
    bool isDark,
  ) async {
    Color picked = settings.primaryColor;
    await showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: isDark ? AppTheme.darkCard : Colors.white,
        title: Text(
          l10n.appearanceSettingsScreenBrandPrimaryColor,
          style: TextStyle(
            color: isDark ? AppTheme.darkText : AppTheme.lightText,
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        content: SingleChildScrollView(
          child: ColorPicker(
            pickerColor: picked,
            onColorChanged: (c) => picked = c,
            enableAlpha: false,
            labelTypes: const [],
            pickerAreaHeightPercent: 0.7,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(l10n.commonCancel),
          ),
          TextButton(
            onPressed: () {
              settings.setPrimaryColor(picked);
              Navigator.pop(ctx);
            },
            child: Text(l10n.commonSave),
          ),
        ],
      ),
    );
  }
}

/// Three-up Light / Dark / System picker.
class _ThemeModeSelector extends StatelessWidget {
  final ThemeMode current;
  final bool isDark;
  final ValueChanged<ThemeMode> onChanged;

  const _ThemeModeSelector({
    required this.current,
    required this.isDark,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final options = [
      (
        ThemeMode.light,
        Icons.light_mode_rounded,
        l10n.appearanceSettingsScreenThemeLight,
      ),
      (
        ThemeMode.dark,
        Icons.dark_mode_rounded,
        l10n.appearanceSettingsScreenThemeDark,
      ),
      (
        ThemeMode.system,
        Icons.brightness_auto_rounded,
        l10n.appearanceSettingsScreenThemeSystem,
      ),
    ];

    return SettingsCard(
      isDark: isDark,
      children: [
        IntrinsicHeight(
          child: Row(
            children: [
              for (var i = 0; i < options.length; i++) ...[
                if (i > 0)
                  VerticalDivider(
                    width: 1,
                    thickness: 1,
                    color: isDark
                        ? Colors.white.withValues(alpha: 0.07)
                        : const Color(0xFFE8E8F2),
                  ),
                Expanded(
                  child: _ThemeOption(
                    icon: options[i].$2,
                    label: options[i].$3,
                    isSelected: current == options[i].$1,
                    onTap: () => onChanged(options[i].$1),
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _ThemeOption extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _ThemeOption({
    required this.icon,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).primaryColor;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final idleColor = isDark
        ? AppTheme.darkTextSecondary
        : AppTheme.lightTextSecondary;

    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        color: isSelected ? primary.withValues(alpha: 0.09) : null,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: isSelected ? primary : idleColor, size: 24),
            const SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                color: isSelected
                    ? primary
                    : (isDark ? AppTheme.darkText : AppTheme.lightText),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// A titled block inside a settings card, for content that isn't a plain row.
class _CardBlock extends StatelessWidget {
  final String title;
  final bool isDark;
  final Widget child;

  const _CardBlock({
    required this.title,
    required this.isDark,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: isDark ? AppTheme.darkText : AppTheme.lightText,
            ),
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}

class _ColorSwatch extends StatelessWidget {
  final Color color;
  final bool isSelected;
  final VoidCallback onTap;

  const _ColorSwatch({
    required this.color,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          border: isSelected ? Border.all(color: Colors.white, width: 3) : null,
          boxShadow: isSelected
              ? [BoxShadow(color: color.withValues(alpha: 0.55), blurRadius: 8)]
              : null,
        ),
        child: isSelected
            ? const Icon(Icons.check_rounded, color: Colors.white, size: 22)
            : null,
      ),
    );
  }
}

class _CustomColorSwatch extends StatelessWidget {
  final Color currentColor;
  final bool isSelected;
  final VoidCallback onTap;

  const _CustomColorSwatch({
    required this.currentColor,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: isSelected ? currentColor : null,
          gradient: isSelected
              ? null
              : const SweepGradient(
                  colors: [
                    Color(0xFFFF0000),
                    Color(0xFFFFFF00),
                    Color(0xFF00FF00),
                    Color(0xFF00FFFF),
                    Color(0xFF0000FF),
                    Color(0xFFFF00FF),
                    Color(0xFFFF0000),
                  ],
                ),
          border: isSelected
              ? Border.all(color: Colors.white, width: 3)
              : Border.all(color: const Color(0x33808080), width: 1),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: currentColor.withValues(alpha: 0.55),
                    blurRadius: 8,
                  ),
                ]
              : null,
        ),
        child: Icon(
          isSelected ? Icons.check_rounded : Icons.colorize_rounded,
          color: Colors.white,
          size: 20,
        ),
      ),
    );
  }
}

class _BackdropSwatch extends StatelessWidget {
  final Color color;
  final bool isSelected;
  final VoidCallback onTap;

  const _BackdropSwatch({
    required this.color,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).primaryColor;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSelected ? primary : const Color(0x33808080),
            width: isSelected ? 2.5 : 1,
          ),
        ),
      ),
    );
  }
}

/// Bundled wallpapers plus "none" and a gallery-pick tile.
class _WallpaperGallery extends StatelessWidget {
  final String? selectedPath;
  final bool isDark;
  final Color accentColor;
  final ValueChanged<String?> onSelected;
  final VoidCallback onPickFromGallery;

  const _WallpaperGallery({
    required this.selectedPath,
    required this.isDark,
    required this.accentColor,
    required this.onSelected,
    required this.onPickFromGallery,
  });

  @override
  Widget build(BuildContext context) {
    final wallpapers = ChatWallpapers.orderedFor(isDarkMode: isDark);
    // A gallery pick is any selection that isn't one of the bundled assets.
    final hasCustomImage =
        selectedPath != null &&
        !ChatWallpapers.isBundledWallpaper(selectedPath!);

    return SizedBox(
      height: 128,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          _GalleryTile(
            isSelected: selectedPath == null,
            accentColor: accentColor,
            onTap: () => onSelected(null),
            child: Container(
              color: isDark ? const Color(0xFF000000) : const Color(0xFFF1F5F9),
              child: Icon(
                Icons.block_rounded,
                color: isDark ? Colors.white38 : const Color(0xFF94A3B8),
              ),
            ),
          ),
          for (final wallpaper in wallpapers) ...[
            const SizedBox(width: 12),
            _GalleryTile(
              isSelected: selectedPath == wallpaper.assetPath,
              accentColor: accentColor,
              onTap: () => onSelected(wallpaper.assetPath),
              child: Image.asset(
                wallpaper.assetPath,
                fit: BoxFit.cover,
                cacheWidth: 200,
                errorBuilder: (_, __, ___) =>
                    Container(color: wallpaper.backdropColor),
              ),
            ),
          ],
          if (hasCustomImage) ...[
            const SizedBox(width: 12),
            _GalleryTile(
              isSelected: true,
              accentColor: accentColor,
              onTap: onPickFromGallery,
              child: ChatWallpaperImage(path: selectedPath!),
            ),
          ],
          const SizedBox(width: 12),
          _GalleryTile(
            isSelected: false,
            accentColor: accentColor,
            onTap: onPickFromGallery,
            child: Container(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.04)
                  : const Color(0xFFF1F5F9),
              child: Icon(
                Icons.add_photo_alternate_outlined,
                color: isDark ? Colors.white54 : const Color(0xFF64748B),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _GalleryTile extends StatelessWidget {
  final bool isSelected;
  final Color accentColor;
  final VoidCallback onTap;
  final Widget child;

  const _GalleryTile({
    required this.isSelected,
    required this.accentColor,
    required this.onTap,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 92,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? accentColor : const Color(0x33808080),
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
                  margin: const EdgeInsets.all(5),
                  padding: const EdgeInsets.all(2),
                  decoration: BoxDecoration(
                    color: accentColor,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.check_rounded,
                    size: 13,
                    color: Colors.white,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _OpacityBlock extends StatelessWidget {
  final double value;
  final bool isDark;
  final ValueChanged<double> onChanged;

  const _OpacityBlock({
    required this.value,
    required this.isDark,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final secondary = isDark
        ? AppTheme.darkTextSecondary
        : AppTheme.lightTextSecondary;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  AppLocalizations.of(
                    context,
                  ).appearanceSettingsScreenImageOpacity,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: isDark ? AppTheme.darkText : AppTheme.lightText,
                  ),
                ),
              ),
              Text(
                '${(value * 100).round()}%',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: secondary,
                ),
              ),
            ],
          ),
          Row(
            children: [
              Icon(Icons.opacity_rounded, size: 16, color: secondary),
              Expanded(
                child: Slider(
                  value: value,
                  min: 0.0,
                  max: 1.0,
                  divisions: 20,
                  activeColor: Theme.of(context).primaryColor,
                  onChanged: onChanged,
                ),
              ),
              Icon(Icons.opacity, size: 16, color: secondary),
            ],
          ),
        ],
      ),
    );
  }
}
