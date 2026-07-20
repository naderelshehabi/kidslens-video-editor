// ignore_for_file: avoid_classes_with_only_static_members

/// Utility functions for Duration formatting and parsing
abstract final class DurationUtils {
  /// Standard frame rates for timecode conversion
  static const double fps24 = 24;
  static const double fps25 = 25;
  static const double fps30 = 30;
  static const double fps60 = 60;

  /// Format a Duration as HH:MM:SS.mmm
  ///
  /// Example: Duration(hours: 1, minutes: 23, seconds: 45, milliseconds: 678)
  /// returns "01:23:45.678"
  static String formatDuration(Duration duration) {
    final isNegative = duration.isNegative;
    final absolute = duration.abs();

    final hours = absolute.inHours;
    final minutes = absolute.inMinutes.remainder(60);
    final seconds = absolute.inSeconds.remainder(60);
    final milliseconds = absolute.inMilliseconds.remainder(1000);

    final formatted = '${hours.toString().padLeft(2, '0')}:'
        '${minutes.toString().padLeft(2, '0')}:'
        '${seconds.toString().padLeft(2, '0')}.'
        '${milliseconds.toString().padLeft(3, '0')}';

    return isNegative ? '-$formatted' : formatted;
  }

  /// Format a Duration as HH:MM:SS (without milliseconds)
  ///
  /// Example: Duration(hours: 1, minutes: 23, seconds: 45)
  /// returns "01:23:45"
  static String formatDurationShort(Duration duration) {
    final isNegative = duration.isNegative;
    final absolute = duration.abs();

    final hours = absolute.inHours;
    final minutes = absolute.inMinutes.remainder(60);
    final seconds = absolute.inSeconds.remainder(60);

    final formatted = '${hours.toString().padLeft(2, '0')}:'
        '${minutes.toString().padLeft(2, '0')}:'
        '${seconds.toString().padLeft(2, '0')}';

    return isNegative ? '-$formatted' : formatted;
  }

  /// Format a Duration as professional timecode HH:MM:SS:FF
  ///
  /// [duration] - The duration to format
  /// [fps] - Frames per second (default: 24)
  ///
  /// Example: Duration(hours: 1, minutes: 23, seconds: 45, milliseconds: 500)
  /// at 24fps returns "01:23:45:12"
  static String formatTimecode(Duration duration, {double fps = fps24}) {
    final isNegative = duration.isNegative;
    final absolute = duration.abs();

    final totalMilliseconds = absolute.inMilliseconds;
    final totalSeconds = totalMilliseconds ~/ 1000;
    final remainingMilliseconds = totalMilliseconds % 1000;

    final hours = totalSeconds ~/ 3600;
    final minutes = (totalSeconds % 3600) ~/ 60;
    final seconds = totalSeconds % 60;

    // Calculate frame number from remaining milliseconds
    final millisecondsPerFrame = 1000.0 / fps;
    final frames = (remainingMilliseconds / millisecondsPerFrame).floor();

    final formatted = '${hours.toString().padLeft(2, '0')}:'
        '${minutes.toString().padLeft(2, '0')}:'
        '${seconds.toString().padLeft(2, '0')}:'
        '${frames.toString().padLeft(2, '0')}';

    return isNegative ? '-$formatted' : formatted;
  }

