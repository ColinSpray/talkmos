import 'package:flutter/material.dart';
import 'package:talkmos/l10n/gen/app_localizations.dart';

/// The group profile's "more" menu: edit info, leave, and — for the owner —
/// delete the group outright.
void showGroupProfileMenuSheet({
  required BuildContext context,
  required bool isDark,
  required Color textColor,
  VoidCallback? onEditInfo,
  required VoidCallback onLeaveGroup,
  VoidCallback? onDeleteGroup,
}) {
  final l10n = AppLocalizations.of(context);
  showModalBottomSheet(
    context: context,
    backgroundColor: isDark ? const Color(0xFF111827) : Colors.white,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (ctx) => SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 12),
          Container(
            width: 38,
            height: 4,
            margin: const EdgeInsets.only(bottom: 8),
            decoration: BoxDecoration(
              color: isDark ? Colors.white24 : const Color(0xFFE2E8F0),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          if (onEditInfo != null)
            ListTile(
              leading: Icon(Icons.edit_rounded, color: textColor),
              title: Text(
                l10n.groupProfileScreenEditGroupInfo,
                style: TextStyle(color: textColor),
              ),
              onTap: () {
                Navigator.pop(ctx);
                onEditInfo();
              },
            ),
          ListTile(
            leading: const Icon(Icons.logout_rounded, color: Colors.redAccent),
            title: Text(
              l10n.groupProfileScreenLeaveGroup,
              style: const TextStyle(color: Colors.redAccent),
            ),
            onTap: () {
              Navigator.pop(ctx);
              onLeaveGroup();
            },
          ),
          if (onDeleteGroup != null)
            ListTile(
              leading: const Icon(
                Icons.delete_forever_rounded,
                color: Colors.redAccent,
              ),
              title: Text(
                l10n.groupProfileScreenDeleteGroup,
                style: const TextStyle(color: Colors.redAccent),
              ),
              onTap: () {
                Navigator.pop(ctx);
                onDeleteGroup();
              },
            ),
          const SizedBox(height: 8),
        ],
      ),
    ),
  );
}
