import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:talkmos/core/router/app_router.dart';
import 'package:talkmos/core/widgets/emoji_picker_sheet.dart';
import 'package:talkmos/features/calls/services/call_signaling/call_signaling_service.dart';
import 'package:talkmos/core/services/token_manager.dart';
import 'package:talkmos/features/chats/widgets/chat_header.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_contacts/flutter_contacts.dart';
import 'package:geolocator/geolocator.dart';
import '../../../../models/chat_message_model.dart';
import '../../../../models/shared_attachment_payloads.dart';
import '../../../../models/user_model.dart';
import '../../../../core/utils/titlecase_function.dart';
import '../../../../providers/chat_provider.dart';
import '../../../../providers/block_provider.dart';
import '../../../../core/translation/app_language.dart';
import '../../../../core/services/translation_preference_store.dart';
import '../../../../core/notifications/message_notifier.dart';
import '../../controllers/chat_media_controller.dart';
import '../../controllers/voice_recorder_controller.dart';
import '../../services/chat_service/chat_service.dart';
import '../../services/socket_service/socket_service.dart';
import '../../widgets/attachment_sheet.dart';
import '../../widgets/chat_body_widgets.dart';
import '../../widgets/chat_input_bar.dart';
import '../../widgets/chat_message_list.dart';
import '../../widgets/chat_selection_app_bar.dart';
import '../../widgets/chat_skeleton_loader.dart';
import '../../widgets/chat_wallpaper_image.dart';
import '../../widgets/context_action_menu.dart';
import '../../widgets/forward_message_sheet.dart';
import '../../widgets/pinned_message_banner.dart';
import '../../../../providers/settings_provider.dart';
import '../../widgets/chat_wallpaper_painter.dart';
import '../group_profile_screen.dart';
import '../media_preview_screen.dart';
import '../../../community/screens/community_detail_screen.dart';
import '../../../users/screens/user_profile_screen.dart';
import 'package:talkmos/l10n/gen/app_localizations.dart';

part 'toggle_message_selection.dart';
part 'clear_selection.dart';
part 'copy_selected_messages.dart';
part 'reply_selected_message.dart';
part 'delete_selected_messages.dart';
part 'delete_single_message.dart';
part 'confirm_and_delete.dart';
part 'perform_delete.dart';
part 'on_text_changed.dart';
part 'init_socket.dart';
part 'on_provider_changed.dart';
part 'load_chat.dart';
part 'open_chat_info.dart';
part 'load_pinned_messages.dart';
part 'start_call.dart';
part 'on_recorder_changed.dart';
part 'on_call_state_changed.dart';
part 'start_recording.dart';
part 'cancel_recording.dart';
part 'stop_and_send_recording.dart';
part 'confirm_media_in_preview.dart';
part 'clear_reply_after_send.dart';
part 'show_snack.dart';
part 'scroll_to_and_highlight_message.dart';
part 'scroll_to_bottom.dart';
part 'on_scroll.dart';
part 'load_more_messages.dart';
part 'send_message.dart';
part 'start_editing_message.dart';
part 'handle_bubble_long_press.dart';
part 'translate_message.dart';
part 'copy_single_message.dart';
part 'show_full_emoji_picker.dart';
part 'show_forward_sheet.dart';
part 'media_meta_of.dart';
part 'on_attachment_pressed.dart';
part 'send_document.dart';
part 'send_contact.dart';
part 'send_location.dart';
part 'send_gallery_media.dart';
part 'send_video.dart';
part 'send_single_photo.dart';

class ChatScreen extends StatefulWidget {
  final UserModel activeUser;
  final String chatId;
  final String chatType; // 'direct' | 'group' | 'community'

