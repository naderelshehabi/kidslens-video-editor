// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'voting_config.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

VotingConfig _$VotingConfigFromJson(Map<String, dynamic> json) {
  return _VotingConfig.fromJson(json);
}

/// @nodoc
mixin _$VotingConfig {
  /// The strategy used to combine model votes.
  VotingStrategy get strategy => throw _privateConstructorUsedError;

  /// Minimum number of models that must return a score for a valid consensus.
  /// If fewer models vote, the category is not triggered.
  int get minVoters => throw _privateConstructorUsedError;

  /// Whether to use each model's accuracy percentage from the registry as
  /// its voting weight (multiplied by [ModelContribution.effectiveWeight]).
  bool get useAccuracyWeights => throw _privateConstructorUsedError;

  /// Serializes this VotingConfig to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of VotingConfig
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $VotingConfigCopyWith<VotingConfig> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $VotingConfigCopyWith<$Res> {
  factory $VotingConfigCopyWith(
          VotingConfig value, $Res Function(VotingConfig) then) =
      _$VotingConfigCopyWithImpl<$Res, VotingConfig>;
  @useResult
  $Res call({VotingStrategy strategy, int minVoters, bool useAccuracyWeights});
}

/// @nodoc
class _$VotingConfigCopyWithImpl<$Res, $Val extends VotingConfig>
    implements $VotingConfigCopyWith<$Res> {
  _$VotingConfigCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of VotingConfig
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? strategy = null,
    Object? minVoters = null,
    Object? useAccuracyWeights = null,
  }) {
    return _then(_value.copyWith(
      strategy: null == strategy
          ? _value.strategy
          : strategy // ignore: cast_nullable_to_non_nullable
              as VotingStrategy,
      minVoters: null == minVoters
          ? _value.minVoters
          : minVoters // ignore: cast_nullable_to_non_nullable
              as int,
      useAccuracyWeights: null == useAccuracyWeights
          ? _value.useAccuracyWeights
          : useAccuracyWeights // ignore: cast_nullable_to_non_nullable
              as bool,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$VotingConfigImplCopyWith<$Res>
    implements $VotingConfigCopyWith<$Res> {
  factory _$$VotingConfigImplCopyWith(
          _$VotingConfigImpl value, $Res Function(_$VotingConfigImpl) then) =
      __$$VotingConfigImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({VotingStrategy strategy, int minVoters, bool useAccuracyWeights});
}

/// @nodoc
class __$$VotingConfigImplCopyWithImpl<$Res>
    extends _$VotingConfigCopyWithImpl<$Res, _$VotingConfigImpl>
    implements _$$VotingConfigImplCopyWith<$Res> {
  __$$VotingConfigImplCopyWithImpl(
      _$VotingConfigImpl _value, $Res Function(_$VotingConfigImpl) _then)
      : super(_value, _then);

  /// Create a copy of VotingConfig
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? strategy = null,
    Object? minVoters = null,
    Object? useAccuracyWeights = null,
  }) {
    return _then(_$VotingConfigImpl(
      strategy: null == strategy
          ? _value.strategy
          : strategy // ignore: cast_nullable_to_non_nullable
              as VotingStrategy,
      minVoters: null == minVoters
          ? _value.minVoters
          : minVoters // ignore: cast_nullable_to_non_nullable
              as int,
      useAccuracyWeights: null == useAccuracyWeights
          ? _value.useAccuracyWeights
          : useAccuracyWeights // ignore: cast_nullable_to_non_nullable
              as bool,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$VotingConfigImpl implements _VotingConfig {
  const _$VotingConfigImpl(
      {this.strategy = VotingStrategy.weightedAverage,
      this.minVoters = 1,
      this.useAccuracyWeights = true});

  factory _$VotingConfigImpl.fromJson(Map<String, dynamic> json) =>
      _$$VotingConfigImplFromJson(json);

  /// The strategy used to combine model votes.
  @override
  @JsonKey()
  final VotingStrategy strategy;

  /// Minimum number of models that must return a score for a valid consensus.
  /// If fewer models vote, the category is not triggered.
  @override
  @JsonKey()
  final int minVoters;

  /// Whether to use each model's accuracy percentage from the registry as
  /// its voting weight (multiplied by [ModelContribution.effectiveWeight]).
  @override
  @JsonKey()
  final bool useAccuracyWeights;

  @override
  String toString() {
    return 'VotingConfig(strategy: $strategy, minVoters: $minVoters, useAccuracyWeights: $useAccuracyWeights)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$VotingConfigImpl &&
            (identical(other.strategy, strategy) ||
                other.strategy == strategy) &&
            (identical(other.minVoters, minVoters) ||
                other.minVoters == minVoters) &&
            (identical(other.useAccuracyWeights, useAccuracyWeights) ||
                other.useAccuracyWeights == useAccuracyWeights));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode =>
      Object.hash(runtimeType, strategy, minVoters, useAccuracyWeights);

  /// Create a copy of VotingConfig
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$VotingConfigImplCopyWith<_$VotingConfigImpl> get copyWith =>
      __$$VotingConfigImplCopyWithImpl<_$VotingConfigImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$VotingConfigImplToJson(
      this,
    );
  }
}

abstract class _VotingConfig implements VotingConfig {
  const factory _VotingConfig(
      {final VotingStrategy strategy,
      final int minVoters,
      final bool useAccuracyWeights}) = _$VotingConfigImpl;

  factory _VotingConfig.fromJson(Map<String, dynamic> json) =
      _$VotingConfigImpl.fromJson;

  /// The strategy used to combine model votes.
  @override
  VotingStrategy get strategy;

  /// Minimum number of models that must return a score for a valid consensus.
  /// If fewer models vote, the category is not triggered.
  @override
  int get minVoters;

  /// Whether to use each model's accuracy percentage from the registry as
  /// its voting weight (multiplied by [ModelContribution.effectiveWeight]).
  @override
  bool get useAccuracyWeights;

  /// Create a copy of VotingConfig
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$VotingConfigImplCopyWith<_$VotingConfigImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
