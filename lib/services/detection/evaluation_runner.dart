import 'dart:convert';

import 'package:kidslens_video_editor/services/detection/evaluation_dataset.dart';

class EvaluationRunner {
  const EvaluationRunner({
    this.temporalIouThreshold = 0.3,
    this.boxIouThreshold = 0.3,
  });

  final double temporalIouThreshold;
  final double boxIouThreshold;

  EvaluationComparisonReport compare({
    required EvaluationDataset dataset,
    required List<EvaluationProfilePredictions> profilePredictions,
    String defaultProfileId = 'vlm_plus_grounding',
    String legacyProfileId = 'legacy_only',
    EvaluationThresholds thresholds = const EvaluationThresholds(),
  }) {
    final results = [
      for (final predictions in profilePredictions)
        evaluateProfile(dataset: dataset, predictions: predictions),
    ];
    final resultByProfile = {
      for (final result in results) result.profileId: result,
    };
    final defaultResult = resultByProfile[defaultProfileId];
    final legacyResult = resultByProfile[legacyProfileId];
    final exitGate = defaultResult == null || legacyResult == null
        ? const EvaluationExitGateResult(
            passed: false,
            issues: [
              'default and legacy profiles must both be evaluated',
            ],
          )
        : thresholds.evaluateDefaultVsLegacy(
            defaultResult: defaultResult,
            legacyResult: legacyResult,
          );
    return EvaluationComparisonReport(
      datasetId: dataset.id,
      datasetVersion: dataset.version,
      results: results,
      defaultProfileId: defaultProfileId,
      legacyProfileId: legacyProfileId,
      exitGate: exitGate,
    );
  }

  EvaluationProfileResult evaluateProfile({
    required EvaluationDataset dataset,
    required EvaluationProfilePredictions predictions,
  }) {
    final categories = <String>{
      for (final clip in dataset.clips)
        for (final truth in clip.groundTruth) truth.categoryId,
      for (final detections in predictions.detectionsByClipId.values)
        for (final detection in detections) detection.categoryId,
    };

    final categoryResults = <String, EvaluationMetricSet>{};
    final aggregate = _MetricAccumulator();
    final safeClipIds = dataset.clips
        .where((clip) => clip.isSafeControl)
        .map((clip) => clip.id)
        .toSet();
    final overallSafeFalsePositiveClips = dataset.clips
        .where(
          (clip) =>
              clip.isSafeControl &&
              (predictions.detectionsByClipId[clip.id]?.isNotEmpty ?? false),
        )
        .length;

    for (final category in categories) {
      final accumulator = _MetricAccumulator();
      var categorySafeFalsePositiveClips = 0;
      for (final clip in dataset.clips) {
        final truth = clip.groundTruth
            .where((annotation) => annotation.categoryId == category)
            .toList(growable: false);
        final predicted = (predictions.detectionsByClipId[clip.id] ??
                const <EvaluationAnnotation>[])
            .where((annotation) => annotation.categoryId == category)
            .toList(growable: false);
        final matched = _matchClip(truth: truth, predicted: predicted);
        accumulator.add(matched);
        aggregate.add(matched);
        if (clip.isSafeControl && predicted.isNotEmpty) {
          categorySafeFalsePositiveClips += 1;
        }
      }
      categoryResults[category] = accumulator.toMetrics(
        safeClipCount: safeClipIds.length,
        safeFalsePositiveClipCount: categorySafeFalsePositiveClips,
        totalDatasetDuration: _datasetDuration(dataset),
        chunkLatencyMs: predictions.chunkLatencyMs,
        memoryUsageMb: predictions.memoryUsageMb,
        vramUsageMb: predictions.vramUsageMb,
      );
    }

    final overall = aggregate.toMetrics(
      safeClipCount: safeClipIds.length,
      safeFalsePositiveClipCount: overallSafeFalsePositiveClips,
      totalDatasetDuration: _datasetDuration(dataset),
      chunkLatencyMs: predictions.chunkLatencyMs,
      memoryUsageMb: predictions.memoryUsageMb,
      vramUsageMb: predictions.vramUsageMb,
    );

    return EvaluationProfileResult(
      profileId: predictions.profileId,
      displayName: predictions.displayName,
      runtimeId: predictions.runtimeId,
      overall: overall,
      byCategory: categoryResults,
    );
  }

