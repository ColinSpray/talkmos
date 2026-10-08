part of 'call_signaling_service.dart';

extension CallSignalingMatchesCurrentCall on CallSignalingService {
  bool _matchesCurrentCall(String? callId) {
    if (_currentCallId == null) {
      if (callId == null || callId.isEmpty) return false;
      _currentCallId = callId;
      return true;
    }
    return callId == _currentCallId;
  }
}
