import 'package:kidslens_video_editor/data/models/models.dart';
import 'package:kidslens_video_editor/jobs/cancellation_token.dart';
import 'package:kidslens_video_editor/services/detection/detection_pipeline_profile.dart';

/// Callback for preserving existing analysis UI integration points.
typedef TimelineBuiltCallback = void Function(UnifiedTimeline timeline);
typedef DetectionsBuiltCallback = void Function(List<Detection> detections);
typedef FrameResultsBuiltCallback = void Function(
  List<FrameAnalysisResult> frameResults,
);

/// Complete request passed to a detection pipeline implementation.
class DetectionPipelineRequest {
  const DetectionPipelineRequest({
    required this.mediaPath,
    required this.settings,
    this.mediaId,
    this.checkpoint,
    this.existingTranscript,
    this.cancellationToken,
    this.onTimelineBuilt,
    this.onDetectionsBuilt,
    this.onFrameResultsBuilt,
  });

  final String mediaPath;
  final AnalysisSettings settings;
  final String? mediaId;
  final AnalysisCheckpoint? checkpoint;
  final Transcript? existingTranscript;
  final CancellationToken? cancellationToken;
  final TimelineBuiltCallback? onTimelineBuilt;
  final DetectionsBuiltCallback? onDetectionsBuilt;
  final FrameResultsBuiltCallback? onFrameResultsBuilt;
}

/// Runtime-neutral orchestration boundary for video detection pipelines.
abstract interface class DetectionPipeline {
  DetectionPipelineProfile get profile;

  Stream<AnalysisProgress> analyze(DetectionPipelineRequest request);
}
