import 'dart:async';
import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:kidslens_video_editor/data/models/models.dart';
import 'package:kidslens_video_editor/jobs/cancellation_token.dart';
import 'package:kidslens_video_editor/native/bindings/ffmpeg_bindings.dart';
import 'package:kidslens_video_editor/native/bindings/mms_bindings.dart';
import 'package:kidslens_video_editor/native/bindings/onnx_bindings.dart';
import 'package:kidslens_video_editor/native/bindings/whisper_bindings.dart';
import 'package:kidslens_video_editor/services/asr_service.dart';
import 'package:kidslens_video_editor/services/detection/analysis_stage_host.dart';
import 'package:kidslens_video_editor/services/detection/detection_pipeline.dart';
import 'package:kidslens_video_editor/services/detection/detection_pipeline_profile.dart';
import 'package:kidslens_video_editor/services/detection/detection_pipeline_registry.dart';
import 'package:kidslens_video_editor/services/detection/detection_pipeline_rollout.dart';
import 'package:kidslens_video_editor/services/detection/legacy_nsfw_pipeline_adapter.dart';
import 'package:kidslens_video_editor/services/detection/vss_family_safety_pipeline.dart';
import 'package:kidslens_video_editor/services/frame_sampling_service.dart';
import 'package:kidslens_video_editor/services/huggingface_model_registry.dart';
import 'package:kidslens_video_editor/services/media_service.dart'
    show MediaMetadata;
import 'package:kidslens_video_editor/services/model_manager_service.dart';
import 'package:kidslens_video_editor/services/modesty_analysis_service.dart';
import 'package:kidslens_video_editor/services/nsfw_model_adapter.dart';
import 'package:kidslens_video_editor/services/nsfw_onnx_service.dart';
import 'package:kidslens_video_editor/services/nsfw_region_model_manifest.dart';
import 'package:kidslens_video_editor/services/profanity_service.dart';
import 'package:kidslens_video_editor/services/region_temporal_aggregator.dart';

class _VisualContext {
  const _VisualContext({
    required this.nsfwCategory,
    required this.regionCategories,
    required this.parserCategories,
    required this.visualCategories,
    required this.samplingConfigHash,
    required this.thresholdConfigHash,
    this.classifierModelId,
    this.classifierModelPath,
    this.classifierSpec,
    this.detectorModelId,
    this.detectorModelPath,
    this.detectorSpec,
    this.parserModelId,
    this.parserModelPath,
    this.genderModelId,
    this.genderModelPath,
  });

  final ContentCategory? nsfwCategory;
  final List<ContentCategory> regionCategories;
  final List<ContentCategory> parserCategories;
  final List<VisualContentCategory> visualCategories;
  final String samplingConfigHash;
  final String thresholdConfigHash;
  final String? classifierModelId;
  final String? classifierModelPath;
  final NsfwModelSpec? classifierSpec;
  final String? detectorModelId;
  final String? detectorModelPath;
  final NsfwRegionModelSpec? detectorSpec;
  final String? parserModelId;
  final String? parserModelPath;
  final String? genderModelId;
  final String? genderModelPath;

  bool get hasNsfwClassifier =>
      classifierModelPath != null &&
      classifierSpec != null &&
      nsfwCategory != null;

  bool get hasDetector => detectorModelPath != null && detectorSpec != null;

  bool get hasParser =>
      parserModelPath != null &&
      parserModelId != null &&
      parserCategories.isNotEmpty;
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
    this.warningMessage,
    this.output,
  });

  final int processedDurationMs;
  final int itemsProcessed;
  final int totalItems;
  final String? warningMessage;
  final _VisualOutput? output;
}

/// Service for running content analysis on media files
class AnalysisService implements AnalysisStageHost {
  AnalysisService({
    required this.ffmpeg,
    required this.whisper,
    required this.mms,
    required this.nsfwOnnx,
    required this.modelManager,
    required this.profanity,
    this.asrService,
    DetectionPipelineRegistry? detectionPipelineRegistry,
    this.rolloutConfig = const DetectionPipelineRolloutConfig(),
    this.detectionTelemetryStore,
    DetectionPipelineFailureHandler? detectionFailureHandler,
  }) : detectionFailureHandler =
            detectionFailureHandler ?? const DetectionPipelineFailureHandler() {
    this.detectionPipelineRegistry = detectionPipelineRegistry ??
        DetectionPipelineRegistry(
          pipelines: [
            VssFamilySafetyPipeline(
              stageHost: this,
              frameSamplingService: FrameSamplingService(ffmpeg: ffmpeg),
              modelManager: modelManager,
            ),
            LegacyNsfwPipelineAdapter(runLegacyAnalysis: _runLegacyAnalysis),
          ],
          defaultPipelineId: DetectionPipelineIds.vssFamilySafetyV1,
        );
  }

  /// Pipeline version - increment when checkpoints become incompatible.
  /// Bumped to 8 for split NSFW classifier + Nudity detector pipelines.
  static const int pipelineVersion = 8;

