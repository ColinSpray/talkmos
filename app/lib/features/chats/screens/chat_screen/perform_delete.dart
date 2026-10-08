part of 'chat_screen.dart';

extension _PerformDelete on _ChatScreenState {
  void _performDelete(
    List<ChatMessageModel> msgs, {
    required bool forEveryone,
  }) async {
    final list = List<ChatMessageModel>.from(msgs);
    _clearSelection();

    try {
      for (final m in list) {
        _socketService.deleteMessage(widget.chatId, m.id, forEveryone);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              AppLocalizations.of(context).chatScreenDeleteFailed(e.toString()),
            ),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }
}
