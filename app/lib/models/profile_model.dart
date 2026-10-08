import 'package:json_annotation/json_annotation.dart';

part 'profile_model.g.dart';

@JsonSerializable()
class ProfileModel {
  @JsonKey(defaultValue: 'everyone')
  final String privacyLastSeen; // 'everyone', 'contacts', 'nobody'

  @JsonKey(defaultValue: false)
  final bool privacyReadReceipts;

  @JsonKey(defaultValue: false)
  final bool notifMessages;

  @JsonKey(defaultValue: false)
  final bool notifCalls;

  @JsonKey(defaultValue: false)
  final bool notifCommunities;

  @JsonKey(defaultValue: 'system')
  final String theme; // 'light', 'dark', 'system'

  ProfileModel({
    required this.privacyLastSeen,
    required this.privacyReadReceipts,
    required this.notifMessages,
    required this.notifCalls,
    required this.notifCommunities,
    required this.theme,
  });

  factory ProfileModel.fromJson(Map<String, dynamic> json) =>
      _$ProfileModelFromJson(json);

  Map<String, dynamic> toJson() => _$ProfileModelToJson(this);
}
