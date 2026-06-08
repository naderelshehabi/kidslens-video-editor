import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:kidslens_video_editor/data/models/models.dart';

/// Configuration for deterministic video chunk planning.
class ChunkPlannerConfig {
  const ChunkPlannerConfig({
    this.targetChunkDuration = const Duration(seconds: 8),
    this.minChunkDuration = const Duration(seconds: 4),
    this.maxChunkDuration = const Duration(seconds: 12),
    this.overlap = const Duration(milliseconds: 750),
    this.sceneBoundaryTolerance = const Duration(milliseconds: 1500),
    this.useSceneBoundaries = true,
  });

  final Duration targetChunkDuration;
  final Duration minChunkDuration;
  final Duration maxChunkDuration;
  final Duration overlap;
  final Duration sceneBoundaryTolerance;
  final bool useSceneBoundaries;

  Map<String, dynamic> toJson() => {
        'targetChunkDurationMs': targetChunkDuration.inMilliseconds,
        'minChunkDurationMs': minChunkDuration.inMilliseconds,
        'maxChunkDurationMs': maxChunkDuration.inMilliseconds,
        'overlapMs': overlap.inMilliseconds,
        'sceneBoundaryToleranceMs': sceneBoundaryTolerance.inMilliseconds,
        'useSceneBoundaries': useSceneBoundaries,
      };

  String get deterministicHash =>
      sha256.convert(utf8.encode(jsonEncode(toJson()))).toString();
}

/// Creates deterministic chunk windows for media ingestion.
class ChunkPlanner {
  const ChunkPlanner({
    this.config = const ChunkPlannerConfig(),
  });

  final ChunkPlannerConfig config;

  List<VideoChunk> planChunks({
    required String mediaId,
    required Duration mediaDuration,
    List<Duration> sceneChanges = const [],
  }) {
    if (mediaDuration <= Duration.zero) {
      return const [];
    }
    _validateConfig();

    final normalizedSceneChanges = _normalizeSceneChanges(
      sceneChanges,
      mediaDuration,
    );
    final chunks = <VideoChunk>[];
    var index = 0;
    var start = Duration.zero;

    while (start < mediaDuration) {
      var end = start + config.targetChunkDuration;
      if (end - start > config.maxChunkDuration) {
        end = start + config.maxChunkDuration;
      }
      if (end > mediaDuration) {
        end = mediaDuration;
      }
      end = _applySceneBoundary(
        start: start,
        plannedEnd: end,
        mediaDuration: mediaDuration,
        sceneChanges: normalizedSceneChanges,
      );

      if (end <= start) {
        end = start + config.minChunkDuration;
      }

      if (end <= start || end > mediaDuration) {
        end = mediaDuration;
      }

      final sceneChangesInChunk = normalizedSceneChanges
          .where((timestamp) => timestamp >= start && timestamp <= end)
          .toList(growable: false);
      final overlapBefore = chunks.isEmpty ? Duration.zero : config.overlap;
      final overlapAfter =
          end >= mediaDuration ? Duration.zero : config.overlap;
      final chunk = VideoChunk(
        id: VideoChunk.deterministicId(
          mediaId: mediaId,
          index: index,
          startTime: start,
          endTime: end,
        ),
        mediaId: mediaId,
        index: index,
        startTime: start,
        endTime: end,
        overlapBefore: overlapBefore,
        overlapAfter: overlapAfter,
        sceneChangeTimestamps: sceneChangesInChunk,
      );
      chunks.add(chunk);

      if (end >= mediaDuration) {
        break;
      }

      final nextStart = end - config.overlap;
      start = nextStart > start ? nextStart : end;
      index++;
    }

    return chunks;
  }

  void _validateConfig() {
    if (config.targetChunkDuration <= Duration.zero) {
      throw ArgumentError.value(
        config.targetChunkDuration,
        'targetChunkDuration',
        'Target chunk duration must be positive',
      );
    }
    if (config.minChunkDuration <= Duration.zero) {
      throw ArgumentError.value(
        config.minChunkDuration,
        'minChunkDuration',
        'Minimum chunk duration must be positive',
      );
    }
    if (config.maxChunkDuration < config.minChunkDuration) {
      throw ArgumentError.value(
        config.maxChunkDuration,
        'maxChunkDuration',
        'Maximum chunk duration must be greater than or equal to minimum',
      );
    }
    if (config.overlap < Duration.zero ||
        config.overlap >= config.minChunkDuration) {
      throw ArgumentError.value(
        config.overlap,
        'overlap',
        'Overlap must be non-negative and shorter than the minimum chunk',
      );
    }
  }

  List<Duration> _normalizeSceneChanges(
    List<Duration> sceneChanges,
    Duration mediaDuration,
  ) {
    final unique = <int>{};
    for (final timestamp in sceneChanges) {
      if (timestamp <= Duration.zero || timestamp >= mediaDuration) {
        continue;
      }
      unique.add(timestamp.inMilliseconds);
    }
    return unique
        .map((milliseconds) => Duration(milliseconds: milliseconds))
        .toList(growable: false)
      ..sort();
  }

  Duration _applySceneBoundary({
    required Duration start,
    required Duration plannedEnd,
    required Duration mediaDuration,
    required List<Duration> sceneChanges,
  }) {
    if (!config.useSceneBoundaries || sceneChanges.isEmpty) {
      return plannedEnd > mediaDuration ? mediaDuration : plannedEnd;
    }

    Duration? bestCandidate;
    var bestDistance = config.sceneBoundaryTolerance + const Duration(days: 1);
    for (final sceneChange in sceneChanges) {
      if (sceneChange <= start || sceneChange >= mediaDuration) {
        continue;
      }
      final chunkLength = sceneChange - start;
      if (chunkLength < config.minChunkDuration ||
          chunkLength > config.maxChunkDuration) {
        continue;
      }
      final distance = _absoluteDuration(sceneChange - plannedEnd);
      if (distance <= config.sceneBoundaryTolerance &&
          distance < bestDistance) {
        bestCandidate = sceneChange;
        bestDistance = distance;
      }
    }

    return bestCandidate ??
        (plannedEnd > mediaDuration ? mediaDuration : plannedEnd);
  }

  Duration _absoluteDuration(Duration value) =>
      value.isNegative ? -value : value;
}
