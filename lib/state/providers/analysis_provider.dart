import 'dart:async';
import 'dart:io';

import 'package:kidslens_video_editor/data/models/models.dart';
import 'package:kidslens_video_editor/jobs/analysis_job.dart';
import 'package:kidslens_video_editor/jobs/cancellation_token.dart';
import 'package:kidslens_video_editor/jobs/job_system.dart';
import 'package:kidslens_video_editor/state/providers/project_provider.dart';
import 'package:kidslens_video_editor/state/providers/service_providers.dart';
import 'package:path/path.dart' as p;
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'analysis_provider.g.dart';

/// State for content analysis
class AnalysisState {
  const AnalysisState({
    this.status = AnalysisStatus.pending,
    this.progress = 0.0,
    this.currentStepProgress = 0.0,
    this.currentStepNumber = 0,
    this.totalSteps = 0,
    this.currentStep,
    this.estimatedSecondsRemaining,
    this.analysisProgress,
    this.result,
    this.errorMessage,
    this.isPaused = false,
    this.isCancelling = false,
    this.detections = const [],
  });

  final AnalysisStatus status;
  final double progress;
  final double currentStepProgress;
  final int currentStepNumber;
  final int totalSteps;
  final String? currentStep;
  final int? estimatedSecondsRemaining;
  final AnalysisProgress? analysisProgress;
  final AnalysisResult? result;
  final String? errorMessage;
  final bool isPaused;
  final bool isCancelling;
  final List<Detection> detections;

  AnalysisState copyWith({
    AnalysisStatus? status,
    double? progress,
    double? currentStepProgress,
    int? currentStepNumber,
    int? totalSteps,
    String? currentStep,
    int? estimatedSecondsRemaining,
    AnalysisProgress? analysisProgress,
    AnalysisResult? result,
    String? errorMessage,
    bool? isPaused,
    bool? isCancelling,
    List<Detection>? detections,
    bool clearError = false,
  }) =>
      AnalysisState(
        status: status ?? this.status,
        progress: progress ?? this.progress,
        currentStepProgress: currentStepProgress ?? this.currentStepProgress,
        currentStepNumber: currentStepNumber ?? this.currentStepNumber,
        totalSteps: totalSteps ?? this.totalSteps,
        currentStep: currentStep ?? this.currentStep,
        estimatedSecondsRemaining:
            estimatedSecondsRemaining ?? this.estimatedSecondsRemaining,
        analysisProgress: analysisProgress ?? this.analysisProgress,
        result: result ?? this.result,
        errorMessage: clearError ? null : errorMessage,
        isPaused: isPaused ?? this.isPaused,
        isCancelling: isCancelling ?? this.isCancelling,
        detections: detections ?? this.detections,
      );
}

/// Provider for managing analysis state
@Riverpod(keepAlive: true)
class AnalysisNotifier extends _$AnalysisNotifier {
  AnalysisJob? _activeJob;
  StreamSubscription<JobProgress>? _jobProgressSubscription;
  StreamSubscription<AnalysisProgress>? _analysisProgressSubscription;
  DateTime? _lastProgressUiUpdateAt;
  double _lastProgressUiValue = -1;
  String? _lastProgressMessage;
  static const Duration _minProgressUiInterval = Duration(milliseconds: 250);
  static const double _minProgressDelta = 0.005;

  @override
  AnalysisState build() {
    ref.onDispose(() {
      _activeJob?.cancel();
      _jobProgressSubscription?.cancel();
      _analysisProgressSubscription?.cancel();
    });
    return const AnalysisState();
  }

