import 'package:kidslens_video_editor/data/models/models.dart';
import 'package:kidslens_video_editor/services/detection/detection_pipeline.dart';
import 'package:kidslens_video_editor/services/detection/detection_pipeline_profile.dart';
import 'package:kidslens_video_editor/services/detection/detection_pipeline_rollout.dart';

/// Registry and resolver for available detection pipelines.
class DetectionPipelineRegistry {
  DetectionPipelineRegistry({
    required Iterable<DetectionPipeline> pipelines,
    this.defaultPipelineId = DetectionPipelineIds.vssFamilySafetyV1,
  }) : _pipelines = {
          for (final pipeline in pipelines) pipeline.profile.id: pipeline,
        } {
    if (!_pipelines.containsKey(defaultPipelineId)) {
      throw ArgumentError.value(
        defaultPipelineId,
        'defaultPipelineId',
        'Default pipeline must be registered',
      );
    }
  }

  final Map<String, DetectionPipeline> _pipelines;
  final String defaultPipelineId;

  Iterable<DetectionPipelineProfile> get availableProfiles =>
      DetectionPipelineProfile.builtInProfiles;

  Iterable<String> get registeredPipelineIds => _pipelines.keys;

  bool isRegistered(String pipelineId) => _pipelines.containsKey(pipelineId);

  bool canRun(String pipelineId) {
    final pipeline = _pipelines[pipelineId];
    return pipeline != null && pipeline.profile.canRun;
  }

  DetectionPipelineProfile? profileFor(String pipelineId) {
    for (final profile in DetectionPipelineProfile.builtInProfiles) {
      if (profile.id == pipelineId) return profile;
    }
    return _pipelines[pipelineId]?.profile;
  }

  DetectionPipeline resolve(String? pipelineId) {
    final trimmedPipelineId = pipelineId?.trim();
    final requestedId =
        trimmedPipelineId?.isNotEmpty ?? false ? trimmedPipelineId : null;
    final resolved = _resolveRequested(requestedId) ??
        _resolveFallback(requestedId) ??
        _pipelines[defaultPipelineId];

    if (resolved == null) {
      throw StateError('No detection pipeline is available');
    }
    return resolved;
  }

