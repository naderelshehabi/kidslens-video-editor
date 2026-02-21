import 'dart:async';
import 'dart:io';
import 'dart:math' as math;

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

/// Result of building a region filter chain (split→crop→effect→overlay)
class _RegionFilterResult {
  const _RegionFilterResult({
    required this.filterChain,
    required this.outputLabel,
  });

  /// The filter chain string (without the initial input label)
  final String filterChain;

  /// The output label of the last overlay (e.g. '[rv2]')
  final String outputLabel;
}

/// Service for exporting modified media files
class ExportService {
  ExportService({
    required this.ffmpeg,
    required this.mediaService,
  });

  final FFmpegBindings ffmpeg;
  final MediaService mediaService;

  /// Maximum filter complex length before switching to -filter_complex_script
  static const int _maxFilterComplexLength = 6000;

  /// Maximum number of region filter chains per export
  static const int _maxRegionChains = 100;

  /// Maps a [RemediationAction] to the corresponding [Modification].
  ///
  /// For region-level actions ([RemediationAction.blurRegion],
  /// [RemediationAction.pixelateRegion], [RemediationAction.blackBoxRegion]),
  /// a non-null [region] must be provided.
  ///
  /// The [startTime] and [endTime] parameters define the time range the
  /// modification applies to. They are not embedded in the returned
  /// [Modification] (which is time-agnostic) but are accepted here so callers
  /// can feed the result straight into timeline segment construction.
  static Modification modificationFromRemediationAction({
    required RemediationAction action,
    required Duration startTime,
    required Duration endTime,
    RegionBounds? region,
  }) {
    switch (action) {
      case RemediationAction.blurRegion:
        if (region == null) {
          throw ArgumentError('region is required for blurRegion action');
        }
        return Modification.videoRegionBlur(region: region);
      case RemediationAction.pixelateRegion:
        if (region == null) {
          throw ArgumentError('region is required for pixelateRegion action');
        }
        return Modification.videoRegionPixelate(region: region);
      case RemediationAction.blackBoxRegion:
        if (region == null) {
          throw ArgumentError('region is required for blackBoxRegion action');
        }
        return Modification.videoRegionBlackBox(region: region);
      case RemediationAction.blurFullFrame:
        return const Modification.videoBlur();
      case RemediationAction.cutScene:
        return const Modification.videoSkip();
      case RemediationAction.mute:
        return const Modification.audioMute();
      case RemediationAction.beep:
        return const Modification.audioBeep();
    }
  }

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

    // Probe video resolution for region-based modifications
    yield const ExportProgress(
      progress: 0.05,
      phase: 'Probing video metadata',
    );

    int? videoWidth;
    int? videoHeight;
    final hasRegionMods = videoMods.any((m) =>
        m.modification is VideoRegionBlur ||
        m.modification is VideoRegionPixelate ||
        m.modification is VideoRegionBlackBox);