  _ClipMatchResult _matchClip({
    required List<EvaluationAnnotation> truth,
    required List<EvaluationAnnotation> predicted,
  }) {
    final unmatchedTruth = truth.toSet();
    final unmatchedPredictions = predicted.toSet();
    final matches = <_AnnotationMatch>[];

    while (unmatchedTruth.isNotEmpty && unmatchedPredictions.isNotEmpty) {
      _AnnotationMatch? best;
      for (final target in unmatchedTruth) {
        for (final candidate in unmatchedPredictions) {
          final temporalIou = _temporalIou(target, candidate);
          if (temporalIou < temporalIouThreshold) continue;
          final targetBox = target.box;
          final candidateBox = candidate.box;
          final boxIou = targetBox == null || candidateBox == null
              ? null
              : targetBox.iou(candidateBox);
          if (targetBox != null &&
              candidateBox != null &&
              boxIou! < boxIouThreshold) {
            continue;
          }
          final score = temporalIou + (boxIou ?? 0);
          if (best == null || score > best.score) {
            best = _AnnotationMatch(
              truth: target,
              prediction: candidate,
              temporalIou: temporalIou,
              boxIou: boxIou,
              maskIou: candidate.maskIouHint,
              score: score,
            );
          }
        }
      }
      if (best == null) break;
      matches.add(best);
      unmatchedTruth.remove(best.truth);
      unmatchedPredictions.remove(best.prediction);
    }

    return _ClipMatchResult(
      matches: matches,
      falseNegatives: unmatchedTruth.length,
      falsePositives: unmatchedPredictions.length,
      predictions: predicted,
    );
  }

  Duration _datasetDuration(EvaluationDataset dataset) => dataset.clips.fold(
        Duration.zero,
        (duration, clip) => duration + clip.duration,
      );

  double _temporalIou(
    EvaluationAnnotation truth,
    EvaluationAnnotation prediction,
  ) {
    final start = truth.startTime > prediction.startTime
        ? truth.startTime
        : prediction.startTime;
    final end =
        truth.endTime < prediction.endTime ? truth.endTime : prediction.endTime;
    final intersection = end - start;
    if (intersection <= Duration.zero) return 0;
    final unionStart = truth.startTime < prediction.startTime
        ? truth.startTime
        : prediction.startTime;
    final unionEnd =
        truth.endTime > prediction.endTime ? truth.endTime : prediction.endTime;
    final union = unionEnd - unionStart;
    return intersection.inMicroseconds / union.inMicroseconds;
  }
}

class EvaluationThresholds {
  const EvaluationThresholds({
    this.minDefaultRecallLift = 0,
    this.maxDefaultFalsePositiveRate = 0.25,
    this.maxDefaultReviewBurdenPerHour = 60,
    this.minExplicitNudityRecall = 0.97,
    this.minGoreBloodRecall = 0.95,
    this.minViolenceRecall = 0.93,
  });

  final double minDefaultRecallLift;
  final double maxDefaultFalsePositiveRate;
  final double maxDefaultReviewBurdenPerHour;
  final double minExplicitNudityRecall;
  final double minGoreBloodRecall;
  final double minViolenceRecall;

  EvaluationExitGateResult evaluateDefaultVsLegacy({
    required EvaluationProfileResult defaultResult,
    required EvaluationProfileResult legacyResult,
  }) {
    final issues = <String>[];
    if (defaultResult.overall.recall <
        legacyResult.overall.recall + minDefaultRecallLift) {
      issues.add('default recall does not beat legacy recall');
    }
    if (defaultResult.overall.falsePositiveRate > maxDefaultFalsePositiveRate) {
      issues.add('default false-positive rate is too high');
    }
    if (defaultResult.overall.reviewBurdenPerHour >
        maxDefaultReviewBurdenPerHour) {
      issues.add('default review burden is too high');
    }
    _checkCategoryRecall(
      issues,
      defaultResult,
      'explicit_nudity',
      minExplicitNudityRecall,
    );
    _checkCategoryRecall(issues, defaultResult, 'gore', minGoreBloodRecall);
    _checkCategoryRecall(issues, defaultResult, 'blood', minGoreBloodRecall);
    _checkCategoryRecall(issues, defaultResult, 'violence', minViolenceRecall);
    return EvaluationExitGateResult(
      passed: issues.isEmpty,
      issues: issues,
    );
  }

