// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'voicemail_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

VoicemailModel _$VoicemailModelFromJson(Map<String, dynamic> json) =>
    VoicemailModel(
      id: json['_id'] as String? ?? '',
      recipientId: json['recipientId'] as String? ?? '',
      callId: json['callId'] as String? ?? '',
      callDetails: json['callDetails'] == null
          ? null
          : CallModel.fromJson(json['callDetails'] as Map<String, dynamic>),
      recordingUrl: json['recordingUrl'] as String? ?? '',
      transcription: json['transcription'] as String? ?? '',
      createdAt: const LocalDateTimeConverter().fromJson(
        json['createdAt'] as String,
      ),
    );

Map<String, dynamic> _$VoicemailModelToJson(VoicemailModel instance) =>
    <String, dynamic>{
      '_id': instance.id,
      'recipientId': instance.recipientId,
      'callId': instance.callId,
      'callDetails': instance.callDetails,
      'recordingUrl': instance.recordingUrl,
      'transcription': instance.transcription,
      'createdAt': const LocalDateTimeConverter().toJson(instance.createdAt),
    };
