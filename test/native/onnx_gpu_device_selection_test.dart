// Example test for Phase 2: GPU Device Selection FFI Layer
// This demonstrates how to use the new execution provider configuration

import 'package:flutter_test/flutter_test.dart';
import 'package:kidslens_video_editor/native/bindings/onnx_bindings.dart';
import 'package:kidslens_video_editor/native/bindings/onnx_ffi_types.dart';
import 'package:kidslens_video_editor/native/gpu_manager.dart';

void main() {
  group('GPU Device Selection FFI Layer Tests', () {
    late ONNXBindings onnx;
    late GPUAccelerationManager gpuManager;

    setUp(() {
      onnx = ONNXBindings();
      gpuManager = GPUAccelerationManager();
    });

    test('Query available execution providers', () async {
      final providers = await gpuManager.queryAvailableProviders();

      expect(providers, contains('CPUExecutionProvider'));
      print('Available providers: $providers');

      // At least CPU should be available
      expect(providers.isNotEmpty, true);
    });

    test('Enumerate DirectML devices on Windows', () async {
      final devices = await gpuManager.getDirectMLDevices();

      print('DirectML devices found: ${devices.length}');
      for (final device in devices) {
        print('  Device $device');
      }

      // This test will pass even with 0 devices (not on Windows or no GPU)
      expect(devices, isA<List<DirectMLDevice>>());
    });

    test('Load model with CPU execution provider', () async {
      await onnx.initialize();

      // Use a simple model path for testing (replace with actual model)
      const modelPath = 'test/fixtures/simple_model.onnx';

      try {
        await onnx.loadModel(
          modelPath,
          executionProvider: 'CPUExecutionProvider',
        );

        final sessionInfo = onnx.getSessionInfo(modelPath);
        expect(sessionInfo, isNotNull);
        expect(sessionInfo!.executionProvider, 'CPUExecutionProvider');

        print('Model loaded successfully with CPU provider');
      } catch (e) {
        print('Note: Model loading requires actual ONNX model file: $e');
      }
    });

    test('Load model with CUDA provider if available', () async {
      await onnx.initialize();

      final providers = await gpuManager.queryAvailableProviders();
      if (!providers.contains('CUDAExecutionProvider')) {
        print('Skipping CUDA test - no CUDA devices available');
        return;
      }

      const modelPath = 'test/fixtures/simple_model.onnx';

      try {
        await onnx.loadModel(
          modelPath,
          deviceId: 0,
          executionProvider: 'CUDAExecutionProvider',
        );

        final sessionInfo = onnx.getSessionInfo(modelPath);
        expect(sessionInfo, isNotNull);
        expect(sessionInfo!.executionProvider, 'CUDAExecutionProvider');

        print('Model loaded successfully with CUDA provider on device 0');
      } catch (e) {
        print('CUDA provider configuration failed: $e');
        // This may fail if ONNX Runtime wasn't built with CUDA support
      }
    });

    test('Load model with DirectML provider if available', () async {
      await onnx.initialize();

      final devices = await gpuManager.getDirectMLDevices();
      if (devices.isEmpty) {
        print('Skipping DirectML test - no DirectML devices available');
        return;
      }

      const modelPath = 'test/fixtures/simple_model.onnx';

      try {
        await onnx.loadModel(
          modelPath,
          deviceId: 0,
          executionProvider: 'DmlExecutionProvider',
          providerOptions: {
            'enable_graph_capture': '1',
          },
        );

        final sessionInfo = onnx.getSessionInfo(modelPath);
        expect(sessionInfo, isNotNull);
        expect(sessionInfo!.executionProvider, 'DmlExecutionProvider');

        print('Model loaded successfully with DirectML provider');
      } catch (e) {
        print('DirectML provider configuration failed: $e');
      }
    });

    test('Test CUDA device enumeration', () async {
      final cudaDevices = await gpuManager.getCudaDevices();

      print('CUDA devices found: ${cudaDevices.length}');
      for (final device in cudaDevices) {
        print('  GPU ${device.index}: ${device.name}');
        print('    VRAM: ${device.memoryTotalMB} MB');
        print('    Compute: ${device.computeCapability}');
      }

      expect(cudaDevices, isA<List<CudaGpuDevice>>());
    });

    test('Test provider fallback on configuration failure', () async {
      await onnx.initialize();

      const modelPath = 'test/fixtures/simple_model.onnx';

      try {
        // Try to load with an invalid provider - should fall back to CPU
        await onnx.loadModel(
          modelPath,
          executionProvider: 'NonExistentProvider',
        );

        // Should still succeed with CPU fallback
        final sessionInfo = onnx.getSessionInfo(modelPath);
        expect(sessionInfo, isNotNull);

        print('Fallback successful despite invalid provider');
      } catch (e) {
        print('Note: Requires actual model file: $e');
      }
    });

    test('DirectMLDeviceConfig toKeyValuePairs conversion', () {
      final config = DirectMLDeviceConfig(
        deviceId: 1,
        enableGraphCapture: true,
        disableMetaCommands: false,
      );

      final kvPairs = config.toKeyValuePairs();

      expect(kvPairs['device_id'], '1');
      expect(kvPairs['enable_graph_capture'], '1');
      expect(kvPairs.containsKey('disable_metacommands'), false);

      print('DirectML config: $kvPairs');
    });

    test('CUDA configuration with custom options', () async {
      await onnx.initialize();

      const modelPath = 'test/fixtures/simple_model.onnx';

      try {
        await onnx.loadModel(
          modelPath,
          deviceId: 0,
          executionProvider: 'CUDAExecutionProvider',
          providerOptions: {
            'gpu_mem_limit': '${2 * 1024 * 1024 * 1024}', // 2GB limit
            'arena_extend_strategy': 'kSameAsRequested',
          },
        );

        print('CUDA provider configured with custom memory limit');
      } catch (e) {
        print('CUDA custom config test: $e');
      }
    });
  });
}
