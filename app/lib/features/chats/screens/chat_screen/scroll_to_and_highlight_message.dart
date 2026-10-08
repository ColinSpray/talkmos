part of 'chat_screen.dart';

extension _ScrollToAndHighlightMessage on _ChatScreenState {
  void _scrollToAndHighlightMessage(String messageId) {
    final messages = _chatProvider.messages[widget.chatId] ?? [];
    final items = buildChatListEntries(messages);

    // Same ordering the list renders, so the index is its distance from the
    // bottom — which is what the offset below measures.
    final index = items.indexWhere((item) => item.message?.id == messageId);
    if (index != -1) {
      if (!_scrollController.hasClients ||
          !_scrollController.position.hasContentDimensions) {
        return;
      }
      final maxExtent = _scrollController.position.maxScrollExtent;
      if (!maxExtent.isFinite || maxExtent < 0) return;

      final targetOffset = (index * 84.0).clamp(0.0, maxExtent);
      if (!targetOffset.isFinite) return;

      _scrollController.animateTo(
        targetOffset,
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeInOut,
      );

      _setState(() {
        _highlightedMessageId = messageId;
      });
      Timer(const Duration(milliseconds: 1500), () {
        if (mounted) {
          _setState(() {
            _highlightedMessageId = null;
          });
        }
      });
    }
  }
}
