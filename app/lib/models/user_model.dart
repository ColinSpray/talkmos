import 'package:json_annotation/json_annotation.dart';
import 'converters/local_date_time_converter.dart';
part 'user_model.g.dart';

@JsonSerializable()
class UserModel {
  @JsonKey(name: '_id', defaultValue: '')
  final String id;

  @JsonKey(defaultValue: '')
  final String name;
  final String? email;
  final String? phone;
  final String? username;
  final String? avatarUrl;
  final String? bio;
  final String? location;
  final String? status;

  @JsonKey(defaultValue: false)
  final bool isPremium;

  @JsonKey(defaultValue: false)
  final bool isVerified;

  @JsonKey(defaultValue: true)
  final bool isPublic;

  @LocalDateTimeConverterNullable()
  final DateTime? lastSeenAt;

  @LocalDateTimeConverterNullable()
  final DateTime? createdAt;
  // fcmToken removed — backend no longer sends this field in user responses;
  // it's a server-internal value used for push notifications, not client data

  UserModel({
    required this.id,
    required this.name,
    this.email,
    this.phone,
    this.username,
    this.avatarUrl,
    this.bio,
    this.location,
    this.status,
    this.isPremium = false,
    this.isVerified = false,
    this.isPublic = true,
    this.lastSeenAt,
    this.createdAt,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    dynamic resolved = json['user'] ?? json['data'] ?? json;
    if (resolved is Map && resolved.containsKey('user')) {
      resolved = resolved['user'];
    }
    final Map<String, dynamic> data = Map<String, dynamic>.from(resolved);
    if (!data.containsKey('_id') && data.containsKey('id')) {
      data['_id'] = data['id'];
    }
    return _$UserModelFromJson(data);
  }

  Map<String, dynamic> toJson() => _$UserModelToJson(this);

  UserModel copyWith({
    String? id,
    String? name,
    String? email,
    String? phone,
    String? username,
    String? avatarUrl,
    String? bio,
    String? location,
    String? status,
    bool? isPremium,
    bool? isVerified,
    bool? isPublic,
    DateTime? lastSeenAt,
    DateTime? createdAt,
  }) {
    return UserModel(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      username: username ?? this.username,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      bio: bio ?? this.bio,
      location: location ?? this.location,
      status: status ?? this.status,
      isPremium: isPremium ?? this.isPremium,
      isVerified: isVerified ?? this.isVerified,
      isPublic: isPublic ?? this.isPublic,
      lastSeenAt: lastSeenAt ?? this.lastSeenAt,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