  /// Format a Duration as drop-frame timecode HH:MM:SS;FF
  ///
  /// Drop-frame timecode is used for 29.97 and 59.94 fps to maintain
  /// sync with wall-clock time.
  static String formatDropFrameTimecode(
    Duration duration, {
    double fps = 29.97,
  }) {
    final isNegative = duration.isNegative;
    final absolute = duration.abs();

    // Calculate total frames
    final totalFrames = (absolute.inMilliseconds * fps / 1000).floor();

    // Drop-frame calculation for 29.97 fps
    // Skip 2 frame numbers every minute, except every 10th minute
    int frames;
    if (fps > 29 && fps < 30) {
      // 29.97 fps
      const droppedFrames = 2;
      final d = totalFrames ~/ 17982;
      final m = totalFrames % 17982;
      frames = totalFrames +
          (droppedFrames * 9 * d) +
          (droppedFrames * ((m - droppedFrames) ~/ 1798));
    } else if (fps > 59 && fps < 60) {
      // 59.94 fps
      const droppedFrames = 4;
      final d = totalFrames ~/ 35964;
      final m = totalFrames % 35964;
      frames = totalFrames +
          (droppedFrames * 9 * d) +
          (droppedFrames * ((m - droppedFrames) ~/ 3596));
    } else {
      frames = totalFrames;
    }

    final roundedFps = fps.round();
    final frameNumber = frames % roundedFps;
    final totalSeconds = frames ~/ roundedFps;
    final seconds = totalSeconds % 60;
    final minutes = (totalSeconds ~/ 60) % 60;
    final hours = totalSeconds ~/ 3600;

    final formatted = '${hours.toString().padLeft(2, '0')}:'
        '${minutes.toString().padLeft(2, '0')}:'
        '${seconds.toString().padLeft(2, '0')};'
        '${frameNumber.toString().padLeft(2, '0')}';

    return isNegative ? '-$formatted' : formatted;
  }

  /// Parse a duration string in HH:MM:SS.mmm or HH:MM:SS format
  ///
  /// Supported formats:
  /// - "01:23:45.678" (full)
  /// - "01:23:45" (no milliseconds)
  /// - "23:45.678" (no hours)
  /// - "23:45" (no hours, no milliseconds)
  /// - "45.678" (seconds only with milliseconds)
  /// - "45" (seconds only)
  ///
  /// Throws [FormatException] if the string cannot be parsed.
  static Duration parseDuration(String input) {
    final trimmed = input.trim();
    if (trimmed.isEmpty) {
      throw const FormatException('Empty duration string');
    }

    final isNegative = trimmed.startsWith('-');
    final normalized = isNegative ? trimmed.substring(1) : trimmed;

    // Split on colon to get time components
    final colonParts = normalized.split(':');
    if (colonParts.length > 3) {
      throw FormatException('Invalid duration format: $input');
    }

    var hours = 0;
    var minutes = 0;
    var seconds = 0;
    var milliseconds = 0;

    try {
      // Parse based on number of colon-separated parts
      switch (colonParts.length) {
        case 3:
          // HH:MM:SS or HH:MM:SS.mmm
          hours = int.parse(colonParts[0]);
          minutes = int.parse(colonParts[1]);
          (seconds, milliseconds) = _parseSecondsAndMillis(colonParts[2]);
        case 2:
          // MM:SS or MM:SS.mmm
          minutes = int.parse(colonParts[0]);
          (seconds, milliseconds) = _parseSecondsAndMillis(colonParts[1]);
        case 1:
          // SS or SS.mmm
          (seconds, milliseconds) = _parseSecondsAndMillis(colonParts[0]);
      }

      // Validate ranges
      if (minutes < 0 || minutes >= 60) {
        throw FormatException('Invalid minutes value: $minutes');
      }
      if (seconds < 0 || seconds >= 60) {
        throw FormatException('Invalid seconds value: $seconds');
      }
      if (milliseconds < 0 || milliseconds >= 1000) {
        throw FormatException('Invalid milliseconds value: $milliseconds');
      }

      var duration = Duration(
        hours: hours,
        minutes: minutes,
        seconds: seconds,
        milliseconds: milliseconds,
      );

      if (isNegative) {
        duration = -duration;
      }

      return duration;
    } catch (e) {
      if (e is FormatException) rethrow;
      throw FormatException('Invalid duration format: $input');
    }
  }

