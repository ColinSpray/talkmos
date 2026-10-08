// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'user_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

UserModel _$UserModelFromJson(Map<String, dynamic> json) => UserModel(
  id: json['_id'] as String? ?? '',
  name: json['name'] as String? ?? '',
  email: json['email'] as String?,
  phone: json['phone'] as String?,
  username: json['username'] as String?,
  avatarUrl: json['avatarUrl'] as String?,
  bio: json['bio'] as String?,
  location: json['location'] as String?,
  status: json['status'] as String?,
  isPremium: json['isPremium'] as bool? ?? false,
  isVerified: json['isVerified'] as bool? ?? false,
  isPublic: json['isPublic'] as bool? ?? true,
  lastSeenAt: const LocalDateTimeConverterNullable().fromJson(
    json['lastSeenAt'] as String?,
  ),
  createdAt: const LocalDateTimeConverterNullable().fromJson(
    json['createdAt'] as String?,
  ),
);

Map<String, dynamic> _$UserModelToJson(UserModel instance) => <String, dynamic>{
  '_id': instance.id,
  'name': instance.name,
  'email': instance.email,
  'phone': instance.phone,
  'username': instance.username,
  'avatarUrl': instance.avatarUrl,
  'bio': instance.bio,
  'location': instance.location,
  'status': instance.status,
  'isPremium': instance.isPremium,
  'isVerified': instance.isVerified,
  'isPublic': instance.isPublic,
  'lastSeenAt': const LocalDateTimeConverterNullable().toJson(
    instance.lastSeenAt,
  ),
  'createdAt': const LocalDateTimeConverterNullable().toJson(
    instance.createdAt,
  ),
};
