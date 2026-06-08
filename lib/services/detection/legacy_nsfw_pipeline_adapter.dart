import 'package:kidslens_video_editor/data/models/models.dart';
import 'package:kidslens_video_editor/services/detection/detection_pipeline.dart';
import 'package:kidslens_video_editor/services/detection/detection_pipeline_profile.dart';

typedef LegacyAnalysisRunner = Stream<AnalysisProgress> Function(
  DetectionPipelineRequest request,
);

/// Adapter that exposes the current direct-detection implementation through
/// the new pipeline registry contract.
class LegacyNsfwPipelineAdapter implements DetectionPipeline {
  const LegacyNsfwPipelineAdapter({
    required LegacyAnalysisRunner runLegacyAnalysis,
  }) : _runLegacyAnalysis = runLegacyAnalysis;

  final LegacyAnalysisRunner _runLegacyAnalysis;

  @override
  DetectionPipelineProfile get profile =>
      DetectionPipelineProfile.legacyNsfwRegionV8;

  @override
  Stream<AnalysisProgress> analyze(DetectionPipelineRequest request) =>
      _runLegacyAnalysis(request);
}