  /// Parse a timecode string in HH:MM:SS:FF or HH:MM:SS;FF format
  ///
  /// [input] - The timecode string to parse
  /// [fps] - Frames per second for conversion (default: 24)
  ///
  /// Returns the Duration represented by the timecode.
  static Duration parseTimecode(String input, {double fps = fps24}) {
    final trimmed = input.trim();
    if (trimmed.isEmpty) {
      throw const FormatException('Empty timecode string');
    }

    final isNegative = trimmed.startsWith('-');
    var normalized = isNegative ? trimmed.substring(1) : trimmed;

    // Replace drop-frame separator with regular separator
    normalized = normalized.replaceAll(';', ':');

    final parts = normalized.split(':');
    if (parts.length != 4) {
      throw FormatException('Invalid timecode format: $input');
    }

    try {
      final hours = int.parse(parts[0]);
      final minutes = int.parse(parts[1]);
      final seconds = int.parse(parts[2]);
      final frames = int.parse(parts[3]);

      // Validate ranges
      if (minutes < 0 || minutes >= 60) {
        throw FormatException('Invalid minutes value: $minutes');
      }
      if (seconds < 0 || seconds >= 60) {
        throw FormatException('Invalid seconds value: $seconds');
      }
      if (frames < 0 || frames >= fps) {
        throw FormatException('Invalid frames value: $frames for $fps fps');
      }

      // Calculate total milliseconds
      final totalMilliseconds = (hours * 3600 + minutes * 60 + seconds) * 1000 +
          (frames * 1000 / fps).round();

      var duration = Duration(milliseconds: totalMilliseconds);

      if (isNegative) {
        duration = -duration;
      }

      return duration;
    } catch (e) {
      if (e is FormatException) rethrow;
      throw FormatException('Invalid timecode format: $input');
    }
  }

  /// Try to parse a duration string, returning null on failure
  static Duration? tryParseDuration(String input) {
    try {
      return parseDuration(input);
    } catch (_) {
      return null;
    }
  }

  /// Try to parse a timecode string, returning null on failure
  static Duration? tryParseTimecode(String input, {double fps = fps24}) {
    try {
      return parseTimecode(input, fps: fps);
    } catch (_) {
      return null;
    }
  }

  /// Format duration in a human-readable way
  ///
  /// Examples:
  /// - "2 hours 30 minutes"
  /// - "5 minutes 23 seconds"
  /// - "45 seconds"
  static String formatHumanReadable(Duration duration) {
    final absolute = duration.abs();
    final isNegative = duration.isNegative;

    final hours = absolute.inHours;
    final minutes = absolute.inMinutes.remainder(60);
    final seconds = absolute.inSeconds.remainder(60);

    final parts = <String>[];

    if (hours > 0) {
      parts.add('$hours ${hours == 1 ? 'hour' : 'hours'}');
    }
    if (minutes > 0) {
      parts.add('$minutes ${minutes == 1 ? 'minute' : 'minutes'}');
    }
    if (seconds > 0 || parts.isEmpty) {
      parts.add('$seconds ${seconds == 1 ? 'second' : 'seconds'}');
    }

    final formatted = parts.join(' ');
    return isNegative ? '-$formatted' : formatted;
  }

  /// Format duration in a compact way
  ///
  /// Examples:
  /// - "2h 30m"
  /// - "5m 23s"
  /// - "45s"
  static String formatCompact(Duration duration) {
    final absolute = duration.abs();
    final isNegative = duration.isNegative;

    final hours = absolute.inHours;
    final minutes = absolute.inMinutes.remainder(60);
    final seconds = absolute.inSeconds.remainder(60);

    final parts = <String>[];

    if (hours > 0) {
      parts.add('${hours}h');
    }
    if (minutes > 0) {
      parts.add('${minutes}m');
    }
    if (seconds > 0 || parts.isEmpty) {
      parts.add('${seconds}s');
    }

    final formatted = parts.join(' ');
    return isNegative ? '-$formatted' : formatted;
  }

  /// Helper to parse seconds and milliseconds from a string like "45.678"
  static (int seconds, int milliseconds) _parseSecondsAndMillis(String input) {
    if (input.contains('.')) {
      final parts = input.split('.');
      if (parts.length != 2) {
        throw FormatException('Invalid seconds format: $input');
      }

      final seconds = int.parse(parts[0]);

      // Handle variable precision (1, 2, or 3 digits)
      var millisPart = parts[1];
      while (millisPart.length < 3) {
        millisPart += '0';
      }
      if (millisPart.length > 3) {
        millisPart = millisPart.substring(0, 3);
      }
      final milliseconds = int.parse(millisPart);

      return (seconds, milliseconds);
    } else {
      return (int.parse(input), 0);
    }
  }
}
