import 'package:flutter_test/flutter_test.dart';
import 'package:kidslens_video_editor/data/models/models.dart';
import 'package:kidslens_video_editor/services/detection/detection_pipeline_profile.dart';
import 'package:kidslens_video_editor/services/detection/policy_engine.dart';

void main() {
  group('PolicyEngine VLM mapping', () {
    test('produces golden findings for every approved policy category', () {
      final record = _vlmCaptionRecord(
        findings: [
          for (final category in FamilySafetyPolicyCategory.values)
            _vlmFinding(
              category: category,
              confidence:
                  category == FamilySafetyPolicyCategory.immodestFemaleClothing
                      ? 0.28
                      : 0.72,
            ),
        ],
      );

      final result = const PolicyEngine().evaluate(
        mediaId: _mediaId,
        records: [record],
      );
      final byCategory = {
        for (final finding in result.findings) finding.category: finding,
      };

      expect(result.warnings, isEmpty);
      expect(byCategory.keys, containsAll(FamilySafetyPolicyCategory.values));
      expect(
        byCategory[FamilySafetyPolicyCategory.explicitNudity]!
            .recommendedAction,
        RemediationAction.blurRegion,
      );
      expect(
        byCategory[FamilySafetyPolicyCategory.profanity]!.recommendedAction,
        RemediationAction.beep,
      );
      expect(
        byCategory[FamilySafetyPolicyCategory.immodestFemaleClothing]!
            .needsReview,
        isTrue,
      );
      expect(
        byCategory[FamilySafetyPolicyCategory.weapons]!.sourceModels,
        ['qwen3.5-vl-local'],
      );
    });

    test('includes supporting grounded-region evidence IDs', () {
      final grounded = _groundedRegionRecord(
        regionId: 'region_legs',
        category: FamilySafetyPolicyCategory.immodestFemaleClothing,
      );
      final vlm = _vlmCaptionRecord(
        findings: [
          _vlmFinding(
            category: FamilySafetyPolicyCategory.immodestFemaleClothing,
            groundingStatus: 'grounded',
            regionIds: const ['region_legs'],
          ),
        ],
      );

      final result = const PolicyEngine().evaluate(
        mediaId: _mediaId,
        records: [grounded, vlm],
      );
      final vlmFinding = result.findings.firstWhere(
        (finding) => finding.origins.contains(PolicyFindingOrigin.vlm),
      );

      expect(vlmFinding.supportingEvidenceIds, contains(vlm.id));
      expect(vlmFinding.supportingEvidenceIds, contains(grounded.id));
      expect(vlmFinding.regionIds, ['region_legs']);
      expect(vlmFinding.groundingStatus, 'grounded');
    });

    test('keeps high-recall categories below normal VLM threshold', () {
      final record = _vlmCaptionRecord(
        findings: [
          _vlmFinding(
            category: FamilySafetyPolicyCategory.weapons,
            confidence: 0.22,
          ),
          _vlmFinding(
            category: FamilySafetyPolicyCategory.profanity,
            confidence: 0.22,
          ),
        ],
      );

      final result = const PolicyEngine().evaluate(
        mediaId: _mediaId,
        records: [record],
      );

      expect(
        result.findings.map((finding) => finding.category),
        [FamilySafetyPolicyCategory.weapons],
      );
    });

    test('maps kissing romance as review-first scene-level content', () {
      final record = _vlmCaptionRecord(
        findings: [
          _vlmFinding(
            category: FamilySafetyPolicyCategory.kissingRomance,
            rationale: 'Brief peck kissing is visible without sexual activity.',
          ),
        ],
      );

      final result = const PolicyEngine().evaluate(
        mediaId: _mediaId,
        records: [record],
      );

      expect(
        result.findings.single.category,
        FamilySafetyPolicyCategory.kissingRomance,
      );
      expect(result.findings.single.severity, FamilySafetySeverity.low);
      expect(result.findings.single.needsReview, isTrue);
      expect(result.findings.single.groundingStatus, 'scene_level_only');
    });

    test('escalates sexualized romance context to sexual content', () {
      final record = _vlmCaptionRecord(
        findings: [
          _vlmFinding(
            category: FamilySafetyPolicyCategory.kissingRomance,
            severity: 'low',
            rationale:
                'Romantic kissing includes sexualized touching and simulated sexual behavior.',
          ),
        ],
      );

      final result = const PolicyEngine().evaluate(
        mediaId: _mediaId,
        records: [record],
      );

      expect(
        result.findings.single.category,
        FamilySafetyPolicyCategory.sexualContent,
      );
      expect(result.findings.single.severity, FamilySafetySeverity.medium);
    });

    test('normalizes immodesty severity from exposure signals', () {
      final record = _vlmCaptionRecord(
        findings: [
          _vlmFinding(
            category: FamilySafetyPolicyCategory.immodestFemaleClothing,
            exposureSignals: const ['bare_legs'],
          ),
          _vlmFinding(
            category: FamilySafetyPolicyCategory.immodestFemaleClothing,
            severity: 'low',
            startTimeMs: 2000,
            endTimeMs: 3000,
            exposureSignals: const ['bare_legs', 'bare_midriff'],
          ),
          _vlmFinding(
            category: FamilySafetyPolicyCategory.immodestFemaleClothing,
            severity: 'low',
            startTimeMs: 4000,
            endTimeMs: 5000,
            exposureSignals: const ['lingerie'],
          ),
        ],
      );

      final result = const PolicyEngine().evaluate(
        mediaId: _mediaId,
        records: [record],
      );

      expect(
        result.findings.map((finding) => finding.severity),
        [
          FamilySafetySeverity.low,
          FamilySafetySeverity.medium,
          FamilySafetySeverity.medium,
        ],
      );
    });

    test('downgrades toy or prop weapon findings to low severity', () {
      final record = _vlmCaptionRecord(
        findings: [
          _vlmFinding(
            category: FamilySafetyPolicyCategory.weapons,
            severity: 'critical',
            weaponState: 'toy/prop',
            rationale: 'A toy/prop gun-like object is displayed.',
          ),
        ],
      );

      final result = const PolicyEngine().evaluate(
        mediaId: _mediaId,
        records: [record],
      );

      expect(
        result.findings.single.category,
        FamilySafetyPolicyCategory.weapons,
      );
      expect(result.findings.single.severity, FamilySafetySeverity.low);
    });
  });

  group('PolicyEngine legacy and transcript mapping', () {
    test('maps legacy NSFW scores to policy findings', () {
      final record = _legacyNsfwRecord(porn: 0.84, neutral: 0.08);

      final result = const PolicyEngine().evaluate(
        mediaId: _mediaId,
        records: [record],
      );

      expect(result.findings, hasLength(1));
      expect(
        result.findings.single.category,
        FamilySafetyPolicyCategory.explicitNudity,
      );
      expect(result.findings.single.confidence, 0.84);
      expect(result.findings.single.supportingEvidenceIds, [record.id]);
    });

    test('maps NudeNet regions to grounded policy findings', () {
      final record = _legacyRegionRecord(
        label: 'FEMALE_BREAST_EXPOSED',
        confidence: 0.91,
      );

      final result = const PolicyEngine().evaluate(
        mediaId: _mediaId,
        records: [record],
      );

      expect(
        result.findings.single.category,
        FamilySafetyPolicyCategory.explicitNudity,
      );
      expect(result.findings.single.groundingStatus, 'grounded');
      expect(result.findings.single.hasBoundary, isTrue);
    });

    test('maps modesty parser signals as review-first', () {
      final record = EvidenceRecord.modestyParserSignal(
        mediaId: _mediaId,
        timestamp: Duration.zero,
        frameNumber: 0,
        categoryId: FamilySafetyPolicyCategory.immodestFemaleClothing.id,
        region: const DetectedRegion(
          label: 'FEMALE_LEGS_EXPOSED',
          confidence: 0.31,
          x: 0.2,
          y: 0.4,
          width: 0.3,
          height: 0.5,
        ),
        provenance: _provenance(providerId: 'local_modesty_parser'),
      );

      final result = const PolicyEngine().evaluate(
        mediaId: _mediaId,
        records: [record],
      );

      expect(
        result.findings.single.category,
        FamilySafetyPolicyCategory.immodestFemaleClothing,
      );
      expect(result.findings.single.needsReview, isTrue);
    });

    test('maps profanity matches and ignores false positives', () {
      final confirmed = EvidenceRecord.profanityMatch(
        mediaId: _mediaId,
        match: ProfanityMatch.exact(
          id: 'pm_1',
          word: const TranscriptWord(
            word: 'badword',
            startTime: Duration(seconds: 1),
            endTime: Duration(seconds: 2),
            confidence: 0.96,
          ),
          matchedProfanity: 'badword',
          severity: 4,
        ),
        provenance: _provenance(providerId: 'local_profanity'),
      );
      final falsePositive = EvidenceRecord.profanityMatch(
        mediaId: _mediaId,
        match: ProfanityMatch.exact(
          id: 'pm_2',
          word: const TranscriptWord(
            word: 'safe',
            startTime: Duration(seconds: 3),
            endTime: Duration(seconds: 4),
            confidence: 0.96,
          ),
          matchedProfanity: 'safe',
        ).markAsFalsePositive(),
        provenance: _provenance(providerId: 'local_profanity'),
      );

      final result = const PolicyEngine().evaluate(
        mediaId: _mediaId,
        records: [confirmed, falsePositive],
      );

      expect(result.findings, hasLength(1));
      expect(
        result.findings.single.category,
        FamilySafetyPolicyCategory.profanity,
      );
      expect(result.findings.single.severity, FamilySafetySeverity.high);
      expect(
        result.findings.single.origins,
        containsAll([
          PolicyFindingOrigin.transcript,
          PolicyFindingOrigin.profanity,
        ]),
      );
    });

    test('maps classified transcript spans when category metadata is present',
        () {
      final record = EvidenceRecord(
        id: 'ev_transcript_span',
        mediaId: _mediaId,
        type: EvidenceType.transcriptSpan,
        provenance: _provenance(providerId: 'local_transcript_classifier'),
        payload: {
          'categoryId': FamilySafetyPolicyCategory.profanity.id,
          'confidence': 0.77,
          'segment': const TranscriptSegment(
            id: 'segment_1',
            startTime: Duration(seconds: 2),
            endTime: Duration(seconds: 4),
            text: 'classified unsafe audio',
            words: [],
          ).toJson(),
        },
      );

      final result = const PolicyEngine().evaluate(
        mediaId: _mediaId,
        records: [record],
      );

      expect(
        result.findings.single.category,
        FamilySafetyPolicyCategory.profanity,
      );
      expect(result.findings.single.origins, [PolicyFindingOrigin.transcript]);
    });

    test('keeps legacy evidence auxiliary-only for the VSS default policy', () {
      final legacyUnsafe = _legacyNsfwRecord(porn: 0.84, neutral: 0.04);
      final nudenet = _legacyRegionRecord(
        label: 'FEMALE_BREAST_EXPOSED',
        confidence: 0.91,
      );
      final modesty = EvidenceRecord.modestyParserSignal(
        mediaId: _mediaId,
        timestamp: Duration.zero,
        frameNumber: 0,
        categoryId: FamilySafetyPolicyCategory.immodestFemaleClothing.id,
        region: const DetectedRegion(
          label: 'FEMALE_LEGS_EXPOSED',
          confidence: 0.7,
          x: 0.2,
          y: 0.4,
          width: 0.3,
          height: 0.5,
        ),
        provenance: _provenance(providerId: 'local_modesty_parser'),
      );

      final result = const PolicyEngine(
        options: PolicyEngineOptions.vssDefault(),
      ).evaluate(
        mediaId: _mediaId,
        records: [legacyUnsafe, nudenet, modesty],
      );

      expect(result.findings, isEmpty);
    });

    test('allows grounded auxiliary output in the VSS default policy', () {
      final grounded = _groundedRegionRecord(
        regionId: 'grounded_1',
        category: FamilySafetyPolicyCategory.explicitNudity,
      );

      final result = const PolicyEngine(
        options: PolicyEngineOptions.vssDefault(),
      ).evaluate(
        mediaId: _mediaId,
        records: [grounded],
      );

      expect(result.findings, hasLength(1));
      expect(
        result.findings.single.origins,
        [PolicyFindingOrigin.groundedRegion],
      );
      expect(result.findings.single.regionIds, ['grounded_1']);
    });

    test('selects auxiliary-only legacy evidence for the VSS pipeline ID', () {
      final vss = PolicyEngine.forPipeline(
        DetectionPipelineIds.vssFamilySafetyV1,
      );
      final legacy = PolicyEngine.forPipeline(
        DetectionPipelineIds.legacyNsfwRegionV8,
      );

      expect(
        vss.options.legacyEvidencePolicy,
        LegacyEvidencePolicy.auxiliaryOnly,
      );
      expect(
        legacy.options.legacyEvidencePolicy,
        LegacyEvidencePolicy.directDetection,
      );
    });
  });

  group('PolicyEngine provider disagreement policy', () {
    test('marks VLM unsafe when legacy reported safe', () {
      final vlm = _vlmCaptionRecord(
        findings: [
          _vlmFinding(category: FamilySafetyPolicyCategory.explicitNudity),
        ],
      );
      final legacySafe = _legacyNsfwRecord(
        porn: 0.02,
        sexy: 0.01,
        hentai: 0.01,
        neutral: 0.96,
      );

      final result = const PolicyEngine().evaluate(
        mediaId: _mediaId,
        records: [vlm, legacySafe],
      );

      expect(
        result.findings.single.agreementState,
        PolicyAgreementState.vlmUnsafeLegacySafe,
      );
      expect(result.findings.single.needsReview, isTrue);
    });

    test('marks legacy unsafe when VLM omitted the category', () {
      final vlm = _vlmCaptionRecord(findings: const []);
      final legacyUnsafe = _legacyNsfwRecord(porn: 0.82, neutral: 0.05);

      final result = const PolicyEngine().evaluate(
        mediaId: _mediaId,
        records: [vlm, legacyUnsafe],
      );

      expect(
        result.findings.single.category,
        FamilySafetyPolicyCategory.explicitNudity,
      );
      expect(
        result.findings.single.agreementState,
        PolicyAgreementState.legacyUnsafeVlmOmitted,
      );
      expect(result.findings.single.needsReview, isTrue);
    });

    test('marks both providers when they agree unsafe', () {
      final vlm = _vlmCaptionRecord(
        findings: [
          _vlmFinding(category: FamilySafetyPolicyCategory.explicitNudity),
        ],
      );
      final legacyUnsafe = _legacyNsfwRecord(porn: 0.82, neutral: 0.05);

      final result = const PolicyEngine().evaluate(
        mediaId: _mediaId,
        records: [vlm, legacyUnsafe],
      );

      expect(result.findings, hasLength(2));
      expect(
        result.findings.map((finding) => finding.agreementState).toSet(),
        {PolicyAgreementState.bothAgreeUnsafe},
      );
    });

    test('reports provider failure warnings', () {
      final failed = EvidenceRecord(
        id: 'ev_vlm_failed',
        mediaId: _mediaId,
        type: EvidenceType.vlmPolicyJson,
        provenance: _provenance(providerId: 'local_vllm'),
        payload: {
          'kind': 'provider_error',
          'error': 'runtime exited before response',
        },
      );

      final result = const PolicyEngine().evaluate(
        mediaId: _mediaId,
        records: [failed],
      );

      expect(result.findings, isEmpty);
      expect(result.warnings.single, startsWith('provider_failed:local_vllm'));
    });
  });
}

