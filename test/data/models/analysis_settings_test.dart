import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:kidslens_video_editor/data/models/analysis_settings.dart';

void main() {
  group('ModelConfig', () {
    group('creation', () {
      test('should create with required fields', () {
        const config = ModelConfig(
          asrModelId: 'whisper-base',
          visualModelId: 'nsfw-detector',
        );

        expect(config.asrModelId, equals('whisper-base'));
        expect(config.visualModelId, equals('nsfw-detector'));
        expect(config.asrLanguage, equals('en'));
        expect(config.useGpu, isTrue);
        expect(config.cpuThreads, equals(4));
        expect(config.batchSize, equals(8));
        expect(config.useFp16, isFalse);
      });

      test('should create with custom values', () {
        const config = ModelConfig(
          asrModelId: 'whisper-large',
          visualModelId: 'yolo-v8',
          asrLanguage: 'es',
          useGpu: false,
          cpuThreads: 8,
          batchSize: 16,
          useFp16: true,
        );

        expect(config.asrLanguage, equals('es'));
        expect(config.useGpu, isFalse);
        expect(config.cpuThreads, equals(8));
        expect(config.batchSize, equals(16));
        expect(config.useFp16, isTrue);
      });
    });

    group('ModelConfig.defaults factory', () {
      test('should create default configuration', () {
        final config = ModelConfig.defaults();

        expect(config.asrModelId, equals('whisper-base'));
        expect(config.visualModelId, equals('nsfw-mobilenet-v2'));
        expect(config.asrLanguage, equals('en'));
        // Verify per-type model IDs have sensible defaults
        expect(config.nsfwModelId, equals('nsfw-mobilenet-v2'));
        expect(config.violenceModelId, equals('violence-mobilenet'));
        expect(config.bloodModelId, equals('gore-efficientnet-b2'));
        expect(config.weaponsModelId, equals('weapons-yolov8-small'));
      });
    });

    group('JSON serialization', () {
      test('should serialize and deserialize correctly', () {
        const original = ModelConfig(
          asrModelId: 'whisper-medium',
          visualModelId: 'custom-model',
          asrLanguage: 'fr',
          cpuThreads: 16,
          batchSize: 32,
          useFp16: true,
        );

        final jsonString = jsonEncode(original.toJson());
        final restored = ModelConfig.fromJson(
          jsonDecode(jsonString) as Map<String, dynamic>,
        );

        expect(restored.asrModelId, equals(original.asrModelId));
        expect(restored.visualModelId, equals(original.visualModelId));
        expect(restored.asrLanguage, equals(original.asrLanguage));
        expect(restored.useGpu, equals(original.useGpu));
        expect(restored.cpuThreads, equals(original.cpuThreads));
        expect(restored.batchSize, equals(original.batchSize));
        expect(restored.useFp16, equals(original.useFp16));
      });
    });
  });

  group('ProfanityConfig', () {
    group('creation', () {
      test('should create with defaults', () {
        const config = ProfanityConfig();

        expect(config.wordlistIds, equals(['english-profanity']));
        expect(config.detectLeetspeak, isTrue);
        expect(config.detectPhonetic, isTrue);
        expect(config.detectFuzzy, isTrue);
        expect(config.detectObfuscated, isTrue);
        expect(config.fuzzyThreshold, equals(0.8));
        expect(config.customWords, isEmpty);
        expect(config.excludedWords, isEmpty);
        expect(config.minWordLength, equals(2));
        expect(config.useContextAnalysis, isTrue);
      });

      test('should create with custom values', () {
        const config = ProfanityConfig(
          wordlistIds: ['english-profanity', 'spanish-profanity'],
          detectLeetspeak: false,
          fuzzyThreshold: 0.9,
          customWords: ['customword'],
          excludedWords: ['excluded'],
          minWordLength: 4,
        );

        expect(config.wordlistIds, hasLength(2));
        expect(config.detectLeetspeak, isFalse);
        expect(config.fuzzyThreshold, equals(0.9));
        expect(config.customWords, contains('customword'));
        expect(config.excludedWords, contains('excluded'));
        expect(config.minWordLength, equals(4));
      });
    });

    group('factory constructors', () {
      test('ProfanityConfig.defaults should create default config', () {
        final config = ProfanityConfig.defaults();

        expect(config.detectLeetspeak, isTrue);
        expect(config.detectPhonetic, isTrue);
        expect(config.detectFuzzy, isTrue);
        expect(config.fuzzyThreshold, equals(0.8));
      });

      test('ProfanityConfig.strict should create strict config', () {
        final config = ProfanityConfig.strict();

        expect(config.detectLeetspeak, isTrue);
        expect(config.detectPhonetic, isTrue);
        expect(config.detectFuzzy, isTrue);
        expect(config.detectObfuscated, isTrue);
        expect(config.fuzzyThreshold, equals(0.7)); // Lower threshold
        expect(config.minWordLength, equals(2));
      });

      test('ProfanityConfig.permissive should create permissive config', () {
        final config = ProfanityConfig.permissive();

        expect(config.detectLeetspeak, isTrue);
        expect(config.detectPhonetic, isFalse);
        expect(config.detectFuzzy, isFalse);
        expect(config.fuzzyThreshold, equals(0.9)); // Higher threshold
        expect(config.minWordLength, equals(3));
        expect(config.useContextAnalysis, isTrue);
      });
    });

    group('JSON serialization', () {
      test('should serialize and deserialize correctly', () {
        const original = ProfanityConfig(
          wordlistIds: ['test-list'],
          detectLeetspeak: false,
          detectPhonetic: false,
          fuzzyThreshold: 0.85,
          customWords: ['custom1', 'custom2'],
          excludedWords: ['safe'],
        );

        final jsonString = jsonEncode(original.toJson());
        final restored = ProfanityConfig.fromJson(
          jsonDecode(jsonString) as Map<String, dynamic>,
        );

        expect(restored.wordlistIds, equals(original.wordlistIds));
        expect(restored.detectLeetspeak, equals(original.detectLeetspeak));
        expect(restored.detectPhonetic, equals(original.detectPhonetic));
        expect(restored.fuzzyThreshold, equals(original.fuzzyThreshold));
        expect(restored.customWords, equals(original.customWords));
        expect(restored.excludedWords, equals(original.excludedWords));
      });
    });
  });

  group('AnalysisSettings', () {
    group('creation', () {
      test('should create with required fields', () {
        final settings = AnalysisSettings(
          modelConfig: ModelConfig.defaults(),
          profanityConfig: ProfanityConfig.defaults(),
        );

        expect(settings.modelConfig, isNotNull);
        expect(settings.profanityConfig, isNotNull);
        expect(settings.nsfwThreshold, equals(0.6));
        expect(settings.violenceThreshold, equals(0.6));
        expect(settings.bloodThreshold, equals(0.6));
        expect(settings.weaponsThreshold, equals(0.6));
        expect(settings.enableNsfw, isTrue);
        expect(settings.enableViolence, isTrue);
        expect(settings.enableBlood, isTrue);
        expect(settings.enableWeapons, isTrue);
        expect(settings.enableProfanity, isTrue);
        expect(settings.frameSamplingRate, equals(5));
        expect(settings.useSceneDetection, isTrue);
        expect(settings.minSegmentDurationMs, equals(500));
        expect(settings.mergeAdjacentDetections, isTrue);
        expect(settings.detectionBufferMs, equals(100));
        expect(settings.maxConcurrentAnalyses, equals(4));
      });
    });

    group('factory constructors', () {
      test('AnalysisSettings.defaults should create balanced settings', () {
        final settings = AnalysisSettings.defaults();

        expect(settings.nsfwThreshold, equals(0.6));
        expect(settings.enableNsfw, isTrue);
        expect(settings.frameSamplingRate, equals(5));
      });

      test('AnalysisSettings.strict should catch more content', () {
        final settings = AnalysisSettings.strict();

        expect(settings.nsfwThreshold, equals(0.4)); // Lower threshold
        expect(settings.violenceThreshold, equals(0.4));
        expect(settings.frameSamplingRate, equals(3)); // More frames
        expect(settings.minSegmentDurationMs, equals(300));
        expect(settings.detectionBufferMs, equals(200)); // More buffer
      });

      test('AnalysisSettings.permissive should reduce false positives', () {
        final settings = AnalysisSettings.permissive();

        expect(settings.nsfwThreshold, equals(0.8)); // Higher threshold
        expect(settings.frameSamplingRate, equals(10)); // Fewer frames
        expect(settings.minSegmentDurationMs, equals(1000));
        expect(settings.detectionBufferMs, equals(50)); // Less buffer
      });

      test('AnalysisSettings.audioOnly should disable visual detection', () {
        final settings = AnalysisSettings.audioOnly();

        expect(settings.enableNsfw, isFalse);
        expect(settings.enableViolence, isFalse);
        expect(settings.enableBlood, isFalse);
        expect(settings.enableWeapons, isFalse);
        expect(settings.enableProfanity, isTrue);
      });

      test('AnalysisSettings.videoOnly should disable audio detection', () {
        final settings = AnalysisSettings.videoOnly();

        expect(settings.enableNsfw, isTrue);
        expect(settings.enableViolence, isTrue);
        expect(settings.enableBlood, isTrue);
        expect(settings.enableWeapons, isTrue);
        expect(settings.enableProfanity, isFalse);
      });
    });

    group('computed properties', () {
      test('hasVisualDetection should check visual types', () {
        final visual = AnalysisSettings(
          modelConfig: ModelConfig.defaults(),
          profanityConfig: ProfanityConfig.defaults(),
        );

        final noVisual = AnalysisSettings(
          modelConfig: ModelConfig.defaults(),
          profanityConfig: ProfanityConfig.defaults(),
          enableNsfw: false,
          enableViolence: false,
          enableBlood: false,
          enableWeapons: false,
        );

        expect(visual.hasVisualDetection, isTrue);
        expect(noVisual.hasVisualDetection, isFalse);
      });

      test('hasAudioDetection should check profanity', () {
        final audio = AnalysisSettings(
          modelConfig: ModelConfig.defaults(),
          profanityConfig: ProfanityConfig.defaults(),
        );

        final noAudio = AnalysisSettings(
          modelConfig: ModelConfig.defaults(),
          profanityConfig: ProfanityConfig.defaults(),
          enableProfanity: false,
        );

        expect(audio.hasAudioDetection, isTrue);
        expect(noAudio.hasAudioDetection, isFalse);
      });

      test('hasAnyDetection should check all types', () {
        final some = AnalysisSettings.defaults();
        final none = AnalysisSettings(
          modelConfig: ModelConfig.defaults(),
          profanityConfig: ProfanityConfig.defaults(),
          enableNsfw: false,
          enableViolence: false,
          enableBlood: false,
          enableWeapons: false,
          enableProfanity: false,
        );

        expect(some.hasAnyDetection, isTrue);
        expect(none.hasAnyDetection, isFalse);
      });

      test('getThreshold should return correct thresholds', () {
        final settings = AnalysisSettings(
          modelConfig: ModelConfig.defaults(),
          profanityConfig: ProfanityConfig.defaults(),
          nsfwThreshold: 0.5,
          bloodThreshold: 0.7,
          weaponsThreshold: 0.8,
        );

        expect(settings.getThreshold('nsfw'), equals(0.5));
        expect(settings.getThreshold('violence'), equals(0.6));
        expect(settings.getThreshold('blood'), equals(0.7));
        expect(settings.getThreshold('weapons'), equals(0.8));
        expect(settings.getThreshold('unknown'), equals(0.5));
      });

      test('minSegmentDuration should return Duration', () {
        final settings = AnalysisSettings(
          modelConfig: ModelConfig.defaults(),
          profanityConfig: ProfanityConfig.defaults(),
          minSegmentDurationMs: 750,
        );

        expect(
          settings.minSegmentDuration,
          equals(const Duration(milliseconds: 750)),
        );
      });

      test('detectionBuffer should return Duration', () {
        final settings = AnalysisSettings(
          modelConfig: ModelConfig.defaults(),
          profanityConfig: ProfanityConfig.defaults(),
          detectionBufferMs: 150,
        );

        expect(
          settings.detectionBuffer,
          equals(const Duration(milliseconds: 150)),
        );
      });
    });

    group('withThresholds', () {
      test('should create copy with adjusted thresholds', () {
        final original = AnalysisSettings.defaults();
        final adjusted = original.withThresholds(
          nsfw: 0.3,
          violence: 0.4,
        );

        expect(adjusted.nsfwThreshold, equals(0.3));
        expect(adjusted.violenceThreshold, equals(0.4));
        expect(adjusted.bloodThreshold, equals(original.bloodThreshold));
        expect(adjusted.weaponsThreshold, equals(original.weaponsThreshold));
      });
    });

    group('withDetections', () {
      test('should create copy with adjusted detection flags', () {
        final original = AnalysisSettings.defaults();
        final adjusted = original.withDetections(
          nsfw: false,
          profanity: false,
        );

        expect(adjusted.enableNsfw, isFalse);
        expect(adjusted.enableProfanity, isFalse);
        expect(adjusted.enableViolence, equals(original.enableViolence));
      });
    });

    group('validate', () {
      test('should return empty list for valid settings', () {
        final settings = AnalysisSettings.defaults();
        expect(settings.validate(), isEmpty);
      });

      test('should detect no enabled detections', () {
        final settings = AnalysisSettings(
          modelConfig: ModelConfig.defaults(),
          profanityConfig: ProfanityConfig.defaults(),
          enableNsfw: false,
          enableViolence: false,
          enableBlood: false,
          enableWeapons: false,
          enableProfanity: false,
        );

        final issues = settings.validate();
        expect(issues, contains('No detection types are enabled'));
      });

      test('should detect invalid thresholds', () {
        final settings = AnalysisSettings(
          modelConfig: ModelConfig.defaults(),
          profanityConfig: ProfanityConfig.defaults(),
          nsfwThreshold: -0.1, // Invalid
          violenceThreshold: 1.5, // Invalid
        );

        final issues = settings.validate();
        expect(issues.any((i) => i.contains('NSFW threshold')), isTrue);
        expect(issues.any((i) => i.contains('Violence threshold')), isTrue);
      });

      test('should detect invalid frame sampling rate', () {
        final settings = AnalysisSettings(
          modelConfig: ModelConfig.defaults(),
          profanityConfig: ProfanityConfig.defaults(),
          frameSamplingRate: 0, // Invalid
        );

        final issues = settings.validate();
        expect(issues.any((i) => i.contains('Frame sampling rate')), isTrue);
      });

      test('should detect negative segment duration', () {
        final settings = AnalysisSettings(
          modelConfig: ModelConfig.defaults(),
          profanityConfig: ProfanityConfig.defaults(),
          minSegmentDurationMs: -100, // Invalid
        );

        final issues = settings.validate();
        expect(issues.any((i) => i.contains('Minimum segment duration')), isTrue);
      });

      test('should detect invalid concurrent analyses', () {
        final settings = AnalysisSettings(
          modelConfig: ModelConfig.defaults(),
          profanityConfig: ProfanityConfig.defaults(),
          maxConcurrentAnalyses: 0, // Invalid
        );

        final issues = settings.validate();
        expect(issues.any((i) => i.contains('Max concurrent analyses')), isTrue);
      });
    });

    group('isValid', () {
      test('should return true for valid settings', () {
        expect(AnalysisSettings.defaults().isValid, isTrue);
      });

      test('should return false for invalid settings', () {
        final invalid = AnalysisSettings(
          modelConfig: ModelConfig.defaults(),
          profanityConfig: ProfanityConfig.defaults(),
          nsfwThreshold: 2, // Invalid
        );
        expect(invalid.isValid, isFalse);
      });
    });

    group('JSON serialization', () {
      test('should serialize and deserialize correctly', () {
        const original = AnalysisSettings(
          modelConfig: ModelConfig(
            asrModelId: 'whisper-large',
            visualModelId: 'yolo-v8',
            asrLanguage: 'es',
          ),
          profanityConfig: ProfanityConfig(
            detectLeetspeak: false,
            fuzzyThreshold: 0.9,
          ),
          nsfwThreshold: 0.7,
          violenceThreshold: 0.8,
          bloodThreshold: 0.5,
          enableViolence: false,
          frameSamplingRate: 10,
          minSegmentDurationMs: 1000,
        );

        final jsonString = jsonEncode(original.toJson());
        final restored = AnalysisSettings.fromJson(
          jsonDecode(jsonString) as Map<String, dynamic>,
        );

        expect(
          restored.modelConfig.asrModelId,
          equals(original.modelConfig.asrModelId),
        );
        expect(
          restored.modelConfig.asrLanguage,
          equals(original.modelConfig.asrLanguage),
        );
        expect(
          restored.profanityConfig.detectLeetspeak,
          equals(original.profanityConfig.detectLeetspeak),
        );
        expect(restored.nsfwThreshold, equals(original.nsfwThreshold));
        expect(restored.violenceThreshold, equals(original.violenceThreshold));
        expect(restored.enableNsfw, equals(original.enableNsfw));
        expect(restored.enableViolence, equals(original.enableViolence));
        expect(restored.frameSamplingRate, equals(original.frameSamplingRate));
        expect(
          restored.minSegmentDurationMs,
          equals(original.minSegmentDurationMs),
        );
      });
    });

    group('equality', () {
      test('should be equal when all fields match', () {
        final settings1 = AnalysisSettings.defaults();
        final settings2 = AnalysisSettings.defaults();

        expect(settings1, equals(settings2));
      });

      test('should not be equal when fields differ', () {
        final settings1 = AnalysisSettings.defaults();
        final settings2 = AnalysisSettings.strict();

        expect(settings1, isNot(equals(settings2)));
      });
    });
  });
}
