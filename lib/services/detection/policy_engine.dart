import 'package:kidslens_video_editor/data/models/models.dart';
import 'package:kidslens_video_editor/services/detection/detection_pipeline_profile.dart';

enum LegacyEvidencePolicy {
  directDetection,
  auxiliaryOnly,
}

class PolicyEngineOptions {
  const PolicyEngineOptions({
    this.vlmConfidenceThreshold = 0.35,
    this.legacyConfidenceThreshold = 0.5,
    this.highRecallConfidenceThreshold = 0.2,
    this.profanityConfidenceThreshold = 0.7,
    this.legacyEvidencePolicy = LegacyEvidencePolicy.directDetection,
  });

  const PolicyEngineOptions.vssDefault()
      : vlmConfidenceThreshold = 0.35,
        legacyConfidenceThreshold = 0.5,
        highRecallConfidenceThreshold = 0.2,
        profanityConfidenceThreshold = 0.7,
        legacyEvidencePolicy = LegacyEvidencePolicy.auxiliaryOnly;

  final double vlmConfidenceThreshold;
  final double legacyConfidenceThreshold;
  final double highRecallConfidenceThreshold;
  final double profanityConfidenceThreshold;
  final LegacyEvidencePolicy legacyEvidencePolicy;

  bool get promotesLegacyEvidence =>
      legacyEvidencePolicy == LegacyEvidencePolicy.directDetection;
}

class PolicyEngineResult {
  const PolicyEngineResult({
    required this.findings,
    this.warnings = const <String>[],
  });

  final List<PolicyFinding> findings;
  final List<String> warnings;

  bool get hasFindings => findings.isNotEmpty;
}

class PolicyEngine {
  const PolicyEngine({this.options = const PolicyEngineOptions()});

  factory PolicyEngine.forPipeline(String pipelineId) => PolicyEngine(
        options: pipelineId == DetectionPipelineIds.vssFamilySafetyV1
            ? const PolicyEngineOptions.vssDefault()
            : const PolicyEngineOptions(),
      );

  final PolicyEngineOptions options;

  PolicyEngineResult evaluate({
    required String mediaId,
    required Iterable<EvidenceRecord> records,
  }) {
    final evidence = records
        .where((record) => record.mediaId == mediaId)
        .toList(growable: false);
    final warnings = <String>[];
    final groundedRegionEvidenceIds = _groundedRegionEvidenceIds(evidence);
    final legacySafeWindows = <_LegacySafeWindow>[];
    final vlmWindows = <_EvidenceWindow>[];
    final findings = <PolicyFinding>[];

    for (final record in evidence) {
      switch (record.type) {
        case EvidenceType.vlmCaption:
          vlmWindows.add(_EvidenceWindow.fromRecord(record));
          findings.addAll(
            _mapVlmCaption(record, groundedRegionEvidenceIds, warnings),
          );
        case EvidenceType.vlmPolicyJson:
          _collectProviderFailure(record, warnings);
        case EvidenceType.legacyNsfwScore:
          legacySafeWindows.addAll(_legacySafeWindows(record));
          if (options.promotesLegacyEvidence) {
            findings.addAll(_mapLegacyNsfwScore(record));
          }
        case EvidenceType.legacyNudenetRegion:
          if (options.promotesLegacyEvidence) {
            findings.addAll(_mapLegacyRegion(record));
          }
        case EvidenceType.modestyParserSignal:
          if (options.promotesLegacyEvidence) {
            findings.addAll(_mapModestySignal(record));
          }
        case EvidenceType.transcriptSpan:
          findings.addAll(_mapTranscriptSpan(record));
        case EvidenceType.profanityMatch:
          findings.addAll(_mapProfanityMatch(record));
        case EvidenceType.groundedRegion:
          findings.addAll(_mapGroundedRegion(record));
        case EvidenceType.embeddingRecord:
          break;
      }
    }

    final compared = _applyAgreementPolicy(
      findings: findings,
      vlmWindows: vlmWindows,
      legacySafeWindows: legacySafeWindows,
    )..sort((a, b) {
        final time = a.startTime.compareTo(b.startTime);
        if (time != 0) return time;
        final category = a.categoryId.compareTo(b.categoryId);
        if (category != 0) return category;
        return b.confidence.compareTo(a.confidence);
      });
    return PolicyEngineResult(
      findings: compared,
      warnings: warnings.toSet().toList(growable: false),
    );
  }

