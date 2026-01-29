// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'frame_data.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

FrameData _$FrameDataFromJson(Map<String, dynamic> json) {
  return _FrameData.fromJson(json);
}

/// @nodoc
mixin _$FrameData {
  /// Timestamp of the frame relative to video start
  @DurationConverter()
  Duration get timestamp => throw _privateConstructorUsedError;

  /// Frame width in pixels
  int get width => throw _privateConstructorUsedError;

  /// Frame height in pixels
  int get height => throw _privateConstructorUsedError;

  /// Raw pixel data
  @Uint8ListConverter()
  Uint8List get data => throw _privateConstructorUsedError;

  /// Pixel format of the data
  FrameFormat get format => throw _privateConstructorUsedError;

  /// Frame number in the video sequence
  int? get frameNumber => throw _privateConstructorUsedError;

  /// Whether this is a keyframe
  bool get isKeyframe => throw _privateConstructorUsedError;

  /// Presentation timestamp (PTS) from decoder
  int? get pts => throw _privateConstructorUsedError;

  /// Scene change score (0.0 to 1.0, higher = more likely scene change)
  double? get sceneChangeScore => throw _privateConstructorUsedError;

  /// Average luminance of the frame (for exposure detection)
  double? get averageLuminance => throw _privateConstructorUsedError;

  /// Motion score compared to previous frame (0.0 = static, 1.0 = max motion)
  double? get motionScore => throw _privateConstructorUsedError;

  /// Serializes this FrameData to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of FrameData
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $FrameDataCopyWith<FrameData> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $FrameDataCopyWith<$Res> {
  factory $FrameDataCopyWith(FrameData value, $Res Function(FrameData) then) =
      _$FrameDataCopyWithImpl<$Res, FrameData>;
  @useResult
  $Res call(
      {@DurationConverter() Duration timestamp,
      int width,
      int height,
      @Uint8ListConverter() Uint8List data,
      FrameFormat format,
      int? frameNumber,
      bool isKeyframe,
      int? pts,
      double? sceneChangeScore,
      double? averageLuminance,
      double? motionScore});
}

/// @nodoc
class _$FrameDataCopyWithImpl<$Res, $Val extends FrameData>
    implements $FrameDataCopyWith<$Res> {
  _$FrameDataCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of FrameData
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? timestamp = null,
    Object? width = null,
    Object? height = null,
    Object? data = null,
    Object? format = null,
    Object? frameNumber = freezed,
    Object? isKeyframe = null,
    Object? pts = freezed,
    Object? sceneChangeScore = freezed,
    Object? averageLuminance = freezed,
    Object? motionScore = freezed,
  }) {
    return _then(_value.copyWith(
      timestamp: null == timestamp
          ? _value.timestamp
          : timestamp // ignore: cast_nullable_to_non_nullable
              as Duration,
      width: null == width
          ? _value.width
          : width // ignore: cast_nullable_to_non_nullable
              as int,
      height: null == height
          ? _value.height
          : height // ignore: cast_nullable_to_non_nullable
              as int,
      data: null == data
          ? _value.data
          : data // ignore: cast_nullable_to_non_nullable
              as Uint8List,
      format: null == format
          ? _value.format
          : format // ignore: cast_nullable_to_non_nullable
              as FrameFormat,
      frameNumber: freezed == frameNumber
          ? _value.frameNumber
          : frameNumber // ignore: cast_nullable_to_non_nullable
              as int?,
      isKeyframe: null == isKeyframe
          ? _value.isKeyframe
          : isKeyframe // ignore: cast_nullable_to_non_nullable
              as bool,
      pts: freezed == pts
          ? _value.pts
          : pts // ignore: cast_nullable_to_non_nullable
              as int?,
      sceneChangeScore: freezed == sceneChangeScore
          ? _value.sceneChangeScore
          : sceneChangeScore // ignore: cast_nullable_to_non_nullable
              as double?,
      averageLuminance: freezed == averageLuminance
          ? _value.averageLuminance
          : averageLuminance // ignore: cast_nullable_to_non_nullable
              as double?,
      motionScore: freezed == motionScore
          ? _value.motionScore
          : motionScore // ignore: cast_nullable_to_non_nullable
              as double?,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$FrameDataImplCopyWith<$Res>
    implements $FrameDataCopyWith<$Res> {
  factory _$$FrameDataImplCopyWith(
          _$FrameDataImpl value, $Res Function(_$FrameDataImpl) then) =
      __$$FrameDataImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {@DurationConverter() Duration timestamp,
      int width,
      int height,
      @Uint8ListConverter() Uint8List data,
      FrameFormat format,
      int? frameNumber,
      bool isKeyframe,
      int? pts,
      double? sceneChangeScore,
      double? averageLuminance,
      double? motionScore});
}

/// @nodoc
class __$$FrameDataImplCopyWithImpl<$Res>
    extends _$FrameDataCopyWithImpl<$Res, _$FrameDataImpl>
    implements _$$FrameDataImplCopyWith<$Res> {
  __$$FrameDataImplCopyWithImpl(
      _$FrameDataImpl _value, $Res Function(_$FrameDataImpl) _then)
      : super(_value, _then);

  /// Create a copy of FrameData
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? timestamp = null,
    Object? width = null,
    Object? height = null,
    Object? data = null,
    Object? format = null,
    Object? frameNumber = freezed,
    Object? isKeyframe = null,
    Object? pts = freezed,
    Object? sceneChangeScore = freezed,
    Object? averageLuminance = freezed,
    Object? motionScore = freezed,
  }) {
    return _then(_$FrameDataImpl(
      timestamp: null == timestamp
          ? _value.timestamp
          : timestamp // ignore: cast_nullable_to_non_nullable
              as Duration,
      width: null == width
          ? _value.width
          : width // ignore: cast_nullable_to_non_nullable
              as int,
      height: null == height
          ? _value.height
          : height // ignore: cast_nullable_to_non_nullable
              as int,
      data: null == data
          ? _value.data
          : data // ignore: cast_nullable_to_non_nullable
              as Uint8List,
      format: null == format
          ? _value.format
          : format // ignore: cast_nullable_to_non_nullable
              as FrameFormat,
      frameNumber: freezed == frameNumber
          ? _value.frameNumber
          : frameNumber // ignore: cast_nullable_to_non_nullable
              as int?,
      isKeyframe: null == isKeyframe
          ? _value.isKeyframe
          : isKeyframe // ignore: cast_nullable_to_non_nullable
              as bool,
      pts: freezed == pts
          ? _value.pts
          : pts // ignore: cast_nullable_to_non_nullable
              as int?,
      sceneChangeScore: freezed == sceneChangeScore
          ? _value.sceneChangeScore
          : sceneChangeScore // ignore: cast_nullable_to_non_nullable
              as double?,
      averageLuminance: freezed == averageLuminance
          ? _value.averageLuminance
          : averageLuminance // ignore: cast_nullable_to_non_nullable
              as double?,
      motionScore: freezed == motionScore
          ? _value.motionScore
          : motionScore // ignore: cast_nullable_to_non_nullable
              as double?,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$FrameDataImpl extends _FrameData {
  const _$FrameDataImpl(
      {@DurationConverter() required this.timestamp,
      required this.width,
      required this.height,
      @Uint8ListConverter() required this.data,
      this.format = FrameFormat.rgb24,
      this.frameNumber,
      this.isKeyframe = false,
      this.pts,
      this.sceneChangeScore,
      this.averageLuminance,
      this.motionScore})
      : super._();

  factory _$FrameDataImpl.fromJson(Map<String, dynamic> json) =>
      _$$FrameDataImplFromJson(json);

  /// Timestamp of the frame relative to video start
  @override
  @DurationConverter()
  final Duration timestamp;

  /// Frame width in pixels
  @override
  final int width;

  /// Frame height in pixels
  @override
  final int height;

  /// Raw pixel data
  @override
  @Uint8ListConverter()
  final Uint8List data;

  /// Pixel format of the data
  @override
  @JsonKey()
  final FrameFormat format;

  /// Frame number in the video sequence
  @override
  final int? frameNumber;

  /// Whether this is a keyframe
  @override
  @JsonKey()
  final bool isKeyframe;

  /// Presentation timestamp (PTS) from decoder
  @override
  final int? pts;

  /// Scene change score (0.0 to 1.0, higher = more likely scene change)
  @override
  final double? sceneChangeScore;

  /// Average luminance of the frame (for exposure detection)
  @override
  final double? averageLuminance;

  /// Motion score compared to previous frame (0.0 = static, 1.0 = max motion)
  @override
  final double? motionScore;

  @override
  String toString() {
    return 'FrameData(timestamp: $timestamp, width: $width, height: $height, data: $data, format: $format, frameNumber: $frameNumber, isKeyframe: $isKeyframe, pts: $pts, sceneChangeScore: $sceneChangeScore, averageLuminance: $averageLuminance, motionScore: $motionScore)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$FrameDataImpl &&
            (identical(other.timestamp, timestamp) ||
                other.timestamp == timestamp) &&
            (identical(other.width, width) || other.width == width) &&
            (identical(other.height, height) || other.height == height) &&
            const DeepCollectionEquality().equals(other.data, data) &&
            (identical(other.format, format) || other.format == format) &&
            (identical(other.frameNumber, frameNumber) ||
                other.frameNumber == frameNumber) &&
            (identical(other.isKeyframe, isKeyframe) ||
                other.isKeyframe == isKeyframe) &&
            (identical(other.pts, pts) || other.pts == pts) &&
            (identical(other.sceneChangeScore, sceneChangeScore) ||
                other.sceneChangeScore == sceneChangeScore) &&
            (identical(other.averageLuminance, averageLuminance) ||
                other.averageLuminance == averageLuminance) &&
            (identical(other.motionScore, motionScore) ||
                other.motionScore == motionScore));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
      runtimeType,
      timestamp,
      width,
      height,
      const DeepCollectionEquality().hash(data),
      format,
      frameNumber,
      isKeyframe,
      pts,
      sceneChangeScore,
      averageLuminance,
      motionScore);

  /// Create a copy of FrameData
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$FrameDataImplCopyWith<_$FrameDataImpl> get copyWith =>
      __$$FrameDataImplCopyWithImpl<_$FrameDataImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$FrameDataImplToJson(
      this,
    );
  }
}

abstract class _FrameData extends FrameData {
  const factory _FrameData(
      {@DurationConverter() required final Duration timestamp,
      required final int width,
      required final int height,
      @Uint8ListConverter() required final Uint8List data,
      final FrameFormat format,
      final int? frameNumber,
      final bool isKeyframe,
      final int? pts,
      final double? sceneChangeScore,
      final double? averageLuminance,
      final double? motionScore}) = _$FrameDataImpl;
  const _FrameData._() : super._();

  factory _FrameData.fromJson(Map<String, dynamic> json) =
      _$FrameDataImpl.fromJson;

  /// Timestamp of the frame relative to video start
  @override
  @DurationConverter()
  Duration get timestamp;

  /// Frame width in pixels
  @override
  int get width;

  /// Frame height in pixels
  @override
  int get height;

  /// Raw pixel data
  @override
  @Uint8ListConverter()
  Uint8List get data;

  /// Pixel format of the data
  @override
  FrameFormat get format;

  /// Frame number in the video sequence
  @override
  int? get frameNumber;

  /// Whether this is a keyframe
  @override
  bool get isKeyframe;

  /// Presentation timestamp (PTS) from decoder
  @override
  int? get pts;

  /// Scene change score (0.0 to 1.0, higher = more likely scene change)
  @override
  double? get sceneChangeScore;

  /// Average luminance of the frame (for exposure detection)
  @override
  double? get averageLuminance;

  /// Motion score compared to previous frame (0.0 = static, 1.0 = max motion)
  @override
  double? get motionScore;

  /// Create a copy of FrameData
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$FrameDataImplCopyWith<_$FrameDataImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

FrameBatch _$FrameBatchFromJson(Map<String, dynamic> json) {
  return _FrameBatch.fromJson(json);
}

/// @nodoc
mixin _$FrameBatch {
  /// List of frames in this batch
  List<FrameData> get frames => throw _privateConstructorUsedError;

  /// Batch index for tracking progress
  int get batchIndex => throw _privateConstructorUsedError;

  /// Total number of batches (if known)
  int? get totalBatches => throw _privateConstructorUsedError;

  /// Serializes this FrameBatch to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of FrameBatch
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $FrameBatchCopyWith<FrameBatch> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $FrameBatchCopyWith<$Res> {
  factory $FrameBatchCopyWith(
          FrameBatch value, $Res Function(FrameBatch) then) =
      _$FrameBatchCopyWithImpl<$Res, FrameBatch>;
  @useResult
  $Res call({List<FrameData> frames, int batchIndex, int? totalBatches});
}

/// @nodoc
class _$FrameBatchCopyWithImpl<$Res, $Val extends FrameBatch>
    implements $FrameBatchCopyWith<$Res> {
  _$FrameBatchCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of FrameBatch
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? frames = null,
    Object? batchIndex = null,
    Object? totalBatches = freezed,
  }) {
    return _then(_value.copyWith(
      frames: null == frames
          ? _value.frames
          : frames // ignore: cast_nullable_to_non_nullable
              as List<FrameData>,
      batchIndex: null == batchIndex
          ? _value.batchIndex
          : batchIndex // ignore: cast_nullable_to_non_nullable
              as int,
      totalBatches: freezed == totalBatches
          ? _value.totalBatches
          : totalBatches // ignore: cast_nullable_to_non_nullable
              as int?,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$FrameBatchImplCopyWith<$Res>
    implements $FrameBatchCopyWith<$Res> {
  factory _$$FrameBatchImplCopyWith(
          _$FrameBatchImpl value, $Res Function(_$FrameBatchImpl) then) =
      __$$FrameBatchImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({List<FrameData> frames, int batchIndex, int? totalBatches});
}

/// @nodoc
class __$$FrameBatchImplCopyWithImpl<$Res>
    extends _$FrameBatchCopyWithImpl<$Res, _$FrameBatchImpl>
    implements _$$FrameBatchImplCopyWith<$Res> {
  __$$FrameBatchImplCopyWithImpl(
      _$FrameBatchImpl _value, $Res Function(_$FrameBatchImpl) _then)
      : super(_value, _then);

  /// Create a copy of FrameBatch
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? frames = null,
    Object? batchIndex = null,
    Object? totalBatches = freezed,
  }) {
    return _then(_$FrameBatchImpl(
      frames: null == frames
          ? _value._frames
          : frames // ignore: cast_nullable_to_non_nullable
              as List<FrameData>,
      batchIndex: null == batchIndex
          ? _value.batchIndex
          : batchIndex // ignore: cast_nullable_to_non_nullable
              as int,
      totalBatches: freezed == totalBatches
          ? _value.totalBatches
          : totalBatches // ignore: cast_nullable_to_non_nullable
              as int?,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$FrameBatchImpl extends _FrameBatch {
  const _$FrameBatchImpl(
      {required final List<FrameData> frames,
      this.batchIndex = 0,
      this.totalBatches})
      : _frames = frames,
        super._();

  factory _$FrameBatchImpl.fromJson(Map<String, dynamic> json) =>
      _$$FrameBatchImplFromJson(json);

  /// List of frames in this batch
  final List<FrameData> _frames;

  /// List of frames in this batch
  @override
  List<FrameData> get frames {
    if (_frames is EqualUnmodifiableListView) return _frames;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_frames);
  }

  /// Batch index for tracking progress
  @override
  @JsonKey()
  final int batchIndex;

  /// Total number of batches (if known)
  @override
  final int? totalBatches;

  @override
  String toString() {
    return 'FrameBatch(frames: $frames, batchIndex: $batchIndex, totalBatches: $totalBatches)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$FrameBatchImpl &&
            const DeepCollectionEquality().equals(other._frames, _frames) &&
            (identical(other.batchIndex, batchIndex) ||
                other.batchIndex == batchIndex) &&
            (identical(other.totalBatches, totalBatches) ||
                other.totalBatches == totalBatches));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType,
      const DeepCollectionEquality().hash(_frames), batchIndex, totalBatches);

  /// Create a copy of FrameBatch
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$FrameBatchImplCopyWith<_$FrameBatchImpl> get copyWith =>
      __$$FrameBatchImplCopyWithImpl<_$FrameBatchImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$FrameBatchImplToJson(
      this,
    );
  }
}

abstract class _FrameBatch extends FrameBatch {
  const factory _FrameBatch(
      {required final List<FrameData> frames,
      final int batchIndex,
      final int? totalBatches}) = _$FrameBatchImpl;
  const _FrameBatch._() : super._();

  factory _FrameBatch.fromJson(Map<String, dynamic> json) =
      _$FrameBatchImpl.fromJson;

  /// List of frames in this batch
  @override
  List<FrameData> get frames;

  /// Batch index for tracking progress
  @override
  int get batchIndex;

  /// Total number of batches (if known)
  @override
  int? get totalBatches;

  /// Create a copy of FrameBatch
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$FrameBatchImplCopyWith<_$FrameBatchImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
