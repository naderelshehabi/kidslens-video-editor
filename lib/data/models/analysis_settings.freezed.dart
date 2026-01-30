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
  /// ID of the ASR model to use for transcription
  String get asrModelId => throw _privateConstructorUsedError;

  /// ID of the visual model to use for frame analysis (legacy, use per-type IDs)
  String get visualModelId => throw _privateConstructorUsedError;

  /// ID of the NSFW detection model
  String get nsfwModelId => throw _privateConstructorUsedError;

  /// ID of the violence detection model
  String get violenceModelId => throw _privateConstructorUsedError;

  /// ID of the blood/gore detection model
  String get bloodModelId => throw _privateConstructorUsedError;

  /// ID of the weapons detection model
  String get weaponsModelId => throw _privateConstructorUsedError;

  /// Language for ASR (e.g., 'en', 'es', 'auto')
  String get asrLanguage => throw _privateConstructorUsedError;

  /// Whether to use GPU acceleration
  bool get useGpu => throw _privateConstructorUsedError;

  /// Number of threads for CPU inference
  int get cpuThreads => throw _privateConstructorUsedError;

  /// Batch size for visual model inference
  int get batchSize => throw _privateConstructorUsedError;

  /// Whether to use half-precision (FP16) for faster inference
  bool get useFp16 => throw _privateConstructorUsedError;

  /// Whether to translate non-English speech to English
  bool get translateToEnglish => throw _privateConstructorUsedError;

  /// Whether to generate word-level timestamps (slower but more precise)
  bool get wordLevelTimestamps => throw _privateConstructorUsedError;

  /// Beam search size for ASR decoding (1-5, higher = more accurate but slower)
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
      String visualModelId,
      String nsfwModelId,
      String violenceModelId,
      String bloodModelId,
      String weaponsModelId,
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
    Object? visualModelId = null,
    Object? nsfwModelId = null,
    Object? violenceModelId = null,
    Object? bloodModelId = null,
    Object? weaponsModelId = null,
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
      visualModelId: null == visualModelId
          ? _value.visualModelId
          : visualModelId // ignore: cast_nullable_to_non_nullable
              as String,
      nsfwModelId: null == nsfwModelId
          ? _value.nsfwModelId
          : nsfwModelId // ignore: cast_nullable_to_non_nullable
              as String,
      violenceModelId: null == violenceModelId
          ? _value.violenceModelId
          : violenceModelId // ignore: cast_nullable_to_non_nullable
              as String,
      bloodModelId: null == bloodModelId
          ? _value.bloodModelId
          : bloodModelId // ignore: cast_nullable_to_non_nullable
              as String,
      weaponsModelId: null == weaponsModelId
          ? _value.weaponsModelId
          : weaponsModelId // ignore: cast_nullable_to_non_nullable
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
      String visualModelId,
      String nsfwModelId,
      String violenceModelId,
      String bloodModelId,
      String weaponsModelId,
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
    Object? visualModelId = null,
    Object? nsfwModelId = null,
    Object? violenceModelId = null,
    Object? bloodModelId = null,
    Object? weaponsModelId = null,
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
      visualModelId: null == visualModelId
          ? _value.visualModelId
          : visualModelId // ignore: cast_nullable_to_non_nullable
              as String,
      nsfwModelId: null == nsfwModelId
          ? _value.nsfwModelId
          : nsfwModelId // ignore: cast_nullable_to_non_nullable
              as String,
      violenceModelId: null == violenceModelId
          ? _value.violenceModelId
          : violenceModelId // ignore: cast_nullable_to_non_nullable
              as String,
      bloodModelId: null == bloodModelId
          ? _value.bloodModelId
          : bloodModelId // ignore: cast_nullable_to_non_nullable
              as String,
      weaponsModelId: null == weaponsModelId
          ? _value.weaponsModelId
          : weaponsModelId // ignore: cast_nullable_to_non_nullable
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
      required this.visualModelId,
      this.nsfwModelId = 'nsfw-mobilenet-v2',
      this.violenceModelId = 'violence-mobilenet',
      this.bloodModelId = 'gore-efficientnet-b2',
      this.weaponsModelId = 'weapons-yolov8-small',
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

  /// ID of the ASR model to use for transcription
  @override
  final String asrModelId;

  /// ID of the visual model to use for frame analysis (legacy, use per-type IDs)
  @override
  final String visualModelId;

  /// ID of the NSFW detection model
  @override
  @JsonKey()
  final String nsfwModelId;

  /// ID of the violence detection model
  @override
  @JsonKey()
  final String violenceModelId;

  /// ID of the blood/gore detection model
  @override
  @JsonKey()
  final String bloodModelId;

  /// ID of the weapons detection model
  @override
  @JsonKey()
  final String weaponsModelId;

  /// Language for ASR (e.g., 'en', 'es', 'auto')
  @override
  @JsonKey()
  final String asrLanguage;

  /// Whether to use GPU acceleration
  @override
  @JsonKey()
  final bool useGpu;

  /// Number of threads for CPU inference
  @override
  @JsonKey()
  final int cpuThreads;

  /// Batch size for visual model inference
  @override
  @JsonKey()
  final int batchSize;

  /// Whether to use half-precision (FP16) for faster inference
  @override
  @JsonKey()
  final bool useFp16;

  /// Whether to translate non-English speech to English
  @override
  @JsonKey()
  final bool translateToEnglish;

  /// Whether to generate word-level timestamps (slower but more precise)
  @override
  @JsonKey()
  final bool wordLevelTimestamps;

  /// Beam search size for ASR decoding (1-5, higher = more accurate but slower)
  @override
  @JsonKey()
  final int beamSize;

  @override
  String toString() {
    return 'ModelConfig(asrModelId: $asrModelId, visualModelId: $visualModelId, nsfwModelId: $nsfwModelId, violenceModelId: $violenceModelId, bloodModelId: $bloodModelId, weaponsModelId: $weaponsModelId, asrLanguage: $asrLanguage, useGpu: $useGpu, cpuThreads: $cpuThreads, batchSize: $batchSize, useFp16: $useFp16, translateToEnglish: $translateToEnglish, wordLevelTimestamps: $wordLevelTimestamps, beamSize: $beamSize)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$ModelConfigImpl &&
            (identical(other.asrModelId, asrModelId) ||
                other.asrModelId == asrModelId) &&
            (identical(other.visualModelId, visualModelId) ||
                other.visualModelId == visualModelId) &&
            (identical(other.nsfwModelId, nsfwModelId) ||
                other.nsfwModelId == nsfwModelId) &&
            (identical(other.violenceModelId, violenceModelId) ||
                other.violenceModelId == violenceModelId) &&
            (identical(other.bloodModelId, bloodModelId) ||
                other.bloodModelId == bloodModelId) &&
            (identical(other.weaponsModelId, weaponsModelId) ||
                other.weaponsModelId == weaponsModelId) &&
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
      visualModelId,
      nsfwModelId,
      violenceModelId,
      bloodModelId,
      weaponsModelId,
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
      required final String visualModelId,
      final String nsfwModelId,
      final String violenceModelId,
      final String bloodModelId,
      final String weaponsModelId,
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

  /// ID of the ASR model to use for transcription
  @override
  String get asrModelId;

  /// ID of the visual model to use for frame analysis (legacy, use per-type IDs)
  @override
  String get visualModelId;

  /// ID of the NSFW detection model
  @override
  String get nsfwModelId;

  /// ID of the violence detection model
  @override
  String get violenceModelId;

  /// ID of the blood/gore detection model
  @override
  String get bloodModelId;

  /// ID of the weapons detection model
  @override
  String get weaponsModelId;

  /// Language for ASR (e.g., 'en', 'es', 'auto')
  @override
  String get asrLanguage;

  /// Whether to use GPU acceleration
  @override
  bool get useGpu;

  /// Number of threads for CPU inference
  @override
  int get cpuThreads;

  /// Batch size for visual model inference
  @override
  int get batchSize;

  /// Whether to use half-precision (FP16) for faster inference
  @override
  bool get useFp16;

  /// Whether to translate non-English speech to English
  @override
  bool get translateToEnglish;

  /// Whether to generate word-level timestamps (slower but more precise)
  @override
  bool get wordLevelTimestamps;

  /// Beam search size for ASR decoding (1-5, higher = more accurate but slower)
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
  /// Wordlist IDs to use for detection
  List<String> get wordlistIds => throw _privateConstructorUsedError;

  /// Whether to detect leetspeak variations
  bool get detectLeetspeak => throw _privateConstructorUsedError;

  /// Whether to detect phonetic variations
  bool get detectPhonetic => throw _privateConstructorUsedError;

  /// Whether to use fuzzy matching
  bool get detectFuzzy => throw _privateConstructorUsedError;

  /// Whether to detect obfuscated words
  bool get detectObfuscated => throw _privateConstructorUsedError;

  /// Minimum confidence for fuzzy matches
  double get fuzzyThreshold => throw _privateConstructorUsedError;

  /// Custom words to add to detection
  List<String> get customWords => throw _privateConstructorUsedError;

  /// Words to exclude from detection
  List<String> get excludedWords => throw _privateConstructorUsedError;

  /// Minimum word length to check
  int get minWordLength => throw _privateConstructorUsedError;

  /// Whether to check for context (reduce false positives)
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

  /// Wordlist IDs to use for detection
  final List<String> _wordlistIds;

  /// Wordlist IDs to use for detection
  @override
  @JsonKey()
  List<String> get wordlistIds {
    if (_wordlistIds is EqualUnmodifiableListView) return _wordlistIds;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_wordlistIds);
  }

  /// Whether to detect leetspeak variations
  @override
  @JsonKey()
  final bool detectLeetspeak;

  /// Whether to detect phonetic variations
  @override
  @JsonKey()
  final bool detectPhonetic;

  /// Whether to use fuzzy matching
  @override
  @JsonKey()
  final bool detectFuzzy;

  /// Whether to detect obfuscated words
  @override
  @JsonKey()
  final bool detectObfuscated;

  /// Minimum confidence for fuzzy matches
  @override
  @JsonKey()
  final double fuzzyThreshold;

  /// Custom words to add to detection
  final List<String> _customWords;

  /// Custom words to add to detection
  @override
  @JsonKey()
  List<String> get customWords {
    if (_customWords is EqualUnmodifiableListView) return _customWords;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_customWords);
  }

  /// Words to exclude from detection
  final List<String> _excludedWords;

  /// Words to exclude from detection
  @override
  @JsonKey()
  List<String> get excludedWords {
    if (_excludedWords is EqualUnmodifiableListView) return _excludedWords;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_excludedWords);
  }

  /// Minimum word length to check
  @override
  @JsonKey()
  final int minWordLength;

  /// Whether to check for context (reduce false positives)
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

  /// Wordlist IDs to use for detection
  @override
  List<String> get wordlistIds;

  /// Whether to detect leetspeak variations
  @override
  bool get detectLeetspeak;

  /// Whether to detect phonetic variations
  @override
  bool get detectPhonetic;

  /// Whether to use fuzzy matching
  @override
  bool get detectFuzzy;

  /// Whether to detect obfuscated words
  @override
  bool get detectObfuscated;

  /// Minimum confidence for fuzzy matches
  @override
  double get fuzzyThreshold;

  /// Custom words to add to detection
  @override
  List<String> get customWords;

  /// Words to exclude from detection
  @override
  List<String> get excludedWords;

  /// Minimum word length to check
  @override
  int get minWordLength;

  /// Whether to check for context (reduce false positives)
  @override
  bool get useContextAnalysis;

  /// Create a copy of ProfanityConfig
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$ProfanityConfigImplCopyWith<_$ProfanityConfigImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

