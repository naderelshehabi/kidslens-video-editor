import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:http/http.dart' as http;
import 'package:kidslens_video_editor/data/models/models.dart';
import 'package:kidslens_video_editor/services/huggingface_model_registry.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

/// Progress information for model downloads
class ModelDownloadProgress {
  const ModelDownloadProgress({
    required this.modelId,
    required this.percentage,
    required this.downloadedBytes,
    required this.totalBytes,
    this.status = ModelDownloadStatus.downloading,
  });

  final String modelId;
  final double percentage;
  final int downloadedBytes;
  final int totalBytes;
  final ModelDownloadStatus status;

  /// Whether the download is complete
  bool get isComplete =>
      percentage >= 1.0 || status == ModelDownloadStatus.complete;

  /// Whether the download failed
  bool get isFailed => status == ModelDownloadStatus.failed;

  /// Progress as a string percentage
  String get percentageFormatted => '${(percentage * 100).toStringAsFixed(1)}%';

  /// Bytes remaining to download
  int get bytesRemaining => totalBytes - downloadedBytes;

  /// Human-readable downloaded size
  String get downloadedFormatted => _formatBytes(downloadedBytes);

  /// Human-readable total size
  String get totalFormatted => _formatBytes(totalBytes);

  static String _formatBytes(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(2)} GB';
  }

  ModelDownloadProgress copyWith({
    String? modelId,
    double? percentage,
    int? downloadedBytes,
    int? totalBytes,
    ModelDownloadStatus? status,
  }) =>
      ModelDownloadProgress(
        modelId: modelId ?? this.modelId,
        percentage: percentage ?? this.percentage,
        downloadedBytes: downloadedBytes ?? this.downloadedBytes,
        totalBytes: totalBytes ?? this.totalBytes,
        status: status ?? this.status,
      );
}

/// Status of a model download
enum ModelDownloadStatus {
  pending,
  downloading,
  verifying,
  complete,
  failed,
}

/// Service for managing AI model downloads and storage
class ModelManagerService {
  ModelManagerService({
    HuggingFaceModelRegistry? registry,
    String? customModelsPath,
  })  : _registry = registry ?? HuggingFaceModelRegistry.instance,
        _customModelsPath = customModelsPath;

  static const String _modelsSubdir = 'kidslens_models';
  static const String _metadataFileName = 'model_metadata.json';
  static const Map<String, List<String>> _legacyModelDirectoryAliases = {
    'nsfw-nudenet-detector-640': <String>['nsfw-nudenet-detector-640-community'],
  };

  final HuggingFaceModelRegistry _registry;
  final String? _customModelsPath;
  String? _cacheDir;

  /// Get the models cache directory
  Future<String> get modelsDirectory async {
    // Use custom path if provided
    if (_customModelsPath != null && _customModelsPath.isNotEmpty) {
      final customDir = Directory(_customModelsPath);
      if (!customDir.existsSync()) {
        customDir.createSync(recursive: true);
      }
      return _customModelsPath;
    }
    _cacheDir ??= await _initCacheDir();
    return _cacheDir!;
  }

  /// Set a custom models directory
  /// Returns the new path if valid, or throws if invalid
  static Future<String> validateModelsPath(String path) async {
    final dir = Directory(path);
    if (!dir.existsSync()) {
      try {
        dir.createSync(recursive: true);
      } catch (e) {
        throw ModelStorageException('Cannot create directory: $path');
      }
    }

    // Test write access
    final testFile = File(p.join(path, '.write_test'));
    try {
      await testFile.writeAsString('test');
      await testFile.delete();
    } catch (e) {
      throw ModelStorageException('Cannot write to directory: $path');
    }

    return path;
  }

  Future<String> _initCacheDir() async {
    final appDir = await getApplicationSupportDirectory();
    final modelsDir = Directory(p.join(appDir.path, _modelsSubdir));
    if (!modelsDir.existsSync()) {
      modelsDir.createSync(recursive: true);
    }
    return modelsDir.path;
  }

