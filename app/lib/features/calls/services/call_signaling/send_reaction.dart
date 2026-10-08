part of 'call_signaling_service.dart';

extension CallSignalingSendReaction on CallSignalingService {
  Future<void> sendReaction(String emoji) async {
    final lp = _room?.localParticipant;
    if (lp == null) return;

    _reactionCounter++;
    _reactionController.add(
      CallReactionEvent(
        id: _reactionCounter,
        senderIdentity: lp.identity,
        emoji: emoji,
      ),
    );

    try {
      await lp.publishData(
        utf8.encode(jsonEncode({'type': 'reaction', 'emoji': emoji})),
        reliable: false,
      );
    } catch (e) {
      debugPrint('[CallSignaling] publishData (reaction) error: $e');
    }
  }
}
