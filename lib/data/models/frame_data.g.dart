// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'frame_data.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$FrameDataImpl _$$FrameDataImplFromJson(Map<String, dynamic> json) =>
    _$FrameDataImpl(
      timestamp: const DurationConverter()
          .fromJson((json['timestamp'] as num).toInt()),
      width: (json['width'] as num).toInt(),
      height: (json['height'] as num).toInt(),
      data: const Uint8ListConverter().fromJson(json['data'] as String),
      format: $enumDecodeNullable(_$FrameFormatEnumMap, json['format']) ??
          FrameFormat.rgb24,
      frameNumber: (json['frameNumber'] as num?)?.toInt(),
      isKeyframe: json['isKeyframe'] as bool? ?? false,
      pts: (json['pts'] as num?)?.toInt(),
      sceneChangeScore: (json['sceneChangeScore'] as num?)?.toDouble(),
      averageLuminance: (json['averageLuminance'] as num?)?.toDouble(),
      motionScore: (json['motionScore'] as num?)?.toDouble(),
    );

Map<String, dynamic> _$$FrameDataImplToJson(_$FrameDataImpl instance) =>
    <String, dynamic>{
      'timestamp': const DurationConverter().toJson(instance.timestamp),
      'width': instance.width,
      'height': instance.height,
      'data': const Uint8ListConverter().toJson(instance.data),
      'format': _$FrameFormatEnumMap[instance.format]!,
      'frameNumber': instance.frameNumber,
      'isKeyframe': instance.isKeyframe,
      'pts': instance.pts,
      'sceneChangeScore': instance.sceneChangeScore,
      'averageLuminance': instance.averageLuminance,
      'motionScore': instance.motionScore,
    };

const _$FrameFormatEnumMap = {
  FrameFormat.rgb24: 'rgb24',
  FrameFormat.rgba32: 'rgba32',
  FrameFormat.bgr24: 'bgr24',
  FrameFormat.bgra32: 'bgra32',
  FrameFormat.gray8: 'gray8',
  FrameFormat.yuv420p: 'yuv420p',
  FrameFormat.nv12: 'nv12',
};

_$FrameBatchImpl _$$FrameBatchImplFromJson(Map<String, dynamic> json) =>
    _$FrameBatchImpl(
      frames: (json['frames'] as List<dynamic>)
          .map((e) => FrameData.fromJson(e as Map<String, dynamic>))
          .toList(),
      batchIndex: (json['batchIndex'] as num?)?.toInt() ?? 0,
      totalBatches: (json['totalBatches'] as num?)?.toInt(),
    );

Map<String, dynamic> _$$FrameBatchImplToJson(_$FrameBatchImpl instance) =>
    <String, dynamic>{
      'frames': instance.frames,
      'batchIndex': instance.batchIndex,
      'totalBatches': instance.totalBatches,
    };
