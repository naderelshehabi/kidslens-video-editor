import 'dart:convert';

import 'package:crypto/crypto.dart';

import 'package:kidslens_video_editor/data/models/content_category.dart';
import 'package:kidslens_video_editor/data/models/family_safety_policy.dart';

enum PolicyFindingOrigin {
  vlm('vlm'),
  legacy('legacy'),
  transcript('transcript'),
  profanity('profanity'),
  groundedRegion('grounded_region'),
  providerFailure('provider_failure');

  const PolicyFindingOrigin(this.jsonValue);

  final String jsonValue;

  static PolicyFindingOrigin fromJson(String value) =>
      PolicyFindingOrigin.values.firstWhere(
        (origin) => origin.jsonValue == value,
        orElse: () => throw ArgumentError('Unknown finding origin: $value'),
      );
}

enum PolicyAgreementState {
  notCompared('not_compared'),
  vlmUnsafeLegacySafe('vlm_unsafe_legacy_safe'),
  legacyUnsafeVlmOmitted('legacy_unsafe_vlm_omitted'),
  bothAgreeUnsafe('both_agree_unsafe'),
  providerFailed('provider_failed');

  const PolicyAgreementState(this.jsonValue);

  final String jsonValue;

  static PolicyAgreementState fromJson(String value) =>
      PolicyAgreementState.values.firstWhere(
        (state) => state.jsonValue == value,
        orElse: () => throw ArgumentError('Unknown agreement state: $value'),
      );
}

class PolicyCategory {
  const PolicyCategory({
    required this.id,
    required this.displayName,
    required this.defaultAction,
    required this.enforcementMode,
    required this.boundaryRequirement,
    required this.reviewFirst,
    required this.highRecallDefault,
  });

  factory PolicyCategory.fromPolicyCategory(
    FamilySafetyPolicyCategory category,
  ) {
    final definition = FamilySafetyPolicyCatalog.byCategory(category);
    return PolicyCategory(
      id: category.id,
      displayName: category.displayName,
      defaultAction: definition.defaultAction,
      enforcementMode: definition.enforcementMode,
      boundaryRequirement: definition.boundaryRequirement,
      reviewFirst: definition.enforcementMode ==
              FamilySafetyEnforcementMode.reviewFirst ||
          definition.enforcementMode ==
              FamilySafetyEnforcementMode.alwaysManualReview,
      highRecallDefault: _highRecallCategories.contains(category),
    );
  }

  factory PolicyCategory.fromJson(Map<String, dynamic> json) {
    final category = familySafetyPolicyCategoryFromId(json['id'] as String);
    final fallback = PolicyCategory.fromPolicyCategory(category);
    return PolicyCategory(
      id: fallback.id,
      displayName: json['displayName'] as String? ?? fallback.displayName,
      defaultAction: _remediationActionFromName(
        json['defaultAction'] as String? ?? fallback.defaultAction.name,
      ),
      enforcementMode: _enforcementModeFromName(
        json['enforcementMode'] as String? ?? fallback.enforcementMode.name,
      ),
      boundaryRequirement: _boundaryRequirementFromName(
        json['boundaryRequirement'] as String? ??
            fallback.boundaryRequirement.name,
      ),
      reviewFirst: json['reviewFirst'] as bool? ?? fallback.reviewFirst,
      highRecallDefault:
          json['highRecallDefault'] as bool? ?? fallback.highRecallDefault,
    );
  }

  final String id;
  final String displayName;
  final RemediationAction defaultAction;
  final FamilySafetyEnforcementMode enforcementMode;
  final BoundaryRequirement boundaryRequirement;
  final bool reviewFirst;
  final bool highRecallDefault;

  Map<String, dynamic> toJson() => {
        'id': id,
        'displayName': displayName,
        'defaultAction': defaultAction.name,
        'enforcementMode': enforcementMode.name,
        'boundaryRequirement': boundaryRequirement.name,
        'reviewFirst': reviewFirst,
        'highRecallDefault': highRecallDefault,
      };
}