  List<PolicyFinding> _mapVlmCaption(
    EvidenceRecord record,
    Map<String, String> groundedRegionEvidenceIds,
    List<String> warnings,
  ) {
    final rawFindings = record.payload['findings'];
    if (rawFindings is! List) return const <PolicyFinding>[];
    final findings = <PolicyFinding>[];
    for (final rawFinding in rawFindings) {
      if (rawFinding is! Map) continue;
      final finding = Map<String, dynamic>.from(rawFinding);
      final category = _tryCategory(finding['category']);
      if (category == null) {
        warnings.add('vlm finding skipped unknown category');
        continue;
      }
      final confidence =
          (finding['confidence'] as num?)?.toDouble().clamp(0.0, 1.0) ?? 0.0;
      final needsReview = finding['needsReview'] as bool? ?? false;
      if (!_shouldKeep(category, confidence, options.vlmConfidenceThreshold) &&
          !needsReview) {
        continue;
      }
      final start = _durationFromMs(finding['startTimeMs']) ??
          record.provenance.startTime;
      final end =
          _durationFromMs(finding['endTimeMs']) ?? record.provenance.endTime;
      final regionIds = _stringList(finding['regionIds']);
      final supportingIds = <String>[
        record.id,
        for (final regionId in regionIds)
          if (groundedRegionEvidenceIds[regionId] != null)
            groundedRegionEvidenceIds[regionId]!,
      ];
      findings.add(
        _finding(
          mediaId: record.mediaId,
          category: category,
          severity: _severityFromAny(finding['severity']) ??
              familySafetySeverityFromScore(confidence),
          confidence: confidence,
          startTime: start,
          endTime: end,
          needsReview: needsReview,
          rationale: _stringOrDefault(
            finding['rationale'],
            'The local VLM reported ${category.displayName}.',
          ),
          supportingEvidenceIds: supportingIds,
          sourceModels: _sourceModels(record),
          origins: const [PolicyFindingOrigin.vlm],
          groundingStatus: _stringOrDefault(
            finding['groundingStatus'],
            'scene_level_only',
          ),
          regionIds: regionIds,
          developerTracePayload: {
            'sourceEvidenceType': record.type.jsonValue,
            'providerId': record.provenance.providerId,
            'chunkId': record.chunkId,
            'rawFinding': finding,
          },
        ),
      );
    }
    return findings;
  }

  List<PolicyFinding> _mapLegacyNsfwScore(EvidenceRecord record) {
    final nsfw = record.payload['nsfw'];
    if (nsfw is! Map) return const <PolicyFinding>[];
    final scores = Map<String, dynamic>.from(nsfw);
    final timestamp = _durationFromMs(record.payload['timestampMs']) ??
        record.provenance.startTime;
    final mapped = <_LegacyScore>[
      _LegacyScore(
        category: FamilySafetyPolicyCategory.explicitNudity,
        score: _score(scores['porn']),
        label: 'porn',
      ),
      _LegacyScore(
        category: FamilySafetyPolicyCategory.suggestiveContent,
        score: _score(scores['sexy']),
        label: 'sexy',
      ),
      _LegacyScore(
        category: FamilySafetyPolicyCategory.sexualContent,
        score: _score(scores['hentai']),
        label: 'hentai',
      ),
    ];
    return [
      for (final score in mapped)
        if (_shouldKeep(
          score.category,
          score.score,
          options.legacyConfidenceThreshold,
        ))
          _finding(
            mediaId: record.mediaId,
            category: score.category,
            severity: familySafetySeverityFromScore(score.score),
            confidence: score.score,
            startTime: timestamp,
            endTime: timestamp,
            needsReview: false,
            rationale:
                'Legacy NSFW model reported ${score.label} content above threshold.',
            supportingEvidenceIds: [record.id],
            sourceModels: _sourceModels(record),
            origins: const [PolicyFindingOrigin.legacy],
            developerTracePayload: {
              'sourceEvidenceType': record.type.jsonValue,
              'providerId': record.provenance.providerId,
              'legacyScores': scores,
              'legacyLabel': score.label,
            },
          ),
    ];
  }

