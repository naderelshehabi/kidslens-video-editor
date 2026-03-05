// Integration Example: Using GPU Device Selection in Practice
// This example demonstrates how to integrate the Phase 2 FFI layer
// with actual model loading and inference workflows.

import 'dart:io';

import 'package:kidslens_video_editor/native/bindings/onnx_bindings.dart';
import 'package:kidslens_video_editor/native/gpu_manager.dart';

/// Example: Automatic GPU device selection and model loading
Future<void> automaticProviderSelection() async {
  final onnx = ONNXBindings();
  final gpuManager = GPUAccelerationManager();

  // Step 1: Initialize ONNX Runtime
  await onnx.initialize();

  // Step 2: Detect available hardware
  await gpuManager.detectAccelerator();
  final availableProviders = await gpuManager.queryAvailableProviders();

  print('Available execution providers: $availableProviders');

  // Step 3: Select optimal provider based on platform
  String selectedProvider;
  int deviceId = 0;
  Map<String, String>? providerOptions;

  if (availableProviders.contains('CUDAExecutionProvider')) {
    // NVIDIA GPU - use CUDA
    selectedProvider = 'CUDAExecutionProvider';
    final cudaDevices = await gpuManager.getCudaDevices();
    if (cudaDevices.isNotEmpty) {
      deviceId = cudaDevices.first.index;
      print('Using CUDA device ${deviceId}: ${cudaDevices.first.name}');
    }
  } else if (Platform.isWindows &&
      availableProviders.contains('DmlExecutionProvider')) {
    // Windows with non-NVIDIA GPU - use DirectML
    selectedProvider = 'DmlExecutionProvider';
    final dmlDevices = await gpuManager.getDirectMLDevices();
    if (dmlDevices.isNotEmpty) {
      deviceId = 0;
      providerOptions = {
        'enable_graph_capture': '1',
      };
      print('Using DirectML device ${deviceId}: ${dmlDevices.first.name}');
    }
  } else if (Platform.isMacOS &&
      availableProviders.contains('CoreMLExecutionProvider')) {
    // macOS - use CoreML
    selectedProvider = 'CoreMLExecutionProvider';
    providerOptions = {
      'MLComputeUnits': '0', // 0 = All, 1 = CPU only, 2 = CPU+GPU
    };
    print('Using CoreML execution provider');
  } else {
    // Fallback to CPU
    selectedProvider = 'CPUExecutionProvider';
    print('Using CPU execution provider');
  }

  // Step 4: Load model with selected provider
  const modelPath = 'assets/models/nsfw_classifier.onnx';
  
  try {
    await onnx.loadModel(
      modelPath,
      deviceId: deviceId,
      executionProvider: selectedProvider,
      providerOptions: providerOptions,
    );

    final sessionInfo = onnx.getSessionInfo(modelPath);
    print('Model loaded successfully:');
    print('  Provider: ${sessionInfo?.executionProvider}');
    print('  Inputs: ${sessionInfo?.inputInfo.map((i) => i.name).join(", ")}');
    print('  Outputs: ${sessionInfo?.outputInfo.map((o) => o.name).join(", ")}');
  } catch (e) {
    print('Failed to load model: $e');
  }
}

/// Example: Multi-GPU CUDA device selection
Future<void> multiGpuCudaSelection() async {
  final onnx = ONNXBindings();
  final gpuManager = GPUAccelerationManager();

  await onnx.initialize();

  final cudaDevices = await gpuManager.getCudaDevices();
  
  if (cudaDevices.isEmpty) {
    print('No CUDA devices available');
    return;
  }

  print('Found ${cudaDevices.length} CUDA device(s):');
  
  // Select device with most VRAM
  final bestDevice = cudaDevices.reduce(
    (a, b) => (a.memoryTotalMB ?? 0) > (b.memoryTotalMB ?? 0) ? a : b,
  );

  print('Selected GPU ${bestDevice.index}: ${bestDevice.name}');
  print('  VRAM: ${bestDevice.memoryTotalMB} MB');
  print('  Compute: ${bestDevice.computeCapability}');

  // Load model on the selected device
  const modelPath = 'assets/models/object_detection.onnx';
  
  await onnx.loadModel(
    modelPath,
    deviceId: bestDevice.index,
    executionProvider: 'CUDAExecutionProvider',
    providerOptions: {
      // Limit memory usage to 80% of available VRAM
      'gpu_mem_limit': '${(bestDevice.memoryTotalMB! * 0.8 * 1024 * 1024).toInt()}',
      'arena_extend_strategy': 'kNextPowerOfTwo',
    },
  );

  print('Model loaded on GPU ${bestDevice.index}');
}

