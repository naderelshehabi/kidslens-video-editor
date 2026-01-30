import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:kidslens_video_editor/native/resource_manager.dart';
import 'package:kidslens_video_editor/services/media_service.dart';

/// FFmpeg bindings - uses system FFmpeg command-line tool
/// 
/// Supports both bundled FFmpeg binaries (preferred) and system-installed FFmpeg.
/// Bundled binaries are located in native/ffmpeg/binaries/{platform}/ relative
/// to the application executable.
class FFmpegBindings extends NativeResource {
  bool _initialized = false;
  bool _initializationAttempted = false;
  String? _ffmpegPath;
  String? _ffprobePath;
  Duration? _lastProbedDuration;
  bool _usingBundledBinaries = false;

  /// Whether using bundled FFmpeg binaries (vs system-installed)
  bool get isUsingBundledBinaries => _usingBundledBinaries;

  /// The path to the FFmpeg executable
  String? get ffmpegPath => _ffmpegPath;

  /// Set FFmpeg path manually for testing
  @visibleForTesting
  void setFFmpegPathForTesting(String path) {
    _ffmpegPath = path;
    _initialized = true;
  }

  /// Initialize FFmpeg bindings by finding FFmpeg on the system
  /// 
  /// First checks for bundled binaries relative to the executable,
  /// then falls back to system-installed FFmpeg.
  Future<void> initialize() async {
    if (_initialized || _initializationAttempted) return;
    _initializationAttempted = true;

    try {
      // First, try to find bundled FFmpeg binaries
      final bundledPath = await _getBundledFFmpegPath();
      if (bundledPath != null) {
        _ffmpegPath = bundledPath;
        _ffprobePath = await _getBundledFFprobePath();
        _usingBundledBinaries = true;
        _initialized = true;
        debugPrint('Using bundled FFmpeg at: $_ffmpegPath');
        return;
      }

      // Fall back to system FFmpeg
      _ffmpegPath = await _findExecutable('ffmpeg');
      _ffprobePath = await _findExecutable('ffprobe');
      _initialized = _ffmpegPath != null;
      _usingBundledBinaries = false;
      
      if (_initialized) {
        debugPrint('FFmpeg found at: $_ffmpegPath');
      } else {
        debugPrint('FFmpeg not found on system');
      }
    } catch (e) {
      debugPrint('Error initializing FFmpeg: $e');
    }
  }

  /// Get the path to bundled FFmpeg binary if it exists
  /// 
  /// Bundled binaries are stored in:
  /// - Windows: {exe_dir}/data/flutter_assets/native/ffmpeg/binaries/windows-{arch}/ffmpeg.exe
  /// - macOS: {app_bundle}/Contents/Frameworks/native/ffmpeg/binaries/macos-universal/ffmpeg
  /// - Linux: {exe_dir}/data/flutter_assets/native/ffmpeg/binaries/linux-{arch}/ffmpeg
  /// 
  /// Also checks for binaries relative to the project root for development mode.
  Future<String?> _getBundledFFmpegPath() async {
    final paths = _getBundledBinaryPaths('ffmpeg');
    
    for (final path in paths) {
      final file = File(path);
      if (file.existsSync()) {
        // Verify the binary works
        try {
          final result = await Process.run(
            path,
            ['-version'],
          );
          if (result.exitCode == 0) {
            return path;
          }
        } catch (_) {
          continue;
        }
      }
    }
    
    return null;
  }

  /// Get the path to bundled FFprobe binary if it exists
  Future<String?> _getBundledFFprobePath() async {
    final paths = _getBundledBinaryPaths('ffprobe');
    
    for (final path in paths) {
      final file = File(path);
      if (file.existsSync()) {
        try {
          final result = await Process.run(
            path,
            ['-version'],
          );
          if (result.exitCode == 0) {
            return path;
          }
        } catch (_) {
          continue;
        }
      }
    }
    
    return null;
  }

