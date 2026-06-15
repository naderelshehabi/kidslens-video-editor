import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kidslens_video_editor/data/models/models.dart';
import 'package:kidslens_video_editor/jobs/cancellation_token.dart';
import 'package:kidslens_video_editor/native/bindings/ffmpeg_bindings.dart';
import 'package:kidslens_video_editor/services/detection/analysis_stage_host.dart';
import 'package:kidslens_video_editor/services/detection/chunk_planner.dart';
import 'package:kidslens_video_editor/services/detection/detection_pipeline.dart';
import 'package:kidslens_video_editor/services/detection/detection_pipeline_profile.dart';
import 'package:kidslens_video_editor/services/detection/evidence_store.dart';
import 'package:kidslens_video_editor/services/detection/llama_server_manager.dart';
import 'package:kidslens_video_editor/services/detection/local_runtime_manager.dart';
import 'package:kidslens_video_editor/services/detection/vlm_provider.dart';
import 'package:kidslens_video_editor/services/detection/vlm_provider_factory.dart';
import 'package:kidslens_video_editor/services/detection/vss_family_safety_pipeline.dart';
import 'package:kidslens_video_editor/services/frame_sampling_service.dart';
import 'package:kidslens_video_editor/services/media_service.dart';
import 'package:kidslens_video_editor/services/model_manager_service.dart';
import 'package:path/path.dart' as p;

