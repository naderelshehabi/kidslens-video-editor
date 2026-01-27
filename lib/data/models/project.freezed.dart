// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'project.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

Project _$ProjectFromJson(Map<String, dynamic> json) {
  return _Project.fromJson(json);
}

/// @nodoc
mixin _$Project {
  /// Unique identifier for the project
  String get id => throw _privateConstructorUsedError;

  /// Project name (displayed in UI)
  String get name => throw _privateConstructorUsedError;

  /// Absolute path to the .kle project file
  String get projectPath => throw _privateConstructorUsedError;

  /// When the project was created
  @DateTimeConverter()
  DateTime get createdAt => throw _privateConstructorUsedError;

  /// When the project was last modified
  @DateTimeConverter()
  DateTime get modifiedAt => throw _privateConstructorUsedError;

  /// Media files imported into the project
  List<MediaFile> get mediaFiles => throw _privateConstructorUsedError;

  /// Currently selected media file ID for editing
  String? get selectedMediaId => throw _privateConstructorUsedError;

  /// All detections found during analysis
  List<Detection> get detections => throw _privateConstructorUsedError;

  /// Edit actions applied to the project (cuts, blurs, mutes)
  List<EditAction> get editActions => throw _privateConstructorUsedError;

  /// Project settings
  ProjectSettings get settings => throw _privateConstructorUsedError;

  /// Analysis progress (0.0 to 1.0, null if not started)
  double? get analysisProgress => throw _privateConstructorUsedError;

  /// Whether analysis is complete
  bool get analysisComplete => throw _privateConstructorUsedError;

  /// Serializes this Project to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of Project
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $ProjectCopyWith<Project> get copyWith => throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $ProjectCopyWith<$Res> {
  factory $ProjectCopyWith(Project value, $Res Function(Project) then) =
      _$ProjectCopyWithImpl<$Res, Project>;
  @useResult
  $Res call(
      {String id,
      String name,
      String projectPath,
      @DateTimeConverter() DateTime createdAt,
      @DateTimeConverter() DateTime modifiedAt,
      List<MediaFile> mediaFiles,
      String? selectedMediaId,
      List<Detection> detections,
      List<EditAction> editActions,
      ProjectSettings settings,
      double? analysisProgress,
      bool analysisComplete});

  $ProjectSettingsCopyWith<$Res> get settings;
}

/// @nodoc
class _$ProjectCopyWithImpl<$Res, $Val extends Project>
    implements $ProjectCopyWith<$Res> {
  _$ProjectCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of Project
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? name = null,
    Object? projectPath = null,
    Object? createdAt = null,
    Object? modifiedAt = null,
    Object? mediaFiles = null,
    Object? selectedMediaId = freezed,
    Object? detections = null,
    Object? editActions = null,
    Object? settings = null,
    Object? analysisProgress = freezed,
    Object? analysisComplete = null,
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
      projectPath: null == projectPath
          ? _value.projectPath
          : projectPath // ignore: cast_nullable_to_non_nullable
              as String,
      createdAt: null == createdAt
          ? _value.createdAt
          : createdAt // ignore: cast_nullable_to_non_nullable
              as DateTime,
      modifiedAt: null == modifiedAt
          ? _value.modifiedAt
          : modifiedAt // ignore: cast_nullable_to_non_nullable
              as DateTime,
      mediaFiles: null == mediaFiles
          ? _value.mediaFiles
          : mediaFiles // ignore: cast_nullable_to_non_nullable
              as List<MediaFile>,
      selectedMediaId: freezed == selectedMediaId
          ? _value.selectedMediaId
          : selectedMediaId // ignore: cast_nullable_to_non_nullable
              as String?,
      detections: null == detections
          ? _value.detections
          : detections // ignore: cast_nullable_to_non_nullable
              as List<Detection>,
      editActions: null == editActions
          ? _value.editActions
          : editActions // ignore: cast_nullable_to_non_nullable
              as List<EditAction>,
      settings: null == settings
          ? _value.settings
          : settings // ignore: cast_nullable_to_non_nullable
              as ProjectSettings,
      analysisProgress: freezed == analysisProgress
          ? _value.analysisProgress
          : analysisProgress // ignore: cast_nullable_to_non_nullable
              as double?,
      analysisComplete: null == analysisComplete
          ? _value.analysisComplete
          : analysisComplete // ignore: cast_nullable_to_non_nullable
              as bool,
    ) as $Val);
  }

  /// Create a copy of Project
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $ProjectSettingsCopyWith<$Res> get settings {
    return $ProjectSettingsCopyWith<$Res>(_value.settings, (value) {
      return _then(_value.copyWith(settings: value) as $Val);
    });
  }
}

