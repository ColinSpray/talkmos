// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'favorite_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

FavoriteModel _$FavoriteModelFromJson(Map<String, dynamic> json) =>
    FavoriteModel(
      id: json['_id'] as String? ?? '',
      userId: json['userId'] as String? ?? '',
      favoriteUserId: json['favoriteUserId'] as String?,
      favoriteUserDetails: json['favoriteUserDetails'] == null
          ? null
          : UserModel.fromJson(
              json['favoriteUserDetails'] as Map<String, dynamic>,
            ),
      favoriteGroupId: json['favoriteGroupId'] as String?,
    );

Map<String, dynamic> _$FavoriteModelToJson(FavoriteModel instance) =>
    <String, dynamic>{
      '_id': instance.id,
      'userId': instance.userId,
      'favoriteUserId': instance.favoriteUserId,
      'favoriteUserDetails': instance.favoriteUserDetails,
      'favoriteGroupId': instance.favoriteGroupId,
    };
