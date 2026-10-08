part of 'chat_screen.dart';

extension _SendMessage on _ChatScreenState {
  void _sendMessage() {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;

    if (_editingMessage != null) {
      _chatProvider.editMessage(widget.chatId, _editingMessage!.id, text);
      _setState(() => _editingMessage = null);
      _messageController.clear();
      return;
    }

    context.read<ChatProvider>().sendMessage(
      chatId: widget.chatId,
      content: text,
      replyToId: _replyingToMessage?.id,
      isDirect: widget.chatType == 'direct',
    );

    if (_replyingToMessage != null) {
      _setState(() {
        _replyingToMessage = null;
      });
    }

    _messageController.clear();
    WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());
  }
}
