import 'dart:async';

import 'package:kidslens_video_editor/data/models/models.dart';
import 'package:kidslens_video_editor/jobs/cancellation_token.dart';
import 'package:kidslens_video_editor/native/bindings/ffmpeg_bindings.dart';
import 'package:kidslens_video_editor/native/bindings/mms_bindings.dart';
import 'package:kidslens_video_editor/native/bindings/whisper_bindings.dart';
import 'package:kidslens_video_editor/services/asr_service.dart';
import 'package:kidslens_video_editor/services/model_manager_service.dart';
import 'package:kidslens_video_editor/services/profanity_service.dart';

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
  });

  final FFmpegBindings ffmpeg;
  final WhisperBindings whisper;
  final MMSBindings mms;
  final ModelManagerService modelManager;
  final ProfanityService profanity;
  final AsrService? asrService;

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
    final mediaMetadata = await ffmpeg.probeMedia(mediaPath);
    final mediaDurationMs = mediaMetadata.duration.inMilliseconds <= 0
        ? 1
        : mediaMetadata.duration.inMilliseconds;

    yield _durationProgress(
      stepName: 'Initializing analysis',
      processedDurationMs: 0,
      totalDurationMs: mediaDurationMs,
    );

    // Phase 1: Extract audio and transcribe
    yield _durationProgress(
      stepName: 'Preparing audio for transcription',
      processedDurationMs: 0,
      totalDurationMs: mediaDurationMs,
    );

    final shouldTranscribe = _hasProfanityCategory(settings);

    Transcript? transcript;
    if (shouldTranscribe) {
      if (existingTranscript != null) {
        // Reuse existing transcript — skip Whisper entirely
        transcript = existingTranscript;
        yield _durationProgress(
          stepName:
              'Using existing transcript (${transcript.segments.length} segments)',
          processedDurationMs: mediaDurationMs,
          totalDurationMs: mediaDurationMs,
          itemsProcessed: transcript.segments.length,
          totalItems: transcript.segments.length,
        );
      } else if (checkpoint?.transcript == null) {
        transcript = await _transcribeAudio(
          mediaPath,
          settings,
          cancellationToken: cancellationToken,
        );
        yield _durationProgress(
          stepName:
              'Audio transcription complete (${transcript.segments.length} segments)',
          processedDurationMs: mediaDurationMs,
          totalDurationMs: mediaDurationMs,
          itemsProcessed: transcript.segments.length,
          totalItems: transcript.segments.length,
        );
      } else {
        transcript = checkpoint!.transcript;
        yield _durationProgress(
          stepName:
              'Using transcription from checkpoint (${transcript!.segments.length} segments)',
          processedDurationMs: mediaDurationMs,
          totalDurationMs: mediaDurationMs,
          itemsProcessed: transcript.segments.length,
          totalItems: transcript.segments.length,
        );
      }
    } else {
      yield _durationProgress(
        stepName: 'Skipping audio transcription (audio categories disabled)',
        processedDurationMs: 0,
        totalDurationMs: mediaDurationMs,
        itemsProcessed: 0,
        totalItems: 0,
      );
    }

    // Phase 2: Detect profanity in transcript
    List<ProfanityMatch> profanityMatches;
    if (shouldTranscribe) {
      await _checkState(cancellationToken);
      if (checkpoint?.profanityMatches == null) {
        yield _durationProgress(
          stepName: 'Detecting profanity in transcript',
          processedDurationMs: mediaDurationMs,
          totalDurationMs: mediaDurationMs,
        );
        profanityMatches = await _detectProfanity(
          transcript!,
          settings,
          cancellationToken: cancellationToken,
        );
        yield _durationProgress(
          stepName:
              'Profanity detection complete (${profanityMatches.length} matches)',
          processedDurationMs: mediaDurationMs,
          totalDurationMs: mediaDurationMs,
          itemsProcessed: profanityMatches.length,
          totalItems: profanityMatches.length,
        );
      } else {
        profanityMatches = checkpoint!.profanityMatches!;
        yield _durationProgress(
          stepName:
              'Using profanity results from checkpoint (${profanityMatches.length} matches)',
          processedDurationMs: mediaDurationMs,
          totalDurationMs: mediaDurationMs,
          itemsProcessed: profanityMatches.length,
          totalItems: profanityMatches.length,
        );
      }
    } else {
      profanityMatches = [];
      yield _durationProgress(
        stepName: 'Skipping profanity detection (no audio categories enabled)',
        processedDurationMs: 0,
        totalDurationMs: mediaDurationMs,
        itemsProcessed: 0,
        totalItems: 0,
      );
    }

    // Phase 3: Visual analysis removed in ASR-only mode.
    yield _durationProgress(
      stepName: 'Skipping visual analysis (ASR-only pipeline)',
      processedDurationMs: mediaDurationMs,
      totalDurationMs: mediaDurationMs,
      itemsProcessed: 0,
      totalItems: 0,
    );

    // Phase 4: Build unified timeline
    yield _durationProgress(
      stepName: 'Building final timeline and detections',
      processedDurationMs: mediaDurationMs,
      totalDurationMs: mediaDurationMs,
    );

    final timeline = await _buildTimeline(
      mediaPath,
      effectiveMediaId,
      profanityMatches,
      settings,
      onDetectionsBuilt: onDetectionsBuilt,
      cancellationToken: cancellationToken,
    );
    onTimelineBuilt?.call(timeline);

    yield _durationProgress(
      stepName: 'Analysis complete',
      processedDurationMs: mediaDurationMs,
      totalDurationMs: mediaDurationMs,
      stepProgress: 1,
      itemsProcessed: profanityMatches.length,
      totalItems: profanityMatches.length,
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

    final timeline = UnifiedTimeline.fromDetections(
      id: 'timeline_${DateTime.now().millisecondsSinceEpoch}',
      mediaDuration: metadata.duration,
      detections: detections,
    );
    await _checkState(cancellationToken);
    onDetectionsBuilt?.call(List<Detection>.unmodifiable(detections));
    return timeline;
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

  AnalysisProgress _durationProgress({
    required String stepName,
    required int processedDurationMs,
    required int totalDurationMs,
    double? stepProgress,
    int? itemsProcessed,
    int? totalItems,
    int? estimatedSecondsRemaining,
  }) {
    final clampedTotal = totalDurationMs <= 0 ? 1 : totalDurationMs;
    final clampedProcessed = processedDurationMs.clamp(0, clampedTotal);
    final progress = stepProgress ?? (clampedProcessed / clampedTotal);
    return AnalysisProgress(
      stepName:
          '$stepName (${_formatDurationMs(clampedProcessed)} / ${_formatDurationMs(clampedTotal)})',
      currentStep: 1,
      totalSteps: 1,
      stepProgress: progress.clamp(0.0, 1.0),
      estimatedSecondsRemaining: estimatedSecondsRemaining,
      itemsProcessed: itemsProcessed,
      totalItems: totalItems,
      processedDurationMs: clampedProcessed,
      totalDurationMs: clampedTotal,
    );
  }

  String _formatDurationMs(int ms) {
    final d = Duration(milliseconds: ms);
    final minutes = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }
}

/// Exception thrown during analysis
class AnalysisException implements Exception {
  AnalysisException(this.message);

  final String message;

  @override
  String toString() => 'AnalysisException: $message';
}