  /// Get list of possible bundled binary paths for a given executable name
  List<String> _getBundledBinaryPaths(String execName) {
    final paths = <String>[];
    final exePath = Platform.resolvedExecutable;
    final exeDir = File(exePath).parent.path;
    
    if (Platform.isWindows) {
      final binaryName = '$execName.exe';
      final arch = _getWindowsArch();
      
      // Release mode: relative to executable
      paths
        ..add('$exeDir\\data\\flutter_assets\\native\\ffmpeg\\binaries\\windows-$arch\\$binaryName')
        ..add('$exeDir\\native\\ffmpeg\\binaries\\windows-$arch\\$binaryName');
      
      // Development mode: relative to project root
      // In debug, exeDir is build/windows/x64/runner/Debug or Release
      final projectRoot = _findProjectRoot(exeDir);
      if (projectRoot != null) {
        paths.add('$projectRoot\\native\\ffmpeg\\binaries\\windows-$arch\\$binaryName');
      }
    } else if (Platform.isMacOS) {
      final binaryName = execName;
      
      // Release mode: inside app bundle
      // Executable is at MyApp.app/Contents/MacOS/MyApp
      final contentsDir = File(exePath).parent.parent.path;
      paths
        ..add('$contentsDir/Frameworks/native/ffmpeg/binaries/macos-universal/$binaryName')
        ..add('$contentsDir/Resources/native/ffmpeg/binaries/macos-universal/$binaryName');
      
      // Development mode
      final projectRoot = _findProjectRoot(exeDir);
      if (projectRoot != null) {
        paths.add('$projectRoot/native/ffmpeg/binaries/macos-universal/$binaryName');
      }
    } else if (Platform.isLinux) {
      final binaryName = execName;
      final arch = _getLinuxArch();
      
      // Release mode: relative to executable
      paths
        ..add('$exeDir/data/flutter_assets/native/ffmpeg/binaries/linux-$arch/$binaryName')
        ..add('$exeDir/native/ffmpeg/binaries/linux-$arch/$binaryName')
        ..add('$exeDir/lib/native/ffmpeg/binaries/linux-$arch/$binaryName');
      
      // Development mode
      final projectRoot = _findProjectRoot(exeDir);
      if (projectRoot != null) {
        paths.add('$projectRoot/native/ffmpeg/binaries/linux-$arch/$binaryName');
      }
    }
    
    return paths;
  }

  /// Get Windows architecture string
  String _getWindowsArch() {
    final arch = Platform.environment['PROCESSOR_ARCHITECTURE'] ?? '';
    if (arch.toLowerCase().contains('arm')) {
      return 'arm64';
    }
    return 'x64';
  }

  /// Get Linux architecture string
  String _getLinuxArch() {
    try {
      final result = Process.runSync('uname', ['-m']);
      final arch = result.stdout.toString().trim();
      if (arch == 'aarch64' || arch == 'arm64') {
        return 'arm64';
      }
    } catch (_) {}
    return 'x64';
  }

  /// Find project root directory by looking for pubspec.yaml
  String? _findProjectRoot(String startDir) {
    var current = Directory(startDir);
    
    // Walk up the directory tree looking for pubspec.yaml
    for (var i = 0; i < 10; i++) {
      final pubspec = File('${current.path}${Platform.pathSeparator}pubspec.yaml');
      if (pubspec.existsSync()) {
        return current.path;
      }
      
      final parent = current.parent;
      if (parent.path == current.path) {
        break; // Reached root
      }
      current = parent;
    }
    
    return null;
  }

