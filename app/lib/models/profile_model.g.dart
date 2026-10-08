// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'profile_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ProfileModel _$ProfileModelFromJson(Map<String, dynamic> json) => ProfileModel(
  privacyLastSeen: json['privacyLastSeen'] as String? ?? 'everyone',
  privacyReadReceipts: json['privacyReadReceipts'] as bool? ?? false,
  notifMessages: json['notifMessages'] as bool? ?? false,
  notifCalls: json['notifCalls'] as bool? ?? false,
  notifCommunities: json['notifCommunities'] as bool? ?? false,
  theme: json['theme'] as String? ?? 'system',
);

Map<String, dynamic> _$ProfileModelToJson(ProfileModel instance) =>
    <String, dynamic>{
      'privacyLastSeen': instance.privacyLastSeen,
      'privacyReadReceipts': instance.privacyReadReceipts,
      'notifMessages': instance.notifMessages,
      'notifCalls': instance.notifCalls,
      'notifCommunities': instance.notifCommunities,
      'theme': instance.theme,
    };