  Future<void> startAnalysis({
    required String mediaPath,
    required String mediaId,
    required AnalysisSettings settings,
    required Duration mediaDuration,
    Transcript? existingTranscript,
    bool clearExistingDetections = true,
  }) async {
    await _jobProgressSubscription?.cancel();
    await _analysisProgressSubscription?.cancel();
    _activeJob?.cancel();
    _lastProgressUiUpdateAt = null;
    _lastProgressUiValue = -1;
    _lastProgressMessage = null;
    state = state.copyWith(
      status: AnalysisStatus.running,
      progress: 0,
      currentStepProgress: 0,
      currentStepNumber: 0,
      totalSteps: _selectedStepCount(settings),
      currentStep: 'Initializing analysis...',
      analysisProgress: null,
      isCancelling: false,
      clearError: true,
    );

    final projectNotifier = ref.read(projectNotifierProvider.notifier);
    if (clearExistingDetections) {
      projectNotifier.removeAllDetections(mediaId);
    }
    projectNotifier.updateAnalysisProgress(0);

    try {
      final analysisService = ref.read(analysisServiceProvider);
      final file = File(mediaPath);
      final fileSize = file.existsSync() ? file.lengthSync() : 0;
      final media = MediaFile(
        id: mediaId,
        path: mediaPath,
        name: p.basename(mediaPath),
        duration: mediaDuration,
        width: 0,
        height: 0,
        fileSize: fileSize,
        mediaType: MediaType.video,
      );

      final transcriptForAnalysis = await _resolveTranscriptForAnalysis(
        mediaPath: mediaPath,
        mediaId: mediaId,
        mediaDuration: mediaDuration,
        settings: settings,
        projectNotifier: projectNotifier,
        providedTranscript: existingTranscript,
      );

      final job = AnalysisJob(
        id: 'analysis_${DateTime.now().millisecondsSinceEpoch}',
        media: media,
        settings: settings,
        analysisService: analysisService,
        existingTranscript: transcriptForAnalysis,
      );
      _activeJob = job;

      _analysisProgressSubscription = job.analysisProgress.listen((progress) {
        final durationProgress =
            progress.mediaDurationProgress ?? progress.stepProgress;
        state = state.copyWith(
          progress: progress.overallProgress,
          currentStepProgress: durationProgress,
          currentStepNumber: progress.currentStep,
          totalSteps: progress.totalSteps,
          currentStep: progress.stepName,
          estimatedSecondsRemaining: progress.estimatedSecondsRemaining,
          analysisProgress: progress,
        );
        projectNotifier.updateAnalysisProgress(progress.overallProgress);
      });

      _jobProgressSubscription = job.progress.listen((jobProgress) {
        final progress = jobProgress.progress;
        final message = state.isCancelling
            ? 'Cancelling... finishing current operation (${jobProgress.message}). This may take a few minutes.'
            : jobProgress.message;
        final now = DateTime.now();
        final elapsed = _lastProgressUiUpdateAt == null
            ? _minProgressUiInterval
            : now.difference(_lastProgressUiUpdateAt!);
        final progressValue = progress ?? state.progress;
        final progressDelta = (_lastProgressUiValue - progressValue).abs();
        final messageChanged = _lastProgressMessage != message;
        final shouldForceEmit = progressValue >= 0.999 || progressValue <= 0;
        final shouldEmit = shouldForceEmit ||
            messageChanged ||
            progressDelta >= _minProgressDelta ||
            elapsed >= _minProgressUiInterval;
        if (!shouldEmit) {
          return;
        }

        _lastProgressUiUpdateAt = now;
        _lastProgressUiValue = progressValue;
        _lastProgressMessage = message;

        if (state.isCancelling) {
          if (progress != null) {
            state = state.copyWith(
              progress: progress,
              currentStep: message,
            );
            projectNotifier.updateAnalysisProgress(progress);
          } else {
            state = state.copyWith(currentStep: message);
          }
        } else if (progress == null) {
          state = state.copyWith(currentStep: message);
        }
      });

      final result = await job.run();
      if (state.status != AnalysisStatus.cancelled) {
        final detections = job.detectedDetections.toList()
          ..sort((a, b) => a.startTime.compareTo(b.startTime));
        projectNotifier
          ..addDetections(detections)
          ..updateAnalysisProgress(1);
        state = state.copyWith(
          status: AnalysisStatus.completed,
          progress: 1,
          currentStepProgress: 1,
          currentStep: 'Analysis complete',
          currentStepNumber:
              state.totalSteps > 0 ? state.totalSteps : state.currentStepNumber,
          detections: detections,
          result: result,
          isPaused: false,
          isCancelling: false,
        );
      }
    } on CancelledException {
      projectNotifier.updateAnalysisProgress(0);
      state = state.copyWith(
        status: AnalysisStatus.cancelled,
        currentStep: 'Cancelled by user',
        currentStepProgress: 0,
        isPaused: false,
        isCancelling: false,
      );
    } catch (e) {
      state = state.copyWith(
        status: AnalysisStatus.failed,
        errorMessage: e.toString(),
        isPaused: false,
        isCancelling: false,
      );
    } finally {
      await _jobProgressSubscription?.cancel();
      await _analysisProgressSubscription?.cancel();
      _jobProgressSubscription = null;
      _analysisProgressSubscription = null;
      _activeJob = null;
      _lastProgressUiUpdateAt = null;
      _lastProgressUiValue = -1;
      _lastProgressMessage = null;
    }
  }

