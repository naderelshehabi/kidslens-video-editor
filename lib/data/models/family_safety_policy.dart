import 'package:kidslens_video_editor/data/models/content_category.dart';

/// V1 policy categories used by the local family-safety pipeline.
enum FamilySafetyPolicyCategory {
  explicitNudity,
  sexualContent,
  suggestiveContent,
  kissingRomance,
  immodestFemaleClothing,
  violence,
  gore,
  blood,
  weapons,
  substances,
  profanity,
}

extension FamilySafetyPolicyCategoryX on FamilySafetyPolicyCategory {
  String get id => switch (this) {
        FamilySafetyPolicyCategory.explicitNudity => 'explicit_nudity',
        FamilySafetyPolicyCategory.sexualContent => 'sexual_content',
        FamilySafetyPolicyCategory.suggestiveContent => 'suggestive_content',
        FamilySafetyPolicyCategory.kissingRomance => 'kissing_romance',
        FamilySafetyPolicyCategory.immodestFemaleClothing =>
          'immodest_female_clothing',
        FamilySafetyPolicyCategory.violence => 'violence',
        FamilySafetyPolicyCategory.gore => 'gore',
        FamilySafetyPolicyCategory.blood => 'blood',
        FamilySafetyPolicyCategory.weapons => 'weapons',
        FamilySafetyPolicyCategory.substances => 'substances',
        FamilySafetyPolicyCategory.profanity => 'profanity',
      };

  String get displayName => switch (this) {
        FamilySafetyPolicyCategory.explicitNudity => 'Explicit Nudity',
        FamilySafetyPolicyCategory.sexualContent => 'Sexual Content',
        FamilySafetyPolicyCategory.suggestiveContent => 'Suggestive Content',
        FamilySafetyPolicyCategory.kissingRomance => 'Kissing/Romance',
        FamilySafetyPolicyCategory.immodestFemaleClothing =>
          'Immodest Female Clothing',
        FamilySafetyPolicyCategory.violence => 'Violence',
        FamilySafetyPolicyCategory.gore => 'Gore',
        FamilySafetyPolicyCategory.blood => 'Blood',
        FamilySafetyPolicyCategory.weapons => 'Weapons',
        FamilySafetyPolicyCategory.substances => 'Substances',
        FamilySafetyPolicyCategory.profanity => 'Profanity',
      };
}

enum FamilySafetySeverity {
  none,
  low,
  medium,
  high,
  critical,
}

enum FamilySafetyEnforcementMode {
  reviewFirst,
  enforceWhenHighConfidence,
  alwaysManualReview,
}

enum BoundaryRequirement {
  regionWhenAvailable,
  objectWhenAvailable,
  sceneLevelAllowed,
}

enum InferenceTransport {
  inProcessNativeRuntime,
  localHelperProcess,
  localLoopbackServer,
}

enum ProhibitedModelSourceKind {
  communityPort,
  unofficialQuantization,
  hostedInferenceProvider,
  missingChecksum,
  missingLicenseMetadata,
}

enum ExplanationField {
  userFacingCategory,
  severity,
  confidence,
  shortRationale,
  timestampRange,
  regionOrSceneLevelStatus,
  sourceModelNames,
  supportingEvidenceIds,
}

class FamilySafetyPolicyDefinition {
  const FamilySafetyPolicyDefinition({
    required this.category,
    required this.defaultAction,
    required this.enforcementMode,
    required this.boundaryRequirement,
  });

  final FamilySafetyPolicyCategory category;
  final RemediationAction defaultAction;
  final FamilySafetyEnforcementMode enforcementMode;
  final BoundaryRequirement boundaryRequirement;
}

class FamilySafetyPolicyCatalog {
  FamilySafetyPolicyCatalog._();

  static const severityLevels = FamilySafetySeverity.values;

  static const requiredExplanationFields = <ExplanationField>[
    ExplanationField.userFacingCategory,
    ExplanationField.severity,
    ExplanationField.confidence,
    ExplanationField.shortRationale,
    ExplanationField.timestampRange,
    ExplanationField.regionOrSceneLevelStatus,
    ExplanationField.sourceModelNames,
    ExplanationField.supportingEvidenceIds,
  ];

