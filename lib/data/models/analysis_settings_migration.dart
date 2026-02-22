import 'package:kidslens_video_editor/data/models/content_category_defaults.dart';

/// Migrates analysis settings JSON to schema v2.
///
/// The ASR-only pipeline retains audio categories and drops legacy visual
/// categories/models during migration.
class AnalysisSettingsMigration {
  AnalysisSettingsMigration._();

  static bool needsMigration(Map<String, dynamic> json) {
    final config = json['contentDetectionConfig'] as Map<String, dynamic>?;
    if (config == null) return true;
    final version = config['schemaVersion'] as int?;
    return version == null || version < 2;
  }

  static Map<String, dynamic> migrateFromV1(Map<String, dynamic> json) {
    final enableProfanity = json['enableProfanity'] as bool? ?? true;
    final profanityJson = ContentCategoryDefaults.profanity.toJson();
    profanityJson['enabled'] = enableProfanity;

    json['contentDetectionConfig'] = {
      'categories': [profanityJson],
      'votingConfig': {
        'strategy': 'weightedAverage',
        'minVoters': 1,
        'useAccuracyWeights': true,
      },
      'schemaVersion': 2,
    };

    return json;
  }
}
