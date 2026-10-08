part of 'call_signaling_service.dart';

extension CallSignalingOnDataReceived on CallSignalingService {
  void _onDataReceived(DataReceivedEvent event) {
    final identity = event.participant?.identity;
    if (identity == null) return;
    Map<String, dynamic> envelope;
    try {
      envelope = jsonDecode(utf8.decode(event.data)) as Map<String, dynamic>;
    } catch (e) {
      debugPrint('[CallSignaling] Malformed data-channel payload: $e');
      return;
    }

    switch (envelope['type']) {
      case 'raise_hand':
        _raisedHandIdentities.add(identity);
        _notify();
      case 'lower_hand':
        _raisedHandIdentities.remove(identity);
        _notify();
      case 'reaction':
        final emoji = envelope['emoji']?.toString();
        if (emoji == null || emoji.isEmpty) return;
        _reactionCounter++;
        _reactionController.add(
          CallReactionEvent(
            id: _reactionCounter,
            senderIdentity: identity,
            emoji: emoji,
          ),
        );
    }
  }
}
