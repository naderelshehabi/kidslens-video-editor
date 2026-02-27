import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:kidslens_video_editor/data/models/frame_data.dart';
import 'package:kidslens_video_editor/native/bindings/ffmpeg_bindings.dart';

/// Configuration for frame sampling
class FrameSamplingConfig {
  const FrameSamplingConfig({
    this.baseFps = 1.0,
    this.includeKeyframes = true,
    this.boostOnSceneChange = true,
    this.maxFps = 5.0,
    this.sceneChangeThreshold = 0.4,
    this.outputWidth,
    this.outputHeight,
    this.outputFormat = FrameFormat.rgb24,
  });

  /// Creates configuration optimized for fast preview
  factory FrameSamplingConfig.fastPreview() => const FrameSamplingConfig(
        baseFps: 0.5,
        includeKeyframes: false,
        boostOnSceneChange: false,
        outputWidth: 224,
        outputHeight: 224,
      );

  /// Creates configuration for thorough analysis
  factory FrameSamplingConfig.thorough() => const FrameSamplingConfig(
        baseFps: 2,
        maxFps: 10,
        outputWidth: 640,
        outputHeight: 480,
      );

  /// Base sampling rate in frames per second
  final double baseFps;

  /// Whether to include all keyframes regardless of sampling rate
  final bool includeKeyframes;

  /// Whether to increase sampling rate around detected scene changes
  final bool boostOnSceneChange;

  /// Maximum sampling rate when boosting for scene changes
  final double maxFps;

  /// Threshold for scene change detection (0.0 to 1.0)
  final double sceneChangeThreshold;

  /// Output width for frames (null = original)
  final int? outputWidth;

  /// Output height for frames (null = original)
  final int? outputHeight;

  /// Output pixel format
  final FrameFormat outputFormat;

  /// Copy with modifications
  FrameSamplingConfig copyWith({
    double? baseFps,
    bool? includeKeyframes,
    bool? boostOnSceneChange,
    double? maxFps,
    double? sceneChangeThreshold,
    int? outputWidth,
    int? outputHeight,
    FrameFormat? outputFormat,
  }) =>
      FrameSamplingConfig(
        baseFps: baseFps ?? this.baseFps,
        includeKeyframes: includeKeyframes ?? this.includeKeyframes,
        boostOnSceneChange: boostOnSceneChange ?? this.boostOnSceneChange,
        maxFps: maxFps ?? this.maxFps,
        sceneChangeThreshold: sceneChangeThreshold ?? this.sceneChangeThreshold,
        outputWidth: outputWidth ?? this.outputWidth,
        outputHeight: outputHeight ?? this.outputHeight,
        outputFormat: outputFormat ?? this.outputFormat,
      );
}

/// Progress information for frame sampling
class FrameSamplingProgress {
  const FrameSamplingProgress({
    required this.framesExtracted,
    required this.estimatedTotalFrames,
    required this.currentTimestamp,
    required this.totalDuration,
  });

  /// Number of frames extracted so far
  final int framesExtracted;

  /// Estimated total frames to extract
  final int estimatedTotalFrames;

  /// Current position in the video
  final Duration currentTimestamp;

  /// Total video duration
  final Duration totalDuration;

  /// Progress as a value from 0.0 to 1.0
  double get progress {
    if (totalDuration.inMilliseconds == 0) return 0;
    return currentTimestamp.inMilliseconds / totalDuration.inMilliseconds;
  }

  /// Progress as a percentage
  double get percentage => progress * 100;
}

/// Service for intelligent frame extraction from video files
///
/// Extracts frames at configurable rates with support for keyframe detection
/// and scene change boosting using FFmpeg.
class FrameSamplingService {
  FrameSamplingService({
    required this.ffmpeg,
  });

  final FFmpegBindings ffmpeg;

