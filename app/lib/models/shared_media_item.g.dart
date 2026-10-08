// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'shared_media_item.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

SharedMediaItem _$SharedMediaItemFromJson(Map<String, dynamic> json) =>
    SharedMediaItem(
      id: _idFromJson(json['_id']),
      messageType: _messageTypeFromJson(json['messageType']),
      media: MessageMedia.fromJson(json['media'] as Map<String, dynamic>?),
      createdAt: _createdAtFromJson(json['createdAt']),
    );