  /// Find an executable on the system PATH
  /// 
  /// This is called as a fallback when bundled binaries are not found.
  Future<String?> _findExecutable(String name) async {
    final possiblePaths = <String>[
      name, // In PATH
      if (Platform.isWindows) ...[
        '$name.exe',
        'C:\\ffmpeg\\bin\\$name.exe',
        'C:\\Program Files\\ffmpeg\\bin\\$name.exe',
        'C:\\Program Files (x86)\\ffmpeg\\bin\\$name.exe',
        // Common installation locations
        '${Platform.environment['LOCALAPPDATA']}\\Programs\\ffmpeg\\bin\\$name.exe',
        '${Platform.environment['USERPROFILE']}\\ffmpeg\\bin\\$name.exe',
      ],
      if (Platform.isMacOS) ...[
        '/usr/local/bin/$name',
        '/opt/homebrew/bin/$name',
        '/opt/local/bin/$name', // MacPorts
      ],
      if (Platform.isLinux) ...[
        '/usr/bin/$name',
        '/usr/local/bin/$name',
        '/snap/bin/$name', // Snap packages
        '${Platform.environment['HOME']}/.local/bin/$name',
      ],
    ];

    for (final execPath in possiblePaths) {
      try {
        final result = await Process.run(
          execPath,
          ['-version'],
        );
        if (result.exitCode == 0) {
          return execPath;
        }
      } catch (_) {
        continue;
      }
    }

    return null;
  }

  /// Check if FFmpeg is available
  bool get isAvailable => _ffmpegPath != null;

  /// Probe media file for metadata
  Future<MediaMetadata> probeMedia(String path) async {
    await _ensureInitialized();

    if (_ffprobePath != null) {
      try {
        final result = await Process.run(
          _ffprobePath!,
          [
            '-v', 'quiet',
            '-print_format', 'json',
            '-show_format',
            '-show_streams',
            path,
          ],
        );

        if (result.exitCode == 0) {
          final json = jsonDecode(result.stdout as String) as Map<String, dynamic>;
          return _parseProbeResult(json, path);
        }
      } catch (e) {
        debugPrint('Error probing media: $e');
      }
    }

    // Fallback to file info
    final file = File(path);
    final stat = file.statSync();

    return MediaMetadata(
      duration: const Duration(minutes: 5),
      fileSizeBytes: stat.size,
      resolution: const Resolution(width: 1920, height: 1080),
      frameRate: 30,
      videoCodec: 'h264',
      audioCodec: 'aac',
    );
  }

  MediaMetadata _parseProbeResult(Map<String, dynamic> json, String path) {
    final format = json['format'] as Map<String, dynamic>?;
    final streams = json['streams'] as List<dynamic>? ?? [];

    var duration = const Duration(minutes: 5);
    var width = 1920;
    var height = 1080;
    var frameRate = 30.0;
    var videoCodec = 'h264';
    var audioCodec = 'aac';
    var fileSize = 0;

    if (format != null) {
      final durationStr = format['duration'] as String?;
      if (durationStr != null) {
        final seconds = double.tryParse(durationStr) ?? 300.0;
        duration = Duration(milliseconds: (seconds * 1000).round());
      }
      fileSize = int.tryParse(format['size']?.toString() ?? '0') ?? 0;
    }

    for (final streamItem in streams) {
      final stream = streamItem as Map<String, dynamic>;
      final codecType = stream['codec_type'] as String?;
      if (codecType == 'video') {
        width = stream['width'] as int? ?? 1920;
        height = stream['height'] as int? ?? 1080;
        videoCodec = stream['codec_name'] as String? ?? 'h264';
        
        final frameRateStr = stream['r_frame_rate'] as String? ?? '30/1';
        final parts = frameRateStr.split('/');
        if (parts.length == 2) {
          final num = double.tryParse(parts[0]) ?? 30.0;
          final den = double.tryParse(parts[1]) ?? 1.0;
          if (den > 0) frameRate = num / den;
        }
      } else if (codecType == 'audio') {
        audioCodec = stream['codec_name'] as String? ?? 'aac';
      }
    }

    _lastProbedDuration = duration;

    return MediaMetadata(
      duration: duration,
      fileSizeBytes: fileSize,
      resolution: Resolution(width: width, height: height),
      frameRate: frameRate,
      videoCodec: videoCodec,
      audioCodec: audioCodec,
    );
  }

