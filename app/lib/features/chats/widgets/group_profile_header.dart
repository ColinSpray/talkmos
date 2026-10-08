import 'package:flutter/material.dart';
import '../../../core/widgets/avatar_circle.dart';
import 'package:talkmos/l10n/gen/app_localizations.dart';
import '../../../core/utils/titlecase_function.dart';

/// Avatar (with upload affordance), name, member count, and optional
/// description shown at the top of [GroupProfileScreen].
class GroupProfileHeader extends StatelessWidget {
  final String? avatarUrl;
  final bool isUploadingImage;

  /// Null when this member may not change the group photo — the avatar
  /// still renders, it just isn't tappable.
  final VoidCallback? onAvatarTap;
  final String name;
  final int memberCount;
  final String description;
  final bool isDark;
  final Color textColor;
  final Color primary;

  const GroupProfileHeader({
    super.key,
    required this.avatarUrl,
    required this.isUploadingImage,
    this.onAvatarTap,
    required this.name,
    required this.memberCount,
    required this.description,
    required this.isDark,
    required this.textColor,
    required this.primary,
  });

  @override
  Widget build(BuildContext context) {
    final trimmedDescription = description.trim();

    return Column(
      children: [
        GestureDetector(
          onTap: isUploadingImage ? null : onAvatarTap,
          child: Stack(
            children: [
              AvatarCircle(
                imageUrl: avatarUrl,
                radius: 46,
                backgroundColor: primary.withValues(alpha: 0.12),
                fallback: Icon(Icons.groups_rounded, size: 42, color: primary),
              ),
              if (isUploadingImage)
                Positioned.fill(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.45),
                      shape: BoxShape.circle,
                    ),
                    child: const Center(
                      child: SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2.4,
                        ),
                      ),
                    ),
                  ),
                ),
              // The camera badge is the affordance for tapping the avatar, so
              // it goes when the tap does.
              if (onAvatarTap != null)
                Positioned(
                  right: 0,
                  bottom: 0,
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: primary,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: isDark
                            ? const Color(0xFF070C17)
                            : const Color(0xFFF6F7FB),
                        width: 2.5,
                      ),
                    ),
                    child: const Icon(
                      Icons.photo_camera_rounded,
                      size: 14,
                      color: Colors.white,
                    ),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        Text(
          toTitleCase(name),
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: textColor,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          AppLocalizations.of(
            context,
          ).groupProfileScreenMemberCount(memberCount),
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w500,
            color: primary,
          ),
        ),
        if (trimmedDescription.isNotEmpty) ...[
          const SizedBox(height: 10),
          Text(
            trimmedDescription,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              height: 1.4,
              color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
            ),
          ),
        ],
      ],
    );
  }
}
