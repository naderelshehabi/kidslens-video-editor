import 'package:flutter_test/flutter_test.dart';
import 'package:kidslens_video_editor/data/models/frame_analysis_result.dart';
import 'package:kidslens_video_editor/data/models/modification.dart';
import 'package:kidslens_video_editor/data/models/visual_content_category.dart';
import 'package:kidslens_video_editor/services/region_temporal_aggregator.dart';

// ---------------------------------------------------------------------------
// Helper: build a FrameAnalysisResult suitable for region-aggregation tests
// ---------------------------------------------------------------------------
FrameAnalysisResult _makeFrame({
  required int frameNumber,
  required Duration timestamp,
  bool isSceneChange = false,
  List<DetectedRegion>? regions,
  Map<String, double>? clipScores,
}) =>
    FrameAnalysisResult(
      frameNumber: frameNumber,
      timestamp: timestamp,
      isSceneChange: isSceneChange,
      nsfw: NsfwResult.safe(),
      violence: ViolenceResult.safe(),
      visualContent: (regions != null || clipScores != null)
          ? VisualContentResult(
              detectedRegions: regions ?? [],
              clipScores: clipScores ?? {},
            )
          : null,
    );

// ---------------------------------------------------------------------------
// Helper categories
// ---------------------------------------------------------------------------
VisualContentCategory _nudityCategory() => const VisualContentCategory(
      id: 'nudity',
      name: 'Nudity',
      description: 'Test',
      detectionSource: CategoryDetectionSource.nudeNet,
      detectionLabels: ['FEMALE_BREAST_EXPOSED', 'BUTTOCKS_EXPOSED'],
      threshold: 0.4,
    );

VisualContentCategory _kissingCategory() => const VisualContentCategory(
      id: 'kissing',
      name: 'Kissing',
      description: 'Test',
      detectionSource: CategoryDetectionSource.clip,
      clipThreshold: 3.0,
      action: VisualContentAction.cutScene,
    );

VisualContentCategory _sexualCategory() => const VisualContentCategory(
      id: 'sexual',
      name: 'Sexual',
      description: 'Test',
      detectionSource: CategoryDetectionSource.both,
      detectionLabels: ['FEMALE_BREAST_EXPOSED'],
      threshold: 0.4,
      clipThreshold: 4.0,
    );

// ---------------------------------------------------------------------------
// Convenience: a DetectedRegion at a given position / confidence
// ---------------------------------------------------------------------------
DetectedRegion _region({
  String label = 'FEMALE_BREAST_EXPOSED',
  double x = 0.3,
  double y = 0.3,
  double width = 0.2,
  double height = 0.2,
  double confidence = 0.8,
}) =>
    DetectedRegion(
      label: label,
      x: x,
      y: y,
      width: width,
      height: height,
      confidence: confidence,
    );

