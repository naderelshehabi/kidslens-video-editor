// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'analysis_result.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$AnalysisProgressImpl _$$AnalysisProgressImplFromJson(
        Map<String, dynamic> json) =>
    _$AnalysisProgressImpl(
      stepName: json['stepName'] as String,
      currentStep: (json['currentStep'] as num).toInt(),
      totalSteps: (json['totalSteps'] as num).toInt(),
      stepProgress: (json['stepProgress'] as num).toDouble(),
      estimatedSecondsRemaining:
          (json['estimatedSecondsRemaining'] as num?)?.toInt(),
      itemsProcessed: (json['itemsProcessed'] as num?)?.toInt(),
      totalItems: (json['totalItems'] as num?)?.toInt(),
    );

Map<String, dynamic> _$$AnalysisProgressImplToJson(
        _$AnalysisProgressImpl instance) =>
    <String, dynamic>{
      'stepName': instance.stepName,
      'currentStep': instance.currentStep,
      'totalSteps': instance.totalSteps,
      'stepProgress': instance.stepProgress,
      'estimatedSecondsRemaining': instance.estimatedSecondsRemaining,
      'itemsProcessed': instance.itemsProcessed,
      'totalItems': instance.totalItems,
    };

_$AnalysisResultImpl _$$AnalysisResultImplFromJson(Map<String, dynamic> json) =>
    _$AnalysisResultImpl(
      id: json['id'] as String,
      status: $enumDecodeNullable(_$AnalysisStatusEnumMap, json['status']) ??
          AnalysisStatus.pending,
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
      timeline: json['timeline'] == null
          ? null
          : UnifiedTimeline.fromJson(json['timeline'] as Map<String, dynamic>),
      processingTime: _$JsonConverterFromJson<int, Duration>(
          json['processingTime'], const DurationConverter().fromJson),
      startedAt: json['startedAt'] == null
          ? null
          : DateTime.parse(json['startedAt'] as String),
      completedAt: json['completedAt'] == null
          ? null
          : DateTime.parse(json['completedAt'] as String),
      errorMessage: json['errorMessage'] as String?,
      progress: json['progress'] == null
          ? null
          : AnalysisProgress.fromJson(json['progress'] as Map<String, dynamic>),
      mediaFileId: json['mediaFileId'] as String?,
      settings: json['settings'] as Map<String, dynamic>?,
    );

Map<String, dynamic> _$$AnalysisResultImplToJson(
        _$AnalysisResultImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'status': _$AnalysisStatusEnumMap[instance.status]!,
      'transcript': instance.transcript,
      'profanityMatches': instance.profanityMatches,
      'frameResults': instance.frameResults,
      'timeline': instance.timeline,
      'processingTime': _$JsonConverterToJson<int, Duration>(
          instance.processingTime, const DurationConverter().toJson),
      'startedAt': instance.startedAt?.toIso8601String(),
      'completedAt': instance.completedAt?.toIso8601String(),
      'errorMessage': instance.errorMessage,
      'progress': instance.progress,
      'mediaFileId': instance.mediaFileId,
      'settings': instance.settings,
    };

const _$AnalysisStatusEnumMap = {
  AnalysisStatus.pending: 'pending',
  AnalysisStatus.running: 'running',
  AnalysisStatus.completed: 'completed',
  AnalysisStatus.failed: 'failed',
  AnalysisStatus.cancelled: 'cancelled',
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
