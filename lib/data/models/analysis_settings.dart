import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:kidslens_video_editor/data/models/content_category.dart';
import 'package:kidslens_video_editor/data/models/content_category_defaults.dart';
import 'package:kidslens_video_editor/data/models/voting_config.dart';

part 'analysis_settings.freezed.dart';
part 'analysis_settings.g.dart';

@freezed
class ModelConfig with _$ModelConfig {
  const factory ModelConfig({
    required String asrModelId,
    @Default('nsfw-gantman-mobilenet-v2-224') String nsfwModelId,
    @Default('en') String asrLanguage,
    // New GPU selection fields
    @Default(true) bool asrGpuEnabled,
    @Default(0) int asrGpuDevice,
    @Default(true) bool onnxGpuEnabled,
    @Default('auto') String onnxExecutionProvider,
    @Default(null) int? onnxGpuDevice,
    // Deprecated fields for backwards compatibility
    @Deprecated('Use asrGpuEnabled instead')
    @Default(true) bool useGpu,
    @Deprecated('Use asrGpuDevice instead')
    @Default(0) int gpuDeviceIndex,
    @Default(4) int cpuThreads,
    @Default(8) int batchSize,
    @Default(false) bool useFp16,
    @Default(false) bool translateToEnglish,
    @Default(false) bool wordLevelTimestamps,
    @Default(3) int beamSize,
  }) = _ModelConfig;

  const ModelConfig._();

  factory ModelConfig.fromJson(Map<String, dynamic> json) =>
      _$ModelConfigFromJson(json);

  factory ModelConfig.defaults() => const ModelConfig(
        asrModelId: 'whisper-base',
      );
}

// Validation extension for ModelConfig
extension ModelConfigValidation on ModelConfig {
  List<String> validate() {
    final issues = <String>[];
    
    if (asrGpuEnabled && asrGpuDevice < 0) {
      issues.add('ASR GPU device must be non-negative');
    }
    
    if (onnxGpuDevice != null && onnxGpuDevice! < 0) {
      issues.add('ONNX GPU device must be non-negative');
    }
    
    if (onnxGpuEnabled && onnxExecutionProvider == 'cpu') {
      issues.add('Cannot enable GPU with CPU execution provider');
    }
    
    // Validate execution provider value
    const validProviders = ['auto', 'cuda', 'directml', 'coreml', 'cpu'];
    if (!validProviders.contains(onnxExecutionProvider)) {
      issues.add('Invalid ONNX execution provider: $onnxExecutionProvider');
    }
    
    return issues;
  }
  
  bool get isValid => validate().isEmpty;
}

@freezed
class ProfanityConfig with _$ProfanityConfig {
  const factory ProfanityConfig({
    @Default(['english-profanity']) List<String> wordlistIds,
    @Default(true) bool detectLeetspeak,
    @Default(true) bool detectPhonetic,
    @Default(true) bool detectFuzzy,
    @Default(true) bool detectObfuscated,
    @Default(0.8) double fuzzyThreshold,
    @Default([]) List<String> customWords,
    @Default([]) List<String> excludedWords,
    @Default(2) int minWordLength,
    @Default(true) bool useContextAnalysis,
  }) = _ProfanityConfig;

  const ProfanityConfig._();

  factory ProfanityConfig.fromJson(Map<String, dynamic> json) =>
      _$ProfanityConfigFromJson(json);

  factory ProfanityConfig.defaults() => const ProfanityConfig();

  factory ProfanityConfig.strict() => const ProfanityConfig(
        fuzzyThreshold: 0.7,
      );

  factory ProfanityConfig.permissive() => const ProfanityConfig(
        detectPhonetic: false,
        detectFuzzy: false,
        fuzzyThreshold: 0.9,
        minWordLength: 3,
      );
}

@freezed
class ContentDetectionConfig with _$ContentDetectionConfig {
  const factory ContentDetectionConfig({
    @Default([]) List<ContentCategory> categories,
    @Default(VotingConfig()) VotingConfig votingConfig,
    @Default(4) int schemaVersion,
  }) = _ContentDetectionConfig;

  const ContentDetectionConfig._();

  factory ContentDetectionConfig.fromJson(Map<String, dynamic> json) =>
      _$ContentDetectionConfigFromJson(json);