  int _selectedStepCount(AnalysisSettings settings) {
    var count = 0;
    if (_hasProfanityCategory(settings)) {
      count++;
    }

    final enabledVisual = settings.contentDetectionConfig.enabledVisualCategories;
    if (enabledVisual.any((c) => c.id == 'nsfw')) {
      count++;
    }
    if (enabledVisual.any((c) => c.id == 'nudity')) {
      count++;
    }

    return count <= 0 ? 1 : count;
  }

  bool _hasProfanityCategory(AnalysisSettings settings) =>
      settings.contentDetectionConfig.enabledAudioCategories.any(
        (c) => c.id == 'profanity',
      );

  Future<Transcript?> _resolveTranscriptForAnalysis({
    required String mediaPath,
    required String mediaId,
    required Duration mediaDuration,
    required AnalysisSettings settings,
    required ProjectNotifier projectNotifier,
    required Transcript? providedTranscript,
  }) async {
    if (!_hasProfanityCategory(settings)) {
      return providedTranscript;
    }

    if (providedTranscript != null) {
      state = state.copyWith(
        currentStep: 'Using existing transcript for profanity detection...',
      );
      return providedTranscript;
    }

    final project = ref.read(projectNotifierProvider).currentProject;
    final existingTrack = project?.subtitleTrackForMedia(mediaId);
    if (existingTrack != null) {
      state = state.copyWith(
        currentStep: 'Using existing transcript for profanity detection...',
      );
      return existingTrack.toTranscript();
    }

    state = state.copyWith(
      currentStep: 'No transcript found. Transcribing audio first...',
    );

    final asrService = ref.read(asrServiceProvider);
    final subtitleTrack = await asrService.transcribeToSubtitleTrack(
      mediaPath,
      mediaId: mediaId,
      trackId: DateTime.now().microsecondsSinceEpoch.toString(),
      language: settings.modelConfig.asrLanguage == 'auto'
          ? null
          : settings.modelConfig.asrLanguage,
      preferredModel: settings.modelConfig.asrModelId,
      mediaDuration: mediaDuration,
      useGpu: settings.modelConfig.useGpu,
      gpuDeviceIndex: settings.modelConfig.gpuDeviceIndex,
      nThreads: settings.modelConfig.cpuThreads,
      beamSize: settings.modelConfig.beamSize,
      onProgress: (_, progress, message, __) {
        final warmupProgress = (progress * 0.15).clamp(0.0, 0.15);
        state = state.copyWith(
          progress: warmupProgress,
          currentStep: message,
        );
        projectNotifier.updateAnalysisProgress(warmupProgress);
      },
    );

    projectNotifier.addSubtitleTrack(subtitleTrack);
    state = state.copyWith(
      currentStep: 'Transcript saved. Continuing analysis...',
    );
    return subtitleTrack.toTranscript();
  }

  void updateProgress(AnalysisProgress progress) {
    state = state.copyWith(
      progress: progress.overallProgress,
      currentStep: progress.stepName,
      estimatedSecondsRemaining: progress.estimatedSecondsRemaining,
    );
  }

  void pause() {
    if (state.status == AnalysisStatus.running &&
        !state.isPaused &&
        !state.isCancelling &&
        _activeJob != null) {
      _activeJob!.pause();
      state = state.copyWith(isPaused: true, currentStep: 'Paused');
    }
  }

  void resume() {
    if (state.status == AnalysisStatus.running &&
        state.isPaused &&
        !state.isCancelling &&
        _activeJob != null) {
      _activeJob!.resume();
      state = state.copyWith(isPaused: false, currentStep: 'Resumed');
    }
  }

  void cancel() {
    if (state.status != AnalysisStatus.running ||
        state.isCancelling ||
        _activeJob == null) {
      return;
    }

    _activeJob!.cancel();
    state = state.copyWith(
      isCancelling: true,
      isPaused: false,
      currentStep:
          'Cancelling... finishing current operation. This may take a few minutes.',
    );
  }

  void reset() {
    _activeJob?.cancel();
    unawaited(_jobProgressSubscription?.cancel());
    _activeJob = null;
    _jobProgressSubscription = null;
    _lastProgressUiUpdateAt = null;
    _lastProgressUiValue = -1;
    _lastProgressMessage = null;
    state = const AnalysisState();
  }
}