void main() {
  group('VssFamilySafetyPipeline', () {
    late Directory tempDir;

    setUp(() async {
      tempDir = await Directory.systemTemp.createTemp('kidslens_vss_test_');
    });

    tearDown(() async {
      if (tempDir.existsSync()) {
        await tempDir.delete(recursive: true);
      }
    });

    test('runs VLM chunks, persists evidence, checkpoint, timeline, and index',
        () async {
      final host = _FakeStageHost();
      final provider = _CountingVlmProvider(_unsafeRawResponse);
      final detections = <Detection>[];
      UnifiedTimeline? timeline;
      final pipeline = _pipeline(
        tempDir: tempDir,
        host: host,
        provider: provider,
      );

      final progress = await pipeline
          .analyze(
            DetectionPipelineRequest(
              mediaPath: 'fixture.mp4',
              mediaId: 'media-1',
              settings: _settings(),
              onDetectionsBuilt: detections.addAll,
              onTimelineBuilt: (value) => timeline = value,
            ),
          )
          .toList();

      expect(progress.last.stepName, 'Analysis complete');
      expect(provider.calls, 2);
      expect(detections, isNotEmpty);
      expect(timeline, isNotNull);

      final evidence = await JsonEvidenceStore(
        File('${tempDir.path}/evidence.json'),
      ).readAll(mediaId: 'media-1');
      expect(
        evidence
            .where((record) => record.type == EvidenceType.vlmPolicyJson)
            .length,
        2,
      );
      expect(
        evidence.where((record) => record.type == EvidenceType.vlmCaption),
        isNotEmpty,
      );

      final manifest = jsonDecode(
        File('${tempDir.path}/analysis_run_manifest.json').readAsStringSync(),
      ) as Map<String, dynamic>;
      expect(manifest['pipelineId'], DetectionPipelineIds.vssFamilySafetyV1);
      expect(manifest['chunks'], hasLength(2));

      final checkpoint = jsonDecode(
        File('${tempDir.path}/vss_checkpoint.json').readAsStringSync(),
      ) as Map<String, dynamic>;
      expect(checkpoint['completedChunkIds'], hasLength(2));
      expect(
        File('${tempDir.path}/family_safety_search_index.json').existsSync(),
        isTrue,
      );
      final searchIndex = jsonDecode(
        File('${tempDir.path}/family_safety_search_index.json')
            .readAsStringSync(),
      ) as List<dynamic>;
      expect(searchIndex, isNotEmpty);
      expect(
        (searchIndex.first as Map<String, dynamic>)['embedding'],
        hasLength(64),
      );
    });

    test('uses downloaded Qwen embedding bundle for local search indexing',
        () async {
      await _writeDownloadedEmbeddingBundle(tempDir);
      final endpoint = await _FakeEmbeddingEndpoint.start();
      addTearDown(endpoint.close);
      LlamaServerStartRequest? embeddingRequest;
      var embeddingLeaseReleased = false;
      final pipeline = _pipeline(
        tempDir: tempDir,
        host: _FakeStageHost(),
        provider: _CountingVlmProvider(_unsafeRawResponse),
        embeddingStarter: (request) async {
          embeddingRequest = request;
          return VssLlamaServerLease(
            endpointUri: endpoint.uri,
            release: () async {
              embeddingLeaseReleased = true;
            },
          );
        },
      );

      await pipeline
          .analyze(
            DetectionPipelineRequest(
              mediaPath: 'fixture.mp4',
              mediaId: 'media-1',
              settings: _settings(),
            ),
          )
          .drain<void>();

      expect(embeddingRequest, isNotNull);
      expect(
        embeddingRequest!.modelBundleId,
        VssFamilySafetyPipeline.embeddingModelBundleId,
      );
      expect(embeddingRequest!.embedding, isTrue);
      expect(embeddingRequest!.gpuLayers, 0);
      expect(endpoint.requests, isNotEmpty);
      expect(embeddingLeaseReleased, isTrue);
      final searchIndex = jsonDecode(
        File('${tempDir.path}/family_safety_search_index.json')
            .readAsStringSync(),
      ) as List<dynamic>;
      expect(searchIndex, isNotEmpty);
      expect(
        (searchIndex.first as Map<String, dynamic>)['embedding'],
        hasLength(4),
      );
    });

    test('embedding startup failures do not block completed analysis',
        () async {
      await _writeDownloadedEmbeddingBundle(tempDir);
      final pipeline = _pipeline(
        tempDir: tempDir,
        host: _FakeStageHost(),
        provider: _CountingVlmProvider(_unsafeRawResponse),
        embeddingStarter: (_) async => throw StateError('embedding offline'),
      );

      final progress = await pipeline
          .analyze(
            DetectionPipelineRequest(
              mediaPath: 'fixture.mp4',
              mediaId: 'media-1',
              settings: _settings(),
            ),
          )
          .toList();

      expect(progress.last.stepName, 'Analysis complete');
      final searchIndex = jsonDecode(
        File('${tempDir.path}/family_safety_search_index.json')
            .readAsStringSync(),
      ) as List<dynamic>;
      expect(searchIndex, isNotEmpty);
      expect(
        (searchIndex.first as Map<String, dynamic>)['embedding'],
        hasLength(64),
      );
    });

    test('resume skips chunks already completed in the VSS checkpoint',
        () async {
      final firstProvider = _CountingVlmProvider(_unsafeRawResponse);
      final first = _pipeline(
        tempDir: tempDir,
        host: _FakeStageHost(),
        provider: firstProvider,
      );
      await first
          .analyze(
            DetectionPipelineRequest(
              mediaPath: 'fixture.mp4',
              mediaId: 'media-1',
              settings: _settings(),
            ),
          )
          .drain<void>();
      expect(firstProvider.calls, 2);

      final secondProvider = _CountingVlmProvider(_unsafeRawResponse);
      final second = _pipeline(
        tempDir: tempDir,
        host: _FakeStageHost(),
        provider: secondProvider,
      );
      await second
          .analyze(
            DetectionPipelineRequest(
              mediaPath: 'fixture.mp4',
              mediaId: 'media-1',
              settings: _settings(),
            ),
          )
          .drain<void>();

      expect(secondProvider.calls, 0);
    });

    test('cancellation after a chunk leaves a resumable checkpoint', () async {
      final token = CancellationToken();
      final provider = _CountingVlmProvider(
        _unsafeRawResponse,
        afterCall: (calls) {
          if (calls == 1) {
            token.cancel();
          }
        },
      );
      final pipeline = _pipeline(
        tempDir: tempDir,
        host: _FakeStageHost(),
        provider: provider,
      );

      await expectLater(
        pipeline
            .analyze(
              DetectionPipelineRequest(
                mediaPath: 'fixture.mp4',
                mediaId: 'media-1',
                settings: _settings(),
                cancellationToken: token,
              ),
            )
            .drain<void>(),
        throwsA(isA<CancelledException>()),
      );

      final checkpoint = jsonDecode(
        File('${tempDir.path}/vss_checkpoint.json').readAsStringSync(),
      ) as Map<String, dynamic>;
      expect(checkpoint['completedChunkIds'], hasLength(1));
    });

    test('startup failures fall back to legacy with a warning progress',
        () async {
      final host = _FakeStageHost();
      final pipeline = _pipeline(
        tempDir: tempDir,
        host: host,
        provider: _CountingVlmProvider(_unsafeRawResponse),
        starter: (_) => throw const VssPipelineStartupException('no runtime'),
      );

      final progress = await pipeline
          .analyze(
            DetectionPipelineRequest(
              mediaPath: 'fixture.mp4',
              mediaId: 'media-1',
              settings: _settings(),
            ),
          )
          .toList();

      expect(host.legacyCalls, 1);
      expect(progress.first.stepName, 'VSS: preparing local VLM');
      expect(progress[1].stepName, startsWith('VSS unavailable'));
      expect(progress.last.stepName, 'Legacy complete');
    });

    test('hosted inference endpoints are rejected before any network call',
        () async {
      final host = _FakeStageHost();
      final provider = _CountingVlmProvider(_unsafeRawResponse);
      final pipeline = _pipeline(
        tempDir: tempDir,
        host: host,
        provider: provider,
        endpoint: Uri.parse('https://api.openai.com'),
      );

      await pipeline
          .analyze(
            DetectionPipelineRequest(
              mediaPath: 'fixture.mp4',
              mediaId: 'media-1',
              settings: _settings(),
            ),
          )
          .drain<void>();

      expect(provider.calls, 0);
      expect(host.legacyCalls, 1);
    });
  });
}

