part of 'call_signaling_service.dart';

extension CallSignalingUpgradeToVideo on CallSignalingService {
  Future<void> upgradeToVideo() async {
    final lp = _room?.localParticipant;
    debugPrint(
      '[UpgradeVideo] called — room=${_room != null}, '
      'localParticipant=${lp?.identity}, callType=$_callType, state=$_state',
    );
    if (lp == null || _callType == 'video') {
      debugPrint(
        '[UpgradeVideo] SKIPPED (lp=${lp == null ? "null" : "ok"}, '
        'callType=$_callType)',
      );
      return;
    }

    debugPrint('[UpgradeVideo] enabling camera...');
    await lp.setCameraEnabled(true);
    debugPrint(
      '[UpgradeVideo] camera enabled. '
      'videoPublications=${lp.videoTrackPublications.length}, '
      'localVideoTrack=${localVideoTrack != null}',
    );

    _callType = 'video';
    _isCameraOff = false;
    _isSpeakerOn = true;
    try {
      await AudioManager.instance.setSpeakerOutputPreferred(true);
    } catch (e) {
      debugPrint('[Hardware] setSpeakerOutputPreferred error: $e');
    }
    _notify();
    debugPrint('[UpgradeVideo] done — callType=$_callType');
  }
}
