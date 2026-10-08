part of 'call_signaling_service.dart';

extension CallSignalingFlushPendingAccept on CallSignalingService {
  void _flushPendingAccept() {
    final payload = _pendingAcceptPayload;
    final userId = _currentUserId;
    if (payload == null || userId == null) return;
    _pendingAcceptPayload = null;
    debugPrint('[CallSignaling] Replaying queued accept for ${payload.callId}');
    acceptIncomingCall(
      userId,
      callId: payload.callId,
      callerId: payload.callerId,
      callerName: payload.callerName,
      callType: payload.callType,
    );
  }
}
