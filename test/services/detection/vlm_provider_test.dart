import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:kidslens_video_editor/data/models/models.dart';
import 'package:kidslens_video_editor/jobs/cancellation_token.dart';
import 'package:kidslens_video_editor/services/detection/evidence_store.dart';
import 'package:kidslens_video_editor/services/detection/vlm_provider.dart';

void main() {
  group('VlmJsonParser', () {
    test('accepts valid JSON responses', () {
      final parsed = const VlmJsonParser().parse(_validRawResponse());

      expect(parsed.json['caption'], 'A routine family scene.');
      expect(parsed.json['findings'], hasLength(1));
      expect(parsed.repairWarnings, isEmpty);
    });

    test('rejects invalid JSON responses', () {
      expect(
        () => const VlmJsonParser().parse('{not json'),
        throwsA(isA<FormatException>()),
      );
    });

    test('rejects responses with missing required fields', () {
      expect(
        () => const VlmJsonParser().parse('{"findings": []}'),
        throwsA(isA<VlmSchemaException>()),
      );
    });

    test('repairs only deterministic wrappers and trailing commas', () {
      final parsed = const VlmJsonParser().parse('''
The model returned:
```json
{
  "schemaVersion": 1,
  "caption": "No unsafe content.",
  "findings": [],
  "groundedRegions": [],
  "searchTerms": [],
  "uncertainty": [],
}
```
done.
''');

      expect(parsed.json['caption'], 'No unsafe content.');
      expect(
        parsed.repairWarnings,
        containsAll([
          'extracted JSON object from surrounding text',
          'removed trailing commas',
        ]),
      );
    });
  });

  group('VLM providers', () {
    test('mock provider produces and persists structured chunk evidence',
        () async {
      final storeFile = await _tempEvidenceFile();
      final store = JsonEvidenceStore(storeFile);
      final provider = MockVlmProvider(rawResponse: _validRawResponse());

      final response = await provider.analyzeSegment(
        _request(evidenceStore: store),
      );
      final persisted = await store.readAll(mediaId: _mediaId);

      expect(response.providerId, 'mock_vlm');
      expect(response.hasFindings, isTrue);
      expect(response.evidenceRecords, hasLength(2));
      expect(persisted, hasLength(2));
      expect(
        persisted.map((record) => record.type),
        containsAll([EvidenceType.vlmPolicyJson, EvidenceType.vlmCaption]),
      );
      expect(
        persisted
            .firstWhere((record) => record.type == EvidenceType.vlmCaption)
            .payload['findings'],
        isNotEmpty,
      );
    });

    test('local HTTP provider rejects non-local runtime endpoints', () {
      expect(
        () => VllmVlmProvider(
          endpoint: Uri.parse('https://api.openai.com/v1/chat/completions'),
          client: _FakeHttpClient((_) => http.Response('{}', 200)),
        ),
        throwsA(isA<VlmProviderException>()),
      );
    });

    test('local HTTP provider accepts loopback adapters and parses responses',
        () async {
      final client = _FakeHttpClient(
        (_) => http.Response(_validRawResponse(), 200),
      );
      final provider = TransformersHelperVlmProvider(
        endpoint: Uri.parse('http://127.0.0.1:8000/analyze'),
        client: client,
      );

      final response = await provider.analyzeSegment(_request());

      expect(response.providerId, 'local_transformers_helper');
      expect(response.findings, hasLength(1));
      expect(client.requestCount, 1);
      final sentPayload = jsonDecode(client.lastBody!) as Map<String, dynamic>;
      expect(sentPayload['mediaId'], _mediaId);
    });

    test('cancels pending provider work cooperatively', () async {
      final token = CancellationToken();
      final future = const MockVlmProvider(
        delay: Duration(seconds: 1),
      ).analyzeSegment(_request(cancellationToken: token));

      token.cancel();

      await expectLater(future, throwsA(isA<CancelledException>()));
    });

    test('enforces model manifest request limits', () async {
      const provider = MockVlmProvider();

      await expectLater(
        provider.analyzeSegment(
          _request(
            modelBundle: _manifest(
              maxFramesPerChunk: 1,
              maxContextTokens: 16,
              supportsImageInput: false,
            ),
            frames: _frames(2),
            maxOutputTokens: 32,
            frameWidth: 0,
          ),
        ),
        throwsA(
          isA<VlmProviderException>()
              .having(
                (error) => error.message,
                'message',
                contains('model does not support image-frame input'),
              )
              .having(
                (error) => error.message,
                'message',
                contains('request has 2 frames'),
              )
              .having(
                (error) => error.message,
                'message',
                contains('request max output tokens exceed model context'),
              )
              .having(
                (error) => error.message,
                'message',
                contains('frame resolution must be positive'),
              ),
        ),
      );
    });

    test('enforces video input support from model manifests', () async {
      await expectLater(
        const MockVlmProvider().analyzeSegment(
          _request(
            inputMode: VlmInputMode.videoSegment,
            modelBundle: _manifest(supportsVideoInput: false),
          ),
        ),
        throwsA(
          isA<VlmProviderException>().having(
            (error) => error.message,
            'message',
            contains('model does not support video-segment input'),
          ),
        ),
      );
    });
  });
}

const _mediaId = 'media_vlm_test';