class PolicyFinding {
  PolicyFinding({
    required this.id,
    required this.mediaId,
    required this.category,
    required this.severity,
    required double confidence,
    required this.startTime,
    required this.endTime,
    required this.recommendedAction,
    required this.needsReview,
    required this.rationale,
    required List<String> supportingEvidenceIds,
    required List<String> sourceModels,
    required List<PolicyFindingOrigin> origins,
    this.agreementState = PolicyAgreementState.notCompared,
    this.groundingStatus = 'scene_level_only',
    List<String> regionIds = const <String>[],
    Map<String, dynamic> developerTracePayload = const <String, dynamic>{},
  })  : confidence = _clampConfidence(confidence),
        supportingEvidenceIds = List.unmodifiable(
          supportingEvidenceIds.where((id) => id.trim().isNotEmpty).toSet(),
        ),
        sourceModels = List.unmodifiable(
          sourceModels.where((model) => model.trim().isNotEmpty).toSet(),
        ),
        origins = List.unmodifiable(origins.toSet()),
        regionIds = List.unmodifiable(
          regionIds.where((id) => id.trim().isNotEmpty).toSet(),
        ),
        developerTracePayload =
            Map.unmodifiable(_normalizeJsonMap(developerTracePayload)) {
    if (id.trim().isEmpty) {
      throw ArgumentError('policy finding id is required');
    }
    if (mediaId.trim().isEmpty) {
      throw ArgumentError('media id is required');
    }
    if (endTime < startTime) {
      throw ArgumentError('finding endTime must be after startTime');
    }
    if (rationale.trim().isEmpty) {
      throw ArgumentError('finding rationale is required');
    }
  }

  factory PolicyFinding.fromJson(Map<String, dynamic> json) => PolicyFinding(
        id: json['id'] as String,
        mediaId: json['mediaId'] as String,
        category: familySafetyPolicyCategoryFromId(
          json['categoryId'] as String,
        ),
        severity: familySafetySeverityFromId(json['severity'] as String),
        confidence: (json['confidence'] as num).toDouble(),
        startTime: Duration(milliseconds: json['startTimeMs'] as int),
        endTime: Duration(milliseconds: json['endTimeMs'] as int),
        recommendedAction:
            _remediationActionFromName(json['recommendedAction'] as String),
        needsReview: json['needsReview'] as bool,
        rationale: json['rationale'] as String,
        supportingEvidenceIds:
            (json['supportingEvidenceIds'] as List<dynamic>? ??
                    const <dynamic>[])
                .map((value) => value as String)
                .toList(growable: false),
        sourceModels:
            (json['sourceModels'] as List<dynamic>? ?? const <dynamic>[])
                .map((value) => value as String)
                .toList(growable: false),
        origins: (json['origins'] as List<dynamic>? ?? const <dynamic>[])
            .map((value) => PolicyFindingOrigin.fromJson(value as String))
            .toList(growable: false),
        agreementState: PolicyAgreementState.fromJson(
          json['agreementState'] as String? ??
              PolicyAgreementState.notCompared.jsonValue,
        ),
        groundingStatus:
            json['groundingStatus'] as String? ?? 'scene_level_only',
        regionIds: (json['regionIds'] as List<dynamic>? ?? const <dynamic>[])
            .map((value) => value as String)
            .toList(growable: false),
        developerTracePayload: Map<String, dynamic>.from(
          json['developerTracePayload'] as Map<dynamic, dynamic>? ??
              const <dynamic, dynamic>{},
        ),
      );

  final String id;
  final String mediaId;
  final FamilySafetyPolicyCategory category;
  final FamilySafetySeverity severity;
  final double confidence;
  final Duration startTime;
  final Duration endTime;
  final RemediationAction recommendedAction;
  final bool needsReview;
  final String rationale;
  final List<String> supportingEvidenceIds;
  final List<String> sourceModels;
  final List<PolicyFindingOrigin> origins;
  final PolicyAgreementState agreementState;
  final String groundingStatus;
  final List<String> regionIds;
  final Map<String, dynamic> developerTracePayload;

  String get categoryId => category.id;

  PolicyCategory get policyCategory =>
      PolicyCategory.fromPolicyCategory(category);

  bool get hasBoundary => regionIds.isNotEmpty || groundingStatus == 'grounded';

  Map<String, dynamic> toJson() => {
        'id': id,
        'mediaId': mediaId,
        'categoryId': category.id,
        'categoryDisplayName': category.displayName,
        'severity': severity.name,
        'confidence': confidence,
        'startTimeMs': startTime.inMilliseconds,
        'endTimeMs': endTime.inMilliseconds,
        'recommendedAction': recommendedAction.name,
        'needsReview': needsReview,
        'rationale': rationale,
        'supportingEvidenceIds': supportingEvidenceIds,
        'sourceModels': sourceModels,
        'origins': origins.map((origin) => origin.jsonValue).toList(),
        'agreementState': agreementState.jsonValue,
        'groundingStatus': groundingStatus,
        'regionIds': regionIds,
        'developerTracePayload': developerTracePayload,
      };

