part of 'chat_screen.dart';

extension _OnTextChanged on _ChatScreenState {
  void _onTextChanged() {
    final isNotEmpty = _messageController.text.isNotEmpty;
    if (isNotEmpty == _isTextEmpty) {
      _setState(() => _isTextEmpty = !isNotEmpty);
    }

    if (isNotEmpty) {
      // Emit typing once per burst
      if (!_isTypingSent) {
        _isTypingSent = true;
        _socketService.sendTyping(widget.chatId);
      }
      // Reset debounce timer on each keystroke
      _typingDebounce?.cancel();
      _typingDebounce = Timer(const Duration(milliseconds: 1500), () {
        _isTypingSent = false;
        _socketService.sendStopTyping(widget.chatId);
      });
    } else {
      // Field cleared — stop typing immediately
      _typingDebounce?.cancel();
      if (_isTypingSent) {
        _isTypingSent = false;
        _socketService.sendStopTyping(widget.chatId);
      }
    }
  }
}
