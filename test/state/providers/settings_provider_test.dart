import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kidslens_video_editor/state/providers/settings_provider.dart';

void main() {
  group('DetectionThresholds', () {
    group('default constructor', () {
      test('should have correct default values', () {
        const thresholds = DetectionThresholds();

        expect(thresholds.nsfwThreshold, equals(0.6));
        expect(thresholds.violenceThreshold, equals(0.6));
        expect(thresholds.bloodThreshold, equals(0.6));
        expect(thresholds.weaponsThreshold, equals(0.6));
        expect(thresholds.profanityConfidence, equals(0.8));
      });
    });

    group('strict factory', () {
      test('should have correct strict values', () {
        final thresholds = DetectionThresholds.strict();

        expect(thresholds.nsfwThreshold, equals(0.4));
        expect(thresholds.violenceThreshold, equals(0.4));
        expect(thresholds.bloodThreshold, equals(0.4));
        expect(thresholds.weaponsThreshold, equals(0.4));
        expect(thresholds.profanityConfidence, equals(0.7));
      });

      test('strict thresholds should be lower than default', () {
        const defaultThresholds = DetectionThresholds();
        final strictThresholds = DetectionThresholds.strict();

        expect(
          strictThresholds.nsfwThreshold,
          lessThan(defaultThresholds.nsfwThreshold),
        );
        expect(
          strictThresholds.violenceThreshold,
          lessThan(defaultThresholds.violenceThreshold),
        );
        expect(
          strictThresholds.bloodThreshold,
          lessThan(defaultThresholds.bloodThreshold),
        );
        expect(
          strictThresholds.weaponsThreshold,
          lessThan(defaultThresholds.weaponsThreshold),
        );
        expect(
          strictThresholds.profanityConfidence,
          lessThan(defaultThresholds.profanityConfidence),
        );
      });
    });

    group('permissive factory', () {
      test('should have correct permissive values', () {
        final thresholds = DetectionThresholds.permissive();

        expect(thresholds.nsfwThreshold, equals(0.8));
        expect(thresholds.violenceThreshold, equals(0.8));
        expect(thresholds.bloodThreshold, equals(0.8));
        expect(thresholds.weaponsThreshold, equals(0.8));
        expect(thresholds.profanityConfidence, equals(0.9));
      });

      test('permissive thresholds should be higher than default', () {
        const defaultThresholds = DetectionThresholds();
        final permissiveThresholds = DetectionThresholds.permissive();

        expect(
          permissiveThresholds.nsfwThreshold,
          greaterThan(defaultThresholds.nsfwThreshold),
        );
        expect(
          permissiveThresholds.violenceThreshold,
          greaterThan(defaultThresholds.violenceThreshold),
        );
        expect(
          permissiveThresholds.bloodThreshold,
          greaterThan(defaultThresholds.bloodThreshold),
        );
        expect(
          permissiveThresholds.weaponsThreshold,
          greaterThan(defaultThresholds.weaponsThreshold),
        );
        expect(
          permissiveThresholds.profanityConfidence,
          greaterThan(defaultThresholds.profanityConfidence),
        );
      });

      test('permissive thresholds should be higher than strict', () {
        final strictThresholds = DetectionThresholds.strict();
        final permissiveThresholds = DetectionThresholds.permissive();

        expect(
          permissiveThresholds.nsfwThreshold,
          greaterThan(strictThresholds.nsfwThreshold),
        );
        expect(
          permissiveThresholds.violenceThreshold,
          greaterThan(strictThresholds.violenceThreshold),
        );
        expect(
          permissiveThresholds.bloodThreshold,
          greaterThan(strictThresholds.bloodThreshold),
        );
        expect(
          permissiveThresholds.weaponsThreshold,
          greaterThan(strictThresholds.weaponsThreshold),
        );
        expect(
          permissiveThresholds.profanityConfidence,
          greaterThan(strictThresholds.profanityConfidence),
        );
      });
    });

    group('copyWith', () {
      test('should copy with new nsfwThreshold', () {
        const thresholds = DetectionThresholds();
        final newThresholds = thresholds.copyWith(nsfwThreshold: 0.9);

        expect(newThresholds.nsfwThreshold, equals(0.9));
        expect(newThresholds.violenceThreshold, equals(0.6)); // Unchanged
      });

      test('should copy with multiple values', () {
        const thresholds = DetectionThresholds();
        final newThresholds = thresholds.copyWith(
          nsfwThreshold: 0.7,
          violenceThreshold: 0.75,
          bloodThreshold: 0.8,
        );

        expect(newThresholds.nsfwThreshold, equals(0.7));
        expect(newThresholds.violenceThreshold, equals(0.75));
        expect(newThresholds.bloodThreshold, equals(0.8));
        expect(newThresholds.weaponsThreshold, equals(0.6)); // Unchanged
        expect(newThresholds.profanityConfidence, equals(0.8)); // Unchanged
      });
    });

    group('toJson', () {
      test('should serialize all fields correctly', () {
        const thresholds = DetectionThresholds(
          nsfwThreshold: 0.55,
          violenceThreshold: 0.65,
          bloodThreshold: 0.75,
          weaponsThreshold: 0.85,
          profanityConfidence: 0.95,
        );

        final json = thresholds.toJson();

        expect(json['nsfwThreshold'], equals(0.55));
        expect(json['violenceThreshold'], equals(0.65));
        expect(json['bloodThreshold'], equals(0.75));
        expect(json['weaponsThreshold'], equals(0.85));
        expect(json['profanityConfidence'], equals(0.95));
      });
    });

    group('fromJson', () {
      test('should deserialize all fields correctly', () {
        final json = <String, dynamic>{
          'nsfwThreshold': 0.45,
          'violenceThreshold': 0.55,
          'bloodThreshold': 0.65,
          'weaponsThreshold': 0.75,
          'profanityConfidence': 0.85,
        };

        final thresholds = DetectionThresholds.fromJson(json);

        expect(thresholds.nsfwThreshold, equals(0.45));
        expect(thresholds.violenceThreshold, equals(0.55));
        expect(thresholds.bloodThreshold, equals(0.65));
        expect(thresholds.weaponsThreshold, equals(0.75));
        expect(thresholds.profanityConfidence, equals(0.85));
      });

      test('should use defaults for missing fields', () {
        final json = <String, dynamic>{};

        final thresholds = DetectionThresholds.fromJson(json);

        expect(thresholds.nsfwThreshold, equals(0.6));
        expect(thresholds.violenceThreshold, equals(0.6));
        expect(thresholds.bloodThreshold, equals(0.6));
        expect(thresholds.weaponsThreshold, equals(0.6));
        expect(thresholds.profanityConfidence, equals(0.8));
      });

      test('should handle partial json', () {
        final json = <String, dynamic>{
          'nsfwThreshold': 0.9,
          'violenceThreshold': 0.85,
        };

        final thresholds = DetectionThresholds.fromJson(json);

        expect(thresholds.nsfwThreshold, equals(0.9));
        expect(thresholds.violenceThreshold, equals(0.85));
        expect(thresholds.bloodThreshold, equals(0.6)); // Default
        expect(thresholds.weaponsThreshold, equals(0.6)); // Default
        expect(thresholds.profanityConfidence, equals(0.8)); // Default
      });
    });

    group('roundtrip serialization', () {
      test('should maintain values through toJson/fromJson cycle', () {
        const original = DetectionThresholds(
          nsfwThreshold: 0.35,
          violenceThreshold: 0.45,
          bloodThreshold: 0.55,
          weaponsThreshold: 0.65,
          profanityConfidence: 0.75,
        );

        final json = original.toJson();
        final restored = DetectionThresholds.fromJson(json);

        expect(restored.nsfwThreshold, equals(original.nsfwThreshold));
        expect(restored.violenceThreshold, equals(original.violenceThreshold));
        expect(restored.bloodThreshold, equals(original.bloodThreshold));
        expect(restored.weaponsThreshold, equals(original.weaponsThreshold));
        expect(
          restored.profanityConfidence,
          equals(original.profanityConfidence),
        );
      });
    });
  });

  group('ExportQuality', () {
    test('should have all expected values', () {
      expect(ExportQuality.values, contains(ExportQuality.low));
      expect(ExportQuality.values, contains(ExportQuality.medium));
      expect(ExportQuality.values, contains(ExportQuality.high));
      expect(ExportQuality.values, contains(ExportQuality.ultra));
    });

    test('low quality should have correct height', () {
      expect(ExportQuality.low.height, equals(480));
      expect(ExportQuality.low.displayName, equals('Low (480p)'));
    });

    test('medium quality should have correct height', () {
      expect(ExportQuality.medium.height, equals(720));
      expect(ExportQuality.medium.displayName, equals('Medium (720p)'));
    });

    test('high quality should have correct height', () {
      expect(ExportQuality.high.height, equals(1080));
      expect(ExportQuality.high.displayName, equals('High (1080p)'));
    });

    test('ultra quality should have correct height', () {
      expect(ExportQuality.ultra.height, equals(2160));
      expect(ExportQuality.ultra.displayName, equals('Ultra (4K)'));
    });

    test('heights should be in ascending order', () {
      expect(
        ExportQuality.low.height,
        lessThan(ExportQuality.medium.height),
      );
      expect(
        ExportQuality.medium.height,
        lessThan(ExportQuality.high.height),
      );
      expect(
        ExportQuality.high.height,
        lessThan(ExportQuality.ultra.height),
      );
    });
  });

  group('ExportFormat', () {
    test('should have all expected values', () {
      expect(ExportFormat.values, contains(ExportFormat.mp4));
      expect(ExportFormat.values, contains(ExportFormat.webm));
      expect(ExportFormat.values, contains(ExportFormat.mov));
    });

    test('mp4 format should have correct extension', () {
      expect(ExportFormat.mp4.extension, equals('mp4'));
      expect(ExportFormat.mp4.displayName, equals('MP4 (H.264)'));
    });

    test('webm format should have correct extension', () {
      expect(ExportFormat.webm.extension, equals('webm'));
      expect(ExportFormat.webm.displayName, equals('WebM (VP9)'));
    });

    test('mov format should have correct extension', () {
      expect(ExportFormat.mov.extension, equals('mov'));
      expect(ExportFormat.mov.displayName, equals('MOV (ProRes)'));
    });
  });

  group('SettingsState', () {
    group('creation', () {
      test('should create with default values', () {
        final state = SettingsState();

        expect(state.selectedLanguage, isNull);
        expect(state.themeMode, equals(ThemeMode.system));
        expect(state.useDarkTheme, isFalse);
        expect(state.showOnboarding, isTrue);
        expect(state.modelCachePath, isNull);
        expect(state.exportPath, isNull);
        expect(state.defaultExportQuality, equals(ExportQuality.high));
        expect(state.defaultExportFormat, equals(ExportFormat.mp4));
        expect(state.autoSaveInterval, equals(const Duration(minutes: 5)));
        expect(state.detectionThresholds, isNotNull);
      });

      test('should create with custom values', () {
        final state = SettingsState(
          selectedLanguage: 'es',
          themeMode: ThemeMode.dark,
          useDarkTheme: true,
          showOnboarding: false,
          modelCachePath: '/custom/path',
          exportPath: '/export/path',
          defaultExportQuality: ExportQuality.ultra,
          defaultExportFormat: ExportFormat.mov,
          autoSaveInterval: const Duration(minutes: 10),
          detectionThresholds: DetectionThresholds.strict(),
        );

        expect(state.selectedLanguage, equals('es'));
        expect(state.themeMode, equals(ThemeMode.dark));
        expect(state.useDarkTheme, isTrue);
        expect(state.showOnboarding, isFalse);
        expect(state.modelCachePath, equals('/custom/path'));
        expect(state.exportPath, equals('/export/path'));
        expect(state.defaultExportQuality, equals(ExportQuality.ultra));
        expect(state.defaultExportFormat, equals(ExportFormat.mov));
        expect(state.autoSaveInterval, equals(const Duration(minutes: 10)));
      });
    });

    group('copyWith', () {
      test('should copy with new themeMode', () {
        final state = SettingsState();
        final newState = state.copyWith(themeMode: ThemeMode.dark);

        expect(newState.themeMode, equals(ThemeMode.dark));
        expect(state.themeMode, equals(ThemeMode.system)); // Original unchanged
      });

      test('should copy with new defaultExportQuality', () {
        final state = SettingsState();
        final newState = state.copyWith(
          defaultExportQuality: ExportQuality.ultra,
        );

        expect(newState.defaultExportQuality, equals(ExportQuality.ultra));
      });

      test('should copy with new selectedLanguage', () {
        final state = SettingsState();
        final newState = state.copyWith(selectedLanguage: 'fr');

        expect(newState.selectedLanguage, equals('fr'));
      });

      test('should copy with multiple values', () {
        final state = SettingsState();
        final newState = state.copyWith(
          themeMode: ThemeMode.light,
          useDarkTheme: false,
          showOnboarding: false,
          defaultExportQuality: ExportQuality.medium,
          defaultExportFormat: ExportFormat.webm,
        );

        expect(newState.themeMode, equals(ThemeMode.light));
        expect(newState.useDarkTheme, isFalse);
        expect(newState.showOnboarding, isFalse);
        expect(newState.defaultExportQuality, equals(ExportQuality.medium));
        expect(newState.defaultExportFormat, equals(ExportFormat.webm));
      });
    });

    group('toJson', () {
      test('should serialize all fields correctly', () {
        final state = SettingsState(
          selectedLanguage: 'de',
          themeMode: ThemeMode.dark,
          useDarkTheme: true,
          showOnboarding: false,
          modelCachePath: '/models',
          exportPath: '/exports',
          defaultExportQuality: ExportQuality.ultra,
          defaultExportFormat: ExportFormat.mov,
          autoSaveInterval: const Duration(minutes: 10),
          detectionThresholds: const DetectionThresholds(
            nsfwThreshold: 0.7,
            violenceThreshold: 0.65,
          ),
        );

        final json = state.toJson();

        expect(json['selectedLanguage'], equals('de'));
        expect(json['themeMode'], equals(ThemeMode.dark.index));
        expect(json['useDarkTheme'], isTrue);
        expect(json['showOnboarding'], isFalse);
        expect(json['modelCachePath'], equals('/models'));
        expect(json['exportPath'], equals('/exports'));
        expect(json['defaultExportQuality'], equals(ExportQuality.ultra.index));
        expect(json['defaultExportFormat'], equals(ExportFormat.mov.index));
        expect(json['autoSaveIntervalMinutes'], equals(10));
        expect(json['detectionThresholds'], isA<Map<String, dynamic>>());
      });
    });

    group('fromJson', () {
      test('should deserialize all fields correctly', () {
        final json = <String, dynamic>{
          'selectedLanguage': 'ja',
          'themeMode': ThemeMode.light.index,
          'useDarkTheme': false,
          'showOnboarding': false,
          'modelCachePath': '/models/path',
          'exportPath': '/export/path',
          'defaultExportQuality': ExportQuality.medium.index,
          'defaultExportFormat': ExportFormat.webm.index,
          'autoSaveIntervalMinutes': 15,
          'detectionThresholds': {
            'nsfwThreshold': 0.5,
            'violenceThreshold': 0.55,
          },
        };

        final state = SettingsState.fromJson(json);

        expect(state.selectedLanguage, equals('ja'));
        expect(state.themeMode, equals(ThemeMode.light));
        expect(state.useDarkTheme, isFalse);
        expect(state.showOnboarding, isFalse);
        expect(state.modelCachePath, equals('/models/path'));
        expect(state.exportPath, equals('/export/path'));
        expect(state.defaultExportQuality, equals(ExportQuality.medium));
        expect(state.defaultExportFormat, equals(ExportFormat.webm));
        expect(state.autoSaveInterval, equals(const Duration(minutes: 15)));
        expect(state.detectionThresholds.nsfwThreshold, equals(0.5));
        expect(state.detectionThresholds.violenceThreshold, equals(0.55));
      });

      test('should use defaults for missing fields', () {
        final json = <String, dynamic>{};

        final state = SettingsState.fromJson(json);

        expect(state.selectedLanguage, isNull);
        expect(state.themeMode, equals(ThemeMode.system));
        expect(state.useDarkTheme, isFalse);
        expect(state.showOnboarding, isTrue);
        expect(state.modelCachePath, isNull);
        expect(state.exportPath, isNull);
        expect(state.defaultExportQuality, equals(ExportQuality.high));
        expect(state.defaultExportFormat, equals(ExportFormat.mp4));
        expect(state.autoSaveInterval, equals(const Duration(minutes: 5)));
      });

      test('should handle null detectionThresholds', () {
        final json = <String, dynamic>{
          'detectionThresholds': null,
        };

        final state = SettingsState.fromJson(json);

        expect(state.detectionThresholds, isNotNull);
        expect(state.detectionThresholds.nsfwThreshold, equals(0.6));
      });
    });

    group('roundtrip serialization', () {
      test('should maintain state through toJson/fromJson cycle', () {
        final original = SettingsState(
          selectedLanguage: 'ko',
          themeMode: ThemeMode.dark,
          useDarkTheme: true,
          showOnboarding: false,
          modelCachePath: '/custom/models',
          exportPath: '/custom/exports',
          defaultExportQuality: ExportQuality.low,
          defaultExportFormat: ExportFormat.webm,
          autoSaveInterval: const Duration(minutes: 3),
          detectionThresholds: const DetectionThresholds(
            nsfwThreshold: 0.35,
            violenceThreshold: 0.45,
            bloodThreshold: 0.55,
            weaponsThreshold: 0.65,
            profanityConfidence: 0.75,
          ),
        );

        final json = original.toJson();
        final restored = SettingsState.fromJson(json);

        expect(restored.selectedLanguage, equals(original.selectedLanguage));
        expect(restored.themeMode, equals(original.themeMode));
        expect(restored.useDarkTheme, equals(original.useDarkTheme));
        expect(restored.showOnboarding, equals(original.showOnboarding));
        expect(restored.modelCachePath, equals(original.modelCachePath));
        expect(restored.exportPath, equals(original.exportPath));
        expect(
          restored.defaultExportQuality,
          equals(original.defaultExportQuality),
        );
        expect(
          restored.defaultExportFormat,
          equals(original.defaultExportFormat),
        );
        expect(restored.autoSaveInterval, equals(original.autoSaveInterval));
        expect(
          restored.detectionThresholds.nsfwThreshold,
          equals(original.detectionThresholds.nsfwThreshold),
        );
      });
    });
  });

  group('SettingsNotifier', () {
    late ProviderContainer container;
    late SettingsNotifier notifier;

    setUp(() {
      container = ProviderContainer();
      notifier = container.read(settingsNotifierProvider.notifier);
    });

    tearDown(() {
      container.dispose();
    });

    group('initialization', () {
      test('should start with default state', () {
        expect(notifier.state.themeMode, equals(ThemeMode.system));
        expect(notifier.state.defaultExportQuality, equals(ExportQuality.high));
        expect(notifier.state.defaultExportFormat, equals(ExportFormat.mp4));
      });
    });

    group('setThemeMode', () {
      test('should update theme mode to dark', () {
        notifier.setThemeMode(ThemeMode.dark);

        expect(notifier.state.themeMode, equals(ThemeMode.dark));
        expect(notifier.state.useDarkTheme, isTrue);
      });

      test('should update theme mode to light', () {
        notifier.setThemeMode(ThemeMode.light);

        expect(notifier.state.themeMode, equals(ThemeMode.light));
        expect(notifier.state.useDarkTheme, isFalse);
      });

      test('should update theme mode to system', () {
        notifier
          ..setThemeMode(ThemeMode.dark)
          ..setThemeMode(ThemeMode.system);

        expect(notifier.state.themeMode, equals(ThemeMode.system));
      });
    });

    group('setDarkTheme', () {
      test('should set dark theme and update themeMode', () {
        notifier.setDarkTheme(useDark: true);

        expect(notifier.state.useDarkTheme, isTrue);
        expect(notifier.state.themeMode, equals(ThemeMode.dark));
      });

      test('should set light theme and update themeMode', () {
        notifier.setDarkTheme(useDark: false);

        expect(notifier.state.useDarkTheme, isFalse);
        expect(notifier.state.themeMode, equals(ThemeMode.light));
      });
    });

    group('setDefaultExportQuality', () {
      test('should update default export quality to low', () {
        notifier.setDefaultExportQuality(ExportQuality.low);

        expect(notifier.state.defaultExportQuality, equals(ExportQuality.low));
      });

      test('should update default export quality to medium', () {
        notifier.setDefaultExportQuality(ExportQuality.medium);

        expect(
          notifier.state.defaultExportQuality,
          equals(ExportQuality.medium),
        );
      });

      test('should update default export quality to ultra', () {
        notifier.setDefaultExportQuality(ExportQuality.ultra);

        expect(
          notifier.state.defaultExportQuality,
          equals(ExportQuality.ultra),
        );
      });

      test('should preserve other settings when updating quality', () {
        notifier
          ..setThemeMode(ThemeMode.dark)
          ..setDefaultExportFormat(ExportFormat.mov)
          ..setDefaultExportQuality(ExportQuality.low);

        expect(notifier.state.defaultExportQuality, equals(ExportQuality.low));
        expect(notifier.state.themeMode, equals(ThemeMode.dark));
        expect(notifier.state.defaultExportFormat, equals(ExportFormat.mov));
      });
    });

    group('setDefaultExportFormat', () {
      test('should update default export format to mp4', () {
        notifier.setDefaultExportFormat(ExportFormat.mp4);

        expect(notifier.state.defaultExportFormat, equals(ExportFormat.mp4));
      });

      test('should update default export format to webm', () {
        notifier.setDefaultExportFormat(ExportFormat.webm);

        expect(notifier.state.defaultExportFormat, equals(ExportFormat.webm));
      });

      test('should update default export format to mov', () {
        notifier.setDefaultExportFormat(ExportFormat.mov);

        expect(notifier.state.defaultExportFormat, equals(ExportFormat.mov));
      });
    });

    group('setLanguage', () {
      test('should update selected language', () {
        notifier.setLanguage('es');

        expect(notifier.state.selectedLanguage, equals('es'));
      });

      test('should support various language codes', () {
        final languages = ['en', 'es', 'fr', 'de', 'zh', 'ja', 'ar', 'ko'];
        for (final lang in languages) {
          notifier.setLanguage(lang);
          expect(notifier.state.selectedLanguage, equals(lang));
        }
      });
    });

    group('setOnboardingComplete', () {
      test('should mark onboarding as complete', () {
        expect(notifier.state.showOnboarding, isTrue);

        notifier.setOnboardingComplete();

        expect(notifier.state.showOnboarding, isFalse);
      });
    });

    group('setModelCachePath', () {
      test('should update model cache path', () {
        notifier.setModelCachePath('/custom/cache/path');

        expect(notifier.state.modelCachePath, equals('/custom/cache/path'));
      });
    });

    group('setExportPath', () {
      test('should update export path', () {
        notifier.setExportPath('/custom/export/path');

        expect(notifier.state.exportPath, equals('/custom/export/path'));
      });
    });

    group('setAutoSaveInterval', () {
      test('should update auto save interval', () {
        notifier.setAutoSaveInterval(const Duration(minutes: 10));

        expect(
          notifier.state.autoSaveInterval,
          equals(const Duration(minutes: 10)),
        );
      });

      test('should support various intervals', () {
        final intervals = [
          const Duration(minutes: 1),
          const Duration(minutes: 5),
          const Duration(minutes: 15),
          const Duration(minutes: 30),
        ];

        for (final interval in intervals) {
          notifier.setAutoSaveInterval(interval);
          expect(notifier.state.autoSaveInterval, equals(interval));
        }
      });
    });

    group('setDetectionThresholds', () {
      test('should update detection thresholds', () {
        final thresholds = DetectionThresholds.strict();

        notifier.setDetectionThresholds(thresholds);

        expect(notifier.state.detectionThresholds.nsfwThreshold, equals(0.4));
        expect(
          notifier.state.detectionThresholds.violenceThreshold,
          equals(0.4),
        );
      });

      test('should replace entire thresholds object', () {
        const customThresholds = DetectionThresholds(
          nsfwThreshold: 0.25,
          violenceThreshold: 0.35,
          bloodThreshold: 0.45,
          weaponsThreshold: 0.55,
          profanityConfidence: 0.65,
        );

        notifier.setDetectionThresholds(customThresholds);

        expect(
          notifier.state.detectionThresholds.nsfwThreshold,
          equals(0.25),
        );
        expect(
          notifier.state.detectionThresholds.violenceThreshold,
          equals(0.35),
        );
        expect(
          notifier.state.detectionThresholds.bloodThreshold,
          equals(0.45),
        );
        expect(
          notifier.state.detectionThresholds.weaponsThreshold,
          equals(0.55),
        );
        expect(
          notifier.state.detectionThresholds.profanityConfidence,
          equals(0.65),
        );
      });
    });

    group('updateNsfwThreshold', () {
      test('should update nsfw threshold', () {
        notifier.updateNsfwThreshold(0.75);

        expect(notifier.state.detectionThresholds.nsfwThreshold, equals(0.75));
      });

      test('should clamp nsfw threshold to 0-1 range', () {
        notifier.updateNsfwThreshold(-0.5);
        expect(notifier.state.detectionThresholds.nsfwThreshold, equals(0.0));

        notifier.updateNsfwThreshold(1.5);
        expect(notifier.state.detectionThresholds.nsfwThreshold, equals(1.0));
      });
    });

    group('updateViolenceThreshold', () {
      test('should update violence threshold', () {
        notifier.updateViolenceThreshold(0.65);

        expect(
          notifier.state.detectionThresholds.violenceThreshold,
          equals(0.65),
        );
      });

      test('should clamp violence threshold to 0-1 range', () {
        notifier.updateViolenceThreshold(-1);
        expect(
          notifier.state.detectionThresholds.violenceThreshold,
          equals(0.0),
        );

        notifier.updateViolenceThreshold(2);
        expect(
          notifier.state.detectionThresholds.violenceThreshold,
          equals(1.0),
        );
      });
    });

    group('updateBloodThreshold', () {
      test('should update blood threshold', () {
        notifier.updateBloodThreshold(0.55);

        expect(
          notifier.state.detectionThresholds.bloodThreshold,
          equals(0.55),
        );
      });

      test('should clamp blood threshold to 0-1 range', () {
        notifier.updateBloodThreshold(-0.2);
        expect(notifier.state.detectionThresholds.bloodThreshold, equals(0.0));

        notifier.updateBloodThreshold(1.2);
        expect(notifier.state.detectionThresholds.bloodThreshold, equals(1.0));
      });
    });

    group('updateWeaponsThreshold', () {
      test('should update weapons threshold', () {
        notifier.updateWeaponsThreshold(0.45);

        expect(
          notifier.state.detectionThresholds.weaponsThreshold,
          equals(0.45),
        );
      });

      test('should clamp weapons threshold to 0-1 range', () {
        notifier.updateWeaponsThreshold(-0.3);
        expect(
          notifier.state.detectionThresholds.weaponsThreshold,
          equals(0.0),
        );

        notifier.updateWeaponsThreshold(1.3);
        expect(
          notifier.state.detectionThresholds.weaponsThreshold,
          equals(1.0),
        );
      });
    });

    group('updateProfanityConfidence', () {
      test('should update profanity confidence', () {
        notifier.updateProfanityConfidence(0.85);

        expect(
          notifier.state.detectionThresholds.profanityConfidence,
          equals(0.85),
        );
      });

      test('should clamp profanity confidence to 0-1 range', () {
        notifier.updateProfanityConfidence(-0.1);
        expect(
          notifier.state.detectionThresholds.profanityConfidence,
          equals(0.0),
        );

        notifier.updateProfanityConfidence(1.1);
        expect(
          notifier.state.detectionThresholds.profanityConfidence,
          equals(1.0),
        );
      });
    });

    group('resetToDefaults', () {
      test('should reset all settings to defaults', () {
        // Modify all settings, then reset
        notifier
          ..setThemeMode(ThemeMode.dark)
          ..setLanguage('ja')
          ..setOnboardingComplete()
          ..setModelCachePath('/custom/path')
          ..setExportPath('/export/path')
          ..setDefaultExportQuality(ExportQuality.ultra)
          ..setDefaultExportFormat(ExportFormat.mov)
          ..setAutoSaveInterval(const Duration(minutes: 15))
          ..setDetectionThresholds(DetectionThresholds.strict())
          ..resetToDefaults();

        // Verify defaults
        expect(notifier.state.themeMode, equals(ThemeMode.system));
        expect(notifier.state.selectedLanguage, isNull);
        expect(notifier.state.showOnboarding, isTrue);
        expect(notifier.state.modelCachePath, isNull);
        expect(notifier.state.exportPath, isNull);
        expect(notifier.state.defaultExportQuality, equals(ExportQuality.high));
        expect(notifier.state.defaultExportFormat, equals(ExportFormat.mp4));
        expect(
          notifier.state.autoSaveInterval,
          equals(const Duration(minutes: 5)),
        );
        expect(
          notifier.state.detectionThresholds.nsfwThreshold,
          equals(0.6),
        );
      });
    });
  });
}
