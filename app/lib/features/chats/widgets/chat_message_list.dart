import 'package:flutter/material.dart';
import '../../../models/chat_message_model.dart';
import 'chat_body_widgets.dart';
import 'chat_bubble.dart';
import 'chat_wallpaper_painter.dart';
import 'swipe_to_reply.dart';
import 'package:talkmos/l10n/gen/app_localizations.dart';

class ChatMessageList extends StatefulWidget {
  final ScrollController scrollController;
  final List<ChatMessageModel> messages;
  final ThemeData theme;
  final bool isGroup;
  final String myId;
  final Set<String> selectedMessageIds;
  final String? highlightedMessageId;
  final bool isLoadingMore;
  final ValueChanged<ChatMessageModel> onToggleSelection;

  /// Goes to the message a reply is quoting, by its id.
  final ValueChanged<String> onJumpToMessage;
  final ValueChanged<ChatMessageModel> onSwipeToReply;
  final void Function(
    ChatMessageModel message,
    GlobalKey bubbleKey,
    Widget bubbleWidget,
    bool isMe,
  )
  onBubbleLongPress;

  const ChatMessageList({
    super.key,
    required this.scrollController,
    required this.messages,
    required this.theme,
    required this.isGroup,
    required this.myId,
    required this.selectedMessageIds,
    required this.highlightedMessageId,
    required this.isLoadingMore,
    required this.onToggleSelection,
    required this.onJumpToMessage,
    required this.onSwipeToReply,
    required this.onBubbleLongPress,
  });

  @override
  State<ChatMessageList> createState() => _ChatMessageListState();
}

class _ChatMessageListState extends State<ChatMessageList> {
  final Map<String, GlobalKey> _bubbleKeys = {};
  final Set<String> _expandedMessageIds = {};

  List<ChatMessageModel>? _derivedFrom;
  Map<String, ChatMessageModel> _byId = const {};
  List<ChatListEntry> _items = const [];

  void _rebuildDerived() {
    if (identical(_derivedFrom, widget.messages)) return;
    _derivedFrom = widget.messages;

    final byId = <String, ChatMessageModel>{};
    for (final m in widget.messages) {
      byId[m.id] = m;
    }
    _bubbleKeys.removeWhere((id, _) => !byId.containsKey(id));
    _expandedMessageIds.removeWhere((id) => !byId.containsKey(id));

    _byId = byId;
    _items = buildChatListEntries(widget.messages);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = widget.theme.brightness == Brightness.dark;

    _rebuildDerived();
    final byId = _byId;
    final items = _items;

    return Stack(
      children: [
        ListView.builder(
          controller: widget.scrollController,
          // Anchored at the bottom: the newest message is offset 0, so the
          // list opens on it, stays on it when the keyboard takes half the
          // screen, and doesn't lurch when older messages load in above.
          reverse: true,
          padding: const EdgeInsets.symmetric(vertical: 8),
          itemCount: items.length,
          itemBuilder: (context, index) {
            final entry = items[index];
            if (entry.date != null) {
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: ChatDateSeparator(date: entry.date!, isDark: isDark),
              );
            }
            final message = entry.message!;

            ChatMessageModel? repliedMessage;
            if (message.replyTo != null && message.replyTo!.isNotEmpty) {
              repliedMessage = byId[message.replyTo];
              if (repliedMessage == null) {
                // The quoted message is older than the loaded window.
                repliedMessage = ChatMessageModel(
                  id: message.replyTo!,
                  chatId: message.chatId,
                  senderId: '',
                  senderName: AppLocalizations.of(
                    context,
                  ).chatScreenOriginalMessageSender,
                  messageType: MessageType.text,
                  content: AppLocalizations.of(
                    context,
                  ).chatScreenOriginalMessageNotFound,
                  media: const MessageMedia(),
                  mentions: const [],
                  forwarded: false,
                  edited: false,
                  status: MessageStatus.sent,
                  isPinned: false,
                  deletedForEveryone: false,
                  deletedForMe: const [],
                  createdAt: DateTime.now(),
                  updatedAt: DateTime.now(),
                );
              }
            }

            final isSelected = widget.selectedMessageIds.contains(message.id);
            final isMe = message.senderId == widget.myId;
            final bubbleKey = _bubbleKeys.putIfAbsent(
              message.id,
              () => GlobalKey(),
            );
            final above = index + 1 < items.length ? items[index + 1] : null;
            final opensRun =
                above?.message == null ||
                above!.message!.senderId != message.senderId;

            final below = index > 0 ? items[index - 1] : null;
            final closesRun =
                below?.message == null ||
                below!.message!.senderId != message.senderId;

            final bubbleWidget = ChatBubble(
              message: message,
              isMe: isMe,
              theme: widget.theme,
              repliedMessage: repliedMessage,
              isSelected: isSelected,
              isHighlighted: widget.highlightedMessageId == message.id,
              isGroup: widget.isGroup,
              opensRun: opensRun,
              closesRun: closesRun,
              isExpanded: _expandedMessageIds.contains(message.id),
              onReplyTap: repliedMessage == null
                  ? null
                  : () => widget.onJumpToMessage(repliedMessage!.id),
              onToggleExpanded: () => setState(() {
                if (!_expandedMessageIds.remove(message.id)) {
                  _expandedMessageIds.add(message.id);
                }
              }),
            );

            return SwipeToReply(
              onSwipe: widget.selectedMessageIds.isNotEmpty
                  ? null
                  : () => widget.onSwipeToReply(message),
              child: GestureDetector(
                onTap: () {
                  FocusScope.of(context).unfocus();
                  if (widget.selectedMessageIds.isNotEmpty) {
                    widget.onToggleSelection(message);
                  }
                },
                onLongPress: () => widget.selectedMessageIds.isNotEmpty
                    ? widget.onToggleSelection(message)
                    : widget.onBubbleLongPress(
                        message,
                        bubbleKey,
                        bubbleWidget,
                        isMe,
                      ),
                child: Container(key: bubbleKey, child: bubbleWidget),
              ),
            );
          },
        ),
        if (widget.isLoadingMore)
          const Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: LinearProgressIndicator(minHeight: 2),
          ),
      ],
    );
  }
}
