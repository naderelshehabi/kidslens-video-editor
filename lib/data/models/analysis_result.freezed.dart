// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'analysis_result.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

AnalysisProgress _$AnalysisProgressFromJson(Map<String, dynamic> json) {
  return _AnalysisProgress.fromJson(json);
}

/// @nodoc
mixin _$AnalysisProgress {
  /// Current step name (e.g., 'Transcribing', 'Analyzing frames')
  String get stepName => throw _privateConstructorUsedError;

  /// Current step number (1-based)
  int get currentStep => throw _privateConstructorUsedError;

  /// Total number of steps
  int get totalSteps => throw _privateConstructorUsedError;

  /// Progress within current step (0.0 to 1.0)
  double get stepProgress => throw _privateConstructorUsedError;

  /// Estimated time remaining in seconds
  int? get estimatedSecondsRemaining => throw _privateConstructorUsedError;

  /// Number of items processed in current step
  int? get itemsProcessed => throw _privateConstructorUsedError;

  /// Total items in current step
  int? get totalItems => throw _privateConstructorUsedError;

  /// Media duration processed so far in milliseconds.
  int? get processedDurationMs => throw _privateConstructorUsedError;

  /// Total media duration in milliseconds.
  int? get totalDurationMs => throw _privateConstructorUsedError;

  /// Serializes this AnalysisProgress to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of AnalysisProgress
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $AnalysisProgressCopyWith<AnalysisProgress> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $AnalysisProgressCopyWith<$Res> {
  factory $AnalysisProgressCopyWith(
          AnalysisProgress value, $Res Function(AnalysisProgress) then) =
      _$AnalysisProgressCopyWithImpl<$Res, AnalysisProgress>;
  @useResult
  $Res call(
      {String stepName,
      int currentStep,
      int totalSteps,
      double stepProgress,
      int? estimatedSecondsRemaining,
      int? itemsProcessed,
      int? totalItems,
      int? processedDurationMs,
      int? totalDurationMs});
}

/// @nodoc
class _$AnalysisProgressCopyWithImpl<$Res, $Val extends AnalysisProgress>
    implements $AnalysisProgressCopyWith<$Res> {
  _$AnalysisProgressCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of AnalysisProgress
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? stepName = null,
    Object? currentStep = null,
    Object? totalSteps = null,
    Object? stepProgress = null,
    Object? estimatedSecondsRemaining = freezed,
    Object? itemsProcessed = freezed,
    Object? totalItems = freezed,
    Object? processedDurationMs = freezed,
    Object? totalDurationMs = freezed,
  }) {
    return _then(_value.copyWith(
      stepName: null == stepName
          ? _value.stepName
          : stepName // ignore: cast_nullable_to_non_nullable
              as String,
      currentStep: null == currentStep
          ? _value.currentStep
          : currentStep // ignore: cast_nullable_to_non_nullable
              as int,
      totalSteps: null == totalSteps
          ? _value.totalSteps
          : totalSteps // ignore: cast_nullable_to_non_nullable
              as int,
      stepProgress: null == stepProgress
          ? _value.stepProgress
          : stepProgress // ignore: cast_nullable_to_non_nullable
              as double,
      estimatedSecondsRemaining: freezed == estimatedSecondsRemaining
          ? _value.estimatedSecondsRemaining
          : estimatedSecondsRemaining // ignore: cast_nullable_to_non_nullable
              as int?,
      itemsProcessed: freezed == itemsProcessed
          ? _value.itemsProcessed
          : itemsProcessed // ignore: cast_nullable_to_non_nullable
              as int?,
      totalItems: freezed == totalItems
          ? _value.totalItems
          : totalItems // ignore: cast_nullable_to_non_nullable
              as int?,
      processedDurationMs: freezed == processedDurationMs
          ? _value.processedDurationMs
          : processedDurationMs // ignore: cast_nullable_to_non_nullable
              as int?,
      totalDurationMs: freezed == totalDurationMs
          ? _value.totalDurationMs
          : totalDurationMs // ignore: cast_nullable_to_non_nullable
              as int?,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$AnalysisProgressImplCopyWith<$Res>
    implements $AnalysisProgressCopyWith<$Res> {
  factory _$$AnalysisProgressImplCopyWith(_$AnalysisProgressImpl value,
          $Res Function(_$AnalysisProgressImpl) then) =
      __$$AnalysisProgressImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String stepName,
      int currentStep,
      int totalSteps,
      double stepProgress,
      int? estimatedSecondsRemaining,
      int? itemsProcessed,
      int? totalItems,
      int? processedDurationMs,
      int? totalDurationMs});
}

/// @nodoc
class __$$AnalysisProgressImplCopyWithImpl<$Res>
    extends _$AnalysisProgressCopyWithImpl<$Res, _$AnalysisProgressImpl>
    implements _$$AnalysisProgressImplCopyWith<$Res> {
  __$$AnalysisProgressImplCopyWithImpl(_$AnalysisProgressImpl _value,
      $Res Function(_$AnalysisProgressImpl) _then)
      : super(_value, _then);

  /// Create a copy of AnalysisProgress
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? stepName = null,
    Object? currentStep = null,
    Object? totalSteps = null,
    Object? stepProgress = null,
    Object? estimatedSecondsRemaining = freezed,
    Object? itemsProcessed = freezed,
    Object? totalItems = freezed,
    Object? processedDurationMs = freezed,
    Object? totalDurationMs = freezed,
  }) {
    return _then(_$AnalysisProgressImpl(
      stepName: null == stepName
          ? _value.stepName
          : stepName // ignore: cast_nullable_to_non_nullable
              as String,
      currentStep: null == currentStep
          ? _value.currentStep
          : currentStep // ignore: cast_nullable_to_non_nullable
              as int,
      totalSteps: null == totalSteps
          ? _value.totalSteps
          : totalSteps // ignore: cast_nullable_to_non_nullable
              as int,
      stepProgress: null == stepProgress
          ? _value.stepProgress
          : stepProgress // ignore: cast_nullable_to_non_nullable
              as double,
      estimatedSecondsRemaining: freezed == estimatedSecondsRemaining
          ? _value.estimatedSecondsRemaining
          : estimatedSecondsRemaining // ignore: cast_nullable_to_non_nullable
              as int?,
      itemsProcessed: freezed == itemsProcessed
          ? _value.itemsProcessed
          : itemsProcessed // ignore: cast_nullable_to_non_nullable
              as int?,
      totalItems: freezed == totalItems
          ? _value.totalItems
          : totalItems // ignore: cast_nullable_to_non_nullable
              as int?,
      processedDurationMs: freezed == processedDurationMs
          ? _value.processedDurationMs
          : processedDurationMs // ignore: cast_nullable_to_non_nullable
              as int?,
      totalDurationMs: freezed == totalDurationMs
          ? _value.totalDurationMs
          : totalDurationMs // ignore: cast_nullable_to_non_nullable
              as int?,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$AnalysisProgressImpl extends _AnalysisProgress {
  const _$AnalysisProgressImpl(
      {required this.stepName,
      required this.currentStep,
      required this.totalSteps,
      required this.stepProgress,
      this.estimatedSecondsRemaining,
      this.itemsProcessed,
      this.totalItems,
      this.processedDurationMs,
      this.totalDurationMs})
      : super._();

  factory _$AnalysisProgressImpl.fromJson(Map<String, dynamic> json) =>
      _$$AnalysisProgressImplFromJson(json);

  /// Current step name (e.g., 'Transcribing', 'Analyzing frames')
  @override
  final String stepName;

  /// Current step number (1-based)
  @override
  final int currentStep;

  /// Total number of steps
  @override
  final int totalSteps;

  /// Progress within current step (0.0 to 1.0)
  @override
  final double stepProgress;

  /// Estimated time remaining in seconds
  @override
  final int? estimatedSecondsRemaining;

  /// Number of items processed in current step
  @override
  final int? itemsProcessed;

  /// Total items in current step
  @override
  final int? totalItems;

  /// Media duration processed so far in milliseconds.
  @override
  final int? processedDurationMs;

  /// Total media duration in milliseconds.
  @override
  final int? totalDurationMs;

  @override
  String toString() {
    return 'AnalysisProgress(stepName: $stepName, currentStep: $currentStep, totalSteps: $totalSteps, stepProgress: $stepProgress, estimatedSecondsRemaining: $estimatedSecondsRemaining, itemsProcessed: $itemsProcessed, totalItems: $totalItems, processedDurationMs: $processedDurationMs, totalDurationMs: $totalDurationMs)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$AnalysisProgressImpl &&
            (identical(other.stepName, stepName) ||
                other.stepName == stepName) &&
            (identical(other.currentStep, currentStep) ||
                other.currentStep == currentStep) &&
            (identical(other.totalSteps, totalSteps) ||
                other.totalSteps == totalSteps) &&
            (identical(other.stepProgress, stepProgress) ||
                other.stepProgress == stepProgress) &&
            (identical(other.estimatedSecondsRemaining,
                    estimatedSecondsRemaining) ||
                other.estimatedSecondsRemaining == estimatedSecondsRemaining) &&
            (identical(other.itemsProcessed, itemsProcessed) ||
                other.itemsProcessed == itemsProcessed) &&
            (identical(other.totalItems, totalItems) ||
                other.totalItems == totalItems) &&
            (identical(other.processedDurationMs, processedDurationMs) ||
                other.processedDurationMs == processedDurationMs) &&
            (identical(other.totalDurationMs, totalDurationMs) ||
                other.totalDurationMs == totalDurationMs));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
      runtimeType,
      stepName,
      currentStep,
      totalSteps,
      stepProgress,
      estimatedSecondsRemaining,
      itemsProcessed,
      totalItems,
      processedDurationMs,
      totalDurationMs);

  /// Create a copy of AnalysisProgress
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$AnalysisProgressImplCopyWith<_$AnalysisProgressImpl> get copyWith =>
      __$$AnalysisProgressImplCopyWithImpl<_$AnalysisProgressImpl>(
          this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$AnalysisProgressImplToJson(
      this,
    );
  }
}

abstract class _AnalysisProgress extends AnalysisProgress {
  const factory _AnalysisProgress(
      {required final String stepName,
      required final int currentStep,
      required final int totalSteps,
      required final double stepProgress,
      final int? estimatedSecondsRemaining,
      final int? itemsProcessed,
      final int? totalItems,
      final int? processedDurationMs,
      final int? totalDurationMs}) = _$AnalysisProgressImpl;
  const _AnalysisProgress._() : super._();

  factory _AnalysisProgress.fromJson(Map<String, dynamic> json) =
      _$AnalysisProgressImpl.fromJson;

  /// Current step name (e.g., 'Transcribing', 'Analyzing frames')
  @override
  String get stepName;

  /// Current step number (1-based)
  @override
  int get currentStep;

  /// Total number of steps
  @override
  int get totalSteps;

  /// Progress within current step (0.0 to 1.0)
  @override
  double get stepProgress;

  /// Estimated time remaining in seconds
  @override
  int? get estimatedSecondsRemaining;

  /// Number of items processed in current step
  @override
  int? get itemsProcessed;

  /// Total items in current step
  @override
  int? get totalItems;

  /// Media duration processed so far in milliseconds.
  @override
  int? get processedDurationMs;

  /// Total media duration in milliseconds.
  @override
  int? get totalDurationMs;

  /// Create a copy of AnalysisProgress
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$AnalysisProgressImplCopyWith<_$AnalysisProgressImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

AnalysisResult _$AnalysisResultFromJson(Map<String, dynamic> json) {
  return _AnalysisResult.fromJson(json);
}

/// @nodoc
mixin _$AnalysisResult {
  /// Unique identifier for this analysis
  String get id => throw _privateConstructorUsedError;

  /// Current status of the analysis
  AnalysisStatus get status => throw _privateConstructorUsedError;

  /// Generated transcript (null if not completed or audio analysis disabled)
  Transcript? get transcript => throw _privateConstructorUsedError;

  /// List of profanity matches found in transcript
  List<ProfanityMatch> get profanityMatches =>
      throw _privateConstructorUsedError;

  /// List of frame analysis results
  List<FrameAnalysisResult> get frameResults =>
      throw _privateConstructorUsedError;

  /// Unified timeline combining all detections
  UnifiedTimeline? get timeline => throw _privateConstructorUsedError;

  /// Total processing time
  @DurationConverter()
  Duration? get processingTime => throw _privateConstructorUsedError;

  /// Timestamp when analysis started
  DateTime? get startedAt => throw _privateConstructorUsedError;

  /// Timestamp when analysis completed
  DateTime? get completedAt => throw _privateConstructorUsedError;

  /// Error message if analysis failed
  String? get errorMessage => throw _privateConstructorUsedError;

  /// Current progress (for running analysis)
  AnalysisProgress? get progress => throw _privateConstructorUsedError;

  /// ID of the media file analyzed
  String? get mediaFileId => throw _privateConstructorUsedError;

  /// Settings used for this analysis
  Map<String, dynamic>? get settings => throw _privateConstructorUsedError;

  /// Serializes this AnalysisResult to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of AnalysisResult
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $AnalysisResultCopyWith<AnalysisResult> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $AnalysisResultCopyWith<$Res> {
  factory $AnalysisResultCopyWith(
          AnalysisResult value, $Res Function(AnalysisResult) then) =
      _$AnalysisResultCopyWithImpl<$Res, AnalysisResult>;
  @useResult
  $Res call(
      {String id,
      AnalysisStatus status,
      Transcript? transcript,
      List<ProfanityMatch> profanityMatches,
      List<FrameAnalysisResult> frameResults,
      UnifiedTimeline? timeline,
      @DurationConverter() Duration? processingTime,
      DateTime? startedAt,
      DateTime? completedAt,
      String? errorMessage,
      AnalysisProgress? progress,
      String? mediaFileId,
      Map<String, dynamic>? settings});

  $TranscriptCopyWith<$Res>? get transcript;
  $UnifiedTimelineCopyWith<$Res>? get timeline;
  $AnalysisProgressCopyWith<$Res>? get progress;
}

/// @nodoc
class _$AnalysisResultCopyWithImpl<$Res, $Val extends AnalysisResult>
    implements $AnalysisResultCopyWith<$Res> {
  _$AnalysisResultCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of AnalysisResult
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? status = null,
    Object? transcript = freezed,
    Object? profanityMatches = null,
    Object? frameResults = null,
    Object? timeline = freezed,
    Object? processingTime = freezed,
    Object? startedAt = freezed,
    Object? completedAt = freezed,
    Object? errorMessage = freezed,
    Object? progress = freezed,
    Object? mediaFileId = freezed,
    Object? settings = freezed,
  }) {
    return _then(_value.copyWith(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      status: null == status
          ? _value.status
          : status // ignore: cast_nullable_to_non_nullable
              as AnalysisStatus,
      transcript: freezed == transcript
          ? _value.transcript
          : transcript // ignore: cast_nullable_to_non_nullable
              as Transcript?,
      profanityMatches: null == profanityMatches
          ? _value.profanityMatches
          : profanityMatches // ignore: cast_nullable_to_non_nullable
              as List<ProfanityMatch>,
      frameResults: null == frameResults
          ? _value.frameResults
          : frameResults // ignore: cast_nullable_to_non_nullable
              as List<FrameAnalysisResult>,
      timeline: freezed == timeline
          ? _value.timeline
          : timeline // ignore: cast_nullable_to_non_nullable
              as UnifiedTimeline?,
      processingTime: freezed == processingTime
          ? _value.processingTime
          : processingTime // ignore: cast_nullable_to_non_nullable
              as Duration?,
      startedAt: freezed == startedAt
          ? _value.startedAt
          : startedAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      completedAt: freezed == completedAt
          ? _value.completedAt
          : completedAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      errorMessage: freezed == errorMessage
          ? _value.errorMessage
          : errorMessage // ignore: cast_nullable_to_non_nullable
              as String?,
      progress: freezed == progress
          ? _value.progress
          : progress // ignore: cast_nullable_to_non_nullable
              as AnalysisProgress?,
      mediaFileId: freezed == mediaFileId
          ? _value.mediaFileId
          : mediaFileId // ignore: cast_nullable_to_non_nullable
              as String?,
      settings: freezed == settings
          ? _value.settings
          : settings // ignore: cast_nullable_to_non_nullable
              as Map<String, dynamic>?,
    ) as $Val);
  }

  /// Create a copy of AnalysisResult
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $TranscriptCopyWith<$Res>? get transcript {
    if (_value.transcript == null) {
      return null;
    }

    return $TranscriptCopyWith<$Res>(_value.transcript!, (value) {
      return _then(_value.copyWith(transcript: value) as $Val);
    });
  }

  /// Create a copy of AnalysisResult
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $UnifiedTimelineCopyWith<$Res>? get timeline {
    if (_value.timeline == null) {
      return null;
    }

    return $UnifiedTimelineCopyWith<$Res>(_value.timeline!, (value) {
      return _then(_value.copyWith(timeline: value) as $Val);
    });
  }

  /// Create a copy of AnalysisResult
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $AnalysisProgressCopyWith<$Res>? get progress {
    if (_value.progress == null) {
      return null;
    }

    return $AnalysisProgressCopyWith<$Res>(_value.progress!, (value) {
      return _then(_value.copyWith(progress: value) as $Val);
    });
  }
}

/// @nodoc
abstract class _$$AnalysisResultImplCopyWith<$Res>
    implements $AnalysisResultCopyWith<$Res> {
  factory _$$AnalysisResultImplCopyWith(_$AnalysisResultImpl value,
          $Res Function(_$AnalysisResultImpl) then) =
      __$$AnalysisResultImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String id,
      AnalysisStatus status,
      Transcript? transcript,
      List<ProfanityMatch> profanityMatches,
      List<FrameAnalysisResult> frameResults,
      UnifiedTimeline? timeline,
      @DurationConverter() Duration? processingTime,
      DateTime? startedAt,
      DateTime? completedAt,
      String? errorMessage,
      AnalysisProgress? progress,
      String? mediaFileId,
      Map<String, dynamic>? settings});

  @override
  $TranscriptCopyWith<$Res>? get transcript;
  @override
  $UnifiedTimelineCopyWith<$Res>? get timeline;
  @override
  $AnalysisProgressCopyWith<$Res>? get progress;
}