/// Example: DirectML device selection on Windows
Future<void> directMLDeviceSelection() async {
  if (!Platform.isWindows) {
    print('DirectML is only available on Windows');
    return;
  }

  final onnx = ONNXBindings();
  final gpuManager = GPUAccelerationManager();

  await onnx.initialize();

  final dmlDevices = await gpuManager.getDirectMLDevices();
  
  if (dmlDevices.isEmpty) {
    print('No DirectML devices available');
    return;
  }

  print('Found ${dmlDevices.length} DirectML device(s):');
  for (final device in dmlDevices) {
    print('  ${device.deviceId}: ${device.name}');
    print('    VRAM: ${device.vramMB} MB');
    print('    Driver: ${device.driverVersion}');
  }

  // Use the first device (or select based on VRAM)
  final selectedDevice = dmlDevices.first;

  const modelPath = 'assets/models/image_classifier.onnx';
  
  await onnx.loadModel(
    modelPath,
    deviceId: selectedDevice.deviceId,
    executionProvider: 'DmlExecutionProvider',
    providerOptions: {
      'enable_graph_capture': '1',
      'disable_metacommands': '0',
    },
  );

  print('Model loaded on DirectML device ${selectedDevice.deviceId}');
}

/// Example: ROCm device selection on Linux
Future<void> rocmDeviceSelection() async {
  if (!Platform.isLinux) {
    print('ROCm is typically available on Linux');
    return;
  }

  final onnx = ONNXBindings();
  final gpuManager = GPUAccelerationManager();

  await onnx.initialize();

  final availableProviders = await gpuManager.queryAvailableProviders();
  
  if (!availableProviders.contains('ROCMExecutionProvider')) {
    print('ROCm execution provider not available');
    return;
  }

  const modelPath = 'assets/models/neural_network.onnx';
  
  // ROCm device ID 0
  await onnx.loadModel(
    modelPath,
    deviceId: 0,
    executionProvider: 'ROCMExecutionProvider',
    providerOptions: {
      'device_id': '0',
    },
  );

  print('Model loaded with ROCm execution provider');
}

/// Example: Fallback chain for robust deployment
Future<void> providerFallbackChain() async {
  final onnx = ONNXBindings();

  await onnx.initialize();
  
  const modelPath = 'assets/models/production_model.onnx';

  // Define fallback chain
  final providerChain = [
    {'name': 'CUDAExecutionProvider', 'deviceId': 0},
    {'name': 'DmlExecutionProvider', 'deviceId': 0},
    {'name': 'CoreMLExecutionProvider', 'deviceId': null},
    {'name': 'CPUExecutionProvider', 'deviceId': null},
  ];

  for (final providerConfig in providerChain) {
    final providerName = providerConfig['name'] as String;
    final deviceId = providerConfig['deviceId'] as int?;

    try {
      print('Attempting to load with $providerName...');
      
      await onnx.loadModel(
        modelPath,
        deviceId: deviceId,
        executionProvider: providerName,
      );

      final sessionInfo = onnx.getSessionInfo(modelPath);
      print('✓ Successfully loaded with ${sessionInfo?.executionProvider}');
      break;
    } catch (e) {
      print('✗ Failed with $providerName: $e');
      continue;
    }
  }
}

/// Example: Check system requirements before loading
Future<void> systemRequirementsCheck() async {
  final gpuManager = GPUAccelerationManager();

  // Define model requirements
  const ramRequired = 8192; // 8GB RAM
  const vramRequired = 4096; // 4GB VRAM

  final result = await gpuManager.checkRequirements(ramRequired, vramRequired);

  print('System Requirements Check:');
  print('  Status: ${result.passed ? "PASSED" : "FAILED"}');
  print('  RAM: ${result.ramAvailable}/${result.ramRequired} MB');
  print('  VRAM: ${result.vramAvailable}/${result.vramRequired} MB');

  if (result.warnings.isNotEmpty) {
    print('\nWarnings:');
    for (final warning in result.warnings) {
      print('  - $warning');
    }
  }

  if (result.suggestions.isNotEmpty) {
    print('\nSuggestions:');
    for (final suggestion in result.suggestions) {
      print('  - $suggestion');
    }
  }

  if (!result.passed) {
    print('\nSystem does not meet requirements. Consider using CPU-only mode.');
    return;
  }

  // Proceed with model loading...
  print('\nSystem meets requirements. Proceeding with GPU acceleration.');
}

void main() async {
  print('=== GPU Device Selection Integration Examples ===\n');

  print('1. Automatic Provider Selection:');
  await automaticProviderSelection();
  print('\n${"=" * 60}\n');

  print('2. Multi-GPU CUDA Selection:');
  await multiGpuCudaSelection();
  print('\n${"=" * 60}\n');

  print('3. DirectML Device Selection (Windows):');
  await directMLDeviceSelection();
  print('\n${"=" * 60}\n');

  print('4. ROCm Device Selection (Linux):');
  await rocmDeviceSelection();
  print('\n${"=" * 60}\n');

  print('5. Provider Fallback Chain:');
  await providerFallbackChain();
  print('\n${"=" * 60}\n');

  print('6. System Requirements Check:');
  await systemRequirementsCheck();
}
