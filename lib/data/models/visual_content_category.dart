import 'package:freezed_annotation/freezed_annotation.dart';

part 'visual_content_category.freezed.dart';
part 'visual_content_category.g.dart';

/// Action to take when visual content is detected
@JsonEnum()
enum VisualContentAction {
  @JsonValue('blurRegion')
  blurRegion,
  @JsonValue('pixelateRegion')
  pixelateRegion,
  @JsonValue('blackBoxRegion')
  blackBoxRegion,
  @JsonValue('cutScene')
  cutScene,
}

/// Source of detection for a visual content category
@JsonEnum()
enum CategoryDetectionSource {
  /// NudeNet bounding box detection (region blur possible)
  @JsonValue('nudeNet')
  nudeNet,

  /// CLIP whole-frame classification (no bounding boxes)
  @JsonValue('clip')
  clip,

  /// Both NudeNet and CLIP (logical AND: CLIP confirms scene, NudeNet localizes)
  @JsonValue('both')
  both,
}

/// A configurable visual content detection category
@freezed
class VisualContentCategory with _$VisualContentCategory {
  const factory VisualContentCategory({
    /// Unique identifier for the category
    required String id,

    /// Human-readable category name
    required String name,

    /// Description of what this category detects
    required String description,

    /// Detection source (nudeNet, clip, or both)
    @JsonKey(unknownEnumValue: CategoryDetectionSource.clip)
    required CategoryDetectionSource detectionSource,

    /// NudeNet class labels for detection (empty for CLIP-only categories)
    @Default([]) List<String> detectionLabels,

    /// CLIP positive prompts for zero-shot classification
    @Default([]) List<String> clipPrompts,

    /// CLIP negative prompts for discriminative scoring
    @Default([]) List<String> clipNegativePrompts,

    /// Whether this category is enabled
    @Default(true) bool enabled,

    /// Threshold for NudeNet detection (confidence 0-1)
    @Default(0.5) double threshold,

    /// Threshold for CLIP temperature-scaled discriminative score
    @Default(3.0) double clipThreshold,

    /// Action to take when content is detected
    @JsonKey(unknownEnumValue: VisualContentAction.blurRegion)
    @Default(VisualContentAction.blurRegion)
    VisualContentAction action,

    /// Optional icon name for UI display
    String? iconName,

    /// Whether this is a built-in category (vs user-created custom)
    @Default(true) bool isBuiltIn,
  }) = _VisualContentCategory;

  const VisualContentCategory._();

  factory VisualContentCategory.fromJson(Map<String, dynamic> json) =>
      _$VisualContentCategoryFromJson(json);

  /// Whether this category uses NudeNet detection
  bool get usesNudeNet =>
      detectionSource == CategoryDetectionSource.nudeNet ||
      detectionSource == CategoryDetectionSource.both;

  /// Whether this category uses CLIP classification
  bool get usesClip =>
      detectionSource == CategoryDetectionSource.clip ||
      detectionSource == CategoryDetectionSource.both;

  /// Whether this category can provide bounding boxes
  bool get hasBoundingBoxes => usesNudeNet;

  /// Whether blur/pixelate applies to full frame (CLIP-only, no bounding boxes)
  bool get isFullFrameEffect =>
      detectionSource == CategoryDetectionSource.clip &&
      action != VisualContentAction.cutScene;
}
