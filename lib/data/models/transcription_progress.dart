import 'package:freezed_annotation/freezed_annotation.dart';

import 'package:kidslens_video_editor/data/models/converters.dart';
import 'package:kidslens_video_editor/data/models/transcript.dart';

part 'transcription_progress.freezed.dart';
part 'transcription_progress.g.dart';

/// Progress information for ASR transcription
@freezed
class TranscriptionProgress with _$TranscriptionProgress {
  const factory TranscriptionProgress({
    /// Progress value from 0.0 to 1.0
    required double progress,

    /// Current segment being processed (if available)
    TranscriptSegment? currentSegment,

    /// Estimated time remaining for transcription
    @NullableDurationConverter() Duration? estimatedTimeRemaining,

    /// Whether the transcription is complete
    @Default(false) bool isComplete,

    /// Number of segments processed so far
    @Default(0) int segmentsProcessed,

    /// Total segments (estimated, may change during processing)
    int? totalSegments,

    /// Current processing phase
    @Default(TranscriptionPhase.initializing) TranscriptionPhase phase,

    /// Error message if transcription failed
    String? errorMessage,
  }) = _TranscriptionProgress;

  const TranscriptionProgress._();

  factory TranscriptionProgress.fromJson(Map<String, dynamic> json) =>
      _$TranscriptionProgressFromJson(json);

  /// Creates initial progress state
  factory TranscriptionProgress.initial() => const TranscriptionProgress(
        progress: 0,
      );

  /// Creates a completed progress state
  factory TranscriptionProgress.completed() => const TranscriptionProgress(
        progress: 1,
        isComplete: true,
        phase: TranscriptionPhase.complete,
      );

  /// Creates an error progress state
  factory TranscriptionProgress.error(String message) => TranscriptionProgress(
        progress: 0,
        phase: TranscriptionPhase.failed,
        errorMessage: message,
      );

  /// Progress as a percentage (0-100)
  double get percentage => progress * 100;

  /// Whether transcription has failed
  bool get hasFailed => phase == TranscriptionPhase.failed;

  /// Formatted estimated time remaining (e.g., "2:30")
  String? get estimatedTimeRemainingFormatted {
    if (estimatedTimeRemaining == null) return null;
    final minutes = estimatedTimeRemaining!.inMinutes;
    final seconds = estimatedTimeRemaining!.inSeconds % 60;
    return '$minutes:${seconds.toString().padLeft(2, '0')}';
  }
}

/// Phases of the transcription process
@JsonEnum()
enum TranscriptionPhase {
  /// Initializing the transcription engine
  @JsonValue('initializing')
  initializing,

  /// Loading the ASR model
  @JsonValue('loadingModel')
  loadingModel,

  /// Extracting audio from video
  @JsonValue('extractingAudio')
  extractingAudio,

  /// Running transcription
  @JsonValue('transcribing')
  transcribing,

  /// Post-processing results
  @JsonValue('postProcessing')
  postProcessing,

  /// Transcription complete
  @JsonValue('complete')
  complete,

  /// Transcription failed
  @JsonValue('failed')
  failed,
}
