part of 'call_signaling_service.dart';

extension CallSignalingStartOutgoingCall on CallSignalingService {
  Future<CallStartOutcome> startOutgoingCall({
    required String chatId,
    required String calleeId,
    required String calleeName,
    String? calleeAvatar,
    required String initiatorName,
    required bool isVideo,
  }) async {
    // Ringing someone else mid-call means "add them", not "fail" — the user
    // stepped out of a call that is still running to pick the next person.
    if (_state == CallState.connected && _currentCallId != null) {
      inviteToCall(calleeId, initiatorName: initiatorName);
      return CallStartOutcome.invitedToActiveCall;
    }

    // A call that is still ringing, either way, has nothing to add anyone to.
    if (hasActiveCallSession) {
      throw ActiveCallInProgressException();
    }

    _isOutgoing = true;
    _calleeRinging = false;
    _presumedRinging = false;
    _state = CallState.ringingOutgoing;
    _peerId = calleeId;
    _peerName = calleeName;
    _peerAvatar = calleeAvatar;
    _callType = isVideo ? 'video' : 'audio';
    _notify();
    _startRingTimeout();
    AnalyticsService.logEvent(
      'call_started',
      parameters: {'direction': 'outgoing', 'call_type': _callType!},
    );

    _socket!.emit('initiate_call', {
      'chatId': chatId,
      'callType': _callType,
      'calleeName': calleeName,
      'initiatorName': initiatorName,
    });
    return CallStartOutcome.started;
  }
}