  /// Extract audio track from video file
  Future<String> extractAudio(String videoPath, String outputPath) async {
    await _ensureInitialized();

    if (_ffmpegPath == null) {
      throw FFmpegNotAvailableException();
    }

    final result = await Process.run(
      _ffmpegPath!,
      [
        '-i', videoPath,
        '-vn',
        '-acodec', 'pcm_s16le',
        '-y',
        outputPath,
      ],
    );

    if (result.exitCode != 0) {
      throw FFmpegException('Failed to extract audio: ${result.stderr}');
    }

    return outputPath;
  }

  /// Extract frames from video at specified FPS
  Stream<FrameData> extractFrames(
    String videoPath, {
    double fps = 2.0,
    int? startFrame,
    int? endFrame,
  }) async* {
    await _ensureInitialized();

    // Placeholder: yield dummy frames
    final metadata = await probeMedia(videoPath);
    final totalFrames = (metadata.duration.inSeconds * fps).ceil();

    for (var i = startFrame ?? 0; i < (endFrame ?? totalFrames); i++) {
      yield FrameData(
        frameNumber: i,
        timestamp: Duration(milliseconds: (i * 1000 / fps).round()),
        rgbData: List.filled(1920 * 1080 * 3, 0),
        width: 1920,
        height: 1080,
      );
    }
  }

  /// Generate thumbnail at specified position
  Future<String> generateThumbnail(
    String videoPath,
    String outputPath, {
    Duration? position,
    int width = 320,
    int height = 180,
  }) async {
    await _ensureInitialized();

    if (_ffmpegPath == null) {
      return outputPath;
    }

    final timestamp = position ?? Duration.zero;
    final timestampStr = _formatTimestamp(timestamp);

    final result = await Process.run(
      _ffmpegPath!,
      [
        '-ss', timestampStr,
        '-i', videoPath,
        '-vframes', '1',
        '-vf', 'scale=$width:$height',
        '-y',
        outputPath,
      ],
    );

    if (result.exitCode != 0) {
      debugPrint('Thumbnail generation failed: ${result.stderr}');
    }

    return outputPath;
  }

  /// Run filter complex for export - actually executes FFmpeg
  Stream<double> runFilterComplex({
    required String inputPath,
    required String outputPath,
    required String filterComplex,
    Map<String, String>? outputSettings,
    Duration? totalDuration,
  }) {
    // ignore: close_sinks - Controller is closed in _runFFmpegExport finally block
    final controller = StreamController<double>();
    
    _runFFmpegExport(
      inputPath: inputPath,
      outputPath: outputPath,
      filterComplex: filterComplex,
      outputSettings: outputSettings,
      totalDuration: totalDuration,
      controller: controller,
    );
    
    return controller.stream;
  }
  
