// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'detection.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$DetectionImpl _$$DetectionImplFromJson(Map<String, dynamic> json) =>
    _$DetectionImpl(
      id: json['id'] as String,
      mediaId: json['mediaId'] as String,
      type: $enumDecode(_$ContentTypeEnumMap, json['type']),
      startTime: const DurationConverter()
          .fromJson((json['startTime'] as num).toInt()),
      endTime:
          const DurationConverter().fromJson((json['endTime'] as num).toInt()),
      confidence: (json['confidence'] as num).toDouble(),
      description: json['description'] as String,
      userStatus: $enumDecodeNullable(
              _$DetectionUserStatusEnumMap, json['userStatus']) ??
          DetectionUserStatus.pending,
      userNote: json['userNote'] as String?,
      originalStartTime: _$JsonConverterFromJson<int, Duration>(
          json['originalStartTime'], const DurationConverter().fromJson),
      originalEndTime: _$JsonConverterFromJson<int, Duration>(
          json['originalEndTime'], const DurationConverter().fromJson),
      source: json['source'] as String?,
      metadata: json['metadata'] as Map<String, dynamic>?,
    );

Map<String, dynamic> _$$DetectionImplToJson(_$DetectionImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'mediaId': instance.mediaId,
      'type': _$ContentTypeEnumMap[instance.type]!,
      'startTime': const DurationConverter().toJson(instance.startTime),
      'endTime': const DurationConverter().toJson(instance.endTime),
      'confidence': instance.confidence,
      'description': instance.description,
      'userStatus': _$DetectionUserStatusEnumMap[instance.userStatus]!,
      'userNote': instance.userNote,
      'originalStartTime': _$JsonConverterToJson<int, Duration>(
          instance.originalStartTime, const DurationConverter().toJson),
      'originalEndTime': _$JsonConverterToJson<int, Duration>(
          instance.originalEndTime, const DurationConverter().toJson),
      'source': instance.source,
      'metadata': instance.metadata,
    };

const _$ContentTypeEnumMap = {
  ContentType.nsfw: 'nsfw',
  ContentType.violence: 'violence',
  ContentType.blood: 'blood',
  ContentType.profanity: 'profanity',
  ContentType.weapons: 'weapons',
};

const _$DetectionUserStatusEnumMap = {
  DetectionUserStatus.pending: 'pending',
  DetectionUserStatus.confirmed: 'confirmed',
  DetectionUserStatus.rejected: 'rejected',
  DetectionUserStatus.adjusted: 'adjusted',
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
