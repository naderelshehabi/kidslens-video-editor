// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'media_file.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

MediaFile _$MediaFileFromJson(Map<String, dynamic> json) {
  return _MediaFile.fromJson(json);
}

/// @nodoc
mixin _$MediaFile {
  /// Unique identifier for the media file
  String get id => throw _privateConstructorUsedError;

  /// Absolute path to the file
  String get path => throw _privateConstructorUsedError;

  /// Display name of the file
  String get name => throw _privateConstructorUsedError;

  /// Duration of the media
  @DurationConverter()
  Duration get duration => throw _privateConstructorUsedError;

  /// Width of the video in pixels (0 for audio-only)
  int get width => throw _privateConstructorUsedError;

  /// Height of the video in pixels (0 for audio-only)
  int get height => throw _privateConstructorUsedError;

  /// File size in bytes
  int get fileSize => throw _privateConstructorUsedError;

  /// Type of the media file
  MediaType get mediaType => throw _privateConstructorUsedError;

  /// Codec used for encoding (e.g., 'h264', 'aac')
  String? get codec => throw _privateConstructorUsedError;

  /// Container format (e.g., 'mp4', 'mkv', 'wav')
  String? get container => throw _privateConstructorUsedError;

  /// Serializes this MediaFile to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of MediaFile
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $MediaFileCopyWith<MediaFile> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $MediaFileCopyWith<$Res> {
  factory $MediaFileCopyWith(MediaFile value, $Res Function(MediaFile) then) =
      _$MediaFileCopyWithImpl<$Res, MediaFile>;
  @useResult
  $Res call(
      {String id,
      String path,
      String name,
      @DurationConverter() Duration duration,
      int width,
      int height,
      int fileSize,
      MediaType mediaType,
      String? codec,
      String? container});
}

/// @nodoc
class _$MediaFileCopyWithImpl<$Res, $Val extends MediaFile>
    implements $MediaFileCopyWith<$Res> {
  _$MediaFileCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of MediaFile
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? path = null,
    Object? name = null,
    Object? duration = null,
    Object? width = null,
    Object? height = null,
    Object? fileSize = null,
    Object? mediaType = null,
    Object? codec = freezed,
    Object? container = freezed,
  }) {
    return _then(_value.copyWith(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      path: null == path
          ? _value.path
          : path // ignore: cast_nullable_to_non_nullable
              as String,
      name: null == name
          ? _value.name
          : name // ignore: cast_nullable_to_non_nullable
              as String,
      duration: null == duration
          ? _value.duration
          : duration // ignore: cast_nullable_to_non_nullable
              as Duration,
      width: null == width
          ? _value.width
          : width // ignore: cast_nullable_to_non_nullable
              as int,
      height: null == height
          ? _value.height
          : height // ignore: cast_nullable_to_non_nullable
              as int,
      fileSize: null == fileSize
          ? _value.fileSize
          : fileSize // ignore: cast_nullable_to_non_nullable
              as int,
      mediaType: null == mediaType
          ? _value.mediaType
          : mediaType // ignore: cast_nullable_to_non_nullable
              as MediaType,
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
abstract class _$$MediaFileImplCopyWith<$Res>
    implements $MediaFileCopyWith<$Res> {
  factory _$$MediaFileImplCopyWith(
          _$MediaFileImpl value, $Res Function(_$MediaFileImpl) then) =
      __$$MediaFileImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String id,
      String path,
      String name,
      @DurationConverter() Duration duration,
      int width,
      int height,
      int fileSize,
      MediaType mediaType,
      String? codec,
      String? container});
}

/// @nodoc
class __$$MediaFileImplCopyWithImpl<$Res>
    extends _$MediaFileCopyWithImpl<$Res, _$MediaFileImpl>
    implements _$$MediaFileImplCopyWith<$Res> {
  __$$MediaFileImplCopyWithImpl(
      _$MediaFileImpl _value, $Res Function(_$MediaFileImpl) _then)
      : super(_value, _then);

  /// Create a copy of MediaFile
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? path = null,
    Object? name = null,
    Object? duration = null,
    Object? width = null,
    Object? height = null,
    Object? fileSize = null,
    Object? mediaType = null,
    Object? codec = freezed,
    Object? container = freezed,
  }) {
    return _then(_$MediaFileImpl(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      path: null == path
          ? _value.path
          : path // ignore: cast_nullable_to_non_nullable
              as String,
      name: null == name
          ? _value.name
          : name // ignore: cast_nullable_to_non_nullable
              as String,
      duration: null == duration
          ? _value.duration
          : duration // ignore: cast_nullable_to_non_nullable
              as Duration,
      width: null == width
          ? _value.width
          : width // ignore: cast_nullable_to_non_nullable
              as int,
      height: null == height
          ? _value.height
          : height // ignore: cast_nullable_to_non_nullable
              as int,
      fileSize: null == fileSize
          ? _value.fileSize
          : fileSize // ignore: cast_nullable_to_non_nullable
              as int,
      mediaType: null == mediaType
          ? _value.mediaType
          : mediaType // ignore: cast_nullable_to_non_nullable
              as MediaType,
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
class _$MediaFileImpl extends _MediaFile {
  const _$MediaFileImpl(
      {required this.id,
      required this.path,
      required this.name,
      @DurationConverter() required this.duration,
      required this.width,
      required this.height,
      required this.fileSize,
      required this.mediaType,
      this.codec,
      this.container})
      : super._();

  factory _$MediaFileImpl.fromJson(Map<String, dynamic> json) =>
      _$$MediaFileImplFromJson(json);

  /// Unique identifier for the media file
  @override
  final String id;

  /// Absolute path to the file
  @override
  final String path;

  /// Display name of the file
  @override
  final String name;

  /// Duration of the media
  @override
  @DurationConverter()
  final Duration duration;

  /// Width of the video in pixels (0 for audio-only)
  @override
  final int width;

  /// Height of the video in pixels (0 for audio-only)
  @override
  final int height;

  /// File size in bytes
  @override
  final int fileSize;

  /// Type of the media file
  @override
  final MediaType mediaType;

  /// Codec used for encoding (e.g., 'h264', 'aac')
  @override
  final String? codec;

  /// Container format (e.g., 'mp4', 'mkv', 'wav')
  @override
  final String? container;

  @override
  String toString() {
    return 'MediaFile(id: $id, path: $path, name: $name, duration: $duration, width: $width, height: $height, fileSize: $fileSize, mediaType: $mediaType, codec: $codec, container: $container)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$MediaFileImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.path, path) || other.path == path) &&
            (identical(other.name, name) || other.name == name) &&
            (identical(other.duration, duration) ||
                other.duration == duration) &&
            (identical(other.width, width) || other.width == width) &&
            (identical(other.height, height) || other.height == height) &&
            (identical(other.fileSize, fileSize) ||
                other.fileSize == fileSize) &&
            (identical(other.mediaType, mediaType) ||
                other.mediaType == mediaType) &&
            (identical(other.codec, codec) || other.codec == codec) &&
            (identical(other.container, container) ||
                other.container == container));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, id, path, name, duration, width,
      height, fileSize, mediaType, codec, container);

  /// Create a copy of MediaFile
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$MediaFileImplCopyWith<_$MediaFileImpl> get copyWith =>
      __$$MediaFileImplCopyWithImpl<_$MediaFileImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$MediaFileImplToJson(
      this,
    );
  }
}

abstract class _MediaFile extends MediaFile {
  const factory _MediaFile(
      {required final String id,
      required final String path,
      required final String name,
      @DurationConverter() required final Duration duration,
      required final int width,
      required final int height,
      required final int fileSize,
      required final MediaType mediaType,
      final String? codec,
      final String? container}) = _$MediaFileImpl;
  const _MediaFile._() : super._();

  factory _MediaFile.fromJson(Map<String, dynamic> json) =
      _$MediaFileImpl.fromJson;

  /// Unique identifier for the media file
  @override
  String get id;

  /// Absolute path to the file
  @override
  String get path;

  /// Display name of the file
  @override
  String get name;

  /// Duration of the media
  @override
  @DurationConverter()
  Duration get duration;

  /// Width of the video in pixels (0 for audio-only)
  @override
  int get width;

  /// Height of the video in pixels (0 for audio-only)
  @override
  int get height;

  /// File size in bytes
  @override
  int get fileSize;

  /// Type of the media file
  @override
  MediaType get mediaType;

  /// Codec used for encoding (e.g., 'h264', 'aac')
  @override
  String? get codec;

  /// Container format (e.g., 'mp4', 'mkv', 'wav')
  @override
  String? get container;

  /// Create a copy of MediaFile
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$MediaFileImplCopyWith<_$MediaFileImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
