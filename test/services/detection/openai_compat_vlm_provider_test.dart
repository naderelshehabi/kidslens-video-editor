import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:kidslens_video_editor/data/models/models.dart';
import 'package:kidslens_video_editor/services/detection/evidence_store.dart';
import 'package:kidslens_video_editor/services/detection/vlm_provider.dart';
import 'package:kidslens_video_editor/services/detection/vlm_provider_factory.dart';

void main() {
  group('OpenAiCompatVlmProvider', () {
    test('sends one base64 JPEG data URL per frame in sampled order', () async {
      final server = await _LoopbackOpenAiServer.start(
        (requestIndex, body) {
          expect(requestIndex, 1);
          expect(body['model'], 'qwen3.5-vl-local');
          expect(body['temperature'], 0);
          expect(body['max_tokens'], 64);
          final responseFormat =
              body['response_format'] as Map<String, dynamic>;
          expect(responseFormat['type'], 'json_schema');

          final messages =
              (body['messages'] as List<dynamic>).cast<Map<String, dynamic>>();
          final user = messages[1];
          final content =
              (user['content'] as List<dynamic>).cast<Map<String, dynamic>>();
          expect(content, hasLength(3));
          expect(content[0]['type'], 'text');
          expect(content[0]['text'], contains('Return family safety JSON'));
          final firstImageUrl = content[1]['image_url'] as Map<String, dynamic>;
          final secondImageUrl =
              content[2]['image_url'] as Map<String, dynamic>;
          expect(
            firstImageUrl['url'],
            'data:image/jpeg;base64,${base64Encode(_jpegBytes(0))}',
          );
          expect(
            secondImageUrl['url'],
            'data:image/jpeg;base64,${base64Encode(_jpegBytes(1))}',
          );
          return _openAiEnvelope(_validRawResponse());
        },
      );
      addTearDown(server.close);

      final provider = OpenAiCompatVlmProvider(
        endpoint: server.endpoint,
        runtimeProfile: LocalRuntimeProfile.byId(LocalRuntimeId.cudaLlamaCpp),
        modelAlias: 'qwen3.5-vl-local',
      );

      final response = await provider.analyzeSegment(_request());

      expect(response.providerId, 'local_llamacpp_openai_compat');
      expect(response.caption, 'A routine family scene.');
      expect(server.requestCount, 1);
    });

    test('parses OpenAI envelope and persists hash-addressed evidence',
        () async {
      final server = await _LoopbackOpenAiServer.start(
        (_, __) => _openAiEnvelope(_validRawResponse()),
      );
      addTearDown(server.close);
      final storeFile = await _tempEvidenceFile();
      final store = JsonEvidenceStore(storeFile);
      final request = _request(evidenceStore: store);
      final firstImageHash = request.frameImages.first.sha256;

      final response = await OpenAiCompatVlmProvider(
        endpoint: server.endpoint,
        runtimeProfile: LocalRuntimeProfile.byId(LocalRuntimeId.cudaLlamaCpp),
        modelAlias: 'test-model',
      ).analyzeSegment(request);
      final persisted = await store.readAll(mediaId: _mediaId);

      expect(response.findings, hasLength(1));
      expect(persisted, hasLength(2));
      expect(
        persisted.first.provenance.inputIds,
        contains('${request.frames.first.id}:sha256:$firstImageHash'),
      );
    });

    test('retries once with repair prompt after schema validation failure',
        () async {
      final server = await _LoopbackOpenAiServer.start(
        (requestIndex, body) {
          if (requestIndex == 1) {
            return _openAiEnvelope('{"caption": ""}');
          }
          final messages =
              (body['messages'] as List<dynamic>).cast<Map<String, dynamic>>();
          final user = messages[1];
          final content =
              (user['content'] as List<dynamic>).cast<Map<String, dynamic>>();
          expect(
            content.first['text'],
            contains('The previous response failed validation'),
          );
          expect(content.first['text'], contains('{"caption": ""}'));
          return _openAiEnvelope(_validRawResponse());
        },
      );
      addTearDown(server.close);

      final response = await OpenAiCompatVlmProvider(
        endpoint: server.endpoint,
        runtimeProfile: LocalRuntimeProfile.byId(LocalRuntimeId.cudaLlamaCpp),
        modelAlias: 'test-model',
      ).analyzeSegment(_request());

      expect(response.caption, 'A routine family scene.');
      expect(response.schemaRepairWarnings, hasLength(1));
      expect(server.requestCount, 2);
    });

    test('rejects non-loopback endpoints', () {
      expect(
        () => OpenAiCompatVlmProvider(
          endpoint: Uri.parse('https://api.openai.com/v1/chat/completions'),
          runtimeProfile: LocalRuntimeProfile.byId(LocalRuntimeId.cudaLlamaCpp),
          modelAlias: 'remote-model',
          client: _NoopClient(),
        ),
        throwsA(isA<VlmProviderException>()),
      );
    });

    test('requires JPEG payloads for image-frame requests', () async {
      final server = await _LoopbackOpenAiServer.start(
        (_, __) => _openAiEnvelope(_validRawResponse()),
      );
      addTearDown(server.close);

      await expectLater(
        OpenAiCompatVlmProvider(
          endpoint: server.endpoint,
          runtimeProfile: LocalRuntimeProfile.byId(LocalRuntimeId.cudaLlamaCpp),
          modelAlias: 'test-model',
        ).analyzeSegment(_request(frameImages: const <VlmFrameImage>[])),
        throwsA(
          isA<VlmProviderException>().having(
            (error) => error.message,
            'message',
            contains('one JPEG payload per sampled frame'),
          ),
        ),
      );
    });
  });

  group('VlmProviderFactory', () {
    test('maps llama.cpp runtimes to OpenAI-compatible provider', () {
      final provider = VlmProviderFactory(
        httpClientFactory: _NoopClient.new,
      ).forRuntime(
        runtimeProfile: LocalRuntimeProfile.byId(LocalRuntimeId.vulkanLlamaCpp),
        endpoint: Uri.parse('http://127.0.0.1:8000'),
        modelAlias: 'gemma-local',
      );

      expect(provider, isA<OpenAiCompatVlmProvider>());
    });
  });
}

