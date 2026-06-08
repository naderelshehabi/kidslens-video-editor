import 'package:flutter_test/flutter_test.dart';
import 'package:kidslens_video_editor/data/models/models.dart';
import 'package:kidslens_video_editor/services/detection/temporal_fusion.dart';

void main() {
  group('TemporalFusion', () {
    test('merges fragmented adjacent same-category findings', () {
      final findings = [
        _finding(
          id: 'pf_1',
          category: FamilySafetyPolicyCategory.blood,
          start: const Duration(seconds: 1),
          end: const Duration(seconds: 2),
          confidence: 0.6,
          severity: FamilySafetySeverity.medium,
          evidenceIds: const ['ev_1'],
          sourceModels: const ['qwen3.5-vl-local'],
          rationale: 'Blood visible in frame one.',
        ),
        _finding(
          id: 'pf_2',
          category: FamilySafetyPolicyCategory.blood,
          start: const Duration(milliseconds: 2400),
          end: const Duration(seconds: 3),
          confidence: 0.7,
          evidenceIds: const ['ev_2'],
          sourceModels: const ['nvidia-cosmos-reason'],
          rationale: 'Blood remains visible.',
        ),
      ];

      final fused = const TemporalFusion().fuse(findings);

      expect(fused, hasLength(1));
      expect(fused.single.startTime, const Duration(seconds: 1));
      expect(fused.single.endTime, const Duration(seconds: 3));
      expect(fused.single.severity, FamilySafetySeverity.high);
      expect(fused.single.confidence, closeTo(0.88, 0.001));
      expect(fused.single.supportingEvidenceIds, containsAll(['ev_1', 'ev_2']));
      expect(
        fused.single.sourceModels,
        containsAll(['qwen3.5-vl-local', 'nvidia-cosmos-reason']),
      );
      expect(fused.single.rationales, hasLength(2));
    });

    test('smooths chunk overlap from multiple providers', () {
      final fused = const TemporalFusion().fuse([
        _finding(
          id: 'pf_vlm',
          category: FamilySafetyPolicyCategory.explicitNudity,
          start: Duration.zero,
          end: const Duration(seconds: 2),
          confidence: 0.82,
          agreementState: PolicyAgreementState.bothAgreeUnsafe,
        ),
        _finding(
          id: 'pf_legacy',
          category: FamilySafetyPolicyCategory.explicitNudity,
          start: const Duration(milliseconds: 1800),
          end: const Duration(seconds: 3),
          confidence: 0.76,
          origins: const [PolicyFindingOrigin.legacy],
          agreementState: PolicyAgreementState.bothAgreeUnsafe,
        ),
      ]);

      expect(fused, hasLength(1));
      expect(fused.single.startTime, Duration.zero);
      expect(fused.single.endTime, const Duration(seconds: 3));
      expect(
        fused.single.origins,
        containsAll([PolicyFindingOrigin.vlm, PolicyFindingOrigin.legacy]),
      );
      expect(
        fused.single.agreementStates,
        [PolicyAgreementState.bothAgreeUnsafe],
      );
    });

    test('preserves short critical unsafe flashes', () {
      final fused = const TemporalFusion().fuse([
        _finding(
          id: 'pf_flash',
          category: FamilySafetyPolicyCategory.gore,
          start: const Duration(seconds: 5),
          end: const Duration(milliseconds: 5100),
          confidence: 0.97,
          severity: FamilySafetySeverity.critical,
        ),
      ]);

      expect(fused, hasLength(1));
      expect(fused.single.duration, const Duration(milliseconds: 100));
      expect(fused.single.severity, FamilySafetySeverity.critical);
    });
  });

  group('PolicyDetectionBuilder', () {
    test('builds scene-level detections and UI-compatible timeline', () {
      final result = const PolicyDetectionBuilder().build(
        mediaId: _mediaId,
        mediaDuration: const Duration(seconds: 30),
        timelineId: 'timeline_policy',
        findings: [
          _finding(
            id: 'pf_scene',
            category: FamilySafetyPolicyCategory.violence,
            start: const Duration(seconds: 4),
            end: const Duration(seconds: 8),
            confidence: 0.74,
            needsReview: true,
            rationale: 'Scene-level violent action was detected.',
          ),
        ],
      );

      expect(result.detections, hasLength(1));
      final detection = result.detections.single;
      expect(detection.type, ContentType.nsfw);
      expect(detection.visualContentCategoryId, 'violence');
      expect(detection.hasBoundingBox, isFalse);
      expect(detection.metadata?['needsReview'], isTrue);
      expect(detection.metadata?['policySeverity'], 'high');
      expect(detection.metadata?['migrationContentType'], 'violence');
      expect(result.timeline.id, 'timeline_policy');
      expect(result.timeline.videoTrack?.segments, hasLength(1));
      expect(result.timeline.audioTrack?.segments, isEmpty);
    });

    test('builds region-level detections with bounding boxes', () {
      final result = const PolicyDetectionBuilder().build(
        mediaId: _mediaId,
        mediaDuration: const Duration(seconds: 30),
        findings: [
          _finding(
            id: 'pf_region',
            category: FamilySafetyPolicyCategory.immodestFemaleClothing,
            start: const Duration(seconds: 10),
            end: const Duration(seconds: 12),
            confidence: 0.68,
            groundingStatus: 'grounded',
            regionIds: const ['region_legs'],
            trace: const {
              'region': {
                'x': 0.25,
                'y': 0.45,
                'width': 0.2,
                'height': 0.35,
              },
            },
          ),
        ],
      );

      final detection = result.detections.single;
      expect(detection.hasBoundingBox, isTrue);
      expect(detection.boundingBox?['x'], 0.25);
      expect(
        detection.metadata?['boundingBoxes'],
        [
          {'x': 0.25, 'y': 0.45, 'width': 0.2, 'height': 0.35},
        ],
      );
      expect(detection.metadata?['regionIds'], ['region_legs']);
      expect(detection.suggestedAction, EditActionType.blur);
    });

    test('routes profanity findings to audio timeline segments', () {
      final result = const PolicyDetectionBuilder().build(
        mediaId: _mediaId,
        mediaDuration: const Duration(seconds: 30),
        findings: [
          _finding(
            id: 'pf_profanity',
            category: FamilySafetyPolicyCategory.profanity,
            start: const Duration(seconds: 15),
            end: const Duration(seconds: 16),
            confidence: 0.93,
            rationale: 'Profanity matched transcript terms.',
          ),
        ],
      );

      final detection = result.detections.single;
      expect(detection.type, ContentType.profanity);
      expect(detection.visualContentCategoryId, isNull);
      expect(detection.metadata?['policyCategoryId'], 'profanity');
      expect(detection.suggestedAction, EditActionType.beep);
      expect(result.timeline.audioTrack?.segments, hasLength(1));
      expect(result.timeline.videoTrack?.segments, isEmpty);
    });
  });
}

