import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:kidslens_video_editor/data/models/content_category.dart';
import 'package:kidslens_video_editor/data/models/huggingface_model.dart';

void main() {
  // ─────────────────────────────────────────────────────────────
  // ModelContribution tests
  // ─────────────────────────────────────────────────────────────

  group('ModelContribution', () {
    test('effectiveWeight returns weightOverride when set', () {
      const contribution = ModelContribution(
        modelId: 'test-model',
        displayName: 'Test Model',
        modelType: HuggingFaceModelType.nsfw,
        weightOverride: 0.75,
      );

      expect(contribution.effectiveWeight, 0.75);
    });

    test('effectiveWeight returns 1.0 when weightOverride is null', () {
      const contribution = ModelContribution(
        modelId: 'test-model',
        displayName: 'Test Model',
        modelType: HuggingFaceModelType.nsfw,
      );

      expect(contribution.effectiveWeight, 1.0);
    });

    test('JSON serialization roundtrip preserves all fields', () {
      const original = ModelContribution(
        modelId: 'nsfw-vit-base',
        displayName: 'NSFW ViT Base',
        modelType: HuggingFaceModelType.nsfw,
        enabled: true,
        weightOverride: 0.9,
        detectionLabels: ['FEMALE_BREAST_EXPOSED'],
        clipPrompts: ['explicit content'],
        clipNegativePrompts: ['safe content'],
      );

      final json = original.toJson();
      final restored = ModelContribution.fromJson(json);

      expect(restored.modelId, original.modelId);
      expect(restored.displayName, original.displayName);
      expect(restored.modelType, original.modelType);
      expect(restored.enabled, original.enabled);
      expect(restored.weightOverride, original.weightOverride);
      expect(restored.detectionLabels, original.detectionLabels);
      expect(restored.clipPrompts, original.clipPrompts);
      expect(restored.clipNegativePrompts, original.clipNegativePrompts);
    });

    test('JSON serialization roundtrip with null weightOverride', () {
      const original = ModelContribution(
        modelId: 'test-model',
        displayName: 'Test',
        modelType: HuggingFaceModelType.clip,
      );

      final json = original.toJson();
      final restored = ModelContribution.fromJson(json);

      expect(restored.weightOverride, isNull);
      expect(restored.effectiveWeight, 1.0);
    });

    test('defaults enabled to true and lists to empty', () {
      const contribution = ModelContribution(
        modelId: 'model',
        displayName: 'Model',
        modelType: HuggingFaceModelType.nudeNet,
      );

      expect(contribution.enabled, true);
      expect(contribution.detectionLabels, isEmpty);
      expect(contribution.clipPrompts, isEmpty);
      expect(contribution.clipNegativePrompts, isEmpty);
    });
  });

  // ─────────────────────────────────────────────────────────────
  // ContentCategory tests
  // ─────────────────────────────────────────────────────────────

  group('ContentCategory', () {
    const enabledContribution = ModelContribution(
      modelId: 'model-a',
      displayName: 'Model A',
      modelType: HuggingFaceModelType.nsfw,
      enabled: true,
    );

    const disabledContribution = ModelContribution(
      modelId: 'model-b',
      displayName: 'Model B',
      modelType: HuggingFaceModelType.nsfw,
      enabled: false,
    );

    const nudeNetContribution = ModelContribution(
      modelId: 'nudenet-model',
      displayName: 'NudeNet',
      modelType: HuggingFaceModelType.nudeNet,
      enabled: true,
      detectionLabels: ['FEMALE_BREAST_EXPOSED'],
    );

    const clipContribution = ModelContribution(
      modelId: 'clip-model',
      displayName: 'CLIP',
      modelType: HuggingFaceModelType.clip,
      enabled: true,
      clipPrompts: ['test prompt'],
    );

    const disabledClipContribution = ModelContribution(
      modelId: 'clip-model-2',
      displayName: 'CLIP Disabled',
      modelType: HuggingFaceModelType.clip,
      enabled: false,
    );

    test('hasEnabledModels returns true when at least one model is enabled',
        () {
      const category = ContentCategory(
        id: 'test',
        name: 'Test',
        description: 'Test category',
        type: CategoryType.visual,
        action: RemediationAction.blurFullFrame,
        modelContributions: [enabledContribution, disabledContribution],
      );

      expect(category.hasEnabledModels, true);
    });

    test('hasEnabledModels returns false when no models are enabled', () {
      const category = ContentCategory(
        id: 'test',
        name: 'Test',
        description: 'Test category',
        type: CategoryType.visual,
        action: RemediationAction.blurFullFrame,
        modelContributions: [disabledContribution],
      );

      expect(category.hasEnabledModels, false);
    });

    test('hasEnabledModels returns false when modelContributions is empty', () {
      const category = ContentCategory(
        id: 'test',
        name: 'Test',
        description: 'Test category',
        type: CategoryType.visual,
        action: RemediationAction.blurFullFrame,
        modelContributions: [],
      );

      expect(category.hasEnabledModels, false);
    });

    test('enabledModels filters out disabled contributions', () {
      const category = ContentCategory(
        id: 'test',
        name: 'Test',
        description: 'Test category',
        type: CategoryType.visual,
        action: RemediationAction.blurFullFrame,
        modelContributions: [
          enabledContribution,
          disabledContribution,
          nudeNetContribution,
        ],
      );

      final enabled = category.enabledModels;
      expect(enabled.length, 2);
      expect(enabled.map((m) => m.modelId),
          containsAll(['model-a', 'nudenet-model']));
      expect(enabled.any((m) => m.modelId == 'model-b'), false);
    });

    test('isVisual returns true for visual CategoryType', () {
      const category = ContentCategory(
        id: 'test',
        name: 'Test',
        description: 'Test',
        type: CategoryType.visual,
        action: RemediationAction.blurFullFrame,
      );

      expect(category.isVisual, true);
      expect(category.isAudio, false);
    });

    test('isAudio returns true for audio CategoryType', () {
      const category = ContentCategory(
        id: 'test',
        name: 'Test',
        description: 'Test',
        type: CategoryType.audio,
        action: RemediationAction.mute,
      );

      expect(category.isAudio, true);
      expect(category.isVisual, false);
    });

    test('hasNudeNetModels returns true when enabled NudeNet model exists', () {
      const category = ContentCategory(
        id: 'test',
        name: 'Test',
        description: 'Test',
        type: CategoryType.visual,
        action: RemediationAction.blurRegion,
        modelContributions: [enabledContribution, nudeNetContribution],
      );

      expect(category.hasNudeNetModels, true);
    });

    test('hasNudeNetModels returns false when NudeNet model is disabled', () {
      const disabledNudeNet = ModelContribution(
        modelId: 'nudenet',
        displayName: 'NudeNet',
        modelType: HuggingFaceModelType.nudeNet,
        enabled: false,
      );

      const category = ContentCategory(
        id: 'test',
        name: 'Test',
        description: 'Test',
        type: CategoryType.visual,
        action: RemediationAction.blurRegion,
        modelContributions: [disabledNudeNet],
      );

      expect(category.hasNudeNetModels, false);
    });

    test('hasClipModels returns true when enabled CLIP model exists', () {
      const category = ContentCategory(
        id: 'test',
        name: 'Test',
        description: 'Test',
        type: CategoryType.visual,
        action: RemediationAction.cutScene,
        modelContributions: [clipContribution],
      );

      expect(category.hasClipModels, true);
    });

    test('hasClipModels returns false when CLIP model is disabled', () {
      const category = ContentCategory(
        id: 'test',
        name: 'Test',
        description: 'Test',
        type: CategoryType.visual,
        action: RemediationAction.cutScene,
        modelContributions: [disabledClipContribution],
      );

      expect(category.hasClipModels, false);
    });

    test('requiredModelIds returns only enabled model IDs', () {
      const category = ContentCategory(
        id: 'test',
        name: 'Test',
        description: 'Test',
        type: CategoryType.visual,
        action: RemediationAction.blurFullFrame,
        modelContributions: [
          enabledContribution,
          disabledContribution,
          nudeNetContribution,
        ],
      );

      final required = category.requiredModelIds;
      expect(required, {'model-a', 'nudenet-model'});
      expect(required.contains('model-b'), false);
    });

    test('requiredModelIds returns empty set when no models are enabled', () {
      const category = ContentCategory(
        id: 'test',
        name: 'Test',
        description: 'Test',
        type: CategoryType.visual,
        action: RemediationAction.blurFullFrame,
        modelContributions: [disabledContribution],
      );

      expect(category.requiredModelIds, isEmpty);
    });

    test('JSON serialization roundtrip preserves all fields', () {
      const original = ContentCategory(
        id: 'violence',
        name: 'Violence',
        description: 'Violent actions',
        type: CategoryType.visual,
        enabled: true,
        threshold: 0.65,
        action: RemediationAction.cutScene,
        modelContributions: [
          ModelContribution(
            modelId: 'violence-detector',
            displayName: 'Violence Detector',
            modelType: HuggingFaceModelType.violence,
            enabled: true,
            weightOverride: 0.8,
          ),
        ],
        isBuiltIn: true,
        iconName: 'sports_mma',
        supportsRegions: false,
      );

      final json = jsonDecode(jsonEncode(original.toJson())) as Map<String, dynamic>;
      final restored = ContentCategory.fromJson(json);

      expect(restored.id, original.id);
      expect(restored.name, original.name);
      expect(restored.description, original.description);
      expect(restored.type, original.type);
      expect(restored.enabled, original.enabled);
      expect(restored.threshold, original.threshold);
      expect(restored.action, original.action);
      expect(restored.modelContributions.length,
          original.modelContributions.length);
      expect(restored.isBuiltIn, original.isBuiltIn);
      expect(restored.iconName, original.iconName);
      expect(restored.supportsRegions, original.supportsRegions);
    });

    test('JSON serialization roundtrip for audio category', () {
      const original = ContentCategory(
        id: 'profanity',
        name: 'Profanity',
        description: 'Swear words',
        type: CategoryType.audio,
        threshold: 0.8,
        action: RemediationAction.beep,
      );

      final json = jsonDecode(jsonEncode(original.toJson())) as Map<String, dynamic>;
      final restored = ContentCategory.fromJson(json);

      expect(restored.id, original.id);
      expect(restored.type, CategoryType.audio);
      expect(restored.action, RemediationAction.beep);
      expect(restored.isAudio, true);
      expect(restored.isVisual, false);
    });
  });

  // ─────────────────────────────────────────────────────────────
  // RemediationActionExtension tests
  // ─────────────────────────────────────────────────────────────

  group('RemediationActionExtension', () {
    test('isVisual returns true for visual actions', () {
      expect(RemediationAction.blurRegion.isVisual, true);
      expect(RemediationAction.pixelateRegion.isVisual, true);
      expect(RemediationAction.blackBoxRegion.isVisual, true);
      expect(RemediationAction.blurFullFrame.isVisual, true);
      expect(RemediationAction.cutScene.isVisual, true);
    });

    test('isVisual returns false for audio actions', () {
      expect(RemediationAction.mute.isVisual, false);
      expect(RemediationAction.beep.isVisual, false);
    });

    test('isAudio returns true for audio actions', () {
      expect(RemediationAction.mute.isAudio, true);
      expect(RemediationAction.beep.isAudio, true);
    });

    test('isAudio returns false for visual actions', () {
      expect(RemediationAction.blurRegion.isAudio, false);
      expect(RemediationAction.cutScene.isAudio, false);
    });

    test('isRegionLevel returns true for region-based actions', () {
      expect(RemediationAction.blurRegion.isRegionLevel, true);
      expect(RemediationAction.pixelateRegion.isRegionLevel, true);
      expect(RemediationAction.blackBoxRegion.isRegionLevel, true);
    });

    test('isRegionLevel returns false for non-region actions', () {
      expect(RemediationAction.blurFullFrame.isRegionLevel, false);
      expect(RemediationAction.cutScene.isRegionLevel, false);
      expect(RemediationAction.mute.isRegionLevel, false);
      expect(RemediationAction.beep.isRegionLevel, false);
    });

    test('displayName returns correct human-readable names', () {
      expect(RemediationAction.blurRegion.displayName, 'Blur Region');
      expect(RemediationAction.pixelateRegion.displayName, 'Pixelate Region');
      expect(
          RemediationAction.blackBoxRegion.displayName, 'Black Box Region');
      expect(RemediationAction.blurFullFrame.displayName, 'Blur Full Frame');
      expect(RemediationAction.cutScene.displayName, 'Cut Scene');
      expect(RemediationAction.mute.displayName, 'Mute');
      expect(RemediationAction.beep.displayName, 'Beep');
    });

    test('iconName returns correct icon names', () {
      expect(RemediationAction.blurRegion.iconName, 'blur_on');
      expect(RemediationAction.pixelateRegion.iconName, 'grid_on');
      expect(RemediationAction.blackBoxRegion.iconName, 'crop_square');
      expect(RemediationAction.blurFullFrame.iconName, 'blur_on');
      expect(RemediationAction.cutScene.iconName, 'content_cut');
      expect(RemediationAction.mute.iconName, 'volume_off');
      expect(RemediationAction.beep.iconName, 'music_note');
    });
  });
}
