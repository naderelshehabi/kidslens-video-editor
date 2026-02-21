import 'dart:async';
import 'dart:typed_data';

import 'package:kidslens_video_editor/data/models/models.dart';
import 'package:kidslens_video_editor/jobs/cancellation_token.dart';
import 'package:kidslens_video_editor/native/bindings/ffmpeg_bindings.dart';
import 'package:kidslens_video_editor/native/bindings/mms_bindings.dart';
import 'package:kidslens_video_editor/native/bindings/whisper_bindings.dart';
import 'package:kidslens_video_editor/services/asr_service.dart';
import 'package:kidslens_video_editor/services/model_manager_service.dart';
import 'package:kidslens_video_editor/services/profanity_service.dart';
import 'package:kidslens_video_editor/services/visual_analysis_service.dart';

/// Checkpoint for resuming analysis
class AnalysisCheckpoint {
  AnalysisCheckpoint({
    required this.timestamp,
    this.transcript,
    this.profanityMatches,
    this.lastAnalyzedFrame = 0,
    this.frameResults,
  });

  factory AnalysisCheckpoint.fromJson(Map<String, dynamic> json) =>
      AnalysisCheckpoint(
        transcript: json['transcript'] != null
            ? Transcript.fromJson(json['transcript'] as Map<String, dynamic>)
            : null,
        profanityMatches: json['profanityMatches'] != null
            ? (json['profanityMatches'] as List)
                .map((e) => ProfanityMatch.fromJson(e as Map<String, dynamic>))
                .toList()
            : null,
        lastAnalyzedFrame: json['lastAnalyzedFrame'] as int? ?? 0,
        frameResults: json['frameResults'] != null
            ? (json['frameResults'] as List)
                .map(
                  (e) =>
                      FrameAnalysisResult.fromJson(e as Map<String, dynamic>),
                )
                .toList()
            : null,
        timestamp: DateTime.parse(json['timestamp'] as String),
      );

  final Transcript? transcript;
  final List<ProfanityMatch>? profanityMatches;
  final int lastAnalyzedFrame;
  final List<FrameAnalysisResult>? frameResults;
  final DateTime timestamp;

  Map<String, dynamic> toJson() => {
        'transcript': transcript?.toJson(),
        'profanityMatches': profanityMatches?.map((e) => e.toJson()).toList(),
        'lastAnalyzedFrame': lastAnalyzedFrame,
        'frameResults': frameResults?.map((e) => e.toJson()).toList(),
        'timestamp': timestamp.toIso8601String(),
      };
}

/// Service for running content analysis on media files
class AnalysisService {
  AnalysisService({
    required this.ffmpeg,
    required this.whisper,
    required this.mms,
    required this.modelManager,
    required this.profanity,
    this.asrService,
    this.visualAnalysis,
  });

  final FFmpegBindings ffmpeg;
  final WhisperBindings whisper;
  final MMSBindings mms;
  final ModelManagerService modelManager;
  final ProfanityService profanity;
  final AsrService? asrService;
  final VisualAnalysisService? visualAnalysis;

