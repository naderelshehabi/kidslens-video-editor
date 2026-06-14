import 'dart:async';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:kidslens_video_editor/data/models/frame_data.dart';
import 'package:kidslens_video_editor/data/models/sampled_frame_ref.dart';
import 'package:kidslens_video_editor/data/models/video_chunk.dart';
import 'package:kidslens_video_editor/jobs/cancellation_token.dart';
import 'package:kidslens_video_editor/native/bindings/ffmpeg_bindings.dart';
import 'package:kidslens_video_editor/services/detection/vlm_provider.dart';

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

/// Configuration for chunk-aware frame-reference selection.
class ChunkFrameSelectionConfig {
  const ChunkFrameSelectionConfig({
    this.maxFramesPerChunk = 12,
    this.includeStart = true,
    this.includeMiddle = true,
    this.includeEnd = true,
    this.includeSceneChanges = true,
    this.includeMotionTimestamps = true,
  });

  final int maxFramesPerChunk;
  final bool includeStart;
  final bool includeMiddle;
  final bool includeEnd;
  final bool includeSceneChanges;
  final bool includeMotionTimestamps;

  Map<String, dynamic> toJson() => {
        'maxFramesPerChunk': maxFramesPerChunk,
        'includeStart': includeStart,
        'includeMiddle': includeMiddle,
        'includeEnd': includeEnd,
        'includeSceneChanges': includeSceneChanges,
        'includeMotionTimestamps': includeMotionTimestamps,
      };
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

    // Calculate output dimensions
    final outputWidth = samplingConfig.outputWidth ?? metadata.width;
    final outputHeight = samplingConfig.outputHeight ?? metadata.height;

    // Use streaming extraction: single FFmpeg process for all frames
    yield* _streamFrames(
      videoPath,
      fps: samplingConfig.baseFps,
      width: outputWidth,
      height: outputHeight,
      format: samplingConfig.outputFormat,
      duration: duration,
      detectSceneChanges: samplingConfig.boostOnSceneChange,
      sceneChangeThreshold: samplingConfig.sceneChangeThreshold,
    );
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

  /// Build deterministic frame references for VLM-style chunk analysis.
  List<SampledFrameRef> selectFrameRefsForChunks(
    List<VideoChunk> chunks, {
    ChunkFrameSelectionConfig config = const ChunkFrameSelectionConfig(),
    Map<String, List<Duration>> motionTimestampsByChunkId = const {},
  }) {
    if (config.maxFramesPerChunk < 1) {
      throw ArgumentError.value(
        config.maxFramesPerChunk,
        'maxFramesPerChunk',
        'Must select at least one frame per non-empty chunk',
      );
    }

    final refs = <SampledFrameRef>[];
    for (final chunk in chunks) {
      final candidates = <int, Set<String>>{};

      void addCandidate(Duration timestamp, String reason) {
        if (timestamp < chunk.startTime || timestamp >= chunk.endTime) {
          return;
        }
        candidates
            .putIfAbsent(timestamp.inMilliseconds, () => <String>{})
            .add(reason);
      }

      if (config.includeStart) {
        addCandidate(chunk.startTime, 'chunk_start');
      }
      if (config.includeMiddle) {
        addCandidate(
          chunk.startTime +
              Duration(milliseconds: chunk.duration.inMilliseconds ~/ 2),
          'chunk_middle',
        );
      }
      if (config.includeEnd) {
        addCandidate(
          chunk.endTime - const Duration(milliseconds: 1),
          'chunk_end',
        );
      }
      if (config.includeSceneChanges) {
        for (final timestamp in chunk.sceneChangeTimestamps) {
          addCandidate(timestamp, 'scene_change');
        }
      }
      if (config.includeMotionTimestamps) {
        for (final timestamp
            in motionTimestampsByChunkId[chunk.id] ?? const <Duration>[]) {
          addCandidate(timestamp, 'motion');
        }
      }

      final selectedTimestamps = _selectRepresentativeTimestamps(
        candidates.keys.toList(growable: false)..sort(),
        config.maxFramesPerChunk,
      );

      for (var frameIndex = 0;
          frameIndex < selectedTimestamps.length;
          frameIndex++) {
        final timestamp =
            Duration(milliseconds: selectedTimestamps[frameIndex]);
        refs.add(
          SampledFrameRef(
            id: SampledFrameRef.deterministicId(
              mediaId: chunk.mediaId,
              chunkId: chunk.id,
              frameIndex: frameIndex,
              timestamp: timestamp,
            ),
            mediaId: chunk.mediaId,
            chunkId: chunk.id,
            frameIndex: frameIndex,
            timestamp: timestamp,
            selectionReasons:
                candidates[selectedTimestamps[frameIndex]]!.toList()..sort(),
          ),
        );
      }
    }

    return refs;
  }

