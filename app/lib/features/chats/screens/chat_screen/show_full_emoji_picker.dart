part of 'chat_screen.dart';

extension _ShowFullEmojiPicker on _ChatScreenState {
  void _showFullEmojiPicker(ChatMessageModel message) {
    showEmojiPickerSheet(
      context,
      onEmojiSelected: (_, emoji) {
        _chatProvider.reactToMessage(widget.chatId, message.id, emoji.emoji);
      },
    );
  }
}
