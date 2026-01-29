import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';

/// Service for extracting video thumbnails
class ThumbnailService {
  final Map<String, List<Uint8List>> _cache = {};
  final Map<String, Completer<List<Uint8List>>> _pendingExtractions = {};

  /// Extract thumbnails from a video file at regular intervals
  /// Returns a list of thumbnail images as Uint8List (PNG bytes)
  Future<List<Uint8List>> extractThumbnails({
    required String videoPath,
    required Duration duration,
    required int count,
    int width = 160,
    int height = 90,
  }) async {
    final cacheKey = '$videoPath:$count';
    
    // Return cached thumbnails if available
    if (_cache.containsKey(cacheKey)) {
      return _cache[cacheKey]!;
    }

    // Check if extraction is already in progress
    if (_pendingExtractions.containsKey(cacheKey)) {
      return _pendingExtractions[cacheKey]!.future;
    }

    final completer = Completer<List<Uint8List>>();
    _pendingExtractions[cacheKey] = completer;

    try {
      final thumbnails = await _extractThumbnailsWithFFmpeg(
        videoPath: videoPath,
        duration: duration,
        count: count,
        width: width,
        height: height,
      );
      
      _cache[cacheKey] = thumbnails;
      completer.complete(thumbnails);
      return thumbnails;
    } catch (e) {
      debugPrint('Error extracting thumbnails: $e');
      // Return placeholder thumbnails on error
      final placeholders = _generatePlaceholderThumbnails(count, width, height);
      completer.complete(placeholders);
      return placeholders;
    } finally {
      _pendingExtractions.remove(cacheKey);
    }
  }

  Future<List<Uint8List>> _extractThumbnailsWithFFmpeg({
    required String videoPath,
    required Duration duration,
    required int count,
    required int width,
    required int height,
  }) async {
    // Get temp directory for thumbnail output
    final tempDir = await getTemporaryDirectory();
    final thumbnailDir = Directory(path.join(tempDir.path, 'thumbnails'));
    await thumbnailDir.create(recursive: true);

    final intervalSeconds = duration.inSeconds / count;
    final thumbnails = <Uint8List>[];

    // Try to use system FFmpeg
    final ffmpegPath = await _findFFmpeg();
    if (ffmpegPath == null) {
      return _generatePlaceholderThumbnails(count, width, height);
    }

    for (var i = 0; i < count; i++) {
      final timestamp = (i * intervalSeconds).toStringAsFixed(2);
      final outputPath = path.join(thumbnailDir.path, 'thumb_$i.png');

      try {
        // Run FFmpeg to extract frame
        final result = await Process.run(
          ffmpegPath,
          [
            '-ss', timestamp,
            '-i', videoPath,
            '-vframes', '1',
            '-vf', 'scale=$width:$height',
            '-y',
            outputPath,
          ],
          runInShell: Platform.isWindows,
        );

        if (result.exitCode == 0) {
          final file = File(outputPath);
          if (await file.exists()) {
            final bytes = await file.readAsBytes();
            thumbnails.add(bytes);
            await file.delete(); // Clean up
            continue;
          }
        }
      } catch (e) {
        debugPrint('Error extracting frame at $timestamp: $e');
      }

      // Add placeholder for failed extraction
      thumbnails.add(await _generatePlaceholderThumbnail(width, height, i));
    }

    // Clean up temp directory
    try {
      await thumbnailDir.delete(recursive: true);
    } catch (_) {}

    return thumbnails;
  }

  Future<String?> _findFFmpeg() async {
    // Check common FFmpeg locations
    final possiblePaths = <String>[
      'ffmpeg', // In PATH
      if (Platform.isWindows) ...[
        r'C:\ffmpeg\bin\ffmpeg.exe',
        r'C:\Program Files\ffmpeg\bin\ffmpeg.exe',
        r'C:\Program Files (x86)\ffmpeg\bin\ffmpeg.exe',
      ],
      if (Platform.isMacOS) ...[
        '/usr/local/bin/ffmpeg',
        '/opt/homebrew/bin/ffmpeg',
      ],
      if (Platform.isLinux) ...[
        '/usr/bin/ffmpeg',
        '/usr/local/bin/ffmpeg',
      ],
    ];

    for (final ffmpegPath in possiblePaths) {
      try {
        final result = await Process.run(
          ffmpegPath,
          ['-version'],
          runInShell: Platform.isWindows,
        );
        if (result.exitCode == 0) {
          return ffmpegPath;
        }
      } catch (_) {
        continue;
      }
    }

    return null;
  }

  List<Uint8List> _generatePlaceholderThumbnails(int count, int width, int height) {
    // Generate simple placeholder thumbnails synchronously
    return List.generate(count, (i) => _generatePlaceholderSync(width, height, i));
  }

  Uint8List _generatePlaceholderSync(int width, int height, int index) {
    // Create a simple colored placeholder
    // This is a minimal PNG-like representation
    final pixels = Uint8List(width * height * 4);
    final hue = (index * 30) % 360;
    final r = _hueToRgb(hue);
    final g = _hueToRgb(hue + 120);
    final b = _hueToRgb(hue + 240);
    
    for (var i = 0; i < pixels.length; i += 4) {
      pixels[i] = r;
      pixels[i + 1] = g;
      pixels[i + 2] = b;
      pixels[i + 3] = 255;
    }
    
    return pixels;
  }

  int _hueToRgb(int hue) {
    hue = hue % 360;
    if (hue < 60) return ((hue / 60) * 128 + 64).toInt();
    if (hue < 180) return 192;
    if (hue < 240) return (((240 - hue) / 60) * 128 + 64).toInt();
    return 64;
  }

  Future<Uint8List> _generatePlaceholderThumbnail(int width, int height, int index) async {
    return _generatePlaceholderSync(width, height, index);
  }

  /// Clear cached thumbnails
  void clearCache() {
    _cache.clear();
  }

  /// Clear cache for a specific video
  void clearCacheForVideo(String videoPath) {
    _cache.removeWhere((key, _) => key.startsWith(videoPath));
  }
}
