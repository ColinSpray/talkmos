part of 'chat_screen.dart';

extension _CopySelectedMessages on _ChatScreenState {
  void _copySelectedMessages(List<ChatMessageModel> messages) {
    final selectedMsgs = messages
        .where((m) => _selectedMessageIds.contains(m.id))
        .toList();
    if (selectedMsgs.isEmpty) return;

    selectedMsgs.sort((a, b) => a.createdAt.compareTo(b.createdAt));

    final joinedText = selectedMsgs.map((m) => m.content).join('\n');
    Clipboard.setData(ClipboardData(text: joinedText));
    _clearSelection();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(AppLocalizations.of(context).chatScreenCopiedToClipboard),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}
