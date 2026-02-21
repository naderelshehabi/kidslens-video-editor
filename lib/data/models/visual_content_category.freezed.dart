// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'visual_content_category.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

VisualContentCategory _$VisualContentCategoryFromJson(
    Map<String, dynamic> json) {
  return _VisualContentCategory.fromJson(json);
}

/// @nodoc
mixin _$VisualContentCategory {
  /// Unique identifier for the category
  String get id => throw _privateConstructorUsedError;

  /// Human-readable category name
  String get name => throw _privateConstructorUsedError;

  /// Description of what this category detects
  String get description => throw _privateConstructorUsedError;

  /// NudeNet class labels for detection (empty for CLIP-only categories)
  List<String> get detectionLabels => throw _privateConstructorUsedError;

  /// CLIP positive prompts for zero-shot classification
  List<String> get clipPrompts => throw _privateConstructorUsedError;

  /// CLIP negative prompts for discriminative scoring
  List<String> get clipNegativePrompts => throw _privateConstructorUsedError;

  /// Detection source (nudeNet, clip, or both)
  @JsonKey(unknownEnumValue: CategoryDetectionSource.clip)
  CategoryDetectionSource get detectionSource =>
      throw _privateConstructorUsedError;

  /// Whether this category is enabled
  bool get enabled => throw _privateConstructorUsedError;

  /// Threshold for NudeNet detection (confidence 0-1)
  double get threshold => throw _privateConstructorUsedError;

  /// Threshold for CLIP temperature-scaled discriminative score
  double get clipThreshold => throw _privateConstructorUsedError;

  /// Action to take when content is detected
  @JsonKey(unknownEnumValue: VisualContentAction.blurRegion)
  VisualContentAction get action => throw _privateConstructorUsedError;

  /// Optional icon name for UI display
  String? get iconName => throw _privateConstructorUsedError;

  /// Whether this is a built-in category (vs user-created custom)
  bool get isBuiltIn => throw _privateConstructorUsedError;

  /// Serializes this VisualContentCategory to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of VisualContentCategory
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $VisualContentCategoryCopyWith<VisualContentCategory> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $VisualContentCategoryCopyWith<$Res> {
  factory $VisualContentCategoryCopyWith(VisualContentCategory value,
          $Res Function(VisualContentCategory) then) =
      _$VisualContentCategoryCopyWithImpl<$Res, VisualContentCategory>;
  @useResult
  $Res call(
      {String id,
      String name,
      String description,
      List<String> detectionLabels,
      List<String> clipPrompts,
      List<String> clipNegativePrompts,
      @JsonKey(unknownEnumValue: CategoryDetectionSource.clip)
      CategoryDetectionSource detectionSource,
      bool enabled,
      double threshold,
      double clipThreshold,
      @JsonKey(unknownEnumValue: VisualContentAction.blurRegion)
      VisualContentAction action,
      String? iconName,
      bool isBuiltIn});
}

/// @nodoc
class _$VisualContentCategoryCopyWithImpl<$Res,
        $Val extends VisualContentCategory>
    implements $VisualContentCategoryCopyWith<$Res> {
  _$VisualContentCategoryCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of VisualContentCategory
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? name = null,
    Object? description = null,
    Object? detectionLabels = null,
    Object? clipPrompts = null,
    Object? clipNegativePrompts = null,
    Object? detectionSource = null,
    Object? enabled = null,
    Object? threshold = null,
    Object? clipThreshold = null,
    Object? action = null,
    Object? iconName = freezed,
    Object? isBuiltIn = null,
  }) {
    return _then(_value.copyWith(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      name: null == name
          ? _value.name
          : name // ignore: cast_nullable_to_non_nullable
              as String,
      description: null == description
          ? _value.description
          : description // ignore: cast_nullable_to_non_nullable
              as String,
      detectionLabels: null == detectionLabels
          ? _value.detectionLabels
          : detectionLabels // ignore: cast_nullable_to_non_nullable
              as List<String>,
      clipPrompts: null == clipPrompts
          ? _value.clipPrompts
          : clipPrompts // ignore: cast_nullable_to_non_nullable
              as List<String>,
      clipNegativePrompts: null == clipNegativePrompts
          ? _value.clipNegativePrompts
          : clipNegativePrompts // ignore: cast_nullable_to_non_nullable
              as List<String>,
      detectionSource: null == detectionSource
          ? _value.detectionSource
          : detectionSource // ignore: cast_nullable_to_non_nullable
              as CategoryDetectionSource,
      enabled: null == enabled
          ? _value.enabled
          : enabled // ignore: cast_nullable_to_non_nullable
              as bool,
      threshold: null == threshold
          ? _value.threshold
          : threshold // ignore: cast_nullable_to_non_nullable
              as double,
      clipThreshold: null == clipThreshold
          ? _value.clipThreshold
          : clipThreshold // ignore: cast_nullable_to_non_nullable
              as double,
      action: null == action
          ? _value.action
          : action // ignore: cast_nullable_to_non_nullable
              as VisualContentAction,
      iconName: freezed == iconName
          ? _value.iconName
          : iconName // ignore: cast_nullable_to_non_nullable
              as String?,
      isBuiltIn: null == isBuiltIn
          ? _value.isBuiltIn
          : isBuiltIn // ignore: cast_nullable_to_non_nullable
              as bool,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$VisualContentCategoryImplCopyWith<$Res>
    implements $VisualContentCategoryCopyWith<$Res> {
  factory _$$VisualContentCategoryImplCopyWith(
          _$VisualContentCategoryImpl value,
          $Res Function(_$VisualContentCategoryImpl) then) =
      __$$VisualContentCategoryImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String id,
      String name,
      String description,
      List<String> detectionLabels,
      List<String> clipPrompts,
      List<String> clipNegativePrompts,
      @JsonKey(unknownEnumValue: CategoryDetectionSource.clip)
      CategoryDetectionSource detectionSource,
      bool enabled,
      double threshold,
      double clipThreshold,
      @JsonKey(unknownEnumValue: VisualContentAction.blurRegion)
      VisualContentAction action,
      String? iconName,
      bool isBuiltIn});
}

/// @nodoc
class __$$VisualContentCategoryImplCopyWithImpl<$Res>
    extends _$VisualContentCategoryCopyWithImpl<$Res,
        _$VisualContentCategoryImpl>
    implements _$$VisualContentCategoryImplCopyWith<$Res> {
  __$$VisualContentCategoryImplCopyWithImpl(_$VisualContentCategoryImpl _value,
      $Res Function(_$VisualContentCategoryImpl) _then)
      : super(_value, _then);

  /// Create a copy of VisualContentCategory
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? name = null,
    Object? description = null,
    Object? detectionLabels = null,
    Object? clipPrompts = null,
    Object? clipNegativePrompts = null,
    Object? detectionSource = null,
    Object? enabled = null,
    Object? threshold = null,
    Object? clipThreshold = null,
    Object? action = null,
    Object? iconName = freezed,
    Object? isBuiltIn = null,
  }) {
    return _then(_$VisualContentCategoryImpl(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      name: null == name
          ? _value.name
          : name // ignore: cast_nullable_to_non_nullable
              as String,
      description: null == description
          ? _value.description
          : description // ignore: cast_nullable_to_non_nullable
              as String,
      detectionLabels: null == detectionLabels
          ? _value._detectionLabels
          : detectionLabels // ignore: cast_nullable_to_non_nullable
              as List<String>,
      clipPrompts: null == clipPrompts
          ? _value._clipPrompts
          : clipPrompts // ignore: cast_nullable_to_non_nullable
              as List<String>,
      clipNegativePrompts: null == clipNegativePrompts
          ? _value._clipNegativePrompts
          : clipNegativePrompts // ignore: cast_nullable_to_non_nullable
              as List<String>,
      detectionSource: null == detectionSource
          ? _value.detectionSource
          : detectionSource // ignore: cast_nullable_to_non_nullable
              as CategoryDetectionSource,
      enabled: null == enabled
          ? _value.enabled
          : enabled // ignore: cast_nullable_to_non_nullable
              as bool,
      threshold: null == threshold
          ? _value.threshold
          : threshold // ignore: cast_nullable_to_non_nullable
              as double,
      clipThreshold: null == clipThreshold
          ? _value.clipThreshold
          : clipThreshold // ignore: cast_nullable_to_non_nullable
              as double,
      action: null == action
          ? _value.action
          : action // ignore: cast_nullable_to_non_nullable
              as VisualContentAction,
      iconName: freezed == iconName
          ? _value.iconName
          : iconName // ignore: cast_nullable_to_non_nullable
              as String?,
      isBuiltIn: null == isBuiltIn
          ? _value.isBuiltIn
          : isBuiltIn // ignore: cast_nullable_to_non_nullable
              as bool,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$VisualContentCategoryImpl extends _VisualContentCategory {
  const _$VisualContentCategoryImpl(
      {required this.id,
      required this.name,
      required this.description,
      final List<String> detectionLabels = const [],
      final List<String> clipPrompts = const [],
      final List<String> clipNegativePrompts = const [],
      @JsonKey(unknownEnumValue: CategoryDetectionSource.clip)
      required this.detectionSource,
      this.enabled = true,
      this.threshold = 0.5,
      this.clipThreshold = 3.0,
      @JsonKey(unknownEnumValue: VisualContentAction.blurRegion)
      this.action = VisualContentAction.blurRegion,
      this.iconName,
      this.isBuiltIn = true})
      : _detectionLabels = detectionLabels,
        _clipPrompts = clipPrompts,
        _clipNegativePrompts = clipNegativePrompts,
        super._();

  factory _$VisualContentCategoryImpl.fromJson(Map<String, dynamic> json) =>
      _$$VisualContentCategoryImplFromJson(json);

  /// Unique identifier for the category
  @override
  final String id;

  /// Human-readable category name
  @override
  final String name;

  /// Description of what this category detects
  @override
  final String description;

  /// NudeNet class labels for detection (empty for CLIP-only categories)
  final List<String> _detectionLabels;

  /// NudeNet class labels for detection (empty for CLIP-only categories)
  @override
  @JsonKey()
  List<String> get detectionLabels {
    if (_detectionLabels is EqualUnmodifiableListView) return _detectionLabels;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_detectionLabels);
  }

  /// CLIP positive prompts for zero-shot classification
  final List<String> _clipPrompts;

  /// CLIP positive prompts for zero-shot classification
  @override
  @JsonKey()
  List<String> get clipPrompts {
    if (_clipPrompts is EqualUnmodifiableListView) return _clipPrompts;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_clipPrompts);
  }

  /// CLIP negative prompts for discriminative scoring
  final List<String> _clipNegativePrompts;

  /// CLIP negative prompts for discriminative scoring
  @override
  @JsonKey()
  List<String> get clipNegativePrompts {
    if (_clipNegativePrompts is EqualUnmodifiableListView)
      return _clipNegativePrompts;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_clipNegativePrompts);
  }

  /// Detection source (nudeNet, clip, or both)
  @override
  @JsonKey(unknownEnumValue: CategoryDetectionSource.clip)
  final CategoryDetectionSource detectionSource;

  /// Whether this category is enabled
  @override
  @JsonKey()
  final bool enabled;

  /// Threshold for NudeNet detection (confidence 0-1)
  @override
  @JsonKey()
  final double threshold;

  /// Threshold for CLIP temperature-scaled discriminative score
  @override
  @JsonKey()
  final double clipThreshold;

  /// Action to take when content is detected
  @override
  @JsonKey(unknownEnumValue: VisualContentAction.blurRegion)
  final VisualContentAction action;

  /// Optional icon name for UI display
  @override
  final String? iconName;

  /// Whether this is a built-in category (vs user-created custom)
  @override
  @JsonKey()
  final bool isBuiltIn;

  @override
  String toString() {
    return 'VisualContentCategory(id: $id, name: $name, description: $description, detectionLabels: $detectionLabels, clipPrompts: $clipPrompts, clipNegativePrompts: $clipNegativePrompts, detectionSource: $detectionSource, enabled: $enabled, threshold: $threshold, clipThreshold: $clipThreshold, action: $action, iconName: $iconName, isBuiltIn: $isBuiltIn)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$VisualContentCategoryImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.name, name) || other.name == name) &&
            (identical(other.description, description) ||
                other.description == description) &&
            const DeepCollectionEquality()
                .equals(other._detectionLabels, _detectionLabels) &&
            const DeepCollectionEquality()
                .equals(other._clipPrompts, _clipPrompts) &&
            const DeepCollectionEquality()
                .equals(other._clipNegativePrompts, _clipNegativePrompts) &&
            (identical(other.detectionSource, detectionSource) ||
                other.detectionSource == detectionSource) &&
            (identical(other.enabled, enabled) || other.enabled == enabled) &&
            (identical(other.threshold, threshold) ||
                other.threshold == threshold) &&
            (identical(other.clipThreshold, clipThreshold) ||
                other.clipThreshold == clipThreshold) &&
            (identical(other.action, action) || other.action == action) &&
            (identical(other.iconName, iconName) ||
                other.iconName == iconName) &&
            (identical(other.isBuiltIn, isBuiltIn) ||
                other.isBuiltIn == isBuiltIn));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
      runtimeType,
      id,
      name,
      description,
      const DeepCollectionEquality().hash(_detectionLabels),
      const DeepCollectionEquality().hash(_clipPrompts),
      const DeepCollectionEquality().hash(_clipNegativePrompts),
      detectionSource,
      enabled,
      threshold,
      clipThreshold,
      action,
      iconName,
      isBuiltIn);

  /// Create a copy of VisualContentCategory
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$VisualContentCategoryImplCopyWith<_$VisualContentCategoryImpl>
      get copyWith => __$$VisualContentCategoryImplCopyWithImpl<
          _$VisualContentCategoryImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$VisualContentCategoryImplToJson(
      this,
    );
  }
}

