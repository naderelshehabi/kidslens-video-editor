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

  /// Type of content detected
  final ContentType type;

  /// Start time of the aggregated detection
  final Duration start;

  /// End time of the aggregated detection
  final Duration end;

  /// Average confidence across frames
  final double confidence;

  /// Number of frames contributing to this detection
  final int frameCount;

  /// Duration of the detection
  Duration get duration => end - start;
}

/// Service for aggregating frame-level analysis results into timeline segments
///
/// Applies temporal smoothing to convert individual frame detections into
/// contiguous time ranges suitable for timeline display and editing.
class TemporalAggregatorService {
  TemporalAggregatorService();

  final _uuid = const Uuid();

  /// Aggregate frame analysis results into timeline segments
  ///
  /// [results] - List of frame analysis results, should be sorted by timestamp
  /// [minDuration] - Minimum duration for a segment to be included (default: 500ms)
  /// [hysteresis] - Time gap allowed between detections to merge them (default: 1s)
  /// [thresholds] - Detection thresholds per content type
  ///
  /// Returns a list of timeline segments representing detected content regions.
  List<TimelineSegment> aggregate(
    List<FrameAnalysisResult> results, {
    Duration minDuration = const Duration(milliseconds: 500),
    Duration hysteresis = const Duration(seconds: 1),
    Map<ContentType, double>? thresholds,
  }) {
    if (results.isEmpty) return [];

    final effectiveThresholds = thresholds ?? _defaultThresholds;

    // Group results by detection type
    final detectionsByType = <ContentType, List<FrameAnalysisResult>>{};

    for (final result in results) {
      // Check each detection type
      if (result.hasNsfwAt(effectiveThresholds[ContentType.nsfw] ?? 0.5)) {
        detectionsByType.putIfAbsent(ContentType.nsfw, () => []).add(result);
      }
      if (result.hasViolenceAt(effectiveThresholds[ContentType.violence] ?? 0.5)) {
        detectionsByType.putIfAbsent(ContentType.violence, () => []).add(result);
      }
      if (result.hasBloodAt(effectiveThresholds[ContentType.blood] ?? 0.5)) {
        detectionsByType.putIfAbsent(ContentType.blood, () => []).add(result);
      }
      if (result.hasWeaponsAt(effectiveThresholds[ContentType.weapons] ?? 0.5)) {
        detectionsByType.putIfAbsent(ContentType.weapons, () => []).add(result);
      }
    }

    // Aggregate each type separately
    final segments = <TimelineSegment>[];

    for (final entry in detectionsByType.entries) {
      final typeSegments = _aggregateType(
        entry.key,
        entry.value,
        minDuration: minDuration,
        hysteresis: hysteresis,
      );
      segments.addAll(typeSegments);
    }

    // Sort segments by start time
    segments.sort((a, b) => a.start.compareTo(b.start));

    return segments;
  }

  /// Aggregate detections and return raw aggregated results
  ///
  /// Similar to [aggregate] but returns [AggregatedDetection] objects
  /// instead of [TimelineSegment] for more detailed processing.
  List<AggregatedDetection> aggregateRaw(
    List<FrameAnalysisResult> results, {
    Duration minDuration = const Duration(milliseconds: 500),
    Duration hysteresis = const Duration(seconds: 1),
    Map<ContentType, double>? thresholds,
  }) {
    if (results.isEmpty) return [];

    final effectiveThresholds = thresholds ?? _defaultThresholds;
    final aggregations = <AggregatedDetection>[];

    // Process each content type
    for (final type in ContentType.values) {
      final threshold = effectiveThresholds[type] ?? 0.5;
      final typeResults = results.where((r) => _hasDetectionOfType(r, type, threshold)).toList();

      if (typeResults.isEmpty) continue;

      final typeAggregations = _aggregateTypeRaw(
        type,
        typeResults,
        minDuration: minDuration,
        hysteresis: hysteresis,
      );
      aggregations.addAll(typeAggregations);
    }

    return aggregations;
  }