  /// Sample frames from a video file
  ///
  /// Returns a stream of [FrameData] objects with associated metadata.
  /// The stream yields progress-like updates as frames are extracted.
  ///
  /// [videoPath] - Path to the video file
  /// [config] - Sampling configuration (uses defaults if not provided)
  Stream<FrameData> sampleFrames(
    String videoPath, {
    FrameSamplingConfig? config,
  }) async* {
    final samplingConfig = config ?? const FrameSamplingConfig();

    // Get video metadata
    final metadata = await _getVideoMetadata(videoPath);
    if (metadata == null) {
      throw FrameSamplingException('Failed to read video metadata');
    }

    final duration = metadata.duration;
    final sourceWidth = metadata.width;
    final sourceHeight = metadata.height;

    // Calculate output dimensions
    final outputWidth = samplingConfig.outputWidth ?? sourceWidth;
    final outputHeight = samplingConfig.outputHeight ?? sourceHeight;

    // Calculate frame extraction times
    final frameTimes = _calculateFrameTimes(
      duration: duration,
      baseFps: samplingConfig.baseFps,
      includeKeyframes: samplingConfig.includeKeyframes,
    );

    var frameNumber = 0;
    Duration? previousTimestamp;

    for (final timestamp in frameTimes) {
      try {
        // Extract frame at timestamp
        final frameData = await _extractFrame(
          videoPath,
          timestamp,
          width: outputWidth,
          height: outputHeight,
          format: samplingConfig.outputFormat,
        );

        if (frameData != null) {
          // Detect scene change if enabled
          double? sceneChangeScore;
          if (samplingConfig.boostOnSceneChange && previousTimestamp != null) {
            sceneChangeScore = await _detectSceneChange(
              videoPath,
              previousTimestamp,
              timestamp,
            );
          }

          yield frameData.copyWith(
            frameNumber: frameNumber,
            sceneChangeScore: sceneChangeScore,
            isKeyframe: await _isKeyframe(videoPath, timestamp),
          );

          frameNumber++;
          previousTimestamp = timestamp;
        }
      } catch (e) {
        debugPrint('Warning: Failed to extract frame at $timestamp: $e');
        // Continue with next frame
      }
    }
  }

  /// Sample frames with explicit FPS control
  ///
  /// Simpler alternative that extracts frames at a fixed rate.
  Stream<FrameData> sampleFramesAtFps(
    String videoPath, {
    double fps = 1.0,
    int? width,
    int? height,
  }) async* {
    yield* sampleFrames(
      videoPath,
      config: FrameSamplingConfig(
        baseFps: fps,
        includeKeyframes: false,
        boostOnSceneChange: false,
        outputWidth: width,
        outputHeight: height,
      ),
    );
  }

  /// Extract a single frame at a specific timestamp
  ///
  /// Useful for thumbnail generation or spot-checking.
  Future<FrameData?> extractFrameAt(
    String videoPath,
    Duration timestamp, {
    int? width,
    int? height,
    FrameFormat format = FrameFormat.rgb24,
  }) async =>
      _extractFrame(
        videoPath,
        timestamp,
        width: width,
        height: height,
        format: format,
      );

  /// Get keyframe timestamps for a video
  ///
  /// Returns timestamps of all I-frames (keyframes) in the video.
  Future<List<Duration>> getKeyframeTimes(String videoPath) async {
    try {
      // Use FFprobe with -skip_frame nokey to extract only keyframe info
      // and show_entries to get frame type and timestamp
      final result = await Process.run(
        'ffprobe',
        [
          '-v', 'quiet',
          '-select_streams', 'v:0', // First video stream
          '-skip_frame', 'nokey', // Only keyframes
          '-show_entries', 'frame=pts_time,pict_type',
          '-of', 'csv=p=0', // Simple CSV output
          videoPath,
        ],
        runInShell: Platform.isWindows,
      );

      if (result.exitCode == 0) {
        final keyframeTimes = <Duration>[];
        final lines = (result.stdout as String).split('\n');

        for (final line in lines) {
          final trimmed = line.trim();
          if (trimmed.isEmpty) continue;

          // Parse CSV: pts_time,pict_type (e.g., "1.234,I")
          final parts = trimmed.split(',');
          if (parts.isNotEmpty) {
            final timeStr = parts[0];
            final time = double.tryParse(timeStr);
            if (time != null) {
              // Check if it's an I-frame (keyframe)
              final isKeyframe = parts.length > 1 && parts[1].trim() == 'I';
              if (isKeyframe || parts.length == 1) {
                keyframeTimes.add(
                  Duration(milliseconds: (time * 1000).round()),
                );
              }
            }
          }
        }

        return keyframeTimes;
      }
    } catch (e) {
      debugPrint('Keyframe detection failed: $e');
    }

    return [];
  }

