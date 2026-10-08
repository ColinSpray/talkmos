// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'story_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

StoryModel _$StoryModelFromJson(Map<String, dynamic> json) => StoryModel(
  id: json['_id'] as String? ?? '',
  userId: json['userId'] as String? ?? '',
  userDetails: json['userDetails'] == null
      ? null
      : UserModel.fromJson(json['userDetails'] as Map<String, dynamic>),
  mediaUrl: json['mediaUrl'] as String? ?? '',
  type: json['type'] as String? ?? 'image',
  caption: json['caption'] as String?,
  category: json['category'] as String?,
  viewsCount: (json['viewsCount'] as num?)?.toInt() ?? 0,
  isViewed: json['isViewed'] as bool? ?? false,
  createdAt: const LocalDateTimeConverter().fromJson(
    json['createdAt'] as String,
  ),
  expiresAt: const LocalDateTimeConverter().fromJson(
    json['expiresAt'] as String,
  ),
);

Map<String, dynamic> _$StoryModelToJson(StoryModel instance) =>
    <String, dynamic>{
      '_id': instance.id,
      'userId': instance.userId,
      'userDetails': instance.userDetails,
      'mediaUrl': instance.mediaUrl,
      'type': instance.type,
      'caption': instance.caption,
      'category': instance.category,
      'viewsCount': instance.viewsCount,
      'isViewed': instance.isViewed,
      'createdAt': const LocalDateTimeConverter().toJson(instance.createdAt),
      'expiresAt': const LocalDateTimeConverter().toJson(instance.expiresAt),
    };