/// @nodoc
abstract class _$$ProjectImplCopyWith<$Res> implements $ProjectCopyWith<$Res> {
  factory _$$ProjectImplCopyWith(
          _$ProjectImpl value, $Res Function(_$ProjectImpl) then) =
      __$$ProjectImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String id,
      String name,
      String projectPath,
      @DateTimeConverter() DateTime createdAt,
      @DateTimeConverter() DateTime modifiedAt,
      List<MediaFile> mediaFiles,
      String? selectedMediaId,
      List<Detection> detections,
      List<EditAction> editActions,
      ProjectSettings settings,
      double? analysisProgress,
      bool analysisComplete});

  @override
  $ProjectSettingsCopyWith<$Res> get settings;
}

/// @nodoc
class __$$ProjectImplCopyWithImpl<$Res>
    extends _$ProjectCopyWithImpl<$Res, _$ProjectImpl>
    implements _$$ProjectImplCopyWith<$Res> {
  __$$ProjectImplCopyWithImpl(
      _$ProjectImpl _value, $Res Function(_$ProjectImpl) _then)
      : super(_value, _then);

  /// Create a copy of Project
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? name = null,
    Object? projectPath = null,
    Object? createdAt = null,
    Object? modifiedAt = null,
    Object? mediaFiles = null,
    Object? selectedMediaId = freezed,
    Object? detections = null,
    Object? editActions = null,
    Object? settings = null,
    Object? analysisProgress = freezed,
    Object? analysisComplete = null,
  }) {
    return _then(_$ProjectImpl(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      name: null == name
          ? _value.name
          : name // ignore: cast_nullable_to_non_nullable
              as String,
      projectPath: null == projectPath
          ? _value.projectPath
          : projectPath // ignore: cast_nullable_to_non_nullable
              as String,
      createdAt: null == createdAt
          ? _value.createdAt
          : createdAt // ignore: cast_nullable_to_non_nullable
              as DateTime,
      modifiedAt: null == modifiedAt
          ? _value.modifiedAt
          : modifiedAt // ignore: cast_nullable_to_non_nullable
              as DateTime,
      mediaFiles: null == mediaFiles
          ? _value._mediaFiles
          : mediaFiles // ignore: cast_nullable_to_non_nullable
              as List<MediaFile>,
      selectedMediaId: freezed == selectedMediaId
          ? _value.selectedMediaId
          : selectedMediaId // ignore: cast_nullable_to_non_nullable
              as String?,
      detections: null == detections
          ? _value._detections
          : detections // ignore: cast_nullable_to_non_nullable
              as List<Detection>,
      editActions: null == editActions
          ? _value._editActions
          : editActions // ignore: cast_nullable_to_non_nullable
              as List<EditAction>,
      settings: null == settings
          ? _value.settings
          : settings // ignore: cast_nullable_to_non_nullable
              as ProjectSettings,
      analysisProgress: freezed == analysisProgress
          ? _value.analysisProgress
          : analysisProgress // ignore: cast_nullable_to_non_nullable
              as double?,
      analysisComplete: null == analysisComplete
          ? _value.analysisComplete
          : analysisComplete // ignore: cast_nullable_to_non_nullable
              as bool,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$ProjectImpl extends _Project {
  const _$ProjectImpl(
      {required this.id,
      required this.name,
      required this.projectPath,
      @DateTimeConverter() required this.createdAt,
      @DateTimeConverter() required this.modifiedAt,
      final List<MediaFile> mediaFiles = const [],
      this.selectedMediaId,
      final List<Detection> detections = const [],
      final List<EditAction> editActions = const [],
      this.settings = const ProjectSettings(),
      this.analysisProgress,
      this.analysisComplete = false})
      : _mediaFiles = mediaFiles,
        _detections = detections,
        _editActions = editActions,
        super._();

  factory _$ProjectImpl.fromJson(Map<String, dynamic> json) =>
      _$$ProjectImplFromJson(json);

  /// Unique identifier for the project
  @override
  final String id;

  /// Project name (displayed in UI)
  @override
  final String name;

  /// Absolute path to the .kle project file
  @override
  final String projectPath;

  /// When the project was created
  @override
  @DateTimeConverter()
  final DateTime createdAt;

  /// When the project was last modified
  @override
  @DateTimeConverter()
  final DateTime modifiedAt;

  /// Media files imported into the project
  final List<MediaFile> _mediaFiles;

  /// Media files imported into the project
  @override
  @JsonKey()
  List<MediaFile> get mediaFiles {
    if (_mediaFiles is EqualUnmodifiableListView) return _mediaFiles;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_mediaFiles);
  }

  /// Currently selected media file ID for editing
  @override
  final String? selectedMediaId;

  /// All detections found during analysis
  final List<Detection> _detections;

  /// All detections found during analysis
  @override
  @JsonKey()
  List<Detection> get detections {
    if (_detections is EqualUnmodifiableListView) return _detections;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_detections);
  }

  /// Edit actions applied to the project (cuts, blurs, mutes)
  final List<EditAction> _editActions;

  /// Edit actions applied to the project (cuts, blurs, mutes)
  @override
  @JsonKey()
  List<EditAction> get editActions {
    if (_editActions is EqualUnmodifiableListView) return _editActions;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_editActions);
  }

  /// Project settings
  @override
  @JsonKey()
  final ProjectSettings settings;

  /// Analysis progress (0.0 to 1.0, null if not started)
  @override
  final double? analysisProgress;

  /// Whether analysis is complete
  @override
  @JsonKey()
  final bool analysisComplete;

  @override
  String toString() {
    return 'Project(id: $id, name: $name, projectPath: $projectPath, createdAt: $createdAt, modifiedAt: $modifiedAt, mediaFiles: $mediaFiles, selectedMediaId: $selectedMediaId, detections: $detections, editActions: $editActions, settings: $settings, analysisProgress: $analysisProgress, analysisComplete: $analysisComplete)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$ProjectImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.name, name) || other.name == name) &&
            (identical(other.projectPath, projectPath) ||
                other.projectPath == projectPath) &&
            (identical(other.createdAt, createdAt) ||
                other.createdAt == createdAt) &&
            (identical(other.modifiedAt, modifiedAt) ||
                other.modifiedAt == modifiedAt) &&
            const DeepCollectionEquality()
                .equals(other._mediaFiles, _mediaFiles) &&
            (identical(other.selectedMediaId, selectedMediaId) ||
                other.selectedMediaId == selectedMediaId) &&
            const DeepCollectionEquality()
                .equals(other._detections, _detections) &&
            const DeepCollectionEquality()
                .equals(other._editActions, _editActions) &&
            (identical(other.settings, settings) ||
                other.settings == settings) &&
            (identical(other.analysisProgress, analysisProgress) ||
                other.analysisProgress == analysisProgress) &&
            (identical(other.analysisComplete, analysisComplete) ||
                other.analysisComplete == analysisComplete));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
      runtimeType,
      id,
      name,
      projectPath,
      createdAt,
      modifiedAt,
      const DeepCollectionEquality().hash(_mediaFiles),
      selectedMediaId,
      const DeepCollectionEquality().hash(_detections),
      const DeepCollectionEquality().hash(_editActions),
      settings,
      analysisProgress,
      analysisComplete);

  /// Create a copy of Project
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$ProjectImplCopyWith<_$ProjectImpl> get copyWith =>
      __$$ProjectImplCopyWithImpl<_$ProjectImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$ProjectImplToJson(
      this,
    );
  }
}

