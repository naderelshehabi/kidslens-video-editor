// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'transcription_progress.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

TranscriptionProgress _$TranscriptionProgressFromJson(
    Map<String, dynamic> json) {
  return _TranscriptionProgress.fromJson(json);
}

/// @nodoc
mixin _$TranscriptionProgress {
  /// Progress value from 0.0 to 1.0
  double get progress => throw _privateConstructorUsedError;

  /// Current segment being processed (if available)
  TranscriptSegment? get currentSegment => throw _privateConstructorUsedError;

  /// Estimated time remaining for transcription
  @NullableDurationConverter()
  Duration? get estimatedTimeRemaining => throw _privateConstructorUsedError;

  /// Whether the transcription is complete
  bool get isComplete => throw _privateConstructorUsedError;

  /// Number of segments processed so far
  int get segmentsProcessed => throw _privateConstructorUsedError;

  /// Total segments (estimated, may change during processing)
  int? get totalSegments => throw _privateConstructorUsedError;

  /// Current processing phase
  TranscriptionPhase get phase => throw _privateConstructorUsedError;

  /// Error message if transcription failed
  String? get errorMessage => throw _privateConstructorUsedError;

  /// Serializes this TranscriptionProgress to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of TranscriptionProgress
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $TranscriptionProgressCopyWith<TranscriptionProgress> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $TranscriptionProgressCopyWith<$Res> {
  factory $TranscriptionProgressCopyWith(TranscriptionProgress value,
          $Res Function(TranscriptionProgress) then) =
      _$TranscriptionProgressCopyWithImpl<$Res, TranscriptionProgress>;
  @useResult
  $Res call(
      {double progress,
      TranscriptSegment? currentSegment,
      @NullableDurationConverter() Duration? estimatedTimeRemaining,
      bool isComplete,
      int segmentsProcessed,
      int? totalSegments,
      TranscriptionPhase phase,
      String? errorMessage});

  $TranscriptSegmentCopyWith<$Res>? get currentSegment;
}

/// @nodoc
class _$TranscriptionProgressCopyWithImpl<$Res,
        $Val extends TranscriptionProgress>
    implements $TranscriptionProgressCopyWith<$Res> {
  _$TranscriptionProgressCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of TranscriptionProgress
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? progress = null,
    Object? currentSegment = freezed,
    Object? estimatedTimeRemaining = freezed,
    Object? isComplete = null,
    Object? segmentsProcessed = null,
    Object? totalSegments = freezed,
    Object? phase = null,
    Object? errorMessage = freezed,
  }) {
    return _then(_value.copyWith(
      progress: null == progress
          ? _value.progress
          : progress // ignore: cast_nullable_to_non_nullable
              as double,
      currentSegment: freezed == currentSegment
          ? _value.currentSegment
          : currentSegment // ignore: cast_nullable_to_non_nullable
              as TranscriptSegment?,
      estimatedTimeRemaining: freezed == estimatedTimeRemaining
          ? _value.estimatedTimeRemaining
          : estimatedTimeRemaining // ignore: cast_nullable_to_non_nullable
              as Duration?,
      isComplete: null == isComplete
          ? _value.isComplete
          : isComplete // ignore: cast_nullable_to_non_nullable
              as bool,
      segmentsProcessed: null == segmentsProcessed
          ? _value.segmentsProcessed
          : segmentsProcessed // ignore: cast_nullable_to_non_nullable
              as int,
      totalSegments: freezed == totalSegments
          ? _value.totalSegments
          : totalSegments // ignore: cast_nullable_to_non_nullable
              as int?,
      phase: null == phase
          ? _value.phase
          : phase // ignore: cast_nullable_to_non_nullable
              as TranscriptionPhase,
      errorMessage: freezed == errorMessage
          ? _value.errorMessage
          : errorMessage // ignore: cast_nullable_to_non_nullable
              as String?,
    ) as $Val);
  }

  /// Create a copy of TranscriptionProgress
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $TranscriptSegmentCopyWith<$Res>? get currentSegment {
    if (_value.currentSegment == null) {
      return null;
    }

    return $TranscriptSegmentCopyWith<$Res>(_value.currentSegment!, (value) {
      return _then(_value.copyWith(currentSegment: value) as $Val);
    });
  }
}

