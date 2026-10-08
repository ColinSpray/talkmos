part of 'chat_screen.dart';

extension _ScrollToBottom on _ChatScreenState {
  /// The list is reversed, so the newest message sits at offset 0.
  void _scrollToBottom({bool animate = false}) {
    if (!_scrollController.hasClients ||
        !_scrollController.position.hasContentDimensions) {
      return;
    }
    if (animate) {
      _scrollController.animateTo(
        0,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    } else {
      _scrollController.jumpTo(0);
    }
  }

  /// Whether the newest message is on screen — the difference between
  /// following the conversation and reading back through it.
  bool get _isAtBottom =>
      _scrollController.hasClients &&
      _scrollController.position.hasContentDimensions &&
      _scrollController.offset <= _ChatScreenState._atBottomThreshold;
}