VssFamilySafetyPipeline _pipeline({
  required Directory tempDir,
  required _FakeStageHost host,
  required _CountingVlmProvider provider,
  Uri? endpoint,
  VssLlamaServerStarter? starter,
  VssLlamaServerStarter? embeddingStarter,
}) =>
    VssFamilySafetyPipeline(
      stageHost: host,
      frameSamplingService: FrameSamplingService(ffmpeg: FFmpegBindings()),
      modelManager: ModelManagerService(customModelsPath: tempDir.path),
      chunkPlanner: const ChunkPlanner(
        config: ChunkPlannerConfig(
          targetChunkDuration: Duration(seconds: 5),
          minChunkDuration: Duration(seconds: 1),
          maxChunkDuration: Duration(seconds: 5),
          overlap: Duration.zero,
          useSceneBoundaries: false,
        ),
      ),
      vlmProviderFactory: VlmProviderFactory(
        overrideProvider: ({
          required runtimeProfile,
          required endpoint,
          required modelAlias,
        }) {
          const LocalRuntimeEndpointPolicy()
              .validate(
                LocalRuntimeConfig(endpointUri: endpoint.toString()),
              )
              .forEach((issue) => throw VlmProviderException(issue));
          provider.runtimeProfile = runtimeProfile;
          return provider;
        },
      ),
      cacheDirectoryFactory: (_) async => tempDir,
      sceneChangeDetector: (_, {required cancellationToken}) async =>
          const <Duration>[],
      frameImageExtractor: ({
        required videoPath,
        required chunk,
        required frameRefs,
        required cancellationToken,
      }) async =>
          [
        for (final ref in frameRefs)
          VlmFrameImage(
            frameRef: ref,
            jpegBytes: const [0xff, 0xd8, 0xff, 0xd9],
            width: 2,
            height: 2,
            sha256: sha256.convert(const [0xff, 0xd8, 0xff, 0xd9]).toString(),
          ),
      ],
      llamaServerStarter: starter ??
          (_) async => VssLlamaServerLease(
                endpointUri: endpoint ?? Uri.http('127.0.0.1:11434'),
                release: () async {},
              ),
      embeddingServerStarter: embeddingStarter,
      modelArtifactResolver: (_) async => const VssModelArtifacts(
        modelPath: r'C:\models\qwen.gguf',
        mmprojPath: r'C:\models\mmproj.gguf',
        modelDirectory: r'C:\models',
      ),
      enableLegacyAuxiliarySignals: false,
      skipRuntimePreflight: true,
    );

