// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'shared_attachment_payloads.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

SharedContactPayload _$SharedContactPayloadFromJson(
  Map<String, dynamic> json,
) => SharedContactPayload(
  name: _asString(json['name']),
  phone: _asString(json['phone']),
);

Map<String, dynamic> _$SharedContactPayloadToJson(
  SharedContactPayload instance,
) => <String, dynamic>{'name': instance.name, 'phone': instance.phone};

SharedLocationPayload _$SharedLocationPayloadFromJson(
  Map<String, dynamic> json,
) => SharedLocationPayload(
  lat: (json['lat'] as num?)?.toDouble() ?? 0.0,
  lng: (json['lng'] as num?)?.toDouble() ?? 0.0,
);

Map<String, dynamic> _$SharedLocationPayloadToJson(
  SharedLocationPayload instance,
) => <String, dynamic>{'lat': instance.lat, 'lng': instance.lng};
