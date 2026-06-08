import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:kidslens_video_editor/data/models/models.dart';
import 'package:kidslens_video_editor/services/detection/local_search_index.dart';

void main() {
  group('FamilySafetySearchIndexer', () {
    test(
        'builds documents for captions, findings, transcript, regions, reviews',
        () {
      final documents = const FamilySafetySearchIndexer().buildDocuments(
        mediaId: _mediaId,
        evidenceRecords: _evidenceRecords(),
        policyFindings: _policyFindings(),
        detections: [_reviewedDetection()],
      );

      expect(
        documents.map((document) => document.kind).toSet(),
        containsAll([
          SearchDocumentKind.caption,
          SearchDocumentKind.vlmFinding,
          SearchDocumentKind.rationale,
          SearchDocumentKind.transcriptSpan,
          SearchDocumentKind.regionLabel,
          SearchDocumentKind.userReviewCorrection,
        ]),
      );
      expect(
        documents
            .where((document) => document.supportingEvidenceIds.isNotEmpty),
        isNotEmpty,
      );
    });
  });

  group('InMemoryLocalSearchIndex', () {
    test('returns timestamped chunks for family-safety fixture queries',
        () async {
      final index = InMemoryLocalSearchIndex();
      await index.indexDocuments(_fixtureDocuments());

      final expectedCategories = {
        'blood': FamilySafetyPolicyCategory.blood.id,
        'fight': FamilySafetyPolicyCategory.violence.id,
        'weapon': FamilySafetyPolicyCategory.weapons.id,
        'revealing clothes':
            FamilySafetyPolicyCategory.immodestFemaleClothing.id,
        'exposed legs': FamilySafetyPolicyCategory.immodestFemaleClothing.id,
        'nudity': FamilySafetyPolicyCategory.explicitNudity.id,
      };

      for (final entry in expectedCategories.entries) {
        final results = await index.search(entry.key, limit: 3);

        expect(results, isNotEmpty, reason: 'query ${entry.key}');
        expect(
          results.any((result) => result.document.categoryId == entry.value),
          isTrue,
          reason: 'query ${entry.key}',
        );
        expect(results.first.startTime, isNotNull);
        expect(results.first.endTime >= results.first.startTime, isTrue);
      }
    });

    test('applies category, severity, review, model, and time filters',
        () async {
      final index = InMemoryLocalSearchIndex();
      await index.indexDocuments(_fixtureDocuments());

      final filtered = await index.search(
        'unsafe',
        filter: SearchFilter(
          categoryIds: {FamilySafetyPolicyCategory.blood.id},
          severities: {FamilySafetySeverity.high.name},
          reviewed: false,
          sourceModels: const {'qwen3.5-vl-local'},
          startTime: const Duration(seconds: 4),
          endTime: const Duration(seconds: 8),
        ),
      );

      expect(filtered, isNotEmpty);
      expect(
        filtered.every(
          (result) =>
              result.document.categoryId ==
                  FamilySafetyPolicyCategory.blood.id &&
              result.document.severity == FamilySafetySeverity.high.name &&
              result.document.reviewed == false &&
              result.document.sourceModels.contains('qwen3.5-vl-local'),
        ),
        isTrue,
      );
    });

    test('persists vector-backed documents under project cache JSON', () async {
      final dir = await Directory.systemTemp.createTemp('kidslens_search_');
      addTearDown(() async {
        if (dir.existsSync()) {
          await dir.delete(recursive: true);
        }
      });
      final store = JsonSearchIndexStore(
        File('${dir.path}${Platform.pathSeparator}search_index.json'),
      );
      final index = InMemoryLocalSearchIndex(store: store);
      await index.indexDocuments(_fixtureDocuments());

      final restored = InMemoryLocalSearchIndex(store: store);
      await restored.load();
      final results = await restored.search('weapon');

      expect(store.file.existsSync(), isTrue);
      expect(results, isNotEmpty);
      expect(results.first.document.embedding, isNotNull);
      expect(results.first.document.embedding, hasLength(64));
    });

    test('can clear one media item without affecting other media', () async {
      final index = InMemoryLocalSearchIndex();
      await index.indexDocuments([
        ..._fixtureDocuments(),
        SearchDocument(
          id: 'sd_other',
          mediaId: 'other_media',
          kind: SearchDocumentKind.caption,
          text: 'blood in another media file',
          startTime: Duration.zero,
          endTime: const Duration(seconds: 1),
          categoryId: FamilySafetyPolicyCategory.blood.id,
        ),
      ]);

      await index.clearMedia(_mediaId);

      final results = await index.search('blood');
      expect(results, hasLength(1));
      expect(results.single.document.mediaId, 'other_media');
    });
  });
}

const _mediaId = 'media_search_fixture';

List<SearchDocument> _fixtureDocuments() =>
    const FamilySafetySearchIndexer().buildDocuments(
      mediaId: _mediaId,
      evidenceRecords: _evidenceRecords(),
      policyFindings: _policyFindings(),
      detections: [_reviewedDetection()],
    );

