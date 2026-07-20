import 'package:kidslens_video_editor/data/models/content_category.dart';
import 'package:kidslens_video_editor/data/models/huggingface_model.dart';

/// Default built-in content categories for the analysis pipeline.
///
/// Each category defines sensible model contributions, thresholds, and
/// remediation actions. Users can toggle individual models on/off and
/// adjust thresholds via the Content Detection settings tab.
class ContentCategoryDefaults {
  ContentCategoryDefaults._();

  static const String _modestyParserModelId = 'modesty-parser-birefnet-clothes';
  static const String _legacyNudeNet640CommunityModelId =
      'nsfw-nudenet-detector-640-community';
  static const String _canonicalNudeNet640ModelId = 'nsfw-nudenet-detector-640';

  /// Supported built-in category IDs.
  static const Set<String> supportedCategoryIds = {
    'nsfw',
    'nudity',
    'female_chest_exposure',
    'female_abdomen_exposure',
    'female_arms_exposure',
    'female_legs_exposure',
    'male_buttocks_exposure',
    'male_genitals_exposure',
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
    femaleChestExposure,
    femaleAbdomenExposure,
    femaleArmsExposure,
    femaleLegsExposure,
    maleButtocksExposure,
    maleGenitalsExposure,
  ];

  /// Modesty policy categories.
  static final List<ContentCategory> modestyCategories = [
    femaleChestExposure,
    femaleAbdomenExposure,
    femaleArmsExposure,
    femaleLegsExposure,
    maleButtocksExposure,
    maleGenitalsExposure,
  ];

  /// Audio detection categories.
  static final List<ContentCategory> audioCategories = [
    profanity,
  ];

  /// Whether a category ID is supported by the current analysis pipeline.
  static bool isSupportedCategoryId(String id) =>
      supportedCategoryIds.contains(id);

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

      final normalizedThreshold = existing.threshold.clamp(0.0, 1.0);
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

    final canonicalDefaults = defaultContributions
        .map(_canonicalizeContribution)
        .toList(growable: false);
    final defaultsById = <String, ModelContribution>{
      for (final contribution in canonicalDefaults)
        contribution.modelId: contribution,
    };
    final normalizedExisting = <String, ModelContribution>{};

    for (final contribution in existingContributions) {
      final canonical = _canonicalizeContribution(
        contribution,
        defaultContribution:
            defaultsById[_normalizeLegacyModelId(contribution.modelId)],
      );
      final previous = normalizedExisting[canonical.modelId];
      normalizedExisting[canonical.modelId] = previous == null
          ? canonical
          : _mergeDuplicateContribution(previous, canonical);
    }

