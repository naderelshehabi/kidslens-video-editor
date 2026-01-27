// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'edit_action.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

EditAction _$EditActionFromJson(Map<String, dynamic> json) {
  return _EditAction.fromJson(json);
}

/// @nodoc
mixin _$EditAction {
  /// Unique identifier for this edit action
  String get id => throw _privateConstructorUsedError;

  /// ID of the media file this action applies to
  String get mediaId => throw _privateConstructorUsedError;

  /// ID of the detection this action was created from (if any)
  String? get detectionId => throw _privateConstructorUsedError;

  /// Type of edit action
  EditActionType get type => throw _privateConstructorUsedError;

  /// Start time in the media
  @DurationConverter()
  Duration get startTime => throw _privateConstructorUsedError;

  /// End time in the media
  @DurationConverter()
  Duration get endTime => throw _privateConstructorUsedError;

  /// Whether this action is enabled
  bool get enabled => throw _privateConstructorUsedError;

  /// Blur intensity (0.0 to 1.0) - only for blur actions
  double get blurIntensity => throw _privateConstructorUsedError;

  /// Bounding box for blur (null means full frame)
  BoundingBox? get boundingBox => throw _privateConstructorUsedError;

  /// Beep frequency in Hz - only for beep actions
  double get beepFrequency => throw _privateConstructorUsedError;

  /// User notes about this edit
  String? get notes => throw _privateConstructorUsedError;

  /// When this edit was created
  @DateTimeConverter()
  DateTime? get createdAt => throw _privateConstructorUsedError;

  /// Serializes this EditAction to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of EditAction
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $EditActionCopyWith<EditAction> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $EditActionCopyWith<$Res> {
  factory $EditActionCopyWith(
          EditAction value, $Res Function(EditAction) then) =
      _$EditActionCopyWithImpl<$Res, EditAction>;
  @useResult
  $Res call(
      {String id,
      String mediaId,
      String? detectionId,
      EditActionType type,
      @DurationConverter() Duration startTime,
      @DurationConverter() Duration endTime,
      bool enabled,
      double blurIntensity,
      BoundingBox? boundingBox,
      double beepFrequency,
      String? notes,
      @DateTimeConverter() DateTime? createdAt});

  $BoundingBoxCopyWith<$Res>? get boundingBox;
}

/// @nodoc
class _$EditActionCopyWithImpl<$Res, $Val extends EditAction>
    implements $EditActionCopyWith<$Res> {
  _$EditActionCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of EditAction
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? mediaId = null,
    Object? detectionId = freezed,
    Object? type = null,
    Object? startTime = null,
    Object? endTime = null,
    Object? enabled = null,
    Object? blurIntensity = null,
    Object? boundingBox = freezed,
    Object? beepFrequency = null,
    Object? notes = freezed,
    Object? createdAt = freezed,
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
      detectionId: freezed == detectionId
          ? _value.detectionId
          : detectionId // ignore: cast_nullable_to_non_nullable
              as String?,
      type: null == type
          ? _value.type
          : type // ignore: cast_nullable_to_non_nullable
              as EditActionType,
      startTime: null == startTime
          ? _value.startTime
          : startTime // ignore: cast_nullable_to_non_nullable
              as Duration,
      endTime: null == endTime
          ? _value.endTime
          : endTime // ignore: cast_nullable_to_non_nullable
              as Duration,
      enabled: null == enabled
          ? _value.enabled
          : enabled // ignore: cast_nullable_to_non_nullable
              as bool,
      blurIntensity: null == blurIntensity
          ? _value.blurIntensity
          : blurIntensity // ignore: cast_nullable_to_non_nullable
              as double,
      boundingBox: freezed == boundingBox
          ? _value.boundingBox
          : boundingBox // ignore: cast_nullable_to_non_nullable
              as BoundingBox?,
      beepFrequency: null == beepFrequency
          ? _value.beepFrequency
          : beepFrequency // ignore: cast_nullable_to_non_nullable
              as double,
      notes: freezed == notes
          ? _value.notes
          : notes // ignore: cast_nullable_to_non_nullable
              as String?,
      createdAt: freezed == createdAt
          ? _value.createdAt
          : createdAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
    ) as $Val);
  }

  /// Create a copy of EditAction
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $BoundingBoxCopyWith<$Res>? get boundingBox {
    if (_value.boundingBox == null) {
      return null;
    }

    return $BoundingBoxCopyWith<$Res>(_value.boundingBox!, (value) {
      return _then(_value.copyWith(boundingBox: value) as $Val);
    });
  }
}

