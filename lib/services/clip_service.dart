import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:kidslens_video_editor/data/models/content_category.dart';
import 'package:kidslens_video_editor/data/models/huggingface_model.dart';
import 'package:kidslens_video_editor/data/models/visual_content_category.dart';
import 'package:kidslens_video_editor/native/bindings/onnx_bindings.dart';
import 'package:kidslens_video_editor/services/clip_tokenizer.dart';
import 'package:kidslens_video_editor/services/model_manager_service.dart';

/// Embeddings for a single category, with positive and negative prompts separated.
class CategoryEmbeddings {
  const CategoryEmbeddings({
    required this.positiveEmbeddings,
    required this.negativeEmbeddings,
  });

  /// L2-normalized text embeddings for positive CLIP prompts
  final List<List<double>> positiveEmbeddings;

  /// L2-normalized text embeddings for negative CLIP prompts
  final List<List<double>> negativeEmbeddings;
}

/// Service for CLIP-based zero-shot visual content classification.
///
/// Uses CLIP ViT-B/32 to classify video frames against text prompts defined
/// in visual content categories. Supports pre-computed text embeddings for
/// efficient per-frame classification.
class ClipService {
  ClipService({
    required this.onnx,
    required this.modelManager,
  });

  final ONNXBindings onnx;
  final ModelManagerService modelManager;

  /// CLIP's learned temperature parameter (logit_scale = exp(4.6052) ≈ 100)
  /// Applied to cosine similarities to spread the score range.
  static const double logitScale = 100.0;

  /// Embedding dimension for CLIP ViT-B/32
  static const int embeddingDim = 512;

  /// Cached text embeddings per category ID
  Map<String, CategoryEmbeddings>? _textEmbeddingsCache;

  /// Hash of the categories used to compute cached embeddings
  String? _cacheHash;

  /// Tokenizer instance (loaded lazily for custom prompts)
  ClipTokenizer? _tokenizer;

  /// Whether the service has been initialized
  bool _initialized = false;

  /// Initialize the service (loads ONNX runtime).
  Future<void> initialize() async {
    if (_initialized) return;
    await onnx.initialize();
    _initialized = true;
  }

  /// Dispose of cached resources.
  void dispose() {
    _textEmbeddingsCache = null;
    _cacheHash = null;
    _tokenizer = null;
  }

  /// Pre-compute text embeddings for all CLIP-enabled categories.
  ///
  /// Run the text encoder once per prompt set. Cache results both in memory
  /// and to disk (keyed by prompt text hash). If prompts are unchanged across
  /// runs, the text encoder is not invoked.
  ///
  /// Returns positive and negative embeddings per category.
  Future<Map<String, CategoryEmbeddings>> precomputePromptEmbeddings(
    List<VisualContentCategory> categories,
  ) async {
    final clipCategories = categories.where((c) => c.enabled && c.usesClip).toList();
    if (clipCategories.isEmpty) return {};

    // Compute hash of all prompts to check cache validity
    final hash = _computePromptHash(clipCategories);
    if (_textEmbeddingsCache != null && _cacheHash == hash) {
      return _textEmbeddingsCache!;
    }

    final textModelPath = await _getTextModelPath();
    if (textModelPath == null) {
      throw StateError('CLIP text encoder model not downloaded');
    }

    final cacheDir = await _getCacheDirectory();
    final result = <String, CategoryEmbeddings>{};

    for (final category in clipCategories) {
      // Compute positive embeddings
      final positiveEmbeddings = <List<double>>[];
      for (final prompt in category.clipPrompts) {
        final embedding = await _getOrComputeEmbedding(
          prompt, textModelPath, cacheDir,
        );
        positiveEmbeddings.add(embedding);
      }

      // Compute negative embeddings
      final negativeEmbeddings = <List<double>>[];
      for (final prompt in category.clipNegativePrompts) {
        final embedding = await _getOrComputeEmbedding(
          prompt, textModelPath, cacheDir,
        );
        negativeEmbeddings.add(embedding);
      }

      result[category.id] = CategoryEmbeddings(
        positiveEmbeddings: positiveEmbeddings,
        negativeEmbeddings: negativeEmbeddings,
      );
    }

    _textEmbeddingsCache = result;
    _cacheHash = hash;

    return result;
  }

