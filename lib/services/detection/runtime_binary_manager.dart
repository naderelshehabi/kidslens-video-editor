import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:archive/archive.dart';
import 'package:crypto/crypto.dart';
import 'package:http/http.dart' as http;
import 'package:kidslens_video_editor/data/models/models.dart';
import 'package:kidslens_video_editor/services/high_performance_downloader.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

enum RuntimeBinaryInstallStatus {
  pending,
  downloading,
  verifying,
  extracting,
  complete,
  failed,
}

class RuntimeBinaryInstallProgress {
  const RuntimeBinaryInstallProgress({
    required this.runtimeId,
    required this.percentage,
    required this.downloadedBytes,
    required this.totalBytes,
    required this.status,
    this.currentAsset,
  });

  final LocalRuntimeId runtimeId;
  final double percentage;
  final int downloadedBytes;
  final int totalBytes;
  final RuntimeBinaryInstallStatus status;
  final String? currentAsset;

  bool get isComplete => status == RuntimeBinaryInstallStatus.complete;
  bool get isFailed => status == RuntimeBinaryInstallStatus.failed;
}

class RuntimeBinaryAsset {
  const RuntimeBinaryAsset({
    required this.name,
    required this.downloadUrl,
    required this.sizeBytes,
    required this.sha256,
    this.isRequired = true,
  });

  final String name;
  final Uri downloadUrl;
  final int sizeBytes;
  final String sha256;
  final bool isRequired;

  Map<String, dynamic> toJson() => {
        'name': name,
        'downloadUrl': downloadUrl.toString(),
        'sizeBytes': sizeBytes,
        'sha256': sha256,
        'isRequired': isRequired,
      };
}

class RuntimeBinarySpec {
  const RuntimeBinarySpec({
    required this.runtimeId,
    required this.tag,
    required this.displayName,
    required this.assets,
    required this.executableName,
    required this.sourceRepo,
    required this.releaseUrl,
  });

  final LocalRuntimeId runtimeId;
  final String tag;
  final String displayName;
  final List<RuntimeBinaryAsset> assets;
  final String executableName;
  final String sourceRepo;
  final Uri releaseUrl;

  int get totalBytes => assets
      .where((asset) => asset.isRequired)
      .fold(0, (sum, asset) => sum + asset.sizeBytes);

  Map<String, dynamic> toJson() => {
        'runtimeId': runtimeId.jsonValue,
        'tag': tag,
        'displayName': displayName,
        'sourceRepo': sourceRepo,
        'releaseUrl': releaseUrl.toString(),
        'executableName': executableName,
        'assets': assets.map((asset) => asset.toJson()).toList(),
      };
}

class RuntimeBinaryInstallState {
  const RuntimeBinaryInstallState({
    required this.isInstalled,
    required this.installDirectory,
    required this.executablePath,
    required this.missingFiles,
    this.metadata = const <String, dynamic>{},
  });

  final bool isInstalled;
  final String installDirectory;
  final String? executablePath;
  final List<String> missingFiles;
  final Map<String, dynamic> metadata;
}

class RuntimeBinaryException implements Exception {
  RuntimeBinaryException(this.message);

  final String message;

  @override
  String toString() => 'RuntimeBinaryException: $message';
}

typedef RuntimeArchiveExtractor = Future<void> Function({
  required File archiveFile,
  required Directory destination,
});

class RuntimeBinaryManager {
  RuntimeBinaryManager({
    String? customRuntimeRoot,
    http.Client Function()? httpClientFactory,
    RuntimeArchiveExtractor? archiveExtractor,
    Map<LocalRuntimeId, RuntimeBinarySpec>? specOverrides,
    HighPerformanceDownloader downloader = const HighPerformanceDownloader(),
  })  : _customRuntimeRoot = customRuntimeRoot,
        _httpClientFactory = httpClientFactory ?? http.Client.new,
        _archiveExtractor = archiveExtractor ?? _extractZipArchive,
        _specOverrides =
            specOverrides ?? const <LocalRuntimeId, RuntimeBinarySpec>{},
        _downloader = downloader;

  static const _runtimeSubdir = 'kidslens_runtimes';
  static const _llamaCppSubdir = 'llamacpp';
  static const _metadataFileName = 'runtime_metadata.json';
  static const _pinnedTag = 'b9628';
  static const _sourceRepo = 'ggml-org/llama.cpp';
  static final _releaseUrl = Uri.parse(
    'https://github.com/ggml-org/llama.cpp/releases/tag/$_pinnedTag',
  );

