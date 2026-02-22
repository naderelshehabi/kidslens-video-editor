import 'package:flutter_test/flutter_test.dart';
import 'package:kidslens_video_editor/data/models/analysis_settings_migration.dart';

void main() {
  test('migration builds v2 contentDetectionConfig with profanity category', () {
    final legacy = <String, dynamic>{
      'enableProfanity': true,
      'analysisSettings': <String, dynamic>{},
    };

    final migrated = AnalysisSettingsMigration.migrateFromV1(legacy);
    final config = migrated['contentDetectionConfig'] as Map<String, dynamic>;

    expect(config['schemaVersion'], 2);
    final categories = config['categories'] as List<dynamic>;
    expect(categories.length, 1);
    expect((categories.first as Map<String, dynamic>)['id'], 'profanity');
  });
}
