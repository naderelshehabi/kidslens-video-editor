// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'visual_content_category.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$VisualContentCategoryImpl _$$VisualContentCategoryImplFromJson(
        Map<String, dynamic> json) =>
    _$VisualContentCategoryImpl(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String,
      detectionLabels: (json['detectionLabels'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          const [],
      clipPrompts: (json['clipPrompts'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          const [],
      clipNegativePrompts: (json['clipNegativePrompts'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          const [],
      detectionSource: $enumDecode(
          _$CategoryDetectionSourceEnumMap, json['detectionSource'],
          unknownValue: CategoryDetectionSource.clip),
      enabled: json['enabled'] as bool? ?? true,
      threshold: (json['threshold'] as num?)?.toDouble() ?? 0.5,
      clipThreshold: (json['clipThreshold'] as num?)?.toDouble() ?? 3.0,
      action: $enumDecodeNullable(_$VisualContentActionEnumMap, json['action'],
              unknownValue: VisualContentAction.blurRegion) ??
          VisualContentAction.blurRegion,
      iconName: json['iconName'] as String?,
      isBuiltIn: json['isBuiltIn'] as bool? ?? true,
    );

Map<String, dynamic> _$$VisualContentCategoryImplToJson(
        _$VisualContentCategoryImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'description': instance.description,
      'detectionLabels': instance.detectionLabels,
      'clipPrompts': instance.clipPrompts,
      'clipNegativePrompts': instance.clipNegativePrompts,
      'detectionSource':
          _$CategoryDetectionSourceEnumMap[instance.detectionSource]!,
      'enabled': instance.enabled,
      'threshold': instance.threshold,
      'clipThreshold': instance.clipThreshold,
      'action': _$VisualContentActionEnumMap[instance.action]!,
      'iconName': instance.iconName,
      'isBuiltIn': instance.isBuiltIn,
    };

const _$CategoryDetectionSourceEnumMap = {
  CategoryDetectionSource.nudeNet: 'nudeNet',
  CategoryDetectionSource.clip: 'clip',
  CategoryDetectionSource.both: 'both',
};

const _$VisualContentActionEnumMap = {
  VisualContentAction.blurRegion: 'blurRegion',
  VisualContentAction.pixelateRegion: 'pixelateRegion',
  VisualContentAction.blackBoxRegion: 'blackBoxRegion',
  VisualContentAction.cutScene: 'cutScene',
};