  /// Run complete analysis on a media file
  Stream<AnalysisProgress> analyze(
    String mediaPath,
    AnalysisSettings settings, {
    String? mediaId,
    AnalysisCheckpoint? checkpoint,
    Transcript? existingTranscript,
    CancellationToken? cancellationToken,
    void Function(UnifiedTimeline timeline)? onTimelineBuilt,
    void Function(List<Detection> detections)? onDetectionsBuilt,
  }) async* {
    final effectiveMediaId = mediaId ?? mediaPath;
    await _checkState(cancellationToken);

    yield const AnalysisProgress(
      stepName: 'Initializing',
      currentStep: 1,
      totalSteps: 4,
      stepProgress: 0,
    );

    // Phase 1: Extract audio and transcribe
    yield const AnalysisProgress(
      stepName: 'Extracting audio',
      currentStep: 1,
      totalSteps: 4,
      stepProgress: 0,
    );

    final shouldTranscribe = _hasProfanityCategory(settings);

    Transcript? transcript;
    if (shouldTranscribe) {
      if (existingTranscript != null) {
        // Reuse existing transcript — skip Whisper entirely
        transcript = existingTranscript;
        yield AnalysisProgress(
          stepName: 'Using existing transcript',
          currentStep: 1,
          totalSteps: 4,
          stepProgress: 1,
          itemsProcessed: transcript.segments.length,
          totalItems: transcript.segments.length,
        );
      } else if (checkpoint?.transcript == null) {
        transcript = await _transcribeAudio(
          mediaPath,
          settings,
          cancellationToken: cancellationToken,
        );
        yield AnalysisProgress(
          stepName: 'Audio transcription complete',
          currentStep: 1,
          totalSteps: 4,
          stepProgress: 1,
          itemsProcessed: transcript.segments.length,
          totalItems: transcript.segments.length,
        );
      } else {
        transcript = checkpoint!.transcript;
      }
    } else {
      yield const AnalysisProgress(
        stepName: 'Skipping audio transcription',
        currentStep: 1,
        totalSteps: 4,
        stepProgress: 1,
        itemsProcessed: 0,
        totalItems: 0,
      );
    }

    // Phase 2: Detect profanity in transcript
    List<ProfanityMatch> profanityMatches;
    if (shouldTranscribe) {
      await _checkState(cancellationToken);
      if (checkpoint?.profanityMatches == null) {
        yield const AnalysisProgress(
          stepName: 'Detecting profanity',
          currentStep: 2,
          totalSteps: 4,
          stepProgress: 0,
        );
        profanityMatches = await _detectProfanity(
          transcript!,
          settings,
          cancellationToken: cancellationToken,
        );
        yield AnalysisProgress(
          stepName: 'Profanity detection complete',
          currentStep: 2,
          totalSteps: 4,
          stepProgress: 1,
          itemsProcessed: profanityMatches.length,
          totalItems: profanityMatches.length,
        );
      } else {
        profanityMatches = checkpoint!.profanityMatches!;
      }
    } else {
      profanityMatches = [];
      yield const AnalysisProgress(
        stepName: 'Skipping profanity detection',
        currentStep: 2,
        totalSteps: 4,
        stepProgress: 1,
        itemsProcessed: 0,
        totalItems: 0,
      );
    }

    // Phase 3: Analyze video frames
    final moeResults = <MoEFrameResult>[];
    final startFrame = checkpoint?.lastAnalyzedFrame ?? 0;

    yield AnalysisProgress(
      stepName: 'Analyzing video frames',
      currentStep: 3,
      totalSteps: 4,
      stepProgress: 0,
      itemsProcessed: startFrame,
    );

    if (settings.contentDetectionConfig.hasVisualCategories) {
      if (visualAnalysis == null) {
        throw AnalysisException(
          'VisualAnalysisService is not configured for content detection.',
        );
      }
      await _validateRequiredVisualModels(settings);

      await for (final result in _analyzeFramesMoE(
        mediaPath,
        settings,
        startFrame,
        cancellationToken: cancellationToken,
      )) {
        moeResults.add(result.frame);
        yield AnalysisProgress(
          stepName: 'Analyzing video frames',
          currentStep: 3,
          totalSteps: 4,
          stepProgress: result.progress,
          itemsProcessed: result.frameNumber,
          totalItems: result.totalFrames,
        );
      }
    }

    // Phase 4: Build unified timeline
    yield const AnalysisProgress(
      stepName: 'Building timeline',
      currentStep: 4,
      totalSteps: 4,
      stepProgress: 0.5,
    );

    final timeline = await _buildTimeline(
      mediaPath,
      effectiveMediaId,
      profanityMatches,
      settings,
      moeResults: moeResults,
      onDetectionsBuilt: onDetectionsBuilt,
      cancellationToken: cancellationToken,
    );
    onTimelineBuilt?.call(timeline);

    yield AnalysisProgress(
      stepName: 'Complete',
      currentStep: 4,
      totalSteps: 4,
      stepProgress: 1,
      itemsProcessed: moeResults.length,
      totalItems: moeResults.length,
    );
  }

  Future<Transcript> _transcribeAudio(
    String mediaPath,
    AnalysisSettings settings, {
    CancellationToken? cancellationToken,
  }) async {
    await _checkState(cancellationToken);
    final asrModel = settings.modelConfig.asrModelId;
    final modelPath = await modelManager.getModelPath(asrModel);

    if (modelPath == null) {
      throw AnalysisException('ASR model not downloaded: $asrModel');
    }

    // Use cancellable ASR isolate path when available.
    if (asrService != null && asrModel.startsWith('whisper')) {
      final cancelCompleter = Completer<void>();
      cancellationToken?.onCancel(() {
        if (!cancelCompleter.isCompleted) {
          cancelCompleter.complete();
        }
      });
      try {
        return await asrService!.transcribeInBackground(
          mediaPath,
          preferredModel: asrModel,
          language: settings.modelConfig.asrLanguage == 'auto'
              ? null
              : settings.modelConfig.asrLanguage,
          useGpu: settings.modelConfig.useGpu,
          nThreads: settings.modelConfig.cpuThreads,
          beamSize: settings.modelConfig.beamSize,
          cancelToken: cancelCompleter,
        );
      } on AsrCancelledException {
        throw CancelledException();
      }
    }

    // Fallback to direct bindings.
    if (asrModel.startsWith('whisper')) {
      final transcript = await whisper.transcribe(mediaPath, modelPath);
      await _checkState(cancellationToken);
      return transcript;
    } else {
      final transcript = await mms.transcribe(mediaPath, modelPath);
      await _checkState(cancellationToken);
      return transcript;
    }
  }

