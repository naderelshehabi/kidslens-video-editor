import 'package:freezed_annotation/freezed_annotation.dart';

part 'analysis_settings.freezed.dart';
part 'analysis_settings.g.dart';

/// Configuration for AI models
@freezed
class ModelConfig with _$ModelConfig {
  const factory ModelConfig({
    /// ID of the ASR model to use for transcription
    required String asrModelId,

    /// ID of the visual model to use for frame analysis
    required String visualModelId,

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
  }) = _ModelConfig;

  const ModelConfig._();

  factory ModelConfig.fromJson(Map<String, dynamic> json) =>
      _$ModelConfigFromJson(json);

  /// Creates default model configuration
  factory ModelConfig.defaults() => const ModelConfig(
        asrModelId: 'whisper-base',
        visualModelId: 'nsfw-mobilenet',
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
      enableNsfw || enableViolence || enableBlood || enableWeapons;

  /// Whether any audio detection is enabled
  bool get hasAudioDetection => enableProfanity;

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

    return issues;
  }

  /// Whether settings are valid
  bool get isValid => validate().isEmpty;
}
