import 'package:flutter_test/flutter_test.dart';
import 'package:kidslens_video_editor/data/models/analysis_settings.dart';

void main() {
  group('GPU Selection Integration', () {
    test('ModelConfig validation accepts valid GPU indices', () {
      final config = ModelConfig(
        asrModelId: 'whisper-base',
        asrGpuEnabled: true,
        asrGpuDevice: 0,
        onnxGpuEnabled: true,
        onnxExecutionProvider: 'cuda',
        onnxGpuDevice: 1,
      );
      
      final issues = config.validate();
      expect(issues, isEmpty);
    });
    
    test('ModelConfig validation rejects negative GPU indices for ASR', () {
      final config = ModelConfig(
        asrModelId: 'whisper-base',
        asrGpuEnabled: true,
        asrGpuDevice: -1,
      );
      
      final issues = config.validate();
      expect(issues, isNotEmpty);
      expect(issues.first, contains('ASR GPU device must be non-negative'));
    });
    
    test('ModelConfig validation rejects negative GPU indices for ONNX', () {
      final config = ModelConfig(
        asrModelId: 'whisper-base',
        onnxGpuDevice: -1,
      );
      
      final issues = config.validate();
      expect(issues, isNotEmpty);
      expect(issues.first, contains('ONNX GPU device must be non-negative'));
    });
    
    test('ModelConfig validation rejects invalid execution providers', () {
      final config = ModelConfig(
        asrModelId: 'whisper-base',
        onnxExecutionProvider: 'invalid_provider',
      );
      
      final issues = config.validate();
      expect(issues, isNotEmpty);
      expect(issues.first, contains('Invalid ONNX execution provider'));
    });
    
    test('ModelConfig validation rejects CPU provider with GPU enabled', () {
      final config = ModelConfig(
        asrModelId: 'whisper-base',
        onnxGpuEnabled: true,
        onnxExecutionProvider: 'cpu',
      );
      
      final issues = config.validate();
      expect(issues, isNotEmpty);
      expect(issues.first, contains('Cannot enable GPU with CPU execution provider'));
    });
    
    test('ModelConfig validation accepts all valid execution providers', () {
      const validProviders = ['auto', 'cuda', 'directml', 'coreml', 'cpu'];
      
      for (final provider in validProviders) {
        final config = ModelConfig(
          asrModelId: 'whisper-base',
          onnxExecutionProvider: provider,
          // Disable GPU if provider is CPU to avoid conflict
          onnxGpuEnabled: provider != 'cpu',
        );
        
        final issues = config.validate();
        expect(issues, isEmpty,
            reason: 'Provider $provider should be valid');
      }
    });
    
    test('ModelConfig validation allows null ONNX GPU device', () {
      final config = ModelConfig(
        asrModelId: 'whisper-base',
        onnxGpuDevice: null,
      );
      
      final issues = config.validate();
      expect(issues, isEmpty);
    });
    
    test('ModelConfig validation allows ASR GPU device 0 when enabled', () {
      final config = ModelConfig(
        asrModelId: 'whisper-base',
        asrGpuEnabled: true,
        asrGpuDevice: 0,
      );
      
      final issues = config.validate();
      expect(issues, isEmpty);
    });
    
    test('ModelConfig isValid getter returns true for valid config', () {
      final config = ModelConfig(
        asrModelId: 'whisper-base',
        asrGpuEnabled: true,
        asrGpuDevice: 1,
        onnxGpuEnabled: true,
        onnxExecutionProvider: 'cuda',
        onnxGpuDevice: 2,
      );
      
      expect(config.isValid, true);
    });
    
    test('ModelConfig isValid getter returns false for invalid config', () {
      final config = ModelConfig(
        asrModelId: 'whisper-base',
        asrGpuDevice: -1,
      );
      
      expect(config.isValid, false);
    });
    
    test('ModelConfig defaults provide valid configuration', () {
      final config = ModelConfig.defaults();
      
      final issues = config.validate();
      expect(issues, isEmpty);
      expect(config.isValid, true);
    });
    
    test('ModelConfig maintains backward compatibility with deprecated fields', () {
      // Test that new fields override deprecated fields when both present
      final config = ModelConfig(
        asrModelId: 'whisper-base',
        // ignore: deprecated_member_use_from_same_package
        useGpu: false, // deprecated
        asrGpuEnabled: true, // should take precedence
        // ignore: deprecated_member_use_from_same_package
        gpuDeviceIndex: 2, // deprecated
        asrGpuDevice: 1, // should take precedence
      );
      
      // The new fields should be used
      expect(config.asrGpuEnabled, true);
      expect(config.asrGpuDevice, 1);
      // The deprecated fields are also stored
      // ignore: deprecated_member_use_from_same_package
      expect(config.useGpu, false);
      // ignore: deprecated_member_use_from_same_package
      expect(config.gpuDeviceIndex, 2);
    });
    
    test('ModelConfig allows disabling GPU for both ASR and ONNX', () {
      final config = ModelConfig(
        asrModelId: 'whisper-base',
        asrGpuEnabled: false,
        onnxGpuEnabled: false,
        onnxExecutionProvider: 'cpu',
      );
      
      final issues = config.validate();
      expect(issues, isEmpty);
      expect(config.asrGpuEnabled, false);
      expect(config.onnxGpuEnabled, false);
    });
    
    test('ModelConfig allows different GPU devices for ASR and ONNX', () {
      final config = ModelConfig(
        asrModelId: 'whisper-base',
        asrGpuDevice: 0,
        onnxGpuDevice: 1,
        onnxExecutionProvider: 'cuda',
      );
      
      final issues = config.validate();
      expect(issues, isEmpty);
      expect(config.asrGpuDevice, 0);
      expect(config.onnxGpuDevice, 1);
    });
  });
}
