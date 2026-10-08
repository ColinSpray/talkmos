// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'nearby_user_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

NearbyUserModel _$NearbyUserModelFromJson(Map<String, dynamic> json) =>
    NearbyUserModel(
      id: json['_id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      username: json['username'] as String? ?? '',
      avatarUrl: json['avatarUrl'] as String? ?? '',
      isVerified: json['isVerified'] as bool? ?? false,
      tier:
          $enumDecodeNullable(
            _$NearbyTierEnumMap,
            json['tier'],
            unknownValue: NearbyTier.nearby,
          ) ??
          NearbyTier.nearby,
    );

Map<String, dynamic> _$NearbyUserModelToJson(NearbyUserModel instance) =>
    <String, dynamic>{
      '_id': instance.id,
      'name': instance.name,
      'username': instance.username,
      'avatarUrl': instance.avatarUrl,
      'isVerified': instance.isVerified,
      'tier': _$NearbyTierEnumMap[instance.tier]!,
    };

const _$NearbyTierEnumMap = {
  NearbyTier.rightHere: 'right_here',
  NearbyTier.veryClose: 'very_close',
  NearbyTier.nearby: 'nearby',
};
