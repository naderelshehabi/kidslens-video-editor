import 'package:freezed_annotation/freezed_annotation.dart';

import 'package:kidslens_video_editor/data/models/converters.dart';
import 'package:kidslens_video_editor/data/models/edit_action.dart';

part 'detection.freezed.dart';
part 'detection.g.dart';

/// Types of content that can be detected
@JsonEnum()
enum ContentType {
  @JsonValue('nsfw')
  nsfw,
  @JsonValue('profanity')
  profanity,
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
  const factory Detection({
    /// Unique identifier for the detection
    required String id,

    /// ID of the media file this detection belongs to
    required String mediaId,

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

  /// Creates a profanity detection
  factory Detection.profanity({
    required String id,
    required String mediaId,
    required Duration startTime,
    required Duration endTime,
    required double confidence,
    required String word,
  }) =>
      Detection(
        id: id,
        mediaId: mediaId,
        type: ContentType.profanity,
        startTime: startTime,
        endTime: endTime,
        confidence: confidence,
        description: 'Profanity detected: "$word"',
        source: 'asr',
        metadata: {'word': word},
      );

  /// Creates a visual content detection.
  factory Detection.visual({
    required String id,
    required String mediaId,
    required ContentType type,
    required Duration startTime,
    required Duration endTime,
    required double confidence,
    String? description,
  }) {
    final defaultDescriptions = {
      ContentType.nsfw: 'NSFW content detected',
    };

    return Detection(
      id: id,
      mediaId: mediaId,
      type: type,
      startTime: startTime,
      endTime: endTime,
      confidence: confidence,
      description: description ?? defaultDescriptions[type] ?? 'Content detected',
      source: 'visual',
    );
  }

  const Detection._();

  factory Detection.fromJson(Map<String, dynamic> json) =>
      _$DetectionFromJson(json);

  /// Key for storing the visual content category ID in metadata
  static const String visualContentCategoryKey = 'visualContentCategory';

  /// Key for storing bounding box coordinates in metadata
  static const String boundingBoxKey = 'boundingBox';

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

  /// Whether this detection is a visual content category detection
  bool get isVisualContentCategory =>
      metadata?[visualContentCategoryKey] != null;

  /// Get the visual content category ID from metadata
  String? get visualContentCategoryId =>
      metadata?[visualContentCategoryKey] as String?;

  /// Get the bounding box from metadata (normalized coordinates)
  Map<String, double>? get boundingBox {
    final box = metadata?[boundingBoxKey];
    if (box is Map) {
      return box.map((k, v) => MapEntry(k.toString(), (v as num).toDouble()));
    }
    return null;
  }

  /// Whether this detection has a bounding box
  bool get hasBoundingBox => metadata?[boundingBoxKey] != null;

  /// Whether this detection has high confidence (>= 0.9)
  bool get isHighConfidence => confidence >= 0.9;

  /// Whether this detection has low confidence (< 0.7)
  bool get isLowConfidence => confidence < 0.7;

  /// Checks if this detection overlaps with a time range
  bool overlapsWithRange(Duration start, Duration end) =>
      startTime < end && endTime > start;

  /// Checks if this detection overlaps with another detection
  bool overlapsWith(Detection other) =>
      overlapsWithRange(other.startTime, other.endTime);

  /// Checks if a timestamp falls within this detection
  bool containsTime(Duration time) => time >= startTime && time < endTime;

  /// Creates a copy with user confirmation
  Detection confirm({String? note}) => copyWith(
        userStatus: DetectionUserStatus.confirmed,
        userNote: note ?? userNote,
      );

  /// Creates a copy with user rejection
  Detection reject({String? note}) => copyWith(
        userStatus: DetectionUserStatus.rejected,
        userNote: note ?? userNote,
      );

  /// Creates a copy with adjusted time range
  Detection adjustTimeRange({
    required Duration newStartTime,
    required Duration newEndTime,
    String? note,
  }) =>
      copyWith(
        startTime: newStartTime,
        endTime: newEndTime,
        originalStartTime: originalStartTime ?? startTime,
        originalEndTime: originalEndTime ?? endTime,
        userStatus: DetectionUserStatus.adjusted,
        userNote: note ?? userNote,
      );

  /// Display name for the content type
  String get typeDisplayName {
    // For visual content categories, use the category ID as a friendlier name
    final categoryId = visualContentCategoryId;
    if (categoryId != null) {
      return categoryId
          .replaceAll('_', ' ')
          .split(' ')
          .map((w) => w.isNotEmpty ? '${w[0].toUpperCase()}${w.substring(1)}' : '')
          .join(' ');
    }

    switch (type) {
      case ContentType.nsfw:
        return 'NSFW';
      case ContentType.profanity:
        return 'Profanity';
    }
  }

  /// Icon name for the content type
  String get typeIcon {
    switch (type) {
      case ContentType.nsfw:
        return 'visibility_off';
      case ContentType.profanity:
        return 'volume_off';
    }
  }

  /// Whether this detection has an edit action applied to it
  /// (needs to be set externally based on edit actions)
  bool get hasAction => metadata?['hasAction'] == true;

  /// Get the detected content (e.g., the profane word)
  String? get content {
    if (type == ContentType.profanity) {
      return metadata?['word'] as String?;
    }
    return null;
  }

  /// Suggested edit action based on detection type
  EditActionType get suggestedAction {
    // Check metadata for visual content category action (from RemediationAction)
    final actionStr = metadata?['action'] as String?;
    if (actionStr != null) {
      switch (actionStr) {
        case 'blurRegion':
        case 'pixelateRegion':
        case 'blackBoxRegion':
        case 'blurFullFrame':
          return EditActionType.blur;
        case 'cutScene':
          return EditActionType.skip;
        case 'mute':
          return EditActionType.mute;
        case 'beep':
          return EditActionType.beep;
      }
    }

    switch (type) {
      case ContentType.profanity:
        return EditActionType.mute;
      case ContentType.nsfw:
        return EditActionType.blur;
    }
  }
}
