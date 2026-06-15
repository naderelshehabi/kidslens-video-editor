import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:kidslens_video_editor/data/models/models.dart';
import 'package:kidslens_video_editor/services/detection/family_safety_prompt_templates.dart';
import 'package:kidslens_video_editor/services/detection/vlm_provider.dart';

void main() {
  group('FamilySafetyPromptTemplates', () {
    test('builds factual caption prompt without policy judgment language', () {
      final prompt = FamilySafetyPromptTemplates.caption(_context()).text;

      expect(prompt, contains('dense, factual caption'));
      expect(prompt, contains('Do not make final policy judgments'));
      expect(prompt, contains('visible people, clothing, actions'));
      expect(prompt, contains('"uncertainty"'));
      expect(prompt, isNot(contains('is this unsafe?')));
    });

    test('builds JSON-only policy prompt with category-specific examples', () {
      final prompt = FamilySafetyPromptTemplates.policy(_context()).text;

      expect(prompt, contains('Return JSON only'));
      expect(prompt, contains('Every unsafe finding must include'));
      expect(prompt, contains('groundingStatus'));
      expect(prompt, contains('regionIds'));
      expect(prompt, contains('explicit_nudity'));
      expect(prompt, contains('kissing_romance'));
      expect(prompt, contains('immodest_female_clothing'));
      expect(prompt, contains('exposureSignals'));
      expect(prompt, contains('weaponState'));
      expect(prompt, contains('alcohol_consumption'));
      expect(prompt, contains('safe beach/swimwear'));
      expect(prompt, contains('bikini or revealing clothing'));
      expect(prompt, contains('exposed female legs'));
      expect(prompt, contains('explicit nudity'));
      expect(prompt, contains('romantic kissing'));
      expect(prompt, contains('sexualized behavior'));
      expect(prompt, contains('sports contact vs violence'));
      expect(prompt, contains('medical blood vs gore'));
      expect(prompt, contains('Halloween makeup vs gore'));
      expect(prompt, contains('weapons/toy weapons ambiguity'));
    });

    test('builds grounding prompt for grounding-capable models', () {
      final prompt = FamilySafetyPromptTemplates.grounding(_context()).text;

      expect(prompt, contains('Use normalized frame-relative boxes'));
      expect(
        prompt,
        contains('Do not return Qwen-style absolute pixel coordinates'),
      );
      expect(
        prompt,
        contains('convert x and width by the supplied frame width'),
      );
      expect(prompt, contains('"groundedRegions"'));
      expect(prompt, contains('"frameId"'));
      expect(prompt, contains('boxes: true'));
      expect(prompt, contains(_frames.first.id));
    });

    test('keeps the example catalog complete and stable', () {
      expect(
        FamilySafetyPromptTemplates.examples.map((example) => example.id),
        containsAllInOrder(const [
          'safe_beach_swimwear',
          'bikini_revealing_clothing',
          'exposed_female_legs',
          'explicit_nudity',
          'romantic_kissing',
          'sexualized_behavior',
          'sports_contact_vs_violence',
          'medical_blood_vs_gore',
          'halloween_makeup_vs_gore',
          'weapons_toy_ambiguity',
        ]),
      );
    });
  });

  group('FamilySafetyVlmOutputSchema', () {
    test('accepts stable mock responses for required prompt examples', () {
      for (final fixture in _validFixtures()) {
        expect(
          FamilySafetyVlmOutputSchema.validate(fixture),
          isEmpty,
          reason: 'fixture should validate: ${fixture['caption']}',
        );
        expect(
          () => const VlmJsonParser().parse(jsonEncode(fixture)),
          returnsNormally,
        );
      }
    });

    test('requires uncertainty list', () {
      final fixture = _baseFixture()..remove('uncertainty');

      expect(
        FamilySafetyVlmOutputSchema.validate(fixture),
        contains('uncertainty list is required'),
      );
      expect(
        () => const VlmJsonParser().parse(jsonEncode(fixture)),
        throwsA(isA<VlmSchemaException>()),
      );
    });

    test('requires rationale for every unsafe finding', () {
      final fixture = _baseFixture();
      (fixture['findings'] as List<Map<String, dynamic>>)
          .first
          .remove('rationale');

      expect(
        FamilySafetyVlmOutputSchema.validate(fixture),
        contains('findings[0].rationale is required'),
      );
    });

    test('requires region IDs for grounded localizable findings', () {
      final fixture = _baseFixture();
      final finding = (fixture['findings'] as List<Map<String, dynamic>>).first;
      finding['groundingStatus'] = 'grounded';
      finding['regionIds'] = <String>[];

      expect(
        FamilySafetyVlmOutputSchema.validate(fixture),
        contains('findings[0].grounded findings require regionIds'),
      );
    });

    test('rejects unknown region IDs referenced by findings', () {
      final fixture = _baseFixture();
      final finding = (fixture['findings'] as List<Map<String, dynamic>>).first;
      finding['groundingStatus'] = 'grounded';
      finding['regionIds'] = <String>['missing_region'];

      expect(
        FamilySafetyVlmOutputSchema.validate(fixture),
        contains('findings[0].regionIds contains unknown id: missing_region'),
      );
    });

    test('validates optional exposure signals and weapon state enums', () {
      final fixture = _baseFixture();
      final finding = (fixture['findings'] as List<Map<String, dynamic>>).first;
      finding['exposureSignals'] = const <String>['bare_legs'];
      finding['weaponState'] = 'toy/prop';

      expect(FamilySafetyVlmOutputSchema.validate(fixture), isEmpty);

      finding['exposureSignals'] = const <String>['unsupported_signal'];
      finding['weaponState'] = 'unknown_state';
      expect(
        FamilySafetyVlmOutputSchema.validate(fixture),
        containsAll([
          'findings[0].exposureSignals contains unsupported signal: unsupported_signal',
          'findings[0].weaponState is not allowed: unknown_state',
        ]),
      );
    });

    test('accepts pixel-coordinate grounded boxes for downstream repair', () {
      final fixture = _baseFixture();
      final region =
          (fixture['groundedRegions'] as List<Map<String, dynamic>>).first;
      region['box'] = const {
        'x': 384,
        'y': 216,
        'width': 576,
        'height': 432,
      };

      expect(FamilySafetyVlmOutputSchema.validate(fixture), isEmpty);
      expect(
        () => const VlmJsonParser().parse(jsonEncode(fixture)),
        returnsNormally,
      );
    });
  });
}

