// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'detection.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

Detection _$DetectionFromJson(Map<String, dynamic> json) {
  return _Detection.fromJson(json);
}

/// @nodoc
mixin _$Detection {
  /// Unique identifier for the detection
  String get id => throw _privateConstructorUsedError;

  /// ID of the media file this detection belongs to
  String get mediaId => throw _privateConstructorUsedError;

  /// Type of content detected
  ContentType get type => throw _privateConstructorUsedError;

  /// Start time of the detection in the media
  @DurationConverter()
  Duration get startTime => throw _privateConstructorUsedError;

  /// End time of the detection in the media
  @DurationConverter()
  Duration get endTime => throw _privateConstructorUsedError;

  /// Confidence score (0.0 to 1.0)
  double get confidence => throw _privateConstructorUsedError;

  /// Human-readable description of the detection
  String get description => throw _privateConstructorUsedError;

  /// User review status
  DetectionUserStatus get userStatus => throw _privateConstructorUsedError;

  /// Optional note from user
  String? get userNote => throw _privateConstructorUsedError;

  /// Original start time before user adjustment
  @DurationConverter()
  Duration? get originalStartTime => throw _privateConstructorUsedError;

  /// Original end time before user adjustment
  @DurationConverter()
  Duration? get originalEndTime => throw _privateConstructorUsedError;

  /// Source of the detection (e.g., 'asr', 'visual', 'manual')
  String? get source => throw _privateConstructorUsedError;

  /// Additional metadata
  Map<String, dynamic>? get metadata => throw _privateConstructorUsedError;

  /// Serializes this Detection to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of Detection
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $DetectionCopyWith<Detection> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $DetectionCopyWith<$Res> {
  factory $DetectionCopyWith(Detection value, $Res Function(Detection) then) =
      _$DetectionCopyWithImpl<$Res, Detection>;
  @useResult
  $Res call(
      {String id,
      String mediaId,
      ContentType type,
      @DurationConverter() Duration startTime,
      @DurationConverter() Duration endTime,
      double confidence,
      String description,
      DetectionUserStatus userStatus,
      String? userNote,
      @DurationConverter() Duration? originalStartTime,
      @DurationConverter() Duration? originalEndTime,
      String? source,
      Map<String, dynamic>? metadata});
}

/// @nodoc
class _$DetectionCopyWithImpl<$Res, $Val extends Detection>
    implements $DetectionCopyWith<$Res> {
  _$DetectionCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of Detection
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? mediaId = null,
    Object? type = null,
    Object? startTime = null,
    Object? endTime = null,
    Object? confidence = null,
    Object? description = null,
    Object? userStatus = null,
    Object? userNote = freezed,
    Object? originalStartTime = freezed,
    Object? originalEndTime = freezed,
    Object? source = freezed,
    Object? metadata = freezed,
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
      type: null == type
          ? _value.type
          : type // ignore: cast_nullable_to_non_nullable
              as ContentType,
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
      description: null == description
          ? _value.description
          : description // ignore: cast_nullable_to_non_nullable
              as String,
      userStatus: null == userStatus
          ? _value.userStatus
          : userStatus // ignore: cast_nullable_to_non_nullable
              as DetectionUserStatus,
      userNote: freezed == userNote
          ? _value.userNote
          : userNote // ignore: cast_nullable_to_non_nullable
              as String?,
      originalStartTime: freezed == originalStartTime
          ? _value.originalStartTime
          : originalStartTime // ignore: cast_nullable_to_non_nullable
              as Duration?,
      originalEndTime: freezed == originalEndTime
          ? _value.originalEndTime
          : originalEndTime // ignore: cast_nullable_to_non_nullable
              as Duration?,
      source: freezed == source
          ? _value.source
          : source // ignore: cast_nullable_to_non_nullable
              as String?,
      metadata: freezed == metadata
          ? _value.metadata
          : metadata // ignore: cast_nullable_to_non_nullable
              as Map<String, dynamic>?,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$DetectionImplCopyWith<$Res>
    implements $DetectionCopyWith<$Res> {
  factory _$$DetectionImplCopyWith(
          _$DetectionImpl value, $Res Function(_$DetectionImpl) then) =
      __$$DetectionImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String id,
      String mediaId,
      ContentType type,
      @DurationConverter() Duration startTime,
      @DurationConverter() Duration endTime,
      double confidence,
      String description,
      DetectionUserStatus userStatus,
      String? userNote,
      @DurationConverter() Duration? originalStartTime,
      @DurationConverter() Duration? originalEndTime,
      String? source,
      Map<String, dynamic>? metadata});
}

