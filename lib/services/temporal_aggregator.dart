import 'package:kidslens_video_editor/data/models/detection.dart';
import 'package:kidslens_video_editor/data/models/frame_analysis_result.dart';
import 'package:kidslens_video_editor/data/models/timeline.dart';
import 'package:uuid/uuid.dart';

/// Result of temporal aggregation for a single detection type
class AggregatedDetection {
  const AggregatedDetection({
    required this.type,
    required this.start,
    required this.end,
    required this.confidence,
    required this.frameCount,
  });

  final ContentType type;
  final Duration start;
  final Duration end;
  final double confidence;
  final int frameCount;

  Duration get duration => end - start;
}

/// Service for aggregating frame-level analysis results into timeline segments.
///
/// Only NSFW is frame-aggregated. Profanity is audio/transcript-based and does
/// not participate in frame aggregation.
class TemporalAggregatorService {
  TemporalAggregatorService();

  final _uuid = const Uuid();

  List<TimelineSegment> aggregate(
    List<FrameAnalysisResult> results, {
    Duration minDuration = const Duration(milliseconds: 500),
    Duration hysteresis = const Duration(seconds: 1),
    Map<ContentType, double>? thresholds,
  }) {
    if (results.isEmpty) return [];

    final effectiveThresholds = thresholds ?? _defaultThresholds;
    final nsfwThreshold = effectiveThresholds[ContentType.nsfw] ?? 0.5;
    final nsfwResults = results
        .where((result) => result.hasNsfwAt(nsfwThreshold))
        .toList(growable: false);

    final segments = _aggregateType(
      ContentType.nsfw,
      nsfwResults,
      minDuration: minDuration,
      hysteresis: hysteresis,
    )..sort((a, b) => a.start.compareTo(b.start));

    return segments;
  }

  List<AggregatedDetection> aggregateRaw(
    List<FrameAnalysisResult> results, {
    Duration minDuration = const Duration(milliseconds: 500),
    Duration hysteresis = const Duration(seconds: 1),
    Map<ContentType, double>? thresholds,
  }) {
    if (results.isEmpty) return [];

    final effectiveThresholds = thresholds ?? _defaultThresholds;
    final threshold = effectiveThresholds[ContentType.nsfw] ?? 0.5;
    final typeResults = results
        .where((result) => _hasDetectionOfType(result, ContentType.nsfw, threshold))
        .toList(growable: false);

    if (typeResults.isEmpty) {
      return const <AggregatedDetection>[];
    }

    return _aggregateTypeRaw(
      ContentType.nsfw,
      typeResults,
      minDuration: minDuration,
      hysteresis: hysteresis,
    );
  }

  List<TimelineSegment> mergeSegments(
    List<TimelineSegment> segments, {
    Duration hysteresis = const Duration(seconds: 1),
  }) {
    if (segments.length <= 1) return segments;

    final byType = <ContentType, List<TimelineSegment>>{};
    for (final segment in segments) {
      byType.putIfAbsent(segment.type, () => []).add(segment);
    }

    final merged = <TimelineSegment>[];

    for (final entry in byType.entries) {
      final typeSegments = entry.value..sort((a, b) => a.start.compareTo(b.start));

      TimelineSegment? current;

      for (final segment in typeSegments) {
        if (current == null) {
          current = segment;
        } else if (segment.start <= current.end + hysteresis) {
          current = current.copyWith(
            end: segment.end > current.end ? segment.end : current.end,
            confidence: (current.confidence + segment.confidence) / 2,
          );
        } else {
          merged.add(current);
          current = segment;
        }
      }

      if (current != null) {
        merged.add(current);
      }
    }

    return merged..sort((a, b) => a.start.compareTo(b.start));
  }

  List<TimelineSegment> applyHysteresis(
    List<TimelineSegment> segments, {
    Duration hysteresis = const Duration(seconds: 1),
    Duration minDuration = const Duration(milliseconds: 500),
  }) {
    final filtered = segments.where((s) => s.duration >= minDuration).toList();
    return mergeSegments(filtered, hysteresis: hysteresis);
  }

