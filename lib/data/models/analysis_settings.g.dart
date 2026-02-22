// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'analysis_settings.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$ModelConfigImpl _$$ModelConfigImplFromJson(Map<String, dynamic> json) =>
    _$ModelConfigImpl(
      asrModelId: json['asrModelId'] as String,
      nsfwModelId:
          json['nsfwModelId'] as String? ?? 'nsfw-gantman-mobilenet-v2-224',
      asrLanguage: json['asrLanguage'] as String? ?? 'en',
      useGpu: json['useGpu'] as bool? ?? true,
      cpuThreads: (json['cpuThreads'] as num?)?.toInt() ?? 4,
      batchSize: (json['batchSize'] as num?)?.toInt() ?? 8,
      useFp16: json['useFp16'] as bool? ?? false,
      translateToEnglish: json['translateToEnglish'] as bool? ?? false,
      wordLevelTimestamps: json['wordLevelTimestamps'] as bool? ?? false,
      beamSize: (json['beamSize'] as num?)?.toInt() ?? 3,
    );

Map<String, dynamic> _$$ModelConfigImplToJson(_$ModelConfigImpl instance) =>
    <String, dynamic>{
      'asrModelId': instance.asrModelId,
      'nsfwModelId': instance.nsfwModelId,
      'asrLanguage': instance.asrLanguage,
      'useGpu': instance.useGpu,
      'cpuThreads': instance.cpuThreads,
      'batchSize': instance.batchSize,
      'useFp16': instance.useFp16,
      'translateToEnglish': instance.translateToEnglish,
      'wordLevelTimestamps': instance.wordLevelTimestamps,
      'beamSize': instance.beamSize,
    };

_$ProfanityConfigImpl _$$ProfanityConfigImplFromJson(
        Map<String, dynamic> json) =>
    _$ProfanityConfigImpl(
      wordlistIds: (json['wordlistIds'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          const ['english-profanity'],
      detectLeetspeak: json['detectLeetspeak'] as bool? ?? true,
      detectPhonetic: json['detectPhonetic'] as bool? ?? true,
      detectFuzzy: json['detectFuzzy'] as bool? ?? true,
      detectObfuscated: json['detectObfuscated'] as bool? ?? true,
      fuzzyThreshold: (json['fuzzyThreshold'] as num?)?.toDouble() ?? 0.8,
      customWords: (json['customWords'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          const [],
      excludedWords: (json['excludedWords'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          const [],
      minWordLength: (json['minWordLength'] as num?)?.toInt() ?? 2,
      useContextAnalysis: json['useContextAnalysis'] as bool? ?? true,
    );

Map<String, dynamic> _$$ProfanityConfigImplToJson(
        _$ProfanityConfigImpl instance) =>
    <String, dynamic>{
      'wordlistIds': instance.wordlistIds,
      'detectLeetspeak': instance.detectLeetspeak,
      'detectPhonetic': instance.detectPhonetic,
      'detectFuzzy': instance.detectFuzzy,
      'detectObfuscated': instance.detectObfuscated,
      'fuzzyThreshold': instance.fuzzyThreshold,
      'customWords': instance.customWords,
      'excludedWords': instance.excludedWords,
      'minWordLength': instance.minWordLength,
      'useContextAnalysis': instance.useContextAnalysis,
    };

_$ContentDetectionConfigImpl _$$ContentDetectionConfigImplFromJson(
        Map<String, dynamic> json) =>
    _$ContentDetectionConfigImpl(
      categories: (json['categories'] as List<dynamic>?)
              ?.map((e) => ContentCategory.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
      votingConfig: json['votingConfig'] == null
          ? const VotingConfig()
          : VotingConfig.fromJson(json['votingConfig'] as Map<String, dynamic>),
      schemaVersion: (json['schemaVersion'] as num?)?.toInt() ?? 3,
    );

Map<String, dynamic> _$$ContentDetectionConfigImplToJson(
        _$ContentDetectionConfigImpl instance) =>
    <String, dynamic>{
      'categories': instance.categories,
      'votingConfig': instance.votingConfig,
      'schemaVersion': instance.schemaVersion,
    };

_$AnalysisSettingsImpl _$$AnalysisSettingsImplFromJson(
        Map<String, dynamic> json) =>
    _$AnalysisSettingsImpl(
      modelConfig:
          ModelConfig.fromJson(json['modelConfig'] as Map<String, dynamic>),
      profanityConfig: ProfanityConfig.fromJson(
          json['profanityConfig'] as Map<String, dynamic>),
      enableProfanity: json['enableProfanity'] as bool? ?? true,
      frameSamplingRate: (json['frameSamplingRate'] as num?)?.toInt() ?? 5,
      useSceneDetection: json['useSceneDetection'] as bool? ?? true,
      minSegmentDurationMs:
          (json['minSegmentDurationMs'] as num?)?.toInt() ?? 500,
      mergeAdjacentDetections: json['mergeAdjacentDetections'] as bool? ?? true,
      detectionBufferMs: (json['detectionBufferMs'] as num?)?.toInt() ?? 100,
      maxConcurrentAnalyses:
          (json['maxConcurrentAnalyses'] as num?)?.toInt() ?? 4,
      contentDetectionConfig: json['contentDetectionConfig'] == null
          ? const ContentDetectionConfig()
          : ContentDetectionConfig.fromJson(
              json['contentDetectionConfig'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$$AnalysisSettingsImplToJson(
        _$AnalysisSettingsImpl instance) =>
    <String, dynamic>{
      'modelConfig': instance.modelConfig,
      'profanityConfig': instance.profanityConfig,
      'enableProfanity': instance.enableProfanity,
      'frameSamplingRate': instance.frameSamplingRate,
      'useSceneDetection': instance.useSceneDetection,
      'minSegmentDurationMs': instance.minSegmentDurationMs,
      'mergeAdjacentDetections': instance.mergeAdjacentDetections,
      'detectionBufferMs': instance.detectionBufferMs,
      'maxConcurrentAnalyses': instance.maxConcurrentAnalyses,
      'contentDetectionConfig': instance.contentDetectionConfig,
    };
