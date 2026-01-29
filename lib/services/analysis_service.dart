import 'dart:async';

import 'package:kidslens_video_editor/data/models/models.dart';
import 'package:kidslens_video_editor/native/bindings/ffmpeg_bindings.dart';
import 'package:kidslens_video_editor/native/bindings/mms_bindings.dart';
import 'package:kidslens_video_editor/native/bindings/onnx_bindings.dart';
import 'package:kidslens_video_editor/native/bindings/whisper_bindings.dart';
import 'package:kidslens_video_editor/services/model_manager_service.dart';
import 'package:kidslens_video_editor/services/profanity_service.dart';

/// Checkpoint for resuming analysis
class AnalysisCheckpoint {
  AnalysisCheckpoint({
    required this.timestamp,
    this.transcript,
    this.profanityMatches,
    this.lastAnalyzedFrame = 0,
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
      timestamp: DateTime.parse(json['timestamp'] as String),
    );

  final Transcript? transcript;
  final List<ProfanityMatch>? profanityMatches;
  final int lastAnalyzedFrame;
  final DateTime timestamp;

  Map<String, dynamic> toJson() => {
        'transcript': transcript?.toJson(),
        'profanityMatches': profanityMatches?.map((e) => e.toJson()).toList(),
        'lastAnalyzedFrame': lastAnalyzedFrame,
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
  });

  final FFmpegBindings ffmpeg;
  final WhisperBindings whisper;
  final MMSBindings mms;
  final ONNXBindings onnx;
  final ModelManagerService modelManager;
  final ProfanityService profanity;

  /// Run complete analysis on a media file
  Stream<AnalysisProgress> analyze(
    String mediaPath,
    AnalysisSettings settings, {
    AnalysisCheckpoint? checkpoint,
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
    if (checkpoint?.transcript == null) {
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
    final startFrame = checkpoint?.lastAnalyzedFrame ?? 0;

    yield AnalysisProgress(
      stepName: 'Analyzing video frames',
      currentStep: 3,
      totalSteps: 4,
      stepProgress: 0,
      itemsProcessed: startFrame,
    );

    if (settings.enableNsfw || settings.enableViolence || settings.enableBlood) {
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
    if (!settings.enableProfanity) return [];

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

    // Load models
    final nsfwModelPath = settings.enableNsfw
        ? await modelManager.getModelPath('nsfw-mobilenet-v2')
        : null;
    final violenceModelPath = settings.enableViolence
        ? await modelManager.getModelPath('violence-mobilenet')
        : null;

    var frameNumber = startFrame;
    await for (final frameData in ffmpeg.extractFrames(mediaPath, fps: samplingFps)) {
      frameNumber++;

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

      yield _FrameAnalysisProgress(
        frame: FrameAnalysisResult(
          frameNumber: frameNumber,
          timestamp: frameData.timestamp,
          nsfw: nsfwResult,
          violence: violenceResult,
        ),
        frameNumber: frameNumber,
        totalFrames: totalFrames,
        progress: frameNumber / totalFrames,
      );
    }
  }

  Future<UnifiedTimeline> _buildTimeline(
    String mediaPath,
    List<ProfanityMatch> profanityMatches,
    List<FrameAnalysisResult> frameResults,
    AnalysisSettings settings,
  ) async {
    final detections = <Detection>[];
    final metadata = await ffmpeg.probeMedia(mediaPath);

    // Convert profanity matches to detections
    for (final match in profanityMatches) {
      if (match.confidence >= settings.profanityConfig.fuzzyThreshold) {
        detections.add(Detection(
          id: 'profanity_${detections.length}',
          mediaId: mediaPath, // Use path as mediaId for now
          type: ContentType.profanity,
          startTime: match.word.startTime,
          endTime: match.word.endTime,
          confidence: match.confidence,
          description: 'Profanity detected: "${match.word.word}"',
          source: 'audio',
        ),);
      }
    }

    // Convert frame results to detections using temporal aggregation
    final aggregatedSegments = _aggregateFrameResults(frameResults, settings);
    for (final segment in aggregatedSegments) {
      detections.add(Detection(
        id: '${segment.type.name}_${detections.length}',
        mediaId: mediaPath, // Use path as mediaId for now
        type: segment.type,
        startTime: segment.start,
        endTime: segment.end,
        confidence: segment.confidence,
        description: _getDescriptionForType(segment.type),
        source: 'video',
      ),);
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
