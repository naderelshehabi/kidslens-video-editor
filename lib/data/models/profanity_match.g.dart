// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'profanity_match.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$ProfanityMatchImpl _$$ProfanityMatchImplFromJson(Map<String, dynamic> json) =>
    _$ProfanityMatchImpl(
      id: json['id'] as String,
      word: TranscriptWord.fromJson(json['word'] as Map<String, dynamic>),
      matchedProfanity: json['matchedProfanity'] as String,
      confidence: (json['confidence'] as num).toDouble(),
      type: $enumDecode(_$MatchTypeEnumMap, json['type']),
      severity: (json['severity'] as num?)?.toInt() ?? 3,
      category: json['category'] as String?,
      isReviewed: json['isReviewed'] as bool? ?? false,
      isFalsePositive: json['isFalsePositive'] as bool? ?? false,
      userNote: json['userNote'] as String?,
    );

Map<String, dynamic> _$$ProfanityMatchImplToJson(
        _$ProfanityMatchImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'word': instance.word,
      'matchedProfanity': instance.matchedProfanity,
      'confidence': instance.confidence,
      'type': _$MatchTypeEnumMap[instance.type]!,
      'severity': instance.severity,
      'category': instance.category,
      'isReviewed': instance.isReviewed,
      'isFalsePositive': instance.isFalsePositive,
      'userNote': instance.userNote,
    };

const _$MatchTypeEnumMap = {
  MatchType.exact: 'exact',
  MatchType.leetspeak: 'leetspeak',
  MatchType.phonetic: 'phonetic',
  MatchType.fuzzy: 'fuzzy',
  MatchType.obfuscated: 'obfuscated',
};
