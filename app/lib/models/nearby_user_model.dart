import 'package:json_annotation/json_annotation.dart';
part 'nearby_user_model.g.dart';

enum NearbyTier {
  @JsonValue('right_here')
  rightHere,
  @JsonValue('very_close')
  veryClose,
  @JsonValue('nearby')
  nearby,
}

@JsonSerializable()
class NearbyUserModel {
  @JsonKey(name: '_id', defaultValue: '')
  final String id;

  @JsonKey(defaultValue: '')
  final String name;

  @JsonKey(defaultValue: '')
  final String username;

  @JsonKey(defaultValue: '')
  final String avatarUrl;

  @JsonKey(defaultValue: false)
  final bool isVerified;

  @JsonKey(defaultValue: NearbyTier.nearby, unknownEnumValue: NearbyTier.nearby)
  final NearbyTier tier;

  const NearbyUserModel({
    required this.id,
    required this.name,
    this.username = '',
    this.avatarUrl = '',
    this.isVerified = false,
    this.tier = NearbyTier.nearby,
  });

  factory NearbyUserModel.fromJson(Map<String, dynamic> json) =>
      _$NearbyUserModelFromJson(json);

  Map<String, dynamic> toJson() => _$NearbyUserModelToJson(this);
}
