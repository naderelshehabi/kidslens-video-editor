// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'voting_config.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$VotingConfigImpl _$$VotingConfigImplFromJson(Map<String, dynamic> json) =>
    _$VotingConfigImpl(
      strategy:
          $enumDecodeNullable(_$VotingStrategyEnumMap, json['strategy']) ??
              VotingStrategy.weightedAverage,
      minVoters: (json['minVoters'] as num?)?.toInt() ?? 1,
      useAccuracyWeights: json['useAccuracyWeights'] as bool? ?? true,
    );

Map<String, dynamic> _$$VotingConfigImplToJson(_$VotingConfigImpl instance) =>
    <String, dynamic>{
      'strategy': _$VotingStrategyEnumMap[instance.strategy]!,
      'minVoters': instance.minVoters,
      'useAccuracyWeights': instance.useAccuracyWeights,
    };

const _$VotingStrategyEnumMap = {
  VotingStrategy.weightedAverage: 'weightedAverage',
  VotingStrategy.maximum: 'maximum',
  VotingStrategy.minimum: 'minimum',
};
