import 'package:freezed_annotation/freezed_annotation.dart';

import 'converters.dart';
import 'frame_analysis_result.dart';
import 'profanity_match.dart';
import 'timeline.dart';
import 'transcript.dart';

part 'analysis_result.freezed.dart';
part 'analysis_result.g.dart';

/// Status of an analysis operation
@JsonEnum()
enum AnalysisStatus {
  /// Analysis has not started
  @JsonValue('pending')
  pending,

  /// Analysis is in progress
  @JsonValue('running')
  running,

  /// Analysis completed successfully
  @JsonValue('completed')
  completed,

  /// Analysis failed with error
  @JsonValue('failed')
  failed,

  /// Analysis was cancelled
  @JsonValue('cancelled')
  cancelled,
}

/// Progress information for an ongoing analysis
@freezed
class AnalysisProgress with _$AnalysisProgress {
  const AnalysisProgress._();

  const factory AnalysisProgress({
    /// Current step name (e.g., 'Transcribing', 'Analyzing frames')
    required String stepName,

    /// Current step number (1-based)
    required int currentStep,

    /// Total number of steps
    required int totalSteps,

    /// Progress within current step (0.0 to 1.0)
    required double stepProgress,

    /// Estimated time remaining in seconds
    int? estimatedSecondsRemaining,

    /// Number of items processed in current step
    int? itemsProcessed,

    /// Total items in current step
    int? totalItems,
  }) = _AnalysisProgress;

  factory AnalysisProgress.fromJson(Map<String, dynamic> json) =>
      _$AnalysisProgressFromJson(json);

  /// Creates initial progress
  factory AnalysisProgress.initial() {
    return const AnalysisProgress(
      stepName: 'Starting',
      currentStep: 0,
      totalSteps: 4,
      stepProgress: 0.0,
    );
  }

  /// Overall progress (0.0 to 1.0)
  double get overallProgress {
    if (totalSteps == 0) return 0.0;
    final stepContribution = 1.0 / totalSteps;
    final completedSteps = (currentStep - 1) * stepContribution;
    final currentStepContribution = stepProgress * stepContribution;
    return (completedSteps + currentStepContribution).clamp(0.0, 1.0);
  }

  /// Overall progress as percentage (0-100)
  int get overallPercentage => (overallProgress * 100).round();

  /// Formatted estimated time remaining
  String get estimatedTimeFormatted {
    if (estimatedSecondsRemaining == null) return 'Calculating...';
    if (estimatedSecondsRemaining! < 60) {
      return '${estimatedSecondsRemaining}s remaining';
    }
    final minutes = estimatedSecondsRemaining! ~/ 60;
    final seconds = estimatedSecondsRemaining! % 60;
    return '${minutes}m ${seconds}s remaining';
  }

  /// Item progress description
  String get itemProgressDescription {
    if (itemsProcessed == null || totalItems == null) return '';
    return '$itemsProcessed / $totalItems';
  }
}

/// Complete result of video analysis
@freezed
class AnalysisResult with _$AnalysisResult {
  const AnalysisResult._();

  const factory AnalysisResult({
    /// Unique identifier for this analysis
    required String id,

    /// Current status of the analysis
    @Default(AnalysisStatus.pending) AnalysisStatus status,

    /// Generated transcript (null if not completed or audio analysis disabled)
    Transcript? transcript,

    /// List of profanity matches found in transcript
    @Default([]) List<ProfanityMatch> profanityMatches,

    /// List of frame analysis results
    @Default([]) List<FrameAnalysisResult> frameResults,

    /// Unified timeline combining all detections
    UnifiedTimeline? timeline,

    /// Total processing time
    @DurationConverter() Duration? processingTime,

    /// Timestamp when analysis started
    DateTime? startedAt,

    /// Timestamp when analysis completed
    DateTime? completedAt,

    /// Error message if analysis failed
    String? errorMessage,

    /// Current progress (for running analysis)
    AnalysisProgress? progress,

    /// ID of the media file analyzed
    String? mediaFileId,

    /// Settings used for this analysis
    Map<String, dynamic>? settings,
  }) = _AnalysisResult;

  factory AnalysisResult.fromJson(Map<String, dynamic> json) =>
      _$AnalysisResultFromJson(json);

  /// Creates an empty/pending analysis result
  factory AnalysisResult.empty({required String id, String? mediaFileId}) {
    return AnalysisResult(
      id: id,
      status: AnalysisStatus.pending,
      mediaFileId: mediaFileId,
    );
  }

  /// Creates a running analysis result
  factory AnalysisResult.running({
    required String id,
    String? mediaFileId,
    AnalysisProgress? progress,
  }) {
    return AnalysisResult(
      id: id,
      status: AnalysisStatus.running,
      startedAt: DateTime.now(),
      mediaFileId: mediaFileId,
      progress: progress ?? AnalysisProgress.initial(),
    );
  }

