import 'package:kidslens_video_editor/data/models/models.dart';
import 'package:kidslens_video_editor/services/detection/detection_pipeline_profile.dart';
import 'package:kidslens_video_editor/services/detection/grounding_provider.dart';
import 'package:kidslens_video_editor/services/detection/policy_engine.dart';

class LegacyDeprecationCriteria {
  const LegacyDeprecationCriteria({
    required this.stabilityWindowSatisfied,
    required this.defaultBeatsLegacyOnEvaluation,
    required this.oldAnalysisResultsReadable,
    required this.exportRemediationCompatible,
    required this.legacyNsfwAvailableAsAuxiliaryEvidence,
    required this.nudenetAvailableAsAuxiliaryGrounding,
    required this.modestyParserAvailableAsAuxiliaryGrounding,
    required this.defaultProfileUsesAuxiliaryOnlyLegacyEvidence,
    this.stabilityWindowDays = 30,
  });

  final bool stabilityWindowSatisfied;
  final bool defaultBeatsLegacyOnEvaluation;
  final bool oldAnalysisResultsReadable;
  final bool exportRemediationCompatible;
  final bool legacyNsfwAvailableAsAuxiliaryEvidence;
  final bool nudenetAvailableAsAuxiliaryGrounding;
  final bool modestyParserAvailableAsAuxiliaryGrounding;
  final bool defaultProfileUsesAuxiliaryOnlyLegacyEvidence;
  final int stabilityWindowDays;
}

class LegacyDeprecationReadinessReport {
  const LegacyDeprecationReadinessReport({
    required this.criteria,
    required this.canDeprecateLegacyDirectDetection,
    required this.issues,
    required this.confirmations,
  });

  final LegacyDeprecationCriteria criteria;
  final bool canDeprecateLegacyDirectDetection;
  final List<String> issues;
  final List<String> confirmations;

  Map<String, dynamic> toJson() => {
        'canDeprecateLegacyDirectDetection': canDeprecateLegacyDirectDetection,
        'stabilityWindowDays': criteria.stabilityWindowDays,
        'issues': issues,
        'confirmations': confirmations,
      };
}

class LegacyDeprecationReadinessChecker {
  const LegacyDeprecationReadinessChecker();

  LegacyDeprecationReadinessReport evaluate({
    required LegacyDeprecationCriteria criteria,
  }) {
    final issues = <String>[];
    final confirmations = <String>[];

    void check({
      required bool condition,
      required String confirmation,
      required String issue,
    }) {
      if (condition) {
        confirmations.add(confirmation);
      } else {
        issues.add(issue);
      }
    }

    check(
      condition: criteria.legacyNsfwAvailableAsAuxiliaryEvidence,
      confirmation: 'legacy NSFW classifier is retained as auxiliary evidence',
      issue:
          'legacy NSFW classifier must remain available as auxiliary evidence',
    );
    check(
      condition: criteria.nudenetAvailableAsAuxiliaryGrounding,
      confirmation: 'NudeNet is retained as auxiliary grounding',
      issue: 'NudeNet must remain available as auxiliary grounding',
    );
    check(
      condition: criteria.modestyParserAvailableAsAuxiliaryGrounding,
      confirmation: 'modesty parser is retained as auxiliary grounding',
      issue: 'modesty parser must remain available as auxiliary grounding',
    );
    check(
      condition: criteria.defaultProfileUsesAuxiliaryOnlyLegacyEvidence,
      confirmation:
          'default profile does not promote legacy-only evidence directly',
      issue: 'default profile must use auxiliary-only legacy evidence policy',
    );
    check(
      condition: criteria.oldAnalysisResultsReadable,
      confirmation: 'old analysis results remain readable',
      issue: 'old analysis results must remain readable',
    );
    check(
      condition: criteria.exportRemediationCompatible,
      confirmation: 'export and remediation behavior remains compatible',
      issue: 'export and remediation behavior must remain compatible',
    );
    check(
      condition: criteria.defaultBeatsLegacyOnEvaluation,
      confirmation: 'default profile beats legacy on evaluation gates',
      issue: 'default profile must beat legacy on evaluation gates',
    );
    check(
      condition: criteria.stabilityWindowSatisfied,
      confirmation: 'measured stability window is satisfied',
      issue:
          'legacy direct detection needs the measured stability window before deprecation',
    );

    return LegacyDeprecationReadinessReport(
      criteria: criteria,
      canDeprecateLegacyDirectDetection: issues.isEmpty,
      issues: issues,
      confirmations: confirmations,
    );
  }

  LegacyDeprecationCriteria buildCriteria({
    required Iterable<DetectionPipelineProfile> profiles,
    required Iterable<GroundingProvider> groundingProviders,
    required PolicyEngineOptions defaultPolicyOptions,
    required bool defaultBeatsLegacyOnEvaluation,
    required bool oldAnalysisResultsReadable,
    required bool exportRemediationCompatible,
    required bool stabilityWindowSatisfied,
    int stabilityWindowDays = 30,
  }) {
    final providerSourceKinds =
        groundingProviders.map((provider) => provider.sourceKind).toSet();
    return LegacyDeprecationCriteria(
      stabilityWindowSatisfied: stabilityWindowSatisfied,
      defaultBeatsLegacyOnEvaluation: defaultBeatsLegacyOnEvaluation,
      oldAnalysisResultsReadable: oldAnalysisResultsReadable,
      exportRemediationCompatible: exportRemediationCompatible,
      legacyNsfwAvailableAsAuxiliaryEvidence: profiles.any(
        (profile) =>
            profile.id == DetectionPipelineIds.legacyNsfwRegionV8 &&
            profile.canRun &&
            profile.isLegacy,
      ),
      nudenetAvailableAsAuxiliaryGrounding:
          providerSourceKinds.contains(GroundingSourceKind.legacyNudenet),
      modestyParserAvailableAsAuxiliaryGrounding:
          providerSourceKinds.contains(GroundingSourceKind.modestyParser),
      defaultProfileUsesAuxiliaryOnlyLegacyEvidence:
          !defaultPolicyOptions.promotesLegacyEvidence,
      stabilityWindowDays: stabilityWindowDays,
    );
  }
}

bool policyFindingsAreExportRemediationCompatible(
  Iterable<PolicyFinding> findings,
) {
  for (final finding in findings) {
    if (finding.recommendedAction == RemediationAction.blurRegion &&
        finding.groundingStatus == 'grounded' &&
        finding.regionIds.isEmpty &&
        !finding.hasBoundary) {
      return false;
    }
    if (finding.startTime > finding.endTime) {
      return false;
    }
  }
  return true;
}
