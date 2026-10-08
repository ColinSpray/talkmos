part of 'call_signaling_service.dart';

extension CallSignalingOnNotificationEvent on CallSignalingService {
  void _onNotificationEvent(CallNotificationEvent event) {
    final payload = event.payload;
    switch (event.action) {
      case CallNotificationAction.decline:
        rejectIncomingCall(callId: payload.callId);
        return;
      case CallNotificationAction.declinedInBackground:
        cleanUp();
        return;
      case CallNotificationAction.hangUp:
        cleanUp();
        return;
      case CallNotificationAction.open:
        // UI-only (reopen the already-running call) — nothing for the
        // service to do; MainNavigationContainer handles the navigation.
        return;
      case CallNotificationAction.accept:
        break;
    }
    if (_currentUserId == null) {
      debugPrint('[CallSignaling] Accept arrived pre-login; queuing.');
      _pendingAcceptPayload = payload;
      return;
    }
    acceptIncomingCall(
      _currentUserId!,
      callId: payload.callId,
      callerId: payload.callerId,
      callerName: payload.callerName,
      callType: payload.callType,
    );
  }
}
