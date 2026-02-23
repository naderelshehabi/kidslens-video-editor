import 'package:kidslens_video_editor/data/models/content_category_defaults.dart';

/// Migrates analysis settings JSON to schema v4.
class AnalysisSettingsMigration {
  AnalysisSettingsMigration._();

  static bool needsMigration(Map<String, dynamic> json) {
    final config = json['contentDetectionConfig'] as Map<String, dynamic>?;
    if (config == null) return true;
    final version = config['schemaVersion'] as int?;
    return version == null || version < 4;
  }

  static Map<String, dynamic> migrateFromV1(Map<String, dynamic> json) {
    final enableProfanity = json['enableProfanity'] as bool? ?? true;
    final profanityJson = ContentCategoryDefaults.profanity.toJson();
    final nsfwJson = ContentCategoryDefaults.nsfw.toJson();
    profanityJson['enabled'] = enableProfanity;

    json['contentDetectionConfig'] = {
      'categories': [nsfwJson, profanityJson],
      'votingConfig': {
        'strategy': 'weightedAverage',
        'minVoters': 1,
        'useAccuracyWeights': true,
      },
      'schemaVersion': 3,
    };

    return json;
  }

  /// Migrates from schema v3 to v4 (GPU selection feature)
  static Map<String, dynamic> migrateToV4(Map<String, dynamic> json) {
    final modelConfig = json['modelConfig'] as Map<String, dynamic>?;
    if (modelConfig == null) return json;

    // Migrate useGpu → asrGpuEnabled & onnxGpuEnabled
    final useGpu = modelConfig['useGpu'] as bool? ?? true;
    modelConfig['asrGpuEnabled'] = useGpu;
    modelConfig['onnxGpuEnabled'] = useGpu;

    // Migrate gpuDeviceIndex → asrGpuDevice
    final gpuDeviceIndex = modelConfig['gpuDeviceIndex'] as int? ?? 0;
    modelConfig['asrGpuDevice'] = gpuDeviceIndex;

    // Set defaults for new fields
    modelConfig['onnxExecutionProvider'] = 'auto';
    modelConfig['onnxGpuDevice'] = null;

    // Update schema version
    final config = json['contentDetectionConfig'] as Map<String, dynamic>?;
    if (config != null) {
      config['schemaVersion'] = 4;
    }

    return json;
  }

  static Map<String, dynamic> migrateToLatest(Map<String, dynamic> json) {
    if (!needsMigration(json)) return json;

    // First migrate from v1 if needed
    var migrated = json;
    final config = json['contentDetectionConfig'] as Map<String, dynamic>?;
    final currentVersion = config?['schemaVersion'] as int?;

    if (currentVersion == null || currentVersion < 3) {
      migrated = migrateFromV1(json);
    }

    // Ensure categories exist
    final migratedConfig =
        migrated['contentDetectionConfig'] as Map<String, dynamic>? ?? {};
    final categories =
        (migratedConfig['categories'] as List<dynamic>? ?? <dynamic>[]).toList();

    final hasNsfw = categories.any(
      (c) => c is Map<String, dynamic> && c['id'] == 'nsfw',
    );
    if (!hasNsfw) {
      categories.insert(0, ContentCategoryDefaults.nsfw.toJson());
    }

    final hasProfanity = categories.any(
      (c) => c is Map<String, dynamic> && c['id'] == 'profanity',
    );
    if (!hasProfanity) {
      categories.add(ContentCategoryDefaults.profanity.toJson());
    }

    migratedConfig['categories'] = categories;
    migrated['contentDetectionConfig'] = migratedConfig;

    // Migrate to v4 (GPU selection)
    migrated = migrateToV4(migrated);

    return migrated;
  }
}
