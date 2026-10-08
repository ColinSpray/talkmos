part of 'call_signaling_service.dart';

extension CallSignalingToggleRaiseHand on CallSignalingService {
  Future<void> toggleRaiseHand() async {
    final lp = _room?.localParticipant;
    if (lp == null) return;

    _isHandRaised = !_isHandRaised;
    final identity = lp.identity;
    if (_isHandRaised) {
      _raisedHandIdentities.add(identity);
    } else {
      _raisedHandIdentities.remove(identity);
    }
    _notify();

    try {
      await lp.publishData(
        utf8.encode(
          jsonEncode({'type': _isHandRaised ? 'raise_hand' : 'lower_hand'}),
        ),
        reliable: true,
      );
    } catch (e) {
      debugPrint('[CallSignaling] publishData (raise hand) error: $e');
    }
  }
}
