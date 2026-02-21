import 'dart:math' as math;

import 'package:kidslens_video_editor/data/models/content_category.dart';
import 'package:kidslens_video_editor/data/models/frame_analysis_result.dart';
import 'package:kidslens_video_editor/data/models/modification.dart';
import 'package:kidslens_video_editor/data/models/visual_content_category.dart';
import 'package:kidslens_video_editor/services/visual_analysis_service.dart';
import 'package:kidslens_video_editor/services/voting_service.dart';

/// A bounding box at a specific timestamp in the video.
class TimestampedBoundingBox {
  const TimestampedBoundingBox({
    required this.timestamp,
    required this.x,
    required this.y,
    required this.width,
    required this.height,
    required this.confidence,
  });

  final Duration timestamp;
  final double x;
  final double y;
  final double width;
  final double height;
  final double confidence;
}

/// A tracked region across multiple frames for a specific category.
class TrackedRegion {
  TrackedRegion({
    required this.categoryId,
    required this.startTime,
    required this.endTime,
    required List<TimestampedBoundingBox> keyframes,
    required this.averageConfidence,
  }) : keyframes = List.of(keyframes);

  final String categoryId;
  Duration startTime;
  Duration endTime;
  final List<TimestampedBoundingBox> keyframes;
  double averageConfidence;

  /// Duration of this tracked region.
  Duration get duration => endTime - startTime;

  /// Most recent bounding box.
  TimestampedBoundingBox get lastKeyframe => keyframes.last;

  /// Expand box by a percentage in each direction and re-clamp.
  static RegionBounds padAndClamp(
    double x,
    double y,
    double w,
    double h, {
    double padding = 0.10,
  }) {
    final padX = w * padding;
    final padY = h * padding;
    var px = x - padX;
    var py = y - padY;
    var pw = w + padX * 2;
    var ph = h + padY * 2;
    // Clamp to image bounds
    px = math.max(0.0, px);
    py = math.max(0.0, py);
    pw = math.min(pw, 1.0 - px);
    ph = math.min(ph, 1.0 - py);
    return RegionBounds(x: px, y: py, width: pw, height: ph);
  }
}

/// Result of temporal aggregation for region-based detections.
class RegionAggregationResult {
  const RegionAggregationResult({
    required this.trackedRegions,
    required this.sceneActions,
  });

  /// All tracked regions across the video, grouped by category.
  final List<TrackedRegion> trackedRegions;

  /// Scene-level actions (cut/full-frame blur) keyed by (startTime, endTime).
  final List<SceneAction> sceneActions;
}

/// A scene-level action (cut or full-frame blur) for a time range.
class SceneAction {
  const SceneAction({
    required this.categoryId,
    required this.startTime,
    required this.endTime,
    required this.action,
  });

  final String categoryId;
  final Duration startTime;
  final Duration endTime;
  final VisualContentAction action;
}

/// Aggregates per-frame visual content detections into temporally coherent
/// tracked regions and scene-level actions.
///
/// This handles:
/// - IoU-based region tracking across frames
/// - Gap bridging (detection disappears for <= 1 second)
/// - Scene change boundary handling
/// - CLIP-only categories → scene-level actions
/// - "both" source fusion (CLIP AND NudeNet)
/// - Region cap (>20 concurrent → fall back to full-frame)
class RegionTemporalAggregator {
  RegionTemporalAggregator({
    this.iouThreshold = 0.45,
    this.maxGapDuration = const Duration(seconds: 1),
    this.boundingBoxPadding = 0.10,
    this.maxConcurrentRegions = 20,
  });

  /// IoU threshold for matching detections across frames.
  final double iouThreshold;

  /// Maximum gap to bridge between detections of the same region.
  final Duration maxGapDuration;

  /// Padding to expand bounding boxes (fraction, e.g. 0.10 = 10%).
  final double boundingBoxPadding;

  /// Maximum concurrent tracked regions before falling back to full-frame.
  final int maxConcurrentRegions;

  /// Active tracked regions being built.
  final List<TrackedRegion> _activeRegions = [];

  /// Finalized tracked regions.
  final List<TrackedRegion> _finalizedRegions = [];