  List<_LegacySafeWindow> _legacySafeWindows(EvidenceRecord record) {
    final nsfw = record.payload['nsfw'];
    if (nsfw is! Map) return const <_LegacySafeWindow>[];
    final scores = Map<String, dynamic>.from(nsfw);
    final maxUnsafe = [
      _score(scores['porn']),
      _score(scores['sexy']),
      _score(scores['hentai']),
    ].fold<double>(0, (max, value) => value > max ? value : max);
    final neutral = _score(scores['neutral']);
    if (neutral <= 0.8 || maxUnsafe >= 0.2) {
      return const <_LegacySafeWindow>[];
    }
    final timestamp = _durationFromMs(record.payload['timestampMs']) ??
        record.provenance.startTime;
    return [
      _LegacySafeWindow(
        startTime: timestamp,
        endTime: timestamp,
        categories: const {
          FamilySafetyPolicyCategory.explicitNudity,
          FamilySafetyPolicyCategory.sexualContent,
          FamilySafetyPolicyCategory.suggestiveContent,
          FamilySafetyPolicyCategory.immodestFemaleClothing,
        },
      ),
    ];
  }

  List<PolicyFinding> _mapLegacyRegion(EvidenceRecord record) {
    final region = _regionPayload(record);
    if (region == null) return const <PolicyFinding>[];
    final category = _tryCategory(record.payload['categoryId']) ??
        _categoryFromLegacyRegionLabel(region.label);
    if (category == null) return const <PolicyFinding>[];
    if (!_shouldKeep(
      category,
      region.confidence,
      options.legacyConfidenceThreshold,
    )) {
      return const <PolicyFinding>[];
    }
    final timestamp = _durationFromMs(record.payload['timestampMs']) ??
        record.provenance.startTime;
    return [
      _finding(
        mediaId: record.mediaId,
        category: category,
        severity: familySafetySeverityFromScore(region.confidence),
        confidence: region.confidence,
        startTime: timestamp,
        endTime: timestamp,
        needsReview: false,
        rationale:
            'Legacy region detector reported ${region.label} above threshold.',
        supportingEvidenceIds: [record.id],
        sourceModels: _sourceModels(record),
        origins: const [PolicyFindingOrigin.legacy],
        groundingStatus: 'grounded',
        developerTracePayload: {
          'sourceEvidenceType': record.type.jsonValue,
          'providerId': record.provenance.providerId,
          'legacyRegion': region.toJson(),
        },
      ),
    ];
  }

  List<PolicyFinding> _mapModestySignal(EvidenceRecord record) {
    final region = _regionPayload(record);
    if (region == null) return const <PolicyFinding>[];
    final category = _tryCategory(record.payload['categoryId']) ??
        FamilySafetyPolicyCategory.immodestFemaleClothing;
    if (!_shouldKeep(
      category,
      region.confidence,
      options.highRecallConfidenceThreshold,
    )) {
      return const <PolicyFinding>[];
    }
    final timestamp = _durationFromMs(record.payload['timestampMs']) ??
        record.provenance.startTime;
    return [
      _finding(
        mediaId: record.mediaId,
        category: category,
        severity: familySafetySeverityFromScore(region.confidence),
        confidence: region.confidence,
        startTime: timestamp,
        endTime: timestamp,
        needsReview: true,
        rationale:
            'Modesty parser reported ${region.label}; this category is review-first.',
        supportingEvidenceIds: [record.id],
        sourceModels: _sourceModels(record),
        origins: const [PolicyFindingOrigin.legacy],
        groundingStatus: 'grounded',
        developerTracePayload: {
          'sourceEvidenceType': record.type.jsonValue,
          'providerId': record.provenance.providerId,
          'region': region.toJson(),
        },
      ),
    ];
  }

  List<PolicyFinding> _mapGroundedRegion(EvidenceRecord record) {
    final category = _tryCategory(record.payload['categoryId']);
    if (category == null) return const <PolicyFinding>[];
    final confidence = _groundedRegionConfidence(record);
    if (!_shouldKeep(
      category,
      confidence,
      options.highRecallConfidenceThreshold,
    )) {
      return const <PolicyFinding>[];
    }
    final timestamp = _durationFromMs(record.payload['timestampMs']) ??
        record.provenance.startTime;
    final groundedRegion = record.payload['groundedRegion'];
    final regionId =
        groundedRegion is Map ? groundedRegion['id'] as String? : null;
    return [
      _finding(
        mediaId: record.mediaId,
        category: category,
        severity: familySafetySeverityFromScore(confidence),
        confidence: confidence,
        startTime: timestamp,
        endTime: timestamp,
        needsReview: false,
        rationale: _stringOrDefault(
          record.payload['rationale'],
          'Grounding provider localized ${category.displayName}.',
        ),
        supportingEvidenceIds: [record.id],
        sourceModels: _sourceModels(record),
        origins: const [PolicyFindingOrigin.groundedRegion],
        groundingStatus: _stringOrDefault(
          record.payload['groundingStatus'],
          'grounded',
        ),
        regionIds: [if (regionId != null) regionId],
        developerTracePayload: {
          'sourceEvidenceType': record.type.jsonValue,
          'providerId': record.provenance.providerId,
          'groundedRegion': groundedRegion,
        },
      ),
    ];
  }

