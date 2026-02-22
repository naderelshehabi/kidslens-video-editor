import 'package:kidslens_video_editor/data/models/content_category_defaults.dart';

/// Migrates analysis settings JSON to schema v3.
class AnalysisSettingsMigration {
  AnalysisSettingsMigration._();

  static bool needsMigration(Map<String, dynamic> json) {
    final config = json['contentDetectionConfig'] as Map<String, dynamic>?;
    if (config == null) return true;
    final version = config['schemaVersion'] as int?;
    return version == null || version < 3;
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

  static Map<String, dynamic> migrateToLatest(Map<String, dynamic> json) {
    if (!needsMigration(json)) return json;

    final migrated = migrateFromV1(json);
    final config =
        migrated['contentDetectionConfig'] as Map<String, dynamic>? ?? {};
    final categories =
        (config['categories'] as List<dynamic>? ?? <dynamic>[]).toList();

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

    config['categories'] = categories;
    config['schemaVersion'] = 3;
    migrated['contentDetectionConfig'] = config;
    return migrated;
  }
}
