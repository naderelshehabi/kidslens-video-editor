import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:kidslens_video_editor/services/detection/evaluation_dataset.dart';
import 'package:kidslens_video_editor/services/detection/vss_validation_report.dart';

void main() {
  group('VssValidationReportBuilder', () {
    test('builds runtime and grounding validation report fields', () {
      final dataset = _dataset();
      final report = const VssValidationReportBuilder().build(
        dataset: dataset,
        datasetRoot: r'D:\validation',
        generatedAt: DateTime.utc(2026, 6, 16),
        profileRuns: [
          VssValidationProfileRun(
            predictions: EvaluationProfilePredictions.forBuiltInProfile(
              profile: EvaluationProfileId.legacyOnly,
              detectionsByClipId: const {},
            ),
          ),
          VssValidationProfileRun(
            predictions: EvaluationProfilePredictions.forBuiltInProfile(
              profile: EvaluationProfileId.vlmPlusGrounding,
              detectionsByClipId: {
                'unsafe': [
                  _prediction(
                    'box_match',
                    box: const EvaluationBox(
                      x: 0.12,
                      y: 0.12,
                      width: 0.28,
                      height: 0.28,
                    ),
                  ),
                ],
              },
              chunkLatencyMs: const [3000, 4000, 9000],
              memoryUsageMb: const [1200],
              vramUsageMb: const [7600, 8200],
            ),
            schemaFailureCount: 1,
            errors: const ['one repaired schema'],
          ),
          VssValidationProfileRun(
            predictions: EvaluationProfilePredictions.forBuiltInProfile(
              profile: EvaluationProfileId.vlmOnly,
              detectionsByClipId: {
                'unsafe': [
                  _prediction(
                    'box_miss',
                    box: const EvaluationBox(
                      x: 0.70,
                      y: 0.70,
                      width: 0.10,
                      height: 0.10,
                    ),
                  ),
                ],
              },
            ),
          ),
        ],
      );

      final json = report.toJson();
      final runtimeValidation =
          json['runtimeValidation'] as Map<String, dynamic>;
      final groundingComparison =
          json['groundingComparison'] as Map<String, dynamic>;
      final defaultRuntime =
          runtimeValidation['vlm_plus_grounding'] as Map<String, dynamic>;
      final defaultGrounding =
          groundingComparison['vlm_plus_grounding'] as Map<String, dynamic>;
      final vlmOnlyGrounding =
          groundingComparison['vlm_only'] as Map<String, dynamic>;
      final rtxGate = json['rtxValidationGate'] as Map<String, dynamic>;
      expect(json['generatedAt'], '2026-06-16T00:00:00.000Z');
      expect(defaultRuntime['peakVramMb'], 8200);
      expect(defaultRuntime['schemaFailureCount'], 1);
      expect(defaultGrounding['localizationRecall'], 1);
      expect(vlmOnlyGrounding['missedLocalizationIds'], ['unsafe:truth_box']);
      expect(rtxGate['passed'], isFalse);
      expect(jsonDecode(report.toPrettyJson()), isA<Map<String, dynamic>>());
    });

    test('parses prediction files with profile run counters', () {
      final predictions = VssValidationPredictionsFile.fromJson({
        'profiles': [
          {
            'profileId': 'vlm_plus_grounding',
            'displayName': 'VLM + grounding',
            'runtimeId': 'cuda_llamacpp',
            'schemaFailureCount': 2,
            'crashCount': 1,
            'errors': ['clip crash'],
            'chunkLatencyMs': [1, 2],
            'vramUsageMb': [3000],
            'detectionsByClipId': {
              'unsafe': [_prediction('parsed').toJson()],
            },
          },
        ],
      });

      expect(predictions.profileRuns, hasLength(1));
      expect(predictions.profileRuns.single.schemaFailureCount, 2);
      expect(predictions.profileRuns.single.crashCount, 1);
      expect(
        predictions.profileRuns.single.predictions.detectionsByClipId['unsafe'],
        hasLength(1),
      );
    });

    test('passes RTX gate when default profile meets production thresholds',
        () {
      final report = const VssValidationReportBuilder().build(
        dataset: _passingDataset(),
        datasetRoot: r'D:\validation',
        profileRuns: [
          VssValidationProfileRun(
            predictions: EvaluationProfilePredictions.forBuiltInProfile(
              profile: EvaluationProfileId.legacyOnly,
              detectionsByClipId: const {},
              chunkLatencyMs: const [1200],
              vramUsageMb: const [2048],
            ),
          ),
          VssValidationProfileRun(
            predictions: EvaluationProfilePredictions.forBuiltInProfile(
              profile: EvaluationProfileId.vlmPlusGrounding,
              detectionsByClipId: {
                'unsafe': [_passingPrediction()],
              },
              chunkLatencyMs: const [4200, 4800, 5100],
              vramUsageMb: const [8192, 9216],
            ),
          ),
        ],
      );

      expect(report.rtxValidationGate.passed, isTrue);
      expect(report.rtxValidationGate.issues, isEmpty);
      expect(
        report.toJson()['rtxValidationGate'],
        containsPair('defaultProfileId', 'vlm_plus_grounding'),
      );
    });

    test('fails RTX gate on runtime regressions', () {
      final report = const VssValidationReportBuilder().build(
        dataset: _passingDataset(),
        datasetRoot: r'D:\validation',
        profileRuns: [
          VssValidationProfileRun(
            predictions: EvaluationProfilePredictions.forBuiltInProfile(
              profile: EvaluationProfileId.legacyOnly,
              detectionsByClipId: const {},
              chunkLatencyMs: const [1200],
              vramUsageMb: const [2048],
            ),
          ),
          VssValidationProfileRun(
            predictions: EvaluationProfilePredictions.forBuiltInProfile(
              profile: EvaluationProfileId.vlmPlusGrounding,
              detectionsByClipId: {
                'unsafe': [_passingPrediction()],
              },
              chunkLatencyMs: const [4200, 9001],
              vramUsageMb: const [13000],
            ),
            schemaFailureCount: 1,
            crashCount: 1,
            errors: const ['clip crashed'],
          ),
        ],
      );

      expect(report.rtxValidationGate.passed, isFalse);
      expect(report.rtxValidationGate.issues, hasLength(5));
      expect(
        report.rtxValidationGate.issues,
        contains(contains('schema failure count')),
      );
      expect(
        report.rtxValidationGate.issues,
        contains(contains('crash count')),
      );
      expect(
        report.rtxValidationGate.issues,
        contains(contains('runtime errors reported')),
      );
      expect(
        report.rtxValidationGate.issues,
        contains(contains('peak VRAM 13000MB exceeds 12288MB')),
      );
      expect(
        report.rtxValidationGate.issues,
        contains(contains('p95 chunk latency 9001ms exceeds 8000ms')),
      );
    });
  });
}