  /// Get list of available models from HuggingFace registry
  Future<List<HuggingFaceModel>> getAvailableModels() async =>
      _registry.getAllModels();

  /// Look up model info (accuracy, type, etc.) by ID
  HuggingFaceModel? getModelInfo(String modelId) =>
      _registry.getModelById(modelId);

  /// Get list of downloaded model IDs
  Future<Set<String>> getDownloadedModels() async {
    final dir = await modelsDirectory;
    final modelsDir = Directory(dir);
    final downloaded = <String>{};

    if (!modelsDir.existsSync()) {
      return downloaded;
    }

    await for (final entity in modelsDir.list()) {
      if (entity is Directory) {
        final modelId = p.basename(entity.path);
        if (await _isModelValid(entity.path)) {
          downloaded.add(_canonicalizeModelId(modelId));
        }
      }
    }
    return downloaded;
  }

  /// Download a model from HuggingFace with progress streaming
  Stream<ModelDownloadProgress> downloadModel(String modelId) async* {
    final model = _registry.getModelById(modelId);
    if (model == null) {
      throw ModelNotFoundException(modelId);
    }

    final filesToDownload = <String>[
      model.fileName,
      ..._registry.getAdditionalModelFiles(model),
    ];
    final dir = await modelsDirectory;
    final modelDir = Directory(p.join(dir, modelId));
    await modelDir.create(recursive: true);

    final client = http.Client();
    try {
      yield ModelDownloadProgress(
        modelId: modelId,
        percentage: 0,
        downloadedBytes: 0,
        totalBytes: model.sizeBytes <= 0 ? 1 : model.sizeBytes,
        status: ModelDownloadStatus.pending,
      );

      var downloadedBytes = 0;
      final totalBytes = model.sizeBytes <= 0 ? 1 : model.sizeBytes;
      for (final fileName in filesToDownload) {
        final downloadUrls = _registry.getDownloadUrlsForFile(model, fileName);
        http.StreamedResponse? response;
        String? failureReason;

        for (final downloadUrl in downloadUrls) {
          try {
            final request = http.Request('GET', Uri.parse(downloadUrl));
            final candidate = await client.send(request);
            if (candidate.statusCode == 200) {
              response = candidate;
              break;
            }

            failureReason =
                'HTTP ${candidate.statusCode} from $downloadUrl while downloading $fileName';
            await candidate.stream.drain<void>();
          } catch (e) {
            failureReason =
                'Request failed for $downloadUrl while downloading $fileName: $e';
          }
        }

        if (response == null) {
          throw ModelDownloadException(
            modelId,
            failureReason ??
                'Unable to download $fileName from any configured source',
          );
        }

        final file = File(p.join(modelDir.path, fileName));
        await file.parent.create(recursive: true);
        final sink = file.openWrite();
        await for (final chunk in response.stream) {
          sink.add(chunk);
          downloadedBytes += chunk.length;
          final percentage = (downloadedBytes / totalBytes).clamp(0.0, 1.0);
          yield ModelDownloadProgress(
            modelId: modelId,
            percentage: percentage,
            downloadedBytes: downloadedBytes,
            totalBytes: totalBytes,
          );
        }
        await sink.close();
      }

      // Verifying model
      yield ModelDownloadProgress(
        modelId: modelId,
        percentage: 1,
        downloadedBytes: totalBytes,
        totalBytes: totalBytes,
        status: ModelDownloadStatus.verifying,
      );

      // Save model metadata
      await _saveModelMetadata(modelId, model);

      // Final complete status
      yield ModelDownloadProgress(
        modelId: modelId,
        percentage: 1,
        downloadedBytes: totalBytes,
        totalBytes: totalBytes,
        status: ModelDownloadStatus.complete,
      );
    } catch (e) {
      // Clean up on error
      if (modelDir.existsSync()) {
        await modelDir.delete(recursive: true);
      }
      yield ModelDownloadProgress(
        modelId: modelId,
        percentage: 0,
        downloadedBytes: 0,
        totalBytes: model.sizeBytes,
        status: ModelDownloadStatus.failed,
      );
      rethrow;
    } finally {
      client.close();
    }
  }

