// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'analysis_settings.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

ModelConfig _$ModelConfigFromJson(Map<String, dynamic> json) {
  return _ModelConfig.fromJson(json);
}

/// @nodoc
mixin _$ModelConfig {
  String get asrModelId => throw _privateConstructorUsedError;
  String get asrLanguage => throw _privateConstructorUsedError;
  bool get useGpu => throw _privateConstructorUsedError;
  int get cpuThreads => throw _privateConstructorUsedError;
  int get batchSize => throw _privateConstructorUsedError;
  bool get useFp16 => throw _privateConstructorUsedError;
  bool get translateToEnglish => throw _privateConstructorUsedError;
  bool get wordLevelTimestamps => throw _privateConstructorUsedError;
  int get beamSize => throw _privateConstructorUsedError;

  /// Serializes this ModelConfig to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of ModelConfig
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $ModelConfigCopyWith<ModelConfig> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $ModelConfigCopyWith<$Res> {
  factory $ModelConfigCopyWith(
          ModelConfig value, $Res Function(ModelConfig) then) =
      _$ModelConfigCopyWithImpl<$Res, ModelConfig>;
  @useResult
  $Res call(
      {String asrModelId,
      String asrLanguage,
      bool useGpu,
      int cpuThreads,
      int batchSize,
      bool useFp16,
      bool translateToEnglish,
      bool wordLevelTimestamps,
      int beamSize});
}

/// @nodoc
class _$ModelConfigCopyWithImpl<$Res, $Val extends ModelConfig>
    implements $ModelConfigCopyWith<$Res> {
  _$ModelConfigCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of ModelConfig
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? asrModelId = null,
    Object? asrLanguage = null,
    Object? useGpu = null,
    Object? cpuThreads = null,
    Object? batchSize = null,
    Object? useFp16 = null,
    Object? translateToEnglish = null,
    Object? wordLevelTimestamps = null,
    Object? beamSize = null,
  }) {
    return _then(_value.copyWith(
      asrModelId: null == asrModelId
          ? _value.asrModelId
          : asrModelId // ignore: cast_nullable_to_non_nullable
              as String,
      asrLanguage: null == asrLanguage
          ? _value.asrLanguage
          : asrLanguage // ignore: cast_nullable_to_non_nullable
              as String,
      useGpu: null == useGpu
          ? _value.useGpu
          : useGpu // ignore: cast_nullable_to_non_nullable
              as bool,
      cpuThreads: null == cpuThreads
          ? _value.cpuThreads
          : cpuThreads // ignore: cast_nullable_to_non_nullable
              as int,
      batchSize: null == batchSize
          ? _value.batchSize
          : batchSize // ignore: cast_nullable_to_non_nullable
              as int,
      useFp16: null == useFp16
          ? _value.useFp16
          : useFp16 // ignore: cast_nullable_to_non_nullable
              as bool,
      translateToEnglish: null == translateToEnglish
          ? _value.translateToEnglish
          : translateToEnglish // ignore: cast_nullable_to_non_nullable
              as bool,
      wordLevelTimestamps: null == wordLevelTimestamps
          ? _value.wordLevelTimestamps
          : wordLevelTimestamps // ignore: cast_nullable_to_non_nullable
              as bool,
      beamSize: null == beamSize
          ? _value.beamSize
          : beamSize // ignore: cast_nullable_to_non_nullable
              as int,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$ModelConfigImplCopyWith<$Res>
    implements $ModelConfigCopyWith<$Res> {
  factory _$$ModelConfigImplCopyWith(
          _$ModelConfigImpl value, $Res Function(_$ModelConfigImpl) then) =
      __$$ModelConfigImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String asrModelId,
      String asrLanguage,
      bool useGpu,
      int cpuThreads,
      int batchSize,
      bool useFp16,
      bool translateToEnglish,
      bool wordLevelTimestamps,
      int beamSize});
}

/// @nodoc
class __$$ModelConfigImplCopyWithImpl<$Res>
    extends _$ModelConfigCopyWithImpl<$Res, _$ModelConfigImpl>
    implements _$$ModelConfigImplCopyWith<$Res> {
  __$$ModelConfigImplCopyWithImpl(
      _$ModelConfigImpl _value, $Res Function(_$ModelConfigImpl) _then)
      : super(_value, _then);

  /// Create a copy of ModelConfig
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? asrModelId = null,
    Object? asrLanguage = null,
    Object? useGpu = null,
    Object? cpuThreads = null,
    Object? batchSize = null,
    Object? useFp16 = null,
    Object? translateToEnglish = null,
    Object? wordLevelTimestamps = null,
    Object? beamSize = null,
  }) {
    return _then(_$ModelConfigImpl(
      asrModelId: null == asrModelId
          ? _value.asrModelId
          : asrModelId // ignore: cast_nullable_to_non_nullable
              as String,
      asrLanguage: null == asrLanguage
          ? _value.asrLanguage
          : asrLanguage // ignore: cast_nullable_to_non_nullable
              as String,
      useGpu: null == useGpu
          ? _value.useGpu
          : useGpu // ignore: cast_nullable_to_non_nullable
              as bool,
      cpuThreads: null == cpuThreads
          ? _value.cpuThreads
          : cpuThreads // ignore: cast_nullable_to_non_nullable
              as int,
      batchSize: null == batchSize
          ? _value.batchSize
          : batchSize // ignore: cast_nullable_to_non_nullable
              as int,
      useFp16: null == useFp16
          ? _value.useFp16
          : useFp16 // ignore: cast_nullable_to_non_nullable
              as bool,
      translateToEnglish: null == translateToEnglish
          ? _value.translateToEnglish
          : translateToEnglish // ignore: cast_nullable_to_non_nullable
              as bool,
      wordLevelTimestamps: null == wordLevelTimestamps
          ? _value.wordLevelTimestamps
          : wordLevelTimestamps // ignore: cast_nullable_to_non_nullable
              as bool,
      beamSize: null == beamSize
          ? _value.beamSize
          : beamSize // ignore: cast_nullable_to_non_nullable
              as int,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$ModelConfigImpl extends _ModelConfig {
  const _$ModelConfigImpl(
      {required this.asrModelId,
      this.asrLanguage = 'en',
      this.useGpu = true,
      this.cpuThreads = 4,
      this.batchSize = 8,
      this.useFp16 = false,
      this.translateToEnglish = false,
      this.wordLevelTimestamps = false,
      this.beamSize = 3})
      : super._();

  factory _$ModelConfigImpl.fromJson(Map<String, dynamic> json) =>
      _$$ModelConfigImplFromJson(json);

  @override
  final String asrModelId;
  @override
  @JsonKey()
  final String asrLanguage;
  @override
  @JsonKey()
  final bool useGpu;
  @override
  @JsonKey()
  final int cpuThreads;
  @override
  @JsonKey()
  final int batchSize;
  @override
  @JsonKey()
  final bool useFp16;
  @override
  @JsonKey()
  final bool translateToEnglish;
  @override
  @JsonKey()
  final bool wordLevelTimestamps;
  @override
  @JsonKey()
  final int beamSize;

  @override
  String toString() {
    return 'ModelConfig(asrModelId: $asrModelId, asrLanguage: $asrLanguage, useGpu: $useGpu, cpuThreads: $cpuThreads, batchSize: $batchSize, useFp16: $useFp16, translateToEnglish: $translateToEnglish, wordLevelTimestamps: $wordLevelTimestamps, beamSize: $beamSize)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$ModelConfigImpl &&
            (identical(other.asrModelId, asrModelId) ||
                other.asrModelId == asrModelId) &&
            (identical(other.asrLanguage, asrLanguage) ||
                other.asrLanguage == asrLanguage) &&
            (identical(other.useGpu, useGpu) || other.useGpu == useGpu) &&
            (identical(other.cpuThreads, cpuThreads) ||
                other.cpuThreads == cpuThreads) &&
            (identical(other.batchSize, batchSize) ||
                other.batchSize == batchSize) &&
            (identical(other.useFp16, useFp16) || other.useFp16 == useFp16) &&
            (identical(other.translateToEnglish, translateToEnglish) ||
                other.translateToEnglish == translateToEnglish) &&
            (identical(other.wordLevelTimestamps, wordLevelTimestamps) ||
                other.wordLevelTimestamps == wordLevelTimestamps) &&
            (identical(other.beamSize, beamSize) ||
                other.beamSize == beamSize));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
      runtimeType,
      asrModelId,
      asrLanguage,
      useGpu,
      cpuThreads,
      batchSize,
      useFp16,
      translateToEnglish,
      wordLevelTimestamps,
      beamSize);

  /// Create a copy of ModelConfig
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$ModelConfigImplCopyWith<_$ModelConfigImpl> get copyWith =>
      __$$ModelConfigImplCopyWithImpl<_$ModelConfigImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$ModelConfigImplToJson(
      this,
    );
  }
}

abstract class _ModelConfig extends ModelConfig {
  const factory _ModelConfig(
      {required final String asrModelId,
      final String asrLanguage,
      final bool useGpu,
      final int cpuThreads,
      final int batchSize,
      final bool useFp16,
      final bool translateToEnglish,
      final bool wordLevelTimestamps,
      final int beamSize}) = _$ModelConfigImpl;
  const _ModelConfig._() : super._();

  factory _ModelConfig.fromJson(Map<String, dynamic> json) =
      _$ModelConfigImpl.fromJson;

  @override
  String get asrModelId;
  @override
  String get asrLanguage;
  @override
  bool get useGpu;
  @override
  int get cpuThreads;
  @override
  int get batchSize;
  @override
  bool get useFp16;
  @override
  bool get translateToEnglish;
  @override
  bool get wordLevelTimestamps;
  @override
  int get beamSize;

  /// Create a copy of ModelConfig
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$ModelConfigImplCopyWith<_$ModelConfigImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

ProfanityConfig _$ProfanityConfigFromJson(Map<String, dynamic> json) {
  return _ProfanityConfig.fromJson(json);
}

/// @nodoc
mixin _$ProfanityConfig {
  List<String> get wordlistIds => throw _privateConstructorUsedError;
  bool get detectLeetspeak => throw _privateConstructorUsedError;
  bool get detectPhonetic => throw _privateConstructorUsedError;
  bool get detectFuzzy => throw _privateConstructorUsedError;
  bool get detectObfuscated => throw _privateConstructorUsedError;
  double get fuzzyThreshold => throw _privateConstructorUsedError;
  List<String> get customWords => throw _privateConstructorUsedError;
  List<String> get excludedWords => throw _privateConstructorUsedError;
  int get minWordLength => throw _privateConstructorUsedError;
  bool get useContextAnalysis => throw _privateConstructorUsedError;

  /// Serializes this ProfanityConfig to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of ProfanityConfig
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $ProfanityConfigCopyWith<ProfanityConfig> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $ProfanityConfigCopyWith<$Res> {
  factory $ProfanityConfigCopyWith(
          ProfanityConfig value, $Res Function(ProfanityConfig) then) =
      _$ProfanityConfigCopyWithImpl<$Res, ProfanityConfig>;
  @useResult
  $Res call(
      {List<String> wordlistIds,
      bool detectLeetspeak,
      bool detectPhonetic,
      bool detectFuzzy,
      bool detectObfuscated,
      double fuzzyThreshold,
      List<String> customWords,
      List<String> excludedWords,
      int minWordLength,
      bool useContextAnalysis});
}

/// @nodoc
class _$ProfanityConfigCopyWithImpl<$Res, $Val extends ProfanityConfig>
    implements $ProfanityConfigCopyWith<$Res> {
  _$ProfanityConfigCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of ProfanityConfig
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? wordlistIds = null,
    Object? detectLeetspeak = null,
    Object? detectPhonetic = null,
    Object? detectFuzzy = null,
    Object? detectObfuscated = null,
    Object? fuzzyThreshold = null,
    Object? customWords = null,
    Object? excludedWords = null,
    Object? minWordLength = null,
    Object? useContextAnalysis = null,
  }) {
    return _then(_value.copyWith(
      wordlistIds: null == wordlistIds
          ? _value.wordlistIds
          : wordlistIds // ignore: cast_nullable_to_non_nullable
              as List<String>,
      detectLeetspeak: null == detectLeetspeak
          ? _value.detectLeetspeak
          : detectLeetspeak // ignore: cast_nullable_to_non_nullable
              as bool,
      detectPhonetic: null == detectPhonetic
          ? _value.detectPhonetic
          : detectPhonetic // ignore: cast_nullable_to_non_nullable
              as bool,
      detectFuzzy: null == detectFuzzy
          ? _value.detectFuzzy
          : detectFuzzy // ignore: cast_nullable_to_non_nullable
              as bool,
      detectObfuscated: null == detectObfuscated
          ? _value.detectObfuscated
          : detectObfuscated // ignore: cast_nullable_to_non_nullable
              as bool,
      fuzzyThreshold: null == fuzzyThreshold
          ? _value.fuzzyThreshold
          : fuzzyThreshold // ignore: cast_nullable_to_non_nullable
              as double,
      customWords: null == customWords
          ? _value.customWords
          : customWords // ignore: cast_nullable_to_non_nullable
              as List<String>,
      excludedWords: null == excludedWords
          ? _value.excludedWords
          : excludedWords // ignore: cast_nullable_to_non_nullable
              as List<String>,
      minWordLength: null == minWordLength
          ? _value.minWordLength
          : minWordLength // ignore: cast_nullable_to_non_nullable
              as int,
      useContextAnalysis: null == useContextAnalysis
          ? _value.useContextAnalysis
          : useContextAnalysis // ignore: cast_nullable_to_non_nullable
              as bool,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$ProfanityConfigImplCopyWith<$Res>
    implements $ProfanityConfigCopyWith<$Res> {
  factory _$$ProfanityConfigImplCopyWith(_$ProfanityConfigImpl value,
          $Res Function(_$ProfanityConfigImpl) then) =
      __$$ProfanityConfigImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {List<String> wordlistIds,
      bool detectLeetspeak,
      bool detectPhonetic,
      bool detectFuzzy,
      bool detectObfuscated,
      double fuzzyThreshold,
      List<String> customWords,
      List<String> excludedWords,
      int minWordLength,
      bool useContextAnalysis});
}

/// @nodoc
class __$$ProfanityConfigImplCopyWithImpl<$Res>
    extends _$ProfanityConfigCopyWithImpl<$Res, _$ProfanityConfigImpl>
    implements _$$ProfanityConfigImplCopyWith<$Res> {
  __$$ProfanityConfigImplCopyWithImpl(
      _$ProfanityConfigImpl _value, $Res Function(_$ProfanityConfigImpl) _then)
      : super(_value, _then);

  /// Create a copy of ProfanityConfig
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? wordlistIds = null,
    Object? detectLeetspeak = null,
    Object? detectPhonetic = null,
    Object? detectFuzzy = null,
    Object? detectObfuscated = null,
    Object? fuzzyThreshold = null,
    Object? customWords = null,
    Object? excludedWords = null,
    Object? minWordLength = null,
    Object? useContextAnalysis = null,
  }) {
    return _then(_$ProfanityConfigImpl(
      wordlistIds: null == wordlistIds
          ? _value._wordlistIds
          : wordlistIds // ignore: cast_nullable_to_non_nullable
              as List<String>,
      detectLeetspeak: null == detectLeetspeak
          ? _value.detectLeetspeak
          : detectLeetspeak // ignore: cast_nullable_to_non_nullable
              as bool,
      detectPhonetic: null == detectPhonetic
          ? _value.detectPhonetic
          : detectPhonetic // ignore: cast_nullable_to_non_nullable
              as bool,
      detectFuzzy: null == detectFuzzy
          ? _value.detectFuzzy
          : detectFuzzy // ignore: cast_nullable_to_non_nullable
              as bool,
      detectObfuscated: null == detectObfuscated
          ? _value.detectObfuscated
          : detectObfuscated // ignore: cast_nullable_to_non_nullable
              as bool,
      fuzzyThreshold: null == fuzzyThreshold
          ? _value.fuzzyThreshold
          : fuzzyThreshold // ignore: cast_nullable_to_non_nullable
              as double,
      customWords: null == customWords
          ? _value._customWords
          : customWords // ignore: cast_nullable_to_non_nullable
              as List<String>,
      excludedWords: null == excludedWords
          ? _value._excludedWords
          : excludedWords // ignore: cast_nullable_to_non_nullable
              as List<String>,
      minWordLength: null == minWordLength
          ? _value.minWordLength
          : minWordLength // ignore: cast_nullable_to_non_nullable
              as int,
      useContextAnalysis: null == useContextAnalysis
          ? _value.useContextAnalysis
          : useContextAnalysis // ignore: cast_nullable_to_non_nullable
              as bool,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$ProfanityConfigImpl extends _ProfanityConfig {
  const _$ProfanityConfigImpl(
      {final List<String> wordlistIds = const ['english-profanity'],
      this.detectLeetspeak = true,
      this.detectPhonetic = true,
      this.detectFuzzy = true,
      this.detectObfuscated = true,
      this.fuzzyThreshold = 0.8,
      final List<String> customWords = const [],
      final List<String> excludedWords = const [],
      this.minWordLength = 2,
      this.useContextAnalysis = true})
      : _wordlistIds = wordlistIds,
        _customWords = customWords,
        _excludedWords = excludedWords,
        super._();

  factory _$ProfanityConfigImpl.fromJson(Map<String, dynamic> json) =>
      _$$ProfanityConfigImplFromJson(json);

  final List<String> _wordlistIds;
  @override
  @JsonKey()
  List<String> get wordlistIds {
    if (_wordlistIds is EqualUnmodifiableListView) return _wordlistIds;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_wordlistIds);
  }

  @override
  @JsonKey()
  final bool detectLeetspeak;
  @override
  @JsonKey()
  final bool detectPhonetic;
  @override
  @JsonKey()
  final bool detectFuzzy;
  @override
  @JsonKey()
  final bool detectObfuscated;
  @override
  @JsonKey()
  final double fuzzyThreshold;
  final List<String> _customWords;
  @override
  @JsonKey()
  List<String> get customWords {
    if (_customWords is EqualUnmodifiableListView) return _customWords;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_customWords);
  }

  final List<String> _excludedWords;
  @override
  @JsonKey()
  List<String> get excludedWords {
    if (_excludedWords is EqualUnmodifiableListView) return _excludedWords;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_excludedWords);
  }

  @override
  @JsonKey()
  final int minWordLength;
  @override
  @JsonKey()
  final bool useContextAnalysis;

  @override
  String toString() {
    return 'ProfanityConfig(wordlistIds: $wordlistIds, detectLeetspeak: $detectLeetspeak, detectPhonetic: $detectPhonetic, detectFuzzy: $detectFuzzy, detectObfuscated: $detectObfuscated, fuzzyThreshold: $fuzzyThreshold, customWords: $customWords, excludedWords: $excludedWords, minWordLength: $minWordLength, useContextAnalysis: $useContextAnalysis)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$ProfanityConfigImpl &&
            const DeepCollectionEquality()
                .equals(other._wordlistIds, _wordlistIds) &&
            (identical(other.detectLeetspeak, detectLeetspeak) ||
                other.detectLeetspeak == detectLeetspeak) &&
            (identical(other.detectPhonetic, detectPhonetic) ||
                other.detectPhonetic == detectPhonetic) &&
            (identical(other.detectFuzzy, detectFuzzy) ||
                other.detectFuzzy == detectFuzzy) &&
            (identical(other.detectObfuscated, detectObfuscated) ||
                other.detectObfuscated == detectObfuscated) &&
            (identical(other.fuzzyThreshold, fuzzyThreshold) ||
                other.fuzzyThreshold == fuzzyThreshold) &&
            const DeepCollectionEquality()
                .equals(other._customWords, _customWords) &&
            const DeepCollectionEquality()
                .equals(other._excludedWords, _excludedWords) &&
            (identical(other.minWordLength, minWordLength) ||
                other.minWordLength == minWordLength) &&
            (identical(other.useContextAnalysis, useContextAnalysis) ||
                other.useContextAnalysis == useContextAnalysis));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
      runtimeType,
      const DeepCollectionEquality().hash(_wordlistIds),
      detectLeetspeak,
      detectPhonetic,
      detectFuzzy,
      detectObfuscated,
      fuzzyThreshold,
      const DeepCollectionEquality().hash(_customWords),
      const DeepCollectionEquality().hash(_excludedWords),
      minWordLength,
      useContextAnalysis);

  /// Create a copy of ProfanityConfig
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$ProfanityConfigImplCopyWith<_$ProfanityConfigImpl> get copyWith =>
      __$$ProfanityConfigImplCopyWithImpl<_$ProfanityConfigImpl>(
          this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$ProfanityConfigImplToJson(
      this,
    );
  }
}

abstract class _ProfanityConfig extends ProfanityConfig {
  const factory _ProfanityConfig(
      {final List<String> wordlistIds,
      final bool detectLeetspeak,
      final bool detectPhonetic,
      final bool detectFuzzy,
      final bool detectObfuscated,
      final double fuzzyThreshold,
      final List<String> customWords,
      final List<String> excludedWords,
      final int minWordLength,
      final bool useContextAnalysis}) = _$ProfanityConfigImpl;
  const _ProfanityConfig._() : super._();

  factory _ProfanityConfig.fromJson(Map<String, dynamic> json) =
      _$ProfanityConfigImpl.fromJson;

  @override
  List<String> get wordlistIds;
  @override
  bool get detectLeetspeak;
  @override
  bool get detectPhonetic;
  @override
  bool get detectFuzzy;
  @override
  bool get detectObfuscated;
  @override
  double get fuzzyThreshold;
  @override
  List<String> get customWords;
  @override
  List<String> get excludedWords;
  @override
  int get minWordLength;
  @override
  bool get useContextAnalysis;

  /// Create a copy of ProfanityConfig
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$ProfanityConfigImplCopyWith<_$ProfanityConfigImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

ContentDetectionConfig _$ContentDetectionConfigFromJson(
    Map<String, dynamic> json) {
  return _ContentDetectionConfig.fromJson(json);
}

/// @nodoc
mixin _$ContentDetectionConfig {
  List<ContentCategory> get categories => throw _privateConstructorUsedError;
  VotingConfig get votingConfig => throw _privateConstructorUsedError;
  int get schemaVersion => throw _privateConstructorUsedError;

  /// Serializes this ContentDetectionConfig to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of ContentDetectionConfig
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $ContentDetectionConfigCopyWith<ContentDetectionConfig> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $ContentDetectionConfigCopyWith<$Res> {
  factory $ContentDetectionConfigCopyWith(ContentDetectionConfig value,
          $Res Function(ContentDetectionConfig) then) =
      _$ContentDetectionConfigCopyWithImpl<$Res, ContentDetectionConfig>;
  @useResult
  $Res call(
      {List<ContentCategory> categories,
      VotingConfig votingConfig,
      int schemaVersion});

  $VotingConfigCopyWith<$Res> get votingConfig;
}

/// @nodoc
class _$ContentDetectionConfigCopyWithImpl<$Res,
        $Val extends ContentDetectionConfig>
    implements $ContentDetectionConfigCopyWith<$Res> {
  _$ContentDetectionConfigCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of ContentDetectionConfig
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? categories = null,
    Object? votingConfig = null,
    Object? schemaVersion = null,
  }) {
    return _then(_value.copyWith(
      categories: null == categories
          ? _value.categories
          : categories // ignore: cast_nullable_to_non_nullable
              as List<ContentCategory>,
      votingConfig: null == votingConfig
          ? _value.votingConfig
          : votingConfig // ignore: cast_nullable_to_non_nullable
              as VotingConfig,
      schemaVersion: null == schemaVersion
          ? _value.schemaVersion
          : schemaVersion // ignore: cast_nullable_to_non_nullable
              as int,
    ) as $Val);
  }

  /// Create a copy of ContentDetectionConfig
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $VotingConfigCopyWith<$Res> get votingConfig {
    return $VotingConfigCopyWith<$Res>(_value.votingConfig, (value) {
      return _then(_value.copyWith(votingConfig: value) as $Val);
    });
  }
}

/// @nodoc
abstract class _$$ContentDetectionConfigImplCopyWith<$Res>
    implements $ContentDetectionConfigCopyWith<$Res> {
  factory _$$ContentDetectionConfigImplCopyWith(
          _$ContentDetectionConfigImpl value,
          $Res Function(_$ContentDetectionConfigImpl) then) =
      __$$ContentDetectionConfigImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {List<ContentCategory> categories,
      VotingConfig votingConfig,
      int schemaVersion});

  @override
  $VotingConfigCopyWith<$Res> get votingConfig;
}

/// @nodoc
class __$$ContentDetectionConfigImplCopyWithImpl<$Res>
    extends _$ContentDetectionConfigCopyWithImpl<$Res,
        _$ContentDetectionConfigImpl>
    implements _$$ContentDetectionConfigImplCopyWith<$Res> {
  __$$ContentDetectionConfigImplCopyWithImpl(
      _$ContentDetectionConfigImpl _value,
      $Res Function(_$ContentDetectionConfigImpl) _then)
      : super(_value, _then);

  /// Create a copy of ContentDetectionConfig
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? categories = null,
    Object? votingConfig = null,
    Object? schemaVersion = null,
  }) {
    return _then(_$ContentDetectionConfigImpl(
      categories: null == categories
          ? _value._categories
          : categories // ignore: cast_nullable_to_non_nullable
              as List<ContentCategory>,
      votingConfig: null == votingConfig
          ? _value.votingConfig
          : votingConfig // ignore: cast_nullable_to_non_nullable
              as VotingConfig,
      schemaVersion: null == schemaVersion
          ? _value.schemaVersion
          : schemaVersion // ignore: cast_nullable_to_non_nullable
              as int,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$ContentDetectionConfigImpl extends _ContentDetectionConfig {
  const _$ContentDetectionConfigImpl(
      {final List<ContentCategory> categories = const [],
      this.votingConfig = const VotingConfig(),
      this.schemaVersion = 2})
      : _categories = categories,
        super._();

  factory _$ContentDetectionConfigImpl.fromJson(Map<String, dynamic> json) =>
      _$$ContentDetectionConfigImplFromJson(json);

  final List<ContentCategory> _categories;
  @override
  @JsonKey()
  List<ContentCategory> get categories {
    if (_categories is EqualUnmodifiableListView) return _categories;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_categories);
  }

  @override
  @JsonKey()
  final VotingConfig votingConfig;
  @override
  @JsonKey()
  final int schemaVersion;

  @override
  String toString() {
    return 'ContentDetectionConfig(categories: $categories, votingConfig: $votingConfig, schemaVersion: $schemaVersion)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$ContentDetectionConfigImpl &&
            const DeepCollectionEquality()
                .equals(other._categories, _categories) &&
            (identical(other.votingConfig, votingConfig) ||
                other.votingConfig == votingConfig) &&
            (identical(other.schemaVersion, schemaVersion) ||
                other.schemaVersion == schemaVersion));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
      runtimeType,
      const DeepCollectionEquality().hash(_categories),
      votingConfig,
      schemaVersion);

  /// Create a copy of ContentDetectionConfig
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$ContentDetectionConfigImplCopyWith<_$ContentDetectionConfigImpl>
      get copyWith => __$$ContentDetectionConfigImplCopyWithImpl<
          _$ContentDetectionConfigImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$ContentDetectionConfigImplToJson(
      this,
    );
  }
}

