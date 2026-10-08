import 'package:json_annotation/json_annotation.dart';
import 'call_model.dart';
import 'converters/local_date_time_converter.dart';

part 'voicemail_model.g.dart';

@JsonSerializable()
class VoicemailModel {
  @JsonKey(name: '_id', defaultValue: '')
  final String id;

  @JsonKey(defaultValue: '')
  final String recipientId;

  @JsonKey(defaultValue: '')
  final String callId;

  final CallModel? callDetails;

  @JsonKey(defaultValue: '')
  final String recordingUrl;

  @JsonKey(defaultValue: '')
  final String transcription;

  @LocalDateTimeConverter()
  final DateTime createdAt;

  VoicemailModel({
    required this.id,
    required this.recipientId,
    required this.callId,
    this.callDetails,
    required this.recordingUrl,
    required this.transcription,
    required this.createdAt,
  });

  factory VoicemailModel.fromJson(Map<String, dynamic> json) {
    CallModel? call;
    if (json['callId'] != null && json['callId'] is Map) {
      call = CallModel.fromJson(Map<String, dynamic>.from(json['callId']));
    }

    final Map<String, dynamic> data = Map<String, dynamic>.from(json);
    if (!data.containsKey('_id') && data.containsKey('id')) {
      data['_id'] = data['id'];
    }
    data['callId'] = call?.id ?? json['callId']?.toString() ?? '';
    data['callDetails'] = call?.toJson();

    if (data['createdAt'] == null) {
      data['createdAt'] = DateTime.now().toIso8601String();
    }

    return _$VoicemailModelFromJson(data);
  }

  Map<String, dynamic> toJson() => _$VoicemailModelToJson(this);
}
