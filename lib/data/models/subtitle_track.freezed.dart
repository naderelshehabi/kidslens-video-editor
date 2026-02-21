// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'subtitle_track.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

SubtitleTrack _$SubtitleTrackFromJson(Map<String, dynamic> json) {
  return _SubtitleTrack.fromJson(json);
}

/// @nodoc
mixin _$SubtitleTrack {
  /// Unique identifier for the subtitle track
  String get id => throw _privateConstructorUsedError;

  /// ID of the media file this subtitle belongs to
  String get mediaId => throw _privateConstructorUsedError;

  /// Language code (e.g., 'en', 'es')
  String get language => throw _privateConstructorUsedError;

  /// When the subtitles were generated
  @DateTimeConverter()
  DateTime get createdAt => throw _privateConstructorUsedError;

  /// Subtitle segments with timing
  List<SubtitleSegment> get segments => throw _privateConstructorUsedError;

  /// The ASR model used to generate the subtitles
  String? get modelId => throw _privateConstructorUsedError;

  /// Serializes this SubtitleTrack to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of SubtitleTrack
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $SubtitleTrackCopyWith<SubtitleTrack> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $SubtitleTrackCopyWith<$Res> {
  factory $SubtitleTrackCopyWith(
          SubtitleTrack value, $Res Function(SubtitleTrack) then) =
      _$SubtitleTrackCopyWithImpl<$Res, SubtitleTrack>;
  @useResult
  $Res call(
      {String id,
      String mediaId,
      String language,
      @DateTimeConverter() DateTime createdAt,
      List<SubtitleSegment> segments,
      String? modelId});
}

/// @nodoc
class _$SubtitleTrackCopyWithImpl<$Res, $Val extends SubtitleTrack>
    implements $SubtitleTrackCopyWith<$Res> {
  _$SubtitleTrackCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of SubtitleTrack
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? mediaId = null,
    Object? language = null,
    Object? createdAt = null,
    Object? segments = null,
    Object? modelId = freezed,
  }) {
    return _then(_value.copyWith(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      mediaId: null == mediaId
          ? _value.mediaId
          : mediaId // ignore: cast_nullable_to_non_nullable
              as String,
      language: null == language
          ? _value.language
          : language // ignore: cast_nullable_to_non_nullable
              as String,
      createdAt: null == createdAt
          ? _value.createdAt
          : createdAt // ignore: cast_nullable_to_non_nullable
              as DateTime,
      segments: null == segments
          ? _value.segments
          : segments // ignore: cast_nullable_to_non_nullable
              as List<SubtitleSegment>,
      modelId: freezed == modelId
          ? _value.modelId
          : modelId // ignore: cast_nullable_to_non_nullable
              as String?,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$SubtitleTrackImplCopyWith<$Res>
    implements $SubtitleTrackCopyWith<$Res> {
  factory _$$SubtitleTrackImplCopyWith(
          _$SubtitleTrackImpl value, $Res Function(_$SubtitleTrackImpl) then) =
      __$$SubtitleTrackImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String id,
      String mediaId,
      String language,
      @DateTimeConverter() DateTime createdAt,
      List<SubtitleSegment> segments,
      String? modelId});
}

/// @nodoc
class __$$SubtitleTrackImplCopyWithImpl<$Res>
    extends _$SubtitleTrackCopyWithImpl<$Res, _$SubtitleTrackImpl>
    implements _$$SubtitleTrackImplCopyWith<$Res> {
  __$$SubtitleTrackImplCopyWithImpl(
      _$SubtitleTrackImpl _value, $Res Function(_$SubtitleTrackImpl) _then)
      : super(_value, _then);

  /// Create a copy of SubtitleTrack
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? mediaId = null,
    Object? language = null,
    Object? createdAt = null,
    Object? segments = null,
    Object? modelId = freezed,
  }) {
    return _then(_$SubtitleTrackImpl(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      mediaId: null == mediaId
          ? _value.mediaId
          : mediaId // ignore: cast_nullable_to_non_nullable
              as String,
      language: null == language
          ? _value.language
          : language // ignore: cast_nullable_to_non_nullable
              as String,
      createdAt: null == createdAt
          ? _value.createdAt
          : createdAt // ignore: cast_nullable_to_non_nullable
              as DateTime,
      segments: null == segments
          ? _value._segments
          : segments // ignore: cast_nullable_to_non_nullable
              as List<SubtitleSegment>,
      modelId: freezed == modelId
          ? _value.modelId
          : modelId // ignore: cast_nullable_to_non_nullable
              as String?,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$SubtitleTrackImpl extends _SubtitleTrack {
  const _$SubtitleTrackImpl(
      {required this.id,
      required this.mediaId,
      required this.language,
      @DateTimeConverter() required this.createdAt,
      required final List<SubtitleSegment> segments,
      this.modelId})
      : _segments = segments,
        super._();

  factory _$SubtitleTrackImpl.fromJson(Map<String, dynamic> json) =>
      _$$SubtitleTrackImplFromJson(json);

  /// Unique identifier for the subtitle track
  @override
  final String id;

  /// ID of the media file this subtitle belongs to
  @override
  final String mediaId;

  /// Language code (e.g., 'en', 'es')
  @override
  final String language;

  /// When the subtitles were generated
  @override
  @DateTimeConverter()
  final DateTime createdAt;

  /// Subtitle segments with timing
  final List<SubtitleSegment> _segments;

  /// Subtitle segments with timing
  @override
  List<SubtitleSegment> get segments {
    if (_segments is EqualUnmodifiableListView) return _segments;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_segments);
  }

  /// The ASR model used to generate the subtitles
  @override
  final String? modelId;

  @override
  String toString() {
    return 'SubtitleTrack(id: $id, mediaId: $mediaId, language: $language, createdAt: $createdAt, segments: $segments, modelId: $modelId)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$SubtitleTrackImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.mediaId, mediaId) || other.mediaId == mediaId) &&
            (identical(other.language, language) ||
                other.language == language) &&
            (identical(other.createdAt, createdAt) ||
                other.createdAt == createdAt) &&
            const DeepCollectionEquality().equals(other._segments, _segments) &&
            (identical(other.modelId, modelId) || other.modelId == modelId));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, id, mediaId, language, createdAt,
      const DeepCollectionEquality().hash(_segments), modelId);

  /// Create a copy of SubtitleTrack
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$SubtitleTrackImplCopyWith<_$SubtitleTrackImpl> get copyWith =>
      __$$SubtitleTrackImplCopyWithImpl<_$SubtitleTrackImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$SubtitleTrackImplToJson(
      this,
    );
  }
}

