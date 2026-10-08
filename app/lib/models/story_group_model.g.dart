// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'story_group_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

StoryGroupModel _$StoryGroupModelFromJson(Map<String, dynamic> json) =>
    StoryGroupModel(
      user: UserModel.fromJson(json['user'] as Map<String, dynamic>),
      stories:
          (json['stories'] as List<dynamic>?)
              ?.map((e) => StoryModel.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );

Map<String, dynamic> _$StoryGroupModelToJson(StoryGroupModel instance) =>
    <String, dynamic>{'user': instance.user, 'stories': instance.stories};
