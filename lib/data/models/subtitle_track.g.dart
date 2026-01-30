// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'subtitle_track.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$SubtitleTrackImpl _$$SubtitleTrackImplFromJson(Map<String, dynamic> json) =>
    _$SubtitleTrackImpl(
      id: json['id'] as String,
      mediaId: json['mediaId'] as String,
      language: json['language'] as String,
      createdAt:
          const DateTimeConverter().fromJson(json['createdAt'] as String),
      modelId: json['modelId'] as String?,
      segments: (json['segments'] as List<dynamic>)
          .map((e) => SubtitleSegment.fromJson(e as Map<String, dynamic>))
          .toList(),
    );

Map<String, dynamic> _$$SubtitleTrackImplToJson(_$SubtitleTrackImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'mediaId': instance.mediaId,
      'language': instance.language,
      'createdAt': const DateTimeConverter().toJson(instance.createdAt),
      'modelId': instance.modelId,
      'segments': instance.segments,
    };

_$SubtitleSegmentImpl _$$SubtitleSegmentImplFromJson(
        Map<String, dynamic> json) =>
    _$SubtitleSegmentImpl(
      id: json['id'] as String,
      startTime: const DurationConverter()
          .fromJson((json['startTime'] as num).toInt()),
      endTime:
          const DurationConverter().fromJson((json['endTime'] as num).toInt()),
      text: json['text'] as String,
    );

Map<String, dynamic> _$$SubtitleSegmentImplToJson(
        _$SubtitleSegmentImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'startTime': const DurationConverter().toJson(instance.startTime),
      'endTime': const DurationConverter().toJson(instance.endTime),
      'text': instance.text,
    };