  PolicyFinding copyWith({
    String? id,
    FamilySafetySeverity? severity,
    double? confidence,
    bool? needsReview,
    String? rationale,
    List<String>? supportingEvidenceIds,
    List<String>? sourceModels,
    List<PolicyFindingOrigin>? origins,
    PolicyAgreementState? agreementState,
    String? groundingStatus,
    List<String>? regionIds,
    Map<String, dynamic>? developerTracePayload,
  }) =>
      PolicyFinding(
        id: id ?? this.id,
        mediaId: mediaId,
        category: category,
        severity: severity ?? this.severity,
        confidence: confidence ?? this.confidence,
        startTime: startTime,
        endTime: endTime,
        recommendedAction: recommendedAction,
        needsReview: needsReview ?? this.needsReview,
        rationale: rationale ?? this.rationale,
        supportingEvidenceIds:
            supportingEvidenceIds ?? this.supportingEvidenceIds,
        sourceModels: sourceModels ?? this.sourceModels,
        origins: origins ?? this.origins,
        agreementState: agreementState ?? this.agreementState,
        groundingStatus: groundingStatus ?? this.groundingStatus,
        regionIds: regionIds ?? this.regionIds,
        developerTracePayload:
            developerTracePayload ?? this.developerTracePayload,
      );

  static String deterministicId({
    required String mediaId,
    required FamilySafetyPolicyCategory category,
    required Duration startTime,
    required Duration endTime,
    required Iterable<String> supportingEvidenceIds,
    required Iterable<PolicyFindingOrigin> origins,
  }) {
    final canonical = jsonEncode({
      'mediaId': mediaId,
      'categoryId': category.id,
      'startTimeMs': startTime.inMilliseconds,
      'endTimeMs': endTime.inMilliseconds,
      'supportingEvidenceIds': supportingEvidenceIds.toList()..sort(),
      'origins': origins.map((origin) => origin.jsonValue).toList()..sort(),
    });
    return 'pf_${sha256.convert(utf8.encode(canonical)).toString().substring(0, 24)}';
  }
}

FamilySafetyPolicyCategory familySafetyPolicyCategoryFromId(String value) =>
    FamilySafetyPolicyCategory.values.firstWhere(
      (category) => category.id == value,
      orElse: () => throw ArgumentError('Unknown policy category: $value'),
    );

FamilySafetySeverity familySafetySeverityFromId(String value) =>
    FamilySafetySeverity.values.firstWhere(
      (severity) => severity.name == value,
      orElse: () => throw ArgumentError('Unknown policy severity: $value'),
    );

FamilySafetySeverity familySafetySeverityFromScore(double score) {
  if (score >= 0.95) return FamilySafetySeverity.critical;
  if (score >= 0.75) return FamilySafetySeverity.high;
  if (score >= 0.5) return FamilySafetySeverity.medium;
  if (score > 0) return FamilySafetySeverity.low;
  return FamilySafetySeverity.none;
}

const _highRecallCategories = <FamilySafetyPolicyCategory>{
  FamilySafetyPolicyCategory.explicitNudity,
  FamilySafetyPolicyCategory.gore,
  FamilySafetyPolicyCategory.blood,
  FamilySafetyPolicyCategory.weapons,
};

double _clampConfidence(double value) {
  if (!value.isFinite) {
    throw ArgumentError('finding confidence must be finite');
  }
  return value.clamp(0.0, 1.0);
}

RemediationAction _remediationActionFromName(String value) =>
    RemediationAction.values.firstWhere(
      (action) => action.name == value,
      orElse: () => throw ArgumentError('Unknown remediation action: $value'),
    );

FamilySafetyEnforcementMode _enforcementModeFromName(String value) =>
    FamilySafetyEnforcementMode.values.firstWhere(
      (mode) => mode.name == value,
      orElse: () => throw ArgumentError('Unknown enforcement mode: $value'),
    );

BoundaryRequirement _boundaryRequirementFromName(String value) =>
    BoundaryRequirement.values.firstWhere(
      (requirement) => requirement.name == value,
      orElse: () => throw ArgumentError('Unknown boundary requirement: $value'),
    );

Map<String, dynamic> _normalizeJsonMap(Map<String, dynamic> value) =>
    Map<String, dynamic>.from(jsonDecode(jsonEncode(value)) as Map);
