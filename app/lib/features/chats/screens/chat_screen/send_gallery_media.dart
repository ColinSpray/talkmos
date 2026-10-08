part of 'chat_screen.dart';

extension _SendGalleryMedia on _ChatScreenState {
  Future<void> _sendGalleryMedia() async {
    try {
      final picked = await ChatMediaPicker.pickGalleryMedia();
      if (picked.isEmpty || !mounted) return;

      // (media, caption) pairs, gathered before anything is sent so the
      // previews aren't interleaved with upload snackbars.
      final confirmed = <MapEntry<PickedMedia, String>>[];
      for (final media in picked) {
        if (!mounted) return;
        final result = await _confirmMediaInPreview(media);
        if (result == null) continue;
        confirmed.add(
          MapEntry(
            _mediaFromPreview(media, result),
            (result['caption'] as String?) ?? '',
          ),
        );
      }

      if (confirmed.isEmpty || !mounted) return;
      _showSnack(
        AppLocalizations.of(context).chatScreenSendingItems(confirmed.length),
      );

      for (final entry in confirmed) {
        final media = entry.key;
        final caption = entry.value;
        final replyToId = _replyingToMessage?.id;
        if (media.mimeType.startsWith('video/')) {
          await _mediaSender.sendVideo(
            media,
            caption: caption,
            replyToId: replyToId,
          );
        } else if (media.mimeType.startsWith('image/')) {
          await _mediaSender.sendImage(
            media,
            caption: caption,
            replyToId: replyToId,
          );
        } else {
          await _mediaSender.sendDocument(
            media,
            caption: caption,
            replyToId: replyToId,
          );
        }
      }
      _clearReplyAfterSend();
      _scrollToBottom();
    } catch (e) {
      _showSnack(
        AppLocalizations.of(context).chatScreenMediaUploadFailed(e.toString()),
        isError: true,
      );
    }
  }
}
