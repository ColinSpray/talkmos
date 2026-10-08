part of 'chat_screen.dart';

extension _DeleteSingleMessage on _ChatScreenState {
  void _deleteSingleMessage(ChatMessageModel message, String myId) {
    _confirmAndDelete([message], myId);
  }
}
