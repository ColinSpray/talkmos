import 'package:flutter/material.dart';
import '../../../core/widgets/avatar_circle.dart';
import 'package:talkmos/core/utils/titlecase_function.dart';
import 'package:talkmos/l10n/gen/app_localizations.dart';
import '../../../models/recent_chat.dart';

/// Chat picker shown when forwarding a message. Resolves to the chosen chat,
/// or null if dismissed.
Future<RecentChat?> showForwardMessageSheet({
  required BuildContext context,
  required List<RecentChat> chats,
  required bool isDark,
}) {
  return showModalBottomSheet<RecentChat>(
    context: context,
    backgroundColor: isDark ? const Color(0xFF000814) : Colors.white,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (ctx) => _ForwardSheetBody(chats: chats, isDark: isDark),
  );
}

class _ForwardSheetBody extends StatelessWidget {
  final List<RecentChat> chats;
  final bool isDark;

  const _ForwardSheetBody({required this.chats, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final textColor = isDark ? Colors.white : const Color(0xFF000000);
    final l10n = AppLocalizations.of(context);

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.only(top: 12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 38,
              height: 4,
              decoration: BoxDecoration(
                color: isDark ? Colors.white24 : const Color(0xFFE2E8F0),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Row(
                children: [
                  Text(
                    l10n.forwardMessageSheetTitle,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: textColor,
                    ),
                  ),
                ],
              ),
            ),
            Flexible(
              child: chats.isEmpty
                  ? Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 24,
                      ),
                      child: Text(
                        l10n.forwardMessageSheetNoChats,
                        style: TextStyle(
                          color: isDark
                              ? Colors.white60
                              : const Color(0xFF64748B),
                        ),
                      ),
                    )
                  : ListView.builder(
                      shrinkWrap: true,
                      itemCount: chats.length,
                      itemBuilder: (_, i) => _ForwardTargetTile(
                        chat: chats[i],
                        textColor: textColor,
                        onTap: () => Navigator.pop(context, chats[i]),
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ForwardTargetTile extends StatelessWidget {
  final RecentChat chat;
  final Color textColor;
  final VoidCallback onTap;

  const _ForwardTargetTile({
    required this.chat,
    required this.textColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: AvatarCircle(
        imageUrl: chat.avatarUrl,
        radius: 22,
        backgroundColor: Theme.of(context).primaryColor.withValues(alpha: 0.12),
        foregroundColor: Theme.of(context).primaryColor,
        fallback: Text(
          chat.title.isNotEmpty ? chat.title[0].toUpperCase() : '?',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      title: Text(
        toTitleCase(chat.title),
        style: TextStyle(color: textColor, fontWeight: FontWeight.w600),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      onTap: onTap,
    );
  }
}
