import 'package:freezed_annotation/freezed_annotation.dart';

import 'converters.dart';

part 'detection.freezed.dart';
part 'detection.g.dart';

/// Types of content that can be detected
@JsonEnum()
enum ContentType {
  @JsonValue('nsfw')
  nsfw,
  @JsonValue('violence')
  violence,
  @JsonValue('blood')
  blood,
  @JsonValue('profanity')
  profanity,
  @JsonValue('weapons')
  weapons,
}

/// User review status for a detection
@JsonEnum()
enum DetectionUserStatus {
  /// Detection has not been reviewed by user
  @JsonValue('pending')
  pending,

  /// User confirmed the detection is accurate
  @JsonValue('confirmed')
  confirmed,

  /// User rejected the detection as false positive
  @JsonValue('rejected')
  rejected,

  /// User adjusted the detection boundaries or type
  @JsonValue('adjusted')
  adjusted,
}

/// Represents a detected content issue in the media
@freezed
class Detection with _$Detection {
  const Detection._();

  const factory Detection({
    /// Unique identifier for the detection
    required String id,

    /// Type of content detected
    required ContentType type,

    /// Start time of the detection in the media
    @DurationConverter() required Duration startTime,

    /// End time of the detection in the media
    @DurationConverter() required Duration endTime,

    /// Confidence score (0.0 to 1.0)
    required double confidence,

    /// Human-readable description of the detection
    required String description,

    /// User review status
    @Default(DetectionUserStatus.pending) DetectionUserStatus userStatus,

    /// Optional note from user
    String? userNote,

    /// Original start time before user adjustment
    @DurationConverter() Duration? originalStartTime,

    /// Original end time before user adjustment
    @DurationConverter() Duration? originalEndTime,

    /// Source of the detection (e.g., 'asr', 'visual', 'manual')
    String? source,

    /// Additional metadata
    Map<String, dynamic>? metadata,
  }) = _Detection;

  factory Detection.fromJson(Map<String, dynamic> json) =>
      _$DetectionFromJson(json);

  /// Creates a profanity detection
  factory Detection.profanity({
    required String id,
    required Duration startTime,
    required Duration endTime,
    required double confidence,
    required String word,
    String? userNote,
  }) {
    return Detection(
      id: id,
      type: ContentType.profanity,
      startTime: startTime,
      endTime: endTime,
      confidence: confidence,
      description: 'Profanity detected: "$word"',
      source: 'asr',
      metadata: {'word': word},
    );
  }

  /// Creates a visual content detection (NSFW, violence, etc.)
  factory Detection.visual({
    required String id,
    required ContentType type,
    required Duration startTime,
    required Duration endTime,
    required double confidence,
    String? description,
  }) {
    final defaultDescriptions = {
      ContentType.nsfw: 'NSFW content detected',
      ContentType.violence: 'Violent content detected',
      ContentType.blood: 'Blood/gore detected',
      ContentType.weapons: 'Weapon detected',
    };

    return Detection(
      id: id,
      type: type,
      startTime: startTime,
      endTime: endTime,
      confidence: confidence,
      description: description ?? defaultDescriptions[type] ?? 'Content detected',
      source: 'visual',
    );
  }

  /// Duration of the detection
  Duration get duration => endTime - startTime;

  /// Whether this detection has been reviewed by user
  bool get isReviewed => userStatus != DetectionUserStatus.pending;

  /// Whether this detection was confirmed by user
  bool get isConfirmed => userStatus == DetectionUserStatus.confirmed;

  /// Whether this detection was rejected by user
  bool get isRejected => userStatus == DetectionUserStatus.rejected;

  /// Whether this detection was adjusted by user
  bool get isAdjusted => userStatus == DetectionUserStatus.adjusted;

  /// Whether this detection is for audio content
  bool get isAudioDetection => type == ContentType.profanity;

  /// Whether this detection is for visual content
  bool get isVisualDetection => type != ContentType.profanity;

  /// Whether this detection has high confidence (>= 0.9)
  bool get isHighConfidence => confidence >= 0.9;

  /// Whether this detection has low confidence (< 0.7)
  bool get isLowConfidence => confidence < 0.7;

  /// Checks if this detection overlaps with a time range
  bool overlapsWithRange(Duration start, Duration end) {
    return startTime < end && endTime > start;
  }

  /// Checks if this detection overlaps with another detection
  bool overlapsWith(Detection other) {
    return overlapsWithRange(other.startTime, other.endTime);
  }

  /// Checks if a timestamp falls within this detection
  bool containsTime(Duration time) {
    return time >= startTime && time < endTime;
  }

  /// Creates a copy with user confirmation
  Detection confirm({String? note}) {
    return copyWith(
      userStatus: DetectionUserStatus.confirmed,
      userNote: note ?? userNote,
    );
  }

  /// Creates a copy with user rejection
  Detection reject({String? note}) {
    return copyWith(
      userStatus: DetectionUserStatus.rejected,
      userNote: note ?? userNote,
    );
  }

  /// Creates a copy with adjusted time range
  Detection adjustTimeRange({
    required Duration newStartTime,
    required Duration newEndTime,
    String? note,
  }) {
    return copyWith(
      startTime: newStartTime,
      endTime: newEndTime,
      originalStartTime: originalStartTime ?? startTime,
      originalEndTime: originalEndTime ?? endTime,
      userStatus: DetectionUserStatus.adjusted,
      userNote: note ?? userNote,
    );
  }

  /// Display name for the content type
  String get typeDisplayName {
    switch (type) {
      case ContentType.nsfw:
        return 'NSFW';
      case ContentType.violence:
        return 'Violence';
      case ContentType.blood:
        return 'Blood/Gore';
      case ContentType.profanity:
        return 'Profanity';
      case ContentType.weapons:
        return 'Weapons';
    }
  }

  /// Icon name for the content type
  String get typeIcon {
    switch (type) {
      case ContentType.nsfw:
        return 'visibility_off';
      case ContentType.violence:
        return 'sports_mma';
      case ContentType.blood:
        return 'water_drop';
      case ContentType.profanity:
        return 'volume_off';
      case ContentType.weapons:
        return 'warning';
    }
  }
}
