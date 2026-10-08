part of 'call_signaling_service.dart';

extension CallSignalingOnCallEnded on CallSignalingService {
  void _onCallEnded(dynamic data) {
    final callId = data is Map ? data['callId']?.toString() : _currentCallId;
    debugPrint('Received call_ended: $data, currentCallId: $_currentCallId');
    if (!_matchesCurrentCall(callId)) return;
    if (_state == CallState.ringingIncoming) _showMissedCall();
    if (callId != null) CallNotificationService.endCall(callId);
    cleanUp();
  }
}
