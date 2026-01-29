import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

import 'package:kidslens_video_editor/data/models/converters.dart';

part 'media_file.freezed.dart';
part 'media_file.g.dart';

/// Enum representing the type of media file
@JsonEnum()
enum MediaType {
  @JsonValue('video')
  video,
  @JsonValue('audio')
  audio,
}

/// Represents a media file (video or audio) in the project
@freezed
class MediaFile with _$MediaFile {
  const factory MediaFile({
    /// Unique identifier for the media file
    required String id,

    /// Absolute path to the file
    required String path,

    /// Display name of the file
    required String name,

    /// Duration of the media
    @DurationConverter() required Duration duration,

    /// Width of the video in pixels (0 for audio-only)
    required int width,

    /// Height of the video in pixels (0 for audio-only)
    required int height,

    /// File size in bytes
    required int fileSize,

    /// Type of the media file
    required MediaType mediaType,

    /// Codec used for encoding (e.g., 'h264', 'aac')
    String? codec,

    /// Container format (e.g., 'mp4', 'mkv', 'wav')
    String? container,
  }) = _MediaFile;

  const MediaFile._();

  factory MediaFile.fromJson(Map<String, dynamic> json) =>
      _$MediaFileFromJson(json);

  /// Creates a MediaFile from a video file path with metadata
  factory MediaFile.video({
    required String id,
    required String path,
    required String name,
    required Duration duration,
    required int width,
    required int height,
    required int fileSize,
    String? codec,
    String? container,
  }) =>
      MediaFile(
        id: id,
        path: path,
        name: name,
        duration: duration,
        width: width,
        height: height,
        fileSize: fileSize,
        codec: codec,
        container: container,
        mediaType: MediaType.video,
      );

  /// Creates a MediaFile from an audio file path with metadata
  factory MediaFile.audio({
    required String id,
    required String path,
    required String name,
    required Duration duration,
    required int fileSize,
    String? codec,
    String? container,
  }) =>
      MediaFile(
        id: id,
        path: path,
        name: name,
        duration: duration,
        width: 0,
        height: 0,
        fileSize: fileSize,
        codec: codec,
        container: container,
        mediaType: MediaType.audio,
      );

  /// Whether this is a video file
  bool get isVideo => mediaType == MediaType.video;

  /// Whether this is an audio file
  bool get isAudio => mediaType == MediaType.audio;

  /// Aspect ratio of the video (width / height)
  double get aspectRatio => height > 0 ? width / height : 0;

  /// Human-readable file size
  String get fileSizeFormatted {
    if (fileSize < 1024) return '$fileSize B';
    if (fileSize < 1024 * 1024) return '${(fileSize / 1024).toStringAsFixed(1)} KB';
    if (fileSize < 1024 * 1024 * 1024) {
      return '${(fileSize / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
    return '${(fileSize / (1024 * 1024 * 1024)).toStringAsFixed(2)} GB';
  }

  /// Computes the SHA-256 hash of the file for integrity verification
  Future<String> computeHash() async {
    final file = File(path);
    if (!file.existsSync()) {
      throw FileSystemException('File not found', path);
    }

    final bytes = await file.readAsBytes();
    final digest = sha256.convert(bytes);
    return digest.toString();
  }
}
