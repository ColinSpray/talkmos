part of 'call_signaling_service.dart';

extension CallSignalingLocalVideoTrack on CallSignalingService {
  /// The local camera track, or null (audio call / camera off / not joined).
  /// Muted counts as off — the track would otherwise keep rendering the frame
  /// the camera stopped on.
  VideoTrack? get localVideoTrack {
    final pubs = _room?.localParticipant?.videoTrackPublications;
    if (pubs == null) return null;
    for (final pub in pubs) {
      final t = pub.track;
      if (t != null && !pub.muted) return t;
    }
    return null;
  }
}