  static const definitions = <FamilySafetyPolicyDefinition>[
    FamilySafetyPolicyDefinition(
      category: FamilySafetyPolicyCategory.explicitNudity,
      defaultAction: RemediationAction.blurRegion,
      enforcementMode: FamilySafetyEnforcementMode.enforceWhenHighConfidence,
      boundaryRequirement: BoundaryRequirement.regionWhenAvailable,
    ),
    FamilySafetyPolicyDefinition(
      category: FamilySafetyPolicyCategory.sexualContent,
      defaultAction: RemediationAction.cutScene,
      enforcementMode: FamilySafetyEnforcementMode.reviewFirst,
      boundaryRequirement: BoundaryRequirement.sceneLevelAllowed,
    ),
    FamilySafetyPolicyDefinition(
      category: FamilySafetyPolicyCategory.suggestiveContent,
      defaultAction: RemediationAction.cutScene,
      enforcementMode: FamilySafetyEnforcementMode.reviewFirst,
      boundaryRequirement: BoundaryRequirement.sceneLevelAllowed,
    ),
    FamilySafetyPolicyDefinition(
      category: FamilySafetyPolicyCategory.kissingRomance,
      defaultAction: RemediationAction.cutScene,
      enforcementMode: FamilySafetyEnforcementMode.reviewFirst,
      boundaryRequirement: BoundaryRequirement.sceneLevelAllowed,
    ),
    FamilySafetyPolicyDefinition(
      category: FamilySafetyPolicyCategory.immodestFemaleClothing,
      defaultAction: RemediationAction.blurRegion,
      enforcementMode: FamilySafetyEnforcementMode.reviewFirst,
      boundaryRequirement: BoundaryRequirement.regionWhenAvailable,
    ),
    FamilySafetyPolicyDefinition(
      category: FamilySafetyPolicyCategory.violence,
      defaultAction: RemediationAction.cutScene,
      enforcementMode: FamilySafetyEnforcementMode.reviewFirst,
      boundaryRequirement: BoundaryRequirement.sceneLevelAllowed,
    ),
    FamilySafetyPolicyDefinition(
      category: FamilySafetyPolicyCategory.gore,
      defaultAction: RemediationAction.blurRegion,
      enforcementMode: FamilySafetyEnforcementMode.enforceWhenHighConfidence,
      boundaryRequirement: BoundaryRequirement.regionWhenAvailable,
    ),
    FamilySafetyPolicyDefinition(
      category: FamilySafetyPolicyCategory.blood,
      defaultAction: RemediationAction.blurRegion,
      enforcementMode: FamilySafetyEnforcementMode.enforceWhenHighConfidence,
      boundaryRequirement: BoundaryRequirement.regionWhenAvailable,
    ),
    FamilySafetyPolicyDefinition(
      category: FamilySafetyPolicyCategory.weapons,
      defaultAction: RemediationAction.blurRegion,
      enforcementMode: FamilySafetyEnforcementMode.enforceWhenHighConfidence,
      boundaryRequirement: BoundaryRequirement.objectWhenAvailable,
    ),
    FamilySafetyPolicyDefinition(
      category: FamilySafetyPolicyCategory.substances,
      defaultAction: RemediationAction.cutScene,
      enforcementMode: FamilySafetyEnforcementMode.reviewFirst,
      boundaryRequirement: BoundaryRequirement.sceneLevelAllowed,
    ),
    FamilySafetyPolicyDefinition(
      category: FamilySafetyPolicyCategory.profanity,
      defaultAction: RemediationAction.beep,
      enforcementMode: FamilySafetyEnforcementMode.enforceWhenHighConfidence,
      boundaryRequirement: BoundaryRequirement.sceneLevelAllowed,
    ),
  ];

  static FamilySafetyPolicyDefinition byCategory(
    FamilySafetyPolicyCategory category,
  ) =>
      definitions.firstWhere((definition) => definition.category == category);
}

class LocalInferenceGovernance {
  LocalInferenceGovernance._();

  static const isLocalOnly = true;

  static const approvedTransports = <InferenceTransport>[
    InferenceTransport.inProcessNativeRuntime,
    InferenceTransport.localHelperProcess,
    InferenceTransport.localLoopbackServer,
  ];

  static bool isApprovedTransport(InferenceTransport transport) =>
      approvedTransports.contains(transport);

  static bool isApprovedLoopbackUri(Uri uri) {
    if (!uri.hasScheme) return false;
    if (uri.scheme != 'http' && uri.scheme != 'https') return false;
    return uri.host == 'localhost' || uri.host == '127.0.0.1';
  }
}

class ModelSourceGovernance {
  ModelSourceGovernance._();

  static const acceptedOfficialOrganizations = <String>{
    'nvidia',
    'Qwen',
    'google',
    'microsoft',
    'meta-llama',
    'mistralai',
  };

  static const prohibitedSourceKinds = <ProhibitedModelSourceKind>[
    ProhibitedModelSourceKind.communityPort,
    ProhibitedModelSourceKind.unofficialQuantization,
    ProhibitedModelSourceKind.hostedInferenceProvider,
    ProhibitedModelSourceKind.missingChecksum,
    ProhibitedModelSourceKind.missingLicenseMetadata,
  ];

  static bool isAcceptedOfficialOrganization(String organization) =>
      acceptedOfficialOrganizations.contains(organization);
}

class InternalConversionPolicy {
  const InternalConversionPolicy({
    required this.officialWeightsSource,
    required this.conversionRecipeId,
    required this.outputSha256,
    required this.publishedArtifactUri,
    required this.sourceRevision,
    required this.validatedOnRtx5070,
  });

  final String officialWeightsSource;
  final String conversionRecipeId;
  final String outputSha256;
  final String publishedArtifactUri;
  final String sourceRevision;
  final bool validatedOnRtx5070;

  List<String> validate() {
    final issues = <String>[];
    if (officialWeightsSource.trim().isEmpty) {
      issues.add('officialWeightsSource is required');
    }
    if (conversionRecipeId.trim().isEmpty) {
      issues.add('conversionRecipeId is required');
    }
    if (outputSha256.trim().isEmpty) {
      issues.add('outputSha256 is required');
    }
    if (publishedArtifactUri.trim().isEmpty) {
      issues.add('publishedArtifactUri is required');
    }
    if (sourceRevision.trim().isEmpty) {
      issues.add('sourceRevision is required');
    }
    if (!validatedOnRtx5070) {
      issues.add('RTX 5070 12 GB validation is required');
    }
    return issues;
  }

  bool get isValid => validate().isEmpty;
}
