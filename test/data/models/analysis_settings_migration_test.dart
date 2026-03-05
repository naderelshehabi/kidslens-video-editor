import 'package:flutter_test/flutter_test.dart';
import 'package:kidslens_video_editor/data/models/analysis_settings_migration.dart';

void main() {
  test('migration builds v3 contentDetectionConfig with nsfw + nudity + profanity categories', () {
    final legacy = <String, dynamic>{
      'enableProfanity': true,
      'analysisSettings': <String, dynamic>{},
    };

    final migrated = AnalysisSettingsMigration.migrateFromV1(legacy);
    final config = migrated['contentDetectionConfig'] as Map<String, dynamic>;

    expect(config['schemaVersion'], 3);
    final categories = config['categories'] as List<dynamic>;
    expect(categories.length, 3);
    final ids = categories
      .cast<Map<String, dynamic>>()
      .map((c) => c['id'] as String)
      .toSet();
    expect(ids.contains('nsfw'), isTrue);
    expect(ids.contains('nudity'), isTrue);
    expect(ids.contains('profanity'), isTrue);
  });

  group('v4 GPU selection migration', () {
    test('preserves consolidated GPU fields and sets provider default', () {
      final input = <String, dynamic>{
        'modelConfig': <String, dynamic>{
          'asrModelId': 'whisper-small',
          'useGpu': true,
          'gpuDeviceIndex': 0,
        },
        'contentDetectionConfig': <String, dynamic>{
          'schemaVersion': 3,
          'categories': <dynamic>[],
          'votingConfig': <String, dynamic>{},
        },
      };

      final migrated = AnalysisSettingsMigration.migrateToV4(input);
      final modelConfig = migrated['modelConfig'] as Map<String, dynamic>;

      expect(modelConfig['useGpu'], true);
      expect(modelConfig['gpuDeviceIndex'], 0);
      expect(modelConfig['onnxExecutionProvider'], 'auto');
      expect(modelConfig['asrGpuEnabled'], null);
      expect(modelConfig['asrGpuDevice'], null);
      expect(modelConfig['onnxGpuEnabled'], null);
      expect(modelConfig['onnxGpuDevice'], null);
    });

    test('migrates with GPU disabled', () {
      final input = <String, dynamic>{
        'modelConfig': <String, dynamic>{
          'asrModelId': 'whisper-base',
          'useGpu': false,
          'gpuDeviceIndex': 1,
        },
        'contentDetectionConfig': <String, dynamic>{
          'schemaVersion': 3,
          'categories': <dynamic>[],
        },
      };

      final migrated = AnalysisSettingsMigration.migrateToV4(input);
      final modelConfig = migrated['modelConfig'] as Map<String, dynamic>;

      expect(modelConfig['useGpu'], false);
      expect(modelConfig['gpuDeviceIndex'], 1);
    });

    test('updates schema version to 4', () {
      final input = <String, dynamic>{
        'modelConfig': <String, dynamic>{
          'asrModelId': 'whisper-small',
          'useGpu': true,
        },
        'contentDetectionConfig': <String, dynamic>{
          'schemaVersion': 3,
          'categories': <dynamic>[],
        },
      };

      final migrated = AnalysisSettingsMigration.migrateToV4(input);
      final config = migrated['contentDetectionConfig'] as Map<String, dynamic>;

      expect(config['schemaVersion'], 4);
    });

    test('migrateToLatest performs full migration chain', () {
      final v1Input = <String, dynamic>{
        'enableProfanity': true,
        'modelConfig': <String, dynamic>{
          'asrModelId': 'whisper-small',
          'useGpu': true,
          'gpuDeviceIndex': 2,
        },
      };

      final migrated = AnalysisSettingsMigration.migrateToLatest(v1Input);
      
      // Verify v3 migration (categories)
      final config = migrated['contentDetectionConfig'] as Map<String, dynamic>;
      final categories = config['categories'] as List<dynamic>;
      expect(categories.length, greaterThanOrEqualTo(3));
      
      // Verify v4 migration (consolidated GPU selection)
      final modelConfig = migrated['modelConfig'] as Map<String, dynamic>;
      expect(modelConfig['useGpu'], true);
      expect(modelConfig['gpuDeviceIndex'], 2);
      expect(modelConfig['onnxExecutionProvider'], 'auto');
      
      // Verify final schema version
      expect(config['schemaVersion'], 4);
    });

    test('needsMigration returns true for v3 and older', () {
      final v3 = <String, dynamic>{
        'contentDetectionConfig': <String, dynamic>{
          'schemaVersion': 3,
        },
      };
      expect(AnalysisSettingsMigration.needsMigration(v3), true);

      final v2 = <String, dynamic>{
        'contentDetectionConfig': <String, dynamic>{
          'schemaVersion': 2,
        },
      };
      expect(AnalysisSettingsMigration.needsMigration(v2), true);
    });

    test('needsMigration returns false for v4', () {
      final v4 = <String, dynamic>{
        'contentDetectionConfig': <String, dynamic>{
          'schemaVersion': 4,
        },
      };
      expect(AnalysisSettingsMigration.needsMigration(v4), false);
    });
  });
}