  static final RuntimeBinarySpec pinnedCudaSpec = RuntimeBinarySpec(
    runtimeId: LocalRuntimeId.cudaLlamaCpp,
    tag: _pinnedTag,
    displayName: 'llama.cpp $_pinnedTag Windows CUDA 13.3',
    sourceRepo: _sourceRepo,
    releaseUrl: _releaseUrl,
    executableName: Platform.isWindows ? 'llama-server.exe' : 'llama-server',
    assets: [
      RuntimeBinaryAsset(
        name: 'llama-$_pinnedTag-bin-win-cuda-13.3-x64.zip',
        downloadUrl: Uri.parse(
          'https://github.com/ggml-org/llama.cpp/releases/download/$_pinnedTag/llama-$_pinnedTag-bin-win-cuda-13.3-x64.zip',
        ),
        sizeBytes: 159018881,
        sha256:
            '3762ce9bcdadf3ba3bafd98f5dc5addc2520c9f94b672d91086496934ddb4c1e',
      ),
      RuntimeBinaryAsset(
        name: 'cudart-llama-bin-win-cuda-13.3-x64.zip',
        downloadUrl: Uri.parse(
          'https://github.com/ggml-org/llama.cpp/releases/download/$_pinnedTag/cudart-llama-bin-win-cuda-13.3-x64.zip',
        ),
        sizeBytes: 390970417,
        sha256:
            '1462a050eb4c684921ba51dcc4cc488a036674c3e73e9945ee705b854808d03e',
      ),
    ],
  );

  static final RuntimeBinarySpec pinnedVulkanSpec = RuntimeBinarySpec(
    runtimeId: LocalRuntimeId.vulkanLlamaCpp,
    tag: _pinnedTag,
    displayName: 'llama.cpp $_pinnedTag Windows Vulkan',
    sourceRepo: _sourceRepo,
    releaseUrl: _releaseUrl,
    executableName: Platform.isWindows ? 'llama-server.exe' : 'llama-server',
    assets: [
      RuntimeBinaryAsset(
        name: 'llama-$_pinnedTag-bin-win-vulkan-x64.zip',
        downloadUrl: Uri.parse(
          'https://github.com/ggml-org/llama.cpp/releases/download/$_pinnedTag/llama-$_pinnedTag-bin-win-vulkan-x64.zip',
        ),
        sizeBytes: 38546148,
        sha256:
            '0545d862acf0940288a13cd4eb1e9c995fb0c42db86d011eabc54fd886cd044e',
      ),
    ],
  );

  static final pinnedSpecs = <LocalRuntimeId, RuntimeBinarySpec>{
    LocalRuntimeId.cudaLlamaCpp: pinnedCudaSpec,
    LocalRuntimeId.vulkanLlamaCpp: pinnedVulkanSpec,
  };

  final String? _customRuntimeRoot;
  final http.Client Function() _httpClientFactory;
  final RuntimeArchiveExtractor _archiveExtractor;
  final Map<LocalRuntimeId, RuntimeBinarySpec> _specOverrides;
  final HighPerformanceDownloader _downloader;
  String? _runtimeRoot;

  Future<String> get runtimeRoot async {
    if (_customRuntimeRoot != null && _customRuntimeRoot.isNotEmpty) {
      final dir = Directory(_customRuntimeRoot);
      if (!dir.existsSync()) {
        await dir.create(recursive: true);
      }
      return dir.path;
    }
    _runtimeRoot ??= await _initRuntimeRoot();
    return _runtimeRoot!;
  }

  RuntimeBinarySpec specForRuntime(LocalRuntimeId runtimeId) {
    final spec = _specOverrides[runtimeId] ?? pinnedSpecs[runtimeId];
    if (spec == null) {
      throw RuntimeBinaryException(
        'No pinned runtime binary spec exists for ${runtimeId.jsonValue}',
      );
    }
    return spec;
  }

  Future<RuntimeBinaryInstallState> getInstallState(
    LocalRuntimeId runtimeId,
  ) async {
    final spec = specForRuntime(runtimeId);
    final installDir = await _installDirectory(spec);
    final executable = await _findExecutable(installDir, spec.executableName);
    final metadataFile = File(p.join(installDir.path, _metadataFileName));
    final metadata = metadataFile.existsSync()
        ? jsonDecode(await metadataFile.readAsString()) as Map<String, dynamic>
        : <String, dynamic>{};
    final missing = <String>[
      if (executable == null) spec.executableName,
      if (!metadataFile.existsSync()) _metadataFileName,
      for (final asset in spec.assets)
        if (!File(p.join(installDir.path, 'downloads', asset.name))
            .existsSync())
          'downloads/${asset.name}',
    ];
    return RuntimeBinaryInstallState(
      isInstalled: missing.isEmpty,
      installDirectory: installDir.path,
      executablePath: executable?.path,
      missingFiles: missing,
      metadata: metadata,
    );
  }

