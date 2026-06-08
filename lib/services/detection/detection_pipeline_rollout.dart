import 'dart:convert';
import 'dart:io';

import 'package:kidslens_video_editor/services/detection/detection_pipeline_profile.dart';
import 'package:kidslens_video_editor/services/detection/evaluation_dataset.dart';
import 'package:kidslens_video_editor/services/detection/evaluation_runner.dart';

enum DetectionPipelineRolloutState {
  off('off'),
  shadow('shadow'),
  preview('preview'),
  defaultProfile('default'),
  enforce('enforce');

  const DetectionPipelineRolloutState(this.value);

  final String value;

  static DetectionPipelineRolloutState parse(String value) {
    final normalized = value.trim().toLowerCase();
    for (final state in values) {
      if (state.value == normalized || state.name == normalized) {
        return state;
      }
    }
    throw ArgumentError.value(value, 'value', 'Unknown rollout state');
  }
}

class DetectionPipelineRolloutConfig {
  const DetectionPipelineRolloutConfig({
    this.state = DetectionPipelineRolloutState.defaultProfile,
    this.defaultPipelineId = DetectionPipelineIds.vssFamilySafetyV1,
    this.legacyPipelineId = DetectionPipelineIds.legacyNsfwRegionV8,
    this.shadowPipelineId = DetectionPipelineIds.vssFamilySafetyV1,
    this.preserveExistingProjectPipeline = true,
    this.allowLegacyFallback = true,
  });

  final DetectionPipelineRolloutState state;
  final String defaultPipelineId;
  final String legacyPipelineId;
  final String shadowPipelineId;
  final bool preserveExistingProjectPipeline;
  final bool allowLegacyFallback;

  Map<String, dynamic> toJson() => {
        'state': state.value,
        'defaultPipelineId': defaultPipelineId,
        'legacyPipelineId': legacyPipelineId,
        'shadowPipelineId': shadowPipelineId,
        'preserveExistingProjectPipeline': preserveExistingProjectPipeline,
        'allowLegacyFallback': allowLegacyFallback,
      };
}

class DetectionPipelineRolloutDecision {
  const DetectionPipelineRolloutDecision({
    required this.state,
    required this.activePipelineId,
    required this.requestedPipelineId,
    required this.defaultPipelineId,
    required this.legacyPipelineId,
    required this.rationale,
    required this.checkpointCompatible,
    this.shadowPipelineId,
    this.checkpointPipelineId,
    this.usedFallback = false,
    this.existingProjectCompatibilityPreserved = false,
    this.warnings = const <String>[],
  });

  final DetectionPipelineRolloutState state;
  final String activePipelineId;
  final String? requestedPipelineId;
  final String defaultPipelineId;
  final String legacyPipelineId;
  final String? shadowPipelineId;
  final String? checkpointPipelineId;
  final String rationale;
  final bool usedFallback;
  final bool checkpointCompatible;
  final bool existingProjectCompatibilityPreserved;
  final List<String> warnings;

  bool get isShadowing => shadowPipelineId != null;

  Map<String, dynamic> toJson() => {
        'state': state.value,
        'activePipelineId': activePipelineId,
        'requestedPipelineId': requestedPipelineId,
        'defaultPipelineId': defaultPipelineId,
        'legacyPipelineId': legacyPipelineId,
        if (shadowPipelineId != null) 'shadowPipelineId': shadowPipelineId,
        if (checkpointPipelineId != null)
          'checkpointPipelineId': checkpointPipelineId,
        'rationale': rationale,
        'usedFallback': usedFallback,
        'checkpointCompatible': checkpointCompatible,
        'existingProjectCompatibilityPreserved':
            existingProjectCompatibilityPreserved,
        'warnings': warnings,
      };
}

enum DetectionPipelineFailureKind {
  pipelineCrash('pipeline_crash'),
  modelLoad('model_load'),
  schema('schema'),
  gpuFallback('gpu_fallback'),
  checkpointCompatibility('checkpoint_compatibility');

  const DetectionPipelineFailureKind(this.value);

  final String value;
}

class DetectionPipelineTelemetryEvent {
  const DetectionPipelineTelemetryEvent({
    required this.kind,
    required this.message,
    required this.timestamp,
    required this.activePipelineId,
    this.requestedPipelineId,
    this.fallbackPipelineId,
    this.rolloutState,
    this.details = const <String, dynamic>{},
  });

  factory DetectionPipelineTelemetryEvent.now({
    required DetectionPipelineFailureKind kind,
    required String message,
    required String activePipelineId,
    String? requestedPipelineId,
    String? fallbackPipelineId,
    DetectionPipelineRolloutState? rolloutState,
    Map<String, dynamic> details = const <String, dynamic>{},
  }) =>
      DetectionPipelineTelemetryEvent(
        kind: kind,
        message: message,
        timestamp: DateTime.now().toUtc(),
        activePipelineId: activePipelineId,
        requestedPipelineId: requestedPipelineId,
        fallbackPipelineId: fallbackPipelineId,
        rolloutState: rolloutState,
        details: details,
      );