const _mediaId = 'media_prompt_test';

final _chunk = VideoChunk(
  id: VideoChunk.deterministicId(
    mediaId: _mediaId,
    index: 0,
    startTime: Duration.zero,
    endTime: const Duration(seconds: 6),
  ),
  mediaId: _mediaId,
  index: 0,
  startTime: Duration.zero,
  endTime: const Duration(seconds: 6),
);

final _frames = [
  SampledFrameRef(
    id: SampledFrameRef.deterministicId(
      mediaId: _mediaId,
      chunkId: _chunk.id,
      frameIndex: 0,
      timestamp: Duration.zero,
    ),
    mediaId: _mediaId,
    chunkId: _chunk.id,
    frameIndex: 0,
    timestamp: Duration.zero,
  ),
  SampledFrameRef(
    id: SampledFrameRef.deterministicId(
      mediaId: _mediaId,
      chunkId: _chunk.id,
      frameIndex: 1,
      timestamp: const Duration(seconds: 3),
    ),
    mediaId: _mediaId,
    chunkId: _chunk.id,
    frameIndex: 1,
    timestamp: const Duration(seconds: 3),
  ),
];

FamilySafetyPromptContext _context() => FamilySafetyPromptContext(
      mediaId: _mediaId,
      chunk: _chunk,
      frames: _frames,
      modelBundle: _manifest(),
    );

