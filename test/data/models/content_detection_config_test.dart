import 'package:flutter_test/flutter_test.dart';
import 'package:kidslens_video_editor/data/models/analysis_settings.dart';
import 'package:kidslens_video_editor/data/models/content_category.dart';
import 'package:kidslens_video_editor/data/models/content_category_defaults.dart';
import 'package:kidslens_video_editor/data/models/huggingface_model.dart';
import 'package:kidslens_video_editor/data/models/voting_config.dart';

void main() {
  // Helper categories used across tests.
  const enabledNsfwModel = ModelContribution(
    modelId: 'nsfw-model',
    displayName: 'NSFW Model',
    modelType: HuggingFaceModelType.nsfw,
    enabled: true,
  );

  const enabledNudeNetModel = ModelContribution(
    modelId: 'nudenet-model',
    displayName: 'NudeNet Model',
    modelType: HuggingFaceModelType.nudeNet,
    enabled: true,
    detectionLabels: ['FEMALE_BREAST_EXPOSED'],
  );

  const enabledClipModel = ModelContribution(
    modelId: 'clip-model',
    displayName: 'CLIP Model',
    modelType: HuggingFaceModelType.clip,
    enabled: true,
    clipPrompts: ['test prompt'],
  );

  const disabledModel = ModelContribution(
    modelId: 'disabled-model',
    displayName: 'Disabled Model',
    modelType: HuggingFaceModelType.nsfw,
    enabled: false,
  );

  const visualCategoryEnabled = ContentCategory(
    id: 'visual-a',
    name: 'Visual A',
    description: 'A visual category',
    type: CategoryType.visual,
    enabled: true,
    threshold: 0.5,
    action: RemediationAction.blurFullFrame,
    modelContributions: [enabledNsfwModel],
  );

  const visualCategoryWithNudeNet = ContentCategory(
    id: 'visual-nudenet',
    name: 'Visual NudeNet',
    description: 'NudeNet visual category',
    type: CategoryType.visual,
    enabled: true,
    threshold: 0.45,
    action: RemediationAction.blurRegion,
    modelContributions: [enabledNudeNetModel],
  );

  const visualCategoryWithClip = ContentCategory(
    id: 'visual-clip',
    name: 'Visual CLIP',
    description: 'CLIP visual category',
    type: CategoryType.visual,
    enabled: true,
    threshold: 0.5,
    action: RemediationAction.cutScene,
    modelContributions: [enabledClipModel],
  );

  const audioCategoryEnabled = ContentCategory(
    id: 'audio-a',
    name: 'Audio A',
    description: 'An audio category',
    type: CategoryType.audio,
    enabled: true,
    threshold: 0.8,
    action: RemediationAction.beep,
    modelContributions: [
      ModelContribution(
        modelId: 'asr-model',
        displayName: 'ASR Model',
        modelType: HuggingFaceModelType.asr,
        enabled: true,
      ),
    ],
  );

  const disabledCategory = ContentCategory(
    id: 'disabled',
    name: 'Disabled',
    description: 'A disabled category',
    type: CategoryType.visual,
    enabled: false,
    action: RemediationAction.blurFullFrame,
    modelContributions: [enabledNsfwModel],
  );

  const categoryNoEnabledModels = ContentCategory(
    id: 'no-models',
    name: 'No Models',
    description: 'Category with no enabled models',
    type: CategoryType.visual,
    enabled: true,
    action: RemediationAction.blurFullFrame,
    modelContributions: [disabledModel],
  );

  group('ContentDetectionConfig', () {
    test('default constructor has empty categories', () {
      const config = ContentDetectionConfig();

      expect(config.categories, isEmpty);
      expect(config.votingConfig, const VotingConfig());
      expect(config.useNsfwPreFilter, true);
      expect(config.preFilterThreshold, 0.30);
      expect(config.schemaVersion, 2);
    });

    test('with empty categories returns empty for all computed lists', () {
      const config = ContentDetectionConfig(categories: []);

      expect(config.visualCategories, isEmpty);
      expect(config.audioCategories, isEmpty);
      expect(config.enabledCategories, isEmpty);
      expect(config.enabledVisualCategories, isEmpty);
      expect(config.enabledAudioCategories, isEmpty);
      expect(config.nudeNetCategories, isEmpty);
      expect(config.clipCategories, isEmpty);
      expect(config.requiredModelIds, isEmpty);
      expect(config.hasAnyEnabled, false);
      expect(config.hasVisualCategories, false);
      expect(config.hasAudioCategories, false);
    });

    test('visualCategories returns only visual categories', () {
      final config = ContentDetectionConfig(categories: [
        visualCategoryEnabled,
        audioCategoryEnabled,
        visualCategoryWithClip,
      ]);

      final visual = config.visualCategories;
      expect(visual.length, 2);
      expect(visual.every((c) => c.isVisual), true);
      expect(visual.map((c) => c.id), containsAll(['visual-a', 'visual-clip']));
    });

    test('audioCategories returns only audio categories', () {
      final config = ContentDetectionConfig(categories: [
        visualCategoryEnabled,
        audioCategoryEnabled,
      ]);

      final audio = config.audioCategories;
      expect(audio.length, 1);
      expect(audio.first.id, 'audio-a');
      expect(audio.first.isAudio, true);
    });

    test('enabledCategories filters out disabled categories', () {
      final config = ContentDetectionConfig(categories: [
        visualCategoryEnabled,
        disabledCategory,
      ]);

      final enabled = config.enabledCategories;
      expect(enabled.length, 1);
      expect(enabled.first.id, 'visual-a');
    });

    test('enabledCategories filters out categories with no enabled models', () {
      final config = ContentDetectionConfig(categories: [
        visualCategoryEnabled,
        categoryNoEnabledModels,
      ]);

      final enabled = config.enabledCategories;
      expect(enabled.length, 1);
      expect(enabled.first.id, 'visual-a');
    });

    test('enabledVisualCategories returns enabled visual subset', () {
      final config = ContentDetectionConfig(categories: [
        visualCategoryEnabled,
        audioCategoryEnabled,
        disabledCategory,
        visualCategoryWithClip,
      ]);

      final enabledVisual = config.enabledVisualCategories;
      expect(enabledVisual.length, 2);
      expect(enabledVisual.every((c) => c.isVisual && c.enabled), true);
    });

    test('enabledAudioCategories returns enabled audio subset', () {
      final config = ContentDetectionConfig(categories: [
        visualCategoryEnabled,
        audioCategoryEnabled,
      ]);

      final enabledAudio = config.enabledAudioCategories;
      expect(enabledAudio.length, 1);
      expect(enabledAudio.first.id, 'audio-a');
    });

    test('nudeNetCategories filters enabled categories by NudeNet model type',
        () {
      final config = ContentDetectionConfig(categories: [
        visualCategoryEnabled,
        visualCategoryWithNudeNet,
        visualCategoryWithClip,
      ]);

      final nudeNet = config.nudeNetCategories;
      expect(nudeNet.length, 1);
      expect(nudeNet.first.id, 'visual-nudenet');
    });

    test('clipCategories filters enabled categories by CLIP model type', () {
      final config = ContentDetectionConfig(categories: [
        visualCategoryEnabled,
        visualCategoryWithNudeNet,
        visualCategoryWithClip,
      ]);

      final clip = config.clipCategories;
      expect(clip.length, 1);
      expect(clip.first.id, 'visual-clip');
    });

    test('hasAnyEnabled returns true when at least one category is enabled', () {
      final config = ContentDetectionConfig(categories: [
        visualCategoryEnabled,
      ]);

      expect(config.hasAnyEnabled, true);
    });

    test('hasAnyEnabled returns false when no categories are enabled', () {
      final config = ContentDetectionConfig(categories: [
        disabledCategory,
        categoryNoEnabledModels,
      ]);

      expect(config.hasAnyEnabled, false);
    });

    test('hasVisualCategories returns true when visual categories are enabled',
        () {
      final config = ContentDetectionConfig(categories: [
        visualCategoryEnabled,
      ]);

      expect(config.hasVisualCategories, true);
    });

    test(
        'hasVisualCategories returns false when only audio categories exist', () {
      final config = ContentDetectionConfig(categories: [
        audioCategoryEnabled,
      ]);

      expect(config.hasVisualCategories, false);
    });

    test('hasAudioCategories returns true when audio categories are enabled',
        () {
      final config = ContentDetectionConfig(categories: [
        audioCategoryEnabled,
      ]);

      expect(config.hasAudioCategories, true);
    });

    test(
        'hasAudioCategories returns false when only visual categories exist', () {
      final config = ContentDetectionConfig(categories: [
        visualCategoryEnabled,
      ]);

      expect(config.hasAudioCategories, false);
    });

    test('requiredModelIds aggregates from all enabled categories', () {
      final config = ContentDetectionConfig(categories: [
        visualCategoryEnabled,
        visualCategoryWithNudeNet,
        visualCategoryWithClip,
        audioCategoryEnabled,
        disabledCategory, // Should be excluded
        categoryNoEnabledModels, // Should be excluded
      ]);

      final modelIds = config.requiredModelIds;
      expect(modelIds, contains('nsfw-model'));
      expect(modelIds, contains('nudenet-model'));
      expect(modelIds, contains('clip-model'));
      expect(modelIds, contains('asr-model'));
      // disabled-model should not appear because its category is excluded
      expect(modelIds, isNot(contains('disabled-model')));
    });

    test('requiredModelIds returns empty set with no enabled categories', () {
      final config = ContentDetectionConfig(categories: [
        disabledCategory,
      ]);

      expect(config.requiredModelIds, isEmpty);
    });

    test('effectivePreFilterThreshold returns value when >= 0.05', () {
      const config = ContentDetectionConfig(preFilterThreshold: 0.30);
      expect(config.effectivePreFilterThreshold, 0.30);
    });

    test('effectivePreFilterThreshold enforces minimum of 0.05', () {
      const config = ContentDetectionConfig(preFilterThreshold: 0.01);
      expect(config.effectivePreFilterThreshold, 0.05);
    });

    test('effectivePreFilterThreshold enforces minimum for zero', () {
      const config = ContentDetectionConfig(preFilterThreshold: 0.0);
      expect(config.effectivePreFilterThreshold, 0.05);
    });

    test('effectivePreFilterThreshold allows exactly 0.05', () {
      const config = ContentDetectionConfig(preFilterThreshold: 0.05);
      expect(config.effectivePreFilterThreshold, 0.05);
    });
  });

  group('ContentDetectionConfig with ContentCategoryDefaults', () {
    test('allCategories returns all 9 built-in categories', () {
      final allCategories = ContentCategoryDefaults.allCategories;
      expect(allCategories.length, 9);
    });

    test('config loaded with allCategories has correct visual/audio split', () {
      final config = ContentDetectionConfig(
        categories: ContentCategoryDefaults.allCategories,
      );

      // 8 visual + 1 audio
      expect(config.visualCategories.length, 8);
      expect(config.audioCategories.length, 1);
    });

    test('config loaded with allCategories has expected category IDs', () {
      final config = ContentDetectionConfig(
        categories: ContentCategoryDefaults.allCategories,
      );

      final ids = config.categories.map((c) => c.id).toSet();
      expect(ids, containsAll([
        'nsfw',
        'violence',
        'blood',
        'weapons',
        'nudity',
        'sexual_content',
        'kissing',
        'immodest_dress',
        'profanity',
      ]));
    });

    test('default categories are all enabled and built-in', () {
      final allCategories = ContentCategoryDefaults.allCategories;

      for (final category in allCategories) {
        expect(category.enabled, true,
            reason: '${category.id} should be enabled');
        expect(category.isBuiltIn, true,
            reason: '${category.id} should be built-in');
      }
    });

    test('nudeNetCategories includes nudity and sexual_content', () {
      final config = ContentDetectionConfig(
        categories: ContentCategoryDefaults.allCategories,
      );

      final nudeNetIds = config.nudeNetCategories.map((c) => c.id).toSet();
      expect(nudeNetIds, contains('nudity'));
      expect(nudeNetIds, contains('sexual_content'));
    });

    test('clipCategories includes CLIP-enabled categories', () {
      final config = ContentDetectionConfig(
        categories: ContentCategoryDefaults.allCategories,
      );

      final clipIds = config.clipCategories.map((c) => c.id).toSet();
      // sexual_content, kissing, and immodest_dress have enabled CLIP models
      expect(clipIds, contains('sexual_content'));
      expect(clipIds, contains('kissing'));
      expect(clipIds, contains('immodest_dress'));
    });
  });
}
