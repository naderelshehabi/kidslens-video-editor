import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:kidslens_video_editor/services/model_manager_service.dart';

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

    test('getDownloadedModels canonicalizes legacy 640 community directory', () async {
      final legacyDir = Directory(
        '${tempDir.path}${Platform.pathSeparator}nsfw-nudenet-detector-640-community',
      )..createSync(recursive: true);
      File('${legacyDir.path}${Platform.pathSeparator}640m.onnx')
          .writeAsBytesSync(const <int>[1, 2, 3, 4]);

      final downloaded = await service.getDownloadedModels();

      expect(downloaded, contains('nsfw-nudenet-detector-640'));
      expect(downloaded, isNot(contains('nsfw-nudenet-detector-640-community')));
    });

    test('getModelPath resolves canonical 640 id from legacy directory', () async {
      final legacyDir = Directory(
        '${tempDir.path}${Platform.pathSeparator}nsfw-nudenet-detector-640-community',
      )..createSync(recursive: true);
      final legacyModelFile =
          File('${legacyDir.path}${Platform.pathSeparator}640m.onnx')
            ..writeAsBytesSync(const <int>[1, 2, 3, 4]);

      final resolvedPath = await service.getModelPath('nsfw-nudenet-detector-640');

      expect(resolvedPath, equals(legacyModelFile.path));
    });

    test('deleteModel removes legacy alias directories for canonical 640 id', () async {
      final legacyDir = Directory(
        '${tempDir.path}${Platform.pathSeparator}nsfw-nudenet-detector-640-community',
      )..createSync(recursive: true);
      File('${legacyDir.path}${Platform.pathSeparator}640m.onnx')
          .writeAsBytesSync(const <int>[1, 2, 3, 4]);

      await service.deleteModel('nsfw-nudenet-detector-640');

      expect(legacyDir.existsSync(), isFalse);
    });
  });
}