  void _checkCategoryRecall(
    List<String> issues,
    EvaluationProfileResult result,
    String categoryId,
    double threshold,
  ) {
    final metrics = result.byCategory[categoryId];
    if (metrics == null || metrics.groundTruthCount == 0) return;
    if (metrics.recall < threshold) {
      issues.add('$categoryId recall is below ${threshold.toStringAsFixed(2)}');
    }
  }
}

class EvaluationComparisonReport {
  const EvaluationComparisonReport({
    required this.datasetId,
    required this.datasetVersion,
    required this.results,
    required this.defaultProfileId,
    required this.legacyProfileId,
    required this.exitGate,
  });

  final String datasetId;
  final String datasetVersion;
  final List<EvaluationProfileResult> results;
  final String defaultProfileId;
  final String legacyProfileId;
  final EvaluationExitGateResult exitGate;

  Map<String, dynamic> toJson() => {
        'datasetId': datasetId,
        'datasetVersion': datasetVersion,
        'defaultProfileId': defaultProfileId,
        'legacyProfileId': legacyProfileId,
        'exitGate': exitGate.toJson(),
        'results': results.map((result) => result.toJson()).toList(),
      };

  String toPrettyJson() => const JsonEncoder.withIndent('  ').convert(toJson());
}

class EvaluationExitGateResult {
  const EvaluationExitGateResult({
    required this.passed,
    required this.issues,
  });

  final bool passed;
  final List<String> issues;

  Map<String, dynamic> toJson() => {
        'passed': passed,
        'issues': issues,
      };
}

class EvaluationProfileResult {
  const EvaluationProfileResult({
    required this.profileId,
    required this.displayName,
    required this.overall,
    required this.byCategory,
    this.runtimeId,
  });

  final String profileId;
  final String displayName;
  final String? runtimeId;
  final EvaluationMetricSet overall;
  final Map<String, EvaluationMetricSet> byCategory;

  Map<String, dynamic> toJson() => {
        'profileId': profileId,
        'displayName': displayName,
        if (runtimeId != null) 'runtimeId': runtimeId,
        'overall': overall.toJson(),
        'byCategory': {
          for (final entry in byCategory.entries)
            entry.key: entry.value.toJson(),
        },
      };
}

class EvaluationMetricSet {
  const EvaluationMetricSet({
    required this.groundTruthCount,
    required this.predictionCount,
    required this.truePositiveCount,
    required this.falsePositiveCount,
    required this.falseNegativeCount,
    required this.recall,
    required this.precision,
    required this.falseNegativeRate,
    required this.falsePositiveRate,
    required this.temporalIou,
    required this.boxIou,
    required this.maskIou,
    required this.reviewBurdenPerHour,
    required this.explanationCompleteness,
    required this.chunkLatencyP50Ms,
    required this.chunkLatencyP95Ms,
    required this.peakMemoryMb,
    required this.peakVramMb,
  });

  final int groundTruthCount;
  final int predictionCount;
  final int truePositiveCount;
  final int falsePositiveCount;
  final int falseNegativeCount;
  final double recall;
  final double precision;
  final double falseNegativeRate;
  final double falsePositiveRate;
  final double temporalIou;
  final double boxIou;
  final double maskIou;
  final double reviewBurdenPerHour;
  final double explanationCompleteness;
  final int chunkLatencyP50Ms;
  final int chunkLatencyP95Ms;
  final int peakMemoryMb;
  final int peakVramMb;

  Map<String, dynamic> toJson() => {
        'groundTruthCount': groundTruthCount,
        'predictionCount': predictionCount,
        'truePositiveCount': truePositiveCount,
        'falsePositiveCount': falsePositiveCount,
        'falseNegativeCount': falseNegativeCount,
        'recall': recall,
        'precision': precision,
        'falseNegativeRate': falseNegativeRate,
        'falsePositiveRate': falsePositiveRate,
        'temporalIou': temporalIou,
        'boxIou': boxIou,
        'maskIou': maskIou,
        'reviewBurdenPerHour': reviewBurdenPerHour,
        'explanationCompleteness': explanationCompleteness,
        'chunkLatencyP50Ms': chunkLatencyP50Ms,
        'chunkLatencyP95Ms': chunkLatencyP95Ms,
        'peakMemoryMb': peakMemoryMb,
        'peakVramMb': peakVramMb,
      };
}

class _MetricAccumulator {
  int groundTruthCount = 0;
  int predictionCount = 0;
  int truePositiveCount = 0;
  int falsePositiveCount = 0;
  int falseNegativeCount = 0;
  int reviewRequiredPredictions = 0;
  int completeExplanationPredictions = 0;
  int explainablePredictions = 0;
  final temporalIous = <double>[];
  final boxIous = <double>[];
  final maskIous = <double>[];

