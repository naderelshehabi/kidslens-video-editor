import 'dart:async';
import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:kidslens_video_editor/data/models/models.dart';
import 'package:kidslens_video_editor/jobs/cancellation_token.dart';
import 'package:kidslens_video_editor/native/bindings/ffmpeg_bindings.dart';
import 'package:kidslens_video_editor/native/bindings/mms_bindings.dart';
import 'package:kidslens_video_editor/native/bindings/whisper_bindings.dart';
import 'package:kidslens_video_editor/services/asr_service.dart';
import 'package:kidslens_video_editor/services/frame_sampling_service.dart';
import 'package:kidslens_video_editor/services/huggingface_model_registry.dart';
import 'package:kidslens_video_editor/services/model_manager_service.dart';
import 'package:kidslens_video_editor/services/nsfw_model_adapter.dart';
import 'package:kidslens_video_editor/services/nsfw_onnx_service.dart';
import 'package:kidslens_video_editor/services/profanity_service.dart';
import 'package:path/path.dart' as p;

/// Checkpoint for resuming analysis
class AnalysisCheckpoint {
  AnalysisCheckpoint({
    required this.timestamp,
    this.transcript,
    this.profanityMatches,
    this.lastAnalyzedFrame = 0,
    this.frameResults,
    this.pipelineVersion = AnalysisService.pipelineVersion,
    this.modelId,
    this.modelSha256,
    this.samplingConfigHash,
    this.thresholdConfigHash,
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
        pipelineVersion:
            json['pipelineVersion'] as int? ?? AnalysisService.pipelineVersion,
        modelId: json['modelId'] as String?,
        modelSha256: json['modelSha256'] as String?,
        samplingConfigHash: json['samplingConfigHash'] as String?,
        thresholdConfigHash: json['thresholdConfigHash'] as String?,
        timestamp: DateTime.parse(json['timestamp'] as String),
      );

  final Transcript? transcript;
  final List<ProfanityMatch>? profanityMatches;
  final int lastAnalyzedFrame;
  final List<FrameAnalysisResult>? frameResults;
  final DateTime timestamp;
  final int pipelineVersion;
  final String? modelId;
  final String? modelSha256;
  final String? samplingConfigHash;
  final String? thresholdConfigHash;

  Map<String, dynamic> toJson() => {
        'transcript': transcript?.toJson(),
        'profanityMatches': profanityMatches?.map((e) => e.toJson()).toList(),
        'lastAnalyzedFrame': lastAnalyzedFrame,
        'frameResults': frameResults?.map((e) => e.toJson()).toList(),
        'timestamp': timestamp.toIso8601String(),
        'pipelineVersion': pipelineVersion,
        'modelId': modelId,
        'modelSha256': modelSha256,
        'samplingConfigHash': samplingConfigHash,
        'thresholdConfigHash': thresholdConfigHash,
      };
}

class _VisualContext {
  const _VisualContext({
    required this.modelId,
    required this.modelPath,
    required this.spec,
    required this.nsfwThreshold,
    required this.samplingConfigHash,
    required this.thresholdConfigHash,
  });

  final String modelId;
  final String modelPath;
  final NsfwModelSpec spec;
  final double nsfwThreshold;
  final String samplingConfigHash;
  final String thresholdConfigHash;
}

class _VisualOutput {
  const _VisualOutput({
    required this.frameResults,
    required this.visualDetections,
  });

  final List<FrameAnalysisResult> frameResults;
  final List<Detection> visualDetections;
}

class _VisualProgressUpdate {
  const _VisualProgressUpdate({
    required this.processedDurationMs,
    required this.itemsProcessed,
    required this.totalItems,
    this.output,
  });

  final int processedDurationMs;
  final int itemsProcessed;
  final int totalItems;
  final _VisualOutput? output;
}

/// Service for running content analysis on media files
class AnalysisService {
  AnalysisService({
    required this.ffmpeg,
    required this.whisper,
    required this.mms,
    required this.nsfwOnnx,
    required this.modelManager,
    required this.profanity,
    this.asrService,
  });

