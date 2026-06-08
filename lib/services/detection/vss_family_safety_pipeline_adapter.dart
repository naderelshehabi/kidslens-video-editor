import 'package:kidslens_video_editor/data/models/models.dart';
import 'package:kidslens_video_editor/services/detection/detection_pipeline.dart';
import 'package:kidslens_video_editor/services/detection/detection_pipeline_profile.dart';

typedef VssFamilySafetyAnalysisRunner = Stream<AnalysisProgress> Function(
  DetectionPipelineRequest request,
);

/// Development adapter for the default VSS family-safety pipeline.
///
/// The VSS orchestration boundary is intentionally distinct from the legacy
/// profile so settings, rollout, telemetry, and UI can migrate to
/// `vss_family_safety_v1` now. The runner can be replaced by the concrete local
/// VLM/evidence/policy implementation as production model bundles are approved.
class VssFamilySafetyPipelineAdapter implements DetectionPipeline {
  const VssFamilySafetyPipelineAdapter({
    required VssFamilySafetyAnalysisRunner runAnalysis,
  }) : _runAnalysis = runAnalysis;

  final VssFamilySafetyAnalysisRunner _runAnalysis;

  @override
  DetectionPipelineProfile get profile =>
      DetectionPipelineProfile.vssFamilySafetyV1;

  @override
  Stream<AnalysisProgress> analyze(DetectionPipelineRequest request) async* {
    yield const AnalysisProgress(
      stepName: 'VSS Family Safety: initializing local pipeline',
      currentStep: 1,
      totalSteps: 1,
      stepProgress: 0,
    );
    yield* _runAnalysis(request);
  }
}