  /// Merge overlapping or adjacent segments of the same type
  List<TimelineSegment> mergeSegments(
    List<TimelineSegment> segments, {
    Duration hysteresis = const Duration(seconds: 1),
  }) {
    if (segments.length <= 1) return segments;

    // Group by content type
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
          // Merge with current
          current = current.copyWith(
            end: segment.end > current.end ? segment.end : current.end,
            confidence: (current.confidence + segment.confidence) / 2,
          );
        } else {
          // Gap too large, start new segment
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

  /// Apply hysteresis filtering to smooth detection boundaries
  ///
  /// Extends detections to fill small gaps and removes very short detections.
  List<TimelineSegment> applyHysteresis(
    List<TimelineSegment> segments, {
    Duration hysteresis = const Duration(seconds: 1),
    Duration minDuration = const Duration(milliseconds: 500),
  }) {
    final filtered = segments.where((s) => s.duration >= minDuration).toList();
    return mergeSegments(filtered, hysteresis: hysteresis);
  }

  /// Aggregate a single content type into timeline segments
  List<TimelineSegment> _aggregateType(
    ContentType type,
    List<FrameAnalysisResult> results, {
    required Duration minDuration,
    required Duration hysteresis,
  }) {
    if (results.isEmpty) return [];

    // Sort by timestamp
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
        // Extend current segment
        segmentEnd = current.timestamp;
        confidenceSum += _getConfidenceForType(current, type);
        frameCount++;
      } else {
        // Gap too large, finalize current segment and start new one
        if (segmentEnd - segmentStart >= minDuration) {
          segments.add(TimelineSegment(
            id: _uuid.v4(),
            start: segmentStart,
            end: segmentEnd,
            type: type,
            confidence: confidenceSum / frameCount,
          ),);
        }

        // Start new segment
        segmentStart = current.timestamp;
        segmentEnd = current.timestamp;
        confidenceSum = _getConfidenceForType(current, type);
        frameCount = 1;
      }
    }

    // Finalize last segment
    if (segmentEnd - segmentStart >= minDuration) {
      segments.add(TimelineSegment(
        id: _uuid.v4(),
        start: segmentStart,
        end: segmentEnd,
        type: type,
        confidence: confidenceSum / frameCount,
      ),);
    }

    return segments;
  }

  /// Aggregate type into raw aggregated detections
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
          aggregations.add(AggregatedDetection(
            type: type,
            start: segmentStart,
            end: segmentEnd,
            confidence: confidenceSum / frameCount,
            frameCount: frameCount,
          ),);
        }

        segmentStart = current.timestamp;
        segmentEnd = current.timestamp;
        confidenceSum = _getConfidenceForType(current, type);
        frameCount = 1;
      }
    }

    if (segmentEnd - segmentStart >= minDuration) {
      aggregations.add(AggregatedDetection(
        type: type,
        start: segmentStart,
        end: segmentEnd,
        confidence: confidenceSum / frameCount,
        frameCount: frameCount,
      ),);
    }

    return aggregations;
  }

  /// Check if a frame has a detection of the specified type
  bool _hasDetectionOfType(
    FrameAnalysisResult result,
    ContentType type,
    double threshold,
  ) {
    switch (type) {
      case ContentType.nsfw:
        return result.hasNsfwAt(threshold);
      case ContentType.violence:
        return result.hasViolenceAt(threshold);
      case ContentType.blood:
        return result.hasBloodAt(threshold);
      case ContentType.weapons:
        return result.hasWeaponsAt(threshold);
      case ContentType.profanity:
        return false; // Profanity is audio-based, not frame-based
    }
  }

  /// Get confidence score for a specific content type
  double _getConfidenceForType(FrameAnalysisResult result, ContentType type) {
    switch (type) {
      case ContentType.nsfw:
        return result.nsfw.maxNsfwScore;
      case ContentType.violence:
        return result.violence.violent;
      case ContentType.blood:
        return result.blood?.score ?? 0;
      case ContentType.weapons:
        return result.weapons?.score ?? 0;
      case ContentType.profanity:
        return 0;
    }
  }

  /// Default detection thresholds
  static const _defaultThresholds = <ContentType, double>{
    ContentType.nsfw: 0.5,
    ContentType.violence: 0.5,
    ContentType.blood: 0.5,
    ContentType.weapons: 0.5,
    ContentType.profanity: 0.5,
  };
}
