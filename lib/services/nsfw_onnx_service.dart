import 'dart:async';
import 'dart:ffi';
import 'dart:io';
import 'package:flutter/foundation.dart';

import 'package:kidslens_video_editor/data/models/gpu_config.dart';
import 'package:kidslens_video_editor/jobs/cancellation_token.dart';
import 'package:kidslens_video_editor/native/bindings/onnx_bindings.dart';
import 'package:kidslens_video_editor/native/gpu_manager.dart';

/// Result of provider resolution, capturing what was requested vs actually used.
class ProviderResolutionResult {
  const ProviderResolutionResult({
    required this.requestedProvider,
    required this.actualProvider,
    required this.deviceIndex,
    this.fallbackOccurred = false,
    this.failureReason,
  });

  final String requestedProvider;
  final String actualProvider;
  final int deviceIndex;
  final bool fallbackOccurred;
  final String? failureReason;

  bool get isUsingRequestedProvider => requestedProvider == actualProvider;
}

/// Service for NSFW content detection using ONNX Runtime.
///
/// This service replaces the legacy TensorFlow.js-based implementation,
/// providing native inference with GPU acceleration support.
class NsfwOnnxService {
  NsfwOnnxService({
    required this.onnx,
    required this.gpuConfig,
    required this.gpuManager,
  });

  final ONNXBindings onnx;
  final GpuConfig gpuConfig;
  final GPUAccelerationManager gpuManager;

  String? _resolvedExecutionProvider;
  int? _resolvedDeviceIndex;

  /// The last provider resolution result, for UI visibility.
  ProviderResolutionResult? lastProviderResolution;

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

    final (executionProvider, deviceIndex) =
        await _loadModelWithBestProvider(modelPath);

