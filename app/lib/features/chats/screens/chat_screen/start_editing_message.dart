part of 'chat_screen.dart';

extension _StartEditingMessage on _ChatScreenState {
  void _startEditingMessage(ChatMessageModel message) {
    _setState(() {
      _editingMessage = message;
      _replyingToMessage = null;
      _messageController.text = message.content;
      _messageController.selection = TextSelection.fromPosition(
        TextPosition(offset: _messageController.text.length),
      );
    });
  }
}
