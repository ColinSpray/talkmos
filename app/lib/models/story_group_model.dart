import 'package:json_annotation/json_annotation.dart';
import 'user_model.dart';
import 'story_model.dart';

part 'story_group_model.g.dart';

@JsonSerializable()
class StoryGroupModel {
  final UserModel user;

  @JsonKey(defaultValue: [])
  final List<StoryModel> stories;

  StoryGroupModel({required this.user, required this.stories});

  factory StoryGroupModel.fromJson(Map<String, dynamic> json) {
    final Map<String, dynamic> data = Map<String, dynamic>.from(json);
    data['user'] = data['user'] ?? {};
    data['stories'] = data['stories'] ?? [];
    return _$StoryGroupModelFromJson(data);
  }

  Map<String, dynamic> toJson() => _$StoryGroupModelToJson(this);
}
