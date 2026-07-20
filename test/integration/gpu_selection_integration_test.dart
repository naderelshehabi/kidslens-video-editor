import 'package:flutter_test/flutter_test.dart';
import 'package:kidslens_video_editor/data/models/analysis_settings.dart';

void main() {
  group('GPU Selection Integration', () {
    test('ModelConfig validation accepts valid GPU indices', () {
      const config = ModelConfig(
        asrModelId: 'whisper-base',
        onnxExecutionProvider: 'cuda',
      );

      final issues = config.validate();
      expect(issues, isEmpty);
    });

    test('ModelConfig validation rejects negative GPU indices', () {
      const config = ModelConfig(
        asrModelId: 'whisper-base',
        gpuDeviceIndex: -1,
      );

      final issues = config.validate();
      expect(issues, isNotEmpty);
      expect(issues.first, contains('GPU device index must be non-negative'));
    });

    test('ModelConfig validation rejects invalid execution providers', () {
      const config = ModelConfig(
        asrModelId: 'whisper-base',
        onnxExecutionProvider: 'invalid_provider',
      );

      final issues = config.validate();
      expect(issues, isNotEmpty);
      expect(issues.first, contains('Invalid ONNX execution provider'));
    });

    test('ModelConfig validation rejects CPU provider with GPU enabled', () {
      const config = ModelConfig(
        asrModelId: 'whisper-base',
        onnxExecutionProvider: 'cpu',
      );

      final issues = config.validate();
      expect(issues, isNotEmpty);
      expect(
        issues.first,
        contains('Cannot enable GPU with CPU execution provider'),
      );
    });

    test('ModelConfig validation accepts all valid execution providers', () {
      const validProviders = ['auto', 'cuda', 'directml', 'coreml', 'cpu'];

      for (final provider in validProviders) {
        final config = ModelConfig(
          asrModelId: 'whisper-base',
          onnxExecutionProvider: provider,
          // Disable GPU if provider is CPU to avoid conflict
          useGpu: provider != 'cpu',
        );

        final issues = config.validate();
        expect(issues, isEmpty, reason: 'Provider $provider should be valid');
      }
    });

    test('ModelConfig validation allows GPU disabled', () {
      const config = ModelConfig(
        asrModelId: 'whisper-base',
        useGpu: false,
        onnxExecutionProvider: 'cpu',
      );

      final issues = config.validate();
      expect(issues, isEmpty);
    });

    test('ModelConfig validation allows GPU device 0 when enabled', () {
      const config = ModelConfig(
        asrModelId: 'whisper-base',
      );

      final issues = config.validate();
      expect(issues, isEmpty);
    });

    test('ModelConfig isValid getter returns true for valid config', () {
      const config = ModelConfig(
        asrModelId: 'whisper-base',
        gpuDeviceIndex: 1,
        onnxExecutionProvider: 'cuda',
      );

      expect(config.isValid, true);
    });

    test('ModelConfig isValid getter returns false for invalid config', () {
      const config = ModelConfig(
        asrModelId: 'whisper-base',
        gpuDeviceIndex: -1,
      );

      expect(config.isValid, false);
    });

    test('ModelConfig defaults provide valid configuration', () {
      final config = ModelConfig.defaults();

      final issues = config.validate();
      expect(issues, isEmpty);
      expect(config.isValid, true);
    });

    test('ModelConfig allows disabling GPU with non-CPU provider', () {
      const config = ModelConfig(
        asrModelId: 'whisper-base',
        useGpu: false,
        onnxExecutionProvider: 'cuda',
      );

      final issues = config.validate();
      expect(issues, isEmpty);
      expect(config.useGpu, false);
    });

    test('ModelConfig supports choosing a specific GPU device', () {
      const config = ModelConfig(
        asrModelId: 'whisper-base',
        gpuDeviceIndex: 2,
        onnxExecutionProvider: 'cuda',
      );

      final issues = config.validate();
      expect(issues, isEmpty);
      expect(config.gpuDeviceIndex, 2);
    });
  });
}
