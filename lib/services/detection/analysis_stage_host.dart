import 'package:kidslens_video_editor/data/models/models.dart';
import 'package:kidslens_video_editor/jobs/cancellation_token.dart';
import 'package:kidslens_video_editor/services/detection/detection_pipeline.dart';
import 'package:kidslens_video_editor/services/media_service.dart';

class AnalysisVisualAuxiliaryResult {
  const AnalysisVisualAuxiliaryResult({
    this.frameResults = const <FrameAnalysisResult>[],
    this.visualDetections = const <Detection>[],
  });

  final List<FrameAnalysisResult> frameResults;
  final List<Detection> visualDetections;
}

class AnalysisVisualAuxiliaryProgressUpdate {
  const AnalysisVisualAuxiliaryProgressUpdate({
    required this.progress,
    this.result,
  });

  final AnalysisProgress progress;
  final AnalysisVisualAuxiliaryResult? result;
}

abstract interface class AnalysisStageHost {
  Stream<AnalysisProgress> runLegacyAnalysis(DetectionPipelineRequest request);

  Future<MediaMetadata> probeMedia(
    String mediaPath, {
    CancellationToken? cancellationToken,
  });

  Future<Transcript> transcribeAudio(
    String mediaPath,
    AnalysisSettings settings, {
    CancellationToken? cancellationToken,
    void Function(String message, double progress)? onProgress,
  });

  Future<List<ProfanityMatch>> detectProfanity(
    Transcript transcript,
    AnalysisSettings settings, {
    CancellationToken? cancellationToken,
  });

  Stream<AnalysisVisualAuxiliaryProgressUpdate> runVisualAuxiliarySignals(
    DetectionPipelineRequest request, {
    required Duration mediaDuration,
    required int currentStep,
    required int totalSteps,
  });

  Future<void> checkState(CancellationToken? token);
}
