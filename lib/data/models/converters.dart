import 'package:freezed_annotation/freezed_annotation.dart';

/// Converter for Duration to/from JSON (stored as microseconds)
class DurationConverter implements JsonConverter<Duration, int> {
  const DurationConverter();

  @override
  Duration fromJson(int json) => Duration(microseconds: json);

  @override
  int toJson(Duration object) => object.inMicroseconds;
}

/// Converter for nullable Duration to/from JSON (stored as microseconds)
class NullableDurationConverter implements JsonConverter<Duration?, int?> {
  const NullableDurationConverter();

  @override
  Duration? fromJson(int? json) =>
      json != null ? Duration(microseconds: json) : null;

  @override
  int? toJson(Duration? object) => object?.inMicroseconds;
}

/// Converter for DateTime to/from JSON (stored as ISO 8601 string)
class DateTimeConverter implements JsonConverter<DateTime, String> {
  const DateTimeConverter();

  @override
  DateTime fromJson(String json) => DateTime.parse(json);

  @override
  String toJson(DateTime object) => object.toIso8601String();
}

/// Converter for nullable DateTime to/from JSON
class NullableDateTimeConverter implements JsonConverter<DateTime?, String?> {
  const NullableDateTimeConverter();

  @override
  DateTime? fromJson(String? json) =>
      json != null ? DateTime.parse(json) : null;

  @override
  String? toJson(DateTime? object) => object?.toIso8601String();
}
