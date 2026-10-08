import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:talkmos/core/utils/titlecase_function.dart';
import 'package:talkmos/l10n/gen/app_localizations.dart';
import '../../../models/chat_message_model.dart';
import '../../../providers/chat_provider.dart';
import 'bubble_shape.dart';
import 'message_content/deleted_message_content.dart';
import 'message_content/text_message_content.dart';
import 'message_content/image_message_content.dart';
import 'message_content/video_message_content.dart';
import 'message_content/voice_message_player.dart';
import 'message_content/document_message_content.dart';
import 'message_content/contact_message_content.dart';
import 'message_content/location_message_content.dart';
import 'quoted_message_preview.dart';

/// A single chat message bubble with timestamp and delivery tick.
class ChatBubble extends StatelessWidget {
  final ChatMessageModel message;
  final bool isMe;
  final ThemeData theme;
  final ChatMessageModel? repliedMessage;
  final bool isSelected;
  final bool isHighlighted;
  final bool isGroup;

  /// First bubble of a run from one sender — the one that gets the tail and
  /// the avatar.
  final bool opensRun;

  /// Last bubble of a run. Only affects the spacing below it.
  final bool closesRun;

  /// Held by the list rather than the bubble: a bubble scrolled out of view is
  /// disposed, and local state would collapse it again on the way back.
  final bool isExpanded;
  final VoidCallback? onToggleExpanded;

  /// Jumps to the message this one is quoting. Null where there is nothing to
  /// scroll — the long-press overlay renders a bubble out of the list.
  final VoidCallback? onReplyTap;

  const ChatBubble({
    super.key,
    required this.message,
    required this.isMe,
    required this.theme,
    this.repliedMessage,
    this.isSelected = false,
    this.isHighlighted = false,
    this.isGroup = false,
    this.opensRun = false,
    this.closesRun = true,
    this.isExpanded = false,
    this.onToggleExpanded,
    this.onReplyTap,
  });

  /// Width of the avatar column reserved beside incoming group messages.
  static const double _avatarSize = 32;
  static const double _avatarGap = 8;

  /// Media carries its own surface, so the bubble around it is a 3px frame
  /// rather than the text bubble's padding.
  static const EdgeInsets _textPadding = EdgeInsets.only(
    left: 12,
    right: 10,
    top: 8,
    bottom: 6,
  );
  static const EdgeInsets _mediaPadding = EdgeInsets.all(3);

  /// Horizontal inset for the parts that sit beside media inside a media
  /// bubble — the sender label, the reply block and the caption.
  static const EdgeInsets _mediaInset = EdgeInsets.symmetric(horizontal: 7);

  bool get _isMediaBubble =>
      message.messageType == MessageType.image ||
      message.messageType == MessageType.video;

  /// Whether the caption text under a photo is worth showing — the senders
  /// put placeholders in `content` when there is nothing to say.
  bool get _hasCaption {
    final text = message.content;
    if (text.isEmpty) return false;
    if (text == '[Media]' || text == '[Video]') return false;
    return !text.startsWith('[Media:');
  }