  /// Scene-level actions collected from CLIP-only and cut categories.
  final List<SceneAction> _sceneActions = [];

  /// Aggregate frame analysis results into tracked regions and scene actions.
  ///
  /// [results] must be sorted by timestamp.
  /// [categories] are the enabled visual content categories.
  RegionAggregationResult aggregate(
    List<FrameAnalysisResult> results,
    List<VisualContentCategory> categories,
  ) {
    _activeRegions.clear();
    _finalizedRegions.clear();
    _sceneActions.clear();

    final categoryMap = {for (final c in categories) c.id: c};

    for (final frame in results) {
      // On scene change, finalize all active regions
      if (frame.isSceneChange) {
        _finalizeAllActive();
      }

      final visualContent = frame.visualContent;
      if (visualContent == null) continue;

      // Process NudeNet regions (categories with nudeNet or both source)
      _processNudeNetRegions(
        frame.timestamp,
        visualContent,
        categoryMap,
      );

      // Process CLIP scores (categories with clip or both source)
      _processClipScores(
        frame.timestamp,
        visualContent,
        categoryMap,
      );

      // Expire stale active regions (gap > maxGapDuration)
      _expireStaleRegions(frame.timestamp);

      // Check concurrent region cap
      _checkRegionCap(frame.timestamp);
    }

    // Finalize remaining active regions
    _finalizeAllActive();

    return RegionAggregationResult(
      trackedRegions: List.unmodifiable(_finalizedRegions),
      sceneActions: List.unmodifiable(_sceneActions),
    );
  }

  /// Process NudeNet detection regions for a frame.
  void _processNudeNetRegions(
    Duration timestamp,
    VisualContentResult visualContent,
    Map<String, VisualContentCategory> categoryMap,
  ) {
    for (final category in categoryMap.values) {
      if (!category.enabled) continue;
      if (!category.usesNudeNet) continue;

      // For "both" source, check that CLIP also triggered
      if (category.detectionSource == CategoryDetectionSource.both) {
        final clipScore = visualContent.clipScores[category.id];
        if (clipScore == null || clipScore < category.clipThreshold) {
          continue; // CLIP didn't confirm — skip this category
        }
      }

      // Find NudeNet regions matching this category's labels
      final matchingRegions = visualContent.detectedRegions.where(
        (r) =>
            category.detectionLabels.contains(r.label) &&
            r.confidence >= category.threshold,
      );

      for (final region in matchingRegions) {
        _matchOrCreateRegion(
          categoryId: category.id,
          timestamp: timestamp,
          x: region.x,
          y: region.y,
          width: region.width,
          height: region.height,
          confidence: region.confidence,
        );
      }
    }
  }

  /// Process CLIP classification scores for a frame.
  void _processClipScores(
    Duration timestamp,
    VisualContentResult visualContent,
    Map<String, VisualContentCategory> categoryMap,
  ) {
    for (final entry in visualContent.clipScores.entries) {
      final category = categoryMap[entry.key];
      if (category == null || !category.enabled) continue;

      // Only process CLIP-only categories here (both is handled in NudeNet)
      if (category.detectionSource != CategoryDetectionSource.clip) continue;

      final score = entry.value;
      if (score < category.clipThreshold) continue;

      // CLIP categories don't have bounding boxes
      if (category.action == VisualContentAction.cutScene) {
        // Add scene-level cut action
        _addOrExtendSceneAction(
          categoryId: category.id,
          timestamp: timestamp,
          action: category.action,
        );
      } else {
        // CLIP-only with blur/pixelate → full-frame scene action
        _addOrExtendSceneAction(
          categoryId: category.id,
          timestamp: timestamp,
          action: category.action,
        );
      }
    }
  }

