import 'package:json_annotation/json_annotation.dart';
import 'user_model.dart';
import 'call_participant_model.dart';
import 'converters/local_date_time_converter.dart';

part 'call_model.g.dart';

@JsonSerializable()
class CallModel {
  @JsonKey(name: '_id', defaultValue: '')
  final String id;

  final String? conversationId;

  @JsonKey(defaultValue: 'voice')
  final String type;

  @JsonKey(defaultValue: '1:1')
  final String scope;

  @JsonKey(defaultValue: '')
  final String initiatorId;

  final UserModel? initiatorDetails;

  @JsonKey(defaultValue: 'ringing')
  final String status;

  @LocalDateTimeConverter()
  final DateTime startedAt;

  @LocalDateTimeConverterNullable()
  final DateTime? endedAt;
  final int? durationSeconds;

  @JsonKey(defaultValue: [])
  final List<CallParticipantModel> participants;

  CallModel({
    required this.id,
    this.conversationId,
    required this.type,
    required this.scope,
    required this.initiatorId,
    this.initiatorDetails,
    required this.status,
    required this.startedAt,
    this.endedAt,
    this.durationSeconds,
    required this.participants,
  });

  factory CallModel.fromJson(Map<String, dynamic> json) {
    UserModel? initDetails;
    if (json['initiatorId'] != null && json['initiatorId'] is Map) {
      initDetails = UserModel.fromJson(
        Map<String, dynamic>.from(json['initiatorId']),
      );
    }

    final initId = initDetails?.id ?? json['initiatorId']?.toString() ?? '';

    final Map<String, dynamic> data = Map<String, dynamic>.from(json);
    if (!data.containsKey('_id') && data.containsKey('id')) {
      data['_id'] = data['id'];
    }
    data['initiatorId'] = initId;
    data['initiatorDetails'] = initDetails?.toJson();

    if (data['startedAt'] == null) {
      data['startedAt'] = DateTime.now().toIso8601String();
    }

    final rawParticipants = data.remove('participants') as List<dynamic>? ?? [];
    final participants = <CallParticipantModel>[];
    for (final p in rawParticipants) {
      try {
        participants.add(
          CallParticipantModel.fromJson(Map<String, dynamic>.from(p as Map)),
        );
      } catch (_) {
        // skip malformed participant entry
      }
    }

    final call = _$CallModelFromJson(data);
    return CallModel(
      id: call.id,
      conversationId: call.conversationId,
      type: call.type,
      scope: call.scope,
      initiatorId: call.initiatorId,
      initiatorDetails: call.initiatorDetails,
      status: call.status,
      startedAt: call.startedAt,
      endedAt: call.endedAt,
      durationSeconds: call.durationSeconds,
      participants: participants,
    );
  }

  Map<String, dynamic> toJson() => _$CallModelToJson(this);
}
