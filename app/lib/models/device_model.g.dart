// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'device_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

DeviceModel _$DeviceModelFromJson(Map<String, dynamic> json) => DeviceModel(
  deviceId: json['deviceId'] as String? ?? '',
  deviceName: json['deviceName'] as String? ?? '',
  platform: json['platform'] as String? ?? 'other',
  isActive: json['isActive'] as bool? ?? true,
  isCurrent: json['isCurrent'] as bool? ?? false,
  loginAt: const LocalDateTimeConverter().fromJson(json['loginAt'] as String),
  lastActiveAt: const LocalDateTimeConverter().fromJson(
    json['lastActiveAt'] as String,
  ),
  loggedOutAt: const LocalDateTimeConverterNullable().fromJson(
    json['loggedOutAt'] as String?,
  ),
);

Map<String, dynamic> _$DeviceModelToJson(
  DeviceModel instance,
) => <String, dynamic>{
  'deviceId': instance.deviceId,
  'deviceName': instance.deviceName,
  'platform': instance.platform,
  'isActive': instance.isActive,
  'isCurrent': instance.isCurrent,
  'loginAt': const LocalDateTimeConverter().toJson(instance.loginAt),
  'lastActiveAt': const LocalDateTimeConverter().toJson(instance.lastActiveAt),
  'loggedOutAt': const LocalDateTimeConverterNullable().toJson(
    instance.loggedOutAt,
  ),
};
