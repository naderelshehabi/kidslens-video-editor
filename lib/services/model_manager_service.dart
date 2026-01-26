import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import 'package:kidslens_video_editor/data/models/models.dart';

/// Progress information for model downloads
class ModelDownloadProgress {
  final String modelId;
  final double percentage;
  final int downloadedBytes;
  final int totalBytes;

  const ModelDownloadProgress({
    required this.modelId,
    required this.percentage,
    required this.downloadedBytes,
    required this.totalBytes,
  });

  /// Whether the download is complete
  bool get isComplete => percentage >= 1.0;

  /// Progress as a string percentage
  String get percentageFormatted => '${(percentage * 100).toStringAsFixed(1)}%';
}

/// Service for managing AI model downloads and storage
class ModelManagerService {
  static const String _modelsSubdir = 'kidslens_models';

  String? _cacheDir;

  /// Get the models cache directory
  Future<String> get modelsDirectory async {
    _cacheDir ??= await _initCacheDir();
    return _cacheDir!;
  }

  Future<String> _initCacheDir() async {
    final appDir = await getApplicationSupportDirectory();
    final modelsDir = Directory(p.join(appDir.path, _modelsSubdir));
    if (!await modelsDir.exists()) {
      await modelsDir.create(recursive: true);
    }
    return modelsDir.path;
  }

  /// Get list of available models (from registry)
  Future<List<ModelInfo>> getAvailableModels() async {
    // Returns the predefined list of supported models
    return _defaultModels;
  }

  /// Get list of downloaded model IDs
  Future<Set<String>> getDownloadedModels() async {
    final dir = await modelsDirectory;
    final modelsDir = Directory(dir);
    final downloaded = <String>{};

    await for (final entity in modelsDir.list()) {
      if (entity is Directory) {
        final modelId = p.basename(entity.path);
        if (await _isModelValid(entity.path)) {
          downloaded.add(modelId);
        }
      }
    }
    return downloaded;
  }

  /// Download a model from HuggingFace
  Stream<ModelDownloadProgress> downloadModel(String modelId) async* {
    final modelInfo = _defaultModels.firstWhere(
      (m) => m.id == modelId,
      orElse: () => throw ModelNotFoundException(modelId),
    );

    final downloadUrl = modelInfo.downloadUrl;
    if (downloadUrl == null) {
      throw ModelDownloadException(modelId, 'No download URL available');
    }

    final dir = await modelsDirectory;
    final modelDir = Directory(p.join(dir, modelId));
    await modelDir.create(recursive: true);

    final client = http.Client();
    try {
      final request = http.Request('GET', Uri.parse(downloadUrl));
      final response = await client.send(request);

      if (response.statusCode != 200) {
        throw ModelDownloadException(
          modelId,
          'HTTP ${response.statusCode}',
        );
      }

      final totalBytes = response.contentLength ?? modelInfo.sizeBytes;
      var downloadedBytes = 0;

      final file = File(p.join(modelDir.path, 'model.onnx'));
      final sink = file.openWrite();

      await for (final chunk in response.stream) {
        sink.add(chunk);
        downloadedBytes += chunk.length;

        yield ModelDownloadProgress(
          modelId: modelId,
          percentage: downloadedBytes / totalBytes,
          downloadedBytes: downloadedBytes,
          totalBytes: totalBytes,
        );
      }

      await sink.close();
    } finally {
      client.close();
    }
  }

  /// Delete a downloaded model
  Future<void> deleteModel(String modelId) async {
    final dir = await modelsDirectory;
    final modelDir = Directory(p.join(dir, modelId));
    if (await modelDir.exists()) {
      await modelDir.delete(recursive: true);
    }
  }

  /// Get the path to a downloaded model
  Future<String?> getModelPath(String modelId) async {
    final dir = await modelsDirectory;
    final modelPath = p.join(dir, modelId, 'model.onnx');
    final file = File(modelPath);
    if (await file.exists()) {
      return modelPath;
    }
    return null;
  }

  /// Validate model integrity
  Future<bool> validateModel(String modelId) async {
    final dir = await modelsDirectory;
    return _isModelValid(p.join(dir, modelId));
  }