  final DetectionPipelineFailureKind kind;
  final String message;
  final DateTime timestamp;
  final String activePipelineId;
  final String? requestedPipelineId;
  final String? fallbackPipelineId;
  final DetectionPipelineRolloutState? rolloutState;
  final Map<String, dynamic> details;

  Map<String, dynamic> toJson() => {
        'kind': kind.value,
        'message': message,
        'timestamp': timestamp.toIso8601String(),
        'activePipelineId': activePipelineId,
        if (requestedPipelineId != null)
          'requestedPipelineId': requestedPipelineId,
        if (fallbackPipelineId != null)
          'fallbackPipelineId': fallbackPipelineId,
        if (rolloutState != null) 'rolloutState': rolloutState!.value,
        if (details.isNotEmpty)
          'details': jsonDecode(jsonEncode(details)) as Map<String, dynamic>,
      };
}

abstract interface class DetectionPipelineTelemetryStore {
  Future<void> record(DetectionPipelineTelemetryEvent event);
}

class InMemoryDetectionPipelineTelemetryStore
    implements DetectionPipelineTelemetryStore {
  final List<DetectionPipelineTelemetryEvent> events =
      <DetectionPipelineTelemetryEvent>[];

  @override
  Future<void> record(DetectionPipelineTelemetryEvent event) async {
    events.add(event);
  }
}

class JsonlDetectionPipelineTelemetryStore
    implements DetectionPipelineTelemetryStore {
  const JsonlDetectionPipelineTelemetryStore(this.file);

  final File file;

  @override
  Future<void> record(DetectionPipelineTelemetryEvent event) async {
    await file.parent.create(recursive: true);
    await file.writeAsString(
      '${jsonEncode(event.toJson())}\n',
      mode: FileMode.append,
      flush: true,
    );
  }
}

class DetectionPipelineFailureResolution {
  const DetectionPipelineFailureResolution({
    required this.kind,
    required this.activePipelineId,
    required this.fallbackPipelineId,
    required this.userMessage,
    required this.canRetry,
    required this.telemetryEvent,
  });

  final DetectionPipelineFailureKind kind;
  final String activePipelineId;
  final String fallbackPipelineId;
  final String userMessage;
  final bool canRetry;
  final DetectionPipelineTelemetryEvent telemetryEvent;
}

class DetectionPipelineFailureHandler {
  const DetectionPipelineFailureHandler({
    this.legacyPipelineId = DetectionPipelineIds.legacyNsfwRegionV8,
  });

  final String legacyPipelineId;

  DetectionPipelineFailureResolution resolve({
    required DetectionPipelineFailureKind kind,
    required String activePipelineId,
    String? requestedPipelineId,
    DetectionPipelineRolloutState? rolloutState,
    Object? error,
    Map<String, dynamic> details = const <String, dynamic>{},
  }) {
    final message = _messageFor(kind);
    final mergedDetails = <String, dynamic>{
      ...details,
      if (error != null) 'error': error.toString(),
    };
    return DetectionPipelineFailureResolution(
      kind: kind,
      activePipelineId: activePipelineId,
      fallbackPipelineId: legacyPipelineId,
      userMessage: message,
      canRetry: kind != DetectionPipelineFailureKind.checkpointCompatibility,
      telemetryEvent: DetectionPipelineTelemetryEvent.now(
        kind: kind,
        message: message,
        activePipelineId: activePipelineId,
        requestedPipelineId: requestedPipelineId,
        fallbackPipelineId: legacyPipelineId,
        rolloutState: rolloutState,
        details: mergedDetails,
      ),
    );
  }

  DetectionPipelineFailureResolution modelLoadFailure({
    required String activePipelineId,
    String? requestedPipelineId,
    Object? error,
  }) =>
      resolve(
        kind: DetectionPipelineFailureKind.modelLoad,
        activePipelineId: activePipelineId,
        requestedPipelineId: requestedPipelineId,
        error: error,
      );

  DetectionPipelineFailureResolution schemaFailure({
    required String activePipelineId,
    String? requestedPipelineId,
    Object? error,
  }) =>
      resolve(
        kind: DetectionPipelineFailureKind.schema,
        activePipelineId: activePipelineId,
        requestedPipelineId: requestedPipelineId,
        error: error,
      );

  DetectionPipelineFailureResolution gpuFallback({
    required String activePipelineId,
    String? requestedPipelineId,
    Object? error,
  }) =>
      resolve(
        kind: DetectionPipelineFailureKind.gpuFallback,
        activePipelineId: activePipelineId,
        requestedPipelineId: requestedPipelineId,
        error: error,
      );

