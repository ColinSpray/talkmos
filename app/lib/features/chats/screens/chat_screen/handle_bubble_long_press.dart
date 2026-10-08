part of 'chat_screen.dart';

extension _HandleBubbleLongPress on _ChatScreenState {
  void _handleBubbleLongPress(
    ChatMessageModel message,
    GlobalKey bubbleKey,
    Widget bubbleWidget,
    bool isMe,
    String myId,
  ) {
    final box = bubbleKey.currentContext?.findRenderObject() as RenderBox?;
    if (box == null) return;
    final bubbleRect = box.localToGlobal(Offset.zero) & box.size;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isDeleted = message.deletedForEveryone;
    final isTextMessage =
        message.messageType == MessageType.text && message.content.isNotEmpty;
    final l10n = AppLocalizations.of(context);

    ContextActionMenu.show(
      context: context,
      anchor: bubbleWidget,
      anchorRect: bubbleRect,
      alignEnd: isMe,
      isDark: isDark,
      onReact: (emoji) =>
          _chatProvider.reactToMessage(widget.chatId, message.id, emoji),
      onMoreReactions: () => _showFullEmojiPicker(message),
      actionGroups: [
        [
          if (!isDeleted)
            ContextActionItem(
              icon: Icons.reply_rounded,
              label: l10n.chatScreenReply,
              onTap: () => _setState(() {
                _replyingToMessage = message;
                _editingMessage = null;
              }),
            ),
          if (!isDeleted && isMe && isTextMessage)
            ContextActionItem(
              icon: Icons.edit_rounded,
              label: l10n.commonEdit,
              onTap: () => _startEditingMessage(message),
            ),
          if (!isDeleted)
            ContextActionItem(
              icon: Icons.forward_rounded,
              label: l10n.chatScreenForward,
              onTap: () => _showForwardSheet(message),
            ),
          if (!isDeleted && isTextMessage)
            ContextActionItem(
              icon: Icons.copy_rounded,
              label: l10n.chatScreenCopy,
              onTap: () => _copySingleMessage(message),
            ),
          if (!isDeleted && isTextMessage)
            _chatProvider.getTranslation(message.id) != null
                ? ContextActionItem(
                    icon: Icons.translate_rounded,
                    label: l10n.chatScreenShowOriginal,
                    onTap: () => _chatProvider.clearTranslation(message.id),
                  )
                : ContextActionItem(
                    icon: Icons.translate_rounded,
                    label: l10n.chatScreenTranslate,
                    subItems: [
                      for (final language in AppLanguage.values)
                        ContextActionItem(
                          icon: Icons.translate_rounded,
                          label: language.nativeName,
                          onTap: () => _translateMessageTo(message, language),
                        ),
                    ],
                  ),
        ],
        [
          if (!isDeleted)
            ContextActionItem(
              icon: message.isPinned
                  ? Icons.push_pin_outlined
                  : Icons.push_pin_rounded,
              label: message.isPinned
                  ? l10n.chatScreenUnpin
                  : l10n.chatScreenPin,
              onTap: () => _chatProvider.togglePinMessage(
                widget.chatId,
                message.id,
                !message.isPinned,
              ),
            ),
        ],
        [
          ContextActionItem(
            icon: Icons.delete_outline_rounded,
            label: l10n.chatScreenDeleteUnsend,
            isDestructive: true,
            onTap: () => _deleteSingleMessage(message, myId),
          ),
        ],
      ],
    );
  }
}