String _validRawResponse() => jsonEncode({
      'schemaVersion': 1,
      'caption': 'A routine family scene.',
      'findings': [
        {
          'category': 'immodest_female_clothing',
          'severity': 'low',
          'confidence': 0.78,
          'rationale': 'The model observed exposed legs but no nudity.',
          'startTimeMs': 0,
          'endTimeMs': 1000,
          'regionIds': <String>[],
          'groundingStatus': 'scene_level_only',
          'needsReview': true,
        },
      ],
      'groundedRegions': <Map<String, dynamic>>[],
      'searchTerms': <String>['routine family scene'],
      'uncertainty': <String>[],
    });

VideoSegmentRequest _request({
  ModelBundleManifest? modelBundle,
  List<SampledFrameRef>? frames,
  VlmInputMode inputMode = VlmInputMode.imageFrames,
  int maxOutputTokens = 64,
  int? frameWidth = 640,
  int? frameHeight = 360,
  CancellationToken? cancellationToken,
  EvidenceStore? evidenceStore,
}) =>
    VideoSegmentRequest(
      mediaId: _mediaId,
      chunk: _chunk(),
      frames: frames ?? _frames(2),
      modelBundle: modelBundle ?? _manifest(),
      runtimeProfile: LocalRuntimeProfile.byId(LocalRuntimeId.cpuLightweight),
      prompt: 'Return family safety JSON.',
      inputMode: inputMode,
      maxOutputTokens: maxOutputTokens,
      frameWidth: frameWidth,
      frameHeight: frameHeight,
      timeout: const Duration(seconds: 2),
      cancellationToken: cancellationToken,
      evidenceStore: evidenceStore,
    );

VideoChunk _chunk() {
  const startTime = Duration.zero;
  const endTime = Duration(seconds: 4);
  return VideoChunk(
    id: VideoChunk.deterministicId(
      mediaId: _mediaId,
      index: 0,
      startTime: startTime,
      endTime: endTime,
    ),
    mediaId: _mediaId,
    index: 0,
    startTime: startTime,
    endTime: endTime,
  );
}

List<SampledFrameRef> _frames(int count) {
  final chunk = _chunk();
  return [
    for (var index = 0; index < count; index++)
      SampledFrameRef(
        id: SampledFrameRef.deterministicId(
          mediaId: _mediaId,
          chunkId: chunk.id,
          frameIndex: index,
          timestamp: Duration(milliseconds: index * 500),
        ),
        mediaId: _mediaId,
        chunkId: chunk.id,
        frameIndex: index,
        timestamp: Duration(milliseconds: index * 500),
        cachePath: 'frames/$index.jpg',
      ),
  ];
}

ModelBundleManifest _manifest({
  int maxFramesPerChunk = 8,
  int maxContextTokens = 512,
  bool supportsImageInput = true,
  bool supportsVideoInput = true,
}) =>
    ModelBundleManifest(
      modelId: 'test_vlm_model',
      displayName: 'Test VLM Model',
      vendor: 'NVIDIA',
      officialSourceRepo: 'nvidia/test-vlm-model',
      officialRevision: 'main',
      license: ModelBundleLicense.nvidiaOpenModelLicense,
      commercialUse: CommercialUseStatus.allowed,
      acceptedTermsRequired: false,
      artifactType: ModelBundleArtifactType.officialWeights,
      artifactUri: 'hf://nvidia/test-vlm-model',
      sha256: null,
      conversionRecipeId: null,
      runtime: ModelBundleRuntime.cpuLightweight,
      minVramGb: 0,
      recommendedVramGb: 0,
      targetGpuClass: ModelBundleCatalog.targetGpuClass,
      maxValidatedVramGb: ModelBundleCatalog.targetGpuVramGb,
      quantization: ModelBundleQuantization.bf16,
      fitsRtx5070Validated: false,
      supportsVideoInput: supportsVideoInput,
      supportsImageInput: supportsImageInput,
      supportsBoundingBoxes: false,
      supportsMasks: false,
      supportsPointLocalization: false,
      maxFramesPerChunk: maxFramesPerChunk,
      maxContextTokens: maxContextTokens,
      recommendedChunkSeconds: 4,
      knownFailureModes: const ['test fixture'],
      roles: const [ModelBundleRole.vlm],
      approvalStatus: ModelBundleApprovalStatus.evaluationOnly,
      reviewNotes: 'test fixture',
    );

Future<File> _tempEvidenceFile() async {
  final dir = await Directory.systemTemp.createTemp('kidslens_vlm_provider_');
  addTearDown(() async {
    if (dir.existsSync()) {
      await dir.delete(recursive: true);
    }
  });
  return File('${dir.path}${Platform.pathSeparator}evidence.json');
}

class _FakeHttpClient extends http.BaseClient {
  _FakeHttpClient(this.handler);

  final FutureOr<http.Response> Function(http.BaseRequest request) handler;
  int requestCount = 0;
  String? lastBody;

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    requestCount++;
    lastBody = utf8.decode(await request.finalize().toBytes());
    final response = await handler(request);
    return http.StreamedResponse(
      Stream.value(response.bodyBytes),
      response.statusCode,
      contentLength: response.contentLength,
      request: request,
      headers: response.headers,
      isRedirect: response.isRedirect,
      persistentConnection: response.persistentConnection,
      reasonPhrase: response.reasonPhrase,
    );
  }
}
