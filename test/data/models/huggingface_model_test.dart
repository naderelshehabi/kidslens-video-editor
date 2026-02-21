import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:kidslens_video_editor/data/models/huggingface_model.dart';

void main() {
  group('HuggingFaceModelType enum', () {
    test('should have all expected values', () {
      expect(HuggingFaceModelType.values, hasLength(7));
      expect(HuggingFaceModelType.values, contains(HuggingFaceModelType.asr));
      expect(HuggingFaceModelType.values, contains(HuggingFaceModelType.nsfw));
      expect(
        HuggingFaceModelType.values,
        contains(HuggingFaceModelType.violence),
      );
      expect(HuggingFaceModelType.values, contains(HuggingFaceModelType.blood));
      expect(
        HuggingFaceModelType.values,
        contains(HuggingFaceModelType.weapons),
      );
      expect(
        HuggingFaceModelType.values,
        contains(HuggingFaceModelType.nudeNet),
      );
      expect(HuggingFaceModelType.values, contains(HuggingFaceModelType.clip));
    });
  });

  group('HuggingFaceModel', () {
    group('creation', () {
      test('should create with required fields', () {
        const model = HuggingFaceModel(
          id: 'test-model',
          displayName: 'Test Model',
          huggingFaceId: 'org/test-model',
          fileName: 'model.bin',
          parameters: '100M',
          parameterCount: 100000000,
          sizeBytes: 200 * 1024 * 1024,
          ramRequired: 1 * 1024 * 1024 * 1024,
          speedMultiplier: 5,
          accuracyPercent: 90,
          modelType: HuggingFaceModelType.asr,
        );

        expect(model.id, equals('test-model'));
        expect(model.displayName, equals('Test Model'));
        expect(model.huggingFaceId, equals('org/test-model'));
        expect(model.fileName, equals('model.bin'));
        expect(model.parameters, equals('100M'));
        expect(model.parameterCount, equals(100000000));
        expect(model.speedMultiplier, equals(5));
        expect(model.accuracyPercent, equals(90));
        expect(model.modelType, equals(HuggingFaceModelType.asr));
      });

      test('should have sensible defaults for optional fields', () {
        const model = HuggingFaceModel(
          id: 'test',
          displayName: 'Test',
          huggingFaceId: 'org/test',
          fileName: 'test.bin',
          parameters: '10M',
          parameterCount: 10000000,
          sizeBytes: 50 * 1024 * 1024,
          ramRequired: 512 * 1024 * 1024,
          speedMultiplier: 10,
          accuracyPercent: 85,
          modelType: HuggingFaceModelType.nsfw,
        );

        expect(model.languages, isEmpty);
        expect(model.badge, isNull);
        expect(model.description, isNull);
        expect(model.requiresGpu, isFalse);
        expect(model.minVramBytes, equals(0));
        expect(model.license, equals('MIT'));
      });
    });

    group('fromJson()', () {
      test('should deserialize from JSON correctly', () {
        final json = {
          'id': 'whisper-tiny',
          'displayName': 'Whisper Tiny',
          'huggingFaceId': 'ggerganov/whisper.cpp',
          'fileName': 'ggml-tiny.bin',
          'parameters': '39M',
          'parameterCount': 39000000,
          'sizeBytes': 75 * 1024 * 1024,
          'ramRequired': 1 * 1024 * 1024 * 1024,
          'speedMultiplier': 10.0,
          'accuracyPercent': 85,
          'modelType': 'asr',
          'languages': ['en', 'de', 'fr'],
          'badge': 'Recommended',
          'description': 'Fast transcription model',
          'requiresGpu': false,
          'minVramBytes': 0,
          'license': 'MIT',
        };

        final model = HuggingFaceModel.fromJson(json);

        expect(model.id, equals('whisper-tiny'));
        expect(model.displayName, equals('Whisper Tiny'));
        expect(model.modelType, equals(HuggingFaceModelType.asr));
        expect(model.languages, equals(['en', 'de', 'fr']));
        expect(model.badge, equals('Recommended'));
        expect(model.description, equals('Fast transcription model'));
      });

      test('should handle missing optional fields', () {
        final json = {
          'id': 'test',
          'displayName': 'Test',
          'huggingFaceId': 'org/test',
          'fileName': 'test.bin',
          'parameters': '10M',
          'parameterCount': 10000000,
          'sizeBytes': 50000000,
          'ramRequired': 500000000,
          'speedMultiplier': 5.0,
          'accuracyPercent': 80,
          'modelType': 'violence',
        };

        final model = HuggingFaceModel.fromJson(json);

        expect(model.languages, isEmpty);
        expect(model.badge, isNull);
        expect(model.description, isNull);
      });
    });

    group('toJson()', () {
      test('should serialize to JSON correctly', () {
        const model = HuggingFaceModel(
          id: 'test-model',
          displayName: 'Test Model',
          huggingFaceId: 'org/test',
          fileName: 'model.onnx',
          parameters: '50M',
          parameterCount: 50000000,
          sizeBytes: 100 * 1024 * 1024,
          ramRequired: 512 * 1024 * 1024,
          speedMultiplier: 8,
          accuracyPercent: 92,
          modelType: HuggingFaceModelType.nsfw,
          languages: ['en'],
          badge: 'Best Value',
          description: 'Great model',
        );

        final json = model.toJson();

        expect(json['id'], equals('test-model'));
        expect(json['displayName'], equals('Test Model'));
        expect(json['huggingFaceId'], equals('org/test'));
        expect(json['fileName'], equals('model.onnx'));
        expect(json['modelType'], equals('nsfw'));
        expect(json['languages'], equals(['en']));
        expect(json['badge'], equals('Best Value'));
      });

      test('should round-trip serialize and deserialize', () {
        const original = HuggingFaceModel(
          id: 'roundtrip-test',
          displayName: 'Roundtrip Test',
          huggingFaceId: 'test/roundtrip',
          fileName: 'roundtrip.bin',
          parameters: '1B',
          parameterCount: 1000000000,
          sizeBytes: 2 * 1024 * 1024 * 1024,
          ramRequired: 8 * 1024 * 1024 * 1024,
          speedMultiplier: 2,
          accuracyPercent: 97,
          modelType: HuggingFaceModelType.asr,
          languages: ['en', 'es', 'fr', 'de'],
          badge: 'Premium',
          description: 'High quality model',
          requiresGpu: true,
          minVramBytes: 4 * 1024 * 1024 * 1024,
          license: 'Apache-2.0',
        );

        final jsonString = jsonEncode(original.toJson());
        final restored = HuggingFaceModel.fromJson(
          jsonDecode(jsonString) as Map<String, dynamic>,
        );

        expect(restored.id, equals(original.id));
        expect(restored.displayName, equals(original.displayName));
        expect(restored.huggingFaceId, equals(original.huggingFaceId));
        expect(restored.fileName, equals(original.fileName));
        expect(restored.parameterCount, equals(original.parameterCount));
        expect(restored.sizeBytes, equals(original.sizeBytes));
        expect(restored.ramRequired, equals(original.ramRequired));
        expect(restored.speedMultiplier, equals(original.speedMultiplier));
        expect(restored.accuracyPercent, equals(original.accuracyPercent));
        expect(restored.modelType, equals(original.modelType));
        expect(restored.languages, equals(original.languages));
        expect(restored.badge, equals(original.badge));
        expect(restored.description, equals(original.description));
        expect(restored.requiresGpu, equals(original.requiresGpu));
        expect(restored.license, equals(original.license));
      });
    });

    group('sizeFormatted getter', () {
      test('should format bytes correctly', () {
        const model = HuggingFaceModel(
          id: 'tiny',
          displayName: 'Tiny',
          huggingFaceId: 'org/tiny',
          fileName: 'tiny.bin',
          parameters: '1K',
          parameterCount: 1000,
          sizeBytes: 500,
          ramRequired: 1024,
          speedMultiplier: 100,
          accuracyPercent: 50,
          modelType: HuggingFaceModelType.asr,
        );

        expect(model.sizeFormatted, equals('500 B'));
      });

      test('should format kilobytes correctly', () {
        const model = HuggingFaceModel(
          id: 'small',
          displayName: 'Small',
          huggingFaceId: 'org/small',
          fileName: 'small.bin',
          parameters: '10K',
          parameterCount: 10000,
          sizeBytes: 5 * 1024, // 5 KB
          ramRequired: 1024 * 1024,
          speedMultiplier: 50,
          accuracyPercent: 60,
          modelType: HuggingFaceModelType.asr,
        );

        expect(model.sizeFormatted, equals('5.0 KB'));
      });

      test('should format megabytes correctly', () {
        const model = HuggingFaceModel(
          id: 'medium',
          displayName: 'Medium',
          huggingFaceId: 'org/medium',
          fileName: 'medium.bin',
          parameters: '100M',
          parameterCount: 100000000,
          sizeBytes: 150 * 1024 * 1024, // 150 MB
          ramRequired: 1 * 1024 * 1024 * 1024,
          speedMultiplier: 5,
          accuracyPercent: 85,
          modelType: HuggingFaceModelType.asr,
        );

        expect(model.sizeFormatted, equals('150 MB'));
      });

      test('should format gigabytes correctly', () {
        const model = HuggingFaceModel(
          id: 'large',
          displayName: 'Large',
          huggingFaceId: 'org/large',
          fileName: 'large.bin',
          parameters: '1.5B',
          parameterCount: 1500000000,
          sizeBytes: 2684354560, // ~2.5 GB
          ramRequired: 10 * 1024 * 1024 * 1024,
          speedMultiplier: 1,
          accuracyPercent: 98,
          modelType: HuggingFaceModelType.asr,
        );

        expect(model.sizeFormatted, equals('2.50 GB'));
      });
    });

    group('ramFormatted getter', () {
      test('should return "No minimum" for zero RAM', () {
        const model = HuggingFaceModel(
          id: 'test',
          displayName: 'Test',
          huggingFaceId: 'org/test',
          fileName: 'test.bin',
          parameters: '1M',
          parameterCount: 1000000,
          sizeBytes: 1000000,
          ramRequired: 0,
          speedMultiplier: 10,
          accuracyPercent: 80,
          modelType: HuggingFaceModelType.asr,
        );

        expect(model.ramFormatted, equals('No minimum'));
      });

      test('should format megabytes correctly', () {
        const model = HuggingFaceModel(
          id: 'test',
          displayName: 'Test',
          huggingFaceId: 'org/test',
          fileName: 'test.bin',
          parameters: '10M',
          parameterCount: 10000000,
          sizeBytes: 50000000,
          ramRequired: 512 * 1024 * 1024, // 512 MB
          speedMultiplier: 8,
          accuracyPercent: 85,
          modelType: HuggingFaceModelType.nsfw,
        );

        expect(model.ramFormatted, equals('512 MB'));
      });

      test('should format gigabytes correctly', () {
        const model = HuggingFaceModel(
          id: 'test',
          displayName: 'Test',
          huggingFaceId: 'org/test',
          fileName: 'test.bin',
          parameters: '1B',
          parameterCount: 1000000000,
          sizeBytes: 2000000000,
          ramRequired: 8 * 1024 * 1024 * 1024, // 8 GB
          speedMultiplier: 2,
          accuracyPercent: 95,
          modelType: HuggingFaceModelType.asr,
        );

        expect(model.ramFormatted, equals('8.0 GB'));
      });
    });

    group('downloadUrl getter', () {
      test('should generate correct HuggingFace URL', () {
        const model = HuggingFaceModel(
          id: 'whisper-tiny',
          displayName: 'Whisper Tiny',
          huggingFaceId: 'ggerganov/whisper.cpp',
          fileName: 'ggml-tiny.bin',
          parameters: '39M',
          parameterCount: 39000000,
          sizeBytes: 75 * 1024 * 1024,
          ramRequired: 1 * 1024 * 1024 * 1024,
          speedMultiplier: 10,
          accuracyPercent: 85,
          modelType: HuggingFaceModelType.asr,
        );

        expect(
          model.downloadUrl,
          equals(
            'https://huggingface.co/ggerganov/whisper.cpp/resolve/main/ggml-tiny.bin',
          ),
        );
      });
    });

    group('computed properties', () {
      test('isAsrModel should return true for ASR type', () {
        const model = HuggingFaceModel(
          id: 'asr',
          displayName: 'ASR',
          huggingFaceId: 'org/asr',
          fileName: 'asr.bin',
          parameters: '1M',
          parameterCount: 1000000,
          sizeBytes: 1000000,
          ramRequired: 1000000,
          speedMultiplier: 10,
          accuracyPercent: 80,
          modelType: HuggingFaceModelType.asr,
        );

        expect(model.isAsrModel, isTrue);
        expect(model.isVisualModel, isFalse);
      });

      test('isVisualModel should return true for visual types', () {
        const model = HuggingFaceModel(
          id: 'nsfw',
          displayName: 'NSFW',
          huggingFaceId: 'org/nsfw',
          fileName: 'nsfw.onnx',
          parameters: '5M',
          parameterCount: 5000000,
          sizeBytes: 20000000,
          ramRequired: 500000000,
          speedMultiplier: 15,
          accuracyPercent: 90,
          modelType: HuggingFaceModelType.nsfw,
        );

        expect(model.isVisualModel, isTrue);
        expect(model.isAsrModel, isFalse);
      });

      test('hasBadge should return correct value', () {
        const withBadge = HuggingFaceModel(
          id: 'with-badge',
          displayName: 'With Badge',
          huggingFaceId: 'org/badge',
          fileName: 'badge.bin',
          parameters: '1M',
          parameterCount: 1000000,
          sizeBytes: 1000000,
          ramRequired: 1000000,
          speedMultiplier: 10,
          accuracyPercent: 90,
          modelType: HuggingFaceModelType.asr,
          badge: 'Recommended',
        );

        const withoutBadge = HuggingFaceModel(
          id: 'no-badge',
          displayName: 'No Badge',
          huggingFaceId: 'org/nobadge',
          fileName: 'nobadge.bin',
          parameters: '1M',
          parameterCount: 1000000,
          sizeBytes: 1000000,
          ramRequired: 1000000,
          speedMultiplier: 10,
          accuracyPercent: 85,
          modelType: HuggingFaceModelType.asr,
        );

        expect(withBadge.hasBadge, isTrue);
        expect(withoutBadge.hasBadge, isFalse);
      });

      test('isRecommended should detect Recommended badge', () {
        const recommended = HuggingFaceModel(
          id: 'rec',
          displayName: 'Recommended',
          huggingFaceId: 'org/rec',
          fileName: 'rec.bin',
          parameters: '1M',
          parameterCount: 1000000,
          sizeBytes: 1000000,
          ramRequired: 1000000,
          speedMultiplier: 5,
          accuracyPercent: 92,
          modelType: HuggingFaceModelType.asr,
          badge: 'Recommended',
        );

        expect(recommended.isRecommended, isTrue);
      });

      test('speedDescription should return correct descriptions', () {
        expect(_createModelWithSpeed(10).speedDescription, equals('Very Fast'));
        expect(_createModelWithSpeed(7).speedDescription, equals('Fast'));
        expect(_createModelWithSpeed(4).speedDescription, equals('Moderate'));
        expect(_createModelWithSpeed(2).speedDescription, equals('Slow'));
        expect(_createModelWithSpeed(1).speedDescription, equals('Very Slow'));
      });

      test('accuracyDescription should return correct descriptions', () {
        expect(
          _createModelWithAccuracy(98).accuracyDescription,
          equals('Excellent'),
        );
        expect(
          _createModelWithAccuracy(95).accuracyDescription,
          equals('Very Good'),
        );
        expect(
          _createModelWithAccuracy(91).accuracyDescription,
          equals('Good'),
        );
        expect(
          _createModelWithAccuracy(86).accuracyDescription,
          equals('Fair'),
        );
        expect(
          _createModelWithAccuracy(70).accuracyDescription,
          equals('Basic'),
        );
      });

      test('isMultilingual should return true for multiple languages', () {
        const multilingual = HuggingFaceModel(
          id: 'multi',
          displayName: 'Multi',
          huggingFaceId: 'org/multi',
          fileName: 'multi.bin',
          parameters: '1M',
          parameterCount: 1000000,
          sizeBytes: 1000000,
          ramRequired: 1000000,
          speedMultiplier: 5,
          accuracyPercent: 90,
          modelType: HuggingFaceModelType.asr,
          languages: ['en', 'de', 'fr', 'es'],
        );

        expect(multilingual.isMultilingual, isTrue);
        expect(multilingual.isEnglishOnly, isFalse);
      });

      test('isEnglishOnly should return true for English-only models', () {
        const englishOnly = HuggingFaceModel(
          id: 'en',
          displayName: 'English',
          huggingFaceId: 'org/en',
          fileName: 'en.bin',
          parameters: '1M',
          parameterCount: 1000000,
          sizeBytes: 1000000,
          ramRequired: 1000000,
          speedMultiplier: 5,
          accuracyPercent: 90,
          modelType: HuggingFaceModelType.asr,
          languages: ['en'],
        );

        expect(englishOnly.isEnglishOnly, isTrue);
        expect(englishOnly.isMultilingual, isFalse);
      });
    });

    group('equality and hashCode', () {
      test('equal models should be equal', () {
        const model1 = HuggingFaceModel(
          id: 'test',
          displayName: 'Test',
          huggingFaceId: 'org/test',
          fileName: 'test.bin',
          parameters: '1M',
          parameterCount: 1000000,
          sizeBytes: 1000000,
          ramRequired: 1000000,
          speedMultiplier: 5,
          accuracyPercent: 90,
          modelType: HuggingFaceModelType.asr,
        );

        const model2 = HuggingFaceModel(
          id: 'test',
          displayName: 'Test',
          huggingFaceId: 'org/test',
          fileName: 'test.bin',
          parameters: '1M',
          parameterCount: 1000000,
          sizeBytes: 1000000,
          ramRequired: 1000000,
          speedMultiplier: 5,
          accuracyPercent: 90,
          modelType: HuggingFaceModelType.asr,
        );

        expect(model1, equals(model2));
        expect(model1.hashCode, equals(model2.hashCode));
      });

      test('different models should not be equal', () {
        const model1 = HuggingFaceModel(
          id: 'test1',
          displayName: 'Test 1',
          huggingFaceId: 'org/test1',
          fileName: 'test1.bin',
          parameters: '1M',
          parameterCount: 1000000,
          sizeBytes: 1000000,
          ramRequired: 1000000,
          speedMultiplier: 5,
          accuracyPercent: 90,
          modelType: HuggingFaceModelType.asr,
        );

        const model2 = HuggingFaceModel(
          id: 'test2',
          displayName: 'Test 2',
          huggingFaceId: 'org/test2',
          fileName: 'test2.bin',
          parameters: '2M',
          parameterCount: 2000000,
          sizeBytes: 2000000,
          ramRequired: 2000000,
          speedMultiplier: 3,
          accuracyPercent: 85,
          modelType: HuggingFaceModelType.nsfw,
        );

        expect(model1, isNot(equals(model2)));
      });
    });

    group('copyWith', () {
      test('should create copy with modified fields', () {
        const original = HuggingFaceModel(
          id: 'original',
          displayName: 'Original',
          huggingFaceId: 'org/original',
          fileName: 'original.bin',
          parameters: '1M',
          parameterCount: 1000000,
          sizeBytes: 1000000,
          ramRequired: 1000000,
          speedMultiplier: 5,
          accuracyPercent: 90,
          modelType: HuggingFaceModelType.asr,
        );

        final modified = original.copyWith(
          displayName: 'Modified',
          accuracyPercent: 95,
        );

        expect(modified.id, equals('original'));
        expect(modified.displayName, equals('Modified'));
        expect(modified.accuracyPercent, equals(95));
        expect(modified.speedMultiplier, equals(5));
      });
    });
  });
}

HuggingFaceModel _createModelWithSpeed(double speed) => HuggingFaceModel(
      id: 'speed-test',
      displayName: 'Speed Test',
      huggingFaceId: 'org/speed',
      fileName: 'speed.bin',
      parameters: '1M',
      parameterCount: 1000000,
      sizeBytes: 1000000,
      ramRequired: 1000000,
      speedMultiplier: speed,
      accuracyPercent: 90,
      modelType: HuggingFaceModelType.asr,
    );

HuggingFaceModel _createModelWithAccuracy(int accuracy) => HuggingFaceModel(
      id: 'accuracy-test',
      displayName: 'Accuracy Test',
      huggingFaceId: 'org/accuracy',
      fileName: 'accuracy.bin',
      parameters: '1M',
      parameterCount: 1000000,
      sizeBytes: 1000000,
      ramRequired: 1000000,
      speedMultiplier: 5,
      accuracyPercent: accuracy,
      modelType: HuggingFaceModelType.asr,
    );