  /// Pipeline version - increment when checkpoints become incompatible.
  /// Bumped to 6 for ONNX migration.
  static const int pipelineVersion = 6;

  final FFmpegBindings ffmpeg;
  final WhisperBindings whisper;
  final MMSBindings mms;
  final NsfwOnnxService nsfwOnnx;
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
    void Function(List<FrameAnalysisResult> frameResults)? onFrameResultsBuilt,
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

    final shouldTranscribe = _hasProfanityCategory(settings);

    Transcript? transcript;
    if (shouldTranscribe) {
      if (existingTranscript != null) {
        transcript = existingTranscript;
        yield _durationProgress(
          stepName: 'Using existing transcript',
          processedDurationMs: 0,
          totalDurationMs: mediaDurationMs,
        );
      } else if (checkpoint?.transcript != null) {
        transcript = checkpoint!.transcript;
        yield _durationProgress(
          stepName: 'Resuming from checkpoint transcript',
          processedDurationMs: 0,
          totalDurationMs: mediaDurationMs,
        );
      } else {
        // Stream transcription progress updates
        yield _durationProgress(
          stepName: 'Starting audio transcription...',
          processedDurationMs: 0,
          totalDurationMs: mediaDurationMs,
        );

        // Use a StreamController to forward progress from the callback
        final progressController = StreamController<AnalysisProgress>();
        final transcriptCompleter = Completer<Transcript>();

        // ignore: unawaited_futures
        _transcribeAudio(
          mediaPath,
          settings,
          cancellationToken: cancellationToken,
          onProgress: (message, progress) {
            if (!progressController.isClosed) {
              progressController.add(_durationProgress(
                stepName: message,
                processedDurationMs: (progress * mediaDurationMs).round(),
                totalDurationMs: mediaDurationMs,
              ));
            }
          },
        ).then((result) {
          transcriptCompleter.complete(result);
          progressController.close();
        }).catchError((Object error, StackTrace stackTrace) {
          transcriptCompleter.completeError(error, stackTrace);
          progressController.close();
        });

        // Yield progress updates while transcription runs
        await for (final progress in progressController.stream) {
          yield progress;
        }

        // Get the transcript result
        transcript = await transcriptCompleter.future;
      }
      final transcriptValue = transcript!;
      yield _durationProgress(
        stepName:
            'Audio transcription complete (${transcriptValue.segments.length} segments)',
        processedDurationMs: mediaDurationMs,
        totalDurationMs: mediaDurationMs,
        itemsProcessed: transcriptValue.segments.length,
        totalItems: transcriptValue.segments.length,
      );
    } else {
      yield _durationProgress(
        stepName: 'Skipping audio transcription (audio categories disabled)',
        processedDurationMs: 0,
        totalDurationMs: mediaDurationMs,
        itemsProcessed: 0,
        totalItems: 0,
      );
    }

    List<ProfanityMatch> profanityMatches;
    if (shouldTranscribe) {
      if (checkpoint?.profanityMatches != null) {
        profanityMatches = checkpoint!.profanityMatches!;
      } else {
        yield _durationProgress(
          stepName: 'Detecting profanity...',
          processedDurationMs: 0,
          totalDurationMs: mediaDurationMs,
        );
        profanityMatches = await _detectProfanity(
          transcript!,
          settings,
          cancellationToken: cancellationToken,
        );
      }
      yield _durationProgress(
        stepName:
            'Profanity detection complete (${profanityMatches.length} matches)',
        processedDurationMs: mediaDurationMs,
        totalDurationMs: mediaDurationMs,
        itemsProcessed: profanityMatches.length,
        totalItems: profanityMatches.length,
      );
    } else {
      profanityMatches = <ProfanityMatch>[];
      yield _durationProgress(
        stepName: 'Skipping profanity detection (no audio categories enabled)',
        processedDurationMs: 0,
        totalDurationMs: mediaDurationMs,
        itemsProcessed: 0,
        totalItems: 0,
      );
    }

