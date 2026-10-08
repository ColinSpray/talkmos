part of 'chat_screen.dart';

extension _SendVideo on _ChatScreenState {
  Future<void> _sendVideo(ImageSource source) async {
    try {
      final picked = await ChatMediaPicker.pickVideo(source);
      if (picked == null || !mounted) return;

      final preview = await _confirmMediaInPreview(picked);
      if (preview == null || !mounted) return;

      _showSnack(AppLocalizations.of(context).chatScreenUploadingVideo);
      await _mediaSender.sendVideo(
        picked,
        caption: (preview['caption'] as String?) ?? '',
        replyToId: _replyingToMessage?.id,
      );
      _clearReplyAfterSend();
      _scrollToBottom();
    } catch (e) {
      _showSnack(
        AppLocalizations.of(context).chatScreenVideoUploadFailed(e.toString()),
        isError: true,
      );
    }
  }
}
