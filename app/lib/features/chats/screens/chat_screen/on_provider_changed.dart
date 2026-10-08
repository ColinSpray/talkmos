part of 'chat_screen.dart';

extension _OnProviderChanged on _ChatScreenState {
  void _onProviderChanged() {
    // The group was deleted for everyone while it was open — there is
    // nothing left to show, so leave rather than sit on a dead chat.
    if (_chatProvider.deletedChatId == widget.chatId) {
      if (mounted) {
        _showSnack(AppLocalizations.of(context).chatScreenGroupDeletedByOwner);
        Navigator.of(context).popUntil((r) => r.isFirst);
      }
      return;
    }

    // Use the cached reference — never call context.read() inside a listener
    final msgs = _chatProvider.messages[widget.chatId] ?? [];

    final newLastId = msgs.isNotEmpty ? msgs.last.id : null;
    if (msgs.isNotEmpty && newLastId != _lastMessageId) {
      _lastMessageId = newLastId;
      // Someone reading back through the history keeps their place; their own
      // message is them rejoining the bottom, so that always follows.
      final isMine = msgs.last.senderId == (_chatProvider.user?.id ?? '');
      if (isMine || _isAtBottom) {
        WidgetsBinding.instance.addPostFrameCallback(
          (_) => _scrollToBottom(animate: true),
        );
      }
    }

    // Sync typing indicator state
    final Set<String> typing =
        _chatProvider.typingUsers[widget.chatId] ?? <String>{};
    if (!setEquals(typing, _typingUserIds)) {
      if (mounted) _setState(() => _typingUserIds = Set<String>.from(typing));
    }
  }
}
