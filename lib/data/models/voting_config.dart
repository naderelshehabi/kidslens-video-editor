import 'package:freezed_annotation/freezed_annotation.dart';

part 'voting_config.freezed.dart';
part 'voting_config.g.dart';

/// Strategy for combining multiple model votes in MoE voting.
@JsonEnum()
enum VotingStrategy {
  /// Weighted average: Σ(score × weight) / Σ(weights).
  @JsonValue('weightedAverage')
  weightedAverage,

  /// Maximum: highest score among all models wins.
  @JsonValue('maximum')
  maximum,

  /// Minimum: lowest score among all models (most conservative).
  @JsonValue('minimum')
  minimum,
}

/// Configuration for Mixture-of-Experts voting across models.
@freezed
class VotingConfig with _$VotingConfig {
  const factory VotingConfig({
    /// The strategy used to combine model votes.
    @Default(VotingStrategy.weightedAverage) VotingStrategy strategy,

    /// Minimum number of models that must return a score for a valid consensus.
    /// If fewer models vote, the category is not triggered.
    @Default(1) int minVoters,

    /// Whether to use each model's accuracy percentage from the registry as
    /// its voting weight (multiplied by [ModelContribution.effectiveWeight]).
    @Default(true) bool useAccuracyWeights,
  }) = _VotingConfig;

  factory VotingConfig.fromJson(Map<String, dynamic> json) =>
      _$VotingConfigFromJson(json);
}