  List<PolicyFinding> _mapTranscriptSpan(EvidenceRecord record) {
    final category = _tryCategory(record.payload['categoryId']);
    if (category == null) return const <PolicyFinding>[];
    final confidence = _score(record.payload['confidence']);
    if (!_shouldKeep(
      category,
      confidence,
      options.profanityConfidenceThreshold,
    )) {
      return const <PolicyFinding>[];
    }
    final segment = record.payload['segment'];
    final start = _durationFromMs(
          segment is Map
              ? segment['startTimeMs']
              : record.payload['startTimeMs'],
        ) ??
        record.provenance.startTime;
    final end = _durationFromMs(
          segment is Map ? segment['endTimeMs'] : record.payload['endTimeMs'],
        ) ??
        record.provenance.endTime;
    return [
      _finding(
        mediaId: record.mediaId,
        category: category,
        severity: familySafetySeverityFromScore(confidence),
        confidence: confidence,
        startTime: start,
        endTime: end,
        needsReview: false,
        rationale: 'Transcript classifier reported ${category.displayName}.',
        supportingEvidenceIds: [record.id],
        sourceModels: _sourceModels(record),
        origins: const [PolicyFindingOrigin.transcript],
        developerTracePayload: {
          'sourceEvidenceType': record.type.jsonValue,
          'providerId': record.provenance.providerId,
          'segmentId': segment is Map ? segment['id'] : null,
        },
      ),
    ];
  }

  List<PolicyFinding> _mapProfanityMatch(EvidenceRecord record) {
    final matchJson = record.payload['match'];
    if (matchJson is! Map) return const <PolicyFinding>[];
    final match = ProfanityMatch.fromJson(Map<String, dynamic>.from(matchJson));
    if (match.isFalsePositive) return const <PolicyFinding>[];
    if (match.confidence < options.profanityConfidenceThreshold &&
        !match.isReviewed &&
        !match.isHighSeverity) {
      return const <PolicyFinding>[];
    }
    return [
      _finding(
        mediaId: record.mediaId,
        category: FamilySafetyPolicyCategory.profanity,
        severity: _severityFromProfanity(match.severity),
        confidence: match.confidence,
        startTime: match.startTime,
        endTime: match.endTime,
        needsReview: !match.isReviewed,
        rationale:
            'Transcript profanity matched configured family-safety terms.',
        supportingEvidenceIds: [record.id],
        sourceModels: _sourceModels(record),
        origins: const [
          PolicyFindingOrigin.transcript,
          PolicyFindingOrigin.profanity,
        ],
        developerTracePayload: {
          'sourceEvidenceType': record.type.jsonValue,
          'providerId': record.provenance.providerId,
          'matchId': match.id,
          'matchType': match.type.name,
          'profanityCategory': match.category,
          'severity': match.severity,
        },
      ),
    ];
  }

  void _collectProviderFailure(
    EvidenceRecord record,
    List<String> warnings,
  ) {
    final kind = record.payload['kind'];
    final error = record.payload['error'] ?? record.payload['message'];
    if (kind == 'provider_error' || error != null) {
      warnings.add(
        'provider_failed:${record.provenance.providerId}:${record.id}',
      );
    }
  }

  List<PolicyFinding> _applyAgreementPolicy({
    required List<PolicyFinding> findings,
    required List<_EvidenceWindow> vlmWindows,
    required List<_LegacySafeWindow> legacySafeWindows,
  }) {
    final vlmFindings = findings
        .where((finding) => finding.origins.contains(PolicyFindingOrigin.vlm))
        .toList(growable: false);
    final legacyFindings = findings
        .where(
          (finding) => finding.origins.contains(PolicyFindingOrigin.legacy),
        )
        .toList(growable: false);

    return [
      for (final finding in findings)
        if (finding.origins.contains(PolicyFindingOrigin.vlm))
          _applyVlmAgreement(finding, legacyFindings, legacySafeWindows)
        else if (finding.origins.contains(PolicyFindingOrigin.legacy))
          _applyLegacyAgreement(finding, vlmFindings, vlmWindows)
        else
          finding,
    ];
  }