  const ChatScreen({
    super.key,
    required this.activeUser,
    required this.chatId,
    required this.chatType,
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  // Cached provider references — safe to use in dispose() and listeners
  // where context lookups are forbidden.
  late SocketService _socketService;
  late ChatProvider _chatProvider;
  CallSignalingService? _signaling;

  bool _isTextEmpty = true;
  bool _isOnline = false;
  DateTime? _peerLastSeenAt;
  Set<String> _typingUserIds = {};

  // Typing debounce — stops typing event 1.5 s after the user pauses
  Timer? _typingDebounce;
  bool _isTypingSent = false;
  String? _lastMessageId;

  ChatMessageModel? _replyingToMessage;
  ChatMessageModel? _editingMessage;
  final Set<String> _selectedMessageIds = {};
  List<ChatMessageModel> _pinnedMessages = [];
  String? _highlightedMessageId;

  final VoiceRecorderController _recorder = VoiceRecorderController();
  // Reassigned rather than `late final` because didChangeDependencies can run
  // more than once for a single State.
  late ChatMediaSender _mediaSender;

  bool _isCalling = false;

  static const double _loadMoreThreshold = 200;

  /// How far off the newest message the user can be and still count as
  /// following along — past this, an arriving message must not yank them back.
  static const double _atBottomThreshold = 120;

  void _setState(VoidCallback fn) => setState(fn);

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Cache once — these never change for the lifetime of this screen.
    _socketService = context.read<SocketService>();
    _chatProvider = context.read<ChatProvider>();

    final signaling = context.read<CallSignalingService>();
    if (!identical(signaling, _signaling)) {
      _signaling?.removeListener(_onCallStateChanged);
      _signaling = signaling..addListener(_onCallStateChanged);
    }
    _mediaSender = ChatMediaSender(
      chatProvider: _chatProvider,
      chatId: widget.chatId,
      isDirect: widget.chatType == 'direct',
    );

    // Sync initial typing indicator state
    final typing = _chatProvider.typingUsers[widget.chatId];
    if (typing != null) {
      _typingUserIds = Set<String>.from(typing);
    }
  }

  @override
  void initState() {
    super.initState();
    _messageController.addListener(_onTextChanged);
    _scrollController.addListener(_onScroll);
    // Suppress (and clear) message notifications for the chat being read.
    MessageNotifier.activeChatId = widget.chatId;
    MessageNotifier.clearFor(widget.chatId);
    // Repaint the input bar as the recording timer ticks.
    _recorder.addListener(_onRecorderChanged);
    WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());
    WidgetsBinding.instance.addPostFrameCallback((_) => _initSocket());
  }

