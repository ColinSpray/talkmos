// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'home_summary_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

HomeSummary _$HomeSummaryFromJson(Map<String, dynamic> json) => HomeSummary(
  unreadChats: (json['unread_chats'] as num?)?.toInt() ?? 0,
  newGroupMessages: (json['new_group_messages'] as num?)?.toInt() ?? 0,
  missedCalls: (json['missed_calls'] as num?)?.toInt() ?? 0,
);

Map<String, dynamic> _$HomeSummaryToJson(HomeSummary instance) =>
    <String, dynamic>{
      'unread_chats': instance.unreadChats,
      'new_group_messages': instance.newGroupMessages,
      'missed_calls': instance.missedCalls,
    };
