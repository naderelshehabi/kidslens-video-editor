import 'package:freezed_annotation/freezed_annotation.dart';

import 'package:kidslens_video_editor/data/models/content_category.dart';
import 'package:kidslens_video_editor/data/models/converters.dart';
import 'package:kidslens_video_editor/data/models/edit_action.dart';
import 'package:kidslens_video_editor/data/models/visual_content_category.dart';

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
  @JsonValue('nudity')
  nudity,
  @JsonValue('sexualContent')
  sexualContent,
  @JsonValue('kissing')
  kissing,
  @JsonValue('immodestDress')
  immodestDress,
  @JsonValue('custom')
  custom,
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

  const Detection._();

  factory Detection.fromJson(Map<String, dynamic> json) =>
      _$DetectionFromJson(json);

  /// Key for storing the visual content category ID in metadata
  static const String visualContentCategoryKey = 'visualContentCategory';

  /// Key for storing bounding box coordinates in metadata
  static const String boundingBoxKey = 'boundingBox';

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

  /// Creates a visual content detection (NSFW, violence, etc.)
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
      ContentType.violence: 'Violent content detected',
      ContentType.blood: 'Blood/gore detected',
      ContentType.weapons: 'Weapon detected',
      ContentType.nudity: 'Nudity detected',
      ContentType.sexualContent: 'Sexual content detected',
      ContentType.kissing: 'Kissing detected',
      ContentType.immodestDress: 'Immodest dress detected',
      ContentType.custom: 'Custom content detected',
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

  /// Creates a visual content category detection (nudity, kissing, etc.)
  ///
  /// Uses [ContentType.nsfw] as the base type and stores the specific
  /// category ID in metadata to avoid extending the ContentType enum.
  factory Detection.visualContent({
    required String id,
    required String mediaId,
    required Duration startTime,
    required Duration endTime,
    required double confidence,
    required String categoryId,
    required String categoryName,
    VisualContentAction? action,
    Map<String, double>? boundingBox,
  }) {
    final meta = <String, dynamic>{
      visualContentCategoryKey: categoryId,
    };
    if (boundingBox != null) {
      meta[boundingBoxKey] = boundingBox;
    }
    if (action != null) {
      meta['action'] = action.name;
    }

    return Detection(
      id: id,
      mediaId: mediaId,
      type: ContentType.nsfw,
      startTime: startTime,
      endTime: endTime,
      confidence: confidence,
      description: '$categoryName detected',
      source: 'visual',
      metadata: meta,
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
      case ContentType.violence:
        return 'Violence';
      case ContentType.blood:
        return 'Blood/Gore';
      case ContentType.profanity:
        return 'Profanity';
      case ContentType.weapons:
        return 'Weapons';
      case ContentType.nudity:
        return 'Nudity';
      case ContentType.sexualContent:
        return 'Sexual Content';
      case ContentType.kissing:
        return 'Kissing';
      case ContentType.immodestDress:
        return 'Immodest Dress';
      case ContentType.custom:
        return categoryId ?? 'Custom';
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
      case ContentType.nudity:
        return 'visibility_off';
      case ContentType.sexualContent:
        return 'block';
      case ContentType.kissing:
        return 'favorite';
      case ContentType.immodestDress:
        return 'checkroom';
      case ContentType.custom:
        return 'category';
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
      case ContentType.blood:
        return EditActionType.blur;
      case ContentType.violence:
      case ContentType.weapons:
        return EditActionType.blur;
      case ContentType.nudity:
        return EditActionType.blur;
      case ContentType.sexualContent:
      case ContentType.kissing:
        return EditActionType.skip;
      case ContentType.immodestDress:
        return EditActionType.blur;
      case ContentType.custom:
        return EditActionType.blur;
    }
  }
}
