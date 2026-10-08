part of 'chat_screen.dart';

extension _OnScroll on _ChatScreenState {
  void _onScroll() {
    if (!_scrollController.hasClients ||
        !_scrollController.position.hasContentDimensions) {
      return;
    }
    final position = _scrollController.position;
    final pixels = position.pixels;
    final max = position.maxScrollExtent;
    // Reversed: the top of the history is the *end* of the scroll range.
    if (!pixels.isFinite || !max.isFinite) return;
    if (pixels < max - _ChatScreenState._loadMoreThreshold) return;
    if (_chatProvider.isLoadingMoreMessages(widget.chatId)) return;
    if (!_chatProvider.hasMoreMessages(widget.chatId)) return;
    _loadMoreMessages();
  }
}
