part of 'chat_screen.dart';

extension _ClearSelection on _ChatScreenState {
  void _clearSelection() {
    _setState(() {
      _selectedMessageIds.clear();
    });
  }
}