  /// Creates a failed analysis result
  factory AnalysisResult.failed({
    required String id,
    required String errorMessage,
    String? mediaFileId,
    DateTime? startedAt,
  }) {
    return AnalysisResult(
      id: id,
      status: AnalysisStatus.failed,
      errorMessage: errorMessage,
      mediaFileId: mediaFileId,
      startedAt: startedAt,
      completedAt: DateTime.now(),
    );
  }

  /// Whether analysis is pending
  bool get isPending => status == AnalysisStatus.pending;

  /// Whether analysis is running
  bool get isRunning => status == AnalysisStatus.running;

  /// Whether analysis is completed
  bool get isCompleted => status == AnalysisStatus.completed;

  /// Whether analysis failed
  bool get isFailed => status == AnalysisStatus.failed;

  /// Whether analysis was cancelled
  bool get isCancelled => status == AnalysisStatus.cancelled;

  /// Whether analysis is finished (completed, failed, or cancelled)
  bool get isFinished => isCompleted || isFailed || isCancelled;

  /// Whether transcript is available
  bool get hasTranscript => transcript != null;

  /// Whether timeline is available
  bool get hasTimeline => timeline != null;

  /// Total number of profanity matches
  int get profanityCount => profanityMatches.length;

  /// Total number of frame results
  int get frameCount => frameResults.length;

  /// Number of valid profanity matches (not marked as false positive)
  int get validProfanityCount =>
      profanityMatches.where((m) => !m.isFalsePositive).length;

  /// Total detections across all types
  int get totalDetectionCount {
    final profanity = validProfanityCount;
    final visual = timeline?.totalSegmentCount ?? 0;
    return profanity + visual;
  }

  /// Gets profanity matches that are not false positives
  List<ProfanityMatch> get validProfanityMatches {
    return profanityMatches.where((m) => !m.isFalsePositive).toList();
  }

  /// Gets frame results with NSFW content at threshold
  List<FrameAnalysisResult> getNsfwFrames(double threshold) {
    return frameResults.where((f) => f.hasNsfwAt(threshold)).toList();
  }

  /// Gets frame results with violence at threshold
  List<FrameAnalysisResult> getViolenceFrames(double threshold) {
    return frameResults.where((f) => f.hasViolenceAt(threshold)).toList();
  }

  /// Gets frame results with blood at threshold
  List<FrameAnalysisResult> getBloodFrames(double threshold) {
    return frameResults.where((f) => f.hasBloodAt(threshold)).toList();
  }

  /// Gets frame results with weapons at threshold
  List<FrameAnalysisResult> getWeaponsFrames(double threshold) {
    return frameResults.where((f) => f.hasWeaponsAt(threshold)).toList();
  }

  /// Summary statistics for the analysis
  Map<String, int> get detectionSummary {
    return {
      'profanity': validProfanityCount,
      'nsfw': timeline?.tracks
              .expand((t) => t.segments)
              .where((s) => s.type.name == 'nsfw')
              .length ??
          0,
      'violence': timeline?.tracks
              .expand((t) => t.segments)
              .where((s) => s.type.name == 'violence')
              .length ??
          0,
      'blood': timeline?.tracks
              .expand((t) => t.segments)
              .where((s) => s.type.name == 'blood')
              .length ??
          0,
      'weapons': timeline?.tracks
              .expand((t) => t.segments)
              .where((s) => s.type.name == 'weapons')
              .length ??
          0,
    };
  }

  /// Processing time formatted as string
  String get processingTimeFormatted {
    if (processingTime == null) return 'Unknown';
    final minutes = processingTime!.inMinutes;
    final seconds = processingTime!.inSeconds % 60;
    if (minutes > 0) {
      return '${minutes}m ${seconds}s';
    }
    return '${seconds}s';
  }

  /// Creates a completed result
  AnalysisResult complete({
    Transcript? transcript,
    List<ProfanityMatch>? profanityMatches,
    List<FrameAnalysisResult>? frameResults,
    UnifiedTimeline? timeline,
  }) {
    final now = DateTime.now();
    return copyWith(
      status: AnalysisStatus.completed,
      transcript: transcript ?? this.transcript,
      profanityMatches: profanityMatches ?? this.profanityMatches,
      frameResults: frameResults ?? this.frameResults,
      timeline: timeline ?? this.timeline,
      completedAt: now,
      processingTime: startedAt != null ? now.difference(startedAt!) : null,
      progress: null,
    );
  }

  /// Creates a cancelled result
  AnalysisResult cancel() {
    return copyWith(
      status: AnalysisStatus.cancelled,
      completedAt: DateTime.now(),
      progress: null,
    );
  }

  /// Updates progress
  AnalysisResult withProgress(AnalysisProgress newProgress) {
    return copyWith(progress: newProgress);
  }
}
