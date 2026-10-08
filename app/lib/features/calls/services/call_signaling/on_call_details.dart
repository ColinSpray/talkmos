part of 'call_signaling_service.dart';

const Set<String> _terminalCallStatuses = {
  'ended',
  'missed',
  'declined',
  'failed',
};

extension CallSignalingOnCallDetails on CallSignalingService {
  /// Asks the server whether the call we think we are in is still running.
  ///
  /// Anything that ended it while this socket was away was delivered to
  /// nobody, and without this the screen sits on a call that finished minutes
  /// ago — the server is the only one who knows.
  void _requestCallState() {
    final callId = _currentCallId;
    if (callId == null || callId.isEmpty) return;
    if (_socket?.connected != true) return;
    _socket!.emit('get_call_by_id', {'callId': callId});
  }

  void _onCallDetails(dynamic data) {
    final call = data is Map ? data['call'] : null;
    if (call is! Map) return;
    final callId = call['_id']?.toString();
    if (callId == null || callId != _currentCallId) return;

    final status = call['status']?.toString() ?? '';
    if (!_terminalCallStatuses.contains(status)) return;

    debugPrint('[CallSignaling] $callId is already $status — tearing down');
    CallNotificationService.endCall(callId);
    cleanUp();
  }
}