    final merged = <ModelContribution>[];
    for (final contribution in canonicalDefaults) {
      merged
          .add(normalizedExisting.remove(contribution.modelId) ?? contribution);
    }
    merged.addAll(normalizedExisting.values);
    return merged;
  }

  static ModelContribution _canonicalizeContribution(
    ModelContribution contribution, {
    ModelContribution? defaultContribution,
  }) {
    final normalizedId = _normalizeLegacyModelId(contribution.modelId);
    final base = defaultContribution;
    if (base == null) {
      return contribution.copyWith(modelId: normalizedId);
    }

    return base.copyWith(
      enabled: contribution.enabled,
      weightOverride: contribution.weightOverride,
      detectionLabels: contribution.detectionLabels.isNotEmpty
          ? contribution.detectionLabels
          : base.detectionLabels,
      clipPrompts: contribution.clipPrompts.isNotEmpty
          ? contribution.clipPrompts
          : base.clipPrompts,
      clipNegativePrompts: contribution.clipNegativePrompts.isNotEmpty
          ? contribution.clipNegativePrompts
          : base.clipNegativePrompts,
    );
  }

  static ModelContribution _mergeDuplicateContribution(
    ModelContribution first,
    ModelContribution second,
  ) =>
      first.copyWith(
        enabled: first.enabled || second.enabled,
        weightOverride: second.weightOverride ?? first.weightOverride,
        detectionLabels: <String>{
          ...first.detectionLabels,
          ...second.detectionLabels,
        }.toList(growable: false),
        clipPrompts: <String>{
          ...first.clipPrompts,
          ...second.clipPrompts,
        }.toList(growable: false),
        clipNegativePrompts: <String>{
          ...first.clipNegativePrompts,
          ...second.clipNegativePrompts,
        }.toList(growable: false),
      );

  static String _normalizeLegacyModelId(String modelId) {
    if (modelId == _legacyNudeNet640CommunityModelId) {
      return _canonicalNudeNet640ModelId;
    }
    return modelId;
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

  static const femaleChestExposure = ContentCategory(
    id: 'female_chest_exposure',
    name: 'Female Chest Exposure',
    description:
        'Detects exposed female chest / breasts for modest-clothes policy enforcement',
    type: CategoryType.visual,
    threshold: 0.35,
    action: RemediationAction.blurRegion,
    enabled: false,
    iconName: 'female',
    supportsRegions: true,
    modelContributions: [
      ModelContribution(
        modelId: 'nsfw-nudenet-detector-640',
        displayName: 'NudeNet Detector 640m',
        modelType: HuggingFaceModelType.nsfw,
        detectionLabels: ['FEMALE_BREAST_EXPOSED'],
      ),
      ModelContribution(
        modelId: 'nsfw-nudenet-detector-320',
        displayName: 'NudeNet Detector 320n (Fast)',
        modelType: HuggingFaceModelType.nsfw,
        enabled: false,
        detectionLabels: ['FEMALE_BREAST_EXPOSED'],
      ),
    ],
  );

  static const femaleAbdomenExposure = ContentCategory(
    id: 'female_abdomen_exposure',
    name: 'Female Abdomen Exposure',
    description:
        'Detects exposed female abdomen / belly for modest-clothes policy enforcement',
    type: CategoryType.visual,
    threshold: 0.35,
    action: RemediationAction.blurRegion,
    enabled: false,
    iconName: 'self_improvement',
    supportsRegions: true,
    modelContributions: [
      ModelContribution(
        modelId: 'nsfw-nudenet-detector-640',
        displayName: 'NudeNet Detector 640m',
        modelType: HuggingFaceModelType.nsfw,
        detectionLabels: ['BELLY_EXPOSED'],
      ),
      ModelContribution(
        modelId: 'nsfw-nudenet-detector-320',
        displayName: 'NudeNet Detector 320n (Fast)',
        modelType: HuggingFaceModelType.nsfw,
        enabled: false,
        detectionLabels: ['BELLY_EXPOSED'],
      ),
    ],
  );

  static const femaleArmsExposure = ContentCategory(
    id: 'female_arms_exposure',
    name: 'Female Arms Exposure',
    description:
        'Conservative parser-backed rule for exposed female arms in modest-clothes policy enforcement',
    type: CategoryType.visual,
    threshold: 0.45,
    action: RemediationAction.blurRegion,
    enabled: false,
    iconName: 'front_hand',
    supportsRegions: true,
    modelContributions: [
      ModelContribution(
        modelId: _modestyParserModelId,
        displayName: 'BiRefNet Person Silhouette Parser',
        modelType: HuggingFaceModelType.parser,
        enabled: false,
      ),
    ],
  );

  static const femaleLegsExposure = ContentCategory(
    id: 'female_legs_exposure',
    name: 'Female Legs Exposure',
    description:
        'Conservative parser-backed rule for exposed female legs in modest-clothes policy enforcement',
    type: CategoryType.visual,
    threshold: 0.45,
    action: RemediationAction.blurRegion,
    enabled: false,
    iconName: 'directions_walk',
    supportsRegions: true,
    modelContributions: [
      ModelContribution(
        modelId: _modestyParserModelId,
        displayName: 'BiRefNet Person Silhouette Parser',
        modelType: HuggingFaceModelType.parser,
        enabled: false,
      ),
    ],
  );

  static const maleButtocksExposure = ContentCategory(
    id: 'male_buttocks_exposure',
    name: 'Male Buttocks Exposure',
    description:
        'Detects exposed male buttocks / anus for modest-clothes policy enforcement',
    type: CategoryType.visual,
    threshold: 0.35,
    action: RemediationAction.blurRegion,
    enabled: false,
    iconName: 'man',
    supportsRegions: true,
    modelContributions: [
      ModelContribution(
        modelId: 'nsfw-nudenet-detector-640',
        displayName: 'NudeNet Detector 640m',
        modelType: HuggingFaceModelType.nsfw,
        detectionLabels: ['BUTTOCKS_EXPOSED', 'ANUS_EXPOSED'],
      ),
      ModelContribution(
        modelId: 'nsfw-nudenet-detector-320',
        displayName: 'NudeNet Detector 320n (Fast)',
        modelType: HuggingFaceModelType.nsfw,
        enabled: false,
        detectionLabels: ['BUTTOCKS_EXPOSED', 'ANUS_EXPOSED'],
      ),
    ],
  );

  static const maleGenitalsExposure = ContentCategory(
    id: 'male_genitals_exposure',
    name: 'Male Genitals Exposure',
    description:
        'Detects exposed male genitals for modest-clothes policy enforcement',
    type: CategoryType.visual,
    threshold: 0.35,
    action: RemediationAction.blurRegion,
    enabled: false,
    iconName: 'man',
    supportsRegions: true,
    modelContributions: [
      ModelContribution(
        modelId: 'nsfw-nudenet-detector-640',
        displayName: 'NudeNet Detector 640m',
        modelType: HuggingFaceModelType.nsfw,
        detectionLabels: ['MALE_GENITALIA_EXPOSED'],
      ),
      ModelContribution(
        modelId: 'nsfw-nudenet-detector-320',
        displayName: 'NudeNet Detector 320n (Fast)',
        modelType: HuggingFaceModelType.nsfw,
        enabled: false,
        detectionLabels: ['MALE_GENITALIA_EXPOSED'],
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