  /// Download from a custom URL with progress callback
  Future<void> downloadFromUrl(
    String url,
    String savePath, {
    void Function(double progress)? onProgress,
  }) async {
    final client = http.Client();
    try {
      final request = http.Request('GET', Uri.parse(url));
      final response = await client.send(request);

      if (response.statusCode != 200) {
        throw Exception('HTTP ${response.statusCode}');
      }

      final totalBytes = response.contentLength ?? 0;
      var downloadedBytes = 0;

      final file = File(savePath);
      await file.parent.create(recursive: true);
      final sink = file.openWrite();

      await for (final chunk in response.stream) {
        sink.add(chunk);
        downloadedBytes += chunk.length;

        if (totalBytes > 0 && onProgress != null) {
          onProgress(downloadedBytes / totalBytes);
        }
      }

      await sink.close();
    } finally {
      client.close();
    }
  }

  /// Delete a downloaded model
  Future<void> deleteModel(String modelId) async {
    final dir = await modelsDirectory;
    for (final candidateId in _candidateModelIds(modelId)) {
      final modelDir = Directory(p.join(dir, candidateId));
      if (modelDir.existsSync()) {
        await modelDir.delete(recursive: true);
      }
    }
  }

  /// Get the path to a downloaded model file
  Future<String?> getModelPath(String modelId) async {
    final modelDir = await _findExistingModelDirectory(modelId);
    if (modelDir == null) {
      return null;
    }

    // Try to find the model file by checking common extensions
    final possibleExtensions = ['.bin', '.onnx', '.pt', '.pth', '.h5'];
    for (final ext in possibleExtensions) {
      final files = modelDir
          .listSync(recursive: true)
          .whereType<File>()
          .where((f) => f.path.endsWith(ext));
      if (files.isNotEmpty) {
        return files.first.path;
      }
    }

    // Check for model file from registry
    final model = _registry.getModelById(modelId);
    if (model != null) {
      final expectedPath = p.join(modelDir.path, model.fileName);
      if (File(expectedPath).existsSync()) {
        return expectedPath;
      }
    }

    return null;
  }

  /// Validate model integrity
  Future<bool> validateModel(String modelId) async {
    final modelDir = await _findExistingModelDirectory(modelId);
    if (modelDir == null) {
      return false;
    }
    final modelDirPath = modelDir.path;

    // Basic validation: check if model file exists
    if (!await _isModelValid(modelDirPath)) {
      return false;
    }

    // Advanced validation: check file size matches expected
    final model = _registry.getModelById(modelId);
    if (model != null) {
      final primaryModelPath = await getModelPath(modelId);
      if (primaryModelPath == null) {
        return false;
      }

      var actualSize = await File(primaryModelPath).length();
      for (final fileName in _registry.getAdditionalModelFiles(model)) {
        final file = File(p.join(modelDirPath, fileName));
        if (!file.existsSync()) {
          return false;
        }
        actualSize += await file.length();
      }
      // Allow 5% tolerance for size differences.
      final tolerance = model.sizeBytes * 0.05;
      if ((actualSize - model.sizeBytes).abs() > tolerance) {
        return false;
      }
    }

    return true;
  }

  /// Validate file integrity with checksum
  Future<bool> validateFileChecksum(
    String filePath,
    String expectedChecksum, {
    String algorithm = 'sha256',
  }) async {
    final file = File(filePath);
    if (!file.existsSync()) {
      return false;
    }

    final bytes = await file.readAsBytes();
    final digest =
        algorithm == 'md5' ? md5.convert(bytes) : sha256.convert(bytes);

    return digest.toString() == expectedChecksum;
  }