  /// Try to match a detection to an existing tracked region, or create a new one.
  void _matchOrCreateRegion({
    required String categoryId,
    required Duration timestamp,
    required double x,
    required double y,
    required double width,
    required double height,
    required double confidence,
  }) {
    // Find best matching active region (same category, IoU above threshold)
    TrackedRegion? bestMatch;
    double bestIoU = 0;

    for (final region in _activeRegions) {
      if (region.categoryId != categoryId) continue;

      final iou = _computeIoU(
        region.lastKeyframe.x,
        region.lastKeyframe.y,
        region.lastKeyframe.width,
        region.lastKeyframe.height,
        x,
        y,
        width,
        height,
      );

      if (iou >= iouThreshold && iou > bestIoU) {
        bestIoU = iou;
        bestMatch = region;
      }
    }

    final keyframe = TimestampedBoundingBox(
      timestamp: timestamp,
      x: x,
      y: y,
      width: width,
      height: height,
      confidence: confidence,
    );

    if (bestMatch != null) {
      // Extend existing region
      bestMatch.endTime = timestamp;
      bestMatch.keyframes.add(keyframe);
      // Update running average confidence
      final n = bestMatch.keyframes.length;
      bestMatch.averageConfidence =
          bestMatch.averageConfidence * (n - 1) / n + confidence / n;
    } else {
      // Create new tracked region
      _activeRegions.add(TrackedRegion(
        categoryId: categoryId,
        startTime: timestamp,
        endTime: timestamp,
        keyframes: [keyframe],
        averageConfidence: confidence,
      ));
    }
  }

  /// Add or extend a scene-level action.
  void _addOrExtendSceneAction({
    required String categoryId,
    required Duration timestamp,
    required VisualContentAction action,
  }) {
    // Try to extend the most recent scene action for this category
    for (var i = _sceneActions.length - 1; i >= 0; i--) {
      final existing = _sceneActions[i];
      if (existing.categoryId != categoryId) continue;
      if (existing.action != action) continue;

      // Check if the gap is bridgeable
      if (timestamp - existing.endTime <= maxGapDuration) {
        _sceneActions[i] = SceneAction(
          categoryId: categoryId,
          startTime: existing.startTime,
          endTime: timestamp,
          action: action,
        );
        return;
      }
      break; // Only check the most recent for this category
    }

    // Create new scene action
    _sceneActions.add(SceneAction(
      categoryId: categoryId,
      startTime: timestamp,
      endTime: timestamp,
      action: action,
    ));
  }

  /// Expire active regions that haven't been updated within maxGapDuration.
  void _expireStaleRegions(Duration currentTime) {
    final toFinalize = <TrackedRegion>[];

    for (final region in _activeRegions) {
      if (currentTime - region.endTime > maxGapDuration) {
        toFinalize.add(region);
      }
    }

    for (final region in toFinalize) {
      _activeRegions.remove(region);
      _finalizedRegions.add(region);
    }
  }

  /// Finalize all active regions (e.g., on scene change or end of video).
  void _finalizeAllActive() {
    _finalizedRegions.addAll(_activeRegions);
    _activeRegions.clear();
  }

  /// Check if concurrent region count exceeds the cap.
  /// If so, merge nearby regions or fall back to full-frame blur.
  void _checkRegionCap(Duration timestamp) {
    if (_activeRegions.length <= maxConcurrentRegions) return;

    // Too many concurrent regions — fall back to scene-level blur
    // for each excess category
    final categoryCounts = <String, int>{};
    for (final region in _activeRegions) {
      categoryCounts[region.categoryId] =
          (categoryCounts[region.categoryId] ?? 0) + 1;
    }

    // Find categories with most regions and convert to scene-level
    final sortedCategories = categoryCounts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    for (final entry in sortedCategories) {
      if (_activeRegions.length <= maxConcurrentRegions) break;

      // Convert all regions of this category to a single scene action
      final regionsToRemove = _activeRegions
          .where((r) => r.categoryId == entry.key)
          .toList();

      if (regionsToRemove.isEmpty) continue;

      final earliest = regionsToRemove
          .map((r) => r.startTime)
          .reduce((a, b) => a < b ? a : b);

      _addOrExtendSceneAction(
        categoryId: entry.key,
        timestamp: timestamp,
        action: VisualContentAction.blurRegion, // Full-frame blur fallback
      );

      for (final r in regionsToRemove) {
        _activeRegions.remove(r);
      }
    }
  }

