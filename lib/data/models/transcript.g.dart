// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'transcript.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$TranscriptWordImpl _$$TranscriptWordImplFromJson(Map<String, dynamic> json) =>
    _$TranscriptWordImpl(
      word: json['word'] as String,
      startTime: const DurationConverter()
          .fromJson((json['startTime'] as num).toInt()),
      endTime:
          const DurationConverter().fromJson((json['endTime'] as num).toInt()),
      confidence: (json['confidence'] as num).toDouble(),
    );

Map<String, dynamic> _$$TranscriptWordImplToJson(
        _$TranscriptWordImpl instance) =>
    <String, dynamic>{
      'word': instance.word,
      'startTime': const DurationConverter().toJson(instance.startTime),
      'endTime': const DurationConverter().toJson(instance.endTime),
      'confidence': instance.confidence,
    };

_$TranscriptSegmentImpl _$$TranscriptSegmentImplFromJson(
        Map<String, dynamic> json) =>
    _$TranscriptSegmentImpl(
      id: json['id'] as String,
      startTime: const DurationConverter()
          .fromJson((json['startTime'] as num).toInt()),
      endTime:
          const DurationConverter().fromJson((json['endTime'] as num).toInt()),
      text: json['text'] as String,
      words: (json['words'] as List<dynamic>)
          .map((e) => TranscriptWord.fromJson(e as Map<String, dynamic>))
          .toList(),
    );

Map<String, dynamic> _$$TranscriptSegmentImplToJson(
        _$TranscriptSegmentImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'startTime': const DurationConverter().toJson(instance.startTime),
      'endTime': const DurationConverter().toJson(instance.endTime),
      'text': instance.text,
      'words': instance.words,
    };

_$TranscriptImpl _$$TranscriptImplFromJson(Map<String, dynamic> json) =>
    _$TranscriptImpl(
      segments: (json['segments'] as List<dynamic>)
          .map((e) => TranscriptSegment.fromJson(e as Map<String, dynamic>))
          .toList(),
      language: json['language'] as String,
      languageDisplayName: json['languageDisplayName'] as String?,
      generatedAt: json['generatedAt'] == null
          ? null
          : DateTime.parse(json['generatedAt'] as String),
      modelId: json['modelId'] as String?,
    );

Map<String, dynamic> _$$TranscriptImplToJson(_$TranscriptImpl instance) =>
    <String, dynamic>{
      'segments': instance.segments,
      'language': instance.language,
      'languageDisplayName': instance.languageDisplayName,
      'generatedAt': instance.generatedAt?.toIso8601String(),
      'modelId': instance.modelId,
    };