  PolicyFinding _applyVlmAgreement(
    PolicyFinding finding,
    List<PolicyFinding> legacyFindings,
    List<_LegacySafeWindow> legacySafeWindows,
  ) {
    final matchingLegacy = legacyFindings.any(
      (legacy) =>
          legacy.category == finding.category && _overlaps(legacy, finding),
    );
    if (matchingLegacy) {
      return finding.copyWith(
        agreementState: PolicyAgreementState.bothAgreeUnsafe,
      );
    }
    final legacySafe = legacySafeWindows.any(
      (window) =>
          window.categories.contains(finding.category) &&
          window.overlaps(finding.startTime, finding.endTime),
    );
    if (legacySafe) {
      return finding.copyWith(
        needsReview: true,
        agreementState: PolicyAgreementState.vlmUnsafeLegacySafe,
      );
    }
    return finding;
  }

  PolicyFinding _applyLegacyAgreement(
    PolicyFinding finding,
    List<PolicyFinding> vlmFindings,
    List<_EvidenceWindow> vlmWindows,
  ) {
    final matchingVlm = vlmFindings.any(
      (vlm) => vlm.category == finding.category && _overlaps(vlm, finding),
    );
    if (matchingVlm) {
      return finding.copyWith(
        agreementState: PolicyAgreementState.bothAgreeUnsafe,
      );
    }
    final hadVlmCoverage = vlmWindows.any(
      (window) => window.overlaps(finding.startTime, finding.endTime),
    );
    if (hadVlmCoverage) {
      return finding.copyWith(
        needsReview: true,
        agreementState: PolicyAgreementState.legacyUnsafeVlmOmitted,
      );
    }
    return finding;
  }

  bool _shouldKeep(
    FamilySafetyPolicyCategory category,
    double confidence,
    double threshold,
  ) {
    final policyCategory = PolicyCategory.fromPolicyCategory(category);
    if (policyCategory.highRecallDefault &&
        confidence >= options.highRecallConfidenceThreshold) {
      return true;
    }
    if (policyCategory.reviewFirst &&
        confidence >= options.highRecallConfidenceThreshold) {
      return true;
    }
    return confidence >= threshold;
  }

  PolicyFinding _finding({
    required String mediaId,
    required FamilySafetyPolicyCategory category,
    required FamilySafetySeverity severity,
    required double confidence,
    required Duration startTime,
    required Duration endTime,
    required bool needsReview,
    required String rationale,
    required List<String> supportingEvidenceIds,
    required List<String> sourceModels,
    required List<PolicyFindingOrigin> origins,
    String groundingStatus = 'scene_level_only',
    List<String> regionIds = const <String>[],
    Map<String, dynamic> developerTracePayload = const <String, dynamic>{},
  }) {
    final policyCategory = PolicyCategory.fromPolicyCategory(category);
    final effectiveReview = needsReview || policyCategory.reviewFirst;
    return PolicyFinding(
      id: PolicyFinding.deterministicId(
        mediaId: mediaId,
        category: category,
        startTime: startTime,
        endTime: endTime,
        supportingEvidenceIds: supportingEvidenceIds,
        origins: origins,
      ),
      mediaId: mediaId,
      category: category,
      severity: severity,
      confidence: confidence,
      startTime: startTime,
      endTime: endTime,
      recommendedAction: policyCategory.defaultAction,
      needsReview: effectiveReview,
      rationale: rationale,
      supportingEvidenceIds: supportingEvidenceIds,
      sourceModels: sourceModels,
      origins: origins,
      groundingStatus: groundingStatus,
      regionIds: regionIds,
      developerTracePayload: developerTracePayload,
    );
  }
}

class _LegacyScore {
  const _LegacyScore({
    required this.category,
    required this.score,
    required this.label,
  });

  final FamilySafetyPolicyCategory category;
  final double score;
  final String label;
}

class _EvidenceWindow {
  const _EvidenceWindow({
    required this.startTime,
    required this.endTime,
  });

  factory _EvidenceWindow.fromRecord(EvidenceRecord record) => _EvidenceWindow(
        startTime: record.provenance.startTime,
        endTime: record.provenance.endTime,
      );

  final Duration startTime;
  final Duration endTime;

  bool overlaps(Duration otherStart, Duration otherEnd) =>
      _overlapDurations(startTime, endTime, otherStart, otherEnd);
}

class _LegacySafeWindow {
  const _LegacySafeWindow({
    required this.startTime,
    required this.endTime,
    required this.categories,
  });

