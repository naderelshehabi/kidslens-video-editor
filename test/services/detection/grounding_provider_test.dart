import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:kidslens_video_editor/data/models/models.dart';
import 'package:kidslens_video_editor/jobs/cancellation_token.dart';
import 'package:kidslens_video_editor/services/detection/evidence_replay_service.dart';
import 'package:kidslens_video_editor/services/detection/evidence_store.dart';
import 'package:kidslens_video_editor/services/detection/grounding_provider.dart';
import 'package:kidslens_video_editor/services/detection/vlm_provider.dart';

void main() {
  group('VlmNativeGroundingProvider', () {
    test('parses VLM-native boxes and persists grounded evidence', () async {
      final storeFile = await _tempEvidenceFile();
      final store = JsonEvidenceStore(storeFile);
      final result = await const VlmNativeGroundingProvider().ground(
        _request(
          evidenceStore: store,
          vlmResponse: _vlmResponse(
            groundedRegions: [
              {
                'regionId': 'region_legs',
                'label': 'exposed female legs',
                'category': 'immodest_female_clothing',
                'frameId': _frames.first.id,
                'box': {
                  'x': 0.2,
                  'y': 0.45,
                  'width': 0.3,
                  'height': 0.4,
                },
                'confidence': 0.82,
                'rationale': 'Visible bare legs below short clothing.',
              },
            ],
          ),
        ),
      );
      final persisted = await store.readAll(type: EvidenceType.groundedRegion);

      expect(result.status, GroundingStatus.grounded);
      expect(result.regions, hasLength(1));
      expect(result.evidenceRecords, hasLength(1));
      expect(persisted, hasLength(1));
      expect(
        result.regions.single.box?.frameAspectRatio,
        closeTo(16 / 9, 0.0001),
      );
      expect(
        persisted.single.payload['categoryId'],
        'immodest_female_clothing',
      );
    });

    test('reports scene-level status when the VLM emits no regions', () async {
      final result = await const VlmNativeGroundingProvider().ground(
        _request(
          vlmResponse: _vlmResponse(),
        ),
      );

      expect(result.status, GroundingStatus.sceneLevelOnly);
      expect(result.regions, isEmpty);
      expect(result.warnings.single, contains('groundedRegions'));
    });

    test('reports unsupported status when manifest cannot localize', () async {
      final result = await const VlmNativeGroundingProvider().ground(
        _request(
          modelBundle: _manifest(
            supportsBoundingBoxes: false,
            supportsPointLocalization: false,
          ),
          vlmResponse: _vlmResponse(groundedRegions: const []),
        ),
      );

      expect(result.status, GroundingStatus.unsupportedByModel);
      expect(result.warnings.single, contains('does not advertise'));
    });

    test('skips invalid zero-area boxes with warnings', () async {
      final result = await const VlmNativeGroundingProvider().ground(
        _request(
          vlmResponse: _vlmResponse(
            groundedRegions: [
              {
                'regionId': 'bad_region',
                'label': 'knife',
                'category': 'weapon',
                'frameId': _frames.first.id,
                'box': {'x': 1, 'y': 0, 'width': 0.2, 'height': 0.2},
                'confidence': 0.7,
                'rationale': 'Object at edge.',
              },
            ],
          ),
        ),
      );

      expect(result.status, GroundingStatus.ambiguous);
      expect(result.regions, isEmpty);
      expect(result.warnings.single, contains('zero area'));
    });
  });

  group('legacy grounding providers', () {
    test('converts NudeNet and modesty regions into grounded evidence',
        () async {
      final nudenet = await const LegacyNudenetGroundingProvider().ground(
        _request(
          legacyNudenetRegionsByFrame: [
            [
              const DetectedRegion(
                label: 'FEMALE_BREAST_EXPOSED',
                confidence: 0.91,
                x: 0.1,
                y: 0.1,
                width: 0.2,
                height: 0.2,
              ),
            ],
          ],
        ),
      );
      final modesty = await const ModestyParserGroundingProvider().ground(
        _request(
          modestyParserRegionsByFrame: [
            [
              const DetectedRegion(
                label: 'exposed_female_legs',
                confidence: 0.7,
                x: 0.3,
                y: 0.4,
                width: 0.2,
                height: 0.4,
              ),
            ],
          ],
        ),
      );

      expect(nudenet.status, GroundingStatus.grounded);
      expect(nudenet.regions.single.categoryId, contains('legacy_nudenet'));
      expect(modesty.status, GroundingStatus.grounded);
      expect(modesty.regions.single.categoryId, 'exposed_female_legs');
    });
  });

  group('LocateAnythingGroundingProvider', () {
    test('is blocked unless explicitly enabled for evaluation', () async {
      await expectLater(
        const LocateAnythingGroundingProvider().ground(
          _request(
            modelBundle: ModelBundleCatalog.byModelId(
              'nvidia_locateanything_3b',
            ),
            rawGroundingResponse: '<box> 100, 200, 400, 600 </box>',
          ),
        ),
        throwsA(isA<GroundingProviderException>()),
      );
    });

    test('parses evaluation-only boxes and point tokens', () async {
      final result = await const LocateAnythingGroundingProvider().ground(
        _request(
          modelBundle: ModelBundleCatalog.byModelId('nvidia_locateanything_3b'),
          allowEvaluationOnlyModels: true,
          groundingPrompts: const ['blood', 'knife'],
          rawGroundingResponse:
              '<box> 100, 200, 400, 600 </box> <point> 500, 500 </point>',
        ),
      );

      expect(result.status, GroundingStatus.grounded);
      expect(result.regions, hasLength(2));
      expect(result.regions.first.label, 'blood');
      expect(result.regions.first.box?.x, 0.1);
      expect(result.regions.first.box?.height, closeTo(0.4, 0.0001));
      expect(result.regions.last.label, 'knife');
      expect(result.regions.last.box?.width, 0.02);
      expect(
        result.regions.first.metadata['commercialProductionAllowed'],
        isFalse,
      );
    });

    test('validates benchmark and failure-mode evaluation records', () {
      const record = LocateAnythingEvaluationRecord(
        licenseVerified: true,
        localRuntimeValidated: true,
        promptsTested: [
          'exposed female legs',
          'blood',
          'knife',
          'gun',
          'exposed chest',
          'bare abdomen',
        ],
        decodingModesBenchmarked: LocateAnythingDecodingMode.values,
        meanBoxIouByPrompt: {'blood': 0.72},
        failureModes: [
          'ambiguous clothing',
          'multiple people',
          'occlusion',
          'blur',
          'low light',
        ],
      );

      expect(record.validate(), isEmpty);
      expect(record.productionEligible, isTrue);
    });
  });

  test('grounded region evidence replays into visual detections', () async {
    final result = await const VlmNativeGroundingProvider().ground(
      _request(
        vlmResponse: _vlmResponse(
          groundedRegions: [
            {
              'label': 'blood',
              'category': 'blood',
              'frameId': _frames.first.id,
              'box': {'x': 0.1, 'y': 0.2, 'width': 0.3, 'height': 0.4},
              'confidence': 0.9,
              'rationale': 'Visible red fluid.',
            },
          ],
        ),
      ),
    );

    final analysis = EvidenceReplayService().replayAnalysis(
      analysisId: 'analysis-a',
      mediaId: _mediaId,
      records: result.evidenceRecords,
      options: const EvidenceReplayOptions(mediaDuration: Duration(seconds: 4)),
    );

    final replayedRegion =
        analysis.frameResults.single.visualContent!.detectedRegions.single;
    expect(replayedRegion.label, 'blood');
    expect(replayedRegion.x, 0.1);
    expect(replayedRegion.y, 0.2);
    expect(replayedRegion.width, 0.3);
    expect(replayedRegion.height, 0.4);
  });

  test('cancels pending grounding work before provider execution', () async {
    final token = CancellationToken()..cancel();

    await expectLater(
      const VlmNativeGroundingProvider().ground(
        _request(cancellationToken: token),
      ),
      throwsA(isA<CancelledException>()),
    );
  });
}

