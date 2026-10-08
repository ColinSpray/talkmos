part of 'chat_screen.dart';

extension _ReplySelectedMessage on _ChatScreenState {
  void _replySelectedMessage(List<ChatMessageModel> messages) {
    final selectedMsgs = messages
        .where((m) => _selectedMessageIds.contains(m.id))
        .toList();
    if (selectedMsgs.length != 1) return;

    _setState(() {
      _replyingToMessage = selectedMsgs.first;
      _selectedMessageIds.clear();
    });
  }
}
