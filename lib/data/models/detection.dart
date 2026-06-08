import 'package:freezed_annotation/freezed_annotation.dart';

import 'package:kidslens_video_editor/data/models/content_category.dart';
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
      description:
          description ?? defaultDescriptions[type] ?? 'Content detected',
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

  /// Key for storing all normalized bounding boxes in metadata
  static const String boundingBoxesKey = 'boundingBoxes';

  /// Key for storing the family-safety policy category ID in metadata
  static const String policyCategoryKey = 'policyCategoryId';

  /// Key for storing the family-safety policy severity in metadata
  static const String policySeverityKey = 'policySeverity';

  /// Key for storing the primary user-facing rationale in metadata
  static const String rationaleKey = 'rationale';

  /// Key for storing all user-facing rationales in metadata
  static const String rationalesKey = 'rationales';

  /// Key for storing source model IDs or display names in metadata
  static const String sourceModelsKey = 'sourceModels';

  /// Key for storing supporting evidence IDs in metadata
  static const String supportingEvidenceIdsKey = 'supportingEvidenceIds';

  /// Key for storing boundary/grounding status in metadata
  static const String groundingStatusKey = 'groundingStatus';

  /// Key for storing grounded region IDs in metadata
  static const String regionIdsKey = 'regionIds';

  /// Key for storing the recommended remediation action in metadata
  static const String actionKey = 'action';

  /// Optional key for a supporting thumbnail path in metadata
  static const String thumbnailPathKey = 'thumbnailPath';

  /// Optional key for a supporting frame image path in metadata
  static const String framePathKey = 'framePath';

  /// Optional key for a supporting sampled frame ID in metadata
  static const String frameIdKey = 'frameId';

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

  /// Get the family-safety policy category ID from metadata.
  String? get policyCategoryId {
    final value = metadata?[policyCategoryKey] ??
        metadata?['policyContentType'] ??
        metadata?['migrationContentType'];
    return value is String && value.trim().isNotEmpty ? value : null;
  }

  /// Display label for the explainable policy category.
  String get explainableCategoryLabel =>
      _humanizePolicyLabel(policyCategoryId ?? visualContentCategoryId) ??
      typeDisplayName;

  /// Severity emitted by the policy engine or temporal fusion layer.
  String? get policySeverity {
    final value = metadata?[policySeverityKey] ?? metadata?['severity'];
    return value is String && value.trim().isNotEmpty ? value : null;
  }

  /// Display label for policy severity.
  String? get policySeverityLabel => _humanizePolicyLabel(policySeverity);

  /// Primary user-facing rationale for the detection.
  String? get rationale {
    final value = metadata?[rationaleKey];
    return value is String && value.trim().isNotEmpty ? value : null;
  }

  /// All user-facing rationales, excluding empty values and duplicates.
  List<String> get rationales {
    final values = metadata?[rationalesKey];
    if (values is Iterable) {
      return _stringList(values);
    }
    final primary = rationale;
    return primary == null ? const <String>[] : <String>[primary];
  }

  /// Local model IDs or display names that contributed to the detection.
  List<String> get sourceModels => _stringList(metadata?[sourceModelsKey]);

  /// Evidence records that support this detection.
  List<String> get supportingEvidenceIds =>
      _stringList(metadata?[supportingEvidenceIdsKey]);

  /// Grounding status emitted by the grounding or fusion layer.
  String? get groundingStatus {
    final value = metadata?[groundingStatusKey];
    return value is String && value.trim().isNotEmpty ? value : null;
  }

  /// User-facing localization label.
  String get localizationLabel {
    final status = groundingStatus;
    if (hasBoundary) return 'Region-level';
    if (status == 'scene_level_only' || status == 'ungrounded') {
      return 'Scene-level';
    }
    if (status == null) return isAudioDetection ? 'Audio span' : 'Scene-level';
    return _humanizePolicyLabel(status) ?? status;
  }

  /// Grounded region IDs attached to this detection.
  List<String> get regionIds => _stringList(metadata?[regionIdsKey]);

  /// Get the bounding box from metadata (normalized coordinates)
  Map<String, double>? get boundingBox {
    final box = _normalizeBox(metadata?[boundingBoxKey]);
    if (box != null) return box;

    final boxes = boundingBoxes;
    return boxes.isEmpty ? null : boxes.first;
  }

  /// Whether this detection has a bounding box
  bool get hasBoundingBox => boundingBox != null;

  /// All normalized bounding boxes attached to this detection.
  List<Map<String, double>> get boundingBoxes {
    final boxes = <Map<String, double>>[];
    final allBoxes = metadata?[boundingBoxesKey];
    if (allBoxes is Iterable) {
      for (final box in allBoxes) {
        final normalized = _normalizeBox(box);
        if (normalized != null) boxes.add(normalized);
      }
    }

    final primary = _normalizeBox(metadata?[boundingBoxKey]);
    if (primary != null && !_containsBox(boxes, primary)) {
      boxes.insert(0, primary);
    }

    return List.unmodifiable(boxes);
  }

  /// Whether this detection has boundary-level evidence.
  bool get hasBoundary => boundingBoxes.isNotEmpty || regionIds.isNotEmpty;

  /// Whether this detection should be treated as a scene-level finding.
  bool get isSceneLevelDetection => !hasBoundary && isVisualDetection;

  /// Whether this detection has explainability metadata from the new pipeline.
  bool get hasExplainabilityMetadata =>
      policyCategoryId != null ||
      policySeverity != null ||
      rationale != null ||
      sourceModels.isNotEmpty ||
      supportingEvidenceIds.isNotEmpty ||
      groundingStatus != null ||
      metadata?[actionKey] != null;

  /// Optional local image path for a supporting thumbnail or sampled frame.
  String? get supportingThumbnailPath {
    final value = metadata?[thumbnailPathKey] ?? metadata?[framePathKey];
    return value is String && value.trim().isNotEmpty ? value : null;
  }

  /// Optional sampled frame ID for this detection.
  String? get supportingFrameId {
    final value = metadata?[frameIdKey] ??
        metadata?['sampledFrameId'] ??
        metadata?['frameRefId'];
    return value is String && value.trim().isNotEmpty ? value : null;
  }

  /// Human-readable supporting frame label, if available.
  String? get supportingFrameLabel {
    final frameId = supportingFrameId;
    if (frameId != null) return 'Frame $frameId';
    if (supportingThumbnailPath != null) return 'Supporting frame';
    return null;
  }

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
          .map(
            (w) => w.isNotEmpty ? '${w[0].toUpperCase()}${w.substring(1)}' : '',
          )
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
    final actionStr = metadata?[actionKey] as String?;
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

  /// Recommended remediation action from metadata, if available.
  RemediationAction? get suggestedRemediationAction {
    final actionStr = metadata?[actionKey] as String?;
    if (actionStr == null) return null;

    for (final action in RemediationAction.values) {
      if (action.name == actionStr) return action;
    }
    return null;
  }

  /// Display label for the recommended remediation action.
  String get suggestedActionLabel =>
      suggestedRemediationAction?.displayName ??
      switch (suggestedAction) {
        EditActionType.mute => 'Mute',
        EditActionType.beep => 'Beep',
        EditActionType.blur => hasBoundary ? 'Blur Region' : 'Blur Frame',
        EditActionType.cut => 'Cut',
        EditActionType.skip => 'Cut Scene',
      };

  /// Display label for the current user review state.
  String get reviewStatusLabel => switch (userStatus) {
        DetectionUserStatus.pending => 'Pending review',
        DetectionUserStatus.confirmed => 'Confirmed',
        DetectionUserStatus.rejected => 'Rejected',
        DetectionUserStatus.adjusted => 'Adjusted',
      };

  static List<String> _stringList(Object? value) {
    if (value is! Iterable) return const <String>[];

    final values = <String>[];
    for (final item in value) {
      if (item is String && item.trim().isNotEmpty) {
        final trimmed = item.trim();
        if (!values.contains(trimmed)) values.add(trimmed);
      }
    }
    return List.unmodifiable(values);
  }

  static Map<String, double>? _normalizeBox(Object? value) {
    if (value is! Map) return null;

    final x = _numValue(value['x']);
    final y = _numValue(value['y']);
    final width = _numValue(value['width'] ?? value['w']);
    final height = _numValue(value['height'] ?? value['h']);
    if (x == null || y == null || width == null || height == null) {
      return null;
    }

    return {
      'x': x,
      'y': y,
      'width': width,
      'height': height,
    };
  }

  static double? _numValue(Object? value) =>
      value is num ? value.toDouble() : null;

  static bool _containsBox(
    List<Map<String, double>> boxes,
    Map<String, double> candidate,
  ) =>
      boxes.any(
        (box) =>
            box['x'] == candidate['x'] &&
            box['y'] == candidate['y'] &&
            box['width'] == candidate['width'] &&
            box['height'] == candidate['height'],
      );

  static String? _humanizePolicyLabel(String? value) {
    if (value == null || value.trim().isEmpty) return null;

    return value
        .trim()
        .replaceAll('-', '_')
        .split('_')
        .where((word) => word.isNotEmpty)
        .map(
          (word) => word.length == 1
              ? word.toUpperCase()
              : '${word[0].toUpperCase()}${word.substring(1)}',
        )
        .join(' ');
  }
}
