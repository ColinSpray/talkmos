import 'package:flutter/material.dart';
import 'package:talkmos/core/utils/titlecase_function.dart';
import 'package:talkmos/l10n/gen/app_localizations.dart';
import '../../../models/chat_message_model.dart';

/// Strip above the message list showing the most recently pinned message,
/// with a tap-to-jump target and an unpin affordance.
class PinnedMessageBanner extends StatelessWidget {
  final List<ChatMessageModel> pinnedMessages;
  final bool isDark;

  /// Jump to the pinned message in the list.
  final ValueChanged<String> onTapMessage;

  /// Confirmed unpin — the dialog is handled here, this only fires on accept.
  final ValueChanged<String> onUnpin;

  const PinnedMessageBanner({
    super.key,
    required this.pinnedMessages,
    required this.isDark,
    required this.onTapMessage,
    required this.onUnpin,
  });

  @override
  Widget build(BuildContext context) {
    if (pinnedMessages.isEmpty) return const SizedBox.shrink();

    final latest = pinnedMessages.first;
    final primary = Theme.of(context).primaryColor;

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF000814) : Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 4,
            offset: const Offset(0, 1),
          ),
        ],
        border: Border(
          bottom: BorderSide(
            color: isDark
                ? Colors.white.withValues(alpha: 0.06)
                : const Color(0xFFE2E8F0),
            width: 1,
          ),
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          Icon(Icons.push_pin_rounded, size: 16, color: primary),
          const SizedBox(width: 12),
          Expanded(
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () => onTapMessage(latest.id),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    AppLocalizations.of(context).pinnedMessageBannerTitle,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: primary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${toTitleCase(latest.senderName)}: ${latest.content}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 13,
                      color: isDark ? Colors.white70 : const Color(0xFF000E23),
                    ),
                  ),
                ],
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close_rounded, size: 16),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
            color: isDark ? Colors.white54 : const Color(0xFF64748B),
            onPressed: () => _confirmUnpin(context, latest.id, primary),
          ),
        ],
      ),
    );
  }

  void _confirmUnpin(BuildContext context, String messageId, Color primary) {
    final textColor = isDark ? Colors.white : const Color(0xFF000000);
    final l10n = AppLocalizations.of(context);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: isDark ? const Color(0xFF000814) : Colors.white,
        title: Text(
          l10n.pinnedMessageBannerConfirmTitle,
          style: TextStyle(color: textColor, fontWeight: FontWeight.bold),
        ),
        content: Text(
          l10n.pinnedMessageBannerConfirmBody,
          style: TextStyle(color: isDark ? Colors.white70 : Colors.black87),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              l10n.commonCancel,
              style: const TextStyle(color: Color(0xFF64748B)),
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              onUnpin(messageId);
            },
            child: Text(
              l10n.pinnedMessageBannerUnpinAction,
              style: TextStyle(color: primary, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }
}