abstract class _Project extends Project {
  const factory _Project(
      {required final String id,
      required final String name,
      required final String projectPath,
      @DateTimeConverter() required final DateTime createdAt,
      @DateTimeConverter() required final DateTime modifiedAt,
      final List<MediaFile> mediaFiles,
      final String? selectedMediaId,
      final List<Detection> detections,
      final List<EditAction> editActions,
      final ProjectSettings settings,
      final double? analysisProgress,
      final bool analysisComplete}) = _$ProjectImpl;
  const _Project._() : super._();

  factory _Project.fromJson(Map<String, dynamic> json) = _$ProjectImpl.fromJson;

  /// Unique identifier for the project
  @override
  String get id;

  /// Project name (displayed in UI)
  @override
  String get name;

  /// Absolute path to the .kle project file
  @override
  String get projectPath;

  /// When the project was created
  @override
  @DateTimeConverter()
  DateTime get createdAt;

  /// When the project was last modified
  @override
  @DateTimeConverter()
  DateTime get modifiedAt;

  /// Media files imported into the project
  @override
  List<MediaFile> get mediaFiles;

  /// Currently selected media file ID for editing
  @override
  String? get selectedMediaId;

  /// All detections found during analysis
  @override
  List<Detection> get detections;

  /// Edit actions applied to the project (cuts, blurs, mutes)
  @override
  List<EditAction> get editActions;

