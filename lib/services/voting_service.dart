import 'dart:math';

import 'package:kidslens_video_editor/data/models/content_category.dart';
import 'package:kidslens_video_editor/data/models/frame_analysis_result.dart';
import 'package:kidslens_video_editor/data/models/voting_config.dart';

/// A single model's vote for a content category.
class ModelVote {
  const ModelVote({
    required this.modelId,
    required this.score,
    required this.weight,
    this.regions,
  });

  /// ID of the model that produced this vote.
  final String modelId;

  /// Normalized score (0.0 - 1.0) from this model.
  final double score;

  /// Weight for this vote (accuracy × contribution weight).
  final double weight;

  /// Optional detected regions (for NudeNet / detection models).
  final List<DetectedRegion>? regions;

  @override
  String toString() =>
      'ModelVote(modelId: $modelId, score: ${score.toStringAsFixed(3)}, '
      'weight: ${weight.toStringAsFixed(3)}, '
      'regions: ${regions?.length ?? 0})';
}

/// Result of MoE voting for a single content category.
class CategoryVoteResult {
  const CategoryVoteResult({
    required this.categoryId,
    required this.finalScore,
    required this.triggered,
    required this.votes,
    this.regions,
  });

  /// Category ID this result is for.
  final String categoryId;

  /// Aggregated consensus score (0.0 - 1.0).
  final double finalScore;

  /// Whether the score met the category's threshold.
  final bool triggered;

  /// Individual model votes that contributed.
  final List<ModelVote> votes;

  /// Merged regions from all region-producing models (after NMS).
  final List<DetectedRegion>? regions;

  /// Number of models that voted.
  int get voterCount => votes.length;

  @override
  String toString() =>
      'CategoryVoteResult(categoryId: $categoryId, '
      'score: ${finalScore.toStringAsFixed(3)}, triggered: $triggered, '
      'voters: $voterCount)';
}

/// Service for aggregating multiple model outputs into a consensus
/// via Mixture-of-Experts (MoE) weighted voting.
class VotingService {
  const VotingService();

  /// Compute a consensus score for a category from multiple model votes.
  ///
  /// Uses the [VotingConfig.strategy] to combine votes and checks against
  /// the [category]'s threshold to determine if the detection is triggered.
  CategoryVoteResult computeConsensus({
    required ContentCategory category,
    required List<ModelVote> votes,
    required VotingConfig config,
  }) {
    if (votes.isEmpty) {
      return CategoryVoteResult(
        categoryId: category.id,
        finalScore: 0,
        triggered: false,
        votes: const [],
      );
    }

    // Check minimum voters requirement
    if (votes.length < config.minVoters) {
      return CategoryVoteResult(
        categoryId: category.id,
        finalScore: 0,
        triggered: false,
        votes: votes,
      );
    }

    final double finalScore;

    switch (config.strategy) {
      case VotingStrategy.weightedAverage:
        finalScore = _weightedAverage(votes);

      case VotingStrategy.maximum:
        finalScore = votes.map((v) => v.score).reduce(max);

      case VotingStrategy.minimum:
        finalScore = votes.map((v) => v.score).reduce(min);
    }

    // Merge regions from all votes that have them
    final allRegions = votes
        .where((v) => v.regions != null && v.regions!.isNotEmpty)
        .expand((v) => v.regions!)
        .toList();

    final mergedRegions =
        allRegions.isNotEmpty ? mergeOverlappingRegions(allRegions) : null;

    return CategoryVoteResult(
      categoryId: category.id,
      finalScore: finalScore,
      triggered: finalScore >= category.threshold,
      votes: votes,
      regions: mergedRegions,
    );
  }

  /// Weighted average: Σ(score × weight) / Σ(weights).
  double _weightedAverage(List<ModelVote> votes) {
    var weightSum = 0.0;
    var scoreSum = 0.0;

    for (final vote in votes) {
      scoreSum += vote.score * vote.weight;
      weightSum += vote.weight;
    }

    return weightSum > 0 ? (scoreSum / weightSum).clamp(0.0, 1.0) : 0.0;
  }

  /// Merge overlapping regions using greedy NMS (Non-Maximum Suppression).
  ///
  /// Regions from different models with IoU >= [iouThreshold] are merged
  /// by taking the bounding-box union and the higher confidence.
  List<DetectedRegion> mergeOverlappingRegions(
    List<DetectedRegion> regions, {
    double iouThreshold = 0.5,
  }) {
    if (regions.isEmpty) return [];

    // Sort by confidence descending
    final sorted = List<DetectedRegion>.from(regions)
      ..sort((a, b) => b.confidence.compareTo(a.confidence));

    final merged = <DetectedRegion>[];
    final used = <int>{};

    for (var i = 0; i < sorted.length; i++) {
      if (used.contains(i)) continue;

      var current = sorted[i];
      used.add(i);

      // Find overlapping lower-confidence regions and merge
      for (var j = i + 1; j < sorted.length; j++) {
        if (used.contains(j)) continue;

        final iou = computeIoU(current, sorted[j]);
        if (iou >= iouThreshold) {
          current = _mergeBoxes(current, sorted[j]);
          used.add(j);
        }
      }

      merged.add(current);
    }

    return merged;
  }

  /// Compute Intersection over Union (IoU) between two detected regions.
  double computeIoU(DetectedRegion a, DetectedRegion b) {
    final x1 = max(a.x, b.x);
    final y1 = max(a.y, b.y);
    final x2 = min(a.x + a.width, b.x + b.width);
    final y2 = min(a.y + a.height, b.y + b.height);

    if (x2 <= x1 || y2 <= y1) return 0;

    final intersection = (x2 - x1) * (y2 - y1);
    final areaA = a.width * a.height;
    final areaB = b.width * b.height;
    final union = areaA + areaB - intersection;

    return union > 0 ? intersection / union : 0.0;
  }

  /// Merge two bounding boxes by taking their union.
  DetectedRegion _mergeBoxes(DetectedRegion a, DetectedRegion b) {
    final x = min(a.x, b.x);
    final y = min(a.y, b.y);
    final x2 = max(a.x + a.width, b.x + b.width);
    final y2 = max(a.y + a.height, b.y + b.height);

    return DetectedRegion(
      label: a.label, // Keep higher-confidence label (a is sorted first)
      confidence: max(a.confidence, b.confidence),
      x: x,
      y: y,
      width: x2 - x,
      height: y2 - y,
    );
  }
}
