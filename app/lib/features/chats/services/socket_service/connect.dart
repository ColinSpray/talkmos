part of 'socket_service.dart';

extension SocketServiceConnect on SocketService {
  void connect(String userId, String token) {
    _currentUserId = userId;
    _currentToken = token;
    _startHealthCheck();

    if (_socket != null && _socket!.connected) return;

    _createSocket(userId, token);
  }

  void _createSocket(String userId, String token) {
    final chatSocketUrl = '${SocketService.socketUrl}/ws/chat';
    debugPrint('Connecting to chat namespace at $chatSocketUrl');

    _socket = IO.io(
      chatSocketUrl,
      IO.OptionBuilder()
          .setTransports(['websocket'])
          .setAuth({'token': token})
          .enableAutoConnect()
          .build(),
    );

    _socket!.onConnect((_) => _handleSocketConnected());
    _socket!.onDisconnect((_) => _handleSocketDisconnected());
    _socket!.onConnectError(_handleConnectError);

    _socket!.on('receive_chat_message', _handleReceiveChatMessage);
    _socket!.on('message_sent', _handleMessageSent);
    _socket!.on('message_delivered', _handleMessageDelivered);
    _socket!.on('messages_read', _handleMessagesRead);
    _socket!.on('user_typing', _handleUserTyping);
    _socket!.on('user_stop_typing', _handleUserStopTyping);
    _socket!.on('user_online_status', _handleUserOnlineStatus);
    _socket!.on('message_deleted', _handleMessageDeletedEvent);
    _socket!.on('message_edited', _handleMessageEditedEvent);
    _socket!.on('message_pinned', _handleMessagePinnedEvent);
    _socket!.on('message_reaction', _handleMessageReactionEvent);
    _socket!.on('friend_request_received', _handleFriendRequestReceived);
    _socket!.on('friend_request_updated', _handleFriendRequestUpdated);
    _socket!.on('conversation_deleted', _handleConversationDeleted);
    _socket!.on('session_revoked', (_) => onSessionEnded?.call());

    _socket!.connect();
  }

  /// A refused handshake. A rejected token will not start working on the next
  /// attempt, so the retry loop stops and the session is reported dead;
  /// anything else is a blip the health check should keep retrying.
  void _handleConnectError(Object? error) {
    debugPrint('[SocketService] chat socket connect failed: $error');
    if (!isSocketAuthFailure(error)) return;
    disconnect();
    onSessionEnded?.call();
  }

  void _startHealthCheck() {
    if (_healthCheckTimer != null) return;
    _healthCheckTimer = Timer.periodic(const Duration(seconds: 12), (_) {
      if (_currentUserId == null || _currentToken == null) return;
      if (_socket != null && _socket!.connected) return;
      debugPrint('[SocketService] chat socket found down — recreating it');
      _teardownSocket();
      _createSocket(_currentUserId!, _currentToken!);
    });
  }

  void _teardownSocket() {
    try {
      _socket?.disconnect();
    } catch (e) {
      debugPrint('[SocketService] socket teardown: $e');
    }
    _socket = null;
  }
}
