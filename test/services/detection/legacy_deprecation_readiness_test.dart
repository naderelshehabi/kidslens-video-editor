import 'package:flutter_test/flutter_test.dart';
import 'package:kidslens_video_editor/data/models/models.dart';
import 'package:kidslens_video_editor/services/detection/detection_pipeline_profile.dart';
import 'package:kidslens_video_editor/services/detection/grounding_provider.dart';
import 'package:kidslens_video_editor/services/detection/legacy_deprecation_readiness.dart';
import 'package:kidslens_video_editor/services/detection/policy_engine.dart';

void main() {
  group('LegacyDeprecationReadinessChecker', () {
    test('confirms auxiliary legacy providers while blocking early deprecation',
        () {
      const checker = LegacyDeprecationReadinessChecker();
      final criteria = checker.buildCriteria(
        profiles: DetectionPipelineProfile.builtInProfiles,
        groundingProviders: const [
          LegacyNudenetGroundingProvider(),
          ModestyParserGroundingProvider(),
        ],
        defaultPolicyOptions: const PolicyEngineOptions.vssDefault(),
        defaultBeatsLegacyOnEvaluation: true,
        oldAnalysisResultsReadable: true,
        exportRemediationCompatible: true,
        stabilityWindowSatisfied: false,
      );

      final report = checker.evaluate(criteria: criteria);

      expect(criteria.legacyNsfwAvailableAsAuxiliaryEvidence, isTrue);
      expect(criteria.nudenetAvailableAsAuxiliaryGrounding, isTrue);
      expect(criteria.modestyParserAvailableAsAuxiliaryGrounding, isTrue);
      expect(criteria.defaultProfileUsesAuxiliaryOnlyLegacyEvidence, isTrue);
      expect(report.canDeprecateLegacyDirectDetection, isFalse);
      expect(
        report.issues,
        contains(
          'legacy direct detection needs the measured stability window before deprecation',
        ),
      );
    });

    test('allows deprecation only after every criterion passes', () {
      const checker = LegacyDeprecationReadinessChecker();

      final report = checker.evaluate(
        criteria: const LegacyDeprecationCriteria(
          stabilityWindowSatisfied: true,
          defaultBeatsLegacyOnEvaluation: true,
          oldAnalysisResultsReadable: true,
          exportRemediationCompatible: true,
          legacyNsfwAvailableAsAuxiliaryEvidence: true,
          nudenetAvailableAsAuxiliaryGrounding: true,
          modestyParserAvailableAsAuxiliaryGrounding: true,
          defaultProfileUsesAuxiliaryOnlyLegacyEvidence: true,
        ),
      );

      expect(report.canDeprecateLegacyDirectDetection, isTrue);
      expect(report.issues, isEmpty);
      expect(
        report.toJson(),
        containsPair('canDeprecateLegacyDirectDetection', true),
      );
    });

    test('checks policy findings for export and remediation compatibility', () {
      final compatible = PolicyFinding(
        id: 'finding_1',
        mediaId: 'media_1',
        category: FamilySafetyPolicyCategory.explicitNudity,
        severity: FamilySafetySeverity.high,
        confidence: 0.9,
        startTime: Duration.zero,
        endTime: const Duration(seconds: 2),
        recommendedAction: RemediationAction.blurRegion,
        needsReview: false,
        rationale: 'Grounded unsafe region.',
        supportingEvidenceIds: const ['evidence_1'],
        sourceModels: const ['qwen3.5-vl-local'],
        origins: const [PolicyFindingOrigin.groundedRegion],
        groundingStatus: 'grounded',
        regionIds: const ['region_1'],
      );

      expect(
        policyFindingsAreExportRemediationCompatible([compatible]),
        isTrue,
      );
    });
  });
}
