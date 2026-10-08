import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:talkmos/l10n/gen/app_localizations.dart';

/// Circular preview of the group photo: the locally picked file if one has
/// been chosen, otherwise a fallback group icon.
class GroupPhotoAvatar extends StatelessWidget {
  final XFile? pickedPhoto;
  final double size;
  final bool isDark;
  final Color primary;
  final bool bordered;

  const GroupPhotoAvatar({
    super.key,
    required this.pickedPhoto,
    required this.size,
    required this.isDark,
    required this.primary,
    this.bordered = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: primary.withValues(alpha: isDark ? 0.14 : 0.07),
        shape: BoxShape.circle,
        border: bordered
            ? Border.all(color: primary.withValues(alpha: isDark ? 0.35 : 0.15))
            : null,
      ),
      clipBehavior: Clip.antiAlias,
      child: pickedPhoto != null
          ? Image.file(File(pickedPhoto!.path), fit: BoxFit.cover)
          : Icon(Icons.groups_rounded, size: 62, color: primary),
    );
  }
}

/// Tappable group-photo picker: a [GroupPhotoAvatar] plus an upload spinner
/// overlay, a camera badge, and a caption reflecting the current state.
class GroupPhotoPicker extends StatelessWidget {
  final XFile? pickedPhoto;
  final bool isUploadingPhoto;
  final bool isDark;
  final Color primary;
  final VoidCallback? onTap;

  const GroupPhotoPicker({
    super.key,
    required this.pickedPhoto,
    required this.isUploadingPhoto,
    required this.isDark,
    required this.primary,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Stack(
            children: [
              GroupPhotoAvatar(
                pickedPhoto: pickedPhoto,
                size: 148,
                isDark: isDark,
                primary: primary,
                bordered: true,
              ),
              if (isUploadingPhoto)
                Positioned.fill(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.4),
                      shape: BoxShape.circle,
                    ),
                    child: const Center(
                      child: SizedBox(
                        width: 26,
                        height: 26,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2.6,
                        ),
                      ),
                    ),
                  ),
                ),
              Positioned(
                right: 4,
                bottom: 8,
                child: Container(
                  padding: const EdgeInsets.all(11),
                  decoration: BoxDecoration(
                    color: primary,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isDark
                          ? const Color(0xFF060B18)
                          : const Color(0xFFF7F8FC),
                      width: 3,
                    ),
                  ),
                  child: const Icon(
                    Icons.photo_camera_rounded,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            isUploadingPhoto
                ? l10n.createGroupScreenUploadingPhoto
                : (pickedPhoto == null
                      ? l10n.createGroupScreenAddPhoto
                      : l10n.createGroupScreenChangePhoto),
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: primary,
            ),
          ),
        ],
      ),
    );
  }
}
