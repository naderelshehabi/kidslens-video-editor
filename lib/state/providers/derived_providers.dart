import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kidslens_video_editor/data/models/models.dart';
import 'package:kidslens_video_editor/state/providers/analysis_provider.dart';
import 'package:kidslens_video_editor/state/providers/media_provider.dart';
import 'package:kidslens_video_editor/state/providers/model_provider.dart';
import 'package:kidslens_video_editor/state/providers/timeline_provider.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'derived_providers.g.dart';

/// Pending detections that need user review
@riverpod
List<Detection> pendingDetections(Ref ref) {
  final timeline = ref.watch(
    timelineNotifierProvider.select((s) => s.timeline),
  );
  if (timeline == null) return [];

  return timeline.detections
      .where((d) => d.userStatus == DetectionUserStatus.pending)
      .toList();
}

/// Count of each detection type
@riverpod
Map<ContentType, int> detectionCounts(Ref ref) {
  final timeline = ref.watch(
    timelineNotifierProvider.select((s) => s.timeline),
  );
  if (timeline == null) return {};

  final counts = <ContentType, int>{};
  for (final detection in timeline.detections) {
    counts[detection.type] = (counts[detection.type] ?? 0) + 1;
  }
  return counts;
}

/// Whether analysis can be started
@riverpod
bool canStartAnalysis(Ref ref) {
  final media = ref.watch(
    mediaNotifierProvider.select((s) => s.currentMedia),
  );
  final analysisStatus = ref.watch(
    analysisNotifierProvider.select((s) => s.status),
  );

  return media != null && analysisStatus == AnalysisStatus.pending;
}

/// Whether export can be started
@riverpod
bool canStartExport(Ref ref) {
  final timeline = ref.watch(
    timelineNotifierProvider.select((s) => s.timeline),
  );
  final analysisStatus = ref.watch(
    analysisNotifierProvider.select((s) => s.status),
  );

  return timeline != null && analysisStatus == AnalysisStatus.completed;
}

/// Total disk space used by downloaded models
@riverpod
int totalModelDiskUsage(Ref ref) {
  final modelState = ref.watch(modelNotifierProvider);
  
  var total = 0;
  for (final modelId in modelState.downloadedModels) {
    final info = modelState.availableModels
        .where((m) => m.id == modelId)
        .firstOrNull;
    if (info != null) {
      total += info.sizeBytes;
    }
  }
  return total;
}

/// Detection statistics summary
@riverpod
DetectionSummary detectionSummary(Ref ref) {
  final timeline = ref.watch(
    timelineNotifierProvider.select((s) => s.timeline),
  );
  if (timeline == null) {
    return const DetectionSummary(
      total: 0,
      pending: 0,
      confirmed: 0,
      rejected: 0,
    );
  }

  final detections = timeline.detections;
  return DetectionSummary(
    total: detections.length,
    pending: detections.where((d) => d.userStatus == DetectionUserStatus.pending).length,
    confirmed: detections.where((d) => d.userStatus == DetectionUserStatus.confirmed).length,
    rejected: detections.where((d) => d.userStatus == DetectionUserStatus.rejected).length,
  );
}

/// Summary of detection counts
class DetectionSummary {
  const DetectionSummary({
    required this.total,
    required this.pending,
    required this.confirmed,
    required this.rejected,
  });

  final int total;
  final int pending;
  final int confirmed;
  final int rejected;
}
