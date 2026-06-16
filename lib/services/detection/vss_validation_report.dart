import 'dart:convert';

import 'package:kidslens_video_editor/services/detection/evaluation_dataset.dart';
import 'package:kidslens_video_editor/services/detection/evaluation_runner.dart';

class VssValidationProfileRun {
  const VssValidationProfileRun({
    required this.predictions,
    this.schemaFailureCount = 0,
    this.crashCount = 0,
    this.errors = const <String>[],
  });

  factory VssValidationProfileRun.fromJson(Map<String, dynamic> json) =>
      VssValidationProfileRun(
        predictions: EvaluationProfilePredictions.fromJson(json),
        schemaFailureCount:
            _readOptionalInt(json, 'schemaFailureCount', defaultValue: 0),
        crashCount: _readOptionalInt(json, 'crashCount', defaultValue: 0),
        errors: _readOptionalStringList(json, 'errors'),
      );

  final EvaluationProfilePredictions predictions;
  final int schemaFailureCount;
  final int crashCount;
  final List<String> errors;

  Map<String, dynamic> toJson() => {
        ...predictions.toJson(),
        'schemaFailureCount': schemaFailureCount,
        'crashCount': crashCount,
        'errors': errors,
      };
}

class VssValidationReport {
  const VssValidationReport({
    required this.generatedAt,
    required this.datasetRoot,
    required this.comparison,
    required this.profileRuns,
    required this.groundingComparison,
  });

  final DateTime generatedAt;
  final String datasetRoot;
  final EvaluationComparisonReport comparison;
  final List<VssValidationProfileRun> profileRuns;
  final VssGroundingComparisonReport groundingComparison;

  Map<String, dynamic> toJson() => {
        'generatedAt': generatedAt.toUtc().toIso8601String(),
        'datasetRoot': datasetRoot,
        'comparison': comparison.toJson(),
        'runtimeValidation': {
          for (final run in profileRuns)
            run.predictions.profileId: {
              'displayName': run.predictions.displayName,
              if (run.predictions.runtimeId != null)
                'runtimeId': run.predictions.runtimeId,
              'chunkLatencyP50Ms':
                  _percentile(run.predictions.chunkLatencyMs, 0.50),
              'chunkLatencyP95Ms':
                  _percentile(run.predictions.chunkLatencyMs, 0.95),
              'peakMemoryMb': _maxOrZero(run.predictions.memoryUsageMb),
              'peakVramMb': _maxOrZero(run.predictions.vramUsageMb),
              'schemaFailureCount': run.schemaFailureCount,
              'crashCount': run.crashCount,
              'errors': run.errors,
            },
        },
        'groundingComparison': groundingComparison.toJson(),
      };

  String toPrettyJson() => const JsonEncoder.withIndent('  ').convert(toJson());
}

class VssValidationReportBuilder {
  const VssValidationReportBuilder({
    this.runner = const EvaluationRunner(),
    this.thresholds = const EvaluationThresholds(),
  });

  final EvaluationRunner runner;
  final EvaluationThresholds thresholds;

  VssValidationReport build({
    required EvaluationDataset dataset,
    required String datasetRoot,
    required List<VssValidationProfileRun> profileRuns,
    DateTime? generatedAt,
  }) {
    final comparison = runner.compare(
      dataset: dataset,
      profilePredictions:
          profileRuns.map((run) => run.predictions).toList(growable: false),
      thresholds: thresholds,
    );
    return VssValidationReport(
      generatedAt: generatedAt ?? DateTime.now().toUtc(),
      datasetRoot: datasetRoot,
      comparison: comparison,
      profileRuns: profileRuns,
      groundingComparison: VssGroundingComparisonReport.compute(
        dataset: dataset,
        profileRuns: profileRuns,
        temporalIouThreshold: runner.temporalIouThreshold,
        boxIouThreshold: runner.boxIouThreshold,
      ),
    );
  }
}

