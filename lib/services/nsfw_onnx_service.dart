import 'dart:async';

import 'package:kidslens_video_editor/data/models/gpu_config.dart';
import 'package:kidslens_video_editor/jobs/cancellation_token.dart';
import 'package:kidslens_video_editor/native/bindings/onnx_bindings.dart';

/// Service for NSFW content detection using ONNX Runtime.
///
/// This service replaces the legacy TensorFlow.js-based implementation,
/// providing native inference with GPU acceleration support.
class NsfwOnnxService {
  NsfwOnnxService({
    required this.onnx,
    required this.gpuConfig,
  });

  final ONNXBindings onnx;
  final GpuConfig gpuConfig;

  /// Run batch inference on multiple frames.
  ///
  /// Returns a list of score maps, one per frame, with keys:
  /// - 'drawings': Probability of drawings/artwork
  /// - 'hentai': Probability of hentai content
  /// - 'neutral': Probability of neutral/safe content
  /// - 'porn': Probability of pornographic content
  /// - 'sexy': Probability of suggestive content
  ///
  /// GPU acceleration is determined by the injected [gpuConfig]:
  /// - Execution providers are configured during ONNXBindings initialization
  /// - The first available provider from [gpuConfig.onnxExecutionProviders] is used
  /// - Falls back to CPU if GPU providers are unavailable
  ///
  /// [modelPath] - Path to the ONNX model file
  /// [rgbDataBatch] - List of RGB byte arrays for each frame
  /// [width] - Width of input frames in pixels
  /// [height] - Height of input frames in pixels
  /// [cancellationToken] - Optional token for cooperative cancellation
  Future<List<Map<String, double>>> runBatchInference({
    required String modelPath,
    required List<List<int>> rgbDataBatch,
    required int width,
    required int height,
    CancellationToken? cancellationToken,
  }) async {
    if (rgbDataBatch.isEmpty) return const <Map<String, double>>[];

    // Ensure ONNX is initialized
    await onnx.initialize();

    // Load model if not already cached
    await onnx.loadModel(
      modelPath,
      deviceId: gpuConfig.onnxGpuDevice,
      executionProvider: gpuConfig.onnxGpuEnabled
          ? gpuConfig.onnxExecutionProviders.first
          : 'CPUExecutionProvider',
    );

    final results = <Map<String, double>>[];

    for (final rgbData in rgbDataBatch) {
      // Check for cancellation between frames
      cancellationToken?.throwIfCancelled();

      try {
        final scores = await onnx.runInference(
          modelPath,
          rgbData,
          width,
          height,
        );
        results.add(scores);
      } on ONNXInferenceException catch (e) {
        throw NsfwOnnxException('NSFW inference failed: ${e.message}');
      }
    }

    return results;
  }

  /// Warm up the model by running a dummy inference.
  ///
  /// This pre-compiles kernels and allocates memory, reducing
  /// latency for the first real inference request.
  Future<void> warmup(String modelPath) async {
    await onnx.initialize();
    await onnx.loadModel(
      modelPath,
      deviceId: gpuConfig.onnxGpuDevice,
      executionProvider: gpuConfig.onnxGpuEnabled
          ? gpuConfig.onnxExecutionProviders.first
          : 'CPUExecutionProvider',
    );
    await onnx.warmup(modelPath);
  }

  /// Unload a model from the cache.
  Future<void> unloadModel(String modelPath) async {
    await onnx.disposeSession(modelPath);
  }

  /// Get information about a loaded model session.
  ONNXSessionInfo? getModelInfo(String modelPath) =>
      onnx.getSessionInfo(modelPath);
}

/// Exception thrown by NsfwOnnxService.
class NsfwOnnxException implements Exception {
  const NsfwOnnxException(this.message);

  final String message;

  @override
  String toString() => 'NsfwOnnxException: $message';
}
