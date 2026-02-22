import 'package:flutter_test/flutter_test.dart';
import 'package:kidslens_video_editor/data/models/analysis_settings_migration.dart';

void main() {
  test('migration builds v3 contentDetectionConfig with nsfw + profanity categories', () {
    final legacy = <String, dynamic>{
      'enableProfanity': true,
      'analysisSettings': <String, dynamic>{},
    };

    final migrated = AnalysisSettingsMigration.migrateFromV1(legacy);
    final config = migrated['contentDetectionConfig'] as Map<String, dynamic>;

    expect(config['schemaVersion'], 3);
    final categories = config['categories'] as List<dynamic>;
    expect(categories.length, 2);
    expect((categories.first as Map<String, dynamic>)['id'], 'nsfw');
    expect((categories[1] as Map<String, dynamic>)['id'], 'profanity');
  });
}
