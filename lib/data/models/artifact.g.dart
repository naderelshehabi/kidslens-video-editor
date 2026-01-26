// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'artifact.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$ArtifactMediaInfoImpl _$$ArtifactMediaInfoImplFromJson(
        Map<String, dynamic> json) =>
    _$ArtifactMediaInfoImpl(
      durationMicroseconds: (json['durationMicroseconds'] as num).toInt(),
      fileSize: (json['fileSize'] as num).toInt(),
      width: (json['width'] as num).toInt(),
      height: (json['height'] as num).toInt(),
      codec: json['codec'] as String?,
      container: json['container'] as String?,
    );

Map<String, dynamic> _$$ArtifactMediaInfoImplToJson(
        _$ArtifactMediaInfoImpl instance) =>
    <String, dynamic>{
      'durationMicroseconds': instance.durationMicroseconds,
      'fileSize': instance.fileSize,
      'width': instance.width,
      'height': instance.height,
      'codec': instance.codec,
      'container': instance.container,
    };

_$AnalysisArtifactImpl _$$AnalysisArtifactImplFromJson(
        Map<String, dynamic> json) =>
    _$AnalysisArtifactImpl(
      version: (json['version'] as num?)?.toInt() ?? 1,
      mediaHash: json['mediaHash'] as String,
      mediaInfo:
          ArtifactMediaInfo.fromJson(json['mediaInfo'] as Map<String, dynamic>),
      settingsUsed: AnalysisSettings.fromJson(
          json['settingsUsed'] as Map<String, dynamic>),
      transcript: json['transcript'] == null
          ? null
          : Transcript.fromJson(json['transcript'] as Map<String, dynamic>),
      profanityMatches: (json['profanityMatches'] as List<dynamic>?)
              ?.map((e) => ProfanityMatch.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
      frameResults: (json['frameResults'] as List<dynamic>?)
              ?.map((e) =>
                  FrameAnalysisResult.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
      timeline:
          UnifiedTimeline.fromJson(json['timeline'] as Map<String, dynamic>),
      createdAt: DateTime.parse(json['createdAt'] as String),
      completedAt: json['completedAt'] == null
          ? null
          : DateTime.parse(json['completedAt'] as String),
      status: $enumDecode(_$AnalysisStatusEnumMap, json['status']),
      errorMessage: json['errorMessage'] as String?,
    );

Map<String, dynamic> _$$AnalysisArtifactImplToJson(
        _$AnalysisArtifactImpl instance) =>
    <String, dynamic>{
      'version': instance.version,
      'mediaHash': instance.mediaHash,
      'mediaInfo': instance.mediaInfo,
      'settingsUsed': instance.settingsUsed,
      'transcript': instance.transcript,
      'profanityMatches': instance.profanityMatches,
      'frameResults': instance.frameResults,
      'timeline': instance.timeline,
      'createdAt': instance.createdAt.toIso8601String(),
      'completedAt': instance.completedAt?.toIso8601String(),
      'status': _$AnalysisStatusEnumMap[instance.status]!,
      'errorMessage': instance.errorMessage,
    };

const _$AnalysisStatusEnumMap = {
  AnalysisStatus.pending: 'pending',
  AnalysisStatus.running: 'running',
  AnalysisStatus.completed: 'completed',
  AnalysisStatus.failed: 'failed',
  AnalysisStatus.cancelled: 'cancelled',
};