AnalysisSettings _settings() => AnalysisSettings.defaults().copyWith(
      enableProfanity: false,
      useSceneDetection: false,
      contentDetectionConfig: const ContentDetectionConfig(
        categories: [
          ContentCategory(
            id: 'immodest_female_clothing',
            name: 'Immodest female clothing',
            description: 'Visible revealing clothing or exposed body regions.',
            type: CategoryType.visual,
            action: RemediationAction.blurRegion,
          ),
        ],
      ),
    );

const _unsafeRawResponse = '''
{
  "schemaVersion": 1,
  "caption": "A person is visible with exposed legs.",
  "findings": [
    {
      "category": "immodest_female_clothing",
      "severity": "medium",
      "confidence": 0.82,
      "startTimeMs": 0,
      "endTimeMs": 5000,
      "rationale": "Visible exposed legs are present in the sampled frames.",
      "groundingStatus": "scene_level_only",
      "needsReview": true,
      "regionIds": []
    }
  ],
  "groundedRegions": [],
  "searchTerms": ["exposed legs"],
  "uncertainty": []
}
''';

class _CountingVlmProvider implements VlmProvider {
  _CountingVlmProvider(
    this.rawResponse, {
    this.afterCall,
    LocalRuntimeProfile? runtimeProfile,
  }) : _runtimeProfile = runtimeProfile ??
            LocalRuntimeProfile.byId(LocalRuntimeId.cudaLlamaCpp);

  final String rawResponse;
  final void Function(int calls)? afterCall;
  LocalRuntimeProfile _runtimeProfile;
  int calls = 0;

  @override
  LocalRuntimeProfile get runtimeProfile => _runtimeProfile;

  set runtimeProfile(LocalRuntimeProfile value) {
    _runtimeProfile = value;
  }

  @override
  String get providerId => 'counting_mock_vlm';

  @override
  String get providerVersion => '1';

  @override
  Future<VlmSegmentResponse> analyzeSegment(VideoSegmentRequest request) async {
    calls++;
    final response =
        await MockVlmProvider(rawResponse: rawResponse).analyzeSegment(request);
    afterCall?.call(calls);
    return response;
  }
}

Future<void> _writeDownloadedEmbeddingBundle(Directory modelsDir) async {
  final bundleDir = Directory(
    p.join(
      modelsDir.path,
      'model_bundles',
      VssFamilySafetyPipeline.embeddingModelBundleId,
    ),
  );
  await bundleDir.create(recursive: true);
  await File(p.join(bundleDir.path, 'Qwen3-Embedding-0.6B-Q8_0.gguf'))
      .writeAsBytes(const <int>[1, 2, 3, 4]);
  await File(p.join(bundleDir.path, 'model_bundle_metadata.json'))
      .writeAsString(
    jsonEncode({
      'id': VssFamilySafetyPipeline.embeddingModelBundleId,
      'displayName': 'Qwen3 Embedding 0.6B GGUF Q8',
      'officialSourceRepo': 'Qwen/Qwen3-Embedding-0.6B-GGUF',
      'officialRevision': 'main',
      'artifactUri': 'hf://Qwen/Qwen3-Embedding-0.6B-GGUF',
      'files': [
        {
          'path': 'Qwen3-Embedding-0.6B-Q8_0.gguf',
          'sizeBytes': 4,
        },
      ],
    }),
  );
}

