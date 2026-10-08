part of 'call_signaling_service.dart';

extension CallSignalingOnCallError on CallSignalingService {
  void _onCallError(dynamic data) {
    final error = data is Map ? data['error']?.toString() : null;
    debugPrint('Call socket error: $error');
    if (_currentCallId == null) return;
    // Some failures are about something the call was asked to do, not about
    // the call — an invite the server turned down leaves it running.
    if (data is Map && data['fatal'] == false) {
      onNonFatalCallError?.call(error ?? 'That did not work');
      return;
    }

    final erroredCallId = data is Map ? data['callId']?.toString() : null;
    if (erroredCallId != null &&
        erroredCallId.isNotEmpty &&
        erroredCallId != _currentCallId) {
      return;
    }
    _joinRejected = true;
    final callId = _currentCallId;
    if (callId != null) CallNotificationService.endCall(callId);
    cleanUp();
  }
}
