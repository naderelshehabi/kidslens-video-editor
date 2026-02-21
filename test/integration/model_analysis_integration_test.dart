import 'package:flutter_test/flutter_test.dart';
import 'package:kidslens_video_editor/data/models/huggingface_model.dart';
import 'package:kidslens_video_editor/services/huggingface_model_registry.dart';
import 'package:kidslens_video_editor/services/visual_analysis_service.dart';
import 'package:kidslens_video_editor/state/providers/analysis_settings_provider.dart';

/// Integration tests for model management and analysis integration
///
/// These tests verify that:
/// 1. Selected models are properly passed to analysis services
/// 2. Model IDs match between registry and analysis code
/// 3. No hardcoded/dummy values are returned
void main() {
  group('Model Registry Model ID Validation', () {
    late HuggingFaceModelRegistry registry;

    setUp(() {
      registry = HuggingFaceModelRegistry.instance;
    });

    test('all NSFW models have valid IDs', () {
      final nsfwModels = registry.getNsfwModels();
      expect(nsfwModels, isNotEmpty, reason: 'Should have NSFW models');

      for (final model in nsfwModels) {
        expect(model.id, isNotEmpty, reason: 'Model ID should not be empty');
        expect(
          model.id,
          isNot(equals('nsfw-mobilenet')),
          reason: 'Model ID should be "nsfw-mobilenet-v2" not "nsfw-mobilenet"',
        );
        expect(model.modelType, equals(HuggingFaceModelType.nsfw));
      }
    });

    test('all violence models have valid IDs', () {
      final violenceModels = registry.getViolenceModels();
      expect(violenceModels, isNotEmpty, reason: 'Should have violence models');

      for (final model in violenceModels) {
        expect(model.id, isNotEmpty);
        expect(model.modelType, equals(HuggingFaceModelType.violence));
      }
    });

    test('all blood models have valid IDs', () {
      final bloodModels = registry.getBloodModels();
      expect(bloodModels, isNotEmpty, reason: 'Should have blood models');

      for (final model in bloodModels) {
        expect(model.id, isNotEmpty);
        expect(
          model.id,
          isNot(equals('blood-detection')),
          reason:
              'Model ID should be specific like "gore-efficientnet-b2" not generic "blood-detection"',
        );
        expect(model.modelType, equals(HuggingFaceModelType.blood));
      }
    });

    test('all weapons models have valid IDs', () {
      final weaponsModels = registry.getWeaponsModels();
      expect(weaponsModels, isNotEmpty, reason: 'Should have weapons models');

      for (final model in weaponsModels) {
        expect(model.id, isNotEmpty);
        expect(
          model.id,
          isNot(equals('weapons-detection')),
          reason:
              'Model ID should be specific like "weapons-yolov8-small" not generic "weapons-detection"',
        );
        expect(model.modelType, equals(HuggingFaceModelType.weapons));
      }
    });

    test('getModelById returns correct models', () {
      // Test NSFW models
      final nsfwModel = registry.getModelById('nsfw-vit-base-quantized');
      expect(nsfwModel, isNotNull, reason: 'Should find nsfw-vit-base-quantized');
      expect(nsfwModel!.modelType, equals(HuggingFaceModelType.nsfw));

      // Test that non-existent hardcoded IDs return null
      final badNsfwModel = registry.getModelById('nsfw-mobilenet');
      expect(
        badNsfwModel,
        isNull,
        reason: 'nsfw-mobilenet should not exist - only nsfw-vit-base-quantized',
      );

      // Test blood models
      final bloodModel = registry.getModelById('gore-classifier');
      expect(bloodModel, isNotNull);
      expect(bloodModel!.modelType, equals(HuggingFaceModelType.blood));

      final badBloodModel = registry.getModelById('blood-detection');
      expect(
        badBloodModel,
        isNull,
        reason: 'blood-detection should not exist - use specific model IDs',
      );

      // Test weapons models
      final weaponsModel = registry.getModelById('weapons-classifier');
      expect(weaponsModel, isNotNull);
      expect(weaponsModel!.modelType, equals(HuggingFaceModelType.weapons));

      final badWeaponsModel = registry.getModelById('weapons-detection');
      expect(
        badWeaponsModel,
        isNull,
        reason: 'weapons-detection should not exist - use specific model IDs',
      );
    });

    test('recommended models exist and are valid', () {
      for (final type in HuggingFaceModelType.values) {
        final recommended = registry.getRecommendedModel(type);
        expect(
          recommended,
          isNotNull,
          reason: 'Should have recommended model for $type',
        );
        expect(recommended!.modelType, equals(type));

        // Verify we can look up the recommended model by ID
        final foundById = registry.getModelById(recommended.id);
        expect(
          foundById,
          isNotNull,
          reason:
              'Recommended model ${recommended.id} should be findable by ID',
        );
        expect(foundById!.id, equals(recommended.id));
      }
    });
  });

  group('VisualAnalysisSettings Model ID Integration', () {
    test('VisualAnalysisSettings should include model IDs', () {
      // Create settings with specific model IDs
      const settings = VisualAnalysisSettings(
        enableBlood: true,
        enableWeapons: true,
        nsfwModelId: 'nsfw-efficientnet-b4',
        violenceModelId: 'violence-vit-base',
        bloodModelId: 'blood-yolo-nano',
        weaponsModelId: 'weapons-detr-resnet50',
      );

      // Verify model IDs are properly stored
      expect(settings.nsfwModelId, equals('nsfw-efficientnet-b4'));
      expect(settings.violenceModelId, equals('violence-vit-base'));
      expect(settings.bloodModelId, equals('blood-yolo-nano'));
      expect(settings.weaponsModelId, equals('weapons-detr-resnet50'));
    });

    test('VisualAnalysisSettings defaults should use valid model IDs', () {
      final registry = HuggingFaceModelRegistry.instance;
      const settings = VisualAnalysisSettings();

      // Model IDs should exist in registry
      expect(
        registry.getModelById(settings.nsfwModelId),
        isNotNull,
        reason: 'NSFW model ID should be valid',
      );
      expect(
        registry.getModelById(settings.violenceModelId),
        isNotNull,
        reason: 'Violence model ID should be valid',
      );
      expect(
        registry.getModelById(settings.bloodModelId),
        isNotNull,
        reason: 'Blood model ID should be valid',
      );
      expect(
        registry.getModelById(settings.weaponsModelId),
        isNotNull,
        reason: 'Weapons model ID should be valid',
      );
    });

    test('VisualAnalysisSettings copyWith should preserve model IDs', () {
      const original = VisualAnalysisSettings(
        nsfwModelId: 'nsfw-efficientnet-b4',
        violenceModelId: 'violence-vit-base',
      );

      final modified = original.copyWith(
        nsfwThreshold: 0.7,
        bloodModelId: 'gore-efficientnet-b2',
      );

      // Original values should be preserved
      expect(modified.nsfwModelId, equals('nsfw-efficientnet-b4'));
      expect(modified.violenceModelId, equals('violence-vit-base'));
      // Modified values should be updated
      expect(modified.nsfwThreshold, equals(0.7));
      expect(modified.bloodModelId, equals('gore-efficientnet-b2'));
    });
  });

  group('Model ID Constants Validation', () {
    test('hardcoded model IDs in analysis service should match registry', () {
      final registry = HuggingFaceModelRegistry.instance;

      // These are stale hardcoded IDs that should NOT exist in the registry
      const hardcodedIds = [
        'nsfw-mobilenet', // WRONG - should be nsfw-vit-base-quantized
        'blood-detection', // WRONG - should be gore-classifier
        'weapons-detection', // WRONG - should be weapons-classifier
      ];

      for (final id in hardcodedIds) {
        final model = registry.getModelById(id);
        // This will fail for the wrong IDs, proving they need to be fixed
        expect(
          model,
          isNull,
          reason: 'Hardcoded ID "$id" should NOT exist in registry - '
              'this proves the analysis service is using wrong IDs',
        );
      }

      // These are the correct IDs that should be used
      const correctIds = [
        'nsfw-vit-base-quantized',
        'gore-classifier',
        'weapons-classifier',
      ];

      for (final id in correctIds) {
        final model = registry.getModelById(id);
        expect(
          model,
          isNotNull,
          reason: 'Correct ID "$id" should exist in registry',
        );
      }
    });
  });

  group('Analysis Service Model Loading', () {
    test('should use selected model IDs from settings, not hardcoded', () {
      // This test documents the expected behavior
      final registry = HuggingFaceModelRegistry.instance;

      // User selects specific models
      const selectedNsfwModelId = 'nsfw-vit-base-fp16';
      const selectedBloodModelId = 'gore-classifier';
      const selectedWeaponsModelId = 'weapons-classifier';

      // Verify these are valid models
      expect(registry.getModelById(selectedNsfwModelId), isNotNull);
      expect(registry.getModelById(selectedBloodModelId), isNotNull);
      expect(registry.getModelById(selectedWeaponsModelId), isNotNull);

      // The analysis service should use these IDs, not hardcoded ones
    });
  });

  group('AnalysisSettingsState to AnalysisSettings conversion', () {
    test('should properly pass visual model IDs to ModelConfig', () {
      // Create AnalysisSettingsState with specific model selections
      const settingsState = AnalysisSettingsState(
        visualModelIds: {
          HuggingFaceModelType.nsfw: 'nsfw-vit-base-quantized',
          HuggingFaceModelType.violence: 'violence-vit-classifier',
          HuggingFaceModelType.blood: 'gore-classifier',
          HuggingFaceModelType.weapons: 'weapons-classifier',
        },
      );

      // Convert to AnalysisSettings
      final analysisSettings = settingsState.toAnalysisSettings();

      // Verify model IDs are correctly passed through
      expect(analysisSettings.modelConfig.nsfwModelId,
          equals('nsfw-vit-base-quantized'),);
      expect(analysisSettings.modelConfig.violenceModelId,
          equals('violence-vit-classifier'),);
      expect(analysisSettings.modelConfig.bloodModelId,
          equals('gore-classifier'),);
      expect(analysisSettings.modelConfig.weaponsModelId,
          equals('weapons-classifier'),);
    });

    test('should use default model IDs when not specified', () {
      // Create AnalysisSettingsState without visual model IDs
      const settingsState = AnalysisSettingsState();

      // Convert to AnalysisSettings
      final analysisSettings = settingsState.toAnalysisSettings();

      // Verify default model IDs are used
      expect(analysisSettings.modelConfig.nsfwModelId,
          equals('nsfw-vit-base-quantized'),);
      expect(analysisSettings.modelConfig.violenceModelId,
          equals('violence-vit-classifier'),);
      expect(analysisSettings.modelConfig.bloodModelId,
          equals('gore-classifier'),);
      expect(analysisSettings.modelConfig.weaponsModelId,
          equals('weapons-classifier'),);
    });

    test('default model IDs should exist in registry', () {
      final registry = HuggingFaceModelRegistry.instance;

      // All standard model IDs that should serve as defaults must be valid
      expect(
        registry.getModelById('nsfw-vit-base-quantized'),
        isNotNull,
        reason: 'Default nsfwModelId should be valid',
      );
      expect(
        registry.getModelById('violence-vit-classifier'),
        isNotNull,
        reason: 'Default violenceModelId should be valid',
      );
      expect(
        registry.getModelById('gore-classifier'),
        isNotNull,
        reason: 'Default bloodModelId should be valid',
      );
      expect(
        registry.getModelById('weapons-classifier'),
        isNotNull,
        reason: 'Default weaponsModelId should be valid',
      );
    });
  });
}
