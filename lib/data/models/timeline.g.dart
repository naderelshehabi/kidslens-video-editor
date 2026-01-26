// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'timeline.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$TimelineSegmentImpl _$$TimelineSegmentImplFromJson(
        Map<String, dynamic> json) =>
    _$TimelineSegmentImpl(
      id: json['id'] as String,
      start: const DurationConverter().fromJson((json['start'] as num).toInt()),
      end: const DurationConverter().fromJson((json['end'] as num).toInt()),
      type: $enumDecode(_$ContentTypeEnumMap, json['type']),
      confidence: (json['confidence'] as num).toDouble(),
      modification: json['modification'] == null
          ? null
          : Modification.fromJson(json['modification'] as Map<String, dynamic>),
      isSelected: json['isSelected'] as bool? ?? false,
      isLocked: json['isLocked'] as bool? ?? false,
      detectionId: json['detectionId'] as String?,
    );

Map<String, dynamic> _$$TimelineSegmentImplToJson(
        _$TimelineSegmentImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'start': const DurationConverter().toJson(instance.start),
      'end': const DurationConverter().toJson(instance.end),
      'type': _$ContentTypeEnumMap[instance.type]!,
      'confidence': instance.confidence,
      'modification': instance.modification,
      'isSelected': instance.isSelected,
      'isLocked': instance.isLocked,
      'detectionId': instance.detectionId,
    };

const _$ContentTypeEnumMap = {
  ContentType.nsfw: 'nsfw',
  ContentType.violence: 'violence',
  ContentType.blood: 'blood',
  ContentType.profanity: 'profanity',
  ContentType.weapons: 'weapons',
};

_$TimelineTrackImpl _$$TimelineTrackImplFromJson(Map<String, dynamic> json) =>
    _$TimelineTrackImpl(
      id: json['id'] as String,
      type: $enumDecode(_$TrackTypeEnumMap, json['type']),
      name: json['name'] as String,
      segments: (json['segments'] as List<dynamic>)
          .map((e) => TimelineSegment.fromJson(e as Map<String, dynamic>))
          .toList(),
      isVisible: json['isVisible'] as bool? ?? true,
      isMuted: json['isMuted'] as bool? ?? false,
      isLocked: json['isLocked'] as bool? ?? false,
      height: (json['height'] as num?)?.toInt() ?? 40,
      color: json['color'] as String?,
    );

Map<String, dynamic> _$$TimelineTrackImplToJson(_$TimelineTrackImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'type': _$TrackTypeEnumMap[instance.type]!,
      'name': instance.name,
      'segments': instance.segments,
      'isVisible': instance.isVisible,
      'isMuted': instance.isMuted,
      'isLocked': instance.isLocked,
      'height': instance.height,
      'color': instance.color,
    };

const _$TrackTypeEnumMap = {
  TrackType.audio: 'audio',
  TrackType.video: 'video',
  TrackType.detection: 'detection',
  TrackType.custom: 'custom',
};

_$TimelineConflictImpl _$$TimelineConflictImplFromJson(
        Map<String, dynamic> json) =>
    _$TimelineConflictImpl(
      segment1:
          TimelineSegment.fromJson(json['segment1'] as Map<String, dynamic>),
      segment2:
          TimelineSegment.fromJson(json['segment2'] as Map<String, dynamic>),
      conflictType: $enumDecode(_$ConflictTypeEnumMap, json['conflictType']),
      description: json['description'] as String,
    );

Map<String, dynamic> _$$TimelineConflictImplToJson(
        _$TimelineConflictImpl instance) =>
    <String, dynamic>{
      'segment1': instance.segment1,
      'segment2': instance.segment2,
      'conflictType': _$ConflictTypeEnumMap[instance.conflictType]!,
      'description': instance.description,
    };

const _$ConflictTypeEnumMap = {
  ConflictType.overlap: 'overlap',
  ConflictType.multipleModifications: 'multipleModifications',
  ConflictType.incompatibleModifications: 'incompatibleModifications',
};

_$UnifiedTimelineImpl _$$UnifiedTimelineImplFromJson(
        Map<String, dynamic> json) =>
    _$UnifiedTimelineImpl(
      id: json['id'] as String,
      mediaDuration: const DurationConverter()
          .fromJson((json['mediaDuration'] as num).toInt()),
      tracks: (json['tracks'] as List<dynamic>)
          .map((e) => TimelineTrack.fromJson(e as Map<String, dynamic>))
          .toList(),
      createdAt: json['createdAt'] == null
          ? null
          : DateTime.parse(json['createdAt'] as String),
      modifiedAt: json['modifiedAt'] == null
          ? null
          : DateTime.parse(json['modifiedAt'] as String),
    );

Map<String, dynamic> _$$UnifiedTimelineImplToJson(
        _$UnifiedTimelineImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'mediaDuration': const DurationConverter().toJson(instance.mediaDuration),
      'tracks': instance.tracks,
      'createdAt': instance.createdAt?.toIso8601String(),
      'modifiedAt': instance.modifiedAt?.toIso8601String(),
    };
