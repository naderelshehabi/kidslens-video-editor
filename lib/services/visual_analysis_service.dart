import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:kidslens_video_editor/data/models/frame_analysis_result.dart';
import 'package:kidslens_video_editor/data/models/frame_data.dart';
import 'package:kidslens_video_editor/data/models/huggingface_model.dart';
import 'package:kidslens_video_editor/data/models/model_info.dart';
import 'package:kidslens_video_editor/native/bindings/onnx_bindings.dart';
import 'package:kidslens_video_editor/services/model_manager_service.dart';

/// Settings for visual analysis
class VisualAnalysisSettings {
  const VisualAnalysisSettings({
    this.enableNsfw = true,
    this.enableViolence = true,
    this.enableBlood = false,
    this.enableWeapons = false,
    this.nsfwThreshold = 0.5,
    this.violenceThreshold = 0.5,
    this.bloodThreshold = 0.5,
    this.weaponsThreshold = 0.5,
    this.batchSize = 8,
    this.useGpu = true,
  });

  /// Creates default settings
  factory VisualAnalysisSettings.defaults() =>
      const VisualAnalysisSettings();

  /// Whether to detect NSFW content
  final bool enableNsfw;

  /// Whether to detect violence
  final bool enableViolence;

  /// Whether to detect blood/gore
  final bool enableBlood;

  /// Whether to detect weapons
  final bool enableWeapons;

  /// Threshold for NSFW detection (0.0 to 1.0)
  final double nsfwThreshold;

  /// Threshold for violence detection (0.0 to 1.0)
  final double violenceThreshold;

  /// Threshold for blood detection (0.0 to 1.0)
  final double bloodThreshold;

  /// Threshold for weapons detection (0.0 to 1.0)
  final double weaponsThreshold;

  /// Batch size for inference
  final int batchSize;

  /// Whether to use GPU acceleration
  final bool useGpu;

  /// Copy with modifications
  VisualAnalysisSettings copyWith({
    bool? enableNsfw,
    bool? enableViolence,
    bool? enableBlood,
    bool? enableWeapons,
    double? nsfwThreshold,
    double? violenceThreshold,
    double? bloodThreshold,
    double? weaponsThreshold,
    int? batchSize,
    bool? useGpu,
  }) =>
      VisualAnalysisSettings(
        enableNsfw: enableNsfw ?? this.enableNsfw,
        enableViolence: enableViolence ?? this.enableViolence,
        enableBlood: enableBlood ?? this.enableBlood,
        enableWeapons: enableWeapons ?? this.enableWeapons,
        nsfwThreshold: nsfwThreshold ?? this.nsfwThreshold,
        violenceThreshold: violenceThreshold ?? this.violenceThreshold,
        bloodThreshold: bloodThreshold ?? this.bloodThreshold,
        weaponsThreshold: weaponsThreshold ?? this.weaponsThreshold,
        batchSize: batchSize ?? this.batchSize,
        useGpu: useGpu ?? this.useGpu,
      );
}

/// Progress information for visual analysis
class VisualAnalysisProgress {
  const VisualAnalysisProgress({
    required this.framesProcessed,
    required this.totalFrames,
    required this.currentResult,
    this.detectionCount = 0,
    this.estimatedTimeRemaining,
  });

  /// Number of frames processed
  final int framesProcessed;

  /// Total frames to process (may be estimated)
  final int totalFrames;

  /// Result for the most recently processed frame
  final FrameAnalysisResult currentResult;

  /// Total number of detections found so far
  final int detectionCount;

  /// Estimated time remaining
  final Duration? estimatedTimeRemaining;

  /// Progress as a value from 0.0 to 1.0
  double get progress =>
      totalFrames > 0 ? framesProcessed / totalFrames : 0;

  /// Progress as a percentage
  double get percentage => progress * 100;

  /// Whether analysis is complete
  bool get isComplete => framesProcessed >= totalFrames;
}

/// Service for visual content analysis and moderation
///
/// Analyzes video frames for inappropriate content including NSFW,
/// violence, blood, and weapons using ONNX models.
class VisualAnalysisService {
  VisualAnalysisService({
    required this.onnx,
    required this.modelManager,
  });

  final ONNXBindings onnx;
  final ModelManagerService modelManager;

