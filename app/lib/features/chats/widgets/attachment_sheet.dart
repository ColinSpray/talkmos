import 'package:flutter/material.dart';
import 'package:talkmos/l10n/gen/app_localizations.dart';

/// What the user picked from the attachment sheet.
enum AttachmentChoice {
  photos,
  camera,
  cameraVideo,
  document,
  contact,
  location,
}

Future<AttachmentChoice?> showAttachmentSheet({
  required BuildContext context,
  required bool isDark,
}) {
  return showModalBottomSheet<AttachmentChoice>(
    context: context,
    backgroundColor: isDark ? const Color(0xFF000814) : Colors.white,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (ctx) => _AttachmentGrid(isDark: isDark),
  );
}

class _AttachmentGrid extends StatelessWidget {
  final bool isDark;

  const _AttachmentGrid({required this.isDark});

  @override
  Widget build(BuildContext context) {
    final textColor = isDark ? Colors.white : const Color(0xFF000000);
    final l10n = AppLocalizations.of(context);

    final options = <_GridOption>[
      _GridOption(
        icon: Icons.insert_drive_file_rounded,
        label: l10n.attachmentSheetDocument,
        color: const Color(0xFF7C3AED),
        choice: AttachmentChoice.document,
      ),
      _GridOption(
        icon: Icons.camera_alt_rounded,
        label: l10n.attachmentSheetCamera,
        color: const Color(0xFFE11D48),
        choice: AttachmentChoice.camera,
      ),
      _GridOption(
        icon: Icons.photo_library_rounded,
        label: l10n.commonGallery,
        color: const Color(0xFF6366F1),
        choice: AttachmentChoice.photos,
      ),
      _GridOption(
        icon: Icons.videocam_rounded,
        label: l10n.commonVideo,
        color: const Color(0xFFDC2626),
        choice: AttachmentChoice.cameraVideo,
      ),
      _GridOption(
        icon: Icons.location_on_rounded,
        label: l10n.commonLocation,
        color: const Color(0xFF16A34A),
        choice: AttachmentChoice.location,
      ),
      _GridOption(
        icon: Icons.person_rounded,
        label: l10n.attachmentSheetContact,
        color: const Color(0xFF2563EB),
        choice: AttachmentChoice.contact,
      ),
    ];

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 38,
              height: 4,
              margin: const EdgeInsets.only(bottom: 20),
              decoration: BoxDecoration(
                color: isDark ? Colors.white24 : const Color(0xFFE2E8F0),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            GridView.count(
              crossAxisCount: 3,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: 20,
              children: [
                for (final option in options)
                  _AttachmentTile(option: option, textColor: textColor),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _GridOption {
  final IconData icon;
  final String label;
  final Color color;
  final AttachmentChoice choice;

  const _GridOption({
    required this.icon,
    required this.label,
    required this.color,
    required this.choice,
  });
}

class _AttachmentTile extends StatelessWidget {
  final _GridOption option;
  final Color textColor;

  const _AttachmentTile({required this.option, required this.textColor});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: () => Navigator.pop(context, option.choice),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: option.color,
              shape: BoxShape.circle,
            ),
            child: Icon(option.icon, color: Colors.white, size: 26),
          ),
          const SizedBox(height: 8),
          Text(
            option.label,
            style: TextStyle(
              fontSize: 12.5,
              color: textColor,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
