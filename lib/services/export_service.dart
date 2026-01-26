import 'dart:async';
import 'dart:io';

import 'package:path/path.dart' as p;

import 'package:kidslens_video_editor/data/models/models.dart';
import 'package:kidslens_video_editor/native/bindings/ffmpeg_bindings.dart';
import 'package:kidslens_video_editor/services/media_service.dart';

/// Holds a modification along with its time range from the segment
class _TimedModification {
  final Modification modification;
  final Duration start;
  final Duration end;

  const _TimedModification({
    required this.modification,
    required this.start,
    required this.end,
  });

  Duration get duration => end - start;
}

/// Service for exporting modified media files
class ExportService {
  final FFmpegBindings ffmpeg;
  final MediaService mediaService;

  ExportService({
    required this.ffmpeg,
    required this.mediaService,
  });

  /// Export media with applied modifications
  Stream<ExportProgress> export({
    required String inputPath,
    required String outputPath,
    required UnifiedTimeline timeline,
    ExportSettings settings = const ExportSettings(),
  }) async* {
    yield const ExportProgress(
      progress: 0.0,
      phase: 'Initializing export',
    );

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
    if (!await outputDir.exists()) {
      await outputDir.create(recursive: true);
    }

    // Run FFmpeg export
    yield const ExportProgress(
      progress: 0.2,
      phase: 'Processing media',
    );

    await for (final progress in ffmpeg.runFilterComplex(
      inputPath: inputPath,
      outputPath: outputPath,
      filterComplex: filterComplex,
      outputSettings: _buildOutputSettings(settings),
    )) {
      yield ExportProgress(
        progress: 0.2 + (progress * 0.75),
        phase: 'Encoding',
        encodedFrames: progress.toInt(),
      );
    }

    // Verify output
    yield const ExportProgress(
      progress: 0.95,
      phase: 'Verifying output',
    );

    final outputFile = File(outputPath);
    if (!await outputFile.exists()) {
      throw ExportException('Output file was not created');
    }

    yield const ExportProgress(
      progress: 1.0,
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

  String _buildEnableExpression(Duration start, Duration end) {
    final startSec = start.inMilliseconds / 1000.0;
    final endSec = end.inMilliseconds / 1000.0;
    return "between(t,$startSec,$endSec)";
  }

  String _audioModToFilter(
    Modification mod,
    String enable,
    _TimedModification timedMod,
  ) {
    return switch (mod) {
      AudioMute() => "volume=enable='$enable':volume=0",
      AudioBeep(:final frequency) =>
        "aevalsrc=sin($frequency*2*PI*t):d=${timedMod.duration.inMilliseconds / 1000.0}",
      AudioReplace(:final audioPath, :final volume) =>
        "amovie=$audioPath,volume=$volume",
      // Video modifications don't apply to audio track
      VideoBlur() => '',
      VideoPixelate() => '',
      VideoBlackBox() => '',
      VideoSkip() => '',
    };
  }

  String _videoModToFilter(Modification mod, String enable) {
    return switch (mod) {
      VideoBlur(:final intensity) => () {
          final sigma = _intensityToBlurSigma(intensity);
          return "gblur=sigma=$sigma:enable='$enable'";
        }(),
      VideoPixelate(:final blockSize) => () {
          // Pixelation is achieved by scaling down then back up with nearest neighbor
          return "scale=iw/$blockSize:ih/$blockSize:enable='$enable',"
              "scale=iw*$blockSize:ih*$blockSize:flags=neighbor:enable='$enable'";
        }(),
      VideoBlackBox(:final color, :final opacity) => () {
          // Convert hex color and apply opacity
          final ffmpegColor = _hexToFFmpegColor(color, opacity);
          return "drawbox=x=0:y=0:w=iw:h=ih:c=$ffmpegColor:t=fill:enable='$enable'";
        }(),
      VideoSkip() =>
        // Skip segments are handled differently - they're cut from the timeline
        '',
      // Audio modifications don't apply to video track
      AudioMute() => '',
      AudioBeep() => '',
      AudioReplace() => '',
    };
  }

  /// Convert blur intensity (1-100) to FFmpeg gblur sigma value
  int _intensityToBlurSigma(int intensity) {
    // Map intensity 1-100 to sigma 5-50
    return 5 + ((intensity - 1) * 45 ~/ 99);
  }

  /// Convert hex color and opacity to FFmpeg color format
  String _hexToFFmpegColor(String hexColor, double opacity) {
    // Remove # prefix if present
    var hex = hexColor.startsWith('#') ? hexColor.substring(1) : hexColor;

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
  final double progress;
  final String phase;
  final int? encodedFrames;
  final Duration? estimatedTimeRemaining;

  const ExportProgress({
    required this.progress,
    required this.phase,
    this.encodedFrames,
    this.estimatedTimeRemaining,
  });
}

/// Settings for export operation
class ExportSettings {
  final String? videoCodec;
  final String? audioCodec;
  final String? videoBitrate;
  final String? audioBitrate;
  final String? preset;
  final bool preserveMetadata;

  const ExportSettings({
    this.videoCodec,
    this.audioCodec,
    this.videoBitrate,
    this.audioBitrate,
    this.preset,
    this.preserveMetadata = true,
  });
}

/// Exception thrown during export
class ExportException implements Exception {
  final String message;
  ExportException(this.message);

  @override
  String toString() => 'ExportException: $message';
}
