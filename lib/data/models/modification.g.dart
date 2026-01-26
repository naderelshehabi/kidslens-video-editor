// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'modification.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$AudioMuteImpl _$$AudioMuteImplFromJson(Map<String, dynamic> json) =>
    _$AudioMuteImpl(
      $type: json['runtimeType'] as String?,
    );

Map<String, dynamic> _$$AudioMuteImplToJson(_$AudioMuteImpl instance) =>
    <String, dynamic>{
      'runtimeType': instance.$type,
    };

_$AudioBeepImpl _$$AudioBeepImplFromJson(Map<String, dynamic> json) =>
    _$AudioBeepImpl(
      frequency: (json['frequency'] as num?)?.toInt() ?? 1000,
      volume: (json['volume'] as num?)?.toDouble() ?? 0.5,
      $type: json['runtimeType'] as String?,
    );

Map<String, dynamic> _$$AudioBeepImplToJson(_$AudioBeepImpl instance) =>
    <String, dynamic>{
      'frequency': instance.frequency,
      'volume': instance.volume,
      'runtimeType': instance.$type,
    };

_$AudioReplaceImpl _$$AudioReplaceImplFromJson(Map<String, dynamic> json) =>
    _$AudioReplaceImpl(
      audioPath: json['audioPath'] as String,
      volume: (json['volume'] as num?)?.toDouble() ?? 1.0,
      loop: json['loop'] as bool? ?? false,
      $type: json['runtimeType'] as String?,
    );

Map<String, dynamic> _$$AudioReplaceImplToJson(_$AudioReplaceImpl instance) =>
    <String, dynamic>{
      'audioPath': instance.audioPath,
      'volume': instance.volume,
      'loop': instance.loop,
      'runtimeType': instance.$type,
    };

_$VideoBlurImpl _$$VideoBlurImplFromJson(Map<String, dynamic> json) =>
    _$VideoBlurImpl(
      intensity: (json['intensity'] as num?)?.toInt() ?? 20,
      $type: json['runtimeType'] as String?,
    );

Map<String, dynamic> _$$VideoBlurImplToJson(_$VideoBlurImpl instance) =>
    <String, dynamic>{
      'intensity': instance.intensity,
      'runtimeType': instance.$type,
    };

_$VideoPixelateImpl _$$VideoPixelateImplFromJson(Map<String, dynamic> json) =>
    _$VideoPixelateImpl(
      blockSize: (json['blockSize'] as num?)?.toInt() ?? 16,
      $type: json['runtimeType'] as String?,
    );

Map<String, dynamic> _$$VideoPixelateImplToJson(_$VideoPixelateImpl instance) =>
    <String, dynamic>{
      'blockSize': instance.blockSize,
      'runtimeType': instance.$type,
    };

_$VideoBlackBoxImpl _$$VideoBlackBoxImplFromJson(Map<String, dynamic> json) =>
    _$VideoBlackBoxImpl(
      color: json['color'] as String? ?? '#000000',
      opacity: (json['opacity'] as num?)?.toDouble() ?? 1.0,
      $type: json['runtimeType'] as String?,
    );

Map<String, dynamic> _$$VideoBlackBoxImplToJson(_$VideoBlackBoxImpl instance) =>
    <String, dynamic>{
      'color': instance.color,
      'opacity': instance.opacity,
      'runtimeType': instance.$type,
    };

_$VideoSkipImpl _$$VideoSkipImplFromJson(Map<String, dynamic> json) =>
    _$VideoSkipImpl(
      $type: json['runtimeType'] as String?,
    );

Map<String, dynamic> _$$VideoSkipImplToJson(_$VideoSkipImpl instance) =>
    <String, dynamic>{
      'runtimeType': instance.$type,
    };
