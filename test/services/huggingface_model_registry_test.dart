import 'package:flutter_test/flutter_test.dart';
import 'package:kidslens_video_editor/data/models/huggingface_model.dart';
import 'package:kidslens_video_editor/services/huggingface_model_registry.dart';

void main() {
  late HuggingFaceModelRegistry registry;

  setUp(() {
    registry = HuggingFaceModelRegistry.instance;
  });

  group('HuggingFaceModelRegistry', () {
    group('getAsrModels()', () {
      test('should return correct count of ASR models', () {
        final asrModels = registry.getAsrModels();

        // Should have multiple Whisper models
        expect(asrModels.length, greaterThanOrEqualTo(10));
      });

      test('should return all models with ASR type', () {
        final asrModels = registry.getAsrModels();

        for (final model in asrModels) {
          expect(model.modelType, equals(HuggingFaceModelType.asr));
        }
      });

      test('should include whisper-tiny model', () {
        final asrModels = registry.getAsrModels();
        final tinyModel = asrModels.where((m) => m.id == 'whisper-tiny');

        expect(tinyModel, isNotEmpty);
      });

      test('should include whisper-large-v3 model', () {
        final asrModels = registry.getAsrModels();
        final largeModel = asrModels.where((m) => m.id == 'whisper-large-v3');

        expect(largeModel, isNotEmpty);
      });
    });

    group('getVisualModels()', () {
      test('should return correct count of visual models', () {
        final visualModels = registry.getVisualModels();

        // Should have NSFW, violence, blood, and weapons models
        expect(visualModels.length, greaterThanOrEqualTo(8));
      });

      test('should return models of visual types only', () {
        final visualModels = registry.getVisualModels();

        for (final model in visualModels) {
          expect(
            model.modelType,
            isIn([
              HuggingFaceModelType.nsfw,
              HuggingFaceModelType.violence,
              HuggingFaceModelType.blood,
              HuggingFaceModelType.weapons,
            ]),
          );
        }
      });

      test('should not contain ASR models', () {
        final visualModels = registry.getVisualModels();

        for (final model in visualModels) {
          expect(model.modelType, isNot(equals(HuggingFaceModelType.asr)));
        }
      });
    });

    group('getModelById()', () {
      test('should find existing ASR model by ID', () {
        final model = registry.getModelById('whisper-tiny');

        expect(model, isNotNull);
        expect(model!.id, equals('whisper-tiny'));
        expect(model.displayName, equals('Whisper Tiny'));
        expect(model.modelType, equals(HuggingFaceModelType.asr));
      });

      test('should find existing visual model by ID', () {
        final model = registry.getModelById('nsfw-mobilenet-v2');

        expect(model, isNotNull);
        expect(model!.id, equals('nsfw-mobilenet-v2'));
        expect(model.modelType, equals(HuggingFaceModelType.nsfw));
      });

      test('should return null for non-existent model ID', () {
        final model = registry.getModelById('non-existent-model');

        expect(model, isNull);
      });

      test('should return null for empty string ID', () {
        final model = registry.getModelById('');

        expect(model, isNull);
      });

      test('should be case-sensitive for model ID lookup', () {
        final model = registry.getModelById('WHISPER-TINY');

        expect(model, isNull);
      });
    });

    group('getDownloadUrl()', () {
      test('should generate correct URL for ASR model', () {
        final model = registry.getModelById('whisper-tiny')!;
        final url = registry.getDownloadUrl(model);

        expect(
          url,
          equals(
            'https://huggingface.co/ggerganov/whisper.cpp/resolve/main/ggml-tiny.bin',
          ),
        );
      });

      test('should generate correct URL for visual model', () {
        final model = registry.getModelById('nsfw-mobilenet-v2')!;
        final url = registry.getDownloadUrl(model);

        expect(
          url,
          equals(
            'https://huggingface.co/kidslens/nsfw-mobilenet-v2/resolve/main/nsfw-mobilenet-v2.onnx',
          ),
        );
      });

      test('should match model downloadUrl getter', () {
        final model = registry.getModelById('whisper-base')!;
        final url = registry.getDownloadUrl(model);

        expect(url, equals(model.downloadUrl));
      });
    });

    group('getModelsByType()', () {
      test('should filter ASR models correctly', () {
        final models = registry.getModelsByType(HuggingFaceModelType.asr);

        expect(models, isNotEmpty);
        for (final model in models) {
          expect(model.modelType, equals(HuggingFaceModelType.asr));
        }
      });

      test('should filter NSFW models correctly', () {
        final models = registry.getModelsByType(HuggingFaceModelType.nsfw);

        expect(models, isNotEmpty);
        for (final model in models) {
          expect(model.modelType, equals(HuggingFaceModelType.nsfw));
        }
      });

      test('should filter violence models correctly', () {
        final models = registry.getModelsByType(HuggingFaceModelType.violence);

        expect(models, isNotEmpty);
        for (final model in models) {
          expect(model.modelType, equals(HuggingFaceModelType.violence));
        }
      });

      test('should filter blood models correctly', () {
        final models = registry.getModelsByType(HuggingFaceModelType.blood);

        expect(models, isNotEmpty);
        for (final model in models) {
          expect(model.modelType, equals(HuggingFaceModelType.blood));
        }
      });

      test('should filter weapons models correctly', () {
        final models = registry.getModelsByType(HuggingFaceModelType.weapons);

        expect(models, isNotEmpty);
        for (final model in models) {
          expect(model.modelType, equals(HuggingFaceModelType.weapons));
        }
      });
    });

    group('model validation', () {
      test('all models should have valid parameterCount > 0', () {
        final allModels = registry.getAllModels();

        for (final model in allModels) {
          expect(
            model.parameterCount,
            greaterThan(0),
            reason:
                'Model ${model.id} should have parameterCount > 0, got ${model.parameterCount}',
          );
        }
      });

      test('all models should have valid sizeBytes > 0', () {
        final allModels = registry.getAllModels();

        for (final model in allModels) {
          expect(
            model.sizeBytes,
            greaterThan(0),
            reason:
                'Model ${model.id} should have sizeBytes > 0, got ${model.sizeBytes}',
          );
        }
      });

      test('all models should have valid ramRequired > 0', () {
        final allModels = registry.getAllModels();

        for (final model in allModels) {
          expect(
            model.ramRequired,
            greaterThan(0),
            reason:
                'Model ${model.id} should have ramRequired > 0, got ${model.ramRequired}',
          );
        }
      });

      test('all models should have valid accuracyPercent between 0 and 100', () {
        final allModels = registry.getAllModels();

        for (final model in allModels) {
          expect(
            model.accuracyPercent,
            inInclusiveRange(0, 100),
            reason:
                'Model ${model.id} should have accuracyPercent between 0-100, got ${model.accuracyPercent}',
          );
        }
      });

      test('all models should have valid speedMultiplier > 0', () {
        final allModels = registry.getAllModels();

        for (final model in allModels) {
          expect(
            model.speedMultiplier,
            greaterThan(0),
            reason:
                'Model ${model.id} should have speedMultiplier > 0, got ${model.speedMultiplier}',
          );
        }
      });

      test('all models should have non-empty IDs', () {
        final allModels = registry.getAllModels();

        for (final model in allModels) {
          expect(model.id, isNotEmpty);
        }
      });

      test('all models should have unique IDs', () {
        final allModels = registry.getAllModels();
        final ids = allModels.map((m) => m.id).toList();
        final uniqueIds = ids.toSet();

        expect(ids.length, equals(uniqueIds.length));
      });

      test('all models should have non-empty displayName', () {
        final allModels = registry.getAllModels();

        for (final model in allModels) {
          expect(model.displayName, isNotEmpty);
        }
      });

      test('all models should have valid HuggingFace IDs', () {
        final allModels = registry.getAllModels();

        for (final model in allModels) {
          expect(model.huggingFaceId, isNotEmpty);
          expect(model.huggingFaceId, contains('/'));
        }
      });

      test('all models should have valid file names', () {
        final allModels = registry.getAllModels();

        for (final model in allModels) {
          expect(model.fileName, isNotEmpty);
          expect(model.fileName, anyOf(endsWith('.bin'), endsWith('.onnx')));
        }
      });
    });

    group('getAllModels()', () {
      test('should return combined ASR and visual models', () {
        final allModels = registry.getAllModels();
        final asrModels = registry.getAsrModels();
        final visualModels = registry.getVisualModels();

        expect(allModels.length, equals(asrModels.length + visualModels.length));
      });
    });

    group('getRecommendedModel()', () {
      test('should return recommended model for ASR type', () {
        final recommended =
            registry.getRecommendedModel(HuggingFaceModelType.asr);

        expect(recommended, isNotNull);
        expect(recommended!.isRecommended, isTrue);
      });

      test('should return recommended model for NSFW type', () {
        final recommended =
            registry.getRecommendedModel(HuggingFaceModelType.nsfw);

        expect(recommended, isNotNull);
      });
    });

    group('sorting methods', () {
      test('getModelsSortedBySize should return models in ascending size order', () {
        final models =
            registry.getModelsSortedBySize(HuggingFaceModelType.asr);

        for (var i = 0; i < models.length - 1; i++) {
          expect(
            models[i].parameterCount,
            lessThanOrEqualTo(models[i + 1].parameterCount),
          );
        }
      });

      test('getModelsSortedByAccuracy should return models in descending accuracy order', () {
        final models =
            registry.getModelsSortedByAccuracy(HuggingFaceModelType.asr);

        for (var i = 0; i < models.length - 1; i++) {
          expect(
            models[i].accuracyPercent,
            greaterThanOrEqualTo(models[i + 1].accuracyPercent),
          );
        }
      });

      test('getModelsSortedBySpeed should return models in descending speed order', () {
        final models =
            registry.getModelsSortedBySpeed(HuggingFaceModelType.asr);

        for (var i = 0; i < models.length - 1; i++) {
          expect(
            models[i].speedMultiplier,
            greaterThanOrEqualTo(models[i + 1].speedMultiplier),
          );
        }
      });
    });

    group('language filtering', () {
      test('getEnglishOnlyAsrModels should return only English-only models', () {
        final models = registry.getEnglishOnlyAsrModels();

        expect(models, isNotEmpty);
        for (final model in models) {
          expect(model.isEnglishOnly, isTrue);
          expect(model.languages, equals(['en']));
        }
      });

      test('getMultilingualAsrModels should return only multilingual models', () {
        final models = registry.getMultilingualAsrModels();

        expect(models, isNotEmpty);
        for (final model in models) {
          expect(model.isMultilingual, isTrue);
          expect(model.languages.length, greaterThan(1));
        }
      });
    });
  });
}