  /// Detect scene changes in a video
  ///
  /// Returns timestamps where scene changes are detected.
  Future<List<Duration>> detectSceneChanges(
    String videoPath, {
    double threshold = 0.4,
  }) async {
    try {
      // Use FFmpeg's select filter with scene detection
      // gt(scene,threshold) selects frames where scene change score > threshold
      final result = await Process.run(
        'ffmpeg',
        [
          '-i',
          videoPath,
          '-vf',
          "select='gt(scene,$threshold)',showinfo",
          '-f',
          'null',
          '-',
        ],
        runInShell: Platform.isWindows,
      );

      // Scene detection info is written to stderr
      if (result.stderr != null) {
        final sceneTimestamps = <Duration>[];
        final lines = (result.stderr as String).split('\n');

        for (final line in lines) {
          // Parse showinfo output: look for pts_time
          final match = RegExp(r'pts_time:(\d+\.?\d*)').firstMatch(line);
          if (match != null) {
            final time = double.tryParse(match.group(1)!) ?? 0.0;
            sceneTimestamps.add(
              Duration(milliseconds: (time * 1000).round()),
            );
          }
        }

        return sceneTimestamps;
      }
    } catch (e) {
      debugPrint('Scene change detection failed: $e');
    }

    return [];
  }

  /// Get video metadata
  Future<_VideoMetadata?> _getVideoMetadata(String videoPath) async {
    try {
      final info = await ffmpeg.probeMedia(videoPath);
      return _VideoMetadata(
        duration: info.duration,
        width: info.resolution.width,
        height: info.resolution.height,
        fps: info.frameRate,
      );
    } catch (e) {
      debugPrint('Failed to get video metadata: $e');
      return null;
    }
  }

  /// Calculate frame extraction timestamps
  List<Duration> _calculateFrameTimes({
    required Duration duration,
    required double baseFps,
    required bool includeKeyframes,
  }) {
    final times = <Duration>[];
    final intervalMs = (1000 / baseFps).round();
    var currentMs = 0;
    final durationMs = duration.inMilliseconds;

    while (currentMs < durationMs) {
      times.add(Duration(milliseconds: currentMs));
      currentMs += intervalMs;
    }

    return times;
  }

  /// Extract a frame at a specific timestamp
  Future<FrameData?> _extractFrame(
    String videoPath,
    Duration timestamp, {
    required FrameFormat format,
    int? width,
    int? height,
  }) async {
    try {
      final ffmpegPath = ffmpeg.ffmpegPath ?? 'ffmpeg';
      final actualWidth = width ?? 1920;
      final actualHeight = height ?? 1080;
      final pixelFormat = _ffmpegPixelFormat(format);
      final expectedSize = _expectedDataSizeForFormat(
        actualWidth,
        actualHeight,
        format,
      );

      final result = await Process.run(
        ffmpegPath,
        [
          '-i',
          videoPath,
          '-ss',
          _formatTimestamp(timestamp),
          '-vframes',
          '1',
          '-vf',
          'scale=$actualWidth:$actualHeight',
          '-pix_fmt',
          pixelFormat,
          '-f',
          'rawvideo',
          'pipe:1',
        ],
        runInShell: Platform.isWindows,
        stdoutEncoding: null,
      );

      if (result.exitCode != 0) {
        throw FrameSamplingException(
          'FFmpeg frame extraction failed: ${result.stderr}',
        );
      }

      final raw = result.stdout;
      if (raw is! List<int> || raw.length < expectedSize) {
        throw FrameSamplingException(
          'FFmpeg returned invalid frame buffer (${raw is List<int> ? raw.length : 0} bytes, expected $expectedSize)',
        );
      }

      return FrameData(
        timestamp: timestamp,
        width: actualWidth,
        height: actualHeight,
        data: Uint8List.fromList(raw.sublist(0, expectedSize)),
        format: format,
      );
    } catch (e) {
      debugPrint('Frame extraction failed at $timestamp: $e');
      return null;
    }
  }

