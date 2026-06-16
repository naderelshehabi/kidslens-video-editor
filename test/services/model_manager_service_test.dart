import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kidslens_video_editor/data/models/models.dart';
import 'package:kidslens_video_editor/services/high_performance_downloader.dart';
import 'package:kidslens_video_editor/services/model_manager_service.dart';
import 'package:path/path.dart' as p;

void main() {
  group('ModelManagerService legacy NudeNet aliases', () {
    late Directory tempDir;
    late ModelManagerService service;

    setUp(() async {
      tempDir = await Directory.systemTemp.createTemp('kidslens_models_test_');
      service = ModelManagerService(customModelsPath: tempDir.path);
    });

    tearDown(() async {
      if (tempDir.existsSync()) {
        await tempDir.delete(recursive: true);
      }
    });

    test(
      'getDownloadedModels canonicalizes legacy 640 community directory',
      () async {
        final legacyDir = Directory(
          '${tempDir.path}${Platform.pathSeparator}nsfw-nudenet-detector-640-community',
        )..createSync(recursive: true);
        File('${legacyDir.path}${Platform.pathSeparator}640m.onnx')
            .writeAsBytesSync(const <int>[1, 2, 3, 4]);

        final downloaded = await service.getDownloadedModels();

        expect(downloaded, contains('nsfw-nudenet-detector-640'));
        expect(
          downloaded,
          isNot(contains('nsfw-nudenet-detector-640-community')),
        );
      },
    );

    test('getModelPath resolves canonical 640 id from legacy directory',
        () async {
      final legacyDir = Directory(
        '${tempDir.path}${Platform.pathSeparator}nsfw-nudenet-detector-640-community',
      )..createSync(recursive: true);
      final legacyModelFile =
          File('${legacyDir.path}${Platform.pathSeparator}640m.onnx')
            ..writeAsBytesSync(const <int>[1, 2, 3, 4]);

      final resolvedPath =
          await service.getModelPath('nsfw-nudenet-detector-640');

      expect(resolvedPath, equals(legacyModelFile.path));
    });

    test('deleteModel removes legacy alias directories for canonical 640 id',
        () async {
      final legacyDir = Directory(
        '${tempDir.path}${Platform.pathSeparator}nsfw-nudenet-detector-640-community',
      )..createSync(recursive: true);
      File('${legacyDir.path}${Platform.pathSeparator}640m.onnx')
          .writeAsBytesSync(const <int>[1, 2, 3, 4]);

      await service.deleteModel('nsfw-nudenet-detector-640');

      expect(legacyDir.existsSync(), isFalse);
    });
  });

  group('ModelManagerService official model bundle downloads', () {
    late Directory tempDir;

    setUp(() async {
      tempDir = await Directory.systemTemp.createTemp('kidslens_bundle_test_');
    });

    tearDown(() async {
      if (tempDir.existsSync()) {
        await tempDir.delete(recursive: true);
      }
    });

    test('downloads official hf model bundle files and metadata', () async {
      final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
      addTearDown(() async => server.close(force: true));
      server.listen((request) async {
        final path = request.uri.path;
        if (path == '/api/models/google/gemma-4-E4B-it/revision/main') {
          request.response.headers.set(
            HttpHeaders.contentTypeHeader,
            'application/json',
          );
          request.response.write('''
{
  "siblings": [
    {"rfilename": "README.md", "size": 10},
    {"rfilename": "config.json"},
    {"rfilename": "model.safetensors"},
    {"rfilename": "images/example.png", "size": 20}
  ]
}
''');
          await request.response.close();
          return;
        }
        if (path == '/google/gemma-4-E4B-it/resolve/main/config.json') {
          if (request.method == 'HEAD') {
            request.response.contentLength = 2;
            await request.response.close();
            return;
          }
          request.response.add(const <int>[123, 125]);
          await request.response.close();
          return;
        }
        if (path == '/google/gemma-4-E4B-it/resolve/main/model.safetensors') {
          if (request.method == 'HEAD') {
            request.response.contentLength = 3;
            await request.response.close();
            return;
          }
          request.response.add(const <int>[1, 2, 3]);
          await request.response.close();
          return;
        }
        request.response.statusCode = HttpStatus.notFound;
        await request.response.close();
      });

      final service = ModelManagerService(
        customModelsPath: tempDir.path,
        huggingFaceBaseUrl: 'http://127.0.0.1:${server.port}',
      );
      final manifest = ModelBundleCatalog.byModelId('google_gemma_4_e4b_it');

      final progress = await service.downloadModelBundle(manifest).toList();

      expect(progress.last.status, ModelDownloadStatus.complete);
      expect(
        progress.any(
          (entry) => entry.percentage > 0 && entry.percentage < 1,
        ),
        isTrue,
      );
      expect(progress.last.totalBytes, 5);
      expect(
        File(
          p.join(
            tempDir.path,
            'model_bundles',
            manifest.modelId,
            'config.json',
          ),
        ).existsSync(),
        isTrue,
      );
      expect(
        File(
          p.join(
            tempDir.path,
            'model_bundles',
            manifest.modelId,
            'model.safetensors',
          ),
        ).existsSync(),
        isTrue,
      );
      expect(
        File(
          p.join(
            tempDir.path,
            'model_bundles',
            manifest.modelId,
            'images',
            'example.png',
          ),
        ).existsSync(),
        isFalse,
      );

      final downloaded = await service.getDownloadedModelBundles();
      expect(downloaded, contains(manifest.modelId));

      final metadata = await service.getModelBundleMetadata(manifest.modelId);
      expect(metadata?['officialSourceRepo'], manifest.officialSourceRepo);
      expect(metadata?['files'], hasLength(2));
    });

    test('reports gated official hf repos with token guidance', () async {
      final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
      addTearDown(() async => server.close(force: true));
      server.listen((request) async {
        request.response.statusCode = HttpStatus.forbidden;
        await request.response.close();
      });

      final service = ModelManagerService(
        customModelsPath: tempDir.path,
        huggingFaceBaseUrl: 'http://127.0.0.1:${server.port}',
      );
      final manifest = ModelBundleCatalog.byModelId('google_gemma_4_e4b_it');

      await expectLater(
        service.downloadModelBundle(manifest).toList(),
        throwsA(
          isA<ModelDownloadException>().having(
            (error) => error.reason,
            'reason',
            contains('HF_TOKEN'),
          ),
        ),
      );
    });

    test('downloads explicit GGUF artifact files without repo-wide scan',
        () async {
      const modelBytes = <int>[1, 2];
      const mmprojBytes = <int>[3, 4, 5];
      var apiRequested = false;
      final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
      addTearDown(() async => server.close(force: true));
      server.listen((request) async {
        final path = request.uri.path;
        if (path == '/api/models/Qwen/fake-gguf/revision/main') {
          apiRequested = true;
          request.response.statusCode = HttpStatus.internalServerError;
          await request.response.close();
          return;
        }
        if (path == '/Qwen/fake-gguf/resolve/main/model.gguf') {
          request.response.add(modelBytes);
          await request.response.close();
          return;
        }
        if (path == '/Qwen/fake-gguf/resolve/main/mmproj.gguf') {
          request.response.add(mmprojBytes);
          await request.response.close();
          return;
        }
        request.response.statusCode = HttpStatus.notFound;
        await request.response.close();
      });

      final service = ModelManagerService(
        customModelsPath: tempDir.path,
        huggingFaceBaseUrl: 'http://127.0.0.1:${server.port}',
      );
      final manifest = _ggufManifest(
        modelSha256: sha256.convert(modelBytes).toString(),
        mmprojSha256: sha256.convert(mmprojBytes).toString(),
      );

      final progress = await service.downloadModelBundle(manifest).toList();

      expect(progress.last.status, ModelDownloadStatus.complete);
      expect(apiRequested, isFalse);
      expect(
        File(
          p.join(
            tempDir.path,
            'model_bundles',
            manifest.modelId,
            'model.gguf',
          ),
        ).existsSync(),
        isTrue,
      );
      final metadata = await service.getModelBundleMetadata(manifest.modelId);
      expect(metadata?['files'], hasLength(2));
      expect(
        (metadata?['files'] as List)
            .cast<Map<String, dynamic>>()
            .map((file) => file['path']),
        ['mmproj.gguf', 'model.gguf'],
      );
    });

    test('uses ranged requests for explicit GGUF bundle artifacts', () async {
      const modelBytes = <int>[1, 2];
      const mmprojBytes = <int>[5, 6, 7];
      final ranges = <String>[];
      final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
      addTearDown(() async => server.close(force: true));
      server.listen((request) async {
        Future<void> respondBytes(List<int> bytes) async {
          final range = request.headers.value(HttpHeaders.rangeHeader);
          if (range == null) {
            request.response.add(bytes);
            await request.response.close();
            return;
          }
          ranges.add(range);
          final parsed = _parseRange(range);
          request.response.statusCode = HttpStatus.partialContent;
          final slice = bytes.sublist(parsed.start, parsed.end + 1);
          request.response.contentLength = slice.length;
          request.response.headers.set(
            HttpHeaders.contentRangeHeader,
            'bytes ${parsed.start}-${parsed.end}/${bytes.length}',
          );
          request.response.add(slice);
          await request.response.close();
        }

        final path = request.uri.path;
        if (path == '/Qwen/fake-gguf/resolve/main/model.gguf') {
          await respondBytes(modelBytes);
          return;
        }
        if (path == '/Qwen/fake-gguf/resolve/main/mmproj.gguf') {
          await respondBytes(mmprojBytes);
          return;
        }
        request.response.statusCode = HttpStatus.notFound;
        await request.response.close();
      });

      final service = ModelManagerService(
        customModelsPath: tempDir.path,
        huggingFaceBaseUrl: 'http://127.0.0.1:${server.port}',
        downloader: const HighPerformanceDownloader(
          maxParallelRequests: 2,
          segmentSizeBytes: 1,
          minParallelFileBytes: 1,
        ),
      );
      final manifest = _ggufManifest(
        modelSha256: sha256.convert(modelBytes).toString(),
        mmprojSha256: sha256.convert(mmprojBytes).toString(),
      );

      final progress = await service.downloadModelBundle(manifest).toList();

      expect(progress.last.status, ModelDownloadStatus.complete);
      expect(ranges, contains('bytes=0-0'));
      expect(ranges.where((range) => range != 'bytes=0-0'), isNotEmpty);
      expect(
        await File(
          p.join(
            tempDir.path,
            'model_bundles',
            manifest.modelId,
            'model.gguf',
          ),
        ).readAsBytes(),
        modelBytes,
      );
    });

    test('resolves downloaded official bundle paths from model_bundles',
        () async {
      final service = ModelManagerService(customModelsPath: tempDir.path);
      final manifest =
          ModelBundleCatalog.byModelId('qwen3_embedding_0_6b_gguf_q8');
      final bundleDir = Directory(
        p.join(tempDir.path, 'model_bundles', manifest.modelId),
      )..createSync(recursive: true);
      final modelFile =
          File(p.join(bundleDir.path, 'Qwen3-Embedding-0.6B-Q8_0.gguf'))
            ..writeAsBytesSync(const <int>[1, 2, 3, 4]);
      File(p.join(bundleDir.path, 'model_bundle_metadata.json'))
          .writeAsStringSync(
        '''
{
  "id": "${manifest.modelId}",
  "displayName": "${manifest.displayName}",
  "officialSourceRepo": "${manifest.officialSourceRepo}",
  "files": [
    {"path": "Qwen3-Embedding-0.6B-Q8_0.gguf", "sizeBytes": 4}
  ]
}
''',
      );

      expect(await service.getModelPath(manifest.modelId), modelFile.path);
      expect(await service.validateModel(manifest.modelId), isTrue);
    });

    test('blocks non-commercial official bundles at runtime', () async {
      final service = ModelManagerService(customModelsPath: tempDir.path);
      final manifest = ModelBundleCatalog.byModelId('nvidia_locateanything_3b');

      expect(
        service.downloadModelBundle(manifest).toList(),
        throwsA(isA<ModelDownloadException>()),
      );
    });
  });
}