  /// Currently loaded model paths
  final Map<String, String> _loadedModels = {};

  /// Whether the service has been initialized
  bool _initialized = false;

  /// Initialize the service
  Future<void> initialize() async {
    if (_initialized) return;

    await onnx.initialize();
    _initialized = true;
  }

  /// Analyze a stream of frames and yield progress updates
  ///
  /// [frames] - Stream of frame data to analyze
  /// [settings] - Analysis settings controlling which detections to run
  Stream<VisualAnalysisProgress> analyzeFrames(
    Stream<FrameData> frames,
    VisualAnalysisSettings settings,
  ) async* {
    await initialize();

    // Load required models
    await _ensureModelsLoaded(settings);

    final results = <FrameAnalysisResult>[];
    final batch = <FrameData>[];
    var framesProcessed = 0;
    var totalFrames = 0; // Will be updated as we process
    var detectionCount = 0;
    final startTime = DateTime.now();

    await for (final frame in frames) {
      batch.add(frame);
      totalFrames++;

      // Process batch when full
      if (batch.length >= settings.batchSize) {
        final batchResults = await _processBatch(batch, settings);
        results.addAll(batchResults);
        framesProcessed += batch.length;

        // Count detections
        for (final result in batchResults) {
          if (!result.isSafeAt(
            nsfwThreshold: settings.nsfwThreshold,
            violenceThreshold: settings.violenceThreshold,
            bloodThreshold: settings.bloodThreshold,
            weaponsThreshold: settings.weaponsThreshold,
          )) {
            detectionCount++;
          }
        }

        // Calculate estimated time remaining
        final elapsed = DateTime.now().difference(startTime);
        final avgTimePerFrame = elapsed.inMilliseconds / framesProcessed;
        final estimatedRemaining = Duration(
          milliseconds: (avgTimePerFrame * (totalFrames - framesProcessed)).round(),
        );

        yield VisualAnalysisProgress(
          framesProcessed: framesProcessed,
          totalFrames: totalFrames,
          currentResult: batchResults.last,
          detectionCount: detectionCount,
          estimatedTimeRemaining: estimatedRemaining,
        );

        batch.clear();
      }
    }

    // Process remaining frames
    if (batch.isNotEmpty) {
      final batchResults = await _processBatch(batch, settings);
      results.addAll(batchResults);
      framesProcessed += batch.length;

      for (final result in batchResults) {
        if (!result.isSafeAt(
          nsfwThreshold: settings.nsfwThreshold,
          violenceThreshold: settings.violenceThreshold,
          bloodThreshold: settings.bloodThreshold,
          weaponsThreshold: settings.weaponsThreshold,
        )) {
          detectionCount++;
        }
      }

      yield VisualAnalysisProgress(
        framesProcessed: framesProcessed,
        totalFrames: totalFrames,
        currentResult: batchResults.last,
        detectionCount: detectionCount,
        estimatedTimeRemaining: Duration.zero,
      );
    }
  }

  /// Analyze a single frame
  ///
  /// [frame] - Frame data to analyze
  /// [settings] - Optional settings (uses defaults if not provided)
  Future<FrameAnalysisResult> analyzeFrame(
    FrameData frame, {
    VisualAnalysisSettings? settings,
  }) async {
    await initialize();

    final analysisSettings = settings ?? VisualAnalysisSettings.defaults();
    await _ensureModelsLoaded(analysisSettings);

    final startTime = DateTime.now();
    final results = await _processBatch([frame], analysisSettings);
    final processingTime = DateTime.now().difference(startTime);

    return results.first.copyWith(
      processingTimeMs: processingTime.inMilliseconds,
    );
  }

  /// Load an ONNX model by ID
  ///
  /// [modelId] - The model identifier to load
  Future<void> loadModel(String modelId) async {
    if (_loadedModels.containsKey(modelId)) return;

    final modelPath = await modelManager.getModelPath(modelId);
    if (modelPath == null) {
      throw VisualAnalysisException('Model not found: $modelId');
    }

    try {
      await onnx.loadModel(modelPath);
      _loadedModels[modelId] = modelPath;
      debugPrint('Loaded visual model: $modelId');
    } catch (e) {
      throw VisualAnalysisException('Failed to load model $modelId: $e');
    }
  }

