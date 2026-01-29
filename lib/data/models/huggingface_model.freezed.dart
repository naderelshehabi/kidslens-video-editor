// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'huggingface_model.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

HuggingFaceModel _$HuggingFaceModelFromJson(Map<String, dynamic> json) {
  return _HuggingFaceModel.fromJson(json);
}

/// @nodoc
mixin _$HuggingFaceModel {
  /// Unique identifier for the model (e.g., 'whisper-tiny', 'nsfw-mobilenet-v2')
  String get id => throw _privateConstructorUsedError;

  /// Human-readable display name
  String get displayName => throw _privateConstructorUsedError;

  /// HuggingFace repository ID (e.g., 'ggerganov/whisper.cpp')
  String get huggingFaceId => throw _privateConstructorUsedError;

  /// Model file name in the repository (e.g., 'ggml-tiny.bin')
  String get fileName => throw _privateConstructorUsedError;

  /// Human-readable parameter count (e.g., '39M', '1.55B')
  String get parameters => throw _privateConstructorUsedError;

  /// Numeric parameter count for sorting (e.g., 39000000)
  int get parameterCount => throw _privateConstructorUsedError;

  /// Model file size in bytes
  int get sizeBytes => throw _privateConstructorUsedError;

  /// RAM required to run the model in bytes
  int get ramRequired => throw _privateConstructorUsedError;

  /// Speed multiplier relative to realtime (e.g., 10.0 = 10x realtime)
  double get speedMultiplier => throw _privateConstructorUsedError;

  /// Accuracy percentage (0-100)
  int get accuracyPercent => throw _privateConstructorUsedError;

  /// Type of model
  HuggingFaceModelType get modelType => throw _privateConstructorUsedError;

  /// Supported languages (for ASR models, empty for visual models)
  List<String> get languages => throw _privateConstructorUsedError;

  /// Optional badge text (e.g., 'Recommended', 'Best Accuracy', 'Best Value')
  String? get badge => throw _privateConstructorUsedError;

  /// Optional description of the model
  String? get description => throw _privateConstructorUsedError;

  /// Whether this model requires a GPU
  bool get requiresGpu => throw _privateConstructorUsedError;

  /// Minimum VRAM required in bytes (0 if CPU-only)
  int get minVramBytes => throw _privateConstructorUsedError;

  /// Model license (e.g., 'MIT', 'Apache-2.0')
  String get license => throw _privateConstructorUsedError;

  /// Serializes this HuggingFaceModel to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of HuggingFaceModel
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $HuggingFaceModelCopyWith<HuggingFaceModel> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $HuggingFaceModelCopyWith<$Res> {
  factory $HuggingFaceModelCopyWith(
          HuggingFaceModel value, $Res Function(HuggingFaceModel) then) =
      _$HuggingFaceModelCopyWithImpl<$Res, HuggingFaceModel>;
  @useResult
  $Res call(
      {String id,
      String displayName,
      String huggingFaceId,
      String fileName,
      String parameters,
      int parameterCount,
      int sizeBytes,
      int ramRequired,
      double speedMultiplier,
      int accuracyPercent,
      HuggingFaceModelType modelType,
      List<String> languages,
      String? badge,
      String? description,
      bool requiresGpu,
      int minVramBytes,
      String license});
}

/// @nodoc
class _$HuggingFaceModelCopyWithImpl<$Res, $Val extends HuggingFaceModel>
    implements $HuggingFaceModelCopyWith<$Res> {
  _$HuggingFaceModelCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of HuggingFaceModel
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? displayName = null,
    Object? huggingFaceId = null,
    Object? fileName = null,
    Object? parameters = null,
    Object? parameterCount = null,
    Object? sizeBytes = null,
    Object? ramRequired = null,
    Object? speedMultiplier = null,
    Object? accuracyPercent = null,
    Object? modelType = null,
    Object? languages = null,
    Object? badge = freezed,
    Object? description = freezed,
    Object? requiresGpu = null,
    Object? minVramBytes = null,
    Object? license = null,
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
      huggingFaceId: null == huggingFaceId
          ? _value.huggingFaceId
          : huggingFaceId // ignore: cast_nullable_to_non_nullable
              as String,
      fileName: null == fileName
          ? _value.fileName
          : fileName // ignore: cast_nullable_to_non_nullable
              as String,
      parameters: null == parameters
          ? _value.parameters
          : parameters // ignore: cast_nullable_to_non_nullable
              as String,
      parameterCount: null == parameterCount
          ? _value.parameterCount
          : parameterCount // ignore: cast_nullable_to_non_nullable
              as int,
      sizeBytes: null == sizeBytes
          ? _value.sizeBytes
          : sizeBytes // ignore: cast_nullable_to_non_nullable
              as int,
      ramRequired: null == ramRequired
          ? _value.ramRequired
          : ramRequired // ignore: cast_nullable_to_non_nullable
              as int,
      speedMultiplier: null == speedMultiplier
          ? _value.speedMultiplier
          : speedMultiplier // ignore: cast_nullable_to_non_nullable
              as double,
      accuracyPercent: null == accuracyPercent
          ? _value.accuracyPercent
          : accuracyPercent // ignore: cast_nullable_to_non_nullable
              as int,
      modelType: null == modelType
          ? _value.modelType
          : modelType // ignore: cast_nullable_to_non_nullable
              as HuggingFaceModelType,
      languages: null == languages
          ? _value.languages
          : languages // ignore: cast_nullable_to_non_nullable
              as List<String>,
      badge: freezed == badge
          ? _value.badge
          : badge // ignore: cast_nullable_to_non_nullable
              as String?,
      description: freezed == description
          ? _value.description
          : description // ignore: cast_nullable_to_non_nullable
              as String?,
      requiresGpu: null == requiresGpu
          ? _value.requiresGpu
          : requiresGpu // ignore: cast_nullable_to_non_nullable
              as bool,
      minVramBytes: null == minVramBytes
          ? _value.minVramBytes
          : minVramBytes // ignore: cast_nullable_to_non_nullable
              as int,
      license: null == license
          ? _value.license
          : license // ignore: cast_nullable_to_non_nullable
              as String,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$HuggingFaceModelImplCopyWith<$Res>
    implements $HuggingFaceModelCopyWith<$Res> {
  factory _$$HuggingFaceModelImplCopyWith(_$HuggingFaceModelImpl value,
          $Res Function(_$HuggingFaceModelImpl) then) =
      __$$HuggingFaceModelImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String id,
      String displayName,
      String huggingFaceId,
      String fileName,
      String parameters,
      int parameterCount,
      int sizeBytes,
      int ramRequired,
      double speedMultiplier,
      int accuracyPercent,
      HuggingFaceModelType modelType,
      List<String> languages,
      String? badge,
      String? description,
      bool requiresGpu,
      int minVramBytes,
      String license});
}

