// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'call_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

CallModel _$CallModelFromJson(Map<String, dynamic> json) => CallModel(
  id: json['_id'] as String? ?? '',
  conversationId: json['conversationId'] as String?,
  type: json['type'] as String? ?? 'voice',
  scope: json['scope'] as String? ?? '1:1',
  initiatorId: json['initiatorId'] as String? ?? '',
  initiatorDetails: json['initiatorDetails'] == null
      ? null
      : UserModel.fromJson(json['initiatorDetails'] as Map<String, dynamic>),
  status: json['status'] as String? ?? 'ringing',
  startedAt: const LocalDateTimeConverter().fromJson(
    json['startedAt'] as String,
  ),
  endedAt: const LocalDateTimeConverterNullable().fromJson(
    json['endedAt'] as String?,
  ),
  durationSeconds: (json['durationSeconds'] as num?)?.toInt(),
  participants:
      (json['participants'] as List<dynamic>?)
          ?.map((e) => CallParticipantModel.fromJson(e as Map<String, dynamic>))
          .toList() ??
      [],
);

Map<String, dynamic> _$CallModelToJson(CallModel instance) => <String, dynamic>{
  '_id': instance.id,
  'conversationId': instance.conversationId,
  'type': instance.type,
  'scope': instance.scope,
  'initiatorId': instance.initiatorId,
  'initiatorDetails': instance.initiatorDetails,
  'status': instance.status,
  'startedAt': const LocalDateTimeConverter().toJson(instance.startedAt),
  'endedAt': const LocalDateTimeConverterNullable().toJson(instance.endedAt),
  'durationSeconds': instance.durationSeconds,
  'participants': instance.participants,
};