abstract class _VisualContentCategory extends VisualContentCategory {
  const factory _VisualContentCategory(
      {required final String id,
      required final String name,
      required final String description,
      final List<String> detectionLabels,
      final List<String> clipPrompts,
      final List<String> clipNegativePrompts,
      @JsonKey(unknownEnumValue: CategoryDetectionSource.clip)
      required final CategoryDetectionSource detectionSource,
      final bool enabled,
      final double threshold,
      final double clipThreshold,
      @JsonKey(unknownEnumValue: VisualContentAction.blurRegion)
      final VisualContentAction action,
      final String? iconName,
      final bool isBuiltIn}) = _$VisualContentCategoryImpl;
  const _VisualContentCategory._() : super._();

  factory _VisualContentCategory.fromJson(Map<String, dynamic> json) =
      _$VisualContentCategoryImpl.fromJson;

  /// Unique identifier for the category
  @override
  String get id;

  /// Human-readable category name
  @override
  String get name;

  /// Description of what this category detects
  @override
  String get description;

  /// NudeNet class labels for detection (empty for CLIP-only categories)
  @override
  List<String> get detectionLabels;

  /// CLIP positive prompts for zero-shot classification
  @override
  List<String> get clipPrompts;

  /// CLIP negative prompts for discriminative scoring
  @override
  List<String> get clipNegativePrompts;

  /// Detection source (nudeNet, clip, or both)
  @override
  @JsonKey(unknownEnumValue: CategoryDetectionSource.clip)
  CategoryDetectionSource get detectionSource;

  /// Whether this category is enabled
  @override
  bool get enabled;

  /// Threshold for NudeNet detection (confidence 0-1)
  @override
  double get threshold;

  /// Threshold for CLIP temperature-scaled discriminative score
  @override
  double get clipThreshold;

  /// Action to take when content is detected
  @override
  @JsonKey(unknownEnumValue: VisualContentAction.blurRegion)
  VisualContentAction get action;

  /// Optional icon name for UI display
  @override
  String? get iconName;

  /// Whether this is a built-in category (vs user-created custom)
  @override
  bool get isBuiltIn;

  /// Create a copy of VisualContentCategory
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$VisualContentCategoryImplCopyWith<_$VisualContentCategoryImpl>
      get copyWith => throw _privateConstructorUsedError;
}
