// ignore_for_file: avoid_classes_with_only_static_members

import 'dart:io';

import 'package:kidslens_video_editor/core/constants/supported_formats.dart';
import 'package:path/path.dart' as path;

/// Utility functions for file operations
abstract final class FileUtils {
  /// Format a file size in bytes to a human-readable string
  ///
  /// Examples:
  /// - 512 → "512 B"
  /// - 1536 → "1.50 KB"
  /// - 1572864 → "1.50 MB"
  /// - 1610612736 → "1.50 GB"
  /// - 1649267441664 → "1.50 TB"
  static String formatFileSize(int bytes, {int decimals = 2}) {
    if (bytes < 0) {
      throw ArgumentError('Bytes cannot be negative: $bytes');
    }

    const units = ['B', 'KB', 'MB', 'GB', 'TB', 'PB'];
    const kilo = 1024;

    if (bytes == 0) {
      return '0 B';
    }

    // Find the appropriate unit
    var unitIndex = 0;
    var size = bytes.toDouble();

    while (size >= kilo && unitIndex < units.length - 1) {
      size /= kilo;
      unitIndex++;
    }

    // Format based on whether we need decimals
    if (unitIndex == 0) {
      // Bytes - no decimals
      return '${size.toInt()} ${units[unitIndex]}';
    } else {
      // Other units - show decimals
      final formatted = size.toStringAsFixed(decimals);
      // Remove trailing zeros after decimal point
      final cleaned = formatted.replaceAll(RegExp(r'\.?0+$'), '');
      return '$cleaned ${units[unitIndex]}';
    }
  }

  /// Format file size with explicit unit
  ///
  /// [bytes] - The size in bytes
  /// [unit] - The unit to display ('KB', 'MB', 'GB')
  static String formatFileSizeInUnit(int bytes, String unit,
      {int decimals = 2,}) {
    const divisors = <String, int>{
      'B': 1,
      'KB': 1024,
      'MB': 1024 * 1024,
      'GB': 1024 * 1024 * 1024,
      'TB': 1024 * 1024 * 1024 * 1024,
    };

    final divisor = divisors[unit.toUpperCase()];
    if (divisor == null) {
      throw ArgumentError('Unknown unit: $unit');
    }

    final size = bytes / divisor;
    if (unit.toUpperCase() == 'B') {
      return '${size.toInt()} $unit';
    }
    return '${size.toStringAsFixed(decimals)} $unit';
  }

  /// Parse a file size string back to bytes
  ///
  /// Examples:
  /// - "1.5 MB" → 1572864
  /// - "512 KB" → 524288
  /// - "1 GB" → 1073741824
  static int parseFileSize(String input) {
    final trimmed = input.trim().toUpperCase();

    final match = RegExp(r'^([\d.]+)\s*(B|KB|MB|GB|TB|PB)?$').firstMatch(trimmed);
    if (match == null) {
      throw FormatException('Invalid file size format: $input');
    }

    final valueStr = match.group(1)!;
    final unit = match.group(2) ?? 'B';

    final value = double.parse(valueStr);

    const multipliers = <String, int>{
      'B': 1,
      'KB': 1024,
      'MB': 1024 * 1024,
      'GB': 1024 * 1024 * 1024,
      'TB': 1024 * 1024 * 1024 * 1024,
      'PB': 1024 * 1024 * 1024 * 1024 * 1024,
    };

    return (value * multipliers[unit]!).round();
  }

  /// Get the file extension from a path (without the dot)
  ///
  /// Examples:
  /// - "/path/to/video.mp4" → "mp4"
  /// - "file.tar.gz" → "gz"
  /// - "noextension" → ""
  static String getFileExtension(String filePath) =>
      path.extension(filePath).isEmpty
          ? ''
          : path.extension(filePath).substring(1).toLowerCase();

  /// Get the file name without extension
  ///
  /// Examples:
  /// - "/path/to/video.mp4" → "video"
  /// - "file.tar.gz" → "file.tar"
  static String getFileNameWithoutExtension(String filePath) =>
      path.basenameWithoutExtension(filePath);

  /// Get the file name with extension
  ///
  /// Examples:
  /// - "/path/to/video.mp4" → "video.mp4"
  static String getFileName(String filePath) => path.basename(filePath);

  /// Get the directory containing a file
  ///
  /// Examples:
  /// - "/path/to/video.mp4" → "/path/to"
  static String getDirectory(String filePath) => path.dirname(filePath);

  /// Check if a path points to a video file
  ///
  /// Based on file extension matching supported video formats.
  static bool isVideoFile(String filePath) =>
      getFileExtension(filePath).isNotEmpty &&
      SupportedFormats.isVideoFormat(getFileExtension(filePath));

  /// Check if a path points to an audio file
  ///
  /// Based on file extension matching supported audio formats.
  static bool isAudioFile(String filePath) =>
      getFileExtension(filePath).isNotEmpty &&
      SupportedFormats.isAudioFormat(getFileExtension(filePath));

  /// Check if a path points to any supported media file
  static bool isMediaFile(String filePath) =>
      isVideoFile(filePath) || isAudioFile(filePath);

  /// Normalize a file path for the current platform
  static String normalizePath(String filePath) => path.normalize(filePath);