  DetectionPipelineRolloutDecision resolveRollout(
    String? pipelineId, {
    AnalysisCheckpoint? checkpoint,
    DetectionPipelineRolloutConfig config =
        const DetectionPipelineRolloutConfig(),
  }) {
    final requestedId = _normalizePipelineId(pipelineId);
    final checkpointPipelineId = _normalizePipelineId(checkpoint?.pipelineId);
    final checkpointCompatible = _isCheckpointCompatible(checkpoint);
    final warnings = <String>[
      if (!checkpointCompatible)
        'checkpoint pipeline version is not compatible with this build',
    ];

    String fallbackLegacy(String reason) {
      final legacy = _resolveRunnablePipelineId(config.legacyPipelineId) ??
          _resolveRunnablePipelineId(defaultPipelineId);
      if (legacy == null) {
        throw StateError('No legacy fallback pipeline is available');
      }
      warnings.add(reason);
      return legacy;
    }

    String resolveCandidateOrLegacy(String? candidateId, String reason) {
      final resolved = _resolveRunnablePipelineId(candidateId);
      if (resolved != null) {
        if (candidateId != null && resolved != candidateId) {
          warnings.add(reason);
        }
        return resolved;
      }
      if (!config.allowLegacyFallback) {
        throw StateError('Pipeline $candidateId is not runnable');
      }
      return fallbackLegacy(reason);
    }

    String activePipelineId;
    String? shadowPipelineId;
    var usedFallback = false;
    var existingProjectCompatibilityPreserved = false;
    String rationale;

    switch (config.state) {
      case DetectionPipelineRolloutState.off:
        activePipelineId = fallbackLegacy('rollout is disabled');
        usedFallback = activePipelineId != config.legacyPipelineId;
        rationale = 'Rollout is off, so legacy detection remains active.';
      case DetectionPipelineRolloutState.shadow:
        activePipelineId = fallbackLegacy('shadow mode keeps legacy active');
        final shadowPipeline = _resolveRequested(config.shadowPipelineId);
        shadowPipelineId = shadowPipeline?.profile.id;
        if (shadowPipeline == null) {
          warnings.add(
            'shadow pipeline ${config.shadowPipelineId} is not runnable',
          );
        }
        usedFallback = activePipelineId != config.legacyPipelineId;
        rationale =
            'Shadow mode keeps legacy output active while evaluating VSS.';
      case DetectionPipelineRolloutState.preview:
        final candidateId = requestedId ?? config.defaultPipelineId;
        activePipelineId = resolveCandidateOrLegacy(
          candidateId,
          'preview pipeline $candidateId is not runnable',
        );
        usedFallback = activePipelineId != candidateId;
        rationale =
            'Preview mode uses the requested preview pipeline when runnable.';
      case DetectionPipelineRolloutState.defaultProfile:
        if (config.preserveExistingProjectPipeline &&
            checkpointPipelineId != null) {
          activePipelineId = resolveCandidateOrLegacy(
            checkpointPipelineId,
            'checkpoint pipeline $checkpointPipelineId is not runnable',
          );
          existingProjectCompatibilityPreserved = true;
          usedFallback = activePipelineId != checkpointPipelineId;
          rationale =
              'Existing checkpoint pipeline is preserved for compatibility.';
        } else {
          final newProjectPipelineId = requestedId ?? config.defaultPipelineId;
          activePipelineId = resolveCandidateOrLegacy(
            newProjectPipelineId,
            'default pipeline $newProjectPipelineId is not runnable',
          );
          usedFallback = activePipelineId != newProjectPipelineId;
          rationale =
              'New analysis defaults to the configured VSS family-safety pipeline.';
        }
      case DetectionPipelineRolloutState.enforce:
        activePipelineId = resolveCandidateOrLegacy(
          config.defaultPipelineId,
          'enforced pipeline ${config.defaultPipelineId} is not runnable',
        );
        usedFallback = activePipelineId != config.defaultPipelineId;
        rationale =
            'Enforce mode selects the configured VSS family-safety pipeline.';
    }

    return DetectionPipelineRolloutDecision(
      state: config.state,
      activePipelineId: activePipelineId,
      requestedPipelineId: requestedId,
      defaultPipelineId: config.defaultPipelineId,
      legacyPipelineId: config.legacyPipelineId,
      shadowPipelineId: shadowPipelineId,
      checkpointPipelineId: checkpointPipelineId,
      rationale: rationale,
      usedFallback: usedFallback || warnings.isNotEmpty,
      checkpointCompatible: checkpointCompatible,
      existingProjectCompatibilityPreserved:
          existingProjectCompatibilityPreserved,
      warnings: warnings.toSet().toList(growable: false),
    );
  }

  DetectionPipeline? _resolveRequested(String? pipelineId) {
    if (pipelineId == null) return null;
    final pipeline = _pipelines[pipelineId];
    if (pipeline == null || !pipeline.profile.canRun) return null;
    return pipeline;
  }

  String? _resolveRunnablePipelineId(String? pipelineId) {
    final pipeline =
        _resolveRequested(pipelineId) ?? _resolveFallback(pipelineId);
    return pipeline?.profile.id;
  }

  DetectionPipeline? _resolveFallback(String? pipelineId) {
    if (pipelineId == null) return null;
    DetectionPipelineProfile? profile;
    for (final candidate in DetectionPipelineProfile.builtInProfiles) {
      if (candidate.id == pipelineId) {
        profile = candidate;
        break;
      }
    }
    final fallbackPipelineId = profile?.fallbackPipelineId;
    if (fallbackPipelineId == null) return null;

    final fallback = _pipelines[fallbackPipelineId];
    if (fallback == null || !fallback.profile.canRun) return null;
    return fallback;
  }

  String? _normalizePipelineId(String? pipelineId) {
    final trimmed = pipelineId?.trim();
    if (trimmed == null || trimmed.isEmpty) return null;
    return trimmed;
  }

  bool _isCheckpointCompatible(AnalysisCheckpoint? checkpoint) {
    if (checkpoint == null) return true;
    return checkpoint.pipelineVersion ==
        AnalysisCheckpoint.defaultPipelineVersion;
  }
}
