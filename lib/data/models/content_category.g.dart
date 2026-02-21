// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'content_category.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$ModelContributionImpl _$$ModelContributionImplFromJson(
        Map<String, dynamic> json) =>
    _$ModelContributionImpl(
      modelId: json['modelId'] as String,
      displayName: json['displayName'] as String,
      modelType: $enumDecode(_$HuggingFaceModelTypeEnumMap, json['modelType']),
      enabled: json['enabled'] as bool? ?? true,
      weightOverride: (json['weightOverride'] as num?)?.toDouble(),
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
    );

Map<String, dynamic> _$$ModelContributionImplToJson(
        _$ModelContributionImpl instance) =>
    <String, dynamic>{
      'modelId': instance.modelId,
      'displayName': instance.displayName,
      'modelType': _$HuggingFaceModelTypeEnumMap[instance.modelType]!,
      'enabled': instance.enabled,
      'weightOverride': instance.weightOverride,
      'detectionLabels': instance.detectionLabels,
      'clipPrompts': instance.clipPrompts,
      'clipNegativePrompts': instance.clipNegativePrompts,
    };

const _$HuggingFaceModelTypeEnumMap = {
  HuggingFaceModelType.asr: 'asr',
  HuggingFaceModelType.nsfw: 'nsfw',
  HuggingFaceModelType.violence: 'violence',
  HuggingFaceModelType.blood: 'blood',
  HuggingFaceModelType.weapons: 'weapons',
  HuggingFaceModelType.nudeNet: 'nudeNet',
  HuggingFaceModelType.clip: 'clip',
};

_$ContentCategoryImpl _$$ContentCategoryImplFromJson(
        Map<String, dynamic> json) =>
    _$ContentCategoryImpl(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String,
      type: $enumDecode(_$CategoryTypeEnumMap, json['type']),
      action: $enumDecode(_$RemediationActionEnumMap, json['action']),
      enabled: json['enabled'] as bool? ?? true,
      threshold: (json['threshold'] as num?)?.toDouble() ?? 0.5,
      modelContributions: (json['modelContributions'] as List<dynamic>?)
              ?.map(
                  (e) => ModelContribution.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
      isBuiltIn: json['isBuiltIn'] as bool? ?? true,
      iconName: json['iconName'] as String?,
      supportsRegions: json['supportsRegions'] as bool? ?? false,
    );

Map<String, dynamic> _$$ContentCategoryImplToJson(
        _$ContentCategoryImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'description': instance.description,
      'type': _$CategoryTypeEnumMap[instance.type]!,
      'action': _$RemediationActionEnumMap[instance.action]!,
      'enabled': instance.enabled,
      'threshold': instance.threshold,
      'modelContributions': instance.modelContributions,
      'isBuiltIn': instance.isBuiltIn,
      'iconName': instance.iconName,
      'supportsRegions': instance.supportsRegions,
    };

const _$CategoryTypeEnumMap = {
  CategoryType.visual: 'visual',
  CategoryType.audio: 'audio',
};

const _$RemediationActionEnumMap = {
  RemediationAction.blurRegion: 'blurRegion',
  RemediationAction.pixelateRegion: 'pixelateRegion',
  RemediationAction.blackBoxRegion: 'blackBoxRegion',
  RemediationAction.blurFullFrame: 'blurFullFrame',
  RemediationAction.cutScene: 'cutScene',
  RemediationAction.mute: 'mute',
  RemediationAction.beep: 'beep',
};
