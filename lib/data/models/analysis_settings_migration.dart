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

    // Consolidate to single GPU fields
    // Priority: asrGpuEnabled > useGpu
    final useGpu = (modelConfig['asrGpuEnabled'] as bool?) ?? 
                   (modelConfig['useGpu'] as bool?) ?? 
                   true;
    modelConfig['useGpu'] = useGpu;

    // Priority: asrGpuDevice > gpuDeviceIndex
    final gpuDeviceIndex = (modelConfig['asrGpuDevice'] as int?) ?? 
                          (modelConfig['gpuDeviceIndex'] as int?) ?? 
                          0;
    modelConfig['gpuDeviceIndex'] = gpuDeviceIndex;

    // Set default for execution provider if not present
    if (!modelConfig.containsKey('onnxExecutionProvider')) {
      modelConfig['onnxExecutionProvider'] = 'auto';
    }

    // Remove old dual-selector fields
    modelConfig.remove('asrGpuEnabled');
    modelConfig.remove('asrGpuDevice');
    modelConfig.remove('onnxGpuEnabled');
    modelConfig.remove('onnxGpuDevice');

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
