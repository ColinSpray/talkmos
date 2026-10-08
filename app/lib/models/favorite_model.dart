import 'package:json_annotation/json_annotation.dart';
import 'user_model.dart';

part 'favorite_model.g.dart';

@JsonSerializable()
class FavoriteModel {
  @JsonKey(name: '_id', defaultValue: '')
  final String id;

  @JsonKey(defaultValue: '')
  final String userId;

  final String? favoriteUserId;
  final UserModel? favoriteUserDetails;
  final String? favoriteGroupId;

  FavoriteModel({
    required this.id,
    required this.userId,
    this.favoriteUserId,
    this.favoriteUserDetails,
    this.favoriteGroupId,
  });

  factory FavoriteModel.fromJson(Map<String, dynamic> json) {
    UserModel? userDetails;
    if (json['favoriteUserId'] != null && json['favoriteUserId'] is Map) {
      userDetails = UserModel.fromJson(
        Map<String, dynamic>.from(json['favoriteUserId']),
      );
    }

    final Map<String, dynamic> data = Map<String, dynamic>.from(json);
    if (!data.containsKey('_id') && data.containsKey('id')) {
      data['_id'] = data['id'];
    }
    data['favoriteUserId'] =
        userDetails?.id ?? json['favoriteUserId']?.toString();
    data['favoriteUserDetails'] = userDetails?.toJson();

    return _$FavoriteModelFromJson(data);
  }

  Map<String, dynamic> toJson() => _$FavoriteModelToJson(this);
}