  Future<List<ProfanityMatch>> _detectProfanity(
    Transcript transcript,
    AnalysisSettings settings, {
    CancellationToken? cancellationToken,
  }) async {
    await _checkState(cancellationToken);
    if (!_hasProfanityCategory(settings)) return [];

    profanity
      ..addCustomWords(settings.profanityConfig.customWords)
      ..excludeWords(settings.profanityConfig.excludedWords);

    final matches = profanity.detect(transcript);
    await _checkState(cancellationToken);
    return matches;
  }

  Future<UnifiedTimeline> _buildTimeline(
    String mediaPath,
    String mediaId,
    List<ProfanityMatch> profanityMatches,
    AnalysisSettings settings, {
    List<MoEFrameResult> moeResults = const [],
    void Function(List<Detection> detections)? onDetectionsBuilt,
    CancellationToken? cancellationToken,
  }) async {
    await _checkState(cancellationToken);
    final detections = <Detection>[];
    final metadata = await ffmpeg.probeMedia(mediaPath);

    // Convert profanity matches to detections (word stored in metadata)
    for (final match in profanityMatches) {
      if (match.confidence >= settings.profanityConfig.fuzzyThreshold) {
        detections.add(
          Detection.profanity(
            id: 'profanity_${detections.length}',
            mediaId: mediaId,
            startTime: match.word.startTime,
            endTime: match.word.endTime,
            confidence: match.confidence,
            word: match.word.word,
          ),
        );
      }
    }

    // Convert MoE frame results to detections (new pipeline)
    if (moeResults.isNotEmpty) {
      final moeDetections = _aggregateMoEResults(moeResults, settings, mediaId);
      detections.addAll(moeDetections);
    }

    final timeline = UnifiedTimeline.fromDetections(
      id: 'timeline_${DateTime.now().millisecondsSinceEpoch}',
      mediaDuration: metadata.duration,
      detections: detections,
    );
    await _checkState(cancellationToken);
    onDetectionsBuilt?.call(List<Detection>.unmodifiable(detections));
    return timeline;
  }

  /// Analyze frames using the MoE pipeline (ContentDetectionConfig).
  ///
  /// Delegates to [VisualAnalysisService.analyzeFrameWithMoE] for per-category
  /// weighted voting across multiple models.
  Stream<_MoEFrameProgress> _analyzeFramesMoE(
    String mediaPath,
    AnalysisSettings settings,
    int startFrame, {
    CancellationToken? cancellationToken,
  }) async* {
    final config = settings.contentDetectionConfig;
    final service = visualAnalysis!;
    cancellationToken?.onCancel(service.cancelAnalysis);

    // Compute total frames for progress reporting
    final metadata = await ffmpeg.probeMedia(mediaPath);
    final fps = metadata.frameRate;
    final totalSeconds = metadata.duration.inMilliseconds / 1000.0;
    final samplingRate = settings.frameSamplingRate;
    final samplingFps = fps / samplingRate;
    final totalFrames = (totalSeconds * samplingFps).ceil();

    // Pre-load all classifier models (ONNX)
    await service.ensureMoEModelsLoaded(config);
    await _checkState(cancellationToken);

    // Pre-compute CLIP text embeddings for any CLIP-based categories
    if (config.clipCategories.isNotEmpty) {
      await service.precomputeClipEmbeddingsForCategories(
        config.enabledVisualCategories,
      );
      await _checkState(cancellationToken);
    }

    var frameNumber = startFrame;
    await for (final frameData in ffmpeg.extractFrames(
      mediaPath,
      fps: samplingFps,
      startFrame: startFrame > 0 ? startFrame : null,
    )) {
      await _checkState(cancellationToken);
      frameNumber++;
      // Convert media-layer FrameData (rgbData: List<int>) to models FrameData
      // (data: Uint8List) expected by VisualAnalysisService.
      final modelsFrame = FrameData(
        timestamp: frameData.timestamp,
        width: frameData.width,
        height: frameData.height,
        data: Uint8List.fromList(frameData.rgbData),
        frameNumber: frameData.frameNumber,
      );
      try {
        final result = await service.analyzeFrameWithMoE(modelsFrame, config);
        await _checkState(cancellationToken);
        yield _MoEFrameProgress(
          frame: result,
          frameNumber: frameNumber,
          totalFrames: totalFrames,
          progress: frameNumber / totalFrames,
        );
      } catch (e) {
        // Per-frame resilience: emit empty result on failure and continue
        yield _MoEFrameProgress(
          frame: MoEFrameResult(
            timestamp: frameData.timestamp,
            frameNumber: frameNumber,
            categoryResults: {},
          ),
          frameNumber: frameNumber,
          totalFrames: totalFrames,
          progress: frameNumber / totalFrames,
        );
      }
    }
  }

