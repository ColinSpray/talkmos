part of 'call_signaling_service.dart';

const Duration _kCallerRingTimeout = Duration(seconds: 35);

extension CallSignalingRingTimeout on CallSignalingService {
  /// Arms the no-answer timeout for the call that just started ringing.
  void _startRingTimeout() {
    _ringTimeoutTimer?.cancel();
    final incoming = !_isOutgoing;
    _ringTimeoutTimer = Timer(
      incoming ? CallNotificationService.ringTimeout : _kCallerRingTimeout,
      incoming ? _onIncomingRingTimeout : _onOutgoingRingTimeout,
    );
  }

  void _cancelRingTimeout() {
    _ringTimeoutTimer?.cancel();
    _ringTimeoutTimer = null;
  }

  /// Nobody picked up on this device: decline for the user and leave a missed
  /// call behind, exactly as if they'd watched it ring out.
  void _onIncomingRingTimeout() {
    if (_state != CallState.ringingIncoming) return;
    final callId = _currentCallId;
    if (callId == null) return;
    debugPrint(
      '[CallSignaling] Unanswered for '
      '${CallNotificationService.ringTimeout.inSeconds}s — auto-declining '
      '$callId',
    );
    // `reason` distinguishes a timeout from a deliberate Decline tap, so the
    // backend can log the call as missed rather than declined.
    _socket?.emit('decline_call', {'callId': callId, 'reason': 'missed'});
    _showMissedCall();
    cleanUp();
  }

  /// The callee never answered (and never even rang, or its own timeout would
  /// have declined first) — stop ringing on this end.
  void _onOutgoingRingTimeout() {
    if (_state != CallState.ringingOutgoing) return;
    debugPrint('[CallSignaling] Outgoing call timed out — cancelling');
    cleanUp();
  }

  /// Posts the missed-call notification for the call currently ringing in.
  /// Also used when the caller hangs up before we answer.
  void _showMissedCall() {
    CallNotificationService.showMissedCall(
      callerName: _peerName ?? 'Someone',
      callType: _callType ?? 'audio',
    );
  }
}
