import 'package:json_annotation/json_annotation.dart';
import '../models/user_model.dart';
part 'friend_model.g.dart';

@JsonSerializable()
class FriendModel {
  @JsonKey(name: '_id', defaultValue: '')
  final String id;

  @JsonKey(defaultValue: '')
  final String name;
  final String? username;
  final String? email;
  final String? phone;
  final String? avatarUrl;
  final String? status;

  @JsonKey(defaultValue: false)
  final bool isVerified;

  final String? chatId;

  const FriendModel({
    required this.id,
    required this.name,
    this.username,
    this.email,
    this.phone,
    this.avatarUrl,
    this.status,
    this.isVerified = false,
    this.chatId,
  });

  factory FriendModel.fromJson(Map<String, dynamic> json) =>
      _$FriendModelFromJson(json);

  Map<String, dynamic> toJson() => _$FriendModelToJson(this);

  UserModel toUserModel() => UserModel(
    id: id,
    name: name,
    username: username,
    email: email,
    phone: phone,
    avatarUrl: avatarUrl,
    status: status,
    isVerified: isVerified,
  );
}
