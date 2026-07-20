import 'package:flutter_test/flutter_test.dart';
import 'package:kidslens_video_editor/services/detection/evaluation_dataset.dart';
import 'package:kidslens_video_editor/services/detection/evaluation_runner.dart';

void main() {
  group('EvaluationRunner', () {
    test('calculates core metrics for matched and missed detections', () {
      final dataset = _dataset();
      final result = const EvaluationRunner().evaluateProfile(
        dataset: dataset,
        predictions: EvaluationProfilePredictions.forBuiltInProfile(
          profile: EvaluationProfileId.vlmPlusGrounding,
          detectionsByClipId: {
            'safe': [_prediction('safe_fp', 'violence', 1, 2)],
            'unsafe': [
              _prediction(
                'match',
                'blood',
                1,
                5,
                box: const EvaluationBox(
                  x: 0.12,
                  y: 0.12,
                  width: 0.28,
                  height: 0.28,
                ),
                maskIouHint: 0.8,
              ),
            ],
          },
          chunkLatencyMs: const [10, 20, 30, 100],
          memoryUsageMb: const [500, 650],
          vramUsageMb: const [3000, 3400],
        ),
      );

      expect(result.overall.truePositiveCount, 1);
      expect(result.overall.falsePositiveCount, 1);
      expect(result.overall.falseNegativeCount, 0);
      expect(result.overall.recall, 1);
      expect(result.overall.precision, 0.5);
      expect(result.overall.falsePositiveRate, 1);
      expect(result.overall.temporalIou, 1);
      expect(result.overall.boxIou, greaterThan(0.7));
      expect(result.overall.maskIou, 0.8);
      expect(result.overall.chunkLatencyP50Ms, 30);
      expect(result.overall.chunkLatencyP95Ms, 100);
      expect(result.overall.peakMemoryMb, 650);
      expect(result.overall.peakVramMb, 3400);
      expect(result.byCategory['blood']!.recall, 1);
    });

    test('compares required profiles and passes exit gate when default wins',
        () {
      final dataset = _dataset();
      final predictions = [
        EvaluationProfilePredictions.forBuiltInProfile(
          profile: EvaluationProfileId.legacyOnly,
          detectionsByClipId: const {},
        ),
        EvaluationProfilePredictions.forBuiltInProfile(
          profile: EvaluationProfileId.vlmOnly,
          detectionsByClipId: {
            'unsafe': [_prediction('vlm', 'blood', 1, 5)],
          },
        ),
        EvaluationProfilePredictions.forBuiltInProfile(
          profile: EvaluationProfileId.vlmPlusLegacyEvidence,
          detectionsByClipId: {
            'unsafe': [_prediction('vlm_legacy', 'blood', 1, 5)],
          },
        ),
        EvaluationProfilePredictions.forBuiltInProfile(
          profile: EvaluationProfileId.vlmPlusGrounding,
          detectionsByClipId: {
            'unsafe': [_prediction('default', 'blood', 1, 5)],
          },
        ),
      ];

      final report = const EvaluationRunner().compare(
        dataset: dataset,
        profilePredictions: predictions,
        thresholds: const EvaluationThresholds(
          minDefaultRecallLift: 0.1,
          maxDefaultFalsePositiveRate: 0,
          maxDefaultReviewBurdenPerHour: 1000,
          minExplicitNudityRecall: 0,
          minGoreBloodRecall: 0.9,
          minViolenceRecall: 0,
        ),
      );

      expect(report.results, hasLength(4));
      expect(report.exitGate.passed, isTrue);
      expect(report.toJson()['datasetId'], 'unit_dataset');
    });

    test('fails exit gate when default recall does not beat legacy', () {
      final dataset = _dataset();
      final report = const EvaluationRunner().compare(
        dataset: dataset,
        profilePredictions: [
          EvaluationProfilePredictions.forBuiltInProfile(
            profile: EvaluationProfileId.legacyOnly,
            detectionsByClipId: {
              'unsafe': [_prediction('legacy', 'blood', 1, 5)],
            },
          ),
          EvaluationProfilePredictions.forBuiltInProfile(
            profile: EvaluationProfileId.vlmPlusGrounding,
            detectionsByClipId: const {},
          ),
        ],
        thresholds: const EvaluationThresholds(
          minGoreBloodRecall: 0.9,
        ),
      );

      expect(report.exitGate.passed, isFalse);
      expect(
        report.exitGate.issues,
        contains('default recall does not beat legacy recall'),
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
              id: 'truth',
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
  String id,
  String categoryId,
  int startSeconds,
  int endSeconds, {
  EvaluationBox? box,
  double? maskIouHint,
}) =>
    EvaluationAnnotation(
      id: id,
      categoryId: categoryId,
      startTime: Duration(seconds: startSeconds),
      endTime: Duration(seconds: endSeconds),
      severity: 'high',
      confidence: 0.9,
      requiresReview: true,
      rationale: 'Detected $categoryId.',
      box: box,
      maskIouHint: maskIouHint,
    );
