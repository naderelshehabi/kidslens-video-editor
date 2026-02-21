import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:kidslens_video_editor/data/models/huggingface_model.dart';

part 'content_category.freezed.dart';
part 'content_category.g.dart';

/// Whether a content category detects visual or audio content.
@JsonEnum()
enum CategoryType {
  @JsonValue('visual')
  visual,
  @JsonValue('audio')
  audio,
}

/// Action to apply when content is detected in a category.
@JsonEnum()
enum RemediationAction {
  // Visual actions
  @JsonValue('blurRegion')
  blurRegion,
  @JsonValue('pixelateRegion')
  pixelateRegion,
  @JsonValue('blackBoxRegion')
  blackBoxRegion,
  @JsonValue('blurFullFrame')
  blurFullFrame,
  @JsonValue('cutScene')
  cutScene,

  // Audio actions
  @JsonValue('mute')
  mute,
  @JsonValue('beep')
  beep,
}

/// Extension helpers for [RemediationAction].
extension RemediationActionExtension on RemediationAction {
  /// Whether this is a visual remediation action.
  bool get isVisual => switch (this) {
        RemediationAction.blurRegion => true,
        RemediationAction.pixelateRegion => true,
        RemediationAction.blackBoxRegion => true,
        RemediationAction.blurFullFrame => true,
        RemediationAction.cutScene => true,
        RemediationAction.mute => false,
        RemediationAction.beep => false,
      };

  /// Whether this is an audio remediation action.
  bool get isAudio => !isVisual;

  /// Whether this is a region-level (bounding-box) action.
  bool get isRegionLevel => switch (this) {
        RemediationAction.blurRegion => true,
        RemediationAction.pixelateRegion => true,
        RemediationAction.blackBoxRegion => true,
        _ => false,
      };

  /// Human-readable display name.
  String get displayName => switch (this) {
        RemediationAction.blurRegion => 'Blur Region',
        RemediationAction.pixelateRegion => 'Pixelate Region',
        RemediationAction.blackBoxRegion => 'Black Box Region',
        RemediationAction.blurFullFrame => 'Blur Full Frame',
        RemediationAction.cutScene => 'Cut Scene',
        RemediationAction.mute => 'Mute',
        RemediationAction.beep => 'Beep',
      };

  /// Material icon name for the action.
  String get iconName => switch (this) {
        RemediationAction.blurRegion => 'blur_on',
        RemediationAction.pixelateRegion => 'grid_on',
        RemediationAction.blackBoxRegion => 'crop_square',
        RemediationAction.blurFullFrame => 'blur_on',
        RemediationAction.cutScene => 'content_cut',
        RemediationAction.mute => 'volume_off',
        RemediationAction.beep => 'music_note',
      };
}

/// Specifies how a particular AI model contributes to a content category.
///
/// Each [ContentCategory] may have multiple [ModelContribution]s, allowing
/// Mixture-of-Experts voting across models.
@freezed
class ModelContribution with _$ModelContribution {
  const factory ModelContribution({
    /// Model ID from the HuggingFace registry (e.g. 'nsfw-vit-base-quantized').
    required String modelId,

    /// Human-readable model name for the UI.
    required String displayName,

    /// Model type, used for inference routing.
    required HuggingFaceModelType modelType,

    /// Whether this model is enabled for voting in this category.
    @Default(true) bool enabled,

    /// Weight override for voting. When null, the model's accuracy percentage
    /// from the registry is used as its weight.
    double? weightOverride,

    /// NudeNet class labels this contribution maps to (e.g. 'FEMALE_BREAST_EXPOSED').
    @Default([]) List<String> detectionLabels,

    /// CLIP positive prompts for zero-shot classification.
    @Default([]) List<String> clipPrompts,

    /// CLIP negative prompts for discriminative scoring.
    @Default([]) List<String> clipNegativePrompts,
  }) = _ModelContribution;

  const ModelContribution._();

  factory ModelContribution.fromJson(Map<String, dynamic> json) =>
      _$ModelContributionFromJson(json);

  /// Effective weight for voting. Uses [weightOverride] if set, otherwise 1.0.
  /// The actual accuracy-based weight is applied at voting time by the
  /// [VotingService] using the model's registry metadata.
  double get effectiveWeight => weightOverride ?? 1.0;
}

/// A unified content detection category.
///
/// Replaces the old separate detection types (NSFW, violence, etc.) and
/// [VisualContentCategory] with a single model that supports both visual
/// and audio categories, each with configurable model contributions and
/// per-category remediation actions.
@freezed
class ContentCategory with _$ContentCategory {
  const factory ContentCategory({
    /// Unique identifier (e.g. 'nsfw', 'violence', 'profanity').
    required String id,

    /// Human-readable name.
    required String name,

    /// Description of what this category detects.
    required String description,

    /// Whether this category detects visual or audio content.
    required CategoryType type,

    /// Whether this category is enabled for detection.
    @Default(true) bool enabled,

    /// Detection threshold (0.0 to 1.0). The MoE consensus score must meet
    /// or exceed this threshold to trigger a detection.
    @Default(0.5) double threshold,

    /// The action to apply when content in this category is detected.
    required RemediationAction action,

    /// Models that contribute to this category's detection via MoE voting.
    @Default([]) List<ModelContribution> modelContributions,

    /// Whether this is a built-in category (vs user-created custom).
    @Default(true) bool isBuiltIn,

    /// Optional Material icon name for the UI.
    String? iconName,

    /// Whether region-level detection (bounding boxes) is available.
    @Default(false) bool supportsRegions,
  }) = _ContentCategory;

  const ContentCategory._();

  factory ContentCategory.fromJson(Map<String, dynamic> json) =>
      _$ContentCategoryFromJson(json);

  /// Whether at least one contributing model is enabled.
  bool get hasEnabledModels =>
      modelContributions.any((m) => m.enabled);

  /// Enabled model contributions only.
  List<ModelContribution> get enabledModels =>
      modelContributions.where((m) => m.enabled).toList();

  /// Whether this is a visual category.
  bool get isVisual => type == CategoryType.visual;

  /// Whether this is an audio category.
  bool get isAudio => type == CategoryType.audio;

  /// Whether any enabled NudeNet models contribute to this category.
  bool get hasNudeNetModels => modelContributions.any(
        (m) => m.modelType == HuggingFaceModelType.nudeNet && m.enabled,
      );

  /// Whether any enabled CLIP models contribute to this category.
  bool get hasClipModels => modelContributions.any(
        (m) => m.modelType == HuggingFaceModelType.clip && m.enabled,
      );

  /// All unique model IDs required by enabled contributions.
  Set<String> get requiredModelIds =>
      enabledModels.map((m) => m.modelId).toSet();
}
