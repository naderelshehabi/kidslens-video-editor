import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:kidslens_video_editor/data/models/content_category.dart';
import 'package:kidslens_video_editor/data/models/visual_content_category.dart';
import 'package:kidslens_video_editor/data/models/voting_config.dart';

part 'analysis_settings.freezed.dart';
part 'analysis_settings.g.dart';

/// Configuration for AI models
@freezed
class ModelConfig with _$ModelConfig {
  const factory ModelConfig({
    /// ID of the ASR model to use for transcription
    required String asrModelId,

    /// ID of the visual model to use for frame analysis (legacy, use per-type IDs)
    required String visualModelId,

    /// ID of the NSFW detection model
    @Default('nsfw-mobilenet-v2') String nsfwModelId,

    /// ID of the violence detection model
    @Default('violence-mobilenet') String violenceModelId,

    /// ID of the blood/gore detection model
    @Default('gore-efficientnet-b2') String bloodModelId,

    /// ID of the weapons detection model
    @Default('weapons-yolov8-small') String weaponsModelId,

    /// Language for ASR (e.g., 'en', 'es', 'auto')
    @Default('en') String asrLanguage,

    /// Whether to use GPU acceleration
    @Default(true) bool useGpu,

    /// Number of threads for CPU inference
    @Default(4) int cpuThreads,

    /// Batch size for visual model inference
    @Default(8) int batchSize,

    /// Whether to use half-precision (FP16) for faster inference
    @Default(false) bool useFp16,

    /// Whether to translate non-English speech to English
    @Default(false) bool translateToEnglish,

    /// Whether to generate word-level timestamps (slower but more precise)
    @Default(false) bool wordLevelTimestamps,

    /// Beam search size for ASR decoding (1-5, higher = more accurate but slower)
    @Default(3) int beamSize,

    /// ID of the NudeNet detection model
    @Default('nudenet-v3-medium') String nudeNetModelId,

    /// ID of the CLIP vision encoder model
    @Default('clip-vit-b32-vision-fp16') String clipVisionModelId,

    /// ID of the CLIP text encoder model
    @Default('clip-vit-b32-text-fp16') String clipTextModelId,
  }) = _ModelConfig;

  const ModelConfig._();

  factory ModelConfig.fromJson(Map<String, dynamic> json) =>
      _$ModelConfigFromJson(json);

  /// Creates default model configuration
  factory ModelConfig.defaults() => const ModelConfig(
        asrModelId: 'whisper-base',
        visualModelId: 'nsfw-mobilenet-v2',
      );
}

/// Configuration for profanity detection
@freezed
class ProfanityConfig with _$ProfanityConfig {
  const factory ProfanityConfig({
    /// Wordlist IDs to use for detection
    @Default(['english-profanity']) List<String> wordlistIds,

    /// Whether to detect leetspeak variations
    @Default(true) bool detectLeetspeak,

    /// Whether to detect phonetic variations
    @Default(true) bool detectPhonetic,

    /// Whether to use fuzzy matching
    @Default(true) bool detectFuzzy,

    /// Whether to detect obfuscated words
    @Default(true) bool detectObfuscated,

    /// Minimum confidence for fuzzy matches
    @Default(0.8) double fuzzyThreshold,

    /// Custom words to add to detection
    @Default([]) List<String> customWords,

    /// Words to exclude from detection
    @Default([]) List<String> excludedWords,

    /// Minimum word length to check
    @Default(2) int minWordLength,

    /// Whether to check for context (reduce false positives)
    @Default(true) bool useContextAnalysis,
  }) = _ProfanityConfig;

  const ProfanityConfig._();

  factory ProfanityConfig.fromJson(Map<String, dynamic> json) =>
      _$ProfanityConfigFromJson(json);

  /// Creates default profanity configuration
  factory ProfanityConfig.defaults() => const ProfanityConfig();

  /// Creates a strict configuration that catches more profanity
  factory ProfanityConfig.strict() => const ProfanityConfig(
        fuzzyThreshold: 0.7,
      );

  /// Creates a permissive configuration with fewer false positives
  factory ProfanityConfig.permissive() => const ProfanityConfig(
        detectPhonetic: false,
        detectFuzzy: false,
        fuzzyThreshold: 0.9,
        minWordLength: 3,
      );
}