void main() {
  late RegionTemporalAggregator aggregator;

  setUp(() {
    aggregator = RegionTemporalAggregator();
  });

  // =========================================================================
  // 1. TrackedRegion.padAndClamp
  // =========================================================================
  group('TrackedRegion.padAndClamp', () {
    test('pads box by 10% in each direction', () {
      // A 0.2 x 0.2 box starting at (0.3, 0.3).
      // padX = 0.2 * 0.10 = 0.02, padY = 0.2 * 0.10 = 0.02
      // Expected: x=0.28, y=0.28, w=0.24, h=0.24
      final b = TrackedRegion.padAndClamp(0.3, 0.3, 0.2, 0.2);

      expect(b.x, closeTo(0.28, 1e-9));
      expect(b.y, closeTo(0.28, 1e-9));
      expect(b.width, closeTo(0.24, 1e-9));
      expect(b.height, closeTo(0.24, 1e-9));
    });

    test('clamps to [0,1] bounds for box at edge of frame', () {
      // Box at top-left corner: x=0.0, y=0.0, w=0.5, h=0.5
      // padX = 0.5 * 0.10 = 0.05, padY = 0.05
      // Before clamp: x=-0.05, y=-0.05, w=0.6, h=0.6
      // After clamp:  x=0.0,   y=0.0,   w=min(0.6, 1.0)=0.6, h=0.6
      final b = TrackedRegion.padAndClamp(0.0, 0.0, 0.5, 0.5);

      expect(b.x, equals(0.0));
      expect(b.y, equals(0.0));
      // Width clamped to min(0.6, 1.0 - 0.0) = 0.6
      expect(b.width, closeTo(0.6, 1e-9));
      expect(b.height, closeTo(0.6, 1e-9));
    });

    test('clamps to [0,1] for box at bottom-right edge', () {
      // Box near bottom-right: x=0.8, y=0.8, w=0.2, h=0.2
      // padX = 0.02, padY = 0.02
      // Before clamp: x=0.78, y=0.78, w=0.24, h=0.24
      // After clamp: w = min(0.24, 1.0-0.78) = min(0.24, 0.22) = 0.22
      final b = TrackedRegion.padAndClamp(0.8, 0.8, 0.2, 0.2);

      expect(b.x, closeTo(0.78, 1e-9));
      expect(b.y, closeTo(0.78, 1e-9));
      expect(b.width, closeTo(0.22, 1e-9));
      expect(b.height, closeTo(0.22, 1e-9));
    });

    test('handles box at origin with small size', () {
      // x=0.0, y=0.0, w=0.1, h=0.1
      // padX=0.01, padY=0.01
      // Before clamp: x=-0.01, y=-0.01, w=0.12, h=0.12
      // After clamp: x=0, y=0, w=min(0.12, 1.0)=0.12, h=0.12
      final b = TrackedRegion.padAndClamp(0.0, 0.0, 0.1, 0.1);

      expect(b.x, equals(0.0));
      expect(b.y, equals(0.0));
      expect(b.width, closeTo(0.12, 1e-9));
      expect(b.height, closeTo(0.12, 1e-9));
    });
  });

  // =========================================================================
  // 2. IoU matching
  // =========================================================================
  group('IoU matching', () {
    test('same region across frames gets tracked (IoU > 0.45)', () {
      // Three frames with heavily overlapping regions for the same category.
      final frames = [
        _makeFrame(
          frameNumber: 0,
          timestamp: Duration.zero,
          regions: [_region(x: 0.3, y: 0.3, width: 0.2, height: 0.2)],
        ),
        _makeFrame(
          frameNumber: 1,
          timestamp: const Duration(milliseconds: 200),
          regions: [_region(x: 0.31, y: 0.31, width: 0.2, height: 0.2)],
        ),
        _makeFrame(
          frameNumber: 2,
          timestamp: const Duration(milliseconds: 400),
          regions: [_region(x: 0.32, y: 0.32, width: 0.2, height: 0.2)],
        ),
      ];

      final result = aggregator.aggregate(frames, [_nudityCategory()]);

      // All three detections should merge into a single tracked region.
      expect(result.trackedRegions, hasLength(1));
      expect(result.trackedRegions.first.categoryId, equals('nudity'));
      expect(result.trackedRegions.first.keyframes, hasLength(3));
      expect(result.trackedRegions.first.startTime, equals(Duration.zero));
      expect(
        result.trackedRegions.first.endTime,
        equals(const Duration(milliseconds: 400)),
      );
    });

    test('different locations create separate tracks', () {
      final frames = [
        _makeFrame(
          frameNumber: 0,
          timestamp: Duration.zero,
          regions: [
            _region(x: 0.0, y: 0.0, width: 0.1, height: 0.1),
          ],
        ),
        _makeFrame(
          frameNumber: 1,
          timestamp: const Duration(milliseconds: 200),
          regions: [
            _region(x: 0.8, y: 0.8, width: 0.1, height: 0.1),
          ],
        ),
      ];

      final result = aggregator.aggregate(frames, [_nudityCategory()]);

      // Non-overlapping boxes -> two separate tracked regions.
      expect(result.trackedRegions, hasLength(2));
    });

    test('IoU below threshold creates new track', () {
      // Two boxes that overlap slightly but IoU < 0.45.
      final frames = [
        _makeFrame(
          frameNumber: 0,
          timestamp: Duration.zero,
          regions: [_region(x: 0.0, y: 0.0, width: 0.2, height: 0.2)],
        ),
        _makeFrame(
          frameNumber: 1,
          timestamp: const Duration(milliseconds: 200),
          regions: [_region(x: 0.15, y: 0.15, width: 0.2, height: 0.2)],
        ),
      ];

      final result = aggregator.aggregate(frames, [_nudityCategory()]);

      // Overlap area is small relative to union -> should be two regions.
      expect(result.trackedRegions, hasLength(2));
    });
  });

  // =========================================================================
  // 3. Scene change handling
  // =========================================================================
  group('Scene change handling', () {
    test('scene change finalizes all active regions', () {
      final frames = [
        _makeFrame(
          frameNumber: 0,
          timestamp: Duration.zero,
          regions: [_region()],
        ),
        _makeFrame(
          frameNumber: 1,
          timestamp: const Duration(milliseconds: 200),
          regions: [_region()],
        ),
        // Scene change at frame 2 — should finalize previous region.
        _makeFrame(
          frameNumber: 2,
          timestamp: const Duration(milliseconds: 400),
          isSceneChange: true,
          regions: [_region()],
        ),
        _makeFrame(
          frameNumber: 3,
          timestamp: const Duration(milliseconds: 600),
          regions: [_region()],
        ),
      ];

      final result = aggregator.aggregate(frames, [_nudityCategory()]);

      // Two tracked regions: one before the scene change, one after.
      expect(result.trackedRegions, hasLength(2));
    });

    test('regions do not carry across scene boundaries', () {
      final frames = [
        _makeFrame(
          frameNumber: 0,
          timestamp: Duration.zero,
          regions: [_region(x: 0.3, y: 0.3, width: 0.2, height: 0.2)],
        ),
        _makeFrame(
          frameNumber: 1,
          timestamp: const Duration(milliseconds: 500),
          isSceneChange: true,
          regions: [_region(x: 0.3, y: 0.3, width: 0.2, height: 0.2)],
        ),
      ];

      final result = aggregator.aggregate(frames, [_nudityCategory()]);

      // Even though bounding boxes are identical, the scene change should
      // split them into separate tracked regions.
      expect(result.trackedRegions, hasLength(2));
      expect(
        result.trackedRegions.first.endTime,
        equals(Duration.zero),
      );
      expect(
        result.trackedRegions.last.startTime,
        equals(const Duration(milliseconds: 500)),
      );
    });
  });

  // =========================================================================
  // 4. Gap bridging
  // =========================================================================
  group('Gap bridging', () {
    test('region disappears for < 1s then reappears -> extended', () {
      final frames = [
        _makeFrame(
          frameNumber: 0,
          timestamp: Duration.zero,
          regions: [_region()],
        ),
        // No region at 500ms — within gap tolerance.
        _makeFrame(
          frameNumber: 1,
          timestamp: const Duration(milliseconds: 500),
        ),
        // Region reappears at 800ms (gap = 800ms < 1s).
        _makeFrame(
          frameNumber: 2,
          timestamp: const Duration(milliseconds: 800),
          regions: [_region()],
        ),
      ];

      final result = aggregator.aggregate(frames, [_nudityCategory()]);

      // Should still be one tracked region, extended across the gap.
      expect(result.trackedRegions, hasLength(1));
      expect(result.trackedRegions.first.keyframes, hasLength(2));
      expect(
        result.trackedRegions.first.endTime,
        equals(const Duration(milliseconds: 800)),
      );
    });

    test('region disappears for > 1s -> finalized and new track starts', () {
      // Intermediate frames must have non-null visualContent (even if empty)
      // so the aggregator does not skip them with `continue` and actually
      // runs the stale-region expiry logic.
      final frames = [
        _makeFrame(
          frameNumber: 0,
          timestamp: Duration.zero,
          regions: [_region()],
        ),
        // No region at 600ms — still within gap tolerance.
        _makeFrame(
          frameNumber: 1,
          timestamp: const Duration(milliseconds: 600),
          regions: [],
        ),
        // No region at 1200ms — triggers expiry (gap = 1200ms > 1000ms).
        _makeFrame(
          frameNumber: 2,
          timestamp: const Duration(milliseconds: 1200),
          regions: [],
        ),
        // Region reappears at 1500ms -> new track.
        _makeFrame(
          frameNumber: 3,
          timestamp: const Duration(milliseconds: 1500),
          regions: [_region()],
        ),
      ];

      final result = aggregator.aggregate(frames, [_nudityCategory()]);

      // Two separate tracked regions because of the >1s gap.
      expect(result.trackedRegions, hasLength(2));
      expect(result.trackedRegions.first.startTime, equals(Duration.zero));
      expect(
        result.trackedRegions.last.startTime,
        equals(const Duration(milliseconds: 1500)),
      );
    });
  });

  // =========================================================================
  // 5. CLIP-only categories
  // =========================================================================
  group('CLIP-only categories', () {
    test('CLIP score above threshold creates scene action', () {
      final frames = [
        _makeFrame(
          frameNumber: 0,
          timestamp: Duration.zero,
          clipScores: {'kissing': 5.0},
        ),
      ];

      final result = aggregator.aggregate(frames, [_kissingCategory()]);

      // No tracked regions (CLIP has no bounding boxes).
      expect(result.trackedRegions, isEmpty);
      // One scene action.
      expect(result.sceneActions, hasLength(1));
      expect(result.sceneActions.first.categoryId, equals('kissing'));
      expect(result.sceneActions.first.action, equals(VisualContentAction.cutScene));
    });

    test('CLIP score below threshold is ignored', () {
      final frames = [
        _makeFrame(
          frameNumber: 0,
          timestamp: Duration.zero,
          clipScores: {'kissing': 1.5}, // below 3.0
        ),
      ];

      final result = aggregator.aggregate(frames, [_kissingCategory()]);

      expect(result.trackedRegions, isEmpty);
      expect(result.sceneActions, isEmpty);
    });

    test('scene actions are extended for consecutive frames', () {
      final frames = [
        _makeFrame(
          frameNumber: 0,
          timestamp: Duration.zero,
          clipScores: {'kissing': 5.0},
        ),
        _makeFrame(
          frameNumber: 1,
          timestamp: const Duration(milliseconds: 200),
          clipScores: {'kissing': 4.5},
        ),
        _makeFrame(
          frameNumber: 2,
          timestamp: const Duration(milliseconds: 400),
          clipScores: {'kissing': 4.0},
        ),
      ];

      final result = aggregator.aggregate(frames, [_kissingCategory()]);

      // All three should merge into one scene action.
      expect(result.sceneActions, hasLength(1));
      expect(result.sceneActions.first.startTime, equals(Duration.zero));
      expect(
        result.sceneActions.first.endTime,
        equals(const Duration(milliseconds: 400)),
      );
    });
  });

  // =========================================================================
  // 6. "both" source fusion
  // =========================================================================
  group('"both" source fusion', () {
    test('NudeNet region without CLIP confirmation is ignored', () {
      final frames = [
        _makeFrame(
          frameNumber: 0,
          timestamp: Duration.zero,
          regions: [_region(label: 'FEMALE_BREAST_EXPOSED', confidence: 0.8)],
          // No CLIP score for "sexual" category — should be ignored.
          clipScores: {},
        ),
      ];

      final result = aggregator.aggregate(frames, [_sexualCategory()]);

      expect(result.trackedRegions, isEmpty);
      expect(result.sceneActions, isEmpty);
    });

    test('NudeNet region with CLIP above threshold is tracked', () {
      final frames = [
        _makeFrame(
          frameNumber: 0,
          timestamp: Duration.zero,
          regions: [_region(label: 'FEMALE_BREAST_EXPOSED', confidence: 0.8)],
          clipScores: {'sexual': 5.0}, // above clipThreshold 4.0
        ),
      ];

      final result = aggregator.aggregate(frames, [_sexualCategory()]);

      expect(result.trackedRegions, hasLength(1));
      expect(result.trackedRegions.first.categoryId, equals('sexual'));
    });

    test('NudeNet region with CLIP below threshold is ignored', () {
      final frames = [
        _makeFrame(
          frameNumber: 0,
          timestamp: Duration.zero,
          regions: [_region(label: 'FEMALE_BREAST_EXPOSED', confidence: 0.8)],
          clipScores: {'sexual': 2.0}, // below clipThreshold 4.0
        ),
      ];

      final result = aggregator.aggregate(frames, [_sexualCategory()]);

      expect(result.trackedRegions, isEmpty);
    });
  });

  // =========================================================================
  // 7. Region cap
  // =========================================================================
  group('Region cap', () {
    test('excess concurrent regions are converted to scene-level blur', () {
      // Create a single frame with 22 non-overlapping regions for the nudity
      // category. This exceeds maxConcurrentRegions (20).
      final manyRegions = List.generate(
        22,
        (i) => _region(
          label: 'FEMALE_BREAST_EXPOSED',
          x: (i % 10) * 0.1,
          y: (i ~/ 10) * 0.1,
          width: 0.05,
          height: 0.05,
          confidence: 0.8,
        ),
      );

      final frames = [
        _makeFrame(
          frameNumber: 0,
          timestamp: Duration.zero,
          regions: manyRegions,
        ),
      ];

      final result = aggregator.aggregate(frames, [_nudityCategory()]);

      // The cap logic should have converted the excess regions for the
      // category with the most active regions into a scene-level blur action.
      expect(result.sceneActions, isNotEmpty);
      expect(
        result.sceneActions.any(
          (a) =>
              a.categoryId == 'nudity' &&
              a.action == VisualContentAction.blurRegion,
        ),
        isTrue,
      );
    });
  });

  // =========================================================================
  // 8. Empty inputs
  // =========================================================================
  group('Empty inputs', () {
    test('no frames produces empty result', () {
      final result = aggregator.aggregate([], [_nudityCategory()]);

      expect(result.trackedRegions, isEmpty);
      expect(result.sceneActions, isEmpty);
    });

    test('frames with no visual content produce empty result', () {
      final frames = [
        _makeFrame(
          frameNumber: 0,
          timestamp: Duration.zero,
        ),
        _makeFrame(
          frameNumber: 1,
          timestamp: const Duration(milliseconds: 500),
        ),
      ];

      final result = aggregator.aggregate(frames, [_nudityCategory()]);

      expect(result.trackedRegions, isEmpty);
      expect(result.sceneActions, isEmpty);
    });

    test('frames with visual content but no matching categories produce empty result', () {
      final frames = [
        _makeFrame(
          frameNumber: 0,
          timestamp: Duration.zero,
          regions: [_region(label: 'SOME_OTHER_LABEL')],
        ),
      ];

      final result = aggregator.aggregate(frames, [_nudityCategory()]);

      expect(result.trackedRegions, isEmpty);
      expect(result.sceneActions, isEmpty);
    });
  });
}
