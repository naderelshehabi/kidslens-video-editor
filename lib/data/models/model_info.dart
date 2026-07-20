import 'package:freezed_annotation/freezed_annotation.dart';

part 'model_info.freezed.dart';
part 'model_info.g.dart';

/// Types of AI models used in the application
@JsonEnum()
enum ModelType {
  /// Automatic Speech Recognition model
  @JsonValue('asr')
  asr,

  /// Visual/image analysis model
  @JsonValue('visual')
  visual,
}

/// Hardware information for checking model requirements
@freezed
class HardwareInfo with _$HardwareInfo {
  const factory HardwareInfo({
    /// Available RAM in bytes
    required int availableRamBytes,

    /// Available VRAM in bytes (0 if no GPU)
    @Default(0) int availableVramBytes,

    /// Whether GPU is available
    @Default(false) bool hasGpu,

    /// GPU name if available
    String? gpuName,

    /// Number of CPU cores
    @Default(4) int cpuCores,

    /// Whether AVX2 instructions are supported
    @Default(false) bool supportsAvx2,

    /// Whether CUDA is available
    @Default(false) bool supportsCuda,

    /// Whether Metal is available (macOS)
    @Default(false) bool supportsMetal,

    /// Operating system
    String? operatingSystem,
  }) = _HardwareInfo;

  factory HardwareInfo.fromJson(Map<String, dynamic> json) =>
      _$HardwareInfoFromJson(json);

  /// Creates a basic hardware info with just RAM
  factory HardwareInfo.basic({required int ramGb}) => HardwareInfo(
        availableRamBytes: ramGb * 1024 * 1024 * 1024,
      );
}

/// Information about an AI model
@freezed
class ModelInfo with _$ModelInfo {
  const factory ModelInfo({
    /// Unique identifier for the model
    required String id,

    /// Human-readable display name
    required String displayName,

    /// Description of the model's capabilities
    required String description,

    /// Type of model (ASR or visual)
    required ModelType type,

    /// Model file size in bytes
    required int sizeBytes,

    /// Accuracy percentage (0-100)
    required int accuracyPercent,

    /// Speed rating (1-5, where 5 is fastest)
    required int speedRating,

    /// Optional badge text (e.g., "Recommended", "New", "Beta")
    String? badge,

    /// Minimum RAM required in bytes
    @Default(0) int minRamBytes,

    /// Minimum VRAM required in bytes (0 if CPU-only)
    @Default(0) int minVramBytes,

    /// Whether GPU is required
    @Default(false) bool requiresGpu,

    /// Whether AVX2 is required
    @Default(false) bool requiresAvx2,

    /// Supported languages (for ASR models)
    List<String>? supportedLanguages,

    /// Download URL
    String? downloadUrl,

    /// Model version
    String? version,

    /// Release date
    DateTime? releaseDate,

    /// Additional metadata
    Map<String, dynamic>? metadata,
  }) = _ModelInfo;

  const ModelInfo._();

  factory ModelInfo.fromJson(Map<String, dynamic> json) =>
      _$ModelInfoFromJson(json);

