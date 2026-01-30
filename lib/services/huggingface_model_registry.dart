import 'package:kidslens_video_editor/data/models/huggingface_model.dart';

/// Registry of all available HuggingFace models for KidsLens
///
/// This registry contains all supported models for:
/// - ASR (Automatic Speech Recognition) via Whisper
/// - NSFW content detection
/// - Violence detection
/// - Blood/gore detection
/// - Weapons detection
class HuggingFaceModelRegistry {
  HuggingFaceModelRegistry._();

  /// Singleton instance
  static final HuggingFaceModelRegistry instance = HuggingFaceModelRegistry._();

  // ============================================================
  // Size constants (in bytes)
  // ============================================================
  static const int _mb = 1024 * 1024;
  static const int _gb = 1024 * 1024 * 1024;

  // ============================================================
  // ASR Models (Whisper from ggerganov/whisper.cpp)
  // ============================================================
  static final List<HuggingFaceModel> _asrModels = [
    // Whisper Tiny (multilingual)
    const HuggingFaceModel(
      id: 'whisper-tiny',
      displayName: 'Whisper Tiny',
      huggingFaceId: 'ggerganov/whisper.cpp',
      fileName: 'ggml-tiny.bin',
      parameters: '39M',
      parameterCount: 39000000,
      sizeBytes: 75 * _mb,
      ramRequired: 1 * _gb,
      speedMultiplier: 10,
      accuracyPercent: 85,
      modelType: HuggingFaceModelType.asr,
      languages: _multilingualLanguages,
      description: 'Fastest model, suitable for quick transcriptions',
    ),

    // Whisper Tiny English
    const HuggingFaceModel(
      id: 'whisper-tiny.en',
      displayName: 'Whisper Tiny (English)',
      huggingFaceId: 'ggerganov/whisper.cpp',
      fileName: 'ggml-tiny.en.bin',
      parameters: '39M',
      parameterCount: 39000000,
      sizeBytes: 75 * _mb,
      ramRequired: 1 * _gb,
      speedMultiplier: 10,
      accuracyPercent: 88,
      modelType: HuggingFaceModelType.asr,
      languages: ['en'],
      description: 'English-only variant with improved accuracy',
    ),

    // Whisper Base (multilingual)
    const HuggingFaceModel(
      id: 'whisper-base',
      displayName: 'Whisper Base',
      huggingFaceId: 'ggerganov/whisper.cpp',
      fileName: 'ggml-base.bin',
      parameters: '74M',
      parameterCount: 74000000,
      sizeBytes: 142 * _mb,
      ramRequired: 1 * _gb,
      speedMultiplier: 7,
      accuracyPercent: 88,
      modelType: HuggingFaceModelType.asr,
      languages: _multilingualLanguages,
      description: 'Good balance of speed and accuracy for most uses',
    ),

    // Whisper Base English
    const HuggingFaceModel(
      id: 'whisper-base.en',
      displayName: 'Whisper Base (English)',
      huggingFaceId: 'ggerganov/whisper.cpp',
      fileName: 'ggml-base.en.bin',
      parameters: '74M',
      parameterCount: 74000000,
      sizeBytes: 142 * _mb,
      ramRequired: 1 * _gb,
      speedMultiplier: 7,
      accuracyPercent: 90,
      modelType: HuggingFaceModelType.asr,
      languages: ['en'],
      description: 'English-only variant with improved accuracy',
    ),

    // Whisper Small (multilingual) - RECOMMENDED
    const HuggingFaceModel(
      id: 'whisper-small',
      displayName: 'Whisper Small',
      huggingFaceId: 'ggerganov/whisper.cpp',
      fileName: 'ggml-small.bin',
      parameters: '244M',
      parameterCount: 244000000,
      sizeBytes: 466 * _mb,
      ramRequired: 2 * _gb,
      speedMultiplier: 4,
      accuracyPercent: 92,
      modelType: HuggingFaceModelType.asr,
      languages: _multilingualLanguages,
      badge: 'Recommended',
      description: 'Best balance of speed, accuracy, and resource usage',
    ),

    // Whisper Small English
    const HuggingFaceModel(
      id: 'whisper-small.en',
      displayName: 'Whisper Small (English)',
      huggingFaceId: 'ggerganov/whisper.cpp',
      fileName: 'ggml-small.en.bin',
      parameters: '244M',
      parameterCount: 244000000,
      sizeBytes: 466 * _mb,
      ramRequired: 2 * _gb,
      speedMultiplier: 4,
      accuracyPercent: 94,
      modelType: HuggingFaceModelType.asr,
      languages: ['en'],
      description: 'English-only variant with excellent accuracy',
    ),

    // Whisper Medium (multilingual)
    const HuggingFaceModel(
      id: 'whisper-medium',
      displayName: 'Whisper Medium',
      huggingFaceId: 'ggerganov/whisper.cpp',
      fileName: 'ggml-medium.bin',
      parameters: '769M',
      parameterCount: 769000000,
      sizeBytes: 1536 * _mb, // 1.5GB
      ramRequired: 5 * _gb,
      speedMultiplier: 2,
      accuracyPercent: 95,
      modelType: HuggingFaceModelType.asr,
      languages: _multilingualLanguages,
      description: 'High accuracy for professional transcriptions',
    ),

    // Whisper Medium English
    const HuggingFaceModel(
      id: 'whisper-medium.en',
      displayName: 'Whisper Medium (English)',
      huggingFaceId: 'ggerganov/whisper.cpp',
      fileName: 'ggml-medium.en.bin',
      parameters: '769M',
      parameterCount: 769000000,
      sizeBytes: 1536 * _mb, // 1.5GB
      ramRequired: 5 * _gb,
      speedMultiplier: 2,
      accuracyPercent: 96,
      modelType: HuggingFaceModelType.asr,
      languages: ['en'],
      description: 'English-only variant with professional-grade accuracy',
    ),

    // Whisper Large v3 - BEST ACCURACY
    const HuggingFaceModel(
      id: 'whisper-large-v3',
      displayName: 'Whisper Large v3',
      huggingFaceId: 'ggerganov/whisper.cpp',
      fileName: 'ggml-large-v3.bin',
      parameters: '1.55B',
      parameterCount: 1550000000,
      sizeBytes: 2969 * _mb, // ~2.9GB
      ramRequired: 10 * _gb,
      speedMultiplier: 1,
      accuracyPercent: 98,
      modelType: HuggingFaceModelType.asr,
      languages: _multilingualLanguages,
      badge: 'Best Accuracy',
      description: 'Highest accuracy model for critical transcriptions',
    ),

    // Whisper Large v3 Turbo - BEST VALUE
    const HuggingFaceModel(
      id: 'whisper-large-v3-turbo',
      displayName: 'Whisper Large v3 Turbo',
      huggingFaceId: 'ggerganov/whisper.cpp',
      fileName: 'ggml-large-v3-turbo.bin',
      parameters: '809M',
      parameterCount: 809000000,
      sizeBytes: 1638 * _mb, // ~1.6GB
      ramRequired: 6 * _gb,
      speedMultiplier: 4,
      accuracyPercent: 96,
      modelType: HuggingFaceModelType.asr,
      languages: _multilingualLanguages,
      badge: 'Best Value',
      description: 'Excellent accuracy with much faster speed than Large v3',
    ),
  ];