  /// Project settings
  @override
  ProjectSettings get settings;

  /// Analysis progress (0.0 to 1.0, null if not started)
  @override
  double? get analysisProgress;

  /// Whether analysis is complete
  @override
  bool get analysisComplete;

  /// Create a copy of Project
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$ProjectImplCopyWith<_$ProjectImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

ProjectSettings _$ProjectSettingsFromJson(Map<String, dynamic> json) {
  return _ProjectSettings.fromJson(json);
}

/// @nodoc
mixin _$ProjectSettings {
  /// Output quality preset
  OutputQuality get outputQuality => throw _privateConstructorUsedError;

  /// Whether to include original audio in export
  bool get includeOriginalAudio => throw _privateConstructorUsedError;

  /// Whether to auto-save project changes
  bool get autoSave => throw _privateConstructorUsedError;

  /// Auto-save interval in seconds
  int get autoSaveIntervalSeconds => throw _privateConstructorUsedError;

  /// Detection sensitivity (0.0 to 1.0)
  double get detectionSensitivity => throw _privateConstructorUsedError;

  /// Categories to detect
  DetectionCategories get detectionCategories =>
      throw _privateConstructorUsedError;

  /// Serializes this ProjectSettings to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of ProjectSettings
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $ProjectSettingsCopyWith<ProjectSettings> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $ProjectSettingsCopyWith<$Res> {
  factory $ProjectSettingsCopyWith(
          ProjectSettings value, $Res Function(ProjectSettings) then) =
      _$ProjectSettingsCopyWithImpl<$Res, ProjectSettings>;
  @useResult
  $Res call(
      {OutputQuality outputQuality,
      bool includeOriginalAudio,
      bool autoSave,
      int autoSaveIntervalSeconds,
      double detectionSensitivity,
      DetectionCategories detectionCategories});

  $DetectionCategoriesCopyWith<$Res> get detectionCategories;
}

/// @nodoc
class _$ProjectSettingsCopyWithImpl<$Res, $Val extends ProjectSettings>
    implements $ProjectSettingsCopyWith<$Res> {
  _$ProjectSettingsCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of ProjectSettings
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? outputQuality = null,
    Object? includeOriginalAudio = null,
    Object? autoSave = null,
    Object? autoSaveIntervalSeconds = null,
    Object? detectionSensitivity = null,
    Object? detectionCategories = null,
  }) {
    return _then(_value.copyWith(
      outputQuality: null == outputQuality
          ? _value.outputQuality
          : outputQuality // ignore: cast_nullable_to_non_nullable
              as OutputQuality,
      includeOriginalAudio: null == includeOriginalAudio
          ? _value.includeOriginalAudio
          : includeOriginalAudio // ignore: cast_nullable_to_non_nullable
              as bool,
      autoSave: null == autoSave
          ? _value.autoSave
          : autoSave // ignore: cast_nullable_to_non_nullable
              as bool,
      autoSaveIntervalSeconds: null == autoSaveIntervalSeconds
          ? _value.autoSaveIntervalSeconds
          : autoSaveIntervalSeconds // ignore: cast_nullable_to_non_nullable
              as int,
      detectionSensitivity: null == detectionSensitivity
          ? _value.detectionSensitivity
          : detectionSensitivity // ignore: cast_nullable_to_non_nullable
              as double,
      detectionCategories: null == detectionCategories
          ? _value.detectionCategories
          : detectionCategories // ignore: cast_nullable_to_non_nullable
              as DetectionCategories,
    ) as $Val);
  }

