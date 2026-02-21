import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:kidslens_video_editor/data/models/analysis_settings.dart';
import 'package:kidslens_video_editor/data/models/frame_analysis_result.dart';
import 'package:kidslens_video_editor/data/models/frame_data.dart';
import 'package:kidslens_video_editor/data/models/huggingface_model.dart';
import 'package:kidslens_video_editor/data/models/model_info.dart';
import 'package:kidslens_video_editor/data/models/visual_content_category.dart';
import 'package:kidslens_video_editor/native/bindings/onnx_bindings.dart';
import 'package:kidslens_video_editor/services/clip_service.dart';
import 'package:kidslens_video_editor/services/model_manager_service.dart';
import 'package:kidslens_video_editor/services/nudenet_service.dart';
import 'package:kidslens_video_editor/data/models/content_category.dart';
import 'package:kidslens_video_editor/services/voting_service.dart';
import 'dart:math' as math;

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
    this.nsfwModelId = 'nsfw-mobilenet-v2',
    this.violenceModelId = 'violence-mobilenet',
    this.bloodModelId = 'gore-efficientnet-b2',
    this.weaponsModelId = 'weapons-yolov8-small',
    this.visualContentConfig,
  });

  /// Creates default settings with recommended models
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

  /// Model ID for NSFW detection
  final String nsfwModelId;

  /// Model ID for violence detection
  final String violenceModelId;

  /// Model ID for blood detection
  final String bloodModelId;

  /// Model ID for weapons detection
  final String weaponsModelId;

  /// Visual content detection configuration (NudeNet + CLIP)
  final VisualContentConfig? visualContentConfig;

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
    String? nsfwModelId,
    String? violenceModelId,
    String? bloodModelId,
    String? weaponsModelId,
    VisualContentConfig? visualContentConfig,
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
        nsfwModelId: nsfwModelId ?? this.nsfwModelId,
        violenceModelId: violenceModelId ?? this.violenceModelId,
        bloodModelId: bloodModelId ?? this.bloodModelId,
        weaponsModelId: weaponsModelId ?? this.weaponsModelId,
        visualContentConfig: visualContentConfig ?? this.visualContentConfig,
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

/// Result of MoE (Mixture of Experts) frame analysis.
///
/// Contains per-category voting results for a single video frame.
class MoEFrameResult {
  const MoEFrameResult({
    required this.timestamp,
    required this.frameNumber,
    required this.categoryResults,
  });

  /// Timestamp of the analyzed frame.
  final Duration timestamp;

  /// Frame number in the video.
  final int frameNumber;

  /// Voting results keyed by category ID.
  final Map<String, CategoryVoteResult> categoryResults;

  /// Whether any category was triggered.
  bool get hasDetections =>
      categoryResults.values.any((r) => r.triggered);

  /// Category IDs that were triggered.
  List<String> get triggeredCategories =>
      categoryResults.entries
          .where((e) => e.value.triggered)
          .map((e) => e.key)
          .toList();
}

/// Service for visual content analysis and moderation
///
/// Analyzes video frames for inappropriate content including NSFW,
/// violence, blood, and weapons using ONNX models.
/// Also supports NudeNet body-part detection and CLIP zero-shot classification.
class VisualAnalysisService {
  VisualAnalysisService({
    required this.onnx,
    required this.modelManager,
    this.nudeNetService,
    this.clipService,
    this.votingService,
  });

  final ONNXBindings onnx;
  final ModelManagerService modelManager;

  /// NudeNet service for body-part detection (optional)
  final NudeNetService? nudeNetService;

  /// CLIP service for zero-shot classification (optional)
  final ClipService? clipService;

  /// Voting service for MoE consensus (optional)
  final VotingService? votingService;

  /// Currently loaded model paths
  final Map<String, String> _loadedModels = {};

  /// Whether the service has been initialized
  bool _initialized = false;

  /// Cached CLIP text embeddings for the current analysis
  Map<String, CategoryEmbeddings>? _clipEmbeddings;

  /// Cancellation flag — checked between frames, not mid-inference
  bool _isCancelled = false;

  /// Whether an analysis is currently running
  bool _isRunning = false;

