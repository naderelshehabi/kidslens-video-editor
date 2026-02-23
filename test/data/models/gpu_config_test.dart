import 'package:flutter_test/flutter_test.dart';
import 'package:kidslens_video_editor/data/models/analysis_settings.dart';
import 'package:kidslens_video_editor/data/models/gpu_config.dart';

void main() {
  group('GpuConfig', () {
    test('fromModelConfig converts correctly', () {
      final modelConfig = ModelConfig(
        asrModelId: 'whisper-base',
        asrGpuEnabled: true,
        asrGpuDevice: 1,
        onnxGpuEnabled: true,
        onnxExecutionProvider: 'cuda',
        onnxGpuDevice: 2,
      );
      
      final gpuConfig = GpuConfig.fromModelConfig(modelConfig);
      
      expect(gpuConfig.asrGpuEnabled, true);
      expect(gpuConfig.asrGpuDevice, 1);
      expect(gpuConfig.onnxGpuEnabled, true);
      expect(gpuConfig.onnxExecutionProvider, 'cuda');
      expect(gpuConfig.onnxGpuDevice, 2);
    });
    
    test('onnxExecutionProviders returns correct providers for auto', () {
      final config = GpuConfig(onnxExecutionProvider: 'auto');
      
      final providers = config.onnxExecutionProviders;
      
      // Should contain CPU as fallback
      expect(providers, contains('CPUExecutionProvider'));
      // Should contain platform-specific providers
      expect(providers.length, greaterThan(1));
    });
    
    test('onnxExecutionProviders returns CPU when GPU disabled', () {
      final config = GpuConfig(
        onnxGpuEnabled: false,
        onnxExecutionProvider: 'cuda',
      );
      
      expect(config.onnxExecutionProviders, ['CPUExecutionProvider']);
    });
    
    test('onnxExecutionProviders maps provider names correctly', () {
      final testCases = {
        'cuda': 'CUDAExecutionProvider',
        'directml': 'DmlExecutionProvider',
        'coreml': 'CoreMLExecutionProvider',
        'rocm': 'ROCMExecutionProvider',
        'cpu': 'CPUExecutionProvider',
      };
      
      testCases.forEach((input, expected) {
        final config = GpuConfig(onnxExecutionProvider: input);
        expect(config.onnxExecutionProviders.first, expected);
      });
    });
    
    test('onnxExecutionProviders includes CPU fallback for specific providers', () {
      final testProviders = ['cuda', 'directml', 'coreml', 'rocm'];
      
      for (final provider in testProviders) {
        final config = GpuConfig(onnxExecutionProvider: provider);
        final providers = config.onnxExecutionProviders;
        
        expect(providers.last, 'CPUExecutionProvider',
            reason: 'CPU should be fallback for $provider');
        expect(providers.length, 2,
            reason: '$provider should only have itself + CPU');
      }
    });
    
    test('default values are correct', () {
      const config = GpuConfig();
      
      expect(config.asrGpuEnabled, true);
      expect(config.asrGpuDevice, 0);
      expect(config.onnxGpuEnabled, true);
      expect(config.onnxExecutionProvider, 'auto');
      expect(config.onnxGpuDevice, null);
      expect(config.cpuThreads, 4);
      expect(config.batchSize, 8);
      expect(config.useFp16, false);
    });
    
    test('can create config with custom values', () {
      const config = GpuConfig(
        asrGpuEnabled: false,
        asrGpuDevice: 2,
        onnxGpuEnabled: false,
        onnxExecutionProvider: 'cpu',
        onnxGpuDevice: 3,
        cpuThreads: 8,
        batchSize: 16,
        useFp16: true,
      );
      
      expect(config.asrGpuEnabled, false);
      expect(config.asrGpuDevice, 2);
      expect(config.onnxGpuEnabled, false);
      expect(config.onnxExecutionProvider, 'cpu');
      expect(config.onnxGpuDevice, 3);
      expect(config.cpuThreads, 8);
      expect(config.batchSize, 16);
      expect(config.useFp16, true);
    });
    
    test('JSON serialization round-trip', () {
      const original = GpuConfig(
        asrGpuEnabled: true,
        asrGpuDevice: 1,
        onnxGpuEnabled: true,
        onnxExecutionProvider: 'cuda',
        onnxGpuDevice: 2,
        cpuThreads: 6,
        batchSize: 12,
        useFp16: true,
      );
      
      final json = original.toJson();
      final restored = GpuConfig.fromJson(json);
      
      expect(restored.asrGpuEnabled, original.asrGpuEnabled);
      expect(restored.asrGpuDevice, original.asrGpuDevice);
      expect(restored.onnxGpuEnabled, original.onnxGpuEnabled);
      expect(restored.onnxExecutionProvider, original.onnxExecutionProvider);
      expect(restored.onnxGpuDevice, original.onnxGpuDevice);
      expect(restored.cpuThreads, original.cpuThreads);
      expect(restored.batchSize, original.batchSize);
      expect(restored.useFp16, original.useFp16);
    });
    
    test('onnxExecutionProviders handles unknown provider gracefully', () {
      final config = GpuConfig(onnxExecutionProvider: 'custom_provider');
      final providers = config.onnxExecutionProviders;
      
      expect(providers.first, 'custom_provider');
      expect(providers.last, 'CPUExecutionProvider');
    });
  });
}