  /// Compute IoU (Intersection over Union) between two bounding boxes.
  double _computeIoU(
    double x1,
    double y1,
    double w1,
    double h1,
    double x2,
    double y2,
    double w2,
    double h2,
  ) {
    final ix1 = math.max(x1, x2);
    final iy1 = math.max(y1, y2);
    final ix2 = math.min(x1 + w1, x2 + w2);
    final iy2 = math.min(y1 + h1, y2 + h2);

    if (ix2 <= ix1 || iy2 <= iy1) return 0.0;

    final intersection = (ix2 - ix1) * (iy2 - iy1);
    final union = w1 * h1 + w2 * h2 - intersection;

    return union > 0 ? intersection / union : 0.0;
  }
}

/// A scene-level action using the new [RemediationAction] from content categories.
class MoESceneAction {
  const MoESceneAction({
    required this.categoryId,
    required this.startTime,
    required this.endTime,
    required this.action,
    required this.confidence,
  });

  final String categoryId;
  final Duration startTime;
  final Duration endTime;
  final RemediationAction action;
  final double confidence;
}

/// Result of MoE-based temporal aggregation.
class MoEAggregationResult {
  const MoEAggregationResult({
    required this.trackedRegions,
    required this.sceneActions,
  });

  /// Tracked bounding-box regions across frames, grouped by category.
  final List<TrackedRegion> trackedRegions;

  /// Scene-level actions (cut, full-frame blur, etc.) from MoE results.
  final List<MoESceneAction> sceneActions;
}

/// Aggregates [MoEFrameResult]s into temporally coherent tracked regions
/// and scene-level actions using the new MoE voting pipeline.
///
/// Similar to [RegionTemporalAggregator] but works with [MoEFrameResult]
/// and [ContentCategory] instead of the legacy [VisualContentCategory].
class MoETemporalAggregator {
  MoETemporalAggregator({
    this.iouThreshold = 0.45,
    this.maxGapDuration = const Duration(seconds: 1),
    this.maxConcurrentRegions = 20,
  });

  final double iouThreshold;
  final Duration maxGapDuration;
  final int maxConcurrentRegions;

  final List<TrackedRegion> _activeRegions = [];
  final List<TrackedRegion> _finalizedRegions = [];
  final List<MoESceneAction> _sceneActions = [];

  /// Aggregate MoE frame results into tracked regions and scene actions.
  ///
  /// [results] must be sorted by timestamp.
  /// [categories] are the enabled content categories (for action lookup).
  MoEAggregationResult aggregate(
    List<MoEFrameResult> results,
    List<ContentCategory> categories,
  ) {
    _activeRegions.clear();
    _finalizedRegions.clear();
    _sceneActions.clear();

    final categoryMap = {for (final c in categories) c.id: c};

    for (final frame in results) {
      for (final entry in frame.categoryResults.entries) {
        final categoryId = entry.key;
        final voteResult = entry.value;
        final category = categoryMap[categoryId];
        if (category == null) continue;
        if (!voteResult.triggered) continue;

        // If category supports regions and we have regions, track them
        if (category.supportsRegions &&
            voteResult.regions != null &&
            voteResult.regions!.isNotEmpty &&
            category.action.isRegionLevel) {
          for (final region in voteResult.regions!) {
            _matchOrCreateRegion(
              categoryId: categoryId,
              timestamp: frame.timestamp,
              x: region.x,
              y: region.y,
              width: region.width,
              height: region.height,
              confidence: region.confidence,
            );
          }
        } else {
          // Scene-level action (cut, full-frame blur, mute, beep)
          _addOrExtendSceneAction(
            categoryId: categoryId,
            timestamp: frame.timestamp,
            action: category.action,
            confidence: voteResult.finalScore,
          );
        }
      }

      // Expire stale regions
      _expireStaleRegions(frame.timestamp);

      // Check region cap
      if (_activeRegions.length > maxConcurrentRegions) {
        _fallbackToSceneLevel(frame.timestamp, categoryMap);
      }
    }

    _finalizedRegions.addAll(_activeRegions);
    _activeRegions.clear();

    return MoEAggregationResult(
      trackedRegions: List.unmodifiable(_finalizedRegions),
      sceneActions: List.unmodifiable(_sceneActions),
    );
  }

