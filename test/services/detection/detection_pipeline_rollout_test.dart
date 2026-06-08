import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:kidslens_video_editor/services/detection/detection_pipeline_profile.dart';
import 'package:kidslens_video_editor/services/detection/detection_pipeline_rollout.dart';
import 'package:kidslens_video_editor/services/detection/evaluation_dataset.dart';

void main() {
  group('DetectionPipelineRolloutState', () {
    test('parses all persisted feature flag values', () {
      expect(
        DetectionPipelineRolloutState.parse('off'),
        DetectionPipelineRolloutState.off,
      );
      expect(
        DetectionPipelineRolloutState.parse('shadow'),
        DetectionPipelineRolloutState.shadow,
      );
      expect(
        DetectionPipelineRolloutState.parse('preview'),
        DetectionPipelineRolloutState.preview,
      );
      expect(
        DetectionPipelineRolloutState.parse('default'),
        DetectionPipelineRolloutState.defaultProfile,
      );
      expect(
        DetectionPipelineRolloutState.parse('enforce'),
        DetectionPipelineRolloutState.enforce,
      );
    });
  });

  group('DetectionPipelineFailureHandler', () {
    test(
        'creates local telemetry events for model, schema, gpu, and checkpoint failures',
        () {
      const handler = DetectionPipelineFailureHandler();

      final modelLoad = handler.modelLoadFailure(
        activePipelineId: DetectionPipelineIds.vssFamilySafetyV1,
        error: StateError('model load failed'),
      );
      final schema = handler.schemaFailure(
        activePipelineId: DetectionPipelineIds.vssFamilySafetyV1,
        error: FormatException('bad schema'),
      );
      final gpu = handler.gpuFallback(
        activePipelineId: DetectionPipelineIds.vssFamilySafetyV1,
        error: StateError('cuda unavailable'),
      );
      final checkpoint = handler.checkpointCompatibility(
        activePipelineId: DetectionPipelineIds.vssFamilySafetyV1,
        error: StateError('old checkpoint'),
      );

      expect(modelLoad.fallbackPipelineId,
          DetectionPipelineIds.legacyNsfwRegionV8);
      expect(schema.telemetryEvent.kind, DetectionPipelineFailureKind.schema);
      expect(gpu.telemetryEvent.kind, DetectionPipelineFailureKind.gpuFallback);
      expect(checkpoint.canRetry, isFalse);
      expect(
        modelLoad.telemetryEvent.toJson()['details'],
        containsPair('error', contains('model load failed')),
      );
    });

    test('stores local JSONL telemetry', () async {
      final directory =
          await Directory.systemTemp.createTemp('kidslens_rollout_');
      addTearDown(() async {
        if (directory.existsSync()) {
          await directory.delete(recursive: true);
        }
      });
      final file =
          File('${directory.path}${Platform.pathSeparator}events.jsonl');
      final store = JsonlDetectionPipelineTelemetryStore(file);

      await store.record(
        DetectionPipelineTelemetryEvent.now(
          kind: DetectionPipelineFailureKind.gpuFallback,
          message: 'GPU fallback',
          activePipelineId: DetectionPipelineIds.vssFamilySafetyV1,
          fallbackPipelineId: DetectionPipelineIds.legacyNsfwRegionV8,
        ),
      );

      final lines = await file.readAsLines();
      expect(lines, hasLength(1));
      expect(jsonDecode(lines.single)['kind'], 'gpu_fallback');
    });
  });

  group('DetectionPipelineShadowComparisonRunner', () {
    test('stores fixture comparison reports for legacy and default profiles',
        () async {
      final dataset = _dataset();
      final legacy = EvaluationProfilePredictions.forBuiltInProfile(
        profile: EvaluationProfileId.legacyOnly,
        detectionsByClipId: const {},
      );
      final vss = EvaluationProfilePredictions.forBuiltInProfile(
        profile: EvaluationProfileId.vlmPlusGrounding,
        detectionsByClipId: {
          'unsafe': [_annotation('vss', 'violence')],
        },
      );
      final store = InMemoryDetectionPipelineRolloutReportStore();

      final stored = await const DetectionPipelineShadowComparisonRunner()
          .compareAndStoreFixtures(
        dataset: dataset,
        legacyPredictions: legacy,
        defaultPredictions: vss,
        store: store,
        runId: 'unit-shadow',
      );

      expect(store.reports, hasLength(1));
      expect(stored.uri.path, 'unit-shadow');
      expect(stored.report.datasetId, 'rollout_dataset');
      expect(stored.report.legacyProfileId, 'legacy_only');
      expect(stored.report.defaultProfileId, 'vlm_plus_grounding');
    });

    test('persists comparison reports as local JSON files', () async {
      final directory =
          await Directory.systemTemp.createTemp('kidslens_reports_');
      addTearDown(() async {
        if (directory.existsSync()) {
          await directory.delete(recursive: true);
        }
      });
      final store = JsonDetectionPipelineRolloutReportStore(directory);
      final dataset = _dataset();

      final stored = await const DetectionPipelineShadowComparisonRunner()
          .compareAndStoreFixtures(
        dataset: dataset,
        legacyPredictions: EvaluationProfilePredictions.forBuiltInProfile(
          profile: EvaluationProfileId.legacyOnly,
          detectionsByClipId: const {},
        ),
        defaultPredictions: EvaluationProfilePredictions.forBuiltInProfile(
          profile: EvaluationProfileId.vlmPlusGrounding,
          detectionsByClipId: {
            'unsafe': [_annotation('vss', 'violence')],
          },
        ),
        store: store,
        runId: 'rollout/report:1',
      );

      final file = File.fromUri(stored.uri);
      expect(file.existsSync(), isTrue);
      expect(file.path, endsWith('rollout_report_1.json'));
      expect(jsonDecode(await file.readAsString())['datasetId'],
          'rollout_dataset');
    });
  });
}

EvaluationDataset _dataset() => EvaluationDataset(
      id: 'rollout_dataset',
      version: '1',
      clips: const [
        EvaluationClip(
          id: 'safe',
          mediaId: 'safe',
          relativePath: 'safe.mp4',
          duration: Duration(seconds: 10),
          kinds: {EvaluationClipKind.safeControl},
          notes: 'Safe control.',
          groundTruth: [],
        ),
        EvaluationClip(
          id: 'unsafe',
          mediaId: 'unsafe',
          relativePath: 'unsafe.mp4',
          duration: Duration(seconds: 10),
          kinds: {EvaluationClipKind.categoryPositive},
          notes: 'Unsafe positive.',
          groundTruth: [
            EvaluationAnnotation(
              id: 'truth',
              categoryId: 'violence',
              startTime: Duration(seconds: 1),
              endTime: Duration(seconds: 4),
              severity: 'high',
              rationale: 'Violence is visible.',
            ),
          ],
        ),
      ],
    );

EvaluationAnnotation _annotation(String id, String categoryId) =>
    EvaluationAnnotation(
      id: id,
      categoryId: categoryId,
      startTime: const Duration(seconds: 1),
      endTime: const Duration(seconds: 4),
      severity: 'high',
      confidence: 0.9,
      requiresReview: true,
      rationale: 'Detected $categoryId.',
    );
