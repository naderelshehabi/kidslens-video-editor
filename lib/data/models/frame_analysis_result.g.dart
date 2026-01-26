// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'frame_analysis_result.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$NsfwResultImpl _$$NsfwResultImplFromJson(Map<String, dynamic> json) =>
    _$NsfwResultImpl(
      porn: (json['porn'] as num).toDouble(),
      sexy: (json['sexy'] as num).toDouble(),
      hentai: (json['hentai'] as num).toDouble(),
      drawings: (json['drawings'] as num).toDouble(),
      neutral: (json['neutral'] as num).toDouble(),
    );

Map<String, dynamic> _$$NsfwResultImplToJson(_$NsfwResultImpl instance) =>
    <String, dynamic>{
      'porn': instance.porn,
      'sexy': instance.sexy,
      'hentai': instance.hentai,
      'drawings': instance.drawings,
      'neutral': instance.neutral,
    };

_$ViolenceResultImpl _$$ViolenceResultImplFromJson(Map<String, dynamic> json) =>
    _$ViolenceResultImpl(
      violent: (json['violent'] as num).toDouble(),
      nonViolent: (json['nonViolent'] as num).toDouble(),
    );

Map<String, dynamic> _$$ViolenceResultImplToJson(
        _$ViolenceResultImpl instance) =>
    <String, dynamic>{
      'violent': instance.violent,
      'nonViolent': instance.nonViolent,
    };

_$BloodResultImpl _$$BloodResultImplFromJson(Map<String, dynamic> json) =>
    _$BloodResultImpl(
      score: (json['score'] as num).toDouble(),
      regions: (json['regions'] as List<dynamic>?)
          ?.map((e) => BloodRegion.fromJson(e as Map<String, dynamic>))
          .toList(),
    );

Map<String, dynamic> _$$BloodResultImplToJson(_$BloodResultImpl instance) =>
    <String, dynamic>{
      'score': instance.score,
      'regions': instance.regions,
    };

_$BloodRegionImpl _$$BloodRegionImplFromJson(Map<String, dynamic> json) =>
    _$BloodRegionImpl(
      x: (json['x'] as num).toDouble(),
      y: (json['y'] as num).toDouble(),
      width: (json['width'] as num).toDouble(),
      height: (json['height'] as num).toDouble(),
      confidence: (json['confidence'] as num).toDouble(),
    );

Map<String, dynamic> _$$BloodRegionImplToJson(_$BloodRegionImpl instance) =>
    <String, dynamic>{
      'x': instance.x,
      'y': instance.y,
      'width': instance.width,
      'height': instance.height,
      'confidence': instance.confidence,
    };

_$WeaponsResultImpl _$$WeaponsResultImplFromJson(Map<String, dynamic> json) =>
    _$WeaponsResultImpl(
      score: (json['score'] as num).toDouble(),
      weapons: (json['weapons'] as List<dynamic>?)
          ?.map((e) => DetectedWeapon.fromJson(e as Map<String, dynamic>))
          .toList(),
    );

Map<String, dynamic> _$$WeaponsResultImplToJson(_$WeaponsResultImpl instance) =>
    <String, dynamic>{
      'score': instance.score,
      'weapons': instance.weapons,
    };

_$DetectedWeaponImpl _$$DetectedWeaponImplFromJson(Map<String, dynamic> json) =>
    _$DetectedWeaponImpl(
      type: json['type'] as String,
      confidence: (json['confidence'] as num).toDouble(),
      x: (json['x'] as num).toDouble(),
      y: (json['y'] as num).toDouble(),
      width: (json['width'] as num).toDouble(),
      height: (json['height'] as num).toDouble(),
    );

Map<String, dynamic> _$$DetectedWeaponImplToJson(
        _$DetectedWeaponImpl instance) =>
    <String, dynamic>{
      'type': instance.type,
      'confidence': instance.confidence,
      'x': instance.x,
      'y': instance.y,
      'width': instance.width,
      'height': instance.height,
    };

_$FrameAnalysisResultImpl _$$FrameAnalysisResultImplFromJson(
        Map<String, dynamic> json) =>
    _$FrameAnalysisResultImpl(
      frameNumber: (json['frameNumber'] as num).toInt(),
      timestamp: const DurationConverter()
          .fromJson((json['timestamp'] as num).toInt()),
      isSceneChange: json['isSceneChange'] as bool? ?? false,
      nsfw: NsfwResult.fromJson(json['nsfw'] as Map<String, dynamic>),
      violence:
          ViolenceResult.fromJson(json['violence'] as Map<String, dynamic>),
      blood: json['blood'] == null
          ? null
          : BloodResult.fromJson(json['blood'] as Map<String, dynamic>),
      weapons: json['weapons'] == null
          ? null
          : WeaponsResult.fromJson(json['weapons'] as Map<String, dynamic>),
      processingTimeMs: (json['processingTimeMs'] as num?)?.toInt(),
      frameHash: json['frameHash'] as String?,
    );

Map<String, dynamic> _$$FrameAnalysisResultImplToJson(
        _$FrameAnalysisResultImpl instance) =>
    <String, dynamic>{
      'frameNumber': instance.frameNumber,
      'timestamp': const DurationConverter().toJson(instance.timestamp),
      'isSceneChange': instance.isSceneChange,
      'nsfw': instance.nsfw,
      'violence': instance.violence,
      'blood': instance.blood,
      'weapons': instance.weapons,
      'processingTimeMs': instance.processingTimeMs,
      'frameHash': instance.frameHash,
    };
