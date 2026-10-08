// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'call_participant_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

CallParticipantModel _$CallParticipantModelFromJson(
  Map<String, dynamic> json,
) => CallParticipantModel(
  id: json['_id'] as String? ?? '',
  callId: json['callId'] as String? ?? '',
  userId: json['userId'] as String? ?? '',
  userDetails: json['userDetails'] == null
      ? null
      : UserModel.fromJson(json['userDetails'] as Map<String, dynamic>),
  role: json['role'] as String? ?? 'participant',
  micMuted: json['micMuted'] as bool? ?? false,
  cameraOn: json['cameraOn'] as bool? ?? false,
  joinTime: const LocalDateTimeConverterNullable().fromJson(
    json['joinTime'] as String?,
  ),
  leaveTime: const LocalDateTimeConverterNullable().fromJson(
    json['leaveTime'] as String?,
  ),
);

Map<String, dynamic> _$CallParticipantModelToJson(
  CallParticipantModel instance,
) => <String, dynamic>{
  '_id': instance.id,
  'callId': instance.callId,
  'userId': instance.userId,
  'userDetails': instance.userDetails,
  'role': instance.role,
  'micMuted': instance.micMuted,
  'cameraOn': instance.cameraOn,
  'joinTime': const LocalDateTimeConverterNullable().toJson(instance.joinTime),
  'leaveTime': const LocalDateTimeConverterNullable().toJson(
    instance.leaveTime,
  ),
};
