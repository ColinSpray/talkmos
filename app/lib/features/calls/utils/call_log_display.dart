import '../../../models/call_model.dart';
import '../../../models/call_participant_model.dart';
import '../../../core/utils/titlecase_function.dart';

/// Everyone on the call except the signed-in user.
List<CallParticipantModel> otherParticipants(
  CallModel log,
  String currentUserId,
) => log.participants.where((p) => p.userId != currentUserId).toList();

bool isGroupCall(CallModel log) =>
    log.scope == 'group' || log.participants.length > 2;

/// "Alice, Bob" / "Alice, Bob +2" — who was actually on the call.
String participantSummary(
  List<CallParticipantModel> others, {
  required String unknownLabel,
}) {
  final names = <String>[];
  for (final p in others) {
    final n = p.userDetails?.name;
    if (n != null && n.isNotEmpty) names.add(toTitleCase(n));
  }
  if (names.isEmpty) return unknownLabel;
  if (names.length <= 2) return names.join(', ');
  return '${names.take(2).join(', ')} +${names.length - 2}';
}

String callLogTitle({
  required CallModel log,
  required String currentUserId,
  required String? conversationTitle,
  required String unknownLabel,
}) {
  final others = otherParticipants(log, currentUserId);

  if (isGroupCall(log)) {
    if (conversationTitle != null && conversationTitle.isNotEmpty) {
      return conversationTitle;
    }
    return participantSummary(others, unknownLabel: unknownLabel);
  }

  final isOutgoing = log.initiatorId == currentUserId;
  final other = others.isNotEmpty ? others.first : null;
  final fallback = isOutgoing ? null : log.initiatorDetails;
  return other?.userDetails?.name ?? fallback?.name ?? unknownLabel;
}

/// The avatar for a call-log row, following the same rules as [callLogTitle].
String? callLogAvatarUrl({
  required CallModel log,
  required String currentUserId,
  required String? conversationAvatarUrl,
}) {
  if (isGroupCall(log)) return conversationAvatarUrl;
  final others = otherParticipants(log, currentUserId);
  final other = others.isNotEmpty ? others.first : null;
  final fallback = log.initiatorId == currentUserId
      ? null
      : log.initiatorDetails;
  return other?.userDetails?.avatarUrl ?? fallback?.avatarUrl;
}
