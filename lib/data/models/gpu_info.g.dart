// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'gpu_info.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$AcceleratorInfoImpl _$$AcceleratorInfoImplFromJson(
        Map<String, dynamic> json) =>
    _$AcceleratorInfoImpl(
      type: $enumDecode(_$AcceleratorTypeEnumMap, json['type']),
      name: json['name'] as String,
      vramMB: (json['vramMB'] as num).toInt(),
      computeCapability: json['computeCapability'] as String?,
      isAppleSilicon: json['isAppleSilicon'] as bool? ?? false,
      recommendedBatchSize: (json['recommendedBatchSize'] as num).toInt(),
    );

Map<String, dynamic> _$$AcceleratorInfoImplToJson(
        _$AcceleratorInfoImpl instance) =>
    <String, dynamic>{
      'type': _$AcceleratorTypeEnumMap[instance.type]!,
      'name': instance.name,
      'vramMB': instance.vramMB,
      'computeCapability': instance.computeCapability,
      'isAppleSilicon': instance.isAppleSilicon,
      'recommendedBatchSize': instance.recommendedBatchSize,
    };

const _$AcceleratorTypeEnumMap = {
  AcceleratorType.cpu: 'cpu',
  AcceleratorType.cuda: 'cuda',
  AcceleratorType.metal: 'metal',
  AcceleratorType.rocm: 'rocm',
  AcceleratorType.vulkan: 'vulkan',
  AcceleratorType.oneapi: 'oneapi',
};

_$SystemCapabilitiesImpl _$$SystemCapabilitiesImplFromJson(
        Map<String, dynamic> json) =>
    _$SystemCapabilitiesImpl(
      cpuCores: (json['cpuCores'] as num).toInt(),
      ramMB: (json['ramMB'] as num).toInt(),
      availableRamMB: (json['availableRamMB'] as num).toInt(),
      diskSpaceMB: (json['diskSpaceMB'] as num).toInt(),
      availableDiskSpaceMB: (json['availableDiskSpaceMB'] as num).toInt(),
      accelerator: json['accelerator'] == null
          ? null
          : AcceleratorInfo.fromJson(
              json['accelerator'] as Map<String, dynamic>),
      supportedExecutionProviders:
          (json['supportedExecutionProviders'] as List<dynamic>?)
                  ?.map((e) => e as String)
                  .toList() ??
              const [],
    );

Map<String, dynamic> _$$SystemCapabilitiesImplToJson(
        _$SystemCapabilitiesImpl instance) =>
    <String, dynamic>{
      'cpuCores': instance.cpuCores,
      'ramMB': instance.ramMB,
      'availableRamMB': instance.availableRamMB,
      'diskSpaceMB': instance.diskSpaceMB,
      'availableDiskSpaceMB': instance.availableDiskSpaceMB,
      'accelerator': instance.accelerator,
      'supportedExecutionProviders': instance.supportedExecutionProviders,
    };
