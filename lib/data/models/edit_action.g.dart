// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'edit_action.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$EditActionImpl _$$EditActionImplFromJson(Map<String, dynamic> json) =>
    _$EditActionImpl(
      id: json['id'] as String,
      mediaId: json['mediaId'] as String,
      type: $enumDecode(_$EditActionTypeEnumMap, json['type']),
      startTime: const DurationConverter()
          .fromJson((json['startTime'] as num).toInt()),
      endTime:
          const DurationConverter().fromJson((json['endTime'] as num).toInt()),
      detectionId: json['detectionId'] as String?,
      enabled: json['enabled'] as bool? ?? true,
      blurIntensity: (json['blurIntensity'] as num?)?.toDouble() ?? 1.0,
      boundingBox: json['boundingBox'] == null
          ? null
          : BoundingBox.fromJson(json['boundingBox'] as Map<String, dynamic>),
      beepFrequency: (json['beepFrequency'] as num?)?.toDouble() ?? 1000.0,
      notes: json['notes'] as String?,
      createdAt: _$JsonConverterFromJson<String, DateTime>(
          json['createdAt'], const DateTimeConverter().fromJson),
    );

Map<String, dynamic> _$$EditActionImplToJson(_$EditActionImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'mediaId': instance.mediaId,
      'type': _$EditActionTypeEnumMap[instance.type]!,
      'startTime': const DurationConverter().toJson(instance.startTime),
      'endTime': const DurationConverter().toJson(instance.endTime),
      'detectionId': instance.detectionId,
      'enabled': instance.enabled,
      'blurIntensity': instance.blurIntensity,
      'boundingBox': instance.boundingBox,
      'beepFrequency': instance.beepFrequency,
      'notes': instance.notes,
      'createdAt': _$JsonConverterToJson<String, DateTime>(
          instance.createdAt, const DateTimeConverter().toJson),
    };

const _$EditActionTypeEnumMap = {
  EditActionType.mute: 'mute',
  EditActionType.beep: 'beep',
  EditActionType.blur: 'blur',
  EditActionType.cut: 'cut',
  EditActionType.skip: 'skip',
};

Value? _$JsonConverterFromJson<Json, Value>(
  Object? json,
  Value? Function(Json json) fromJson,
) =>
    json == null ? null : fromJson(json as Json);

Json? _$JsonConverterToJson<Json, Value>(
  Value? value,
  Json? Function(Value value) toJson,
) =>
    value == null ? null : toJson(value);

_$BoundingBoxImpl _$$BoundingBoxImplFromJson(Map<String, dynamic> json) =>
    _$BoundingBoxImpl(
      left: (json['left'] as num).toDouble(),
      top: (json['top'] as num).toDouble(),
      width: (json['width'] as num).toDouble(),
      height: (json['height'] as num).toDouble(),
    );

Map<String, dynamic> _$$BoundingBoxImplToJson(_$BoundingBoxImpl instance) =>
    <String, dynamic>{
      'left': instance.left,
      'top': instance.top,
      'width': instance.width,
      'height': instance.height,
    };
