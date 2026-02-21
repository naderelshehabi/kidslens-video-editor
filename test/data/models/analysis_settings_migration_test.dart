import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:kidslens_video_editor/data/models/analysis_settings.dart';
import 'package:kidslens_video_editor/data/models/visual_content_category.dart';

void main() {
  group('AnalysisSettings migration', () {
    group('old JSON without visualContentConfig', () {
      test('should deserialize safely with default config', () {
        // Use jsonDecode(jsonEncode(...)) to ensure proper Map<String, dynamic> types
        final oldJson = jsonDecode(jsonEncode({
          'modelConfig': {
            'asrModelId': 'whisper-base',
            'visualModelId': 'nsfw-mobilenet-v2',
          },
          'profanityConfig': {},
          'nsfwThreshold': 0.6,
          'violenceThreshold': 0.6,
          'bloodThreshold': 0.6,
          'weaponsThreshold': 0.6,
          'enableNsfw': true,
          'enableViolence': true,
          'enableBlood': false,
          'enableWeapons': false,
          'enableProfanity': true,
          'frameSamplingRate': 5,
        })) as Map<String, dynamic>;

        final settings = AnalysisSettings.fromJson(oldJson);

        expect(settings.nsfwThreshold, equals(0.6));
        expect(settings.enableNsfw, isTrue);
        // visualContentConfig should be default (empty categories)
        expect(settings.visualContentConfig.categories, isEmpty);
        expect(settings.visualContentConfig.enableNudeNetDetection, isTrue);
        expect(settings.visualContentConfig.enableClipClassification, isTrue);
        expect(settings.visualContentConfig.preFilterThreshold, equals(0.30));
      });

      test('should handle null visualContentConfig field', () {
        final json = jsonDecode(jsonEncode({
          'modelConfig': {
            'asrModelId': 'whisper-base',
            'visualModelId': 'nsfw-mobilenet-v2',
          },
          'profanityConfig': {},
          'visualContentConfig': null,
        })) as Map<String, dynamic>;

        // Should not throw
        final settings = AnalysisSettings.fromJson(json);
        expect(settings.visualContentConfig.categories, isEmpty);
      });
    });

    group('JSON with visualContentConfig', () {
      test('should roundtrip with categories', () {
        final settings = AnalysisSettings(
          modelConfig: ModelConfig.defaults(),
          profanityConfig: ProfanityConfig.defaults(),
          visualContentConfig: const VisualContentConfig(
            enableNudeNetDetection: true,
            enableClipClassification: false,
            preFilterThreshold: 0.25,
            categories: [
              VisualContentCategory(
                id: 'nudity',
                name: 'Nudity',
                description: 'Test',
                detectionSource: CategoryDetectionSource.nudeNet,
                threshold: 0.45,
                action: VisualContentAction.blurRegion,
              ),
            ],
          ),
        );

        final jsonString = jsonEncode(settings.toJson());
        final restored = AnalysisSettings.fromJson(
          jsonDecode(jsonString) as Map<String, dynamic>,
        );

        expect(restored.visualContentConfig.enableNudeNetDetection, isTrue);
        expect(restored.visualContentConfig.enableClipClassification, isFalse);
        expect(restored.visualContentConfig.preFilterThreshold, equals(0.25));
        expect(restored.visualContentConfig.categories, hasLength(1));
        expect(
          restored.visualContentConfig.categories.first.id,
          equals('nudity'),
        );
        expect(
          restored.visualContentConfig.categories.first.threshold,
          equals(0.45),
        );
      });

      test('should handle empty categories list', () {
        final settings = AnalysisSettings(
          modelConfig: ModelConfig.defaults(),
          profanityConfig: ProfanityConfig.defaults(),
          visualContentConfig: const VisualContentConfig(categories: []),
        );

        final jsonString = jsonEncode(settings.toJson());
        final restored = AnalysisSettings.fromJson(
          jsonDecode(jsonString) as Map<String, dynamic>,
        );

        expect(restored.visualContentConfig.categories, isEmpty);
      });
    });

    group('VisualContentConfig helpers', () {
      test('effectivePreFilterThreshold enforces minimum of 0.05', () {
        const config = VisualContentConfig(preFilterThreshold: 0.01);
        expect(config.effectivePreFilterThreshold, equals(0.05));
      });

      test('effectivePreFilterThreshold passes through valid values', () {
        const config = VisualContentConfig(preFilterThreshold: 0.30);
        expect(config.effectivePreFilterThreshold, equals(0.30));
      });

      test('effectivePreFilterThreshold handles exactly 0.05', () {
        const config = VisualContentConfig(preFilterThreshold: 0.05);
        expect(config.effectivePreFilterThreshold, equals(0.05));
      });

      test('hasNudeNetCategories is false when no NudeNet categories', () {
        const config = VisualContentConfig(
          categories: [
            VisualContentCategory(
              id: 'clip_only',
              name: 'CLIP Only',
              description: 'Test',
              detectionSource: CategoryDetectionSource.clip,
            ),
          ],
        );
        expect(config.hasNudeNetCategories, isFalse);
      });

      test('hasNudeNetCategories is true with nudeNet category', () {
        const config = VisualContentConfig(
          categories: [
            VisualContentCategory(
              id: 'nude',
              name: 'Nudity',
              description: 'Test',
              detectionSource: CategoryDetectionSource.nudeNet,
            ),
          ],
        );
        expect(config.hasNudeNetCategories, isTrue);
      });

      test('hasNudeNetCategories ignores disabled categories', () {
        const config = VisualContentConfig(
          categories: [
            VisualContentCategory(
              id: 'nude',
              name: 'Nudity',
              description: 'Test',
              detectionSource: CategoryDetectionSource.nudeNet,
              enabled: false,
            ),
          ],
        );
        expect(config.hasNudeNetCategories, isFalse);
      });

      test('hasClipCategories is true with clip category', () {
        const config = VisualContentConfig(
          categories: [
            VisualContentCategory(
              id: 'kissing',
              name: 'Kissing',
              description: 'Test',
              detectionSource: CategoryDetectionSource.clip,
            ),
          ],
        );
        expect(config.hasClipCategories, isTrue);
      });

      test('hasAnyEnabled is false when all disabled', () {
        const config = VisualContentConfig(
          categories: [
            VisualContentCategory(
              id: 'a',
              name: 'A',
              description: 'A',
              detectionSource: CategoryDetectionSource.nudeNet,
              enabled: false,
            ),
          ],
        );
        expect(config.hasAnyEnabled, isFalse);
      });

      test('enabledCategories filters correctly', () {
        const config = VisualContentConfig(
          categories: [
            VisualContentCategory(
              id: 'a',
              name: 'Enabled',
              description: 'A',
              detectionSource: CategoryDetectionSource.nudeNet,
              enabled: true,
            ),
            VisualContentCategory(
              id: 'b',
              name: 'Disabled',
              description: 'B',
              detectionSource: CategoryDetectionSource.clip,
              enabled: false,
            ),
          ],
        );

        final enabled = config.enabledCategories;
        expect(enabled, hasLength(1));
        expect(enabled.first.id, equals('a'));
      });
    });

    group('AnalysisSettings validation with visual content', () {
      test('should flag pre-filter threshold below 0.05', () {
        final settings = AnalysisSettings(
          modelConfig: ModelConfig.defaults(),
          profanityConfig: ProfanityConfig.defaults(),
          visualContentConfig:
              const VisualContentConfig(preFilterThreshold: 0.01),
        );

        final issues = settings.validate();
        expect(issues, contains(contains('Pre-filter threshold')));
      });

      test('should flag empty custom categories', () {
        final settings = AnalysisSettings(
          modelConfig: ModelConfig.defaults(),
          profanityConfig: ProfanityConfig.defaults(),
          visualContentConfig: const VisualContentConfig(
            categories: [
              VisualContentCategory(
                id: 'empty_custom',
                name: 'Empty Custom',
                description: 'No labels or prompts',
                detectionSource: CategoryDetectionSource.nudeNet,
                isBuiltIn: false,
              ),
            ],
          ),
        );

        final issues = settings.validate();
        expect(issues, contains(contains('Empty Custom')));
      });

      test('should not flag built-in categories even without labels', () {
        final settings = AnalysisSettings(
          modelConfig: ModelConfig.defaults(),
          profanityConfig: ProfanityConfig.defaults(),
          visualContentConfig: const VisualContentConfig(
            categories: [
              VisualContentCategory(
                id: 'built_in',
                name: 'Built In',
                description: 'No labels but built-in',
                detectionSource: CategoryDetectionSource.nudeNet,
                isBuiltIn: true,
              ),
            ],
          ),
        );

        final issues = settings.validate();
        expect(issues, isNot(contains(contains('Built In'))));
      });
    });

    group('ModelConfig NudeNet/CLIP fields', () {
      test('defaults should have NudeNet and CLIP model IDs', () {
        final config = ModelConfig.defaults();

        expect(config.nudeNetModelId, equals('nudenet-v3-medium'));
        expect(config.clipVisionModelId, equals('clip-vit-b32-vision-fp16'));
        expect(config.clipTextModelId, equals('clip-vit-b32-text-fp16'));
      });

      test('should roundtrip NudeNet/CLIP model IDs via JSON', () {
        const config = ModelConfig(
          asrModelId: 'whisper-base',
          visualModelId: 'nsfw-mobilenet-v2',
          nudeNetModelId: 'nudenet-v3-nano',
          clipVisionModelId: 'clip-custom-vision',
          clipTextModelId: 'clip-custom-text',
        );

        final json = config.toJson();
        final restored = ModelConfig.fromJson(json);

        expect(restored.nudeNetModelId, equals('nudenet-v3-nano'));
        expect(restored.clipVisionModelId, equals('clip-custom-vision'));
        expect(restored.clipTextModelId, equals('clip-custom-text'));
      });
    });
  });
}