  final Duration startTime;
  final Duration endTime;
  final Set<FamilySafetyPolicyCategory> categories;

  bool overlaps(Duration otherStart, Duration otherEnd) =>
      _overlapDurations(startTime, endTime, otherStart, otherEnd);
}

Map<String, String> _groundedRegionEvidenceIds(List<EvidenceRecord> evidence) {
  final ids = <String, String>{};
  for (final record in evidence) {
    if (record.type != EvidenceType.groundedRegion) continue;
    final groundedRegion = record.payload['groundedRegion'];
    if (groundedRegion is Map && groundedRegion['id'] is String) {
      ids[groundedRegion['id'] as String] = record.id;
    }
  }
  return ids;
}

List<String> _sourceModels(EvidenceRecord record) => [
      if (record.provenance.modelBundleId != null)
        record.provenance.modelBundleId!,
      if (record.provenance.modelBundleId == null) record.provenance.providerId,
    ];

FamilySafetyPolicyCategory? _tryCategory(Object? value) {
  if (value is! String || value.trim().isEmpty) return null;
  for (final category in FamilySafetyPolicyCategory.values) {
    if (category.id == value) return category;
  }
  return null;
}

FamilySafetyPolicyCategory? _categoryFromLegacyRegionLabel(String label) {
  final normalized = label.toUpperCase();
  if (normalized.contains('EXPOSED') &&
      (normalized.contains('BREAST') ||
          normalized.contains('GENITAL') ||
          normalized.contains('ANUS') ||
          normalized.contains('BUTTOCK'))) {
    return FamilySafetyPolicyCategory.explicitNudity;
  }
  if ((normalized.contains('FEMALE') || normalized.contains('WOMAN')) &&
      (normalized.contains('LEG') ||
          normalized.contains('THIGH') ||
          normalized.contains('MIDRIFF') ||
          normalized.contains('BELLY'))) {
    return FamilySafetyPolicyCategory.immodestFemaleClothing;
  }
  return null;
}

DetectedRegion? _regionPayload(EvidenceRecord record) {
  final region = record.payload['region'];
  if (region is! Map) return null;
  return DetectedRegion.fromJson(Map<String, dynamic>.from(region));
}

double _groundedRegionConfidence(EvidenceRecord record) {
  final groundedRegion = record.payload['groundedRegion'];
  if (groundedRegion is Map && groundedRegion['confidence'] is num) {
    return (groundedRegion['confidence'] as num).toDouble().clamp(0.0, 1.0);
  }
  final region = record.payload['region'];
  if (region is Map && region['confidence'] is num) {
    return (region['confidence'] as num).toDouble().clamp(0.0, 1.0);
  }
  return 1;
}

FamilySafetySeverity? _severityFromAny(Object? value) {
  if (value is! String) return null;
  for (final severity in FamilySafetySeverity.values) {
    if (severity.name == value) return severity;
  }
  return null;
}

FamilySafetySeverity _severityFromProfanity(int severity) {
  if (severity >= 5) return FamilySafetySeverity.critical;
  if (severity >= 4) return FamilySafetySeverity.high;
  if (severity >= 3) return FamilySafetySeverity.medium;
  return FamilySafetySeverity.low;
}

Duration? _durationFromMs(Object? value) {
  if (value is! num) return null;
  return Duration(milliseconds: value.round());
}

double _score(Object? value) {
  if (value is! num || !value.toDouble().isFinite) return 0;
  return value.toDouble().clamp(0.0, 1.0);
}

String _stringOrDefault(Object? value, String fallback) {
  if (value is String && value.trim().isNotEmpty) return value;
  return fallback;
}

List<String> _stringList(Object? value) {
  if (value is! List) return const <String>[];
  return value
      .whereType<String>()
      .where((item) => item.trim().isNotEmpty)
      .toList(growable: false);
}

bool _overlaps(PolicyFinding a, PolicyFinding b) =>
    _overlapDurations(a.startTime, a.endTime, b.startTime, b.endTime);

bool _overlapDurations(
  Duration aStart,
  Duration aEnd,
  Duration bStart,
  Duration bEnd,
) {
  final normalizedAEnd =
      aEnd > aStart ? aEnd : aStart + const Duration(milliseconds: 1);
  final normalizedBEnd =
      bEnd > bStart ? bEnd : bStart + const Duration(milliseconds: 1);
  return aStart < normalizedBEnd && normalizedAEnd > bStart;
}
