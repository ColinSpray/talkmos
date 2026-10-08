import 'package:json_annotation/json_annotation.dart';
import 'user_model.dart';
import 'converters/local_date_time_converter.dart';

part 'call_participant_model.g.dart';

@JsonSerializable()
class CallParticipantModel {
  @JsonKey(name: '_id', defaultValue: '')
  final String id;

  @JsonKey(defaultValue: '')
  final String callId;

  @JsonKey(defaultValue: '')
  final String userId;

  final UserModel? userDetails;

  @JsonKey(defaultValue: 'participant')
  final String role;

  @JsonKey(defaultValue: false)
  final bool micMuted;

  @JsonKey(defaultValue: false)
  final bool cameraOn;

  @LocalDateTimeConverterNullable()
  final DateTime? joinTime;

  @LocalDateTimeConverterNullable()
  final DateTime? leaveTime;

  CallParticipantModel({
    required this.id,
    required this.callId,
    required this.userId,
    this.userDetails,
    required this.role,
    this.micMuted = false,
    this.cameraOn = false,
    this.joinTime,
    this.leaveTime,
  });

  factory CallParticipantModel.fromJson(Map<String, dynamic> json) {
    UserModel? details;
    if (json['userId'] != null && json['userId'] is Map) {
      details = UserModel.fromJson(Map<String, dynamic>.from(json['userId']));
    }

    final uId = details?.id ?? json['userId']?.toString() ?? '';

    final Map<String, dynamic> data = Map<String, dynamic>.from(json);
    if (!data.containsKey('_id') && data.containsKey('id')) {
      data['_id'] = data['id'];
    }
    data['userId'] = uId;
    data['userDetails'] = details?.toJson();

    return _$CallParticipantModelFromJson(data);
  }

  Map<String, dynamic> toJson() => _$CallParticipantModelToJson(this);
}
