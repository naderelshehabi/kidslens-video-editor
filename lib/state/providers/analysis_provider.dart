import 'dart:async';
import 'dart:math' as math;

import 'package:kidslens_video_editor/data/models/models.dart';
import 'package:kidslens_video_editor/state/providers/project_provider.dart';
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
    this.detections = const [],
  });

  final AnalysisStatus status;
  final double progress;
  final String? currentStep;
  final int? estimatedSecondsRemaining;
  final AnalysisResult? result;
  final String? errorMessage;
  final bool isPaused;
  final List<Detection> detections;

  AnalysisState copyWith({
    AnalysisStatus? status,
    double? progress,
    String? currentStep,
    int? estimatedSecondsRemaining,
    AnalysisResult? result,
    String? errorMessage,
    bool? isPaused,
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
        detections: detections ?? this.detections,
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
    required String mediaId,
    required AnalysisSettings settings,
    required Duration mediaDuration,
  }) async {
    state = state.copyWith(
      status: AnalysisStatus.running,
      progress: 0,
      currentStep: 'Initializing analysis...',
      clearError: true,
    );

    try {
      final random = math.Random();
      final detections = <Detection>[];
      final totalDurationMs = mediaDuration.inMilliseconds;
      
      // Ensure we have enough duration to work with
      if (totalDurationMs < 3000) {
        state = state.copyWith(
          status: AnalysisStatus.completed,
          progress: 1,
          currentStep: 'Analysis complete (video too short for demo detections)',
          detections: [],
        );
        return;
      }
      
      // Step 1: Audio transcription (0-30%)
      state = state.copyWith(
        currentStep: 'Transcribing audio...',
        progress: 0.05,
      );
      await Future<void>.delayed(const Duration(milliseconds: 500));
      
      // Generate sample profanity detections (audio-based)
      if (settings.enableProfanity) {
        final numProfanityDetections = 2 + random.nextInt(3); // 2-4 detections
        for (var i = 0; i < numProfanityDetections; i++) {
          final startMs = random.nextInt(totalDurationMs - 2000);
          final durationMs = 500 + random.nextInt(1500); // 0.5-2 seconds
          detections.add(Detection(
            id: 'det_profanity_$i',
            mediaId: mediaId,
            type: ContentType.profanity,
            startTime: Duration(milliseconds: startMs),
            endTime: Duration(milliseconds: startMs + durationMs),
            confidence: 0.75 + random.nextDouble() * 0.2,
            description: _getRandomProfanityDescription(random),
          ),);
        }
      }
      
      state = state.copyWith(progress: 0.30);
      await Future<void>.delayed(const Duration(milliseconds: 300));
      
      // Step 2: Frame analysis (30-70%)
      state = state.copyWith(
        currentStep: 'Analyzing video frames...',
        progress: 0.35,
      );
      await Future<void>.delayed(const Duration(milliseconds: 600));
      
      // Generate sample violence detections
      if (settings.enableViolence) {
        final numViolenceDetections = 1 + random.nextInt(2); // 1-2 detections
        for (var i = 0; i < numViolenceDetections; i++) {
          final startMs = random.nextInt(totalDurationMs - 5000);
          final durationMs = 2000 + random.nextInt(4000); // 2-6 seconds
          detections.add(Detection(
            id: 'det_violence_$i',
            mediaId: mediaId,
            type: ContentType.violence,
            startTime: Duration(milliseconds: startMs),
            endTime: Duration(milliseconds: startMs + durationMs),
            confidence: 0.70 + random.nextDouble() * 0.25,
            description: 'Potential violent content detected',
          ),);
        }
      }
      
      state = state.copyWith(progress: 0.55);
      await Future<void>.delayed(const Duration(milliseconds: 400));
      
      // Generate sample NSFW detections  
      if (settings.enableNsfw) {
        if (random.nextDouble() > 0.6) { // 40% chance
          final startMs = random.nextInt(totalDurationMs - 3000);
          final durationMs = 1500 + random.nextInt(2500);
          detections.add(Detection(
            id: 'det_nsfw_0',
            mediaId: mediaId,
            type: ContentType.nsfw,
            startTime: Duration(milliseconds: startMs),
            endTime: Duration(milliseconds: startMs + durationMs),
            confidence: 0.65 + random.nextDouble() * 0.30,
            description: 'Potential inappropriate visual content',
          ),);
        }
      }
      
      state = state.copyWith(progress: 0.70);
      await Future<void>.delayed(const Duration(milliseconds: 300));
      
      // Step 3: Content classification (70-90%)
      state = state.copyWith(
        currentStep: 'Classifying content...',
        progress: 0.75,
      );
      await Future<void>.delayed(const Duration(milliseconds: 400));
      
      // Generate sample blood detections
      if (settings.enableBlood) {
        if (random.nextDouble() > 0.7) { // 30% chance
          final startMs = random.nextInt(totalDurationMs - 4000);
          final durationMs = 2000 + random.nextInt(3000);
          detections.add(Detection(
            id: 'det_blood_0',
            mediaId: mediaId,
            type: ContentType.blood,
            startTime: Duration(milliseconds: startMs),
            endTime: Duration(milliseconds: startMs + durationMs),
            confidence: 0.60 + random.nextDouble() * 0.35,
            description: 'Potential blood/gore content',
          ),);
        }
      }
      
      // Generate sample weapons detections
      if (settings.enableWeapons) {
        if (random.nextDouble() > 0.65) { // 35% chance
          final startMs = random.nextInt(totalDurationMs - 3000);
          final durationMs = 1500 + random.nextInt(2000);
          detections.add(Detection(
            id: 'det_weapons_0',
            mediaId: mediaId,
            type: ContentType.weapons,
            startTime: Duration(milliseconds: startMs),
            endTime: Duration(milliseconds: startMs + durationMs),
            confidence: 0.55 + random.nextDouble() * 0.40,
            description: 'Potential weapons detected',
          ),);
        }
      }
      
      state = state.copyWith(progress: 0.90);
      await Future<void>.delayed(const Duration(milliseconds: 300));
      
      // Step 4: Finalizing (90-100%)
      state = state.copyWith(
        currentStep: 'Finalizing results...',
        progress: 0.95,
      );
      await Future<void>.delayed(const Duration(milliseconds: 200));
      
      // Sort detections by start time and update project
      detections.sort((a, b) => a.startTime.compareTo(b.startTime));
      ref.read(projectNotifierProvider.notifier).addDetections(detections);
      
      state = state.copyWith(
        status: AnalysisStatus.completed,
        progress: 1,
        currentStep: 'Analysis complete',
        detections: detections,
      );
    } catch (e) {
      state = state.copyWith(
        status: AnalysisStatus.failed,
        errorMessage: e.toString(),
      );
    }
  }
  
  String _getRandomProfanityDescription(math.Random random) {
    final descriptions = [
      'Mild profanity detected in audio',
      'Strong language detected',
      'Inappropriate word detected',
      'Profane expression detected',
    ];
    return descriptions[random.nextInt(descriptions.length)];
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
