// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'gpu_config.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

GpuConfig _$GpuConfigFromJson(Map<String, dynamic> json) {
  return _GpuConfig.fromJson(json);
}

/// @nodoc
mixin _$GpuConfig {
  bool get useGpu => throw _privateConstructorUsedError;
  int get gpuDeviceIndex => throw _privateConstructorUsedError;
  String get onnxExecutionProvider => throw _privateConstructorUsedError;
  int get cpuThreads => throw _privateConstructorUsedError;
  int get batchSize => throw _privateConstructorUsedError;
  bool get useFp16 => throw _privateConstructorUsedError;

  /// Serializes this GpuConfig to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of GpuConfig
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $GpuConfigCopyWith<GpuConfig> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $GpuConfigCopyWith<$Res> {
  factory $GpuConfigCopyWith(GpuConfig value, $Res Function(GpuConfig) then) =
      _$GpuConfigCopyWithImpl<$Res, GpuConfig>;
  @useResult
  $Res call(
      {bool useGpu,
      int gpuDeviceIndex,
      String onnxExecutionProvider,
      int cpuThreads,
      int batchSize,
      bool useFp16});
}

/// @nodoc
class _$GpuConfigCopyWithImpl<$Res, $Val extends GpuConfig>
    implements $GpuConfigCopyWith<$Res> {
  _$GpuConfigCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of GpuConfig
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? useGpu = null,
    Object? gpuDeviceIndex = null,
    Object? onnxExecutionProvider = null,
    Object? cpuThreads = null,
    Object? batchSize = null,
    Object? useFp16 = null,
  }) {
    return _then(_value.copyWith(
      useGpu: null == useGpu
          ? _value.useGpu
          : useGpu // ignore: cast_nullable_to_non_nullable
              as bool,
      gpuDeviceIndex: null == gpuDeviceIndex
          ? _value.gpuDeviceIndex
          : gpuDeviceIndex // ignore: cast_nullable_to_non_nullable
              as int,
      onnxExecutionProvider: null == onnxExecutionProvider
          ? _value.onnxExecutionProvider
          : onnxExecutionProvider // ignore: cast_nullable_to_non_nullable
              as String,
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
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$GpuConfigImplCopyWith<$Res>
    implements $GpuConfigCopyWith<$Res> {
  factory _$$GpuConfigImplCopyWith(
          _$GpuConfigImpl value, $Res Function(_$GpuConfigImpl) then) =
      __$$GpuConfigImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {bool useGpu,
      int gpuDeviceIndex,
      String onnxExecutionProvider,
      int cpuThreads,
      int batchSize,
      bool useFp16});
}

/// @nodoc
class __$$GpuConfigImplCopyWithImpl<$Res>
    extends _$GpuConfigCopyWithImpl<$Res, _$GpuConfigImpl>
    implements _$$GpuConfigImplCopyWith<$Res> {
  __$$GpuConfigImplCopyWithImpl(
      _$GpuConfigImpl _value, $Res Function(_$GpuConfigImpl) _then)
      : super(_value, _then);

  /// Create a copy of GpuConfig
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? useGpu = null,
    Object? gpuDeviceIndex = null,
    Object? onnxExecutionProvider = null,
    Object? cpuThreads = null,
    Object? batchSize = null,
    Object? useFp16 = null,
  }) {
    return _then(_$GpuConfigImpl(
      useGpu: null == useGpu
          ? _value.useGpu
          : useGpu // ignore: cast_nullable_to_non_nullable
              as bool,
      gpuDeviceIndex: null == gpuDeviceIndex
          ? _value.gpuDeviceIndex
          : gpuDeviceIndex // ignore: cast_nullable_to_non_nullable
              as int,
      onnxExecutionProvider: null == onnxExecutionProvider
          ? _value.onnxExecutionProvider
          : onnxExecutionProvider // ignore: cast_nullable_to_non_nullable
              as String,
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
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$GpuConfigImpl extends _GpuConfig {
  const _$GpuConfigImpl(
      {this.useGpu = true,
      this.gpuDeviceIndex = 0,
      this.onnxExecutionProvider = 'auto',
      this.cpuThreads = 4,
      this.batchSize = 8,
      this.useFp16 = false})
      : super._();

  factory _$GpuConfigImpl.fromJson(Map<String, dynamic> json) =>
      _$$GpuConfigImplFromJson(json);

  @override
  @JsonKey()
  final bool useGpu;
  @override
  @JsonKey()
  final int gpuDeviceIndex;
  @override
  @JsonKey()
  final String onnxExecutionProvider;
  @override
  @JsonKey()
  final int cpuThreads;
  @override
  @JsonKey()
  final int batchSize;
  @override
  @JsonKey()
  final bool useFp16;

  @override
  String toString() {
    return 'GpuConfig(useGpu: $useGpu, gpuDeviceIndex: $gpuDeviceIndex, onnxExecutionProvider: $onnxExecutionProvider, cpuThreads: $cpuThreads, batchSize: $batchSize, useFp16: $useFp16)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$GpuConfigImpl &&
            (identical(other.useGpu, useGpu) || other.useGpu == useGpu) &&
            (identical(other.gpuDeviceIndex, gpuDeviceIndex) ||
                other.gpuDeviceIndex == gpuDeviceIndex) &&
            (identical(other.onnxExecutionProvider, onnxExecutionProvider) ||
                other.onnxExecutionProvider == onnxExecutionProvider) &&
            (identical(other.cpuThreads, cpuThreads) ||
                other.cpuThreads == cpuThreads) &&
            (identical(other.batchSize, batchSize) ||
                other.batchSize == batchSize) &&
            (identical(other.useFp16, useFp16) || other.useFp16 == useFp16));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, useGpu, gpuDeviceIndex,
      onnxExecutionProvider, cpuThreads, batchSize, useFp16);

  /// Create a copy of GpuConfig
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$GpuConfigImplCopyWith<_$GpuConfigImpl> get copyWith =>
      __$$GpuConfigImplCopyWithImpl<_$GpuConfigImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$GpuConfigImplToJson(
      this,
    );
  }
}

abstract class _GpuConfig extends GpuConfig {
  const factory _GpuConfig(
      {final bool useGpu,
      final int gpuDeviceIndex,
      final String onnxExecutionProvider,
      final int cpuThreads,
      final int batchSize,
      final bool useFp16}) = _$GpuConfigImpl;
  const _GpuConfig._() : super._();

  factory _GpuConfig.fromJson(Map<String, dynamic> json) =
      _$GpuConfigImpl.fromJson;

  @override
  bool get useGpu;
  @override
  int get gpuDeviceIndex;
  @override
  String get onnxExecutionProvider;
  @override
  int get cpuThreads;
  @override
  int get batchSize;
  @override
  bool get useFp16;

  /// Create a copy of GpuConfig
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$GpuConfigImplCopyWith<_$GpuConfigImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