const _mediaId = 'media_policy_engine';

Map<String, dynamic> _vlmFinding({
  required FamilySafetyPolicyCategory category,
  double confidence = 0.81,
  String severity = 'high',
  String? rationale,
  String groundingStatus = 'scene_level_only',
  List<String> regionIds = const <String>[],
  List<String>? exposureSignals,
  String? weaponState,
  int startTimeMs = 0,
  int endTimeMs = 1000,
}) =>
    {
      'category': category.id,
      'severity': severity,
      'confidence': confidence,
      'rationale':
          rationale ?? 'Local VLM rationale for ${category.displayName}.',
      'startTimeMs': startTimeMs,
      'endTimeMs': endTimeMs,
      'regionIds': regionIds,
      'groundingStatus': groundingStatus,
      'needsReview': false,
      if (exposureSignals != null) 'exposureSignals': exposureSignals,
      if (weaponState != null) 'weaponState': weaponState,
    };

EvidenceRecord _vlmCaptionRecord({
  required List<Map<String, dynamic>> findings,
}) {
  final payload = {
    'kind': 'parsed_response',
    'caption': 'Policy test caption.',
    'findings': findings,
    'uncertainty': <String>[],
    'schemaRepairWarnings': <String>[],
  };
  final provenance = _provenance(
    providerId: 'local_vllm',
    modelBundleId: 'qwen3.5-vl-local',
  );
  return EvidenceRecord(
    id: EvidenceRecord.deterministicId(
      mediaId: _mediaId,
      type: EvidenceType.vlmCaption,
      provenance: provenance,
      payload: payload,
    ),
    mediaId: _mediaId,
    type: EvidenceType.vlmCaption,
    provenance: provenance,
    payload: payload,
    chunkId: 'chunk_1',
  );
}