  /// Build deterministic fixed-FPS frame references for legacy providers.
  List<SampledFrameRef> selectLegacyFixedFpsFrameRefs(
    List<VideoChunk> chunks, {
    double fps = 1.0,
  }) {
    if (fps <= 0) {
      throw ArgumentError.value(fps, 'fps', 'FPS must be positive');
    }

    final refs = <SampledFrameRef>[];
    final intervalMs = (1000 / fps).round();
    for (final chunk in chunks) {
      var timestampMs = chunk.startTime.inMilliseconds;
      var frameIndex = 0;
      while (timestampMs < chunk.endTime.inMilliseconds) {
        final timestamp = Duration(milliseconds: timestampMs);
        refs.add(
          SampledFrameRef(
            id: SampledFrameRef.deterministicId(
              mediaId: chunk.mediaId,
              chunkId: chunk.id,
              frameIndex: frameIndex,
              timestamp: timestamp,
            ),
            mediaId: chunk.mediaId,
            chunkId: chunk.id,
            frameIndex: frameIndex,
            timestamp: timestamp,
            selectionReasons: const ['legacy_fixed_fps'],
          ),
        );
        timestampMs += intervalMs;
        frameIndex++;
      }
    }
    return refs;
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

  /// Extract JPEG payloads for sampled frame references in a video chunk.
  ///
  /// This path is used by local VLM providers, so it returns in-memory JPEG
  /// payloads instead of writing frame files to disk. The implementation uses
  /// one fast-seek FFmpeg invocation per selected frame for correctness and
  /// simple cancellation semantics.
  Future<List<VlmFrameImage>> extractChunkJpegFrames({
    required String videoPath,
    required VideoChunk chunk,
    required List<SampledFrameRef> frameRefs,
    int maxLongSide = 768,
    int jpegQuality = 85,
    CancellationToken? cancellationToken,
  }) async {
    if (maxLongSide < 1) {
      throw ArgumentError.value(maxLongSide, 'maxLongSide', 'must be positive');
    }
    if (jpegQuality < 1 || jpegQuality > 100) {
      throw ArgumentError.value(jpegQuality, 'jpegQuality', 'must be 1..100');
    }
    SampledFrameRef? invalidRef;
    for (final ref in frameRefs) {
      if (ref.mediaId != chunk.mediaId ||
          ref.chunkId != chunk.id ||
          ref.timestamp < chunk.startTime ||
          ref.timestamp >= chunk.endTime) {
        invalidRef = ref;
        break;
      }
    }
    if (invalidRef != null) {
      throw FrameSamplingException(
        'Frame reference ${invalidRef.id} does not belong to chunk ${chunk.id}',
      );
    }

    await cancellationToken?.checkState();
    final metadata = await _getVideoMetadata(videoPath);
    if (metadata == null) {
      throw FrameSamplingException('Failed to read video metadata');
    }
    final size = _scaleToLongSide(
      width: metadata.width,
      height: metadata.height,
      maxLongSide: maxLongSide,
    );

    final stopwatch = Stopwatch()..start();
    final images = <VlmFrameImage>[];
    for (final ref in frameRefs) {
      await cancellationToken?.checkState();
      final bytes = await _extractJpegFrame(
        videoPath: videoPath,
        timestamp: ref.timestamp,
        width: size.width,
        height: size.height,
        jpegQuality: jpegQuality,
      );
      images.add(
        VlmFrameImage(
          frameRef: ref,
          jpegBytes: bytes,
          width: size.width,
          height: size.height,
          sha256: sha256.convert(bytes).toString(),
        ),
      );
    }
    stopwatch.stop();
    debugPrint(
      'Extracted ${images.length} JPEG VLM frame(s) for ${chunk.id} in '
      '${stopwatch.elapsedMilliseconds} ms',
    );
    return images;
  }

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

  /// Stream all frames from a video using a single FFmpeg process.
  ///
  /// This replaces the per-frame process spawning approach, which was the
  /// primary speed bottleneck. A single FFmpeg invocation reads the video once
  /// and outputs downsampled raw frames on stdout. Frames are yielded as soon
  /// as enough bytes are buffered.
  Stream<FrameData> _streamFrames(
    String videoPath, {
    required double fps,
    required int width,
    required int height,
    required FrameFormat format,
    required Duration duration,
    bool detectSceneChanges = false,
    double sceneChangeThreshold = 0.4,
  }) async* {
    final ffmpegPath = ffmpeg.ffmpegPath ?? 'ffmpeg';
    final pixelFormat = _ffmpegPixelFormat(format);
    final frameSize = _expectedDataSizeForFormat(width, height, format);

    if (frameSize <= 0) {
      throw FrameSamplingException(
        'Invalid frame size: ${width}x$height format=$format',
      );
    }

    // Build video filter chain
    final filters = <String>[
      'fps=$fps',
      'scale=$width:$height',
    ];
    final vf = filters.join(',');

    final process = await Process.start(
      ffmpegPath,
      [
        '-hide_banner',
        '-loglevel',
        'error',
        '-i',
        videoPath,
        '-vf',
        vf,
        '-pix_fmt',
        pixelFormat,
        '-f',
        'rawvideo',
        'pipe:1',
      ],
      runInShell: Platform.isWindows,
    );

    var frameNumber = 0;
    // Accumulate stdout bytes, yielding complete frames as they arrive
    var buffer = Uint8List(0);

    try {
      await for (final chunk in process.stdout) {
        // Append chunk to buffer
        final newBuffer = Uint8List(buffer.length + chunk.length)
          ..setRange(0, buffer.length, buffer)
          ..setRange(buffer.length, buffer.length + chunk.length, chunk);
        buffer = newBuffer;

        // Yield complete frames as soon as we have enough data
        while (buffer.length >= frameSize) {
          final frameBytes = Uint8List.sublistView(buffer, 0, frameSize);

          final timestamp = Duration(
            milliseconds: (frameNumber * 1000 / fps).round(),
          );

          yield FrameData(
            timestamp: timestamp,
            width: width,
            height: height,
            data: Uint8List.fromList(frameBytes),
            format: format,
            frameNumber: frameNumber,
          );

          // Remove consumed bytes from buffer
          buffer = Uint8List.sublistView(buffer, frameSize);
          frameNumber++;
        }
      }

      final exitCode = await process.exitCode;
      if (exitCode != 0 && frameNumber == 0) {
        throw FrameSamplingException(
          'FFmpeg streaming extraction failed with exit code $exitCode',
        );
      }
    } catch (e) {
      process.kill();
      if (e is FrameSamplingException) rethrow;
      throw FrameSamplingException('Frame streaming failed: $e');
    }
  }

  /// Calculate frame extraction timestamps
  // ignore: unused_element
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

  Future<List<int>> _extractJpegFrame({
    required String videoPath,
    required Duration timestamp,
    required int width,
    required int height,
    required int jpegQuality,
  }) async {
    final ffmpegPath = ffmpeg.ffmpegPath ?? 'ffmpeg';
    final qscale = _jpegQualityToQscale(jpegQuality);
    String? lastFailure;
    for (final attemptTimestamp in _jpegSeekAttempts(timestamp)) {
      final result = await Process.run(
        ffmpegPath,
        [
          '-hide_banner',
          '-loglevel',
          'error',
          '-ss',
          _formatTimestamp(attemptTimestamp),
          '-i',
          videoPath,
          '-frames:v',
          '1',
          '-vf',
          'scale=$width:$height',
          '-pix_fmt',
          'yuvj420p',
          '-q:v',
          '$qscale',
          '-vcodec',
          'mjpeg',
          '-f',
          'image2pipe',
          'pipe:1',
        ],
        stdoutEncoding: null,
      );

      if (result.exitCode != 0) {
        final stderr = (result.stderr ?? '').toString();
        lastFailure =
            'exit code ${result.exitCode} at ${_formatTimestamp(attemptTimestamp)}: ${_tail(stderr)}';
        continue;
      }

      final raw = result.stdout;
      if (raw is! List<int> || raw.length < 4) {
        lastFailure =
            'invalid JPEG buffer at ${_formatTimestamp(attemptTimestamp)} (${raw is List<int> ? raw.length : 0} bytes)';
        continue;
      }
      if (raw[0] != 0xff || raw[1] != 0xd8) {
        lastFailure =
            'non-JPEG frame buffer at ${_formatTimestamp(attemptTimestamp)}';
        continue;
      }
      return List<int>.unmodifiable(raw);
    }

    throw FrameSamplingException(
      'FFmpeg JPEG frame extraction failed: ${lastFailure ?? 'no frame returned'}',
    );
  }

  /// Detect scene change between two timestamps
  // ignore: unused_element
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
  // ignore: unused_element
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

  _ScaledFrameSize _scaleToLongSide({
    required int width,
    required int height,
    required int maxLongSide,
  }) {
    if (width < 1 || height < 1) {
      throw FrameSamplingException(
        'Invalid source video size: ${width}x$height',
      );
    }
    final longSide = width > height ? width : height;
    final scale = longSide > maxLongSide ? maxLongSide / longSide : 1.0;
    var scaledWidth = (width * scale).round();
    var scaledHeight = (height * scale).round();
    scaledWidth = _makeEven(scaledWidth.clamp(2, maxLongSide));
    scaledHeight = _makeEven(scaledHeight.clamp(2, maxLongSide));
    return _ScaledFrameSize(width: scaledWidth, height: scaledHeight);
  }

  int _makeEven(num value) {
    final integer = value.round();
    if (integer <= 2) {
      return 2;
    }
    return integer.isEven ? integer : integer - 1;
  }

  int _jpegQualityToQscale(int quality) =>
      (31 - ((quality.clamp(1, 100) - 1) * 29 / 99)).round().clamp(2, 31);

  List<Duration> _jpegSeekAttempts(Duration timestamp) {
    final attempts = <Duration>[timestamp];
    for (final offset in const [
      Duration(milliseconds: 100),
      Duration(milliseconds: 250),
      Duration(milliseconds: 500),
    ]) {
      final candidate = timestamp - offset;
      attempts.add(candidate.isNegative ? Duration.zero : candidate);
    }
    return attempts.toSet().toList(growable: false);
  }

  String _tail(String value, {int maxChars = 1200}) {
    final trimmed = value.trim();
    if (trimmed.length <= maxChars) {
      return trimmed;
    }
    return trimmed.substring(trimmed.length - maxChars);
  }

  List<int> _selectRepresentativeTimestamps(
    List<int> sortedTimestamps,
    int maxCount,
  ) {
    if (sortedTimestamps.length <= maxCount) {
      return sortedTimestamps;
    }

    final selected = <int>{};
    final lastIndex = sortedTimestamps.length - 1;
    for (var i = 0; i < maxCount; i++) {
      final index =
          maxCount == 1 ? 0 : (i * lastIndex / (maxCount - 1)).round();
      selected.add(sortedTimestamps[index]);
    }
    return selected.toList(growable: false)..sort();
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

class _ScaledFrameSize {
  const _ScaledFrameSize({
    required this.width,
    required this.height,
  });

  final int width;
  final int height;
}

/// Exception thrown by frame sampling service
class FrameSamplingException implements Exception {
  FrameSamplingException(this.message);

  final String message;

  @override
  String toString() => 'FrameSamplingException: $message';
}