  Future<String> executablePath(LocalRuntimeId runtimeId) async {
    final state = await getInstallState(runtimeId);
    if (!state.isInstalled || state.executablePath == null) {
      throw RuntimeBinaryException(
        'Runtime ${runtimeId.jsonValue} is not installed: ${state.missingFiles.join(', ')}',
      );
    }
    return state.executablePath!;
  }

  Stream<RuntimeBinaryInstallProgress> ensureInstalled(
    LocalRuntimeId runtimeId,
  ) async* {
    final spec = specForRuntime(runtimeId);
    final currentState = await getInstallState(runtimeId);
    if (currentState.isInstalled) {
      yield RuntimeBinaryInstallProgress(
        runtimeId: runtimeId,
        percentage: 1,
        downloadedBytes: spec.totalBytes,
        totalBytes: spec.totalBytes,
        status: RuntimeBinaryInstallStatus.complete,
      );
      return;
    }

    final installDir = await _installDirectory(spec);
    final downloadsDir = Directory(p.join(installDir.path, 'downloads'));
    await downloadsDir.create(recursive: true);
    final client = _httpClientFactory();
    final totalBytes = spec.totalBytes <= 0 ? 1 : spec.totalBytes;
    var downloadedBytes = 0;

    try {
      yield RuntimeBinaryInstallProgress(
        runtimeId: runtimeId,
        percentage: 0,
        downloadedBytes: 0,
        totalBytes: totalBytes,
        status: RuntimeBinaryInstallStatus.pending,
      );

      for (final asset in spec.assets.where((asset) => asset.isRequired)) {
        final destination = File(p.join(downloadsDir.path, asset.name));
        if (destination.existsSync() &&
            await destination.length() == asset.sizeBytes &&
            await _sha256Matches(destination, asset.sha256)) {
          downloadedBytes += asset.sizeBytes;
          yield RuntimeBinaryInstallProgress(
            runtimeId: runtimeId,
            percentage: (downloadedBytes / totalBytes).clamp(0.0, 1.0),
            downloadedBytes: downloadedBytes,
            totalBytes: totalBytes,
            status: RuntimeBinaryInstallStatus.downloading,
            currentAsset: asset.name,
          );
          continue;
        }

        final progressDeltas = StreamController<int>();
        late final Future<HighPerformanceDownloadResult> downloadFuture;
        try {
          downloadFuture = _downloader
              .download(
                client: client,
                uri: asset.downloadUrl,
                destination: destination,
                expectedSizeBytes: asset.sizeBytes,
                expectedSha256: asset.sha256,
                onProgress: progressDeltas.add,
              )
              .whenComplete(progressDeltas.close);
          await for (final bytesDelta in progressDeltas.stream) {
            downloadedBytes += bytesDelta;
            yield RuntimeBinaryInstallProgress(
              runtimeId: runtimeId,
              percentage: (downloadedBytes / totalBytes).clamp(0.0, 1.0),
              downloadedBytes: downloadedBytes,
              totalBytes: totalBytes,
              status: RuntimeBinaryInstallStatus.downloading,
              currentAsset: asset.name,
            );
          }
          await downloadFuture;
        } on HighPerformanceDownloadException catch (error) {
          throw RuntimeBinaryException(
            error.statusCode == null
                ? 'Failed downloading ${asset.name}: ${error.message}'
                : 'HTTP ${error.statusCode} while downloading ${asset.name}',
          );
        }
      }

      yield RuntimeBinaryInstallProgress(
        runtimeId: runtimeId,
        percentage: 1,
        downloadedBytes: totalBytes,
        totalBytes: totalBytes,
        status: RuntimeBinaryInstallStatus.verifying,
      );

      for (final asset in spec.assets.where((asset) => asset.isRequired)) {
        final archiveFile = File(p.join(downloadsDir.path, asset.name));
        if (!archiveFile.existsSync() ||
            await archiveFile.length() != asset.sizeBytes ||
            !await _sha256Matches(archiveFile, asset.sha256)) {
          throw RuntimeBinaryException(
            'Installed archive verification failed for ${asset.name}',
          );
        }
      }

      yield RuntimeBinaryInstallProgress(
        runtimeId: runtimeId,
        percentage: 1,
        downloadedBytes: totalBytes,
        totalBytes: totalBytes,
        status: RuntimeBinaryInstallStatus.extracting,
      );

      for (final asset in spec.assets.where((asset) => asset.isRequired)) {
        await _archiveExtractor(
          archiveFile: File(p.join(downloadsDir.path, asset.name)),
          destination: installDir,
        );
      }

      final executable = await _findExecutable(installDir, spec.executableName);
      if (executable == null) {
        throw RuntimeBinaryException(
          '${spec.executableName} was not found after extracting ${spec.displayName}',
        );
      }
      await _saveMetadata(spec, executable.path);

      yield RuntimeBinaryInstallProgress(
        runtimeId: runtimeId,
        percentage: 1,
        downloadedBytes: totalBytes,
        totalBytes: totalBytes,
        status: RuntimeBinaryInstallStatus.complete,
      );
    } catch (_) {
      yield RuntimeBinaryInstallProgress(
        runtimeId: runtimeId,
        percentage: 0,
        downloadedBytes: 0,
        totalBytes: totalBytes,
        status: RuntimeBinaryInstallStatus.failed,
      );
      rethrow;
    } finally {
      client.close();
    }
  }

