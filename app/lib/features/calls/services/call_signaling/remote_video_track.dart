part of 'call_signaling_service.dart';

extension CallSignalingRemoteVideoTrack on CallSignalingService {
  /// The first remote participant's live camera track (1:1), or null. A muted
  /// publication is skipped: its track keeps handing out the last frame it
  /// received, which renders as the peer frozen mid-blink after they turn
  /// their camera off.
  VideoTrack? get remoteVideoTrack {
    final participants = _room?.remoteParticipants.values;
    if (participants == null) return null;
    for (final p in participants) {
      for (final pub in p.videoTrackPublications) {
        final t = pub.track;
        if (t != null && !pub.muted) return t;
      }
    }
    return null;
  }

  /// Whether the peer has a camera published at all, muted or not — the call
  /// stays a video call while they briefly turn their camera off, so the UI
  /// must not fall back to the audio layout.
  bool get hasRemoteVideoPublication {
    final participants = _room?.remoteParticipants.values;
    if (participants == null) return false;
    for (final p in participants) {
      if (p.videoTrackPublications.isNotEmpty) return true;
    }
    return false;
  }
}
