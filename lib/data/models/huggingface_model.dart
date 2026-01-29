import 'package:freezed_annotation/freezed_annotation.dart';

part 'huggingface_model.freezed.dart';
part 'huggingface_model.g.dart';

/// Types of HuggingFace AI models used in the application
@JsonEnum()
enum HuggingFaceModelType {
  /// Automatic Speech Recognition model
  @JsonValue('asr')
  asr,

  /// NSFW content detection
  @JsonValue('nsfw')
  nsfw,

  /// Violence detection
  @JsonValue('violence')
  violence,

  /// Blood/gore detection
  @JsonValue('blood')
  blood,

  /// Weapons detection
  @JsonValue('weapons')
  weapons,
}

/// A HuggingFace model with download and hardware information
@freezed
class HuggingFaceModel with _$HuggingFaceModel {
  const factory HuggingFaceModel({
    /// Unique identifier for the model (e.g., 'whisper-tiny', 'nsfw-mobilenet-v2')
    required String id,

    /// Human-readable display name
    required String displayName,

    /// HuggingFace repository ID (e.g., 'ggerganov/whisper.cpp')
    required String huggingFaceId,

    /// Model file name in the repository (e.g., 'ggml-tiny.bin')
    required String fileName,

    /// Human-readable parameter count (e.g., '39M', '1.55B')
    required String parameters,

    /// Numeric parameter count for sorting (e.g., 39000000)
    required int parameterCount,

    /// Model file size in bytes
    required int sizeBytes,

    /// RAM required to run the model in bytes
    required int ramRequired,

    /// Speed multiplier relative to realtime (e.g., 10.0 = 10x realtime)
    required double speedMultiplier,

    /// Accuracy percentage (0-100)
    required int accuracyPercent,

    /// Type of model
    required HuggingFaceModelType modelType,

    /// Supported languages (for ASR models, empty for visual models)
    @Default([]) List<String> languages,

    /// Optional badge text (e.g., 'Recommended', 'Best Accuracy', 'Best Value')
    String? badge,

    /// Optional description of the model
    String? description,

    /// Whether this model requires a GPU
    @Default(false) bool requiresGpu,

    /// Minimum VRAM required in bytes (0 if CPU-only)
    @Default(0) int minVramBytes,

    /// Model license (e.g., 'MIT', 'Apache-2.0')
    @Default('MIT') String license,
  }) = _HuggingFaceModel;

  const HuggingFaceModel._();

  factory HuggingFaceModel.fromJson(Map<String, dynamic> json) =>
      _$HuggingFaceModelFromJson(json);

  /// Human-readable file size
  String get sizeFormatted {
    if (sizeBytes < 1024) return '$sizeBytes B';
    if (sizeBytes < 1024 * 1024) {
      return '${(sizeBytes / 1024).toStringAsFixed(1)} KB';
    }
    if (sizeBytes < 1024 * 1024 * 1024) {
      return '${(sizeBytes / (1024 * 1024)).toStringAsFixed(0)} MB';
    }
    return '${(sizeBytes / (1024 * 1024 * 1024)).toStringAsFixed(2)} GB';
  }

  /// Human-readable RAM requirement
  String get ramFormatted {
    if (ramRequired == 0) return 'No minimum';
    if (ramRequired < 1024 * 1024 * 1024) {
      return '${(ramRequired / (1024 * 1024)).toStringAsFixed(0)} MB';
    }
    return '${(ramRequired / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
  }

  /// Direct download URL from HuggingFace
  String get downloadUrl =>
      'https://huggingface.co/$huggingFaceId/resolve/main/$fileName';

  /// Whether this is an ASR model
  bool get isAsrModel => modelType == HuggingFaceModelType.asr;

  /// Whether this is a visual detection model
  bool get isVisualModel => modelType != HuggingFaceModelType.asr;

  /// Whether this model has a badge
  bool get hasBadge => badge != null && badge!.isNotEmpty;

  /// Whether this model is marked as recommended
  bool get isRecommended =>
      badge?.toLowerCase().contains('recommend') ?? false;

  /// Speed description based on multiplier
  String get speedDescription {
    if (speedMultiplier >= 10) return 'Very Fast';
    if (speedMultiplier >= 7) return 'Fast';
    if (speedMultiplier >= 4) return 'Moderate';
    if (speedMultiplier >= 2) return 'Slow';
    return 'Very Slow';
  }

  /// Accuracy description based on percentage
  String get accuracyDescription {
    if (accuracyPercent >= 97) return 'Excellent';
    if (accuracyPercent >= 94) return 'Very Good';
    if (accuracyPercent >= 90) return 'Good';
    if (accuracyPercent >= 85) return 'Fair';
    return 'Basic';
  }

  /// Whether this model supports multiple languages
  bool get isMultilingual => languages.length > 1;

  /// Whether this model is English-only
  bool get isEnglishOnly =>
      languages.length == 1 && languages.first.toLowerCase() == 'en';
}