_Range _parseRange(String value) {
  final match = RegExp(r'^bytes=(\d+)-(\d+)$').firstMatch(value);
  if (match == null) {
    throw StateError('Invalid range header: $value');
  }
  return _Range(
    start: int.parse(match.group(1)!),
    end: int.parse(match.group(2)!),
  );
}

class _Range {
  const _Range({required this.start, required this.end});

  final int start;
  final int end;
}

ModelBundleManifest _ggufManifest({
  required String modelSha256,
  required String mmprojSha256,
}) =>
    ModelBundleManifest(
      modelId: 'qwen_fake_gguf',
      displayName: 'Qwen Fake GGUF',
      vendor: 'Alibaba / Qwen',
      officialSourceRepo: 'Qwen/fake-gguf',
      officialRevision: 'main',
      license: ModelBundleLicense.apache20,
      commercialUse: CommercialUseStatus.allowed,
      acceptedTermsRequired: false,
      artifactType: ModelBundleArtifactType.officialGguf,
      artifactUri: 'hf://Qwen/fake-gguf',
      sha256: null,
      conversionRecipeId: null,
      runtime: ModelBundleRuntime.llamaCppServer,
      minVramGb: 1,
      recommendedVramGb: 1,
      targetGpuClass: ModelBundleCatalog.targetGpuClass,
      maxValidatedVramGb: ModelBundleCatalog.targetGpuVramGb,
      quantization: ModelBundleQuantization.q4KM,
      fitsRtx5070Validated: false,
      supportsVideoInput: false,
      supportsImageInput: true,
      supportsBoundingBoxes: true,
      supportsMasks: false,
      supportsPointLocalization: false,
      maxFramesPerChunk: 2,
      maxContextTokens: 8192,
      recommendedChunkSeconds: 8,
      knownFailureModes: const <String>['test fixture'],
      roles: const <ModelBundleRole>[ModelBundleRole.vlm],
      approvalStatus: ModelBundleApprovalStatus.evaluationOnly,
      reviewNotes: 'test fixture',
      artifactFiles: <ModelBundleArtifactFile>[
        ModelBundleArtifactFile(
          path: 'model.gguf',
          sizeBytes: 2,
          sha256: modelSha256,
        ),
        ModelBundleArtifactFile(
          path: 'mmproj.gguf',
          sizeBytes: 3,
          sha256: mmprojSha256,
        ),
      ],
    );