abstract class _SubtitleTrack extends SubtitleTrack {
  const factory _SubtitleTrack(
      {required final String id,
      required final String mediaId,
      required final String language,
      @DateTimeConverter() required final DateTime createdAt,
      required final List<SubtitleSegment> segments,
      final String? modelId}) = _$SubtitleTrackImpl;
  const _SubtitleTrack._() : super._();

  factory _SubtitleTrack.fromJson(Map<String, dynamic> json) =
      _$SubtitleTrackImpl.fromJson;

  /// Unique identifier for the subtitle track
  @override
  String get id;

  /// ID of the media file this subtitle belongs to
  @override
  String get mediaId;

  /// Language code (e.g., 'en', 'es')
  @override
  String get language;

  /// When the subtitles were generated
  @override
  @DateTimeConverter()
  DateTime get createdAt;

  /// Subtitle segments with timing
  @override
  List<SubtitleSegment> get segments;

  /// The ASR model used to generate the subtitles
  @override
  String? get modelId;

  /// Create a copy of SubtitleTrack
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$SubtitleTrackImplCopyWith<_$SubtitleTrackImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

SubtitleSegment _$SubtitleSegmentFromJson(Map<String, dynamic> json) {
  return _SubtitleSegment.fromJson(json);
}

/// @nodoc
mixin _$SubtitleSegment {
  /// Unique identifier
  String get id => throw _privateConstructorUsedError;

  /// Start time relative to media start
  @DurationConverter()
  Duration get startTime => throw _privateConstructorUsedError;

  /// End time relative to media start
  @DurationConverter()
  Duration get endTime => throw _privateConstructorUsedError;

  /// The subtitle text to display
  String get text => throw _privateConstructorUsedError;

  /// Serializes this SubtitleSegment to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of SubtitleSegment
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $SubtitleSegmentCopyWith<SubtitleSegment> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $SubtitleSegmentCopyWith<$Res> {
  factory $SubtitleSegmentCopyWith(
          SubtitleSegment value, $Res Function(SubtitleSegment) then) =
      _$SubtitleSegmentCopyWithImpl<$Res, SubtitleSegment>;
  @useResult
  $Res call(
      {String id,
      @DurationConverter() Duration startTime,
      @DurationConverter() Duration endTime,
      String text});
}

/// @nodoc
class _$SubtitleSegmentCopyWithImpl<$Res, $Val extends SubtitleSegment>
    implements $SubtitleSegmentCopyWith<$Res> {
  _$SubtitleSegmentCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of SubtitleSegment
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? startTime = null,
    Object? endTime = null,
    Object? text = null,
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
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$SubtitleSegmentImplCopyWith<$Res>
    implements $SubtitleSegmentCopyWith<$Res> {
  factory _$$SubtitleSegmentImplCopyWith(_$SubtitleSegmentImpl value,
          $Res Function(_$SubtitleSegmentImpl) then) =
      __$$SubtitleSegmentImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String id,
      @DurationConverter() Duration startTime,
      @DurationConverter() Duration endTime,
      String text});
}

/// @nodoc
class __$$SubtitleSegmentImplCopyWithImpl<$Res>
    extends _$SubtitleSegmentCopyWithImpl<$Res, _$SubtitleSegmentImpl>
    implements _$$SubtitleSegmentImplCopyWith<$Res> {
  __$$SubtitleSegmentImplCopyWithImpl(
      _$SubtitleSegmentImpl _value, $Res Function(_$SubtitleSegmentImpl) _then)
      : super(_value, _then);

  /// Create a copy of SubtitleSegment
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? startTime = null,
    Object? endTime = null,
    Object? text = null,
  }) {
    return _then(_$SubtitleSegmentImpl(
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
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$SubtitleSegmentImpl extends _SubtitleSegment {
  const _$SubtitleSegmentImpl(
      {required this.id,
      @DurationConverter() required this.startTime,
      @DurationConverter() required this.endTime,
      required this.text})
      : super._();

  factory _$SubtitleSegmentImpl.fromJson(Map<String, dynamic> json) =>
      _$$SubtitleSegmentImplFromJson(json);

  /// Unique identifier
  @override
  final String id;

  /// Start time relative to media start
  @override
  @DurationConverter()
  final Duration startTime;

  /// End time relative to media start
  @override
  @DurationConverter()
  final Duration endTime;

  /// The subtitle text to display
  @override
  final String text;

  @override
  String toString() {
    return 'SubtitleSegment(id: $id, startTime: $startTime, endTime: $endTime, text: $text)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$SubtitleSegmentImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.startTime, startTime) ||
                other.startTime == startTime) &&
            (identical(other.endTime, endTime) || other.endTime == endTime) &&
            (identical(other.text, text) || other.text == text));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, id, startTime, endTime, text);

  /// Create a copy of SubtitleSegment
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$SubtitleSegmentImplCopyWith<_$SubtitleSegmentImpl> get copyWith =>
      __$$SubtitleSegmentImplCopyWithImpl<_$SubtitleSegmentImpl>(
          this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$SubtitleSegmentImplToJson(
      this,
    );
  }
}

abstract class _SubtitleSegment extends SubtitleSegment {
  const factory _SubtitleSegment(
      {required final String id,
      @DurationConverter() required final Duration startTime,
      @DurationConverter() required final Duration endTime,
      required final String text}) = _$SubtitleSegmentImpl;
  const _SubtitleSegment._() : super._();

  factory _SubtitleSegment.fromJson(Map<String, dynamic> json) =
      _$SubtitleSegmentImpl.fromJson;

  /// Unique identifier
  @override
  String get id;

  /// Start time relative to media start
  @override
  @DurationConverter()
  Duration get startTime;

  /// End time relative to media start
  @override
  @DurationConverter()
  Duration get endTime;

  /// The subtitle text to display
  @override
  String get text;

  /// Create a copy of SubtitleSegment
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$SubtitleSegmentImplCopyWith<_$SubtitleSegmentImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
