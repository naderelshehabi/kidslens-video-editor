import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:kidslens_video_editor/services/detection/evaluation_dataset.dart';

void main() {
  group('EvaluationDataset', () {
    test('family safety smoke dataset covers every required fixture kind', () {
      const dataset = EvaluationDataset.familySafetyV1Smoke;

      expect(dataset.validate(), isEmpty);
      expect(dataset.isValid, isTrue);
      expect(
        dataset.clips.where((clip) => clip.isSafeControl),
        isNotEmpty,
      );
      expect(
        dataset.clips
            .expand((clip) => clip.groundTruth)
            .map((truth) => truth.categoryId),
        containsAll(const [
          'blood',
          'explicit_nudity',
          'gore',
          'violence',
          'weapons',
        ]),
      );
      expect(
        dataset.clips.any(
          (clip) => clip.groundTruth.any((truth) => truth.box != null),
        ),
        isTrue,
      );
    });

    test('serializes to JSON-compatible fixture manifest', () {
      final json = EvaluationDataset.familySafetyV1Smoke.toJson();

      expect(jsonDecode(jsonEncode(json)), isA<Map<String, dynamic>>());
      expect(json['id'], 'kidslens_family_safety_v1_smoke');
    });

    test('round-trips from JSON-compatible fixture manifest', () {
      final restored = EvaluationDataset.fromJson(
        jsonDecode(jsonEncode(EvaluationDataset.familySafetyV1Smoke.toJson()))
            as Map<String, dynamic>,
      );

      expect(restored.id, EvaluationDataset.familySafetyV1Smoke.id);
      expect(restored.version, EvaluationDataset.familySafetyV1Smoke.version);
      expect(
        restored.clips,
        hasLength(EvaluationDataset.familySafetyV1Smoke.clips.length),
      );
      expect(restored.validate(), isEmpty);
      expect(
        restored.clips
            .expand((clip) => clip.groundTruth)
            .where((truth) => truth.box != null),
        isNotEmpty,
      );
    });
  });

  group('EvaluationBox', () {
    test('computes normalized box IoU', () {
      const a = EvaluationBox(x: 0.1, y: 0.1, width: 0.4, height: 0.4);
      const b = EvaluationBox(x: 0.3, y: 0.3, width: 0.4, height: 0.4);

      expect(a.iou(b), closeTo(1 / 7, 0.0001));
    });

    test('rejects boxes outside normalized frame', () {
      const box = EvaluationBox(x: 0.8, y: 0.8, width: 0.4, height: 0.4);

      expect(
        box.validate(),
        contains('box must remain within normalized frame'),
      );
    });
  });

  group('EvaluationProfilePredictions', () {
    test('creates required comparison and runtime profiles', () {
      final profiles = EvaluationProfilePredictions.requiredComparisonProfiles(
        detectionsByProfile: const {},
        detectionsByRuntime: const {
          'cuda_vllm': {
            'clip_1': [
              EvaluationAnnotation(
                id: 'runtime_prediction',
                categoryId: 'blood',
                startTime: Duration(seconds: 1),
                endTime: Duration(seconds: 2),
                severity: 'high',
                rationale: 'Blood is visible.',
              ),
            ],
          },
        },
      );

      expect(
        profiles.map((profile) => profile.profileId),
        containsAll(const [
          'legacy_only',
          'vlm_only',
          'vlm_plus_legacy_evidence',
          'vlm_plus_grounding',
          'runtime_cuda_vllm',
        ]),
      );
      expect(
        profiles.last.detectionsByClipId['clip_1'],
        isA<List<EvaluationAnnotation>>(),
      );
    });
  });
}