/// @nodoc
class __$$HuggingFaceModelImplCopyWithImpl<$Res>
    extends _$HuggingFaceModelCopyWithImpl<$Res, _$HuggingFaceModelImpl>
    implements _$$HuggingFaceModelImplCopyWith<$Res> {
  __$$HuggingFaceModelImplCopyWithImpl(_$HuggingFaceModelImpl _value,
      $Res Function(_$HuggingFaceModelImpl) _then)
      : super(_value, _then);

  /// Create a copy of HuggingFaceModel
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? displayName = null,
    Object? huggingFaceId = null,
    Object? fileName = null,
    Object? parameters = null,
    Object? parameterCount = null,
    Object? sizeBytes = null,
    Object? ramRequired = null,
    Object? speedMultiplier = null,
    Object? accuracyPercent = null,
    Object? modelType = null,
    Object? languages = null,
    Object? badge = freezed,
    Object? description = freezed,
    Object? requiresGpu = null,
    Object? minVramBytes = null,
    Object? license = null,
  }) {
    return _then(_$HuggingFaceModelImpl(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      displayName: null == displayName
          ? _value.displayName
          : displayName // ignore: cast_nullable_to_non_nullable
              as String,
      huggingFaceId: null == huggingFaceId
          ? _value.huggingFaceId
          : huggingFaceId // ignore: cast_nullable_to_non_nullable
              as String,
      fileName: null == fileName
          ? _value.fileName
          : fileName // ignore: cast_nullable_to_non_nullable
              as String,
      parameters: null == parameters
          ? _value.parameters
          : parameters // ignore: cast_nullable_to_non_nullable
              as String,
      parameterCount: null == parameterCount
          ? _value.parameterCount
          : parameterCount // ignore: cast_nullable_to_non_nullable
              as int,
      sizeBytes: null == sizeBytes
          ? _value.sizeBytes
          : sizeBytes // ignore: cast_nullable_to_non_nullable
              as int,
      ramRequired: null == ramRequired
          ? _value.ramRequired
          : ramRequired // ignore: cast_nullable_to_non_nullable
              as int,
      speedMultiplier: null == speedMultiplier
          ? _value.speedMultiplier
          : speedMultiplier // ignore: cast_nullable_to_non_nullable
              as double,
      accuracyPercent: null == accuracyPercent
          ? _value.accuracyPercent
          : accuracyPercent // ignore: cast_nullable_to_non_nullable
              as int,
      modelType: null == modelType
          ? _value.modelType
          : modelType // ignore: cast_nullable_to_non_nullable
              as HuggingFaceModelType,
      languages: null == languages
          ? _value._languages
          : languages // ignore: cast_nullable_to_non_nullable
              as List<String>,
      badge: freezed == badge
          ? _value.badge
          : badge // ignore: cast_nullable_to_non_nullable
              as String?,
      description: freezed == description
          ? _value.description
          : description // ignore: cast_nullable_to_non_nullable
              as String?,
      requiresGpu: null == requiresGpu
          ? _value.requiresGpu
          : requiresGpu // ignore: cast_nullable_to_non_nullable
              as bool,
      minVramBytes: null == minVramBytes
          ? _value.minVramBytes
          : minVramBytes // ignore: cast_nullable_to_non_nullable
              as int,
      license: null == license
          ? _value.license
          : license // ignore: cast_nullable_to_non_nullable
              as String,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$HuggingFaceModelImpl extends _HuggingFaceModel {
  const _$HuggingFaceModelImpl(
      {required this.id,
      required this.displayName,
      required this.huggingFaceId,
      required this.fileName,
      required this.parameters,
      required this.parameterCount,
      required this.sizeBytes,
      required this.ramRequired,
      required this.speedMultiplier,
      required this.accuracyPercent,
      required this.modelType,
      final List<String> languages = const [],
      this.badge,
      this.description,
      this.requiresGpu = false,
      this.minVramBytes = 0,
      this.license = 'MIT'})
      : _languages = languages,
        super._();

  factory _$HuggingFaceModelImpl.fromJson(Map<String, dynamic> json) =>
      _$$HuggingFaceModelImplFromJson(json);

  /// Unique identifier for the model (e.g., 'whisper-tiny', 'nsfw-mobilenet-v2')
  @override
  final String id;

  /// Human-readable display name
  @override
  final String displayName;

  /// HuggingFace repository ID (e.g., 'ggerganov/whisper.cpp')
  @override
  final String huggingFaceId;

  /// Model file name in the repository (e.g., 'ggml-tiny.bin')
  @override
  final String fileName;

  /// Human-readable parameter count (e.g., '39M', '1.55B')
  @override
  final String parameters;

  /// Numeric parameter count for sorting (e.g., 39000000)
  @override
  final int parameterCount;

  /// Model file size in bytes
  @override
  final int sizeBytes;

  /// RAM required to run the model in bytes
  @override
  final int ramRequired;

  /// Speed multiplier relative to realtime (e.g., 10.0 = 10x realtime)
  @override
  final double speedMultiplier;

  /// Accuracy percentage (0-100)
  @override
  final int accuracyPercent;

  /// Type of model
  @override
  final HuggingFaceModelType modelType;

  /// Supported languages (for ASR models, empty for visual models)
  final List<String> _languages;

  /// Supported languages (for ASR models, empty for visual models)
  @override
  @JsonKey()
  List<String> get languages {
    if (_languages is EqualUnmodifiableListView) return _languages;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_languages);
  }

  /// Optional badge text (e.g., 'Recommended', 'Best Accuracy', 'Best Value')
  @override
  final String? badge;

  /// Optional description of the model
  @override
  final String? description;

  /// Whether this model requires a GPU
  @override
  @JsonKey()
  final bool requiresGpu;

  /// Minimum VRAM required in bytes (0 if CPU-only)
  @override
  @JsonKey()
  final int minVramBytes;

  /// Model license (e.g., 'MIT', 'Apache-2.0')
  @override
  @JsonKey()
  final String license;

  @override
  String toString() {
    return 'HuggingFaceModel(id: $id, displayName: $displayName, huggingFaceId: $huggingFaceId, fileName: $fileName, parameters: $parameters, parameterCount: $parameterCount, sizeBytes: $sizeBytes, ramRequired: $ramRequired, speedMultiplier: $speedMultiplier, accuracyPercent: $accuracyPercent, modelType: $modelType, languages: $languages, badge: $badge, description: $description, requiresGpu: $requiresGpu, minVramBytes: $minVramBytes, license: $license)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$HuggingFaceModelImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.displayName, displayName) ||
                other.displayName == displayName) &&
            (identical(other.huggingFaceId, huggingFaceId) ||
                other.huggingFaceId == huggingFaceId) &&
            (identical(other.fileName, fileName) ||
                other.fileName == fileName) &&
            (identical(other.parameters, parameters) ||
                other.parameters == parameters) &&
            (identical(other.parameterCount, parameterCount) ||
                other.parameterCount == parameterCount) &&
            (identical(other.sizeBytes, sizeBytes) ||
                other.sizeBytes == sizeBytes) &&
            (identical(other.ramRequired, ramRequired) ||
                other.ramRequired == ramRequired) &&
            (identical(other.speedMultiplier, speedMultiplier) ||
                other.speedMultiplier == speedMultiplier) &&
            (identical(other.accuracyPercent, accuracyPercent) ||
                other.accuracyPercent == accuracyPercent) &&
            (identical(other.modelType, modelType) ||
                other.modelType == modelType) &&
            const DeepCollectionEquality()
                .equals(other._languages, _languages) &&
            (identical(other.badge, badge) || other.badge == badge) &&
            (identical(other.description, description) ||
                other.description == description) &&
            (identical(other.requiresGpu, requiresGpu) ||
                other.requiresGpu == requiresGpu) &&
            (identical(other.minVramBytes, minVramBytes) ||
                other.minVramBytes == minVramBytes) &&
            (identical(other.license, license) || other.license == license));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
      runtimeType,
      id,
      displayName,
      huggingFaceId,
      fileName,
      parameters,
      parameterCount,
      sizeBytes,
      ramRequired,
      speedMultiplier,
      accuracyPercent,
      modelType,
      const DeepCollectionEquality().hash(_languages),
      badge,
      description,
      requiresGpu,
      minVramBytes,
      license);

  /// Create a copy of HuggingFaceModel
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$HuggingFaceModelImplCopyWith<_$HuggingFaceModelImpl> get copyWith =>
      __$$HuggingFaceModelImplCopyWithImpl<_$HuggingFaceModelImpl>(
          this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$HuggingFaceModelImplToJson(
      this,
    );
  }
}