  /// Human-readable file size
  String get sizeFormatted {
    if (sizeBytes < 1024) return '$sizeBytes B';
    if (sizeBytes < 1024 * 1024) {
      return '${(sizeBytes / 1024).toStringAsFixed(1)} KB';
    }
    if (sizeBytes < 1024 * 1024 * 1024) {
      return '${(sizeBytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
    return '${(sizeBytes / (1024 * 1024 * 1024)).toStringAsFixed(2)} GB';
  }

  /// Human-readable minimum RAM
  String get minRamFormatted {
    if (minRamBytes == 0) return 'No minimum';
    if (minRamBytes < 1024 * 1024 * 1024) {
      return '${(minRamBytes / (1024 * 1024)).toStringAsFixed(0)} MB';
    }
    return '${(minRamBytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
  }

  /// Speed rating as descriptive text
  String get speedDescription {
    switch (speedRating) {
      case 1:
        return 'Very Slow';
      case 2:
        return 'Slow';
      case 3:
        return 'Moderate';
      case 4:
        return 'Fast';
      case 5:
        return 'Very Fast';
      default:
        return 'Unknown';
    }
  }

  /// Accuracy rating as descriptive text
  String get accuracyDescription {
    if (accuracyPercent >= 95) return 'Excellent';
    if (accuracyPercent >= 90) return 'Very Good';
    if (accuracyPercent >= 80) return 'Good';
    if (accuracyPercent >= 70) return 'Fair';
    return 'Basic';
  }

  /// Whether this is an ASR model
  bool get isAsrModel => type == ModelType.asr;

  /// Whether this is a visual model
  bool get isVisualModel => type == ModelType.visual;

  /// Whether this model has a badge
  bool get hasBadge => badge != null && badge!.isNotEmpty;

  /// Whether this model is marked as recommended
  bool get isRecommended => badge?.toLowerCase().contains('recommend') ?? false;

  /// Checks if the hardware meets the model's requirements
  bool meetsRequirements(HardwareInfo info) {
    // Check RAM requirement
    if (minRamBytes > 0 && info.availableRamBytes < minRamBytes) {
      return false;
    }

    // Check VRAM requirement
    if (minVramBytes > 0 && info.availableVramBytes < minVramBytes) {
      return false;
    }

    // Check GPU requirement
    if (requiresGpu && !info.hasGpu) {
      return false;
    }

    // Check AVX2 requirement
    if (requiresAvx2 && !info.supportsAvx2) {
      return false;
    }

    return true;
  }

  /// Gets a list of unmet requirements for given hardware
  List<String> getUnmetRequirements(HardwareInfo info) {
    final unmet = <String>[];

    if (minRamBytes > 0 && info.availableRamBytes < minRamBytes) {
      final required = (minRamBytes / (1024 * 1024 * 1024)).toStringAsFixed(1);
      final available =
          (info.availableRamBytes / (1024 * 1024 * 1024)).toStringAsFixed(1);
      unmet.add('Requires ${required}GB RAM (available: ${available}GB)');
    }

    if (minVramBytes > 0 && info.availableVramBytes < minVramBytes) {
      final required = (minVramBytes / (1024 * 1024 * 1024)).toStringAsFixed(1);
      final available =
          (info.availableVramBytes / (1024 * 1024 * 1024)).toStringAsFixed(1);
      unmet.add('Requires ${required}GB VRAM (available: ${available}GB)');
    }

    if (requiresGpu && !info.hasGpu) {
      unmet.add('Requires GPU');
    }

    if (requiresAvx2 && !info.supportsAvx2) {
      unmet.add('Requires AVX2 CPU instructions');
    }

    return unmet;
  }

  /// Estimated processing time factor relative to real-time
  /// (e.g., 0.5 means 2x faster than real-time)
  double get estimatedProcessingFactor {
    // Based on speed rating (5 = fastest)
    switch (speedRating) {
      case 5:
        return 0.25; // 4x faster
      case 4:
        return 0.5; // 2x faster
      case 3:
        return 1; // Real-time
      case 2:
        return 2; // 2x slower
      case 1:
        return 4; // 4x slower
      default:
        return 1;
    }
  }
}

/// Extension for working with lists of models
extension ModelInfoListExtensions on List<ModelInfo> {
  /// Gets all ASR models
  List<ModelInfo> get asrModels =>
      where((m) => m.type == ModelType.asr).toList();

  /// Gets all visual models
  List<ModelInfo> get visualModels =>
      where((m) => m.type == ModelType.visual).toList();

  /// Gets models that meet hardware requirements
  List<ModelInfo> meetingRequirements(HardwareInfo info) =>
      where((m) => m.meetsRequirements(info)).toList();

  /// Gets the recommended model
  ModelInfo? get recommended => where((m) => m.isRecommended).firstOrNull;

  /// Sorts by accuracy (descending)
  List<ModelInfo> sortedByAccuracy() =>
      [...this]..sort((a, b) => b.accuracyPercent.compareTo(a.accuracyPercent));

  /// Sorts by speed (descending)
  List<ModelInfo> sortedBySpeed() =>
      [...this]..sort((a, b) => b.speedRating.compareTo(a.speedRating));

  /// Sorts by size (ascending)
  List<ModelInfo> sortedBySize() =>
      [...this]..sort((a, b) => a.sizeBytes.compareTo(b.sizeBytes));
}
