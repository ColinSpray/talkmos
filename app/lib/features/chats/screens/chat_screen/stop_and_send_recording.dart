part of 'chat_screen.dart';

extension _StopAndSendRecording on _ChatScreenState {
  /// Stops recording, lets the user review the clip, then sends it.
  void _stopAndSendRecording() async {
    final result = await _recorder.stop();
    if (!mounted) return;

    if (!result.isSuccess) {
      final l10n = AppLocalizations.of(context);
      switch (result.failure) {
        case VoiceRecordingFailure.tooShort:
          _showSnack(l10n.chatScreenMessageTooShort);
        case VoiceRecordingFailure.error:
          _showSnack(
            l10n.chatScreenVoiceSendFailed(result.errorMessage ?? ''),
            isError: true,
          );
        default:
          break;
      }
      return;
    }

    final recording = result.recording!;
    final media = PickedMedia(
      bytes: recording.bytes,
      fileName: recording.fileName,
      mimeType: recording.mimeType,
      durationSeconds: recording.durationSeconds,
    );

    final preview = await _confirmMediaInPreview(
      media,
      durationSeconds: recording.durationSeconds,
    );
    if (preview == null || !mounted) return;
    final caption = (preview['caption'] as String?) ?? '';

    await _mediaSender.sendVoice(
      media,
      caption: caption,
      replyToId: _replyingToMessage?.id,
    );
    _clearReplyAfterSend();
    _scrollToBottom();
  }
}