  /// Unload a model to free resources
  void unloadModel(String modelId) {
    final modelPath = _loadedModels[modelId];
    if (modelPath != null) {
      onnx.unloadModel(modelPath);
      _loadedModels.remove(modelId);
    }
  }

  /// Get list of available visual models
  Future<List<ModelInfo>> getAvailableModels() async {
    final models = await modelManager.getAvailableModels();
    return models
        .where((m) => m.modelType != HuggingFaceModelType.asr)
        .map((m) => ModelInfo(
              id: m.id,
              displayName: m.displayName,
              description: m.description ?? '',
              type: ModelType.visual,
              sizeBytes: m.sizeBytes,
              accuracyPercent: m.accuracyPercent,
              speedRating: m.speedMultiplier >= 10
                  ? 5
                  : m.speedMultiplier >= 7
                      ? 4
                      : m.speedMultiplier >= 4
                          ? 3
                          : m.speedMultiplier >= 2
                              ? 2
                              : 1,
              badge: m.badge,
              minRamBytes: m.ramRequired,
              minVramBytes: m.minVramBytes,
              requiresGpu: m.requiresGpu,
            ),)
        .toList();
  }

  /// Process a batch of frames
  Future<List<FrameAnalysisResult>> _processBatch(
    List<FrameData> frames,
    VisualAnalysisSettings settings,
  ) async {
    final results = <FrameAnalysisResult>[];

    for (var i = 0; i < frames.length; i++) {
      final frame = frames[i];

      // Run inference for each enabled detection type
      var nsfw = NsfwResult.safe();
      var violence = ViolenceResult.safe();
      BloodResult? blood;
      WeaponsResult? weapons;

      if (settings.enableNsfw || settings.enableViolence) {
        final modelPath = _loadedModels['nsfw-mobilenet'] ??
            _loadedModels.values.firstOrNull;

        if (modelPath != null) {
          final scores = await onnx.runInference(
            modelPath,
            frame.data.toList(),
            frame.width,
            frame.height,
          );

          if (settings.enableNsfw) {
            nsfw = NsfwResult(
              porn: scores['porn'] ?? 0,
              sexy: scores['sexy'] ?? 0,
              hentai: scores['hentai'] ?? 0,
              drawings: scores['drawings'] ?? 0,
              neutral: scores['neutral'] ?? 1,
            );
          }

          if (settings.enableViolence) {
            violence = ViolenceResult(
              violent: scores['violent'] ?? 0,
              nonViolent: scores['non_violent'] ?? 1,
            );
          }
        }
      }

      if (settings.enableBlood) {
        blood = const BloodResult(score: 0); // Placeholder
      }

      if (settings.enableWeapons) {
        weapons = const WeaponsResult(score: 0); // Placeholder
      }

      results.add(FrameAnalysisResult(
        frameNumber: frame.frameNumber ?? i,
        timestamp: frame.timestamp,
        nsfw: nsfw,
        violence: violence,
        blood: blood,
        weapons: weapons,
        isSceneChange: frame.isSceneChange,
      ),);
    }

    return results;
  }

  /// Ensure required models are loaded based on settings
  Future<void> _ensureModelsLoaded(VisualAnalysisSettings settings) async {
    // Determine which models we need
    final requiredModels = <String>[];

    if (settings.enableNsfw || settings.enableViolence) {
      requiredModels.add('nsfw-mobilenet');
    }

    if (settings.enableBlood) {
      requiredModels.add('blood-detection');
    }

    if (settings.enableWeapons) {
      requiredModels.add('weapons-detection');
    }

    // Load any models that aren't already loaded
    for (final modelId in requiredModels) {
      if (!_loadedModels.containsKey(modelId)) {
        try {
          await loadModel(modelId);
        } catch (e) {
          debugPrint('Warning: Could not load model $modelId: $e');
          // Continue with other models
        }
      }
    }
  }

  /// Release all resources
  void dispose() {
    _loadedModels.values.forEach(onnx.unloadModel);
    _loadedModels.clear();
    _initialized = false;
  }
}

/// Exception thrown by visual analysis service
class VisualAnalysisException implements Exception {
  VisualAnalysisException(this.message);

  final String message;

  @override
  String toString() => 'VisualAnalysisException: $message';
}