    if (hasRegionMods) {
      try {
        final metadata = await ffmpeg.probeMedia(inputPath);
        videoWidth = metadata.resolution.width;
        videoHeight = metadata.resolution.height;
      } catch (e) {
        throw ExportException(
          'Cannot determine video resolution for region-based effects. '
          'Failed to probe media: $e',
        );
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
      videoWidth: videoWidth,
      videoHeight: videoHeight,
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

    // For long filter graphs, write to temp file to avoid command-line length limits
    File? filterScriptFile;
    try {
      String effectiveFilterComplex = filterComplex;
      if (filterComplex.length > _maxFilterComplexLength) {
        filterScriptFile = File(p.join(
          p.dirname(outputPath),
          '.kidslens_filter_${DateTime.now().millisecondsSinceEpoch}.txt',
        ));
        filterScriptFile.writeAsStringSync(filterComplex);
        // Empty string signals ffmpeg bindings to skip -filter_complex arg;
        // we'll pass -filter_complex_script via outputSettings instead
        effectiveFilterComplex = '';
      }

      final outputSettings = _buildOutputSettings(settings);

      // Add filter_complex_script if using temp file
      if (filterScriptFile != null) {
        outputSettings['filter_complex_script'] = filterScriptFile.path;
      }

      await for (final progress in ffmpeg.runFilterComplex(
        inputPath: inputPath,
        outputPath: outputPath,
        filterComplex: effectiveFilterComplex,
        outputSettings: outputSettings,
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
    } finally {
      // Clean up temp filter script file
      if (filterScriptFile != null && filterScriptFile.existsSync()) {
        try {
          filterScriptFile.deleteSync();
        } catch (_) {}
      }
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
    ExportSettings settings, {
    int? videoWidth,
    int? videoHeight,
  }) {
    final chains = <String>[];

    // Partition video mods: region mods vs linear mods vs drawbox mods
    final regionMods = <_TimedModification>[];
    final drawboxMods = <_TimedModification>[];
    final linearMods = <_TimedModification>[];

    for (final mod in videoMods) {
      if (mod.modification is VideoRegionBlur ||
          mod.modification is VideoRegionPixelate) {
        regionMods.add(mod);
      } else if (mod.modification is VideoRegionBlackBox) {
        drawboxMods.add(mod);
      } else {
        linearMods.add(mod);
      }
    }

    // ============ VIDEO CHAIN ============
    // Stage 1: Region blur/pixelate via split→crop→effect→overlay chain
    // Stage 2: Drawbox mods comma-chained (no split overhead)
    // Stage 3: Linear full-frame mods applied last
    // Subtitle burn-in appended at the very end

    String videoInput = '[0:v]';

    // Stage 1: Region mods (only if we have video dimensions)
    if (regionMods.isNotEmpty && videoWidth != null && videoHeight != null) {
      final regionChain = _buildRegionFilterChain(
        regionMods,
        videoWidth,
        videoHeight,
      );
      if (regionChain != null) {
        chains.add('$videoInput${regionChain.filterChain}');
        videoInput = regionChain.outputLabel;
      }
    }

    // Stages 2+3 + subtitle burn-in: comma-chainable filters on the last
    // video output (either [0:v] or the region chain output label)
    final postRegionFilters = <String>[];

    // Stage 2: Drawbox mods
    if (drawboxMods.isNotEmpty && videoWidth != null && videoHeight != null) {
      for (final mod in drawboxMods) {
        final m = mod.modification as VideoRegionBlackBox;
        final enable = _buildEnableExpression(mod.start, mod.end);
        final px = (m.region.x * videoWidth).round();
        final py = (m.region.y * videoHeight).round();
        final pw = (m.region.width * videoWidth).round();
        final ph = (m.region.height * videoHeight).round();
        final color = _hexToFFmpegColor(m.color, m.opacity);
        postRegionFilters.add(
          "drawbox=x=$px:y=$py:w=$pw:h=$ph:c=$color:t=fill:enable='$enable'",
        );
      }
    }

    // Stage 3: Linear full-frame mods
    for (final mod in linearMods) {
      final enable = _buildEnableExpression(mod.start, mod.end);
      final filter = _videoModToFilter(mod.modification, enable);
      if (filter.isNotEmpty) {
        postRegionFilters.add(filter);
      }
    }

    // ============ SUBTITLE BURN-IN ============
    if (settings.subtitleMode == SubtitleExportMode.burnIn &&
        settings.subtitleFilePath != null) {
      // FFmpeg subtitles filter requires forward slashes and escaped colons
      final escapedPath = settings.subtitleFilePath!
          .replaceAll(r'\', '/')
          .replaceAll(':', r'\:');
      postRegionFilters.add("subtitles='$escapedPath'");
    }

    if (postRegionFilters.isNotEmpty) {
      chains.add('$videoInput${postRegionFilters.join(',')}');
    }

    // ============ AUDIO CHAIN ============
    // Complex graph with mixing for overlays (Beep, Replace)
    
    // 1. Separate modifications
    final baseFilters = <String>[];
    final overlays = <String>[];
    var overlayCount = 0;

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
            'aevalsrc=sin($frequency*2*PI*t):d=$durationSec,'
            'volume=$volume,'
            'adelay=$startMs|$startMs[out_$label]'
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
            'atrim=duration=$durationSec,'
            'volume=$volume,'
            'adelay=$startMs|$startMs[out_$label]'
          );
          
        default:
          // Ignore unrelated
      }
    }

    // 2. Build Audio Graph
    
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

      // 3. Mix
      final mixInputs = StringBuffer()..write('[a_base]');
      for (final overlay in overlays) {
        // Extract label from end of string: [out_X]
        final match = RegExp(r'\[(.*?)\]$').firstMatch(overlay);
        if (match != null) {
          mixInputs.write('[${match.group(1)}]');
        }
      }

      final audioGraphParts = <String>[
        baseExpression,
        // 2. Overlays
        ...overlays,
        // 3. Mix
        // duration=first ensures output matches base track length
        '${mixInputs}amix=inputs=${overlays.length + 1}:duration=first:dropout_transition=0',
      ];
      
      chains.add(audioGraphParts.join(';'));
    } else if (baseFilters.isNotEmpty) {
      // Simple linear chain
      chains.add('[0:a]${baseFilters.join(',')}');
    }

    return chains.join(';');
  }

  String _buildEnableExpression(Duration start, Duration end) =>
      'between(t,${start.inMilliseconds / 1000.0},${end.inMilliseconds / 1000.0})';

  /// Build region filter chain for blur/pixelate region mods.
  ///
  /// Generates a split→crop→effect→overlay chain per region mod.
  /// Each region's overlay output feeds the next region's split input.
  ///
  /// Example for 2 regions:
  /// ```
  /// split=2[base0][c0];
  /// [c0]crop=200:150:100:50,gblur=sigma=30[b0];
  /// [base0][b0]overlay=x=100:y=50:enable='between(t,2.0,5.0)'[rv0];
  /// [rv0]split=2[base1][c1];
  /// [c1]crop=300:200:400:100,gblur=sigma=30[b1];
  /// [base1][b1]overlay=x=400:y=100:enable='between(t,1.0,4.0)'
  /// ```
  _RegionFilterResult? _buildRegionFilterChain(
    List<_TimedModification> regionMods,
    int videoWidth,
    int videoHeight,
  ) {
    if (regionMods.isEmpty) return null;

    // Cap region chains to prevent excessively long filter graphs
    final effectiveMods = regionMods.length > _maxRegionChains
        ? regionMods.sublist(0, _maxRegionChains)
        : regionMods;

    final parts = <String>[];
    String? lastOutputLabel;

    for (var i = 0; i < effectiveMods.length; i++) {
      final mod = effectiveMods[i];
      final enable = _buildEnableExpression(mod.start, mod.end);

      // Extract region bounds from the modification
      final RegionBounds region;
      final bool isPixelate;
      int blurIntensity = 50;
      int pixelateBlockSize = 10;

      switch (mod.modification) {
        case VideoRegionBlur(:final intensity, region: final r):
          region = r;
          blurIntensity = intensity;
          isPixelate = false;
        case VideoRegionPixelate(:final blockSize, region: final r):
          region = r;
          pixelateBlockSize = blockSize;
          isPixelate = true;
        default:
          continue; // Skip non-region blur/pixelate mods
      }

      // Compute pixel coordinates from normalized region bounds
      final px = (region.x * videoWidth).round();
      final py = (region.y * videoHeight).round();
      final pw = (region.width * videoWidth).round();
      final ph = (region.height * videoHeight).round();

      // Clamp to video bounds
      final cropX = math.max(0, math.min(px, videoWidth - 1));
      final cropY = math.max(0, math.min(py, videoHeight - 1));
      final cropW = math.max(1, math.min(pw, videoWidth - cropX));
      final cropH = math.max(1, math.min(ph, videoHeight - cropY));

      // Build effect filter using clamped dimensions
      final String effectFilter;
      if (isPixelate) {
        // Pixelate: scale down then back up to exact clamped crop size
        final downW = math.max(1, cropW ~/ pixelateBlockSize);
        final downH = math.max(1, cropH ~/ pixelateBlockSize);
        effectFilter = 'scale=$downW:$downH,scale=$cropW:$cropH:flags=neighbor';
      } else {
        effectFilter = 'gblur=sigma=${_intensityToBlurSigma(blurIntensity)}';
      }

      final isLast = i == effectiveMods.length - 1;

      // The input for this region: either [0:v] implicit or last output label
      // Note: the first region's input is handled by the caller prepending videoInput
      if (i == 0) {
        // First region: caller already prepended the video input label
        // split=2[base0][c0];[c0]crop...effect[b0];[base0][b0]overlay...[rv0]
        parts.add('split=2[base0][c0]');
        parts.add('[c0]crop=$cropW:$cropH:$cropX:$cropY,$effectFilter[b0]');
        if (isLast) {
          parts.add("[base0][b0]overlay=x=$cropX:y=$cropY:enable='$enable'");
        } else {
          parts.add("[base0][b0]overlay=x=$cropX:y=$cropY:enable='$enable'[rv0]");
          lastOutputLabel = '[rv0]';
        }
      } else {
        // Subsequent regions chain from previous output
        parts.add('${lastOutputLabel}split=2[base$i][c$i]');
        parts.add('[c$i]crop=$cropW:$cropH:$cropX:$cropY,$effectFilter[b$i]');
        if (isLast) {
          parts.add("[base$i][b$i]overlay=x=$cropX:y=$cropY:enable='$enable'");
        } else {
          parts.add("[base$i][b$i]overlay=x=$cropX:y=$cropY:enable='$enable'[rv$i]");
          lastOutputLabel = '[rv$i]';
        }
      }
    }

    if (parts.isEmpty) return null;

    // Always label the last output so the caller can reference it
    // for subsequent stages (drawbox, linear, subtitle burn-in).
    final lastIdx = effectiveMods.length - 1;
    if (parts.isNotEmpty) {
      final lastPart = parts.last;
      if (!lastPart.endsWith(']')) {
        parts[parts.length - 1] = '$lastPart[rv$lastIdx]';
      }
    }

    return _RegionFilterResult(
      filterChain: parts.join(';'),
      outputLabel: '[rv$lastIdx]',
    );
  }

  String _videoModToFilter(Modification mod, String enable) => switch (mod) {
      VideoBlur(:final intensity) =>
        "gblur=sigma=${_intensityToBlurSigma(intensity)}:enable='$enable'",
      VideoPixelate(:final blockSize) =>
        "scale=iw/$blockSize:ih/$blockSize:enable='$enable',"
            "scale=iw*$blockSize:ih*$blockSize:flags=neighbor:enable='$enable'",
      VideoBlackBox(:final color, :final opacity) =>
        "drawbox=x=0:y=0:w=iw:h=ih:c=${_hexToFFmpegColor(color, opacity)}:t=fill:enable='$enable'",
      VideoSkip() => '',
      // Region mods handled separately via split→crop→effect→overlay chain
      VideoRegionBlur() => '',
      VideoRegionPixelate() => '',
      VideoRegionBlackBox() => '',
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

/// How subtitles should be included in the export
enum SubtitleExportMode {
  /// No subtitle embedding in video stream
  none,
  /// Burn subtitles permanently into the video pixels
  burnIn,
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
    this.subtitleMode = SubtitleExportMode.none,
    this.subtitleFilePath,
  });

  final String? videoCodec;
  final String? audioCodec;
  final String? videoBitrate;
  final String? audioBitrate;
  final String? preset;
  final bool preserveMetadata;

  /// How subtitles should be embedded in the video
  final SubtitleExportMode subtitleMode;

  /// Path to subtitle file for burn-in. Required when [subtitleMode] is [SubtitleExportMode.burnIn].
  final String? subtitleFilePath;
}

/// Exception thrown during export
class ExportException implements Exception {
  ExportException(this.message);

  final String message;

  @override
  String toString() => 'ExportException: $message';
}
