import 'dart:io';

import 'package:kidslens_video_editor/data/models/models.dart';
import 'package:kidslens_video_editor/native/bindings/ffmpeg_bindings.dart';

/// Service for media file operations
class MediaService {
  MediaService(this._ffmpeg);

  final FFmpegBindings _ffmpeg;

  /// Import a media file and extract metadata
  Future<MediaFile> importMedia(String path) async {
    final file = File(path);
    if (!file.existsSync()) {
      throw MediaFileNotFoundException(path);
    }

    final metadata = await _ffmpeg.probeMedia(path);
    final mediaType = _determineMediaType(path);

    return MediaFile(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      path: path,
      name: file.uri.pathSegments.last,
      duration: metadata.duration,
      width: metadata.resolution.width,
      height: metadata.resolution.height,
      fileSize: metadata.fileSizeBytes,
      mediaType: mediaType,
      codec: mediaType == MediaType.video
          ? metadata.videoCodec
          : metadata.audioCodec,
    );
  }

  /// Extract audio track from video file
  Future<String> extractAudio(String videoPath, String outputPath) async =>
      _ffmpeg.extractAudio(videoPath, outputPath);

  /// Extract frames from video at specified FPS
  Stream<FrameData> extractFrames(
    String videoPath, {
    double fps = 2.0,
    int? startFrame,
    int? endFrame,
  }) => _ffmpeg.extractFrames(
      videoPath,
      fps: fps,
      startFrame: startFrame,
      endFrame: endFrame,
    );

  /// Generate thumbnail for a video
  Future<String> generateThumbnail(String videoPath, String outputPath) async =>
      _ffmpeg.generateThumbnail(videoPath, outputPath);

  /// Get the duration of a media file
  Future<Duration> getDuration(String path) async {
    final metadata = await _ffmpeg.probeMedia(path);
    return metadata.duration;
  }

  MediaType _determineMediaType(String path) {
    final extension = path.split('.').last.toLowerCase();
    const videoExtensions = [
      'mp4', 'mkv', 'avi', 'mov', 'wmv', 'flv', 'webm', 'm4v',
    ];
    return videoExtensions.contains(extension)
        ? MediaType.video
        : MediaType.audio;
  }
}

/// Exception thrown when a media file is not found
class MediaFileNotFoundException implements Exception {
  MediaFileNotFoundException(this.path);

  final String path;

  @override
  String toString() => 'Media file not found: $path';
}

/// Represents extracted frame data
class FrameData {
  FrameData({
    required this.frameNumber,
    required this.timestamp,
    required this.rgbData,
    required this.width,
    required this.height,
  });

  final int frameNumber;
  final Duration timestamp;
  final List<int> rgbData;
  final int width;
  final int height;
}

/// Resolution of a video file
class Resolution {
  const Resolution({required this.width, required this.height});

  final int width;
  final int height;
}

/// Metadata extracted from a media file
class MediaMetadata {
  const MediaMetadata({
    required this.duration,
    required this.fileSizeBytes,
    required this.resolution,
    required this.frameRate,
    this.videoCodec,
    this.audioCodec,
  });

  final Duration duration;
  final int fileSizeBytes;
  final Resolution resolution;
  final double frameRate;
  final String? videoCodec;
  final String? audioCodec;
}
