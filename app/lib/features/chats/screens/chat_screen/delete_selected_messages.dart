part of 'chat_screen.dart';

extension _DeleteSelectedMessages on _ChatScreenState {
  void _deleteSelectedMessages(List<ChatMessageModel> messages, String myId) {
    final selectedMsgs = messages
        .where((m) => _selectedMessageIds.contains(m.id))
        .toList();
    if (selectedMsgs.isEmpty) return;
    _confirmAndDelete(selectedMsgs, myId);
  }
}
