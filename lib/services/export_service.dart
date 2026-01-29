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
    final chains = <String>[];
    
    // ============ VIDEO CHAIN ============
    // Linear chain: [0:v] -> filter1 -> filter2...
    if (videoMods.isNotEmpty) {
      final filters = <String>[];
      for (final mod in videoMods) {
        final enable = _buildEnableExpression(mod.start, mod.end);
        final filter = _videoModToFilter(mod.modification, enable);
        if (filter.isNotEmpty) {
          filters.add(filter);
        }
      }
      
      if (filters.isNotEmpty) {
        // [0:v]filter1,filter2
        // We do not label the output to let generic FFmpeg mapping pick it up
        chains.add('[0:v]${filters.join(',')}');
      }
    }

    // ============ AUDIO CHAIN ============
    // Complex graph with mixing for overlays (Beep, Replace)
    
    // 1. Separate modifications
    final baseFilters = <String>[];
    final overlays = <String>[];
    int overlayCount = 0;

    for (final mod in audioMods) {
      final enable = _buildEnableExpression(mod.start, mod.end);
      
      switch (mod.modification) {
        case AudioMute():
          baseFilters.add("volume=enable='$enable':volume=0");
          
        case AudioBeep(:final frequency, :final volume):
          // Mute original track during beep
          baseFilters.add("volume=enable='$enable':volume=0");
          
          overlayCount++;
          final label = 'beep_$overlayCount';
          final durationSec = mod.duration.inMilliseconds / 1000.0;
          final startMs = mod.start.inMilliseconds;
          
          // Generate beep source
          // aevalsrc -> vol -> adelay -> [label]
          overlays.add(
            "aevalsrc=sin($frequency*2*PI*t):d=$durationSec,"
            "volume=$volume,"
            "adelay=$startMs|$startMs[out_$label]"
          );
          
        case AudioReplace(:final audioPath, :final volume, :final loop):
          // Mute original track
          baseFilters.add("volume=enable='$enable':volume=0");
          
          overlayCount++;
          final label = 'replace_$overlayCount';
          // Escape path for FFmpeg string
          final escapedPath = audioPath.replaceAll("'", "'\\''").replaceAll(':', '\\:');
          final durationSec = mod.duration.inMilliseconds / 1000.0;
          final startMs = mod.start.inMilliseconds;
          final loopVal = loop ? 0 : 1;
          
          // Generate replacement source
          // amovie -> atrim -> vol -> adelay -> [label]
          overlays.add(
            "amovie='$escapedPath':loop=$loopVal,"
            "atrim=duration=$durationSec,"
            "volume=$volume,"
            "adelay=$startMs|$startMs[out_$label]"
          );
          
        default:
          // Ignore unrelated
      }
    }

    // 2. Build Audio Graph
    if (overlays.isEmpty) {
      // Linear chain only
      if (baseFilters.isNotEmpty) {
        chains.add('[0:a]${baseFilters.join(',')}');
      }
    } else {
      // Complex mix
      final mixParts = <String>[];
      
      // Part A: Base Chain
      // [0:a]filters...[a_base]
      var baseChain = '[0:a]';
      if (baseFilters.isNotEmpty) {
        baseChain += baseFilters.join(',');
      } else {
        baseChain += 'anull';
      }
      baseChain += '[a_base]';
      mixParts.add(baseChain);
      
      // Part B: Overlays definitions
      mixParts.addAll(overlays);
      
      // Part C: Mixing
      // [a_base][out_beep_1]...amix...
      final mixCmd = StringBuffer();
      mixCmd.write('[a_base]');
      for (int i = 1; i <= overlayCount; i++) {
        // Find which type of label was used. 
        // Logic above uses 'beep_$i' or 'replace_$i' BUT overlayCount increments globally.
        // Wait, I need to reconstruct the labels exactly matching generation order.
        // The generation loop populates `overlays` strings which contain `[out_beep_1]` etc.
        // I should have stored the labels separately to be sure.
        // Let's refactor loop slightly to store labels.
      }
      // REFACTORING INSIDE TO FIX LABEL LOGIC
      // ... (See implementation below) ...
    }
    
    // RE-IMPLEMENTING AUDIO LOGIC TO BE CLEANER
    final audioGraphParts = <String>[];
    
    // If we have overlays, we need a base label and mix
    if (overlays.isNotEmpty) {
      // 1. Base Chain
      var baseExpression = '[0:a]';
      if (baseFilters.isNotEmpty) {
        baseExpression += baseFilters.join(',');
      } else {
        baseExpression += 'anull';
      }
      baseExpression += '[a_base]';
      audioGraphParts.add(baseExpression);
      
      // 2. Overlays
      audioGraphParts.addAll(overlays);
      
      // 3. Mix
      final mixInputs = StringBuffer();
      mixInputs.write('[a_base]');
      for (final overlay in overlays) {
        // Extract label from end of string: [out_X]
        final match = RegExp(r'\[(.*?)\]$').firstMatch(overlay);
        if (match != null) {
          mixInputs.write('[${match.group(1)}]');
        }
      }
      // duration=first ensures output matches base track length
      audioGraphParts.add('${mixInputs}amix=inputs=${overlays.length + 1}:duration=first:dropout_transition=0');
      
      chains.add(audioGraphParts.join(';'));
    } else if (baseFilters.isNotEmpty) {
      // Simple linear chain
      chains.add('[0:a]${baseFilters.join(',')}');
    }

    return chains.join(';');
  }

  String _buildEnableExpression(Duration start, Duration end) =>
      'between(t,${start.inMilliseconds / 1000.0},${end.inMilliseconds / 1000.0})';

  String _videoModToFilter(Modification mod, String enable) => switch (mod) {
      VideoBlur(:final intensity) =>
        "gblur=sigma=${_intensityToBlurSigma(intensity)}:enable='$enable'",
      VideoPixelate(:final blockSize) =>
        "scale=iw/$blockSize:ih/$blockSize:enable='$enable',"
            "scale=iw*$blockSize:ih*$blockSize:flags=neighbor:enable='$enable'",
      VideoBlackBox(:final color, :final opacity) =>
        "drawbox=x=0:y=0:w=iw:h=ih:c=${_hexToFFmpegColor(color, opacity)}:t=fill:enable='$enable'",
      VideoSkip() => '',
      // Audio mods ignored
      AudioMute() => '',
      AudioBeep() => '',
      AudioReplace() => '',
  };

  // Removed _audioModToFilter as logic is now embedded in _buildFilterComplex

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
