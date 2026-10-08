part of 'chat_screen.dart';

extension _TranslateMessage on _ChatScreenState {
  Future<void> _translateMessageTo(
    ChatMessageModel message,
    AppLanguage target,
  ) async {
    unawaited(TranslationPreferenceStore.instance.setTargetLanguage(target));
    try {
      await _chatProvider.translateMessage(message, target: target);
    } catch (e) {
      _showSnack(
        AppLocalizations.of(context).chatScreenTranslateFailed,
        isError: true,
      );
    }
  }
}