List<Map<String, dynamic>> _validFixtures() => [
      _baseFixture(
        caption: 'People at a public beach wearing ordinary swimwear.',
        category: 'other',
        severity: 'none',
        rationale: 'Ordinary swimwear in a beach context.',
        groundingStatus: 'scene_level_only',
        regionIds: const <String>[],
      ),
      _baseFixture(
        caption: 'A person is wearing a bikini without explicit nudity.',
        category: 'suggestive_content',
        rationale: 'Revealing swimwear is visible, but no explicit nudity.',
        groundingStatus: 'scene_level_only',
        regionIds: const <String>[],
        uncertainty: const <String>['context may affect policy handling'],
      ),
      _baseFixture(),
      _baseFixture(
        caption: 'Explicit nudity is visible.',
        category: 'explicit_nudity',
        severity: 'high',
        rationale: 'Exposed explicit body region is visible.',
      ),
      _baseFixture(
        caption: 'Two adults are romantically kissing.',
        category: 'kissing_romance',
        rationale: 'Brief romantic kissing is visible without nudity.',
        groundingStatus: 'scene_level_only',
        regionIds: const <String>[],
      ),
      _baseFixture(
        caption: 'Sexualized behavior is visible.',
        category: 'sexual_content',
        severity: 'medium',
        rationale: 'Sexualized gestures are visible.',
        groundingStatus: 'scene_level_only',
        regionIds: const <String>[],
      ),
      _baseFixture(
        caption: 'Players collide during a sports match.',
        category: 'violence',
        severity: 'none',
        rationale: 'Contact appears to be ordinary sports play.',
        groundingStatus: 'scene_level_only',
        regionIds: const <String>[],
      ),
      _baseFixture(
        caption: 'Blood is visible in a medical setting.',
        category: 'blood',
        severity: 'medium',
        rationale: 'Visible blood is present in a clinical context.',
      ),
      _baseFixture(
        caption: 'Costume makeup resembles a wound.',
        category: 'gore',
        rationale: 'Makeup resembles injury but may be a costume effect.',
        groundingStatus: 'ambiguous',
        regionIds: const <String>[],
        uncertainty: const <String>['Halloween makeup may be non-realistic'],
      ),
      _baseFixture(
        caption: 'An object resembles a toy weapon.',
        category: 'weapons',
        rationale: 'A gun-like object is visible but may be a toy.',
        uncertainty: const <String>['object may be a toy or prop'],
      ),
    ];

Map<String, dynamic> _baseFixture({
  String caption = 'A female-presenting person has visibly bare legs.',
  String category = 'immodest_female_clothing',
  String severity = 'low',
  String rationale = 'Visible bare legs below short clothing.',
  String groundingStatus = 'grounded',
  List<String> regionIds = const <String>['region_legs'],
  List<String> uncertainty = const <String>[],
}) =>
    {
      'schemaVersion': 1,
      'caption': caption,
      'groundedRegions': [
        {
          'regionId': 'region_legs',
          'label': 'exposed female legs',
          'category': 'immodest_female_clothing',
          'frameId': _frames.first.id,
          'box': {'x': 0.2, 'y': 0.45, 'width': 0.3, 'height': 0.4},
          'maskRef': null,
          'confidence': 0.82,
          'rationale': 'Visible bare legs below short clothing.',
        },
      ],
      'findings': [
        {
          'category': category,
          'severity': severity,
          'confidence': 0.78,
          'startTimeMs': 0,
          'endTimeMs': 3000,
          'rationale': rationale,
          'regionIds': regionIds,
          'groundingStatus': groundingStatus,
          'needsReview': true,
        },
      ],
      'searchTerms': const <String>['family safety fixture'],
      'uncertainty': uncertainty,
    };

ModelBundleManifest _manifest() => const ModelBundleManifest(
      modelId: 'test_prompt_vlm',
      displayName: 'Test Prompt VLM',
      vendor: 'NVIDIA',
      officialSourceRepo: 'nvidia/test-prompt-vlm',
      officialRevision: 'main',
      license: ModelBundleLicense.nvidiaOpenModelLicense,
      commercialUse: CommercialUseStatus.allowed,
      acceptedTermsRequired: false,
      artifactType: ModelBundleArtifactType.officialWeights,
      artifactUri: 'hf://nvidia/test-prompt-vlm',
      sha256: null,
      conversionRecipeId: null,
      runtime: ModelBundleRuntime.cpuLightweight,
      minVramGb: 0,
      recommendedVramGb: 0,
      targetGpuClass: ModelBundleCatalog.targetGpuClass,
      maxValidatedVramGb: ModelBundleCatalog.targetGpuVramGb,
      quantization: ModelBundleQuantization.bf16,
      fitsRtx5070Validated: false,
      supportsVideoInput: true,
      supportsImageInput: true,
      supportsBoundingBoxes: true,
      supportsMasks: false,
      supportsPointLocalization: true,
      maxFramesPerChunk: 8,
      maxContextTokens: 512,
      recommendedChunkSeconds: 4,
      knownFailureModes: ['test fixture'],
      roles: [ModelBundleRole.vlm],
      approvalStatus: ModelBundleApprovalStatus.evaluationOnly,
      reviewNotes: 'test fixture',
    );
