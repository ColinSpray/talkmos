part of 'chat_screen.dart';

extension _LoadMoreMessages on _ChatScreenState {
  /// Older messages are appended past the end of the reversed list, which is
  /// off screen above — the viewport keeps its position on its own, so unlike
  /// a forward list there is nothing to correct for afterwards.
  Future<void> _loadMoreMessages() =>
      _chatProvider.loadMoreMessages(widget.chatId);
}