  /// Cancel the current analysis.
  ///
  /// The current frame's inference will complete naturally before stopping.
  /// Partial results processed so far remain valid.
  void cancelAnalysis() {
    _isCancelled = true;
  }

  /// Whether an analysis is currently in progress
  bool get isRunning => _isRunning;

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
    _isCancelled = false;
    _isRunning = true;

    try {
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
        // Check cancellation between frames
        if (_isCancelled) {
          debugPrint('VisualAnalysisService: Analysis cancelled after '
              '$framesProcessed frames');
          break;
        }

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

      // Process remaining frames (unless cancelled)
      if (batch.isNotEmpty && !_isCancelled) {
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
    } finally {
      _isRunning = false;
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

  /// Analyze a single frame using MoE (Mixture of Experts) voting.
  ///
  /// For each enabled visual [ContentCategory] in the config, runs each
  /// enabled [ModelContribution], collects votes, and computes consensus
  /// via the [VotingService].
  Future<MoEFrameResult> analyzeFrameWithMoE(
    FrameData frame,
    ContentDetectionConfig config,
  ) async {
    await initialize();

    final voting = votingService ?? const VotingService();
    final categoryResults = <String, CategoryVoteResult>{};

    // Optional NSFW pre-filter gate for NudeNet efficiency
    double? nsfwPreFilterScore;
    if (config.useNsfwPreFilter) {
      nsfwPreFilterScore = await _runNsfwPreFilter(frame, config);
    }

    for (final category in config.enabledVisualCategories) {
      final votes = <ModelVote>[];

      for (final contribution in category.enabledModels) {
        try {
          final vote = await _runModelContribution(
            frame: frame,
            category: category,
            contribution: contribution,
            config: config,
            nsfwPreFilterScore: nsfwPreFilterScore,
          );
          if (vote != null) {
            votes.add(vote);
          }
        } catch (e) {
          debugPrint('MoE: ${contribution.modelId} failed for '
              '${category.id}: $e');
        }
      }

      if (votes.isNotEmpty) {
        final result = voting.computeConsensus(
          category: category,
          votes: votes,
          config: config.votingConfig,
        );
        categoryResults[category.id] = result;
      }
    }

    return MoEFrameResult(
      timestamp: frame.timestamp,
      frameNumber: frame.frameNumber ?? 0,
      categoryResults: categoryResults,
    );
  }

  /// Run NSFW pre-filter to gate NudeNet inference.
  Future<double?> _runNsfwPreFilter(
    FrameData frame,
    ContentDetectionConfig config,
  ) async {
    // Find an enabled NSFW classifier model
    for (final category in config.enabledVisualCategories) {
      for (final contribution in category.enabledModels) {
        if (contribution.modelType == HuggingFaceModelType.nsfw) {
          final modelPath = await _loadModelById(contribution.modelId);
          if (modelPath == null) continue;

          try {
            final scores = await onnx.runInference(
              modelPath,
              frame.data.toList(),
              frame.width,
              frame.height,
            );
            return _computeMaxNsfwScore(scores);
          } catch (e) {
            debugPrint('MoE: NSFW pre-filter failed: $e');
          }
        }
      }
    }
    return null;
  }

  /// Extract the maximum NSFW-relevant score from classifier output.
  double _computeMaxNsfwScore(Map<String, double> scores) {
    final nsfwKeys = ['porn', 'sexy', 'hentai'];
    var maxScore = 0.0;
    for (final key in nsfwKeys) {
      final score = scores[key] ?? 0.0;
      if (score > maxScore) maxScore = score;
    }
    return maxScore;
  }

  /// Run a single model contribution and produce a [ModelVote].
  Future<ModelVote?> _runModelContribution({
    required FrameData frame,
    required ContentCategory category,
    required ModelContribution contribution,
    required ContentDetectionConfig config,
    double? nsfwPreFilterScore,
  }) async {
    switch (contribution.modelType) {
      case HuggingFaceModelType.nsfw:
      case HuggingFaceModelType.violence:
      case HuggingFaceModelType.blood:
      case HuggingFaceModelType.weapons:
        return _runClassifierModel(frame, contribution);

      case HuggingFaceModelType.nudeNet:
        // Gate NudeNet behind NSFW pre-filter
        if (config.useNsfwPreFilter && nsfwPreFilterScore != null) {
          if (nsfwPreFilterScore < config.preFilterThreshold) {
            return null; // Skip NudeNet — pre-filter didn't trigger
          }
        }
        return _runNudeNetModel(frame, contribution);

      case HuggingFaceModelType.clip:
        return _runClipModel(frame, contribution);

      default:
        debugPrint('MoE: Unsupported model type '
            '${contribution.modelType} for ${contribution.modelId}');
        return null;
    }
  }

  /// Run a standard ONNX classifier model (NSFW, violence, blood, weapons).
  Future<ModelVote?> _runClassifierModel(
    FrameData frame,
    ModelContribution contribution,
  ) async {
    final modelPath = await _loadModelById(contribution.modelId);
    if (modelPath == null) return null;

    final scores = await onnx.runInference(
      modelPath,
      frame.data.toList(),
      frame.width,
      frame.height,
    );

    final normalizedScore = _normalizeClassifierScore(
      scores,
      contribution.modelType,
    );

    // Look up model accuracy for weight
    final modelInfo = modelManager.getModelInfo(contribution.modelId);
    final accuracyWeight = (modelInfo?.accuracyPercent ?? 80) / 100.0;
    final weight = accuracyWeight * contribution.effectiveWeight;

    return ModelVote(
      modelId: contribution.modelId,
      score: normalizedScore,
      weight: weight,
    );
  }

  /// Normalize raw classifier scores to a 0-1 detection score.
  double _normalizeClassifierScore(
    Map<String, double> scores,
    HuggingFaceModelType modelType,
  ) {
    switch (modelType) {
      case HuggingFaceModelType.nsfw:
        return _computeMaxNsfwScore(scores);
      case HuggingFaceModelType.violence:
        return scores['violent'] ?? 0.0;
      case HuggingFaceModelType.blood:
        return scores['blood'] ?? scores['gore'] ?? 0.0;
      case HuggingFaceModelType.weapons:
        return scores['weapons'] ?? scores['weapon'] ?? 0.0;
      default:
        // Take the max of all scores as a fallback
        return scores.values.fold(0.0, math.max);
    }
  }

  /// Run NudeNet model and produce a vote with detected regions.
  Future<ModelVote?> _runNudeNetModel(
    FrameData frame,
    ModelContribution contribution,
  ) async {
    if (nudeNetService == null) return null;

    final modelPath = await nudeNetService!.getModelPath(
      contribution.modelId,
    );
    if (modelPath == null) return null;

    final regions = await nudeNetService!.detectRegions(
      modelPath: modelPath,
      rgbData: Uint8List.fromList(frame.data),
      width: frame.width,
      height: frame.height,
    );

    // Filter regions by contribution's detection labels
    final filteredRegions = contribution.detectionLabels.isEmpty
        ? regions
        : regions
            .where((r) => contribution.detectionLabels.contains(r.label))
            .toList();

    if (filteredRegions.isEmpty) return null;

    // Score = max confidence across filtered regions
    final score = filteredRegions
        .map((r) => r.confidence)
        .reduce(math.max);

    final modelInfo = modelManager.getModelInfo(contribution.modelId);
    final accuracyWeight = (modelInfo?.accuracyPercent ?? 80) / 100.0;
    final weight = accuracyWeight * contribution.effectiveWeight;

    return ModelVote(
      modelId: contribution.modelId,
      score: score,
      weight: weight,
      regions: filteredRegions,
    );
  }

  /// Run CLIP model and produce a vote from zero-shot classification.
  Future<ModelVote?> _runClipModel(
    FrameData frame,
    ModelContribution contribution,
  ) async {
    if (clipService == null) return null;
    if (_clipEmbeddings == null || _clipEmbeddings!.isEmpty) return null;

    // Look up pre-computed embeddings for the parent category
    // The embeddings are keyed by category ID (set up in precomputeClipEmbeddingsForCategories)
    // We need to find the right embedding entry
    String? embeddingKey;
    for (final key in _clipEmbeddings!.keys) {
      if (key.startsWith(contribution.modelId) ||
          _clipEmbeddings!.containsKey(key)) {
        embeddingKey = key;
        break;
      }
    }

    if (embeddingKey == null) return null;

    try {
      final scores = await clipService!.classifyFrame(
        Uint8List.fromList(frame.data),
        frame.width,
        frame.height,
        {embeddingKey: _clipEmbeddings![embeddingKey]!},
      );

      final rawScore = scores[embeddingKey] ?? 0.0;
      final normalizedScore = _sigmoidNormalize(rawScore);

      final modelInfo = modelManager.getModelInfo(contribution.modelId);
      final accuracyWeight = (modelInfo?.accuracyPercent ?? 70) / 100.0;
      final weight = accuracyWeight * contribution.effectiveWeight;

      return ModelVote(
        modelId: contribution.modelId,
        score: normalizedScore,
        weight: weight,
      );
    } catch (e) {
      debugPrint('MoE: CLIP classification failed: $e');
      return null;
    }
  }

  /// Sigmoid normalization for CLIP discriminative scores.
  ///
  /// CLIP scores range approximately [-15, +15]. This transforms them
  /// to [0, 1] using: `1 / (1 + exp(-rawScore / 3))`.
  double _sigmoidNormalize(double rawScore) {
    return 1.0 / (1.0 + math.exp(-rawScore / 3.0));
  }

  /// Load a model by ID, caching the path.
  Future<String?> _loadModelById(String modelId) async {
    if (_loadedModels.containsKey(modelId)) {
      return _loadedModels[modelId];
    }

    final modelPath = await modelManager.getModelPath(modelId);
    if (modelPath == null) return null;

    try {
      await onnx.loadModel(modelPath);
      _loadedModels[modelId] = modelPath;
      return modelPath;
    } catch (e) {
      debugPrint('MoE: Failed to load model $modelId: $e');
      return null;
    }
  }

  /// Pre-load all classifier models required by the content detection config.
  Future<void> ensureMoEModelsLoaded(ContentDetectionConfig config) async {
    await initialize();

    for (final category in config.enabledVisualCategories) {
      for (final contribution in category.enabledModels) {
        if (contribution.modelType == HuggingFaceModelType.clip) continue;
        // NudeNet models are managed by NudeNetService
        if (contribution.modelType == HuggingFaceModelType.nudeNet) continue;

        try {
          await _loadModelById(contribution.modelId);
        } catch (e) {
          debugPrint('MoE: Could not pre-load ${contribution.modelId}: $e');
        }
      }
    }
  }

  /// Pre-compute CLIP text embeddings from [ContentCategory] contributions.
  ///
  /// Converts [ContentCategory] CLIP model contributions into the legacy
  /// [VisualContentCategory] format and delegates to [ClipService].
  Future<void> precomputeClipEmbeddingsForCategories(
    List<ContentCategory> categories,
  ) async {
    if (clipService == null) return;

    final clipCategories = <VisualContentCategory>[];
    for (final category in categories) {
      if (!category.enabled) continue;
      for (final contribution in category.enabledModels) {
        if (contribution.modelType != HuggingFaceModelType.clip) continue;
        if (contribution.clipPrompts.isEmpty) continue;

        clipCategories.add(VisualContentCategory(
          id: category.id,
          name: category.name,
          description: category.description,
          clipPrompts: contribution.clipPrompts,
          clipNegativePrompts: contribution.clipNegativePrompts,
          detectionSource: CategoryDetectionSource.clip,
          enabled: true,
        ));
      }
    }

    if (clipCategories.isEmpty) {
      _clipEmbeddings = {};
      return;
    }

    _clipEmbeddings = await clipService!.precomputePromptEmbeddings(
      clipCategories,
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

      // Validate frame data dimensions
      if (frame.data.length != frame.width * frame.height * 3) {
        debugPrint('VisualAnalysisService: Frame ${frame.frameNumber ?? i} '
            'has invalid data size: ${frame.data.length} '
            '(expected ${frame.width * frame.height * 3})');
        results.add(FrameAnalysisResult.safe(
          frameNumber: frame.frameNumber ?? i,
          timestamp: frame.timestamp,
          isSceneChange: frame.isSceneChange,
        ));
        continue;
      }

      try {
        // Run inference for each enabled detection type
        var nsfw = NsfwResult.safe();
        var violence = ViolenceResult.safe();
        BloodResult? blood;
        WeaponsResult? weapons;
        VisualContentResult? visualContent;

        // NSFW detection using selected model
        if (settings.enableNsfw) {
          final modelPath = _loadedModels[settings.nsfwModelId];

          if (modelPath != null) {
            final scores = await onnx.runInference(
              modelPath,
              frame.data.toList(),
              frame.width,
              frame.height,
            );

            nsfw = NsfwResult(
              porn: scores['porn'] ?? 0,
              sexy: scores['sexy'] ?? 0,
              hentai: scores['hentai'] ?? 0,
              drawings: scores['drawings'] ?? 0,
              neutral: scores['neutral'] ?? 1,
            );
          }
        }

        // Violence detection using selected model
        if (settings.enableViolence) {
          final modelPath = _loadedModels[settings.violenceModelId];

          if (modelPath != null) {
            final scores = await onnx.runInference(
              modelPath,
              frame.data.toList(),
              frame.width,
              frame.height,
            );

            violence = ViolenceResult(
              violent: scores['violent'] ?? 0,
              nonViolent: scores['non_violent'] ?? 1,
            );
          }
        }

        // Blood detection using selected model
        if (settings.enableBlood) {
          final modelPath = _loadedModels[settings.bloodModelId];

          if (modelPath != null) {
            final scores = await onnx.runInference(
              modelPath,
              frame.data.toList(),
              frame.width,
              frame.height,
            );

            blood = BloodResult(score: scores['blood'] ?? scores['gore'] ?? 0);
          } else {
            blood = const BloodResult(score: 0);
          }
        }

        // Weapons detection using selected model
        if (settings.enableWeapons) {
          final modelPath = _loadedModels[settings.weaponsModelId];

          if (modelPath != null) {
            final scores = await onnx.runInference(
              modelPath,
              frame.data.toList(),
              frame.width,
              frame.height,
            );

            weapons = WeaponsResult(
                score: scores['weapons'] ?? scores['weapon'] ?? 0);
          } else {
            weapons = const WeaponsResult(score: 0);
          }
        }

        // Visual content detection (NudeNet + CLIP)
        visualContent = await _analyzeVisualContent(
          frame,
          nsfw,
          settings,
        );

        results.add(FrameAnalysisResult(
          frameNumber: frame.frameNumber ?? i,
          timestamp: frame.timestamp,
          nsfw: nsfw,
          violence: violence,
          blood: blood,
          weapons: weapons,
          visualContent: visualContent,
          isSceneChange: frame.isSceneChange,
        ));
      } catch (e) {
        // Per-frame resilience: on failure, emit safe result and continue
        debugPrint('VisualAnalysisService: Frame ${frame.frameNumber ?? i} '
            'analysis failed: $e');
        results.add(FrameAnalysisResult.safe(
          frameNumber: frame.frameNumber ?? i,
          timestamp: frame.timestamp,
          isSceneChange: frame.isSceneChange,
        ));
      }
    }

    return results;
  }

  /// Analyze a frame for visual content using NudeNet and CLIP.
  ///
  /// Pipeline:
  /// 1. CLIP path (unconditional if CLIP enabled + any CLIP category enabled)
  /// 2. NudeNet path (gated by NSFW pre-filter if enabled)
  Future<VisualContentResult?> _analyzeVisualContent(
    FrameData frame,
    NsfwResult nsfwResult,
    VisualAnalysisSettings settings,
  ) async {
    final visualConfig = settings.visualContentConfig;
    if (visualConfig == null) return null;
    if (!visualConfig.hasAnyEnabled) return null;

    var detectedRegions = <DetectedRegion>[];
    var clipScores = <String, double>{};

    // 1. CLIP path: runs unconditionally if CLIP is enabled and categories exist
    if (visualConfig.enableClipClassification &&
        visualConfig.hasClipCategories &&
        clipService != null &&
        _clipEmbeddings != null &&
        _clipEmbeddings!.isNotEmpty) {
      try {
        clipScores = await clipService!.classifyFrame(
          Uint8List.fromList(frame.data),
          frame.width,
          frame.height,
          _clipEmbeddings!,
        );
      } catch (e) {
        debugPrint('VisualAnalysisService: CLIP classification failed: $e');
      }
    }

    // 2. NudeNet path: gated by NSFW pre-filter
    if (visualConfig.enableNudeNetDetection &&
        visualConfig.hasNudeNetCategories &&
        nudeNetService != null) {
      final shouldRunNudeNet = !visualConfig.useNsfwPreFilter ||
          nsfwResult.maxNsfwScore >= visualConfig.effectivePreFilterThreshold;

      if (shouldRunNudeNet) {
        try {
          final nudeNetModelPath = await nudeNetService!.getModelPath();
          if (nudeNetModelPath != null) {
            detectedRegions = await nudeNetService!.detectRegions(
              modelPath: nudeNetModelPath,
              rgbData: Uint8List.fromList(frame.data),
              width: frame.width,
              height: frame.height,
              categories: visualConfig.enabledCategories,
            );
          }
        } catch (e) {
          debugPrint('VisualAnalysisService: NudeNet detection failed: $e');
        }
      }
    }

    // Only return a result if there are any detections
    if (detectedRegions.isEmpty && clipScores.isEmpty) {
      return null;
    }

    return VisualContentResult(
      detectedRegions: detectedRegions,
      clipScores: clipScores,
    );
  }

  /// Pre-compute CLIP text embeddings for the current analysis settings.
  ///
  /// Must be called before starting analysis if CLIP categories are enabled.
  Future<void> precomputeClipEmbeddings(
    List<VisualContentCategory> categories,
  ) async {
    if (clipService == null) return;

    final clipCategories = categories.where((c) => c.enabled && c.usesClip).toList();
    if (clipCategories.isEmpty) {
      _clipEmbeddings = {};
      return;
    }

    _clipEmbeddings = await clipService!.precomputePromptEmbeddings(clipCategories);
  }

  /// Ensure required models are loaded based on settings
  Future<void> _ensureModelsLoaded(VisualAnalysisSettings settings) async {
    // Determine which models we need based on settings model IDs
    final requiredModels = <String>[];

    if (settings.enableNsfw) {
      requiredModels.add(settings.nsfwModelId);
    }

    if (settings.enableViolence) {
      requiredModels.add(settings.violenceModelId);
    }

    if (settings.enableBlood) {
      requiredModels.add(settings.bloodModelId);
    }

    if (settings.enableWeapons) {
      requiredModels.add(settings.weaponsModelId);
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

  /// Validate that all required models for the given settings are downloaded.
  ///
  /// Returns a list of missing model descriptions. Empty list means all
  /// models are available.
  Future<List<String>> validateRequiredModels(
    VisualAnalysisSettings settings,
  ) async {
    final missing = <String>[];

    // Check standard models
    final standardModels = <String, String>{};
    if (settings.enableNsfw) {
      standardModels[settings.nsfwModelId] = 'NSFW classifier';
    }
    if (settings.enableViolence) {
      standardModels[settings.violenceModelId] = 'Violence classifier';
    }
    if (settings.enableBlood) {
      standardModels[settings.bloodModelId] = 'Blood/gore classifier';
    }
    if (settings.enableWeapons) {
      standardModels[settings.weaponsModelId] = 'Weapons detector';
    }

    for (final entry in standardModels.entries) {
      final path = await modelManager.getModelPath(entry.key);
      if (path == null) {
        missing.add('${entry.value} (${entry.key})');
      }
    }

    // Check visual content models
    final visualConfig = settings.visualContentConfig;
    if (visualConfig != null && visualConfig.hasAnyEnabled) {
      if (visualConfig.enableNudeNetDetection &&
          visualConfig.hasNudeNetCategories) {
        if (nudeNetService != null) {
          final nudeNetPath = await nudeNetService!.getModelPath();
          if (nudeNetPath == null) {
            missing.add('NudeNet model (required for region detection)');
          }
        } else {
          missing.add('NudeNet service not configured');
        }
      }

      if (visualConfig.enableClipClassification &&
          visualConfig.hasClipCategories) {
        if (clipService == null) {
          missing.add('CLIP service not configured');
        }
        // CLIP model paths are managed by ClipService internally
      }
    }

    return missing;
  }

  /// Release all resources
  void dispose() {
    _isCancelled = true;
    _loadedModels.values.forEach(onnx.unloadModel);
    _loadedModels.clear();
    _clipEmbeddings = null;
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