/// @nodoc
abstract class _$$TranscriptionProgressImplCopyWith<$Res>
    implements $TranscriptionProgressCopyWith<$Res> {
  factory _$$TranscriptionProgressImplCopyWith(
          _$TranscriptionProgressImpl value,
          $Res Function(_$TranscriptionProgressImpl) then) =
      __$$TranscriptionProgressImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {double progress,
      TranscriptSegment? currentSegment,
      @NullableDurationConverter() Duration? estimatedTimeRemaining,
      bool isComplete,
      int segmentsProcessed,
      int? totalSegments,
      TranscriptionPhase phase,
      String? errorMessage});

  @override
  $TranscriptSegmentCopyWith<$Res>? get currentSegment;
}

/// @nodoc
class __$$TranscriptionProgressImplCopyWithImpl<$Res>
    extends _$TranscriptionProgressCopyWithImpl<$Res,
        _$TranscriptionProgressImpl>
    implements _$$TranscriptionProgressImplCopyWith<$Res> {
  __$$TranscriptionProgressImplCopyWithImpl(_$TranscriptionProgressImpl _value,
      $Res Function(_$TranscriptionProgressImpl) _then)
      : super(_value, _then);

  /// Create a copy of TranscriptionProgress
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? progress = null,
    Object? currentSegment = freezed,
    Object? estimatedTimeRemaining = freezed,
    Object? isComplete = null,
    Object? segmentsProcessed = null,
    Object? totalSegments = freezed,
    Object? phase = null,
    Object? errorMessage = freezed,
  }) {
    return _then(_$TranscriptionProgressImpl(
      progress: null == progress
          ? _value.progress
          : progress // ignore: cast_nullable_to_non_nullable
              as double,
      currentSegment: freezed == currentSegment
          ? _value.currentSegment
          : currentSegment // ignore: cast_nullable_to_non_nullable
              as TranscriptSegment?,
      estimatedTimeRemaining: freezed == estimatedTimeRemaining
          ? _value.estimatedTimeRemaining
          : estimatedTimeRemaining // ignore: cast_nullable_to_non_nullable
              as Duration?,
      isComplete: null == isComplete
          ? _value.isComplete
          : isComplete // ignore: cast_nullable_to_non_nullable
              as bool,
      segmentsProcessed: null == segmentsProcessed
          ? _value.segmentsProcessed
          : segmentsProcessed // ignore: cast_nullable_to_non_nullable
              as int,
      totalSegments: freezed == totalSegments
          ? _value.totalSegments
          : totalSegments // ignore: cast_nullable_to_non_nullable
              as int?,
      phase: null == phase
          ? _value.phase
          : phase // ignore: cast_nullable_to_non_nullable
              as TranscriptionPhase,
      errorMessage: freezed == errorMessage
          ? _value.errorMessage
          : errorMessage // ignore: cast_nullable_to_non_nullable
              as String?,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$TranscriptionProgressImpl extends _TranscriptionProgress {
  const _$TranscriptionProgressImpl(
      {required this.progress,
      this.currentSegment,
      @NullableDurationConverter() this.estimatedTimeRemaining,
      this.isComplete = false,
      this.segmentsProcessed = 0,
      this.totalSegments,
      this.phase = TranscriptionPhase.initializing,
      this.errorMessage})
      : super._();

  factory _$TranscriptionProgressImpl.fromJson(Map<String, dynamic> json) =>
      _$$TranscriptionProgressImplFromJson(json);

  /// Progress value from 0.0 to 1.0
  @override
  final double progress;

  /// Current segment being processed (if available)
  @override
  final TranscriptSegment? currentSegment;

  /// Estimated time remaining for transcription
  @override
  @NullableDurationConverter()
  final Duration? estimatedTimeRemaining;

  /// Whether the transcription is complete
  @override
  @JsonKey()
  final bool isComplete;

  /// Number of segments processed so far
  @override
  @JsonKey()
  final int segmentsProcessed;

  /// Total segments (estimated, may change during processing)
  @override
  final int? totalSegments;

  /// Current processing phase
  @override
  @JsonKey()
  final TranscriptionPhase phase;

  /// Error message if transcription failed
  @override
  final String? errorMessage;

  @override
  String toString() {
    return 'TranscriptionProgress(progress: $progress, currentSegment: $currentSegment, estimatedTimeRemaining: $estimatedTimeRemaining, isComplete: $isComplete, segmentsProcessed: $segmentsProcessed, totalSegments: $totalSegments, phase: $phase, errorMessage: $errorMessage)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$TranscriptionProgressImpl &&
            (identical(other.progress, progress) ||
                other.progress == progress) &&
            (identical(other.currentSegment, currentSegment) ||
                other.currentSegment == currentSegment) &&
            (identical(other.estimatedTimeRemaining, estimatedTimeRemaining) ||
                other.estimatedTimeRemaining == estimatedTimeRemaining) &&
            (identical(other.isComplete, isComplete) ||
                other.isComplete == isComplete) &&
            (identical(other.segmentsProcessed, segmentsProcessed) ||
                other.segmentsProcessed == segmentsProcessed) &&
            (identical(other.totalSegments, totalSegments) ||
                other.totalSegments == totalSegments) &&
            (identical(other.phase, phase) || other.phase == phase) &&
            (identical(other.errorMessage, errorMessage) ||
                other.errorMessage == errorMessage));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
      runtimeType,
      progress,
      currentSegment,
      estimatedTimeRemaining,
      isComplete,
      segmentsProcessed,
      totalSegments,
      phase,
      errorMessage);

  /// Create a copy of TranscriptionProgress
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$TranscriptionProgressImplCopyWith<_$TranscriptionProgressImpl>
      get copyWith => __$$TranscriptionProgressImplCopyWithImpl<
          _$TranscriptionProgressImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$TranscriptionProgressImplToJson(
      this,
    );
  }
}

abstract class _TranscriptionProgress extends TranscriptionProgress {
  const factory _TranscriptionProgress(
      {required final double progress,
      final TranscriptSegment? currentSegment,
      @NullableDurationConverter() final Duration? estimatedTimeRemaining,
      final bool isComplete,
      final int segmentsProcessed,
      final int? totalSegments,
      final TranscriptionPhase phase,
      final String? errorMessage}) = _$TranscriptionProgressImpl;
  const _TranscriptionProgress._() : super._();

  factory _TranscriptionProgress.fromJson(Map<String, dynamic> json) =
      _$TranscriptionProgressImpl.fromJson;

  /// Progress value from 0.0 to 1.0
  @override
  double get progress;

  /// Current segment being processed (if available)
  @override
  TranscriptSegment? get currentSegment;

  /// Estimated time remaining for transcription
  @override
  @NullableDurationConverter()
  Duration? get estimatedTimeRemaining;

  /// Whether the transcription is complete
  @override
  bool get isComplete;

  /// Number of segments processed so far
  @override
  int get segmentsProcessed;

  /// Total segments (estimated, may change during processing)
  @override
  int? get totalSegments;

  /// Current processing phase
  @override
  TranscriptionPhase get phase;

  /// Error message if transcription failed
  @override
  String? get errorMessage;

  /// Create a copy of TranscriptionProgress
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$TranscriptionProgressImplCopyWith<_$TranscriptionProgressImpl>
      get copyWith => throw _privateConstructorUsedError;
}