  /// Create a copy of ProjectSettings
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $DetectionCategoriesCopyWith<$Res> get detectionCategories {
    return $DetectionCategoriesCopyWith<$Res>(_value.detectionCategories,
        (value) {
      return _then(_value.copyWith(detectionCategories: value) as $Val);
    });
  }
}

/// @nodoc
abstract class _$$ProjectSettingsImplCopyWith<$Res>
    implements $ProjectSettingsCopyWith<$Res> {
  factory _$$ProjectSettingsImplCopyWith(_$ProjectSettingsImpl value,
          $Res Function(_$ProjectSettingsImpl) then) =
      __$$ProjectSettingsImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {OutputQuality outputQuality,
      bool includeOriginalAudio,
      bool autoSave,
      int autoSaveIntervalSeconds,
      double detectionSensitivity,
      DetectionCategories detectionCategories});

  @override
  $DetectionCategoriesCopyWith<$Res> get detectionCategories;
}

/// @nodoc
class __$$ProjectSettingsImplCopyWithImpl<$Res>
    extends _$ProjectSettingsCopyWithImpl<$Res, _$ProjectSettingsImpl>
    implements _$$ProjectSettingsImplCopyWith<$Res> {
  __$$ProjectSettingsImplCopyWithImpl(
      _$ProjectSettingsImpl _value, $Res Function(_$ProjectSettingsImpl) _then)
      : super(_value, _then);

  /// Create a copy of ProjectSettings
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? outputQuality = null,
    Object? includeOriginalAudio = null,
    Object? autoSave = null,
    Object? autoSaveIntervalSeconds = null,
    Object? detectionSensitivity = null,
    Object? detectionCategories = null,
  }) {
    return _then(_$ProjectSettingsImpl(
      outputQuality: null == outputQuality
          ? _value.outputQuality
          : outputQuality // ignore: cast_nullable_to_non_nullable
              as OutputQuality,
      includeOriginalAudio: null == includeOriginalAudio
          ? _value.includeOriginalAudio
          : includeOriginalAudio // ignore: cast_nullable_to_non_nullable
              as bool,
      autoSave: null == autoSave
          ? _value.autoSave
          : autoSave // ignore: cast_nullable_to_non_nullable
              as bool,
      autoSaveIntervalSeconds: null == autoSaveIntervalSeconds
          ? _value.autoSaveIntervalSeconds
          : autoSaveIntervalSeconds // ignore: cast_nullable_to_non_nullable
              as int,
      detectionSensitivity: null == detectionSensitivity
          ? _value.detectionSensitivity
          : detectionSensitivity // ignore: cast_nullable_to_non_nullable
              as double,
      detectionCategories: null == detectionCategories
          ? _value.detectionCategories
          : detectionCategories // ignore: cast_nullable_to_non_nullable
              as DetectionCategories,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$ProjectSettingsImpl implements _ProjectSettings {
  const _$ProjectSettingsImpl(
      {this.outputQuality = OutputQuality.high,
      this.includeOriginalAudio = true,
      this.autoSave = true,
      this.autoSaveIntervalSeconds = 60,
      this.detectionSensitivity = 0.7,
      this.detectionCategories = const DetectionCategories()});

  factory _$ProjectSettingsImpl.fromJson(Map<String, dynamic> json) =>
      _$$ProjectSettingsImplFromJson(json);

  /// Output quality preset
  @override
  @JsonKey()
  final OutputQuality outputQuality;

  /// Whether to include original audio in export
  @override
  @JsonKey()
  final bool includeOriginalAudio;

  /// Whether to auto-save project changes
  @override
  @JsonKey()
  final bool autoSave;

  /// Auto-save interval in seconds
  @override
  @JsonKey()
  final int autoSaveIntervalSeconds;

  /// Detection sensitivity (0.0 to 1.0)
  @override
  @JsonKey()
  final double detectionSensitivity;

  /// Categories to detect
  @override
  @JsonKey()
  final DetectionCategories detectionCategories;

  @override
  String toString() {
    return 'ProjectSettings(outputQuality: $outputQuality, includeOriginalAudio: $includeOriginalAudio, autoSave: $autoSave, autoSaveIntervalSeconds: $autoSaveIntervalSeconds, detectionSensitivity: $detectionSensitivity, detectionCategories: $detectionCategories)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$ProjectSettingsImpl &&
            (identical(other.outputQuality, outputQuality) ||
                other.outputQuality == outputQuality) &&
            (identical(other.includeOriginalAudio, includeOriginalAudio) ||
                other.includeOriginalAudio == includeOriginalAudio) &&
            (identical(other.autoSave, autoSave) ||
                other.autoSave == autoSave) &&
            (identical(
                    other.autoSaveIntervalSeconds, autoSaveIntervalSeconds) ||
                other.autoSaveIntervalSeconds == autoSaveIntervalSeconds) &&
            (identical(other.detectionSensitivity, detectionSensitivity) ||
                other.detectionSensitivity == detectionSensitivity) &&
            (identical(other.detectionCategories, detectionCategories) ||
                other.detectionCategories == detectionCategories));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
      runtimeType,
      outputQuality,
      includeOriginalAudio,
      autoSave,
      autoSaveIntervalSeconds,
      detectionSensitivity,
      detectionCategories);

  /// Create a copy of ProjectSettings
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$ProjectSettingsImplCopyWith<_$ProjectSettingsImpl> get copyWith =>
      __$$ProjectSettingsImplCopyWithImpl<_$ProjectSettingsImpl>(
          this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$ProjectSettingsImplToJson(
      this,
    );
  }
}

abstract class _ProjectSettings implements ProjectSettings {
  const factory _ProjectSettings(
      {final OutputQuality outputQuality,
      final bool includeOriginalAudio,
      final bool autoSave,
      final int autoSaveIntervalSeconds,
      final double detectionSensitivity,
      final DetectionCategories detectionCategories}) = _$ProjectSettingsImpl;

  factory _ProjectSettings.fromJson(Map<String, dynamic> json) =
      _$ProjectSettingsImpl.fromJson;

  /// Output quality preset
  @override
  OutputQuality get outputQuality;

  /// Whether to include original audio in export
  @override
  bool get includeOriginalAudio;

  /// Whether to auto-save project changes
  @override
  bool get autoSave;

  /// Auto-save interval in seconds
  @override
  int get autoSaveIntervalSeconds;

  /// Detection sensitivity (0.0 to 1.0)
  @override
  double get detectionSensitivity;

  /// Categories to detect
  @override
  DetectionCategories get detectionCategories;

  /// Create a copy of ProjectSettings
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$ProjectSettingsImplCopyWith<_$ProjectSettingsImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

DetectionCategories _$DetectionCategoriesFromJson(Map<String, dynamic> json) {
  return _DetectionCategories.fromJson(json);
}

/// @nodoc
mixin _$DetectionCategories {
  bool get profanity => throw _privateConstructorUsedError;
  bool get nudity => throw _privateConstructorUsedError;
  bool get violence => throw _privateConstructorUsedError;
  bool get drugs => throw _privateConstructorUsedError;
  bool get alcohol => throw _privateConstructorUsedError;
  bool get customWords => throw _privateConstructorUsedError;
  List<String> get customWordList => throw _privateConstructorUsedError;

  /// Serializes this DetectionCategories to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of DetectionCategories
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $DetectionCategoriesCopyWith<DetectionCategories> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $DetectionCategoriesCopyWith<$Res> {
  factory $DetectionCategoriesCopyWith(
          DetectionCategories value, $Res Function(DetectionCategories) then) =
      _$DetectionCategoriesCopyWithImpl<$Res, DetectionCategories>;
  @useResult
  $Res call(
      {bool profanity,
      bool nudity,
      bool violence,
      bool drugs,
      bool alcohol,
      bool customWords,
      List<String> customWordList});
}

/// @nodoc
class _$DetectionCategoriesCopyWithImpl<$Res, $Val extends DetectionCategories>
    implements $DetectionCategoriesCopyWith<$Res> {
  _$DetectionCategoriesCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of DetectionCategories
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? profanity = null,
    Object? nudity = null,
    Object? violence = null,
    Object? drugs = null,
    Object? alcohol = null,
    Object? customWords = null,
    Object? customWordList = null,
  }) {
    return _then(_value.copyWith(
      profanity: null == profanity
          ? _value.profanity
          : profanity // ignore: cast_nullable_to_non_nullable
              as bool,
      nudity: null == nudity
          ? _value.nudity
          : nudity // ignore: cast_nullable_to_non_nullable
              as bool,
      violence: null == violence
          ? _value.violence
          : violence // ignore: cast_nullable_to_non_nullable
              as bool,
      drugs: null == drugs
          ? _value.drugs
          : drugs // ignore: cast_nullable_to_non_nullable
              as bool,
      alcohol: null == alcohol
          ? _value.alcohol
          : alcohol // ignore: cast_nullable_to_non_nullable
              as bool,
      customWords: null == customWords
          ? _value.customWords
          : customWords // ignore: cast_nullable_to_non_nullable
              as bool,
      customWordList: null == customWordList
          ? _value.customWordList
          : customWordList // ignore: cast_nullable_to_non_nullable
              as List<String>,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$DetectionCategoriesImplCopyWith<$Res>
    implements $DetectionCategoriesCopyWith<$Res> {
  factory _$$DetectionCategoriesImplCopyWith(_$DetectionCategoriesImpl value,
          $Res Function(_$DetectionCategoriesImpl) then) =
      __$$DetectionCategoriesImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {bool profanity,
      bool nudity,
      bool violence,
      bool drugs,
      bool alcohol,
      bool customWords,
      List<String> customWordList});
}

/// @nodoc
class __$$DetectionCategoriesImplCopyWithImpl<$Res>
    extends _$DetectionCategoriesCopyWithImpl<$Res, _$DetectionCategoriesImpl>
    implements _$$DetectionCategoriesImplCopyWith<$Res> {
  __$$DetectionCategoriesImplCopyWithImpl(_$DetectionCategoriesImpl _value,
      $Res Function(_$DetectionCategoriesImpl) _then)
      : super(_value, _then);

  /// Create a copy of DetectionCategories
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? profanity = null,
    Object? nudity = null,
    Object? violence = null,
    Object? drugs = null,
    Object? alcohol = null,
    Object? customWords = null,
    Object? customWordList = null,
  }) {
    return _then(_$DetectionCategoriesImpl(
      profanity: null == profanity
          ? _value.profanity
          : profanity // ignore: cast_nullable_to_non_nullable
              as bool,
      nudity: null == nudity
          ? _value.nudity
          : nudity // ignore: cast_nullable_to_non_nullable
              as bool,
      violence: null == violence
          ? _value.violence
          : violence // ignore: cast_nullable_to_non_nullable
              as bool,
      drugs: null == drugs
          ? _value.drugs
          : drugs // ignore: cast_nullable_to_non_nullable
              as bool,
      alcohol: null == alcohol
          ? _value.alcohol
          : alcohol // ignore: cast_nullable_to_non_nullable
              as bool,
      customWords: null == customWords
          ? _value.customWords
          : customWords // ignore: cast_nullable_to_non_nullable
              as bool,
      customWordList: null == customWordList
          ? _value._customWordList
          : customWordList // ignore: cast_nullable_to_non_nullable
              as List<String>,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$DetectionCategoriesImpl implements _DetectionCategories {
  const _$DetectionCategoriesImpl(
      {this.profanity = true,
      this.nudity = true,
      this.violence = true,
      this.drugs = true,
      this.alcohol = true,
      this.customWords = false,
      final List<String> customWordList = const []})
      : _customWordList = customWordList;

  factory _$DetectionCategoriesImpl.fromJson(Map<String, dynamic> json) =>
      _$$DetectionCategoriesImplFromJson(json);

  @override
  @JsonKey()
  final bool profanity;
  @override
  @JsonKey()
  final bool nudity;
  @override
  @JsonKey()
  final bool violence;
  @override
  @JsonKey()
  final bool drugs;
  @override
  @JsonKey()
  final bool alcohol;
  @override
  @JsonKey()
  final bool customWords;
  final List<String> _customWordList;
  @override
  @JsonKey()
  List<String> get customWordList {
    if (_customWordList is EqualUnmodifiableListView) return _customWordList;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_customWordList);
  }

  @override
  String toString() {
    return 'DetectionCategories(profanity: $profanity, nudity: $nudity, violence: $violence, drugs: $drugs, alcohol: $alcohol, customWords: $customWords, customWordList: $customWordList)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$DetectionCategoriesImpl &&
            (identical(other.profanity, profanity) ||
                other.profanity == profanity) &&
            (identical(other.nudity, nudity) || other.nudity == nudity) &&
            (identical(other.violence, violence) ||
                other.violence == violence) &&
            (identical(other.drugs, drugs) || other.drugs == drugs) &&
            (identical(other.alcohol, alcohol) || other.alcohol == alcohol) &&
            (identical(other.customWords, customWords) ||
                other.customWords == customWords) &&
            const DeepCollectionEquality()
                .equals(other._customWordList, _customWordList));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
      runtimeType,
      profanity,
      nudity,
      violence,
      drugs,
      alcohol,
      customWords,
      const DeepCollectionEquality().hash(_customWordList));

  /// Create a copy of DetectionCategories
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$DetectionCategoriesImplCopyWith<_$DetectionCategoriesImpl> get copyWith =>
      __$$DetectionCategoriesImplCopyWithImpl<_$DetectionCategoriesImpl>(
          this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$DetectionCategoriesImplToJson(
      this,
    );
  }
}

abstract class _DetectionCategories implements DetectionCategories {
  const factory _DetectionCategories(
      {final bool profanity,
      final bool nudity,
      final bool violence,
      final bool drugs,
      final bool alcohol,
      final bool customWords,
      final List<String> customWordList}) = _$DetectionCategoriesImpl;

  factory _DetectionCategories.fromJson(Map<String, dynamic> json) =
      _$DetectionCategoriesImpl.fromJson;

  @override
  bool get profanity;
  @override
  bool get nudity;
  @override
  bool get violence;
  @override
  bool get drugs;
  @override
  bool get alcohol;
  @override
  bool get customWords;
  @override
  List<String> get customWordList;

  /// Create a copy of DetectionCategories
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$DetectionCategoriesImplCopyWith<_$DetectionCategoriesImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
