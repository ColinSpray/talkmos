part of 'chat_screen.dart';

extension _InitSocket on _ChatScreenState {
  Future<void> _initSocket() async {
    _socketService.enterChat(widget.chatId, widget.activeUser.id);

    _chatProvider.onUserOnlineStatus = (userId, online, lastSeenAt) {
      if (userId == widget.activeUser.id && mounted) {
        _setState(() {
          _isOnline = online;
          // Null while they are online, and when their privacy setting hides
          // it — either way there is nothing to show but the name.
          _peerLastSeenAt = lastSeenAt;
        });
      }
    };

    _chatProvider.onMessagePinned =
        (chatId, messageId, isPinned, pinnedAt, message) {
          if (chatId == widget.chatId && mounted) {
            _loadPinnedMessages();
          }
        };

    _socketService.checkUserOnline(widget.activeUser.id);

    _chatProvider.addListener(_onProviderChanged);

    await _loadChat();
    _loadPinnedMessages();
  }
}
