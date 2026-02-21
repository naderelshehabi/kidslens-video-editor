import 'dart:async';
import 'dart:typed_data';

import 'package:kidslens_video_editor/data/models/models.dart';
import 'package:kidslens_video_editor/native/bindings/ffmpeg_bindings.dart';
import 'package:kidslens_video_editor/native/bindings/mms_bindings.dart';
import 'package:kidslens_video_editor/native/bindings/onnx_bindings.dart';
import 'package:kidslens_video_editor/native/bindings/whisper_bindings.dart';
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

  factory AnalysisCheckpoint.fromJson(Map<String, dynamic> json) => AnalysisCheckpoint(
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
              .map((e) => FrameAnalysisResult.fromJson(e as Map<String, dynamic>))
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
    required this.onnx,
    required this.modelManager,
    required this.profanity,
    this.visualAnalysis,
  });

  final FFmpegBindings ffmpeg;
  final WhisperBindings whisper;
  final MMSBindings mms;
  final ONNXBindings onnx;
  final ModelManagerService modelManager;
  final ProfanityService profanity;
  final VisualAnalysisService? visualAnalysis;

  /// Run complete analysis on a media file
  Stream<AnalysisProgress> analyze(
    String mediaPath,
    AnalysisSettings settings, {
    AnalysisCheckpoint? checkpoint,
    Transcript? existingTranscript,
  }) async* {
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

    Transcript? transcript;
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
      transcript = await _transcribeAudio(mediaPath, settings);
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

    // Phase 2: Detect profanity in transcript
    List<ProfanityMatch> profanityMatches;
    if (checkpoint?.profanityMatches == null) {
      yield const AnalysisProgress(
        stepName: 'Detecting profanity',
        currentStep: 2,
        totalSteps: 4,
        stepProgress: 0,
      );
      profanityMatches = await _detectProfanity(transcript!, settings);
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

    // Phase 3: Analyze video frames
    final frameResults = <FrameAnalysisResult>[];
    final moeResults = <MoEFrameResult>[];
    final startFrame = checkpoint?.lastAnalyzedFrame ?? 0;

    // Restore previous frame results if resuming
    if (checkpoint?.frameResults != null) {
      frameResults.addAll(checkpoint!.frameResults!);
    }

    yield AnalysisProgress(
      stepName: 'Analyzing video frames',
      currentStep: 3,
      totalSteps: 4,
      stepProgress: 0,
      itemsProcessed: startFrame,
    );

    if (_hasVisualCategories(settings)) {
      final useMoE = visualAnalysis != null &&
          settings.contentDetectionConfig.hasVisualCategories;

      if (useMoE) {
        // MoE pipeline: use ContentDetectionConfig with per-category model voting
        await for (final result in _analyzeFramesMoE(mediaPath, settings, startFrame)) {
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
      } else {
        // Legacy pipeline: use per-type enable flags and model IDs
        await for (final result in _analyzeFrames(mediaPath, settings, startFrame)) {
          frameResults.add(result.frame);
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
    }

    // Phase 4: Build unified timeline
    yield const AnalysisProgress(
      stepName: 'Building timeline',
      currentStep: 4,
      totalSteps: 4,
      stepProgress: 0.5,
    );

    // Build the timeline (result used for side effects - timeline is stored)
    await _buildTimeline(
      mediaPath,
      profanityMatches,
      frameResults,
      settings,
      moeResults: moeResults,
    );

    yield AnalysisProgress(
      stepName: 'Complete',
      currentStep: 4,
      totalSteps: 4,
      stepProgress: 1,
      itemsProcessed: frameResults.length,
      totalItems: frameResults.length,
    );
  }

  Future<Transcript> _transcribeAudio(
    String mediaPath,
    AnalysisSettings settings,
  ) async {
    final asrModel = settings.modelConfig.asrModelId;
    final modelPath = await modelManager.getModelPath(asrModel);

    if (modelPath == null) {
      throw AnalysisException('ASR model not downloaded: $asrModel');
    }

    // Use Whisper or MMS based on model type
    if (asrModel.startsWith('whisper')) {
      return whisper.transcribe(mediaPath, modelPath);
    } else {
      return mms.transcribe(mediaPath, modelPath);
    }
  }

  Future<List<ProfanityMatch>> _detectProfanity(
    Transcript transcript,
    AnalysisSettings settings,
  ) async {
    if (!settings.enableProfanity && !_hasProfanityCategory(settings)) return [];

    profanity
      ..addCustomWords(settings.profanityConfig.customWords)
      ..excludeWords(settings.profanityConfig.excludedWords);

    return profanity.detect(transcript);
  }

  Stream<_FrameAnalysisProgress> _analyzeFrames(
    String mediaPath,
    AnalysisSettings settings,
    int startFrame,
  ) async* {
    // Get total frame count for progress
    final metadata = await ffmpeg.probeMedia(mediaPath);
    final fps = metadata.frameRate;
    final totalSeconds = metadata.duration.inMilliseconds / 1000.0;
    final samplingRate = settings.frameSamplingRate;
    final samplingFps = fps / samplingRate;
    final totalFrames = (totalSeconds * samplingFps).ceil();

    // Load models using IDs from settings
    final nsfwModelPath = settings.enableNsfw
        ? await modelManager.getModelPath(settings.modelConfig.nsfwModelId)
        : null;
    final violenceModelPath = settings.enableViolence
        ? await modelManager.getModelPath(settings.modelConfig.violenceModelId)
        : null;
    final bloodModelPath = settings.enableBlood
        ? await modelManager.getModelPath(settings.modelConfig.bloodModelId)
        : null;
    final weaponsModelPath = settings.enableWeapons
        ? await modelManager.getModelPath(settings.modelConfig.weaponsModelId)
        : null;

    var frameNumber = startFrame;
    await for (final frameData in ffmpeg.extractFrames(mediaPath, fps: samplingFps)) {
      frameNumber++;

      try {
        // Run NSFW detection
        var nsfwResult = NsfwResult.safe();
        if (nsfwModelPath != null) {
          final nsfwScores = await onnx.runInference(
            nsfwModelPath,
            frameData.rgbData,
            frameData.width,
            frameData.height,
          );
          nsfwResult = NsfwResult(
            porn: nsfwScores['porn'] ?? 0.0,
            sexy: nsfwScores['sexy'] ?? 0.0,
            hentai: nsfwScores['hentai'] ?? 0.0,
            drawings: nsfwScores['drawings'] ?? 0.0,
            neutral: nsfwScores['neutral'] ?? 0.0,
          );
        }

        // Run violence detection
        var violenceResult = ViolenceResult.safe();
        if (violenceModelPath != null) {
          final violenceScores = await onnx.runInference(
            violenceModelPath,
            frameData.rgbData,
            frameData.width,
            frameData.height,
          );
          violenceResult = ViolenceResult(
            violent: violenceScores['violent'] ?? 0.0,
            nonViolent: violenceScores['non_violent'] ?? 0.0,
          );
        }

        // Run blood/gore detection
        BloodResult? bloodResult;
        if (bloodModelPath != null) {
          final bloodScores = await onnx.runInference(
            bloodModelPath,
            frameData.rgbData,
            frameData.width,
            frameData.height,
          );
          bloodResult = BloodResult(
            score: bloodScores['blood'] ?? bloodScores['gore'] ?? 0.0,
          );
        }

        // Run weapons detection
        WeaponsResult? weaponsResult;
        if (weaponsModelPath != null) {
          final weaponsScores = await onnx.runInference(
            weaponsModelPath,
            frameData.rgbData,
            frameData.width,
            frameData.height,
          );
          weaponsResult = WeaponsResult(
            score: weaponsScores['weapons'] ?? weaponsScores['weapon'] ?? 0.0,
          );
        }

        yield _FrameAnalysisProgress(
          frame: FrameAnalysisResult(
            frameNumber: frameNumber,
            timestamp: frameData.timestamp,
            nsfw: nsfwResult,
            violence: violenceResult,
            blood: bloodResult,
            weapons: weaponsResult,
          ),
          frameNumber: frameNumber,
          totalFrames: totalFrames,
          progress: frameNumber / totalFrames,
        );
      } catch (e) {
        // Per-frame resilience: emit safe result on failure and continue
        yield _FrameAnalysisProgress(
          frame: FrameAnalysisResult.safe(
            frameNumber: frameNumber,
            timestamp: frameData.timestamp,
          ),
          frameNumber: frameNumber,
          totalFrames: totalFrames,
          progress: frameNumber / totalFrames,
        );
      }
    }
  }

  Future<UnifiedTimeline> _buildTimeline(
    String mediaPath,
    List<ProfanityMatch> profanityMatches,
    List<FrameAnalysisResult> frameResults,
    AnalysisSettings settings, {
    List<MoEFrameResult> moeResults = const [],
  }) async {
    final detections = <Detection>[];
    final metadata = await ffmpeg.probeMedia(mediaPath);

    // Convert profanity matches to detections (word stored in metadata)
    for (final match in profanityMatches) {
      if (match.confidence >= settings.profanityConfig.fuzzyThreshold) {
        detections.add(Detection.profanity(
          id: 'profanity_${detections.length}',
          mediaId: mediaPath,
          startTime: match.word.startTime,
          endTime: match.word.endTime,
          confidence: match.confidence,
          word: match.word.word,
        ),);
      }
    }

    // Convert MoE frame results to detections (new pipeline)
    if (moeResults.isNotEmpty) {
      final moeDetections = _aggregateMoEResults(moeResults, settings, mediaPath);
      detections.addAll(moeDetections);
    }

    // Convert legacy frame results to detections using temporal aggregation
    if (frameResults.isNotEmpty) {
      final aggregatedSegments = _aggregateFrameResults(frameResults, settings);
      for (final segment in aggregatedSegments) {
        detections.add(Detection(
          id: '${segment.type.name}_${detections.length}',
          mediaId: mediaPath,
          type: segment.type,
          startTime: segment.start,
          endTime: segment.end,
          confidence: segment.confidence,
          description: _getDescriptionForType(segment.type),
          source: 'video',
        ),);
      }
    }

    return UnifiedTimeline.fromDetections(
      id: 'timeline_${DateTime.now().millisecondsSinceEpoch}',
      mediaDuration: metadata.duration,
      detections: detections,
    );
  }

  String _getDescriptionForType(ContentType type) {
    switch (type) {
      case ContentType.nsfw:
        return 'NSFW content detected';
      case ContentType.violence:
        return 'Violent content detected';
      case ContentType.blood:
        return 'Blood/gore detected';
      case ContentType.profanity:
        return 'Profanity detected';
      case ContentType.weapons:
        return 'Weapon detected';
      case ContentType.nudity:
        return 'Nudity detected';
      case ContentType.sexualContent:
        return 'Sexual content detected';
      case ContentType.kissing:
        return 'Kissing detected';
      case ContentType.immodestDress:
        return 'Immodest dress detected';
      case ContentType.custom:
        return 'Custom content detected';
    }
  }

  List<_AggregatedSegment> _aggregateFrameResults(
    List<FrameAnalysisResult> frameResults,
    AnalysisSettings settings,
  ) {
    final segments = <_AggregatedSegment>[];

    // Simple aggregation - group consecutive frames with high scores
    _AggregatedSegment? currentSegment;

    for (final frame in frameResults) {
      // Check for nudity
      final nudityScore = frame.nsfw.maxNsfwScore;

      if (nudityScore >= settings.nsfwThreshold) {
        if (currentSegment == null || currentSegment.type != ContentType.nsfw) {
          if (currentSegment != null) segments.add(currentSegment);
          currentSegment = _AggregatedSegment(
            type: ContentType.nsfw,
            start: frame.timestamp,
            end: frame.timestamp,
            confidence: nudityScore,
          );
        } else {
          currentSegment = currentSegment.copyWith(
            end: frame.timestamp,
            confidence: (currentSegment.confidence + nudityScore) / 2,
          );
        }
        continue;
      }

      // Check for violence
      final violenceScore = frame.violence.violent;
      if (violenceScore >= settings.violenceThreshold) {
        if (currentSegment == null || currentSegment.type != ContentType.violence) {
          if (currentSegment != null) segments.add(currentSegment);
          currentSegment = _AggregatedSegment(
            type: ContentType.violence,
            start: frame.timestamp,
            end: frame.timestamp,
            confidence: violenceScore,
          );
        } else {
          currentSegment = currentSegment.copyWith(
            end: frame.timestamp,
            confidence: (currentSegment.confidence + violenceScore) / 2,
          );
        }
        continue;
      }

      // No detection - close current segment if any
      if (currentSegment != null) {
        segments.add(currentSegment);
        currentSegment = null;
      }
    }

    if (currentSegment != null) {
      segments.add(currentSegment);
    }

    return segments;
  }

  /// Analyze frames using the MoE pipeline (ContentDetectionConfig).
  ///
  /// Delegates to [VisualAnalysisService.analyzeFrameWithMoE] for per-category
  /// weighted voting across multiple models.
  Stream<_MoEFrameProgress> _analyzeFramesMoE(
    String mediaPath,
    AnalysisSettings settings,
    int startFrame,
  ) async* {
    final config = settings.contentDetectionConfig;
    final service = visualAnalysis!;

    // Compute total frames for progress reporting
    final metadata = await ffmpeg.probeMedia(mediaPath);
    final fps = metadata.frameRate;
    final totalSeconds = metadata.duration.inMilliseconds / 1000.0;
    final samplingRate = settings.frameSamplingRate;
    final samplingFps = fps / samplingRate;
    final totalFrames = (totalSeconds * samplingFps).ceil();

    // Pre-load all classifier models (ONNX)
    await service.ensureMoEModelsLoaded(config);

    // Pre-compute CLIP text embeddings for any CLIP-based categories
    if (config.clipCategories.isNotEmpty) {
      await service.precomputeClipEmbeddingsForCategories(
        config.enabledVisualCategories,
      );
    }

    var frameNumber = startFrame;
    await for (final frameData in ffmpeg.extractFrames(
      mediaPath,
      fps: samplingFps,
      startFrame: startFrame > 0 ? startFrame : null,
    )) {
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
            detections.add(Detection(
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
            ),);
            segmentStart = null;
            segmentEnd = null;
            confidenceSum = 0.0;
            confidenceCount = 0;
          }
        }
      }

      // Close any segment still open at end of video
      if (segmentStart != null && segmentEnd != null) {
        detections.add(Detection(
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
        ),);
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

  /// Whether the settings have any visual detection categories enabled.
  bool _hasVisualCategories(AnalysisSettings settings) =>
      settings.enableNsfw ||
      settings.enableViolence ||
      settings.enableBlood ||
      settings.enableWeapons ||
      settings.contentDetectionConfig.hasVisualCategories;

  /// Whether the settings have a profanity category enabled.
  bool _hasProfanityCategory(AnalysisSettings settings) =>
      settings.contentDetectionConfig.enabledAudioCategories.any(
        (c) => c.id == 'profanity',
      );
}

class _FrameAnalysisProgress {
  _FrameAnalysisProgress({
    required this.frame,
    required this.frameNumber,
    required this.totalFrames,
    required this.progress,
  });

  final FrameAnalysisResult frame;
  final int frameNumber;
  final int totalFrames;
  final double progress;
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

class _AggregatedSegment {
  _AggregatedSegment({
    required this.type,
    required this.start,
    required this.end,
    required this.confidence,
  });

  final ContentType type;
  final Duration start;
  final Duration end;
  final double confidence;

  _AggregatedSegment copyWith({
    ContentType? type,
    Duration? start,
    Duration? end,
    double? confidence,
  }) => _AggregatedSegment(
      type: type ?? this.type,
      start: start ?? this.start,
      end: end ?? this.end,
      confidence: confidence ?? this.confidence,
    );
}

/// Exception thrown during analysis
class AnalysisException implements Exception {
  AnalysisException(this.message);

  final String message;

  @override
  String toString() => 'AnalysisException: $message';
}
