// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'content_category.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

ModelContribution _$ModelContributionFromJson(Map<String, dynamic> json) {
  return _ModelContribution.fromJson(json);
}

/// @nodoc
mixin _$ModelContribution {
  /// Model ID from the HuggingFace registry (e.g. 'nsfw-vit-base-quantized').
  String get modelId => throw _privateConstructorUsedError;

  /// Human-readable model name for the UI.
  String get displayName => throw _privateConstructorUsedError;

  /// Model type, used for inference routing.
  HuggingFaceModelType get modelType => throw _privateConstructorUsedError;

  /// Whether this model is enabled for voting in this category.
  bool get enabled => throw _privateConstructorUsedError;

  /// Weight override for voting. When null, the model's accuracy percentage
  /// from the registry is used as its weight.
  double? get weightOverride => throw _privateConstructorUsedError;

  /// NudeNet class labels this contribution maps to (e.g. 'FEMALE_BREAST_EXPOSED').
  List<String> get detectionLabels => throw _privateConstructorUsedError;

  /// CLIP positive prompts for zero-shot classification.
  List<String> get clipPrompts => throw _privateConstructorUsedError;

  /// CLIP negative prompts for discriminative scoring.
  List<String> get clipNegativePrompts => throw _privateConstructorUsedError;

  /// Serializes this ModelContribution to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of ModelContribution
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $ModelContributionCopyWith<ModelContribution> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $ModelContributionCopyWith<$Res> {
  factory $ModelContributionCopyWith(
          ModelContribution value, $Res Function(ModelContribution) then) =
      _$ModelContributionCopyWithImpl<$Res, ModelContribution>;
  @useResult
  $Res call(
      {String modelId,
      String displayName,
      HuggingFaceModelType modelType,
      bool enabled,
      double? weightOverride,
      List<String> detectionLabels,
      List<String> clipPrompts,
      List<String> clipNegativePrompts});
}

/// @nodoc
class _$ModelContributionCopyWithImpl<$Res, $Val extends ModelContribution>
    implements $ModelContributionCopyWith<$Res> {
  _$ModelContributionCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of ModelContribution
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? modelId = null,
    Object? displayName = null,
    Object? modelType = null,
    Object? enabled = null,
    Object? weightOverride = freezed,
    Object? detectionLabels = null,
    Object? clipPrompts = null,
    Object? clipNegativePrompts = null,
  }) {
    return _then(_value.copyWith(
      modelId: null == modelId
          ? _value.modelId
          : modelId // ignore: cast_nullable_to_non_nullable
              as String,
      displayName: null == displayName
          ? _value.displayName
          : displayName // ignore: cast_nullable_to_non_nullable
              as String,
      modelType: null == modelType
          ? _value.modelType
          : modelType // ignore: cast_nullable_to_non_nullable
              as HuggingFaceModelType,
      enabled: null == enabled
          ? _value.enabled
          : enabled // ignore: cast_nullable_to_non_nullable
              as bool,
      weightOverride: freezed == weightOverride
          ? _value.weightOverride
          : weightOverride // ignore: cast_nullable_to_non_nullable
              as double?,
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
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$ModelContributionImplCopyWith<$Res>
    implements $ModelContributionCopyWith<$Res> {
  factory _$$ModelContributionImplCopyWith(_$ModelContributionImpl value,
          $Res Function(_$ModelContributionImpl) then) =
      __$$ModelContributionImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String modelId,
      String displayName,
      HuggingFaceModelType modelType,
      bool enabled,
      double? weightOverride,
      List<String> detectionLabels,
      List<String> clipPrompts,
      List<String> clipNegativePrompts});
}

/// @nodoc
class __$$ModelContributionImplCopyWithImpl<$Res>
    extends _$ModelContributionCopyWithImpl<$Res, _$ModelContributionImpl>
    implements _$$ModelContributionImplCopyWith<$Res> {
  __$$ModelContributionImplCopyWithImpl(_$ModelContributionImpl _value,
      $Res Function(_$ModelContributionImpl) _then)
      : super(_value, _then);

  /// Create a copy of ModelContribution
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? modelId = null,
    Object? displayName = null,
    Object? modelType = null,
    Object? enabled = null,
    Object? weightOverride = freezed,
    Object? detectionLabels = null,
    Object? clipPrompts = null,
    Object? clipNegativePrompts = null,
  }) {
    return _then(_$ModelContributionImpl(
      modelId: null == modelId
          ? _value.modelId
          : modelId // ignore: cast_nullable_to_non_nullable
              as String,
      displayName: null == displayName
          ? _value.displayName
          : displayName // ignore: cast_nullable_to_non_nullable
              as String,
      modelType: null == modelType
          ? _value.modelType
          : modelType // ignore: cast_nullable_to_non_nullable
              as HuggingFaceModelType,
      enabled: null == enabled
          ? _value.enabled
          : enabled // ignore: cast_nullable_to_non_nullable
              as bool,
      weightOverride: freezed == weightOverride
          ? _value.weightOverride
          : weightOverride // ignore: cast_nullable_to_non_nullable
              as double?,
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
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$ModelContributionImpl extends _ModelContribution {
  const _$ModelContributionImpl(
      {required this.modelId,
      required this.displayName,
      required this.modelType,
      this.enabled = true,
      this.weightOverride,
      final List<String> detectionLabels = const [],
      final List<String> clipPrompts = const [],
      final List<String> clipNegativePrompts = const []})
      : _detectionLabels = detectionLabels,
        _clipPrompts = clipPrompts,
        _clipNegativePrompts = clipNegativePrompts,
        super._();

  factory _$ModelContributionImpl.fromJson(Map<String, dynamic> json) =>
      _$$ModelContributionImplFromJson(json);

  /// Model ID from the HuggingFace registry (e.g. 'nsfw-vit-base-quantized').
  @override
  final String modelId;

  /// Human-readable model name for the UI.
  @override
  final String displayName;

  /// Model type, used for inference routing.
  @override
  final HuggingFaceModelType modelType;

  /// Whether this model is enabled for voting in this category.
  @override
  @JsonKey()
  final bool enabled;

  /// Weight override for voting. When null, the model's accuracy percentage
  /// from the registry is used as its weight.
  @override
  final double? weightOverride;

  /// NudeNet class labels this contribution maps to (e.g. 'FEMALE_BREAST_EXPOSED').
  final List<String> _detectionLabels;

  /// NudeNet class labels this contribution maps to (e.g. 'FEMALE_BREAST_EXPOSED').
  @override
  @JsonKey()
  List<String> get detectionLabels {
    if (_detectionLabels is EqualUnmodifiableListView) return _detectionLabels;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_detectionLabels);
  }

  /// CLIP positive prompts for zero-shot classification.
  final List<String> _clipPrompts;

  /// CLIP positive prompts for zero-shot classification.
  @override
  @JsonKey()
  List<String> get clipPrompts {
    if (_clipPrompts is EqualUnmodifiableListView) return _clipPrompts;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_clipPrompts);
  }

  /// CLIP negative prompts for discriminative scoring.
  final List<String> _clipNegativePrompts;

  /// CLIP negative prompts for discriminative scoring.
  @override
  @JsonKey()
  List<String> get clipNegativePrompts {
    if (_clipNegativePrompts is EqualUnmodifiableListView)
      return _clipNegativePrompts;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_clipNegativePrompts);
  }

  @override
  String toString() {
    return 'ModelContribution(modelId: $modelId, displayName: $displayName, modelType: $modelType, enabled: $enabled, weightOverride: $weightOverride, detectionLabels: $detectionLabels, clipPrompts: $clipPrompts, clipNegativePrompts: $clipNegativePrompts)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$ModelContributionImpl &&
            (identical(other.modelId, modelId) || other.modelId == modelId) &&
            (identical(other.displayName, displayName) ||
                other.displayName == displayName) &&
            (identical(other.modelType, modelType) ||
                other.modelType == modelType) &&
            (identical(other.enabled, enabled) || other.enabled == enabled) &&
            (identical(other.weightOverride, weightOverride) ||
                other.weightOverride == weightOverride) &&
            const DeepCollectionEquality()
                .equals(other._detectionLabels, _detectionLabels) &&
            const DeepCollectionEquality()
                .equals(other._clipPrompts, _clipPrompts) &&
            const DeepCollectionEquality()
                .equals(other._clipNegativePrompts, _clipNegativePrompts));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
      runtimeType,
      modelId,
      displayName,
      modelType,
      enabled,
      weightOverride,
      const DeepCollectionEquality().hash(_detectionLabels),
      const DeepCollectionEquality().hash(_clipPrompts),
      const DeepCollectionEquality().hash(_clipNegativePrompts));

  /// Create a copy of ModelContribution
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$ModelContributionImplCopyWith<_$ModelContributionImpl> get copyWith =>
      __$$ModelContributionImplCopyWithImpl<_$ModelContributionImpl>(
          this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$ModelContributionImplToJson(
      this,
    );
  }
}