/// Configuration for visual content detection (NudeNet + CLIP)
@freezed
class VisualContentConfig with _$VisualContentConfig {
  const factory VisualContentConfig({
    /// Whether NudeNet detection is enabled
    @Default(true) bool enableNudeNetDetection,

    /// Whether CLIP classification is enabled
    @Default(true) bool enableClipClassification,

    /// Whether to use NSFW pre-filter before NudeNet (performance optimization)
    @Default(true) bool useNsfwPreFilter,

    /// Minimum NSFW score to trigger NudeNet (min 0.05 enforced)
    @Default(0.30) double preFilterThreshold,

    /// Visual content categories (empty default; populated at runtime)
    @Default([]) List<VisualContentCategory> categories,
  }) = _VisualContentConfig;

  const VisualContentConfig._();

  factory VisualContentConfig.fromJson(Map<String, dynamic> json) =>
      _$VisualContentConfigFromJson(json);

  /// Pre-filter threshold with enforced minimum of 0.05
  double get effectivePreFilterThreshold =>
      preFilterThreshold < 0.05 ? 0.05 : preFilterThreshold;

  /// Whether any NudeNet categories are enabled
  bool get hasNudeNetCategories => categories.any(
        (c) => c.enabled && c.usesNudeNet,
      );

  /// Whether any CLIP categories are enabled
  bool get hasClipCategories => categories.any(
        (c) => c.enabled && c.usesClip,
      );

  /// Whether any category is enabled
  bool get hasAnyEnabled => categories.any((c) => c.enabled);

  /// Enabled categories only
  List<VisualContentCategory> get enabledCategories =>
      categories.where((c) => c.enabled).toList();
}

/// Unified content detection configuration (v2).
///
/// Replaces the legacy per-type enable/threshold fields and [VisualContentConfig]
/// with a category-based system supporting MoE voting.
@freezed
class ContentDetectionConfig with _$ContentDetectionConfig {
  const factory ContentDetectionConfig({
    /// All content categories (visual + audio).
    @Default([]) List<ContentCategory> categories,

    /// Voting configuration for MoE consensus.
    @Default(VotingConfig()) VotingConfig votingConfig,

    /// Whether to use NSFW pre-filter before NudeNet (performance).
    @Default(true) bool useNsfwPreFilter,

    /// NSFW score threshold to trigger NudeNet (min 0.05 enforced).
    @Default(0.30) double preFilterThreshold,

    /// Schema version for migration (v2 = unified categories).
    @Default(2) int schemaVersion,
  }) = _ContentDetectionConfig;

  const ContentDetectionConfig._();

  factory ContentDetectionConfig.fromJson(Map<String, dynamic> json) =>
      _$ContentDetectionConfigFromJson(json);

  /// Pre-filter threshold with enforced minimum of 0.05.
  double get effectivePreFilterThreshold =>
      preFilterThreshold < 0.05 ? 0.05 : preFilterThreshold;

  /// Visual categories only.
  List<ContentCategory> get visualCategories =>
      categories.where((c) => c.isVisual).toList();

  /// Audio categories only.
  List<ContentCategory> get audioCategories =>
      categories.where((c) => c.isAudio).toList();

  /// Enabled categories (enabled + has at least one enabled model).
  List<ContentCategory> get enabledCategories =>
      categories.where((c) => c.enabled && c.hasEnabledModels).toList();

  /// Enabled visual categories.
  List<ContentCategory> get enabledVisualCategories =>
      enabledCategories.where((c) => c.isVisual).toList();

  /// Enabled audio categories.
  List<ContentCategory> get enabledAudioCategories =>
      enabledCategories.where((c) => c.isAudio).toList();

  /// Categories that require NudeNet models.
  List<ContentCategory> get nudeNetCategories =>
      enabledCategories.where((c) => c.hasNudeNetModels).toList();

  /// Categories that require CLIP models.
  List<ContentCategory> get clipCategories =>
      enabledCategories.where((c) => c.hasClipModels).toList();

