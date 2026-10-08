part of 'chat_screen.dart';

extension _SendDocument on _ChatScreenState {
  Future<void> _sendDocument() async {
    try {
      final media = await ChatMediaPicker.pickDocument();
      if (media == null || !mounted) return;

      final preview = await _confirmMediaInPreview(media);
      if (preview == null || !mounted) return;

      _showSnack(AppLocalizations.of(context).chatScreenUploadingDocument);
      await _mediaSender.sendDocument(
        media,
        caption: (preview['caption'] as String?) ?? '',
        replyToId: _replyingToMessage?.id,
      );
      _clearReplyAfterSend();
      _scrollToBottom();
    } catch (e) {
      _showSnack(
        AppLocalizations.of(
          context,
        ).chatScreenDocumentUploadFailed(e.toString()),
        isError: true,
      );
    }
  }
}
