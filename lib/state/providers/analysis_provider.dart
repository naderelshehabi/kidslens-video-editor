import 'dart:async';

import 'package:kidslens_video_editor/data/models/models.dart';
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
  });

  final AnalysisStatus status;
  final double progress;
  final String? currentStep;
  final int? estimatedSecondsRemaining;
  final AnalysisResult? result;
  final String? errorMessage;
  final bool isPaused;

  AnalysisState copyWith({
    AnalysisStatus? status,
    double? progress,
    String? currentStep,
    int? estimatedSecondsRemaining,
    AnalysisResult? result,
    String? errorMessage,
    bool? isPaused,
  }) =>
      AnalysisState(
          status: status ?? this.status,
        progress: progress ?? this.progress,
        currentStep: currentStep ?? this.currentStep,
        estimatedSecondsRemaining:
            estimatedSecondsRemaining ?? this.estimatedSecondsRemaining,
        result: result ?? this.result,
        errorMessage: errorMessage,
        isPaused: isPaused ?? this.isPaused,
      );
}

/// Provider for managing analysis state
@Riverpod(keepAlive: true)
class AnalysisNotifier extends _$AnalysisNotifier {
  StreamSubscription<AnalysisProgress>? _progressSubscription;

  @override
  AnalysisState build() {
    ref.onDispose(() {
      _progressSubscription?.cancel();
    });
    return const AnalysisState();
  }

  Future<void> startAnalysis({
    required String mediaPath,
    required AnalysisSettings settings,
  }) async {
    state = state.copyWith(
      status: AnalysisStatus.running,
      progress: 0,
      currentStep: 'Initializing',
    );

    try {
      // TODO: Implement actual analysis via AnalysisJob
      // This will use the job system with CancellationToken
      await Future<void>.delayed(const Duration(milliseconds: 100));
      state = state.copyWith(
        status: AnalysisStatus.completed,
        progress: 1,
        currentStep: 'Complete',
      );
    } catch (e) {
      state = state.copyWith(
        status: AnalysisStatus.failed,
        errorMessage: e.toString(),
      );
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
    if (state.status == AnalysisStatus.running && !state.isPaused) {
      state = state.copyWith(isPaused: true);
    }
  }

  void resume() {
    if (state.status == AnalysisStatus.running && state.isPaused) {
      state = state.copyWith(isPaused: false);
    }
  }

  void cancel() {
    _progressSubscription?.cancel();
    state = state.copyWith(status: AnalysisStatus.cancelled);
  }

  void reset() {
    _progressSubscription?.cancel();
    state = const AnalysisState();
  }
}
