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
  static const Set<String> supportedCategoryIds = {'nsfw', 'profanity'};

  /// All built-in categories.
  static List<ContentCategory> get allCategories => [
        ...visualCategories,
        ...audioCategories,
      ];

  /// Visual detection categories.
  static final List<ContentCategory> visualCategories = [
    nsfw,
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
      final normalizedModels = existing.modelContributions.isEmpty
          ? defaultCategory.modelContributions
          : existing.modelContributions;

      return defaultCategory.copyWith(
        enabled: existing.enabled,
        threshold: normalizedThreshold,
        action: normalizedAction,
        modelContributions: normalizedModels,
      );
    }).toList(growable: false);
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
    description: 'Sexual content classifier using porn/hentai/sexy signals',
    type: CategoryType.visual,
    action: RemediationAction.blurFullFrame,
    iconName: 'no_adult_content',
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