abstract class _ContentDetectionConfig extends ContentDetectionConfig {
  const factory _ContentDetectionConfig(
      {final List<ContentCategory> categories,
      final VotingConfig votingConfig,
      final int schemaVersion}) = _$ContentDetectionConfigImpl;
  const _ContentDetectionConfig._() : super._();

  factory _ContentDetectionConfig.fromJson(Map<String, dynamic> json) =
      _$ContentDetectionConfigImpl.fromJson;

  @override
  List<ContentCategory> get categories;
  @override
  VotingConfig get votingConfig;
  @override
  int get schemaVersion;

  /// Create a copy of ContentDetectionConfig
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$ContentDetectionConfigImplCopyWith<_$ContentDetectionConfigImpl>
      get copyWith => throw _privateConstructorUsedError;
}

AnalysisSettings _$AnalysisSettingsFromJson(Map<String, dynamic> json) {
  return _AnalysisSettings.fromJson(json);
}

/// @nodoc
mixin _$AnalysisSettings {
  ModelConfig get modelConfig => throw _privateConstructorUsedError;
  ProfanityConfig get profanityConfig => throw _privateConstructorUsedError;
  bool get enableProfanity => throw _privateConstructorUsedError;
  int get frameSamplingRate => throw _privateConstructorUsedError;
  bool get useSceneDetection => throw _privateConstructorUsedError;
  int get minSegmentDurationMs => throw _privateConstructorUsedError;
  bool get mergeAdjacentDetections => throw _privateConstructorUsedError;
  int get detectionBufferMs => throw _privateConstructorUsedError;
  int get maxConcurrentAnalyses => throw _privateConstructorUsedError;
  ContentDetectionConfig get contentDetectionConfig =>
      throw _privateConstructorUsedError;

  /// Serializes this AnalysisSettings to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of AnalysisSettings
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $AnalysisSettingsCopyWith<AnalysisSettings> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $AnalysisSettingsCopyWith<$Res> {
  factory $AnalysisSettingsCopyWith(
          AnalysisSettings value, $Res Function(AnalysisSettings) then) =
      _$AnalysisSettingsCopyWithImpl<$Res, AnalysisSettings>;
  @useResult
  $Res call(
      {ModelConfig modelConfig,
      ProfanityConfig profanityConfig,
      bool enableProfanity,
      int frameSamplingRate,
      bool useSceneDetection,
      int minSegmentDurationMs,
      bool mergeAdjacentDetections,
      int detectionBufferMs,
      int maxConcurrentAnalyses,
      ContentDetectionConfig contentDetectionConfig});

  $ModelConfigCopyWith<$Res> get modelConfig;
  $ProfanityConfigCopyWith<$Res> get profanityConfig;
  $ContentDetectionConfigCopyWith<$Res> get contentDetectionConfig;
}

/// @nodoc
class _$AnalysisSettingsCopyWithImpl<$Res, $Val extends AnalysisSettings>
    implements $AnalysisSettingsCopyWith<$Res> {
  _$AnalysisSettingsCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of AnalysisSettings
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? modelConfig = null,
    Object? profanityConfig = null,
    Object? enableProfanity = null,
    Object? frameSamplingRate = null,
    Object? useSceneDetection = null,
    Object? minSegmentDurationMs = null,
    Object? mergeAdjacentDetections = null,
    Object? detectionBufferMs = null,
    Object? maxConcurrentAnalyses = null,
    Object? contentDetectionConfig = null,
  }) {
    return _then(_value.copyWith(
      modelConfig: null == modelConfig
          ? _value.modelConfig
          : modelConfig // ignore: cast_nullable_to_non_nullable
              as ModelConfig,
      profanityConfig: null == profanityConfig
          ? _value.profanityConfig
          : profanityConfig // ignore: cast_nullable_to_non_nullable
              as ProfanityConfig,
      enableProfanity: null == enableProfanity
          ? _value.enableProfanity
          : enableProfanity // ignore: cast_nullable_to_non_nullable
              as bool,
      frameSamplingRate: null == frameSamplingRate
          ? _value.frameSamplingRate
          : frameSamplingRate // ignore: cast_nullable_to_non_nullable
              as int,
      useSceneDetection: null == useSceneDetection
          ? _value.useSceneDetection
          : useSceneDetection // ignore: cast_nullable_to_non_nullable
              as bool,
      minSegmentDurationMs: null == minSegmentDurationMs
          ? _value.minSegmentDurationMs
          : minSegmentDurationMs // ignore: cast_nullable_to_non_nullable
              as int,
      mergeAdjacentDetections: null == mergeAdjacentDetections
          ? _value.mergeAdjacentDetections
          : mergeAdjacentDetections // ignore: cast_nullable_to_non_nullable
              as bool,
      detectionBufferMs: null == detectionBufferMs
          ? _value.detectionBufferMs
          : detectionBufferMs // ignore: cast_nullable_to_non_nullable
              as int,
      maxConcurrentAnalyses: null == maxConcurrentAnalyses
          ? _value.maxConcurrentAnalyses
          : maxConcurrentAnalyses // ignore: cast_nullable_to_non_nullable
              as int,
      contentDetectionConfig: null == contentDetectionConfig
          ? _value.contentDetectionConfig
          : contentDetectionConfig // ignore: cast_nullable_to_non_nullable
              as ContentDetectionConfig,
    ) as $Val);
  }

  /// Create a copy of AnalysisSettings
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $ModelConfigCopyWith<$Res> get modelConfig {
    return $ModelConfigCopyWith<$Res>(_value.modelConfig, (value) {
      return _then(_value.copyWith(modelConfig: value) as $Val);
    });
  }

  /// Create a copy of AnalysisSettings
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $ProfanityConfigCopyWith<$Res> get profanityConfig {
    return $ProfanityConfigCopyWith<$Res>(_value.profanityConfig, (value) {
      return _then(_value.copyWith(profanityConfig: value) as $Val);
    });
  }

  /// Create a copy of AnalysisSettings
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $ContentDetectionConfigCopyWith<$Res> get contentDetectionConfig {
    return $ContentDetectionConfigCopyWith<$Res>(_value.contentDetectionConfig,
        (value) {
      return _then(_value.copyWith(contentDetectionConfig: value) as $Val);
    });
  }
}

