import 'dart:async';
import 'dart:ffi';
import 'dart:io';
import 'package:flutter/foundation.dart';

import 'package:kidslens_video_editor/data/models/gpu_config.dart';
import 'package:kidslens_video_editor/jobs/cancellation_token.dart';
import 'package:kidslens_video_editor/native/bindings/onnx_bindings.dart';
import 'package:kidslens_video_editor/native/gpu_manager.dart';

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
      return ('CPUExecutionProvider', 0);
    }

    final candidateProviders = gpuConfig.onnxExecutionProviders;

    for (final provider in candidateProviders) {
      if (!_providerRuntimeLikelyAvailable(provider)) {
        debugPrint(
          'NSFW ONNX provider skipped (runtime prerequisites missing): $provider',
        );
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
        return (provider, deviceIndex);
      } catch (e) {
        debugPrint(
          'NSFW ONNX provider attempt failed: provider=$provider, deviceId=$deviceIndex, error=$e',
        );
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
        final hasCudaRuntime =
            canLoadAny(const ['cudart64_12.dll', 'cudart64_11.dll']);
        final hasCudnnRuntime = canLoadAny(const [
          'cudnn64_9.dll',
          'cudnn64_8.dll',
          'cudnn_ops_infer64_8.dll',
        ]);

        final available = hasOrtShared &&
            hasOrtCuda &&
            hasCudaRuntime &&
            hasCudnnRuntime;
        if (!available) {
          debugPrint(
            'NSFW ONNX CUDA runtime unavailable: '
            'ortShared=$hasOrtShared, ortCuda=$hasOrtCuda, '
            'cudaRuntime=$hasCudaRuntime, cudnnRuntime=$hasCudnnRuntime',
          );
        }
        return available;
      case 'DmlExecutionProvider':
        final hasOrtShared =
            canLoadFromSearchPaths('onnxruntime_providers_shared.dll');
        final hasOrtDml = canLoadFromSearchPaths('onnxruntime_providers_dml.dll');
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
        return requestedIndex;
      }

      final indexes = cudaDevices.map((d) => d.index).toSet();
      if (indexes.contains(requestedIndex)) {
        return requestedIndex;
      }

      return cudaDevices.first.index;
    } catch (_) {
      return requestedIndex;
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
