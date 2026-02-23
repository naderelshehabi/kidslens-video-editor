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

  group('v4 GPU selection migration', () {
    test('migrates useGpu to asrGpuEnabled and onnxGpuEnabled', () {
      final input = <String, dynamic>{
        'modelConfig': <String, dynamic>{
          'asrModelId': 'whisper-small',
          'useGpu': true,
          'gpuDeviceIndex': 0,
        },
        'contentDetectionConfig': <String, dynamic>{
          'schemaVersion': 3,
          'categories': [],
          'votingConfig': <String, dynamic>{},
        },
      };

      final migrated = AnalysisSettingsMigration.migrateToV4(input);
      final modelConfig = migrated['modelConfig'] as Map<String, dynamic>;

      expect(modelConfig['asrGpuEnabled'], true);
      expect(modelConfig['onnxGpuEnabled'], true);
      expect(modelConfig['asrGpuDevice'], 0);
      expect(modelConfig['onnxExecutionProvider'], 'auto');
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
          'categories': [],
        },
      };

      final migrated = AnalysisSettingsMigration.migrateToV4(input);
      final modelConfig = migrated['modelConfig'] as Map<String, dynamic>;

      expect(modelConfig['asrGpuEnabled'], false);
      expect(modelConfig['onnxGpuEnabled'], false);
      expect(modelConfig['asrGpuDevice'], 1);
    });

    test('updates schema version to 4', () {
      final input = <String, dynamic>{
        'modelConfig': <String, dynamic>{
          'asrModelId': 'whisper-small',
          'useGpu': true,
        },
        'contentDetectionConfig': <String, dynamic>{
          'schemaVersion': 3,
          'categories': [],
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
      expect(categories.length, greaterThanOrEqualTo(2));
      
      // Verify v4 migration (GPU selection)
      final modelConfig = migrated['modelConfig'] as Map<String, dynamic>;
      expect(modelConfig['asrGpuEnabled'], true);
      expect(modelConfig['onnxGpuEnabled'], true);
      expect(modelConfig['asrGpuDevice'], 2);
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