  /// Join path segments using the platform separator
  static String joinPath(String path1, String path2,
      [String? path3, String? path4,]) {
    if (path4 != null) {
      return path.join(path1, path2, path3, path4);
    }
    if (path3 != null) {
      return path.join(path1, path2, path3);
    }
    return path.join(path1, path2);
  }

  /// Check if a file exists
  static Future<bool> fileExists(String filePath) async =>
      File(filePath).existsSync();

  /// Check if a file exists (synchronous)
  static bool fileExistsSync(String filePath) => File(filePath).existsSync();

  /// Check if a directory exists
  static Future<bool> directoryExists(String dirPath) async =>
      Directory(dirPath).existsSync();

  /// Check if a directory exists (synchronous)
  static bool directoryExistsSync(String dirPath) =>
      Directory(dirPath).existsSync();

  /// Get file size in bytes
  static Future<int> getFileSize(String filePath) async {
    final file = File(filePath);
    if (file.existsSync()) {
      return file.length();
    }
    return 0;
  }

  /// Get file size in bytes (synchronous)
  static int getFileSizeSync(String filePath) {
    final file = File(filePath);
    if (file.existsSync()) {
      return file.lengthSync();
    }
    return 0;
  }

  /// Get file modification time
  static Future<DateTime?> getFileModifiedTime(String filePath) async {
    final file = File(filePath);
    if (file.existsSync()) {
      return file.lastModifiedSync();
    }
    return null;
  }

  /// Create a directory if it doesn't exist
  static Future<Directory> ensureDirectory(String dirPath) async {
    final dir = Directory(dirPath);
    if (!dir.existsSync()) {
      dir.createSync(recursive: true);
    }
    return dir;
  }

  /// Create a directory if it doesn't exist (synchronous)
  static Directory ensureDirectorySync(String dirPath) {
    final dir = Directory(dirPath);
    if (!dir.existsSync()) {
      dir.createSync(recursive: true);
    }
    return dir;
  }

  /// Delete a file if it exists
  static Future<void> deleteFileIfExists(String filePath) async {
    final file = File(filePath);
    if (file.existsSync()) {
      await file.delete();
    }
  }

  /// Copy a file to a new location
  static Future<File> copyFile(String sourcePath, String destPath) async {
    final sourceFile = File(sourcePath);
    // Ensure destination directory exists
    await ensureDirectory(getDirectory(destPath));
    return sourceFile.copy(destPath);
  }

  /// Move a file to a new location
  static Future<File> moveFile(String sourcePath, String destPath) async {
    final sourceFile = File(sourcePath);
    // Ensure destination directory exists
    await ensureDirectory(getDirectory(destPath));
    return sourceFile.rename(destPath);
  }

  /// Generate a unique file path by appending a number if the file exists
  ///
  /// Example: "video.mp4" → "video (1).mp4" → "video (2).mp4"
  static String generateUniquePath(String filePath) {
    final file = File(filePath);
    if (!file.existsSync()) {
      return filePath;
    }

    final dir = getDirectory(filePath);
    final nameWithoutExt = getFileNameWithoutExtension(filePath);
    final ext = getFileExtension(filePath);

    var counter = 1;
    String newPath;

    do {
      final newName = ext.isEmpty
          ? '$nameWithoutExt ($counter)'
          : '$nameWithoutExt ($counter).$ext';
      newPath = joinPath(dir, newName);
      counter++;
    } while (File(newPath).existsSync());

    return newPath;
  }

  /// Get available disk space in bytes
  ///
  /// Returns the available space on the drive containing the given path.
  /// Returns 0 if the space cannot be determined.
  static Future<int> getAvailableDiskSpace(String path) async {
    try {
      // This is platform-specific and may need platform channels
      // For now, return a large default value
      // TODO: Implement platform-specific disk space check
      return 10 * 1024 * 1024 * 1024; // 10 GB default
    } catch (_) {
      return 0;
    }
  }

  /// Calculate total size of files in a directory
  static Future<int> getDirectorySize(String dirPath) async {
    final dir = Directory(dirPath);
    if (!dir.existsSync()) {
      return 0;
    }

    var totalSize = 0;
    await for (final entity in dir.list(recursive: true)) {
      if (entity is File) {
        totalSize += await entity.length();
      }
    }

    return totalSize;
  }

  /// List files in a directory with optional extension filter
  static Future<List<String>> listFiles(
    String dirPath, {
    List<String>? extensions,
    bool recursive = false,
  }) async {
    final dir = Directory(dirPath);
    if (!dir.existsSync()) {
      return [];
    }

    final files = <String>[];
    await for (final entity in dir.list(recursive: recursive)) {
      if (entity is File) {
        if (extensions == null || extensions.isEmpty) {
          files.add(entity.path);
        } else {
          final ext = getFileExtension(entity.path);
          if (extensions.contains(ext)) {
            files.add(entity.path);
          }
        }
      }
    }

    return files;
  }

  /// Sanitize a file name by removing/replacing invalid characters
  // Characters invalid on Windows: \ / : * ? " < > |
  // Also remove control characters
  static String sanitizeFileName(String fileName) => fileName
      .replaceAll(RegExp(r'[\\/:*?"<>|]'), '_')
      .replaceAll(RegExp(r'[\x00-\x1F]'), '')
      .trim();
}
