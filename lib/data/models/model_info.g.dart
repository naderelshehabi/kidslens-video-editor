// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'model_info.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$HardwareInfoImpl _$$HardwareInfoImplFromJson(Map<String, dynamic> json) =>
    _$HardwareInfoImpl(
      availableRamBytes: (json['availableRamBytes'] as num).toInt(),
      availableVramBytes: (json['availableVramBytes'] as num?)?.toInt() ?? 0,
      hasGpu: json['hasGpu'] as bool? ?? false,
      gpuName: json['gpuName'] as String?,
      cpuCores: (json['cpuCores'] as num?)?.toInt() ?? 4,
      supportsAvx2: json['supportsAvx2'] as bool? ?? false,
      supportsCuda: json['supportsCuda'] as bool? ?? false,
      supportsMetal: json['supportsMetal'] as bool? ?? false,
      operatingSystem: json['operatingSystem'] as String?,
    );

Map<String, dynamic> _$$HardwareInfoImplToJson(_$HardwareInfoImpl instance) =>
    <String, dynamic>{
      'availableRamBytes': instance.availableRamBytes,
      'availableVramBytes': instance.availableVramBytes,
      'hasGpu': instance.hasGpu,
      'gpuName': instance.gpuName,
      'cpuCores': instance.cpuCores,
      'supportsAvx2': instance.supportsAvx2,
      'supportsCuda': instance.supportsCuda,
      'supportsMetal': instance.supportsMetal,
      'operatingSystem': instance.operatingSystem,
    };

_$ModelInfoImpl _$$ModelInfoImplFromJson(Map<String, dynamic> json) =>
    _$ModelInfoImpl(
      id: json['id'] as String,
      displayName: json['displayName'] as String,
      description: json['description'] as String,
      type: $enumDecode(_$ModelTypeEnumMap, json['type']),
      sizeBytes: (json['sizeBytes'] as num).toInt(),
      accuracyPercent: (json['accuracyPercent'] as num).toInt(),
      speedRating: (json['speedRating'] as num).toInt(),
      badge: json['badge'] as String?,
      minRamBytes: (json['minRamBytes'] as num?)?.toInt() ?? 0,
      minVramBytes: (json['minVramBytes'] as num?)?.toInt() ?? 0,
      requiresGpu: json['requiresGpu'] as bool? ?? false,
      requiresAvx2: json['requiresAvx2'] as bool? ?? false,
      supportedLanguages: (json['supportedLanguages'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList(),
      downloadUrl: json['downloadUrl'] as String?,
      version: json['version'] as String?,
      releaseDate: json['releaseDate'] == null
          ? null
          : DateTime.parse(json['releaseDate'] as String),
      metadata: json['metadata'] as Map<String, dynamic>?,
    );

Map<String, dynamic> _$$ModelInfoImplToJson(_$ModelInfoImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'displayName': instance.displayName,
      'description': instance.description,
      'type': _$ModelTypeEnumMap[instance.type]!,
      'sizeBytes': instance.sizeBytes,
      'accuracyPercent': instance.accuracyPercent,
      'speedRating': instance.speedRating,
      'badge': instance.badge,
      'minRamBytes': instance.minRamBytes,
      'minVramBytes': instance.minVramBytes,
      'requiresGpu': instance.requiresGpu,
      'requiresAvx2': instance.requiresAvx2,
      'supportedLanguages': instance.supportedLanguages,
      'downloadUrl': instance.downloadUrl,
      'version': instance.version,
      'releaseDate': instance.releaseDate?.toIso8601String(),
      'metadata': instance.metadata,
    };

const _$ModelTypeEnumMap = {
  ModelType.asr: 'asr',
  ModelType.visual: 'visual',
};