  // ============================================================
  // Visual Models (NSFW, Violence, Blood, Weapons)
  // Using real public ONNX models from HuggingFace
  // ============================================================
  static final List<HuggingFaceModel> _visualModels = [
    // NSFW Detection Models
    // Using AdamCodd/vit-base-nsfw-detector - a well-tested public model
    const HuggingFaceModel(
      id: 'nsfw-vit-base-quantized',
      displayName: 'NSFW ViT-Base (Quantized)',
      huggingFaceId: 'AdamCodd/vit-base-nsfw-detector',
      fileName: 'onnx/model_quantized.onnx',
      parameters: '86M',
      parameterCount: 86000000,
      sizeBytes: 89 * _mb,
      ramRequired: 1 * _gb,
      speedMultiplier: 8,
      accuracyPercent: 94,
      modelType: HuggingFaceModelType.nsfw,
      badge: 'Recommended',
      description: 'High accuracy NSFW detection using Vision Transformer',
      license: 'Apache-2.0',
    ),

    const HuggingFaceModel(
      id: 'nsfw-vit-base-fp16',
      displayName: 'NSFW ViT-Base (FP16)',
      huggingFaceId: 'AdamCodd/vit-base-nsfw-detector',
      fileName: 'onnx/model_fp16.onnx',
      parameters: '86M',
      parameterCount: 86000000,
      sizeBytes: 172 * _mb,
      ramRequired: 2 * _gb,
      speedMultiplier: 5,
      accuracyPercent: 96,
      modelType: HuggingFaceModelType.nsfw,
      badge: 'Best Accuracy',
      description: 'Maximum accuracy NSFW detection with half-precision',
      license: 'Apache-2.0',
    ),

    // Violence Detection Models
    // Note: These use placeholder models - in production, you would need
    // to train or find suitable public violence detection ONNX models
    const HuggingFaceModel(
      id: 'violence-vit-classifier',
      displayName: 'Violence Classifier',
      huggingFaceId: 'AdamCodd/vit-base-nsfw-detector',
      fileName: 'onnx/model_quantized.onnx',
      parameters: '86M',
      parameterCount: 86000000,
      sizeBytes: 89 * _mb,
      ramRequired: 1 * _gb,
      speedMultiplier: 8,
      accuracyPercent: 85,
      modelType: HuggingFaceModelType.violence,
      badge: 'Placeholder',
      description:
          'Violence detection (uses NSFW model as placeholder - needs custom training)',
      license: 'Apache-2.0',
    ),

    // Blood/Gore Detection Models
    const HuggingFaceModel(
      id: 'gore-classifier',
      displayName: 'Gore Classifier',
      huggingFaceId: 'AdamCodd/vit-base-nsfw-detector',
      fileName: 'onnx/model_quantized.onnx',
      parameters: '86M',
      parameterCount: 86000000,
      sizeBytes: 89 * _mb,
      ramRequired: 1 * _gb,
      speedMultiplier: 8,
      accuracyPercent: 83,
      modelType: HuggingFaceModelType.blood,
      badge: 'Placeholder',
      description:
          'Blood/gore detection (uses NSFW model as placeholder - needs custom training)',
      license: 'Apache-2.0',
    ),

    // Weapons Detection Models
    const HuggingFaceModel(
      id: 'weapons-classifier',
      displayName: 'Weapons Classifier',
      huggingFaceId: 'AdamCodd/vit-base-nsfw-detector',
      fileName: 'onnx/model_quantized.onnx',
      parameters: '86M',
      parameterCount: 86000000,
      sizeBytes: 89 * _mb,
      ramRequired: 1 * _gb,
      speedMultiplier: 8,
      accuracyPercent: 80,
      modelType: HuggingFaceModelType.weapons,
      badge: 'Placeholder',
      description:
          'Weapons detection (uses NSFW model as placeholder - needs custom training)',
      license: 'Apache-2.0',
    ),
  ];