class _FakeEmbeddingEndpoint {
  _FakeEmbeddingEndpoint._(this._server);

  final HttpServer _server;
  final requests = <_EmbeddingRequest>[];

  Uri get uri => Uri.http('127.0.0.1:${_server.port}');

  static Future<_FakeEmbeddingEndpoint> start() async {
    final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    final endpoint = _FakeEmbeddingEndpoint._(server);
    server.listen(endpoint._handle);
    return endpoint;
  }

  Future<void> close() => _server.close(force: true);

  Future<void> _handle(HttpRequest request) async {
    final body = await utf8.decoder.bind(request).join();
    final decoded = jsonDecode(body) as Map<String, dynamic>;
    final inputs = (decoded['input'] as List<dynamic>).cast<String>();
    requests.add(
      _EmbeddingRequest(
        path: request.uri.path,
        model: decoded['model'] as String,
        inputs: inputs,
      ),
    );
    request.response.headers.set(
      HttpHeaders.contentTypeHeader,
      'application/json; charset=utf-8',
    );
    request.response.write(
      jsonEncode({
        'object': 'list',
        'model': decoded['model'],
        'data': [
          for (var index = 0; index < inputs.length; index++)
            {
              'object': 'embedding',
              'index': index,
              'embedding': _embeddingFor(inputs[index]),
            },
        ],
      }),
    );
    await request.response.close();
  }
}

class _EmbeddingRequest {
  const _EmbeddingRequest({
    required this.path,
    required this.model,
    required this.inputs,
  });

  final String path;
  final String model;
  final List<String> inputs;
}

List<double> _embeddingFor(String text) {
  final digest = sha256.convert(utf8.encode(text)).bytes;
  return <double>[
    digest[0] + 1,
    digest[1] + 1,
    digest[2] + 1,
    digest[3] + 1,
  ];
}

class _FakeStageHost implements AnalysisStageHost {
  int legacyCalls = 0;

  @override
  Future<void> checkState(CancellationToken? token) async {
    await token?.checkState();
  }

  @override
  Future<List<ProfanityMatch>> detectProfanity(
    Transcript transcript,
    AnalysisSettings settings, {
    CancellationToken? cancellationToken,
  }) async =>
      const <ProfanityMatch>[];

  @override
  Future<MediaMetadata> probeMedia(
    String mediaPath, {
    CancellationToken? cancellationToken,
  }) async =>
      const MediaMetadata(
        duration: Duration(seconds: 10),
        fileSizeBytes: 1024,
        resolution: Resolution(width: 640, height: 360),
        frameRate: 30,
      );

  @override
  Stream<AnalysisProgress> runLegacyAnalysis(
    DetectionPipelineRequest request,
  ) async* {
    legacyCalls++;
    yield const AnalysisProgress(
      stepName: 'Legacy complete',
      currentStep: 1,
      totalSteps: 1,
      stepProgress: 1,
    );
  }

  @override
  Stream<AnalysisVisualAuxiliaryProgressUpdate> runVisualAuxiliarySignals(
    DetectionPipelineRequest request, {
    required Duration mediaDuration,
    required int currentStep,
    required int totalSteps,
  }) async* {
    yield AnalysisVisualAuxiliaryProgressUpdate(
      progress: AnalysisProgress(
        stepName: 'Legacy auxiliary visual signals complete',
        currentStep: currentStep,
        totalSteps: totalSteps,
        stepProgress: 1,
      ),
      result: const AnalysisVisualAuxiliaryResult(),
    );
  }

  @override
  Future<Transcript> transcribeAudio(
    String mediaPath,
    AnalysisSettings settings, {
    CancellationToken? cancellationToken,
    void Function(String message, double progress)? onProgress,
  }) async =>
      Transcript.empty();
}
