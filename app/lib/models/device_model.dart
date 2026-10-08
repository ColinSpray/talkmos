import 'package:json_annotation/json_annotation.dart';
import 'converters/local_date_time_converter.dart';

part 'device_model.g.dart';

/// One entry from GET /auth/devices — mirrors the shape authController.getDevices
/// returns from User.devices (see talkmos-backend modules/auth/deviceSessions.js).
@JsonSerializable()
class DeviceModel {
  @JsonKey(defaultValue: '')
  final String deviceId;

  @JsonKey(defaultValue: '')
  final String deviceName;

  @JsonKey(defaultValue: 'other')
  final String platform;

  @JsonKey(defaultValue: true)
  final bool isActive;

  @JsonKey(defaultValue: false)
  final bool isCurrent;

  @LocalDateTimeConverter()
  final DateTime loginAt;

  @LocalDateTimeConverter()
  final DateTime lastActiveAt;

  @LocalDateTimeConverterNullable()
  final DateTime? loggedOutAt;

  DeviceModel({
    required this.deviceId,
    required this.deviceName,
    required this.platform,
    required this.isActive,
    required this.isCurrent,
    required this.loginAt,
    required this.lastActiveAt,
    this.loggedOutAt,
  });

  factory DeviceModel.fromJson(Map<String, dynamic> json) {
    final Map<String, dynamic> data = Map<String, dynamic>.from(json);
    final now = DateTime.now().toIso8601String();
    data['loginAt'] ??= now;
    data['lastActiveAt'] ??= now;
    return _$DeviceModelFromJson(data);
  }

  Map<String, dynamic> toJson() => _$DeviceModelToJson(this);
}