  Future<String> _initRuntimeRoot() async {
    final appDir = await getApplicationSupportDirectory();
    final root = Directory(
      p.join(appDir.path, _runtimeSubdir, _llamaCppSubdir),
    );
    if (!root.existsSync()) {
      await root.create(recursive: true);
    }
    return root.path;
  }

  Future<Directory> _installDirectory(RuntimeBinarySpec spec) async {
    final root = await runtimeRoot;
    final dir = Directory(
      p.join(root, spec.tag, _runtimeFolderName(spec.runtimeId)),
    );
    if (!dir.existsSync()) {
      await dir.create(recursive: true);
    }
    return dir;
  }

  String _runtimeFolderName(LocalRuntimeId runtimeId) => switch (runtimeId) {
        LocalRuntimeId.cudaLlamaCpp => 'cuda',
        LocalRuntimeId.vulkanLlamaCpp => 'vulkan',
        _ => runtimeId.jsonValue,
      };

  Future<void> _saveMetadata(
    RuntimeBinarySpec spec,
    String executablePath,
  ) async {
    final installDir = await _installDirectory(spec);
    final metadata = {
      ...spec.toJson(),
      'executablePath': executablePath,
      'installedAt': DateTime.now().toIso8601String(),
      'provenance': {
        'downloadHost': 'github.com',
        'officialRepo': spec.sourceRepo,
        'releaseTag': spec.tag,
        'releaseUrl': spec.releaseUrl.toString(),
      },
    };
    await File(p.join(installDir.path, _metadataFileName)).writeAsString(
      jsonEncode(metadata),
    );
  }

  Future<File?> _findExecutable(Directory root, String executableName) async {
    if (!root.existsSync()) {
      return null;
    }
    await for (final entity in root.list(recursive: true, followLinks: false)) {
      if (entity is File && p.basename(entity.path) == executableName) {
        return entity;
      }
    }
    return null;
  }

  Future<bool> _sha256Matches(File file, String expected) async {
    final digest = await sha256.bind(file.openRead()).first;
    return digest.toString().toLowerCase() == expected.toLowerCase();
  }

  static Future<void> _extractZipArchive({
    required File archiveFile,
    required Directory destination,
  }) async {
    final archive = ZipDecoder().decodeBytes(await archiveFile.readAsBytes());
    final destinationRoot = p.normalize(destination.absolute.path);
    for (final entry in archive) {
      final normalizedName = entry.name.replaceAll('\\', '/');
      if (normalizedName.trim().isEmpty ||
          normalizedName.startsWith('/') ||
          normalizedName.contains('../')) {
        throw RuntimeBinaryException(
          'Unsafe archive entry path in ${archiveFile.path}: ${entry.name}',
        );
      }
      final outputPath = p.normalize(p.join(destination.path, normalizedName));
      if (!p.isWithin(destinationRoot, outputPath) &&
          outputPath != destinationRoot) {
        throw RuntimeBinaryException(
          'Archive entry escapes runtime directory: ${entry.name}',
        );
      }
      if (entry.isFile) {
        final file = File(outputPath);
        await file.parent.create(recursive: true);
        await file.writeAsBytes(entry.content as List<int>);
      } else {
        await Directory(outputPath).create(recursive: true);
      }
    }
  }
}
