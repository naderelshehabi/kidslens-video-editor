import 'package:flutter_test/flutter_test.dart';
import 'package:kidslens_video_editor/data/models/models.dart';

void main() {
  group('PolicyCategory', () {
    test('wraps family-safety catalog defaults', () {
      final explicit = PolicyCategory.fromPolicyCategory(
        FamilySafetyPolicyCategory.explicitNudity,
      );
      final immodest = PolicyCategory.fromPolicyCategory(
        FamilySafetyPolicyCategory.immodestFemaleClothing,
      );

      expect(explicit.id, 'explicit_nudity');
      expect(explicit.defaultAction, RemediationAction.blurRegion);
      expect(explicit.highRecallDefault, isTrue);
      expect(explicit.reviewFirst, isFalse);
      expect(immodest.reviewFirst, isTrue);
      expect(immodest.highRecallDefault, isFalse);
    });

    test('round trips to JSON', () {
      final category = PolicyCategory.fromPolicyCategory(
        FamilySafetyPolicyCategory.weapons,
      );

      expect(
        PolicyCategory.fromJson(category.toJson()).toJson(),
        category.toJson(),
      );
    });
  });

  group('PolicyFinding', () {
    test('generates deterministic IDs and round trips JSON', () {
      final finding = PolicyFinding(
        id: PolicyFinding.deterministicId(
          mediaId: 'media_policy',
          category: FamilySafetyPolicyCategory.blood,
          startTime: const Duration(seconds: 1),
          endTime: const Duration(seconds: 2),
          supportingEvidenceIds: const ['ev_b'],
          origins: const [PolicyFindingOrigin.vlm],
        ),
        mediaId: 'media_policy',
        category: FamilySafetyPolicyCategory.blood,
        severity: FamilySafetySeverity.high,
        confidence: 0.82,
        startTime: const Duration(seconds: 1),
        endTime: const Duration(seconds: 2),
        recommendedAction: RemediationAction.blurRegion,
        needsReview: false,
        rationale: 'Visible blood on the subject.',
        supportingEvidenceIds: const ['ev_b'],
        sourceModels: const ['nvidia-cosmos-reason1-7b'],
        origins: const [PolicyFindingOrigin.vlm],
        agreementState: PolicyAgreementState.bothAgreeUnsafe,
        groundingStatus: 'grounded',
        regionIds: const ['region_blood'],
        developerTracePayload: const {
          'providerId': 'local_vllm',
          'raw': {'category': 'blood'},
        },
      );

      final decoded = PolicyFinding.fromJson(finding.toJson());

      expect(decoded.toJson(), finding.toJson());
      expect(decoded.policyCategory.highRecallDefault, isTrue);
      expect(decoded.hasBoundary, isTrue);
    });
  });
}
