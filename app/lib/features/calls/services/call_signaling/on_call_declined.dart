part of 'call_signaling_service.dart';

extension CallSignalingOnCallDeclined on CallSignalingService {
  void _onCallDeclined(dynamic data) {
    final callId = data is Map ? data['callId']?.toString() : _currentCallId;
    debugPrint('Received call_declined: $data, currentCallId: $_currentCallId');
    if (!_matchesCurrentCall(callId)) return;
    if (callId != null) CallNotificationService.endCall(callId);
    cleanUp();
  }
}
