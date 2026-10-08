import 'package:flutter/material.dart';
import 'package:talkmos/l10n/gen/app_localizations.dart';

/// WhatsApp-style "Archived" entry row, shown above the chat list only when
/// something is actually archived.
class ArchivedChatsRow extends StatelessWidget {
  final bool isDark;
  final int archivedCount;
  final int unreadCount;
  final VoidCallback onTap;

  const ArchivedChatsRow({
    super.key,
    required this.isDark,
    required this.archivedCount,
    required this.unreadCount,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    if (archivedCount == 0) return const SizedBox.shrink();

    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 12),
        child: Row(
          children: [
            SizedBox(
              width: 52,
              child: Icon(
                Icons.archive_outlined,
                size: 22,
                color: isDark ? Colors.white70 : const Color(0xFF64748B),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                AppLocalizations.of(context).homeScreenArchived,
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 15,
                  color: isDark ? Colors.white : const Color(0xFF000000),
                ),
              ),
            ),
            if (unreadCount > 0)
              Text(
                '$unreadCount',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).primaryColor,
                ),
              )
            else
              Text(
                '$archivedCount',
                style: const TextStyle(fontSize: 13, color: Color(0xFF94A3B8)),
              ),
          ],
        ),
      ),
    );
  }
}