const _mediaId = 'media_openai_compat_vlm_test';

String _openAiEnvelope(String content) => jsonEncode({
      'choices': [
        {
          'message': {'content': content},
        },
      ],
    });

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
          'regionIds': <String>['region_1'],
          'groundingStatus': 'grounded',
          'needsReview': true,
        },
      ],
      'groundedRegions': [
        {
          'regionId': 'region_1',
          'label': 'exposed legs',
          'category': 'immodest_female_clothing',
          'frameId': _frames(2).first.id,
          'box': {'x': 0.2, 'y': 0.4, 'width': 0.3, 'height': 0.5},
          'maskRef': null,
          'confidence': 0.81,
          'rationale': 'Bare legs are visible in the frame.',
        },
      ],
      'searchTerms': <String>['routine family scene'],
      'uncertainty': <String>[],
    });

VideoSegmentRequest _request({
  List<VlmFrameImage>? frameImages,
  EvidenceStore? evidenceStore,
}) {
  final frames = _frames(2);
  return VideoSegmentRequest(
    mediaId: _mediaId,
    chunk: _chunk(),
    frames: frames,
    frameImages: frameImages ?? _frameImages(frames),
    modelBundle: _manifest(),
    runtimeProfile: LocalRuntimeProfile.byId(LocalRuntimeId.cudaLlamaCpp),
    prompt: 'Return family safety JSON.',
    maxOutputTokens: 64,
    frameWidth: 640,
    frameHeight: 360,
    timeout: const Duration(seconds: 2),
    evidenceStore: evidenceStore,
  );
}

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

List<VlmFrameImage> _frameImages(List<SampledFrameRef> frames) => [
      for (var index = 0; index < frames.length; index++)
        VlmFrameImage(
          frameRef: frames[index],
          jpegBytes: _jpegBytes(index),
          width: 640,
          height: 360,
          sha256: sha256.convert(_jpegBytes(index)).toString(),
        ),
    ];

List<int> _jpegBytes(int index) => [0xff, 0xd8, 0xff, index, 0xff, 0xd9];

ModelBundleManifest _manifest() => const ModelBundleManifest(
      modelId: 'test_openai_compat_vlm_model',
      displayName: 'Test OpenAI-compatible VLM Model',
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
      runtime: ModelBundleRuntime.llamaCppServer,
      minVramGb: 0,
      recommendedVramGb: 0,
      targetGpuClass: ModelBundleCatalog.targetGpuClass,
      maxValidatedVramGb: ModelBundleCatalog.targetGpuVramGb,
      quantization: ModelBundleQuantization.q4KM,
      fitsRtx5070Validated: false,
      supportsVideoInput: true,
      supportsImageInput: true,
      supportsBoundingBoxes: true,
      supportsMasks: false,
      supportsPointLocalization: false,
      maxFramesPerChunk: 8,
      maxContextTokens: 512,
      recommendedChunkSeconds: 4,
      knownFailureModes: ['test fixture'],
      roles: [ModelBundleRole.vlm],
      approvalStatus: ModelBundleApprovalStatus.evaluationOnly,
      reviewNotes: 'test fixture',
    );

Future<File> _tempEvidenceFile() async {
  final dir =
      await Directory.systemTemp.createTemp('kidslens_openai_compat_vlm_');
  addTearDown(() async {
    if (dir.existsSync()) {
      await dir.delete(recursive: true);
    }
  });
  return File('${dir.path}${Platform.pathSeparator}evidence.json');
}

class _LoopbackOpenAiServer {
  _LoopbackOpenAiServer._(this._server);

  final HttpServer _server;
  int requestCount = 0;

  Uri get endpoint => Uri.parse('http://127.0.0.1:${_server.port}');

  static Future<_LoopbackOpenAiServer> start(
    FutureOr<String> Function(int requestIndex, Map<String, dynamic> body)
        handler,
  ) async {
    final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    final wrapper = _LoopbackOpenAiServer._(server);
    server.listen((request) async {
      wrapper.requestCount++;
      expect(request.method, 'POST');
      expect(request.uri.path, '/v1/chat/completions');
      final bodyText = await utf8.decoder.bind(request).join();
      final body = jsonDecode(bodyText) as Map<String, dynamic>;
      final responseBody = await handler(wrapper.requestCount, body);
      request.response
        ..statusCode = HttpStatus.ok
        ..headers.set(
          HttpHeaders.contentTypeHeader,
          'application/json; charset=utf-8',
        )
        ..write(responseBody);
      await request.response.close();
    });
    return wrapper;
  }

  Future<void> close() async {
    await _server.close(force: true);
  }
}

class _NoopClient extends http.BaseClient {
  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) {
    throw UnimplementedError();
  }
}