  void _matchOrCreateRegion({
    required String categoryId,
    required Duration timestamp,
    required double x,
    required double y,
    required double width,
    required double height,
    required double confidence,
  }) {
    TrackedRegion? bestMatch;
    double bestIoU = 0;

    for (final region in _activeRegions) {
      if (region.categoryId != categoryId) continue;

      final last = region.lastKeyframe;
      final iou = _computeIoU(
        last.x, last.y, last.width, last.height,
        x, y, width, height,
      );

      if (iou >= iouThreshold && iou > bestIoU) {
        bestIoU = iou;
        bestMatch = region;
      }
    }

    final keyframe = TimestampedBoundingBox(
      timestamp: timestamp,
      x: x, y: y, width: width, height: height,
      confidence: confidence,
    );

    if (bestMatch != null) {
      bestMatch.endTime = timestamp;
      bestMatch.keyframes.add(keyframe);
      final n = bestMatch.keyframes.length;
      bestMatch.averageConfidence =
          bestMatch.averageConfidence * (n - 1) / n + confidence / n;
    } else {
      _activeRegions.add(TrackedRegion(
        categoryId: categoryId,
        startTime: timestamp,
        endTime: timestamp,
        keyframes: [keyframe],
        averageConfidence: confidence,
      ));
    }
  }

  void _addOrExtendSceneAction({
    required String categoryId,
    required Duration timestamp,
    required RemediationAction action,
    required double confidence,
  }) {
    for (var i = _sceneActions.length - 1; i >= 0; i--) {
      final existing = _sceneActions[i];
      if (existing.categoryId != categoryId) continue;
      if (existing.action != action) continue;

      if (timestamp - existing.endTime <= maxGapDuration) {
        _sceneActions[i] = MoESceneAction(
          categoryId: categoryId,
          startTime: existing.startTime,
          endTime: timestamp,
          action: action,
          confidence: (existing.confidence + confidence) / 2,
        );
        return;
      }
      break;
    }

    _sceneActions.add(MoESceneAction(
      categoryId: categoryId,
      startTime: timestamp,
      endTime: timestamp,
      action: action,
      confidence: confidence,
    ));
  }

  void _expireStaleRegions(Duration currentTime) {
    final toFinalize = <TrackedRegion>[];
    for (final region in _activeRegions) {
      if (currentTime - region.endTime > maxGapDuration) {
        toFinalize.add(region);
      }
    }
    for (final region in toFinalize) {
      _activeRegions.remove(region);
      _finalizedRegions.add(region);
    }
  }

  void _fallbackToSceneLevel(
    Duration timestamp,
    Map<String, ContentCategory> categoryMap,
  ) {
    final categoryCounts = <String, int>{};
    for (final region in _activeRegions) {
      categoryCounts[region.categoryId] =
          (categoryCounts[region.categoryId] ?? 0) + 1;
    }

    final sorted = categoryCounts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    for (final entry in sorted) {
      if (_activeRegions.length <= maxConcurrentRegions) break;

      final category = categoryMap[entry.key];
      final action = category?.action ?? RemediationAction.blurFullFrame;

      final regionsToRemove = _activeRegions
          .where((r) => r.categoryId == entry.key)
          .toList();

      if (regionsToRemove.isEmpty) continue;

      _addOrExtendSceneAction(
        categoryId: entry.key,
        timestamp: timestamp,
        action: action,
        confidence: regionsToRemove
            .map((r) => r.averageConfidence)
            .reduce(math.max),
      );

      for (final r in regionsToRemove) {
        _activeRegions.remove(r);
      }
    }
  }

  double _computeIoU(
    double x1, double y1, double w1, double h1,
    double x2, double y2, double w2, double h2,
  ) {
    final ix1 = math.max(x1, x2);
    final iy1 = math.max(y1, y2);
    final ix2 = math.min(x1 + w1, x2 + w2);
    final iy2 = math.min(y1 + h1, y2 + h2);

    if (ix2 <= ix1 || iy2 <= iy1) return 0.0;

    final intersection = (ix2 - ix1) * (iy2 - iy1);
    final union = w1 * h1 + w2 * h2 - intersection;

    return union > 0 ? intersection / union : 0.0;
  }
}
