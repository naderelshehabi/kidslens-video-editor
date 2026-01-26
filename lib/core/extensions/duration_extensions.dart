/// Extension methods for Duration
extension DurationExtensions on Duration {
  // ============================================================
  // Arithmetic Operators
  // ============================================================

  /// Divide this duration by another duration, returning a double ratio
  ///
  /// Example: Duration(seconds: 10) / Duration(seconds: 2) = 5.0
  double operator /(Duration other) {
    if (other.inMicroseconds == 0) {
      throw ArgumentError('Cannot divide by zero duration');
    }
    return inMicroseconds / other.inMicroseconds;
  }

  /// Integer division of this duration by another duration
  ///
  /// Example: Duration(seconds: 10) ~/ Duration(seconds: 3) = 3
  int intDivide(Duration other) {
    if (other.inMicroseconds == 0) {
      throw ArgumentError('Cannot divide by zero duration');
    }
    return inMicroseconds ~/ other.inMicroseconds;
  }

  /// Modulo operation with another duration
  ///
  /// Example: Duration(seconds: 10) % Duration(seconds: 3) = Duration(seconds: 1)
  Duration operator %(Duration other) {
    if (other.inMicroseconds == 0) {
      throw ArgumentError('Cannot modulo by zero duration');
    }
    return Duration(microseconds: inMicroseconds % other.inMicroseconds);
  }

  /// Multiply this duration by a factor
  ///
  /// Example: Duration(seconds: 10) * 2.5 = Duration(seconds: 25)
  Duration multiply(double factor) {
    return Duration(microseconds: (inMicroseconds * factor).round());
  }

  /// Divide this duration by a numeric factor
  ///
  /// Example: Duration(seconds: 10).divideBy(2) = Duration(seconds: 5)
  Duration divideBy(double divisor) {
    if (divisor == 0) {
      throw ArgumentError('Cannot divide by zero');
    }
    return Duration(microseconds: (inMicroseconds / divisor).round());
  }

  // ============================================================
  // Timestamp Formatting
  // ============================================================

  /// Format duration as HH:MM:SS.mmm
  String toTimestamp() {
    final isNeg = isNegative;
    final absolute = abs();
    final hours = absolute.inHours.toString().padLeft(2, '0');
    final minutes = (absolute.inMinutes % 60).toString().padLeft(2, '0');
    final seconds = (absolute.inSeconds % 60).toString().padLeft(2, '0');
    final milliseconds =
        (absolute.inMilliseconds % 1000).toString().padLeft(3, '0');
    final formatted = '$hours:$minutes:$seconds.$milliseconds';
    return isNeg ? '-$formatted' : formatted;
  }

  /// Format duration as HH:MM:SS
  String toShortTimestamp() {
    final isNeg = isNegative;
    final absolute = abs();
    final hours = absolute.inHours.toString().padLeft(2, '0');
    final minutes = (absolute.inMinutes % 60).toString().padLeft(2, '0');
    final seconds = (absolute.inSeconds % 60).toString().padLeft(2, '0');
    final formatted = '$hours:$minutes:$seconds';
    return isNeg ? '-$formatted' : formatted;
  }

  // ============================================================
  // Timecode Formatting
  // ============================================================

  /// Format duration as professional timecode HH:MM:SS:FF
  ///
  /// [fps] - Frames per second (default: 24)
  ///
  /// Example: Duration(seconds: 90, milliseconds: 500) at 24fps
  /// returns "00:01:30:12"
  String toTimecode({double fps = 24.0}) {
    final isNeg = isNegative;
    final absolute = abs();

    final totalMilliseconds = absolute.inMilliseconds;
    final totalSeconds = totalMilliseconds ~/ 1000;
    final remainingMilliseconds = totalMilliseconds % 1000;

    final hours = (totalSeconds ~/ 3600).toString().padLeft(2, '0');
    final minutes = ((totalSeconds % 3600) ~/ 60).toString().padLeft(2, '0');
    final seconds = (totalSeconds % 60).toString().padLeft(2, '0');

    // Calculate frame number from remaining milliseconds
    final millisecondsPerFrame = 1000.0 / fps;
    final frames =
        (remainingMilliseconds / millisecondsPerFrame).floor().toString().padLeft(2, '0');

    final formatted = '$hours:$minutes:$seconds:$frames';
    return isNeg ? '-$formatted' : formatted;
  }

