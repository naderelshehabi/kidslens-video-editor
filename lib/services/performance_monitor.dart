import 'dart:collection';

import 'package:flutter/foundation.dart';

/// Tier levels for model selection based on performance
enum ModelTier {
  /// Low performance tier - use smallest/fastest models
  low,

  /// Medium performance tier - balanced models
  medium,

  /// High performance tier - can use larger, more accurate models
  high,
}

/// Statistics for a single operation
class OperationStats {
  OperationStats({
    required this.operation,
  });

  /// Name of the operation
  final String operation;

  /// All recorded durations
  final List<Duration> _durations = [];

  /// Record a new timing
  void record(Duration duration) {
    _durations.add(duration);

    // Keep only last 100 measurements
    if (_durations.length > 100) {
      _durations.removeAt(0);
    }
  }

  /// Number of recordings
  int get count => _durations.length;

  /// Average duration
  Duration get average {
    if (_durations.isEmpty) return Duration.zero;
    final totalMicroseconds =
        _durations.fold<int>(0, (sum, d) => sum + d.inMicroseconds);
    return Duration(microseconds: totalMicroseconds ~/ _durations.length);
  }

  /// Minimum duration
  Duration get minimum {
    if (_durations.isEmpty) return Duration.zero;
    return _durations.reduce((a, b) => a < b ? a : b);
  }

  /// Maximum duration
  Duration get maximum {
    if (_durations.isEmpty) return Duration.zero;
    return _durations.reduce((a, b) => a > b ? a : b);
  }

  /// Standard deviation of durations
  Duration get standardDeviation {
    if (_durations.length < 2) return Duration.zero;

    final avgMicros = average.inMicroseconds;
    final variance = _durations.fold<double>(
          0,
          (sum, d) {
            final diff = d.inMicroseconds - avgMicros;
            return sum + (diff * diff);
          },
        ) /
        _durations.length;

    return Duration(microseconds: variance.sqrt().round());
  }

  /// Percentile duration (e.g., p95)
  Duration percentile(double p) {
    if (_durations.isEmpty) return Duration.zero;

    final sorted = List<Duration>.from(_durations)
      ..sort((a, b) => a.compareTo(b));

    final index = ((sorted.length - 1) * p / 100).round();
    return sorted[index];
  }

  /// P50 (median) duration
  Duration get p50 => percentile(50);

  /// P95 duration
  Duration get p95 => percentile(95);

  /// P99 duration
  Duration get p99 => percentile(99);

  /// Clear all recordings
  void clear() => _durations.clear();
}

/// Service for tracking performance metrics and recommending model tiers
///
/// Tracks operation timings to help determine the appropriate model tier
/// for the current hardware. Uses a singleton pattern with Riverpod keepAlive.
class PerformanceMonitor {
  PerformanceMonitor._();

  /// Get the singleton instance
  factory PerformanceMonitor.instance() {
    _instance ??= PerformanceMonitor._();
    return _instance!;
  }

  static PerformanceMonitor? _instance;

  /// Operation statistics by name
  final Map<String, OperationStats> _stats = {};

  /// Threshold timings for tier classification (per frame)
  static const _tierThresholds = {
    'frame_inference': {
      ModelTier.high: Duration(milliseconds: 50),
      ModelTier.medium: Duration(milliseconds: 150),
      // Anything above medium threshold is low tier
    },
    'transcription_per_second': {
      ModelTier.high: Duration(milliseconds: 100),
      ModelTier.medium: Duration(milliseconds: 500),
    },
    'model_load': {
      ModelTier.high: Duration(seconds: 2),
      ModelTier.medium: Duration(seconds: 5),
    },
  };

  /// Historical tier recommendations for smoothing
  final Queue<ModelTier> _tierHistory = Queue();