class VssGroundingComparisonReport {
  const VssGroundingComparisonReport({
    required this.byProfile,
  });

  factory VssGroundingComparisonReport.compute({
    required EvaluationDataset dataset,
    required List<VssValidationProfileRun> profileRuns,
    required double temporalIouThreshold,
    required double boxIouThreshold,
  }) {
    final profiles = <String, VssGroundingProfileMetrics>{};
    for (final run in profileRuns) {
      profiles[run.predictions.profileId] = VssGroundingProfileMetrics.compute(
        dataset: dataset,
        predictions: run.predictions,
        temporalIouThreshold: temporalIouThreshold,
        boxIouThreshold: boxIouThreshold,
      );
    }
    return VssGroundingComparisonReport(byProfile: profiles);
  }

  final Map<String, VssGroundingProfileMetrics> byProfile;

  Map<String, dynamic> toJson() => {
        for (final entry in byProfile.entries) entry.key: entry.value.toJson(),
      };
}

class VssGroundingProfileMetrics {
  const VssGroundingProfileMetrics({
    required this.groundedTruthCount,
    required this.localizedCount,
    required this.localizationRecall,
    required this.medianBoxIou,
    required this.p10BoxIou,
    required this.byCategory,
    required this.missedLocalizationIds,
  });

  factory VssGroundingProfileMetrics.compute({
    required EvaluationDataset dataset,
    required EvaluationProfilePredictions predictions,
    required double temporalIouThreshold,
    required double boxIouThreshold,
  }) {
    final accumulators = <String, _GroundingAccumulator>{};
    final overall = _GroundingAccumulator();
    for (final clip in dataset.clips) {
      final predicted = predictions.detectionsByClipId[clip.id] ??
          const <EvaluationAnnotation>[];
      for (final truth
          in clip.groundTruth.where((truth) => truth.box != null)) {
        final accumulator = accumulators.putIfAbsent(
          truth.categoryId,
          _GroundingAccumulator.new,
        );
        final best = _bestBoxIou(
          truth: truth,
          predicted: predicted,
          temporalIouThreshold: temporalIouThreshold,
        );
        final truthId = '${clip.id}:${truth.id}';
        accumulator.add(truthId, best, boxIouThreshold);
        overall.add(truthId, best, boxIouThreshold);
      }
    }

    return VssGroundingProfileMetrics(
      groundedTruthCount: overall.total,
      localizedCount: overall.localized,
      localizationRecall: overall.recall,
      medianBoxIou: overall.medianIou,
      p10BoxIou: overall.p10Iou,
      missedLocalizationIds: overall.missedIds,
      byCategory: {
        for (final entry in accumulators.entries)
          entry.key: entry.value.toCategoryMetrics(),
      },
    );
  }

  final int groundedTruthCount;
  final int localizedCount;
  final double localizationRecall;
  final double medianBoxIou;
  final double p10BoxIou;
  final Map<String, VssGroundingCategoryMetrics> byCategory;
  final List<String> missedLocalizationIds;

  Map<String, dynamic> toJson() => {
        'groundedTruthCount': groundedTruthCount,
        'localizedCount': localizedCount,
        'localizationRecall': localizationRecall,
        'medianBoxIou': medianBoxIou,
        'p10BoxIou': p10BoxIou,
        'missedLocalizationIds': missedLocalizationIds,
        'byCategory': {
          for (final entry in byCategory.entries)
            entry.key: entry.value.toJson(),
        },
      };
}

class VssGroundingCategoryMetrics {
  const VssGroundingCategoryMetrics({
    required this.groundedTruthCount,
    required this.localizedCount,
    required this.localizationRecall,
    required this.medianBoxIou,
    required this.p10BoxIou,
    required this.missedLocalizationIds,
  });

  final int groundedTruthCount;
  final int localizedCount;
  final double localizationRecall;
  final double medianBoxIou;
  final double p10BoxIou;
  final List<String> missedLocalizationIds;

