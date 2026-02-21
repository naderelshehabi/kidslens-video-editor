import 'package:kidslens_video_editor/data/models/content_category.dart';
import 'package:kidslens_video_editor/data/models/content_category_defaults.dart';
import 'package:kidslens_video_editor/data/models/huggingface_model.dart';
import 'package:kidslens_video_editor/data/models/visual_content_category.dart';

/// Migrates analysis settings JSON from V1 (legacy flat fields) to V2
/// (unified [ContentDetectionConfig] with [ContentCategory] objects).
///
/// V1 format used separate `enableNsfw`, `nsfwThreshold`, `enableViolence`, etc.
/// fields plus a `visualContentConfig` with `VisualContentCategory` objects.
///
/// V2 format uses a single `contentDetectionConfig` with a list of
/// [ContentCategory] objects, each with their own threshold, remediation
/// action, and model contributions.
class AnalysisSettingsMigration {
  AnalysisSettingsMigration._();

  /// Detects whether the given JSON needs migration.
  static bool needsMigration(Map<String, dynamic> json) {
    final config = json['contentDetectionConfig'] as Map<String, dynamic>?;
    if (config == null) return true;
    final version = config['schemaVersion'] as int?;
    return version == null || version < 2;
  }

  /// Migrates V1 JSON to V2 format in-place and returns the modified map.
  ///
  /// The migration:
  /// 1. Reads legacy enable/threshold flags per type
  /// 2. Reads `visualContentConfig.categories` for VisualContentCategory data
  /// 3. Merges them into `ContentCategory` objects with `ModelContribution`s
  /// 4. Writes the result as `contentDetectionConfig`
  static Map<String, dynamic> migrateFromV1(Map<String, dynamic> json) {
    // --- Migrate legacy per-type flags to content categories ---
    final categories = <Map<String, dynamic>>[
      _migrateLegacyCategory(
        json: json,
        defaults: ContentCategoryDefaults.nsfw,
        enableKey: 'enableNsfw',
        thresholdKey: 'nsfwThreshold',
      ),
      _migrateLegacyCategory(
        json: json,
        defaults: ContentCategoryDefaults.violence,
        enableKey: 'enableViolence',
        thresholdKey: 'violenceThreshold',
      ),
      _migrateLegacyCategory(
        json: json,
        defaults: ContentCategoryDefaults.blood,
        enableKey: 'enableBlood',
        thresholdKey: 'bloodThreshold',
      ),
      _migrateLegacyCategory(
        json: json,
        defaults: ContentCategoryDefaults.weapons,
        enableKey: 'enableWeapons',
        thresholdKey: 'weaponsThreshold',
      ),
    ];

    // --- Migrate VisualContentConfig categories ---
    final vccJson =
        json['visualContentConfig'] as Map<String, dynamic>? ?? {};
    final vccCategories = vccJson['categories'] as List<dynamic>? ?? [];

    final migratedVisualIds = <String>{};
    for (final catJson in vccCategories) {
      if (catJson is Map<String, dynamic>) {
        final migrated = _migrateVisualContentCategory(catJson);
        if (migrated != null) {
          migratedVisualIds.add(migrated['id'] as String);
          categories.add(migrated);
        }
      }
    }

    // Add default categories that weren't in the old visual content config
    for (final defaultCat in [
      ContentCategoryDefaults.nudity,
      ContentCategoryDefaults.sexualContent,
      ContentCategoryDefaults.kissing,
      ContentCategoryDefaults.immodestDress,
    ]) {
      if (!migratedVisualIds.contains(defaultCat.id)) {
        categories.add(defaultCat.toJson());
      }
    }

    // --- Migrate profanity ---
    final enableProfanity = json['enableProfanity'] as bool? ?? true;
    final profanityJson = ContentCategoryDefaults.profanity.toJson();
    profanityJson['enabled'] = enableProfanity;
    categories.add(profanityJson);

    // --- Build the contentDetectionConfig ---
    final preFilter = vccJson['useNsfwPreFilter'] as bool? ?? true;
    final preFilterThreshold =
        (vccJson['preFilterThreshold'] as num?)?.toDouble() ?? 0.30;

    json['contentDetectionConfig'] = {
      'categories': categories,
      'votingConfig': {
        'strategy': 'weightedAverage',
        'minVoters': 1,
        'useAccuracyWeights': true,
      },
      'useNsfwPreFilter': preFilter,
      'preFilterThreshold': preFilterThreshold,
      'schemaVersion': 2,
    };

    return json;
  }

