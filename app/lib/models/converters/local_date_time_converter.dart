import 'package:json_annotation/json_annotation.dart';

class LocalDateTimeConverter implements JsonConverter<DateTime, String> {
  const LocalDateTimeConverter();

  @override
  DateTime fromJson(String json) => DateTime.parse(json).toLocal();

  @override
  String toJson(DateTime object) => object.toUtc().toIso8601String();
}

/// Nullable counterpart — `json_serializable` needs a distinct converter type
/// per nullability, it won't infer null-safety from the non-nullable one above.
class LocalDateTimeConverterNullable
    implements JsonConverter<DateTime?, String?> {
  const LocalDateTimeConverterNullable();

  @override
  DateTime? fromJson(String? json) =>
      json == null || json.isEmpty ? null : DateTime.parse(json).toLocal();

  @override
  String? toJson(DateTime? object) => object?.toUtc().toIso8601String();
}
