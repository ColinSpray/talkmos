part of 'call_signaling_service.dart';

extension CallSignalingCleanUp on CallSignalingService {
  void cleanUp() {
    if (_cleaningUp) return; // guard against re-entrant calls (e.g. the
    // RoomDisconnectedEvent our own disconnect triggers).
    if (_state == CallState.idle && _currentCallId == null && _room == null) {
      return;
    }
    _cleaningUp = true;
    _cancelRingTimeout();
    _peerReconnectTimer?.cancel();
    _peerReconnectTimer = null;
    _peerReconnecting = false;
    debugPrint('Cleaning up call state... $_currentCallId');

    final connectedAt = _connectedAt;
    AnalyticsService.logEvent(
      'call_ended',
      parameters: {
        'direction': _isOutgoing ? 'outgoing' : 'incoming',
        'call_type': _callType ?? 'unknown',
        'was_connected': (connectedAt != null).toString(),
        'duration_seconds': connectedAt == null
            ? 0
            : DateTime.now().difference(connectedAt).inSeconds,
      },
    );

    if (_currentCallId != null) {
      CallNotificationService.endCall(_currentCallId!);
      _socket?.emit('leave_call_room', {
        'callId': _currentCallId,
        'status': 'left',
      });
      requestCallHistory();
    }

    try {
      AudioManager.instance.setSpeakerOutputPreferred(false);
      CallActivityService.finishCallActivity();
    } catch (_) {}

    final room = _room;
    _room = null;
    _roomListener?.dispose();
    _roomListener = null;
    room?.disconnect().catchError(
      (Object e) => debugPrint('[LiveKit] disconnect during cleanup: $e'),
    );

    _currentCallId = null;
    // Must be cleared here or a single rejected join would block every
    // subsequent call, including outgoing ones.
    _joinRejected = false;
    _peerId = null;
    _peerName = null;
    _peerAvatar = null;
    _callType = null;
    _frontCamera = true;
    _isMicMuted = false;
    _isCameraOff = false;
    _isSpeakerOn = false;
    _calleeRinging = false;
    _presumedRinging = false;
    _presumedRingingTimer?.cancel();
    _presumedRingingTimer = null;
    _isHandRaised = false;
    _raisedHandIdentities.clear();
    _connectedAt = null;
    _cameraSuspendedForShare = false;
    if (_isScreenSharing) {
      _isScreenSharing = false;
      ScreenShareService.instance.stop();
    }

    // Transition ended → idle over two notifies so UI can show an "ended"
    // frame before resetting.
    _state = CallState.ended;
    _notify();
    Future.microtask(() {
      _state = CallState.idle;
      _cleaningUp = false;
      _notify();
    });
  }
}