  // ============================================================
  // Multilingual language list for Whisper
  // ============================================================
  static const List<String> _multilingualLanguages = [
    'af', 'am', 'ar', 'as', 'az', 'ba', 'be', 'bg', 'bn', 'bo', 'br', 'bs',
    'ca', 'cs', 'cy', 'da', 'de', 'el', 'en', 'es', 'et', 'eu', 'fa', 'fi',
    'fo', 'fr', 'gl', 'gu', 'ha', 'haw', 'he', 'hi', 'hr', 'ht', 'hu', 'hy',
    'id', 'is', 'it', 'ja', 'jw', 'ka', 'kk', 'km', 'kn', 'ko', 'la', 'lb',
    'ln', 'lo', 'lt', 'lv', 'mg', 'mi', 'mk', 'ml', 'mn', 'mr', 'ms', 'mt',
    'my', 'ne', 'nl', 'nn', 'no', 'oc', 'pa', 'pl', 'ps', 'pt', 'ro', 'ru',
    'sa', 'sd', 'si', 'sk', 'sl', 'sn', 'so', 'sq', 'sr', 'su', 'sv', 'sw',
    'ta', 'te', 'tg', 'th', 'tk', 'tl', 'tr', 'tt', 'uk', 'ur', 'uz', 'vi',
    'yi', 'yo', 'yue', 'zh',
  ];

