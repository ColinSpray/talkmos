part of 'call_signaling_service.dart';

extension CallSignalingVideoTrackFor on CallSignalingService {
  /// A participant's live camera track (local or remote), or null. Muted
  /// publications are skipped so a camera switched off shows the participant's
  /// tile placeholder instead of their last frame, frozen.
  VideoTrack? videoTrackFor(Participant participant) {
    for (final pub in participant.videoTrackPublications) {
      final t = pub.track;
      if (t is VideoTrack && !pub.muted) return t;
    }
    return null;
  }
}