  List<TimelineSegment> _aggregateType(
    ContentType type,
    List<FrameAnalysisResult> results, {
    required Duration minDuration,
    required Duration hysteresis,
  }) {
    if (results.isEmpty) return [];

    final sorted = List<FrameAnalysisResult>.from(results)
      ..sort((a, b) => a.timestamp.compareTo(b.timestamp));

    final segments = <TimelineSegment>[];
    var segmentStart = sorted.first.timestamp;
    var segmentEnd = sorted.first.timestamp;
    var confidenceSum = _getConfidenceForType(sorted.first, type);
    var frameCount = 1;

    for (var i = 1; i < sorted.length; i++) {
      final current = sorted[i];
      final gap = current.timestamp - segmentEnd;

      if (gap <= hysteresis) {
        segmentEnd = current.timestamp;
        confidenceSum += _getConfidenceForType(current, type);
        frameCount++;
      } else {
        if (segmentEnd - segmentStart >= minDuration) {
          segments.add(
            TimelineSegment(
              id: _uuid.v4(),
              start: segmentStart,
              end: segmentEnd,
              type: type,
              confidence: confidenceSum / frameCount,
            ),
          );
        }

        segmentStart = current.timestamp;
        segmentEnd = current.timestamp;
        confidenceSum = _getConfidenceForType(current, type);
        frameCount = 1;
      }
    }

    if (segmentEnd - segmentStart >= minDuration) {
      segments.add(
        TimelineSegment(
          id: _uuid.v4(),
          start: segmentStart,
          end: segmentEnd,
          type: type,
          confidence: confidenceSum / frameCount,
        ),
      );
    }

    return segments;
  }

  List<AggregatedDetection> _aggregateTypeRaw(
    ContentType type,
    List<FrameAnalysisResult> results, {
    required Duration minDuration,
    required Duration hysteresis,
  }) {
    if (results.isEmpty) return [];

    final sorted = List<FrameAnalysisResult>.from(results)
      ..sort((a, b) => a.timestamp.compareTo(b.timestamp));

    final aggregations = <AggregatedDetection>[];
    var segmentStart = sorted.first.timestamp;
    var segmentEnd = sorted.first.timestamp;
    var confidenceSum = _getConfidenceForType(sorted.first, type);
    var frameCount = 1;

    for (var i = 1; i < sorted.length; i++) {
      final current = sorted[i];
      final gap = current.timestamp - segmentEnd;

      if (gap <= hysteresis) {
        segmentEnd = current.timestamp;
        confidenceSum += _getConfidenceForType(current, type);
        frameCount++;
      } else {
        if (segmentEnd - segmentStart >= minDuration) {
          aggregations.add(
            AggregatedDetection(
              type: type,
              start: segmentStart,
              end: segmentEnd,
              confidence: confidenceSum / frameCount,
              frameCount: frameCount,
            ),
          );
        }

        segmentStart = current.timestamp;
        segmentEnd = current.timestamp;
        confidenceSum = _getConfidenceForType(current, type);
        frameCount = 1;
      }
    }

    if (segmentEnd - segmentStart >= minDuration) {
      aggregations.add(
        AggregatedDetection(
          type: type,
          start: segmentStart,
          end: segmentEnd,
          confidence: confidenceSum / frameCount,
          frameCount: frameCount,
        ),
      );
    }

    return aggregations;
  }

  bool _hasDetectionOfType(
    FrameAnalysisResult result,
    ContentType type,
    double threshold,
  ) {
    switch (type) {
      case ContentType.nsfw:
        return result.hasNsfwAt(threshold);
      case ContentType.profanity:
        return false;
    }
  }

  double _getConfidenceForType(FrameAnalysisResult result, ContentType type) {
    switch (type) {
      case ContentType.nsfw:
        return result.nsfw.maxNsfwScore;
      case ContentType.profanity:
        return 0;
    }
  }

  static const _defaultThresholds = <ContentType, double>{
    ContentType.nsfw: 0.5,
    ContentType.profanity: 0.5,
  };
}