  @override
  Widget build(BuildContext context) {
    final isDark = theme.brightness == Brightness.dark;

    final Color bubbleColor = isMe
        ? (isDark ? const Color(0xFF1E3A8A) : const Color(0xFFE8F2FF))
        : (isDark ? const Color(0xFF000814) : Colors.white);
    final Color textColor = isMe
        ? (isDark ? Colors.white : const Color(0xFF000000))
        : (isDark ? Colors.white : const Color(0xFF000000));
    // One muted tone for both sides. The timestamp used to take the primary
    // colour on outgoing bubbles, which put blue on a pale blue bubble.
    final Color metaColor = isDark
        ? const Color(0xFF8696A0)
        : const Color(0xFF667781);

    return Container(
      color: isSelected
          ? (isDark
                ? Theme.of(context).primaryColor.withValues(alpha: 0.16)
                : Theme.of(context).primaryColor.withValues(alpha: 0.08))
          : (isHighlighted
                ? (isDark
                      ? Theme.of(context).primaryColor.withValues(alpha: 0.28)
                      : Theme.of(context).primaryColor.withValues(alpha: 0.18))
                : Colors.transparent),
      width: double.infinity,
      padding: EdgeInsets.only(left: isGroup && !isMe ? 8 : 16, right: 16),
      child: _withAvatarGutter(
        context,
        isDark,
        Align(
          alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
          child: Column(
            crossAxisAlignment: isMe
                ? CrossAxisAlignment.end
                : CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                // Bubbles inside a run sit closer together than the gap
                // between one person's run and the next.
                margin: EdgeInsets.only(
                  top: opensRun ? 4 : 1.5,
                  bottom: closesRun ? 4 : 1.5,
                ),
                padding: _isMediaBubble ? _mediaPadding : _textPadding,
                constraints: BoxConstraints(
                  maxWidth: MediaQuery.of(context).size.width * 0.85,
                ),
                // The shape reserves the tail's width on every bubble and
                // draws the point only on the first of a run, so the column
                // edge stays straight down the whole run.
                decoration: ShapeDecoration(
                  color: bubbleColor,
                  shape: BubbleShape(isMe: isMe, showTail: opensRun),
                  shadows: [
                    BoxShadow(
                      color: Colors.black.withValues(
                        alpha: isDark ? 0.22 : 0.10,
                      ),
                      blurRadius: 1,
                      offset: const Offset(0, 1),
                    ),
                  ],
                ),
                child: Builder(
                  builder: (context) {
                    final isAudio =
                        message.messageType == MessageType.voice ||
                        message.messageType == MessageType.audio;
                    final body = _buildMessageBody(
                      textColor,
                      metaColor,
                      isDark,
                      context,
                    );
                    // The player needs a fixed track width; everything else
                    // sizes to its own content, which a Column already does —
                    // IntrinsicWidth only made every bubble lay out twice.
                    return isAudio ? SizedBox(width: 240, child: body) : body;
                  },
                ),
              ),
              if (message.reactions.isNotEmpty) _buildReactions(isDark),
            ],
          ),
        ),
      ),
    );
  }

  Widget _withAvatarGutter(BuildContext context, bool isDark, Widget child) {
    if (!isGroup || isMe) return child;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: _avatarSize,
          // The gutter is reserved for every message of a run so the column
          // stays straight; only the first one fills it.
          child: opensRun
              ? Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: _SenderAvatar(
                    name: _getSenderName(context),
                    avatarUrl: message.senderAvatarUrl,
                    color: _getSenderColor(message.senderId, isDark),
                    size: _avatarSize,
                  ),
                )
              : null,
        ),
        const SizedBox(width: _avatarGap),
        Expanded(child: child),
      ],
    );
  }

  /// Compact pill under the bubble showing each distinct emoji and how many
  /// people reacted with it.
  Widget _buildReactions(bool isDark) {
    final counts = <String, int>{};
    for (final r in message.reactions) {
      if (r is! Map) continue;
      final e = r['emoji']?.toString();
      if (e == null || e.isEmpty) continue;
      counts[e] = (counts[e] ?? 0) + 1;
    }
    if (counts.isEmpty) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.only(top: 1, bottom: 2),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF000814) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.08)
              : const Color(0xFFE2E8F0),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 2,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (final entry in counts.entries) ...[
            Text(entry.key, style: const TextStyle(fontSize: 13)),
            if (entry.value > 1) ...[
              const SizedBox(width: 2),
              Text(
                '${entry.value}',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: isDark ? Colors.white70 : const Color(0xFF64748B),
                ),
              ),
            ],
            const SizedBox(width: 6),
          ],
        ],
      ),
    );
  }

  Widget _buildTranslatingStatus(Color metaColor, BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 10,
            height: 10,
            child: CircularProgressIndicator(
              strokeWidth: 1.5,
              valueColor: AlwaysStoppedAnimation(metaColor),
            ),
          ),
          const SizedBox(width: 6),
          Text(
            AppLocalizations.of(context).chatScreenTranslating,
            style: TextStyle(
              fontSize: 11,
              fontStyle: FontStyle.italic,
              color: metaColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTranslatedText(
    String translated,
    Color textColor,
    Color metaColor,
    bool isDark,
    BuildContext context,
  ) {
    return Container(
      margin: const EdgeInsets.only(top: 6),
      padding: const EdgeInsets.only(top: 6),
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(
            color: isDark
                ? Colors.white.withValues(alpha: 0.12)
                : Colors.black.withValues(alpha: 0.08),
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.translate_rounded, size: 11, color: metaColor),
              const SizedBox(width: 4),
              Text(
                AppLocalizations.of(context).chatScreenTranslated,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: metaColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 2),
          Text(
            translated,
            style: TextStyle(
              fontSize: 15,
              fontStyle: FontStyle.italic,
              color: textColor,
            ),
          ),
        ],
      ),
    );
  }

  static String _formatTime(DateTime dateTime) {
    final t = dateTime.toLocal();
    return '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';
  }

  Widget _buildMessageBody(
    Color textColor,
    Color metaColor,
    bool isDark,
    BuildContext context,
  ) {
    if (message.deletedForEveryone) {
      // Was returning with no meta at all, so a deleted message was the one
      // kind with no time on it.
      return _buildTextWithInlineMeta(
        DeletedMessageContent(metaColor: metaColor),
        metaColor,
        context,
      );
    }

    final chatProvider = Provider.of<ChatProvider>(context, listen: false);
    final localBytes = chatProvider.getLocalMedia(message.id);
    final localThumbnailBytes = chatProvider.getLocalThumbnail(message.id);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        // Paired with the avatar: both mark the start of a run, so a burst of
        // messages from one person is labelled once instead of on every bubble.
        if (isGroup && !isMe && opensRun)
          Padding(
            // A media bubble's own padding is only 3, so the label carries the
            // inset that the text bubble gets from the container.
            padding: _isMediaBubble
                ? const EdgeInsets.only(top: 4, bottom: 5, left: 7, right: 8)
                : const EdgeInsets.only(bottom: 4, left: 2, right: 8),
            child: Text(
              toTitleCase(_getSenderName(context)),
              style: TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.bold,
                color: _getSenderColor(message.senderId, isDark),
              ),
            ),
          ),
        if (repliedMessage != null)
          _ReplyQuote(
            message: repliedMessage!,
            textColor: textColor,
            isDark: isDark,
            margin: _isMediaBubble
                ? const EdgeInsets.fromLTRB(4, 1, 4, 5)
                : const EdgeInsets.only(bottom: 6),
            onTap: onReplyTap,
          ),
        if (message.messageType == MessageType.voice ||
            message.messageType == MessageType.audio) ...[
          VoiceMessagePlayer(
            audioUrl: message.media.url,
            durationSeconds: message.media.duration,
            textColor: textColor,
            metaColor: metaColor,
            isMe: isMe,
            // Shares the line with the clip duration instead of adding a
            // third row to an already tall bubble.
            trailing: _buildMetaRow(metaColor, context),
          ),
        ] else if (_isMediaBubble) ...[
          // The media fills the bubble; without a caption the meta rides on
          // top of it in a scrim, which is the only way it stays readable
          // over an arbitrary photo.
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: Stack(
              children: [
                if (message.messageType == MessageType.image)
                  ImageMessageContent(
                    message: message,
                    textColor: textColor,
                    localBytes: localBytes,
                  )
                else
                  VideoMessageContent(
                    message: message,
                    localBytes: localBytes,
                    localThumbnailBytes: localThumbnailBytes,
                  ),
                if (!_hasCaption)
                  Positioned(
                    right: 6,
                    bottom: 6,
                    child: _MetaScrim(
                      child: _buildMetaRow(Colors.white, context),
                    ),
                  ),
              ],
            ),
          ),
          if (_hasCaption) ...[
            const SizedBox(height: 6),
            Padding(
              padding: _mediaInset,
              child: _buildTextWithInlineMeta(
                Text(
                  message.content,
                  style: TextStyle(fontSize: 14, color: textColor),
                ),
                metaColor,
                context,
              ),
            ),
            const SizedBox(height: 4),
          ],
        ] else if (message.messageType == MessageType.file)
          // Each of these cards ends in a muted detail line, which is where
          // the time belongs — same rule as a photo's caption. A row of its
          // own underneath just made the bubble taller.
          DocumentMessageContent(
            message: message,
            textColor: textColor,
            trailing: _buildMetaRow(metaColor, context),
          )
        else if (message.messageType == MessageType.contact)
          ContactMessageContent(
            content: message.content,
            textColor: textColor,
            trailing: _buildMetaRow(metaColor, context),
          )
        else if (message.messageType == MessageType.location)
          LocationMessageContent(
            content: message.content,
            textColor: textColor,
            trailing: _buildMetaRow(metaColor, context),
          )
        else ...[
          if (chatProvider.isTranslating(message.id)) ...[
            TextMessageContent(
              content: message.content,
              textColor: textColor,
              isExpanded: isExpanded,
              onToggleExpanded: onToggleExpanded,
            ),
            _buildTranslatingStatus(metaColor, context),
            const SizedBox(height: 4),
            _buildMetaRow(metaColor, context),
          ] else if (chatProvider.getTranslation(message.id) != null) ...[
            TextMessageContent(
              content: message.content,
              textColor: textColor,
              isExpanded: isExpanded,
              onToggleExpanded: onToggleExpanded,
            ),
            _buildTranslatedText(
              chatProvider.getTranslation(message.id)!,
              textColor,
              metaColor,
              isDark,
              context,
            ),
            const SizedBox(height: 4),
            _buildMetaRow(metaColor, context),
          ] else
            // Plain text is the one case where the time can share the last
            // line, so "ok" is one line tall instead of two.
            _buildTextWithInlineMeta(
              TextMessageContent(
                content: message.content,
                textColor: textColor,
                isExpanded: isExpanded,
                onToggleExpanded: onToggleExpanded,
              ),
              metaColor,
              context,
            ),
        ],
      ],
    );
  }

  /// Lays the meta out beside the text when the last line leaves room, and
  /// drops it to its own right-aligned line when it does not.
  Widget _buildTextWithInlineMeta(
    Widget text,
    Color metaColor,
    BuildContext context,
  ) {
    return Wrap(
      alignment: WrapAlignment.end,
      crossAxisAlignment: WrapCrossAlignment.end,
      spacing: 8,
      runSpacing: 2,
      children: [text, _buildMetaRow(metaColor, context)],
    );
  }

  Widget _buildMetaRow(Color metaColor, BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        if (message.isPinned) ...[
          Icon(Icons.push_pin_rounded, size: 11, color: metaColor),
          const SizedBox(width: 4),
        ],
        if (message.edited && !message.deletedForEveryone) ...[
          Text(
            AppLocalizations.of(context).chatBubbleEdited,
            style: TextStyle(
              fontSize: 10,
              fontStyle: FontStyle.italic,
              color: metaColor,
            ),
          ),
          const SizedBox(width: 4),
        ],
        Text(
          _formatTime(message.createdAt),
          style: TextStyle(fontSize: 10, color: metaColor),
        ),
        if (isMe) ...[
          const SizedBox(width: 4),
          ChatTickIndicator(status: message.status, color: metaColor),
        ],
      ],
    );
  }

  String _getSenderName(BuildContext context) {
    if (message.senderName.isNotEmpty) return message.senderName;
    try {
      final chatProvider = Provider.of<ChatProvider>(context, listen: false);
      final activeChat = chatProvider.activeChatDetails;
      final members =
          (activeChat['members'] as List?) ??
          (activeChat['participants'] as List?);
      if (members != null) {
        for (final m in members) {
          if (m is Map) {
            final userObj = m['userId'];
            if (userObj is Map) {
              final uId =
                  userObj['_id']?.toString() ?? userObj['id']?.toString();
              if (uId == message.senderId) {
                final uName = userObj['name']?.toString();
                if (uName != null && uName.isNotEmpty) return uName;
              }
            } else if (userObj?.toString() == message.senderId) {
              final uName = m['name']?.toString();
              if (uName != null && uName.isNotEmpty) return uName;
            }
          }
        }
      }
    } catch (_) {}
    return AppLocalizations.of(context).commonMember;
  }

  Color _getSenderColor(String senderId, bool isDark) {
    final colors = isDark
        ? const [
            Color(0xFF818CF8), // Indigo
            Color(0xFF34D399), // Emerald
            Color(0xFFFBBF24), // Amber
            Color(0xFFF472B6), // Pink
            Color(0xFF38BDF8), // Sky
            Color(0xFFA78BFA), // Purple
            Color(0xFFFB923C), // Orange
          ]
        : const [
            Color(0xFF4F46E5), // Indigo
            Color(0xFF059669), // Emerald
            Color(0xFFD97706), // Amber
            Color(0xFFDB2777), // Pink
            Color(0xFF0284C7), // Sky
            Color(0xFF7C3AED), // Purple
            Color(0xFFEA580C), // Orange
          ];
    final hash = senderId.hashCode.abs();
    return colors[hash % colors.length];
  }
}