  /// Whether any category is enabled.
  bool get hasAnyEnabled => enabledCategories.isNotEmpty;

  /// Whether any visual category is enabled.
  bool get hasVisualCategories => enabledVisualCategories.isNotEmpty;

  /// Whether any audio category is enabled.
  bool get hasAudioCategories => enabledAudioCategories.isNotEmpty;

  /// All unique model IDs required by enabled categories.
  Set<String> get requiredModelIds =>
      enabledCategories.expand((c) => c.requiredModelIds).toSet();
}

/// Complete analysis settings for the video editor
@freezed
class AnalysisSettings with _$AnalysisSettings {
  const factory AnalysisSettings({
    /// Model configuration
    required ModelConfig modelConfig,

    /// Profanity configuration
    required ProfanityConfig profanityConfig,

    /// NSFW detection threshold (0.0 to 1.0)
    @Default(0.6) double nsfwThreshold,

    /// Violence detection threshold (0.0 to 1.0)
    @Default(0.6) double violenceThreshold,

    /// Blood/gore detection threshold (0.0 to 1.0)
    @Default(0.6) double bloodThreshold,

    /// Weapons detection threshold (0.0 to 1.0)
    @Default(0.6) double weaponsThreshold,

    /// Whether NSFW detection is enabled
    @Default(true) bool enableNsfw,

    /// Whether violence detection is enabled
    @Default(true) bool enableViolence,

    /// Whether blood/gore detection is enabled
    @Default(true) bool enableBlood,

    /// Whether weapons detection is enabled
    @Default(true) bool enableWeapons,

    /// Whether profanity detection is enabled
    @Default(true) bool enableProfanity,

    /// Frame sampling rate (analyze every Nth frame)
    @Default(5) int frameSamplingRate,

    /// Whether to use scene detection for adaptive sampling
    @Default(true) bool useSceneDetection,

    /// Minimum segment duration in milliseconds
    @Default(500) int minSegmentDurationMs,

    /// Whether to merge adjacent detections of same type
    @Default(true) bool mergeAdjacentDetections,

    /// Buffer time in milliseconds to add around detections
    @Default(100) int detectionBufferMs,

    /// Maximum concurrent frame analyses
    @Default(4) int maxConcurrentAnalyses,

    /// Visual content detection configuration (NudeNet + CLIP)
    @Default(VisualContentConfig()) VisualContentConfig visualContentConfig,

    /// Unified content detection configuration (v2, MoE voting).
    @Default(ContentDetectionConfig()) ContentDetectionConfig contentDetectionConfig,
  }) = _AnalysisSettings;

  const AnalysisSettings._();

  factory AnalysisSettings.fromJson(Map<String, dynamic> json) =>
      _$AnalysisSettingsFromJson(json);

  /// Creates default analysis settings
  factory AnalysisSettings.defaults() => AnalysisSettings(
        modelConfig: ModelConfig.defaults(),
        profanityConfig: ProfanityConfig.defaults(),
      );

  /// Creates strict settings for maximum detection
  factory AnalysisSettings.strict() => AnalysisSettings(
        modelConfig: ModelConfig.defaults(),
        nsfwThreshold: 0.4,
        violenceThreshold: 0.4,
        bloodThreshold: 0.4,
        weaponsThreshold: 0.4,
        profanityConfig: ProfanityConfig.strict(),
        frameSamplingRate: 3,
        minSegmentDurationMs: 300,
        detectionBufferMs: 200,
      );

  /// Creates permissive settings for fewer false positives
  factory AnalysisSettings.permissive() => AnalysisSettings(
        modelConfig: ModelConfig.defaults(),
        nsfwThreshold: 0.8,
        violenceThreshold: 0.8,
        bloodThreshold: 0.8,
        weaponsThreshold: 0.8,
        profanityConfig: ProfanityConfig.permissive(),
        frameSamplingRate: 10,
        minSegmentDurationMs: 1000,
        detectionBufferMs: 50,
      );

  /// Creates settings for audio-only analysis
  factory AnalysisSettings.audioOnly() => AnalysisSettings(
        modelConfig: ModelConfig.defaults(),
        profanityConfig: ProfanityConfig.defaults(),
        enableNsfw: false,
        enableViolence: false,
        enableBlood: false,
        enableWeapons: false,
      );

