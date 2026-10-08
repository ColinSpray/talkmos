part of 'call_signaling_service.dart';

extension CallSignalingOnActivityDecline on CallSignalingService {
  void _onActivityDecline(Map<String, dynamic> data) {
    final callId = data['callId']?.toString() ?? _currentCallId;
    if (callId != null) {
      rejectIncomingCall(callId: callId);
    }
  }
}