/// Renders the appropriate delivery-status tick icon for a message.
class ChatTickIndicator extends StatelessWidget {
  final MessageStatus status;

  /// Matched to the bubble the tick sits on. It used to be hardcoded white,
  /// which is invisible on the light outgoing bubble.
  final Color color;

  const ChatTickIndicator({
    super.key,
    required this.status,
    this.color = Colors.white70,
  });

  /// Read stays its own colour in every theme — it is the one state people
  /// actually look for, and a tick that only differs by count is missable.
  static const Color readColor = Color(0xFF34B7F1);

  @override
  Widget build(BuildContext context) {
    switch (status) {
      case MessageStatus.sending:
        return Icon(
          Icons.access_time_rounded,
          size: 13,
          color: color.withValues(alpha: 0.7),
        );
      case MessageStatus.sent:
        return Icon(Icons.done_rounded, size: 15, color: color);
      case MessageStatus.delivered:
        return Icon(Icons.done_all_rounded, size: 15, color: color);
      case MessageStatus.read:
        return const Icon(Icons.done_all_rounded, size: 15, color: readColor);
      case MessageStatus.failed:
        return const Icon(
          Icons.error_outline_rounded,
          size: 15,
          color: Colors.redAccent,
        );
    }
  }
}

/// Keeps the timestamp legible where it sits over a photo, whatever the photo
/// happens to be behind it.
class _MetaScrim extends StatelessWidget {
  final Widget child;

