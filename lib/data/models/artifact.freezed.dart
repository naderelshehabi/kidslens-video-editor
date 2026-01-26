// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'artifact.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

ArtifactMediaInfo _$ArtifactMediaInfoFromJson(Map<String, dynamic> json) {
  return _ArtifactMediaInfo.fromJson(json);
}

/// @nodoc
mixin _$ArtifactMediaInfo {
  /// Duration of the media in microseconds
  int get durationMicroseconds => throw _privateConstructorUsedError;

  /// File size in bytes
  int get fileSize => throw _privateConstructorUsedError;

  /// Width of video (0 for audio)
  int get width => throw _privateConstructorUsedError;

  /// Height of video (0 for audio)
  int get height => throw _privateConstructorUsedError;

  /// Codec used
  String? get codec => throw _privateConstructorUsedError;

  /// Container format
  String? get container => throw _privateConstructorUsedError;

  /// Serializes this ArtifactMediaInfo to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of ArtifactMediaInfo
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $ArtifactMediaInfoCopyWith<ArtifactMediaInfo> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $ArtifactMediaInfoCopyWith<$Res> {
  factory $ArtifactMediaInfoCopyWith(
          ArtifactMediaInfo value, $Res Function(ArtifactMediaInfo) then) =
      _$ArtifactMediaInfoCopyWithImpl<$Res, ArtifactMediaInfo>;
  @useResult
  $Res call(
      {int durationMicroseconds,
      int fileSize,
      int width,
      int height,
      String? codec,
      String? container});
}

/// @nodoc
class _$ArtifactMediaInfoCopyWithImpl<$Res, $Val extends ArtifactMediaInfo>
    implements $ArtifactMediaInfoCopyWith<$Res> {
  _$ArtifactMediaInfoCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of ArtifactMediaInfo
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? durationMicroseconds = null,
    Object? fileSize = null,
    Object? width = null,
    Object? height = null,
    Object? codec = freezed,
    Object? container = freezed,
  }) {
    return _then(_value.copyWith(
      durationMicroseconds: null == durationMicroseconds
          ? _value.durationMicroseconds
          : durationMicroseconds // ignore: cast_nullable_to_non_nullable
              as int,
      fileSize: null == fileSize
          ? _value.fileSize
          : fileSize // ignore: cast_nullable_to_non_nullable
              as int,
      width: null == width
          ? _value.width
          : width // ignore: cast_nullable_to_non_nullable
              as int,
      height: null == height
          ? _value.height
          : height // ignore: cast_nullable_to_non_nullable
              as int,
      codec: freezed == codec
          ? _value.codec
          : codec // ignore: cast_nullable_to_non_nullable
              as String?,
      container: freezed == container
          ? _value.container
          : container // ignore: cast_nullable_to_non_nullable
              as String?,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$ArtifactMediaInfoImplCopyWith<$Res>
    implements $ArtifactMediaInfoCopyWith<$Res> {
  factory _$$ArtifactMediaInfoImplCopyWith(_$ArtifactMediaInfoImpl value,
          $Res Function(_$ArtifactMediaInfoImpl) then) =
      __$$ArtifactMediaInfoImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {int durationMicroseconds,
      int fileSize,
      int width,
      int height,
      String? codec,
      String? container});
}

/// @nodoc
class __$$ArtifactMediaInfoImplCopyWithImpl<$Res>
    extends _$ArtifactMediaInfoCopyWithImpl<$Res, _$ArtifactMediaInfoImpl>
    implements _$$ArtifactMediaInfoImplCopyWith<$Res> {
  __$$ArtifactMediaInfoImplCopyWithImpl(_$ArtifactMediaInfoImpl _value,
      $Res Function(_$ArtifactMediaInfoImpl) _then)
      : super(_value, _then);

  /// Create a copy of ArtifactMediaInfo
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? durationMicroseconds = null,
    Object? fileSize = null,
    Object? width = null,
    Object? height = null,
    Object? codec = freezed,
    Object? container = freezed,
  }) {
    return _then(_$ArtifactMediaInfoImpl(
      durationMicroseconds: null == durationMicroseconds
          ? _value.durationMicroseconds
          : durationMicroseconds // ignore: cast_nullable_to_non_nullable
              as int,
      fileSize: null == fileSize
          ? _value.fileSize
          : fileSize // ignore: cast_nullable_to_non_nullable
              as int,
      width: null == width
          ? _value.width
          : width // ignore: cast_nullable_to_non_nullable
              as int,
      height: null == height
          ? _value.height
          : height // ignore: cast_nullable_to_non_nullable
              as int,
      codec: freezed == codec
          ? _value.codec
          : codec // ignore: cast_nullable_to_non_nullable
              as String?,
      container: freezed == container
          ? _value.container
          : container // ignore: cast_nullable_to_non_nullable
              as String?,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$ArtifactMediaInfoImpl implements _ArtifactMediaInfo {
  const _$ArtifactMediaInfoImpl(
      {required this.durationMicroseconds,
      required this.fileSize,
      required this.width,
      required this.height,
      this.codec,
      this.container});

  factory _$ArtifactMediaInfoImpl.fromJson(Map<String, dynamic> json) =>
      _$$ArtifactMediaInfoImplFromJson(json);

  /// Duration of the media in microseconds
  @override
  final int durationMicroseconds;

  /// File size in bytes
  @override
  final int fileSize;

  /// Width of video (0 for audio)
  @override
  final int width;

  /// Height of video (0 for audio)
  @override
  final int height;

  /// Codec used
  @override
  final String? codec;

  /// Container format
  @override
  final String? container;

  @override
  String toString() {
    return 'ArtifactMediaInfo(durationMicroseconds: $durationMicroseconds, fileSize: $fileSize, width: $width, height: $height, codec: $codec, container: $container)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$ArtifactMediaInfoImpl &&
            (identical(other.durationMicroseconds, durationMicroseconds) ||
                other.durationMicroseconds == durationMicroseconds) &&
            (identical(other.fileSize, fileSize) ||
                other.fileSize == fileSize) &&
            (identical(other.width, width) || other.width == width) &&
            (identical(other.height, height) || other.height == height) &&
            (identical(other.codec, codec) || other.codec == codec) &&
            (identical(other.container, container) ||
                other.container == container));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, durationMicroseconds, fileSize,
      width, height, codec, container);

  /// Create a copy of ArtifactMediaInfo
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$ArtifactMediaInfoImplCopyWith<_$ArtifactMediaInfoImpl> get copyWith =>
      __$$ArtifactMediaInfoImplCopyWithImpl<_$ArtifactMediaInfoImpl>(
          this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$ArtifactMediaInfoImplToJson(
      this,
    );
  }
}

abstract class _ArtifactMediaInfo implements ArtifactMediaInfo {
  const factory _ArtifactMediaInfo(
      {required final int durationMicroseconds,
      required final int fileSize,
      required final int width,
      required final int height,
      final String? codec,
      final String? container}) = _$ArtifactMediaInfoImpl;

  factory _ArtifactMediaInfo.fromJson(Map<String, dynamic> json) =
      _$ArtifactMediaInfoImpl.fromJson;

  /// Duration of the media in microseconds
  @override
  int get durationMicroseconds;

  /// File size in bytes
  @override
  int get fileSize;

  /// Width of video (0 for audio)
  @override
  int get width;

  /// Height of video (0 for audio)
  @override
  int get height;

  /// Codec used
  @override
  String? get codec;

  /// Container format
  @override
  String? get container;

  /// Create a copy of ArtifactMediaInfo
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$ArtifactMediaInfoImplCopyWith<_$ArtifactMediaInfoImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

AnalysisArtifact _$AnalysisArtifactFromJson(Map<String, dynamic> json) {
  return _AnalysisArtifact.fromJson(json);
}

/// @nodoc
mixin _$AnalysisArtifact {
  /// Version of the artifact format
  int get version => throw _privateConstructorUsedError;

  /// SHA-256 hash of the source media file
  String get mediaHash => throw _privateConstructorUsedError;

  /// Media file information
  ArtifactMediaInfo get mediaInfo => throw _privateConstructorUsedError;

  /// Settings used for this analysis
  AnalysisSettings get settingsUsed => throw _privateConstructorUsedError;

  /// Transcript if ASR was performed
  Transcript? get transcript => throw _privateConstructorUsedError;

  /// Profanity matches found
  List<ProfanityMatch> get profanityMatches =>
      throw _privateConstructorUsedError;

  /// Frame analysis results
  List<FrameAnalysisResult> get frameResults =>
      throw _privateConstructorUsedError;

  /// Unified timeline with all detections and modifications
  UnifiedTimeline get timeline => throw _privateConstructorUsedError;

  /// When the analysis was started
  DateTime get createdAt => throw _privateConstructorUsedError;

  /// When the analysis was completed
  DateTime? get completedAt => throw _privateConstructorUsedError;

  /// Current status of the analysis
  AnalysisStatus get status => throw _privateConstructorUsedError;

  /// Error message if failed
  String? get errorMessage => throw _privateConstructorUsedError;

  /// Serializes this AnalysisArtifact to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of AnalysisArtifact
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $AnalysisArtifactCopyWith<AnalysisArtifact> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $AnalysisArtifactCopyWith<$Res> {
  factory $AnalysisArtifactCopyWith(
          AnalysisArtifact value, $Res Function(AnalysisArtifact) then) =
      _$AnalysisArtifactCopyWithImpl<$Res, AnalysisArtifact>;
  @useResult
  $Res call(
      {int version,
      String mediaHash,
      ArtifactMediaInfo mediaInfo,
      AnalysisSettings settingsUsed,
      Transcript? transcript,
      List<ProfanityMatch> profanityMatches,
      List<FrameAnalysisResult> frameResults,
      UnifiedTimeline timeline,
      DateTime createdAt,
      DateTime? completedAt,
      AnalysisStatus status,
      String? errorMessage});

  $ArtifactMediaInfoCopyWith<$Res> get mediaInfo;
  $AnalysisSettingsCopyWith<$Res> get settingsUsed;
  $TranscriptCopyWith<$Res>? get transcript;
  $UnifiedTimelineCopyWith<$Res> get timeline;
}

/// @nodoc
class _$AnalysisArtifactCopyWithImpl<$Res, $Val extends AnalysisArtifact>
    implements $AnalysisArtifactCopyWith<$Res> {
  _$AnalysisArtifactCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of AnalysisArtifact
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? version = null,
    Object? mediaHash = null,
    Object? mediaInfo = null,
    Object? settingsUsed = null,
    Object? transcript = freezed,
    Object? profanityMatches = null,
    Object? frameResults = null,
    Object? timeline = null,
    Object? createdAt = null,
    Object? completedAt = freezed,
    Object? status = null,
    Object? errorMessage = freezed,
  }) {
    return _then(_value.copyWith(
      version: null == version
          ? _value.version
          : version // ignore: cast_nullable_to_non_nullable
              as int,
      mediaHash: null == mediaHash
          ? _value.mediaHash
          : mediaHash // ignore: cast_nullable_to_non_nullable
              as String,
      mediaInfo: null == mediaInfo
          ? _value.mediaInfo
          : mediaInfo // ignore: cast_nullable_to_non_nullable
              as ArtifactMediaInfo,
      settingsUsed: null == settingsUsed
          ? _value.settingsUsed
          : settingsUsed // ignore: cast_nullable_to_non_nullable
              as AnalysisSettings,
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
      timeline: null == timeline
          ? _value.timeline
          : timeline // ignore: cast_nullable_to_non_nullable
              as UnifiedTimeline,
      createdAt: null == createdAt
          ? _value.createdAt
          : createdAt // ignore: cast_nullable_to_non_nullable
              as DateTime,
      completedAt: freezed == completedAt
          ? _value.completedAt
          : completedAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      status: null == status
          ? _value.status
          : status // ignore: cast_nullable_to_non_nullable
              as AnalysisStatus,
      errorMessage: freezed == errorMessage
          ? _value.errorMessage
          : errorMessage // ignore: cast_nullable_to_non_nullable
              as String?,
    ) as $Val);
  }

  /// Create a copy of AnalysisArtifact
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $ArtifactMediaInfoCopyWith<$Res> get mediaInfo {
    return $ArtifactMediaInfoCopyWith<$Res>(_value.mediaInfo, (value) {
      return _then(_value.copyWith(mediaInfo: value) as $Val);
    });
  }

  /// Create a copy of AnalysisArtifact
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $AnalysisSettingsCopyWith<$Res> get settingsUsed {
    return $AnalysisSettingsCopyWith<$Res>(_value.settingsUsed, (value) {
      return _then(_value.copyWith(settingsUsed: value) as $Val);
    });
  }

  /// Create a copy of AnalysisArtifact
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

  /// Create a copy of AnalysisArtifact
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $UnifiedTimelineCopyWith<$Res> get timeline {
    return $UnifiedTimelineCopyWith<$Res>(_value.timeline, (value) {
      return _then(_value.copyWith(timeline: value) as $Val);
    });
  }
}

/// @nodoc
abstract class _$$AnalysisArtifactImplCopyWith<$Res>
    implements $AnalysisArtifactCopyWith<$Res> {
  factory _$$AnalysisArtifactImplCopyWith(_$AnalysisArtifactImpl value,
          $Res Function(_$AnalysisArtifactImpl) then) =
      __$$AnalysisArtifactImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {int version,
      String mediaHash,
      ArtifactMediaInfo mediaInfo,
      AnalysisSettings settingsUsed,
      Transcript? transcript,
      List<ProfanityMatch> profanityMatches,
      List<FrameAnalysisResult> frameResults,
      UnifiedTimeline timeline,
      DateTime createdAt,
      DateTime? completedAt,
      AnalysisStatus status,
      String? errorMessage});

  @override
  $ArtifactMediaInfoCopyWith<$Res> get mediaInfo;
  @override
  $AnalysisSettingsCopyWith<$Res> get settingsUsed;
  @override
  $TranscriptCopyWith<$Res>? get transcript;
  @override
  $UnifiedTimelineCopyWith<$Res> get timeline;
}

/// @nodoc
class __$$AnalysisArtifactImplCopyWithImpl<$Res>
    extends _$AnalysisArtifactCopyWithImpl<$Res, _$AnalysisArtifactImpl>
    implements _$$AnalysisArtifactImplCopyWith<$Res> {
  __$$AnalysisArtifactImplCopyWithImpl(_$AnalysisArtifactImpl _value,
      $Res Function(_$AnalysisArtifactImpl) _then)
      : super(_value, _then);

  /// Create a copy of AnalysisArtifact
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? version = null,
    Object? mediaHash = null,
    Object? mediaInfo = null,
    Object? settingsUsed = null,
    Object? transcript = freezed,
    Object? profanityMatches = null,
    Object? frameResults = null,
    Object? timeline = null,
    Object? createdAt = null,
    Object? completedAt = freezed,
    Object? status = null,
    Object? errorMessage = freezed,
  }) {
    return _then(_$AnalysisArtifactImpl(
      version: null == version
          ? _value.version
          : version // ignore: cast_nullable_to_non_nullable
              as int,
      mediaHash: null == mediaHash
          ? _value.mediaHash
          : mediaHash // ignore: cast_nullable_to_non_nullable
              as String,
      mediaInfo: null == mediaInfo
          ? _value.mediaInfo
          : mediaInfo // ignore: cast_nullable_to_non_nullable
              as ArtifactMediaInfo,
      settingsUsed: null == settingsUsed
          ? _value.settingsUsed
          : settingsUsed // ignore: cast_nullable_to_non_nullable
              as AnalysisSettings,
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
      timeline: null == timeline
          ? _value.timeline
          : timeline // ignore: cast_nullable_to_non_nullable
              as UnifiedTimeline,
      createdAt: null == createdAt
          ? _value.createdAt
          : createdAt // ignore: cast_nullable_to_non_nullable
              as DateTime,
      completedAt: freezed == completedAt
          ? _value.completedAt
          : completedAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      status: null == status
          ? _value.status
          : status // ignore: cast_nullable_to_non_nullable
              as AnalysisStatus,
      errorMessage: freezed == errorMessage
          ? _value.errorMessage
          : errorMessage // ignore: cast_nullable_to_non_nullable
              as String?,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$AnalysisArtifactImpl extends _AnalysisArtifact {
  const _$AnalysisArtifactImpl(
      {this.version = 1,
      required this.mediaHash,
      required this.mediaInfo,
      required this.settingsUsed,
      this.transcript,
      final List<ProfanityMatch> profanityMatches = const [],
      final List<FrameAnalysisResult> frameResults = const [],
      required this.timeline,
      required this.createdAt,
      this.completedAt,
      required this.status,
      this.errorMessage})
      : _profanityMatches = profanityMatches,
        _frameResults = frameResults,
        super._();

  factory _$AnalysisArtifactImpl.fromJson(Map<String, dynamic> json) =>
      _$$AnalysisArtifactImplFromJson(json);

  /// Version of the artifact format
  @override
  @JsonKey()
  final int version;

  /// SHA-256 hash of the source media file
  @override
  final String mediaHash;

  /// Media file information
  @override
  final ArtifactMediaInfo mediaInfo;

  /// Settings used for this analysis
  @override
  final AnalysisSettings settingsUsed;

  /// Transcript if ASR was performed
  @override
  final Transcript? transcript;

  /// Profanity matches found
  final List<ProfanityMatch> _profanityMatches;

  /// Profanity matches found
  @override
  @JsonKey()
  List<ProfanityMatch> get profanityMatches {
    if (_profanityMatches is EqualUnmodifiableListView)
      return _profanityMatches;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_profanityMatches);
  }

  /// Frame analysis results
  final List<FrameAnalysisResult> _frameResults;

  /// Frame analysis results
  @override
  @JsonKey()
  List<FrameAnalysisResult> get frameResults {
    if (_frameResults is EqualUnmodifiableListView) return _frameResults;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_frameResults);
  }

  /// Unified timeline with all detections and modifications
  @override
  final UnifiedTimeline timeline;

  /// When the analysis was started
  @override
  final DateTime createdAt;

  /// When the analysis was completed
  @override
  final DateTime? completedAt;

  /// Current status of the analysis
  @override
  final AnalysisStatus status;

  /// Error message if failed
  @override
  final String? errorMessage;

  @override
  String toString() {
    return 'AnalysisArtifact(version: $version, mediaHash: $mediaHash, mediaInfo: $mediaInfo, settingsUsed: $settingsUsed, transcript: $transcript, profanityMatches: $profanityMatches, frameResults: $frameResults, timeline: $timeline, createdAt: $createdAt, completedAt: $completedAt, status: $status, errorMessage: $errorMessage)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$AnalysisArtifactImpl &&
            (identical(other.version, version) || other.version == version) &&
            (identical(other.mediaHash, mediaHash) ||
                other.mediaHash == mediaHash) &&
            (identical(other.mediaInfo, mediaInfo) ||
                other.mediaInfo == mediaInfo) &&
            (identical(other.settingsUsed, settingsUsed) ||
                other.settingsUsed == settingsUsed) &&
            (identical(other.transcript, transcript) ||
                other.transcript == transcript) &&
            const DeepCollectionEquality()
                .equals(other._profanityMatches, _profanityMatches) &&
            const DeepCollectionEquality()
                .equals(other._frameResults, _frameResults) &&
            (identical(other.timeline, timeline) ||
                other.timeline == timeline) &&
            (identical(other.createdAt, createdAt) ||
                other.createdAt == createdAt) &&
            (identical(other.completedAt, completedAt) ||
                other.completedAt == completedAt) &&
            (identical(other.status, status) || other.status == status) &&
            (identical(other.errorMessage, errorMessage) ||
                other.errorMessage == errorMessage));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
      runtimeType,
      version,
      mediaHash,
      mediaInfo,
      settingsUsed,
      transcript,
      const DeepCollectionEquality().hash(_profanityMatches),
      const DeepCollectionEquality().hash(_frameResults),
      timeline,
      createdAt,
      completedAt,
      status,
      errorMessage);

  /// Create a copy of AnalysisArtifact
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$AnalysisArtifactImplCopyWith<_$AnalysisArtifactImpl> get copyWith =>
      __$$AnalysisArtifactImplCopyWithImpl<_$AnalysisArtifactImpl>(
          this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$AnalysisArtifactImplToJson(
      this,
    );
  }
}

abstract class _AnalysisArtifact extends AnalysisArtifact {
  const factory _AnalysisArtifact(
      {final int version,
      required final String mediaHash,
      required final ArtifactMediaInfo mediaInfo,
      required final AnalysisSettings settingsUsed,
      final Transcript? transcript,
      final List<ProfanityMatch> profanityMatches,
      final List<FrameAnalysisResult> frameResults,
      required final UnifiedTimeline timeline,
      required final DateTime createdAt,
      final DateTime? completedAt,
      required final AnalysisStatus status,
      final String? errorMessage}) = _$AnalysisArtifactImpl;
  const _AnalysisArtifact._() : super._();

  factory _AnalysisArtifact.fromJson(Map<String, dynamic> json) =
      _$AnalysisArtifactImpl.fromJson;

  /// Version of the artifact format
  @override
  int get version;

  /// SHA-256 hash of the source media file
  @override
  String get mediaHash;

  /// Media file information
  @override
  ArtifactMediaInfo get mediaInfo;

  /// Settings used for this analysis
  @override
  AnalysisSettings get settingsUsed;

  /// Transcript if ASR was performed
  @override
  Transcript? get transcript;

  /// Profanity matches found
  @override
  List<ProfanityMatch> get profanityMatches;

  /// Frame analysis results
  @override
  List<FrameAnalysisResult> get frameResults;

  /// Unified timeline with all detections and modifications
  @override
  UnifiedTimeline get timeline;

  /// When the analysis was started
  @override
  DateTime get createdAt;

  /// When the analysis was completed
  @override
  DateTime? get completedAt;

  /// Current status of the analysis
  @override
  AnalysisStatus get status;

  /// Error message if failed
  @override
  String? get errorMessage;

  /// Create a copy of AnalysisArtifact
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$AnalysisArtifactImplCopyWith<_$AnalysisArtifactImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