/// @nodoc
abstract class _$$EditActionImplCopyWith<$Res>
    implements $EditActionCopyWith<$Res> {
  factory _$$EditActionImplCopyWith(
          _$EditActionImpl value, $Res Function(_$EditActionImpl) then) =
      __$$EditActionImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String id,
      String mediaId,
      String? detectionId,
      EditActionType type,
      @DurationConverter() Duration startTime,
      @DurationConverter() Duration endTime,
      bool enabled,
      double blurIntensity,
      BoundingBox? boundingBox,
      double beepFrequency,
      String? notes,
      @DateTimeConverter() DateTime? createdAt});

  @override
  $BoundingBoxCopyWith<$Res>? get boundingBox;
}

/// @nodoc
class __$$EditActionImplCopyWithImpl<$Res>
    extends _$EditActionCopyWithImpl<$Res, _$EditActionImpl>
    implements _$$EditActionImplCopyWith<$Res> {
  __$$EditActionImplCopyWithImpl(
      _$EditActionImpl _value, $Res Function(_$EditActionImpl) _then)
      : super(_value, _then);

  /// Create a copy of EditAction
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? mediaId = null,
    Object? detectionId = freezed,
    Object? type = null,
    Object? startTime = null,
    Object? endTime = null,
    Object? enabled = null,
    Object? blurIntensity = null,
    Object? boundingBox = freezed,
    Object? beepFrequency = null,
    Object? notes = freezed,
    Object? createdAt = freezed,
  }) {
    return _then(_$EditActionImpl(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      mediaId: null == mediaId
          ? _value.mediaId
          : mediaId // ignore: cast_nullable_to_non_nullable
              as String,
      detectionId: freezed == detectionId
          ? _value.detectionId
          : detectionId // ignore: cast_nullable_to_non_nullable
              as String?,
      type: null == type
          ? _value.type
          : type // ignore: cast_nullable_to_non_nullable
              as EditActionType,
      startTime: null == startTime
          ? _value.startTime
          : startTime // ignore: cast_nullable_to_non_nullable
              as Duration,
      endTime: null == endTime
          ? _value.endTime
          : endTime // ignore: cast_nullable_to_non_nullable
              as Duration,
      enabled: null == enabled
          ? _value.enabled
          : enabled // ignore: cast_nullable_to_non_nullable
              as bool,
      blurIntensity: null == blurIntensity
          ? _value.blurIntensity
          : blurIntensity // ignore: cast_nullable_to_non_nullable
              as double,
      boundingBox: freezed == boundingBox
          ? _value.boundingBox
          : boundingBox // ignore: cast_nullable_to_non_nullable
              as BoundingBox?,
      beepFrequency: null == beepFrequency
          ? _value.beepFrequency
          : beepFrequency // ignore: cast_nullable_to_non_nullable
              as double,
      notes: freezed == notes
          ? _value.notes
          : notes // ignore: cast_nullable_to_non_nullable
              as String?,
      createdAt: freezed == createdAt
          ? _value.createdAt
          : createdAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$EditActionImpl extends _EditAction {
  const _$EditActionImpl(
      {required this.id,
      required this.mediaId,
      this.detectionId,
      required this.type,
      @DurationConverter() required this.startTime,
      @DurationConverter() required this.endTime,
      this.enabled = true,
      this.blurIntensity = 1.0,
      this.boundingBox,
      this.beepFrequency = 1000.0,
      this.notes,
      @DateTimeConverter() this.createdAt})
      : super._();

  factory _$EditActionImpl.fromJson(Map<String, dynamic> json) =>
      _$$EditActionImplFromJson(json);

  /// Unique identifier for this edit action
  @override
  final String id;

  /// ID of the media file this action applies to
  @override
  final String mediaId;

  /// ID of the detection this action was created from (if any)
  @override
  final String? detectionId;

  /// Type of edit action
  @override
  final EditActionType type;

  /// Start time in the media
  @override
  @DurationConverter()
  final Duration startTime;

  /// End time in the media
  @override
  @DurationConverter()
  final Duration endTime;

  /// Whether this action is enabled
  @override
  @JsonKey()
  final bool enabled;

  /// Blur intensity (0.0 to 1.0) - only for blur actions
  @override
  @JsonKey()
  final double blurIntensity;

  /// Bounding box for blur (null means full frame)
  @override
  final BoundingBox? boundingBox;

  /// Beep frequency in Hz - only for beep actions
  @override
  @JsonKey()
  final double beepFrequency;

  /// User notes about this edit
  @override
  final String? notes;

  /// When this edit was created
  @override
  @DateTimeConverter()
  final DateTime? createdAt;

  @override
  String toString() {
    return 'EditAction(id: $id, mediaId: $mediaId, detectionId: $detectionId, type: $type, startTime: $startTime, endTime: $endTime, enabled: $enabled, blurIntensity: $blurIntensity, boundingBox: $boundingBox, beepFrequency: $beepFrequency, notes: $notes, createdAt: $createdAt)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$EditActionImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.mediaId, mediaId) || other.mediaId == mediaId) &&
            (identical(other.detectionId, detectionId) ||
                other.detectionId == detectionId) &&
            (identical(other.type, type) || other.type == type) &&
            (identical(other.startTime, startTime) ||
                other.startTime == startTime) &&
            (identical(other.endTime, endTime) || other.endTime == endTime) &&
            (identical(other.enabled, enabled) || other.enabled == enabled) &&
            (identical(other.blurIntensity, blurIntensity) ||
                other.blurIntensity == blurIntensity) &&
            (identical(other.boundingBox, boundingBox) ||
                other.boundingBox == boundingBox) &&
            (identical(other.beepFrequency, beepFrequency) ||
                other.beepFrequency == beepFrequency) &&
            (identical(other.notes, notes) || other.notes == notes) &&
            (identical(other.createdAt, createdAt) ||
                other.createdAt == createdAt));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
      runtimeType,
      id,
      mediaId,
      detectionId,
      type,
      startTime,
      endTime,
      enabled,
      blurIntensity,
      boundingBox,
      beepFrequency,
      notes,
      createdAt);

  /// Create a copy of EditAction
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$EditActionImplCopyWith<_$EditActionImpl> get copyWith =>
      __$$EditActionImplCopyWithImpl<_$EditActionImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$EditActionImplToJson(
      this,
    );
  }
}

abstract class _EditAction extends EditAction {
  const factory _EditAction(
      {required final String id,
      required final String mediaId,
      final String? detectionId,
      required final EditActionType type,
      @DurationConverter() required final Duration startTime,
      @DurationConverter() required final Duration endTime,
      final bool enabled,
      final double blurIntensity,
      final BoundingBox? boundingBox,
      final double beepFrequency,
      final String? notes,
      @DateTimeConverter() final DateTime? createdAt}) = _$EditActionImpl;
  const _EditAction._() : super._();

  factory _EditAction.fromJson(Map<String, dynamic> json) =
      _$EditActionImpl.fromJson;

  /// Unique identifier for this edit action
  @override
  String get id;

  /// ID of the media file this action applies to
  @override
  String get mediaId;

  /// ID of the detection this action was created from (if any)
  @override
  String? get detectionId;

  /// Type of edit action
  @override
  EditActionType get type;

  /// Start time in the media
  @override
  @DurationConverter()
  Duration get startTime;

  /// End time in the media
  @override
  @DurationConverter()
  Duration get endTime;

  /// Whether this action is enabled
  @override
  bool get enabled;

  /// Blur intensity (0.0 to 1.0) - only for blur actions
  @override
  double get blurIntensity;

  /// Bounding box for blur (null means full frame)
  @override
  BoundingBox? get boundingBox;

  /// Beep frequency in Hz - only for beep actions
  @override
  double get beepFrequency;

  /// User notes about this edit
  @override
  String? get notes;

  /// When this edit was created
  @override
  @DateTimeConverter()
  DateTime? get createdAt;

  /// Create a copy of EditAction
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$EditActionImplCopyWith<_$EditActionImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

BoundingBox _$BoundingBoxFromJson(Map<String, dynamic> json) {
  return _BoundingBox.fromJson(json);
}

/// @nodoc
mixin _$BoundingBox {
  /// Left edge (0-1 normalized)
  double get left => throw _privateConstructorUsedError;

  /// Top edge (0-1 normalized)
  double get top => throw _privateConstructorUsedError;

  /// Width (0-1 normalized)
  double get width => throw _privateConstructorUsedError;

  /// Height (0-1 normalized)
  double get height => throw _privateConstructorUsedError;

  /// Serializes this BoundingBox to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of BoundingBox
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $BoundingBoxCopyWith<BoundingBox> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $BoundingBoxCopyWith<$Res> {
  factory $BoundingBoxCopyWith(
          BoundingBox value, $Res Function(BoundingBox) then) =
      _$BoundingBoxCopyWithImpl<$Res, BoundingBox>;
  @useResult
  $Res call({double left, double top, double width, double height});
}

/// @nodoc
class _$BoundingBoxCopyWithImpl<$Res, $Val extends BoundingBox>
    implements $BoundingBoxCopyWith<$Res> {
  _$BoundingBoxCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of BoundingBox
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? left = null,
    Object? top = null,
    Object? width = null,
    Object? height = null,
  }) {
    return _then(_value.copyWith(
      left: null == left
          ? _value.left
          : left // ignore: cast_nullable_to_non_nullable
              as double,
      top: null == top
          ? _value.top
          : top // ignore: cast_nullable_to_non_nullable
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
abstract class _$$BoundingBoxImplCopyWith<$Res>
    implements $BoundingBoxCopyWith<$Res> {
  factory _$$BoundingBoxImplCopyWith(
          _$BoundingBoxImpl value, $Res Function(_$BoundingBoxImpl) then) =
      __$$BoundingBoxImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({double left, double top, double width, double height});
}

/// @nodoc
class __$$BoundingBoxImplCopyWithImpl<$Res>
    extends _$BoundingBoxCopyWithImpl<$Res, _$BoundingBoxImpl>
    implements _$$BoundingBoxImplCopyWith<$Res> {
  __$$BoundingBoxImplCopyWithImpl(
      _$BoundingBoxImpl _value, $Res Function(_$BoundingBoxImpl) _then)
      : super(_value, _then);

  /// Create a copy of BoundingBox
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? left = null,
    Object? top = null,
    Object? width = null,
    Object? height = null,
  }) {
    return _then(_$BoundingBoxImpl(
      left: null == left
          ? _value.left
          : left // ignore: cast_nullable_to_non_nullable
              as double,
      top: null == top
          ? _value.top
          : top // ignore: cast_nullable_to_non_nullable
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
class _$BoundingBoxImpl implements _BoundingBox {
  const _$BoundingBoxImpl(
      {required this.left,
      required this.top,
      required this.width,
      required this.height});

  factory _$BoundingBoxImpl.fromJson(Map<String, dynamic> json) =>
      _$$BoundingBoxImplFromJson(json);

  /// Left edge (0-1 normalized)
  @override
  final double left;

  /// Top edge (0-1 normalized)
  @override
  final double top;

  /// Width (0-1 normalized)
  @override
  final double width;

  /// Height (0-1 normalized)
  @override
  final double height;

  @override
  String toString() {
    return 'BoundingBox(left: $left, top: $top, width: $width, height: $height)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$BoundingBoxImpl &&
            (identical(other.left, left) || other.left == left) &&
            (identical(other.top, top) || other.top == top) &&
            (identical(other.width, width) || other.width == width) &&
            (identical(other.height, height) || other.height == height));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, left, top, width, height);

  /// Create a copy of BoundingBox
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$BoundingBoxImplCopyWith<_$BoundingBoxImpl> get copyWith =>
      __$$BoundingBoxImplCopyWithImpl<_$BoundingBoxImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$BoundingBoxImplToJson(
      this,
    );
  }
}

abstract class _BoundingBox implements BoundingBox {
  const factory _BoundingBox(
      {required final double left,
      required final double top,
      required final double width,
      required final double height}) = _$BoundingBoxImpl;

  factory _BoundingBox.fromJson(Map<String, dynamic> json) =
      _$BoundingBoxImpl.fromJson;

  /// Left edge (0-1 normalized)
  @override
  double get left;

  /// Top edge (0-1 normalized)
  @override
  double get top;

  /// Width (0-1 normalized)
  @override
  double get width;

  /// Height (0-1 normalized)
  @override
  double get height;

  /// Create a copy of BoundingBox
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$BoundingBoxImplCopyWith<_$BoundingBoxImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
