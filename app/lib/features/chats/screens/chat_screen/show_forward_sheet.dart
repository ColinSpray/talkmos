part of 'chat_screen.dart';

extension _ShowForwardSheet on _ChatScreenState {
  /// Forwards a message into another chat picked from a bottom sheet.
  void _showForwardSheet(ChatMessageModel message) async {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final target = await showForwardMessageSheet(
      context: context,
      chats: _chatProvider.recentChats,
      isDark: isDark,
    );
    if (target == null || !mounted) return;

    _chatProvider.sendMessage(
      chatId: target.id,
      content: message.content,
      messageType: message.messageType.name,
      media: _mediaMetaOf(message),
      isDirect: target.chatType == 'direct',
    );
    _showSnack(
      AppLocalizations.of(
        context,
      ).chatScreenForwardedTo(toTitleCase(target.title)),
    );
  }
}