  Future<void> _runFFmpegExport({
    required String inputPath,
    required String outputPath,
    required String filterComplex,
    required StreamController<double> controller,
    Map<String, String>? outputSettings,
    Duration? totalDuration,
  }) async {
    await _ensureInitialized();

    if (_ffmpegPath == null) {
      controller.addError(FFmpegNotAvailableException());
      await controller.close();
      return;
    }

    // Build FFmpeg command
    final args = <String>[
      '-i', inputPath,
      '-progress', 'pipe:1', // Output progress to stdout
      '-stats_period', '0.5', // Update every 0.5 seconds
    ];

    // Add filter complex if not empty
    if (filterComplex.isNotEmpty) {
      args.addAll(['-filter_complex', filterComplex]);
    }

    // Add output settings
    if (outputSettings != null) {
      for (final entry in outputSettings.entries) {
        args.addAll(['-${entry.key}', entry.value]);
      }
    }

    // Add output path with overwrite
    args.addAll(['-y', outputPath]);

    debugPrint('Running FFmpeg: $_ffmpegPath ${args.join(' ')}');

    // Get total duration for progress calculation
    var duration = totalDuration ?? _lastProbedDuration ?? const Duration(minutes: 5);
    
    // Try to get actual duration if not provided
    if (totalDuration == null && _lastProbedDuration == null) {
      try {
        final metadata = await probeMedia(inputPath);
        duration = metadata.duration;
      } catch (_) {}
    }

    final totalMicroseconds = duration.inMicroseconds.toDouble();

    try {
      // Start FFmpeg process
      final process = await Process.start(
        _ffmpegPath!,
        args,
      );

      var lastProgress = 0.0;
      final stderrBuffer = StringBuffer();

      // Parse progress from stdout (due to -progress pipe:1)
      process.stdout.transform(utf8.decoder).transform(const LineSplitter()).listen((line) {
        // Parse progress lines like "out_time_us=1234567" or "out_time=00:01:30.000000"
        if (line.startsWith('out_time_us=')) {
          final timeUs = int.tryParse(line.substring(12));
          if (timeUs != null && timeUs > 0 && totalMicroseconds > 0) {
            final progress = (timeUs / totalMicroseconds).clamp(0.0, 1.0);
            if (progress > lastProgress) {
              lastProgress = progress;
              controller.add(progress);
            }
          }
        } else if (line.startsWith('out_time=')) {
          final timeStr = line.substring(9);
          final timeDuration = _parseFFmpegTime(timeStr);
          if (timeDuration != null && timeDuration.inMicroseconds > 0 && totalMicroseconds > 0) {
            final progress = (timeDuration.inMicroseconds / totalMicroseconds).clamp(0.0, 1.0);
            if (progress > lastProgress) {
              lastProgress = progress;
              controller.add(progress);
            }
          }
        } else if (line == 'progress=end') {
          if (lastProgress < 1.0) {
            controller.add(1);
          }
        }
      });

      // Also parse stderr for additional progress info (FFmpeg writes stats there)
      process.stderr.transform(utf8.decoder).transform(const LineSplitter()).listen((line) {
        stderrBuffer.writeln(line);
        
        // Parse lines like "frame= 1234 fps= 30 ... time=00:01:30.00 ..."
        final timeMatch = RegExp(r'time=(\d{2}):(\d{2}):(\d{2})\.(\d{2})').firstMatch(line);
        if (timeMatch != null) {
          final hours = int.parse(timeMatch.group(1)!);
          final minutes = int.parse(timeMatch.group(2)!);
          final seconds = int.parse(timeMatch.group(3)!);
          final centiseconds = int.parse(timeMatch.group(4)!);
          
          final timeDuration = Duration(
            hours: hours,
            minutes: minutes,
            seconds: seconds,
            milliseconds: centiseconds * 10,
          );
          
          if (totalMicroseconds > 0) {
            final progress = (timeDuration.inMicroseconds / totalMicroseconds).clamp(0.0, 1.0);
            if (progress > lastProgress) {
              lastProgress = progress;
              controller.add(progress);
            }
          }
        }
      });

      // Wait for process to complete
      final exitCode = await process.exitCode;

      if (exitCode != 0) {
        // Check if output file was created despite error
        final outputFile = File(outputPath);
        if (!outputFile.existsSync()) {
          controller.addError(FFmpegException(
            'FFmpeg failed with exit code $exitCode.\n${stderrBuffer.toString().split('\n').take(10).join('\n')}',
          ),);
        } else {
          // File was created, consider it a success (some warnings may cause non-zero exit)
          if (lastProgress < 1.0) {
            controller.add(1);
          }
        }
      } else {
        if (lastProgress < 1.0) {
          controller.add(1);
        }
      }
    } catch (e) {
      controller.addError(FFmpegException('Failed to run FFmpeg: $e'));
    } finally {
      await controller.close();
    }
  }

