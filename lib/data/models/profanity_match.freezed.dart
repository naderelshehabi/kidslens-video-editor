// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'profanity_match.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

ProfanityMatch _$ProfanityMatchFromJson(Map<String, dynamic> json) {
  return _ProfanityMatch.fromJson(json);
}

/// @nodoc
mixin _$ProfanityMatch {
  /// Unique identifier for the match
  String get id => throw _privateConstructorUsedError;

  /// The transcript word that matched
  TranscriptWord get word => throw _privateConstructorUsedError;

  /// The profanity word/pattern that was matched against
  String get matchedProfanity => throw _privateConstructorUsedError;

  /// Confidence score (0.0 to 1.0)
  double get confidence => throw _privateConstructorUsedError;

  /// Type of match
  MatchType get type => throw _privateConstructorUsedError;

  /// Severity level (1-5, where 5 is most severe)
  int get severity => throw _privateConstructorUsedError;

  /// Category of profanity (e.g., 'sexual', 'slur', 'general')
  String? get category => throw _privateConstructorUsedError;

  /// Whether this match has been reviewed by user
  bool get isReviewed => throw _privateConstructorUsedError;

  /// Whether this is a false positive (user marked)
  bool get isFalsePositive => throw _privateConstructorUsedError;

  /// User note about this match
  String? get userNote => throw _privateConstructorUsedError;

  /// Serializes this ProfanityMatch to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of ProfanityMatch
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $ProfanityMatchCopyWith<ProfanityMatch> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $ProfanityMatchCopyWith<$Res> {
  factory $ProfanityMatchCopyWith(
          ProfanityMatch value, $Res Function(ProfanityMatch) then) =
      _$ProfanityMatchCopyWithImpl<$Res, ProfanityMatch>;
  @useResult
  $Res call(
      {String id,
      TranscriptWord word,
      String matchedProfanity,
      double confidence,
      MatchType type,
      int severity,
      String? category,
      bool isReviewed,
      bool isFalsePositive,
      String? userNote});

  $TranscriptWordCopyWith<$Res> get word;
}

/// @nodoc
class _$ProfanityMatchCopyWithImpl<$Res, $Val extends ProfanityMatch>
    implements $ProfanityMatchCopyWith<$Res> {
  _$ProfanityMatchCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of ProfanityMatch
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? word = null,
    Object? matchedProfanity = null,
    Object? confidence = null,
    Object? type = null,
    Object? severity = null,
    Object? category = freezed,
    Object? isReviewed = null,
    Object? isFalsePositive = null,
    Object? userNote = freezed,
  }) {
    return _then(_value.copyWith(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      word: null == word
          ? _value.word
          : word // ignore: cast_nullable_to_non_nullable
              as TranscriptWord,
      matchedProfanity: null == matchedProfanity
          ? _value.matchedProfanity
          : matchedProfanity // ignore: cast_nullable_to_non_nullable
              as String,
      confidence: null == confidence
          ? _value.confidence
          : confidence // ignore: cast_nullable_to_non_nullable
              as double,
      type: null == type
          ? _value.type
          : type // ignore: cast_nullable_to_non_nullable
              as MatchType,
      severity: null == severity
          ? _value.severity
          : severity // ignore: cast_nullable_to_non_nullable
              as int,
      category: freezed == category
          ? _value.category
          : category // ignore: cast_nullable_to_non_nullable
              as String?,
      isReviewed: null == isReviewed
          ? _value.isReviewed
          : isReviewed // ignore: cast_nullable_to_non_nullable
              as bool,
      isFalsePositive: null == isFalsePositive
          ? _value.isFalsePositive
          : isFalsePositive // ignore: cast_nullable_to_non_nullable
              as bool,
      userNote: freezed == userNote
          ? _value.userNote
          : userNote // ignore: cast_nullable_to_non_nullable
              as String?,
    ) as $Val);
  }

  /// Create a copy of ProfanityMatch
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $TranscriptWordCopyWith<$Res> get word {
    return $TranscriptWordCopyWith<$Res>(_value.word, (value) {
      return _then(_value.copyWith(word: value) as $Val);
    });
  }
}

/// @nodoc
abstract class _$$ProfanityMatchImplCopyWith<$Res>
    implements $ProfanityMatchCopyWith<$Res> {
  factory _$$ProfanityMatchImplCopyWith(_$ProfanityMatchImpl value,
          $Res Function(_$ProfanityMatchImpl) then) =
      __$$ProfanityMatchImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String id,
      TranscriptWord word,
      String matchedProfanity,
      double confidence,
      MatchType type,
      int severity,
      String? category,
      bool isReviewed,
      bool isFalsePositive,
      String? userNote});

  @override
  $TranscriptWordCopyWith<$Res> get word;
}

