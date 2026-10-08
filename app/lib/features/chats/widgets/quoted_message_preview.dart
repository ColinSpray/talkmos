import 'package:flutter/material.dart';
import 'package:talkmos/l10n/gen/app_localizations.dart';
import '../../../models/chat_message_model.dart';
import '../../../models/shared_attachment_payloads.dart';

/// How a message reads when it is quoted in a reply: an icon and a word for
/// anything that isn't text.
///
/// Media messages carry no text of their own, so quoting one used to leave
/// the preview blank under the sender's name.
({IconData? icon, String label}) quotedPreviewOf(
  BuildContext context,
  ChatMessageModel message,
) {
  final l10n = AppLocalizations.of(context);
  final content = message.content;

  switch (message.messageType) {
    case MessageType.image:
      return (icon: Icons.photo_outlined, label: l10n.commonPhoto);
    case MessageType.video:
      return (icon: Icons.videocam_outlined, label: l10n.commonVideo);
    case MessageType.voice:
      return (icon: Icons.mic_rounded, label: l10n.commonVoiceMessage);
    case MessageType.audio:
      return (icon: Icons.audiotrack_rounded, label: l10n.commonAudio);
    case MessageType.file:
      return (
        icon: Icons.description_outlined,
        label: message.media.fileName.isNotEmpty
            ? message.media.fileName
            : l10n.commonDocument,
      );
    case MessageType.gif:
      return (icon: Icons.gif_box_outlined, label: l10n.commonGif);
    case MessageType.sticker:
      return (icon: Icons.emoji_emotions_outlined, label: l10n.commonSticker);
    case MessageType.location:
      return (icon: Icons.location_on_rounded, label: l10n.commonLocation);
    case MessageType.contact:
      final payload = SharedContactPayload.tryDecode(content);
      return (
        icon: Icons.person_rounded,
        label: payload?.name.isNotEmpty == true
            ? payload!.name
            : l10n.recentChatTileContact,
      );
    default:
      return (icon: null, label: content);
  }
}

/// The image to show beside a quoted photo or video, if there is one.
String? quotedThumbnailOf(ChatMessageModel message) {
  if (message.messageType != MessageType.image &&
      message.messageType != MessageType.video &&
      message.messageType != MessageType.gif) {
    return null;
  }
  final thumbnail = message.media.thumbnail;
  if (thumbnail.isNotEmpty) return thumbnail;
  final url = message.media.url;
  return message.messageType == MessageType.video || url.isEmpty ? null : url;
}