  /// Aggregate [MoEFrameResult] list into [Detection] objects.
  ///
  /// Groups consecutive triggered frames per category into segments,
  /// using per-category thresholds and remediation actions.
  List<Detection> _aggregateMoEResults(
    List<MoEFrameResult> moeResults,
    AnalysisSettings settings,
    String mediaPath,
  ) {
    final detections = <Detection>[];
    final config = settings.contentDetectionConfig;

    // Build lookup for enabled visual categories
    final categoryMap = <String, ContentCategory>{
      for (final cat in config.enabledVisualCategories) cat.id: cat,
    };

    for (final entry in categoryMap.entries) {
      final categoryId = entry.key;
      final category = entry.value;
      final contentType = _contentTypeForCategoryId(categoryId);

      Duration? segmentStart;
      Duration? segmentEnd;
      var confidenceSum = 0.0;
      var confidenceCount = 0;

      for (final frame in moeResults) {
        final result = frame.categoryResults[categoryId];
        if (result != null && result.triggered) {
          segmentStart ??= frame.timestamp;
          segmentEnd = frame.timestamp;
          confidenceSum += result.finalScore;
          confidenceCount++;
        } else {
          // Close any open segment
          if (segmentStart != null && segmentEnd != null) {
            detections.add(
              Detection(
                id: '${categoryId}_${detections.length}',
                mediaId: mediaPath,
                type: contentType,
                startTime: segmentStart,
                endTime: segmentEnd,
                confidence:
                    confidenceCount > 0 ? confidenceSum / confidenceCount : 0.5,
                description: '${category.name} detected',
                source: 'video',
                metadata: {
                  'categoryId': categoryId,
                  'action': category.action.name,
                },
              ),
            );
            segmentStart = null;
            segmentEnd = null;
            confidenceSum = 0.0;
            confidenceCount = 0;
          }
        }
      }

      // Close any segment still open at end of video
      if (segmentStart != null && segmentEnd != null) {
        detections.add(
          Detection(
            id: '${categoryId}_${detections.length}',
            mediaId: mediaPath,
            type: contentType,
            startTime: segmentStart,
            endTime: segmentEnd,
            confidence:
                confidenceCount > 0 ? confidenceSum / confidenceCount : 0.5,
            description: '${category.name} detected',
            source: 'video',
            metadata: {
              'categoryId': categoryId,
              'action': category.action.name,
            },
          ),
        );
      }
    }

    return detections;
  }

  /// Map built-in category IDs to [ContentType] enum values.
  ContentType _contentTypeForCategoryId(String categoryId) {
    switch (categoryId) {
      case 'nsfw':
        return ContentType.nsfw;
      case 'violence':
        return ContentType.violence;
      case 'blood':
        return ContentType.blood;
      case 'weapons':
        return ContentType.weapons;
      case 'nudity':
        return ContentType.nudity;
      case 'sexual_content':
        return ContentType.sexualContent;
      case 'kissing':
        return ContentType.kissing;
      case 'immodest_dress':
        return ContentType.immodestDress;
      default:
        return ContentType.custom;
    }
  }

  /// Whether the settings have a profanity category enabled.
  bool _hasProfanityCategory(AnalysisSettings settings) =>
      settings.contentDetectionConfig.enabledAudioCategories.any(
        (c) => c.id == 'profanity',
      );

  Future<void> _checkState(CancellationToken? token) async {
    if (token != null) {
      await token.checkState();
    }
  }

  Future<void> _validateRequiredVisualModels(AnalysisSettings settings) async {
    final modelConfig = settings.modelConfig;
    final requiredModels = <String>{
      modelConfig.nudeNetModelId,
      modelConfig.clipVisionModelId,
      modelConfig.clipTextModelId,
    };

    final missing = <String>[];
    for (final modelId in requiredModels) {
      final modelPath = await modelManager.getModelPath(modelId);
      if (modelPath == null) {
        missing.add(modelId);
      }
    }

    if (missing.isNotEmpty) {
      throw AnalysisException(
        'Required visual models are missing: ${missing.join(', ')}. '
        'Open Models Management and download them before starting analysis.',
      );
    }
  }
}

class _MoEFrameProgress {
  _MoEFrameProgress({
    required this.frame,
    required this.frameNumber,
    required this.totalFrames,
    required this.progress,
  });

  final MoEFrameResult frame;
  final int frameNumber;
  final int totalFrames;
  final double progress;
}

/// Exception thrown during analysis
class AnalysisException implements Exception {
  AnalysisException(this.message);

  final String message;

  @override
  String toString() => 'AnalysisException: $message';
}
