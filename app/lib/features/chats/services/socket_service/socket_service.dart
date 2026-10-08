import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;
import '../../../../core/config/api_config.dart';
import '../../../../core/services/socket_auth_error.dart';
import '../../../../models/chat_message_model.dart';
import '../../../../models/converters/local_date_time_converter.dart';

part 'add_optimistic_message.dart';
part 'load_history.dart';
part 'enter_chat.dart';
part 'leave_chat.dart';
part 'connect.dart';
part 'handle_socket_connected.dart';
part 'handle_socket_disconnected.dart';
part 'handle_receive_chat_message.dart';
part 'handle_message_sent.dart';
part 'handle_message_delivered.dart';
part 'handle_messages_read.dart';
part 'handle_user_typing.dart';
part 'handle_user_stop_typing.dart';
part 'handle_user_online_status.dart';
part 'handle_message_deleted.dart';
part 'handle_message_edited.dart';
part 'handle_message_pinned.dart';
part 'handle_message_reaction.dart';
part 'handle_friend_request_received.dart';
part 'handle_friend_request_updated.dart';
part 'handle_conversation_deleted.dart';
part 'join_chat_room.dart';
part 'update_message_status.dart';
part 'mark_all_messages_read_by.dart';
part 'handle_local_message_deleted.dart';
part 'handle_local_message_pinned.dart';
part 'send_typing.dart';
part 'send_stop_typing.dart';
part 'delete_message.dart';
part 'edit_message.dart';
part 'send_message.dart';
part 'mark_messages_read.dart';
part 'check_user_online.dart';
part 'clear_messages.dart';
part 'disconnect.dart';

class SocketService with ChangeNotifier {
  IO.Socket? _socket;
  bool _isConnected = false;
  final List<ChatMessageModel> _messages = [];

  String? _currentUserId;
  String? _currentToken;
  Timer? _healthCheckTimer;

  void Function(ChatMessageModel message, String? clientMessageId)?
  onMessageReceived;
  void Function(ChatMessageModel message)? onMessageNotification;
  void Function(ChatMessageModel message, String clientMessageId)?
  onMessageSent;
  void Function(String chatId, String userId)? onUserTyping;
  void Function(String chatId, String userId)? onUserStopTyping;
  void Function(String messageId, MessageStatus status)? onMessageStatusChanged;
  void Function(String readerId, String? chatId)? onMessagesRead;
  void Function(String userId, bool online, DateTime? lastSeenAt)?
  onUserOnlineStatus;
  void Function(String chatId, String messageId, bool forEveryone)?
  onMessageDeleted;
  void Function(
    String chatId,
    String messageId,
    String content,
    DateTime? editedAt,
  )?
  onMessageEdited;
  void Function(
    String chatId,
    String messageId,
    bool isPinned,
    DateTime? pinnedAt,
    ChatMessageModel? message,
  )?
  onMessagePinned;
  void Function(String chatId, String messageId, String userId, String? emoji)?
  onMessageReacted;
  void Function(Map<String, dynamic> request)? onFriendRequestReceived;
  void Function(Map<String, dynamic> request)? onFriendRequestUpdated;

  /// A group was deleted for everyone by its owner. Carries the chat's id and
  /// who deleted it.
  void Function(String chatId, String deletedBy)? onConversationDeleted;

  /// The server will not take this token: revoked from another device, or
  /// expired. Either way the session is over.
  void Function()? onSessionEnded;

  String? currentChatId;
  String? currentPeerId;

  bool get isConnected => _isConnected;

  /// Fired every time the socket (re)connects. ChatProvider uses it to flush
  /// anything composed while offline.
  void Function()? onConnected;
  List<ChatMessageModel> get messages => _messages;

  static String get socketUrl => ApiConfig.socketUrl;

  void _notify() => notifyListeners();

  @override
  void dispose() {
    _healthCheckTimer?.cancel();
    super.dispose();
  }
}