    debugPrint(
      'NSFW ONNX session: provider=$executionProvider, deviceId=$deviceIndex, configuredChain=${gpuConfig.onnxExecutionProviders.join(' -> ')}',
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

  /// Run object detection inference on a single frame.
  ///
  /// Returns detector output boxes and optional timing metadata.
  ///
  /// [modelPath] - Path to the ONNX detection model file
  /// [rgbData] - RGB byte array for one frame
  /// [width] - Width of input frame in pixels
  /// [height] - Height of input frame in pixels
  /// [classNames] - Ordered class labels matching detector output classes
  /// [confidenceThreshold] - Minimum confidence for detections
  /// [iouThreshold] - IoU threshold used for NMS
  /// [inputSize] - Detector square input size (e.g. 640)
  /// [maxDetections] - Max detections to keep after filtering
  /// [cancellationToken] - Optional token for cooperative cancellation
  Future<DetectionResult> runDetectionInference({
    required String modelPath,
    required List<int> rgbData,
    required int width,
    required int height,
    required List<String> classNames,
    double confidenceThreshold = 0.25,
    double iouThreshold = 0.45,
    int inputSize = 640,
    int maxDetections = 30,
    CancellationToken? cancellationToken,
  }) async {
    cancellationToken?.throwIfCancelled();

    await onnx.initialize();
    await _loadModelWithBestProvider(modelPath);

    try {
      cancellationToken?.throwIfCancelled();
      return await onnx.runDetectionInference(
        modelPath,
        rgbData,
        width,
        height,
        classNames: classNames,
        confidenceThreshold: confidenceThreshold,
        iouThreshold: iouThreshold,
        inputSize: inputSize,
        maxDetections: maxDetections,
      );
    } on ONNXInferenceException catch (e) {
      throw NsfwOnnxException('NSFW detection inference failed: ${e.message}');
    }
  }

  /// Run a generic labeled image classifier through the same provider pipeline.
  Future<Map<String, double>> runLabeledClassificationInference({
    required String modelPath,
    required List<int> rgbData,
    required int width,
    required int height,
    required List<String> labels,
    CancellationToken? cancellationToken,
  }) async {
    cancellationToken?.throwIfCancelled();

    await onnx.initialize();
    await _loadModelWithBestProvider(modelPath);

    try {
      cancellationToken?.throwIfCancelled();
      return await onnx.runLabeledClassificationInference(
        modelPath,
        rgbData,
        width,
        height,
        labels: labels,
      );
    } on ONNXInferenceException catch (e) {
      throw NsfwOnnxException(
        'Helper classification inference failed: ${e.message}',
      );
    }
  }

  /// Run a binary segmentation helper model through the same provider pipeline.
  Future<BinarySegmentationMask> runBinarySegmentationInference({
    required String modelPath,
    required List<int> rgbData,
    required int width,
    required int height,
    double threshold = 0.5,
    CancellationToken? cancellationToken,
  }) async {
    cancellationToken?.throwIfCancelled();

    await onnx.initialize();
    await _loadModelWithBestProvider(modelPath);

    try {
      cancellationToken?.throwIfCancelled();
      return await onnx.runBinarySegmentationInference(
        modelPath,
        rgbData,
        width,
        height,
        threshold: threshold,
      );
    } on ONNXInferenceException catch (e) {
      throw NsfwOnnxException('Segmentation inference failed: ${e.message}');
    }
  }

  /// Warm up the model by running a dummy inference.
  ///
  /// This pre-compiles kernels and allocates memory, reducing
  /// latency for the first real inference request.
  Future<void> warmup(String modelPath) async {
    await onnx.initialize();

    await _loadModelWithBestProvider(modelPath);
    await onnx.warmup(modelPath);
  }

  Future<(String, int)> _loadModelWithBestProvider(String modelPath) async {
    if (_resolvedExecutionProvider != null && _resolvedDeviceIndex != null) {
      try {
        await onnx.loadModel(
          modelPath,
          deviceId: _resolvedDeviceIndex,
          executionProvider: _resolvedExecutionProvider,
          allowProviderFallbackToCpu: false,
        );
        return (_resolvedExecutionProvider!, _resolvedDeviceIndex!);
      } catch (e) {
        debugPrint(
          'NSFW ONNX cached provider failed, re-resolving: provider=$_resolvedExecutionProvider, deviceId=$_resolvedDeviceIndex, error=$e',
        );
        _resolvedExecutionProvider = null;
        _resolvedDeviceIndex = null;
      }
    }

    if (!gpuConfig.useGpu) {
      await onnx.loadModel(
        modelPath,
        deviceId: 0,
        executionProvider: 'CPUExecutionProvider',
      );
      _resolvedExecutionProvider = 'CPUExecutionProvider';
      _resolvedDeviceIndex = 0;
      lastProviderResolution = const ProviderResolutionResult(
        requestedProvider: 'CPUExecutionProvider',
        actualProvider: 'CPUExecutionProvider',
        deviceIndex: 0,
      );
      return ('CPUExecutionProvider', 0);
    }

    final isExplicitProvider = gpuConfig.onnxExecutionProvider != 'auto';
    final candidateProviders = gpuConfig.onnxExecutionProviders;
    final requestedProviderName = candidateProviders.first;
    String? firstFailureReason;

    for (final provider in candidateProviders) {
      if (!_providerRuntimeLikelyAvailable(provider)) {
        final reason = 'Runtime prerequisites missing for $provider';
        debugPrint('NSFW ONNX provider skipped: $reason');
        if (isExplicitProvider && provider == requestedProviderName) {
          debugPrint(
            'WARNING: Explicitly selected provider "$provider" is unavailable: $reason. '
            'Will attempt fallback providers.',
          );
        }
        firstFailureReason ??= reason;
        continue;
      }

      final deviceIndex = await _getMappedDeviceIndex(provider);
      try {
        await onnx.loadModel(
          modelPath,
          deviceId: deviceIndex,
          executionProvider: provider,
          allowProviderFallbackToCpu: false,
        );

        _resolvedExecutionProvider = provider;
        _resolvedDeviceIndex = deviceIndex;

        final fallbackOccurred = provider != requestedProviderName;
        lastProviderResolution = ProviderResolutionResult(
          requestedProvider: requestedProviderName,
          actualProvider: provider,
          deviceIndex: deviceIndex,
          fallbackOccurred: fallbackOccurred,
          failureReason: fallbackOccurred ? firstFailureReason : null,
        );

        if (fallbackOccurred) {
          debugPrint(
            'WARNING: Requested provider "$requestedProviderName" failed. '
            'Fell back to "$provider" (deviceId=$deviceIndex). '
            'Reason: $firstFailureReason',
          );
        }

        return (provider, deviceIndex);
      } catch (e) {
        final reason = 'provider=$provider, deviceId=$deviceIndex, error=$e';
        debugPrint('NSFW ONNX provider attempt failed: $reason');
        firstFailureReason ??= reason;

        if (isExplicitProvider && provider == requestedProviderName) {
          debugPrint(
            'WARNING: Explicitly selected provider "$provider" failed to initialize '
            '(deviceId=$deviceIndex): $e. Will attempt fallback providers.',
          );
        }
      }
    }

    throw const NsfwOnnxException(
      'Failed to load ONNX model with all configured execution providers.',
    );
  }

  bool _providerRuntimeLikelyAvailable(String provider) {
    if (!Platform.isWindows) return true;

    bool canLoadFromSearchPaths(String fileName) {
      final exeDir = File(Platform.resolvedExecutable).parent.path;
      final cwd = Directory.current.path;

      final candidatePaths = <String>[
        '$exeDir/$fileName',
        '$cwd/$fileName',
      ];

      for (final candidate in candidatePaths) {
        if (!File(candidate).existsSync()) {
          continue;
        }
        try {
          DynamicLibrary.open(candidate);
          return true;
        } catch (_) {
          // Try next candidate path.
        }
      }

      try {
        DynamicLibrary.open(fileName);
        return true;
      } catch (_) {
        return false;
      }
    }

    bool canLoadAny(List<String> fileNames) {
      for (final fileName in fileNames) {
        if (canLoadFromSearchPaths(fileName)) {
          return true;
        }
      }
      return false;
    }

    switch (provider) {
      case 'CUDAExecutionProvider':
        final hasOrtShared =
            canLoadFromSearchPaths('onnxruntime_providers_shared.dll');
        final hasOrtCuda =
            canLoadFromSearchPaths('onnxruntime_providers_cuda.dll');

        // Check CUDA/cuDNN version compatibility:
        // CUDA 12.x requires cuDNN 9.x; CUDA 11.x requires cuDNN 8.x
        final hasCuda12 = canLoadFromSearchPaths('cudart64_12.dll');
        final hasCuda11 = canLoadFromSearchPaths('cudart64_11.dll');
        final hasCudnn9 = canLoadFromSearchPaths('cudnn64_9.dll');
        final hasCudnn8 = canLoadAny(const [
          'cudnn64_8.dll',
          'cudnn_ops_infer64_8.dll',
        ]);

        final hasCompatibleCudaPair =
            (hasCuda12 && hasCudnn9) || (hasCuda11 && hasCudnn8);

        final available = hasOrtShared && hasOrtCuda && hasCompatibleCudaPair;
        if (!available) {
          final versionMismatch = (hasCuda12 && hasCudnn8 && !hasCudnn9) ||
              (hasCuda11 && hasCudnn9 && !hasCudnn8);
          debugPrint(
            'NSFW ONNX CUDA runtime unavailable: '
            'ortShared=$hasOrtShared, ortCuda=$hasOrtCuda, '
            'cuda12=$hasCuda12, cuda11=$hasCuda11, '
            'cudnn9=$hasCudnn9, cudnn8=$hasCudnn8'
            '${versionMismatch ? ' (VERSION MISMATCH: CUDA 12 requires cuDNN 9, CUDA 11 requires cuDNN 8)' : ''}',
          );
        }
        return available;
      case 'DmlExecutionProvider':
        final hasOrtShared =
            canLoadFromSearchPaths('onnxruntime_providers_shared.dll');
        final hasOrtDml =
            canLoadFromSearchPaths('onnxruntime_providers_dml.dll');
        final hasDirectMl = canLoadFromSearchPaths('DirectML.dll');
        final available = hasOrtShared && hasOrtDml && hasDirectMl;
        if (!available) {
          debugPrint(
            'NSFW ONNX DirectML runtime unavailable: '
            'ortShared=$hasOrtShared, ortDml=$hasOrtDml, directML=$hasDirectMl',
          );
        }
        return available;
      default:
        return true;
    }
  }

  Future<int> _resolveCudaDeviceIndex() async {
    final requestedIndex = gpuConfig.gpuDeviceIndex;
    if (requestedIndex < 0) return 0;

    try {
      final cudaDevices = await gpuManager.getCudaDevices();
      if (cudaDevices.isEmpty) {
        debugPrint(
          'CUDA device resolution: No CUDA devices found, using index 0',
        );
        return 0;
      }

      final indexes = cudaDevices.map((d) => d.index).toSet();
      if (indexes.contains(requestedIndex)) {
        return requestedIndex;
      }

      debugPrint(
        'CUDA device resolution: Requested index $requestedIndex not found '
        '(available: $indexes), using ${cudaDevices.first.index}',
      );
      return cudaDevices.first.index;
    } catch (e) {
      debugPrint('CUDA device resolution failed: $e, using index 0');
      return 0;
    }
  }

  /// Map GPU device index based on execution provider
  ///
  /// When using DirectML (or auto mode which may fall back to DirectML),
  /// the CUDA device index needs to be mapped to the corresponding DirectML
  /// device index because DirectML enumerates all GPUs while CUDA only
  /// shows NVIDIA GPUs.
  Future<int> _getMappedDeviceIndex(String executionProvider) async {
    if (!gpuConfig.useGpu) return 0;

    final cudaDeviceIndex = await _resolveCudaDeviceIndex();

    // If using DirectML, map CUDA index to DirectML index
    if (executionProvider == 'DmlExecutionProvider') {
      return await gpuManager.mapCudaToDirectMLDeviceIndex(
        cudaDeviceIndex,
      );
    }

    // For CUDA and other providers, use index as-is
    return cudaDeviceIndex;
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