/// @nodoc
abstract class _$$AnalysisSettingsImplCopyWith<$Res>
    implements $AnalysisSettingsCopyWith<$Res> {
  factory _$$AnalysisSettingsImplCopyWith(_$AnalysisSettingsImpl value,
          $Res Function(_$AnalysisSettingsImpl) then) =
      __$$AnalysisSettingsImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {ModelConfig modelConfig,
      ProfanityConfig profanityConfig,
      bool enableProfanity,
      int frameSamplingRate,
      bool useSceneDetection,
      int minSegmentDurationMs,
      bool mergeAdjacentDetections,
      int detectionBufferMs,
      int maxConcurrentAnalyses,
      ContentDetectionConfig contentDetectionConfig});

  @override
  $ModelConfigCopyWith<$Res> get modelConfig;
  @override
  $ProfanityConfigCopyWith<$Res> get profanityConfig;
  @override
  $ContentDetectionConfigCopyWith<$Res> get contentDetectionConfig;
}

/// @nodoc
class __$$AnalysisSettingsImplCopyWithImpl<$Res>
    extends _$AnalysisSettingsCopyWithImpl<$Res, _$AnalysisSettingsImpl>
    implements _$$AnalysisSettingsImplCopyWith<$Res> {
  __$$AnalysisSettingsImplCopyWithImpl(_$AnalysisSettingsImpl _value,
      $Res Function(_$AnalysisSettingsImpl) _then)
      : super(_value, _then);

  /// Create a copy of AnalysisSettings
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? modelConfig = null,
    Object? profanityConfig = null,
    Object? enableProfanity = null,
    Object? frameSamplingRate = null,
    Object? useSceneDetection = null,
    Object? minSegmentDurationMs = null,
    Object? mergeAdjacentDetections = null,
    Object? detectionBufferMs = null,
    Object? maxConcurrentAnalyses = null,
    Object? contentDetectionConfig = null,
  }) {
    return _then(_$AnalysisSettingsImpl(
      modelConfig: null == modelConfig
          ? _value.modelConfig
          : modelConfig // ignore: cast_nullable_to_non_nullable
              as ModelConfig,
      profanityConfig: null == profanityConfig
          ? _value.profanityConfig
          : profanityConfig // ignore: cast_nullable_to_non_nullable
              as ProfanityConfig,
      enableProfanity: null == enableProfanity
          ? _value.enableProfanity
          : enableProfanity // ignore: cast_nullable_to_non_nullable
              as bool,
      frameSamplingRate: null == frameSamplingRate
          ? _value.frameSamplingRate
          : frameSamplingRate // ignore: cast_nullable_to_non_nullable
              as int,
      useSceneDetection: null == useSceneDetection
          ? _value.useSceneDetection
          : useSceneDetection // ignore: cast_nullable_to_non_nullable
              as bool,
      minSegmentDurationMs: null == minSegmentDurationMs
          ? _value.minSegmentDurationMs
          : minSegmentDurationMs // ignore: cast_nullable_to_non_nullable
              as int,
      mergeAdjacentDetections: null == mergeAdjacentDetections
          ? _value.mergeAdjacentDetections
          : mergeAdjacentDetections // ignore: cast_nullable_to_non_nullable
              as bool,
      detectionBufferMs: null == detectionBufferMs
          ? _value.detectionBufferMs
          : detectionBufferMs // ignore: cast_nullable_to_non_nullable
              as int,
      maxConcurrentAnalyses: null == maxConcurrentAnalyses
          ? _value.maxConcurrentAnalyses
          : maxConcurrentAnalyses // ignore: cast_nullable_to_non_nullable
              as int,
      contentDetectionConfig: null == contentDetectionConfig
          ? _value.contentDetectionConfig
          : contentDetectionConfig // ignore: cast_nullable_to_non_nullable
              as ContentDetectionConfig,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$AnalysisSettingsImpl extends _AnalysisSettings {
  const _$AnalysisSettingsImpl(
      {required this.modelConfig,
      required this.profanityConfig,
      this.enableProfanity = true,
      this.frameSamplingRate = 5,
      this.useSceneDetection = true,
      this.minSegmentDurationMs = 500,
      this.mergeAdjacentDetections = true,
      this.detectionBufferMs = 100,
      this.maxConcurrentAnalyses = 4,
      this.contentDetectionConfig = const ContentDetectionConfig()})
      : super._();

  factory _$AnalysisSettingsImpl.fromJson(Map<String, dynamic> json) =>
      _$$AnalysisSettingsImplFromJson(json);

  @override
  final ModelConfig modelConfig;
  @override
  final ProfanityConfig profanityConfig;
  @override
  @JsonKey()
  final bool enableProfanity;
  @override
  @JsonKey()
  final int frameSamplingRate;
  @override
  @JsonKey()
  final bool useSceneDetection;
  @override
  @JsonKey()
  final int minSegmentDurationMs;
  @override
  @JsonKey()
  final bool mergeAdjacentDetections;
  @override
  @JsonKey()
  final int detectionBufferMs;
  @override
  @JsonKey()
  final int maxConcurrentAnalyses;
  @override
  @JsonKey()
  final ContentDetectionConfig contentDetectionConfig;

  @override
  String toString() {
    return 'AnalysisSettings(modelConfig: $modelConfig, profanityConfig: $profanityConfig, enableProfanity: $enableProfanity, frameSamplingRate: $frameSamplingRate, useSceneDetection: $useSceneDetection, minSegmentDurationMs: $minSegmentDurationMs, mergeAdjacentDetections: $mergeAdjacentDetections, detectionBufferMs: $detectionBufferMs, maxConcurrentAnalyses: $maxConcurrentAnalyses, contentDetectionConfig: $contentDetectionConfig)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$AnalysisSettingsImpl &&
            (identical(other.modelConfig, modelConfig) ||
                other.modelConfig == modelConfig) &&
            (identical(other.profanityConfig, profanityConfig) ||
                other.profanityConfig == profanityConfig) &&
            (identical(other.enableProfanity, enableProfanity) ||
                other.enableProfanity == enableProfanity) &&
            (identical(other.frameSamplingRate, frameSamplingRate) ||
                other.frameSamplingRate == frameSamplingRate) &&
            (identical(other.useSceneDetection, useSceneDetection) ||
                other.useSceneDetection == useSceneDetection) &&
            (identical(other.minSegmentDurationMs, minSegmentDurationMs) ||
                other.minSegmentDurationMs == minSegmentDurationMs) &&
            (identical(
                    other.mergeAdjacentDetections, mergeAdjacentDetections) ||
                other.mergeAdjacentDetections == mergeAdjacentDetections) &&
            (identical(other.detectionBufferMs, detectionBufferMs) ||
                other.detectionBufferMs == detectionBufferMs) &&
            (identical(other.maxConcurrentAnalyses, maxConcurrentAnalyses) ||
                other.maxConcurrentAnalyses == maxConcurrentAnalyses) &&
            (identical(other.contentDetectionConfig, contentDetectionConfig) ||
                other.contentDetectionConfig == contentDetectionConfig));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
      runtimeType,
      modelConfig,
      profanityConfig,
      enableProfanity,
      frameSamplingRate,
      useSceneDetection,
      minSegmentDurationMs,
      mergeAdjacentDetections,
      detectionBufferMs,
      maxConcurrentAnalyses,
      contentDetectionConfig);

  /// Create a copy of AnalysisSettings
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$AnalysisSettingsImplCopyWith<_$AnalysisSettingsImpl> get copyWith =>
      __$$AnalysisSettingsImplCopyWithImpl<_$AnalysisSettingsImpl>(
          this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$AnalysisSettingsImplToJson(
      this,
    );
  }
}

abstract class _AnalysisSettings extends AnalysisSettings {
  const factory _AnalysisSettings(
          {required final ModelConfig modelConfig,
          required final ProfanityConfig profanityConfig,
          final bool enableProfanity,
          final int frameSamplingRate,
          final bool useSceneDetection,
          final int minSegmentDurationMs,
          final bool mergeAdjacentDetections,
          final int detectionBufferMs,
          final int maxConcurrentAnalyses,
          final ContentDetectionConfig contentDetectionConfig}) =
      _$AnalysisSettingsImpl;
  const _AnalysisSettings._() : super._();

  factory _AnalysisSettings.fromJson(Map<String, dynamic> json) =
      _$AnalysisSettingsImpl.fromJson;

  @override
  ModelConfig get modelConfig;
  @override
  ProfanityConfig get profanityConfig;
  @override
  bool get enableProfanity;
  @override
  int get frameSamplingRate;
  @override
  bool get useSceneDetection;
  @override
  int get minSegmentDurationMs;
  @override
  bool get mergeAdjacentDetections;
  @override
  int get detectionBufferMs;
  @override
  int get maxConcurrentAnalyses;
  @override
  ContentDetectionConfig get contentDetectionConfig;

  /// Create a copy of AnalysisSettings
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$AnalysisSettingsImplCopyWith<_$AnalysisSettingsImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
