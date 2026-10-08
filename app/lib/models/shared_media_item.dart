import 'package:json_annotation/json_annotation.dart';
import 'chat_message_model.dart';
part 'shared_media_item.g.dart';

@JsonSerializable(createToJson: false)
class SharedMediaItem {
  @JsonKey(name: '_id', fromJson: _idFromJson)
  final String id;

  @JsonKey(fromJson: _messageTypeFromJson)
  final MessageType messageType;

  @JsonKey(fromJson: MessageMedia.fromJson)
  final MessageMedia media;

  @JsonKey(fromJson: _createdAtFromJson)
  final DateTime createdAt;

  const SharedMediaItem({
    required this.id,
    required this.messageType,
    required this.media,
    required this.createdAt,
  });

  factory SharedMediaItem.fromJson(Map<String, dynamic> json) =>
      _$SharedMediaItemFromJson(json);
}

/// Coerced rather than cast: an `_id` that arrives as anything but a string
/// should degrade to empty, not throw and lose the whole page.
String _idFromJson(Object? value) => value?.toString() ?? '';

MessageType _messageTypeFromJson(Object? value) =>
    ChatMessageModel.messageTypeFromString(value?.toString());

DateTime _createdAtFromJson(Object? value) =>
    DateTime.tryParse(value?.toString() ?? '')?.toLocal() ?? DateTime.now();

class SharedMediaPage {
  final List<SharedMediaItem> items;
  final int total;

  const SharedMediaPage({required this.items, required this.total});
}