  const _MetaScrim({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.38),
        borderRadius: BorderRadius.circular(10),
      ),
      child: child,
    );
  }
}

class _SenderAvatar extends StatelessWidget {
  const _SenderAvatar({
    required this.name,
    required this.avatarUrl,
    required this.color,
    required this.size,
  });

  final String name;
  final String avatarUrl;
  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) {
    final initial = name.trim().isEmpty ? '?' : name.trim()[0].toUpperCase();
    return ClipOval(
      child: SizedBox(
        width: size,
        height: size,
        child: avatarUrl.isEmpty
            ? _initials(initial)
            : CachedNetworkImage(
                imageUrl: avatarUrl,
                fit: BoxFit.cover,
                // Sized to what is actually drawn: without this every avatar in
                // the thread decodes at full source resolution.
                memCacheWidth: (size * MediaQuery.devicePixelRatioOf(context))
                    .round(),
                fadeInDuration: const Duration(milliseconds: 120),
                placeholder: (_, _) => _initials(initial),
                errorWidget: (_, _, _) => _initials(initial),
              ),
      ),
    );
  }

  Widget _initials(String initial) => ColoredBox(
    color: color.withValues(alpha: 0.18),
    child: Center(
      child: Text(
        initial,
        style: TextStyle(
          fontSize: size * 0.42,
          fontWeight: FontWeight.w700,
          color: color,
        ),
      ),
    ),
  );
}

