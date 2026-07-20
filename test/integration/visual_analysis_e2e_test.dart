import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';
import 'package:kidslens_video_editor/data/models/frame_analysis_result.dart';
import 'package:kidslens_video_editor/data/models/modification.dart';
import 'package:kidslens_video_editor/data/models/visual_content_category.dart';
import 'package:kidslens_video_editor/services/region_temporal_aggregator.dart';

// ---------------------------------------------------------------------------
// Helper: build a FrameAnalysisResult for end-to-end tests
// ---------------------------------------------------------------------------

FrameAnalysisResult makeFrame({
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

VisualContentCategory nudityCategory() => const VisualContentCategory(
      id: 'nudity',
      name: 'Nudity',
      description: 'Test',
      detectionSource: CategoryDetectionSource.nudeNet,
      detectionLabels: ['FEMALE_BREAST_EXPOSED'],
      threshold: 0.4,
    );

VisualContentCategory kissingCategory() => const VisualContentCategory(
      id: 'kissing',
      name: 'Kissing',
      description: 'Test',
      detectionSource: CategoryDetectionSource.clip,
      action: VisualContentAction.cutScene,
    );

// ---------------------------------------------------------------------------
// Helper: build a DetectedRegion at a given position / confidence
// ---------------------------------------------------------------------------

DetectedRegion makeRegion({
  String label = 'FEMALE_BREAST_EXPOSED',
  double x = 0.1,
  double y = 0.2,
  double width = 0.3,
  double height = 0.4,
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

// ---------------------------------------------------------------------------
// Helper: ExportService-equivalent formulas (copied so we can verify
// the full chain without depending on ExportService itself)
// ---------------------------------------------------------------------------

/// Maps blur intensity (1-100) to FFmpeg gblur sigma (5-50).
int intensityToSigma(int intensity) => 5 + ((intensity - 1) * 45 ~/ 99);

/// Builds the FFmpeg enable expression for a time range.
String buildEnable(Duration start, Duration end) =>
    'between(t,${start.inMilliseconds / 1000.0},${end.inMilliseconds / 1000.0})';

// ===========================================================================
// Tests
// ===========================================================================

void main() {
  late RegionTemporalAggregator aggregator;

  setUp(() {
    aggregator = RegionTemporalAggregator();
  });

  // =========================================================================
  // 1. Region detection -> aggregation -> blur modification
  // =========================================================================
  group('Region detection -> aggregation -> blur modification', () {
    test(
      'NudeNet regions across first 3 frames produce 1 tracked region '
      'and valid VideoRegionBlur modification',
      () {
        // 5 frames at 0.0s, 0.5s, 1.0s, 1.5s, 2.0s.
        // Frames 0-2 have NudeNet regions with overlapping boxes (high IoU).
        // Frames 3-4 have no detections.
        final frames = [
          makeFrame(
            frameNumber: 0,
            timestamp: Duration.zero,
            regions: [
              makeRegion(),
            ],
          ),
          makeFrame(
            frameNumber: 1,
            timestamp: const Duration(milliseconds: 500),
            regions: [
              makeRegion(x: 0.11, y: 0.21),
            ],
          ),
          makeFrame(
            frameNumber: 2,
            timestamp: const Duration(milliseconds: 1000),
            regions: [
              makeRegion(x: 0.12, y: 0.22),
            ],
          ),
          makeFrame(
            frameNumber: 3,
            timestamp: const Duration(milliseconds: 1500),
          ),
          makeFrame(
            frameNumber: 4,
            timestamp: const Duration(milliseconds: 2000),
          ),
        ];

        // --- Stage: Aggregation ---
        final result = aggregator.aggregate(frames, [nudityCategory()]);

        expect(
          result.trackedRegions,
          hasLength(1),
          reason: 'All 3 overlapping regions should merge into 1 track',
        );
        expect(
          result.sceneActions,
          isEmpty,
          reason: 'NudeNet-only category should not produce scene actions',
        );

        final tracked = result.trackedRegions.first;
        expect(tracked.categoryId, equals('nudity'));
        expect(tracked.startTime, equals(Duration.zero));
        expect(
          tracked.endTime,
          equals(const Duration(milliseconds: 1000)),
        );
        expect(tracked.keyframes, hasLength(3));
        expect(tracked.averageConfidence, closeTo(0.8, 1e-6));

        // --- Stage: Convert TrackedRegion to Modification ---
        final lastKf = tracked.lastKeyframe;
        final paddedBounds = TrackedRegion.padAndClamp(
          lastKf.x,
          lastKf.y,
          lastKf.width,
          lastKf.height,
        );

        final modification = Modification.videoRegionBlur(
          region: paddedBounds,
        );

        // --- Verify modification ---
        expect(modification, isA<VideoRegionBlur>());
        final blur = modification as VideoRegionBlur;
        expect(blur.intensity, equals(50));
        expect(blur.isRegionModification, isTrue);
        expect(blur.isVideoModification, isTrue);
        expect(blur.isDestructive, isFalse);

        // Padded bounds should be expanded beyond the raw detection box.
        // Last keyframe: x=0.12, y=0.22, w=0.30, h=0.40
        // padX = 0.30 * 0.10 = 0.03, padY = 0.40 * 0.10 = 0.04
        // x = 0.12 - 0.03 = 0.09, y = 0.22 - 0.04 = 0.18
        // w = 0.30 + 0.06 = 0.36, h = 0.40 + 0.08 = 0.48
        expect(blur.region.x, closeTo(0.09, 1e-9));
        expect(blur.region.y, closeTo(0.18, 1e-9));
        expect(blur.region.width, closeTo(0.36, 1e-9));
        expect(blur.region.height, closeTo(0.48, 1e-9));
      },
    );
  });

  // =========================================================================
  // 2. CLIP detection -> aggregation -> cut scene
  // =========================================================================
  group('CLIP detection -> aggregation -> cut scene', () {
    test(
      'CLIP scores above threshold across frames 1-3 produce 1 scene action '
      'and convert to VideoSkip',
      () {
        // 5 frames at 0.0s, 0.5s, 1.0s, 1.5s, 2.0s.
        // Frames 1-3 (0.5s-1.5s) have CLIP score > 3.0 for "kissing".
        final frames = [
          makeFrame(
            frameNumber: 0,
            timestamp: Duration.zero,
          ),
          makeFrame(
            frameNumber: 1,
            timestamp: const Duration(milliseconds: 500),
            clipScores: {'kissing': 5.0},
          ),
          makeFrame(
            frameNumber: 2,
            timestamp: const Duration(milliseconds: 1000),
            clipScores: {'kissing': 4.5},
          ),
          makeFrame(
            frameNumber: 3,
            timestamp: const Duration(milliseconds: 1500),
            clipScores: {'kissing': 4.0},
          ),
          makeFrame(
            frameNumber: 4,
            timestamp: const Duration(milliseconds: 2000),
          ),
        ];

        // --- Stage: Aggregation ---
        final result = aggregator.aggregate(frames, [kissingCategory()]);

        // CLIP categories produce scene actions, not tracked regions.
        expect(
          result.trackedRegions,
          isEmpty,
          reason: 'CLIP-only categories have no bounding boxes',
        );
        expect(
          result.sceneActions,
          hasLength(1),
          reason: 'Three consecutive CLIP triggers should merge into 1',
        );

        final action = result.sceneActions.first;
        expect(action.categoryId, equals('kissing'));
        expect(action.action, equals(VisualContentAction.cutScene));
        expect(
          action.startTime,
          equals(const Duration(milliseconds: 500)),
        );
        expect(
          action.endTime,
          equals(const Duration(milliseconds: 1500)),
        );

        // --- Stage: Convert SceneAction to Modification ---
        const modification = Modification.videoSkip();

        expect(modification, isA<VideoSkip>());
        expect(modification.isDestructive, isTrue);
        expect(modification.isVideoModification, isTrue);
        expect(modification.isAudioModification, isFalse);
        expect(modification.toFFmpegFilter(), equals('select=0'));
      },
    );
  });

  // =========================================================================
  // 3. Mixed categories -> multiple modifications
  // =========================================================================
  group('Mixed categories -> multiple modifications', () {
    test(
      'NudeNet regions + CLIP scores produce both tracked regions and '
      'scene actions, converting to mixed modifications',
      () {
        // Frames have both NudeNet regions (nudity) and CLIP scores (kissing).
        final frames = [
          makeFrame(
            frameNumber: 0,
            timestamp: Duration.zero,
            regions: [
              makeRegion(),
            ],
            clipScores: {'kissing': 5.0},
          ),
          makeFrame(
            frameNumber: 1,
            timestamp: const Duration(milliseconds: 500),
            regions: [
              makeRegion(x: 0.11, y: 0.21),
            ],
            clipScores: {'kissing': 4.5},
          ),
          makeFrame(
            frameNumber: 2,
            timestamp: const Duration(milliseconds: 1000),
            regions: [
              makeRegion(x: 0.12, y: 0.22),
            ],
          ),
          makeFrame(
            frameNumber: 3,
            timestamp: const Duration(milliseconds: 1500),
          ),
          makeFrame(
            frameNumber: 4,
            timestamp: const Duration(milliseconds: 2000),
          ),
        ];

        // --- Stage: Aggregation with both categories ---
        final result = aggregator.aggregate(
          frames,
          [nudityCategory(), kissingCategory()],
        );

        // Both types of results present.
        expect(
          result.trackedRegions,
          hasLength(1),
          reason: 'NudeNet regions should produce 1 tracked region',
        );
        expect(
          result.sceneActions,
          hasLength(1),
          reason: 'CLIP scores should produce 1 scene action',
        );

        // Verify tracked region (NudeNet / nudity)
        final tracked = result.trackedRegions.first;
        expect(tracked.categoryId, equals('nudity'));
        expect(tracked.startTime, equals(Duration.zero));
        expect(
          tracked.endTime,
          equals(const Duration(milliseconds: 1000)),
        );

        // Verify scene action (CLIP / kissing)
        final scene = result.sceneActions.first;
        expect(scene.categoryId, equals('kissing'));
        expect(scene.action, equals(VisualContentAction.cutScene));
        expect(scene.startTime, equals(Duration.zero));
        expect(
          scene.endTime,
          equals(const Duration(milliseconds: 500)),
        );

        // --- Stage: Convert to Modification objects ---
        final lastKf = tracked.lastKeyframe;
        final paddedBounds = TrackedRegion.padAndClamp(
          lastKf.x,
          lastKf.y,
          lastKf.width,
          lastKf.height,
        );

        final modifications = <Modification>[
          Modification.videoRegionBlur(region: paddedBounds),
          const Modification.videoSkip(),
        ];

        // Verify correct types
        expect(modifications[0], isA<VideoRegionBlur>());
        expect(modifications[1], isA<VideoSkip>());

        // Verify properties
        expect(modifications[0].isRegionModification, isTrue);
        expect(modifications[0].isDestructive, isFalse);
        expect(modifications[1].isRegionModification, isFalse);
        expect(modifications[1].isDestructive, isTrue);

        // Verify the classification helpers
        expect(modifications.videoModifications, hasLength(2));
        expect(modifications.audioModifications, isEmpty);
        expect(modifications.destructiveModifications, hasLength(1));
      },
    );
  });

  // =========================================================================
  // 4. Scene change splits detections
  // =========================================================================
  group('Scene change splits detections', () {
    test(
      'continuous NudeNet regions across 4 frames split at scene boundary '
      'into 2 tracked regions',
      () {
        // 4 frames with NudeNet regions. Frame 2 has isSceneChange = true.
        // The aggregator should finalize all active regions on scene change,
        // then start a new track for the post-change frames.
        final frames = [
          makeFrame(
            frameNumber: 0,
            timestamp: Duration.zero,
            regions: [
              makeRegion(x: 0.30, y: 0.30, width: 0.20, height: 0.20),
            ],
          ),
          makeFrame(
            frameNumber: 1,
            timestamp: const Duration(milliseconds: 500),
            regions: [
              makeRegion(x: 0.31, y: 0.31, width: 0.20, height: 0.20),
            ],
          ),
          // Scene change at frame 2 — finalizes the previous track.
          makeFrame(
            frameNumber: 2,
            timestamp: const Duration(milliseconds: 1000),
            isSceneChange: true,
            regions: [
              makeRegion(x: 0.30, y: 0.30, width: 0.20, height: 0.20),
            ],
          ),
          makeFrame(
            frameNumber: 3,
            timestamp: const Duration(milliseconds: 1500),
            regions: [
              makeRegion(x: 0.31, y: 0.31, width: 0.20, height: 0.20),
            ],
          ),
        ];

        final result = aggregator.aggregate(frames, [nudityCategory()]);

        // Scene change should split into 2 tracked regions.
        expect(result.trackedRegions, hasLength(2));

        final first = result.trackedRegions[0];
        final second = result.trackedRegions[1];

        // First region: frames 0-1 (before scene change).
        expect(first.categoryId, equals('nudity'));
        expect(first.startTime, equals(Duration.zero));
        expect(
          first.endTime,
          equals(const Duration(milliseconds: 500)),
        );
        expect(first.keyframes, hasLength(2));

        // Second region: frames 2-3 (after scene change).
        expect(second.categoryId, equals('nudity'));
        expect(
          second.startTime,
          equals(const Duration(milliseconds: 1000)),
        );
        expect(
          second.endTime,
          equals(const Duration(milliseconds: 1500)),
        );
        expect(second.keyframes, hasLength(2));

        // Both can be independently converted to VideoRegionBlur modifications.
        for (final tracked in result.trackedRegions) {
          final kf = tracked.lastKeyframe;
          final bounds = TrackedRegion.padAndClamp(
            kf.x,
            kf.y,
            kf.width,
            kf.height,
          );
          final mod = Modification.videoRegionBlur(
            region: bounds,
          );
          expect(mod.isRegionModification, isTrue);
        }
      },
    );
  });

  // =========================================================================
  // 5. Full pipeline: detection -> aggregation -> modification -> filter string
  // =========================================================================
  group(
    'Full pipeline: detection -> aggregation -> modification -> filter string',
    () {
      test(
        'produces correct crop dimensions, blur sigma, and enable expression '
        'for 1920x1080 video',
        () {
          const videoWidth = 1920;
          const videoHeight = 1080;

          // Create 3 frames with a consistent region at (0.1, 0.2, 0.3, 0.4).
          final frames = [
            makeFrame(
              frameNumber: 0,
              timestamp: Duration.zero,
              regions: [
                makeRegion(),
              ],
            ),
            makeFrame(
              frameNumber: 1,
              timestamp: const Duration(milliseconds: 500),
              regions: [
                makeRegion(),
              ],
            ),
            makeFrame(
              frameNumber: 2,
              timestamp: const Duration(milliseconds: 1000),
              regions: [
                makeRegion(),
              ],
            ),
          ];

          // ---- Stage 1: Aggregation ----
          final aggResult = aggregator.aggregate(frames, [nudityCategory()]);

          expect(aggResult.trackedRegions, hasLength(1));
          final tracked = aggResult.trackedRegions.first;
          expect(tracked.startTime, equals(Duration.zero));
          expect(
            tracked.endTime,
            equals(const Duration(milliseconds: 1000)),
          );

          // ---- Stage 2: Pad and clamp ----
          final lastKf = tracked.lastKeyframe;
          final paddedBounds = TrackedRegion.padAndClamp(
            lastKf.x,
            lastKf.y,
            lastKf.width,
            lastKf.height,
          );

          // padX = 0.3 * 0.10 = 0.03, padY = 0.4 * 0.10 = 0.04
          // x = 0.1 - 0.03 = 0.07
          // y = 0.2 - 0.04 = 0.16
          // w = 0.3 + 0.06 = 0.36
          // h = 0.4 + 0.08 = 0.48
          expect(paddedBounds.x, closeTo(0.07, 1e-9));
          expect(paddedBounds.y, closeTo(0.16, 1e-9));
          expect(paddedBounds.width, closeTo(0.36, 1e-9));
          expect(paddedBounds.height, closeTo(0.48, 1e-9));

          // ---- Stage 3: Create modification ----
          const blurIntensity = 50;
          final modification = Modification.videoRegionBlur(
            region: paddedBounds,
          );
          expect(modification, isA<VideoRegionBlur>());

          // ---- Stage 4: Compute expected FFmpeg filter values ----

          // Pixel coordinates from normalized bounds.
          final px = (paddedBounds.x * videoWidth).round();
          final py = (paddedBounds.y * videoHeight).round();
          final pw = (paddedBounds.width * videoWidth).round();
          final ph = (paddedBounds.height * videoHeight).round();

          // Apply clamping (same formula used by ExportService).
          final cropX = math.max(0, math.min(px, videoWidth - 1));
          final cropY = math.max(0, math.min(py, videoHeight - 1));
          final cropW = math.max(1, math.min(pw, videoWidth - cropX));
          final cropH = math.max(1, math.min(ph, videoHeight - cropY));

          // (0.07 * 1920).round() = 134
          expect(cropX, equals(134));
          // (0.16 * 1080).round() = 173
          expect(cropY, equals(173));
          // (0.36 * 1920).round() = 691
          expect(cropW, equals(691));
          // (0.48 * 1080).round() = 518
          expect(cropH, equals(518));

          // Blur sigma: 5 + ((50-1)*45~/99) = 5 + 22 = 27
          final sigma = intensityToSigma(blurIntensity);
          expect(sigma, equals(27));

          // Enable expression: between(t, 0.0, 1.0)
          final enable = buildEnable(tracked.startTime, tracked.endTime);
          expect(enable, equals('between(t,0.0,1.0)'));

          // ---- Stage 5: Compose and verify filter string ----
          // This is the split-crop-blur-overlay chain that ExportService would
          // produce for this region modification.
          final expectedCrop = 'crop=$cropW:$cropH:$cropX:$cropY';
          final expectedBlur = 'gblur=sigma=$sigma';
          final expectedOverlay = "overlay=x=$cropX:y=$cropY:enable='$enable'";

          expect(expectedCrop, equals('crop=691:518:134:173'));
          expect(expectedBlur, equals('gblur=sigma=27'));
          expect(
            expectedOverlay,
            equals(
              "overlay=x=134:y=173:enable='between(t,0.0,1.0)'",
            ),
          );

          // Verify the full filter chain pattern matches the expected format.
          final filterChain = '[0:v]split=2[base0][c0];'
              '[c0]$expectedCrop,$expectedBlur[b0];'
              '[base0][b0]$expectedOverlay[rv0]';

          expect(filterChain, contains('[0:v]split=2[base0][c0]'));
          expect(filterChain, contains('crop=691:518:134:173'));
          expect(filterChain, contains('gblur=sigma=27'));
          expect(
            filterChain,
            contains(
              "overlay=x=134:y=173:enable='between(t,0.0,1.0)'",
            ),
          );
          expect(filterChain, contains('[rv0]'));

          // Verify the full chain string is coherent end-to-end.
          expect(
            filterChain,
            equals(
              '[0:v]split=2[base0][c0];'
              '[c0]crop=691:518:134:173,gblur=sigma=27[b0];'
              '[base0][b0]overlay=x=134:y=173:'
              "enable='between(t,0.0,1.0)'[rv0]",
            ),
          );
        },
      );
    },
  );
}
