import 'dart:io';

import 'package:kidslens_video_editor/data/models/models.dart';

import 'package:kidslens_video_editor/services/analysis_service.dart';
import 'package:kidslens_video_editor/services/media_service.dart';

/// Strategy for selecting sample segment
enum SampleStrategy {
  beginning,
  middle,
  end,
  random,
  detectInteresting,
}

/// Service for running analysis on a sample segment
class SampleAnalysisService {
  SampleAnalysisService({
    required this.analysisService,
    required this.mediaService,
  });

  static const Duration sampleDuration = Duration(seconds: 5);

  final AnalysisService analysisService;
  final MediaService mediaService;

  /// Extract a representative sample offset from the media
  Future<Duration> selectSampleOffset(
    MediaFile media, {
    Duration? userPreference,
    SampleStrategy strategy = SampleStrategy.detectInteresting,
  }) async {
    if (userPreference != null) {
      return _clampOffset(userPreference, media.duration);
    }

    switch (strategy) {
      case SampleStrategy.beginning:
        return Duration.zero;
      case SampleStrategy.middle:
        final middle = media.duration ~/ 2;
        return _clampOffset(middle, media.duration);
      case SampleStrategy.end:
        final end = media.duration - sampleDuration;
        return _clampOffset(end, media.duration);
      case SampleStrategy.random:
        final maxOffset = media.duration - sampleDuration;
        if (maxOffset <= Duration.zero) return Duration.zero;
        final randomMs =
            DateTime.now().millisecondsSinceEpoch % maxOffset.inMilliseconds;
        return Duration(milliseconds: randomMs);
      case SampleStrategy.detectInteresting:
        return _detectInterestingOffset(media);
    }
  }

  /// Detect an "interesting" segment with potential content
  Future<Duration> _detectInterestingOffset(MediaFile media) async {
    try {
      // Use scene change detection to find interesting segments
      // FFmpeg's select filter with gt(scene,0.4) detects scene changes
      final result = await Process.run(
        'ffmpeg',
        [
          '-i', media.path,
          '-vf', "select='gt(scene,0.4)',showinfo",
          '-f', 'null',
          '-t', '60', // Limit analysis to first 60 seconds for performance
          '-',
        ],
        runInShell: Platform.isWindows,
      );

      if (result.exitCode == 0 || result.stderr != null) {
        // Parse scene change timestamps from stderr
        final lines = (result.stderr as String).split('\n');
        final sceneTimestamps = <Duration>[];

        for (final line in lines) {
          final match = RegExp(r'pts_time:(\d+\.?\d*)').firstMatch(line);
          if (match != null) {
            final time = double.tryParse(match.group(1)!) ?? 0.0;
            sceneTimestamps.add(Duration(milliseconds: (time * 1000).round()));
          }
        }

        if (sceneTimestamps.isNotEmpty) {
          // Return the first scene change that leaves enough time for sample
          for (final timestamp in sceneTimestamps) {
            final offset = _clampOffset(timestamp, media.duration);
            if (offset + sampleDuration <= media.duration) {
              return offset;
            }
          }
        }
      }
    } catch (e) {
      // Fall back to middle if scene detection fails
    }

    // Fallback: use middle of the video
    final middle = media.duration ~/ 2;
    return _clampOffset(middle, media.duration);
  }

  Duration _clampOffset(Duration offset, Duration totalDuration) {
    final maxOffset = totalDuration - sampleDuration;
    if (offset < Duration.zero) {
      return Duration.zero;
    }
    if (offset > maxOffset) {
      return maxOffset.isNegative ? Duration.zero : maxOffset;
    }
    return offset;
  }

  /// Run analysis on a sample segment
  Stream<AnalysisProgress> analyzeSample(
    MediaFile media,
    Duration offset,
    AnalysisSettings settings,
  ) async* {
    // Extract sample segment using FFmpeg's seeking
    final tempDir = await Directory.systemTemp.createTemp('kidslens_sample_');
    final samplePath = '${tempDir.path}${Platform.pathSeparator}sample.mp4';

    try {
      // Extract sample segment using FFmpeg with accurate seeking
      final startTime = _formatTimestamp(offset);
      final duration = _formatTimestamp(sampleDuration);

      final extractResult = await Process.run(
        'ffmpeg',
        [
          '-ss', startTime, // Seek before input for faster seeking
          '-i', media.path,
          '-t', duration,
          '-c', 'copy', // Copy codecs for speed
          '-avoid_negative_ts', 'make_zero',
          '-y',
          samplePath,
        ],
        runInShell: Platform.isWindows,
      );

      if (extractResult.exitCode != 0) {
        // If copy fails, try re-encoding
        await Process.run(
          'ffmpeg',
          [
            '-ss',
            startTime,
            '-i',
            media.path,
            '-t',
            duration,
            '-y',
            samplePath,
          ],
          runInShell: Platform.isWindows,
        );
      }

      // Run analysis on the extracted sample
      if (File(samplePath).existsSync()) {
        await for (final progress in analysisService.analyze(
          samplePath,
          settings,
        )) {
          yield progress;
        }
      } else {
        // Fallback: analyze full file if extraction failed
        await for (final progress in analysisService.analyze(
          media.path,
          settings,
        )) {
          yield progress;
        }
      }
    } finally {
      // Clean up temp files
      try {
        await tempDir.delete(recursive: true);
      } catch (_) {
        // Ignore cleanup errors
      }
    }
  }

  /// Format duration as FFmpeg timestamp (HH:MM:SS.mmm)
  String _formatTimestamp(Duration duration) {
    final hours = duration.inHours.toString().padLeft(2, '0');
    final minutes = (duration.inMinutes % 60).toString().padLeft(2, '0');
    final seconds = (duration.inSeconds % 60).toString().padLeft(2, '0');
    final millis = (duration.inMilliseconds % 1000).toString().padLeft(3, '0');
    return '$hours:$minutes:$seconds.$millis';
  }
}

/// Result of sample analysis
class SampleAnalysisResult {
  const SampleAnalysisResult({
    required this.sampleOffset,
    required this.sampleDuration,
    required this.settingsUsed,
    required this.profanityCount,
    required this.nudityCount,
    required this.violenceCount,
  }) : hasContent = profanityCount > 0 || nudityCount > 0 || violenceCount > 0;

  final Duration sampleOffset;
  final Duration sampleDuration;
  final AnalysisSettings settingsUsed;
  final int profanityCount;
  final int nudityCount;
  final int violenceCount;
  final bool hasContent;
}
