// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'gpu_info.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

AcceleratorInfo _$AcceleratorInfoFromJson(Map<String, dynamic> json) {
  return _AcceleratorInfo.fromJson(json);
}

/// @nodoc
mixin _$AcceleratorInfo {
  AcceleratorType get type => throw _privateConstructorUsedError;
  String get name => throw _privateConstructorUsedError;
  int get vramMB => throw _privateConstructorUsedError;
  String? get computeCapability => throw _privateConstructorUsedError;
  bool get isAppleSilicon => throw _privateConstructorUsedError;
  int get recommendedBatchSize => throw _privateConstructorUsedError;

  /// Serializes this AcceleratorInfo to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of AcceleratorInfo
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $AcceleratorInfoCopyWith<AcceleratorInfo> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $AcceleratorInfoCopyWith<$Res> {
  factory $AcceleratorInfoCopyWith(
          AcceleratorInfo value, $Res Function(AcceleratorInfo) then) =
      _$AcceleratorInfoCopyWithImpl<$Res, AcceleratorInfo>;
  @useResult
  $Res call(
      {AcceleratorType type,
      String name,
      int vramMB,
      String? computeCapability,
      bool isAppleSilicon,
      int recommendedBatchSize});
}

/// @nodoc
class _$AcceleratorInfoCopyWithImpl<$Res, $Val extends AcceleratorInfo>
    implements $AcceleratorInfoCopyWith<$Res> {
  _$AcceleratorInfoCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of AcceleratorInfo
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? type = null,
    Object? name = null,
    Object? vramMB = null,
    Object? computeCapability = freezed,
    Object? isAppleSilicon = null,
    Object? recommendedBatchSize = null,
  }) {
    return _then(_value.copyWith(
      type: null == type
          ? _value.type
          : type // ignore: cast_nullable_to_non_nullable
              as AcceleratorType,
      name: null == name
          ? _value.name
          : name // ignore: cast_nullable_to_non_nullable
              as String,
      vramMB: null == vramMB
          ? _value.vramMB
          : vramMB // ignore: cast_nullable_to_non_nullable
              as int,
      computeCapability: freezed == computeCapability
          ? _value.computeCapability
          : computeCapability // ignore: cast_nullable_to_non_nullable
              as String?,
      isAppleSilicon: null == isAppleSilicon
          ? _value.isAppleSilicon
          : isAppleSilicon // ignore: cast_nullable_to_non_nullable
              as bool,
      recommendedBatchSize: null == recommendedBatchSize
          ? _value.recommendedBatchSize
          : recommendedBatchSize // ignore: cast_nullable_to_non_nullable
              as int,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$AcceleratorInfoImplCopyWith<$Res>
    implements $AcceleratorInfoCopyWith<$Res> {
  factory _$$AcceleratorInfoImplCopyWith(_$AcceleratorInfoImpl value,
          $Res Function(_$AcceleratorInfoImpl) then) =
      __$$AcceleratorInfoImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {AcceleratorType type,
      String name,
      int vramMB,
      String? computeCapability,
      bool isAppleSilicon,
      int recommendedBatchSize});
}

/// @nodoc
class __$$AcceleratorInfoImplCopyWithImpl<$Res>
    extends _$AcceleratorInfoCopyWithImpl<$Res, _$AcceleratorInfoImpl>
    implements _$$AcceleratorInfoImplCopyWith<$Res> {
  __$$AcceleratorInfoImplCopyWithImpl(
      _$AcceleratorInfoImpl _value, $Res Function(_$AcceleratorInfoImpl) _then)
      : super(_value, _then);

  /// Create a copy of AcceleratorInfo
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? type = null,
    Object? name = null,
    Object? vramMB = null,
    Object? computeCapability = freezed,
    Object? isAppleSilicon = null,
    Object? recommendedBatchSize = null,
  }) {
    return _then(_$AcceleratorInfoImpl(
      type: null == type
          ? _value.type
          : type // ignore: cast_nullable_to_non_nullable
              as AcceleratorType,
      name: null == name
          ? _value.name
          : name // ignore: cast_nullable_to_non_nullable
              as String,
      vramMB: null == vramMB
          ? _value.vramMB
          : vramMB // ignore: cast_nullable_to_non_nullable
              as int,
      computeCapability: freezed == computeCapability
          ? _value.computeCapability
          : computeCapability // ignore: cast_nullable_to_non_nullable
              as String?,
      isAppleSilicon: null == isAppleSilicon
          ? _value.isAppleSilicon
          : isAppleSilicon // ignore: cast_nullable_to_non_nullable
              as bool,
      recommendedBatchSize: null == recommendedBatchSize
          ? _value.recommendedBatchSize
          : recommendedBatchSize // ignore: cast_nullable_to_non_nullable
              as int,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$AcceleratorInfoImpl implements _AcceleratorInfo {
  const _$AcceleratorInfoImpl(
      {required this.type,
      required this.name,
      required this.vramMB,
      this.computeCapability,
      this.isAppleSilicon = false,
      required this.recommendedBatchSize});

  factory _$AcceleratorInfoImpl.fromJson(Map<String, dynamic> json) =>
      _$$AcceleratorInfoImplFromJson(json);

  @override
  final AcceleratorType type;
  @override
  final String name;
  @override
  final int vramMB;
  @override
  final String? computeCapability;
  @override
  @JsonKey()
  final bool isAppleSilicon;
  @override
  final int recommendedBatchSize;

  @override
  String toString() {
    return 'AcceleratorInfo(type: $type, name: $name, vramMB: $vramMB, computeCapability: $computeCapability, isAppleSilicon: $isAppleSilicon, recommendedBatchSize: $recommendedBatchSize)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$AcceleratorInfoImpl &&
            (identical(other.type, type) || other.type == type) &&
            (identical(other.name, name) || other.name == name) &&
            (identical(other.vramMB, vramMB) || other.vramMB == vramMB) &&
            (identical(other.computeCapability, computeCapability) ||
                other.computeCapability == computeCapability) &&
            (identical(other.isAppleSilicon, isAppleSilicon) ||
                other.isAppleSilicon == isAppleSilicon) &&
            (identical(other.recommendedBatchSize, recommendedBatchSize) ||
                other.recommendedBatchSize == recommendedBatchSize));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, type, name, vramMB,
      computeCapability, isAppleSilicon, recommendedBatchSize);

  /// Create a copy of AcceleratorInfo
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$AcceleratorInfoImplCopyWith<_$AcceleratorInfoImpl> get copyWith =>
      __$$AcceleratorInfoImplCopyWithImpl<_$AcceleratorInfoImpl>(
          this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$AcceleratorInfoImplToJson(
      this,
    );
  }
}

abstract class _AcceleratorInfo implements AcceleratorInfo {
  const factory _AcceleratorInfo(
      {required final AcceleratorType type,
      required final String name,
      required final int vramMB,
      final String? computeCapability,
      final bool isAppleSilicon,
      required final int recommendedBatchSize}) = _$AcceleratorInfoImpl;

  factory _AcceleratorInfo.fromJson(Map<String, dynamic> json) =
      _$AcceleratorInfoImpl.fromJson;

  @override
  AcceleratorType get type;
  @override
  String get name;
  @override
  int get vramMB;
  @override
  String? get computeCapability;
  @override
  bool get isAppleSilicon;
  @override
  int get recommendedBatchSize;

  /// Create a copy of AcceleratorInfo
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$AcceleratorInfoImplCopyWith<_$AcceleratorInfoImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

SystemCapabilities _$SystemCapabilitiesFromJson(Map<String, dynamic> json) {
  return _SystemCapabilities.fromJson(json);
}

/// @nodoc
mixin _$SystemCapabilities {
  int get cpuCores => throw _privateConstructorUsedError;
  int get ramMB => throw _privateConstructorUsedError;
  int get availableRamMB => throw _privateConstructorUsedError;
  int get diskSpaceMB => throw _privateConstructorUsedError;
  int get availableDiskSpaceMB => throw _privateConstructorUsedError;
  AcceleratorInfo? get accelerator => throw _privateConstructorUsedError;
  List<String> get supportedExecutionProviders =>
      throw _privateConstructorUsedError;

  /// Serializes this SystemCapabilities to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of SystemCapabilities
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $SystemCapabilitiesCopyWith<SystemCapabilities> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $SystemCapabilitiesCopyWith<$Res> {
  factory $SystemCapabilitiesCopyWith(
          SystemCapabilities value, $Res Function(SystemCapabilities) then) =
      _$SystemCapabilitiesCopyWithImpl<$Res, SystemCapabilities>;
  @useResult
  $Res call(
      {int cpuCores,
      int ramMB,
      int availableRamMB,
      int diskSpaceMB,
      int availableDiskSpaceMB,
      AcceleratorInfo? accelerator,
      List<String> supportedExecutionProviders});

  $AcceleratorInfoCopyWith<$Res>? get accelerator;
}

/// @nodoc
class _$SystemCapabilitiesCopyWithImpl<$Res, $Val extends SystemCapabilities>
    implements $SystemCapabilitiesCopyWith<$Res> {
  _$SystemCapabilitiesCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of SystemCapabilities
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? cpuCores = null,
    Object? ramMB = null,
    Object? availableRamMB = null,
    Object? diskSpaceMB = null,
    Object? availableDiskSpaceMB = null,
    Object? accelerator = freezed,
    Object? supportedExecutionProviders = null,
  }) {
    return _then(_value.copyWith(
      cpuCores: null == cpuCores
          ? _value.cpuCores
          : cpuCores // ignore: cast_nullable_to_non_nullable
              as int,
      ramMB: null == ramMB
          ? _value.ramMB
          : ramMB // ignore: cast_nullable_to_non_nullable
              as int,
      availableRamMB: null == availableRamMB
          ? _value.availableRamMB
          : availableRamMB // ignore: cast_nullable_to_non_nullable
              as int,
      diskSpaceMB: null == diskSpaceMB
          ? _value.diskSpaceMB
          : diskSpaceMB // ignore: cast_nullable_to_non_nullable
              as int,
      availableDiskSpaceMB: null == availableDiskSpaceMB
          ? _value.availableDiskSpaceMB
          : availableDiskSpaceMB // ignore: cast_nullable_to_non_nullable
              as int,
      accelerator: freezed == accelerator
          ? _value.accelerator
          : accelerator // ignore: cast_nullable_to_non_nullable
              as AcceleratorInfo?,
      supportedExecutionProviders: null == supportedExecutionProviders
          ? _value.supportedExecutionProviders
          : supportedExecutionProviders // ignore: cast_nullable_to_non_nullable
              as List<String>,
    ) as $Val);
  }

  /// Create a copy of SystemCapabilities
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $AcceleratorInfoCopyWith<$Res>? get accelerator {
    if (_value.accelerator == null) {
      return null;
    }

    return $AcceleratorInfoCopyWith<$Res>(_value.accelerator!, (value) {
      return _then(_value.copyWith(accelerator: value) as $Val);
    });
  }
}

/// @nodoc
abstract class _$$SystemCapabilitiesImplCopyWith<$Res>
    implements $SystemCapabilitiesCopyWith<$Res> {
  factory _$$SystemCapabilitiesImplCopyWith(_$SystemCapabilitiesImpl value,
          $Res Function(_$SystemCapabilitiesImpl) then) =
      __$$SystemCapabilitiesImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {int cpuCores,
      int ramMB,
      int availableRamMB,
      int diskSpaceMB,
      int availableDiskSpaceMB,
      AcceleratorInfo? accelerator,
      List<String> supportedExecutionProviders});

  @override
  $AcceleratorInfoCopyWith<$Res>? get accelerator;
}

/// @nodoc
class __$$SystemCapabilitiesImplCopyWithImpl<$Res>
    extends _$SystemCapabilitiesCopyWithImpl<$Res, _$SystemCapabilitiesImpl>
    implements _$$SystemCapabilitiesImplCopyWith<$Res> {
  __$$SystemCapabilitiesImplCopyWithImpl(_$SystemCapabilitiesImpl _value,
      $Res Function(_$SystemCapabilitiesImpl) _then)
      : super(_value, _then);

  /// Create a copy of SystemCapabilities
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? cpuCores = null,
    Object? ramMB = null,
    Object? availableRamMB = null,
    Object? diskSpaceMB = null,
    Object? availableDiskSpaceMB = null,
    Object? accelerator = freezed,
    Object? supportedExecutionProviders = null,
  }) {
    return _then(_$SystemCapabilitiesImpl(
      cpuCores: null == cpuCores
          ? _value.cpuCores
          : cpuCores // ignore: cast_nullable_to_non_nullable
              as int,
      ramMB: null == ramMB
          ? _value.ramMB
          : ramMB // ignore: cast_nullable_to_non_nullable
              as int,
      availableRamMB: null == availableRamMB
          ? _value.availableRamMB
          : availableRamMB // ignore: cast_nullable_to_non_nullable
              as int,
      diskSpaceMB: null == diskSpaceMB
          ? _value.diskSpaceMB
          : diskSpaceMB // ignore: cast_nullable_to_non_nullable
              as int,
      availableDiskSpaceMB: null == availableDiskSpaceMB
          ? _value.availableDiskSpaceMB
          : availableDiskSpaceMB // ignore: cast_nullable_to_non_nullable
              as int,
      accelerator: freezed == accelerator
          ? _value.accelerator
          : accelerator // ignore: cast_nullable_to_non_nullable
              as AcceleratorInfo?,
      supportedExecutionProviders: null == supportedExecutionProviders
          ? _value._supportedExecutionProviders
          : supportedExecutionProviders // ignore: cast_nullable_to_non_nullable
              as List<String>,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$SystemCapabilitiesImpl implements _SystemCapabilities {
  const _$SystemCapabilitiesImpl(
      {required this.cpuCores,
      required this.ramMB,
      required this.availableRamMB,
      required this.diskSpaceMB,
      required this.availableDiskSpaceMB,
      this.accelerator,
      final List<String> supportedExecutionProviders = const []})
      : _supportedExecutionProviders = supportedExecutionProviders;

  factory _$SystemCapabilitiesImpl.fromJson(Map<String, dynamic> json) =>
      _$$SystemCapabilitiesImplFromJson(json);

  @override
  final int cpuCores;
  @override
  final int ramMB;
  @override
  final int availableRamMB;
  @override
  final int diskSpaceMB;
  @override
  final int availableDiskSpaceMB;
  @override
  final AcceleratorInfo? accelerator;
  final List<String> _supportedExecutionProviders;
  @override
  @JsonKey()
  List<String> get supportedExecutionProviders {
    if (_supportedExecutionProviders is EqualUnmodifiableListView)
      return _supportedExecutionProviders;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_supportedExecutionProviders);
  }

  @override
  String toString() {
    return 'SystemCapabilities(cpuCores: $cpuCores, ramMB: $ramMB, availableRamMB: $availableRamMB, diskSpaceMB: $diskSpaceMB, availableDiskSpaceMB: $availableDiskSpaceMB, accelerator: $accelerator, supportedExecutionProviders: $supportedExecutionProviders)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$SystemCapabilitiesImpl &&
            (identical(other.cpuCores, cpuCores) ||
                other.cpuCores == cpuCores) &&
            (identical(other.ramMB, ramMB) || other.ramMB == ramMB) &&
            (identical(other.availableRamMB, availableRamMB) ||
                other.availableRamMB == availableRamMB) &&
            (identical(other.diskSpaceMB, diskSpaceMB) ||
                other.diskSpaceMB == diskSpaceMB) &&
            (identical(other.availableDiskSpaceMB, availableDiskSpaceMB) ||
                other.availableDiskSpaceMB == availableDiskSpaceMB) &&
            (identical(other.accelerator, accelerator) ||
                other.accelerator == accelerator) &&
            const DeepCollectionEquality().equals(
                other._supportedExecutionProviders,
                _supportedExecutionProviders));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
      runtimeType,
      cpuCores,
      ramMB,
      availableRamMB,
      diskSpaceMB,
      availableDiskSpaceMB,
      accelerator,
      const DeepCollectionEquality().hash(_supportedExecutionProviders));

  /// Create a copy of SystemCapabilities
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$SystemCapabilitiesImplCopyWith<_$SystemCapabilitiesImpl> get copyWith =>
      __$$SystemCapabilitiesImplCopyWithImpl<_$SystemCapabilitiesImpl>(
          this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$SystemCapabilitiesImplToJson(
      this,
    );
  }
}

abstract class _SystemCapabilities implements SystemCapabilities {
  const factory _SystemCapabilities(
          {required final int cpuCores,
          required final int ramMB,
          required final int availableRamMB,
          required final int diskSpaceMB,
          required final int availableDiskSpaceMB,
          final AcceleratorInfo? accelerator,
          final List<String> supportedExecutionProviders}) =
      _$SystemCapabilitiesImpl;

  factory _SystemCapabilities.fromJson(Map<String, dynamic> json) =
      _$SystemCapabilitiesImpl.fromJson;

  @override
  int get cpuCores;
  @override
  int get ramMB;
  @override
  int get availableRamMB;
  @override
  int get diskSpaceMB;
  @override
  int get availableDiskSpaceMB;
  @override
  AcceleratorInfo? get accelerator;
  @override
  List<String> get supportedExecutionProviders;

  /// Create a copy of SystemCapabilities
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$SystemCapabilitiesImplCopyWith<_$SystemCapabilitiesImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
