// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'friend_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

FriendModel _$FriendModelFromJson(Map<String, dynamic> json) => FriendModel(
  id: json['_id'] as String? ?? '',
  name: json['name'] as String? ?? '',
  username: json['username'] as String?,
  email: json['email'] as String?,
  phone: json['phone'] as String?,
  avatarUrl: json['avatarUrl'] as String?,
  status: json['status'] as String?,
  isVerified: json['isVerified'] as bool? ?? false,
  chatId: json['chatId'] as String?,
);

Map<String, dynamic> _$FriendModelToJson(FriendModel instance) =>
    <String, dynamic>{
      '_id': instance.id,
      'name': instance.name,
      'username': instance.username,
      'email': instance.email,
      'phone': instance.phone,
      'avatarUrl': instance.avatarUrl,
      'status': instance.status,
      'isVerified': instance.isVerified,
      'chatId': instance.chatId,
    };