  void add(_ClipMatchResult result) {
    truePositiveCount += result.matches.length;
    falsePositiveCount += result.falsePositives;
    falseNegativeCount += result.falseNegatives;
    groundTruthCount += result.matches.length + result.falseNegatives;
    predictionCount += result.predictions.length;
    reviewRequiredPredictions += result.predictions
        .where((prediction) => prediction.requiresReview)
        .length;
    for (final prediction in result.predictions) {
      if (prediction.rationale.trim().isNotEmpty) {
        explainablePredictions += 1;
        if (prediction.confidence > 0 &&
            prediction.severity.trim().isNotEmpty &&
            prediction.categoryId.trim().isNotEmpty) {
          completeExplanationPredictions += 1;
        }
      }
    }
    for (final match in result.matches) {
      temporalIous.add(match.temporalIou);
      if (match.boxIou != null) boxIous.add(match.boxIou!);
      if (match.maskIou != null) maskIous.add(match.maskIou!);
    }
  }

  EvaluationMetricSet toMetrics({
    required int safeClipCount,
    required int safeFalsePositiveClipCount,
    required Duration totalDatasetDuration,
    required List<int> chunkLatencyMs,
    required List<int> memoryUsageMb,
    required List<int> vramUsageMb,
  }) {
    final totalGroundTruth = truePositiveCount + falseNegativeCount;
    final totalPredictions = truePositiveCount + falsePositiveCount;
    final hours = totalDatasetDuration.inMilliseconds <= 0
        ? 1.0
        : totalDatasetDuration.inMilliseconds /
            const Duration(hours: 1).inMilliseconds;
    return EvaluationMetricSet(
      groundTruthCount: totalGroundTruth,
      predictionCount: totalPredictions,
      truePositiveCount: truePositiveCount,
      falsePositiveCount: falsePositiveCount,
      falseNegativeCount: falseNegativeCount,
      recall: _safeDivide(truePositiveCount, totalGroundTruth),
      precision: _safeDivide(truePositiveCount, totalPredictions),
      falseNegativeRate: _safeDivide(falseNegativeCount, totalGroundTruth),
      falsePositiveRate:
          safeClipCount == 0 ? 0 : safeFalsePositiveClipCount / safeClipCount,
      temporalIou: _average(temporalIous),
      boxIou: _average(boxIous),
      maskIou: _average(maskIous),
      reviewBurdenPerHour: reviewRequiredPredictions / hours,
      explanationCompleteness: explainablePredictions == 0
          ? 0
          : completeExplanationPredictions / explainablePredictions,
      chunkLatencyP50Ms: _percentile(chunkLatencyMs, 0.50),
      chunkLatencyP95Ms: _percentile(chunkLatencyMs, 0.95),
      peakMemoryMb: _maxOrZero(memoryUsageMb),
      peakVramMb: _maxOrZero(vramUsageMb),
    );
  }
}

class _ClipMatchResult {
  const _ClipMatchResult({
    required this.matches,
    required this.falseNegatives,
    required this.falsePositives,
    required this.predictions,
  });

  final List<_AnnotationMatch> matches;
  final int falseNegatives;
  final int falsePositives;
  final List<EvaluationAnnotation> predictions;
}

class _AnnotationMatch {
  const _AnnotationMatch({
    required this.truth,
    required this.prediction,
    required this.temporalIou,
    required this.boxIou,
    required this.maskIou,
    required this.score,
  });

  final EvaluationAnnotation truth;
  final EvaluationAnnotation prediction;
  final double temporalIou;
  final double? boxIou;
  final double? maskIou;
  final double score;
}

double _safeDivide(int numerator, int denominator) =>
    denominator == 0 ? 0 : numerator / denominator;

double _average(List<double> values) =>
    values.isEmpty ? 0 : values.reduce((a, b) => a + b) / values.length;

int _percentile(List<int> values, double percentile) {
  if (values.isEmpty) return 0;
  final sorted = [...values]..sort();
  final index = ((sorted.length - 1) * percentile).ceil();
  return sorted[index.clamp(0, sorted.length - 1)];
}

int _maxOrZero(List<int> values) {
  if (values.isEmpty) return 0;
  return values.reduce((a, b) => a > b ? a : b);
}
