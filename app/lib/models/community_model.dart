import 'package:json_annotation/json_annotation.dart';
import 'chat_message_model.dart';
import 'converters/local_date_time_converter.dart';

part 'community_model.g.dart';

@JsonSerializable()
class CommunityModel {
  @JsonKey(name: '_id', defaultValue: '')
  final String id;

  @JsonKey(defaultValue: 'community')
  final String chatType;

  @JsonKey(defaultValue: '')
  final String name;

  @JsonKey(defaultValue: '')
  final String description;

  @JsonKey(defaultValue: '')
  final String imageUrl;

  @JsonKey(defaultValue: false)
  final bool isVerified;

  @JsonKey(defaultValue: '')
  final String category;

  @JsonKey(defaultValue: '')
  final String owner;

  @JsonKey(defaultValue: '')
  final String createdBy;

  @JsonKey(defaultValue: 0)
  final int memberCount;

  @JsonKey(defaultValue: false)
  final bool isMember;

  final ChatMessageModel? lastMessage;

  @LocalDateTimeConverter()
  final DateTime createdAt;

  CommunityModel({
    required this.id,
    required this.chatType,
    required this.name,
    required this.description,
    required this.imageUrl,
    required this.isVerified,
    required this.category,
    required this.owner,
    required this.createdBy,
    required this.memberCount,
    required this.isMember,
    this.lastMessage,
    required this.createdAt,
  });

  // Backward-compatible aliases in case older UI code still refers to these:
  String get title => name;
  String get creatorId => createdBy;
  int get membersCount => memberCount;

  String? get lastMessageContent => lastMessage?.content;
  DateTime? get lastMessageAt => lastMessage?.createdAt ?? createdAt;
  String? get lastMessageSenderId => lastMessage?.senderId;

  factory CommunityModel.fromJson(Map<String, dynamic> json) {
    final Map<String, dynamic> data = Map<String, dynamic>.from(json);

    if (!data.containsKey('_id') && data.containsKey('id')) {
      data['_id'] = data['id'];
    }
    if (data['owner'] != null) {
      data['owner'] = data['owner'].toString();
    }
    if (data['createdBy'] != null) {
      data['createdBy'] = data['createdBy'].toString();
    }
    if (data['createdAt'] == null) {
      data['createdAt'] = DateTime.now().toIso8601String();
    }
    return _$CommunityModelFromJson(data);
  }

  Map<String, dynamic> toJson() => _$CommunityModelToJson(this);
}
