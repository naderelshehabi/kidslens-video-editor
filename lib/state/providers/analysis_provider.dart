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
    this.currentStep,
    this.estimatedSecondsRemaining,
    this.result,
    this.errorMessage,
    this.isPaused = false,
    this.isCancelling = false,
    this.detections = const [],
  });

  final AnalysisStatus status;
  final double progress;
  final String? currentStep;
  final int? estimatedSecondsRemaining;
  final AnalysisResult? result;
  final String? errorMessage;
  final bool isPaused;
  final bool isCancelling;
  final List<Detection> detections;

  AnalysisState copyWith({
    AnalysisStatus? status,
    double? progress,
    String? currentStep,
    int? estimatedSecondsRemaining,
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
        currentStep: currentStep ?? this.currentStep,
        estimatedSecondsRemaining:
            estimatedSecondsRemaining ?? this.estimatedSecondsRemaining,
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
    _activeJob?.cancel();
    _lastProgressUiUpdateAt = null;
    _lastProgressUiValue = -1;
    _lastProgressMessage = null;
    state = state.copyWith(
      status: AnalysisStatus.running,
      progress: 0,
      currentStep: 'Initializing analysis...',
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

      final job = AnalysisJob(
        id: 'analysis_${DateTime.now().millisecondsSinceEpoch}',
        media: media,
        settings: settings,
        analysisService: analysisService,
        existingTranscript: existingTranscript,
      );
      _activeJob = job;

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

        if (progress != null) {
          state = state.copyWith(
            progress: progress,
            currentStep: message,
          );
          projectNotifier.updateAnalysisProgress(progress);
        } else {
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
          currentStep: 'Analysis complete',
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
      _jobProgressSubscription = null;
      _activeJob = null;
      _lastProgressUiUpdateAt = null;
      _lastProgressUiValue = -1;
      _lastProgressMessage = null;
    }
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