  /// Detect scene change between two timestamps
  Future<double> _detectSceneChange(
    String videoPath,
    Duration previous,
    Duration current,
  ) async {
    try {
      // Extract the segment between timestamps and analyze scene changes
      final startTime = _formatTimestamp(previous);
      final duration = _formatTimestamp(current - previous);

      final result = await Process.run(
        ffmpeg.ffmpegPath ?? 'ffmpeg',
        [
          '-ss',
          startTime,
          '-i',
          videoPath,
          '-t',
          duration,
          '-vf',
          "select='gt(scene,0)',metadata=print:file=-",
          '-f',
          'null',
          '-',
        ],
        runInShell: Platform.isWindows,
      );

      // Parse scene scores from output
      if (result.stderr != null) {
        final lines = (result.stderr as String).split('\n');
        var maxScore = 0.0;

        for (final line in lines) {
          // Look for scene score in metadata
          final match =
              RegExp(r'lavfi\.scene_score=(\d+\.?\d*)').firstMatch(line);
          if (match != null) {
            final score = double.tryParse(match.group(1)!) ?? 0.0;
            if (score > maxScore) maxScore = score;
          }
        }

        return maxScore;
      }
    } catch (e) {
      debugPrint('Scene change detection failed: $e');
    }

    return 0.0;
  }

  /// Format duration as FFmpeg timestamp (HH:MM:SS.mmm)
  String _formatTimestamp(Duration duration) {
    final hours = duration.inHours.toString().padLeft(2, '0');
    final minutes = (duration.inMinutes % 60).toString().padLeft(2, '0');
    final seconds = (duration.inSeconds % 60).toString().padLeft(2, '0');
    final millis = (duration.inMilliseconds % 1000).toString().padLeft(3, '0');
    return '$hours:$minutes:$seconds.$millis';
  }

  /// Check if a timestamp corresponds to a keyframe
  Future<bool> _isKeyframe(String videoPath, Duration timestamp) async {
    try {
      final timeStr = _formatTimestamp(timestamp);

      // Use FFprobe to get frame info at the specific timestamp
      final result = await Process.run(
        ffmpeg.ffprobePath ?? 'ffprobe',
        [
          '-v', 'quiet',
          '-select_streams', 'v:0',
          '-read_intervals', '%$timeStr%+#1', // Read 1 frame at timestamp
          '-show_entries', 'frame=pict_type',
          '-of', 'csv=p=0',
          videoPath,
        ],
        runInShell: Platform.isWindows,
      );

      if (result.exitCode == 0) {
        final output = (result.stdout as String).trim();
        // I = keyframe (I-frame), P = P-frame, B = B-frame
        return output == 'I';
      }
    } catch (e) {
      debugPrint('Keyframe check failed: $e');
    }

    return false;
  }

  int _expectedDataSizeForFormat(int width, int height, FrameFormat format) {
    switch (format) {
      case FrameFormat.rgb24:
      case FrameFormat.bgr24:
        return width * height * 3;
      case FrameFormat.rgba32:
      case FrameFormat.bgra32:
        return width * height * 4;
      case FrameFormat.gray8:
        return width * height;
      case FrameFormat.yuv420p:
      case FrameFormat.nv12:
        return (width * height * 3) ~/ 2;
    }
  }

  String _ffmpegPixelFormat(FrameFormat format) {
    switch (format) {
      case FrameFormat.rgb24:
        return 'rgb24';
      case FrameFormat.rgba32:
        return 'rgba';
      case FrameFormat.bgr24:
        return 'bgr24';
      case FrameFormat.bgra32:
        return 'bgra';
      case FrameFormat.gray8:
        return 'gray';
      case FrameFormat.yuv420p:
        return 'yuv420p';
      case FrameFormat.nv12:
        return 'nv12';
    }
  }
}

/// Internal video metadata structure
class _VideoMetadata {
  const _VideoMetadata({
    required this.duration,
    required this.width,
    required this.height,
    required this.fps,
  });

  final Duration duration;
  final int width;
  final int height;
  final double fps;
}

/// Exception thrown by frame sampling service
class FrameSamplingException implements Exception {
  FrameSamplingException(this.message);

  final String message;

  @override
  String toString() => 'FrameSamplingException: $message';
}