EvaluationDataset _dataset() => const EvaluationDataset(
      id: 'unit_dataset',
      version: '1',
      clips: [
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
              id: 'truth_box',
              categoryId: 'blood',
              startTime: Duration(seconds: 1),
              endTime: Duration(seconds: 5),
              severity: 'high',
              rationale: 'Blood is visible.',
              box: EvaluationBox(x: 0.1, y: 0.1, width: 0.3, height: 0.3),
            ),
          ],
        ),
      ],
    );

EvaluationAnnotation _prediction(
  String id, {
  EvaluationBox? box,
}) =>
    EvaluationAnnotation(
      id: id,
      categoryId: 'blood',
      startTime: const Duration(seconds: 1),
      endTime: const Duration(seconds: 5),
      severity: 'high',
      confidence: 0.9,
      requiresReview: true,
      rationale: 'Detected blood.',
      box: box,
    );

EvaluationDataset _passingDataset() => const EvaluationDataset(
      id: 'passing_dataset',
      version: '1',
      clips: [
        EvaluationClip(
          id: 'safe',
          mediaId: 'safe',
          relativePath: 'safe.mp4',
          duration: Duration(minutes: 30),
          kinds: {EvaluationClipKind.safeControl},
          notes: 'Safe control.',
          groundTruth: [],
        ),
        EvaluationClip(
          id: 'unsafe',
          mediaId: 'unsafe',
          relativePath: 'unsafe.mp4',
          duration: Duration(minutes: 30),
          kinds: {EvaluationClipKind.categoryPositive},
          notes: 'Blood positive.',
          groundTruth: [
            EvaluationAnnotation(
              id: 'truth_blood',
              categoryId: 'blood',
              startTime: Duration(seconds: 1),
              endTime: Duration(seconds: 5),
              severity: 'high',
              rationale: 'Blood is visible.',
              box: EvaluationBox(x: 0.1, y: 0.1, width: 0.3, height: 0.3),
            ),
          ],
        ),
      ],
    );

EvaluationAnnotation _passingPrediction() => const EvaluationAnnotation(
      id: 'blood_match',
      categoryId: 'blood',
      startTime: Duration(seconds: 1),
      endTime: Duration(seconds: 5),
      severity: 'high',
      confidence: 0.9,
      requiresReview: true,
      rationale: 'Detected blood.',
      box: EvaluationBox(x: 0.1, y: 0.1, width: 0.3, height: 0.3),
    );