/// @nodoc
class __$$AnalysisResultImplCopyWithImpl<$Res>
    extends _$AnalysisResultCopyWithImpl<$Res, _$AnalysisResultImpl>
    implements _$$AnalysisResultImplCopyWith<$Res> {
  __$$AnalysisResultImplCopyWithImpl(
      _$AnalysisResultImpl _value, $Res Function(_$AnalysisResultImpl) _then)
      : super(_value, _then);

  /// Create a copy of AnalysisResult
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? status = null,
    Object? transcript = freezed,
    Object? profanityMatches = null,
    Object? frameResults = null,
    Object? timeline = freezed,
    Object? processingTime = freezed,
    Object? startedAt = freezed,
    Object? completedAt = freezed,
    Object? errorMessage = freezed,
    Object? progress = freezed,
    Object? mediaFileId = freezed,
    Object? settings = freezed,
  }) {
    return _then(_$AnalysisResultImpl(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      status: null == status
          ? _value.status
          : status // ignore: cast_nullable_to_non_nullable
              as AnalysisStatus,
      transcript: freezed == transcript
          ? _value.transcript
          : transcript // ignore: cast_nullable_to_non_nullable
              as Transcript?,
      profanityMatches: null == profanityMatches
          ? _value._profanityMatches
          : profanityMatches // ignore: cast_nullable_to_non_nullable
              as List<ProfanityMatch>,
      frameResults: null == frameResults
          ? _value._frameResults
          : frameResults // ignore: cast_nullable_to_non_nullable
              as List<FrameAnalysisResult>,
      timeline: freezed == timeline
          ? _value.timeline
          : timeline // ignore: cast_nullable_to_non_nullable
              as UnifiedTimeline?,
      processingTime: freezed == processingTime
          ? _value.processingTime
          : processingTime // ignore: cast_nullable_to_non_nullable
              as Duration?,
      startedAt: freezed == startedAt
          ? _value.startedAt
          : startedAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      completedAt: freezed == completedAt
          ? _value.completedAt
          : completedAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      errorMessage: freezed == errorMessage
          ? _value.errorMessage
          : errorMessage // ignore: cast_nullable_to_non_nullable
              as String?,
      progress: freezed == progress
          ? _value.progress
          : progress // ignore: cast_nullable_to_non_nullable
              as AnalysisProgress?,
      mediaFileId: freezed == mediaFileId
          ? _value.mediaFileId
          : mediaFileId // ignore: cast_nullable_to_non_nullable
              as String?,
      settings: freezed == settings
          ? _value._settings
          : settings // ignore: cast_nullable_to_non_nullable
              as Map<String, dynamic>?,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$AnalysisResultImpl extends _AnalysisResult {
  const _$AnalysisResultImpl(
      {required this.id,
      this.status = AnalysisStatus.pending,
      this.transcript,
      final List<ProfanityMatch> profanityMatches = const [],
      final List<FrameAnalysisResult> frameResults = const [],
      this.timeline,
      @DurationConverter() this.processingTime,
      this.startedAt,
      this.completedAt,
      this.errorMessage,
      this.progress,
      this.mediaFileId,
      final Map<String, dynamic>? settings})
      : _profanityMatches = profanityMatches,
        _frameResults = frameResults,
        _settings = settings,
        super._();

  factory _$AnalysisResultImpl.fromJson(Map<String, dynamic> json) =>
      _$$AnalysisResultImplFromJson(json);

  /// Unique identifier for this analysis
  @override
  final String id;

  /// Current status of the analysis
  @override
  @JsonKey()
  final AnalysisStatus status;

  /// Generated transcript (null if not completed or audio analysis disabled)
  @override
  final Transcript? transcript;

  /// List of profanity matches found in transcript
  final List<ProfanityMatch> _profanityMatches;

  /// List of profanity matches found in transcript
  @override
  @JsonKey()
  List<ProfanityMatch> get profanityMatches {
    if (_profanityMatches is EqualUnmodifiableListView)
      return _profanityMatches;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_profanityMatches);
  }

  /// List of frame analysis results
  final List<FrameAnalysisResult> _frameResults;

  /// List of frame analysis results
  @override
  @JsonKey()
  List<FrameAnalysisResult> get frameResults {
    if (_frameResults is EqualUnmodifiableListView) return _frameResults;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_frameResults);
  }

  /// Unified timeline combining all detections
  @override
  final UnifiedTimeline? timeline;

  /// Total processing time
  @override
  @DurationConverter()
  final Duration? processingTime;

  /// Timestamp when analysis started
  @override
  final DateTime? startedAt;

  /// Timestamp when analysis completed
  @override
  final DateTime? completedAt;

  /// Error message if analysis failed
  @override
  final String? errorMessage;

  /// Current progress (for running analysis)
  @override
  final AnalysisProgress? progress;

  /// ID of the media file analyzed
  @override
  final String? mediaFileId;

  /// Settings used for this analysis
  final Map<String, dynamic>? _settings;

  /// Settings used for this analysis
  @override
  Map<String, dynamic>? get settings {
    final value = _settings;
    if (value == null) return null;
    if (_settings is EqualUnmodifiableMapView) return _settings;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableMapView(value);
  }

  @override
  String toString() {
    return 'AnalysisResult(id: $id, status: $status, transcript: $transcript, profanityMatches: $profanityMatches, frameResults: $frameResults, timeline: $timeline, processingTime: $processingTime, startedAt: $startedAt, completedAt: $completedAt, errorMessage: $errorMessage, progress: $progress, mediaFileId: $mediaFileId, settings: $settings)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$AnalysisResultImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.status, status) || other.status == status) &&
            (identical(other.transcript, transcript) ||
                other.transcript == transcript) &&
            const DeepCollectionEquality()
                .equals(other._profanityMatches, _profanityMatches) &&
            const DeepCollectionEquality()
                .equals(other._frameResults, _frameResults) &&
            (identical(other.timeline, timeline) ||
                other.timeline == timeline) &&
            (identical(other.processingTime, processingTime) ||
                other.processingTime == processingTime) &&
            (identical(other.startedAt, startedAt) ||
                other.startedAt == startedAt) &&
            (identical(other.completedAt, completedAt) ||
                other.completedAt == completedAt) &&
            (identical(other.errorMessage, errorMessage) ||
                other.errorMessage == errorMessage) &&
            (identical(other.progress, progress) ||
                other.progress == progress) &&
            (identical(other.mediaFileId, mediaFileId) ||
                other.mediaFileId == mediaFileId) &&
            const DeepCollectionEquality().equals(other._settings, _settings));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
      runtimeType,
      id,
      status,
      transcript,
      const DeepCollectionEquality().hash(_profanityMatches),
      const DeepCollectionEquality().hash(_frameResults),
      timeline,
      processingTime,
      startedAt,
      completedAt,
      errorMessage,
      progress,
      mediaFileId,
      const DeepCollectionEquality().hash(_settings));

  /// Create a copy of AnalysisResult
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$AnalysisResultImplCopyWith<_$AnalysisResultImpl> get copyWith =>
      __$$AnalysisResultImplCopyWithImpl<_$AnalysisResultImpl>(
          this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$AnalysisResultImplToJson(
      this,
    );
  }
}

