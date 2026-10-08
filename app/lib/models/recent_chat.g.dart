// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'recent_chat.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ChatMember _$ChatMemberFromJson(Map<String, dynamic> json) => ChatMember(
  id: json['_id'] as String,
  name: json['name'] as String,
  imageUrl: json['imageUrl'] as String? ?? '',
);

Map<String, dynamic> _$ChatMemberToJson(ChatMember instance) =>
    <String, dynamic>{
      '_id': instance.id,
      'name': instance.name,
      'imageUrl': instance.imageUrl,
    };

RecentChat _$RecentChatFromJson(Map<String, dynamic> json) => RecentChat(
  id: json['_id'] as String,
  chatType: json['chatType'] as String? ?? 'direct',
  spaceId: json['spaceId'] as String?,
  activeCall: json['activeCall'],
  deletedAt: const LocalDateTimeConverterNullable().fromJson(
    json['deletedAt'] as String?,
  ),
  createdAt: const LocalDateTimeConverter().fromJson(
    json['createdAt'] as String,
  ),
  name: json['name'] as String? ?? '',
  imageUrl: json['imageUrl'] as String? ?? '',
  members:
      (json['members'] as List<dynamic>?)
          ?.map((e) => ChatMember.fromJson(e as Map<String, dynamic>))
          .toList() ??
      [],
  lastActivityAt: const LocalDateTimeConverterNullable().fromJson(
    json['lastActivityAt'] as String?,
  ),
  lastMessage: json['lastMessage'] == null
      ? null
      : ChatMessageModel.fromJson(json['lastMessage'] as Map<String, dynamic>),
  isPinned: json['isPinned'] as bool? ?? false,
  isMuted: json['isMuted'] as bool? ?? false,
  isArchived: json['isArchived'] as bool? ?? false,
  unreadCount: (json['unreadCount'] as num?)?.toInt() ?? 0,
);

Map<String, dynamic> _$RecentChatToJson(RecentChat instance) =>
    <String, dynamic>{
      '_id': instance.id,
      'chatType': instance.chatType,
      'spaceId': instance.spaceId,
      'activeCall': instance.activeCall,
      'deletedAt': const LocalDateTimeConverterNullable().toJson(
        instance.deletedAt,
      ),
      'createdAt': const LocalDateTimeConverter().toJson(instance.createdAt),
      'name': instance.name,
      'imageUrl': instance.imageUrl,
      'members': instance.members.map((e) => e.toJson()).toList(),
      'lastActivityAt': const LocalDateTimeConverterNullable().toJson(
        instance.lastActivityAt,
      ),
      'lastMessage': instance.lastMessage?.toJson(),
      'isPinned': instance.isPinned,
      'isMuted': instance.isMuted,
      'isArchived': instance.isArchived,
      'unreadCount': instance.unreadCount,
    };
