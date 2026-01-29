import 'dart:async';
import 'dart:io';

import 'package:kidslens_video_editor/data/models/models.dart';
import 'package:kidslens_video_editor/native/bindings/ffmpeg_bindings.dart';
import 'package:kidslens_video_editor/services/media_service.dart';
import 'package:path/path.dart' as p;

/// Holds a modification along with its time range from the segment
class _TimedModification {
  const _TimedModification({
    required this.modification,
    required this.start,
    required this.end,
  });

  final Modification modification;
  final Duration start;
  final Duration end;

  Duration get duration => end - start;
}

/// Service for exporting modified media files
class ExportService {
  ExportService({
    required this.ffmpeg,
    required this.mediaService,
  });

  final FFmpegBindings ffmpeg;
  final MediaService mediaService;

  /// Export media with applied modifications
  Stream<ExportProgress> export({
    required String inputPath,
    required String outputPath,
    required UnifiedTimeline timeline,
    ExportSettings settings = const ExportSettings(),
  }) async* {
    yield const ExportProgress(
      progress: 0,
      phase: 'Initializing export',
    );

    // Check if FFmpeg is available
    await ffmpeg.initialize();
    if (!ffmpeg.isAvailable) {
      throw ExportException(
        'FFmpeg is not installed or not found.\n'
        'Please install FFmpeg and add it to your PATH.\n'
        'Download from: https://ffmpeg.org/download.html'
      );
    }

    // Collect all modifications with their time ranges
    final audioMods = <_TimedModification>[];
    final videoMods = <_TimedModification>[];

    for (final track in timeline.tracks) {
      for (final segment in track.segments) {
        if (segment.modification != null) {
          final timedMod = _TimedModification(
            modification: segment.modification!,
            start: segment.start,
            end: segment.end,
          );
          if (track.type == TrackType.audio) {
            audioMods.add(timedMod);
          } else if (track.type == TrackType.video) {
            videoMods.add(timedMod);
          }
        }
      }
    }

    // Generate FFmpeg filter complex
    yield const ExportProgress(
      progress: 0.1,
      phase: 'Building filter graph',
    );

    final filterComplex = _buildFilterComplex(
      audioMods,
      videoMods,
      settings,
    );

    // Create output directory if needed
    final outputDir = Directory(p.dirname(outputPath));
    if (!outputDir.existsSync()) {
      outputDir.createSync(recursive: true);
    }

    // Run FFmpeg export
    yield const ExportProgress(
      progress: 0.15,
      phase: 'Starting export',
    );

    try {
      await for (final progress in ffmpeg.runFilterComplex(
        inputPath: inputPath,
        outputPath: outputPath,
        filterComplex: filterComplex,
        outputSettings: _buildOutputSettings(settings),
        totalDuration: timeline.mediaDuration,
      )) {
        // Map FFmpeg progress (0-1) to export progress (0.15-0.95)
        final exportProgress = 0.15 + (progress * 0.80);
        yield ExportProgress(
          progress: exportProgress.clamp(0.0, 0.95),
          phase: 'Encoding: ${(progress * 100).toStringAsFixed(0)}%',
          encodedFrames: (progress * 100).toInt(),
        );
      }
    } catch (e) {
      throw ExportException('Export failed: $e');
    }

    // Verify output
    yield const ExportProgress(
      progress: 0.97,
      phase: 'Verifying output',
    );

    final outputFile = File(outputPath);
    if (!outputFile.existsSync()) {
      throw ExportException('Output file was not created. FFmpeg may have failed silently.');
    }

    final stat = outputFile.statSync();
    if (stat.size == 0) {
      throw ExportException('Output file is empty. FFmpeg encoding may have failed.');
    }

    yield const ExportProgress(
      progress: 1,
      phase: 'Complete',
    );
  }

  String _buildFilterComplex(
    List<_TimedModification> audioMods,
    List<_TimedModification> videoMods,
    ExportSettings settings,
  ) {
    final filters = <String>[];

    // Build audio filters
    for (final timedMod in audioMods) {
      final enable = _buildEnableExpression(timedMod.start, timedMod.end);
      final filter = _audioModToFilter(timedMod.modification, enable, timedMod);
      if (filter.isNotEmpty) {
        filters.add(filter);
      }
    }

    // Build video filters
    for (final timedMod in videoMods) {
      final enable = _buildEnableExpression(timedMod.start, timedMod.end);
      final filter = _videoModToFilter(timedMod.modification, enable);
      if (filter.isNotEmpty) {
        filters.add(filter);
      }
    }

    return filters.join(',');
  }