EvidenceRecord _legacyNsfwRecord({
  double porn = 0,
  double sexy = 0,
  double hentai = 0,
  double neutral = 1,
}) =>
    EvidenceRecord.legacyNsfwScore(
      mediaId: _mediaId,
      frame: FrameAnalysisResult(
        frameNumber: 0,
        timestamp: Duration.zero,
        nsfw: NsfwResult(
          porn: porn,
          sexy: sexy,
          hentai: hentai,
          drawings: 0,
          neutral: neutral,
        ),
        violence: ViolenceResult.safe(),
      ),
      provenance: _provenance(providerId: 'legacy_nsfw'),
    );

EvidenceRecord _legacyRegionRecord({
  required String label,
  required double confidence,
}) =>
    EvidenceRecord.legacyNudenetRegion(
      mediaId: _mediaId,
      timestamp: Duration.zero,
      frameNumber: 0,
      region: DetectedRegion(
        label: label,
        confidence: confidence,
        x: 0.1,
        y: 0.2,
        width: 0.3,
        height: 0.4,
      ),
      provenance: _provenance(providerId: 'legacy_nudenet'),
    );

EvidenceRecord _groundedRegionRecord({
  required String regionId,
  required FamilySafetyPolicyCategory category,
}) {
  final payload = {
    'timestampMs': 0,
    'categoryId': category.id,
    'groundingStatus': 'grounded',
    'rationale': 'Localized ${category.displayName}.',
    'region': const DetectedRegion(
      label: 'localized_region',
      confidence: 0.88,
      x: 0.3,
      y: 0.3,
      width: 0.2,
      height: 0.2,
    ).toJson(),
    'groundedRegion': {
      'id': regionId,
      'confidence': 0.88,
    },
  };
  final provenance = _provenance(providerId: 'local_grounding');
  return EvidenceRecord(
    id: EvidenceRecord.deterministicId(
      mediaId: _mediaId,
      type: EvidenceType.groundedRegion,
      provenance: provenance,
      payload: payload,
    ),
    mediaId: _mediaId,
    type: EvidenceType.groundedRegion,
    provenance: provenance,
    payload: payload,
  );
}

EvidenceProvenance _provenance({
  required String providerId,
  String? modelBundleId,
  Duration startTime = Duration.zero,
  Duration endTime = const Duration(seconds: 2),
}) =>
    EvidenceProvenance(
      providerId: providerId,
      providerVersion: '1',
      modelBundleId: modelBundleId,
      runtime: 'test',
      inputIds: const ['chunk_1'],
      startTime: startTime,
      endTime: endTime,
    );
