import 'package:kidslens_video_editor/data/models/content_category.dart';
import 'package:kidslens_video_editor/data/models/huggingface_model.dart';

/// Default built-in content categories for the analysis pipeline.
///
/// Each category defines sensible model contributions, thresholds, and
/// remediation actions. Users can toggle individual models on/off and
/// adjust thresholds via the Content Detection settings tab.
class ContentCategoryDefaults {
  ContentCategoryDefaults._();

  /// Supported built-in category IDs.
  static const Set<String> supportedCategoryIds = {
    'nsfw',
    'nudity',
    'profanity',
  };

  /// All built-in categories.
  static List<ContentCategory> get allCategories => [
        ...visualCategories,
        ...audioCategories,
      ];

  /// Visual detection categories.
  static final List<ContentCategory> visualCategories = [
    nsfw,
    nudity,
  ];

  /// Audio detection categories.
  static final List<ContentCategory> audioCategories = [
    profanity,
  ];

  /// Whether a category ID is supported by the current analysis pipeline.
  static bool isSupportedCategoryId(String id) => supportedCategoryIds.contains(id);

  /// Normalize any category list to only supported built-ins while preserving
  /// user-configurable values (enabled, threshold, action, model toggles).
  static List<ContentCategory> normalizeCategories(
    Iterable<ContentCategory> categories,
  ) {
    final existingById = <String, ContentCategory>{};
    for (final category in categories) {
      if (isSupportedCategoryId(category.id)) {
        existingById[category.id] = category;
      }
    }

    return allCategories.map((defaultCategory) {
      final existing = existingById[defaultCategory.id];
      if (existing == null) {
        return defaultCategory;
      }

      final normalizedThreshold =
          existing.threshold.clamp(0.0, 1.0).toDouble();
      final normalizedAction = _normalizeActionForType(
        defaultCategory.type,
        existing.action,
      );
      final normalizedModels = _mergeModelContributions(
        defaultContributions: defaultCategory.modelContributions,
        existingContributions: existing.modelContributions,
      );

      return defaultCategory.copyWith(
        enabled: existing.enabled,
        threshold: normalizedThreshold,
        action: normalizedAction,
        modelContributions: normalizedModels,
      );
    }).toList(growable: false);
  }

  static List<ModelContribution> _mergeModelContributions({
    required List<ModelContribution> defaultContributions,
    required List<ModelContribution> existingContributions,
  }) {
    if (existingContributions.isEmpty) {
      return defaultContributions;
    }

    final merged = List<ModelContribution>.from(existingContributions);
    final existingModelIds = existingContributions
        .map((contribution) => contribution.modelId)
        .toSet();

    for (final contribution in defaultContributions) {
      if (existingModelIds.contains(contribution.modelId)) {
        continue;
      }
      merged.add(contribution);
    }

    return merged;
  }

  static RemediationAction _normalizeActionForType(
    CategoryType type,
    RemediationAction action,
  ) {
    if (type == CategoryType.visual) {
      return action.isVisual ? action : nsfw.action;
    }
    return action.isAudio ? action : profanity.action;
  }

  /// NSFW visual category using canonical nsfw_model semantics.
  static const nsfw = ContentCategory(
    id: 'nsfw',
    name: 'NSFW',
    description: 'Whole-frame sexual-content classifier (porn/hentai/sexy)',
    type: CategoryType.visual,
    action: RemediationAction.blurFullFrame,
    iconName: 'no_adult_content',
    supportsRegions: false,
    modelContributions: [
      ModelContribution(
        modelId: 'nsfw-onnx-community-vit-224',
        displayName: 'ONNX Community NSFW ViT (FP16)',
        modelType: HuggingFaceModelType.nsfw,
      ),
      ModelContribution(
        modelId: 'nsfw-onnx-community-vit-224-int8',
        displayName: 'ONNX Community NSFW ViT (INT8)',
        modelType: HuggingFaceModelType.nsfw,
        enabled: false,
      ),
    ],
  );

  /// Nudity region detection via NudeNet detector outputs.
  static const nudity = ContentCategory(
    id: 'nudity',
    name: 'Nudity',
    description: 'Region-level nudity detector for localized moderation',
    type: CategoryType.visual,
    threshold: 0.35,
    action: RemediationAction.blurRegion,
    iconName: 'visibility_off',
    supportsRegions: true,
    modelContributions: [
      ModelContribution(
        modelId: 'nsfw-nudenet-detector-640',
        displayName: 'NudeNet Detector 640m',
        modelType: HuggingFaceModelType.nsfw,
        detectionLabels: [
          'FEMALE_BREAST_EXPOSED',
          'FEMALE_GENITALIA_EXPOSED',
          'MALE_GENITALIA_EXPOSED',
          'ANUS_EXPOSED',
          'BUTTOCKS_EXPOSED',
        ],
      ),
      ModelContribution(
        modelId: 'nsfw-nudenet-detector-640-community',
        displayName: 'NudeNet Detector 640m (Community)',
        modelType: HuggingFaceModelType.nsfw,
        enabled: false,
        detectionLabels: [
          'FEMALE_BREAST_EXPOSED',
          'FEMALE_GENITALIA_EXPOSED',
          'MALE_GENITALIA_EXPOSED',
          'ANUS_EXPOSED',
          'BUTTOCKS_EXPOSED',
        ],
      ),
      ModelContribution(
        modelId: 'nsfw-nudenet-detector-320',
        displayName: 'NudeNet Detector 320n (Fast)',
        modelType: HuggingFaceModelType.nsfw,
        enabled: false,
        detectionLabels: [
          'FEMALE_BREAST_EXPOSED',
          'FEMALE_GENITALIA_EXPOSED',
          'MALE_GENITALIA_EXPOSED',
          'ANUS_EXPOSED',
          'BUTTOCKS_EXPOSED',
        ],
      ),
    ],
  );

  /// Profanity — swear words and offensive language in the audio track.
  static const profanity = ContentCategory(
    id: 'profanity',
    name: 'Profanity',
    description: 'Swear words and offensive language',
    type: CategoryType.audio,
    threshold: 0.8,
    action: RemediationAction.beep,
    iconName: 'volume_off',
    modelContributions: [
      ModelContribution(
        modelId: 'whisper-small',
        displayName: 'Whisper Transcription + Word Match',
        modelType: HuggingFaceModelType.asr,
      ),
    ],
  );
}