  DetectionPipelineFailureResolution checkpointCompatibility({
    required String activePipelineId,
    String? requestedPipelineId,
    Object? error,
  }) =>
      resolve(
        kind: DetectionPipelineFailureKind.checkpointCompatibility,
        activePipelineId: activePipelineId,
        requestedPipelineId: requestedPipelineId,
        error: error,
      );

  String _messageFor(DetectionPipelineFailureKind kind) {
    switch (kind) {
      case DetectionPipelineFailureKind.pipelineCrash:
        return 'Detection pipeline failed and legacy fallback is available.';
      case DetectionPipelineFailureKind.modelLoad:
        return 'Local model could not be loaded; legacy fallback is available.';
      case DetectionPipelineFailureKind.schema:
        return 'Model output schema validation failed; legacy fallback is available.';
      case DetectionPipelineFailureKind.gpuFallback:
        return 'GPU execution failed; CPU or legacy fallback is available.';
      case DetectionPipelineFailureKind.checkpointCompatibility:
        return 'Checkpoint is not compatible with the selected pipeline.';
    }
  }
}

abstract interface class DetectionPipelineRolloutReportStore {
  Future<StoredRolloutComparisonReport> storeComparisonReport(
    EvaluationComparisonReport report, {
    String? runId,
  });
}

class StoredRolloutComparisonReport {
  const StoredRolloutComparisonReport({
    required this.report,
    required this.uri,
  });

  final EvaluationComparisonReport report;
  final Uri uri;
}

class InMemoryDetectionPipelineRolloutReportStore
    implements DetectionPipelineRolloutReportStore {
  final List<StoredRolloutComparisonReport> reports =
      <StoredRolloutComparisonReport>[];

  @override
  Future<StoredRolloutComparisonReport> storeComparisonReport(
    EvaluationComparisonReport report, {
    String? runId,
  }) async {
    final stored = StoredRolloutComparisonReport(
      report: report,
      uri: runId == null
          ? Uri(scheme: 'memory', path: '/${reports.length + 1}')
          : Uri(path: runId),
    );
    reports.add(stored);
    return stored;
  }
}

class JsonDetectionPipelineRolloutReportStore
    implements DetectionPipelineRolloutReportStore {
  const JsonDetectionPipelineRolloutReportStore(this.directory);

  final Directory directory;

  @override
  Future<StoredRolloutComparisonReport> storeComparisonReport(
    EvaluationComparisonReport report, {
    String? runId,
  }) async {
    await directory.create(recursive: true);
    final safeRunId = _safeFilePart(
      runId ??
          '${report.datasetId}_${DateTime.now().toUtc().toIso8601String()}',
    );
    final file =
        File('${directory.path}${Platform.pathSeparator}$safeRunId.json');
    await file.writeAsString(report.toPrettyJson(), flush: true);
    return StoredRolloutComparisonReport(report: report, uri: file.uri);
  }
}

class DetectionPipelineShadowComparisonRunner {
  const DetectionPipelineShadowComparisonRunner({
    this.evaluationRunner = const EvaluationRunner(),
    this.thresholds = const EvaluationThresholds(),
  });

  final EvaluationRunner evaluationRunner;
  final EvaluationThresholds thresholds;

  EvaluationComparisonReport compareFixtures({
    required EvaluationDataset dataset,
    required EvaluationProfilePredictions legacyPredictions,
    required EvaluationProfilePredictions defaultPredictions,
    List<EvaluationProfilePredictions> additionalPredictions =
        const <EvaluationProfilePredictions>[],
  }) {
    return evaluationRunner.compare(
      dataset: dataset,
      profilePredictions: [
        legacyPredictions,
        ...additionalPredictions,
        defaultPredictions,
      ],
      legacyProfileId: legacyPredictions.profileId,
      defaultProfileId: defaultPredictions.profileId,
      thresholds: thresholds,
    );
  }

  Future<StoredRolloutComparisonReport> compareAndStoreFixtures({
    required EvaluationDataset dataset,
    required EvaluationProfilePredictions legacyPredictions,
    required EvaluationProfilePredictions defaultPredictions,
    required DetectionPipelineRolloutReportStore store,
    List<EvaluationProfilePredictions> additionalPredictions =
        const <EvaluationProfilePredictions>[],
    String? runId,
  }) {
    final report = compareFixtures(
      dataset: dataset,
      legacyPredictions: legacyPredictions,
      defaultPredictions: defaultPredictions,
      additionalPredictions: additionalPredictions,
    );
    return store.storeComparisonReport(report, runId: runId);
  }
}

String _safeFilePart(String value) {
  final buffer = StringBuffer();
  for (final codeUnit in value.codeUnits) {
    final char = String.fromCharCode(codeUnit);
    final isSafe = RegExp(r'[A-Za-z0-9._-]').hasMatch(char);
    buffer.write(isSafe ? char : '_');
  }
  final sanitized = buffer.toString();
  return sanitized.isEmpty ? 'rollout_report' : sanitized;
}