  Map<String, dynamic> toJson() => {
        'groundedTruthCount': groundedTruthCount,
        'localizedCount': localizedCount,
        'localizationRecall': localizationRecall,
        'medianBoxIou': medianBoxIou,
        'p10BoxIou': p10BoxIou,
        'missedLocalizationIds': missedLocalizationIds,
      };
}

class VssValidationPredictionsFile {
  const VssValidationPredictionsFile({
    required this.profileRuns,
  });

  factory VssValidationPredictionsFile.fromJson(Map<String, dynamic> json) =>
      VssValidationPredictionsFile(
        profileRuns: _readList(json, 'profiles')
            .map(
              (entry) => VssValidationProfileRun.fromJson(
                _readMap(entry, 'profiles[]'),
              ),
            )
            .toList(growable: false),
      );

  final List<VssValidationProfileRun> profileRuns;
}

class _GroundingAccumulator {
  final ious = <double>[];
  final missedIds = <String>[];
  int total = 0;
  int localized = 0;

  double get recall => total == 0 ? 0 : localized / total;

  double get medianIou => _percentileDouble(ious, 0.50);

  double get p10Iou => _percentileDouble(ious, 0.10);

  void add(String truthId, double? iou, double boxIouThreshold) {
    total += 1;
    if (iou != null) {
      ious.add(iou);
    }
    if (iou != null && iou >= boxIouThreshold) {
      localized += 1;
    } else {
      missedIds.add(truthId);
    }
  }

  VssGroundingCategoryMetrics toCategoryMetrics() =>
      VssGroundingCategoryMetrics(
        groundedTruthCount: total,
        localizedCount: localized,
        localizationRecall: recall,
        medianBoxIou: medianIou,
        p10BoxIou: p10Iou,
        missedLocalizationIds: missedIds,
      );
}

double? _bestBoxIou({
  required EvaluationAnnotation truth,
  required List<EvaluationAnnotation> predicted,
  required double temporalIouThreshold,
}) {
  double? best;
  for (final candidate in predicted) {
    if (candidate.categoryId != truth.categoryId || candidate.box == null) {
      continue;
    }
    if (_temporalIou(truth, candidate) < temporalIouThreshold) continue;
    final iou = truth.box!.iou(candidate.box!);
    if (best == null || iou > best) {
      best = iou;
    }
  }
  return best;
}

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

Map<String, dynamic> _readMap(Object? value, String field) {
  if (value is Map<String, dynamic>) return value;
  if (value is Map) return Map<String, dynamic>.from(value);
  throw FormatException('$field must be an object');
}

List<dynamic> _readList(Map<String, dynamic> json, String field) {
  final value = json[field];
  if (value is List) return value;
  throw FormatException('$field must be a list');
}

int _readOptionalInt(
  Map<String, dynamic> json,
  String field, {
  required int defaultValue,
}) {
  final value = json[field];
  if (value == null) return defaultValue;
  if (value is int) return value;
  if (value is num) return value.round();
  throw FormatException('$field must be an integer');
}

List<String> _readOptionalStringList(Map<String, dynamic> json, String field) {
  final value = json[field];
  if (value == null) return const <String>[];
  if (value is! List) throw FormatException('$field must be a list');
  return value.map((entry) => '$entry').toList(growable: false);
}

int _maxOrZero(List<int> values) {
  if (values.isEmpty) return 0;
  return values.reduce((a, b) => a > b ? a : b);
}

int _percentile(List<int> values, double percentile) {
  if (values.isEmpty) return 0;
  final sorted = [...values]..sort();
  final index = ((sorted.length - 1) * percentile).ceil();
  return sorted[index.clamp(0, sorted.length - 1)];
}

double _percentileDouble(List<double> values, double percentile) {
  if (values.isEmpty) return 0;
  final sorted = [...values]..sort();
  final index = ((sorted.length - 1) * percentile).ceil();
  return sorted[index.clamp(0, sorted.length - 1)];
}
