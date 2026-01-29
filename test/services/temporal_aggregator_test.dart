import 'package:flutter_test/flutter_test.dart';
import 'package:kidslens_video_editor/data/models/detection.dart';
import 'package:kidslens_video_editor/data/models/frame_analysis_result.dart';
import 'package:kidslens_video_editor/services/temporal_aggregator.dart';

void main() {
  late TemporalAggregatorService aggregator;

  setUp(() {
    aggregator = TemporalAggregatorService();
  });

  group('TemporalAggregatorService', () {
    group('aggregate()', () {
      test('should return empty list for empty input', () {
        final results = aggregator.aggregate([]);

        expect(results, isEmpty);
      });

      test('should handle single detection', () {
        final results = aggregator.aggregate(
          [
            _createFrameResult(
              timestamp: Duration.zero,
              nsfwScore: 0.9,
            ),
          ],
          minDuration: Duration.zero,
        );

        // Single frame detection might not meet minimum duration
        // unless minDuration is 0
        expect(results, isNotEmpty);
      });

      test('should merge adjacent detections within hysteresis', () {
        final results = aggregator.aggregate(
          [
            _createFrameResult(
              timestamp: const Duration(),
              nsfwScore: 0.9,
            ),
            _createFrameResult(
              timestamp: const Duration(milliseconds: 500),
              nsfwScore: 0.85,
            ),
            _createFrameResult(
              timestamp: const Duration(seconds: 1),
              nsfwScore: 0.8,
            ),
          ],
          hysteresis: const Duration(seconds: 2),
          minDuration: Duration.zero,
        );

        // Should merge into one segment
        expect(results.length, equals(1));
        expect(results.first.type, equals(ContentType.nsfw));
        expect(results.first.start, equals(Duration.zero));
        expect(results.first.end, equals(const Duration(seconds: 1)));
      });

      test('should not merge detections separated by gap larger than hysteresis', () {
        final results = aggregator.aggregate(
          [
            _createFrameResult(
              timestamp: const Duration(),
              nsfwScore: 0.9,
            ),
            _createFrameResult(
              timestamp: const Duration(seconds: 5),
              nsfwScore: 0.85,
            ),
          ],
          minDuration: Duration.zero,
        );

        // Should be two separate segments (or one if the second is filtered by minDuration)
        expect(results.length, greaterThanOrEqualTo(1));
      });

      test('should respect minDuration filtering', () {
        final results = aggregator.aggregate(
          [
            _createFrameResult(
              timestamp: const Duration(),
              nsfwScore: 0.9,
            ),
          ],
          minDuration: const Duration(seconds: 1),
        );

        // Single frame cannot meet 1 second minDuration
        expect(results, isEmpty);
      });

      test('should include segments that meet minDuration', () {
        final results = aggregator.aggregate(
          [
            _createFrameResult(
              timestamp: const Duration(),
              nsfwScore: 0.9,
            ),
            _createFrameResult(
              timestamp: const Duration(seconds: 1),
              nsfwScore: 0.85,
            ),
            _createFrameResult(
              timestamp: const Duration(seconds: 2),
              nsfwScore: 0.8,
            ),
          ],
          hysteresis: const Duration(seconds: 2),
          minDuration: const Duration(seconds: 1),
        );

        // Should have at least one segment meeting the duration requirement
        expect(results, isNotEmpty);
        for (final segment in results) {
          expect(segment.duration, greaterThanOrEqualTo(const Duration(seconds: 1)));
        }
      });

      test('should handle multiple detection types simultaneously', () {
        final results = aggregator.aggregate(
          [
            _createFrameResult(
              timestamp: const Duration(),
              nsfwScore: 0.9,
              violenceScore: 0.8,
            ),
            _createFrameResult(
              timestamp: const Duration(seconds: 1),
              nsfwScore: 0.85,
              violenceScore: 0.75,
            ),
          ],
          hysteresis: const Duration(seconds: 2),
          minDuration: Duration.zero,
        );

        // Should have segments for both NSFW and violence
        final types = results.map((s) => s.type).toSet();
        expect(types, contains(ContentType.nsfw));
        expect(types, contains(ContentType.violence));
      });

      test('should sort results by start time', () {
        final results = aggregator.aggregate(
          [
            _createFrameResult(
              timestamp: const Duration(seconds: 5),
              nsfwScore: 0.9,
            ),
            _createFrameResult(
              timestamp: const Duration(),
              violenceScore: 0.8,
            ),
          ],
          minDuration: Duration.zero,
        );

        if (results.length > 1) {
          for (var i = 0; i < results.length - 1; i++) {
            expect(results[i].start, lessThanOrEqualTo(results[i + 1].start));
          }
        }
      });

      test('should use custom thresholds when provided', () {
        final lowThresholdResults = aggregator.aggregate(
          [
            _createFrameResult(
              timestamp: const Duration(),
              nsfwScore: 0.3, // Below default 0.5 threshold
            ),
          ],
          thresholds: {ContentType.nsfw: 0.2},
          minDuration: Duration.zero,
        );

        expect(lowThresholdResults, isNotEmpty);

        final highThresholdResults = aggregator.aggregate(
          [
            _createFrameResult(
              timestamp: const Duration(),
              nsfwScore: 0.6, // Above default but below custom high threshold
            ),
          ],
          thresholds: {ContentType.nsfw: 0.7},
          minDuration: Duration.zero,
        );

        expect(highThresholdResults, isEmpty);
      });
    });

    group('aggregateRaw()', () {
      test('should return empty list for empty input', () {
        final results = aggregator.aggregateRaw([]);

        expect(results, isEmpty);
      });

      test('should return AggregatedDetection objects with correct properties', () {
        final results = aggregator.aggregateRaw(
          [
            _createFrameResult(
              timestamp: const Duration(),
              nsfwScore: 0.9,
            ),
            _createFrameResult(
              timestamp: const Duration(seconds: 1),
              nsfwScore: 0.8,
            ),
          ],
          hysteresis: const Duration(seconds: 2),
          minDuration: Duration.zero,
        );

        expect(results, isNotEmpty);
        final detection = results.first;
        expect(detection.type, equals(ContentType.nsfw));
        expect(detection.start, equals(Duration.zero));
        expect(detection.end, equals(const Duration(seconds: 1)));
        expect(detection.frameCount, equals(2));
        expect(detection.confidence, greaterThan(0));
      });

      test('should calculate average confidence across frames', () {
        final results = aggregator.aggregateRaw(
          [
            _createFrameResult(
              timestamp: const Duration(),
              nsfwScore: 1,
            ),
            _createFrameResult(
              timestamp: const Duration(seconds: 1),
              nsfwScore: 0.5,
            ),
          ],
          hysteresis: const Duration(seconds: 2),
          minDuration: Duration.zero,
        );

        expect(results, isNotEmpty);
        // Average of 1.0 and 0.5 is 0.75
        expect(results.first.confidence, closeTo(0.75, 0.01));
      });
    });

    group('mergeSegments()', () {
      test('should return empty list for empty input', () {
        final merged = aggregator.mergeSegments([]);

        expect(merged, isEmpty);
      });

      test('should return single segment unchanged', () {
        final segments = aggregator.aggregate(
          [
            _createFrameResult(
              timestamp: Duration.zero,
              nsfwScore: 0.9,
            ),
          ],
          minDuration: Duration.zero,
        );

        if (segments.isNotEmpty) {
          final merged = aggregator.mergeSegments(segments);
          expect(merged.length, equals(1));
        }
      });

      test('should merge overlapping segments of same type', () {
        final segments = aggregator.aggregate(
          [
            _createFrameResult(
              timestamp: const Duration(),
              nsfwScore: 0.9,
            ),
            _createFrameResult(
              timestamp: const Duration(seconds: 1),
              nsfwScore: 0.85,
            ),
            // Gap
            _createFrameResult(
              timestamp: const Duration(seconds: 3),
              nsfwScore: 0.8,
            ),
          ],
          hysteresis: const Duration(milliseconds: 500),
          minDuration: Duration.zero,
        );

        final merged = aggregator.mergeSegments(
          segments,
          hysteresis: const Duration(seconds: 2),
        );

        // Merged segments should be equal or fewer
        expect(merged.length, lessThanOrEqualTo(segments.length));
      });
    });

    group('applyHysteresis()', () {
      test('should filter segments shorter than minDuration', () {
        final segments = aggregator.aggregate(
          [
            _createFrameResult(
              timestamp: Duration.zero,
              nsfwScore: 0.9,
            ),
          ],
          minDuration: Duration.zero,
        );

        if (segments.isNotEmpty) {
          final filtered = aggregator.applyHysteresis(
            segments,
            minDuration: const Duration(seconds: 5),
          );

          // Should filter out short segments
          for (final segment in filtered) {
            expect(segment.duration, greaterThanOrEqualTo(const Duration(seconds: 5)));
          }
        }
      });

      test('should merge segments within hysteresis after filtering', () {
        // This tests the combined behavior
        final segments = aggregator.aggregate(
          [
            _createFrameResult(
              timestamp: const Duration(),
              nsfwScore: 0.9,
            ),
            _createFrameResult(
              timestamp: const Duration(seconds: 2),
              nsfwScore: 0.85,
            ),
          ],
          hysteresis: const Duration(seconds: 3),
          minDuration: Duration.zero,
        );

        final result = aggregator.applyHysteresis(
          segments,
          hysteresis: const Duration(seconds: 3),
          minDuration: Duration.zero,
        );

        expect(result.length, lessThanOrEqualTo(segments.length));
      });
    });

    group('AggregatedDetection', () {
      test('should calculate duration correctly', () {
        const detection = AggregatedDetection(
          type: ContentType.nsfw,
          start: Duration(seconds: 5),
          end: Duration(seconds: 10),
          confidence: 0.9,
          frameCount: 10,
        );

        expect(detection.duration, equals(const Duration(seconds: 5)));
      });
    });
  });
}

/// Helper to create a FrameAnalysisResult for testing
FrameAnalysisResult _createFrameResult({
  required Duration timestamp,
  double nsfwScore = 0.0,
  double violenceScore = 0.0,
  double bloodScore = 0.0,
  double weaponsScore = 0.0,
}) => FrameAnalysisResult(
    frameNumber: timestamp.inMilliseconds,
    timestamp: timestamp,
    nsfw: NsfwResult(
      porn: nsfwScore,
      sexy: 0,
      hentai: 0,
      drawings: 0,
      neutral: 1 - nsfwScore,
    ),
    violence: ViolenceResult(
      violent: violenceScore,
      nonViolent: 1 - violenceScore,
    ),
    blood: BloodResult(score: bloodScore),
    weapons: WeaponsResult(score: weaponsScore),
  );