/// @nodoc
class __$$DetectionImplCopyWithImpl<$Res>
    extends _$DetectionCopyWithImpl<$Res, _$DetectionImpl>
    implements _$$DetectionImplCopyWith<$Res> {
  __$$DetectionImplCopyWithImpl(
      _$DetectionImpl _value, $Res Function(_$DetectionImpl) _then)
      : super(_value, _then);

  /// Create a copy of Detection
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? mediaId = null,
    Object? type = null,
    Object? startTime = null,
    Object? endTime = null,
    Object? confidence = null,
    Object? description = null,
    Object? userStatus = null,
    Object? userNote = freezed,
    Object? originalStartTime = freezed,
    Object? originalEndTime = freezed,
    Object? source = freezed,
    Object? metadata = freezed,
  }) {
    return _then(_$DetectionImpl(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      mediaId: null == mediaId
          ? _value.mediaId
          : mediaId // ignore: cast_nullable_to_non_nullable
              as String,
      type: null == type
          ? _value.type
          : type // ignore: cast_nullable_to_non_nullable
              as ContentType,
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
      description: null == description
          ? _value.description
          : description // ignore: cast_nullable_to_non_nullable
              as String,
      userStatus: null == userStatus
          ? _value.userStatus
          : userStatus // ignore: cast_nullable_to_non_nullable
              as DetectionUserStatus,
      userNote: freezed == userNote
          ? _value.userNote
          : userNote // ignore: cast_nullable_to_non_nullable
              as String?,
      originalStartTime: freezed == originalStartTime
          ? _value.originalStartTime
          : originalStartTime // ignore: cast_nullable_to_non_nullable
              as Duration?,
      originalEndTime: freezed == originalEndTime
          ? _value.originalEndTime
          : originalEndTime // ignore: cast_nullable_to_non_nullable
              as Duration?,
      source: freezed == source
          ? _value.source
          : source // ignore: cast_nullable_to_non_nullable
              as String?,
      metadata: freezed == metadata
          ? _value._metadata
          : metadata // ignore: cast_nullable_to_non_nullable
              as Map<String, dynamic>?,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$DetectionImpl extends _Detection {
  const _$DetectionImpl(
      {required this.id,
      required this.mediaId,
      required this.type,
      @DurationConverter() required this.startTime,
      @DurationConverter() required this.endTime,
      required this.confidence,
      required this.description,
      this.userStatus = DetectionUserStatus.pending,
      this.userNote,
      @DurationConverter() this.originalStartTime,
      @DurationConverter() this.originalEndTime,
      this.source,
      final Map<String, dynamic>? metadata})
      : _metadata = metadata,
        super._();

  factory _$DetectionImpl.fromJson(Map<String, dynamic> json) =>
      _$$DetectionImplFromJson(json);

  /// Unique identifier for the detection
  @override
  final String id;

  /// ID of the media file this detection belongs to
  @override
  final String mediaId;

  /// Type of content detected
  @override
  final ContentType type;

  /// Start time of the detection in the media
  @override
  @DurationConverter()
  final Duration startTime;

  /// End time of the detection in the media
  @override
  @DurationConverter()
  final Duration endTime;

  /// Confidence score (0.0 to 1.0)
  @override
  final double confidence;

  /// Human-readable description of the detection
  @override
  final String description;

  /// User review status
  @override
  @JsonKey()
  final DetectionUserStatus userStatus;

  /// Optional note from user
  @override
  final String? userNote;

  /// Original start time before user adjustment
  @override
  @DurationConverter()
  final Duration? originalStartTime;

  /// Original end time before user adjustment
  @override
  @DurationConverter()
  final Duration? originalEndTime;

  /// Source of the detection (e.g., 'asr', 'visual', 'manual')
  @override
  final String? source;

  /// Additional metadata
  final Map<String, dynamic>? _metadata;

  /// Additional metadata
  @override
  Map<String, dynamic>? get metadata {
    final value = _metadata;
    if (value == null) return null;
    if (_metadata is EqualUnmodifiableMapView) return _metadata;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableMapView(value);
  }

  @override
  String toString() {
    return 'Detection(id: $id, mediaId: $mediaId, type: $type, startTime: $startTime, endTime: $endTime, confidence: $confidence, description: $description, userStatus: $userStatus, userNote: $userNote, originalStartTime: $originalStartTime, originalEndTime: $originalEndTime, source: $source, metadata: $metadata)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$DetectionImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.mediaId, mediaId) || other.mediaId == mediaId) &&
            (identical(other.type, type) || other.type == type) &&
            (identical(other.startTime, startTime) ||
                other.startTime == startTime) &&
            (identical(other.endTime, endTime) || other.endTime == endTime) &&
            (identical(other.confidence, confidence) ||
                other.confidence == confidence) &&
            (identical(other.description, description) ||
                other.description == description) &&
            (identical(other.userStatus, userStatus) ||
                other.userStatus == userStatus) &&
            (identical(other.userNote, userNote) ||
                other.userNote == userNote) &&
            (identical(other.originalStartTime, originalStartTime) ||
                other.originalStartTime == originalStartTime) &&
            (identical(other.originalEndTime, originalEndTime) ||
                other.originalEndTime == originalEndTime) &&
            (identical(other.source, source) || other.source == source) &&
            const DeepCollectionEquality().equals(other._metadata, _metadata));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
      runtimeType,
      id,
      mediaId,
      type,
      startTime,
      endTime,
      confidence,
      description,
      userStatus,
      userNote,
      originalStartTime,
      originalEndTime,
      source,
      const DeepCollectionEquality().hash(_metadata));

  /// Create a copy of Detection
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$DetectionImplCopyWith<_$DetectionImpl> get copyWith =>
      __$$DetectionImplCopyWithImpl<_$DetectionImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$DetectionImplToJson(
      this,
    );
  }
}

abstract class _Detection extends Detection {
  const factory _Detection(
      {required final String id,
      required final String mediaId,
      required final ContentType type,
      @DurationConverter() required final Duration startTime,
      @DurationConverter() required final Duration endTime,
      required final double confidence,
      required final String description,
      final DetectionUserStatus userStatus,
      final String? userNote,
      @DurationConverter() final Duration? originalStartTime,
      @DurationConverter() final Duration? originalEndTime,
      final String? source,
      final Map<String, dynamic>? metadata}) = _$DetectionImpl;
  const _Detection._() : super._();

  factory _Detection.fromJson(Map<String, dynamic> json) =
      _$DetectionImpl.fromJson;

  /// Unique identifier for the detection
  @override
  String get id;

  /// ID of the media file this detection belongs to
  @override
  String get mediaId;

  /// Type of content detected
  @override
  ContentType get type;

  /// Start time of the detection in the media
  @override
  @DurationConverter()
  Duration get startTime;

  /// End time of the detection in the media
  @override
  @DurationConverter()
  Duration get endTime;

  /// Confidence score (0.0 to 1.0)
  @override
  double get confidence;

  /// Human-readable description of the detection
  @override
  String get description;

  /// User review status
  @override
  DetectionUserStatus get userStatus;

  /// Optional note from user
  @override
  String? get userNote;

  /// Original start time before user adjustment
  @override
  @DurationConverter()
  Duration? get originalStartTime;

  /// Original end time before user adjustment
  @override
  @DurationConverter()
  Duration? get originalEndTime;

  /// Source of the detection (e.g., 'asr', 'visual', 'manual')
  @override
  String? get source;

  /// Additional metadata
  @override
  Map<String, dynamic>? get metadata;

  /// Create a copy of Detection
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$DetectionImplCopyWith<_$DetectionImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
