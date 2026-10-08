part of 'chat_screen.dart';

extension _SendSinglePhoto on _ChatScreenState {
  /// Picks one photo, lets the user caption/edit it in the preview, then sends.
  Future<void> _sendSinglePhoto(ImageSource source) async {
    try {
      final picked = await ChatMediaPicker.pickImage(source);
      if (picked == null || !mounted) return;

      final result = await _confirmMediaInPreview(picked);
      if (result == null || !mounted) return;

      // The preview screen can hand back edited bytes (crop/rotate).
      final media = _mediaFromPreview(picked, result);

      await _mediaSender.sendImage(
        media,
        caption: (result['caption'] as String?) ?? '',
        replyToId: _replyingToMessage?.id,
      );
      _clearReplyAfterSend();
      _scrollToBottom();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      _showSnack(
        AppLocalizations.of(context).chatScreenUploadFailed(e.toString()),
        isError: true,
      );
    }
  }
}