  Future<bool> _isModelValid(String modelDir) async {
    final dir = Directory(modelDir);
    if (!dir.existsSync()) {
      return false;
    }

    // Prefer exact registry file path when available.
    final modelId = p.basename(modelDir);
    final model = _registry.getModelById(modelId);
    if (model != null) {
      final expectedPath = p.join(modelDir, model.fileName);
      final requiredPaths = <String>[
        expectedPath,
        ..._registry
            .getAdditionalModelFiles(model)
            .map((name) => p.join(modelDir, name)),
      ];
      if (requiredPaths.every((path) => File(path).existsSync())) {
        return true;
      }
    }

    // Fallback: recursively check for any supported model file.
    await for (final entity in dir.list(recursive: true, followLinks: false)) {
      if (entity is! File) continue;
      final ext = p.extension(entity.path).toLowerCase();
      if (['.bin', '.onnx', '.pt', '.pth', '.h5'].contains(ext)) {
        return true;
      }
    }
    return false;
  }

  Future<void> _saveModelMetadata(
    String modelId,
    HuggingFaceModel model,
  ) async {
    final dir = await modelsDirectory;
    final metadataPath = p.join(dir, modelId, _metadataFileName);
    final metadata = {
      'id': model.id,
      'displayName': model.displayName,
      'huggingFaceId': model.huggingFaceId,
      'fileName': model.fileName,
      'sizeBytes': model.sizeBytes,
      'downloadedAt': DateTime.now().toIso8601String(),
    };
    await File(metadataPath).writeAsString(jsonEncode(metadata));
  }

  /// Get metadata for a downloaded model
  Future<Map<String, dynamic>?> getModelMetadata(String modelId) async {
    final dir = await modelsDirectory;
    final metadataPath = p.join(dir, modelId, _metadataFileName);
    final file = File(metadataPath);
    if (!file.existsSync()) {
      return null;
    }
    final content = await file.readAsString();
    return jsonDecode(content) as Map<String, dynamic>;
  }

  /// Get total disk space used by all downloaded models
  Future<int> getTotalDiskUsage() async {
    final dir = await modelsDirectory;
    final modelsDir = Directory(dir);
    if (!modelsDir.existsSync()) {
      return 0;
    }

    var totalBytes = 0;
    await for (final entity in modelsDir.list(recursive: true)) {
      if (entity is File) {
        totalBytes += await entity.length();
      }
    }
    return totalBytes;
  }

  /// Clear all downloaded models
  Future<void> clearAllModels() async {
    final dir = await modelsDirectory;
    final modelsDir = Directory(dir);
    if (modelsDir.existsSync()) {
      await modelsDir.delete(recursive: true);
      await modelsDir.create(recursive: true);
    }
  }

  String _canonicalizeModelId(String modelId) =>
      _registry.getModelById(modelId)?.id ?? modelId;

  Iterable<String> _candidateModelIds(String modelId) sync* {
    final canonicalId = _canonicalizeModelId(modelId);
    yield canonicalId;
    for (final alias in _legacyModelDirectoryAliases[canonicalId] ?? const <String>[]) {
      yield alias;
    }
  }

  Future<Directory?> _findExistingModelDirectory(String modelId) async {
    final dir = await modelsDirectory;
    for (final candidateId in _candidateModelIds(modelId)) {
      final candidateDir = Directory(p.join(dir, candidateId));
      if (candidateDir.existsSync()) {
        return candidateDir;
      }
    }
    return null;
  }
}

/// Exception thrown when a model is not found
class ModelNotFoundException implements Exception {
  ModelNotFoundException(this.modelId);

  final String modelId;

  @override
  String toString() => 'Model not found: $modelId';
}

/// Exception thrown when model download fails
class ModelDownloadException implements Exception {
  ModelDownloadException(this.modelId, this.reason);

  final String modelId;
  final String reason;

  @override
  String toString() => 'Failed to download model $modelId: $reason';
}

/// Exception thrown when model storage path is invalid
class ModelStorageException implements Exception {
  ModelStorageException(this.message);

  final String message;

  @override
  String toString() => 'Model storage error: $message';
}
