import 'package:kidslens_video_editor/data/models/huggingface_model.dart';

/// Registry of all available HuggingFace models for KidsLens.
///
/// Non-ASR model families have been removed; only ASR models are registered.
class HuggingFaceModelRegistry {
  HuggingFaceModelRegistry._();

  /// Singleton instance
  static final HuggingFaceModelRegistry instance = HuggingFaceModelRegistry._();

  static const int _mb = 1024 * 1024;
  static const int _gb = 1024 * 1024 * 1024;

  static final List<HuggingFaceModel> _asrModels = [
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
    const HuggingFaceModel(
      id: 'whisper-medium',
      displayName: 'Whisper Medium',
      huggingFaceId: 'ggerganov/whisper.cpp',
      fileName: 'ggml-medium.bin',
      parameters: '769M',
      parameterCount: 769000000,
      sizeBytes: 1536 * _mb,
      ramRequired: 5 * _gb,
      speedMultiplier: 2,
      accuracyPercent: 95,
      modelType: HuggingFaceModelType.asr,
      languages: _multilingualLanguages,
      description: 'High accuracy for professional transcriptions',
    ),
    const HuggingFaceModel(
      id: 'whisper-medium.en',
      displayName: 'Whisper Medium (English)',
      huggingFaceId: 'ggerganov/whisper.cpp',
      fileName: 'ggml-medium.en.bin',
      parameters: '769M',
      parameterCount: 769000000,
      sizeBytes: 1536 * _mb,
      ramRequired: 5 * _gb,
      speedMultiplier: 2,
      accuracyPercent: 96,
      modelType: HuggingFaceModelType.asr,
      languages: ['en'],
      description: 'English-only variant with professional-grade accuracy',
    ),
    const HuggingFaceModel(
      id: 'whisper-large-v3',
      displayName: 'Whisper Large v3',
      huggingFaceId: 'ggerganov/whisper.cpp',
      fileName: 'ggml-large-v3.bin',
      parameters: '1.55B',
      parameterCount: 1550000000,
      sizeBytes: 2969 * _mb,
      ramRequired: 10 * _gb,
      speedMultiplier: 1,
      accuracyPercent: 98,
      modelType: HuggingFaceModelType.asr,
      languages: _multilingualLanguages,
      badge: 'Best Accuracy',
      description: 'Highest accuracy model for critical transcriptions',
    ),
    const HuggingFaceModel(
      id: 'whisper-large-v3-turbo',
      displayName: 'Whisper Large v3 Turbo',
      huggingFaceId: 'ggerganov/whisper.cpp',
      fileName: 'ggml-large-v3-turbo.bin',
      parameters: '809M',
      parameterCount: 809000000,
      sizeBytes: 1638 * _mb,
      ramRequired: 6 * _gb,
      speedMultiplier: 4,
      accuracyPercent: 96,
      modelType: HuggingFaceModelType.asr,
      languages: _multilingualLanguages,
      badge: 'Best Value',
      description: 'Excellent accuracy with much faster speed than Large v3',
    ),
  ];

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

  List<HuggingFaceModel> getAsrModels() => List.unmodifiable(_asrModels);

  List<HuggingFaceModel> getVisualModels() => const [];

  List<HuggingFaceModel> getModelsByType(HuggingFaceModelType type) {
    if (type == HuggingFaceModelType.asr) {
      return getAsrModels();
    }
    return const [];
  }

  List<HuggingFaceModel> getAllModels() => List.unmodifiable(_asrModels);

  HuggingFaceModel? getModelById(String id) {
    for (final model in _asrModels) {
      if (model.id == id) return model;
    }
    return null;
  }

  String getDownloadUrl(HuggingFaceModel model) => model.downloadUrl;

  HuggingFaceModel? getRecommendedModel(HuggingFaceModelType type) {
    final models = getModelsByType(type);
    return models.cast<HuggingFaceModel?>().firstWhere(
          (m) => m?.isRecommended ?? false,
          orElse: () => models.isNotEmpty ? models.first : null,
        );
  }

  List<HuggingFaceModel> getNsfwModels() => const [];
  List<HuggingFaceModel> getViolenceModels() => const [];
  List<HuggingFaceModel> getBloodModels() => const [];
  List<HuggingFaceModel> getWeaponsModels() => const [];
  List<HuggingFaceModel> getNudeNetModels() => const [];
  List<HuggingFaceModel> getClipModels() => const [];

  List<HuggingFaceModel> getModelsSortedBySize(HuggingFaceModelType type) {
    final models = getModelsByType(type).toList()
      ..sort((a, b) => a.parameterCount.compareTo(b.parameterCount));
    return models;
  }

  List<HuggingFaceModel> getModelsSortedByAccuracy(HuggingFaceModelType type) {
    final models = getModelsByType(type).toList()
      ..sort((a, b) => b.accuracyPercent.compareTo(a.accuracyPercent));
    return models;
  }

  List<HuggingFaceModel> getModelsSortedBySpeed(HuggingFaceModelType type) {
    final models = getModelsByType(type).toList()
      ..sort((a, b) => b.speedMultiplier.compareTo(a.speedMultiplier));
    return models;
  }

  List<HuggingFaceModel> getEnglishOnlyAsrModels() => _asrModels
      .where((model) => model.isEnglishOnly)
      .toList(growable: false);

  List<HuggingFaceModel> getMultilingualAsrModels() => _asrModels
      .where((model) => model.isMultilingual)
      .toList(growable: false);
}
