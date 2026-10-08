part of 'chat_screen.dart';

extension _ClearReplyAfterSend on _ChatScreenState {
  void _clearReplyAfterSend() {
    if (_replyingToMessage != null) {
      _setState(() => _replyingToMessage = null);
    }
  }
}