const _mediaId = 'media_temporal_fusion';

PolicyFinding _finding({
  required String id,
  required FamilySafetyPolicyCategory category,
  required Duration start,
  required Duration end,
  double confidence = 0.81,
  FamilySafetySeverity severity = FamilySafetySeverity.high,
  bool needsReview = false,
  String rationale = 'Policy finding rationale.',
  List<String> evidenceIds = const ['ev_policy'],
  List<String> sourceModels = const ['local_vlm'],
  List<PolicyFindingOrigin> origins = const [PolicyFindingOrigin.vlm],
  PolicyAgreementState agreementState = PolicyAgreementState.notCompared,
  String groundingStatus = 'scene_level_only',
  List<String> regionIds = const <String>[],
  Map<String, dynamic> trace = const <String, dynamic>{},
}) =>
    PolicyFinding(
      id: id,
      mediaId: _mediaId,
      category: category,
      severity: severity,
      confidence: confidence,
      startTime: start,
      endTime: end,
      recommendedAction:
          PolicyCategory.fromPolicyCategory(category).defaultAction,
      needsReview: needsReview,
      rationale: rationale,
      supportingEvidenceIds: evidenceIds,
      sourceModels: sourceModels,
      origins: origins,
      agreementState: agreementState,
      groundingStatus: groundingStatus,
      regionIds: regionIds,
      developerTracePayload: trace,
    );
