// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'timeline.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

TimelineSegment _$TimelineSegmentFromJson(Map<String, dynamic> json) {
  return _TimelineSegment.fromJson(json);
}

/// @nodoc
mixin _$TimelineSegment {
  /// Unique identifier for the segment
  String get id => throw _privateConstructorUsedError;

  /// Start time of the segment
  @DurationConverter()
  Duration get start => throw _privateConstructorUsedError;

  /// End time of the segment
  @DurationConverter()
  Duration get end => throw _privateConstructorUsedError;

  /// Type of content in this segment
  ContentType get type => throw _privateConstructorUsedError;

  /// Confidence score (0.0 to 1.0)
  double get confidence => throw _privateConstructorUsedError;

  /// Optional modification to apply to this segment
  Modification? get modification => throw _privateConstructorUsedError;

  /// Whether this segment is selected in the UI
  bool get isSelected => throw _privateConstructorUsedError;

  /// Whether this segment is locked from editing
  bool get isLocked => throw _privateConstructorUsedError;

  /// Reference to the original detection ID if applicable
  String? get detectionId => throw _privateConstructorUsedError;

  /// Serializes this TimelineSegment to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of TimelineSegment
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $TimelineSegmentCopyWith<TimelineSegment> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $TimelineSegmentCopyWith<$Res> {
  factory $TimelineSegmentCopyWith(
          TimelineSegment value, $Res Function(TimelineSegment) then) =
      _$TimelineSegmentCopyWithImpl<$Res, TimelineSegment>;
  @useResult
  $Res call(
      {String id,
      @DurationConverter() Duration start,
      @DurationConverter() Duration end,
      ContentType type,
      double confidence,
      Modification? modification,
      bool isSelected,
      bool isLocked,
      String? detectionId});

  $ModificationCopyWith<$Res>? get modification;
}

/// @nodoc
class _$TimelineSegmentCopyWithImpl<$Res, $Val extends TimelineSegment>
    implements $TimelineSegmentCopyWith<$Res> {
  _$TimelineSegmentCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of TimelineSegment
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? start = null,
    Object? end = null,
    Object? type = null,
    Object? confidence = null,
    Object? modification = freezed,
    Object? isSelected = null,
    Object? isLocked = null,
    Object? detectionId = freezed,
  }) {
    return _then(_value.copyWith(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      start: null == start
          ? _value.start
          : start // ignore: cast_nullable_to_non_nullable
              as Duration,
      end: null == end
          ? _value.end
          : end // ignore: cast_nullable_to_non_nullable
              as Duration,
      type: null == type
          ? _value.type
          : type // ignore: cast_nullable_to_non_nullable
              as ContentType,
      confidence: null == confidence
          ? _value.confidence
          : confidence // ignore: cast_nullable_to_non_nullable
              as double,
      modification: freezed == modification
          ? _value.modification
          : modification // ignore: cast_nullable_to_non_nullable
              as Modification?,
      isSelected: null == isSelected
          ? _value.isSelected
          : isSelected // ignore: cast_nullable_to_non_nullable
              as bool,
      isLocked: null == isLocked
          ? _value.isLocked
          : isLocked // ignore: cast_nullable_to_non_nullable
              as bool,
      detectionId: freezed == detectionId
          ? _value.detectionId
          : detectionId // ignore: cast_nullable_to_non_nullable
              as String?,
    ) as $Val);
  }

  /// Create a copy of TimelineSegment
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $ModificationCopyWith<$Res>? get modification {
    if (_value.modification == null) {
      return null;
    }

    return $ModificationCopyWith<$Res>(_value.modification!, (value) {
      return _then(_value.copyWith(modification: value) as $Val);
    });
  }
}

/// @nodoc
abstract class _$$TimelineSegmentImplCopyWith<$Res>
    implements $TimelineSegmentCopyWith<$Res> {
  factory _$$TimelineSegmentImplCopyWith(_$TimelineSegmentImpl value,
          $Res Function(_$TimelineSegmentImpl) then) =
      __$$TimelineSegmentImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String id,
      @DurationConverter() Duration start,
      @DurationConverter() Duration end,
      ContentType type,
      double confidence,
      Modification? modification,
      bool isSelected,
      bool isLocked,
      String? detectionId});

  @override
  $ModificationCopyWith<$Res>? get modification;
}

