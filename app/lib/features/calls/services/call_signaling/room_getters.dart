part of 'call_signaling_service.dart';

extension CallSignalingRoomGetters on CallSignalingService {
  Room? get room => _room;

  bool get hasRemoteVideo => remoteVideoTrack != null;

  bool get isVideoCall => _callType == 'video' || hasRemoteVideoPublication;

  /// All remote participants in the room, for group-call grids.
  List<RemoteParticipant> get remoteParticipants =>
      _room?.remoteParticipants.values.toList() ?? const [];

  /// True once more than one other participant is present (group call).
  bool get isGroupCall => remoteParticipants.length > 1;

  String get activeCallTitle => callTitleFor(
    remoteParticipants.map((p) => p.name.isNotEmpty ? p.name : p.identity),
    fallback: _peerName,
  );
}