  /// Pre-compute text embeddings from [ContentCategory] model contributions.
  ///
  /// Extracts CLIP prompts from enabled [ModelContribution]s with
  /// [HuggingFaceModelType.clip] and delegates to the standard method.
  Future<Map<String, CategoryEmbeddings>> precomputeFromContentCategories(
    List<ContentCategory> categories,
  ) async {
    // Convert ContentCategory CLIP contributions to VisualContentCategory
    final clipCategories = <VisualContentCategory>[];
    for (final category in categories) {
      if (!category.enabled) continue;
      for (final contribution in category.enabledModels) {
        if (contribution.modelType != HuggingFaceModelType.clip) continue;
        if (contribution.clipPrompts.isEmpty) continue;

        clipCategories.add(VisualContentCategory(
          id: category.id,
          name: category.name,
          description: category.description,
          clipPrompts: contribution.clipPrompts,
          clipNegativePrompts: contribution.clipNegativePrompts,
          detectionSource: CategoryDetectionSource.clip,
          enabled: true,
        ));
      }
    }

    return precomputePromptEmbeddings(clipCategories);
  }

  /// Classify a single frame against pre-computed text embeddings.
  ///
  /// Returns temperature-scaled discriminative scores per category ID.
  /// Score range is approximately [-15, +15] in practice.
  Future<Map<String, double>> classifyFrame(
    Uint8List rgbData,
    int width,
    int height,
    Map<String, CategoryEmbeddings> textEmbeddings,
  ) async {
    if (textEmbeddings.isEmpty) return {};

    final visionModelPath = await _getVisionModelPath();
    if (visionModelPath == null) {
      throw StateError('CLIP vision encoder model not downloaded');
    }

    // Run vision encoder to get image embedding (preprocessing handled by onnx)
    final imageEmbedding = await onnx.runEmbeddingInference(
      visionModelPath,
      rgbData: rgbData,
      width: width,
      height: height,
      isVisionModel: true,
    );

    // Compute discriminative score per category
    final scores = <String, double>{};
    for (final entry in textEmbeddings.entries) {
      scores[entry.key] = _discriminativeScore(imageEmbedding, entry.value);
    }

    return scores;
  }

  /// Compute temperature-scaled discriminative score for a category.
  ///
  /// 1. Compute cosine similarity between image embedding and each text embedding
  /// 2. Apply logit_scale: scaled_sim = cosine_sim * logitScale
  /// 3. Score = max(scaled_positive_sims) - max(scaled_negative_sims)
  double _discriminativeScore(
    List<double> imageEmbedding,
    CategoryEmbeddings categoryEmbeddings,
  ) {
    // Compute max scaled positive similarity
    var maxPositive = double.negativeInfinity;
    for (final posEmb in categoryEmbeddings.positiveEmbeddings) {
      final sim = _cosineSimilarity(imageEmbedding, posEmb);
      final scaled = sim * logitScale;
      if (scaled > maxPositive) maxPositive = scaled;
    }

    // Compute max scaled negative similarity
    var maxNegative = double.negativeInfinity;
    if (categoryEmbeddings.negativeEmbeddings.isNotEmpty) {
      for (final negEmb in categoryEmbeddings.negativeEmbeddings) {
        final sim = _cosineSimilarity(imageEmbedding, negEmb);
        final scaled = sim * logitScale;
        if (scaled > maxNegative) maxNegative = scaled;
      }
    } else {
      maxNegative = 0.0;
    }

    // If no positive prompts, return 0
    if (categoryEmbeddings.positiveEmbeddings.isEmpty) return 0.0;

    return maxPositive - maxNegative;
  }

  /// Compute cosine similarity between two L2-normalized embeddings.
  ///
  /// Since embeddings are already L2-normalized, cosine similarity is just
  /// the dot product.
  double _cosineSimilarity(List<double> a, List<double> b) {
    assert(a.length == b.length, 'Embedding dimensions must match');
    var dot = 0.0;
    for (var i = 0; i < a.length; i++) {
      dot += a[i] * b[i];
    }
    return dot;
  }