  String _buildEnableExpression(Duration start, Duration end) =>
      'between(t,${start.inMilliseconds / 1000.0},${end.inMilliseconds / 1000.0})';

  String _audioModToFilter(
    Modification mod,
    String enable,
    _TimedModification timedMod,
  ) => switch (mod) {
      AudioMute() => "volume=enable='$enable':volume=0",
      AudioBeep(:final frequency) =>
        'aevalsrc=sin($frequency*2*PI*t):d=${timedMod.duration.inMilliseconds / 1000.0}',
      AudioReplace(:final audioPath, :final volume) =>
        'amovie=$audioPath,volume=$volume',
      // Video modifications don't apply to audio track
      VideoBlur() => '',
      VideoPixelate() => '',
      VideoBlackBox() => '',
      VideoSkip() => '',
    };

  String _videoModToFilter(Modification mod, String enable) => switch (mod) {
      VideoBlur(:final intensity) =>
        "gblur=sigma=${_intensityToBlurSigma(intensity)}:enable='$enable'",
      // Pixelation is achieved by scaling down then back up with nearest neighbor
      VideoPixelate(:final blockSize) =>
        "scale=iw/$blockSize:ih/$blockSize:enable='$enable',"
            "scale=iw*$blockSize:ih*$blockSize:flags=neighbor:enable='$enable'",
      // Convert hex color and apply opacity
      VideoBlackBox(:final color, :final opacity) =>
        "drawbox=x=0:y=0:w=iw:h=ih:c=${_hexToFFmpegColor(color, opacity)}:t=fill:enable='$enable'",
      // Skip segments are handled differently - they're cut from the timeline
      VideoSkip() => '',
      // Audio modifications don't apply to video track
      AudioMute() => '',
      AudioBeep() => '',
      AudioReplace() => '',
    };

  /// Convert blur intensity (1-100) to FFmpeg gblur sigma value
  // Map intensity 1-100 to sigma 5-50
  int _intensityToBlurSigma(int intensity) => 5 + ((intensity - 1) * 45 ~/ 99);

  /// Convert hex color and opacity to FFmpeg color format
  String _hexToFFmpegColor(String hexColor, double opacity) {
    // Remove # prefix if present
    final hex = hexColor.startsWith('#') ? hexColor.substring(1) : hexColor;

    // Convert opacity to hex (0-255)
    final alphaHex = (opacity * 255).round().toRadixString(16).padLeft(2, '0');

    return '0x$hex$alphaHex';
  }

  Map<String, String> _buildOutputSettings(ExportSettings settings) {
    final result = <String, String>{};

    if (settings.videoCodec != null) {
      result['c:v'] = settings.videoCodec!;
    }
    if (settings.audioCodec != null) {
      result['c:a'] = settings.audioCodec!;
    }
    if (settings.videoBitrate != null) {
      result['b:v'] = settings.videoBitrate!;
    }
    if (settings.audioBitrate != null) {
      result['b:a'] = settings.audioBitrate!;
    }
    if (settings.preset != null) {
      result['preset'] = settings.preset!;
    }

    return result;
  }
}

/// Export progress information
class ExportProgress {
  const ExportProgress({
    required this.progress,
    required this.phase,
    this.encodedFrames,
    this.estimatedTimeRemaining,
  });

  final double progress;
  final String phase;
  final int? encodedFrames;
  final Duration? estimatedTimeRemaining;
}

/// Settings for export operation
class ExportSettings {
  const ExportSettings({
    this.videoCodec,
    this.audioCodec,
    this.videoBitrate,
    this.audioBitrate,
    this.preset,
    this.preserveMetadata = true,
  });

  final String? videoCodec;
  final String? audioCodec;
  final String? videoBitrate;
  final String? audioBitrate;
  final String? preset;
  final bool preserveMetadata;
}

/// Exception thrown during export
class ExportException implements Exception {
  ExportException(this.message);

  final String message;

  @override
  String toString() => 'ExportException: $message';
}