    final allDetections = <Detection>[];
    final frameResults = <FrameAnalysisResult>[];

    if (settings.hasVisualDetection) {
      yield _durationProgress(
        stepName: 'Running visual NSFW analysis',
        processedDurationMs: 0,
        totalDurationMs: mediaDurationMs,
      );

      final visualContext = await _resolveVisualContext(settings);
      final compatibleCheckpoint = _isVisualCheckpointCompatible(
        checkpoint,
        visualContext,
      );
      if (compatibleCheckpoint && checkpoint?.frameResults != null) {
        frameResults
          ..clear()
          ..addAll(checkpoint!.frameResults!);
        allDetections.addAll(
          _buildVisualDetectionsFromFrames(
            mediaId: effectiveMediaId,
            frameResults: frameResults,
            nsfwThreshold: visualContext.nsfwThreshold,
          ),
        );
      } else {
        await for (final update in _runVisualAnalysis(
          mediaPath,
          effectiveMediaId,
          mediaMetadata.duration,
          settings,
          visualContext,
          cancellationToken: cancellationToken,
        )) {
          yield _durationProgress(
            stepName: 'Running visual NSFW analysis',
            processedDurationMs: update.processedDurationMs,
            totalDurationMs: mediaDurationMs,
            itemsProcessed: update.itemsProcessed,
            totalItems: update.totalItems,
          );

          if (update.output != null) {
            frameResults
              ..clear()
              ..addAll(update.output!.frameResults);
            allDetections.addAll(update.output!.visualDetections);
          }
        }
      }

      onFrameResultsBuilt
          ?.call(List<FrameAnalysisResult>.unmodifiable(frameResults));
      yield _durationProgress(
        stepName:
            'Visual analysis complete (${frameResults.length} sampled frames)',
        processedDurationMs: mediaDurationMs,
        totalDurationMs: mediaDurationMs,
        itemsProcessed: frameResults.length,
        totalItems: frameResults.length,
      );
    } else {
      yield _durationProgress(
        stepName: 'Skipping visual analysis (visual categories disabled)',
        processedDurationMs: mediaDurationMs,
        totalDurationMs: mediaDurationMs,
      );
    }

    final timeline = await _buildTimeline(
      mediaPath,
      effectiveMediaId,
      profanityMatches,
      allDetections,
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
      itemsProcessed: allDetections.length + profanityMatches.length,
      totalItems: allDetections.length + profanityMatches.length,
    );
  }

