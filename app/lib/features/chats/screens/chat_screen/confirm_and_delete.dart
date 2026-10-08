part of 'chat_screen.dart';

extension _ConfirmAndDelete on _ChatScreenState {
  void _confirmAndDelete(List<ChatMessageModel> selectedMsgs, String myId) {
    final allSentByMe = selectedMsgs.every(
      (m) => m.senderId == myId && !m.deletedForEveryone,
    );

    showDialog(
      context: context,
      builder: (ctx) {
        final l10n = AppLocalizations.of(context);
        final isDark = Theme.of(context).brightness == Brightness.dark;
        final textColor = isDark ? Colors.white : const Color(0xFF000000);
        return AlertDialog(
          backgroundColor: isDark ? const Color(0xFF000814) : Colors.white,
          title: Text(
            l10n.chatScreenDeleteMessageTitle,
            style: TextStyle(color: textColor, fontWeight: FontWeight.bold),
          ),
          content: Text(
            allSentByMe
                ? l10n.chatScreenDeleteMessagesConfirm(selectedMsgs.length)
                : l10n.chatScreenDeleteMessagesForMeConfirm(
                    selectedMsgs.length,
                  ),
            style: TextStyle(color: isDark ? Colors.white70 : Colors.black87),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(
                l10n.commonCancel,
                style: const TextStyle(color: Color(0xFF64748B)),
              ),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(ctx);
                _performDelete(selectedMsgs, forEveryone: false);
              },
              child: Text(
                l10n.chatScreenDeleteForMe,
                style: const TextStyle(color: Colors.redAccent),
              ),
            ),
            if (allSentByMe)
              TextButton(
                onPressed: () {
                  Navigator.pop(ctx);
                  _performDelete(selectedMsgs, forEveryone: true);
                },
                child: Text(
                  l10n.chatScreenDeleteForEveryone,
                  style: const TextStyle(color: Colors.redAccent),
                ),
              ),
          ],
        );
      },
    );
  }
}