/// @nodoc
class __$$TimelineSegmentImplCopyWithImpl<$Res>
    extends _$TimelineSegmentCopyWithImpl<$Res, _$TimelineSegmentImpl>
    implements _$$TimelineSegmentImplCopyWith<$Res> {
  __$$TimelineSegmentImplCopyWithImpl(
      _$TimelineSegmentImpl _value, $Res Function(_$TimelineSegmentImpl) _then)
      : super(_value, _then);

  /// Create a copy of TimelineSegment
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? start = null,
    Object? end = null,
    Object? type = null,
    Object? confidence = null,
    Object? modification = freezed,
    Object? isSelected = null,
    Object? isLocked = null,
    Object? detectionId = freezed,
  }) {
    return _then(_$TimelineSegmentImpl(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      start: null == start
          ? _value.start
          : start // ignore: cast_nullable_to_non_nullable
              as Duration,
      end: null == end
          ? _value.end
          : end // ignore: cast_nullable_to_non_nullable
              as Duration,
      type: null == type
          ? _value.type
          : type // ignore: cast_nullable_to_non_nullable
              as ContentType,
      confidence: null == confidence
          ? _value.confidence
          : confidence // ignore: cast_nullable_to_non_nullable
              as double,
      modification: freezed == modification
          ? _value.modification
          : modification // ignore: cast_nullable_to_non_nullable
              as Modification?,
      isSelected: null == isSelected
          ? _value.isSelected
          : isSelected // ignore: cast_nullable_to_non_nullable
              as bool,
      isLocked: null == isLocked
          ? _value.isLocked
          : isLocked // ignore: cast_nullable_to_non_nullable
              as bool,
      detectionId: freezed == detectionId
          ? _value.detectionId
          : detectionId // ignore: cast_nullable_to_non_nullable
              as String?,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$TimelineSegmentImpl extends _TimelineSegment {
  const _$TimelineSegmentImpl(
      {required this.id,
      @DurationConverter() required this.start,
      @DurationConverter() required this.end,
      required this.type,
      required this.confidence,
      this.modification,
      this.isSelected = false,
      this.isLocked = false,
      this.detectionId})
      : super._();

  factory _$TimelineSegmentImpl.fromJson(Map<String, dynamic> json) =>
      _$$TimelineSegmentImplFromJson(json);

  /// Unique identifier for the segment
  @override
  final String id;

  /// Start time of the segment
  @override
  @DurationConverter()
  final Duration start;

  /// End time of the segment
  @override
  @DurationConverter()
  final Duration end;

  /// Type of content in this segment
  @override
  final ContentType type;

  /// Confidence score (0.0 to 1.0)
  @override
  final double confidence;

  /// Optional modification to apply to this segment
  @override
  final Modification? modification;

  /// Whether this segment is selected in the UI
  @override
  @JsonKey()
  final bool isSelected;

  /// Whether this segment is locked from editing
  @override
  @JsonKey()
  final bool isLocked;

  /// Reference to the original detection ID if applicable
  @override
  final String? detectionId;

  @override
  String toString() {
    return 'TimelineSegment(id: $id, start: $start, end: $end, type: $type, confidence: $confidence, modification: $modification, isSelected: $isSelected, isLocked: $isLocked, detectionId: $detectionId)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$TimelineSegmentImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.start, start) || other.start == start) &&
            (identical(other.end, end) || other.end == end) &&
            (identical(other.type, type) || other.type == type) &&
            (identical(other.confidence, confidence) ||
                other.confidence == confidence) &&
            (identical(other.modification, modification) ||
                other.modification == modification) &&
            (identical(other.isSelected, isSelected) ||
                other.isSelected == isSelected) &&
            (identical(other.isLocked, isLocked) ||
                other.isLocked == isLocked) &&
            (identical(other.detectionId, detectionId) ||
                other.detectionId == detectionId));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, id, start, end, type, confidence,
      modification, isSelected, isLocked, detectionId);

  /// Create a copy of TimelineSegment
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$TimelineSegmentImplCopyWith<_$TimelineSegmentImpl> get copyWith =>
      __$$TimelineSegmentImplCopyWithImpl<_$TimelineSegmentImpl>(
          this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$TimelineSegmentImplToJson(
      this,
    );
  }
}

abstract class _TimelineSegment extends TimelineSegment {
  const factory _TimelineSegment(
      {required final String id,
      @DurationConverter() required final Duration start,
      @DurationConverter() required final Duration end,
      required final ContentType type,
      required final double confidence,
      final Modification? modification,
      final bool isSelected,
      final bool isLocked,
      final String? detectionId}) = _$TimelineSegmentImpl;
  const _TimelineSegment._() : super._();

  factory _TimelineSegment.fromJson(Map<String, dynamic> json) =
      _$TimelineSegmentImpl.fromJson;

  /// Unique identifier for the segment
  @override
  String get id;

  /// Start time of the segment
  @override
  @DurationConverter()
  Duration get start;

  /// End time of the segment
  @override
  @DurationConverter()
  Duration get end;

  /// Type of content in this segment
  @override
  ContentType get type;

  /// Confidence score (0.0 to 1.0)
  @override
  double get confidence;

  /// Optional modification to apply to this segment
  @override
  Modification? get modification;

  /// Whether this segment is selected in the UI
  @override
  bool get isSelected;

  /// Whether this segment is locked from editing
  @override
  bool get isLocked;

  /// Reference to the original detection ID if applicable
  @override
  String? get detectionId;

  /// Create a copy of TimelineSegment
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$TimelineSegmentImplCopyWith<_$TimelineSegmentImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

TimelineTrack _$TimelineTrackFromJson(Map<String, dynamic> json) {
  return _TimelineTrack.fromJson(json);
}

/// @nodoc
mixin _$TimelineTrack {
  /// Unique identifier for the track
  String get id => throw _privateConstructorUsedError;

  /// Type of track
  TrackType get type => throw _privateConstructorUsedError;

  /// Display name of the track
  String get name => throw _privateConstructorUsedError;

  /// Segments on this track
  List<TimelineSegment> get segments => throw _privateConstructorUsedError;

  /// Whether this track is visible
  bool get isVisible => throw _privateConstructorUsedError;

  /// Whether this track is muted (for audio/video tracks)
  bool get isMuted => throw _privateConstructorUsedError;

  /// Whether this track is locked from editing
  bool get isLocked => throw _privateConstructorUsedError;

  /// Track height in pixels (for UI)
  int get height => throw _privateConstructorUsedError;

  /// Track color in hex format
  String? get color => throw _privateConstructorUsedError;

  /// Serializes this TimelineTrack to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of TimelineTrack
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $TimelineTrackCopyWith<TimelineTrack> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $TimelineTrackCopyWith<$Res> {
  factory $TimelineTrackCopyWith(
          TimelineTrack value, $Res Function(TimelineTrack) then) =
      _$TimelineTrackCopyWithImpl<$Res, TimelineTrack>;
  @useResult
  $Res call(
      {String id,
      TrackType type,
      String name,
      List<TimelineSegment> segments,
      bool isVisible,
      bool isMuted,
      bool isLocked,
      int height,
      String? color});
}

/// @nodoc
class _$TimelineTrackCopyWithImpl<$Res, $Val extends TimelineTrack>
    implements $TimelineTrackCopyWith<$Res> {
  _$TimelineTrackCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of TimelineTrack
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? type = null,
    Object? name = null,
    Object? segments = null,
    Object? isVisible = null,
    Object? isMuted = null,
    Object? isLocked = null,
    Object? height = null,
    Object? color = freezed,
  }) {
    return _then(_value.copyWith(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      type: null == type
          ? _value.type
          : type // ignore: cast_nullable_to_non_nullable
              as TrackType,
      name: null == name
          ? _value.name
          : name // ignore: cast_nullable_to_non_nullable
              as String,
      segments: null == segments
          ? _value.segments
          : segments // ignore: cast_nullable_to_non_nullable
              as List<TimelineSegment>,
      isVisible: null == isVisible
          ? _value.isVisible
          : isVisible // ignore: cast_nullable_to_non_nullable
              as bool,
      isMuted: null == isMuted
          ? _value.isMuted
          : isMuted // ignore: cast_nullable_to_non_nullable
              as bool,
      isLocked: null == isLocked
          ? _value.isLocked
          : isLocked // ignore: cast_nullable_to_non_nullable
              as bool,
      height: null == height
          ? _value.height
          : height // ignore: cast_nullable_to_non_nullable
              as int,
      color: freezed == color
          ? _value.color
          : color // ignore: cast_nullable_to_non_nullable
              as String?,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$TimelineTrackImplCopyWith<$Res>
    implements $TimelineTrackCopyWith<$Res> {
  factory _$$TimelineTrackImplCopyWith(
          _$TimelineTrackImpl value, $Res Function(_$TimelineTrackImpl) then) =
      __$$TimelineTrackImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String id,
      TrackType type,
      String name,
      List<TimelineSegment> segments,
      bool isVisible,
      bool isMuted,
      bool isLocked,
      int height,
      String? color});
}

/// @nodoc
class __$$TimelineTrackImplCopyWithImpl<$Res>
    extends _$TimelineTrackCopyWithImpl<$Res, _$TimelineTrackImpl>
    implements _$$TimelineTrackImplCopyWith<$Res> {
  __$$TimelineTrackImplCopyWithImpl(
      _$TimelineTrackImpl _value, $Res Function(_$TimelineTrackImpl) _then)
      : super(_value, _then);

  /// Create a copy of TimelineTrack
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? type = null,
    Object? name = null,
    Object? segments = null,
    Object? isVisible = null,
    Object? isMuted = null,
    Object? isLocked = null,
    Object? height = null,
    Object? color = freezed,
  }) {
    return _then(_$TimelineTrackImpl(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      type: null == type
          ? _value.type
          : type // ignore: cast_nullable_to_non_nullable
              as TrackType,
      name: null == name
          ? _value.name
          : name // ignore: cast_nullable_to_non_nullable
              as String,
      segments: null == segments
          ? _value._segments
          : segments // ignore: cast_nullable_to_non_nullable
              as List<TimelineSegment>,
      isVisible: null == isVisible
          ? _value.isVisible
          : isVisible // ignore: cast_nullable_to_non_nullable
              as bool,
      isMuted: null == isMuted
          ? _value.isMuted
          : isMuted // ignore: cast_nullable_to_non_nullable
              as bool,
      isLocked: null == isLocked
          ? _value.isLocked
          : isLocked // ignore: cast_nullable_to_non_nullable
              as bool,
      height: null == height
          ? _value.height
          : height // ignore: cast_nullable_to_non_nullable
              as int,
      color: freezed == color
          ? _value.color
          : color // ignore: cast_nullable_to_non_nullable
              as String?,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$TimelineTrackImpl extends _TimelineTrack {
  const _$TimelineTrackImpl(
      {required this.id,
      required this.type,
      required this.name,
      required final List<TimelineSegment> segments,
      this.isVisible = true,
      this.isMuted = false,
      this.isLocked = false,
      this.height = 40,
      this.color})
      : _segments = segments,
        super._();

  factory _$TimelineTrackImpl.fromJson(Map<String, dynamic> json) =>
      _$$TimelineTrackImplFromJson(json);

  /// Unique identifier for the track
  @override
  final String id;

  /// Type of track
  @override
  final TrackType type;

  /// Display name of the track
  @override
  final String name;

  /// Segments on this track
  final List<TimelineSegment> _segments;

  /// Segments on this track
  @override
  List<TimelineSegment> get segments {
    if (_segments is EqualUnmodifiableListView) return _segments;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_segments);
  }

  /// Whether this track is visible
  @override
  @JsonKey()
  final bool isVisible;

  /// Whether this track is muted (for audio/video tracks)
  @override
  @JsonKey()
  final bool isMuted;

  /// Whether this track is locked from editing
  @override
  @JsonKey()
  final bool isLocked;

  /// Track height in pixels (for UI)
  @override
  @JsonKey()
  final int height;

  /// Track color in hex format
  @override
  final String? color;

  @override
  String toString() {
    return 'TimelineTrack(id: $id, type: $type, name: $name, segments: $segments, isVisible: $isVisible, isMuted: $isMuted, isLocked: $isLocked, height: $height, color: $color)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$TimelineTrackImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.type, type) || other.type == type) &&
            (identical(other.name, name) || other.name == name) &&
            const DeepCollectionEquality().equals(other._segments, _segments) &&
            (identical(other.isVisible, isVisible) ||
                other.isVisible == isVisible) &&
            (identical(other.isMuted, isMuted) || other.isMuted == isMuted) &&
            (identical(other.isLocked, isLocked) ||
                other.isLocked == isLocked) &&
            (identical(other.height, height) || other.height == height) &&
            (identical(other.color, color) || other.color == color));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
      runtimeType,
      id,
      type,
      name,
      const DeepCollectionEquality().hash(_segments),
      isVisible,
      isMuted,
      isLocked,
      height,
      color);

  /// Create a copy of TimelineTrack
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$TimelineTrackImplCopyWith<_$TimelineTrackImpl> get copyWith =>
      __$$TimelineTrackImplCopyWithImpl<_$TimelineTrackImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$TimelineTrackImplToJson(
      this,
    );
  }
}

abstract class _TimelineTrack extends TimelineTrack {
  const factory _TimelineTrack(
      {required final String id,
      required final TrackType type,
      required final String name,
      required final List<TimelineSegment> segments,
      final bool isVisible,
      final bool isMuted,
      final bool isLocked,
      final int height,
      final String? color}) = _$TimelineTrackImpl;
  const _TimelineTrack._() : super._();

  factory _TimelineTrack.fromJson(Map<String, dynamic> json) =
      _$TimelineTrackImpl.fromJson;

  /// Unique identifier for the track
  @override
  String get id;

  /// Type of track
  @override
  TrackType get type;

  /// Display name of the track
  @override
  String get name;

  /// Segments on this track
  @override
  List<TimelineSegment> get segments;

  /// Whether this track is visible
  @override
  bool get isVisible;

  /// Whether this track is muted (for audio/video tracks)
  @override
  bool get isMuted;

  /// Whether this track is locked from editing
  @override
  bool get isLocked;

  /// Track height in pixels (for UI)
  @override
  int get height;

  /// Track color in hex format
  @override
  String? get color;

  /// Create a copy of TimelineTrack
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$TimelineTrackImplCopyWith<_$TimelineTrackImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

TimelineConflict _$TimelineConflictFromJson(Map<String, dynamic> json) {
  return _TimelineConflict.fromJson(json);
}

/// @nodoc
mixin _$TimelineConflict {
  /// First conflicting segment
  TimelineSegment get segment1 => throw _privateConstructorUsedError;

  /// Second conflicting segment
  TimelineSegment get segment2 => throw _privateConstructorUsedError;

  /// Type of conflict
  ConflictType get conflictType => throw _privateConstructorUsedError;

  /// Description of the conflict
  String get description => throw _privateConstructorUsedError;

  /// Serializes this TimelineConflict to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of TimelineConflict
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $TimelineConflictCopyWith<TimelineConflict> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $TimelineConflictCopyWith<$Res> {
  factory $TimelineConflictCopyWith(
          TimelineConflict value, $Res Function(TimelineConflict) then) =
      _$TimelineConflictCopyWithImpl<$Res, TimelineConflict>;
  @useResult
  $Res call(
      {TimelineSegment segment1,
      TimelineSegment segment2,
      ConflictType conflictType,
      String description});

  $TimelineSegmentCopyWith<$Res> get segment1;
  $TimelineSegmentCopyWith<$Res> get segment2;
}

/// @nodoc
class _$TimelineConflictCopyWithImpl<$Res, $Val extends TimelineConflict>
    implements $TimelineConflictCopyWith<$Res> {
  _$TimelineConflictCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of TimelineConflict
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? segment1 = null,
    Object? segment2 = null,
    Object? conflictType = null,
    Object? description = null,
  }) {
    return _then(_value.copyWith(
      segment1: null == segment1
          ? _value.segment1
          : segment1 // ignore: cast_nullable_to_non_nullable
              as TimelineSegment,
      segment2: null == segment2
          ? _value.segment2
          : segment2 // ignore: cast_nullable_to_non_nullable
              as TimelineSegment,
      conflictType: null == conflictType
          ? _value.conflictType
          : conflictType // ignore: cast_nullable_to_non_nullable
              as ConflictType,
      description: null == description
          ? _value.description
          : description // ignore: cast_nullable_to_non_nullable
              as String,
    ) as $Val);
  }

  /// Create a copy of TimelineConflict
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $TimelineSegmentCopyWith<$Res> get segment1 {
    return $TimelineSegmentCopyWith<$Res>(_value.segment1, (value) {
      return _then(_value.copyWith(segment1: value) as $Val);
    });
  }

  /// Create a copy of TimelineConflict
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $TimelineSegmentCopyWith<$Res> get segment2 {
    return $TimelineSegmentCopyWith<$Res>(_value.segment2, (value) {
      return _then(_value.copyWith(segment2: value) as $Val);
    });
  }
}

/// @nodoc
abstract class _$$TimelineConflictImplCopyWith<$Res>
    implements $TimelineConflictCopyWith<$Res> {
  factory _$$TimelineConflictImplCopyWith(_$TimelineConflictImpl value,
          $Res Function(_$TimelineConflictImpl) then) =
      __$$TimelineConflictImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {TimelineSegment segment1,
      TimelineSegment segment2,
      ConflictType conflictType,
      String description});

  @override
  $TimelineSegmentCopyWith<$Res> get segment1;
  @override
  $TimelineSegmentCopyWith<$Res> get segment2;
}

/// @nodoc
class __$$TimelineConflictImplCopyWithImpl<$Res>
    extends _$TimelineConflictCopyWithImpl<$Res, _$TimelineConflictImpl>
    implements _$$TimelineConflictImplCopyWith<$Res> {
  __$$TimelineConflictImplCopyWithImpl(_$TimelineConflictImpl _value,
      $Res Function(_$TimelineConflictImpl) _then)
      : super(_value, _then);

  /// Create a copy of TimelineConflict
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? segment1 = null,
    Object? segment2 = null,
    Object? conflictType = null,
    Object? description = null,
  }) {
    return _then(_$TimelineConflictImpl(
      segment1: null == segment1
          ? _value.segment1
          : segment1 // ignore: cast_nullable_to_non_nullable
              as TimelineSegment,
      segment2: null == segment2
          ? _value.segment2
          : segment2 // ignore: cast_nullable_to_non_nullable
              as TimelineSegment,
      conflictType: null == conflictType
          ? _value.conflictType
          : conflictType // ignore: cast_nullable_to_non_nullable
              as ConflictType,
      description: null == description
          ? _value.description
          : description // ignore: cast_nullable_to_non_nullable
              as String,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$TimelineConflictImpl implements _TimelineConflict {
  const _$TimelineConflictImpl(
      {required this.segment1,
      required this.segment2,
      required this.conflictType,
      required this.description});

  factory _$TimelineConflictImpl.fromJson(Map<String, dynamic> json) =>
      _$$TimelineConflictImplFromJson(json);

  /// First conflicting segment
  @override
  final TimelineSegment segment1;

  /// Second conflicting segment
  @override
  final TimelineSegment segment2;

  /// Type of conflict
  @override
  final ConflictType conflictType;

  /// Description of the conflict
  @override
  final String description;

  @override
  String toString() {
    return 'TimelineConflict(segment1: $segment1, segment2: $segment2, conflictType: $conflictType, description: $description)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$TimelineConflictImpl &&
            (identical(other.segment1, segment1) ||
                other.segment1 == segment1) &&
            (identical(other.segment2, segment2) ||
                other.segment2 == segment2) &&
            (identical(other.conflictType, conflictType) ||
                other.conflictType == conflictType) &&
            (identical(other.description, description) ||
                other.description == description));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode =>
      Object.hash(runtimeType, segment1, segment2, conflictType, description);

  /// Create a copy of TimelineConflict
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$TimelineConflictImplCopyWith<_$TimelineConflictImpl> get copyWith =>
      __$$TimelineConflictImplCopyWithImpl<_$TimelineConflictImpl>(
          this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$TimelineConflictImplToJson(
      this,
    );
  }
}

abstract class _TimelineConflict implements TimelineConflict {
  const factory _TimelineConflict(
      {required final TimelineSegment segment1,
      required final TimelineSegment segment2,
      required final ConflictType conflictType,
      required final String description}) = _$TimelineConflictImpl;

  factory _TimelineConflict.fromJson(Map<String, dynamic> json) =
      _$TimelineConflictImpl.fromJson;

  /// First conflicting segment
  @override
  TimelineSegment get segment1;

  /// Second conflicting segment
  @override
  TimelineSegment get segment2;

  /// Type of conflict
  @override
  ConflictType get conflictType;

  /// Description of the conflict
  @override
  String get description;

  /// Create a copy of TimelineConflict
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$TimelineConflictImplCopyWith<_$TimelineConflictImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

UnifiedTimeline _$UnifiedTimelineFromJson(Map<String, dynamic> json) {
  return _UnifiedTimeline.fromJson(json);
}

/// @nodoc
mixin _$UnifiedTimeline {
  /// Unique identifier for the timeline
  String get id => throw _privateConstructorUsedError;

  /// Total duration of the media
  @DurationConverter()
  Duration get mediaDuration => throw _privateConstructorUsedError;

  /// All tracks in the timeline
  List<TimelineTrack> get tracks => throw _privateConstructorUsedError;

  /// Timestamp when timeline was created
  DateTime? get createdAt => throw _privateConstructorUsedError;

  /// Timestamp when timeline was last modified
  DateTime? get modifiedAt => throw _privateConstructorUsedError;

  /// Serializes this UnifiedTimeline to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of UnifiedTimeline
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $UnifiedTimelineCopyWith<UnifiedTimeline> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $UnifiedTimelineCopyWith<$Res> {
  factory $UnifiedTimelineCopyWith(
          UnifiedTimeline value, $Res Function(UnifiedTimeline) then) =
      _$UnifiedTimelineCopyWithImpl<$Res, UnifiedTimeline>;
  @useResult
  $Res call(
      {String id,
      @DurationConverter() Duration mediaDuration,
      List<TimelineTrack> tracks,
      DateTime? createdAt,
      DateTime? modifiedAt});
}

/// @nodoc
class _$UnifiedTimelineCopyWithImpl<$Res, $Val extends UnifiedTimeline>
    implements $UnifiedTimelineCopyWith<$Res> {
  _$UnifiedTimelineCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of UnifiedTimeline
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? mediaDuration = null,
    Object? tracks = null,
    Object? createdAt = freezed,
    Object? modifiedAt = freezed,
  }) {
    return _then(_value.copyWith(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      mediaDuration: null == mediaDuration
          ? _value.mediaDuration
          : mediaDuration // ignore: cast_nullable_to_non_nullable
              as Duration,
      tracks: null == tracks
          ? _value.tracks
          : tracks // ignore: cast_nullable_to_non_nullable
              as List<TimelineTrack>,
      createdAt: freezed == createdAt
          ? _value.createdAt
          : createdAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      modifiedAt: freezed == modifiedAt
          ? _value.modifiedAt
          : modifiedAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$UnifiedTimelineImplCopyWith<$Res>
    implements $UnifiedTimelineCopyWith<$Res> {
  factory _$$UnifiedTimelineImplCopyWith(_$UnifiedTimelineImpl value,
          $Res Function(_$UnifiedTimelineImpl) then) =
      __$$UnifiedTimelineImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String id,
      @DurationConverter() Duration mediaDuration,
      List<TimelineTrack> tracks,
      DateTime? createdAt,
      DateTime? modifiedAt});
}

/// @nodoc
class __$$UnifiedTimelineImplCopyWithImpl<$Res>
    extends _$UnifiedTimelineCopyWithImpl<$Res, _$UnifiedTimelineImpl>
    implements _$$UnifiedTimelineImplCopyWith<$Res> {
  __$$UnifiedTimelineImplCopyWithImpl(
      _$UnifiedTimelineImpl _value, $Res Function(_$UnifiedTimelineImpl) _then)
      : super(_value, _then);

  /// Create a copy of UnifiedTimeline
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? mediaDuration = null,
    Object? tracks = null,
    Object? createdAt = freezed,
    Object? modifiedAt = freezed,
  }) {
    return _then(_$UnifiedTimelineImpl(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      mediaDuration: null == mediaDuration
          ? _value.mediaDuration
          : mediaDuration // ignore: cast_nullable_to_non_nullable
              as Duration,
      tracks: null == tracks
          ? _value._tracks
          : tracks // ignore: cast_nullable_to_non_nullable
              as List<TimelineTrack>,
      createdAt: freezed == createdAt
          ? _value.createdAt
          : createdAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      modifiedAt: freezed == modifiedAt
          ? _value.modifiedAt
          : modifiedAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$UnifiedTimelineImpl extends _UnifiedTimeline {
  const _$UnifiedTimelineImpl(
      {required this.id,
      @DurationConverter() required this.mediaDuration,
      required final List<TimelineTrack> tracks,
      this.createdAt,
      this.modifiedAt})
      : _tracks = tracks,
        super._();

  factory _$UnifiedTimelineImpl.fromJson(Map<String, dynamic> json) =>
      _$$UnifiedTimelineImplFromJson(json);

  /// Unique identifier for the timeline
  @override
  final String id;

  /// Total duration of the media
  @override
  @DurationConverter()
  final Duration mediaDuration;

  /// All tracks in the timeline
  final List<TimelineTrack> _tracks;

  /// All tracks in the timeline
  @override
  List<TimelineTrack> get tracks {
    if (_tracks is EqualUnmodifiableListView) return _tracks;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_tracks);
  }

  /// Timestamp when timeline was created
  @override
  final DateTime? createdAt;

  /// Timestamp when timeline was last modified
  @override
  final DateTime? modifiedAt;

  @override
  String toString() {
    return 'UnifiedTimeline(id: $id, mediaDuration: $mediaDuration, tracks: $tracks, createdAt: $createdAt, modifiedAt: $modifiedAt)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$UnifiedTimelineImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.mediaDuration, mediaDuration) ||
                other.mediaDuration == mediaDuration) &&
            const DeepCollectionEquality().equals(other._tracks, _tracks) &&
            (identical(other.createdAt, createdAt) ||
                other.createdAt == createdAt) &&
            (identical(other.modifiedAt, modifiedAt) ||
                other.modifiedAt == modifiedAt));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, id, mediaDuration,
      const DeepCollectionEquality().hash(_tracks), createdAt, modifiedAt);

  /// Create a copy of UnifiedTimeline
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$UnifiedTimelineImplCopyWith<_$UnifiedTimelineImpl> get copyWith =>
      __$$UnifiedTimelineImplCopyWithImpl<_$UnifiedTimelineImpl>(
          this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$UnifiedTimelineImplToJson(
      this,
    );
  }
}

abstract class _UnifiedTimeline extends UnifiedTimeline {
  const factory _UnifiedTimeline(
      {required final String id,
      @DurationConverter() required final Duration mediaDuration,
      required final List<TimelineTrack> tracks,
      final DateTime? createdAt,
      final DateTime? modifiedAt}) = _$UnifiedTimelineImpl;
  const _UnifiedTimeline._() : super._();

  factory _UnifiedTimeline.fromJson(Map<String, dynamic> json) =
      _$UnifiedTimelineImpl.fromJson;

  /// Unique identifier for the timeline
  @override
  String get id;

  /// Total duration of the media
  @override
  @DurationConverter()
  Duration get mediaDuration;

  /// All tracks in the timeline
  @override
  List<TimelineTrack> get tracks;

  /// Timestamp when timeline was created
  @override
  DateTime? get createdAt;

  /// Timestamp when timeline was last modified
  @override
  DateTime? get modifiedAt;

  /// Create a copy of UnifiedTimeline
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$UnifiedTimelineImplCopyWith<_$UnifiedTimelineImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