  /// Get or compute a text embedding, using disk cache when available.
  Future<List<double>> _getOrComputeEmbedding(
    String prompt,
    String textModelPath,
    String cacheDir,
  ) async {
    final cacheKey = _promptCacheKey(prompt);
    final cacheFile = File('$cacheDir/$cacheKey.bin');

    // Try loading from disk cache
    if (await cacheFile.exists()) {
      final embedding = await _loadEmbeddingFromDisk(cacheFile);
      if (embedding != null) return embedding;
      // Corrupted cache entry, delete and recompute
      await cacheFile.delete();
    }

    // Tokenize the prompt
    final tokenIds = _tokenizePrompt(prompt);

    // Run text encoder
    final embedding = await onnx.runEmbeddingInference(
      textModelPath,
      tokenIds: tokenIds,
      isVisionModel: false,
    );

    // Save to disk cache
    await _saveEmbeddingToDisk(cacheFile, embedding);

    return embedding;
  }

  /// Tokenize a prompt string, using pre-tokenized constants when available.
  Int32List _tokenizePrompt(String prompt) {
    // Try built-in pre-tokenized first
    final preTokenized = ClipBuiltInTokens.getPreTokenized(prompt);
    if (preTokenized != null) return preTokenized;

    // Fall back to runtime tokenizer for custom prompts
    if (_tokenizer == null) {
      throw StateError(
        'CLIP tokenizer not loaded. Call loadTokenizer() before '
        'using custom prompts.',
      );
    }
    return _tokenizer!.tokenize(prompt);
  }

  /// Load the BPE tokenizer vocabulary for custom prompt support.
  Future<void> loadTokenizer(String vocabPath) async {
    _tokenizer = await ClipTokenizer.load(vocabPath);
  }

  /// Load an embedding from a disk cache file.
  ///
  /// Returns null if the file is corrupted (wrong size).
  Future<List<double>?> _loadEmbeddingFromDisk(File file) async {
    try {
      final bytes = await file.readAsBytes();
      // Each embedding value is a float64 (8 bytes)
      if (bytes.length != embeddingDim * 8) return null;

      final data = bytes.buffer.asFloat64List();
      return data.toList();
    } catch (_) {
      return null;
    }
  }

  /// Save an embedding to a disk cache file.
  Future<void> _saveEmbeddingToDisk(
    File file,
    List<double> embedding,
  ) async {
    try {
      await file.parent.create(recursive: true);
      final data = Float64List.fromList(embedding);
      await file.writeAsBytes(data.buffer.asUint8List());
    } catch (e) {
      debugPrint('ClipService: Failed to cache embedding: $e');
    }
  }

  /// Compute a cache key for a prompt string (SHA256 hex).
  String _promptCacheKey(String prompt) {
    final bytes = utf8.encode(prompt.toLowerCase().trim());
    return sha256.convert(bytes).toString();
  }

  /// Compute a hash of all prompt strings across categories.
  String _computePromptHash(List<VisualContentCategory> categories) {
    final buffer = StringBuffer();
    for (final c in categories) {
      buffer.write(c.id);
      for (final p in c.clipPrompts) {
        buffer.write('|+$p');
      }
      for (final p in c.clipNegativePrompts) {
        buffer.write('|-$p');
      }
    }
    final bytes = utf8.encode(buffer.toString());
    return sha256.convert(bytes).toString();
  }

  /// Get the cache directory for text embeddings.
  Future<String> _getCacheDirectory() async {
    final modelsDir = await modelManager.modelsDirectory;
    return '$modelsDir/clip_cache';
  }

  /// Get the path to the CLIP vision encoder model.
  Future<String?> _getVisionModelPath() async {
    return modelManager.getModelPath('clip-vit-b32-vision-fp16');
  }

  /// Get the path to the CLIP text encoder model.
  Future<String?> _getTextModelPath() async {
    return modelManager.getModelPath('clip-vit-b32-text-fp16');
  }

  /// Clean up cache entries not accessed for [maxAge].
  Future<void> cleanupCache({
    Duration maxAge = const Duration(days: 30),
  }) async {
    try {
      final cacheDir = Directory(await _getCacheDirectory());
      if (!await cacheDir.exists()) return;

      final cutoff = DateTime.now().subtract(maxAge);
      await for (final entity in cacheDir.list()) {
        if (entity is File && entity.path.endsWith('.bin')) {
          final stat = await entity.stat();
          if (stat.accessed.isBefore(cutoff)) {
            await entity.delete();
          }
        }
      }
    } catch (e) {
      debugPrint('ClipService: Cache cleanup failed: $e');
    }
  }
}