  /// Format duration as drop-frame timecode HH:MM:SS;FF
  ///
  /// Used for 29.97 fps and 59.94 fps to maintain sync with wall-clock time.
  String toDropFrameTimecode({double fps = 29.97}) {
    final isNeg = isNegative;
    final absolute = abs();

    // Calculate total frames
    var totalFrames = (absolute.inMilliseconds * fps / 1000).floor();

    // Drop-frame calculation
    if (fps > 29 && fps < 30) {
      // 29.97 fps - drop 2 frames every minute except every 10th minute
      const droppedFrames = 2;
      final d = totalFrames ~/ 17982;
      final m = totalFrames % 17982;
      totalFrames += (droppedFrames * 9 * d) +
          (droppedFrames * ((m - droppedFrames) ~/ 1798));
    } else if (fps > 59 && fps < 60) {
      // 59.94 fps
      const droppedFrames = 4;
      final d = totalFrames ~/ 35964;
      final m = totalFrames % 35964;
      totalFrames += (droppedFrames * 9 * d) +
          (droppedFrames * ((m - droppedFrames) ~/ 3596));
    }

    final roundedFps = fps.round();
    final frames = (totalFrames % roundedFps).toString().padLeft(2, '0');
    final totalSeconds = totalFrames ~/ roundedFps;
    final seconds = (totalSeconds % 60).toString().padLeft(2, '0');
    final minutes = ((totalSeconds ~/ 60) % 60).toString().padLeft(2, '0');
    final hours = (totalSeconds ~/ 3600).toString().padLeft(2, '0');

    final formatted = '$hours:$minutes:$seconds;$frames';
    return isNeg ? '-$formatted' : formatted;
  }

  // ============================================================
  // Human Readable Formatting
  // ============================================================

  /// Format duration as human readable (e.g., "2h 30m")
  String toHumanReadable() {
    final absolute = abs();
    final prefix = isNegative ? '-' : '';

    if (absolute.inHours > 0) {
      return '$prefix${absolute.inHours}h ${absolute.inMinutes % 60}m';
    } else if (absolute.inMinutes > 0) {
      return '$prefix${absolute.inMinutes}m ${absolute.inSeconds % 60}s';
    } else if (absolute.inSeconds > 0) {
      return '$prefix${absolute.inSeconds}s';
    } else {
      return '$prefix${absolute.inMilliseconds}ms';
    }
  }

  /// Format duration as a readable string with full words
  ///
  /// Example: "2 hours 30 minutes 45 seconds"
  String toReadable() {
    final absolute = abs();
    final prefix = isNegative ? '-' : '';

    final hours = absolute.inHours;
    final minutes = absolute.inMinutes % 60;
    final seconds = absolute.inSeconds % 60;

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

    return '$prefix${parts.join(' ')}';
  }

  /// Format as a compact progress string
  ///
  /// Example: "1:23:45" or "23:45" or "0:45"
  String toProgressString() {
    final absolute = abs();
    final prefix = isNegative ? '-' : '';

    final hours = absolute.inHours;
    final minutes = absolute.inMinutes % 60;
    final seconds = absolute.inSeconds % 60;

    if (hours > 0) {
      return '$prefix$hours:${minutes.toString().padLeft(2, '0')}:'
          '${seconds.toString().padLeft(2, '0')}';
    } else {
      return '$prefix$minutes:${seconds.toString().padLeft(2, '0')}';
    }
  }

  // ============================================================
  // Time Range Operations
  // ============================================================

  /// Check if this duration overlaps with another time range
  bool overlaps(Duration otherStart, Duration otherEnd, Duration thisEnd) {
    return this < otherEnd && thisEnd > otherStart;
  }

  /// Check if this duration is within a range (inclusive)
  bool isWithin(Duration start, Duration end) {
    return this >= start && this <= end;
  }

  /// Clamp this duration to a range
  Duration clampDuration(Duration min, Duration max) {
    if (this < min) return min;
    if (this > max) return max;
    return this;
  }

  /// Get the distance to another duration
  Duration distanceTo(Duration other) {
    return Duration(microseconds: (inMicroseconds - other.inMicroseconds).abs());
  }

  // ============================================================
  // Frame Calculations
  // ============================================================

  /// Convert duration to frame number at given fps
  int toFrameNumber({double fps = 24.0}) {
    return (inMilliseconds * fps / 1000).floor();
  }

  /// Create a duration from a frame number at given fps
  static Duration fromFrameNumber(int frame, {double fps = 24.0}) {
    return Duration(milliseconds: (frame * 1000 / fps).round());
  }

  /// Round duration to nearest frame boundary
  Duration roundToFrame({double fps = 24.0}) {
    final frameNumber = toFrameNumber(fps: fps);
    return Duration(milliseconds: (frameNumber * 1000 / fps).round());
  }

  // ============================================================
  // Conversion Helpers
  // ============================================================

  /// Get total duration as fractional seconds
  double get inSecondsDouble => inMicroseconds / 1000000.0;

  /// Get total duration as fractional minutes
  double get inMinutesDouble => inMicroseconds / 60000000.0;

  /// Get total duration as fractional hours
  double get inHoursDouble => inMicroseconds / 3600000000.0;
}
