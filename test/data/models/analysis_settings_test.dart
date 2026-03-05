import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:kidslens_video_editor/data/models/analysis_settings.dart';

void main() {
  group('ModelConfig', () {
    test('defaults are ASR-only aligned', () {
      final config = ModelConfig.defaults();
      expect(config.asrModelId, 'whisper-base');
      expect(config.asrLanguage, 'en');
    });

    test('json round-trip', () {
      const original = ModelConfig(asrModelId: 'whisper-small');
      final restored = ModelConfig.fromJson(
        jsonDecode(jsonEncode(original.toJson())) as Map<String, dynamic>,
      );
      expect(restored, original);
    });

    group('validation', () {
      test('validates successfully with correct settings', () {
        const config = ModelConfig(
          asrModelId: 'whisper-base',
          useGpu: true,
          gpuDeviceIndex: 0,
          onnxExecutionProvider: 'cuda',
        );
        expect(config.validate(), isEmpty);
        expect(config.isValid, isTrue);
      });

      test('rejects negative GPU device index', () {
        const config = ModelConfig(
          asrModelId: 'whisper-base',
          useGpu: true,
          gpuDeviceIndex: -1,
        );
        final issues = config.validate();
        expect(issues, contains('GPU device index must be non-negative'));
        expect(config.isValid, isFalse);
      });

      test('rejects negative GPU device index (alternate case)', () {
        const config = ModelConfig(
          asrModelId: 'whisper-base',
          useGpu: true,
          gpuDeviceIndex: -2,
        );
        final issues = config.validate();
        expect(issues, contains('GPU device index must be non-negative'));
        expect(config.isValid, isFalse);
      });

      test('rejects GPU enabled with CPU execution provider', () {
        const config = ModelConfig(
          asrModelId: 'whisper-base',
          useGpu: true,
          onnxExecutionProvider: 'cpu',
        );
        final issues = config.validate();
        expect(
          issues,
          contains('Cannot enable GPU with CPU execution provider'),
        );
        expect(config.isValid, isFalse);
      });

      test('rejects invalid execution provider', () {
        const config = ModelConfig(
          asrModelId: 'whisper-base',
          onnxExecutionProvider: 'invalid_provider',
        );
        final issues = config.validate();
        expect(
          issues,
          contains('Invalid ONNX execution provider: invalid_provider'),
        );
        expect(config.isValid, isFalse);
      });

      test('accepts all valid execution providers', () {
        const validProviders = ['auto', 'cuda', 'directml', 'coreml', 'cpu'];
        for (final provider in validProviders) {
          final config = ModelConfig(
            asrModelId: 'whisper-base',
            useGpu: provider != 'cpu',
            onnxExecutionProvider: provider,
          );
          expect(config.isValid, isTrue, reason: 'Failed for $provider');
        }
      });

      test('deprecated fields are still accessible', () {
        const config = ModelConfig(
          asrModelId: 'whisper-base',
          // ignore: deprecated_member_use_from_same_package
          useGpu: false,
          // ignore: deprecated_member_use_from_same_package
          gpuDeviceIndex: 3,
        );
        // ignore: deprecated_member_use_from_same_package
        expect(config.useGpu, false);
        // ignore: deprecated_member_use_from_same_package
        expect(config.gpuDeviceIndex, 3);
      });
    });
  });

  group('AnalysisSettings', () {
    test('defaults enable audio + visual detection', () {
      final settings = AnalysisSettings.defaults();
      expect(settings.hasVisualDetection, isTrue);
      expect(settings.hasAudioDetection, isTrue);
    });

    test('videoOnly keeps visual detections enabled and disables audio', () {
      final settings = AnalysisSettings.videoOnly();
      expect(settings.hasVisualDetection, isTrue);
      expect(settings.hasAudioDetection, isFalse);
      expect(settings.hasAnyDetection, isTrue);
    });

    test('json round-trip', () {
      final original = AnalysisSettings.defaults().copyWith(
        modelConfig: const ModelConfig(asrModelId: 'whisper-small'),
      );
      final restored = AnalysisSettings.fromJson(
        jsonDecode(jsonEncode(original.toJson())) as Map<String, dynamic>,
      );
      expect(restored.modelConfig.asrModelId, 'whisper-small');
      expect(restored.hasVisualDetection, isTrue);
    });
  });
}
