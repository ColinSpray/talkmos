part of 'chat_screen.dart';

extension _OnRecorderChanged on _ChatScreenState {
  void _onRecorderChanged() {
    if (mounted) _setState(() {});
  }
}
