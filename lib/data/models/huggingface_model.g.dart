// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'huggingface_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$HuggingFaceModelImpl _$$HuggingFaceModelImplFromJson(
        Map<String, dynamic> json) =>
    _$HuggingFaceModelImpl(
      id: json['id'] as String,
      displayName: json['displayName'] as String,
      huggingFaceId: json['huggingFaceId'] as String,
      fileName: json['fileName'] as String,
      parameters: json['parameters'] as String,
      parameterCount: (json['parameterCount'] as num).toInt(),
      sizeBytes: (json['sizeBytes'] as num).toInt(),
      ramRequired: (json['ramRequired'] as num).toInt(),
      speedMultiplier: (json['speedMultiplier'] as num).toDouble(),
      accuracyPercent: (json['accuracyPercent'] as num).toInt(),
      modelType: $enumDecode(_$HuggingFaceModelTypeEnumMap, json['modelType']),
      languages: (json['languages'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          const [],
      badge: json['badge'] as String?,
      description: json['description'] as String?,
      requiresGpu: json['requiresGpu'] as bool? ?? false,
      minVramBytes: (json['minVramBytes'] as num?)?.toInt() ?? 0,
      license: json['license'] as String? ?? 'MIT',
    );

Map<String, dynamic> _$$HuggingFaceModelImplToJson(
        _$HuggingFaceModelImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'displayName': instance.displayName,
      'huggingFaceId': instance.huggingFaceId,
      'fileName': instance.fileName,
      'parameters': instance.parameters,
      'parameterCount': instance.parameterCount,
      'sizeBytes': instance.sizeBytes,
      'ramRequired': instance.ramRequired,
      'speedMultiplier': instance.speedMultiplier,
      'accuracyPercent': instance.accuracyPercent,
      'modelType': _$HuggingFaceModelTypeEnumMap[instance.modelType]!,
      'languages': instance.languages,
      'badge': instance.badge,
      'description': instance.description,
      'requiresGpu': instance.requiresGpu,
      'minVramBytes': instance.minVramBytes,
      'license': instance.license,
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
