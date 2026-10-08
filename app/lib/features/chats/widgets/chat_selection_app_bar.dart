import 'package:flutter/material.dart';
import '../../../models/chat_message_model.dart';
import 'package:talkmos/l10n/gen/app_localizations.dart';

/// App bar shown while one or more messages are selected (long-press select
/// mode): copy/reply/pin/delete actions instead of the normal [ChatHeader].
class ChatSelectionAppBar extends StatelessWidget
    implements PreferredSizeWidget {
  final List<ChatMessageModel> messages;
  final Set<String> selectedMessageIds;
  final bool isDark;
  final VoidCallback onClose;
  final VoidCallback onCopy;
  final ValueChanged<ChatMessageModel> onReply;
  final ValueChanged<ChatMessageModel> onTogglePin;
  final VoidCallback onDelete;

  const ChatSelectionAppBar({
    super.key,
    required this.messages,
    required this.selectedMessageIds,
    required this.isDark,
    required this.onClose,
    required this.onCopy,
    required this.onReply,
    required this.onTogglePin,
    required this.onDelete,
  });

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final anyDeleted = messages
        .where((m) => selectedMessageIds.contains(m.id))
        .any((m) => m.deletedForEveryone);

    ChatMessageModel? singleSelected;
    if (selectedMessageIds.length == 1) {
      final id = selectedMessageIds.first;
      singleSelected = messages.firstWhere((m) => m.id == id);
    }

    return AppBar(
      backgroundColor: isDark
          ? const Color(0xFF000814)
          : const Color(0xFFF1F5F9),
      elevation: 0,
      leading: IconButton(
        icon: const Icon(Icons.close_rounded),
        onPressed: onClose,
      ),
      title: Text(
        l10n.chatScreenSelectedCount(selectedMessageIds.length),
        style: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: isDark ? Colors.white : const Color(0xFF000000),
        ),
      ),
      actions: [
        if (!anyDeleted)
          IconButton(
            icon: const Icon(Icons.copy_rounded),
            onPressed: onCopy,
            tooltip: l10n.chatScreenCopy,
          ),
        if (singleSelected != null && !singleSelected.deletedForEveryone) ...[
          IconButton(
            icon: const Icon(Icons.reply_rounded),
            onPressed: () => onReply(singleSelected!),
            tooltip: l10n.chatScreenReply,
          ),
          IconButton(
            icon: Icon(
              singleSelected.isPinned
                  ? Icons.pin_drop_rounded
                  : Icons.push_pin_rounded,
            ),
            onPressed: () => onTogglePin(singleSelected!),
            tooltip: singleSelected.isPinned
                ? l10n.chatScreenUnpin
                : l10n.chatScreenPin,
          ),
        ],
        IconButton(
          icon: const Icon(Icons.delete_outline_rounded),
          onPressed: onDelete,
          tooltip: l10n.commonDelete,
        ),
        const SizedBox(width: 8),
      ],
    );
  }
}