/// The quoted message shown above a reply.
///
/// Tapping it goes to the original. Media quotes carry a thumbnail and a word
/// for what they are — quoting a photo used to leave a blank line, since a
/// media message has no text of its own.
class _ReplyQuote extends StatelessWidget {
  const _ReplyQuote({
    required this.message,
    required this.textColor,
    required this.isDark,
    required this.margin,
    this.onTap,
  });

  final ChatMessageModel message;

  /// The bubble's own text colour. Both bubbles are light in light mode and
  /// dark in dark mode, so the quote takes its contrast from the same place
  /// rather than assuming an outgoing bubble is dark.
  final Color textColor;
  final bool isDark;
  final EdgeInsets margin;
  final VoidCallback? onTap;

  static const double _thumbnailSize = 38;

  @override
  Widget build(BuildContext context) {
    final accent = isDark ? Colors.white : Theme.of(context).primaryColor;
    final preview = quotedPreviewOf(context, message);
    final thumbnail = quotedThumbnailOf(message);
    final bodyColor = textColor.withValues(alpha: 0.7);

    return Container(
      margin: margin,
      decoration: BoxDecoration(
        // A shade of whatever the bubble already is, rather than a grey slab
        // laid over it.
        color: isDark
            ? Colors.white.withValues(alpha: 0.08)
            : Colors.black.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(8),
      ),
      clipBehavior: Clip.antiAlias,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          // Sized by its content rather than a fixed height, so the accent bar
          // matches however tall the quote turns out to be.
          child: IntrinsicHeight(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Container(width: 3.5, color: accent),
                Flexible(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(8, 5, 8, 5),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          toTitleCase(message.senderName),
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: accent,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (preview.icon != null) ...[
                              Icon(preview.icon, size: 13, color: bodyColor),
                              const SizedBox(width: 4),
                            ],
                            Flexible(
                              child: Text(
                                preview.label,
                                style: TextStyle(
                                  fontSize: 11,
                                  color: bodyColor,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                if (thumbnail != null)
                  CachedNetworkImage(
                    imageUrl: thumbnail,
                    width: _thumbnailSize,
                    height: _thumbnailSize,
                    fit: BoxFit.cover,
                    errorWidget: (_, _, _) => const SizedBox.shrink(),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