  /// Migrates a single legacy per-type detection (nsfw, violence, etc.)
  /// to a [ContentCategory] JSON map, using the provided defaults.
  static Map<String, dynamic> _migrateLegacyCategory({
    required Map<String, dynamic> json,
    required ContentCategory defaults,
    required String enableKey,
    required String thresholdKey,
  }) {
    final enabled = json[enableKey] as bool? ?? defaults.enabled;
    final threshold =
        (json[thresholdKey] as num?)?.toDouble() ?? defaults.threshold;

    final catJson = defaults.toJson();
    catJson['enabled'] = enabled;
    catJson['threshold'] = threshold;

    // Try to pick up per-type model ID from legacy ModelConfig
    final modelConfig = json['modelConfig'] as Map<String, dynamic>?;
    if (modelConfig != null) {
      final modelIdKey = _modelIdKeyForCategory(defaults.id);
      final legacyModelId = modelConfig[modelIdKey] as String?;
      if (legacyModelId != null) {
        // Update the first model contribution to use the legacy model ID
        final contributions =
            catJson['modelContributions'] as List<dynamic>? ?? [];
        if (contributions.isNotEmpty) {
          final first = contributions[0] as Map<String, dynamic>;
          first['modelId'] = legacyModelId;
        }
      }
    }

    return catJson;
  }

  /// Maps category ID to the legacy ModelConfig field name.
  static String? _modelIdKeyForCategory(String categoryId) {
    switch (categoryId) {
      case 'nsfw':
        return 'nsfwModelId';
      case 'violence':
        return 'violenceModelId';
      case 'blood':
        return 'bloodModelId';
      case 'weapons':
        return 'weaponsModelId';
      default:
        return null;
    }
  }

  /// Migrates a single V1 [VisualContentCategory] JSON to a
  /// [ContentCategory] JSON map.
  static Map<String, dynamic>? _migrateVisualContentCategory(
    Map<String, dynamic> catJson,
  ) {
    final id = catJson['id'] as String?;
    if (id == null) return null;

    final name = catJson['name'] as String? ?? id;
    final description = catJson['description'] as String? ?? '';
    final enabled = catJson['enabled'] as bool? ?? true;
    final threshold = (catJson['threshold'] as num?)?.toDouble() ?? 0.5;
    final isBuiltIn = catJson['isBuiltIn'] as bool? ?? true;
    final iconName = catJson['iconName'] as String?;
    final detectionLabels =
        (catJson['detectionLabels'] as List<dynamic>?)?.cast<String>() ?? [];
    final clipPrompts =
        (catJson['clipPrompts'] as List<dynamic>?)?.cast<String>() ?? [];
    final clipNegativePrompts =
        (catJson['clipNegativePrompts'] as List<dynamic>?)?.cast<String>() ??
            [];
    final sourceStr = catJson['detectionSource'] as String? ?? 'clip';
    final actionStr = catJson['action'] as String? ?? 'blurRegion';

    // Map VisualContentAction → RemediationAction
    final action = _mapVisualContentAction(actionStr);

    // Build model contributions based on detection source
    final contributions = <Map<String, dynamic>>[];

    if (sourceStr == 'nudeNet' || sourceStr == 'both') {
      contributions.add({
        'modelId': 'nudenet-v3-medium',
        'displayName': 'NudeNet v3 Medium',
        'modelType': HuggingFaceModelType.nudeNet.name,
        'enabled': true,
        'detectionLabels': detectionLabels,
        'clipPrompts': <String>[],
        'clipNegativePrompts': <String>[],
      });
    }

    if (sourceStr == 'clip' || sourceStr == 'both') {
      contributions.add({
        'modelId': 'clip-vit-b32-vision-fp16',
        'displayName': 'CLIP Zero-Shot',
        'modelType': HuggingFaceModelType.clip.name,
        'enabled': true,
        'clipPrompts': clipPrompts,
        'clipNegativePrompts': clipNegativePrompts,
        'detectionLabels': <String>[],
      });
    }

    return {
      'id': id,
      'name': name,
      'description': description,
      'type': CategoryType.visual.name,
      'enabled': enabled,
      'threshold': threshold,
      'action': action,
      'modelContributions': contributions,
      'isBuiltIn': isBuiltIn,
      if (iconName != null) 'iconName': iconName,
      'supportsRegions': sourceStr == 'nudeNet' || sourceStr == 'both',
    };
  }

  /// Maps old [VisualContentAction] string to [RemediationAction] string.
  static String _mapVisualContentAction(String actionStr) {
    switch (actionStr) {
      case 'blurRegion':
        return 'blurRegion';
      case 'pixelateRegion':
        return 'pixelateRegion';
      case 'blackBoxRegion':
        return 'blackBoxRegion';
      case 'cutScene':
        return 'cutScene';
      default:
        return 'blurRegion';
    }
  }
}