  final FFmpegBindings ffmpeg;
  final WhisperBindings whisper;
  final MMSBindings mms;
  final NsfwOnnxService nsfwOnnx;
  final ModelManagerService modelManager;
  final ProfanityService profanity;
  final AsrService? asrService;
  late final DetectionPipelineRegistry detectionPipelineRegistry;
  final DetectionPipelineRolloutConfig rolloutConfig;
  final DetectionPipelineTelemetryStore? detectionTelemetryStore;
  final DetectionPipelineFailureHandler detectionFailureHandler;

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
  }) {
    final decision = detectionPipelineRegistry.resolveRollout(
      settings.analysisPipelineId,
      checkpoint: checkpoint,
      config: rolloutConfig,
    );
    if (!decision.checkpointCompatible) {
      unawaited(
        _recordFailure(
          detectionFailureHandler.checkpointCompatibility(
            activePipelineId: decision.activePipelineId,
            requestedPipelineId: decision.requestedPipelineId,
          ),
        ),
      );
    }
    final effectiveSettings = settings.copyWith(
      analysisPipelineId: decision.activePipelineId,
    );
    final request = DetectionPipelineRequest(
      mediaPath: mediaPath,
      settings: effectiveSettings,
      mediaId: mediaId,
      checkpoint: checkpoint,
      existingTranscript: existingTranscript,
      cancellationToken: cancellationToken,
      onTimelineBuilt: onTimelineBuilt,
      onDetectionsBuilt: onDetectionsBuilt,
      onFrameResultsBuilt: onFrameResultsBuilt,
    );
    final pipeline =
        detectionPipelineRegistry.resolve(decision.activePipelineId);
    return _analyzeWithTelemetry(
      pipeline: pipeline,
      request: request,
      decision: decision,
    );
  }

  Stream<AnalysisProgress> _analyzeWithTelemetry({
    required DetectionPipeline pipeline,
    required DetectionPipelineRequest request,
    required DetectionPipelineRolloutDecision decision,
  }) {
    late StreamSubscription<AnalysisProgress> subscription;
    final controller = StreamController<AnalysisProgress>();

    controller.onListen = () {
      subscription = pipeline.analyze(request).listen(
        controller.add,
        onError: (Object error, StackTrace stackTrace) async {
          await _recordFailure(
            detectionFailureHandler.resolve(
              kind: _classifyPipelineFailure(error),
              activePipelineId: decision.activePipelineId,
              requestedPipelineId: decision.requestedPipelineId,
              rolloutState: decision.state,
              error: error,
              details: decision.toJson(),
            ),
          );
          controller.addError(error, stackTrace);
          await controller.close();
        },
        onDone: controller.close,
      );
    };
    controller.onPause = () {
      subscription.pause();
    };
    controller.onResume = () {
      subscription.resume();
    };
    controller.onCancel = () => subscription.cancel();

    return controller.stream;
  }

  Future<void> _recordFailure(
    DetectionPipelineFailureResolution resolution,
  ) async {
    await detectionTelemetryStore?.record(resolution.telemetryEvent);
  }

  DetectionPipelineFailureKind _classifyPipelineFailure(Object error) {
    final message = error.toString().toLowerCase();
    if (message.contains('schema') ||
        message.contains('json') ||
        message.contains('parse')) {
      return DetectionPipelineFailureKind.schema;
    }
    if (message.contains('gpu') ||
        message.contains('cuda') ||
        message.contains('vram')) {
      return DetectionPipelineFailureKind.gpuFallback;
    }
    if (message.contains('model') &&
        (message.contains('load') ||
            message.contains('init') ||
            message.contains('checkpoint'))) {
      return DetectionPipelineFailureKind.modelLoad;
    }
    return DetectionPipelineFailureKind.pipelineCrash;
  }

  @override
  Stream<AnalysisProgress> runLegacyAnalysis(
    DetectionPipelineRequest request,
  ) =>
      _runLegacyAnalysis(request);

  @override
  Future<MediaMetadata> probeMedia(
    String mediaPath, {
    CancellationToken? cancellationToken,
  }) async {
    await _checkState(cancellationToken);
    final metadata = await ffmpeg.probeMedia(mediaPath);
    await _checkState(cancellationToken);
    return metadata;
  }

  @override
  Future<Transcript> transcribeAudio(
    String mediaPath,
    AnalysisSettings settings, {
    CancellationToken? cancellationToken,
    void Function(String message, double progress)? onProgress,
  }) =>
      _transcribeAudio(
        mediaPath,
        settings,
        cancellationToken: cancellationToken,
        onProgress: onProgress,
      );

  @override
  Future<List<ProfanityMatch>> detectProfanity(
    Transcript transcript,
    AnalysisSettings settings, {
    CancellationToken? cancellationToken,
  }) =>
      _detectProfanity(
        transcript,
        settings,
        cancellationToken: cancellationToken,
      );

  @override
  Stream<AnalysisVisualAuxiliaryProgressUpdate> runVisualAuxiliarySignals(
    DetectionPipelineRequest request, {
    required Duration mediaDuration,
    required int currentStep,
    required int totalSteps,
  }) async* {
    final settings = request.settings;
    final enabledVisualCategories =
        settings.contentDetectionConfig.enabledVisualCategories;
    final includeNsfw =
        enabledVisualCategories.any((category) => category.id == 'nsfw');
    final includeRegionDetection = enabledVisualCategories.any(
      (category) =>
          _supportsRegionDetectorCategory(category) ||
          _supportsParserCategory(category),
    );
    if (!includeNsfw && !includeRegionDetection) {
      yield AnalysisVisualAuxiliaryProgressUpdate(
        progress: _durationProgress(
          stepName: 'Legacy auxiliary visual signals skipped',
          currentStep: currentStep,
          totalSteps: totalSteps,
          processedDurationMs: 0,
          totalDurationMs: mediaDuration.inMilliseconds,
          stepProgress: 1,
        ),
        result: const AnalysisVisualAuxiliaryResult(),
      );
      return;
    }

    final effectiveMediaId = request.mediaId ?? request.mediaPath;
    final mediaDurationMs =
        mediaDuration.inMilliseconds <= 0 ? 1 : mediaDuration.inMilliseconds;
    final frameResults = <FrameAnalysisResult>[];
    final visualDetections = <Detection>[];
    final visualContext = await _resolveVisualContext(settings);
    final compatibleCheckpoint = _isVisualCheckpointCompatible(
      request.checkpoint,
      visualContext,
    );

    if (compatibleCheckpoint && request.checkpoint?.frameResults != null) {
      frameResults.addAll(request.checkpoint!.frameResults!);
      if (includeNsfw) {
        visualDetections.addAll(
          _buildVisualDetectionsFromFrames(
            mediaId: effectiveMediaId,
            frameResults: frameResults,
            nsfwCategory: visualContext.nsfwCategory,
            visualCategories: const <VisualContentCategory>[],
          ),
        );
      }
      if (includeRegionDetection) {
        visualDetections.addAll(
          _buildVisualDetectionsFromFrames(
            mediaId: effectiveMediaId,
            frameResults: frameResults,
            nsfwCategory: null,
            visualCategories: visualContext.visualCategories,
          ),
        );
      }
      yield AnalysisVisualAuxiliaryProgressUpdate(
        progress: _durationProgress(
          stepName: 'Legacy auxiliary visual signals restored',
          currentStep: currentStep,
          totalSteps: totalSteps,
          processedDurationMs: mediaDurationMs,
          totalDurationMs: mediaDurationMs,
          stepProgress: 1,
          itemsProcessed: visualDetections.length,
          totalItems: visualDetections.length,
        ),
        result: AnalysisVisualAuxiliaryResult(
          frameResults: List<FrameAnalysisResult>.unmodifiable(frameResults),
          visualDetections: List<Detection>.unmodifiable(visualDetections),
        ),
      );
      return;
    }

    if (includeNsfw) {
      await for (final update in _runVisualAnalysis(
        request.mediaPath,
        effectiveMediaId,
        mediaDuration,
        settings,
        visualContext,
        runNsfwClassifier: true,
        runNudityDetector: false,
        nsfwCategoryForDetections: visualContext.nsfwCategory,
        visualCategoriesForDetections: const <VisualContentCategory>[],
        cancellationToken: request.cancellationToken,
      )) {
        final stepProgress = mediaDurationMs <= 0
            ? 0.0
            : (update.processedDurationMs / mediaDurationMs).clamp(0.0, 1.0);
        if (update.output != null) {
          _mergeFrameResults(frameResults, update.output!.frameResults);
          visualDetections.addAll(update.output!.visualDetections);
        }
        yield AnalysisVisualAuxiliaryProgressUpdate(
          progress: _durationProgress(
            stepName: 'Legacy auxiliary: detecting NSFW',
            currentStep: currentStep,
            totalSteps: totalSteps,
            processedDurationMs: update.processedDurationMs,
            totalDurationMs: mediaDurationMs,
            stepProgress: stepProgress,
            itemsProcessed: update.itemsProcessed,
            totalItems: update.totalItems,
          ),
        );
      }
    }

    if (includeRegionDetection) {
      var regionWarningMessage = '';
      await for (final update in _runVisualAnalysis(
        request.mediaPath,
        effectiveMediaId,
        mediaDuration,
        settings,
        visualContext,
        runNsfwClassifier: false,
        runNudityDetector: true,
        nsfwCategoryForDetections: null,
        visualCategoriesForDetections: visualContext.visualCategories,
        cancellationToken: request.cancellationToken,
      )) {
        final stepProgress = mediaDurationMs <= 0
            ? 0.0
            : (update.processedDurationMs / mediaDurationMs).clamp(0.0, 1.0);
        if (update.warningMessage != null &&
            update.warningMessage!.isNotEmpty) {
          regionWarningMessage = update.warningMessage!;
        }
        if (update.output != null) {
          _mergeFrameResults(frameResults, update.output!.frameResults);
          visualDetections.addAll(update.output!.visualDetections);
        }
        yield AnalysisVisualAuxiliaryProgressUpdate(
          progress: _durationProgress(
            stepName: regionWarningMessage.isEmpty
                ? 'Legacy auxiliary: detecting body exposure'
                : regionWarningMessage,
            currentStep: currentStep,
            totalSteps: totalSteps,
            processedDurationMs: update.processedDurationMs,
            totalDurationMs: mediaDurationMs,
            stepProgress: stepProgress,
            itemsProcessed: update.itemsProcessed,
            totalItems: update.totalItems,
          ),
        );
      }
    }

    request.onFrameResultsBuilt
        ?.call(List<FrameAnalysisResult>.unmodifiable(frameResults));
    yield AnalysisVisualAuxiliaryProgressUpdate(
      progress: _durationProgress(
        stepName: 'Legacy auxiliary visual signals complete',
        currentStep: currentStep,
        totalSteps: totalSteps,
        processedDurationMs: mediaDurationMs,
        totalDurationMs: mediaDurationMs,
        stepProgress: 1,
        itemsProcessed: visualDetections.length,
        totalItems: visualDetections.length,
      ),
      result: AnalysisVisualAuxiliaryResult(
        frameResults: List<FrameAnalysisResult>.unmodifiable(frameResults),
        visualDetections: List<Detection>.unmodifiable(visualDetections),
      ),
    );
  }

  @override
  Future<void> checkState(CancellationToken? token) => _checkState(token);

  Stream<AnalysisProgress> _runLegacyAnalysis(
    DetectionPipelineRequest request,
  ) async* {
    final mediaPath = request.mediaPath;
    final settings = request.settings;
    final mediaId = request.mediaId;
    final checkpoint = request.checkpoint;
    final existingTranscript = request.existingTranscript;
    final cancellationToken = request.cancellationToken;
    final onTimelineBuilt = request.onTimelineBuilt;
    final onDetectionsBuilt = request.onDetectionsBuilt;
    final onFrameResultsBuilt = request.onFrameResultsBuilt;

    final effectiveMediaId = mediaId ?? mediaPath;
    await _checkState(cancellationToken);
    final mediaMetadata = await ffmpeg.probeMedia(mediaPath);
    final mediaDurationMs = mediaMetadata.duration.inMilliseconds <= 0
        ? 1
        : mediaMetadata.duration.inMilliseconds;

    final includeProfanity = _hasProfanityCategory(settings);
    final enabledVisualCategories =
        settings.contentDetectionConfig.enabledVisualCategories;
    final includeNsfw =
        enabledVisualCategories.any((category) => category.id == 'nsfw');
    final includeRegionDetection = enabledVisualCategories.any(
      (category) =>
          _supportsRegionDetectorCategory(category) ||
          _supportsParserCategory(category),
    );

    final selectedSteps = <String>[
      if (includeProfanity) 'profanity',
      if (includeNsfw) 'nsfw',
      if (includeRegionDetection) 'body_exposure',
    ];
    final totalSelectedSteps = selectedSteps.isEmpty ? 1 : selectedSteps.length;

    int stepNumberFor(String stepId) {
      final index = selectedSteps.indexOf(stepId);
      return index < 0 ? 1 : (index + 1);
    }

    yield _durationProgress(
      stepName: 'Preparing analysis',
      currentStep: 1,
      totalSteps: totalSelectedSteps,
      processedDurationMs: 0,
      totalDurationMs: mediaDurationMs,
      stepProgress: 0,
    );

    Transcript? transcript = existingTranscript ?? checkpoint?.transcript;
    List<ProfanityMatch> profanityMatches =
        checkpoint?.profanityMatches?.toList(growable: false) ??
            const <ProfanityMatch>[];

    if (includeProfanity) {
      final profanityStep = stepNumberFor('profanity');

      if (transcript != null) {
        yield _durationProgress(
          stepName: 'Profanity: using existing transcript',
          currentStep: profanityStep,
          totalSteps: totalSelectedSteps,
          processedDurationMs: 0,
          totalDurationMs: mediaDurationMs,
          stepProgress: 0.3,
        );
      } else {
        yield _durationProgress(
          stepName: 'Profanity: transcribing audio',
          currentStep: profanityStep,
          totalSteps: totalSelectedSteps,
          processedDurationMs: 0,
          totalDurationMs: mediaDurationMs,
          stepProgress: 0,
        );

        final progressController = StreamController<AnalysisProgress>();
        final transcriptCompleter = Completer<Transcript>();

        _transcribeAudio(
          mediaPath,
          settings,
          cancellationToken: cancellationToken,
          onProgress: (message, progress) {
            if (!progressController.isClosed) {
              progressController.add(
                _durationProgress(
                  stepName: 'Profanity: $message',
                  currentStep: profanityStep,
                  totalSteps: totalSelectedSteps,
                  processedDurationMs: (progress * mediaDurationMs).round(),
                  totalDurationMs: mediaDurationMs,
                  stepProgress: (progress * 0.8).clamp(0.0, 0.8),
                ),
              );
            }
          },
        ).then((result) {
          transcriptCompleter.complete(result);
          progressController.close();
        }).catchError((Object error, StackTrace stackTrace) {
          transcriptCompleter.completeError(error, stackTrace);
          progressController.close();
        });

        await for (final progress in progressController.stream) {
          yield progress;
        }

        transcript = await transcriptCompleter.future;
      }

      yield _durationProgress(
        stepName: 'Profanity: detecting matches',
        currentStep: profanityStep,
        totalSteps: totalSelectedSteps,
        processedDurationMs: 0,
        totalDurationMs: mediaDurationMs,
        stepProgress: 0.85,
      );

      if (checkpoint?.profanityMatches == null) {
        profanityMatches = await _detectProfanity(
          transcript,
          settings,
          cancellationToken: cancellationToken,
        );
      }

      yield _durationProgress(
        stepName: 'Profanity complete (${profanityMatches.length} matches)',
        currentStep: profanityStep,
        totalSteps: totalSelectedSteps,
        processedDurationMs: 0,
        totalDurationMs: mediaDurationMs,
        stepProgress: 1,
        itemsProcessed: profanityMatches.length,
        totalItems: profanityMatches.length,
      );
    } else {
      profanityMatches = <ProfanityMatch>[];
    }

    final allDetections = <Detection>[];
    final frameResults = <FrameAnalysisResult>[];

    if (includeNsfw || includeRegionDetection) {
      final visualContext = await _resolveVisualContext(settings);
      final compatibleCheckpoint = _isVisualCheckpointCompatible(
        checkpoint,
        visualContext,
      );

      if (compatibleCheckpoint && checkpoint?.frameResults != null) {
        frameResults
          ..clear()
          ..addAll(checkpoint!.frameResults!);

        if (includeNsfw) {
          allDetections.addAll(
            _buildVisualDetectionsFromFrames(
              mediaId: effectiveMediaId,
              frameResults: frameResults,
              nsfwCategory: visualContext.nsfwCategory,
              visualCategories: const <VisualContentCategory>[],
            ),
          );
          yield _durationProgress(
            stepName: 'NSFW complete (restored from checkpoint)',
            currentStep: stepNumberFor('nsfw'),
            totalSteps: totalSelectedSteps,
            processedDurationMs: mediaDurationMs,
            totalDurationMs: mediaDurationMs,
            stepProgress: 1,
          );
        }

        if (includeRegionDetection) {
          allDetections.addAll(
            _buildVisualDetectionsFromFrames(
              mediaId: effectiveMediaId,
              frameResults: frameResults,
              nsfwCategory: null,
              visualCategories: visualContext.visualCategories,
            ),
          );
          yield _durationProgress(
            stepName: 'Body exposure complete (restored from checkpoint)',
            currentStep: stepNumberFor('body_exposure'),
            totalSteps: totalSelectedSteps,
            processedDurationMs: mediaDurationMs,
            totalDurationMs: mediaDurationMs,
            stepProgress: 1,
          );
        }
      } else {
        if (includeNsfw) {
          await for (final update in _runVisualAnalysis(
            mediaPath,
            effectiveMediaId,
            mediaMetadata.duration,
            settings,
            visualContext,
            runNsfwClassifier: true,
            runNudityDetector: false,
            nsfwCategoryForDetections: visualContext.nsfwCategory,
            visualCategoriesForDetections: const <VisualContentCategory>[],
            cancellationToken: cancellationToken,
          )) {
            final stepProgress = mediaDurationMs <= 0
                ? 0.0
                : (update.processedDurationMs / mediaDurationMs)
                    .clamp(0.0, 1.0);

            yield _durationProgress(
              stepName: 'Detecting NSFW',
              currentStep: stepNumberFor('nsfw'),
              totalSteps: totalSelectedSteps,
              processedDurationMs: update.processedDurationMs,
              totalDurationMs: mediaDurationMs,
              stepProgress: stepProgress,
              itemsProcessed: update.itemsProcessed,
              totalItems: update.totalItems,
            );

            if (update.output != null) {
              _mergeFrameResults(frameResults, update.output!.frameResults);
              allDetections.addAll(update.output!.visualDetections);
            }
          }

          yield _durationProgress(
            stepName: 'NSFW complete',
            currentStep: stepNumberFor('nsfw'),
            totalSteps: totalSelectedSteps,
            processedDurationMs: mediaDurationMs,
            totalDurationMs: mediaDurationMs,
            stepProgress: 1,
          );
        }

        if (includeRegionDetection) {
          var regionWarningMessage = '';
          await for (final update in _runVisualAnalysis(
            mediaPath,
            effectiveMediaId,
            mediaMetadata.duration,
            settings,
            visualContext,
            runNsfwClassifier: false,
            runNudityDetector: true,
            nsfwCategoryForDetections: null,
            visualCategoriesForDetections: visualContext.visualCategories,
            cancellationToken: cancellationToken,
          )) {
            final stepProgress = mediaDurationMs <= 0
                ? 0.0
                : (update.processedDurationMs / mediaDurationMs)
                    .clamp(0.0, 1.0);
            if (update.warningMessage != null &&
                update.warningMessage!.isNotEmpty) {
              regionWarningMessage = update.warningMessage!;
            }

            yield _durationProgress(
              stepName: regionWarningMessage.isEmpty
                  ? 'Detecting Body Exposure'
                  : regionWarningMessage,
              currentStep: stepNumberFor('body_exposure'),
              totalSteps: totalSelectedSteps,
              processedDurationMs: update.processedDurationMs,
              totalDurationMs: mediaDurationMs,
              stepProgress: stepProgress,
              itemsProcessed: update.itemsProcessed,
              totalItems: update.totalItems,
            );

            if (update.output != null) {
              _mergeFrameResults(frameResults, update.output!.frameResults);
              allDetections.addAll(update.output!.visualDetections);
            }
          }

          yield _durationProgress(
            stepName: regionWarningMessage.isEmpty
                ? 'Body exposure complete'
                : 'Body exposure complete (fallback mode)',
            currentStep: stepNumberFor('body_exposure'),
            totalSteps: totalSelectedSteps,
            processedDurationMs: mediaDurationMs,
            totalDurationMs: mediaDurationMs,
            stepProgress: 1,
          );
        }
      }

      onFrameResultsBuilt
          ?.call(List<FrameAnalysisResult>.unmodifiable(frameResults));
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
      currentStep: totalSelectedSteps,
      totalSteps: totalSelectedSteps,
      processedDurationMs: mediaDurationMs,
      totalDurationMs: mediaDurationMs,
      stepProgress: 1,
      itemsProcessed: allDetections.length + profanityMatches.length,
      totalItems: allDetections.length + profanityMatches.length,
    );
  }

  void _mergeFrameResults(
    List<FrameAnalysisResult> target,
    List<FrameAnalysisResult> incoming,
  ) {
    if (incoming.isEmpty) {
      return;
    }

    final byTimestampMicros = <int, FrameAnalysisResult>{
      for (final frame in target) frame.timestamp.inMicroseconds: frame,
    };

    for (final nextFrame in incoming) {
      final key = nextFrame.timestamp.inMicroseconds;
      final existingFrame = byTimestampMicros[key];
      if (existingFrame == null) {
        byTimestampMicros[key] = nextFrame;
        continue;
      }

      final existingVisual =
          existingFrame.visualContent ?? VisualContentResult.safe();
      final nextVisual = nextFrame.visualContent ?? VisualContentResult.safe();

      final mergedVisual = existingVisual.detectedRegions.isEmpty &&
              nextVisual.detectedRegions.isEmpty &&
              existingVisual.clipScores.isEmpty &&
              nextVisual.clipScores.isEmpty
          ? VisualContentResult.safe()
          : VisualContentResult(
              detectedRegions: [
                ...existingVisual.detectedRegions,
                ...nextVisual.detectedRegions,
              ],
              clipScores: {
                ...existingVisual.clipScores,
                ...nextVisual.clipScores,
              },
            );

      byTimestampMicros[key] = existingFrame.copyWith(
        nsfw: nextFrame.nsfw.maxNsfwScore > existingFrame.nsfw.maxNsfwScore
            ? nextFrame.nsfw
            : existingFrame.nsfw,
        isSceneChange: existingFrame.isSceneChange || nextFrame.isSceneChange,
        visualContent: mergedVisual,
        processingTimeMs:
            nextFrame.processingTimeMs ?? existingFrame.processingTimeMs,
        frameHash: existingFrame.frameHash ?? nextFrame.frameHash,
      );
    }

    final merged = byTimestampMicros.values.toList(growable: false)
      ..sort((a, b) => a.timestamp.compareTo(b.timestamp));

    target
      ..clear()
      ..addAll(merged);
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
    final enabledVisualCategories =
        settings.contentDetectionConfig.enabledVisualCategories;
    final nsfwCategory = enabledVisualCategories
        .where((category) => category.id == 'nsfw')
        .firstOrNull;
    final regionCategories = enabledVisualCategories
        .where(_supportsRegionDetectorCategory)
        .toList(growable: false);
    final parserCategories = enabledVisualCategories
        .where(_supportsParserCategory)
        .toList(growable: false);

    if (nsfwCategory == null &&
        regionCategories.isEmpty &&
        parserCategories.isEmpty) {
      throw AnalysisException('No supported visual category is enabled');
    }

    String? classifierModelId;
    String? classifierModelPath;
    NsfwModelSpec? classifierSpec;

    if (nsfwCategory != null) {
      final preferredModelId = _normalizeLegacyModelId(
        settings.modelConfig.nsfwModelId,
      );
      final preferredCategoryModelId = _resolveClassifierModelId(nsfwCategory);
      final candidateIds = <String>[
        if (preferredCategoryModelId != null) preferredCategoryModelId,
        if (preferredModelId.isNotEmpty) preferredModelId,
        ...nsfwCategory.enabledModels.map((m) => m.modelId),
        ...HuggingFaceModelRegistry.instance
            .getNsfwClassifierModels()
            .map((m) => m.id),
      ];
      final seen = <String>{};

      for (final rawCandidateId in candidateIds) {
        final candidateId = _normalizeLegacyModelId(rawCandidateId);
        if (candidateId.isEmpty || !seen.add(candidateId)) {
          continue;
        }

        final candidateSpec = NsfwModelManifest.findById(candidateId);
        if (candidateSpec == null ||
            !NsfwModelManifest.isLicenseAllowed(candidateSpec.license)) {
          continue;
        }

        final candidatePath = await modelManager.getModelPath(candidateId);
        if (candidatePath == null) continue;

        if (candidateSpec.sha256.isNotEmpty) {
          final checksumOk = await modelManager.validateFileChecksum(
            candidatePath,
            candidateSpec.sha256,
          );
          if (!checksumOk) continue;
        }

        classifierModelId = candidateId;
        classifierModelPath = candidatePath;
        classifierSpec = candidateSpec;
        break;
      }

      if (classifierModelId == null ||
          classifierModelPath == null ||
          classifierSpec == null) {
        throw AnalysisException(
          'No downloaded approved NSFW classifier model is available',
        );
      }
    }

    const preferredDetectorModelId = 'nsfw-nudenet-detector-640';
    String? detectorModelId;
    String? detectorModelPath;
    NsfwRegionModelSpec? detectorSpec;
    String? parserModelId;
    String? parserModelPath;
    String? genderModelId;
    String? genderModelPath;

    if (regionCategories.isNotEmpty) {
      final preferredCategoryDetectorIds =
          regionCategories.map(_resolveDetectorModelId).whereType<String>();
      final candidateIds = <String>[
        ...preferredCategoryDetectorIds,
        preferredDetectorModelId,
        ...regionCategories
            .expand((category) => category.enabledModels.map((m) => m.modelId)),
        ...regionCategories.expand(
            (category) => category.modelContributions.map((m) => m.modelId)),
        ...HuggingFaceModelRegistry.instance
            .getNudeNetModels()
            .map((m) => m.id),
      ];
      final seen = <String>{};

      for (final rawCandidateId in candidateIds) {
        final candidateId = _normalizeLegacyModelId(rawCandidateId);
        if (candidateId.isEmpty || !seen.add(candidateId)) {
          continue;
        }

        final candidateSpec = NsfwRegionModelManifest.findById(candidateId);
        if (candidateSpec == null ||
            !NsfwRegionModelManifest.isLicenseAllowed(candidateSpec.license)) {
          continue;
        }

        final candidatePath = await modelManager.getModelPath(candidateId);
        if (candidatePath == null) continue;

        if ((candidateSpec.sha256 ?? '').isNotEmpty) {
          final checksumOk = await modelManager.validateFileChecksum(
            candidatePath,
            candidateSpec.sha256!,
          );
          if (!checksumOk) continue;
        }

        detectorModelId = candidateId;
        detectorModelPath = candidatePath;
        detectorSpec = candidateSpec;
        break;
      }

      if (detectorModelId == null ||
          detectorModelPath == null ||
          detectorSpec == null) {
        throw AnalysisException(
          'No downloaded approved body-exposure detector model is available',
        );
      }
    }

    if (parserCategories.isNotEmpty) {
      final parserCandidateIds = <String>[
        settings.modelConfig.parserModelId,
        ...parserCategories.map(_resolveParserModelId).whereType<String>(),
        ...HuggingFaceModelRegistry.instance.getParserModels().map((m) => m.id),
      ];
      final parserSeen = <String>{};

      for (final candidateId in parserCandidateIds) {
        if (candidateId.isEmpty || !parserSeen.add(candidateId)) {
          continue;
        }

        final candidateModel =
            HuggingFaceModelRegistry.instance.getModelById(candidateId);
        if (candidateModel == null ||
            candidateModel.modelType != HuggingFaceModelType.parser) {
          continue;
        }

        final candidatePath = await modelManager.getModelPath(candidateId);
        if (candidatePath == null) {
          continue;
        }

        parserModelId = candidateId;
        parserModelPath = candidatePath;
        break;
      }

      if (parserModelId == null || parserModelPath == null) {
        throw AnalysisException(
          'No downloaded parser model is available for modesty categories',
        );
      }

      final genderCandidateIds = <String>[
        settings.modelConfig.genderModelId,
        ...HuggingFaceModelRegistry.instance
            .getGenderHelperModels()
            .map((m) => m.id),
      ];
      final genderSeen = <String>{};

      for (final candidateId in genderCandidateIds) {
        if (candidateId.isEmpty || !genderSeen.add(candidateId)) {
          continue;
        }

        final candidateModel =
            HuggingFaceModelRegistry.instance.getModelById(candidateId);
        if (candidateModel == null ||
            candidateModel.modelType != HuggingFaceModelType.genderHelper) {
          continue;
        }

        final candidatePath = await modelManager.getModelPath(candidateId);
        if (candidatePath == null) {
          continue;
        }

        genderModelId = candidateId;
        genderModelPath = candidatePath;
        break;
      }
    }

    final visualCategories = <VisualContentCategory>[
      ..._buildVisualAggregatorCategories(
        regionCategories,
        detectorModelId,
        detectorSpec,
      ),
      ..._buildParserVisualAggregatorCategories(parserCategories),
    ];
    final visualCategorySignature = visualCategories
        .map(
          (c) =>
              '${c.id}|${c.enabled}|${c.threshold}|${c.action.name}|${c.detectionSource.name}|${c.detectionLabels.join(',')}',
        )
        .toList()
      ..sort();

    final samplingConfigHash = _hashJson(<String, dynamic>{
      'pipelineVersion': pipelineVersion,
      'frameSamplingRate': settings.frameSamplingRate,
      'useSceneDetection': settings.useSceneDetection,
      'minSegmentDurationMs': settings.minSegmentDurationMs,
      'nsfwModelId': classifierModelId,
      'classifierInputWidth': classifierSpec?.inputWidth,
      'classifierInputHeight': classifierSpec?.inputHeight,
      'detectorModelId': detectorModelId,
      'detectorInputSize': detectorSpec?.inputSize,
      'parserModelId': parserModelId,
      'genderModelId': genderModelId,
      'regionCategories': visualCategorySignature,
    });
    final thresholdConfigHash = _hashJson(<String, dynamic>{
      'nsfwThreshold': nsfwCategory?.threshold,
      'detectorConfidenceThreshold': detectorSpec?.confidenceThreshold,
      'detectorIouThreshold': detectorSpec?.iouThreshold,
      'detectorMaxDetections': detectorSpec?.maxDetections,
      'parserModelId': parserModelId,
      'genderModelId': genderModelId,
      'regionCategoryIds': [...regionCategories, ...parserCategories]
          .map((c) => c.id)
          .toList(growable: false),
      'regionCategories': visualCategorySignature,
    });

    return _VisualContext(
      nsfwCategory: nsfwCategory,
      regionCategories: regionCategories,
      parserCategories: parserCategories,
      visualCategories: visualCategories,
      samplingConfigHash: samplingConfigHash,
      thresholdConfigHash: thresholdConfigHash,
      classifierModelId: classifierModelId,
      classifierModelPath: classifierModelPath,
      classifierSpec: classifierSpec,
      detectorModelId: detectorModelId,
      detectorModelPath: detectorModelPath,
      detectorSpec: detectorSpec,
      parserModelId: parserModelId,
      parserModelPath: parserModelPath,
      genderModelId: genderModelId,
      genderModelPath: genderModelPath,
    );
  }

  bool _isVisualCheckpointCompatible(
    AnalysisCheckpoint? checkpoint,
    _VisualContext context,
  ) {
    if (checkpoint == null) return false;
    return checkpoint.pipelineVersion == pipelineVersion &&
        checkpoint.samplingConfigHash == context.samplingConfigHash &&
        checkpoint.thresholdConfigHash == context.thresholdConfigHash;
  }

  Stream<_VisualProgressUpdate> _runVisualAnalysis(
    String mediaPath,
    String mediaId,
    Duration mediaDuration,
    AnalysisSettings settings,
    _VisualContext context, {
    required bool runNsfwClassifier,
    required bool runNudityDetector,
    required ContentCategory? nsfwCategoryForDetections,
    required List<VisualContentCategory> visualCategoriesForDetections,
    CancellationToken? cancellationToken,
  }) async* {
    await _checkState(cancellationToken);

    final classifierInputWidth =
        runNsfwClassifier ? (context.classifierSpec?.inputWidth ?? 0) : 0;
    final classifierInputHeight =
        runNsfwClassifier ? (context.classifierSpec?.inputHeight ?? 0) : 0;
    final detectorInputSize =
        runNudityDetector ? (context.detectorSpec?.inputSize ?? 0) : 0;
    final parserInputSize = context.hasParser ? 640 : 0;
    final largestSquareInput = detectorInputSize > parserInputSize
        ? detectorInputSize
        : parserInputSize;
    final sampleWidth = classifierInputWidth >= largestSquareInput
        ? classifierInputWidth
        : largestSquareInput;
    final sampleHeight = classifierInputHeight >= largestSquareInput
        ? classifierInputHeight
        : largestSquareInput;

    if (sampleWidth <= 0 || sampleHeight <= 0) {
      throw AnalysisException(
          'No visual model available for enabled categories');
    }

    final sampler = FrameSamplingService(ffmpeg: ffmpeg);
    final sampleConfig = FrameSamplingConfig(
      baseFps: settings.frameSamplingRate.clamp(1, 10).toDouble(),
      includeKeyframes: settings.useSceneDetection,
      boostOnSceneChange: settings.useSceneDetection,
      outputWidth: sampleWidth,
      outputHeight: sampleHeight,
    );
    final adapter = runNsfwClassifier && context.hasNsfwClassifier
        ? NsfwModelAdapter(context.classifierSpec!)
        : null;

    final mediaDurationMs =
        mediaDuration.inMilliseconds <= 0 ? 1 : mediaDuration.inMilliseconds;
    var sampledCount = 0;

    // Stream-process frames: accumulate into batches and process as they arrive
    // instead of loading all frames into memory first.
    final batchSize = settings.modelConfig.batchSize.clamp(1, 16);
    final frameResults = <FrameAnalysisResult>[];
    var detectorEnabled = runNudityDetector && context.hasDetector;
    var classifierEnabled = runNsfwClassifier && context.hasNsfwClassifier;
    final parserEnabled = context.hasParser;
    String? warningMessage;
    var pendingBatch = <FrameData>[];
    final modestyService =
        parserEnabled ? ModestyAnalysisService(nsfwOnnx: nsfwOnnx) : null;

    await for (final frame
        in sampler.sampleFrames(mediaPath, config: sampleConfig)) {
      await _checkState(cancellationToken);
      pendingBatch.add(frame);
      sampledCount++;

      // Process batch when full
      if (pendingBatch.length >= batchSize) {
        final chunk = pendingBatch;
        pendingBatch = <FrameData>[];

        final rgbBatch =
            chunk.map((f) => f.data.toList(growable: false)).toList();

        List<Map<String, double>>? rawBatch;
        if (classifierEnabled &&
            adapter != null &&
            context.classifierModelPath != null) {
          rawBatch = await nsfwOnnx.runBatchInference(
            modelPath: context.classifierModelPath!,
            rgbDataBatch: rgbBatch,
            width: sampleWidth,
            height: sampleHeight,
            cancellationToken: cancellationToken,
          );
        }

        final detectorBatch =
            List<DetectionResult?>.filled(chunk.length, null, growable: false);
        if (detectorEnabled &&
            context.detectorModelPath != null &&
            context.detectorSpec != null) {
          try {
            for (var j = 0; j < chunk.length; j++) {
              await _checkState(cancellationToken);
              final f = chunk[j];
              detectorBatch[j] = await nsfwOnnx.runDetectionInference(
                modelPath: context.detectorModelPath!,
                rgbData: f.data.toList(growable: false),
                width: sampleWidth,
                height: sampleHeight,
                classNames: context.detectorSpec!.classLabels,
                confidenceThreshold: context.detectorSpec!.confidenceThreshold,
                iouThreshold: context.detectorSpec!.iouThreshold,
                inputSize: context.detectorSpec!.inputSize,
                maxDetections: context.detectorSpec!.maxDetections,
                cancellationToken: cancellationToken,
              );
            }
          } on NsfwOnnxException catch (e) {
            detectorEnabled = false;
            warningMessage = 'Nudity detector inference failed: ${e.message}; '
                'continuing without nudity regions';
            debugPrint(
                'ANALYSIS: Detector disabled due to error: ${e.message}');
          }
        }

        final detectorRegionsBatch = _buildDetectorRegionsBatch(detectorBatch);
        ModestyAnalysisBatchResult? modestyResult;
        if (parserEnabled && modestyService != null) {
          modestyResult = await modestyService.analyzeBatch(
            frames: chunk,
            parserCategories: context.parserCategories,
            parserModelPath: context.parserModelPath!,
            genderModelPath: context.genderModelPath,
            explicitRegionsByFrame: detectorRegionsBatch,
            cancellationToken: cancellationToken,
          );
          if (modestyResult.warningMessage?.isNotEmpty ?? false) {
            warningMessage = modestyResult.warningMessage;
          }
        }

        for (var j = 0; j < chunk.length; j++) {
          final frame = chunk[j];
          final nsfw = rawBatch != null && adapter != null
              ? adapter.adapt(rawBatch[j])
              : NsfwResult.safe();
          final regions = <DetectedRegion>[
            ...detectorRegionsBatch[j],
            ..._buildModestyRegionsForFrame(modestyResult, j),
          ];

          final result = FrameAnalysisResult(
            frameNumber: frame.frameNumber ?? frameResults.length,
            timestamp: frame.timestamp,
            nsfw: nsfw,
            violence: ViolenceResult.safe(),
            isSceneChange: frame.isSceneChange,
            blood: BloodResult.safe(),
            weapons: WeaponsResult.safe(),
            visualContent: regions.isEmpty
                ? VisualContentResult.safe()
                : VisualContentResult(detectedRegions: regions),
          );
          frameResults.add(result);
        }

        final processedDurationMs =
            chunk.last.timestamp.inMilliseconds.clamp(0, mediaDurationMs);
        yield _VisualProgressUpdate(
          processedDurationMs: processedDurationMs,
          itemsProcessed: frameResults.length,
          totalItems: sampledCount,
          warningMessage: warningMessage,
        );
      }
    }

    // Process any remaining frames in the last partial batch
    if (pendingBatch.isNotEmpty) {
      final chunk = pendingBatch;
      final rgbBatch =
          chunk.map((f) => f.data.toList(growable: false)).toList();

      List<Map<String, double>>? rawBatch;
      if (classifierEnabled &&
          adapter != null &&
          context.classifierModelPath != null) {
        rawBatch = await nsfwOnnx.runBatchInference(
          modelPath: context.classifierModelPath!,
          rgbDataBatch: rgbBatch,
          width: sampleWidth,
          height: sampleHeight,
          cancellationToken: cancellationToken,
        );
      }

      final detectorBatch =
          List<DetectionResult?>.filled(chunk.length, null, growable: false);
      if (detectorEnabled &&
          context.detectorModelPath != null &&
          context.detectorSpec != null) {
        try {
          for (var j = 0; j < chunk.length; j++) {
            await _checkState(cancellationToken);
            final f = chunk[j];
            detectorBatch[j] = await nsfwOnnx.runDetectionInference(
              modelPath: context.detectorModelPath!,
              rgbData: f.data.toList(growable: false),
              width: sampleWidth,
              height: sampleHeight,
              classNames: context.detectorSpec!.classLabels,
              confidenceThreshold: context.detectorSpec!.confidenceThreshold,
              iouThreshold: context.detectorSpec!.iouThreshold,
              inputSize: context.detectorSpec!.inputSize,
              maxDetections: context.detectorSpec!.maxDetections,
              cancellationToken: cancellationToken,
            );
          }
        } on NsfwOnnxException catch (e) {
          detectorEnabled = false;
          warningMessage = 'Nudity detector inference failed: ${e.message}; '
              'continuing without nudity regions';
          debugPrint('ANALYSIS: Detector disabled due to error: ${e.message}');
        }
      }

      final detectorRegionsBatch = _buildDetectorRegionsBatch(detectorBatch);
      ModestyAnalysisBatchResult? modestyResult;
      if (parserEnabled && modestyService != null) {
        modestyResult = await modestyService.analyzeBatch(
          frames: chunk,
          parserCategories: context.parserCategories,
          parserModelPath: context.parserModelPath!,
          genderModelPath: context.genderModelPath,
          explicitRegionsByFrame: detectorRegionsBatch,
          cancellationToken: cancellationToken,
        );
        if (modestyResult.warningMessage?.isNotEmpty ?? false) {
          warningMessage = modestyResult.warningMessage;
        }
      }

      for (var j = 0; j < chunk.length; j++) {
        final frame = chunk[j];
        final nsfw = rawBatch != null && adapter != null
            ? adapter.adapt(rawBatch[j])
            : NsfwResult.safe();
        final regions = <DetectedRegion>[
          ...detectorRegionsBatch[j],
          ..._buildModestyRegionsForFrame(modestyResult, j),
        ];

        final result = FrameAnalysisResult(
          frameNumber: frame.frameNumber ?? frameResults.length,
          timestamp: frame.timestamp,
          nsfw: nsfw,
          violence: ViolenceResult.safe(),
          isSceneChange: frame.isSceneChange,
          blood: BloodResult.safe(),
          weapons: WeaponsResult.safe(),
          visualContent: regions.isEmpty
              ? VisualContentResult.safe()
              : VisualContentResult(detectedRegions: regions),
        );
        frameResults.add(result);
      }
    }

    if (frameResults.isEmpty) {
      yield const _VisualProgressUpdate(
        processedDurationMs: 0,
        itemsProcessed: 0,
        totalItems: 0,
        output: _VisualOutput(frameResults: [], visualDetections: []),
      );
      return;
    }

    final visualDetections = _buildVisualDetectionsFromFrames(
      mediaId: mediaId,
      frameResults: frameResults,
      nsfwCategory: nsfwCategoryForDetections,
      visualCategories: visualCategoriesForDetections,
    );

    yield _VisualProgressUpdate(
      processedDurationMs: mediaDuration.inMilliseconds,
      itemsProcessed: frameResults.length,
      totalItems: sampledCount,
      warningMessage: warningMessage,
      output: _VisualOutput(
        frameResults: frameResults,
        visualDetections: visualDetections,
      ),
    );
  }

  List<Detection> _buildVisualDetectionsFromFrames({
    required String mediaId,
    required List<FrameAnalysisResult> frameResults,
    required ContentCategory? nsfwCategory,
    required List<VisualContentCategory> visualCategories,
  }) {
    if (frameResults.isEmpty) return const <Detection>[];

    final detections = <Detection>[];

    final hasRegionData = frameResults.any(
      (frame) => frame.visualContent?.detectedRegions.isNotEmpty ?? false,
    );
    final enabledVisualCategories = visualCategories
        .where((category) => category.enabled)
        .toList(growable: false);

    if (hasRegionData &&
        enabledVisualCategories.any((category) => category.usesNudeNet)) {
      final aggregator = RegionTemporalAggregator();
      final aggregated = aggregator.aggregate(
        frameResults,
        enabledVisualCategories,
      );
      final categoryById = {
        for (final category in enabledVisualCategories) category.id: category,
      };

      var index = 0;
      for (final tracked in aggregated.trackedRegions) {
        final category = categoryById[tracked.categoryId];
        if (category == null) continue;

        final box = _clampNormalizedBoundingBox(
          x: tracked.lastKeyframe.x,
          y: tracked.lastKeyframe.y,
          width: tracked.lastKeyframe.width,
          height: tracked.lastKeyframe.height,
        );

        final detection = Detection.visual(
          id: 'visual_region_${index++}',
          mediaId: mediaId,
          type: ContentType.nsfw,
          startTime: tracked.startTime,
          endTime: tracked.endTime,
          confidence: tracked.averageConfidence,
          description: _describeVisualCategory(category),
        ).copyWith(
          metadata: {
            Detection.visualContentCategoryKey: tracked.categoryId,
            'action': category.action.name,
            Detection.boundingBoxKey: box,
            'confidenceSource': 'region_temporal_aggregator',
          },
        );

        detections.add(detection);
      }

      for (final sceneAction in aggregated.sceneActions) {
        final category = categoryById[sceneAction.categoryId];
        if (category == null) continue;

        final confidence = _maxRegionConfidenceInRange(
          frameResults,
          sceneAction.startTime,
          sceneAction.endTime,
          fallback: category.threshold,
          labels: category.detectionLabels,
        );

        final detection = Detection.visual(
          id: 'visual_scene_${index++}',
          mediaId: mediaId,
          type: ContentType.nsfw,
          startTime: sceneAction.startTime,
          endTime: sceneAction.endTime,
          confidence: confidence,
          description: _describeVisualCategory(category),
        ).copyWith(
          metadata: {
            Detection.visualContentCategoryKey: sceneAction.categoryId,
            'action': sceneAction.action.name,
            'confidenceSource': 'region_temporal_aggregator',
          },
        );

        detections.add(detection);
      }
    }

    if (nsfwCategory != null && nsfwCategory.enabled) {
      detections.addAll(
        _buildLegacyClassifierDetections(
          mediaId: mediaId,
          frameResults: frameResults,
          nsfwThreshold: nsfwCategory.threshold,
        ),
      );
    }

    return detections;
  }

  List<Detection> _buildLegacyClassifierDetections({
    required String mediaId,
    required List<FrameAnalysisResult> frameResults,
    required double nsfwThreshold,
  }) {
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

  String? _resolveClassifierModelId(ContentCategory category) {
    for (final contribution in category.enabledModels) {
      final modelId = _normalizeLegacyModelId(contribution.modelId);
      if (NsfwModelManifest.findById(modelId) != null) {
        return modelId;
      }
    }

    for (final contribution in category.modelContributions) {
      final modelId = _normalizeLegacyModelId(contribution.modelId);
      if (NsfwModelManifest.findById(modelId) != null) {
        return modelId;
      }
    }

    return null;
  }

  String? _resolveDetectorModelId(ContentCategory category) {
    for (final contribution in category.enabledModels) {
      final modelId = _normalizeLegacyModelId(contribution.modelId);
      if (NsfwRegionModelManifest.findById(modelId) != null) {
        return modelId;
      }
    }

    for (final contribution in category.modelContributions) {
      final modelId = _normalizeLegacyModelId(contribution.modelId);
      if (NsfwRegionModelManifest.findById(modelId) != null) {
        return modelId;
      }
    }

    return null;
  }

  List<String> _resolveDetectorLabelsForCategory(
    ContentCategory category,
    String detectorModelId,
    NsfwRegionModelSpec detectorSpec,
  ) {
    final selectedContribution = category.enabledModels
            .where((m) => _normalizeLegacyModelId(m.modelId) == detectorModelId)
            .firstOrNull ??
        category.modelContributions
            .where((m) => _normalizeLegacyModelId(m.modelId) == detectorModelId)
            .firstOrNull;

    final allowedLabels = detectorSpec.classLabels.toSet();
    final contributionLabels = selectedContribution?.detectionLabels
            .where(allowedLabels.contains)
            .toList(growable: false) ??
        const <String>[];
    if (contributionLabels.isNotEmpty) {
      return contributionLabels;
    }

    if (category.id == 'nudity') {
      return kDefaultNudityDetectionLabels
          .where(allowedLabels.contains)
          .toList(growable: false);
    }

    return const <String>[];
  }

  List<VisualContentCategory> _buildVisualAggregatorCategories(
    List<ContentCategory> regionCategories,
    String? detectorModelId,
    NsfwRegionModelSpec? detectorSpec,
  ) {
    if (regionCategories.isEmpty ||
        detectorSpec == null ||
        detectorModelId == null) {
      return const <VisualContentCategory>[];
    }

    final visualCategories = <VisualContentCategory>[];
    for (final category in regionCategories) {
      if (!category.enabled ||
          !category.isVisual ||
          !category.supportsRegions) {
        continue;
      }

      final visualAction = _mapRemediationToVisualAction(category.action);
      if (visualAction == null) {
        continue;
      }

      final detectionLabels = _resolveDetectorLabelsForCategory(
        category,
        detectorModelId,
        detectorSpec,
      );
      if (detectionLabels.isEmpty) {
        continue;
      }

      visualCategories.add(
        VisualContentCategory(
          id: category.id,
          name: category.name,
          description: category.description,
          detectionSource: CategoryDetectionSource.nudeNet,
          detectionLabels: detectionLabels,
          enabled: category.enabled,
          threshold: category.threshold,
          action: visualAction,
          iconName: category.iconName,
        ),
      );
    }

    return visualCategories;
  }

  bool _supportsRegionDetectorCategory(ContentCategory category) =>
      category.isVisual &&
      category.supportsRegions &&
      _resolveDetectorModelId(category) != null;

  bool _supportsParserCategory(ContentCategory category) =>
      category.isVisual &&
      category.supportsRegions &&
      _resolveParserModelId(category) != null;

  List<VisualContentCategory> _buildParserVisualAggregatorCategories(
    List<ContentCategory> parserCategories,
  ) {
    final visualCategories = <VisualContentCategory>[];
    for (final category in parserCategories) {
      final visualAction = _mapRemediationToVisualAction(category.action);
      if (visualAction == null) {
        continue;
      }

      final detectionLabels = switch (category.id) {
        'female_arms_exposure' => const <String>['MODESTY_FEMALE_ARMS_EXPOSED'],
        'female_legs_exposure' => const <String>['MODESTY_FEMALE_LEGS_EXPOSED'],
        _ => const <String>[],
      };
      if (detectionLabels.isEmpty) {
        continue;
      }

      visualCategories.add(
        VisualContentCategory(
          id: category.id,
          name: category.name,
          description: category.description,
          detectionSource: CategoryDetectionSource.nudeNet,
          detectionLabels: detectionLabels,
          enabled: category.enabled,
          threshold: category.threshold,
          action: visualAction,
          iconName: category.iconName,
        ),
      );
    }
    return visualCategories;
  }

  String? _resolveParserModelId(ContentCategory category) {
    for (final contribution in category.enabledModels) {
      final model = HuggingFaceModelRegistry.instance.getModelById(
        contribution.modelId,
      );
      if (model?.modelType == HuggingFaceModelType.parser) {
        return contribution.modelId;
      }
    }

    for (final contribution in category.modelContributions) {
      final model = HuggingFaceModelRegistry.instance.getModelById(
        contribution.modelId,
      );
      if (model?.modelType == HuggingFaceModelType.parser) {
        return contribution.modelId;
      }
    }

    return null;
  }

  String _describeVisualCategory(VisualContentCategory category) {
    final normalizedName = category.name.trim();
    if (normalizedName.isEmpty) {
      return 'Visual policy violation detected';
    }
    return '$normalizedName detected';
  }

  VisualContentAction? _mapRemediationToVisualAction(RemediationAction action) {
    switch (action) {
      case RemediationAction.blurRegion:
      case RemediationAction.blurFullFrame:
        return VisualContentAction.blurRegion;
      case RemediationAction.pixelateRegion:
        return VisualContentAction.pixelateRegion;
      case RemediationAction.blackBoxRegion:
        return VisualContentAction.blackBoxRegion;
      case RemediationAction.cutScene:
        return VisualContentAction.cutScene;
      case RemediationAction.mute:
      case RemediationAction.beep:
        return null;
    }
  }

  DetectedRegion _toDetectedRegion({
    required String label,
    required double confidence,
    required double x,
    required double y,
    required double width,
    required double height,
  }) {
    final box = _clampNormalizedBoundingBox(
      x: x,
      y: y,
      width: width,
      height: height,
    );
    return DetectedRegion(
      label: label,
      confidence: _clampUnit(confidence),
      x: box['x']!,
      y: box['y']!,
      width: box['width']!,
      height: box['height']!,
    );
  }

  List<List<DetectedRegion>> _buildDetectorRegionsBatch(
    List<DetectionResult?> detectorBatch,
  ) =>
      List<List<DetectedRegion>>.generate(
        detectorBatch.length,
        (index) =>
            detectorBatch[index]
                ?.boxes
                .map(
                  (box) => _toDetectedRegion(
                    label: box.className,
                    confidence: box.confidence,
                    x: box.x,
                    y: box.y,
                    width: box.width,
                    height: box.height,
                  ),
                )
                .toList(growable: false) ??
            const <DetectedRegion>[],
        growable: false,
      );

  List<DetectedRegion> _buildModestyRegionsForFrame(
    ModestyAnalysisBatchResult? result,
    int frameIndex,
  ) {
    if (result == null || frameIndex >= result.signalsByFrame.length) {
      return const <DetectedRegion>[];
    }

    return result.signalsByFrame[frameIndex]
        .map(_toDetectedRegionFromModestySignal)
        .whereType<DetectedRegion>()
        .toList(growable: false);
  }

  DetectedRegion? _toDetectedRegionFromModestySignal(ModestyRuleSignal signal) {
    final region = signal.region;
    if (region == null) {
      return null;
    }

    final metadataLabel = signal.metadata['label'];
    final label = metadataLabel is String && metadataLabel.isNotEmpty
        ? metadataLabel
        : signal.categoryId.toUpperCase();
    return _toDetectedRegion(
      label: label,
      confidence: signal.confidence,
      x: region.x,
      y: region.y,
      width: region.width,
      height: region.height,
    );
  }

  Map<String, double> _clampNormalizedBoundingBox({
    required double x,
    required double y,
    required double width,
    required double height,
  }) {
    final clampedX = _clampUnit(x);
    final clampedY = _clampUnit(y);
    final clampedWidth = _clampUnit(width).clamp(0.0, 1.0 - clampedX);
    final clampedHeight = _clampUnit(height).clamp(0.0, 1.0 - clampedY);

    return {
      'x': clampedX,
      'y': clampedY,
      'width': clampedWidth.toDouble(),
      'height': clampedHeight.toDouble(),
    };
  }

  double _clampUnit(double value) => value.clamp(0.0, 1.0).toDouble();

  double _maxRegionConfidenceInRange(
    List<FrameAnalysisResult> frameResults,
    Duration start,
    Duration end, {
    required double fallback,
    List<String> labels = const <String>[],
  }) {
    var found = false;
    var maxScore = 0.0;
    final labelSet = labels.toSet();

    for (final frame in frameResults) {
      if (frame.timestamp < start || frame.timestamp > end) {
        continue;
      }
      final regions =
          frame.visualContent?.detectedRegions ?? const <DetectedRegion>[];
      for (final region in regions) {
        if (labelSet.isNotEmpty && !labelSet.contains(region.label)) {
          continue;
        }
        found = true;
        if (region.confidence > maxScore) {
          maxScore = region.confidence;
        }
      }
    }

    return found ? maxScore : fallback;
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
    final profanityAction = settings.contentDetectionConfig.categories
        .where((c) => c.id == 'profanity')
        .firstOrNull
        ?.action
        .name;

    for (final match in profanityMatches) {
      if (match.confidence >= settings.profanityConfig.fuzzyThreshold) {
        var detection = Detection.profanity(
          id: 'profanity_${detections.length}',
          mediaId: mediaId,
          startTime: match.word.startTime,
          endTime: match.word.endTime,
          confidence: match.confidence,
          word: match.word.word,
        );
        if (profanityAction != null) {
          detection = detection.copyWith(
            metadata: {
              ...?detection.metadata,
              'action': profanityAction,
            },
          );
        }
        detections.add(detection);
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

  String _normalizeLegacyModelId(String id) {
    switch (id) {
      case 'nsfw-mobilenet-v2':
      case 'nsfw-inception-v3':
      case 'nsfw-gantman-mobilenet-v2-224':
      case 'nsfw-gantman-inception-299':
        return 'nsfw-onnx-community-vit-224';
      case 'nsfw-nudenet-detector-640-community':
        return 'nsfw-nudenet-detector-640';
      default:
        return id;
    }
  }

  AnalysisProgress _durationProgress({
    required String stepName,
    required int currentStep,
    required int totalSteps,
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
      currentStep: currentStep < 1 ? 1 : currentStep,
      totalSteps: totalSteps < 1 ? 1 : totalSteps,
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