abstract class _HuggingFaceModel extends HuggingFaceModel {
  const factory _HuggingFaceModel(
      {required final String id,
      required final String displayName,
      required final String huggingFaceId,
      required final String fileName,
      required final String parameters,
      required final int parameterCount,
      required final int sizeBytes,
      required final int ramRequired,
      required final double speedMultiplier,
      required final int accuracyPercent,
      required final HuggingFaceModelType modelType,
      final List<String> languages,
      final String? badge,
      final String? description,
      final bool requiresGpu,
      final int minVramBytes,
      final String license}) = _$HuggingFaceModelImpl;
  const _HuggingFaceModel._() : super._();

  factory _HuggingFaceModel.fromJson(Map<String, dynamic> json) =
      _$HuggingFaceModelImpl.fromJson;

  /// Unique identifier for the model (e.g., 'whisper-tiny', 'nsfw-mobilenet-v2')
  @override
  String get id;

  /// Human-readable display name
  @override
  String get displayName;

  /// HuggingFace repository ID (e.g., 'ggerganov/whisper.cpp')
  @override
  String get huggingFaceId;

  /// Model file name in the repository (e.g., 'ggml-tiny.bin')
  @override
  String get fileName;

  /// Human-readable parameter count (e.g., '39M', '1.55B')
  @override
  String get parameters;

  /// Numeric parameter count for sorting (e.g., 39000000)
  @override
  int get parameterCount;

  /// Model file size in bytes
  @override
  int get sizeBytes;

  /// RAM required to run the model in bytes
  @override
  int get ramRequired;

  /// Speed multiplier relative to realtime (e.g., 10.0 = 10x realtime)
  @override
  double get speedMultiplier;

  /// Accuracy percentage (0-100)
  @override
  int get accuracyPercent;

  /// Type of model
  @override
  HuggingFaceModelType get modelType;

  /// Supported languages (for ASR models, empty for visual models)
  @override
  List<String> get languages;

  /// Optional badge text (e.g., 'Recommended', 'Best Accuracy', 'Best Value')
  @override
  String? get badge;

  /// Optional description of the model
  @override
  String? get description;

  /// Whether this model requires a GPU
  @override
  bool get requiresGpu;

  /// Minimum VRAM required in bytes (0 if CPU-only)
  @override
  int get minVramBytes;

  /// Model license (e.g., 'MIT', 'Apache-2.0')
  @override
  String get license;

  /// Create a copy of HuggingFaceModel
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$HuggingFaceModelImplCopyWith<_$HuggingFaceModelImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
