part of 'chat_screen.dart';

extension _MediaMetaOf on _ChatScreenState {
  /// Re-packs an existing message's already-uploaded media for forwarding.
  Map<String, dynamic>? _mediaMetaOf(ChatMessageModel message) {
    if (message.media.url.isEmpty) return null;
    return {
      'url': message.media.url,
      'thumbnail': message.media.thumbnail,
      'fileName': message.media.fileName,
      'mimeType': message.media.mimeType,
      'size': message.media.size,
      'duration': message.media.duration,
    };
  }
}