/// @nodoc
class __$$ProfanityMatchImplCopyWithImpl<$Res>
    extends _$ProfanityMatchCopyWithImpl<$Res, _$ProfanityMatchImpl>
    implements _$$ProfanityMatchImplCopyWith<$Res> {
  __$$ProfanityMatchImplCopyWithImpl(
      _$ProfanityMatchImpl _value, $Res Function(_$ProfanityMatchImpl) _then)
      : super(_value, _then);

  /// Create a copy of ProfanityMatch
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? word = null,
    Object? matchedProfanity = null,
    Object? confidence = null,
    Object? type = null,
    Object? severity = null,
    Object? category = freezed,
    Object? isReviewed = null,
    Object? isFalsePositive = null,
    Object? userNote = freezed,
  }) {
    return _then(_$ProfanityMatchImpl(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      word: null == word
          ? _value.word
          : word // ignore: cast_nullable_to_non_nullable
              as TranscriptWord,
      matchedProfanity: null == matchedProfanity
          ? _value.matchedProfanity
          : matchedProfanity // ignore: cast_nullable_to_non_nullable
              as String,
      confidence: null == confidence
          ? _value.confidence
          : confidence // ignore: cast_nullable_to_non_nullable
              as double,
      type: null == type
          ? _value.type
          : type // ignore: cast_nullable_to_non_nullable
              as MatchType,
      severity: null == severity
          ? _value.severity
          : severity // ignore: cast_nullable_to_non_nullable
              as int,
      category: freezed == category
          ? _value.category
          : category // ignore: cast_nullable_to_non_nullable
              as String?,
      isReviewed: null == isReviewed
          ? _value.isReviewed
          : isReviewed // ignore: cast_nullable_to_non_nullable
              as bool,
      isFalsePositive: null == isFalsePositive
          ? _value.isFalsePositive
          : isFalsePositive // ignore: cast_nullable_to_non_nullable
              as bool,
      userNote: freezed == userNote
          ? _value.userNote
          : userNote // ignore: cast_nullable_to_non_nullable
              as String?,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$ProfanityMatchImpl extends _ProfanityMatch {
  const _$ProfanityMatchImpl(
      {required this.id,
      required this.word,
      required this.matchedProfanity,
      required this.confidence,
      required this.type,
      this.severity = 3,
      this.category,
      this.isReviewed = false,
      this.isFalsePositive = false,
      this.userNote})
      : super._();

  factory _$ProfanityMatchImpl.fromJson(Map<String, dynamic> json) =>
      _$$ProfanityMatchImplFromJson(json);

  /// Unique identifier for the match
  @override
  final String id;

  /// The transcript word that matched
  @override
  final TranscriptWord word;

  /// The profanity word/pattern that was matched against
  @override
  final String matchedProfanity;

  /// Confidence score (0.0 to 1.0)
  @override
  final double confidence;

  /// Type of match
  @override
  final MatchType type;

  /// Severity level (1-5, where 5 is most severe)
  @override
  @JsonKey()
  final int severity;

  /// Category of profanity (e.g., 'sexual', 'slur', 'general')
  @override
  final String? category;

  /// Whether this match has been reviewed by user
  @override
  @JsonKey()
  final bool isReviewed;

  /// Whether this is a false positive (user marked)
  @override
  @JsonKey()
  final bool isFalsePositive;

  /// User note about this match
  @override
  final String? userNote;

  @override
  String toString() {
    return 'ProfanityMatch(id: $id, word: $word, matchedProfanity: $matchedProfanity, confidence: $confidence, type: $type, severity: $severity, category: $category, isReviewed: $isReviewed, isFalsePositive: $isFalsePositive, userNote: $userNote)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$ProfanityMatchImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.word, word) || other.word == word) &&
            (identical(other.matchedProfanity, matchedProfanity) ||
                other.matchedProfanity == matchedProfanity) &&
            (identical(other.confidence, confidence) ||
                other.confidence == confidence) &&
            (identical(other.type, type) || other.type == type) &&
            (identical(other.severity, severity) ||
                other.severity == severity) &&
            (identical(other.category, category) ||
                other.category == category) &&
            (identical(other.isReviewed, isReviewed) ||
                other.isReviewed == isReviewed) &&
            (identical(other.isFalsePositive, isFalsePositive) ||
                other.isFalsePositive == isFalsePositive) &&
            (identical(other.userNote, userNote) ||
                other.userNote == userNote));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
      runtimeType,
      id,
      word,
      matchedProfanity,
      confidence,
      type,
      severity,
      category,
      isReviewed,
      isFalsePositive,
      userNote);

  /// Create a copy of ProfanityMatch
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$ProfanityMatchImplCopyWith<_$ProfanityMatchImpl> get copyWith =>
      __$$ProfanityMatchImplCopyWithImpl<_$ProfanityMatchImpl>(
          this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$ProfanityMatchImplToJson(
      this,
    );
  }
}

abstract class _ProfanityMatch extends ProfanityMatch {
  const factory _ProfanityMatch(
      {required final String id,
      required final TranscriptWord word,
      required final String matchedProfanity,
      required final double confidence,
      required final MatchType type,
      final int severity,
      final String? category,
      final bool isReviewed,
      final bool isFalsePositive,
      final String? userNote}) = _$ProfanityMatchImpl;
  const _ProfanityMatch._() : super._();

  factory _ProfanityMatch.fromJson(Map<String, dynamic> json) =
      _$ProfanityMatchImpl.fromJson;

  /// Unique identifier for the match
  @override
  String get id;

  /// The transcript word that matched
  @override
  TranscriptWord get word;

  /// The profanity word/pattern that was matched against
  @override
  String get matchedProfanity;

  /// Confidence score (0.0 to 1.0)
  @override
  double get confidence;

  /// Type of match
  @override
  MatchType get type;

  /// Severity level (1-5, where 5 is most severe)
  @override
  int get severity;

  /// Category of profanity (e.g., 'sexual', 'slur', 'general')
  @override
  String? get category;

  /// Whether this match has been reviewed by user
  @override
  bool get isReviewed;

  /// Whether this is a false positive (user marked)
  @override
  bool get isFalsePositive;

  /// User note about this match
  @override
  String? get userNote;

  /// Create a copy of ProfanityMatch
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$ProfanityMatchImplCopyWith<_$ProfanityMatchImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