abstract class _ModelContribution extends ModelContribution {
  const factory _ModelContribution(
      {required final String modelId,
      required final String displayName,
      required final HuggingFaceModelType modelType,
      final bool enabled,
      final double? weightOverride,
      final List<String> detectionLabels,
      final List<String> clipPrompts,
      final List<String> clipNegativePrompts}) = _$ModelContributionImpl;
  const _ModelContribution._() : super._();

  factory _ModelContribution.fromJson(Map<String, dynamic> json) =
      _$ModelContributionImpl.fromJson;

  /// Model ID from the HuggingFace registry (e.g. 'nsfw-vit-base-quantized').
  @override
  String get modelId;

  /// Human-readable model name for the UI.
  @override
  String get displayName;

  /// Model type, used for inference routing.
  @override
  HuggingFaceModelType get modelType;

  /// Whether this model is enabled for voting in this category.
  @override
  bool get enabled;

  /// Weight override for voting. When null, the model's accuracy percentage
  /// from the registry is used as its weight.
  @override
  double? get weightOverride;

  /// NudeNet class labels this contribution maps to (e.g. 'FEMALE_BREAST_EXPOSED').
  @override
  List<String> get detectionLabels;

  /// CLIP positive prompts for zero-shot classification.
  @override
  List<String> get clipPrompts;

