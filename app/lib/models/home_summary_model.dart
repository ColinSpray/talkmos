import 'package:json_annotation/json_annotation.dart';
part 'home_summary_model.g.dart';

@JsonSerializable()
class HomeSummary {
  @JsonKey(name: 'unread_chats', defaultValue: 0)
  final int unreadChats;

  @JsonKey(name: 'new_group_messages', defaultValue: 0)
  final int newGroupMessages;

  @JsonKey(name: 'missed_calls', defaultValue: 0)
  final int missedCalls;

  HomeSummary({
    required this.unreadChats,
    required this.newGroupMessages,
    required this.missedCalls,
  });

  factory HomeSummary.fromJson(Map<String, dynamic> json) =>
      _$HomeSummaryFromJson(json);

  Map<String, dynamic> toJson() => _$HomeSummaryToJson(this);

  static HomeSummary empty() =>
      HomeSummary(unreadChats: 0, newGroupMessages: 0, missedCalls: 0);
}
