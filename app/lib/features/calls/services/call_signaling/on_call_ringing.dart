part of 'call_signaling_service.dart';

extension CallSignalingOnCallRinging on CallSignalingService {
  /// The callee's device has confirmed it's ringing — flips the caller's
  /// "Calling…" label over to "Ringing…".
  void _onCallRinging(dynamic data) {
    final callId = data is Map ? data['callId']?.toString() : null;
    if (!_matchesCurrentCall(callId)) return;
    if (_calleeRinging) return;
    _calleeRinging = true;
    _notify();
  }
}