  /// CLIP negative prompts for discriminative scoring.
  @override
  List<String> get clipNegativePrompts;

  /// Create a copy of ModelContribution
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$ModelContributionImplCopyWith<_$ModelContributionImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

ContentCategory _$ContentCategoryFromJson(Map<String, dynamic> json) {
  return _ContentCategory.fromJson(json);
}

/// @nodoc
mixin _$ContentCategory {
  /// Unique identifier (e.g. 'nsfw', 'violence', 'profanity').
  String get id => throw _privateConstructorUsedError;

  /// Human-readable name.
  String get name => throw _privateConstructorUsedError;

  /// Description of what this category detects.
  String get description => throw _privateConstructorUsedError;

  /// Whether this category detects visual or audio content.
  CategoryType get type => throw _privateConstructorUsedError;

  /// The action to apply when content in this category is detected.
  RemediationAction get action => throw _privateConstructorUsedError;

  /// Whether this category is enabled for detection.
  bool get enabled => throw _privateConstructorUsedError;

  /// Detection threshold (0.0 to 1.0). The MoE consensus score must meet
  /// or exceed this threshold to trigger a detection.
  double get threshold => throw _privateConstructorUsedError;

  /// Models that contribute to this category's detection via MoE voting.
  List<ModelContribution> get modelContributions =>
      throw _privateConstructorUsedError;

  /// Whether this is a built-in category (vs user-created custom).
  bool get isBuiltIn => throw _privateConstructorUsedError;

  /// Optional Material icon name for the UI.
  String? get iconName => throw _privateConstructorUsedError;

  /// Whether region-level detection (bounding boxes) is available.
  bool get supportsRegions => throw _privateConstructorUsedError;

  /// Serializes this ContentCategory to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of ContentCategory
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $ContentCategoryCopyWith<ContentCategory> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $ContentCategoryCopyWith<$Res> {
  factory $ContentCategoryCopyWith(
          ContentCategory value, $Res Function(ContentCategory) then) =
      _$ContentCategoryCopyWithImpl<$Res, ContentCategory>;
  @useResult
  $Res call(
      {String id,
      String name,
      String description,
      CategoryType type,
      RemediationAction action,
      bool enabled,
      double threshold,
      List<ModelContribution> modelContributions,
      bool isBuiltIn,
      String? iconName,
      bool supportsRegions});
}

/// @nodoc
class _$ContentCategoryCopyWithImpl<$Res, $Val extends ContentCategory>
    implements $ContentCategoryCopyWith<$Res> {
  _$ContentCategoryCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of ContentCategory
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? name = null,
    Object? description = null,
    Object? type = null,
    Object? action = null,
    Object? enabled = null,
    Object? threshold = null,
    Object? modelContributions = null,
    Object? isBuiltIn = null,
    Object? iconName = freezed,
    Object? supportsRegions = null,
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
      type: null == type
          ? _value.type
          : type // ignore: cast_nullable_to_non_nullable
              as CategoryType,
      action: null == action
          ? _value.action
          : action // ignore: cast_nullable_to_non_nullable
              as RemediationAction,
      enabled: null == enabled
          ? _value.enabled
          : enabled // ignore: cast_nullable_to_non_nullable
              as bool,
      threshold: null == threshold
          ? _value.threshold
          : threshold // ignore: cast_nullable_to_non_nullable
              as double,
      modelContributions: null == modelContributions
          ? _value.modelContributions
          : modelContributions // ignore: cast_nullable_to_non_nullable
              as List<ModelContribution>,
      isBuiltIn: null == isBuiltIn
          ? _value.isBuiltIn
          : isBuiltIn // ignore: cast_nullable_to_non_nullable
              as bool,
      iconName: freezed == iconName
          ? _value.iconName
          : iconName // ignore: cast_nullable_to_non_nullable
              as String?,
      supportsRegions: null == supportsRegions
          ? _value.supportsRegions
          : supportsRegions // ignore: cast_nullable_to_non_nullable
              as bool,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$ContentCategoryImplCopyWith<$Res>
    implements $ContentCategoryCopyWith<$Res> {
  factory _$$ContentCategoryImplCopyWith(_$ContentCategoryImpl value,
          $Res Function(_$ContentCategoryImpl) then) =
      __$$ContentCategoryImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String id,
      String name,
      String description,
      CategoryType type,
      RemediationAction action,
      bool enabled,
      double threshold,
      List<ModelContribution> modelContributions,
      bool isBuiltIn,
      String? iconName,
      bool supportsRegions});
}

/// @nodoc
class __$$ContentCategoryImplCopyWithImpl<$Res>
    extends _$ContentCategoryCopyWithImpl<$Res, _$ContentCategoryImpl>
    implements _$$ContentCategoryImplCopyWith<$Res> {
  __$$ContentCategoryImplCopyWithImpl(
      _$ContentCategoryImpl _value, $Res Function(_$ContentCategoryImpl) _then)
      : super(_value, _then);

  /// Create a copy of ContentCategory
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? name = null,
    Object? description = null,
    Object? type = null,
    Object? action = null,
    Object? enabled = null,
    Object? threshold = null,
    Object? modelContributions = null,
    Object? isBuiltIn = null,
    Object? iconName = freezed,
    Object? supportsRegions = null,
  }) {
    return _then(_$ContentCategoryImpl(
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
      type: null == type
          ? _value.type
          : type // ignore: cast_nullable_to_non_nullable
              as CategoryType,
      action: null == action
          ? _value.action
          : action // ignore: cast_nullable_to_non_nullable
              as RemediationAction,
      enabled: null == enabled
          ? _value.enabled
          : enabled // ignore: cast_nullable_to_non_nullable
              as bool,
      threshold: null == threshold
          ? _value.threshold
          : threshold // ignore: cast_nullable_to_non_nullable
              as double,
      modelContributions: null == modelContributions
          ? _value._modelContributions
          : modelContributions // ignore: cast_nullable_to_non_nullable
              as List<ModelContribution>,
      isBuiltIn: null == isBuiltIn
          ? _value.isBuiltIn
          : isBuiltIn // ignore: cast_nullable_to_non_nullable
              as bool,
      iconName: freezed == iconName
          ? _value.iconName
          : iconName // ignore: cast_nullable_to_non_nullable
              as String?,
      supportsRegions: null == supportsRegions
          ? _value.supportsRegions
          : supportsRegions // ignore: cast_nullable_to_non_nullable
              as bool,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$ContentCategoryImpl extends _ContentCategory {
  const _$ContentCategoryImpl(
      {required this.id,
      required this.name,
      required this.description,
      required this.type,
      required this.action,
      this.enabled = true,
      this.threshold = 0.5,
      final List<ModelContribution> modelContributions = const [],
      this.isBuiltIn = true,
      this.iconName,
      this.supportsRegions = false})
      : _modelContributions = modelContributions,
        super._();

  factory _$ContentCategoryImpl.fromJson(Map<String, dynamic> json) =>
      _$$ContentCategoryImplFromJson(json);

  /// Unique identifier (e.g. 'nsfw', 'violence', 'profanity').
  @override
  final String id;

  /// Human-readable name.
  @override
  final String name;

  /// Description of what this category detects.
  @override
  final String description;

  /// Whether this category detects visual or audio content.
  @override
  final CategoryType type;

  /// The action to apply when content in this category is detected.
  @override
  final RemediationAction action;

  /// Whether this category is enabled for detection.
  @override
  @JsonKey()
  final bool enabled;

  /// Detection threshold (0.0 to 1.0). The MoE consensus score must meet
  /// or exceed this threshold to trigger a detection.
  @override
  @JsonKey()
  final double threshold;

  /// Models that contribute to this category's detection via MoE voting.
  final List<ModelContribution> _modelContributions;

  /// Models that contribute to this category's detection via MoE voting.
  @override
  @JsonKey()
  List<ModelContribution> get modelContributions {
    if (_modelContributions is EqualUnmodifiableListView)
      return _modelContributions;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_modelContributions);
  }

  /// Whether this is a built-in category (vs user-created custom).
  @override
  @JsonKey()
  final bool isBuiltIn;

  /// Optional Material icon name for the UI.
  @override
  final String? iconName;

  /// Whether region-level detection (bounding boxes) is available.
  @override
  @JsonKey()
  final bool supportsRegions;

  @override
  String toString() {
    return 'ContentCategory(id: $id, name: $name, description: $description, type: $type, action: $action, enabled: $enabled, threshold: $threshold, modelContributions: $modelContributions, isBuiltIn: $isBuiltIn, iconName: $iconName, supportsRegions: $supportsRegions)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$ContentCategoryImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.name, name) || other.name == name) &&
            (identical(other.description, description) ||
                other.description == description) &&
            (identical(other.type, type) || other.type == type) &&
            (identical(other.action, action) || other.action == action) &&
            (identical(other.enabled, enabled) || other.enabled == enabled) &&
            (identical(other.threshold, threshold) ||
                other.threshold == threshold) &&
            const DeepCollectionEquality()
                .equals(other._modelContributions, _modelContributions) &&
            (identical(other.isBuiltIn, isBuiltIn) ||
                other.isBuiltIn == isBuiltIn) &&
            (identical(other.iconName, iconName) ||
                other.iconName == iconName) &&
            (identical(other.supportsRegions, supportsRegions) ||
                other.supportsRegions == supportsRegions));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
      runtimeType,
      id,
      name,
      description,
      type,
      action,
      enabled,
      threshold,
      const DeepCollectionEquality().hash(_modelContributions),
      isBuiltIn,
      iconName,
      supportsRegions);

  /// Create a copy of ContentCategory
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$ContentCategoryImplCopyWith<_$ContentCategoryImpl> get copyWith =>
      __$$ContentCategoryImplCopyWithImpl<_$ContentCategoryImpl>(
          this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$ContentCategoryImplToJson(
      this,
    );
  }
}

abstract class _ContentCategory extends ContentCategory {
  const factory _ContentCategory(
      {required final String id,
      required final String name,
      required final String description,
      required final CategoryType type,
      required final RemediationAction action,
      final bool enabled,
      final double threshold,
      final List<ModelContribution> modelContributions,
      final bool isBuiltIn,
      final String? iconName,
      final bool supportsRegions}) = _$ContentCategoryImpl;
  const _ContentCategory._() : super._();

  factory _ContentCategory.fromJson(Map<String, dynamic> json) =
      _$ContentCategoryImpl.fromJson;

  /// Unique identifier (e.g. 'nsfw', 'violence', 'profanity').
  @override
  String get id;

  /// Human-readable name.
  @override
  String get name;

  /// Description of what this category detects.
  @override
  String get description;

  /// Whether this category detects visual or audio content.
  @override
  CategoryType get type;

  /// The action to apply when content in this category is detected.
  @override
  RemediationAction get action;

  /// Whether this category is enabled for detection.
  @override
  bool get enabled;

  /// Detection threshold (0.0 to 1.0). The MoE consensus score must meet
  /// or exceed this threshold to trigger a detection.
  @override
  double get threshold;

  /// Models that contribute to this category's detection via MoE voting.
  @override
  List<ModelContribution> get modelContributions;

  /// Whether this is a built-in category (vs user-created custom).
  @override
  bool get isBuiltIn;

  /// Optional Material icon name for the UI.
  @override
  String? get iconName;

  /// Whether region-level detection (bounding boxes) is available.
  @override
  bool get supportsRegions;

  /// Create a copy of ContentCategory
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$ContentCategoryImplCopyWith<_$ContentCategoryImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