  /// Creates settings for video-only analysis (no ASR)
  factory AnalysisSettings.videoOnly() => AnalysisSettings(
        modelConfig: ModelConfig.defaults(),
        profanityConfig: ProfanityConfig.defaults(),
        enableProfanity: false,
      );

  /// Whether any visual detection is enabled
  bool get hasVisualDetection =>
      enableNsfw || enableViolence || enableBlood || enableWeapons ||
      contentDetectionConfig.hasVisualCategories;

  /// Whether any audio detection is enabled
  bool get hasAudioDetection =>
      enableProfanity || contentDetectionConfig.hasAudioCategories;

  /// Whether any detection is enabled
  bool get hasAnyDetection => hasVisualDetection || hasAudioDetection;

  /// Gets threshold for a specific content type
  double getThreshold(String type) {
    switch (type.toLowerCase()) {
      case 'nsfw':
        return nsfwThreshold;
      case 'violence':
        return violenceThreshold;
      case 'blood':
        return bloodThreshold;
      case 'weapons':
        return weaponsThreshold;
      default:
        return 0.5;
    }
  }

  /// Minimum segment duration as Duration
  Duration get minSegmentDuration =>
      Duration(milliseconds: minSegmentDurationMs);

  /// Detection buffer as Duration
  Duration get detectionBuffer => Duration(milliseconds: detectionBufferMs);

  /// Creates a copy with adjusted thresholds
  AnalysisSettings withThresholds({
    double? nsfw,
    double? violence,
    double? blood,
    double? weapons,
  }) =>
      copyWith(
        nsfwThreshold: nsfw ?? nsfwThreshold,
        violenceThreshold: violence ?? violenceThreshold,
        bloodThreshold: blood ?? bloodThreshold,
        weaponsThreshold: weapons ?? weaponsThreshold,
      );

  /// Creates a copy with specified detections enabled/disabled
  AnalysisSettings withDetections({
    bool? nsfw,
    bool? violence,
    bool? blood,
    bool? weapons,
    bool? profanity,
  }) =>
      copyWith(
        enableNsfw: nsfw ?? enableNsfw,
        enableViolence: violence ?? enableViolence,
        enableBlood: blood ?? enableBlood,
        enableWeapons: weapons ?? enableWeapons,
        enableProfanity: profanity ?? enableProfanity,
      );

  /// Validates settings and returns list of issues
  List<String> validate() {
    final issues = <String>[];

    if (!hasAnyDetection) {
      issues.add('No detection types are enabled');
    }

    if (nsfwThreshold < 0 || nsfwThreshold > 1) {
      issues.add('NSFW threshold must be between 0 and 1');
    }
    if (violenceThreshold < 0 || violenceThreshold > 1) {
      issues.add('Violence threshold must be between 0 and 1');
    }
    if (bloodThreshold < 0 || bloodThreshold > 1) {
      issues.add('Blood threshold must be between 0 and 1');
    }
    if (weaponsThreshold < 0 || weaponsThreshold > 1) {
      issues.add('Weapons threshold must be between 0 and 1');
    }

    if (frameSamplingRate < 1) {
      issues.add('Frame sampling rate must be at least 1');
    }
    if (minSegmentDurationMs < 0) {
      issues.add('Minimum segment duration cannot be negative');
    }
    if (maxConcurrentAnalyses < 1) {
      issues.add('Max concurrent analyses must be at least 1');
    }

    // Validate visual content config
    if (visualContentConfig.preFilterThreshold < 0.05) {
      issues.add('Pre-filter threshold must be at least 0.05');
    }
    for (final category in visualContentConfig.categories) {
      if (!category.isBuiltIn) {
        final hasLabels = category.detectionLabels.isNotEmpty;
        final hasPrompts = category.clipPrompts.isNotEmpty;
        if (!hasLabels && !hasPrompts) {
          issues.add(
            'Custom category "${category.name}" has no detection labels or prompts',
          );
        }
      }
    }

    return issues;
  }

  /// Whether settings are valid
  bool get isValid => validate().isEmpty;
}