  Future<bool> _isModelValid(String modelDir) async {
    final modelFile = File(p.join(modelDir, 'model.onnx'));
    return modelFile.exists();
  }

  /// Default list of supported models
  static final List<ModelInfo> _defaultModels = [
    // Whisper ASR models
    const ModelInfo(
      id: 'whisper-tiny',
      displayName: 'Whisper Tiny',
      type: ModelType.asr,
      sizeBytes: 75 * 1024 * 1024,
      description: 'Fastest, lowest accuracy',
      accuracyPercent: 85,
      speedRating: 5,
      minRamBytes: 1024 * 1024 * 1024,
    ),
    const ModelInfo(
      id: 'whisper-base',
      displayName: 'Whisper Base',
      type: ModelType.asr,
      sizeBytes: 142 * 1024 * 1024,
      description: 'Fast, good accuracy',
      accuracyPercent: 88,
      speedRating: 4,
      minRamBytes: 1024 * 1024 * 1024,
    ),
    const ModelInfo(
      id: 'whisper-small',
      displayName: 'Whisper Small',
      type: ModelType.asr,
      sizeBytes: 466 * 1024 * 1024,
      description: 'Balanced speed/accuracy (Recommended)',
      accuracyPercent: 92,
      speedRating: 3,
      badge: 'Recommended',
      minRamBytes: 2 * 1024 * 1024 * 1024,
    ),
    const ModelInfo(
      id: 'whisper-medium',
      displayName: 'Whisper Medium',
      type: ModelType.asr,
      sizeBytes: 1536 * 1024 * 1024,
      description: 'High accuracy, slower',
      accuracyPercent: 95,
      speedRating: 2,
      minRamBytes: 5 * 1024 * 1024 * 1024,
    ),
    const ModelInfo(
      id: 'whisper-large-v3',
      displayName: 'Whisper Large v3',
      type: ModelType.asr,
      sizeBytes: 2900 * 1024 * 1024,
      description: 'Best accuracy, slowest',
      accuracyPercent: 98,
      speedRating: 1,
      minRamBytes: 10 * 1024 * 1024 * 1024,
    ),
    // Visual detection models (NSFW)
    const ModelInfo(
      id: 'nsfw-mobilenet-v2',
      displayName: 'NSFW MobileNetV2',
      type: ModelType.visual,
      sizeBytes: 20 * 1024 * 1024,
      description: 'Fast NSFW detection',
      accuracyPercent: 91,
      speedRating: 5,
      minRamBytes: 512 * 1024 * 1024,
    ),
    const ModelInfo(
      id: 'nsfw-efficientnet-b4',
      displayName: 'NSFW EfficientNet-B4',
      type: ModelType.visual,
      sizeBytes: 75 * 1024 * 1024,
      description: 'High accuracy NSFW detection',
      accuracyPercent: 95,
      speedRating: 3,
      badge: 'Recommended',
      minRamBytes: 1024 * 1024 * 1024,
    ),
    // Violence detection models
    const ModelInfo(
      id: 'violence-mobilenet',
      displayName: 'Violence MobileNet',
      type: ModelType.visual,
      sizeBytes: 15 * 1024 * 1024,
      description: 'Fast violence detection',
      accuracyPercent: 94,
      speedRating: 5,
      minRamBytes: 512 * 1024 * 1024,
    ),
    const ModelInfo(
      id: 'violence-vit-base',
      displayName: 'Violence ViT-Base',
      type: ModelType.visual,
      sizeBytes: 330 * 1024 * 1024,
      description: 'Best accuracy violence detection',
      accuracyPercent: 99,
      speedRating: 2,
      minRamBytes: 2 * 1024 * 1024 * 1024,
    ),
  ];
}

/// Exception thrown when a model is not found
class ModelNotFoundException implements Exception {
  final String modelId;
  ModelNotFoundException(this.modelId);

  @override
  String toString() => 'Model not found: $modelId';
}

/// Exception thrown when model download fails
class ModelDownloadException implements Exception {
  final String modelId;
  final String reason;
  ModelDownloadException(this.modelId, this.reason);

  @override
  String toString() => 'Failed to download model $modelId: $reason';
}
