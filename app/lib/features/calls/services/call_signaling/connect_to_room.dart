part of 'call_signaling_service.dart';

extension CallSignalingConnectToRoom on CallSignalingService {
  /// Joins the LiveKit room for [callId] and publishes local media.
  Future<void> _connectToRoom(String callId) async {
    if (_room != null) return; // already connecting / connected

    final tokenData = await _fetchLivekitToken(callId);

    // The backend can reject the join while the token round-trip is in
    // flight (e.g. the call ended first). Bail before touching the mic.
    if (_joinRejected || _currentCallId != callId) {
      debugPrint('[CallSignaling] Join no longer valid; not entering room');
      return;
    }

    final url = tokenData?['url']?.toString();
    final token = tokenData?['token']?.toString();
    if (url == null || url.isEmpty || token == null || token.isEmpty) {
      debugPrint('[CallSignaling] Missing LiveKit url/token; cannot join room');
      return;
    }

    final room = Room(
      roomOptions: const RoomOptions(
        adaptiveStream: true,
        dynacast: true,
        defaultCameraCaptureOptions: CameraCaptureOptions(
          params: VideoParametersPresets.h720_169,
        ),
        defaultVideoPublishOptions: VideoPublishOptions(
          simulcast: true,
          videoEncoding: VideoEncoding(
            maxBitrate: 2 * 1000 * 1000, // ~2 Mbps for crisp 720p
            maxFramerate: 30,
          ),
        ),
      ),
    );
    _room = room;
    _roomListener = room.createListener();
    _wireRoomEvents(_roomListener!);

    try {
      debugPrint('[LiveKit] connecting to $url room=$callId');
      await room.connect(url, token);

      if (_room != room || _joinRejected || _currentCallId != callId) {
        debugPrint('[LiveKit] call ended while connecting; leaving room');
        await room.disconnect();
        return;
      }

      debugPrint('[LiveKit] connected to room=$callId');
      try {
        await room.startAudio();
      } catch (err) {
        debugPrint('[LiveKit] room.startAudio error: $err');
      }
    } catch (e) {
      debugPrint('[LiveKit] room.connect failed: $e');
      return;
    }

    final isVideo = _callType == 'video';
    try {
      final hasPerm = await AppPermissions.ensureCallMedia(video: isVideo);
      if (!hasPerm) {
        debugPrint('[LiveKit] camera/microphone permission was denied');
      }
      // Re-checked because the permission prompt above can sit open for a
      // long time; never switch the mic on for a call that has since ended.
      if (_room != room || _currentCallId != callId) {
        debugPrint('[LiveKit] call ended before publishing; skipping');
        await room.disconnect();
        return;
      }
      await room.localParticipant?.setMicrophoneEnabled(true);
      if (isVideo) {
        await room.localParticipant?.setCameraEnabled(true);
      }
      debugPrint('[LiveKit] local media published (video=$isVideo)');
    } catch (e) {
      debugPrint('[LiveKit] publishing local media failed: $e');
    }

    _isMicMuted = false;
    _isCameraOff = !isVideo;
    // A voice call starts at the earpiece the way a phone call does; video has
    // nowhere else to go.
    _isSpeakerOn = isVideo;
    try {
      await AudioManager.instance.setSpeakerOutputPreferred(_isSpeakerOn);
    } catch (e) {
      debugPrint('[Hardware] setSpeakerOutputPreferred error: $e');
    }
    _notify();
  }
}
