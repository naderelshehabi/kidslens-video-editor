import 'package:freezed_annotation/freezed_annotation.dart';

import 'converters.dart';

part 'edit_action.freezed.dart';
part 'edit_action.g.dart';

/// Types of edit actions that can be applied
@JsonEnum()
enum EditActionType {
  @JsonValue('mute')
  mute, // Mute audio segment
  @JsonValue('beep')
  beep, // Replace with beep sound
  @JsonValue('blur')
  blur, // Blur video region
  @JsonValue('cut')
  cut, // Cut the segment entirely
  @JsonValue('skip')
  skip, // Skip during playback
}

/// Represents an edit action applied to a media file
@freezed
class EditAction with _$EditAction {
  const EditAction._();

  const factory EditAction({
    /// Unique identifier for this edit action
    required String id,

    /// ID of the media file this action applies to
    required String mediaId,

    /// ID of the detection this action was created from (if any)
    String? detectionId,

    /// Type of edit action
    required EditActionType type,

    /// Start time in the media
    @DurationConverter() required Duration startTime,

    /// End time in the media
    @DurationConverter() required Duration endTime,

    /// Whether this action is enabled
    @Default(true) bool enabled,

    /// Blur intensity (0.0 to 1.0) - only for blur actions
    @Default(1.0) double blurIntensity,

    /// Bounding box for blur (null means full frame)
    BoundingBox? boundingBox,

    /// Beep frequency in Hz - only for beep actions
    @Default(1000.0) double beepFrequency,

    /// User notes about this edit
    String? notes,

    /// When this edit was created
    @DateTimeConverter() DateTime? createdAt,
  }) = _EditAction;

  factory EditAction.fromJson(Map<String, dynamic> json) =>
      _$EditActionFromJson(json);

  /// Create a mute action
  factory EditAction.mute({
    required String id,
    required String mediaId,
    required Duration startTime,
    required Duration endTime,
    String? detectionId,
    String? notes,
  }) {
    return EditAction(
      id: id,
      mediaId: mediaId,
      detectionId: detectionId,
      type: EditActionType.mute,
      startTime: startTime,
      endTime: endTime,
      notes: notes,
      createdAt: DateTime.now(),
    );
  }

  /// Create a beep action
  factory EditAction.beep({
    required String id,
    required String mediaId,
    required Duration startTime,
    required Duration endTime,
    String? detectionId,
    double frequency = 1000.0,
    String? notes,
  }) {
    return EditAction(
      id: id,
      mediaId: mediaId,
      detectionId: detectionId,
      type: EditActionType.beep,
      startTime: startTime,
      endTime: endTime,
      beepFrequency: frequency,
      notes: notes,
      createdAt: DateTime.now(),
    );
  }

  /// Create a blur action
  factory EditAction.blur({
    required String id,
    required String mediaId,
    required Duration startTime,
    required Duration endTime,
    String? detectionId,
    BoundingBox? boundingBox,
    double intensity = 1.0,
    String? notes,
  }) {
    return EditAction(
      id: id,
      mediaId: mediaId,
      detectionId: detectionId,
      type: EditActionType.blur,
      startTime: startTime,
      endTime: endTime,
      boundingBox: boundingBox,
      blurIntensity: intensity,
      notes: notes,
      createdAt: DateTime.now(),
    );
  }

  /// Create a cut action
  factory EditAction.cut({
    required String id,
    required String mediaId,
    required Duration startTime,
    required Duration endTime,
    String? detectionId,
    String? notes,
  }) {
    return EditAction(
      id: id,
      mediaId: mediaId,
      detectionId: detectionId,
      type: EditActionType.cut,
      startTime: startTime,
      endTime: endTime,
      notes: notes,
      createdAt: DateTime.now(),
    );
  }

  /// Duration of this edit action
  Duration get duration => endTime - startTime;

  /// Display label for the action type
  String get typeLabel {
    switch (type) {
      case EditActionType.mute:
        return 'Mute';
      case EditActionType.beep:
        return 'Beep';
      case EditActionType.blur:
        return 'Blur';
      case EditActionType.cut:
        return 'Cut';
      case EditActionType.skip:
        return 'Skip';
    }
  }

  /// Icon name for the action type
  String get typeIcon {
    switch (type) {
      case EditActionType.mute:
        return 'volume_off';
      case EditActionType.beep:
        return 'notifications_active';
      case EditActionType.blur:
        return 'blur_on';
      case EditActionType.cut:
        return 'content_cut';
      case EditActionType.skip:
        return 'skip_next';
    }
  }

  /// Whether this action affects audio
  bool get affectsAudio =>
      type == EditActionType.mute || type == EditActionType.beep;

  /// Whether this action affects video
  bool get affectsVideo =>
      type == EditActionType.blur || type == EditActionType.cut;

  /// Checks if this action overlaps with a time range
  bool overlapsWithRange(Duration start, Duration end) {
    return startTime < end && endTime > start;
  }

  /// Checks if a timestamp falls within this action
  bool containsTime(Duration time) {
    return time >= startTime && time < endTime;
  }
}

/// Bounding box for blur regions (reuse from detection or define here)
@freezed
class BoundingBox with _$BoundingBox {
  const factory BoundingBox({
    /// Left edge (0-1 normalized)
    required double left,
    /// Top edge (0-1 normalized)
    required double top,
    /// Width (0-1 normalized)
    required double width,
    /// Height (0-1 normalized)
    required double height,
  }) = _BoundingBox;

  factory BoundingBox.fromJson(Map<String, dynamic> json) =>
      _$BoundingBoxFromJson(json);
}
