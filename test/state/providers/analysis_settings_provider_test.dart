import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kidslens_video_editor/data/models/huggingface_model.dart';
import 'package:kidslens_video_editor/state/providers/analysis_settings_provider.dart';

void main() {
  group('AnalysisSettingsState', () {
    group('initial state', () {
      test('should have correct default values', () {
        const state = AnalysisSettingsState();

        expect(state.asrModelId, equals('whisper-small'));
        expect(state.visualModelIds, isEmpty);
        expect(state.nsfwThreshold, equals(0.6));
        expect(state.violenceThreshold, equals(0.6));
        expect(state.bloodThreshold, equals(0.6));
        expect(state.weaponsThreshold, equals(0.6));
        expect(state.profanityThreshold, equals(0.8));
        expect(state.enableNsfw, isTrue);
        expect(state.enableViolence, isTrue);
        expect(state.enableBlood, isTrue);
        expect(state.enableWeapons, isTrue);
        expect(state.enableProfanity, isTrue);
        expect(state.frameSamplingRate, equals(5));
        expect(state.asrLanguage, equals('en'));
        expect(state.useGpuAcceleration, isTrue);
        expect(state.cpuThreads, equals(4));
      });

      test('should create with defaults factory', () {
        final state = AnalysisSettingsState.withDefaults();

        expect(state.visualModelIds, isNotEmpty);
        expect(
          state.visualModelIds[HuggingFaceModelType.nsfw],
          equals('nsfw-efficientnet-b4'),
        );
        expect(
          state.visualModelIds[HuggingFaceModelType.violence],
          equals('violence-vit-base'),
        );
        expect(
          state.visualModelIds[HuggingFaceModelType.blood],
          equals('gore-efficientnet-b2'),
        );
        expect(
          state.visualModelIds[HuggingFaceModelType.weapons],
          equals('weapons-yolov8-small'),
        );
      });
    });

    group('strict factory', () {
      test('should have correct strict threshold values', () {
        final state = AnalysisSettingsState.strict();

        expect(state.nsfwThreshold, equals(0.4));
        expect(state.violenceThreshold, equals(0.4));
        expect(state.bloodThreshold, equals(0.4));
        expect(state.weaponsThreshold, equals(0.4));
        expect(state.profanityThreshold, equals(0.7));
        expect(state.frameSamplingRate, equals(3));
      });
    });

    group('permissive factory', () {
      test('should have correct permissive threshold values', () {
        final state = AnalysisSettingsState.permissive();

        expect(state.nsfwThreshold, equals(0.8));
        expect(state.violenceThreshold, equals(0.8));
        expect(state.bloodThreshold, equals(0.8));
        expect(state.weaponsThreshold, equals(0.8));
        expect(state.profanityThreshold, equals(0.9));
        expect(state.frameSamplingRate, equals(10));
      });
    });

    group('getThreshold', () {
      test('should return correct threshold for nsfw type', () {
        const state = AnalysisSettingsState(nsfwThreshold: 0.75);

        expect(
          state.getThreshold(HuggingFaceModelType.nsfw),
          equals(0.75),
        );
      });

      test('should return correct threshold for violence type', () {
        const state = AnalysisSettingsState(violenceThreshold: 0.5);

        expect(
          state.getThreshold(HuggingFaceModelType.violence),
          equals(0.5),
        );
      });

      test('should return correct threshold for blood type', () {
        const state = AnalysisSettingsState(bloodThreshold: 0.45);

        expect(
          state.getThreshold(HuggingFaceModelType.blood),
          equals(0.45),
        );
      });

      test('should return correct threshold for weapons type', () {
        const state = AnalysisSettingsState(weaponsThreshold: 0.55);

        expect(
          state.getThreshold(HuggingFaceModelType.weapons),
          equals(0.55),
        );
      });

      test('should return 1 for asr type (no threshold)', () {
        const state = AnalysisSettingsState();

        expect(
          state.getThreshold(HuggingFaceModelType.asr),
          equals(1.0),
        );
      });
    });

    group('isEnabled', () {
      test('should return correct enabled state for nsfw', () {
        const state = AnalysisSettingsState(enableNsfw: false);

        expect(state.isEnabled(HuggingFaceModelType.nsfw), isFalse);
      });

      test('should return correct enabled state for violence', () {
        const state = AnalysisSettingsState(enableViolence: false);

        expect(state.isEnabled(HuggingFaceModelType.violence), isFalse);
      });

      test('should return correct enabled state for blood', () {
        const state = AnalysisSettingsState(enableBlood: false);

        expect(state.isEnabled(HuggingFaceModelType.blood), isFalse);
      });

      test('should return correct enabled state for weapons', () {
        const state = AnalysisSettingsState(enableWeapons: false);

        expect(state.isEnabled(HuggingFaceModelType.weapons), isFalse);
      });

      test('should always return true for asr', () {
        const state = AnalysisSettingsState();

        expect(state.isEnabled(HuggingFaceModelType.asr), isTrue);
      });
    });

    group('getVisualModelId', () {
      test('should return model id when present', () {
        const state = AnalysisSettingsState(
          visualModelIds: {HuggingFaceModelType.nsfw: 'test-nsfw-model'},
        );

        expect(
          state.getVisualModelId(HuggingFaceModelType.nsfw),
          equals('test-nsfw-model'),
        );
      });

      test('should return null when model id not present', () {
        const state = AnalysisSettingsState();

        expect(
          state.getVisualModelId(HuggingFaceModelType.nsfw),
          isNull,
        );
      });
    });

    group('copyWith', () {
      test('should copy with new asrModelId', () {
        const state = AnalysisSettingsState();
        final newState = state.copyWith(asrModelId: 'whisper-large');

        expect(newState.asrModelId, equals('whisper-large'));
        expect(state.asrModelId, equals('whisper-small')); // Original unchanged
      });

      test('should copy with new visualModelIds', () {
        const state = AnalysisSettingsState();
        final newState = state.copyWith(
          visualModelIds: {HuggingFaceModelType.nsfw: 'new-model'},
        );

        expect(newState.visualModelIds[HuggingFaceModelType.nsfw], equals('new-model'));
        expect(state.visualModelIds, isEmpty); // Original unchanged
      });

      test('should copy with new thresholds', () {
        const state = AnalysisSettingsState();
        final newState = state.copyWith(
          nsfwThreshold: 0.9,
          violenceThreshold: 0.85,
        );

        expect(newState.nsfwThreshold, equals(0.9));
        expect(newState.violenceThreshold, equals(0.85));
      });
    });

    group('toJson', () {
      test('should serialize all fields correctly', () {
        const state = AnalysisSettingsState(
          asrModelId: 'whisper-medium',
          visualModelIds: {HuggingFaceModelType.nsfw: 'test-nsfw'},
          nsfwThreshold: 0.7,
          violenceThreshold: 0.65,
          bloodThreshold: 0.55,
          weaponsThreshold: 0.5,
          profanityThreshold: 0.75,
          enableNsfw: false,
          enableBlood: false,
          enableProfanity: false,
          frameSamplingRate: 8,
          asrLanguage: 'es',
          useGpuAcceleration: false,
          cpuThreads: 8,
        );

        final json = state.toJson();

        expect(json['asrModelId'], equals('whisper-medium'));
        expect(json['visualModelIds'], isA<Map<String, dynamic>>());
        expect(
          (json['visualModelIds'] as Map<String, dynamic>)['nsfw'],
          equals('test-nsfw'),
        );
        expect(json['nsfwThreshold'], equals(0.7));
        expect(json['violenceThreshold'], equals(0.65));
        expect(json['bloodThreshold'], equals(0.55));
        expect(json['weaponsThreshold'], equals(0.5));
        expect(json['profanityThreshold'], equals(0.75));
        expect(json['enableNsfw'], isFalse);
        expect(json['enableViolence'], isTrue);
        expect(json['enableBlood'], isFalse);
        expect(json['enableWeapons'], isTrue);
        expect(json['enableProfanity'], isFalse);
        expect(json['frameSamplingRate'], equals(8));
        expect(json['asrLanguage'], equals('es'));
        expect(json['useGpuAcceleration'], isFalse);
        expect(json['cpuThreads'], equals(8));
      });

      test('should serialize empty visualModelIds as empty map', () {
        const state = AnalysisSettingsState();

        final json = state.toJson();

        expect(json['visualModelIds'], isEmpty);
      });
    });

    group('fromJson', () {
      test('should deserialize all fields correctly', () {
        final json = <String, dynamic>{
          'asrModelId': 'whisper-large',
          'visualModelIds': {'nsfw': 'test-nsfw-model', 'violence': 'test-violence'},
          'nsfwThreshold': 0.75,
          'violenceThreshold': 0.55,
          'bloodThreshold': 0.45,
          'weaponsThreshold': 0.65,
          'profanityThreshold': 0.85,
          'enableNsfw': false,
          'enableViolence': false,
          'enableBlood': true,
          'enableWeapons': false,
          'enableProfanity': true,
          'frameSamplingRate': 10,
          'asrLanguage': 'fr',
          'useGpuAcceleration': false,
          'cpuThreads': 16,
        };

        final state = AnalysisSettingsState.fromJson(json);

        expect(state.asrModelId, equals('whisper-large'));
        expect(
          state.visualModelIds[HuggingFaceModelType.nsfw],
          equals('test-nsfw-model'),
        );
        expect(
          state.visualModelIds[HuggingFaceModelType.violence],
          equals('test-violence'),
        );
        expect(state.nsfwThreshold, equals(0.75));
        expect(state.violenceThreshold, equals(0.55));
        expect(state.bloodThreshold, equals(0.45));
        expect(state.weaponsThreshold, equals(0.65));
        expect(state.profanityThreshold, equals(0.85));
        expect(state.enableNsfw, isFalse);
        expect(state.enableViolence, isFalse);
        expect(state.enableBlood, isTrue);
        expect(state.enableWeapons, isFalse);
        expect(state.enableProfanity, isTrue);
        expect(state.frameSamplingRate, equals(10));
        expect(state.asrLanguage, equals('fr'));
        expect(state.useGpuAcceleration, isFalse);
        expect(state.cpuThreads, equals(16));
      });

      test('should use defaults for missing fields', () {
        final json = <String, dynamic>{};

        final state = AnalysisSettingsState.fromJson(json);

        expect(state.asrModelId, equals('whisper-small'));
        expect(state.visualModelIds, isEmpty);
        expect(state.nsfwThreshold, equals(0.6));
        expect(state.violenceThreshold, equals(0.6));
        expect(state.bloodThreshold, equals(0.6));
        expect(state.weaponsThreshold, equals(0.6));
        expect(state.profanityThreshold, equals(0.8));
        expect(state.enableNsfw, isTrue);
        expect(state.enableViolence, isTrue);
        expect(state.enableBlood, isTrue);
        expect(state.enableWeapons, isTrue);
        expect(state.enableProfanity, isTrue);
        expect(state.frameSamplingRate, equals(5));
        expect(state.asrLanguage, equals('en'));
        expect(state.useGpuAcceleration, isTrue);
        expect(state.cpuThreads, equals(4));
      });

      test('should handle null visualModelIds', () {
        final json = <String, dynamic>{
          'visualModelIds': null,
        };

        final state = AnalysisSettingsState.fromJson(json);

        expect(state.visualModelIds, isEmpty);
      });
    });

    group('roundtrip serialization', () {
      test('should maintain state through toJson/fromJson cycle', () {
        const original = AnalysisSettingsState(
          asrModelId: 'whisper-base',
          visualModelIds: {
            HuggingFaceModelType.nsfw: 'nsfw-model',
            HuggingFaceModelType.violence: 'violence-model',
          },
          nsfwThreshold: 0.55,
          violenceThreshold: 0.45,
          bloodThreshold: 0.35,
          weaponsThreshold: 0.25,
          profanityThreshold: 0.95,
          enableNsfw: false,
          enableBlood: false,
          enableProfanity: false,
          frameSamplingRate: 7,
          asrLanguage: 'de',
          useGpuAcceleration: false,
          cpuThreads: 2,
        );

        final json = original.toJson();
        final restored = AnalysisSettingsState.fromJson(json);

        expect(restored.asrModelId, equals(original.asrModelId));
        expect(
          restored.visualModelIds[HuggingFaceModelType.nsfw],
          equals(original.visualModelIds[HuggingFaceModelType.nsfw]),
        );
        expect(
          restored.visualModelIds[HuggingFaceModelType.violence],
          equals(original.visualModelIds[HuggingFaceModelType.violence]),
        );
        expect(restored.nsfwThreshold, equals(original.nsfwThreshold));
        expect(restored.violenceThreshold, equals(original.violenceThreshold));
        expect(restored.bloodThreshold, equals(original.bloodThreshold));
        expect(restored.weaponsThreshold, equals(original.weaponsThreshold));
        expect(restored.profanityThreshold, equals(original.profanityThreshold));
        expect(restored.enableNsfw, equals(original.enableNsfw));
        expect(restored.enableViolence, equals(original.enableViolence));
        expect(restored.enableBlood, equals(original.enableBlood));
        expect(restored.enableWeapons, equals(original.enableWeapons));
        expect(restored.enableProfanity, equals(original.enableProfanity));
        expect(restored.frameSamplingRate, equals(original.frameSamplingRate));
        expect(restored.asrLanguage, equals(original.asrLanguage));
        expect(restored.useGpuAcceleration, equals(original.useGpuAcceleration));
        expect(restored.cpuThreads, equals(original.cpuThreads));
      });
    });

    group('toAnalysisSettings', () {
      test('should convert to AnalysisSettings correctly', () {
        const state = AnalysisSettingsState(
          asrModelId: 'whisper-medium',
          nsfwThreshold: 0.7,
          violenceThreshold: 0.65,
          bloodThreshold: 0.55,
          weaponsThreshold: 0.5,
          enableViolence: false,
          enableWeapons: false,
          frameSamplingRate: 8,
          asrLanguage: 'es',
          cpuThreads: 8,
        );

        final analysisSettings = state.toAnalysisSettings();

        expect(analysisSettings.modelConfig.asrModelId, equals('whisper-medium'));
        expect(analysisSettings.modelConfig.asrLanguage, equals('es'));
        expect(analysisSettings.modelConfig.useGpu, isTrue);
        expect(analysisSettings.modelConfig.cpuThreads, equals(8));
        expect(analysisSettings.nsfwThreshold, equals(0.7));
        expect(analysisSettings.violenceThreshold, equals(0.65));
        expect(analysisSettings.bloodThreshold, equals(0.55));
        expect(analysisSettings.weaponsThreshold, equals(0.5));
        expect(analysisSettings.enableNsfw, isTrue);
        expect(analysisSettings.enableViolence, isFalse);
        expect(analysisSettings.enableBlood, isTrue);
        expect(analysisSettings.enableWeapons, isFalse);
        expect(analysisSettings.enableProfanity, isTrue);
        expect(analysisSettings.frameSamplingRate, equals(8));
      });
    });
  });

  group('AnalysisSettingsNotifier', () {
    late ProviderContainer container;
    late AnalysisSettingsNotifier notifier;

    setUp(() {
      container = ProviderContainer();
      notifier = container.read(analysisSettingsNotifierProvider.notifier);
    });

    tearDown(() {
      container.dispose();
    });

    group('initialization', () {
      test('should start with default state', () {
        expect(notifier.state.asrModelId, equals('whisper-small'));
        expect(notifier.state.nsfwThreshold, equals(0.6));
        expect(notifier.state.violenceThreshold, equals(0.6));
      });
    });

    group('setAsrModel', () {
      test('should update asr model id', () {
        notifier.setAsrModel('whisper-large');

        expect(notifier.state.asrModelId, equals('whisper-large'));
      });

      test('should preserve other state when setting asr model', () {
        notifier
          ..setNsfwThreshold(0.9)
          ..setAsrModel('whisper-tiny');

        expect(notifier.state.asrModelId, equals('whisper-tiny'));
        expect(notifier.state.nsfwThreshold, equals(0.9));
      });
    });

    group('setVisualModel', () {
      test('should update visual model for nsfw type', () {
        notifier.setVisualModel(HuggingFaceModelType.nsfw, 'custom-nsfw-model');

        expect(
          notifier.state.visualModelIds[HuggingFaceModelType.nsfw],
          equals('custom-nsfw-model'),
        );
      });

      test('should update visual model for violence type', () {
        notifier.setVisualModel(HuggingFaceModelType.violence, 'violence-v2');

        expect(
          notifier.state.visualModelIds[HuggingFaceModelType.violence],
          equals('violence-v2'),
        );
      });

      test('should update visual model for blood type', () {
        notifier.setVisualModel(HuggingFaceModelType.blood, 'blood-detector');

        expect(
          notifier.state.visualModelIds[HuggingFaceModelType.blood],
          equals('blood-detector'),
        );
      });

      test('should update visual model for weapons type', () {
        notifier.setVisualModel(HuggingFaceModelType.weapons, 'weapons-v3');

        expect(
          notifier.state.visualModelIds[HuggingFaceModelType.weapons],
          equals('weapons-v3'),
        );
      });

      test('should preserve other visual models when setting one', () {
        notifier
          ..setVisualModel(HuggingFaceModelType.nsfw, 'nsfw-1')
          ..setVisualModel(HuggingFaceModelType.violence, 'violence-1');

        expect(
          notifier.state.visualModelIds[HuggingFaceModelType.nsfw],
          equals('nsfw-1'),
        );
        expect(
          notifier.state.visualModelIds[HuggingFaceModelType.violence],
          equals('violence-1'),
        );
      });
    });

    group('setNsfwThreshold', () {
      test('should update nsfw threshold', () {
        notifier.setNsfwThreshold(0.8);

        expect(notifier.state.nsfwThreshold, equals(0.8));
      });

      test('should clamp nsfw threshold to minimum 0', () {
        notifier.setNsfwThreshold(-0.5);

        expect(notifier.state.nsfwThreshold, equals(0.0));
      });

      test('should clamp nsfw threshold to maximum 1', () {
        notifier.setNsfwThreshold(1.5);

        expect(notifier.state.nsfwThreshold, equals(1.0));
      });

      test('should handle edge case of exactly 0', () {
        notifier.setNsfwThreshold(0);

        expect(notifier.state.nsfwThreshold, equals(0.0));
      });

      test('should handle edge case of exactly 1', () {
        notifier.setNsfwThreshold(1);

        expect(notifier.state.nsfwThreshold, equals(1.0));
      });
    });

    group('setViolenceThreshold', () {
      test('should update violence threshold', () {
        notifier.setViolenceThreshold(0.75);

        expect(notifier.state.violenceThreshold, equals(0.75));
      });

      test('should clamp violence threshold to minimum 0', () {
        notifier.setViolenceThreshold(-1);

        expect(notifier.state.violenceThreshold, equals(0.0));
      });

      test('should clamp violence threshold to maximum 1', () {
        notifier.setViolenceThreshold(2);

        expect(notifier.state.violenceThreshold, equals(1.0));
      });
    });

    group('setBloodThreshold', () {
      test('should update blood threshold', () {
        notifier.setBloodThreshold(0.5);

        expect(notifier.state.bloodThreshold, equals(0.5));
      });

      test('should clamp blood threshold to 0-1 range', () {
        notifier.setBloodThreshold(-0.1);
        expect(notifier.state.bloodThreshold, equals(0.0));

        notifier.setBloodThreshold(1.2);
        expect(notifier.state.bloodThreshold, equals(1.0));
      });
    });

    group('setWeaponsThreshold', () {
      test('should update weapons threshold', () {
        notifier.setWeaponsThreshold(0.65);

        expect(notifier.state.weaponsThreshold, equals(0.65));
      });

      test('should clamp weapons threshold to 0-1 range', () {
        notifier.setWeaponsThreshold(-5);
        expect(notifier.state.weaponsThreshold, equals(0.0));

        notifier.setWeaponsThreshold(5);
        expect(notifier.state.weaponsThreshold, equals(1.0));
      });
    });

    group('setProfanityThreshold', () {
      test('should update profanity threshold', () {
        notifier.setProfanityThreshold(0.85);

        expect(notifier.state.profanityThreshold, equals(0.85));
      });

      test('should clamp profanity threshold to 0-1 range', () {
        notifier.setProfanityThreshold(-0.3);
        expect(notifier.state.profanityThreshold, equals(0.0));

        notifier.setProfanityThreshold(1.3);
        expect(notifier.state.profanityThreshold, equals(1.0));
      });
    });

    group('setAllThresholds', () {
      test('should update all thresholds at once', () {
        notifier.setAllThresholds(
          nsfw: 0.3,
          violence: 0.4,
          blood: 0.5,
          weapons: 0.6,
          profanity: 0.7,
        );

        expect(notifier.state.nsfwThreshold, equals(0.3));
        expect(notifier.state.violenceThreshold, equals(0.4));
        expect(notifier.state.bloodThreshold, equals(0.5));
        expect(notifier.state.weaponsThreshold, equals(0.6));
        expect(notifier.state.profanityThreshold, equals(0.7));
      });

      test('should only update specified thresholds', () {
        notifier.setAllThresholds(nsfw: 0.9, violence: 0.85);

        expect(notifier.state.nsfwThreshold, equals(0.9));
        expect(notifier.state.violenceThreshold, equals(0.85));
        expect(notifier.state.bloodThreshold, equals(0.6)); // Default unchanged
        expect(notifier.state.weaponsThreshold, equals(0.6)); // Default unchanged
        expect(notifier.state.profanityThreshold, equals(0.8)); // Default unchanged
      });

      test('should clamp all thresholds to 0-1 range', () {
        notifier.setAllThresholds(
          nsfw: -0.5,
          violence: 1.5,
          blood: -1,
          weapons: 2,
          profanity: 10,
        );

        expect(notifier.state.nsfwThreshold, equals(0.0));
        expect(notifier.state.violenceThreshold, equals(1.0));
        expect(notifier.state.bloodThreshold, equals(0.0));
        expect(notifier.state.weaponsThreshold, equals(1.0));
        expect(notifier.state.profanityThreshold, equals(1.0));
      });
    });

    group('applyStrictSettings', () {
      test('should apply correct strict thresholds', () {
        notifier.applyStrictSettings();

        expect(notifier.state.nsfwThreshold, equals(0.4));
        expect(notifier.state.violenceThreshold, equals(0.4));
        expect(notifier.state.bloodThreshold, equals(0.4));
        expect(notifier.state.weaponsThreshold, equals(0.4));
        expect(notifier.state.profanityThreshold, equals(0.7));
        expect(notifier.state.frameSamplingRate, equals(3));
      });

      test('should preserve non-threshold settings when applying strict', () {
        notifier
          ..setAsrModel('whisper-large')
          ..setVisualModel(HuggingFaceModelType.nsfw, 'custom-model')
          ..applyStrictSettings();

        expect(notifier.state.asrModelId, equals('whisper-large'));
        expect(
          notifier.state.visualModelIds[HuggingFaceModelType.nsfw],
          equals('custom-model'),
        );
        expect(notifier.state.nsfwThreshold, equals(0.4));
      });
    });

    group('applyPermissiveSettings', () {
      test('should apply correct permissive thresholds', () {
        notifier.applyPermissiveSettings();

        expect(notifier.state.nsfwThreshold, equals(0.8));
        expect(notifier.state.violenceThreshold, equals(0.8));
        expect(notifier.state.bloodThreshold, equals(0.8));
        expect(notifier.state.weaponsThreshold, equals(0.8));
        expect(notifier.state.profanityThreshold, equals(0.9));
        expect(notifier.state.frameSamplingRate, equals(10));
      });

      test('should preserve non-threshold settings when applying permissive', () {
        notifier
          ..setAsrModel('whisper-medium')
          ..setAsrLanguage('fr')
          ..applyPermissiveSettings();

        expect(notifier.state.asrModelId, equals('whisper-medium'));
        expect(notifier.state.asrLanguage, equals('fr'));
        expect(notifier.state.nsfwThreshold, equals(0.8));
      });
    });

    group('resetToDefaults', () {
      test('should restore all settings to initial state', () {
        // Modify multiple settings, then reset
        notifier
          ..setAsrModel('whisper-large')
          ..setVisualModel(HuggingFaceModelType.nsfw, 'custom-model')
          ..setNsfwThreshold(0.9)
          ..setViolenceThreshold(0.85)
          ..setBloodThreshold(0.75)
          ..setWeaponsThreshold(0.65)
          ..setProfanityThreshold(0.95)
          ..setNsfwEnabled(enabled: false)
          ..setViolenceEnabled(enabled: false)
          ..setFrameSamplingRate(15)
          ..setAsrLanguage('es')
          ..setGpuAcceleration(enabled: false)
          ..setCpuThreads(16)
          ..resetToDefaults();

        // Verify all settings are back to defaults
        expect(notifier.state.asrModelId, equals('whisper-small'));
        expect(notifier.state.visualModelIds, isEmpty);
        expect(notifier.state.nsfwThreshold, equals(0.6));
        expect(notifier.state.violenceThreshold, equals(0.6));
        expect(notifier.state.bloodThreshold, equals(0.6));
        expect(notifier.state.weaponsThreshold, equals(0.6));
        expect(notifier.state.profanityThreshold, equals(0.8));
        expect(notifier.state.enableNsfw, isTrue);
        expect(notifier.state.enableViolence, isTrue);
        expect(notifier.state.enableBlood, isTrue);
        expect(notifier.state.enableWeapons, isTrue);
        expect(notifier.state.enableProfanity, isTrue);
        expect(notifier.state.frameSamplingRate, equals(5));
        expect(notifier.state.asrLanguage, equals('en'));
        expect(notifier.state.useGpuAcceleration, isTrue);
        expect(notifier.state.cpuThreads, equals(4));
      });
    });

    group('enable/disable methods', () {
      test('setNsfwEnabled should update nsfw enabled state', () {
        notifier.setNsfwEnabled(enabled: false);
        expect(notifier.state.enableNsfw, isFalse);

        notifier.setNsfwEnabled(enabled: true);
        expect(notifier.state.enableNsfw, isTrue);
      });

      test('setViolenceEnabled should update violence enabled state', () {
        notifier.setViolenceEnabled(enabled: false);
        expect(notifier.state.enableViolence, isFalse);
      });

      test('setBloodEnabled should update blood enabled state', () {
        notifier.setBloodEnabled(enabled: false);
        expect(notifier.state.enableBlood, isFalse);
      });

      test('setWeaponsEnabled should update weapons enabled state', () {
        notifier.setWeaponsEnabled(enabled: false);
        expect(notifier.state.enableWeapons, isFalse);
      });

      test('setProfanityEnabled should update profanity enabled state', () {
        notifier.setProfanityEnabled(enabled: false);
        expect(notifier.state.enableProfanity, isFalse);
      });

      test('setAllVisualEnabled should enable/disable all visual types', () {
        notifier.setAllVisualEnabled(enabled: false);

        expect(notifier.state.enableNsfw, isFalse);
        expect(notifier.state.enableViolence, isFalse);
        expect(notifier.state.enableBlood, isFalse);
        expect(notifier.state.enableWeapons, isFalse);

        notifier.setAllVisualEnabled(enabled: true);

        expect(notifier.state.enableNsfw, isTrue);
        expect(notifier.state.enableViolence, isTrue);
        expect(notifier.state.enableBlood, isTrue);
        expect(notifier.state.enableWeapons, isTrue);
      });
    });

    group('performance methods', () {
      test('setFrameSamplingRate should update rate', () {
        notifier.setFrameSamplingRate(10);

        expect(notifier.state.frameSamplingRate, equals(10));
      });

      test('setFrameSamplingRate should clamp to minimum 1', () {
        notifier.setFrameSamplingRate(0);

        expect(notifier.state.frameSamplingRate, equals(1));
      });

      test('setFrameSamplingRate should clamp to maximum 30', () {
        notifier.setFrameSamplingRate(50);

        expect(notifier.state.frameSamplingRate, equals(30));
      });

      test('setGpuAcceleration should update gpu setting', () {
        notifier.setGpuAcceleration(enabled: false);
        expect(notifier.state.useGpuAcceleration, isFalse);

        notifier.setGpuAcceleration(enabled: true);
        expect(notifier.state.useGpuAcceleration, isTrue);
      });

      test('setCpuThreads should update thread count', () {
        notifier.setCpuThreads(8);

        expect(notifier.state.cpuThreads, equals(8));
      });

      test('setCpuThreads should clamp to minimum 1', () {
        notifier.setCpuThreads(0);

        expect(notifier.state.cpuThreads, equals(1));
      });

      test('setCpuThreads should clamp to maximum 32', () {
        notifier.setCpuThreads(64);

        expect(notifier.state.cpuThreads, equals(32));
      });
    });

    group('setAsrLanguage', () {
      test('should update asr language', () {
        notifier.setAsrLanguage('es');

        expect(notifier.state.asrLanguage, equals('es'));
      });

      test('should support various language codes', () {
        final languages = ['en', 'es', 'fr', 'de', 'zh', 'ja', 'ar'];
        for (final lang in languages) {
          notifier.setAsrLanguage(lang);
          expect(notifier.state.asrLanguage, equals(lang));
        }
      });
    });
  });
}
