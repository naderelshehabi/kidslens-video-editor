// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'gpu_config.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$GpuConfigImpl _$$GpuConfigImplFromJson(Map<String, dynamic> json) =>
    _$GpuConfigImpl(
      asrGpuEnabled: json['asrGpuEnabled'] as bool? ?? true,
      asrGpuDevice: (json['asrGpuDevice'] as num?)?.toInt() ?? 0,
      onnxGpuEnabled: json['onnxGpuEnabled'] as bool? ?? true,
      onnxExecutionProvider: json['onnxExecutionProvider'] as String? ?? 'auto',
      onnxGpuDevice: (json['onnxGpuDevice'] as num?)?.toInt(),
      cpuThreads: (json['cpuThreads'] as num?)?.toInt() ?? 4,
      batchSize: (json['batchSize'] as num?)?.toInt() ?? 8,
      useFp16: json['useFp16'] as bool? ?? false,
    );

Map<String, dynamic> _$$GpuConfigImplToJson(_$GpuConfigImpl instance) =>
    <String, dynamic>{
      'asrGpuEnabled': instance.asrGpuEnabled,
      'asrGpuDevice': instance.asrGpuDevice,
      'onnxGpuEnabled': instance.onnxGpuEnabled,
      'onnxExecutionProvider': instance.onnxExecutionProvider,
      'onnxGpuDevice': instance.onnxGpuDevice,
      'cpuThreads': instance.cpuThreads,
      'batchSize': instance.batchSize,
      'useFp16': instance.useFp16,
    };
