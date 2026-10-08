import 'package:flutter/material.dart';
import 'package:talkmos/core/utils/titlecase_function.dart';
import 'package:talkmos/l10n/gen/app_localizations.dart';
import '../../../models/recent_chat.dart';
import '../../../models/chat_message_model.dart';
import '../../../models/shared_attachment_payloads.dart';
import '../../../core/widgets/avatar_circle.dart';
import '../screens/full_screen_image_viewer.dart';

/// A single row in a chat list — used by both the main chat list and the
/// archived chats screen.
class RecentChatTile extends StatelessWidget {
  final RecentChat chat;
  final bool isDark;
  final VoidCallback onTap;
  final VoidCallback? onLongPress;

  const RecentChatTile({
    super.key,
    required this.chat,
    required this.isDark,
    required this.onTap,
    this.onLongPress,
  });

  ({IconData? icon, String label}) _preview(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final content = chat.lastMessageContent ?? '';
    switch (chat.lastMessage?.messageType) {
      case MessageType.contact:
        final payload = SharedContactPayload.tryDecode(content);
        return (
          icon: Icons.person_rounded,
          label: payload != null
              ? l10n.recentChatTileContactWithName(payload.name)
              : l10n.recentChatTileContact,
        );
      case MessageType.location:
        return (icon: Icons.location_on_rounded, label: l10n.commonLocation);
      case MessageType.file:
        return (icon: Icons.description_outlined, label: content);
      case MessageType.image:
        return (icon: Icons.image_outlined, label: content);
      case MessageType.video:
        return (icon: Icons.videocam_outlined, label: content);
      case MessageType.voice:
      case MessageType.audio:
        return (icon: Icons.mic_rounded, label: content);
      default:
        return (
          icon: null,
          label: content.isNotEmpty ? content : l10n.recentChatTileTapToOpen,
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isOfficial = chat.chatType == 'official';
    final textColor = isDark ? Colors.white : const Color(0xFF000000);
    final subtitleColor = isDark
        ? const Color(0xFF94A3B8)
        : const Color(0xFF64748B);

    final hasAvatar = chat.avatarUrl != null && chat.avatarUrl!.isNotEmpty;
    final avatarHeroTag = 'chat_avatar_${chat.conversationId}';

    final avatar = AvatarCircle(
      imageUrl: chat.avatarUrl,
      radius: 26,
      backgroundColor: Theme.of(context).primaryColor.withValues(alpha: 0.12),
      foregroundColor: Theme.of(context).primaryColor,
      fallback: chat.chatType == 'direct'
          ? Text(
              chat.title.isNotEmpty ? chat.title[0].toUpperCase() : '?',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            )
          : Icon(
              isOfficial ? Icons.campaign_rounded : Icons.groups_rounded,
              size: 22,
              color: Theme.of(context).primaryColor,
            ),
    );

    final leadingWidget = hasAvatar
        ? Hero(
            tag: avatarHeroTag,
            child: Material(
              type: MaterialType.circle,
              color: Colors.transparent,
              child: InkWell(
                customBorder: const CircleBorder(),
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => FullScreenImageViewer(
                      imageUrl: chat.avatarUrl!,
                      heroTag: avatarHeroTag,
                    ),
                  ),
                ),
                child: avatar,
              ),
            ),
          )
        : avatar;

    final titleWidget = Row(
      children: [
        Flexible(
          child: Text(
            toTitleCase(chat.title),
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
              color: textColor,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        if (isOfficial) ...[
          const SizedBox(width: 4),
          Icon(
            Icons.verified_rounded,
            size: 16,
            color: Theme.of(context).primaryColor,
          ),
        ],
      ],
    );

    final preview = _preview(context);

    final subtitleWidget = Row(
      children: [
        if (preview.icon != null) ...[
          Icon(preview.icon, size: 14, color: subtitleColor),
          const SizedBox(width: 4),
        ],
        Expanded(
          child: Text(
            preview.label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(fontSize: 14, color: subtitleColor),
          ),
        ),
      ],
    );

    final trailingWidget = Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (chat.lastMessageAt != null)
          Text(
            _formatTime(context, chat.lastMessageAt!),
            style: const TextStyle(fontSize: 12, color: Color(0xFF94A3B8)),
          ),
        const SizedBox(height: 4),
        if (chat.unreadCount > 0)
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: Theme.of(context).primaryColor,
              shape: BoxShape.circle,
            ),
            child: Text(
              chat.unreadCount > 99 ? '99+' : '${chat.unreadCount}',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 11,
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          )
        else if (chat.isPinned)
          const Icon(
            Icons.push_pin_outlined,
            size: 16,
            color: Color(0xFF94A3B8),
          ),
      ],
    );

    return InkWell(
      onTap: onTap,
      onLongPress: onLongPress,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 10),
        child: Row(
          children: [
            leadingWidget,
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  titleWidget,
                  const SizedBox(height: 4),
                  subtitleWidget,
                ],
              ),
            ),
            const SizedBox(width: 8),
            trailingWidget,
          ],
        ),
      ),
    );
  }

  String _formatTime(BuildContext context, DateTime dt) {
    final now = DateTime.now();
    final diff = now.difference(dt);
    if (diff.inDays == 0) {
      return '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
    }
    if (diff.inDays == 1) return AppLocalizations.of(context).commonYesterday;
    return '${dt.day}/${dt.month}';
  }
}
