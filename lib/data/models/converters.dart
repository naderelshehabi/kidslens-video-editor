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
