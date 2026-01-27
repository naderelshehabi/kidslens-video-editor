// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'project.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$ProjectImpl _$$ProjectImplFromJson(Map<String, dynamic> json) =>
    _$ProjectImpl(
      id: json['id'] as String,
      name: json['name'] as String,
      projectPath: json['projectPath'] as String,
      createdAt:
          const DateTimeConverter().fromJson(json['createdAt'] as String),
      modifiedAt:
          const DateTimeConverter().fromJson(json['modifiedAt'] as String),
      mediaFiles: (json['mediaFiles'] as List<dynamic>?)
              ?.map((e) => MediaFile.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
      selectedMediaId: json['selectedMediaId'] as String?,
      detections: (json['detections'] as List<dynamic>?)
              ?.map((e) => Detection.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
      editActions: (json['editActions'] as List<dynamic>?)
              ?.map((e) => EditAction.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
      settings: json['settings'] == null
          ? const ProjectSettings()
          : ProjectSettings.fromJson(json['settings'] as Map<String, dynamic>),
      analysisProgress: (json['analysisProgress'] as num?)?.toDouble(),
      analysisComplete: json['analysisComplete'] as bool? ?? false,
    );

Map<String, dynamic> _$$ProjectImplToJson(_$ProjectImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'projectPath': instance.projectPath,
      'createdAt': const DateTimeConverter().toJson(instance.createdAt),
      'modifiedAt': const DateTimeConverter().toJson(instance.modifiedAt),
      'mediaFiles': instance.mediaFiles,
      'selectedMediaId': instance.selectedMediaId,
      'detections': instance.detections,
      'editActions': instance.editActions,
      'settings': instance.settings,
      'analysisProgress': instance.analysisProgress,
      'analysisComplete': instance.analysisComplete,
    };

_$ProjectSettingsImpl _$$ProjectSettingsImplFromJson(
        Map<String, dynamic> json) =>
    _$ProjectSettingsImpl(
      outputQuality:
          $enumDecodeNullable(_$OutputQualityEnumMap, json['outputQuality']) ??
              OutputQuality.high,
      includeOriginalAudio: json['includeOriginalAudio'] as bool? ?? true,
      autoSave: json['autoSave'] as bool? ?? true,
      autoSaveIntervalSeconds:
          (json['autoSaveIntervalSeconds'] as num?)?.toInt() ?? 60,
      detectionSensitivity:
          (json['detectionSensitivity'] as num?)?.toDouble() ?? 0.7,
      detectionCategories: json['detectionCategories'] == null
          ? const DetectionCategories()
          : DetectionCategories.fromJson(
              json['detectionCategories'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$$ProjectSettingsImplToJson(
        _$ProjectSettingsImpl instance) =>
    <String, dynamic>{
      'outputQuality': _$OutputQualityEnumMap[instance.outputQuality]!,
      'includeOriginalAudio': instance.includeOriginalAudio,
      'autoSave': instance.autoSave,
      'autoSaveIntervalSeconds': instance.autoSaveIntervalSeconds,
      'detectionSensitivity': instance.detectionSensitivity,
      'detectionCategories': instance.detectionCategories,
    };

const _$OutputQualityEnumMap = {
  OutputQuality.low: 'low',
  OutputQuality.medium: 'medium',
  OutputQuality.high: 'high',
  OutputQuality.original: 'original',
};

_$DetectionCategoriesImpl _$$DetectionCategoriesImplFromJson(
        Map<String, dynamic> json) =>
    _$DetectionCategoriesImpl(
      profanity: json['profanity'] as bool? ?? true,
      nudity: json['nudity'] as bool? ?? true,
      violence: json['violence'] as bool? ?? true,
      drugs: json['drugs'] as bool? ?? true,
      alcohol: json['alcohol'] as bool? ?? true,
      customWords: json['customWords'] as bool? ?? false,
      customWordList: (json['customWordList'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          const [],
    );

Map<String, dynamic> _$$DetectionCategoriesImplToJson(
        _$DetectionCategoriesImpl instance) =>
    <String, dynamic>{
      'profanity': instance.profanity,
      'nudity': instance.nudity,
      'violence': instance.violence,
      'drugs': instance.drugs,
      'alcohol': instance.alcohol,
      'customWords': instance.customWords,
      'customWordList': instance.customWordList,
    };
