part of 'call_signaling_service.dart';

extension CallSignalingSyncPeerName on CallSignalingService {
  /// Repoints the peer name at whoever is actually in the room.
  void _syncPeerNameToRoom() {
    if (remoteParticipants.isEmpty) return;

    final title = callTitleFor(
      remoteParticipants.map((p) => p.name.isNotEmpty ? p.name : p.identity),
    );
    if (title.isEmpty || title == _peerName) return;

    _peerName = title;

    if (_currentCallId != null && _state == CallState.connected) {
      CallNotificationService.showActiveCall(
        callId: _currentCallId!,
        peerName: title,
        callType: _callType ?? 'audio',
      );
    }
  }
}
