import 'package:flutter_test/flutter_test.dart';
import 'package:kidslens_video_editor/data/models/analysis_settings.dart';
import 'package:kidslens_video_editor/data/models/content_category.dart';
import 'package:kidslens_video_editor/data/models/content_category_defaults.dart';
import 'package:kidslens_video_editor/data/models/frame_analysis_result.dart';
import 'package:kidslens_video_editor/data/models/huggingface_model.dart';
import 'package:kidslens_video_editor/data/models/modification.dart';
import 'package:kidslens_video_editor/data/models/voting_config.dart';
import 'package:kidslens_video_editor/services/export_service.dart';
import 'package:kidslens_video_editor/services/voting_service.dart';

/// Integration test that exercises the full MoE voting pipeline:
///   ContentDetectionConfig → VotingService → CategoryVoteResult → ExportService
void main() {
  const votingService = VotingService();

  // ─────────────────────────────────────────────────────────────
  // End-to-end: Config → Voting → Export
  // ─────────────────────────────────────────────────────────────

  group('MoE pipeline: config → voting → export', () {
    test('NSFW category with single model triggers blur full frame', () {
      // 1. Build config with defaults
      final config = ContentDetectionConfig(
        categories: ContentCategoryDefaults.allCategories,
      );

      // 2. Get the NSFW category
      final nsfwCategory =
          config.enabledCategories.firstWhere((c) => c.id == 'nsfw');
      expect(nsfwCategory.action, RemediationAction.blurFullFrame);

      // 3. Simulate a model vote above threshold
      final votes = [
        ModelVote(
          modelId: 'nsfw-vit-base-quantized',
          score: 0.85,
          weight: 1.0,
        ),
      ];

      // 4. Run voting
      final result = votingService.computeConsensus(
        category: nsfwCategory,
        votes: votes,
        config: config.votingConfig,
      );

      expect(result.triggered, true);
      expect(result.finalScore, closeTo(0.85, 0.001));

      // 5. Map to export modification
      final mod = ExportService.modificationFromRemediationAction(
        action: nsfwCategory.action,
        startTime: const Duration(seconds: 5),
        endTime: const Duration(seconds: 10),
      );

      expect(mod, isA<VideoBlur>());
    });

    test('violence category triggers cut scene on high score', () {
      final config = ContentDetectionConfig(
        categories: ContentCategoryDefaults.allCategories,
      );

      final violenceCategory =
          config.enabledCategories.firstWhere((c) => c.id == 'violence');
      expect(violenceCategory.action, RemediationAction.cutScene);

      final result = votingService.computeConsensus(
        category: violenceCategory,
        votes: [
          const ModelVote(
            modelId: 'violence-mobilenet',
            score: 0.75,
            weight: 1.0,
          ),
        ],
        config: config.votingConfig,
      );

      expect(result.triggered, true);

      final mod = ExportService.modificationFromRemediationAction(
        action: violenceCategory.action,
        startTime: const Duration(seconds: 20),
        endTime: const Duration(seconds: 25),
      );

      expect(mod, isA<VideoSkip>());
    });

    test('nudity category with region triggers blur region', () {
      final config = ContentDetectionConfig(
        categories: ContentCategoryDefaults.allCategories,
      );

      final nudityCategory =
          config.enabledCategories.firstWhere((c) => c.id == 'nudity');
      expect(nudityCategory.action, RemediationAction.blurRegion);
      expect(nudityCategory.supportsRegions, true);

      const detectedRegion = DetectedRegion(
        label: 'FEMALE_BREAST_EXPOSED',
        confidence: 0.92,
        x: 0.3,
        y: 0.2,
        width: 0.15,
        height: 0.2,
      );

      final result = votingService.computeConsensus(
        category: nudityCategory,
        votes: [
          const ModelVote(
            modelId: 'nudenet-v3-medium',
            score: 0.92,
            weight: 1.0,
            regions: [detectedRegion],
          ),
        ],
        config: config.votingConfig,
      );

      expect(result.triggered, true);
      expect(result.regions, isNotNull);
      expect(result.regions!.length, 1);

      // Convert detected region to RegionBounds for export
      final region = RegionBounds(
        x: result.regions!.first.x,
        y: result.regions!.first.y,
        width: result.regions!.first.width,
        height: result.regions!.first.height,
      );

      final mod = ExportService.modificationFromRemediationAction(
        action: nudityCategory.action,
        startTime: const Duration(seconds: 30),
        endTime: const Duration(seconds: 35),
        region: region,
      );

      expect(mod, isA<VideoRegionBlur>());
      final regionBlur = mod as VideoRegionBlur;
      expect(regionBlur.region.x, closeTo(0.3, 0.001));
      expect(regionBlur.region.y, closeTo(0.2, 0.001));
    });

    test('profanity category triggers beep audio modification', () {
      final config = ContentDetectionConfig(
        categories: ContentCategoryDefaults.allCategories,
      );

      final profanityCategory =
          config.enabledCategories.firstWhere((c) => c.id == 'profanity');
      expect(profanityCategory.isAudio, true);
      expect(profanityCategory.action, RemediationAction.beep);

      final result = votingService.computeConsensus(
        category: profanityCategory,
        votes: [
          const ModelVote(
            modelId: 'whisper-small',
            score: 0.95,
            weight: 1.0,
          ),
        ],
        config: config.votingConfig,
      );

      expect(result.triggered, true);

      final mod = ExportService.modificationFromRemediationAction(
        action: profanityCategory.action,
        startTime: const Duration(seconds: 42),
        endTime: const Duration(milliseconds: 42500),
      );

      expect(mod, isA<AudioBeep>());
      expect(mod.isAudioModification, true);
    });

    test('below-threshold score does not trigger detection', () {
      final config = ContentDetectionConfig(
        categories: ContentCategoryDefaults.allCategories,
      );

      final nsfwCategory =
          config.enabledCategories.firstWhere((c) => c.id == 'nsfw');

      final result = votingService.computeConsensus(
        category: nsfwCategory,
        votes: [
          const ModelVote(
            modelId: 'nsfw-vit-base-quantized',
            score: 0.3, // Below 0.6 threshold
            weight: 1.0,
          ),
        ],
        config: config.votingConfig,
      );

      expect(result.triggered, false);
      expect(result.finalScore, closeTo(0.3, 0.001));
    });
  });

  // ─────────────────────────────────────────────────────────────
  // Multi-model MoE voting scenarios
  // ─────────────────────────────────────────────────────────────

  group('MoE multi-model voting', () {
    test('two models voting lifts score above threshold via weighted average',
        () {
      const category = ContentCategory(
        id: 'test-visual',
        name: 'Test Visual',
        description: 'Test',
        type: CategoryType.visual,
        threshold: 0.55,
        action: RemediationAction.blurFullFrame,
        modelContributions: [
          ModelContribution(
            modelId: 'model-a',
            displayName: 'Model A',
            modelType: HuggingFaceModelType.nsfw,
            enabled: true,
          ),
          ModelContribution(
            modelId: 'model-b',
            displayName: 'Model B',
            modelType: HuggingFaceModelType.nsfw,
            enabled: true,
          ),
        ],
      );

      // Model A says 0.4 (below), Model B says 0.8 (above)
      // Weighted average with equal weights: (0.4 + 0.8) / 2 = 0.6 → above 0.55
      final result = votingService.computeConsensus(
        category: category,
        votes: [
          const ModelVote(modelId: 'model-a', score: 0.4, weight: 1.0),
          const ModelVote(modelId: 'model-b', score: 0.8, weight: 1.0),
        ],
        config: const VotingConfig(strategy: VotingStrategy.weightedAverage),
      );

      expect(result.finalScore, closeTo(0.6, 0.001));
      expect(result.triggered, true);
      expect(result.voterCount, 2);
    });

    test('high-weight model dominates the consensus', () {
      const category = ContentCategory(
        id: 'test-visual',
        name: 'Test Visual',
        description: 'Test',
        type: CategoryType.visual,
        threshold: 0.5,
        action: RemediationAction.blurFullFrame,
        modelContributions: [
          ModelContribution(
            modelId: 'accurate-model',
            displayName: 'Accurate',
            modelType: HuggingFaceModelType.nsfw,
            enabled: true,
            weightOverride: 3.0,
          ),
          ModelContribution(
            modelId: 'weak-model',
            displayName: 'Weak',
            modelType: HuggingFaceModelType.nsfw,
            enabled: true,
            weightOverride: 1.0,
          ),
        ],
      );

      // Accurate model says safe (0.2), weak model says unsafe (0.9)
      // Weighted: (0.2 * 3.0 + 0.9 * 1.0) / (3.0 + 1.0) = (0.6 + 0.9) / 4.0 = 0.375
      final result = votingService.computeConsensus(
        category: category,
        votes: [
          const ModelVote(modelId: 'accurate-model', score: 0.2, weight: 3.0),
          const ModelVote(modelId: 'weak-model', score: 0.9, weight: 1.0),
        ],
        config: const VotingConfig(strategy: VotingStrategy.weightedAverage),
      );

      expect(result.finalScore, closeTo(0.375, 0.001));
      expect(result.triggered, false, reason: '0.375 < 0.5 threshold');
    });

    test('maximum strategy triggers when any model exceeds threshold', () {
      const category = ContentCategory(
        id: 'test-visual',
        name: 'Test Visual',
        description: 'Test',
        type: CategoryType.visual,
        threshold: 0.7,
        action: RemediationAction.cutScene,
      );

      final result = votingService.computeConsensus(
        category: category,
        votes: [
          const ModelVote(modelId: 'model-a', score: 0.3, weight: 1.0),
          const ModelVote(modelId: 'model-b', score: 0.85, weight: 1.0),
        ],
        config: const VotingConfig(strategy: VotingStrategy.maximum),
      );

      expect(result.finalScore, closeTo(0.85, 0.001));
      expect(result.triggered, true);
    });

    test('minimum strategy requires all models to agree (conservative)', () {
      const category = ContentCategory(
        id: 'test-visual',
        name: 'Test Visual',
        description: 'Test',
        type: CategoryType.visual,
        threshold: 0.5,
        action: RemediationAction.blurFullFrame,
      );

      // One model is below threshold → minimum strategy blocks trigger
      final result = votingService.computeConsensus(
        category: category,
        votes: [
          const ModelVote(modelId: 'model-a', score: 0.3, weight: 1.0),
          const ModelVote(modelId: 'model-b', score: 0.9, weight: 1.0),
        ],
        config: const VotingConfig(strategy: VotingStrategy.minimum),
      );

      expect(result.finalScore, closeTo(0.3, 0.001));
      expect(result.triggered, false, reason: '0.3 < 0.5 threshold');
    });

    test('minVoters=2 blocks single model from triggering', () {
      const category = ContentCategory(
        id: 'test-visual',
        name: 'Test Visual',
        description: 'Test',
        type: CategoryType.visual,
        threshold: 0.3,
        action: RemediationAction.blurFullFrame,
      );

      final result = votingService.computeConsensus(
        category: category,
        votes: [
          const ModelVote(modelId: 'model-a', score: 0.99, weight: 1.0),
        ],
        config: const VotingConfig(minVoters: 2),
      );

      expect(result.triggered, false,
          reason: 'need at least 2 voters but only got 1');
      expect(result.finalScore, 0.0);
    });
  });

  // ─────────────────────────────────────────────────────────────
  // Region merging across models
  // ─────────────────────────────────────────────────────────────

  group('MoE region merging', () {
    test('regions from two models are merged via NMS', () {
      const category = ContentCategory(
        id: 'nudity',
        name: 'Nudity',
        description: 'Test',
        type: CategoryType.visual,
        threshold: 0.4,
        action: RemediationAction.blurRegion,
        supportsRegions: true,
      );

      // Two models detect roughly the same region
      final result = votingService.computeConsensus(
        category: category,
        votes: [
          const ModelVote(
            modelId: 'nudenet-v3-medium',
            score: 0.85,
            weight: 1.0,
            regions: [
              DetectedRegion(
                label: 'FEMALE_BREAST_EXPOSED',
                confidence: 0.9,
                x: 0.3,
                y: 0.2,
                width: 0.15,
                height: 0.2,
              ),
            ],
          ),
          const ModelVote(
            modelId: 'clip-model',
            score: 0.7,
            weight: 1.0,
            regions: [
              DetectedRegion(
                label: 'FEMALE_BREAST_EXPOSED',
                confidence: 0.75,
                x: 0.31,
                y: 0.21,
                width: 0.14,
                height: 0.19,
              ),
            ],
          ),
        ],
        config: const VotingConfig(),
      );

      expect(result.triggered, true);
      expect(result.regions, isNotNull);
      // IoU of these two nearly-identical boxes should be high → merge into 1
      expect(result.regions!.length, 1);
      // Merged confidence should be the higher one
      expect(result.regions!.first.confidence, 0.9);
    });

    test('non-overlapping regions stay separate after NMS', () {
      const category = ContentCategory(
        id: 'nudity',
        name: 'Nudity',
        description: 'Test',
        type: CategoryType.visual,
        threshold: 0.4,
        action: RemediationAction.blurRegion,
        supportsRegions: true,
      );

      final result = votingService.computeConsensus(
        category: category,
        votes: [
          const ModelVote(
            modelId: 'model-a',
            score: 0.85,
            weight: 1.0,
            regions: [
              DetectedRegion(
                label: 'A',
                confidence: 0.9,
                x: 0.0,
                y: 0.0,
                width: 0.1,
                height: 0.1,
              ),
            ],
          ),
          const ModelVote(
            modelId: 'model-b',
            score: 0.7,
            weight: 1.0,
            regions: [
              DetectedRegion(
                label: 'B',
                confidence: 0.8,
                x: 0.8,
                y: 0.8,
                width: 0.1,
                height: 0.1,
              ),
            ],
          ),
        ],
        config: const VotingConfig(),
      );

      expect(result.regions, isNotNull);
      expect(result.regions!.length, 2);
    });

    test('each merged region can be exported as a region modification', () {
      const category = ContentCategory(
        id: 'nudity',
        name: 'Nudity',
        description: 'Test',
        type: CategoryType.visual,
        threshold: 0.4,
        action: RemediationAction.pixelateRegion,
        supportsRegions: true,
      );

      final result = votingService.computeConsensus(
        category: category,
        votes: [
          const ModelVote(
            modelId: 'nudenet',
            score: 0.9,
            weight: 1.0,
            regions: [
              DetectedRegion(
                label: 'body-part',
                confidence: 0.95,
                x: 0.2,
                y: 0.3,
                width: 0.1,
                height: 0.15,
              ),
              DetectedRegion(
                label: 'body-part',
                confidence: 0.8,
                x: 0.6,
                y: 0.5,
                width: 0.12,
                height: 0.18,
              ),
            ],
          ),
        ],
        config: const VotingConfig(),
      );

      expect(result.triggered, true);
      expect(result.regions!.length, 2);

      // Export each region
      for (final region in result.regions!) {
        final bounds = RegionBounds(
          x: region.x,
          y: region.y,
          width: region.width,
          height: region.height,
        );

        final mod = ExportService.modificationFromRemediationAction(
          action: category.action,
          startTime: const Duration(seconds: 0),
          endTime: const Duration(seconds: 1),
          region: bounds,
        );

        expect(mod, isA<VideoRegionPixelate>());
        expect(mod.isRegionModification, true);
      }
    });
  });

  // ─────────────────────────────────────────────────────────────
  // ContentDetectionConfig computed properties with defaults
  // ─────────────────────────────────────────────────────────────

  group('ContentDetectionConfig with defaults integration', () {
    test('all 9 default categories have correct action types', () {
      final config = ContentDetectionConfig(
        categories: ContentCategoryDefaults.allCategories,
      );

      // Check visual actions are visual
      for (final category in config.enabledVisualCategories) {
        expect(category.action.isVisual, true,
            reason: '${category.id} should have a visual action');
      }

      // Check audio actions are audio
      for (final category in config.enabledAudioCategories) {
        expect(category.action.isAudio, true,
            reason: '${category.id} should have an audio action');
      }
    });

    test('requiredModelIds covers all enabled model contributions', () {
      final config = ContentDetectionConfig(
        categories: ContentCategoryDefaults.allCategories,
      );

      final requiredIds = config.requiredModelIds;

      // The enabled-by-default models should be included
      expect(requiredIds, contains('nsfw-vit-base-quantized'));
      expect(requiredIds, contains('violence-mobilenet'));
      expect(requiredIds, contains('gore-efficientnet-b2'));
      expect(requiredIds, contains('weapons-yolov8-small'));
      expect(requiredIds, contains('nudenet-v3-medium'));
      expect(requiredIds, contains('clip-vit-b32-vision-fp16'));
      expect(requiredIds, contains('whisper-small'));

      // Disabled-by-default models should NOT appear
      expect(requiredIds, isNot(contains('nsfw-vit-base-fp16')));
    });

    test('disabling a category removes its models from requiredModelIds', () {
      final categories = ContentCategoryDefaults.allCategories.map((c) {
        if (c.id == 'nsfw') {
          return ContentCategory(
            id: c.id,
            name: c.name,
            description: c.description,
            type: c.type,
            enabled: false,
            threshold: c.threshold,
            action: c.action,
            modelContributions: c.modelContributions,
          );
        }
        return c;
      }).toList();

      final config = ContentDetectionConfig(categories: categories);

      // nsfw-vit-base-quantized is only used by NSFW category (which is disabled)
      expect(config.requiredModelIds, isNot(contains('nsfw-vit-base-quantized')));
    });

    test('voting all 9 categories produces correct number of results', () {
      final config = ContentDetectionConfig(
        categories: ContentCategoryDefaults.allCategories,
      );

      final results = <String, CategoryVoteResult>{};

      for (final category in config.enabledCategories) {
        // Simulate a generic model vote
        final result = votingService.computeConsensus(
          category: category,
          votes: [
            ModelVote(
              modelId: category.enabledModels.first.modelId,
              score: 0.5,
              weight: 1.0,
            ),
          ],
          config: config.votingConfig,
        );
        results[category.id] = result;
      }

      // All 9 categories should have results
      expect(results.length, 9);

      // Each result should have the correct category ID
      for (final entry in results.entries) {
        expect(entry.value.categoryId, entry.key);
      }
    });
  });
}
