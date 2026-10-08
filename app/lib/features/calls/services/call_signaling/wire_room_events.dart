part of 'call_signaling_service.dart';

extension CallSignalingWireRoomEvents on CallSignalingService {
  void _wireRoomEvents(EventsListener<RoomEvent> listener) {
    listener
      ..on<AudioPlaybackStatusChanged>((e) async {
        debugPrint(
          '[LiveKit] AudioPlaybackStatusChanged: isPlaying=${e.isPlaying}',
        );
        if (_room != null && !_room!.canPlaybackAudio) {
          try {
            await _room!.startAudio();
          } catch (err) {
            debugPrint('[LiveKit] startAudio error: $err');
          }
        }
      })
      ..on<TrackSubscribedEvent>((e) {
        debugPrint(
          '[LiveKit] track subscribed: ${e.track.kind} from ${e.participant.identity}',
        );
        try {
          e.track.start();
        } catch (_) {}
        _notify();
      })
      ..on<TrackUnsubscribedEvent>((e) {
        debugPrint(
          '[LiveKit] track UNsubscribed: ${e.track.kind} from ${e.participant.identity}',
        );
        _notify();
      })
      ..on<LocalTrackPublishedEvent>((e) {
        debugPrint('[LiveKit] local track published: ${e.publication.kind}');
        _notify();
      })
      ..on<LocalTrackUnpublishedEvent>((e) {
        debugPrint('[LiveKit] local track UNpublished: ${e.publication.kind}');
        _notify();
      })
      ..on<TrackMutedEvent>((_) => _notify())
      ..on<TrackUnmutedEvent>((_) => _notify())
      ..on<ActiveSpeakersChangedEvent>((_) => _notify())
      ..on<ParticipantConnectedEvent>((e) {
        debugPrint(
          '[LiveKit] participant connected: ${e.participant.identity}',
        );
        _cancelPeerReconnectWait();
        if (_state == CallState.ringingOutgoing) {
          _updateStateToConnected();
          _syncPeerNameToRoom();
        } else {
          _syncPeerNameToRoom();
          _notify();
        }
      })
      ..on<ParticipantDisconnectedEvent>((e) {
        debugPrint(
          '[LiveKit] participant disconnected: ${e.participant.identity}',
        );
        // End only when nobody else remains (handles both 1:1 and group) —
        // and not immediately: the server holds the call open for a peer whose
        // connection dropped, so a web client reloading its page has something
        // to come back to. Ending here would make that grace period pointless.
        if (remoteParticipants.isEmpty) {
          _waitForPeerToReconnect();
        } else {
          // The dialler may be the one who just left; the title has to follow
          // whoever is still talking.
          _syncPeerNameToRoom();
          _notify();
        }
      })
      ..on<RoomDisconnectedEvent>((e) {
        debugPrint('[LiveKit] room disconnected, reason: ${e.reason}');
        cleanUp();
      })
      ..on<DataReceivedEvent>(_onDataReceived);
  }

  /// Gives the last remote participant a moment to come back before the call
  /// is torn down. Ends it the moment the window closes with nobody there.
  void _waitForPeerToReconnect() {
    if (_peerReconnectTimer != null) return;
    debugPrint(
      '[LiveKit] room empty — waiting ${CallSignalingService.peerReconnectGrace.inSeconds}s '
      'for the peer to rejoin',
    );
    _peerReconnecting = true;
    _notify();
    _peerReconnectTimer = Timer(CallSignalingService.peerReconnectGrace, () {
      _peerReconnectTimer = null;
      _peerReconnecting = false;
      if (remoteParticipants.isEmpty) {
        debugPrint('[LiveKit] peer did not rejoin — ending the call');
        cleanUp();
      } else {
        _notify();
      }
    });
  }

  void _cancelPeerReconnectWait() {
    if (_peerReconnectTimer == null) return;
    debugPrint('[LiveKit] peer rejoined — call continues');
    _peerReconnectTimer!.cancel();
    _peerReconnectTimer = null;
    _peerReconnecting = false;
  }
}
