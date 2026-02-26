// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'gpu_config.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$GpuConfigImpl _$$GpuConfigImplFromJson(Map<String, dynamic> json) =>
    _$GpuConfigImpl(
      useGpu: json['useGpu'] as bool? ?? true,
      gpuDeviceIndex: (json['gpuDeviceIndex'] as num?)?.toInt() ?? 0,
      onnxExecutionProvider: json['onnxExecutionProvider'] as String? ?? 'auto',
      cpuThreads: (json['cpuThreads'] as num?)?.toInt() ?? 4,
      batchSize: (json['batchSize'] as num?)?.toInt() ?? 8,
      useFp16: json['useFp16'] as bool? ?? false,
    );

Map<String, dynamic> _$$GpuConfigImplToJson(_$GpuConfigImpl instance) =>
    <String, dynamic>{
      'useGpu': instance.useGpu,
      'gpuDeviceIndex': instance.gpuDeviceIndex,
      'onnxExecutionProvider': instance.onnxExecutionProvider,
      'cpuThreads': instance.cpuThreads,
      'batchSize': instance.batchSize,
      'useFp16': instance.useFp16,
    };
