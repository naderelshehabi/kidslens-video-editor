// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'transcription_progress.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$TranscriptionProgressImpl _$$TranscriptionProgressImplFromJson(
        Map<String, dynamic> json) =>
    _$TranscriptionProgressImpl(
      progress: (json['progress'] as num).toDouble(),
      currentSegment: json['currentSegment'] == null
          ? null
          : TranscriptSegment.fromJson(
              json['currentSegment'] as Map<String, dynamic>),
      estimatedTimeRemaining: const NullableDurationConverter()
          .fromJson((json['estimatedTimeRemaining'] as num?)?.toInt()),
      isComplete: json['isComplete'] as bool? ?? false,
      segmentsProcessed: (json['segmentsProcessed'] as num?)?.toInt() ?? 0,
      totalSegments: (json['totalSegments'] as num?)?.toInt(),
      phase: $enumDecodeNullable(_$TranscriptionPhaseEnumMap, json['phase']) ??
          TranscriptionPhase.initializing,
      errorMessage: json['errorMessage'] as String?,
    );

Map<String, dynamic> _$$TranscriptionProgressImplToJson(
        _$TranscriptionProgressImpl instance) =>
    <String, dynamic>{
      'progress': instance.progress,
      'currentSegment': instance.currentSegment,
      'estimatedTimeRemaining': const NullableDurationConverter()
          .toJson(instance.estimatedTimeRemaining),
      'isComplete': instance.isComplete,
      'segmentsProcessed': instance.segmentsProcessed,
      'totalSegments': instance.totalSegments,
      'phase': _$TranscriptionPhaseEnumMap[instance.phase]!,
      'errorMessage': instance.errorMessage,
    };

const _$TranscriptionPhaseEnumMap = {
  TranscriptionPhase.initializing: 'initializing',
  TranscriptionPhase.loadingModel: 'loadingModel',
  TranscriptionPhase.extractingAudio: 'extractingAudio',
  TranscriptionPhase.transcribing: 'transcribing',
  TranscriptionPhase.postProcessing: 'postProcessing',
  TranscriptionPhase.complete: 'complete',
  TranscriptionPhase.failed: 'failed',
};
