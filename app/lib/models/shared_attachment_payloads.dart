import 'dart:convert';
import 'package:json_annotation/json_annotation.dart';
part 'shared_attachment_payloads.g.dart';

String _asString(Object? value) => value?.toString() ?? '';

@JsonSerializable()
class SharedContactPayload {
  @JsonKey(fromJson: _asString)
  final String name;

  @JsonKey(fromJson: _asString)
  final String phone;

  const SharedContactPayload({required this.name, required this.phone});

  factory SharedContactPayload.fromJson(Map<String, dynamic> json) =>
      _$SharedContactPayloadFromJson(json);

  Map<String, dynamic> toJson() => _$SharedContactPayloadToJson(this);

  String encode() => jsonEncode(toJson());

  /// Null if [content] isn't a valid encoded contact payload.
  static SharedContactPayload? tryDecode(String content) {
    try {
      final decoded = jsonDecode(content);
      if (decoded is! Map<String, dynamic>) return null;
      final payload = SharedContactPayload.fromJson(decoded);
      return payload.name.isEmpty ? null : payload;
    } catch (_) {
      return null;
    }
  }
}

/// A location shared in a chat message. Same encoding approach as
/// [SharedContactPayload] — JSON in `content` for `messageType: location`.
@JsonSerializable()
class SharedLocationPayload {
  @JsonKey(defaultValue: 0.0)
  final double lat;

  @JsonKey(defaultValue: 0.0)
  final double lng;

  const SharedLocationPayload({required this.lat, required this.lng});

  factory SharedLocationPayload.fromJson(Map<String, dynamic> json) =>
      _$SharedLocationPayloadFromJson(json);

  Map<String, dynamic> toJson() => _$SharedLocationPayloadToJson(this);

  String encode() => jsonEncode(toJson());

  static SharedLocationPayload? tryDecode(String content) {
    try {
      final decoded = jsonDecode(content);
      if (decoded is! Map<String, dynamic>) return null;
      final payload = SharedLocationPayload.fromJson(decoded);
      return (payload.lat == 0 && payload.lng == 0) ? null : payload;
    } catch (_) {
      return null;
    }
  }
}
