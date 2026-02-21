// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'frame_analysis_result.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

NsfwResult _$NsfwResultFromJson(Map<String, dynamic> json) {
  return _NsfwResult.fromJson(json);
}

/// @nodoc
mixin _$NsfwResult {
  /// Probability of pornographic content
  double get porn => throw _privateConstructorUsedError;

  /// Probability of sexy/suggestive content
  double get sexy => throw _privateConstructorUsedError;

  /// Probability of hentai/animated adult content
  double get hentai => throw _privateConstructorUsedError;

  /// Probability of drawings/illustrations (non-adult)
  double get drawings => throw _privateConstructorUsedError;

  /// Probability of neutral/safe content
  double get neutral => throw _privateConstructorUsedError;

  /// Serializes this NsfwResult to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of NsfwResult
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $NsfwResultCopyWith<NsfwResult> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $NsfwResultCopyWith<$Res> {
  factory $NsfwResultCopyWith(
          NsfwResult value, $Res Function(NsfwResult) then) =
      _$NsfwResultCopyWithImpl<$Res, NsfwResult>;
  @useResult
  $Res call(
      {double porn,
      double sexy,
      double hentai,
      double drawings,
      double neutral});
}

/// @nodoc
class _$NsfwResultCopyWithImpl<$Res, $Val extends NsfwResult>
    implements $NsfwResultCopyWith<$Res> {
  _$NsfwResultCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of NsfwResult
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? porn = null,
    Object? sexy = null,
    Object? hentai = null,
    Object? drawings = null,
    Object? neutral = null,
  }) {
    return _then(_value.copyWith(
      porn: null == porn
          ? _value.porn
          : porn // ignore: cast_nullable_to_non_nullable
              as double,
      sexy: null == sexy
          ? _value.sexy
          : sexy // ignore: cast_nullable_to_non_nullable
              as double,
      hentai: null == hentai
          ? _value.hentai
          : hentai // ignore: cast_nullable_to_non_nullable
              as double,
      drawings: null == drawings
          ? _value.drawings
          : drawings // ignore: cast_nullable_to_non_nullable
              as double,
      neutral: null == neutral
          ? _value.neutral
          : neutral // ignore: cast_nullable_to_non_nullable
              as double,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$NsfwResultImplCopyWith<$Res>
    implements $NsfwResultCopyWith<$Res> {
  factory _$$NsfwResultImplCopyWith(
          _$NsfwResultImpl value, $Res Function(_$NsfwResultImpl) then) =
      __$$NsfwResultImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {double porn,
      double sexy,
      double hentai,
      double drawings,
      double neutral});
}

/// @nodoc
class __$$NsfwResultImplCopyWithImpl<$Res>
    extends _$NsfwResultCopyWithImpl<$Res, _$NsfwResultImpl>
    implements _$$NsfwResultImplCopyWith<$Res> {
  __$$NsfwResultImplCopyWithImpl(
      _$NsfwResultImpl _value, $Res Function(_$NsfwResultImpl) _then)
      : super(_value, _then);

  /// Create a copy of NsfwResult
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? porn = null,
    Object? sexy = null,
    Object? hentai = null,
    Object? drawings = null,
    Object? neutral = null,
  }) {
    return _then(_$NsfwResultImpl(
      porn: null == porn
          ? _value.porn
          : porn // ignore: cast_nullable_to_non_nullable
              as double,
      sexy: null == sexy
          ? _value.sexy
          : sexy // ignore: cast_nullable_to_non_nullable
              as double,
      hentai: null == hentai
          ? _value.hentai
          : hentai // ignore: cast_nullable_to_non_nullable
              as double,
      drawings: null == drawings
          ? _value.drawings
          : drawings // ignore: cast_nullable_to_non_nullable
              as double,
      neutral: null == neutral
          ? _value.neutral
          : neutral // ignore: cast_nullable_to_non_nullable
              as double,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$NsfwResultImpl extends _NsfwResult {
  const _$NsfwResultImpl(
      {required this.porn,
      required this.sexy,
      required this.hentai,
      required this.drawings,
      required this.neutral})
      : super._();

  factory _$NsfwResultImpl.fromJson(Map<String, dynamic> json) =>
      _$$NsfwResultImplFromJson(json);

  /// Probability of pornographic content
  @override
  final double porn;

  /// Probability of sexy/suggestive content
  @override
  final double sexy;

  /// Probability of hentai/animated adult content
  @override
  final double hentai;

  /// Probability of drawings/illustrations (non-adult)
  @override
  final double drawings;

  /// Probability of neutral/safe content
  @override
  final double neutral;

  @override
  String toString() {
    return 'NsfwResult(porn: $porn, sexy: $sexy, hentai: $hentai, drawings: $drawings, neutral: $neutral)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$NsfwResultImpl &&
            (identical(other.porn, porn) || other.porn == porn) &&
            (identical(other.sexy, sexy) || other.sexy == sexy) &&
            (identical(other.hentai, hentai) || other.hentai == hentai) &&
            (identical(other.drawings, drawings) ||
                other.drawings == drawings) &&
            (identical(other.neutral, neutral) || other.neutral == neutral));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode =>
      Object.hash(runtimeType, porn, sexy, hentai, drawings, neutral);

  /// Create a copy of NsfwResult
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$NsfwResultImplCopyWith<_$NsfwResultImpl> get copyWith =>
      __$$NsfwResultImplCopyWithImpl<_$NsfwResultImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$NsfwResultImplToJson(
      this,
    );
  }
}

abstract class _NsfwResult extends NsfwResult {
  const factory _NsfwResult(
      {required final double porn,
      required final double sexy,
      required final double hentai,
      required final double drawings,
      required final double neutral}) = _$NsfwResultImpl;
  const _NsfwResult._() : super._();

  factory _NsfwResult.fromJson(Map<String, dynamic> json) =
      _$NsfwResultImpl.fromJson;

  /// Probability of pornographic content
  @override
  double get porn;

  /// Probability of sexy/suggestive content
  @override
  double get sexy;

  /// Probability of hentai/animated adult content
  @override
  double get hentai;

  /// Probability of drawings/illustrations (non-adult)
  @override
  double get drawings;

  /// Probability of neutral/safe content
  @override
  double get neutral;

  /// Create a copy of NsfwResult
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$NsfwResultImplCopyWith<_$NsfwResultImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

ViolenceResult _$ViolenceResultFromJson(Map<String, dynamic> json) {
  return _ViolenceResult.fromJson(json);
}

/// @nodoc
mixin _$ViolenceResult {
  /// Probability of violent content
  double get violent => throw _privateConstructorUsedError;

  /// Probability of non-violent content
  double get nonViolent => throw _privateConstructorUsedError;

  /// Serializes this ViolenceResult to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of ViolenceResult
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $ViolenceResultCopyWith<ViolenceResult> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $ViolenceResultCopyWith<$Res> {
  factory $ViolenceResultCopyWith(
          ViolenceResult value, $Res Function(ViolenceResult) then) =
      _$ViolenceResultCopyWithImpl<$Res, ViolenceResult>;
  @useResult
  $Res call({double violent, double nonViolent});
}

/// @nodoc
class _$ViolenceResultCopyWithImpl<$Res, $Val extends ViolenceResult>
    implements $ViolenceResultCopyWith<$Res> {
  _$ViolenceResultCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of ViolenceResult
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? violent = null,
    Object? nonViolent = null,
  }) {
    return _then(_value.copyWith(
      violent: null == violent
          ? _value.violent
          : violent // ignore: cast_nullable_to_non_nullable
              as double,
      nonViolent: null == nonViolent
          ? _value.nonViolent
          : nonViolent // ignore: cast_nullable_to_non_nullable
              as double,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$ViolenceResultImplCopyWith<$Res>
    implements $ViolenceResultCopyWith<$Res> {
  factory _$$ViolenceResultImplCopyWith(_$ViolenceResultImpl value,
          $Res Function(_$ViolenceResultImpl) then) =
      __$$ViolenceResultImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({double violent, double nonViolent});
}

/// @nodoc
class __$$ViolenceResultImplCopyWithImpl<$Res>
    extends _$ViolenceResultCopyWithImpl<$Res, _$ViolenceResultImpl>
    implements _$$ViolenceResultImplCopyWith<$Res> {
  __$$ViolenceResultImplCopyWithImpl(
      _$ViolenceResultImpl _value, $Res Function(_$ViolenceResultImpl) _then)
      : super(_value, _then);

  /// Create a copy of ViolenceResult
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? violent = null,
    Object? nonViolent = null,
  }) {
    return _then(_$ViolenceResultImpl(
      violent: null == violent
          ? _value.violent
          : violent // ignore: cast_nullable_to_non_nullable
              as double,
      nonViolent: null == nonViolent
          ? _value.nonViolent
          : nonViolent // ignore: cast_nullable_to_non_nullable
              as double,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$ViolenceResultImpl extends _ViolenceResult {
  const _$ViolenceResultImpl({required this.violent, required this.nonViolent})
      : super._();

  factory _$ViolenceResultImpl.fromJson(Map<String, dynamic> json) =>
      _$$ViolenceResultImplFromJson(json);

  /// Probability of violent content
  @override
  final double violent;

  /// Probability of non-violent content
  @override
  final double nonViolent;

  @override
  String toString() {
    return 'ViolenceResult(violent: $violent, nonViolent: $nonViolent)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$ViolenceResultImpl &&
            (identical(other.violent, violent) || other.violent == violent) &&
            (identical(other.nonViolent, nonViolent) ||
                other.nonViolent == nonViolent));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, violent, nonViolent);

  /// Create a copy of ViolenceResult
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$ViolenceResultImplCopyWith<_$ViolenceResultImpl> get copyWith =>
      __$$ViolenceResultImplCopyWithImpl<_$ViolenceResultImpl>(
          this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$ViolenceResultImplToJson(
      this,
    );
  }
}

abstract class _ViolenceResult extends ViolenceResult {
  const factory _ViolenceResult(
      {required final double violent,
      required final double nonViolent}) = _$ViolenceResultImpl;
  const _ViolenceResult._() : super._();

  factory _ViolenceResult.fromJson(Map<String, dynamic> json) =
      _$ViolenceResultImpl.fromJson;

  /// Probability of violent content
  @override
  double get violent;

  /// Probability of non-violent content
  @override
  double get nonViolent;

  /// Create a copy of ViolenceResult
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$ViolenceResultImplCopyWith<_$ViolenceResultImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

BloodResult _$BloodResultFromJson(Map<String, dynamic> json) {
  return _BloodResult.fromJson(json);
}

/// @nodoc
mixin _$BloodResult {
  /// Probability of blood/gore presence
  double get score => throw _privateConstructorUsedError;

  /// Detected regions (optional, for bounding boxes)
  List<BloodRegion>? get regions => throw _privateConstructorUsedError;

  /// Serializes this BloodResult to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of BloodResult
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $BloodResultCopyWith<BloodResult> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $BloodResultCopyWith<$Res> {
  factory $BloodResultCopyWith(
          BloodResult value, $Res Function(BloodResult) then) =
      _$BloodResultCopyWithImpl<$Res, BloodResult>;
  @useResult
  $Res call({double score, List<BloodRegion>? regions});
}

/// @nodoc
class _$BloodResultCopyWithImpl<$Res, $Val extends BloodResult>
    implements $BloodResultCopyWith<$Res> {
  _$BloodResultCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of BloodResult
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? score = null,
    Object? regions = freezed,
  }) {
    return _then(_value.copyWith(
      score: null == score
          ? _value.score
          : score // ignore: cast_nullable_to_non_nullable
              as double,
      regions: freezed == regions
          ? _value.regions
          : regions // ignore: cast_nullable_to_non_nullable
              as List<BloodRegion>?,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$BloodResultImplCopyWith<$Res>
    implements $BloodResultCopyWith<$Res> {
  factory _$$BloodResultImplCopyWith(
          _$BloodResultImpl value, $Res Function(_$BloodResultImpl) then) =
      __$$BloodResultImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({double score, List<BloodRegion>? regions});
}

/// @nodoc
class __$$BloodResultImplCopyWithImpl<$Res>
    extends _$BloodResultCopyWithImpl<$Res, _$BloodResultImpl>
    implements _$$BloodResultImplCopyWith<$Res> {
  __$$BloodResultImplCopyWithImpl(
      _$BloodResultImpl _value, $Res Function(_$BloodResultImpl) _then)
      : super(_value, _then);

  /// Create a copy of BloodResult
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? score = null,
    Object? regions = freezed,
  }) {
    return _then(_$BloodResultImpl(
      score: null == score
          ? _value.score
          : score // ignore: cast_nullable_to_non_nullable
              as double,
      regions: freezed == regions
          ? _value._regions
          : regions // ignore: cast_nullable_to_non_nullable
              as List<BloodRegion>?,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$BloodResultImpl extends _BloodResult {
  const _$BloodResultImpl(
      {required this.score, final List<BloodRegion>? regions})
      : _regions = regions,
        super._();

  factory _$BloodResultImpl.fromJson(Map<String, dynamic> json) =>
      _$$BloodResultImplFromJson(json);

  /// Probability of blood/gore presence
  @override
  final double score;

  /// Detected regions (optional, for bounding boxes)
  final List<BloodRegion>? _regions;

  /// Detected regions (optional, for bounding boxes)
  @override
  List<BloodRegion>? get regions {
    final value = _regions;
    if (value == null) return null;
    if (_regions is EqualUnmodifiableListView) return _regions;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(value);
  }

  @override
  String toString() {
    return 'BloodResult(score: $score, regions: $regions)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$BloodResultImpl &&
            (identical(other.score, score) || other.score == score) &&
            const DeepCollectionEquality().equals(other._regions, _regions));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
      runtimeType, score, const DeepCollectionEquality().hash(_regions));

  /// Create a copy of BloodResult
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$BloodResultImplCopyWith<_$BloodResultImpl> get copyWith =>
      __$$BloodResultImplCopyWithImpl<_$BloodResultImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$BloodResultImplToJson(
      this,
    );
  }
}

abstract class _BloodResult extends BloodResult {
  const factory _BloodResult(
      {required final double score,
      final List<BloodRegion>? regions}) = _$BloodResultImpl;
  const _BloodResult._() : super._();

  factory _BloodResult.fromJson(Map<String, dynamic> json) =
      _$BloodResultImpl.fromJson;

  /// Probability of blood/gore presence
  @override
  double get score;

  /// Detected regions (optional, for bounding boxes)
  @override
  List<BloodRegion>? get regions;

  /// Create a copy of BloodResult
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$BloodResultImplCopyWith<_$BloodResultImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

BloodRegion _$BloodRegionFromJson(Map<String, dynamic> json) {
  return _BloodRegion.fromJson(json);
}

/// @nodoc
mixin _$BloodRegion {
  /// X coordinate of top-left corner (normalized 0-1)
  double get x => throw _privateConstructorUsedError;

  /// Y coordinate of top-left corner (normalized 0-1)
  double get y => throw _privateConstructorUsedError;

  /// Width of region (normalized 0-1)
  double get width => throw _privateConstructorUsedError;

  /// Height of region (normalized 0-1)
  double get height => throw _privateConstructorUsedError;

  /// Confidence score for this region
  double get confidence => throw _privateConstructorUsedError;

  /// Serializes this BloodRegion to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of BloodRegion
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $BloodRegionCopyWith<BloodRegion> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $BloodRegionCopyWith<$Res> {
  factory $BloodRegionCopyWith(
          BloodRegion value, $Res Function(BloodRegion) then) =
      _$BloodRegionCopyWithImpl<$Res, BloodRegion>;
  @useResult
  $Res call(
      {double x, double y, double width, double height, double confidence});
}

/// @nodoc
class _$BloodRegionCopyWithImpl<$Res, $Val extends BloodRegion>
    implements $BloodRegionCopyWith<$Res> {
  _$BloodRegionCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of BloodRegion
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? x = null,
    Object? y = null,
    Object? width = null,
    Object? height = null,
    Object? confidence = null,
  }) {
    return _then(_value.copyWith(
      x: null == x
          ? _value.x
          : x // ignore: cast_nullable_to_non_nullable
              as double,
      y: null == y
          ? _value.y
          : y // ignore: cast_nullable_to_non_nullable
              as double,
      width: null == width
          ? _value.width
          : width // ignore: cast_nullable_to_non_nullable
              as double,
      height: null == height
          ? _value.height
          : height // ignore: cast_nullable_to_non_nullable
              as double,
      confidence: null == confidence
          ? _value.confidence
          : confidence // ignore: cast_nullable_to_non_nullable
              as double,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$BloodRegionImplCopyWith<$Res>
    implements $BloodRegionCopyWith<$Res> {
  factory _$$BloodRegionImplCopyWith(
          _$BloodRegionImpl value, $Res Function(_$BloodRegionImpl) then) =
      __$$BloodRegionImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {double x, double y, double width, double height, double confidence});
}

/// @nodoc
class __$$BloodRegionImplCopyWithImpl<$Res>
    extends _$BloodRegionCopyWithImpl<$Res, _$BloodRegionImpl>
    implements _$$BloodRegionImplCopyWith<$Res> {
  __$$BloodRegionImplCopyWithImpl(
      _$BloodRegionImpl _value, $Res Function(_$BloodRegionImpl) _then)
      : super(_value, _then);

  /// Create a copy of BloodRegion
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? x = null,
    Object? y = null,
    Object? width = null,
    Object? height = null,
    Object? confidence = null,
  }) {
    return _then(_$BloodRegionImpl(
      x: null == x
          ? _value.x
          : x // ignore: cast_nullable_to_non_nullable
              as double,
      y: null == y
          ? _value.y
          : y // ignore: cast_nullable_to_non_nullable
              as double,
      width: null == width
          ? _value.width
          : width // ignore: cast_nullable_to_non_nullable
              as double,
      height: null == height
          ? _value.height
          : height // ignore: cast_nullable_to_non_nullable
              as double,
      confidence: null == confidence
          ? _value.confidence
          : confidence // ignore: cast_nullable_to_non_nullable
              as double,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$BloodRegionImpl implements _BloodRegion {
  const _$BloodRegionImpl(
      {required this.x,
      required this.y,
      required this.width,
      required this.height,
      required this.confidence});

  factory _$BloodRegionImpl.fromJson(Map<String, dynamic> json) =>
      _$$BloodRegionImplFromJson(json);

  /// X coordinate of top-left corner (normalized 0-1)
  @override
  final double x;

  /// Y coordinate of top-left corner (normalized 0-1)
  @override
  final double y;

  /// Width of region (normalized 0-1)
  @override
  final double width;

  /// Height of region (normalized 0-1)
  @override
  final double height;

  /// Confidence score for this region
  @override
  final double confidence;

  @override
  String toString() {
    return 'BloodRegion(x: $x, y: $y, width: $width, height: $height, confidence: $confidence)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$BloodRegionImpl &&
            (identical(other.x, x) || other.x == x) &&
            (identical(other.y, y) || other.y == y) &&
            (identical(other.width, width) || other.width == width) &&
            (identical(other.height, height) || other.height == height) &&
            (identical(other.confidence, confidence) ||
                other.confidence == confidence));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, x, y, width, height, confidence);

  /// Create a copy of BloodRegion
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$BloodRegionImplCopyWith<_$BloodRegionImpl> get copyWith =>
      __$$BloodRegionImplCopyWithImpl<_$BloodRegionImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$BloodRegionImplToJson(
      this,
    );
  }
}

abstract class _BloodRegion implements BloodRegion {
  const factory _BloodRegion(
      {required final double x,
      required final double y,
      required final double width,
      required final double height,
      required final double confidence}) = _$BloodRegionImpl;

  factory _BloodRegion.fromJson(Map<String, dynamic> json) =
      _$BloodRegionImpl.fromJson;

  /// X coordinate of top-left corner (normalized 0-1)
  @override
  double get x;

  /// Y coordinate of top-left corner (normalized 0-1)
  @override
  double get y;

  /// Width of region (normalized 0-1)
  @override
  double get width;

  /// Height of region (normalized 0-1)
  @override
  double get height;

  /// Confidence score for this region
  @override
  double get confidence;

  /// Create a copy of BloodRegion
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$BloodRegionImplCopyWith<_$BloodRegionImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

WeaponsResult _$WeaponsResultFromJson(Map<String, dynamic> json) {
  return _WeaponsResult.fromJson(json);
}

/// @nodoc
mixin _$WeaponsResult {
  /// Probability of weapon presence
  double get score => throw _privateConstructorUsedError;

  /// List of detected weapons
  List<DetectedWeapon>? get weapons => throw _privateConstructorUsedError;

  /// Serializes this WeaponsResult to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of WeaponsResult
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $WeaponsResultCopyWith<WeaponsResult> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $WeaponsResultCopyWith<$Res> {
  factory $WeaponsResultCopyWith(
          WeaponsResult value, $Res Function(WeaponsResult) then) =
      _$WeaponsResultCopyWithImpl<$Res, WeaponsResult>;
  @useResult
  $Res call({double score, List<DetectedWeapon>? weapons});
}

/// @nodoc
class _$WeaponsResultCopyWithImpl<$Res, $Val extends WeaponsResult>
    implements $WeaponsResultCopyWith<$Res> {
  _$WeaponsResultCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of WeaponsResult
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? score = null,
    Object? weapons = freezed,
  }) {
    return _then(_value.copyWith(
      score: null == score
          ? _value.score
          : score // ignore: cast_nullable_to_non_nullable
              as double,
      weapons: freezed == weapons
          ? _value.weapons
          : weapons // ignore: cast_nullable_to_non_nullable
              as List<DetectedWeapon>?,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$WeaponsResultImplCopyWith<$Res>
    implements $WeaponsResultCopyWith<$Res> {
  factory _$$WeaponsResultImplCopyWith(
          _$WeaponsResultImpl value, $Res Function(_$WeaponsResultImpl) then) =
      __$$WeaponsResultImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({double score, List<DetectedWeapon>? weapons});
}

/// @nodoc
class __$$WeaponsResultImplCopyWithImpl<$Res>
    extends _$WeaponsResultCopyWithImpl<$Res, _$WeaponsResultImpl>
    implements _$$WeaponsResultImplCopyWith<$Res> {
  __$$WeaponsResultImplCopyWithImpl(
      _$WeaponsResultImpl _value, $Res Function(_$WeaponsResultImpl) _then)
      : super(_value, _then);

  /// Create a copy of WeaponsResult
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? score = null,
    Object? weapons = freezed,
  }) {
    return _then(_$WeaponsResultImpl(
      score: null == score
          ? _value.score
          : score // ignore: cast_nullable_to_non_nullable
              as double,
      weapons: freezed == weapons
          ? _value._weapons
          : weapons // ignore: cast_nullable_to_non_nullable
              as List<DetectedWeapon>?,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$WeaponsResultImpl extends _WeaponsResult {
  const _$WeaponsResultImpl(
      {required this.score, final List<DetectedWeapon>? weapons})
      : _weapons = weapons,
        super._();

  factory _$WeaponsResultImpl.fromJson(Map<String, dynamic> json) =>
      _$$WeaponsResultImplFromJson(json);

  /// Probability of weapon presence
  @override
  final double score;

  /// List of detected weapons
  final List<DetectedWeapon>? _weapons;

  /// List of detected weapons
  @override
  List<DetectedWeapon>? get weapons {
    final value = _weapons;
    if (value == null) return null;
    if (_weapons is EqualUnmodifiableListView) return _weapons;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(value);
  }

  @override
  String toString() {
    return 'WeaponsResult(score: $score, weapons: $weapons)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$WeaponsResultImpl &&
            (identical(other.score, score) || other.score == score) &&
            const DeepCollectionEquality().equals(other._weapons, _weapons));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
      runtimeType, score, const DeepCollectionEquality().hash(_weapons));

  /// Create a copy of WeaponsResult
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$WeaponsResultImplCopyWith<_$WeaponsResultImpl> get copyWith =>
      __$$WeaponsResultImplCopyWithImpl<_$WeaponsResultImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$WeaponsResultImplToJson(
      this,
    );
  }
}

abstract class _WeaponsResult extends WeaponsResult {
  const factory _WeaponsResult(
      {required final double score,
      final List<DetectedWeapon>? weapons}) = _$WeaponsResultImpl;
  const _WeaponsResult._() : super._();

  factory _WeaponsResult.fromJson(Map<String, dynamic> json) =
      _$WeaponsResultImpl.fromJson;

  /// Probability of weapon presence
  @override
  double get score;

  /// List of detected weapons
  @override
  List<DetectedWeapon>? get weapons;

  /// Create a copy of WeaponsResult
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$WeaponsResultImplCopyWith<_$WeaponsResultImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

DetectedWeapon _$DetectedWeaponFromJson(Map<String, dynamic> json) {
  return _DetectedWeapon.fromJson(json);
}

/// @nodoc
mixin _$DetectedWeapon {
  /// Type of weapon (e.g., 'gun', 'knife', 'rifle')
  String get type => throw _privateConstructorUsedError;

  /// Confidence score
  double get confidence => throw _privateConstructorUsedError;

  /// Bounding box X (normalized 0-1)
  double get x => throw _privateConstructorUsedError;

  /// Bounding box Y (normalized 0-1)
  double get y => throw _privateConstructorUsedError;

  /// Bounding box width (normalized 0-1)
  double get width => throw _privateConstructorUsedError;

  /// Bounding box height (normalized 0-1)
  double get height => throw _privateConstructorUsedError;

  /// Serializes this DetectedWeapon to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of DetectedWeapon
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $DetectedWeaponCopyWith<DetectedWeapon> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $DetectedWeaponCopyWith<$Res> {
  factory $DetectedWeaponCopyWith(
          DetectedWeapon value, $Res Function(DetectedWeapon) then) =
      _$DetectedWeaponCopyWithImpl<$Res, DetectedWeapon>;
  @useResult
  $Res call(
      {String type,
      double confidence,
      double x,
      double y,
      double width,
      double height});
}

/// @nodoc
class _$DetectedWeaponCopyWithImpl<$Res, $Val extends DetectedWeapon>
    implements $DetectedWeaponCopyWith<$Res> {
  _$DetectedWeaponCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of DetectedWeapon
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? type = null,
    Object? confidence = null,
    Object? x = null,
    Object? y = null,
    Object? width = null,
    Object? height = null,
  }) {
    return _then(_value.copyWith(
      type: null == type
          ? _value.type
          : type // ignore: cast_nullable_to_non_nullable
              as String,
      confidence: null == confidence
          ? _value.confidence
          : confidence // ignore: cast_nullable_to_non_nullable
              as double,
      x: null == x
          ? _value.x
          : x // ignore: cast_nullable_to_non_nullable
              as double,
      y: null == y
          ? _value.y
          : y // ignore: cast_nullable_to_non_nullable
              as double,
      width: null == width
          ? _value.width
          : width // ignore: cast_nullable_to_non_nullable
              as double,
      height: null == height
          ? _value.height
          : height // ignore: cast_nullable_to_non_nullable
              as double,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$DetectedWeaponImplCopyWith<$Res>
    implements $DetectedWeaponCopyWith<$Res> {
  factory _$$DetectedWeaponImplCopyWith(_$DetectedWeaponImpl value,
          $Res Function(_$DetectedWeaponImpl) then) =
      __$$DetectedWeaponImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String type,
      double confidence,
      double x,
      double y,
      double width,
      double height});
}

/// @nodoc
class __$$DetectedWeaponImplCopyWithImpl<$Res>
    extends _$DetectedWeaponCopyWithImpl<$Res, _$DetectedWeaponImpl>
    implements _$$DetectedWeaponImplCopyWith<$Res> {
  __$$DetectedWeaponImplCopyWithImpl(
      _$DetectedWeaponImpl _value, $Res Function(_$DetectedWeaponImpl) _then)
      : super(_value, _then);

  /// Create a copy of DetectedWeapon
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? type = null,
    Object? confidence = null,
    Object? x = null,
    Object? y = null,
    Object? width = null,
    Object? height = null,
  }) {
    return _then(_$DetectedWeaponImpl(
      type: null == type
          ? _value.type
          : type // ignore: cast_nullable_to_non_nullable
              as String,
      confidence: null == confidence
          ? _value.confidence
          : confidence // ignore: cast_nullable_to_non_nullable
              as double,
      x: null == x
          ? _value.x
          : x // ignore: cast_nullable_to_non_nullable
              as double,
      y: null == y
          ? _value.y
          : y // ignore: cast_nullable_to_non_nullable
              as double,
      width: null == width
          ? _value.width
          : width // ignore: cast_nullable_to_non_nullable
              as double,
      height: null == height
          ? _value.height
          : height // ignore: cast_nullable_to_non_nullable
              as double,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$DetectedWeaponImpl implements _DetectedWeapon {
  const _$DetectedWeaponImpl(
      {required this.type,
      required this.confidence,
      required this.x,
      required this.y,
      required this.width,
      required this.height});

  factory _$DetectedWeaponImpl.fromJson(Map<String, dynamic> json) =>
      _$$DetectedWeaponImplFromJson(json);

  /// Type of weapon (e.g., 'gun', 'knife', 'rifle')
  @override
  final String type;

  /// Confidence score
  @override
  final double confidence;

  /// Bounding box X (normalized 0-1)
  @override
  final double x;

  /// Bounding box Y (normalized 0-1)
  @override
  final double y;

  /// Bounding box width (normalized 0-1)
  @override
  final double width;

  /// Bounding box height (normalized 0-1)
  @override
  final double height;

  @override
  String toString() {
    return 'DetectedWeapon(type: $type, confidence: $confidence, x: $x, y: $y, width: $width, height: $height)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$DetectedWeaponImpl &&
            (identical(other.type, type) || other.type == type) &&
            (identical(other.confidence, confidence) ||
                other.confidence == confidence) &&
            (identical(other.x, x) || other.x == x) &&
            (identical(other.y, y) || other.y == y) &&
            (identical(other.width, width) || other.width == width) &&
            (identical(other.height, height) || other.height == height));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode =>
      Object.hash(runtimeType, type, confidence, x, y, width, height);

  /// Create a copy of DetectedWeapon
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$DetectedWeaponImplCopyWith<_$DetectedWeaponImpl> get copyWith =>
      __$$DetectedWeaponImplCopyWithImpl<_$DetectedWeaponImpl>(
          this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$DetectedWeaponImplToJson(
      this,
    );
  }
}

abstract class _DetectedWeapon implements DetectedWeapon {
  const factory _DetectedWeapon(
      {required final String type,
      required final double confidence,
      required final double x,
      required final double y,
      required final double width,
      required final double height}) = _$DetectedWeaponImpl;

  factory _DetectedWeapon.fromJson(Map<String, dynamic> json) =
      _$DetectedWeaponImpl.fromJson;

  /// Type of weapon (e.g., 'gun', 'knife', 'rifle')
  @override
  String get type;

  /// Confidence score
  @override
  double get confidence;

  /// Bounding box X (normalized 0-1)
  @override
  double get x;

  /// Bounding box Y (normalized 0-1)
  @override
  double get y;

  /// Bounding box width (normalized 0-1)
  @override
  double get width;

  /// Bounding box height (normalized 0-1)
  @override
  double get height;

  /// Create a copy of DetectedWeapon
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$DetectedWeaponImplCopyWith<_$DetectedWeaponImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

DetectedRegion _$DetectedRegionFromJson(Map<String, dynamic> json) {
  return _DetectedRegion.fromJson(json);
}

/// @nodoc
mixin _$DetectedRegion {
  /// Raw model label (e.g. 'FEMALE_BREAST_EXPOSED')
  String get label => throw _privateConstructorUsedError;

  /// Detection confidence score (0-1)
  double get confidence => throw _privateConstructorUsedError;

  /// X coordinate of top-left corner (normalized 0-1)
  double get x => throw _privateConstructorUsedError;

  /// Y coordinate of top-left corner (normalized 0-1)
  double get y => throw _privateConstructorUsedError;

  /// Width of region (normalized 0-1)
  double get width => throw _privateConstructorUsedError;

  /// Height of region (normalized 0-1)
  double get height => throw _privateConstructorUsedError;

  /// Serializes this DetectedRegion to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of DetectedRegion
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $DetectedRegionCopyWith<DetectedRegion> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $DetectedRegionCopyWith<$Res> {
  factory $DetectedRegionCopyWith(
          DetectedRegion value, $Res Function(DetectedRegion) then) =
      _$DetectedRegionCopyWithImpl<$Res, DetectedRegion>;
  @useResult
  $Res call(
      {String label,
      double confidence,
      double x,
      double y,
      double width,
      double height});
}

/// @nodoc
class _$DetectedRegionCopyWithImpl<$Res, $Val extends DetectedRegion>
    implements $DetectedRegionCopyWith<$Res> {
  _$DetectedRegionCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of DetectedRegion
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? label = null,
    Object? confidence = null,
    Object? x = null,
    Object? y = null,
    Object? width = null,
    Object? height = null,
  }) {
    return _then(_value.copyWith(
      label: null == label
          ? _value.label
          : label // ignore: cast_nullable_to_non_nullable
              as String,
      confidence: null == confidence
          ? _value.confidence
          : confidence // ignore: cast_nullable_to_non_nullable
              as double,
      x: null == x
          ? _value.x
          : x // ignore: cast_nullable_to_non_nullable
              as double,
      y: null == y
          ? _value.y
          : y // ignore: cast_nullable_to_non_nullable
              as double,
      width: null == width
          ? _value.width
          : width // ignore: cast_nullable_to_non_nullable
              as double,
      height: null == height
          ? _value.height
          : height // ignore: cast_nullable_to_non_nullable
              as double,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$DetectedRegionImplCopyWith<$Res>
    implements $DetectedRegionCopyWith<$Res> {
  factory _$$DetectedRegionImplCopyWith(_$DetectedRegionImpl value,
          $Res Function(_$DetectedRegionImpl) then) =
      __$$DetectedRegionImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String label,
      double confidence,
      double x,
      double y,
      double width,
      double height});
}

/// @nodoc
class __$$DetectedRegionImplCopyWithImpl<$Res>
    extends _$DetectedRegionCopyWithImpl<$Res, _$DetectedRegionImpl>
    implements _$$DetectedRegionImplCopyWith<$Res> {
  __$$DetectedRegionImplCopyWithImpl(
      _$DetectedRegionImpl _value, $Res Function(_$DetectedRegionImpl) _then)
      : super(_value, _then);

  /// Create a copy of DetectedRegion
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? label = null,
    Object? confidence = null,
    Object? x = null,
    Object? y = null,
    Object? width = null,
    Object? height = null,
  }) {
    return _then(_$DetectedRegionImpl(
      label: null == label
          ? _value.label
          : label // ignore: cast_nullable_to_non_nullable
              as String,
      confidence: null == confidence
          ? _value.confidence
          : confidence // ignore: cast_nullable_to_non_nullable
              as double,
      x: null == x
          ? _value.x
          : x // ignore: cast_nullable_to_non_nullable
              as double,
      y: null == y
          ? _value.y
          : y // ignore: cast_nullable_to_non_nullable
              as double,
      width: null == width
          ? _value.width
          : width // ignore: cast_nullable_to_non_nullable
              as double,
      height: null == height
          ? _value.height
          : height // ignore: cast_nullable_to_non_nullable
              as double,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$DetectedRegionImpl implements _DetectedRegion {
  const _$DetectedRegionImpl(
      {required this.label,
      required this.confidence,
      required this.x,
      required this.y,
      required this.width,
      required this.height});

  factory _$DetectedRegionImpl.fromJson(Map<String, dynamic> json) =>
      _$$DetectedRegionImplFromJson(json);

  /// Raw model label (e.g. 'FEMALE_BREAST_EXPOSED')
  @override
  final String label;

  /// Detection confidence score (0-1)
  @override
  final double confidence;

  /// X coordinate of top-left corner (normalized 0-1)
  @override
  final double x;

  /// Y coordinate of top-left corner (normalized 0-1)
  @override
  final double y;

  /// Width of region (normalized 0-1)
  @override
  final double width;

  /// Height of region (normalized 0-1)
  @override
  final double height;

  @override
  String toString() {
    return 'DetectedRegion(label: $label, confidence: $confidence, x: $x, y: $y, width: $width, height: $height)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$DetectedRegionImpl &&
            (identical(other.label, label) || other.label == label) &&
            (identical(other.confidence, confidence) ||
                other.confidence == confidence) &&
            (identical(other.x, x) || other.x == x) &&
            (identical(other.y, y) || other.y == y) &&
            (identical(other.width, width) || other.width == width) &&
            (identical(other.height, height) || other.height == height));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode =>
      Object.hash(runtimeType, label, confidence, x, y, width, height);

  /// Create a copy of DetectedRegion
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$DetectedRegionImplCopyWith<_$DetectedRegionImpl> get copyWith =>
      __$$DetectedRegionImplCopyWithImpl<_$DetectedRegionImpl>(
          this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$DetectedRegionImplToJson(
      this,
    );
  }
}

abstract class _DetectedRegion implements DetectedRegion {
  const factory _DetectedRegion(
      {required final String label,
      required final double confidence,
      required final double x,
      required final double y,
      required final double width,
      required final double height}) = _$DetectedRegionImpl;

  factory _DetectedRegion.fromJson(Map<String, dynamic> json) =
      _$DetectedRegionImpl.fromJson;

  /// Raw model label (e.g. 'FEMALE_BREAST_EXPOSED')
  @override
  String get label;

  /// Detection confidence score (0-1)
  @override
  double get confidence;

  /// X coordinate of top-left corner (normalized 0-1)
  @override
  double get x;

  /// Y coordinate of top-left corner (normalized 0-1)
  @override
  double get y;

  /// Width of region (normalized 0-1)
  @override
  double get width;

  /// Height of region (normalized 0-1)
  @override
  double get height;

  /// Create a copy of DetectedRegion
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$DetectedRegionImplCopyWith<_$DetectedRegionImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

VisualContentResult _$VisualContentResultFromJson(Map<String, dynamic> json) {
  return _VisualContentResult.fromJson(json);
}

/// @nodoc
mixin _$VisualContentResult {
  /// Detected regions from NudeNet (bounding boxes)
  List<DetectedRegion> get detectedRegions =>
      throw _privateConstructorUsedError;

  /// CLIP temperature-scaled discriminative scores per category ID
  Map<String, double> get clipScores => throw _privateConstructorUsedError;

  /// Serializes this VisualContentResult to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of VisualContentResult
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $VisualContentResultCopyWith<VisualContentResult> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $VisualContentResultCopyWith<$Res> {
  factory $VisualContentResultCopyWith(
          VisualContentResult value, $Res Function(VisualContentResult) then) =
      _$VisualContentResultCopyWithImpl<$Res, VisualContentResult>;
  @useResult
  $Res call(
      {List<DetectedRegion> detectedRegions, Map<String, double> clipScores});
}

/// @nodoc
class _$VisualContentResultCopyWithImpl<$Res, $Val extends VisualContentResult>
    implements $VisualContentResultCopyWith<$Res> {
  _$VisualContentResultCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of VisualContentResult
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? detectedRegions = null,
    Object? clipScores = null,
  }) {
    return _then(_value.copyWith(
      detectedRegions: null == detectedRegions
          ? _value.detectedRegions
          : detectedRegions // ignore: cast_nullable_to_non_nullable
              as List<DetectedRegion>,
      clipScores: null == clipScores
          ? _value.clipScores
          : clipScores // ignore: cast_nullable_to_non_nullable
              as Map<String, double>,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$VisualContentResultImplCopyWith<$Res>
    implements $VisualContentResultCopyWith<$Res> {
  factory _$$VisualContentResultImplCopyWith(_$VisualContentResultImpl value,
          $Res Function(_$VisualContentResultImpl) then) =
      __$$VisualContentResultImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {List<DetectedRegion> detectedRegions, Map<String, double> clipScores});
}

/// @nodoc
class __$$VisualContentResultImplCopyWithImpl<$Res>
    extends _$VisualContentResultCopyWithImpl<$Res, _$VisualContentResultImpl>
    implements _$$VisualContentResultImplCopyWith<$Res> {
  __$$VisualContentResultImplCopyWithImpl(_$VisualContentResultImpl _value,
      $Res Function(_$VisualContentResultImpl) _then)
      : super(_value, _then);

  /// Create a copy of VisualContentResult
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? detectedRegions = null,
    Object? clipScores = null,
  }) {
    return _then(_$VisualContentResultImpl(
      detectedRegions: null == detectedRegions
          ? _value._detectedRegions
          : detectedRegions // ignore: cast_nullable_to_non_nullable
              as List<DetectedRegion>,
      clipScores: null == clipScores
          ? _value._clipScores
          : clipScores // ignore: cast_nullable_to_non_nullable
              as Map<String, double>,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$VisualContentResultImpl extends _VisualContentResult {
  const _$VisualContentResultImpl(
      {final List<DetectedRegion> detectedRegions = const [],
      final Map<String, double> clipScores = const {}})
      : _detectedRegions = detectedRegions,
        _clipScores = clipScores,
        super._();

  factory _$VisualContentResultImpl.fromJson(Map<String, dynamic> json) =>
      _$$VisualContentResultImplFromJson(json);

  /// Detected regions from NudeNet (bounding boxes)
  final List<DetectedRegion> _detectedRegions;

  /// Detected regions from NudeNet (bounding boxes)
  @override
  @JsonKey()
  List<DetectedRegion> get detectedRegions {
    if (_detectedRegions is EqualUnmodifiableListView) return _detectedRegions;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_detectedRegions);
  }

  /// CLIP temperature-scaled discriminative scores per category ID
  final Map<String, double> _clipScores;

  /// CLIP temperature-scaled discriminative scores per category ID
  @override
  @JsonKey()
  Map<String, double> get clipScores {
    if (_clipScores is EqualUnmodifiableMapView) return _clipScores;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableMapView(_clipScores);
  }

  @override
  String toString() {
    return 'VisualContentResult(detectedRegions: $detectedRegions, clipScores: $clipScores)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$VisualContentResultImpl &&
            const DeepCollectionEquality()
                .equals(other._detectedRegions, _detectedRegions) &&
            const DeepCollectionEquality()
                .equals(other._clipScores, _clipScores));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
      runtimeType,
      const DeepCollectionEquality().hash(_detectedRegions),
      const DeepCollectionEquality().hash(_clipScores));

  /// Create a copy of VisualContentResult
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$VisualContentResultImplCopyWith<_$VisualContentResultImpl> get copyWith =>
      __$$VisualContentResultImplCopyWithImpl<_$VisualContentResultImpl>(
          this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$VisualContentResultImplToJson(
      this,
    );
  }
}

abstract class _VisualContentResult extends VisualContentResult {
  const factory _VisualContentResult(
      {final List<DetectedRegion> detectedRegions,
      final Map<String, double> clipScores}) = _$VisualContentResultImpl;
  const _VisualContentResult._() : super._();

  factory _VisualContentResult.fromJson(Map<String, dynamic> json) =
      _$VisualContentResultImpl.fromJson;

  /// Detected regions from NudeNet (bounding boxes)
  @override
  List<DetectedRegion> get detectedRegions;

  /// CLIP temperature-scaled discriminative scores per category ID
  @override
  Map<String, double> get clipScores;

  /// Create a copy of VisualContentResult
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$VisualContentResultImplCopyWith<_$VisualContentResultImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

FrameAnalysisResult _$FrameAnalysisResultFromJson(Map<String, dynamic> json) {
  return _FrameAnalysisResult.fromJson(json);
}

/// @nodoc
mixin _$FrameAnalysisResult {
  /// Frame number in the video
  int get frameNumber => throw _privateConstructorUsedError;

  /// Timestamp of the frame in the video
  @DurationConverter()
  Duration get timestamp => throw _privateConstructorUsedError;

  /// NSFW classification result
  NsfwResult get nsfw => throw _privateConstructorUsedError;

  /// Violence classification result
  ViolenceResult get violence => throw _privateConstructorUsedError;

  /// Whether this frame is a scene change
  bool get isSceneChange => throw _privateConstructorUsedError;

  /// Blood/gore detection result (optional)
  BloodResult? get blood => throw _privateConstructorUsedError;

  /// Weapons detection result (optional)
  WeaponsResult? get weapons => throw _privateConstructorUsedError;

  /// Visual content detection result (NudeNet + CLIP)
  VisualContentResult? get visualContent => throw _privateConstructorUsedError;

  /// Processing time for this frame in milliseconds
  int? get processingTimeMs => throw _privateConstructorUsedError;

  /// Optional frame hash for deduplication
  String? get frameHash => throw _privateConstructorUsedError;

  /// Serializes this FrameAnalysisResult to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of FrameAnalysisResult
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $FrameAnalysisResultCopyWith<FrameAnalysisResult> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $FrameAnalysisResultCopyWith<$Res> {
  factory $FrameAnalysisResultCopyWith(
          FrameAnalysisResult value, $Res Function(FrameAnalysisResult) then) =
      _$FrameAnalysisResultCopyWithImpl<$Res, FrameAnalysisResult>;
  @useResult
  $Res call(
      {int frameNumber,
      @DurationConverter() Duration timestamp,
      NsfwResult nsfw,
      ViolenceResult violence,
      bool isSceneChange,
      BloodResult? blood,
      WeaponsResult? weapons,
      VisualContentResult? visualContent,
      int? processingTimeMs,
      String? frameHash});

  $NsfwResultCopyWith<$Res> get nsfw;
  $ViolenceResultCopyWith<$Res> get violence;
  $BloodResultCopyWith<$Res>? get blood;
  $WeaponsResultCopyWith<$Res>? get weapons;
  $VisualContentResultCopyWith<$Res>? get visualContent;
}

/// @nodoc
class _$FrameAnalysisResultCopyWithImpl<$Res, $Val extends FrameAnalysisResult>
    implements $FrameAnalysisResultCopyWith<$Res> {
  _$FrameAnalysisResultCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of FrameAnalysisResult
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? frameNumber = null,
    Object? timestamp = null,
    Object? nsfw = null,
    Object? violence = null,
    Object? isSceneChange = null,
    Object? blood = freezed,
    Object? weapons = freezed,
    Object? visualContent = freezed,
    Object? processingTimeMs = freezed,
    Object? frameHash = freezed,
  }) {
    return _then(_value.copyWith(
      frameNumber: null == frameNumber
          ? _value.frameNumber
          : frameNumber // ignore: cast_nullable_to_non_nullable
              as int,
      timestamp: null == timestamp
          ? _value.timestamp
          : timestamp // ignore: cast_nullable_to_non_nullable
              as Duration,
      nsfw: null == nsfw
          ? _value.nsfw
          : nsfw // ignore: cast_nullable_to_non_nullable
              as NsfwResult,
      violence: null == violence
          ? _value.violence
          : violence // ignore: cast_nullable_to_non_nullable
              as ViolenceResult,
      isSceneChange: null == isSceneChange
          ? _value.isSceneChange
          : isSceneChange // ignore: cast_nullable_to_non_nullable
              as bool,
      blood: freezed == blood
          ? _value.blood
          : blood // ignore: cast_nullable_to_non_nullable
              as BloodResult?,
      weapons: freezed == weapons
          ? _value.weapons
          : weapons // ignore: cast_nullable_to_non_nullable
              as WeaponsResult?,
      visualContent: freezed == visualContent
          ? _value.visualContent
          : visualContent // ignore: cast_nullable_to_non_nullable
              as VisualContentResult?,
      processingTimeMs: freezed == processingTimeMs
          ? _value.processingTimeMs
          : processingTimeMs // ignore: cast_nullable_to_non_nullable
              as int?,
      frameHash: freezed == frameHash
          ? _value.frameHash
          : frameHash // ignore: cast_nullable_to_non_nullable
              as String?,
    ) as $Val);
  }

  /// Create a copy of FrameAnalysisResult
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $NsfwResultCopyWith<$Res> get nsfw {
    return $NsfwResultCopyWith<$Res>(_value.nsfw, (value) {
      return _then(_value.copyWith(nsfw: value) as $Val);
    });
  }

  /// Create a copy of FrameAnalysisResult
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $ViolenceResultCopyWith<$Res> get violence {
    return $ViolenceResultCopyWith<$Res>(_value.violence, (value) {
      return _then(_value.copyWith(violence: value) as $Val);
    });
  }

  /// Create a copy of FrameAnalysisResult
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $BloodResultCopyWith<$Res>? get blood {
    if (_value.blood == null) {
      return null;
    }

    return $BloodResultCopyWith<$Res>(_value.blood!, (value) {
      return _then(_value.copyWith(blood: value) as $Val);
    });
  }

  /// Create a copy of FrameAnalysisResult
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $WeaponsResultCopyWith<$Res>? get weapons {
    if (_value.weapons == null) {
      return null;
    }

    return $WeaponsResultCopyWith<$Res>(_value.weapons!, (value) {
      return _then(_value.copyWith(weapons: value) as $Val);
    });
  }

  /// Create a copy of FrameAnalysisResult
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $VisualContentResultCopyWith<$Res>? get visualContent {
    if (_value.visualContent == null) {
      return null;
    }

    return $VisualContentResultCopyWith<$Res>(_value.visualContent!, (value) {
      return _then(_value.copyWith(visualContent: value) as $Val);
    });
  }
}

/// @nodoc
abstract class _$$FrameAnalysisResultImplCopyWith<$Res>
    implements $FrameAnalysisResultCopyWith<$Res> {
  factory _$$FrameAnalysisResultImplCopyWith(_$FrameAnalysisResultImpl value,
          $Res Function(_$FrameAnalysisResultImpl) then) =
      __$$FrameAnalysisResultImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {int frameNumber,
      @DurationConverter() Duration timestamp,
      NsfwResult nsfw,
      ViolenceResult violence,
      bool isSceneChange,
      BloodResult? blood,
      WeaponsResult? weapons,
      VisualContentResult? visualContent,
      int? processingTimeMs,
      String? frameHash});

  @override
  $NsfwResultCopyWith<$Res> get nsfw;
  @override
  $ViolenceResultCopyWith<$Res> get violence;
  @override
  $BloodResultCopyWith<$Res>? get blood;
  @override
  $WeaponsResultCopyWith<$Res>? get weapons;
  @override
  $VisualContentResultCopyWith<$Res>? get visualContent;
}

/// @nodoc
class __$$FrameAnalysisResultImplCopyWithImpl<$Res>
    extends _$FrameAnalysisResultCopyWithImpl<$Res, _$FrameAnalysisResultImpl>
    implements _$$FrameAnalysisResultImplCopyWith<$Res> {
  __$$FrameAnalysisResultImplCopyWithImpl(_$FrameAnalysisResultImpl _value,
      $Res Function(_$FrameAnalysisResultImpl) _then)
      : super(_value, _then);

  /// Create a copy of FrameAnalysisResult
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? frameNumber = null,
    Object? timestamp = null,
    Object? nsfw = null,
    Object? violence = null,
    Object? isSceneChange = null,
    Object? blood = freezed,
    Object? weapons = freezed,
    Object? visualContent = freezed,
    Object? processingTimeMs = freezed,
    Object? frameHash = freezed,
  }) {
    return _then(_$FrameAnalysisResultImpl(
      frameNumber: null == frameNumber
          ? _value.frameNumber
          : frameNumber // ignore: cast_nullable_to_non_nullable
              as int,
      timestamp: null == timestamp
          ? _value.timestamp
          : timestamp // ignore: cast_nullable_to_non_nullable
              as Duration,
      nsfw: null == nsfw
          ? _value.nsfw
          : nsfw // ignore: cast_nullable_to_non_nullable
              as NsfwResult,
      violence: null == violence
          ? _value.violence
          : violence // ignore: cast_nullable_to_non_nullable
              as ViolenceResult,
      isSceneChange: null == isSceneChange
          ? _value.isSceneChange
          : isSceneChange // ignore: cast_nullable_to_non_nullable
              as bool,
      blood: freezed == blood
          ? _value.blood
          : blood // ignore: cast_nullable_to_non_nullable
              as BloodResult?,
      weapons: freezed == weapons
          ? _value.weapons
          : weapons // ignore: cast_nullable_to_non_nullable
              as WeaponsResult?,
      visualContent: freezed == visualContent
          ? _value.visualContent
          : visualContent // ignore: cast_nullable_to_non_nullable
              as VisualContentResult?,
      processingTimeMs: freezed == processingTimeMs
          ? _value.processingTimeMs
          : processingTimeMs // ignore: cast_nullable_to_non_nullable
              as int?,
      frameHash: freezed == frameHash
          ? _value.frameHash
          : frameHash // ignore: cast_nullable_to_non_nullable
              as String?,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$FrameAnalysisResultImpl extends _FrameAnalysisResult {
  const _$FrameAnalysisResultImpl(
      {required this.frameNumber,
      @DurationConverter() required this.timestamp,
      required this.nsfw,
      required this.violence,
      this.isSceneChange = false,
      this.blood,
      this.weapons,
      this.visualContent,
      this.processingTimeMs,
      this.frameHash})
      : super._();

  factory _$FrameAnalysisResultImpl.fromJson(Map<String, dynamic> json) =>
      _$$FrameAnalysisResultImplFromJson(json);

  /// Frame number in the video
  @override
  final int frameNumber;

  /// Timestamp of the frame in the video
  @override
  @DurationConverter()
  final Duration timestamp;

  /// NSFW classification result
  @override
  final NsfwResult nsfw;

  /// Violence classification result
  @override
  final ViolenceResult violence;

  /// Whether this frame is a scene change
  @override
  @JsonKey()
  final bool isSceneChange;

  /// Blood/gore detection result (optional)
  @override
  final BloodResult? blood;

  /// Weapons detection result (optional)
  @override
  final WeaponsResult? weapons;

  /// Visual content detection result (NudeNet + CLIP)
  @override
  final VisualContentResult? visualContent;

  /// Processing time for this frame in milliseconds
  @override
  final int? processingTimeMs;

  /// Optional frame hash for deduplication
  @override
  final String? frameHash;

  @override
  String toString() {
    return 'FrameAnalysisResult(frameNumber: $frameNumber, timestamp: $timestamp, nsfw: $nsfw, violence: $violence, isSceneChange: $isSceneChange, blood: $blood, weapons: $weapons, visualContent: $visualContent, processingTimeMs: $processingTimeMs, frameHash: $frameHash)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$FrameAnalysisResultImpl &&
            (identical(other.frameNumber, frameNumber) ||
                other.frameNumber == frameNumber) &&
            (identical(other.timestamp, timestamp) ||
                other.timestamp == timestamp) &&
            (identical(other.nsfw, nsfw) || other.nsfw == nsfw) &&
            (identical(other.violence, violence) ||
                other.violence == violence) &&
            (identical(other.isSceneChange, isSceneChange) ||
                other.isSceneChange == isSceneChange) &&
            (identical(other.blood, blood) || other.blood == blood) &&
            (identical(other.weapons, weapons) || other.weapons == weapons) &&
            (identical(other.visualContent, visualContent) ||
                other.visualContent == visualContent) &&
            (identical(other.processingTimeMs, processingTimeMs) ||
                other.processingTimeMs == processingTimeMs) &&
            (identical(other.frameHash, frameHash) ||
                other.frameHash == frameHash));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
      runtimeType,
      frameNumber,
      timestamp,
      nsfw,
      violence,
      isSceneChange,
      blood,
      weapons,
      visualContent,
      processingTimeMs,
      frameHash);

  /// Create a copy of FrameAnalysisResult
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$FrameAnalysisResultImplCopyWith<_$FrameAnalysisResultImpl> get copyWith =>
      __$$FrameAnalysisResultImplCopyWithImpl<_$FrameAnalysisResultImpl>(
          this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$FrameAnalysisResultImplToJson(
      this,
    );
  }
}

abstract class _FrameAnalysisResult extends FrameAnalysisResult {
  const factory _FrameAnalysisResult(
      {required final int frameNumber,
      @DurationConverter() required final Duration timestamp,
      required final NsfwResult nsfw,
      required final ViolenceResult violence,
      final bool isSceneChange,
      final BloodResult? blood,
      final WeaponsResult? weapons,
      final VisualContentResult? visualContent,
      final int? processingTimeMs,
      final String? frameHash}) = _$FrameAnalysisResultImpl;
  const _FrameAnalysisResult._() : super._();

  factory _FrameAnalysisResult.fromJson(Map<String, dynamic> json) =
      _$FrameAnalysisResultImpl.fromJson;

  /// Frame number in the video
  @override
  int get frameNumber;

  /// Timestamp of the frame in the video
  @override
  @DurationConverter()
  Duration get timestamp;

  /// NSFW classification result
  @override
  NsfwResult get nsfw;

  /// Violence classification result
  @override
  ViolenceResult get violence;

  /// Whether this frame is a scene change
  @override
  bool get isSceneChange;

  /// Blood/gore detection result (optional)
  @override
  BloodResult? get blood;

  /// Weapons detection result (optional)
  @override
  WeaponsResult? get weapons;

  /// Visual content detection result (NudeNet + CLIP)
  @override
  VisualContentResult? get visualContent;

  /// Processing time for this frame in milliseconds
  @override
  int? get processingTimeMs;

  /// Optional frame hash for deduplication
  @override
  String? get frameHash;

  /// Create a copy of FrameAnalysisResult
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$FrameAnalysisResultImplCopyWith<_$FrameAnalysisResultImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
