// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'transcript.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

TranscriptWord _$TranscriptWordFromJson(Map<String, dynamic> json) {
  return _TranscriptWord.fromJson(json);
}

/// @nodoc
mixin _$TranscriptWord {
  /// The actual word text
  String get word => throw _privateConstructorUsedError;

  /// Start time of the word relative to media start
  @DurationConverter()
  Duration get startTime => throw _privateConstructorUsedError;

  /// End time of the word relative to media start
  @DurationConverter()
  Duration get endTime => throw _privateConstructorUsedError;

  /// Confidence score from ASR (0.0 to 1.0)
  double get confidence => throw _privateConstructorUsedError;

  /// Serializes this TranscriptWord to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of TranscriptWord
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $TranscriptWordCopyWith<TranscriptWord> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $TranscriptWordCopyWith<$Res> {
  factory $TranscriptWordCopyWith(
          TranscriptWord value, $Res Function(TranscriptWord) then) =
      _$TranscriptWordCopyWithImpl<$Res, TranscriptWord>;
  @useResult
  $Res call(
      {String word,
      @DurationConverter() Duration startTime,
      @DurationConverter() Duration endTime,
      double confidence});
}

/// @nodoc
class _$TranscriptWordCopyWithImpl<$Res, $Val extends TranscriptWord>
    implements $TranscriptWordCopyWith<$Res> {
  _$TranscriptWordCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of TranscriptWord
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? word = null,
    Object? startTime = null,
    Object? endTime = null,
    Object? confidence = null,
  }) {
    return _then(_value.copyWith(
      word: null == word
          ? _value.word
          : word // ignore: cast_nullable_to_non_nullable
              as String,
      startTime: null == startTime
          ? _value.startTime
          : startTime // ignore: cast_nullable_to_non_nullable
              as Duration,
      endTime: null == endTime
          ? _value.endTime
          : endTime // ignore: cast_nullable_to_non_nullable
              as Duration,
      confidence: null == confidence
          ? _value.confidence
          : confidence // ignore: cast_nullable_to_non_nullable
              as double,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$TranscriptWordImplCopyWith<$Res>
    implements $TranscriptWordCopyWith<$Res> {
  factory _$$TranscriptWordImplCopyWith(_$TranscriptWordImpl value,
          $Res Function(_$TranscriptWordImpl) then) =
      __$$TranscriptWordImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String word,
      @DurationConverter() Duration startTime,
      @DurationConverter() Duration endTime,
      double confidence});
}

/// @nodoc
class __$$TranscriptWordImplCopyWithImpl<$Res>
    extends _$TranscriptWordCopyWithImpl<$Res, _$TranscriptWordImpl>
    implements _$$TranscriptWordImplCopyWith<$Res> {
  __$$TranscriptWordImplCopyWithImpl(
      _$TranscriptWordImpl _value, $Res Function(_$TranscriptWordImpl) _then)
      : super(_value, _then);

  /// Create a copy of TranscriptWord
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? word = null,
    Object? startTime = null,
    Object? endTime = null,
    Object? confidence = null,
  }) {
    return _then(_$TranscriptWordImpl(
      word: null == word
          ? _value.word
          : word // ignore: cast_nullable_to_non_nullable
              as String,
      startTime: null == startTime
          ? _value.startTime
          : startTime // ignore: cast_nullable_to_non_nullable
              as Duration,
      endTime: null == endTime
          ? _value.endTime
          : endTime // ignore: cast_nullable_to_non_nullable
              as Duration,
      confidence: null == confidence
          ? _value.confidence
          : confidence // ignore: cast_nullable_to_non_nullable
              as double,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$TranscriptWordImpl extends _TranscriptWord {
  const _$TranscriptWordImpl(
      {required this.word,
      @DurationConverter() required this.startTime,
      @DurationConverter() required this.endTime,
      required this.confidence})
      : super._();

  factory _$TranscriptWordImpl.fromJson(Map<String, dynamic> json) =>
      _$$TranscriptWordImplFromJson(json);

  /// The actual word text
  @override
  final String word;

  /// Start time of the word relative to media start
  @override
  @DurationConverter()
  final Duration startTime;

  /// End time of the word relative to media start
  @override
  @DurationConverter()
  final Duration endTime;

  /// Confidence score from ASR (0.0 to 1.0)
  @override
  final double confidence;

  @override
  String toString() {
    return 'TranscriptWord(word: $word, startTime: $startTime, endTime: $endTime, confidence: $confidence)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$TranscriptWordImpl &&
            (identical(other.word, word) || other.word == word) &&
            (identical(other.startTime, startTime) ||
                other.startTime == startTime) &&
            (identical(other.endTime, endTime) || other.endTime == endTime) &&
            (identical(other.confidence, confidence) ||
                other.confidence == confidence));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode =>
      Object.hash(runtimeType, word, startTime, endTime, confidence);

  /// Create a copy of TranscriptWord
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$TranscriptWordImplCopyWith<_$TranscriptWordImpl> get copyWith =>
      __$$TranscriptWordImplCopyWithImpl<_$TranscriptWordImpl>(
          this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$TranscriptWordImplToJson(
      this,
    );
  }
}

abstract class _TranscriptWord extends TranscriptWord {
  const factory _TranscriptWord(
      {required final String word,
      @DurationConverter() required final Duration startTime,
      @DurationConverter() required final Duration endTime,
      required final double confidence}) = _$TranscriptWordImpl;
  const _TranscriptWord._() : super._();

  factory _TranscriptWord.fromJson(Map<String, dynamic> json) =
      _$TranscriptWordImpl.fromJson;

  /// The actual word text
  @override
  String get word;

  /// Start time of the word relative to media start
  @override
  @DurationConverter()
  Duration get startTime;

  /// End time of the word relative to media start
  @override
  @DurationConverter()
  Duration get endTime;

  /// Confidence score from ASR (0.0 to 1.0)
  @override
  double get confidence;

  /// Create a copy of TranscriptWord
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$TranscriptWordImplCopyWith<_$TranscriptWordImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

TranscriptSegment _$TranscriptSegmentFromJson(Map<String, dynamic> json) {
  return _TranscriptSegment.fromJson(json);
}

/// @nodoc
mixin _$TranscriptSegment {
  /// Unique identifier for the segment
  String get id => throw _privateConstructorUsedError;

  /// Start time of the segment relative to media start
  @DurationConverter()
  Duration get startTime => throw _privateConstructorUsedError;

  /// End time of the segment relative to media start
  @DurationConverter()
  Duration get endTime => throw _privateConstructorUsedError;

  /// Full text of the segment
  String get text => throw _privateConstructorUsedError;

  /// Individual words with timing information
  List<TranscriptWord> get words => throw _privateConstructorUsedError;

  /// Serializes this TranscriptSegment to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of TranscriptSegment
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $TranscriptSegmentCopyWith<TranscriptSegment> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $TranscriptSegmentCopyWith<$Res> {
  factory $TranscriptSegmentCopyWith(
          TranscriptSegment value, $Res Function(TranscriptSegment) then) =
      _$TranscriptSegmentCopyWithImpl<$Res, TranscriptSegment>;
  @useResult
  $Res call(
      {String id,
      @DurationConverter() Duration startTime,
      @DurationConverter() Duration endTime,
      String text,
      List<TranscriptWord> words});
}

/// @nodoc
class _$TranscriptSegmentCopyWithImpl<$Res, $Val extends TranscriptSegment>
    implements $TranscriptSegmentCopyWith<$Res> {
  _$TranscriptSegmentCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of TranscriptSegment
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? startTime = null,
    Object? endTime = null,
    Object? text = null,
    Object? words = null,
  }) {
    return _then(_value.copyWith(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      startTime: null == startTime
          ? _value.startTime
          : startTime // ignore: cast_nullable_to_non_nullable
              as Duration,
      endTime: null == endTime
          ? _value.endTime
          : endTime // ignore: cast_nullable_to_non_nullable
              as Duration,
      text: null == text
          ? _value.text
          : text // ignore: cast_nullable_to_non_nullable
              as String,
      words: null == words
          ? _value.words
          : words // ignore: cast_nullable_to_non_nullable
              as List<TranscriptWord>,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$TranscriptSegmentImplCopyWith<$Res>
    implements $TranscriptSegmentCopyWith<$Res> {
  factory _$$TranscriptSegmentImplCopyWith(_$TranscriptSegmentImpl value,
          $Res Function(_$TranscriptSegmentImpl) then) =
      __$$TranscriptSegmentImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String id,
      @DurationConverter() Duration startTime,
      @DurationConverter() Duration endTime,
      String text,
      List<TranscriptWord> words});
}

/// @nodoc
class __$$TranscriptSegmentImplCopyWithImpl<$Res>
    extends _$TranscriptSegmentCopyWithImpl<$Res, _$TranscriptSegmentImpl>
    implements _$$TranscriptSegmentImplCopyWith<$Res> {
  __$$TranscriptSegmentImplCopyWithImpl(_$TranscriptSegmentImpl _value,
      $Res Function(_$TranscriptSegmentImpl) _then)
      : super(_value, _then);

  /// Create a copy of TranscriptSegment
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? startTime = null,
    Object? endTime = null,
    Object? text = null,
    Object? words = null,
  }) {
    return _then(_$TranscriptSegmentImpl(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      startTime: null == startTime
          ? _value.startTime
          : startTime // ignore: cast_nullable_to_non_nullable
              as Duration,
      endTime: null == endTime
          ? _value.endTime
          : endTime // ignore: cast_nullable_to_non_nullable
              as Duration,
      text: null == text
          ? _value.text
          : text // ignore: cast_nullable_to_non_nullable
              as String,
      words: null == words
          ? _value._words
          : words // ignore: cast_nullable_to_non_nullable
              as List<TranscriptWord>,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$TranscriptSegmentImpl extends _TranscriptSegment {
  const _$TranscriptSegmentImpl(
      {required this.id,
      @DurationConverter() required this.startTime,
      @DurationConverter() required this.endTime,
      required this.text,
      required final List<TranscriptWord> words})
      : _words = words,
        super._();

  factory _$TranscriptSegmentImpl.fromJson(Map<String, dynamic> json) =>
      _$$TranscriptSegmentImplFromJson(json);

  /// Unique identifier for the segment
  @override
  final String id;

  /// Start time of the segment relative to media start
  @override
  @DurationConverter()
  final Duration startTime;

  /// End time of the segment relative to media start
  @override
  @DurationConverter()
  final Duration endTime;

  /// Full text of the segment
  @override
  final String text;

  /// Individual words with timing information
  final List<TranscriptWord> _words;

  /// Individual words with timing information
  @override
  List<TranscriptWord> get words {
    if (_words is EqualUnmodifiableListView) return _words;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_words);
  }

  @override
  String toString() {
    return 'TranscriptSegment(id: $id, startTime: $startTime, endTime: $endTime, text: $text, words: $words)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$TranscriptSegmentImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.startTime, startTime) ||
                other.startTime == startTime) &&
            (identical(other.endTime, endTime) || other.endTime == endTime) &&
            (identical(other.text, text) || other.text == text) &&
            const DeepCollectionEquality().equals(other._words, _words));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, id, startTime, endTime, text,
      const DeepCollectionEquality().hash(_words));

  /// Create a copy of TranscriptSegment
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$TranscriptSegmentImplCopyWith<_$TranscriptSegmentImpl> get copyWith =>
      __$$TranscriptSegmentImplCopyWithImpl<_$TranscriptSegmentImpl>(
          this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$TranscriptSegmentImplToJson(
      this,
    );
  }
}

abstract class _TranscriptSegment extends TranscriptSegment {
  const factory _TranscriptSegment(
      {required final String id,
      @DurationConverter() required final Duration startTime,
      @DurationConverter() required final Duration endTime,
      required final String text,
      required final List<TranscriptWord> words}) = _$TranscriptSegmentImpl;
  const _TranscriptSegment._() : super._();

  factory _TranscriptSegment.fromJson(Map<String, dynamic> json) =
      _$TranscriptSegmentImpl.fromJson;

  /// Unique identifier for the segment
  @override
  String get id;

  /// Start time of the segment relative to media start
  @override
  @DurationConverter()
  Duration get startTime;

  /// End time of the segment relative to media start
  @override
  @DurationConverter()
  Duration get endTime;

  /// Full text of the segment
  @override
  String get text;

  /// Individual words with timing information
  @override
  List<TranscriptWord> get words;

  /// Create a copy of TranscriptSegment
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$TranscriptSegmentImplCopyWith<_$TranscriptSegmentImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

Transcript _$TranscriptFromJson(Map<String, dynamic> json) {
  return _Transcript.fromJson(json);
}

/// @nodoc
mixin _$Transcript {
  /// List of transcript segments
  List<TranscriptSegment> get segments => throw _privateConstructorUsedError;

  /// Language code (e.g., 'en', 'es', 'fr')
  String get language => throw _privateConstructorUsedError;

  /// Optional display name for the language
  String? get languageDisplayName => throw _privateConstructorUsedError;

  /// Timestamp when the transcript was generated
  DateTime? get generatedAt => throw _privateConstructorUsedError;

  /// Model ID used to generate the transcript
  String? get modelId => throw _privateConstructorUsedError;

  /// Serializes this Transcript to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of Transcript
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $TranscriptCopyWith<Transcript> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $TranscriptCopyWith<$Res> {
  factory $TranscriptCopyWith(
          Transcript value, $Res Function(Transcript) then) =
      _$TranscriptCopyWithImpl<$Res, Transcript>;
  @useResult
  $Res call(
      {List<TranscriptSegment> segments,
      String language,
      String? languageDisplayName,
      DateTime? generatedAt,
      String? modelId});
}

/// @nodoc
class _$TranscriptCopyWithImpl<$Res, $Val extends Transcript>
    implements $TranscriptCopyWith<$Res> {
  _$TranscriptCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of Transcript
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? segments = null,
    Object? language = null,
    Object? languageDisplayName = freezed,
    Object? generatedAt = freezed,
    Object? modelId = freezed,
  }) {
    return _then(_value.copyWith(
      segments: null == segments
          ? _value.segments
          : segments // ignore: cast_nullable_to_non_nullable
              as List<TranscriptSegment>,
      language: null == language
          ? _value.language
          : language // ignore: cast_nullable_to_non_nullable
              as String,
      languageDisplayName: freezed == languageDisplayName
          ? _value.languageDisplayName
          : languageDisplayName // ignore: cast_nullable_to_non_nullable
              as String?,
      generatedAt: freezed == generatedAt
          ? _value.generatedAt
          : generatedAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      modelId: freezed == modelId
          ? _value.modelId
          : modelId // ignore: cast_nullable_to_non_nullable
              as String?,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$TranscriptImplCopyWith<$Res>
    implements $TranscriptCopyWith<$Res> {
  factory _$$TranscriptImplCopyWith(
          _$TranscriptImpl value, $Res Function(_$TranscriptImpl) then) =
      __$$TranscriptImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {List<TranscriptSegment> segments,
      String language,
      String? languageDisplayName,
      DateTime? generatedAt,
      String? modelId});
}

/// @nodoc
class __$$TranscriptImplCopyWithImpl<$Res>
    extends _$TranscriptCopyWithImpl<$Res, _$TranscriptImpl>
    implements _$$TranscriptImplCopyWith<$Res> {
  __$$TranscriptImplCopyWithImpl(
      _$TranscriptImpl _value, $Res Function(_$TranscriptImpl) _then)
      : super(_value, _then);

  /// Create a copy of Transcript
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? segments = null,
    Object? language = null,
    Object? languageDisplayName = freezed,
    Object? generatedAt = freezed,
    Object? modelId = freezed,
  }) {
    return _then(_$TranscriptImpl(
      segments: null == segments
          ? _value._segments
          : segments // ignore: cast_nullable_to_non_nullable
              as List<TranscriptSegment>,
      language: null == language
          ? _value.language
          : language // ignore: cast_nullable_to_non_nullable
              as String,
      languageDisplayName: freezed == languageDisplayName
          ? _value.languageDisplayName
          : languageDisplayName // ignore: cast_nullable_to_non_nullable
              as String?,
      generatedAt: freezed == generatedAt
          ? _value.generatedAt
          : generatedAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      modelId: freezed == modelId
          ? _value.modelId
          : modelId // ignore: cast_nullable_to_non_nullable
              as String?,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$TranscriptImpl extends _Transcript {
  const _$TranscriptImpl(
      {required final List<TranscriptSegment> segments,
      required this.language,
      this.languageDisplayName,
      this.generatedAt,
      this.modelId})
      : _segments = segments,
        super._();

  factory _$TranscriptImpl.fromJson(Map<String, dynamic> json) =>
      _$$TranscriptImplFromJson(json);

  /// List of transcript segments
  final List<TranscriptSegment> _segments;

  /// List of transcript segments
  @override
  List<TranscriptSegment> get segments {
    if (_segments is EqualUnmodifiableListView) return _segments;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_segments);
  }

  /// Language code (e.g., 'en', 'es', 'fr')
  @override
  final String language;

  /// Optional display name for the language
  @override
  final String? languageDisplayName;

  /// Timestamp when the transcript was generated
  @override
  final DateTime? generatedAt;

  /// Model ID used to generate the transcript
  @override
  final String? modelId;

  @override
  String toString() {
    return 'Transcript(segments: $segments, language: $language, languageDisplayName: $languageDisplayName, generatedAt: $generatedAt, modelId: $modelId)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$TranscriptImpl &&
            const DeepCollectionEquality().equals(other._segments, _segments) &&
            (identical(other.language, language) ||
                other.language == language) &&
            (identical(other.languageDisplayName, languageDisplayName) ||
                other.languageDisplayName == languageDisplayName) &&
            (identical(other.generatedAt, generatedAt) ||
                other.generatedAt == generatedAt) &&
            (identical(other.modelId, modelId) || other.modelId == modelId));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
      runtimeType,
      const DeepCollectionEquality().hash(_segments),
      language,
      languageDisplayName,
      generatedAt,
      modelId);

  /// Create a copy of Transcript
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$TranscriptImplCopyWith<_$TranscriptImpl> get copyWith =>
      __$$TranscriptImplCopyWithImpl<_$TranscriptImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$TranscriptImplToJson(
      this,
    );
  }
}

abstract class _Transcript extends Transcript {
  const factory _Transcript(
      {required final List<TranscriptSegment> segments,
      required final String language,
      final String? languageDisplayName,
      final DateTime? generatedAt,
      final String? modelId}) = _$TranscriptImpl;
  const _Transcript._() : super._();

  factory _Transcript.fromJson(Map<String, dynamic> json) =
      _$TranscriptImpl.fromJson;

  /// List of transcript segments
  @override
  List<TranscriptSegment> get segments;

  /// Language code (e.g., 'en', 'es', 'fr')
  @override
  String get language;

  /// Optional display name for the language
  @override
  String? get languageDisplayName;

  /// Timestamp when the transcript was generated
  @override
  DateTime? get generatedAt;

  /// Model ID used to generate the transcript
  @override
  String? get modelId;

  /// Create a copy of Transcript
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$TranscriptImplCopyWith<_$TranscriptImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
