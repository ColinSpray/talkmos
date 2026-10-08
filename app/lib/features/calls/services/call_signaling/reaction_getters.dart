part of 'call_signaling_service.dart';

/// Trivial one-line raise-hand/reaction getters, grouped here for the same
/// reason as [CallSignalingRoomGetters].
extension CallSignalingReactionGetters on CallSignalingService {
  bool get isHandRaised => _isHandRaised;
  Set<String> get raisedHandIdentities => _raisedHandIdentities;
  Stream<CallReactionEvent> get onReaction => _reactionController.stream;
}
