part of 'call_signaling_service.dart';

extension CallSignalingApplyIncomingCall on CallSignalingService {
  void _applyIncomingCall({
    required String callId,
    required String callerId,
    String? callerName,
    String? callerAvatar,
    required String callType,
    bool showNativeUi = true,
  }) {
    _isOutgoing = false;
    _currentCallId = callId;
    _peerId = callerId;
    _peerName = callerName;
    _peerAvatar = callerAvatar;
    _callType = callType;
    _state = CallState.ringingIncoming;
    _notify();

    // Tells the caller's device to flip its "Calling…" label over to
    // "Ringing…" — this is the moment this device actually starts ringing.
    _socket?.emit('call_ringing', {'callId': callId});

    // …and the moment the no-answer clock starts.
    _startRingTimeout();

    if (!showNativeUi) return;

    CallNotificationService.showIncomingCall(
      callId: callId,
      callerId: callerId,
      callerName: callerName ?? 'Someone',
      callType: callType,
    );
  }
}
