// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'model_info.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

HardwareInfo _$HardwareInfoFromJson(Map<String, dynamic> json) {
  return _HardwareInfo.fromJson(json);
}

/// @nodoc
mixin _$HardwareInfo {
  /// Available RAM in bytes
  int get availableRamBytes => throw _privateConstructorUsedError;

  /// Available VRAM in bytes (0 if no GPU)
  int get availableVramBytes => throw _privateConstructorUsedError;

  /// Whether GPU is available
  bool get hasGpu => throw _privateConstructorUsedError;

  /// GPU name if available
  String? get gpuName => throw _privateConstructorUsedError;

  /// Number of CPU cores
  int get cpuCores => throw _privateConstructorUsedError;

  /// Whether AVX2 instructions are supported
  bool get supportsAvx2 => throw _privateConstructorUsedError;

  /// Whether CUDA is available
  bool get supportsCuda => throw _privateConstructorUsedError;

  /// Whether Metal is available (macOS)
  bool get supportsMetal => throw _privateConstructorUsedError;

  /// Operating system
  String? get operatingSystem => throw _privateConstructorUsedError;

  /// Serializes this HardwareInfo to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of HardwareInfo
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $HardwareInfoCopyWith<HardwareInfo> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $HardwareInfoCopyWith<$Res> {
  factory $HardwareInfoCopyWith(
          HardwareInfo value, $Res Function(HardwareInfo) then) =
      _$HardwareInfoCopyWithImpl<$Res, HardwareInfo>;
  @useResult
  $Res call(
      {int availableRamBytes,
      int availableVramBytes,
      bool hasGpu,
      String? gpuName,
      int cpuCores,
      bool supportsAvx2,
      bool supportsCuda,
      bool supportsMetal,
      String? operatingSystem});
}

/// @nodoc
class _$HardwareInfoCopyWithImpl<$Res, $Val extends HardwareInfo>
    implements $HardwareInfoCopyWith<$Res> {
  _$HardwareInfoCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of HardwareInfo
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? availableRamBytes = null,
    Object? availableVramBytes = null,
    Object? hasGpu = null,
    Object? gpuName = freezed,
    Object? cpuCores = null,
    Object? supportsAvx2 = null,
    Object? supportsCuda = null,
    Object? supportsMetal = null,
    Object? operatingSystem = freezed,
  }) {
    return _then(_value.copyWith(
      availableRamBytes: null == availableRamBytes
          ? _value.availableRamBytes
          : availableRamBytes // ignore: cast_nullable_to_non_nullable
              as int,
      availableVramBytes: null == availableVramBytes
          ? _value.availableVramBytes
          : availableVramBytes // ignore: cast_nullable_to_non_nullable
              as int,
      hasGpu: null == hasGpu
          ? _value.hasGpu
          : hasGpu // ignore: cast_nullable_to_non_nullable
              as bool,
      gpuName: freezed == gpuName
          ? _value.gpuName
          : gpuName // ignore: cast_nullable_to_non_nullable
              as String?,
      cpuCores: null == cpuCores
          ? _value.cpuCores
          : cpuCores // ignore: cast_nullable_to_non_nullable
              as int,
      supportsAvx2: null == supportsAvx2
          ? _value.supportsAvx2
          : supportsAvx2 // ignore: cast_nullable_to_non_nullable
              as bool,
      supportsCuda: null == supportsCuda
          ? _value.supportsCuda
          : supportsCuda // ignore: cast_nullable_to_non_nullable
              as bool,
      supportsMetal: null == supportsMetal
          ? _value.supportsMetal
          : supportsMetal // ignore: cast_nullable_to_non_nullable
              as bool,
      operatingSystem: freezed == operatingSystem
          ? _value.operatingSystem
          : operatingSystem // ignore: cast_nullable_to_non_nullable
              as String?,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$HardwareInfoImplCopyWith<$Res>
    implements $HardwareInfoCopyWith<$Res> {
  factory _$$HardwareInfoImplCopyWith(
          _$HardwareInfoImpl value, $Res Function(_$HardwareInfoImpl) then) =
      __$$HardwareInfoImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {int availableRamBytes,
      int availableVramBytes,
      bool hasGpu,
      String? gpuName,
      int cpuCores,
      bool supportsAvx2,
      bool supportsCuda,
      bool supportsMetal,
      String? operatingSystem});
}

/// @nodoc
class __$$HardwareInfoImplCopyWithImpl<$Res>
    extends _$HardwareInfoCopyWithImpl<$Res, _$HardwareInfoImpl>
    implements _$$HardwareInfoImplCopyWith<$Res> {
  __$$HardwareInfoImplCopyWithImpl(
      _$HardwareInfoImpl _value, $Res Function(_$HardwareInfoImpl) _then)
      : super(_value, _then);

  /// Create a copy of HardwareInfo
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? availableRamBytes = null,
    Object? availableVramBytes = null,
    Object? hasGpu = null,
    Object? gpuName = freezed,
    Object? cpuCores = null,
    Object? supportsAvx2 = null,
    Object? supportsCuda = null,
    Object? supportsMetal = null,
    Object? operatingSystem = freezed,
  }) {
    return _then(_$HardwareInfoImpl(
      availableRamBytes: null == availableRamBytes
          ? _value.availableRamBytes
          : availableRamBytes // ignore: cast_nullable_to_non_nullable
              as int,
      availableVramBytes: null == availableVramBytes
          ? _value.availableVramBytes
          : availableVramBytes // ignore: cast_nullable_to_non_nullable
              as int,
      hasGpu: null == hasGpu
          ? _value.hasGpu
          : hasGpu // ignore: cast_nullable_to_non_nullable
              as bool,
      gpuName: freezed == gpuName
          ? _value.gpuName
          : gpuName // ignore: cast_nullable_to_non_nullable
              as String?,
      cpuCores: null == cpuCores
          ? _value.cpuCores
          : cpuCores // ignore: cast_nullable_to_non_nullable
              as int,
      supportsAvx2: null == supportsAvx2
          ? _value.supportsAvx2
          : supportsAvx2 // ignore: cast_nullable_to_non_nullable
              as bool,
      supportsCuda: null == supportsCuda
          ? _value.supportsCuda
          : supportsCuda // ignore: cast_nullable_to_non_nullable
              as bool,
      supportsMetal: null == supportsMetal
          ? _value.supportsMetal
          : supportsMetal // ignore: cast_nullable_to_non_nullable
              as bool,
      operatingSystem: freezed == operatingSystem
          ? _value.operatingSystem
          : operatingSystem // ignore: cast_nullable_to_non_nullable
              as String?,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$HardwareInfoImpl implements _HardwareInfo {
  const _$HardwareInfoImpl(
      {required this.availableRamBytes,
      this.availableVramBytes = 0,
      this.hasGpu = false,
      this.gpuName,
      this.cpuCores = 4,
      this.supportsAvx2 = false,
      this.supportsCuda = false,
      this.supportsMetal = false,
      this.operatingSystem});

  factory _$HardwareInfoImpl.fromJson(Map<String, dynamic> json) =>
      _$$HardwareInfoImplFromJson(json);

  /// Available RAM in bytes
  @override
  final int availableRamBytes;

  /// Available VRAM in bytes (0 if no GPU)
  @override
  @JsonKey()
  final int availableVramBytes;

  /// Whether GPU is available
  @override
  @JsonKey()
  final bool hasGpu;

  /// GPU name if available
  @override
  final String? gpuName;

  /// Number of CPU cores
  @override
  @JsonKey()
  final int cpuCores;

  /// Whether AVX2 instructions are supported
  @override
  @JsonKey()
  final bool supportsAvx2;

  /// Whether CUDA is available
  @override
  @JsonKey()
  final bool supportsCuda;

  /// Whether Metal is available (macOS)
  @override
  @JsonKey()
  final bool supportsMetal;

  /// Operating system
  @override
  final String? operatingSystem;

  @override
  String toString() {
    return 'HardwareInfo(availableRamBytes: $availableRamBytes, availableVramBytes: $availableVramBytes, hasGpu: $hasGpu, gpuName: $gpuName, cpuCores: $cpuCores, supportsAvx2: $supportsAvx2, supportsCuda: $supportsCuda, supportsMetal: $supportsMetal, operatingSystem: $operatingSystem)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$HardwareInfoImpl &&
            (identical(other.availableRamBytes, availableRamBytes) ||
                other.availableRamBytes == availableRamBytes) &&
            (identical(other.availableVramBytes, availableVramBytes) ||
                other.availableVramBytes == availableVramBytes) &&
            (identical(other.hasGpu, hasGpu) || other.hasGpu == hasGpu) &&
            (identical(other.gpuName, gpuName) || other.gpuName == gpuName) &&
            (identical(other.cpuCores, cpuCores) ||
                other.cpuCores == cpuCores) &&
            (identical(other.supportsAvx2, supportsAvx2) ||
                other.supportsAvx2 == supportsAvx2) &&
            (identical(other.supportsCuda, supportsCuda) ||
                other.supportsCuda == supportsCuda) &&
            (identical(other.supportsMetal, supportsMetal) ||
                other.supportsMetal == supportsMetal) &&
            (identical(other.operatingSystem, operatingSystem) ||
                other.operatingSystem == operatingSystem));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
      runtimeType,
      availableRamBytes,
      availableVramBytes,
      hasGpu,
      gpuName,
      cpuCores,
      supportsAvx2,
      supportsCuda,
      supportsMetal,
      operatingSystem);

  /// Create a copy of HardwareInfo
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$HardwareInfoImplCopyWith<_$HardwareInfoImpl> get copyWith =>
      __$$HardwareInfoImplCopyWithImpl<_$HardwareInfoImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$HardwareInfoImplToJson(
      this,
    );
  }
}

abstract class _HardwareInfo implements HardwareInfo {
  const factory _HardwareInfo(
      {required final int availableRamBytes,
      final int availableVramBytes,
      final bool hasGpu,
      final String? gpuName,
      final int cpuCores,
      final bool supportsAvx2,
      final bool supportsCuda,
      final bool supportsMetal,
      final String? operatingSystem}) = _$HardwareInfoImpl;

  factory _HardwareInfo.fromJson(Map<String, dynamic> json) =
      _$HardwareInfoImpl.fromJson;

  /// Available RAM in bytes
  @override
  int get availableRamBytes;

  /// Available VRAM in bytes (0 if no GPU)
  @override
  int get availableVramBytes;

  /// Whether GPU is available
  @override
  bool get hasGpu;

  /// GPU name if available
  @override
  String? get gpuName;

  /// Number of CPU cores
  @override
  int get cpuCores;

  /// Whether AVX2 instructions are supported
  @override
  bool get supportsAvx2;

  /// Whether CUDA is available
  @override
  bool get supportsCuda;

  /// Whether Metal is available (macOS)
  @override
  bool get supportsMetal;

  /// Operating system
  @override
  String? get operatingSystem;

  /// Create a copy of HardwareInfo
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$HardwareInfoImplCopyWith<_$HardwareInfoImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

ModelInfo _$ModelInfoFromJson(Map<String, dynamic> json) {
  return _ModelInfo.fromJson(json);
}

/// @nodoc
mixin _$ModelInfo {
  /// Unique identifier for the model
  String get id => throw _privateConstructorUsedError;

  /// Human-readable display name
  String get displayName => throw _privateConstructorUsedError;

  /// Description of the model's capabilities
  String get description => throw _privateConstructorUsedError;

  /// Type of model (ASR or visual)
  ModelType get type => throw _privateConstructorUsedError;

  /// Model file size in bytes
  int get sizeBytes => throw _privateConstructorUsedError;

  /// Accuracy percentage (0-100)
  int get accuracyPercent => throw _privateConstructorUsedError;

  /// Speed rating (1-5, where 5 is fastest)
  int get speedRating => throw _privateConstructorUsedError;

  /// Optional badge text (e.g., "Recommended", "New", "Beta")
  String? get badge => throw _privateConstructorUsedError;

  /// Minimum RAM required in bytes
  int get minRamBytes => throw _privateConstructorUsedError;

  /// Minimum VRAM required in bytes (0 if CPU-only)
  int get minVramBytes => throw _privateConstructorUsedError;

  /// Whether GPU is required
  bool get requiresGpu => throw _privateConstructorUsedError;

  /// Whether AVX2 is required
  bool get requiresAvx2 => throw _privateConstructorUsedError;

  /// Supported languages (for ASR models)
  List<String>? get supportedLanguages => throw _privateConstructorUsedError;

  /// Download URL
  String? get downloadUrl => throw _privateConstructorUsedError;

  /// Model version
  String? get version => throw _privateConstructorUsedError;

  /// Release date
  DateTime? get releaseDate => throw _privateConstructorUsedError;

  /// Additional metadata
  Map<String, dynamic>? get metadata => throw _privateConstructorUsedError;

  /// Serializes this ModelInfo to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of ModelInfo
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $ModelInfoCopyWith<ModelInfo> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $ModelInfoCopyWith<$Res> {
  factory $ModelInfoCopyWith(ModelInfo value, $Res Function(ModelInfo) then) =
      _$ModelInfoCopyWithImpl<$Res, ModelInfo>;
  @useResult
  $Res call(
      {String id,
      String displayName,
      String description,
      ModelType type,
      int sizeBytes,
      int accuracyPercent,
      int speedRating,
      String? badge,
      int minRamBytes,
      int minVramBytes,
      bool requiresGpu,
      bool requiresAvx2,
      List<String>? supportedLanguages,
      String? downloadUrl,
      String? version,
      DateTime? releaseDate,
      Map<String, dynamic>? metadata});
}

/// @nodoc
class _$ModelInfoCopyWithImpl<$Res, $Val extends ModelInfo>
    implements $ModelInfoCopyWith<$Res> {
  _$ModelInfoCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of ModelInfo
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? displayName = null,
    Object? description = null,
    Object? type = null,
    Object? sizeBytes = null,
    Object? accuracyPercent = null,
    Object? speedRating = null,
    Object? badge = freezed,
    Object? minRamBytes = null,
    Object? minVramBytes = null,
    Object? requiresGpu = null,
    Object? requiresAvx2 = null,
    Object? supportedLanguages = freezed,
    Object? downloadUrl = freezed,
    Object? version = freezed,
    Object? releaseDate = freezed,
    Object? metadata = freezed,
  }) {
    return _then(_value.copyWith(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      displayName: null == displayName
          ? _value.displayName
          : displayName // ignore: cast_nullable_to_non_nullable
              as String,
      description: null == description
          ? _value.description
          : description // ignore: cast_nullable_to_non_nullable
              as String,
      type: null == type
          ? _value.type
          : type // ignore: cast_nullable_to_non_nullable
              as ModelType,
      sizeBytes: null == sizeBytes
          ? _value.sizeBytes
          : sizeBytes // ignore: cast_nullable_to_non_nullable
              as int,
      accuracyPercent: null == accuracyPercent
          ? _value.accuracyPercent
          : accuracyPercent // ignore: cast_nullable_to_non_nullable
              as int,
      speedRating: null == speedRating
          ? _value.speedRating
          : speedRating // ignore: cast_nullable_to_non_nullable
              as int,
      badge: freezed == badge
          ? _value.badge
          : badge // ignore: cast_nullable_to_non_nullable
              as String?,
      minRamBytes: null == minRamBytes
          ? _value.minRamBytes
          : minRamBytes // ignore: cast_nullable_to_non_nullable
              as int,
      minVramBytes: null == minVramBytes
          ? _value.minVramBytes
          : minVramBytes // ignore: cast_nullable_to_non_nullable
              as int,
      requiresGpu: null == requiresGpu
          ? _value.requiresGpu
          : requiresGpu // ignore: cast_nullable_to_non_nullable
              as bool,
      requiresAvx2: null == requiresAvx2
          ? _value.requiresAvx2
          : requiresAvx2 // ignore: cast_nullable_to_non_nullable
              as bool,
      supportedLanguages: freezed == supportedLanguages
          ? _value.supportedLanguages
          : supportedLanguages // ignore: cast_nullable_to_non_nullable
              as List<String>?,
      downloadUrl: freezed == downloadUrl
          ? _value.downloadUrl
          : downloadUrl // ignore: cast_nullable_to_non_nullable
              as String?,
      version: freezed == version
          ? _value.version
          : version // ignore: cast_nullable_to_non_nullable
              as String?,
      releaseDate: freezed == releaseDate
          ? _value.releaseDate
          : releaseDate // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      metadata: freezed == metadata
          ? _value.metadata
          : metadata // ignore: cast_nullable_to_non_nullable
              as Map<String, dynamic>?,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$ModelInfoImplCopyWith<$Res>
    implements $ModelInfoCopyWith<$Res> {
  factory _$$ModelInfoImplCopyWith(
          _$ModelInfoImpl value, $Res Function(_$ModelInfoImpl) then) =
      __$$ModelInfoImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String id,
      String displayName,
      String description,
      ModelType type,
      int sizeBytes,
      int accuracyPercent,
      int speedRating,
      String? badge,
      int minRamBytes,
      int minVramBytes,
      bool requiresGpu,
      bool requiresAvx2,
      List<String>? supportedLanguages,
      String? downloadUrl,
      String? version,
      DateTime? releaseDate,
      Map<String, dynamic>? metadata});
}

/// @nodoc
class __$$ModelInfoImplCopyWithImpl<$Res>
    extends _$ModelInfoCopyWithImpl<$Res, _$ModelInfoImpl>
    implements _$$ModelInfoImplCopyWith<$Res> {
  __$$ModelInfoImplCopyWithImpl(
      _$ModelInfoImpl _value, $Res Function(_$ModelInfoImpl) _then)
      : super(_value, _then);

  /// Create a copy of ModelInfo
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? displayName = null,
    Object? description = null,
    Object? type = null,
    Object? sizeBytes = null,
    Object? accuracyPercent = null,
    Object? speedRating = null,
    Object? badge = freezed,
    Object? minRamBytes = null,
    Object? minVramBytes = null,
    Object? requiresGpu = null,
    Object? requiresAvx2 = null,
    Object? supportedLanguages = freezed,
    Object? downloadUrl = freezed,
    Object? version = freezed,
    Object? releaseDate = freezed,
    Object? metadata = freezed,
  }) {
    return _then(_$ModelInfoImpl(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      displayName: null == displayName
          ? _value.displayName
          : displayName // ignore: cast_nullable_to_non_nullable
              as String,
      description: null == description
          ? _value.description
          : description // ignore: cast_nullable_to_non_nullable
              as String,
      type: null == type
          ? _value.type
          : type // ignore: cast_nullable_to_non_nullable
              as ModelType,
      sizeBytes: null == sizeBytes
          ? _value.sizeBytes
          : sizeBytes // ignore: cast_nullable_to_non_nullable
              as int,
      accuracyPercent: null == accuracyPercent
          ? _value.accuracyPercent
          : accuracyPercent // ignore: cast_nullable_to_non_nullable
              as int,
      speedRating: null == speedRating
          ? _value.speedRating
          : speedRating // ignore: cast_nullable_to_non_nullable
              as int,
      badge: freezed == badge
          ? _value.badge
          : badge // ignore: cast_nullable_to_non_nullable
              as String?,
      minRamBytes: null == minRamBytes
          ? _value.minRamBytes
          : minRamBytes // ignore: cast_nullable_to_non_nullable
              as int,
      minVramBytes: null == minVramBytes
          ? _value.minVramBytes
          : minVramBytes // ignore: cast_nullable_to_non_nullable
              as int,
      requiresGpu: null == requiresGpu
          ? _value.requiresGpu
          : requiresGpu // ignore: cast_nullable_to_non_nullable
              as bool,
      requiresAvx2: null == requiresAvx2
          ? _value.requiresAvx2
          : requiresAvx2 // ignore: cast_nullable_to_non_nullable
              as bool,
      supportedLanguages: freezed == supportedLanguages
          ? _value._supportedLanguages
          : supportedLanguages // ignore: cast_nullable_to_non_nullable
              as List<String>?,
      downloadUrl: freezed == downloadUrl
          ? _value.downloadUrl
          : downloadUrl // ignore: cast_nullable_to_non_nullable
              as String?,
      version: freezed == version
          ? _value.version
          : version // ignore: cast_nullable_to_non_nullable
              as String?,
      releaseDate: freezed == releaseDate
          ? _value.releaseDate
          : releaseDate // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      metadata: freezed == metadata
          ? _value._metadata
          : metadata // ignore: cast_nullable_to_non_nullable
              as Map<String, dynamic>?,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$ModelInfoImpl extends _ModelInfo {
  const _$ModelInfoImpl(
      {required this.id,
      required this.displayName,
      required this.description,
      required this.type,
      required this.sizeBytes,
      required this.accuracyPercent,
      required this.speedRating,
      this.badge,
      this.minRamBytes = 0,
      this.minVramBytes = 0,
      this.requiresGpu = false,
      this.requiresAvx2 = false,
      final List<String>? supportedLanguages,
      this.downloadUrl,
      this.version,
      this.releaseDate,
      final Map<String, dynamic>? metadata})
      : _supportedLanguages = supportedLanguages,
        _metadata = metadata,
        super._();

  factory _$ModelInfoImpl.fromJson(Map<String, dynamic> json) =>
      _$$ModelInfoImplFromJson(json);

  /// Unique identifier for the model
  @override
  final String id;

  /// Human-readable display name
  @override
  final String displayName;

  /// Description of the model's capabilities
  @override
  final String description;

  /// Type of model (ASR or visual)
  @override
  final ModelType type;

  /// Model file size in bytes
  @override
  final int sizeBytes;

  /// Accuracy percentage (0-100)
  @override
  final int accuracyPercent;

  /// Speed rating (1-5, where 5 is fastest)
  @override
  final int speedRating;

  /// Optional badge text (e.g., "Recommended", "New", "Beta")
  @override
  final String? badge;

  /// Minimum RAM required in bytes
  @override
  @JsonKey()
  final int minRamBytes;

  /// Minimum VRAM required in bytes (0 if CPU-only)
  @override
  @JsonKey()
  final int minVramBytes;

  /// Whether GPU is required
  @override
  @JsonKey()
  final bool requiresGpu;

  /// Whether AVX2 is required
  @override
  @JsonKey()
  final bool requiresAvx2;

  /// Supported languages (for ASR models)
  final List<String>? _supportedLanguages;

  /// Supported languages (for ASR models)
  @override
  List<String>? get supportedLanguages {
    final value = _supportedLanguages;
    if (value == null) return null;
    if (_supportedLanguages is EqualUnmodifiableListView)
      return _supportedLanguages;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(value);
  }

  /// Download URL
  @override
  final String? downloadUrl;

  /// Model version
  @override
  final String? version;

  /// Release date
  @override
  final DateTime? releaseDate;

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
    return 'ModelInfo(id: $id, displayName: $displayName, description: $description, type: $type, sizeBytes: $sizeBytes, accuracyPercent: $accuracyPercent, speedRating: $speedRating, badge: $badge, minRamBytes: $minRamBytes, minVramBytes: $minVramBytes, requiresGpu: $requiresGpu, requiresAvx2: $requiresAvx2, supportedLanguages: $supportedLanguages, downloadUrl: $downloadUrl, version: $version, releaseDate: $releaseDate, metadata: $metadata)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$ModelInfoImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.displayName, displayName) ||
                other.displayName == displayName) &&
            (identical(other.description, description) ||
                other.description == description) &&
            (identical(other.type, type) || other.type == type) &&
            (identical(other.sizeBytes, sizeBytes) ||
                other.sizeBytes == sizeBytes) &&
            (identical(other.accuracyPercent, accuracyPercent) ||
                other.accuracyPercent == accuracyPercent) &&
            (identical(other.speedRating, speedRating) ||
                other.speedRating == speedRating) &&
            (identical(other.badge, badge) || other.badge == badge) &&
            (identical(other.minRamBytes, minRamBytes) ||
                other.minRamBytes == minRamBytes) &&
            (identical(other.minVramBytes, minVramBytes) ||
                other.minVramBytes == minVramBytes) &&
            (identical(other.requiresGpu, requiresGpu) ||
                other.requiresGpu == requiresGpu) &&
            (identical(other.requiresAvx2, requiresAvx2) ||
                other.requiresAvx2 == requiresAvx2) &&
            const DeepCollectionEquality()
                .equals(other._supportedLanguages, _supportedLanguages) &&
            (identical(other.downloadUrl, downloadUrl) ||
                other.downloadUrl == downloadUrl) &&
            (identical(other.version, version) || other.version == version) &&
            (identical(other.releaseDate, releaseDate) ||
                other.releaseDate == releaseDate) &&
            const DeepCollectionEquality().equals(other._metadata, _metadata));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
      runtimeType,
      id,
      displayName,
      description,
      type,
      sizeBytes,
      accuracyPercent,
      speedRating,
      badge,
      minRamBytes,
      minVramBytes,
      requiresGpu,
      requiresAvx2,
      const DeepCollectionEquality().hash(_supportedLanguages),
      downloadUrl,
      version,
      releaseDate,
      const DeepCollectionEquality().hash(_metadata));

  /// Create a copy of ModelInfo
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$ModelInfoImplCopyWith<_$ModelInfoImpl> get copyWith =>
      __$$ModelInfoImplCopyWithImpl<_$ModelInfoImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$ModelInfoImplToJson(
      this,
    );
  }
}

abstract class _ModelInfo extends ModelInfo {
  const factory _ModelInfo(
      {required final String id,
      required final String displayName,
      required final String description,
      required final ModelType type,
      required final int sizeBytes,
      required final int accuracyPercent,
      required final int speedRating,
      final String? badge,
      final int minRamBytes,
      final int minVramBytes,
      final bool requiresGpu,
      final bool requiresAvx2,
      final List<String>? supportedLanguages,
      final String? downloadUrl,
      final String? version,
      final DateTime? releaseDate,
      final Map<String, dynamic>? metadata}) = _$ModelInfoImpl;
  const _ModelInfo._() : super._();

  factory _ModelInfo.fromJson(Map<String, dynamic> json) =
      _$ModelInfoImpl.fromJson;

  /// Unique identifier for the model
  @override
  String get id;

  /// Human-readable display name
  @override
  String get displayName;

  /// Description of the model's capabilities
  @override
  String get description;

  /// Type of model (ASR or visual)
  @override
  ModelType get type;

  /// Model file size in bytes
  @override
  int get sizeBytes;

  /// Accuracy percentage (0-100)
  @override
  int get accuracyPercent;

  /// Speed rating (1-5, where 5 is fastest)
  @override
  int get speedRating;

  /// Optional badge text (e.g., "Recommended", "New", "Beta")
  @override
  String? get badge;

  /// Minimum RAM required in bytes
  @override
  int get minRamBytes;

  /// Minimum VRAM required in bytes (0 if CPU-only)
  @override
  int get minVramBytes;

  /// Whether GPU is required
  @override
  bool get requiresGpu;

  /// Whether AVX2 is required
  @override
  bool get requiresAvx2;

  /// Supported languages (for ASR models)
  @override
  List<String>? get supportedLanguages;

  /// Download URL
  @override
  String? get downloadUrl;

  /// Model version
  @override
  String? get version;

  /// Release date
  @override
  DateTime? get releaseDate;

  /// Additional metadata
  @override
  Map<String, dynamic>? get metadata;

  /// Create a copy of ModelInfo
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$ModelInfoImplCopyWith<_$ModelInfoImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