abstract class _AnalysisResult extends AnalysisResult {
  const factory _AnalysisResult(
      {required final String id,
      final AnalysisStatus status,
      final Transcript? transcript,
      final List<ProfanityMatch> profanityMatches,
      final List<FrameAnalysisResult> frameResults,
      final UnifiedTimeline? timeline,
      @DurationConverter() final Duration? processingTime,
      final DateTime? startedAt,
      final DateTime? completedAt,
      final String? errorMessage,
      final AnalysisProgress? progress,
      final String? mediaFileId,
      final Map<String, dynamic>? settings}) = _$AnalysisResultImpl;
  const _AnalysisResult._() : super._();

  factory _AnalysisResult.fromJson(Map<String, dynamic> json) =
      _$AnalysisResultImpl.fromJson;

  /// Unique identifier for this analysis
  @override
  String get id;

  /// Current status of the analysis
  @override
  AnalysisStatus get status;

  /// Generated transcript (null if not completed or audio analysis disabled)
  @override
  Transcript? get transcript;

  /// List of profanity matches found in transcript
  @override
  List<ProfanityMatch> get profanityMatches;

  /// List of frame analysis results
  @override
  List<FrameAnalysisResult> get frameResults;

  /// Unified timeline combining all detections
  @override
  UnifiedTimeline? get timeline;

  /// Total processing time
  @override
  @DurationConverter()
  Duration? get processingTime;

  /// Timestamp when analysis started
  @override
  DateTime? get startedAt;

  /// Timestamp when analysis completed
  @override
  DateTime? get completedAt;

  /// Error message if analysis failed
  @override
  String? get errorMessage;

  /// Current progress (for running analysis)
  @override
  AnalysisProgress? get progress;

  /// ID of the media file analyzed
  @override
  String? get mediaFileId;

  /// Settings used for this analysis
  @override
  Map<String, dynamic>? get settings;

  /// Create a copy of AnalysisResult
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$AnalysisResultImplCopyWith<_$AnalysisResultImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
