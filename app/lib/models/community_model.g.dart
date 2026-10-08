// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'community_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

CommunityModel _$CommunityModelFromJson(Map<String, dynamic> json) =>
    CommunityModel(
      id: json['_id'] as String? ?? '',
      chatType: json['chatType'] as String? ?? 'community',
      name: json['name'] as String? ?? '',
      description: json['description'] as String? ?? '',
      imageUrl: json['imageUrl'] as String? ?? '',
      isVerified: json['isVerified'] as bool? ?? false,
      category: json['category'] as String? ?? '',
      owner: json['owner'] as String? ?? '',
      createdBy: json['createdBy'] as String? ?? '',
      memberCount: (json['memberCount'] as num?)?.toInt() ?? 0,
      isMember: json['isMember'] as bool? ?? false,
      lastMessage: json['lastMessage'] == null
          ? null
          : ChatMessageModel.fromJson(
              json['lastMessage'] as Map<String, dynamic>,
            ),
      createdAt: const LocalDateTimeConverter().fromJson(
        json['createdAt'] as String,
      ),
    );

Map<String, dynamic> _$CommunityModelToJson(CommunityModel instance) =>
    <String, dynamic>{
      '_id': instance.id,
      'chatType': instance.chatType,
      'name': instance.name,
      'description': instance.description,
      'imageUrl': instance.imageUrl,
      'isVerified': instance.isVerified,
      'category': instance.category,
      'owner': instance.owner,
      'createdBy': instance.createdBy,
      'memberCount': instance.memberCount,
      'isMember': instance.isMember,
      'lastMessage': instance.lastMessage,
      'createdAt': const LocalDateTimeConverter().toJson(instance.createdAt),
    };
