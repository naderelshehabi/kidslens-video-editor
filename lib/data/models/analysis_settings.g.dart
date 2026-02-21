// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'analysis_settings.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$ModelConfigImpl _$$ModelConfigImplFromJson(Map<String, dynamic> json) =>
    _$ModelConfigImpl(
      asrModelId: json['asrModelId'] as String,
      visualModelId: json['visualModelId'] as String,
      nsfwModelId: json['nsfwModelId'] as String? ?? 'nsfw-vit-base-quantized',
      violenceModelId:
          json['violenceModelId'] as String? ?? 'violence-vit-classifier',
      bloodModelId: json['bloodModelId'] as String? ?? 'gore-classifier',
      weaponsModelId: json['weaponsModelId'] as String? ?? 'weapons-classifier',
      asrLanguage: json['asrLanguage'] as String? ?? 'en',
      useGpu: json['useGpu'] as bool? ?? true,
      cpuThreads: (json['cpuThreads'] as num?)?.toInt() ?? 4,
      batchSize: (json['batchSize'] as num?)?.toInt() ?? 8,
      useFp16: json['useFp16'] as bool? ?? false,
      translateToEnglish: json['translateToEnglish'] as bool? ?? false,
      wordLevelTimestamps: json['wordLevelTimestamps'] as bool? ?? false,
      beamSize: (json['beamSize'] as num?)?.toInt() ?? 3,
      nudeNetModelId: json['nudeNetModelId'] as String? ?? 'nudenet-v3-medium',
      clipVisionModelId:
          json['clipVisionModelId'] as String? ?? 'clip-vit-b32-vision-fp16',
      clipTextModelId:
          json['clipTextModelId'] as String? ?? 'clip-vit-b32-text-fp16',
    );

Map<String, dynamic> _$$ModelConfigImplToJson(_$ModelConfigImpl instance) =>
    <String, dynamic>{
      'asrModelId': instance.asrModelId,
      'visualModelId': instance.visualModelId,
      'nsfwModelId': instance.nsfwModelId,
      'violenceModelId': instance.violenceModelId,
      'bloodModelId': instance.bloodModelId,
      'weaponsModelId': instance.weaponsModelId,
      'asrLanguage': instance.asrLanguage,
      'useGpu': instance.useGpu,
      'cpuThreads': instance.cpuThreads,
      'batchSize': instance.batchSize,
      'useFp16': instance.useFp16,
      'translateToEnglish': instance.translateToEnglish,
      'wordLevelTimestamps': instance.wordLevelTimestamps,
      'beamSize': instance.beamSize,
      'nudeNetModelId': instance.nudeNetModelId,
      'clipVisionModelId': instance.clipVisionModelId,
      'clipTextModelId': instance.clipTextModelId,
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

_$VisualContentConfigImpl _$$VisualContentConfigImplFromJson(
        Map<String, dynamic> json) =>
    _$VisualContentConfigImpl(
      enableNudeNetDetection: json['enableNudeNetDetection'] as bool? ?? true,
      enableClipClassification:
          json['enableClipClassification'] as bool? ?? true,
      useNsfwPreFilter: json['useNsfwPreFilter'] as bool? ?? true,
      preFilterThreshold:
          (json['preFilterThreshold'] as num?)?.toDouble() ?? 0.30,
      categories: (json['categories'] as List<dynamic>?)
              ?.map((e) =>
                  VisualContentCategory.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
    );

Map<String, dynamic> _$$VisualContentConfigImplToJson(
        _$VisualContentConfigImpl instance) =>
    <String, dynamic>{
      'enableNudeNetDetection': instance.enableNudeNetDetection,
      'enableClipClassification': instance.enableClipClassification,
      'useNsfwPreFilter': instance.useNsfwPreFilter,
      'preFilterThreshold': instance.preFilterThreshold,
      'categories': instance.categories,
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
      useNsfwPreFilter: json['useNsfwPreFilter'] as bool? ?? true,
      preFilterThreshold:
          (json['preFilterThreshold'] as num?)?.toDouble() ?? 0.30,
      schemaVersion: (json['schemaVersion'] as num?)?.toInt() ?? 2,
    );

Map<String, dynamic> _$$ContentDetectionConfigImplToJson(
        _$ContentDetectionConfigImpl instance) =>
    <String, dynamic>{
      'categories': instance.categories,
      'votingConfig': instance.votingConfig,
      'useNsfwPreFilter': instance.useNsfwPreFilter,
      'preFilterThreshold': instance.preFilterThreshold,
      'schemaVersion': instance.schemaVersion,
    };

_$AnalysisSettingsImpl _$$AnalysisSettingsImplFromJson(
        Map<String, dynamic> json) =>
    _$AnalysisSettingsImpl(
      modelConfig:
          ModelConfig.fromJson(json['modelConfig'] as Map<String, dynamic>),
      profanityConfig: ProfanityConfig.fromJson(
          json['profanityConfig'] as Map<String, dynamic>),
      nsfwThreshold: (json['nsfwThreshold'] as num?)?.toDouble() ?? 0.6,
      violenceThreshold: (json['violenceThreshold'] as num?)?.toDouble() ?? 0.6,
      bloodThreshold: (json['bloodThreshold'] as num?)?.toDouble() ?? 0.6,
      weaponsThreshold: (json['weaponsThreshold'] as num?)?.toDouble() ?? 0.6,
      enableNsfw: json['enableNsfw'] as bool? ?? true,
      enableViolence: json['enableViolence'] as bool? ?? true,
      enableBlood: json['enableBlood'] as bool? ?? true,
      enableWeapons: json['enableWeapons'] as bool? ?? true,
      enableProfanity: json['enableProfanity'] as bool? ?? true,
      frameSamplingRate: (json['frameSamplingRate'] as num?)?.toInt() ?? 5,
      useSceneDetection: json['useSceneDetection'] as bool? ?? true,
      minSegmentDurationMs:
          (json['minSegmentDurationMs'] as num?)?.toInt() ?? 500,
      mergeAdjacentDetections: json['mergeAdjacentDetections'] as bool? ?? true,
      detectionBufferMs: (json['detectionBufferMs'] as num?)?.toInt() ?? 100,
      maxConcurrentAnalyses:
          (json['maxConcurrentAnalyses'] as num?)?.toInt() ?? 4,
      visualContentConfig: json['visualContentConfig'] == null
          ? const VisualContentConfig()
          : VisualContentConfig.fromJson(
              json['visualContentConfig'] as Map<String, dynamic>),
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
      'nsfwThreshold': instance.nsfwThreshold,
      'violenceThreshold': instance.violenceThreshold,
      'bloodThreshold': instance.bloodThreshold,
      'weaponsThreshold': instance.weaponsThreshold,
      'enableNsfw': instance.enableNsfw,
      'enableViolence': instance.enableViolence,
      'enableBlood': instance.enableBlood,
      'enableWeapons': instance.enableWeapons,
      'enableProfanity': instance.enableProfanity,
      'frameSamplingRate': instance.frameSamplingRate,
      'useSceneDetection': instance.useSceneDetection,
      'minSegmentDurationMs': instance.minSegmentDurationMs,
      'mergeAdjacentDetections': instance.mergeAdjacentDetections,
      'detectionBufferMs': instance.detectionBufferMs,
      'maxConcurrentAnalyses': instance.maxConcurrentAnalyses,
      'visualContentConfig': instance.visualContentConfig,
      'contentDetectionConfig': instance.contentDetectionConfig,
    };
