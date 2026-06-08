import 'package:flutter_test/flutter_test.dart';
import 'package:kidslens_video_editor/data/models/models.dart';
import 'package:kidslens_video_editor/services/detection/detection_pipeline.dart';
import 'package:kidslens_video_editor/services/detection/detection_pipeline_profile.dart';
import 'package:kidslens_video_editor/services/detection/detection_pipeline_registry.dart';
import 'package:kidslens_video_editor/services/detection/detection_pipeline_rollout.dart';

void main() {
  group('DetectionPipelineRegistry', () {
    test('registers the required built-in profile IDs', () {
      final profileIds = DetectionPipelineProfile.builtInProfiles
          .map((profile) => profile.id)
          .toSet();

      expect(profileIds, contains(DetectionPipelineIds.vssFamilySafetyV1));
      expect(profileIds, contains(DetectionPipelineIds.legacyNsfwRegionV8));
      expect(profileIds, contains(DetectionPipelineIds.audioOnly));
      expect(profileIds, contains(DetectionPipelineIds.fastPreview));
    });

    test('resolves the legacy pipeline by explicit profile ID', () {
      const legacy = _StubPipeline(DetectionPipelineProfile.legacyNsfwRegionV8);
      final registry = DetectionPipelineRegistry(
        pipelines: [legacy],
        defaultPipelineId: DetectionPipelineIds.legacyNsfwRegionV8,
      );

      expect(
        registry.resolve(DetectionPipelineIds.legacyNsfwRegionV8),
        same(legacy),
      );
    });

    test('resolves the VSS default pipeline when registered', () {
      const legacy = _StubPipeline(DetectionPipelineProfile.legacyNsfwRegionV8);
      const vss = _StubPipeline(DetectionPipelineProfile.vssFamilySafetyV1);
      final registry = DetectionPipelineRegistry(pipelines: [legacy, vss]);

      expect(
        registry.resolve(DetectionPipelineIds.vssFamilySafetyV1),
        same(vss),
      );
    });

    test('falls back to default for unknown or blank profile IDs', () {
      const legacy = _StubPipeline(DetectionPipelineProfile.legacyNsfwRegionV8);
      const vss = _StubPipeline(DetectionPipelineProfile.vssFamilySafetyV1);
      final registry = DetectionPipelineRegistry(pipelines: [legacy, vss]);

      expect(registry.resolve('unknown_pipeline'), same(vss));
      expect(registry.resolve(''), same(vss));
      expect(registry.resolve(null), same(vss));
    });

    test('requires default pipeline to be registered', () {
      expect(
        () => DetectionPipelineRegistry(pipelines: const []),
        throwsArgumentError,
      );
    });

    test('resolves rollout off to the legacy pipeline', () {
      const legacy = _StubPipeline(DetectionPipelineProfile.legacyNsfwRegionV8);
      final registry = DetectionPipelineRegistry(
        pipelines: [legacy],
        defaultPipelineId: DetectionPipelineIds.legacyNsfwRegionV8,
      );

      final decision = registry.resolveRollout(
        DetectionPipelineIds.vssFamilySafetyV1,
        config: const DetectionPipelineRolloutConfig(
          state: DetectionPipelineRolloutState.off,
        ),
      );

      expect(
          decision.activePipelineId, DetectionPipelineIds.legacyNsfwRegionV8);
      expect(decision.state, DetectionPipelineRolloutState.off);
      expect(decision.shadowPipelineId, isNull);
    });

    test('does not shadow VSS unless the VSS pipeline itself can run', () {
      const legacy = _StubPipeline(DetectionPipelineProfile.legacyNsfwRegionV8);
      final registry = DetectionPipelineRegistry(
        pipelines: [legacy],
        defaultPipelineId: DetectionPipelineIds.legacyNsfwRegionV8,
      );

      final decision = registry.resolveRollout(
        DetectionPipelineIds.vssFamilySafetyV1,
        config: const DetectionPipelineRolloutConfig(
          state: DetectionPipelineRolloutState.shadow,
        ),
      );

      expect(
          decision.activePipelineId, DetectionPipelineIds.legacyNsfwRegionV8);
      expect(decision.shadowPipelineId, isNull);
      expect(
        decision.warnings,
        contains('shadow pipeline vss_family_safety_v1 is not runnable'),
      );
    });

    test('preserves existing checkpoint pipeline in default rollout', () {
      const legacy = _StubPipeline(DetectionPipelineProfile.legacyNsfwRegionV8);
      final registry = DetectionPipelineRegistry(
        pipelines: [legacy],
        defaultPipelineId: DetectionPipelineIds.legacyNsfwRegionV8,
      );

      final decision = registry.resolveRollout(
        DetectionPipelineIds.vssFamilySafetyV1,
        checkpoint: AnalysisCheckpoint(
          timestamp: DateTime.utc(2026),
          pipelineId: DetectionPipelineIds.legacyNsfwRegionV8,
        ),
        config: const DetectionPipelineRolloutConfig(
          state: DetectionPipelineRolloutState.defaultProfile,
        ),
      );

      expect(
          decision.activePipelineId, DetectionPipelineIds.legacyNsfwRegionV8);
      expect(decision.existingProjectCompatibilityPreserved, isTrue);
      expect(decision.checkpointCompatible, isTrue);
    });

    test('enforce selects VSS when an official VSS pipeline is registered', () {
      const legacy = _StubPipeline(DetectionPipelineProfile.legacyNsfwRegionV8);
      const vss = _StubPipeline(_implementedVssProfile);
      final registry = DetectionPipelineRegistry(pipelines: [legacy, vss]);

      final decision = registry.resolveRollout(
        DetectionPipelineIds.legacyNsfwRegionV8,
        config: const DetectionPipelineRolloutConfig(
          state: DetectionPipelineRolloutState.enforce,
        ),
      );

      expect(decision.activePipelineId, DetectionPipelineIds.vssFamilySafetyV1);
      expect(decision.usedFallback, isFalse);
    });

    test('default rollout selects VSS for new projects when VSS can run', () {
      const legacy = _StubPipeline(DetectionPipelineProfile.legacyNsfwRegionV8);
      const vss = _StubPipeline(_implementedVssProfile);
      final registry = DetectionPipelineRegistry(pipelines: [legacy, vss]);

      final decision = registry.resolveRollout(
        DetectionPipelineIds.vssFamilySafetyV1,
        config: const DetectionPipelineRolloutConfig(
          state: DetectionPipelineRolloutState.defaultProfile,
        ),
      );

      expect(decision.activePipelineId, DetectionPipelineIds.vssFamilySafetyV1);
      expect(decision.existingProjectCompatibilityPreserved, isFalse);
    });

    test('flags incompatible checkpoints while preserving legacy fallback', () {
      const legacy = _StubPipeline(DetectionPipelineProfile.legacyNsfwRegionV8);
      final registry = DetectionPipelineRegistry(
        pipelines: [legacy],
        defaultPipelineId: DetectionPipelineIds.legacyNsfwRegionV8,
      );

      final decision = registry.resolveRollout(
        DetectionPipelineIds.vssFamilySafetyV1,
        checkpoint: AnalysisCheckpoint(
          timestamp: DateTime.utc(2026),
          pipelineId: DetectionPipelineIds.legacyNsfwRegionV8,
          pipelineVersion: 1,
        ),
        config: const DetectionPipelineRolloutConfig(
          state: DetectionPipelineRolloutState.defaultProfile,
        ),
      );

      expect(
          decision.activePipelineId, DetectionPipelineIds.legacyNsfwRegionV8);
      expect(decision.checkpointCompatible, isFalse);
      expect(
        decision.warnings,
        contains(
            'checkpoint pipeline version is not compatible with this build'),
      );
    });
  });
}

const _implementedVssProfile = DetectionPipelineProfile(
  id: DetectionPipelineIds.vssFamilySafetyV1,
  displayName: 'VSS Family Safety',
  description: 'Runnable VSS test pipeline.',
  isDefaultForNewProjects: true,
  isImplemented: true,
  isLegacy: false,
  fallbackPipelineId: DetectionPipelineIds.legacyNsfwRegionV8,
);

class _StubPipeline implements DetectionPipeline {
  const _StubPipeline(this.profile);

  @override
  final DetectionPipelineProfile profile;

  @override
  Stream<AnalysisProgress> analyze(DetectionPipelineRequest request) =>
      Stream.value(
        const AnalysisProgress(
          stepName: 'complete',
          currentStep: 1,
          totalSteps: 1,
          stepProgress: 1,
        ),
      );
}
