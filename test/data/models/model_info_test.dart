import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:kidslens_video_editor/data/models/model_info.dart';

void main() {
  group('ModelType enum', () {
    test('should have all expected values', () {
      expect(ModelType.values, hasLength(2));
      expect(ModelType.values, contains(ModelType.asr));
      expect(ModelType.values, contains(ModelType.visual));
    });

    test('should have correct JSON values', () {
      expect(ModelType.asr.name, equals('asr'));
      expect(ModelType.visual.name, equals('visual'));
    });
  });

  group('HardwareInfo', () {
    group('creation', () {
      test('should create with required fields', () {
        const info = HardwareInfo(
          availableRamBytes: 8 * 1024 * 1024 * 1024, // 8 GB
        );

        expect(info.availableRamBytes, equals(8 * 1024 * 1024 * 1024));
        expect(info.availableVramBytes, equals(0));
        expect(info.hasGpu, isFalse);
        expect(info.cpuCores, equals(4));
        expect(info.supportsAvx2, isFalse);
        expect(info.supportsCuda, isFalse);
        expect(info.supportsMetal, isFalse);
      });

      test('should create with all optional fields', () {
        const info = HardwareInfo(
          availableRamBytes: 16 * 1024 * 1024 * 1024,
          availableVramBytes: 8 * 1024 * 1024 * 1024,
          hasGpu: true,
          gpuName: 'NVIDIA RTX 3080',
          cpuCores: 8,
          supportsAvx2: true,
          supportsCuda: true,
          operatingSystem: 'Windows 11',
        );

        expect(info.availableVramBytes, equals(8 * 1024 * 1024 * 1024));
        expect(info.hasGpu, isTrue);
        expect(info.gpuName, equals('NVIDIA RTX 3080'));
        expect(info.cpuCores, equals(8));
        expect(info.supportsAvx2, isTrue);
        expect(info.supportsCuda, isTrue);
        expect(info.operatingSystem, equals('Windows 11'));
      });
    });

    group('HardwareInfo.basic factory', () {
      test('should create with specified RAM in GB', () {
        final info = HardwareInfo.basic(ramGb: 16);

        expect(info.availableRamBytes, equals(16 * 1024 * 1024 * 1024));
      });
    });

    group('JSON serialization', () {
      test('should serialize and deserialize correctly', () {
        const original = HardwareInfo(
          availableRamBytes: 32 * 1024 * 1024 * 1024,
          availableVramBytes: 12 * 1024 * 1024 * 1024,
          hasGpu: true,
          gpuName: 'RTX 4090',
          cpuCores: 16,
          supportsAvx2: true,
          supportsCuda: true,
        );

        final jsonString = jsonEncode(original.toJson());
        final restored = HardwareInfo.fromJson(
          jsonDecode(jsonString) as Map<String, dynamic>,
        );

        expect(restored.availableRamBytes, equals(original.availableRamBytes));
        expect(restored.availableVramBytes, equals(original.availableVramBytes));
        expect(restored.hasGpu, equals(original.hasGpu));
        expect(restored.gpuName, equals(original.gpuName));
        expect(restored.cpuCores, equals(original.cpuCores));
      });
    });
  });

  group('ModelInfo', () {
    group('creation', () {
      test('should create with required fields', () {
        const model = ModelInfo(
          id: 'whisper-base',
          displayName: 'Whisper Base',
          description: 'Base ASR model',
          type: ModelType.asr,
          sizeBytes: 150 * 1024 * 1024, // 150 MB
          accuracyPercent: 85,
          speedRating: 4,
        );

        expect(model.id, equals('whisper-base'));
        expect(model.displayName, equals('Whisper Base'));
        expect(model.type, equals(ModelType.asr));
        expect(model.accuracyPercent, equals(85));
        expect(model.speedRating, equals(4));
      });

      test('should have sensible defaults for optional fields', () {
        const model = ModelInfo(
          id: 'test-model',
          displayName: 'Test Model',
          description: 'Test',
          type: ModelType.visual,
          sizeBytes: 100 * 1024 * 1024,
          accuracyPercent: 90,
          speedRating: 3,
        );

        expect(model.minRamBytes, equals(0));
        expect(model.minVramBytes, equals(0));
        expect(model.requiresGpu, isFalse);
        expect(model.requiresAvx2, isFalse);
      });
    });

    group('sizeFormatted', () {
      test('should format bytes correctly', () {
        const model = ModelInfo(
          id: 'tiny',
          displayName: 'Tiny',
          description: 'Tiny model',
          type: ModelType.asr,
          sizeBytes: 500,
          accuracyPercent: 70,
          speedRating: 5,
        );

        expect(model.sizeFormatted, equals('500 B'));
      });

      test('should format kilobytes correctly', () {
        const model = ModelInfo(
          id: 'small',
          displayName: 'Small',
          description: 'Small model',
          type: ModelType.asr,
          sizeBytes: 10 * 1024, // 10 KB
          accuracyPercent: 75,
          speedRating: 5,
        );

        expect(model.sizeFormatted, equals('10.0 KB'));
      });

      test('should format megabytes correctly', () {
        const model = ModelInfo(
          id: 'medium',
          displayName: 'Medium',
          description: 'Medium model',
          type: ModelType.asr,
          sizeBytes: 256 * 1024 * 1024, // 256 MB
          accuracyPercent: 85,
          speedRating: 3,
        );

        expect(model.sizeFormatted, equals('256.0 MB'));
      });

      test('should format gigabytes correctly', () {
        final model = ModelInfo(
          id: 'large',
          displayName: 'Large',
          description: 'Large model',
          type: ModelType.asr,
          sizeBytes: (2.5 * 1024 * 1024 * 1024).round(), // 2.5 GB
          accuracyPercent: 95,
          speedRating: 1,
        );

        expect(model.sizeFormatted, equals('2.50 GB'));
      });
    });

    group('minRamFormatted', () {
      test('should return "No minimum" when minRamBytes is 0', () {
        const model = ModelInfo(
          id: 'no-req',
          displayName: 'No Requirements',
          description: 'Test',
          type: ModelType.asr,
          sizeBytes: 100 * 1024 * 1024,
          accuracyPercent: 80,
          speedRating: 4,
        );

        expect(model.minRamFormatted, equals('No minimum'));
      });

      test('should format RAM requirement in GB', () {
        const model = ModelInfo(
          id: 'high-req',
          displayName: 'High Requirements',
          description: 'Test',
          type: ModelType.asr,
          sizeBytes: 1024 * 1024 * 1024,
          accuracyPercent: 95,
          speedRating: 2,
          minRamBytes: 8 * 1024 * 1024 * 1024, // 8 GB
        );

        expect(model.minRamFormatted, equals('8.0 GB'));
      });
    });

    group('speedDescription', () {
      test('should return correct descriptions for all ratings', () {
        final ratings = <int, String>{
          1: 'Very Slow',
          2: 'Slow',
          3: 'Moderate',
          4: 'Fast',
          5: 'Very Fast',
          0: 'Unknown',
          6: 'Unknown',
        };

        for (final entry in ratings.entries) {
          final model = ModelInfo(
            id: 'test',
            displayName: 'Test',
            description: 'Test',
            type: ModelType.asr,
            sizeBytes: 100 * 1024 * 1024,
            accuracyPercent: 80,
            speedRating: entry.key,
          );

          expect(model.speedDescription, equals(entry.value));
        }
      });
    });

    group('accuracyDescription', () {
      test('should return Excellent for >= 95%', () {
        const model = ModelInfo(
          id: 'excellent',
          displayName: 'Excellent',
          description: 'Test',
          type: ModelType.asr,
          sizeBytes: 100 * 1024 * 1024,
          accuracyPercent: 97,
          speedRating: 3,
        );

        expect(model.accuracyDescription, equals('Excellent'));
      });

      test('should return Very Good for 90-94%', () {
        const model = ModelInfo(
          id: 'very-good',
          displayName: 'Very Good',
          description: 'Test',
          type: ModelType.asr,
          sizeBytes: 100 * 1024 * 1024,
          accuracyPercent: 92,
          speedRating: 3,
        );

        expect(model.accuracyDescription, equals('Very Good'));
      });

      test('should return Good for 80-89%', () {
        const model = ModelInfo(
          id: 'good',
          displayName: 'Good',
          description: 'Test',
          type: ModelType.asr,
          sizeBytes: 100 * 1024 * 1024,
          accuracyPercent: 85,
          speedRating: 3,
        );

        expect(model.accuracyDescription, equals('Good'));
      });

      test('should return Fair for 70-79%', () {
        const model = ModelInfo(
          id: 'fair',
          displayName: 'Fair',
          description: 'Test',
          type: ModelType.asr,
          sizeBytes: 100 * 1024 * 1024,
          accuracyPercent: 75,
          speedRating: 3,
        );

        expect(model.accuracyDescription, equals('Fair'));
      });

      test('should return Basic for < 70%', () {
        const model = ModelInfo(
          id: 'basic',
          displayName: 'Basic',
          description: 'Test',
          type: ModelType.asr,
          sizeBytes: 100 * 1024 * 1024,
          accuracyPercent: 65,
          speedRating: 5,
        );

        expect(model.accuracyDescription, equals('Basic'));
      });
    });

    group('type checks', () {
      test('isAsrModel should return true for ASR type', () {
        const model = ModelInfo(
          id: 'asr-model',
          displayName: 'ASR Model',
          description: 'Test',
          type: ModelType.asr,
          sizeBytes: 100 * 1024 * 1024,
          accuracyPercent: 85,
          speedRating: 3,
        );

        expect(model.isAsrModel, isTrue);
        expect(model.isVisualModel, isFalse);
      });

      test('isVisualModel should return true for visual type', () {
        const model = ModelInfo(
          id: 'visual-model',
          displayName: 'Visual Model',
          description: 'Test',
          type: ModelType.visual,
          sizeBytes: 200 * 1024 * 1024,
          accuracyPercent: 90,
          speedRating: 2,
        );

        expect(model.isVisualModel, isTrue);
        expect(model.isAsrModel, isFalse);
      });
    });

    group('badge checks', () {
      test('hasBadge should return true when badge is set', () {
        const model = ModelInfo(
          id: 'test',
          displayName: 'Test',
          description: 'Test',
          type: ModelType.asr,
          sizeBytes: 100 * 1024 * 1024,
          accuracyPercent: 90,
          speedRating: 3,
          badge: 'New',
        );

        expect(model.hasBadge, isTrue);
      });

      test('hasBadge should return false when badge is null', () {
        const model = ModelInfo(
          id: 'test',
          displayName: 'Test',
          description: 'Test',
          type: ModelType.asr,
          sizeBytes: 100 * 1024 * 1024,
          accuracyPercent: 90,
          speedRating: 3,
        );

        expect(model.hasBadge, isFalse);
      });

      test('isRecommended should detect recommended badge', () {
        const recommended = ModelInfo(
          id: 'recommended',
          displayName: 'Recommended Model',
          description: 'Test',
          type: ModelType.asr,
          sizeBytes: 100 * 1024 * 1024,
          accuracyPercent: 90,
          speedRating: 4,
          badge: 'Recommended',
        );

        expect(recommended.isRecommended, isTrue);

        const notRecommended = ModelInfo(
          id: 'not-recommended',
          displayName: 'Not Recommended',
          description: 'Test',
          type: ModelType.asr,
          sizeBytes: 100 * 1024 * 1024,
          accuracyPercent: 90,
          speedRating: 4,
          badge: 'New',
        );

        expect(notRecommended.isRecommended, isFalse);
      });
    });

    group('meetsRequirements', () {
      test('should return true when hardware meets all requirements', () {
        const model = ModelInfo(
          id: 'demanding',
          displayName: 'Demanding Model',
          description: 'Test',
          type: ModelType.visual,
          sizeBytes: 1024 * 1024 * 1024,
          accuracyPercent: 95,
          speedRating: 2,
          minRamBytes: 8 * 1024 * 1024 * 1024,
          minVramBytes: 4 * 1024 * 1024 * 1024,
          requiresGpu: true,
          requiresAvx2: true,
        );

        const goodHardware = HardwareInfo(
          availableRamBytes: 16 * 1024 * 1024 * 1024,
          availableVramBytes: 8 * 1024 * 1024 * 1024,
          hasGpu: true,
          supportsAvx2: true,
        );

        expect(model.meetsRequirements(goodHardware), isTrue);
      });

      test('should return false when RAM is insufficient', () {
        const model = ModelInfo(
          id: 'test',
          displayName: 'Test',
          description: 'Test',
          type: ModelType.asr,
          sizeBytes: 100 * 1024 * 1024,
          accuracyPercent: 85,
          speedRating: 3,
          minRamBytes: 16 * 1024 * 1024 * 1024,
        );

        final lowRam = HardwareInfo.basic(ramGb: 8);

        expect(model.meetsRequirements(lowRam), isFalse);
      });

      test('should return false when GPU is required but not available', () {
        const model = ModelInfo(
          id: 'gpu-model',
          displayName: 'GPU Model',
          description: 'Test',
          type: ModelType.visual,
          sizeBytes: 500 * 1024 * 1024,
          accuracyPercent: 95,
          speedRating: 5,
          requiresGpu: true,
        );

        final noGpu = HardwareInfo.basic(ramGb: 16);

        expect(model.meetsRequirements(noGpu), isFalse);
      });

      test('should return false when AVX2 is required but not supported', () {
        const model = ModelInfo(
          id: 'avx2-model',
          displayName: 'AVX2 Model',
          description: 'Test',
          type: ModelType.asr,
          sizeBytes: 300 * 1024 * 1024,
          accuracyPercent: 92,
          speedRating: 4,
          requiresAvx2: true,
        );

        final noAvx2 = HardwareInfo.basic(ramGb: 16);

        expect(model.meetsRequirements(noAvx2), isFalse);
      });
    });

    group('getUnmetRequirements', () {
      test('should return empty list when all requirements met', () {
        const model = ModelInfo(
          id: 'simple',
          displayName: 'Simple Model',
          description: 'Test',
          type: ModelType.asr,
          sizeBytes: 50 * 1024 * 1024,
          accuracyPercent: 80,
          speedRating: 5,
        );

        final hardware = HardwareInfo.basic(ramGb: 8);

        expect(model.getUnmetRequirements(hardware), isEmpty);
      });

      test('should list all unmet requirements', () {
        const model = ModelInfo(
          id: 'demanding',
          displayName: 'Demanding',
          description: 'Test',
          type: ModelType.visual,
          sizeBytes: 1024 * 1024 * 1024,
          accuracyPercent: 98,
          speedRating: 1,
          minRamBytes: 32 * 1024 * 1024 * 1024,
          minVramBytes: 12 * 1024 * 1024 * 1024,
          requiresGpu: true,
          requiresAvx2: true,
        );

        final lowHardware = HardwareInfo.basic(ramGb: 8);
        final unmet = model.getUnmetRequirements(lowHardware);

        expect(unmet, hasLength(4)); // RAM, VRAM, GPU, AVX2
        expect(unmet.any((r) => r.contains('RAM')), isTrue);
        expect(unmet.any((r) => r.contains('VRAM')), isTrue);
        expect(unmet.any((r) => r.contains('GPU')), isTrue);
        expect(unmet.any((r) => r.contains('AVX2')), isTrue);
      });
    });

    group('estimatedProcessingFactor', () {
      test('should return correct factors for each speed rating', () {
        final factors = <int, double>{
          5: 0.25,
          4: 0.5,
          3: 1.0,
          2: 2.0,
          1: 4.0,
        };

        for (final entry in factors.entries) {
          final model = ModelInfo(
            id: 'test',
            displayName: 'Test',
            description: 'Test',
            type: ModelType.asr,
            sizeBytes: 100 * 1024 * 1024,
            accuracyPercent: 85,
            speedRating: entry.key,
          );

          expect(model.estimatedProcessingFactor, equals(entry.value));
        }
      });
    });

    group('JSON serialization', () {
      test('should serialize and deserialize correctly', () {
        const original = ModelInfo(
          id: 'whisper-medium',
          displayName: 'Whisper Medium',
          description: 'Medium-sized ASR model',
          type: ModelType.asr,
          sizeBytes: 500 * 1024 * 1024,
          accuracyPercent: 90,
          speedRating: 3,
          badge: 'Recommended',
          minRamBytes: 4 * 1024 * 1024 * 1024,
          requiresAvx2: true,
          supportedLanguages: ['en', 'es', 'fr'],
          version: '1.0.0',
        );

        final jsonString = jsonEncode(original.toJson());
        final restored = ModelInfo.fromJson(
          jsonDecode(jsonString) as Map<String, dynamic>,
        );

        expect(restored.id, equals(original.id));
        expect(restored.displayName, equals(original.displayName));
        expect(restored.description, equals(original.description));
        expect(restored.type, equals(original.type));
        expect(restored.sizeBytes, equals(original.sizeBytes));
        expect(restored.accuracyPercent, equals(original.accuracyPercent));
        expect(restored.speedRating, equals(original.speedRating));
        expect(restored.badge, equals(original.badge));
        expect(restored.minRamBytes, equals(original.minRamBytes));
        expect(restored.requiresAvx2, equals(original.requiresAvx2));
        expect(restored.supportedLanguages, equals(original.supportedLanguages));
        expect(restored.version, equals(original.version));
      });
    });
  });

  group('ModelInfoListExtensions', () {
    late List<ModelInfo> models;

    setUp(() {
      models = [
        const ModelInfo(
          id: 'asr-1',
          displayName: 'ASR 1',
          description: 'Test',
          type: ModelType.asr,
          sizeBytes: 100 * 1024 * 1024,
          accuracyPercent: 85,
          speedRating: 4,
        ),
        const ModelInfo(
          id: 'asr-2',
          displayName: 'ASR 2',
          description: 'Test',
          type: ModelType.asr,
          sizeBytes: 500 * 1024 * 1024,
          accuracyPercent: 95,
          speedRating: 2,
          badge: 'Recommended',
        ),
        const ModelInfo(
          id: 'visual-1',
          displayName: 'Visual 1',
          description: 'Test',
          type: ModelType.visual,
          sizeBytes: 200 * 1024 * 1024,
          accuracyPercent: 90,
          speedRating: 3,
        ),
      ];
    });

    test('asrModels should filter ASR models only', () {
      expect(models.asrModels, hasLength(2));
      expect(models.asrModels.every((m) => m.type == ModelType.asr), isTrue);
    });

    test('visualModels should filter visual models only', () {
      expect(models.visualModels, hasLength(1));
      expect(models.visualModels.every((m) => m.type == ModelType.visual), isTrue);
    });

    test('recommended should return recommended model', () {
      final recommended = models.recommended;
      expect(recommended?.id, equals('asr-2'));
    });

    test('sortedByAccuracy should sort descending', () {
      final sorted = models.sortedByAccuracy();
      expect(sorted.first.accuracyPercent, equals(95));
      expect(sorted.last.accuracyPercent, equals(85));
    });

    test('sortedBySpeed should sort descending', () {
      final sorted = models.sortedBySpeed();
      expect(sorted.first.speedRating, equals(4));
      expect(sorted.last.speedRating, equals(2));
    });

    test('sortedBySize should sort ascending', () {
      final sorted = models.sortedBySize();
      expect(sorted.first.sizeBytes, equals(100 * 1024 * 1024));
      expect(sorted.last.sizeBytes, equals(500 * 1024 * 1024));
    });

    test('meetingRequirements should filter by hardware', () {
      const hardwareWithGpu = HardwareInfo(
        availableRamBytes: 16 * 1024 * 1024 * 1024,
        hasGpu: true,
      );

      final demanding = [
        ...models,
        const ModelInfo(
          id: 'gpu-only',
          displayName: 'GPU Only',
          description: 'Test',
          type: ModelType.visual,
          sizeBytes: 1024 * 1024 * 1024,
          accuracyPercent: 98,
          speedRating: 5,
          requiresGpu: true,
        ),
      ];

      expect(demanding.meetingRequirements(hardwareWithGpu), hasLength(4));
      
      final noGpu = HardwareInfo.basic(ramGb: 16);
      expect(demanding.meetingRequirements(noGpu), hasLength(3));
    });
  });
}
