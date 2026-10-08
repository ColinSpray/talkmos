part of 'chat_screen.dart';

extension _ToggleMessageSelection on _ChatScreenState {
  void _toggleMessageSelection(ChatMessageModel message) {
    _setState(() {
      if (_selectedMessageIds.contains(message.id)) {
        _selectedMessageIds.remove(message.id);
      } else {
        _selectedMessageIds.add(message.id);
      }
    });
  }
}
