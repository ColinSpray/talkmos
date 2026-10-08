part of 'call_signaling_service.dart';

extension CallSignalingConnect on CallSignalingService {
  void connect(String userId, String token, {String? userName}) {
    _currentUserId = userId;
    _currentUserName = userName;
    _currentToken = token;
    CallNotificationService.consumeLaunchDetails();
    // consumeLaunchDetails can deliver an Accept synchronously; either way,
    // release anything that arrived before this user id was known.
    _flushPendingAccept();

    _startHealthCheck();

    if (_socket != null) return;

    _createSocket(userId, token, userName);
  }

  void _createSocket(String userId, String token, String? userName) {
    _socket = IO.io(
      '${ApiConfig.backendUrl}/ws/call',
      IO.OptionBuilder()
          .setTransports(['websocket'])
          .setAuth({'token': token})
          .enableAutoConnect()
          .build(),
    );

    _socket!
      ..onConnect((_) {
        debugPrint('Call socket connected');
        // Re-issue any history request that was made before the socket was
        // connected (or that should be refreshed after a reconnect).
        if (_pendingHistoryRequest) {
          _socket!.emit('get_call_history', {'limit': _historyLimit});
        }
        // Whatever happened to our call while the socket was away reached
        // nobody, so check it is still running.
        _requestCallState();
      })
      ..onDisconnect((_) => debugPrint('Call socket disconnected'))
      ..onConnectError(_handleConnectError)
      ..on('incoming_call', (data) => _onIncomingCall(data, userId))
      ..on('livekit_token', _onLivekitToken)
      ..on(
        'call_participant_joined',
        (data) => _onParticipantJoined(data, userId),
      )
      ..on('call_declined', _onCallDeclined)
      ..on('call_ringing', _onCallRinging)
      ..on('call_ended', _onCallEnded)
      ..on('call_participant_left', _onCallParticipantLeft)
      ..on('call_details', _onCallDetails)
      ..on('call_history', _onCallHistory)
      ..on('call_error', _onCallError)
      ..on('call_initiated', _onCallInitiated)
      ..connect();
  }

  /// See the note on the chat socket's copy: a token the server refuses is
  /// not worth reconnecting over.
  void _handleConnectError(Object? error) {
    debugPrint('[CallSignalingService] socket connect failed: $error');
    if (!isSocketAuthFailure(error)) return;
    disconnect();
    onSessionEnded?.call();
  }

  void _startHealthCheck() {
    if (_healthCheckTimer != null) return;
    _healthCheckTimer = Timer.periodic(const Duration(seconds: 12), (_) {
      if (_currentUserId == null || _currentToken == null) return;
      if (_socket != null && _socket!.connected) return;
      debugPrint('[CallSignalingService] socket found down — recreating it');
      _teardownSocket();
      _createSocket(_currentUserId!, _currentToken!, _currentUserName);
    });
  }

  void _teardownSocket() {
    try {
      _socket?.disconnect();
    } catch (e) {
      debugPrint('[CallSignalingService] socket teardown: $e');
    }
    _socket = null;
  }
}
