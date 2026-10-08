import 'package:json_annotation/json_annotation.dart';
import 'user_model.dart';
import 'converters/local_date_time_converter.dart';

part 'story_model.g.dart';

@JsonSerializable()
class StoryModel {
  @JsonKey(name: '_id', defaultValue: '')
  final String id;

  @JsonKey(defaultValue: '')
  final String userId;

  final UserModel? userDetails;

  @JsonKey(defaultValue: '')
  final String mediaUrl;

  @JsonKey(defaultValue: 'image')
  final String type;

  final String? caption;
  final String? category;

  @JsonKey(defaultValue: 0)
  final int viewsCount;

  @JsonKey(defaultValue: false)
  final bool isViewed;

  @LocalDateTimeConverter()
  final DateTime createdAt;

  @LocalDateTimeConverter()
  final DateTime expiresAt;

  StoryModel({
    required this.id,
    required this.userId,
    this.userDetails,
    required this.mediaUrl,
    required this.type,
    this.caption,
    this.category,
    this.viewsCount = 0,
    this.isViewed = false,
    required this.createdAt,
    required this.expiresAt,
  });

  factory StoryModel.fromJson(Map<String, dynamic> json) {
    UserModel? user;
    if (json['userId'] != null && json['userId'] is Map) {
      user = UserModel.fromJson(Map<String, dynamic>.from(json['userId']));
    }

    final Map<String, dynamic> data = Map<String, dynamic>.from(json);
    if (!data.containsKey('_id') && data.containsKey('id')) {
      data['_id'] = data['id'];
    }
    data['userId'] = user?.id ?? json['userId']?.toString() ?? '';
    data['userDetails'] = user?.toJson();

    // Backend field is `viewed`, not `isViewed`.
    data['isViewed'] = data['viewed'] ?? data['isViewed'] ?? false;
    data['type'] = data['mediaType'] ?? data['type'] ?? 'image';

    if (data['createdAt'] == null) {
      data['createdAt'] = DateTime.now().toIso8601String();
    }
    if (data['expiresAt'] == null) {
      data['expiresAt'] = DateTime.now()
          .add(const Duration(hours: 24))
          .toIso8601String();
    }

    return _$StoryModelFromJson(data);
  }

  Map<String, dynamic> toJson() => _$StoryModelToJson(this);
}