const _mediaId = 'media_grounding_test';

final _chunk = VideoChunk(
  id: VideoChunk.deterministicId(
    mediaId: _mediaId,
    index: 0,
    startTime: Duration.zero,
    endTime: const Duration(seconds: 4),
  ),
  mediaId: _mediaId,
  index: 0,
  startTime: Duration.zero,
  endTime: const Duration(seconds: 4),
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
      timestamp: const Duration(seconds: 1),
    ),
    mediaId: _mediaId,
    chunkId: _chunk.id,
    frameIndex: 1,
    timestamp: const Duration(seconds: 1),
  ),
];

GroundingRequest _request({
  ModelBundleManifest? modelBundle,
  VlmSegmentResponse? vlmResponse,
  String? rawGroundingResponse,
  List<String> groundingPrompts = const <String>[],
  List<List<DetectedRegion>> legacyNudenetRegionsByFrame =
      const <List<DetectedRegion>>[],
  List<List<DetectedRegion>> modestyParserRegionsByFrame =
      const <List<DetectedRegion>>[],
  bool allowEvaluationOnlyModels = false,
  EvidenceStore? evidenceStore,
  CancellationToken? cancellationToken,
}) =>
    GroundingRequest(
      mediaId: _mediaId,
      chunk: _chunk,
      frames: _frames,
      modelBundle: modelBundle ?? _manifest(),
      runtimeProfile: LocalRuntimeProfile.byId(LocalRuntimeId.cpuLightweight),
      vlmResponse: vlmResponse,
      rawGroundingResponse: rawGroundingResponse,
      groundingPrompts: groundingPrompts,
      legacyNudenetRegionsByFrame: legacyNudenetRegionsByFrame,
      modestyParserRegionsByFrame: modestyParserRegionsByFrame,
      frameWidth: 1920,
      frameHeight: 1080,
      allowEvaluationOnlyModels: allowEvaluationOnlyModels,
      evidenceStore: evidenceStore,
      cancellationToken: cancellationToken,
    );