AnalysisSettings _$AnalysisSettingsFromJson(Map<String, dynamic> json) {
  return _AnalysisSettings.fromJson(json);
}

/// @nodoc
mixin _$AnalysisSettings {
  /// Model configuration
  ModelConfig get modelConfig => throw _privateConstructorUsedError;

  /// Profanity configuration
  ProfanityConfig get profanityConfig => throw _privateConstructorUsedError;

  /// NSFW detection threshold (0.0 to 1.0)
  double get nsfwThreshold => throw _privateConstructorUsedError;

  /// Violence detection threshold (0.0 to 1.0)
  double get violenceThreshold => throw _privateConstructorUsedError;

  /// Blood/gore detection threshold (0.0 to 1.0)
  double get bloodThreshold => throw _privateConstructorUsedError;

  /// Weapons detection threshold (0.0 to 1.0)
  double get weaponsThreshold => throw _privateConstructorUsedError;

  /// Whether NSFW detection is enabled
  bool get enableNsfw => throw _privateConstructorUsedError;

  /// Whether violence detection is enabled
  bool get enableViolence => throw _privateConstructorUsedError;

  /// Whether blood/gore detection is enabled
  bool get enableBlood => throw _privateConstructorUsedError;

  /// Whether weapons detection is enabled
  bool get enableWeapons => throw _privateConstructorUsedError;

  /// Whether profanity detection is enabled
  bool get enableProfanity => throw _privateConstructorUsedError;

  /// Frame sampling rate (analyze every Nth frame)
  int get frameSamplingRate => throw _privateConstructorUsedError;

  /// Whether to use scene detection for adaptive sampling
  bool get useSceneDetection => throw _privateConstructorUsedError;

  /// Minimum segment duration in milliseconds
  int get minSegmentDurationMs => throw _privateConstructorUsedError;

  /// Whether to merge adjacent detections of same type
  bool get mergeAdjacentDetections => throw _privateConstructorUsedError;

  /// Buffer time in milliseconds to add around detections
  int get detectionBufferMs => throw _privateConstructorUsedError;

  /// Maximum concurrent frame analyses
  int get maxConcurrentAnalyses => throw _privateConstructorUsedError;

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
      double nsfwThreshold,
      double violenceThreshold,
      double bloodThreshold,
      double weaponsThreshold,
      bool enableNsfw,
      bool enableViolence,
      bool enableBlood,
      bool enableWeapons,
      bool enableProfanity,
      int frameSamplingRate,
      bool useSceneDetection,
      int minSegmentDurationMs,
      bool mergeAdjacentDetections,
      int detectionBufferMs,
      int maxConcurrentAnalyses});

  $ModelConfigCopyWith<$Res> get modelConfig;
  $ProfanityConfigCopyWith<$Res> get profanityConfig;
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
    Object? nsfwThreshold = null,
    Object? violenceThreshold = null,
    Object? bloodThreshold = null,
    Object? weaponsThreshold = null,
    Object? enableNsfw = null,
    Object? enableViolence = null,
    Object? enableBlood = null,
    Object? enableWeapons = null,
    Object? enableProfanity = null,
    Object? frameSamplingRate = null,
    Object? useSceneDetection = null,
    Object? minSegmentDurationMs = null,
    Object? mergeAdjacentDetections = null,
    Object? detectionBufferMs = null,
    Object? maxConcurrentAnalyses = null,
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
      nsfwThreshold: null == nsfwThreshold
          ? _value.nsfwThreshold
          : nsfwThreshold // ignore: cast_nullable_to_non_nullable
              as double,
      violenceThreshold: null == violenceThreshold
          ? _value.violenceThreshold
          : violenceThreshold // ignore: cast_nullable_to_non_nullable
              as double,
      bloodThreshold: null == bloodThreshold
          ? _value.bloodThreshold
          : bloodThreshold // ignore: cast_nullable_to_non_nullable
              as double,
      weaponsThreshold: null == weaponsThreshold
          ? _value.weaponsThreshold
          : weaponsThreshold // ignore: cast_nullable_to_non_nullable
              as double,
      enableNsfw: null == enableNsfw
          ? _value.enableNsfw
          : enableNsfw // ignore: cast_nullable_to_non_nullable
              as bool,
      enableViolence: null == enableViolence
          ? _value.enableViolence
          : enableViolence // ignore: cast_nullable_to_non_nullable
              as bool,
      enableBlood: null == enableBlood
          ? _value.enableBlood
          : enableBlood // ignore: cast_nullable_to_non_nullable
              as bool,
      enableWeapons: null == enableWeapons
          ? _value.enableWeapons
          : enableWeapons // ignore: cast_nullable_to_non_nullable
              as bool,
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
      double nsfwThreshold,
      double violenceThreshold,
      double bloodThreshold,
      double weaponsThreshold,
      bool enableNsfw,
      bool enableViolence,
      bool enableBlood,
      bool enableWeapons,
      bool enableProfanity,
      int frameSamplingRate,
      bool useSceneDetection,
      int minSegmentDurationMs,
      bool mergeAdjacentDetections,
      int detectionBufferMs,
      int maxConcurrentAnalyses});

  @override
  $ModelConfigCopyWith<$Res> get modelConfig;
  @override
  $ProfanityConfigCopyWith<$Res> get profanityConfig;
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
    Object? nsfwThreshold = null,
    Object? violenceThreshold = null,
    Object? bloodThreshold = null,
    Object? weaponsThreshold = null,
    Object? enableNsfw = null,
    Object? enableViolence = null,
    Object? enableBlood = null,
    Object? enableWeapons = null,
    Object? enableProfanity = null,
    Object? frameSamplingRate = null,
    Object? useSceneDetection = null,
    Object? minSegmentDurationMs = null,
    Object? mergeAdjacentDetections = null,
    Object? detectionBufferMs = null,
    Object? maxConcurrentAnalyses = null,
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
      nsfwThreshold: null == nsfwThreshold
          ? _value.nsfwThreshold
          : nsfwThreshold // ignore: cast_nullable_to_non_nullable
              as double,
      violenceThreshold: null == violenceThreshold
          ? _value.violenceThreshold
          : violenceThreshold // ignore: cast_nullable_to_non_nullable
              as double,
      bloodThreshold: null == bloodThreshold
          ? _value.bloodThreshold
          : bloodThreshold // ignore: cast_nullable_to_non_nullable
              as double,
      weaponsThreshold: null == weaponsThreshold
          ? _value.weaponsThreshold
          : weaponsThreshold // ignore: cast_nullable_to_non_nullable
              as double,
      enableNsfw: null == enableNsfw
          ? _value.enableNsfw
          : enableNsfw // ignore: cast_nullable_to_non_nullable
              as bool,
      enableViolence: null == enableViolence
          ? _value.enableViolence
          : enableViolence // ignore: cast_nullable_to_non_nullable
              as bool,
      enableBlood: null == enableBlood
          ? _value.enableBlood
          : enableBlood // ignore: cast_nullable_to_non_nullable
              as bool,
      enableWeapons: null == enableWeapons
          ? _value.enableWeapons
          : enableWeapons // ignore: cast_nullable_to_non_nullable
              as bool,
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
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$AnalysisSettingsImpl extends _AnalysisSettings {
  const _$AnalysisSettingsImpl(
      {required this.modelConfig,
      required this.profanityConfig,
      this.nsfwThreshold = 0.6,
      this.violenceThreshold = 0.6,
      this.bloodThreshold = 0.6,
      this.weaponsThreshold = 0.6,
      this.enableNsfw = true,
      this.enableViolence = true,
      this.enableBlood = true,
      this.enableWeapons = true,
      this.enableProfanity = true,
      this.frameSamplingRate = 5,
      this.useSceneDetection = true,
      this.minSegmentDurationMs = 500,
      this.mergeAdjacentDetections = true,
      this.detectionBufferMs = 100,
      this.maxConcurrentAnalyses = 4})
      : super._();

  factory _$AnalysisSettingsImpl.fromJson(Map<String, dynamic> json) =>
      _$$AnalysisSettingsImplFromJson(json);

  /// Model configuration
  @override
  final ModelConfig modelConfig;

  /// Profanity configuration
  @override
  final ProfanityConfig profanityConfig;

  /// NSFW detection threshold (0.0 to 1.0)
  @override
  @JsonKey()
  final double nsfwThreshold;

  /// Violence detection threshold (0.0 to 1.0)
  @override
  @JsonKey()
  final double violenceThreshold;

  /// Blood/gore detection threshold (0.0 to 1.0)
  @override
  @JsonKey()
  final double bloodThreshold;

  /// Weapons detection threshold (0.0 to 1.0)
  @override
  @JsonKey()
  final double weaponsThreshold;

  /// Whether NSFW detection is enabled
  @override
  @JsonKey()
  final bool enableNsfw;

  /// Whether violence detection is enabled
  @override
  @JsonKey()
  final bool enableViolence;

  /// Whether blood/gore detection is enabled
  @override
  @JsonKey()
  final bool enableBlood;

  /// Whether weapons detection is enabled
  @override
  @JsonKey()
  final bool enableWeapons;

  /// Whether profanity detection is enabled
  @override
  @JsonKey()
  final bool enableProfanity;

  /// Frame sampling rate (analyze every Nth frame)
  @override
  @JsonKey()
  final int frameSamplingRate;

  /// Whether to use scene detection for adaptive sampling
  @override
  @JsonKey()
  final bool useSceneDetection;

  /// Minimum segment duration in milliseconds
  @override
  @JsonKey()
  final int minSegmentDurationMs;

  /// Whether to merge adjacent detections of same type
  @override
  @JsonKey()
  final bool mergeAdjacentDetections;

  /// Buffer time in milliseconds to add around detections
  @override
  @JsonKey()
  final int detectionBufferMs;

  /// Maximum concurrent frame analyses
  @override
  @JsonKey()
  final int maxConcurrentAnalyses;

  @override
  String toString() {
    return 'AnalysisSettings(modelConfig: $modelConfig, profanityConfig: $profanityConfig, nsfwThreshold: $nsfwThreshold, violenceThreshold: $violenceThreshold, bloodThreshold: $bloodThreshold, weaponsThreshold: $weaponsThreshold, enableNsfw: $enableNsfw, enableViolence: $enableViolence, enableBlood: $enableBlood, enableWeapons: $enableWeapons, enableProfanity: $enableProfanity, frameSamplingRate: $frameSamplingRate, useSceneDetection: $useSceneDetection, minSegmentDurationMs: $minSegmentDurationMs, mergeAdjacentDetections: $mergeAdjacentDetections, detectionBufferMs: $detectionBufferMs, maxConcurrentAnalyses: $maxConcurrentAnalyses)';
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
            (identical(other.nsfwThreshold, nsfwThreshold) ||
                other.nsfwThreshold == nsfwThreshold) &&
            (identical(other.violenceThreshold, violenceThreshold) ||
                other.violenceThreshold == violenceThreshold) &&
            (identical(other.bloodThreshold, bloodThreshold) ||
                other.bloodThreshold == bloodThreshold) &&
            (identical(other.weaponsThreshold, weaponsThreshold) ||
                other.weaponsThreshold == weaponsThreshold) &&
            (identical(other.enableNsfw, enableNsfw) ||
                other.enableNsfw == enableNsfw) &&
            (identical(other.enableViolence, enableViolence) ||
                other.enableViolence == enableViolence) &&
            (identical(other.enableBlood, enableBlood) ||
                other.enableBlood == enableBlood) &&
            (identical(other.enableWeapons, enableWeapons) ||
                other.enableWeapons == enableWeapons) &&
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
                other.maxConcurrentAnalyses == maxConcurrentAnalyses));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
      runtimeType,
      modelConfig,
      profanityConfig,
      nsfwThreshold,
      violenceThreshold,
      bloodThreshold,
      weaponsThreshold,
      enableNsfw,
      enableViolence,
      enableBlood,
      enableWeapons,
      enableProfanity,
      frameSamplingRate,
      useSceneDetection,
      minSegmentDurationMs,
      mergeAdjacentDetections,
      detectionBufferMs,
      maxConcurrentAnalyses);

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
      final double nsfwThreshold,
      final double violenceThreshold,
      final double bloodThreshold,
      final double weaponsThreshold,
      final bool enableNsfw,
      final bool enableViolence,
      final bool enableBlood,
      final bool enableWeapons,
      final bool enableProfanity,
      final int frameSamplingRate,
      final bool useSceneDetection,
      final int minSegmentDurationMs,
      final bool mergeAdjacentDetections,
      final int detectionBufferMs,
      final int maxConcurrentAnalyses}) = _$AnalysisSettingsImpl;
  const _AnalysisSettings._() : super._();

  factory _AnalysisSettings.fromJson(Map<String, dynamic> json) =
      _$AnalysisSettingsImpl.fromJson;

  /// Model configuration
  @override
  ModelConfig get modelConfig;

  /// Profanity configuration
  @override
  ProfanityConfig get profanityConfig;

  /// NSFW detection threshold (0.0 to 1.0)
  @override
  double get nsfwThreshold;

  /// Violence detection threshold (0.0 to 1.0)
  @override
  double get violenceThreshold;

  /// Blood/gore detection threshold (0.0 to 1.0)
  @override
  double get bloodThreshold;

  /// Weapons detection threshold (0.0 to 1.0)
  @override
  double get weaponsThreshold;

  /// Whether NSFW detection is enabled
  @override
  bool get enableNsfw;

  /// Whether violence detection is enabled
  @override
  bool get enableViolence;

  /// Whether blood/gore detection is enabled
  @override
  bool get enableBlood;

  /// Whether weapons detection is enabled
  @override
  bool get enableWeapons;

  /// Whether profanity detection is enabled
  @override
  bool get enableProfanity;

  /// Frame sampling rate (analyze every Nth frame)
  @override
  int get frameSamplingRate;

  /// Whether to use scene detection for adaptive sampling
  @override
  bool get useSceneDetection;

  /// Minimum segment duration in milliseconds
  @override
  int get minSegmentDurationMs;

  /// Whether to merge adjacent detections of same type
  @override
  bool get mergeAdjacentDetections;

  /// Buffer time in milliseconds to add around detections
  @override
  int get detectionBufferMs;

  /// Maximum concurrent frame analyses
  @override
  int get maxConcurrentAnalyses;

  /// Create a copy of AnalysisSettings
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$AnalysisSettingsImplCopyWith<_$AnalysisSettingsImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
