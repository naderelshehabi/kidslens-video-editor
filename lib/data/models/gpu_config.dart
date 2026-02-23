import 'dart:io';

import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:kidslens_video_editor/data/models/analysis_settings.dart';

part 'gpu_config.freezed.dart';
part 'gpu_config.g.dart';

/// GPU configuration for hardware acceleration across ASR and ONNX services.
///
/// This value object encapsulates all GPU-related settings and provides
/// platform-aware execution provider selection for ONNX Runtime.
@freezed
class GpuConfig with _$GpuConfig {
  const factory GpuConfig({
    @Default(true) bool asrGpuEnabled,
    @Default(0) int asrGpuDevice,
    @Default(true) bool onnxGpuEnabled,
    @Default('auto') String onnxExecutionProvider,
    int? onnxGpuDevice,
    @Default(4) int cpuThreads,
    @Default(8) int batchSize,
    @Default(false) bool useFp16,
  }) = _GpuConfig;

  const GpuConfig._();

  factory GpuConfig.fromJson(Map<String, dynamic> json) =>
      _$GpuConfigFromJson(json);

  /// Create GpuConfig from ModelConfig settings
  factory GpuConfig.fromModelConfig(ModelConfig config) => GpuConfig(
        asrGpuEnabled: config.asrGpuEnabled,
        asrGpuDevice: config.asrGpuDevice,
        onnxGpuEnabled: config.onnxGpuEnabled,
        onnxExecutionProvider: config.onnxExecutionProvider,
        onnxGpuDevice: config.onnxGpuDevice,
        cpuThreads: config.cpuThreads,
        batchSize: config.batchSize,
        useFp16: config.useFp16,
      );

  /// Get ONNX execution providers with platform-aware fallback chain
  ///
  /// Returns a prioritized list of execution providers:
  /// - First provider is the preferred GPU provider (if enabled)
  /// - CPUExecutionProvider is always included as a fallback
  ///
  /// Platform-specific defaults when onnxExecutionProvider is 'auto':
  /// - Windows: CUDA → DirectML → CPU
  /// - macOS: CoreML → CPU
  /// - Linux: CUDA → ROCm → CPU
  List<String> get onnxExecutionProviders {
    if (!onnxGpuEnabled) return ['CPUExecutionProvider'];

    if (onnxExecutionProvider == 'auto') {
      // Platform-specific defaults
      if (Platform.isWindows) {
        return [
          'CUDAExecutionProvider',
          'DmlExecutionProvider',
          'CPUExecutionProvider',
        ];
      } else if (Platform.isMacOS) {
        return ['CoreMLExecutionProvider', 'CPUExecutionProvider'];
      } else {
        // Linux and other platforms
        return [
          'CUDAExecutionProvider',
          'ROCMExecutionProvider',
          'CPUExecutionProvider',
        ];
      }
    }

    return [_mapProviderName(onnxExecutionProvider), 'CPUExecutionProvider'];
  }

  /// Map user-friendly provider names to ONNX Runtime provider names
  String _mapProviderName(String input) => switch (input) {
        'cuda' => 'CUDAExecutionProvider',
        'directml' => 'DmlExecutionProvider',
        'coreml' => 'CoreMLExecutionProvider',
        'rocm' => 'ROCMExecutionProvider',
        'cpu' => 'CPUExecutionProvider',
        _ => input, // Pass through unknown values (may be custom providers)
      };
}