  /// Record timing for an operation
  ///
  /// [operation] - Name of the operation (e.g., 'frame_inference', 'transcription')
  /// [duration] - How long the operation took
  void recordTiming(String operation, Duration duration) {
    _stats.putIfAbsent(operation, () => OperationStats(operation: operation));
    _stats[operation]!.record(duration);

    debugPrint('Performance: $operation took ${duration.inMilliseconds}ms');
  }

  /// Record timing using a stopwatch
  ///
  /// Returns a function to call when the operation completes.
  void Function() startTiming(String operation) {
    final stopwatch = Stopwatch()..start();
    return () {
      stopwatch.stop();
      recordTiming(operation, stopwatch.elapsed);
    };
  }

  /// Record timing for an async operation
  Future<T> timeAsync<T>(String operation, Future<T> Function() work) async {
    final stopwatch = Stopwatch()..start();
    try {
      return await work();
    } finally {
      stopwatch.stop();
      recordTiming(operation, stopwatch.elapsed);
    }
  }

  /// Get average timing for an operation
  ///
  /// Returns null if no timings have been recorded.
  Duration? getAverageTiming(String operation) {
    final stats = _stats[operation];
    if (stats == null || stats.count == 0) return null;
    return stats.average;
  }

  /// Get full statistics for an operation
  OperationStats? getStats(String operation) => _stats[operation];

  /// Get all recorded operations
  List<String> get operations => _stats.keys.toList();

  /// Get recommended model tier based on performance history
  ///
  /// Analyzes recorded performance data to determine what tier of models
  /// the system can handle efficiently.
  ModelTier getRecommendedTier() {
    // If no data, default to medium tier
    if (_stats.isEmpty) return ModelTier.medium;

    var overallTier = ModelTier.high;

    for (final entry in _tierThresholds.entries) {
      final operation = entry.key;
      final thresholds = entry.value;

      final stats = _stats[operation];
      if (stats == null || stats.count < 3) continue;

      // Use p95 for more stable recommendations
      final timing = stats.p95;

      // Determine tier for this operation
      ModelTier operationTier;
      if (timing <= thresholds[ModelTier.high]!) {
        operationTier = ModelTier.high;
      } else if (timing <= thresholds[ModelTier.medium]!) {
        operationTier = ModelTier.medium;
      } else {
        operationTier = ModelTier.low;
      }

      // Overall tier is the minimum of all operations
      if (operationTier.index < overallTier.index) {
        overallTier = operationTier;
      }
    }

    // Add to history for smoothing
    _tierHistory.add(overallTier);
    if (_tierHistory.length > 5) {
      _tierHistory.removeFirst();
    }

    // Return the most common tier in recent history
    return _getMostCommonTier();
  }

  /// Get the most common tier from recent history
  ModelTier _getMostCommonTier() {
    if (_tierHistory.isEmpty) return ModelTier.medium;

    final counts = <ModelTier, int>{};
    for (final tier in _tierHistory) {
      counts[tier] = (counts[tier] ?? 0) + 1;
    }

    return counts.entries.reduce((a, b) => a.value > b.value ? a : b).key;
  }

  /// Get a performance summary
  Map<String, dynamic> getSummary() => {
        'recommendedTier': getRecommendedTier().name,
        'operations': _stats.map(
          (key, value) => MapEntry(key, {
            'count': value.count,
            'average': value.average.inMilliseconds,
            'min': value.minimum.inMilliseconds,
            'max': value.maximum.inMilliseconds,
            'p95': value.p95.inMilliseconds,
          }),
        ),
      };

  /// Clear all recorded data
  void clear() {
    _stats.clear();
    _tierHistory.clear();
  }

  /// Reset the singleton instance (for testing)
  @visibleForTesting
  static void reset() {
    _instance = null;
  }
}

/// Extension on num for sqrt
extension _NumExtension on double {
  double sqrt() {
    if (this < 0) return 0;
    var guess = this / 2;
    for (var i = 0; i < 10; i++) {
      guess = (guess + this / guess) / 2;
    }
    return guess;
  }
}