VlmSegmentResponse _vlmResponse({
  List<Map<String, dynamic>>? groundedRegions,
}) =>
    VlmSegmentResponse(
      providerId: 'mock_vlm',
      providerVersion: '1',
      rawResponse: '{}',
      parsedJson: {
        'caption': 'test',
        'findings': const <Map<String, dynamic>>[],
        if (groundedRegions != null) 'groundedRegions': groundedRegions,
      },
      evidenceRecords: [
        EvidenceRecord(
          id: 'ev_vlm',
          mediaId: _mediaId,
          type: EvidenceType.vlmPolicyJson,
          provenance: const EvidenceProvenance(
            providerId: 'mock_vlm',
            providerVersion: '1',
            runtime: 'cpu_lightweight',
            inputIds: ['frame'],
            startTime: Duration.zero,
            endTime: Duration(seconds: 4),
          ),
          payload: const {'raw': true},
          chunkId: _chunk.id,
        ),
      ],
    );

ModelBundleManifest _manifest({
  bool supportsBoundingBoxes = true,
  bool supportsPointLocalization = true,
}) =>
    ModelBundleManifest(
      modelId: 'test_grounding_vlm',
      displayName: 'Test Grounding VLM',
      vendor: 'NVIDIA',
      officialSourceRepo: 'nvidia/test-grounding-vlm',
      officialRevision: 'main',
      license: ModelBundleLicense.nvidiaOpenModelLicense,
      commercialUse: CommercialUseStatus.allowed,
      acceptedTermsRequired: false,
      artifactType: ModelBundleArtifactType.officialWeights,
      artifactUri: 'hf://nvidia/test-grounding-vlm',
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
      supportsBoundingBoxes: supportsBoundingBoxes,
      supportsMasks: false,
      supportsPointLocalization: supportsPointLocalization,
      maxFramesPerChunk: 8,
      maxContextTokens: 512,
      recommendedChunkSeconds: 4,
      knownFailureModes: const ['test fixture'],
      roles: const [ModelBundleRole.vlm],
      approvalStatus: ModelBundleApprovalStatus.evaluationOnly,
      reviewNotes: 'test fixture',
    );

Future<File> _tempEvidenceFile() async {
  final dir = await Directory.systemTemp.createTemp('kidslens_grounding_');
  addTearDown(() async {
    if (dir.existsSync()) {
      await dir.delete(recursive: true);
    }
  });
  return File('${dir.path}${Platform.pathSeparator}evidence.json');
}