List<EvidenceRecord> _evidenceRecords() {
  final vlmProvenance = _provenance(
    providerId: 'local_vllm',
    modelBundleId: 'qwen3.5-vl-local',
    end: const Duration(seconds: 6),
  );
  final captionPayload = {
    'kind': 'parsed_response',
    'caption': 'A tense scene with a visible weapon on a table.',
    'findings': [
      {
        'category': FamilySafetyPolicyCategory.weapons.id,
        'severity': FamilySafetySeverity.high.name,
        'confidence': 0.85,
        'rationale': 'A knife-like weapon is visible.',
        'startTimeMs': 1000,
        'endTimeMs': 3000,
        'regionIds': <String>[],
        'groundingStatus': 'scene_level_only',
        'needsReview': false,
      },
    ],
  };

  const transcript = TranscriptSegment(
    id: 'segment_fight',
    startTime: Duration(seconds: 2),
    endTime: Duration(seconds: 5),
    text: 'They argue loudly before a fight breaks out.',
    words: [],
  );
  return [
    EvidenceRecord(
      id: EvidenceRecord.deterministicId(
        mediaId: _mediaId,
        type: EvidenceType.vlmCaption,
        provenance: vlmProvenance,
        payload: captionPayload,
      ),
      mediaId: _mediaId,
      type: EvidenceType.vlmCaption,
      provenance: vlmProvenance,
      payload: captionPayload,
    ),
    EvidenceRecord.transcriptSpan(
      mediaId: _mediaId,
      segment: transcript,
      provenance: _provenance(providerId: 'local_asr'),
    ),
    EvidenceRecord.modestyParserSignal(
      mediaId: _mediaId,
      timestamp: const Duration(seconds: 12),
      frameNumber: 42,
      categoryId: FamilySafetyPolicyCategory.immodestFemaleClothing.id,
      region: const DetectedRegion(
        label: 'FEMALE_LEGS_EXPOSED',
        confidence: 0.76,
        x: 0.2,
        y: 0.4,
        width: 0.3,
        height: 0.4,
      ),
      provenance: _provenance(providerId: 'local_modesty_parser'),
    ),
  ];
}

List<PolicyFinding> _policyFindings() => [
      _finding(
        id: 'pf_blood',
        category: FamilySafetyPolicyCategory.blood,
        start: const Duration(seconds: 5),
        end: const Duration(seconds: 7),
        rationale: 'Unsafe blood is visible on clothing.',
      ),
      _finding(
        id: 'pf_fight',
        category: FamilySafetyPolicyCategory.violence,
        start: const Duration(seconds: 2),
        end: const Duration(seconds: 5),
        rationale: 'A fight and violent shove are visible.',
      ),
      _finding(
        id: 'pf_weapon',
        category: FamilySafetyPolicyCategory.weapons,
        start: const Duration(seconds: 1),
        end: const Duration(seconds: 3),
        rationale: 'A weapon is held in view.',
      ),
      _finding(
        id: 'pf_legs',
        category: FamilySafetyPolicyCategory.immodestFemaleClothing,
        severity: FamilySafetySeverity.medium,
        start: const Duration(seconds: 12),
        end: const Duration(seconds: 14),
        rationale: 'Revealing clothes show exposed legs.',
        needsReview: true,
      ),
      _finding(
        id: 'pf_nudity',
        category: FamilySafetyPolicyCategory.explicitNudity,
        start: const Duration(seconds: 20),
        end: const Duration(seconds: 21),
        rationale: 'Explicit nudity is visible.',
      ),
    ];

PolicyFinding _finding({
  required String id,
  required FamilySafetyPolicyCategory category,
  required Duration start,
  required Duration end,
  required String rationale,
  FamilySafetySeverity severity = FamilySafetySeverity.high,
  bool needsReview = false,
}) =>
    PolicyFinding(
      id: id,
      mediaId: _mediaId,
      category: category,
      severity: severity,
      confidence: 0.82,
      startTime: start,
      endTime: end,
      recommendedAction:
          PolicyCategory.fromPolicyCategory(category).defaultAction,
      needsReview: needsReview,
      rationale: rationale,
      supportingEvidenceIds: ['ev_$id'],
      sourceModels: const ['qwen3.5-vl-local'],
      origins: const [PolicyFindingOrigin.vlm],
    );

Detection _reviewedDetection() => Detection.visual(
      id: 'det_reviewed_blood',
      mediaId: _mediaId,
      type: ContentType.nsfw,
      startTime: const Duration(seconds: 5),
      endTime: const Duration(seconds: 7),
      confidence: 0.82,
      description: 'Blood reviewed by user.',
    ).copyWith(
      userStatus: DetectionUserStatus.confirmed,
      userNote: 'Confirmed blood detection after review.',
      metadata: {
        'policyCategoryId': FamilySafetyPolicyCategory.blood.id,
        'policySeverity': FamilySafetySeverity.high.name,
        'sourceModels': const ['qwen3.5-vl-local'],
        'supportingEvidenceIds': const ['ev_reviewed'],
      },
    );

EvidenceProvenance _provenance({
  required String providerId,
  String? modelBundleId,
  Duration start = Duration.zero,
  Duration end = const Duration(seconds: 1),
}) =>
    EvidenceProvenance(
      providerId: providerId,
      providerVersion: '1',
      modelBundleId: modelBundleId,
      runtime: 'test',
      inputIds: const ['chunk_1'],
      startTime: start,
      endTime: end,
    );
