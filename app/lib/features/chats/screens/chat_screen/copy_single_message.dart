part of 'chat_screen.dart';

extension _CopySingleMessage on _ChatScreenState {
  void _copySingleMessage(ChatMessageModel message) {
    Clipboard.setData(ClipboardData(text: message.content));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(AppLocalizations.of(context).chatScreenCopiedToClipboard),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}
