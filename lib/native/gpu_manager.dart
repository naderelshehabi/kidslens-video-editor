import 'dart:io';
import 'dart:math';

import '../data/models/gpu_info.dart';

/// Detect GPU capabilities and select optimal acceleration
class GPUAccelerationManager {
  AcceleratorInfo? _detectedAccelerator;
  bool _initialized = false;

  /// Detect available GPU acceleration
  Future<AcceleratorInfo> detectAccelerator() async {
    if (_initialized) return _detectedAccelerator!;

    // Try different acceleration backends in order of preference
    _detectedAccelerator = await _tryNvidiaCuda();
    _detectedAccelerator ??= await _tryAppleMetal();
    _detectedAccelerator ??= await _tryVulkan();
    _detectedAccelerator ??= _cpuFallback();

    _initialized = true;
    return _detectedAccelerator!;
  }

  Future<AcceleratorInfo?> _tryNvidiaCuda() async {
    if (!Platform.isWindows && !Platform.isLinux) return null;

    try {
      // Check for nvidia-smi
      final result = await Process.run('nvidia-smi', [
        '--query-gpu=name,memory.total',
        '--format=csv,noheader,nounits',
      ]);

      if (result.exitCode != 0) return null;

      final output = result.stdout.toString().trim();
      if (output.isEmpty) return null;

      final parts = output.split(',').map((s) => s.trim()).toList();
      if (parts.length < 2) return null;

      final name = parts[0];
      final vramMB = int.tryParse(parts[1]) ?? 0;

      return AcceleratorInfo(
        type: AcceleratorType.cuda,
        name: name,
        vramMB: vramMB,
        recommendedBatchSize: _calculateOptimalBatch(vramMB),
      );
    } catch (_) {
      return null;
    }
  }

  Future<AcceleratorInfo?> _tryAppleMetal() async {
    if (!Platform.isMacOS) return null;

    try {
      // Check for Apple Silicon
      final result = await Process.run('sysctl', ['-n', 'machdep.cpu.brand_string']);
      final cpuBrand = result.stdout.toString().trim();
      final isAppleSilicon = cpuBrand.contains('Apple');

      // Get memory info
      final memResult = await Process.run('sysctl', ['-n', 'hw.memsize']);
      final memBytes = int.tryParse(memResult.stdout.toString().trim()) ?? 0;
      final memMB = memBytes ~/ (1024 * 1024);

      // Apple Silicon shares unified memory
      final vramMB = isAppleSilicon ? (memMB ~/ 2) : 2048;

      return AcceleratorInfo(
        type: AcceleratorType.metal,
        name: isAppleSilicon ? 'Apple Silicon GPU' : 'Intel/AMD GPU',
        vramMB: vramMB,
        isAppleSilicon: isAppleSilicon,
        recommendedBatchSize: _calculateOptimalBatch(vramMB),
      );
    } catch (_) {
      return null;
    }
  }

  Future<AcceleratorInfo?> _tryVulkan() async {
    try {
      // TODO: Implement Vulkan detection
      return null;
    } catch (_) {
      return null;
    }
  }

  AcceleratorInfo _cpuFallback() {
    return const AcceleratorInfo(
      type: AcceleratorType.cpu,
      name: 'CPU (No GPU acceleration)',
      vramMB: 0,
      recommendedBatchSize: 1,
    );
  }

  int _calculateOptimalBatch(int vramMB) {
    // Assuming ~200MB per batch item for typical models
    final maxBatch = vramMB ~/ 200;
    return min(max(maxBatch, 1), 16); // Clamp to 1-16
  }

  /// Get ONNX execution providers in priority order
  List<String> getOnnxExecutionProviders() {
    switch (_detectedAccelerator?.type) {
      case AcceleratorType.cuda:
        return ['CUDAExecutionProvider', 'CPUExecutionProvider'];
      case AcceleratorType.metal:
        return ['CoreMLExecutionProvider', 'CPUExecutionProvider'];
      case AcceleratorType.rocm:
        return ['ROCMExecutionProvider', 'CPUExecutionProvider'];
      case AcceleratorType.vulkan:
        return ['CPUExecutionProvider'];
      case AcceleratorType.oneapi:
        return ['DnnlExecutionProvider', 'CPUExecutionProvider'];
      default:
        return ['CPUExecutionProvider'];
    }
  }

  /// Check if GPU acceleration is available
  bool get hasGpuAcceleration =>
      _detectedAccelerator?.type != AcceleratorType.cpu;

  /// Get the detected accelerator info
  AcceleratorInfo? get accelerator => _detectedAccelerator;
}