  Future<Transcript> _transcribeAudio(
    String mediaPath,
    AnalysisSettings settings, {
    CancellationToken? cancellationToken,
    void Function(String message, double progress)? onProgress,
  }) async {
    await _checkState(cancellationToken);
    final asrModel = settings.modelConfig.asrModelId;
    final modelPath = await modelManager.getModelPath(asrModel);

    if (modelPath == null) {
      throw AnalysisException('ASR model not downloaded: $asrModel');
    }

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
          gpuDeviceIndex: settings.modelConfig.gpuDeviceIndex,
          nThreads: settings.modelConfig.cpuThreads,
          beamSize: settings.modelConfig.beamSize,
          cancelToken: cancelCompleter,
          onProgress: onProgress != null
              ? (phase, progress, message, timestamp) {
                  onProgress(message, progress);
                }
              : null,
        );
      } on AsrCancelledException {
        throw CancelledException();
      }
    }

    if (asrModel.startsWith('whisper')) {
      await whisper.initialize();
      final transcript = await whisper.transcribe(
        mediaPath,
        modelPath,
        language: settings.modelConfig.asrLanguage == 'auto'
            ? null
            : settings.modelConfig.asrLanguage,
        useGpu: settings.modelConfig.useGpu,
        gpuDeviceIndex: settings.modelConfig.gpuDeviceIndex,
        nThreads: settings.modelConfig.cpuThreads,
        beamSize: settings.modelConfig.beamSize,
      );
      await _checkState(cancellationToken);
      return transcript;
    }

    final transcript = await mms.transcribe(mediaPath, modelPath);
    await _checkState(cancellationToken);
    return transcript;
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

  Future<_VisualContext> _resolveVisualContext(
    AnalysisSettings settings,
  ) async {
    final preferredModelId = _normalizeLegacyNsfwModelId(
      settings.modelConfig.nsfwModelId,
    );
    final selectedModelId = preferredModelId.isNotEmpty
        ? preferredModelId
        : HuggingFaceModelRegistry.instance.getNsfwModels().first.id;

    final modelPath = await modelManager.getModelPath(selectedModelId);
    if (modelPath == null) {
      throw AnalysisException('NSFW model not downloaded: $selectedModelId');
    }

    final spec = NsfwModelManifest.findById(selectedModelId);
    if (spec == null) {
      throw AnalysisException(
        'NSFW model not in approved manifest: $selectedModelId',
      );
    }
    if (!NsfwModelManifest.isLicenseAllowed(spec.license)) {
      throw AnalysisException(
        'NSFW model license is not allowed: ${spec.license}',
      );
    }

    if (spec.sha256.isNotEmpty) {
      final checksumOk = await modelManager.validateFileChecksum(
        modelPath,
        spec.sha256,
      );
      if (!checksumOk) {
        throw AnalysisException(
          'NSFW model checksum mismatch: $selectedModelId',
        );
      }
    }

    ContentCategory? nsfwCategory;
    for (final category
        in settings.contentDetectionConfig.enabledVisualCategories) {
      if (category.id == 'nsfw') {
        nsfwCategory = category;
        break;
      }
    }
    final nsfwThreshold = nsfwCategory?.threshold ?? 0.5;
    final samplingConfigHash = _hashJson(<String, dynamic>{
      'pipelineVersion': pipelineVersion,
      'frameSamplingRate': settings.frameSamplingRate,
      'useSceneDetection': settings.useSceneDetection,
      'minSegmentDurationMs': settings.minSegmentDurationMs,
    });
    final thresholdConfigHash = _hashJson(<String, dynamic>{
      'nsfwThreshold': nsfwThreshold,
    });

    return _VisualContext(
      modelId: selectedModelId,
      modelPath: modelPath,
      spec: spec,
      nsfwThreshold: nsfwThreshold,
      samplingConfigHash: samplingConfigHash,
      thresholdConfigHash: thresholdConfigHash,
    );
  }

  bool _isVisualCheckpointCompatible(
    AnalysisCheckpoint? checkpoint,
    _VisualContext context,
  ) {
    if (checkpoint == null) return false;
    return checkpoint.pipelineVersion == pipelineVersion &&
        checkpoint.modelId == context.modelId &&
        checkpoint.modelSha256 == context.spec.sha256 &&
        checkpoint.samplingConfigHash == context.samplingConfigHash &&
        checkpoint.thresholdConfigHash == context.thresholdConfigHash;
  }

  Stream<_VisualProgressUpdate> _runVisualAnalysis(
    String mediaPath,
    String mediaId,
    Duration mediaDuration,
    AnalysisSettings settings,
    _VisualContext context, {
    CancellationToken? cancellationToken,
  }) async* {
    await _checkState(cancellationToken);

    final sampler = FrameSamplingService(ffmpeg: ffmpeg);
    final sampleConfig = FrameSamplingConfig(
      baseFps: settings.frameSamplingRate.clamp(1, 10).toDouble(),
      includeKeyframes: settings.useSceneDetection,
      boostOnSceneChange: settings.useSceneDetection,
      outputWidth: context.spec.inputWidth,
      outputHeight: context.spec.inputHeight,
    );
    final adapter = NsfwModelAdapter(context.spec);

    final sampledFrames = <FrameData>[];
    final mediaDurationMs = mediaDuration.inMilliseconds <= 0
        ? 1
        : mediaDuration.inMilliseconds;
    var sampledCount = 0;
    await for (final frame
        in sampler.sampleFrames(mediaPath, config: sampleConfig)) {
      await _checkState(cancellationToken);
      sampledFrames.add(frame);
      sampledCount++;
      final processedDurationMs = frame.timestamp.inMilliseconds.clamp(
        0,
        mediaDurationMs,
      );
      yield _VisualProgressUpdate(
        processedDurationMs: processedDurationMs,
        itemsProcessed: sampledCount,
        totalItems: sampledCount,
      );
    }
    if (sampledFrames.isEmpty) {
      yield const _VisualProgressUpdate(
        processedDurationMs: 0,
        itemsProcessed: 0,
        totalItems: 0,
        output: _VisualOutput(frameResults: [], visualDetections: []),
      );
      return;
    }

    final batchSize = settings.modelConfig.batchSize.clamp(1, 16);
    final totalItems = sampledFrames.length;
    final frameResults = <FrameAnalysisResult>[];
    final visualDetections = <Detection>[];
    var unsafeWindow = <bool>[];
    var safeStreak = 0;
    var inUnsafeState = false;
    Duration? activeStart;
    var activeMaxConfidence = 0.0;
    var detectionIndex = 0;

    for (var i = 0; i < sampledFrames.length; i += batchSize) {
      await _checkState(cancellationToken);
      final end = (i + batchSize).clamp(0, sampledFrames.length);
      final chunk = sampledFrames.sublist(i, end);

      final rgbBatch =
          chunk.map((f) => f.data.toList(growable: false)).toList();
      final rawBatch = await nsfwOnnx.runBatchInference(
        modelPath: context.modelPath,
        rgbDataBatch: rgbBatch,
        width: context.spec.inputWidth,
        height: context.spec.inputHeight,
        cancellationToken: cancellationToken,
      );

      for (var j = 0; j < chunk.length; j++) {
        final frame = chunk[j];
        final nsfw = adapter.adapt(rawBatch[j]);
        final result = FrameAnalysisResult(
          frameNumber: frame.frameNumber ?? frameResults.length,
          timestamp: frame.timestamp,
          nsfw: nsfw,
          violence: ViolenceResult.safe(),
          isSceneChange: frame.isSceneChange,
          blood: BloodResult.safe(),
          weapons: WeaponsResult.safe(),
          visualContent: VisualContentResult.safe(),
        );
        frameResults.add(result);

        final unsafe = nsfw.maxNsfwScore >= context.nsfwThreshold;
        unsafeWindow = [...unsafeWindow, unsafe];
        if (unsafeWindow.length > 3) {
          unsafeWindow = unsafeWindow.sublist(unsafeWindow.length - 3);
        }

        if (!inUnsafeState) {
          final unsafeCount = unsafeWindow.where((value) => value).length;
          if (unsafeCount >= 2 && unsafeWindow.length == 3) {
            inUnsafeState = true;
            activeStart = frame.timestamp;
            safeStreak = 0;
            activeMaxConfidence = nsfw.maxNsfwScore;
          }
        } else {
          activeMaxConfidence = nsfw.maxNsfwScore > activeMaxConfidence
              ? nsfw.maxNsfwScore
              : activeMaxConfidence;
          if (unsafe) {
            safeStreak = 0;
          } else {
            safeStreak++;
          }

          if (safeStreak >= 5) {
            final endTime = frame.timestamp;
            if (activeStart != null && endTime > activeStart) {
              visualDetections.add(
                Detection.visual(
                  id: 'visual_nsfw_${detectionIndex++}',
                  mediaId: mediaId,
                  type: ContentType.nsfw,
                  startTime: activeStart,
                  endTime: endTime,
                  confidence: activeMaxConfidence,
                  description: 'NSFW content detected',
                ),
              );
            }
            inUnsafeState = false;
            safeStreak = 0;
            activeStart = null;
            activeMaxConfidence = 0;
          }
        }
      }

      final processedDurationMs = chunk.last.timestamp.inMilliseconds
          .clamp(0, mediaDuration.inMilliseconds);
      yield _VisualProgressUpdate(
        processedDurationMs: processedDurationMs,
        itemsProcessed: frameResults.length,
        totalItems: totalItems,
      );
    }

    if (inUnsafeState && activeStart != null) {
      visualDetections.add(
        Detection.visual(
          id: 'visual_nsfw_${detectionIndex++}',
          mediaId: mediaId,
          type: ContentType.nsfw,
          startTime: activeStart,
          endTime: mediaDuration,
          confidence: activeMaxConfidence,
          description: 'NSFW content detected',
        ),
      );
    }

    yield _VisualProgressUpdate(
      processedDurationMs: mediaDuration.inMilliseconds,
      itemsProcessed: frameResults.length,
      totalItems: totalItems,
      output: _VisualOutput(
        frameResults: frameResults,
        visualDetections: visualDetections,
      ),
    );
  }

  List<Detection> _buildVisualDetectionsFromFrames({
    required String mediaId,
    required List<FrameAnalysisResult> frameResults,
    required double nsfwThreshold,
  }) {
    if (frameResults.isEmpty) return const <Detection>[];
    final detections = <Detection>[];
    var start = -1;
    var maxScore = 0.0;
    var index = 0;
    for (var i = 0; i < frameResults.length; i++) {
      final frame = frameResults[i];
      final flagged = frame.nsfw.maxNsfwScore >= nsfwThreshold;
      if (flagged && start < 0) {
        start = i;
        maxScore = frame.nsfw.maxNsfwScore;
      } else if (flagged) {
        maxScore = frame.nsfw.maxNsfwScore > maxScore
            ? frame.nsfw.maxNsfwScore
            : maxScore;
      } else if (start >= 0) {
        detections.add(
          Detection.visual(
            id: 'visual_nsfw_resume_${index++}',
            mediaId: mediaId,
            type: ContentType.nsfw,
            startTime: frameResults[start].timestamp,
            endTime: frame.timestamp,
            confidence: maxScore,
            description: 'NSFW content detected',
          ),
        );
        start = -1;
        maxScore = 0;
      }
    }

    if (start >= 0) {
      detections.add(
        Detection.visual(
          id: 'visual_nsfw_resume_${index++}',
          mediaId: mediaId,
          type: ContentType.nsfw,
          startTime: frameResults[start].timestamp,
          endTime: frameResults.last.timestamp,
          confidence: maxScore,
          description: 'NSFW content detected',
        ),
      );
    }

    return detections;
  }

  Future<UnifiedTimeline> _buildTimeline(
    String mediaPath,
    String mediaId,
    List<ProfanityMatch> profanityMatches,
    List<Detection> visualDetections,
    AnalysisSettings settings, {
    void Function(List<Detection> detections)? onDetectionsBuilt,
    CancellationToken? cancellationToken,
  }) async {
    await _checkState(cancellationToken);
    final detections = <Detection>[];
    final metadata = await ffmpeg.probeMedia(mediaPath);

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
    detections.addAll(visualDetections);

    final timeline = UnifiedTimeline.fromDetections(
      id: 'timeline_${DateTime.now().millisecondsSinceEpoch}',
      mediaDuration: metadata.duration,
      detections: detections,
    );
    await _checkState(cancellationToken);
    onDetectionsBuilt?.call(List<Detection>.unmodifiable(detections));
    return timeline;
  }

  bool _hasProfanityCategory(AnalysisSettings settings) =>
      settings.contentDetectionConfig.enabledAudioCategories.any(
        (c) => c.id == 'profanity',
      );

  Future<void> _checkState(CancellationToken? token) async {
    if (token != null) {
      await token.checkState();
    }
  }

  String _hashJson(Map<String, dynamic> payload) =>
      sha256.convert(utf8.encode(jsonEncode(payload))).toString();

  String _normalizeLegacyNsfwModelId(String id) {
    switch (id) {
      case 'nsfw-mobilenet-v2':
        return 'nsfw-gantman-mobilenet-v2-224';
      case 'nsfw-inception-v3':
        return 'nsfw-gantman-inception-299';
      default:
        return id;
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