  List<ContentCategory> get visualCategories =>
      categories.where((c) => c.isVisual).toList();

  List<ContentCategory> get audioCategories =>
      categories.where((c) => c.isAudio).toList();

  List<ContentCategory> get enabledCategories =>
      categories.where((c) => c.enabled && c.hasEnabledModels).toList();

  List<ContentCategory> get enabledVisualCategories =>
      enabledCategories.where((c) => c.isVisual).toList();

  List<ContentCategory> get enabledAudioCategories =>
      enabledCategories.where((c) => c.isAudio).toList();

  bool get hasAnyEnabled => enabledCategories.isNotEmpty;

  bool get hasVisualCategories => enabledVisualCategories.isNotEmpty;

  bool get hasAudioCategories => enabledAudioCategories.isNotEmpty;

  Set<String> get requiredModelIds =>
      enabledCategories.expand((c) => c.requiredModelIds).toSet();
}

@freezed
class AnalysisSettings with _$AnalysisSettings {
  const factory AnalysisSettings({
    required ModelConfig modelConfig,
    required ProfanityConfig profanityConfig,
    @Default(true) bool enableProfanity,
    @Default(5) int frameSamplingRate,
    @Default(true) bool useSceneDetection,
    @Default(500) int minSegmentDurationMs,
    @Default(true) bool mergeAdjacentDetections,
    @Default(100) int detectionBufferMs,
    @Default(4) int maxConcurrentAnalyses,
    @Default(ContentDetectionConfig())
    ContentDetectionConfig contentDetectionConfig,
  }) = _AnalysisSettings;

  const AnalysisSettings._();

  factory AnalysisSettings.fromJson(Map<String, dynamic> json) =>
      _$AnalysisSettingsFromJson(json);

  factory AnalysisSettings.defaults() => AnalysisSettings(
        modelConfig: ModelConfig.defaults(),
        profanityConfig: ProfanityConfig.defaults(),
        contentDetectionConfig: ContentDetectionConfig(
          categories: ContentCategoryDefaults.allCategories,
        ),
      );

  factory AnalysisSettings.strict() => AnalysisSettings(
        modelConfig: ModelConfig.defaults(),
        profanityConfig: ProfanityConfig.strict(),
        frameSamplingRate: 3,
        minSegmentDurationMs: 300,
        detectionBufferMs: 200,
        contentDetectionConfig: ContentDetectionConfig(
          categories: ContentCategoryDefaults.allCategories,
        ),
      );

  factory AnalysisSettings.permissive() => AnalysisSettings(
        modelConfig: ModelConfig.defaults(),
        profanityConfig: ProfanityConfig.permissive(),
        frameSamplingRate: 10,
        minSegmentDurationMs: 1000,
        detectionBufferMs: 50,
        contentDetectionConfig: ContentDetectionConfig(
          categories: ContentCategoryDefaults.allCategories,
        ),
      );

  factory AnalysisSettings.audioOnly() => AnalysisSettings(
        modelConfig: ModelConfig.defaults(),
        profanityConfig: ProfanityConfig.defaults(),
        contentDetectionConfig: ContentDetectionConfig(
          categories: ContentCategoryDefaults.audioCategories,
        ),
      );

  factory AnalysisSettings.videoOnly() => AnalysisSettings(
        modelConfig: ModelConfig.defaults(),
        profanityConfig: ProfanityConfig.defaults(),
        enableProfanity: false,
        contentDetectionConfig: ContentDetectionConfig(
          categories: ContentCategoryDefaults.visualCategories,
        ),
      );

  bool get hasVisualDetection => contentDetectionConfig.hasVisualCategories;

  bool get hasAudioDetection =>
      enableProfanity || contentDetectionConfig.hasAudioCategories;

  bool get hasAnyDetection => hasVisualDetection || hasAudioDetection;

  Duration get minSegmentDuration =>
      Duration(milliseconds: minSegmentDurationMs);

  Duration get detectionBuffer => Duration(milliseconds: detectionBufferMs);

  List<String> validate() {
    final issues = <String>[];

    if (!hasAnyDetection) {
      issues.add('No detection types are enabled');
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

  bool get isValid => validate().isEmpty;
}
