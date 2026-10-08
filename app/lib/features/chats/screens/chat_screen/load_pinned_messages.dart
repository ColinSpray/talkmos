part of 'chat_screen.dart';

extension _LoadPinnedMessages on _ChatScreenState {
  Future<void> _loadPinnedMessages() async {
    try {
      final pinned = await _chatProvider.chatService.getPinnedMessages(
        widget.chatId,
      );
      if (mounted) {
        _setState(() {
          _pinnedMessages = pinned;
        });
      }
    } catch (e) {
      debugPrint('Error loading pinned messages: $e');
    }
  }
}
