import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:archive/archive.dart';
import 'package:crypto/crypto.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:kidslens_video_editor/data/models/models.dart';
import 'package:kidslens_video_editor/services/detection/runtime_binary_manager.dart';
import 'package:kidslens_video_editor/services/high_performance_downloader.dart';

void main() {
  late Directory tempDir;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('kidslens_runtime_test_');
  });

  tearDown(() async {
    if (tempDir.existsSync()) {
      await tempDir.delete(recursive: true);
    }
  });

  test('pins official llama.cpp CUDA and Vulkan release assets', () {
    final cuda = RuntimeBinaryManager.pinnedCudaSpec;
    final vulkan = RuntimeBinaryManager.pinnedVulkanSpec;

    expect(cuda.tag, 'b9628');
    expect(cuda.sourceRepo, 'ggml-org/llama.cpp');
    expect(
      cuda.assets.map((asset) => asset.name),
      containsAll([
        'llama-b9628-bin-win-cuda-13.3-x64.zip',
        'cudart-llama-bin-win-cuda-13.3-x64.zip',
      ]),
    );
    expect(cuda.assets.every((asset) => asset.sha256.length == 64), isTrue);
    expect(vulkan.assets.single.name, 'llama-b9628-bin-win-vulkan-x64.zip');
    expect(vulkan.assets.single.sha256.length, 64);
  });

  test('downloads, verifies, extracts, and records runtime provenance',
      () async {
    final archiveBytes = _zipBytes({
      'bin/llama-server.exe': 'fake runtime',
      'README.txt': 'llama.cpp test archive',
    });
    final spec = _fakeSpec(
      assetBytes: archiveBytes,
      sha: sha256.convert(archiveBytes).toString(),
    );
    final requests = <Uri>[];
    final manager = RuntimeBinaryManager(
      customRuntimeRoot: tempDir.path,
      specOverrides: {LocalRuntimeId.vulkanLlamaCpp: spec},
      httpClientFactory: () => _FakeHttpClient((request) {
        requests.add(request.url);
        return http.Response.bytes(archiveBytes, 200);
      }),
    );

    final progress =
        await manager.ensureInstalled(LocalRuntimeId.vulkanLlamaCpp).toList();

    expect(requests, [spec.assets.single.downloadUrl]);
    expect(progress.first.status, RuntimeBinaryInstallStatus.pending);
    expect(progress.last.status, RuntimeBinaryInstallStatus.complete);

    final state = await manager.getInstallState(LocalRuntimeId.vulkanLlamaCpp);
    expect(state.isInstalled, isTrue);
    expect(state.executablePath, endsWith('llama-server.exe'));
    expect(File(state.executablePath!).existsSync(), isTrue);
    expect(state.metadata['sourceRepo'], 'ggml-org/llama.cpp');
    final provenance = state.metadata['provenance'] as Map<String, dynamic>;
    expect(provenance['downloadHost'], 'github.com');

    final secondRun =
        await manager.ensureInstalled(LocalRuntimeId.vulkanLlamaCpp).toList();
    expect(secondRun.single.status, RuntimeBinaryInstallStatus.complete);
    expect(requests.length, 1);
  });

  test('rejects checksum mismatch and reports failed progress', () async {
    final archiveBytes = _zipBytes({'llama-server.exe': 'bad checksum'});
    final spec = _fakeSpec(
      assetBytes: archiveBytes,
      sha: List.filled(64, '0').join(),
    );
    final manager = RuntimeBinaryManager(
      customRuntimeRoot: tempDir.path,
      specOverrides: {LocalRuntimeId.vulkanLlamaCpp: spec},
      httpClientFactory: () => _FakeHttpClient(
        (_) => http.Response.bytes(archiveBytes, 200),
      ),
    );

    final progress = <RuntimeBinaryInstallProgress>[];
    Object? error;
    try {
      await manager
          .ensureInstalled(LocalRuntimeId.vulkanLlamaCpp)
          .forEach(progress.add);
    } catch (e) {
      error = e;
    }

    expect(error, isA<RuntimeBinaryException>());
    expect(progress.last.status, RuntimeBinaryInstallStatus.failed);
    final state = await manager.getInstallState(LocalRuntimeId.vulkanLlamaCpp);
    expect(state.isInstalled, isFalse);
  });

  test('uses ranged downloader for runtime archives', () async {
    final archiveBytes = _zipBytes({
      'bin/llama-server.exe': 'fake runtime with enough bytes for ranges',
      'README.txt': 'llama.cpp test archive',
    });
    final spec = _fakeSpec(
      assetBytes: archiveBytes,
      sha: sha256.convert(archiveBytes).toString(),
    );
    final ranges = <String>[];
    final manager = RuntimeBinaryManager(
      customRuntimeRoot: tempDir.path,
      specOverrides: {LocalRuntimeId.vulkanLlamaCpp: spec},
      downloader: const HighPerformanceDownloader(
        maxParallelRequests: 3,
        segmentSizeBytes: 8,
        minParallelFileBytes: 1,
      ),
      httpClientFactory: () => _FakeHttpClient((request) {
        final range = request.headers[HttpHeaders.rangeHeader];
        if (range == null) {
          return http.Response.bytes(archiveBytes, HttpStatus.ok);
        }
        ranges.add(range);
        final parsed = _parseRange(range);
        return http.Response.bytes(
          archiveBytes.sublist(parsed.start, parsed.end + 1),
          HttpStatus.partialContent,
        );
      }),
    );

    final progress =
        await manager.ensureInstalled(LocalRuntimeId.vulkanLlamaCpp).toList();

    expect(progress.last.status, RuntimeBinaryInstallStatus.complete);
    expect(ranges.first, 'bytes=0-0');
    expect(ranges.skip(1).length, greaterThan(1));
  });
}

RuntimeBinarySpec _fakeSpec({
  required List<int> assetBytes,
  required String sha,
}) =>
    RuntimeBinarySpec(
      runtimeId: LocalRuntimeId.vulkanLlamaCpp,
      tag: 'test-tag',
      displayName: 'Test llama.cpp Vulkan',
      sourceRepo: 'ggml-org/llama.cpp',
      releaseUrl: Uri.parse(
        'https://github.com/ggml-org/llama.cpp/releases/tag/test-tag',
      ),
      executableName: 'llama-server.exe',
      assets: [
        RuntimeBinaryAsset(
          name: 'llama-test-bin-win-vulkan-x64.zip',
          downloadUrl: Uri.parse(
            'https://github.com/ggml-org/llama.cpp/releases/download/test-tag/llama-test-bin-win-vulkan-x64.zip',
          ),
          sizeBytes: assetBytes.length,
          sha256: sha,
        ),
      ],
    );

List<int> _zipBytes(Map<String, String> files) {
  final archive = Archive();
  for (final entry in files.entries) {
    final bytes = utf8.encode(entry.value);
    archive.addFile(ArchiveFile(entry.key, bytes.length, bytes));
  }
  return ZipEncoder().encodeBytes(archive);
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

class _FakeHttpClient extends http.BaseClient {
  _FakeHttpClient(this.handler);

  final FutureOr<http.Response> Function(http.BaseRequest request) handler;

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    final response = await handler(request);
    return http.StreamedResponse(
      Stream.value(response.bodyBytes),
      response.statusCode,
      headers: response.headers,
      reasonPhrase: response.reasonPhrase,
      request: request,
    );
  }
}