  @override
  void dispose() {
    _typingDebounce?.cancel();
    // Stop typing if user leaves mid-composition
    if (_isTypingSent) {
      _socketService.sendStopTyping(widget.chatId);
    }
    final socket = _socketService;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      socket.leaveChat();
    });
    if (MessageNotifier.activeChatId == widget.chatId) {
      MessageNotifier.activeChatId = null;
    }
    _signaling?.removeListener(_onCallStateChanged);
    _recorder.removeListener(_onRecorderChanged);
    _recorder.dispose();
    _chatProvider.onUserOnlineStatus = null;
    _chatProvider.onMessagePinned = null;
    _chatProvider.removeListener(_onProviderChanged);
    _chatProvider.activeChatId = null;
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final settings = context.watch<SettingsProvider>();
    final isBlocked =
        widget.chatType == 'direct' &&
        context.watch<BlockProvider>().isBlocked(widget.activeUser.id);

    return Consumer<ChatProvider>(
      builder: (context, provider, _) {
        final isLoading = provider.isLoadingMessagesFor(widget.chatId);
        final messages = provider.messages[widget.chatId] ?? [];
        final myId = provider.user?.id ?? '';
        return Scaffold(
          appBar: _selectedMessageIds.isNotEmpty
              ? ChatSelectionAppBar(
                  messages: messages,
                  selectedMessageIds: _selectedMessageIds,
                  isDark: isDark,
                  onClose: _clearSelection,
                  onCopy: () => _copySelectedMessages(messages),
                  onReply: (_) => _replySelectedMessage(messages),
                  onTogglePin: (message) {
                    _chatProvider.togglePinMessage(
                      widget.chatId,
                      message.id,
                      !message.isPinned,
                    );
                    _clearSelection();
                  },
                  onDelete: () => _deleteSelectedMessages(messages, myId),
                )
              : ChatHeader(
                  peerName: widget.activeUser.name,
                  peerAvatarUrl: widget.activeUser.avatarUrl,
                  isDark: isDark,
                  isOnline: _isOnline,
                  lastSeenAt: widget.chatType == 'direct'
                      ? _peerLastSeenAt
                      : null,
                  isTyping: _typingUserIds.isNotEmpty,
                  onBack: () => Navigator.pop(context),
                  onTap: _openChatInfo,
                  actions: [
                    // Calling is available for direct and group chats (not
                    // large communities).
                    if (widget.chatType == 'direct' ||
                        widget.chatType == 'group') ...[
                      if (_isCalling)
                        Padding(
                          padding: EdgeInsets.symmetric(horizontal: 12),
                          child: SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Theme.of(context).primaryColor,
                            ),
                          ),
                        )
                      else
                        // Dimmed rather than removed while a voice note is
                        // recording: tapping still explains why it is refused.
                        Opacity(
                          opacity: _recorder.isRecording ? 0.4 : 1,
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.videocam_rounded),
                                onPressed: () => _startCall(isVideo: true),
                                tooltip: l10n.chatScreenVideoCall,
                              ),
                              IconButton(
                                icon: const Icon(Icons.phone_rounded),
                                onPressed: () => _startCall(isVideo: false),
                                tooltip: l10n.chatScreenVoiceCall,
                              ),
                            ],
                          ),
                        ),
                    ],
                  ],
                ),
          body: PopScope(
            canPop: _selectedMessageIds.isEmpty,
            onPopInvokedWithResult: (didPop, result) {
              if (didPop) return;
              _clearSelection();
            },
            child: SafeArea(
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () => FocusScope.of(context).unfocus(),
                child: Container(
                  color: settings.chatWallpaperColor,
                  child: Stack(
                    children: [
                      if (settings.chatWallpaperImagePath != null)
                        Positioned.fill(
                          child: ChatWallpaperImage(
                            path: settings.chatWallpaperImagePath!,
                            opacity: settings.chatWallpaperOpacity,
                          ),
                        ),
                      if (settings.showDoodles)
                        Positioned.fill(
                          child: CustomPaint(
                            painter: WhatsAppWallpaperPainter(
                              color: isDark
                                  ? Colors.white.withValues(alpha: 0.02)
                                  : settings.primaryColor.withValues(
                                      alpha: 0.02,
                                    ),
                            ),
                          ),
                        ),
                      Column(
                        children: [
                          PinnedMessageBanner(
                            pinnedMessages: _pinnedMessages,
                            isDark: isDark,
                            onTapMessage: _scrollToAndHighlightMessage,
                            onUnpin: (messageId) =>
                                _chatProvider.togglePinMessage(
                                  widget.chatId,
                                  messageId,
                                  false,
                                ),
                          ),
                          ChatPrivacyBanner(isDark: isDark),
                          Expanded(
                            child: isLoading
                                ? ChatSkeletonLoader(isDark: isDark)
                                : messages.isEmpty
                                ? ChatEmptyState(
                                    isDark: isDark,
                                    peerName: widget.activeUser.name,
                                  )
                                : ChatMessageList(
                                    scrollController: _scrollController,
                                    messages: messages,
                                    theme: theme,
                                    isGroup: widget.chatType != 'direct',
                                    myId: myId,
                                    selectedMessageIds: _selectedMessageIds,
                                    highlightedMessageId: _highlightedMessageId,
                                    isLoadingMore: _chatProvider
                                        .isLoadingMoreMessages(widget.chatId),
                                    onToggleSelection: _toggleMessageSelection,
                                    onJumpToMessage:
                                        _scrollToAndHighlightMessage,
                                    onSwipeToReply: (message) => setState(() {
                                      _replyingToMessage = message;
                                      _editingMessage = null;
                                    }),
                                    onBubbleLongPress:
                                        (
                                          message,
                                          bubbleKey,
                                          bubbleWidget,
                                          isMe,
                                        ) => _handleBubbleLongPress(
                                          message,
                                          bubbleKey,
                                          bubbleWidget,
                                          isMe,
                                          myId,
                                        ),
                                  ),
                          ),
                          if (isBlocked)
                            BlockedContactBar(
                              isDark: isDark,
                              peerName: widget.activeUser.name,
                              onUnblock: () => context
                                  .read<BlockProvider>()
                                  .unblockUser(widget.activeUser.id),
                            )
                          else
                            ChatInputBar(
                              controller: _messageController,
                              isTextEmpty: _isTextEmpty,
                              isDark: isDark,
                              onSend: _sendMessage,
                              onAttachment: () => _onAttachmentPressed(isDark),
                              camera: () =>
                                  _sendSinglePhoto(ImageSource.camera),
                              replyingToMessage: _replyingToMessage,
                              onCancelReply: () =>
                                  setState(() => _replyingToMessage = null),
                              editingMessage: _editingMessage,
                              onCancelEdit: () {
                                setState(() => _editingMessage = null);
                                _messageController.clear();
                              },
                              isRecording: _recorder.isRecording,
                              recordingDuration: _recorder.elapsedLabel,
                              onStartRecording: _startRecording,
                              onStopRecording: _stopAndSendRecording,
                              onCancelRecording: _cancelRecording,
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
