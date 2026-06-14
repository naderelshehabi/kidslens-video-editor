import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:kidslens_video_editor/data/models/models.dart';
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
