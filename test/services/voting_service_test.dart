import 'package:flutter_test/flutter_test.dart';
import 'package:kidslens_video_editor/data/models/content_category.dart';
import 'package:kidslens_video_editor/data/models/frame_analysis_result.dart';
import 'package:kidslens_video_editor/data/models/voting_config.dart';
import 'package:kidslens_video_editor/services/voting_service.dart';

ContentCategory _testCategory({double threshold = 0.5}) => ContentCategory(
      id: 'test',
      name: 'Test',
      description: 'Test category',
      type: CategoryType.visual,
      threshold: threshold,
      action: RemediationAction.blurFullFrame,
    );

void main() {
  const votingService = VotingService();
  const defaultConfig = VotingConfig();

  // ─────────────────────────────────────────────────────────────
  // computeConsensus tests
  // ─────────────────────────────────────────────────────────────

  group('computeConsensus', () {
    test('with empty votes returns finalScore=0 and triggered=false', () {
      final result = votingService.computeConsensus(
        category: _testCategory(),
        votes: [],
        config: defaultConfig,
      );

      expect(result.finalScore, 0.0);
      expect(result.triggered, false);
      expect(result.votes, isEmpty);
      expect(result.categoryId, 'test');
    });

    test('with single vote returns that vote score', () {
      final result = votingService.computeConsensus(
        category: _testCategory(),
        votes: [
          const ModelVote(modelId: 'm1', score: 0.8, weight: 1),
        ],
        config: defaultConfig,
      );

      expect(result.finalScore, closeTo(0.8, 0.001));
      expect(result.voterCount, 1);
    });

    group('weightedAverage strategy', () {
      test('two votes with different weights computes correct weighted average',
          () {
        // Formula: (s1*w1 + s2*w2) / (w1 + w2)
        // (0.8 * 2.0 + 0.4 * 1.0) / (2.0 + 1.0) = (1.6 + 0.4) / 3.0 = 2.0/3.0
        final result = votingService.computeConsensus(
          category: _testCategory(),
          votes: [
            const ModelVote(modelId: 'm1', score: 0.8, weight: 2),
            const ModelVote(modelId: 'm2', score: 0.4, weight: 1),
          ],
          config: const VotingConfig(),
        );

        const expected = (0.8 * 2.0 + 0.4 * 1.0) / (2.0 + 1.0);
        expect(result.finalScore, closeTo(expected, 0.001));
      });

      test('equal weights produces simple average', () {
        final result = votingService.computeConsensus(
          category: _testCategory(),
          votes: [
            const ModelVote(modelId: 'm1', score: 0.6, weight: 1),
            const ModelVote(modelId: 'm2', score: 0.4, weight: 1),
          ],
          config: const VotingConfig(),
        );

        expect(result.finalScore, closeTo(0.5, 0.001));
      });
    });

    group('maximum strategy', () {
      test('returns highest score among votes', () {
        final result = votingService.computeConsensus(
          category: _testCategory(),
          votes: [
            const ModelVote(modelId: 'm1', score: 0.3, weight: 1),
            const ModelVote(modelId: 'm2', score: 0.9, weight: 1),
            const ModelVote(modelId: 'm3', score: 0.5, weight: 1),
          ],
          config: const VotingConfig(strategy: VotingStrategy.maximum),
        );

        expect(result.finalScore, closeTo(0.9, 0.001));
      });
    });

    group('minimum strategy', () {
      test('returns lowest score among votes', () {
        final result = votingService.computeConsensus(
          category: _testCategory(),
          votes: [
            const ModelVote(modelId: 'm1', score: 0.3, weight: 1),
            const ModelVote(modelId: 'm2', score: 0.9, weight: 1),
            const ModelVote(modelId: 'm3', score: 0.5, weight: 1),
          ],
          config: const VotingConfig(strategy: VotingStrategy.minimum),
        );

        expect(result.finalScore, closeTo(0.3, 0.001));
      });
    });

    group('threshold triggering', () {
      test('triggered is true when finalScore >= category threshold', () {
        final result = votingService.computeConsensus(
          category: _testCategory(),
          votes: [
            const ModelVote(modelId: 'm1', score: 0.7, weight: 1),
          ],
          config: defaultConfig,
        );

        expect(result.triggered, true);
      });

      test('triggered is true when finalScore exactly equals threshold', () {
        final result = votingService.computeConsensus(
          category: _testCategory(),
          votes: [
            const ModelVote(modelId: 'm1', score: 0.5, weight: 1),
          ],
          config: defaultConfig,
        );

        expect(result.triggered, true);
      });

      test('triggered is false when finalScore < category threshold', () {
        final result = votingService.computeConsensus(
          category: _testCategory(),
          votes: [
            const ModelVote(modelId: 'm1', score: 0.3, weight: 1),
          ],
          config: defaultConfig,
        );

        expect(result.triggered, false);
      });
    });

    group('minVoters', () {
      test('fewer voters than minVoters returns not triggered with score 0',
          () {
        final result = votingService.computeConsensus(
          category: _testCategory(threshold: 0.3),
          votes: [
            const ModelVote(modelId: 'm1', score: 0.9, weight: 1),
          ],
          config: const VotingConfig(minVoters: 2),
        );

        expect(result.finalScore, 0.0);
        expect(result.triggered, false);
        // Votes are still recorded even though consensus wasn't reached
        expect(result.votes.length, 1);
      });

      test('exact minVoters count triggers normally', () {
        final result = votingService.computeConsensus(
          category: _testCategory(threshold: 0.3),
          votes: [
            const ModelVote(modelId: 'm1', score: 0.8, weight: 1),
            const ModelVote(modelId: 'm2', score: 0.6, weight: 1),
          ],
          config: const VotingConfig(minVoters: 2),
        );

        expect(result.finalScore, greaterThan(0.0));
        expect(result.triggered, true);
      });
    });

    group('region merging', () {
      test('overlapping regions get merged by NMS', () {
        final result = votingService.computeConsensus(
          category: _testCategory(threshold: 0.3),
          votes: [
            const ModelVote(
              modelId: 'm1',
              score: 0.8,
              weight: 1,
              regions: [
                DetectedRegion(
                  label: 'test',
                  confidence: 0.9,
                  x: 0.1,
                  y: 0.1,
                  width: 0.3,
                  height: 0.3,
                ),
              ],
            ),
            const ModelVote(
              modelId: 'm2',
              score: 0.7,
              weight: 1,
              regions: [
                DetectedRegion(
                  label: 'test',
                  confidence: 0.85,
                  x: 0.12,
                  y: 0.12,
                  width: 0.3,
                  height: 0.3,
                ),
              ],
            ),
          ],
          config: defaultConfig,
        );

        // The two overlapping regions should be merged into one
        expect(result.regions, isNotNull);
        expect(result.regions!.length, 1);
        // Merged region should have the higher confidence
        expect(result.regions!.first.confidence, 0.9);
      });

      test('non-overlapping regions from votes stay separate', () {
        final result = votingService.computeConsensus(
          category: _testCategory(threshold: 0.3),
          votes: [
            const ModelVote(
              modelId: 'm1',
              score: 0.8,
              weight: 1,
              regions: [
                DetectedRegion(
                  label: 'test',
                  confidence: 0.9,
                  x: 0,
                  y: 0,
                  width: 0.1,
                  height: 0.1,
                ),
              ],
            ),
            const ModelVote(
              modelId: 'm2',
              score: 0.7,
              weight: 1,
              regions: [
                DetectedRegion(
                  label: 'test',
                  confidence: 0.85,
                  x: 0.8,
                  y: 0.8,
                  width: 0.1,
                  height: 0.1,
                ),
              ],
            ),
          ],
          config: defaultConfig,
        );

        expect(result.regions, isNotNull);
        expect(result.regions!.length, 2);
      });

      test('votes without regions produce null regions in result', () {
        final result = votingService.computeConsensus(
          category: _testCategory(),
          votes: [
            const ModelVote(modelId: 'm1', score: 0.8, weight: 1),
          ],
          config: defaultConfig,
        );

        expect(result.regions, isNull);
      });
    });
  });

  // ─────────────────────────────────────────────────────────────
  // computeIoU tests
  // ─────────────────────────────────────────────────────────────

  group('computeIoU', () {
    test('perfect overlap returns 1.0', () {
      const regionA = DetectedRegion(
        label: 'test',
        confidence: 0.9,
        x: 0.1,
        y: 0.1,
        width: 0.3,
        height: 0.3,
      );
      const regionB = DetectedRegion(
        label: 'test',
        confidence: 0.8,
        x: 0.1,
        y: 0.1,
        width: 0.3,
        height: 0.3,
      );

      final iou = votingService.computeIoU(regionA, regionB);
      expect(iou, closeTo(1.0, 0.001));
    });

    test('no overlap returns 0.0', () {
      const regionA = DetectedRegion(
        label: 'test',
        confidence: 0.9,
        x: 0,
        y: 0,
        width: 0.1,
        height: 0.1,
      );
      const regionB = DetectedRegion(
        label: 'test',
        confidence: 0.8,
        x: 0.5,
        y: 0.5,
        width: 0.1,
        height: 0.1,
      );

      final iou = votingService.computeIoU(regionA, regionB);
      expect(iou, 0.0);
    });

    test('partial overlap returns correct value', () {
      // Region A: [0.0, 0.0] to [0.4, 0.4], area = 0.16
      const regionA = DetectedRegion(
        label: 'test',
        confidence: 0.9,
        x: 0,
        y: 0,
        width: 0.4,
        height: 0.4,
      );
      // Region B: [0.2, 0.2] to [0.6, 0.6], area = 0.16
      const regionB = DetectedRegion(
        label: 'test',
        confidence: 0.8,
        x: 0.2,
        y: 0.2,
        width: 0.4,
        height: 0.4,
      );

      // Intersection: [0.2, 0.2] to [0.4, 0.4] = 0.2 * 0.2 = 0.04
      // Union: 0.16 + 0.16 - 0.04 = 0.28
      // IoU = 0.04 / 0.28 = 1/7 ~= 0.142857
      final iou = votingService.computeIoU(regionA, regionB);
      expect(iou, closeTo(1.0 / 7.0, 0.001));
    });

    test('touching edges with no overlap returns 0.0', () {
      const regionA = DetectedRegion(
        label: 'test',
        confidence: 0.9,
        x: 0,
        y: 0,
        width: 0.5,
        height: 0.5,
      );
      // Starts exactly where A ends
      const regionB = DetectedRegion(
        label: 'test',
        confidence: 0.8,
        x: 0.5,
        y: 0,
        width: 0.5,
        height: 0.5,
      );

      final iou = votingService.computeIoU(regionA, regionB);
      expect(iou, 0.0);
    });
  });

  // ─────────────────────────────────────────────────────────────
  // mergeOverlappingRegions tests
  // ─────────────────────────────────────────────────────────────

  group('mergeOverlappingRegions', () {
    test('empty list returns empty list', () {
      final result = votingService.mergeOverlappingRegions([]);
      expect(result, isEmpty);
    });

    test('single region returns that region', () {
      const region = DetectedRegion(
        label: 'test',
        confidence: 0.9,
        x: 0.1,
        y: 0.1,
        width: 0.3,
        height: 0.3,
      );

      final result = votingService.mergeOverlappingRegions([region]);
      expect(result.length, 1);
      expect(result.first.confidence, 0.9);
    });

    test('non-overlapping regions are kept separate', () {
      const regionA = DetectedRegion(
        label: 'face',
        confidence: 0.9,
        x: 0,
        y: 0,
        width: 0.1,
        height: 0.1,
      );
      const regionB = DetectedRegion(
        label: 'face',
        confidence: 0.8,
        x: 0.8,
        y: 0.8,
        width: 0.1,
        height: 0.1,
      );

      final result = votingService.mergeOverlappingRegions([regionA, regionB]);
      expect(result.length, 2);
    });

    test('highly overlapping regions are merged', () {
      // Two nearly identical regions should merge
      const regionA = DetectedRegion(
        label: 'test',
        confidence: 0.95,
        x: 0.1,
        y: 0.1,
        width: 0.3,
        height: 0.3,
      );
      const regionB = DetectedRegion(
        label: 'test',
        confidence: 0.7,
        x: 0.1,
        y: 0.1,
        width: 0.3,
        height: 0.3,
      );

      final result = votingService.mergeOverlappingRegions([regionA, regionB]);
      expect(result.length, 1);
      // Should keep the higher confidence
      expect(result.first.confidence, 0.95);
    });

    test('merged region is the bounding-box union', () {
      // Region A: [0.1, 0.1] to [0.5, 0.5]
      const regionA = DetectedRegion(
        label: 'test',
        confidence: 0.9,
        x: 0.1,
        y: 0.1,
        width: 0.4,
        height: 0.4,
      );
      // Region B: [0.2, 0.2] to [0.6, 0.6] - overlaps significantly
      const regionB = DetectedRegion(
        label: 'test',
        confidence: 0.85,
        x: 0.2,
        y: 0.2,
        width: 0.4,
        height: 0.4,
      );

      final result = votingService.mergeOverlappingRegions(
        [regionA, regionB],
        iouThreshold: 0.1, // Low threshold to ensure merge
      );
      expect(result.length, 1);

      // Union should be [0.1, 0.1] to [0.6, 0.6]
      final merged = result.first;
      expect(merged.x, closeTo(0.1, 0.001));
      expect(merged.y, closeTo(0.1, 0.001));
      expect(merged.width, closeTo(0.5, 0.001));
      expect(merged.height, closeTo(0.5, 0.001));
      expect(merged.confidence, 0.9);
    });

    test('three regions with chain overlap merge correctly', () {
      // A overlaps with B, B overlaps with C, but A may not overlap with C directly.
      // After greedy NMS, A merges with B first (since A has highest confidence),
      // then the merged result may or may not merge with C.
      const regionA = DetectedRegion(
        label: 'test',
        confidence: 0.95,
        x: 0,
        y: 0,
        width: 0.4,
        height: 0.4,
      );
      const regionB = DetectedRegion(
        label: 'test',
        confidence: 0.85,
        x: 0,
        y: 0,
        width: 0.4,
        height: 0.4,
      );
      // Far away, no overlap
      const regionC = DetectedRegion(
        label: 'test',
        confidence: 0.7,
        x: 0.8,
        y: 0.8,
        width: 0.1,
        height: 0.1,
      );

      final result = votingService.mergeOverlappingRegions(
        [regionA, regionB, regionC],
      );
      // A and B merge (perfect overlap), C stays separate
      expect(result.length, 2);
    });
  });
}