  /// Parse FFmpeg time format (HH:MM:SS.microseconds)
  Duration? _parseFFmpegTime(String timeStr) {
    // Format: HH:MM:SS.FFFFFF or HH:MM:SS.FF
    final parts = timeStr.split(':');
    if (parts.length != 3) return null;

    final hours = int.tryParse(parts[0]) ?? 0;
    final minutes = int.tryParse(parts[1]) ?? 0;
    
    final secParts = parts[2].split('.');
    final seconds = int.tryParse(secParts[0]) ?? 0;
    var microseconds = 0;
    
    if (secParts.length > 1) {
      final fracStr = secParts[1].padRight(6, '0').substring(0, 6);
      microseconds = int.tryParse(fracStr) ?? 0;
    }

    return Duration(
      hours: hours,
      minutes: minutes,
      seconds: seconds,
      microseconds: microseconds,
    );
  }

  /// Format duration as FFmpeg timestamp
  String _formatTimestamp(Duration duration) {
    final hours = duration.inHours.toString().padLeft(2, '0');
    final minutes = (duration.inMinutes % 60).toString().padLeft(2, '0');
    final seconds = (duration.inSeconds % 60).toString().padLeft(2, '0');
    final millis = (duration.inMilliseconds % 1000).toString().padLeft(3, '0');
    return '$hours:$minutes:$seconds.$millis';
  }

  /// Detect scene changes in video
  Future<List<SceneChange>> detectSceneChanges(
    String videoPath, {
    double threshold = 0.4,
  }) async {
    await _ensureInitialized();

    if (_ffmpegPath == null) {
      return [];
    }

    // Use FFmpeg's select filter for scene detection
    final result = await Process.run(
      _ffmpegPath!,
      [
        '-i', videoPath,
        '-vf', "select='gt(scene,$threshold)',showinfo",
        '-f', 'null',
        '-',
      ],
    );

    final scenes = <SceneChange>[];
    final lines = (result.stderr as String).split('\n');

    for (final line in lines) {
      final match = RegExp(r'pts_time:(\d+\.?\d*)').firstMatch(line);
      if (match != null) {
        final time = double.tryParse(match.group(1)!) ?? 0.0;
        scenes.add(SceneChange(
          frameNumber: scenes.length,
          timestamp: Duration(milliseconds: (time * 1000).round()),
          score: threshold,
        ),);
      }
    }

    return scenes;
  }

  Future<void> _ensureInitialized() async {
    if (!_initializationAttempted) {
      await initialize();
    }
  }

  @override
  void releaseNative() {
    _ffmpegPath = null;
    _ffprobePath = null;
    _initialized = false;
    _initializationAttempted = false;
    _usingBundledBinaries = false;
  }
}

/// Scene change detection result
class SceneChange {
  SceneChange({
    required this.frameNumber,
    required this.timestamp,
    required this.score,
  });

  final int frameNumber;
  final Duration timestamp;
  final double score;
}

/// Exception thrown when FFmpeg is not available on the system
class FFmpegNotAvailableException implements Exception {
  @override
  String toString() => 'FFmpeg is not installed or not found in PATH. '
      'Please install FFmpeg and ensure it is accessible from the command line.\n'
      'Download FFmpeg from: https://ffmpeg.org/download.html';
}

/// Exception thrown when FFmpeg command fails
class FFmpegException implements Exception {
  FFmpegException(this.message);

  final String message;

  @override
  String toString() => 'FFmpegException: $message';
}

/// Exception thrown when FFmpeg initialization fails
class FFmpegInitializationException implements Exception {
  FFmpegInitializationException(this.message);

  final String message;

  @override
  String toString() => 'FFmpegInitializationException: $message';
}

/// Exception thrown when FFmpeg is not initialized
class FFmpegNotInitializedException implements Exception {
  @override
  String toString() => 'FFmpeg bindings not initialized. Call initialize() first.';
}