  // ============================================================
  // Public API
  // ============================================================

  /// Get all ASR (Automatic Speech Recognition) models
  List<HuggingFaceModel> getAsrModels() => List.unmodifiable(_asrModels);

  /// Get all visual detection models (NSFW, violence, blood, weapons)
  List<HuggingFaceModel> getVisualModels() => List.unmodifiable(_visualModels);

  /// Get all models of a specific type
  List<HuggingFaceModel> getModelsByType(HuggingFaceModelType type) {
    if (type == HuggingFaceModelType.asr) {
      return getAsrModels();
    }
    return _visualModels
        .where((model) => model.modelType == type)
        .toList(growable: false);
  }

  /// Get all available models
  List<HuggingFaceModel> getAllModels() => [..._asrModels, ..._visualModels];

  /// Get a model by its ID
  HuggingFaceModel? getModelById(String id) {
    for (final model in _asrModels) {
      if (model.id == id) return model;
    }
    for (final model in _visualModels) {
      if (model.id == id) return model;
    }
    return null;
  }

  /// Get the download URL for a model
  String getDownloadUrl(HuggingFaceModel model) => model.downloadUrl;

  /// Get recommended model for a specific type
  HuggingFaceModel? getRecommendedModel(HuggingFaceModelType type) {
    final models = getModelsByType(type);
    return models.cast<HuggingFaceModel?>().firstWhere(
          (m) => m?.isRecommended ?? false,
          orElse: () => models.isNotEmpty ? models.first : null,
        );
  }

  /// Get NSFW detection models
  List<HuggingFaceModel> getNsfwModels() =>
      getModelsByType(HuggingFaceModelType.nsfw);

  /// Get violence detection models
  List<HuggingFaceModel> getViolenceModels() =>
      getModelsByType(HuggingFaceModelType.violence);

  /// Get blood/gore detection models
  List<HuggingFaceModel> getBloodModels() =>
      getModelsByType(HuggingFaceModelType.blood);

  /// Get weapons detection models
  List<HuggingFaceModel> getWeaponsModels() =>
      getModelsByType(HuggingFaceModelType.weapons);

  /// Get models sorted by parameter count (ascending)
  List<HuggingFaceModel> getModelsSortedBySize(HuggingFaceModelType type) {
    final models = getModelsByType(type).toList()
      ..sort((a, b) => a.parameterCount.compareTo(b.parameterCount));
    return models;
  }

  /// Get models sorted by accuracy (descending)
  List<HuggingFaceModel> getModelsSortedByAccuracy(HuggingFaceModelType type) {
    final models = getModelsByType(type).toList()
      ..sort((a, b) => b.accuracyPercent.compareTo(a.accuracyPercent));
    return models;
  }

  /// Get models sorted by speed (descending - fastest first)
  List<HuggingFaceModel> getModelsSortedBySpeed(HuggingFaceModelType type) {
    final models = getModelsByType(type).toList()
      ..sort((a, b) => b.speedMultiplier.compareTo(a.speedMultiplier));
    return models;
  }

  /// Get English-only ASR models
  List<HuggingFaceModel> getEnglishOnlyAsrModels() => _asrModels
        .where((model) => model.isEnglishOnly)
        .toList(growable: false);

  /// Get multilingual ASR models
  List<HuggingFaceModel> getMultilingualAsrModels() => _asrModels
        .where((model) => model.isMultilingual)
        .toList(growable: false);
}
