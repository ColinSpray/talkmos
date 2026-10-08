import 'package:flutter/material.dart';
import 'package:talkmos/core/utils/titlecase_function.dart';
import 'package:talkmos/l10n/gen/app_localizations.dart';

/// Small presentational pieces of the chat body: the privacy notice, the
/// empty-thread prompt, and the day divider between message groups.

/// Pill reminding the user that the thread is private to this chat.
class ChatPrivacyBanner extends StatelessWidget {
  final bool isDark;

  const ChatPrivacyBanner({super.key, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 10, bottom: 4),
      child: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: _pillDecoration(isDark, radius: 20),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.lock_rounded,
                size: 13,
                color: isDark ? Colors.white54 : const Color(0xFF64748B),
              ),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  AppLocalizations.of(context).chatBodyPrivacyBanner,
                  style: TextStyle(
                    fontSize: 11.5,
                    color: isDark ? Colors.white60 : const Color(0xFF64748B),
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class BlockedContactBar extends StatelessWidget {
  final bool isDark;
  final String peerName;
  final VoidCallback onUnblock;

  const BlockedContactBar({
    super.key,
    required this.isDark,
    required this.peerName,
    required this.onUnblock,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF000000) : Colors.white,
        border: Border(
          top: BorderSide(
            color: isDark
                ? Colors.white.withValues(alpha: 0.08)
                : const Color(0xFFE3E6EF),
          ),
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.block_rounded,
            size: 18,
            color: isDark ? Colors.white54 : const Color(0xFF64748B),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              l10n.chatBodyYouBlocked(peerName),
              style: TextStyle(
                fontSize: 13,
                color: isDark ? Colors.white70 : const Color(0xFF000E23),
              ),
            ),
          ),
          TextButton(onPressed: onUnblock, child: Text(l10n.commonUnblock)),
        ],
      ),
    );
  }
}

/// Shown in place of the message list when a chat has no messages yet.
class ChatEmptyState extends StatelessWidget {
  final bool isDark;
  final String peerName;

  const ChatEmptyState({
    super.key,
    required this.isDark,
    required this.peerName,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final primary = Theme.of(context).primaryColor;
    final firstName = peerName.split(' ').first;

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: primary.withValues(alpha: 0.08),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.waving_hand_rounded, color: primary, size: 28),
            ),
            const SizedBox(height: 14),
            Text(
              l10n.chatBodyNoMessagesYet,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 15,
                color: isDark ? Colors.white70 : const Color(0xFF000E23),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              l10n.chatBodySayHi(toTitleCase(firstName)),
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 13, color: Color(0xFF94A3B8)),
            ),
          ],
        ),
      ),
    );
  }
}

/// "Today" / "Yesterday" / "Mar 4, 2026" divider between days of messages.
class ChatDateSeparator extends StatelessWidget {
  final DateTime date;
  final bool isDark;

  const ChatDateSeparator({
    super.key,
    required this.date,
    required this.isDark,
  });

  static const List<String> _months = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];

  static String formatLabel(BuildContext context, DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    if (date == today) return AppLocalizations.of(context).commonToday;
    if (date == yesterday) return AppLocalizations.of(context).commonYesterday;
    return '${_months[date.month - 1]} ${date.day}, ${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
          decoration: _pillDecoration(isDark, radius: 14),
          child: Text(
            formatLabel(context, date),
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: isDark ? Colors.white70 : const Color(0xFF475569),
            ),
          ),
        ),
      ),
    );
  }
}

BoxDecoration _pillDecoration(bool isDark, {required double radius}) {
  return BoxDecoration(
    color: isDark ? const Color(0xFF000814) : Colors.white,
    borderRadius: BorderRadius.circular(radius),
    boxShadow: [
      BoxShadow(
        color: Colors.black.withValues(alpha: 0.04),
        blurRadius: 4,
        offset: const Offset(0, 1),
      ),
    ],
  );
}
