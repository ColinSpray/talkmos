part of 'chat_screen.dart';

extension _LoadChat on _ChatScreenState {
  Future<void> _loadChat() async {
    final myId = _chatProvider.user?.id ?? '';

    await _chatProvider.getMessages(widget.chatId);

    // Mark all existing messages from peer as read on open
    if (myId.isNotEmpty) {
      _socketService.markMessagesRead(
        widget.chatId,
        myId,
        widget.activeUser.id,
      );
    }

    final msgs = _chatProvider.messages[widget.chatId] ?? [];
    _lastMessageId = msgs.isNotEmpty ? msgs.last.id : null;
    WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());
  }
}
