import 'package:kidslens_video_editor/data/models/models.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'timeline_provider.g.dart';

/// State for timeline management
class TimelineState {
  const TimelineState({
    this.timeline,
    this.selectedDetectionIds = const {},
    this.playheadPosition = Duration.zero,
    this.zoomLevel = 1.0,
    this.isPlaying = false,
  });

  final UnifiedTimeline? timeline;
  final Set<String> selectedDetectionIds;
  final Duration playheadPosition;
  final double zoomLevel;
  final bool isPlaying;

  TimelineState copyWith({
    UnifiedTimeline? timeline,
    Set<String>? selectedDetectionIds,
    Duration? playheadPosition,
    double? zoomLevel,
    bool? isPlaying,
  }) =>
      TimelineState(
        timeline: timeline ?? this.timeline,
        selectedDetectionIds: selectedDetectionIds ?? this.selectedDetectionIds,
        playheadPosition: playheadPosition ?? this.playheadPosition,
        zoomLevel: zoomLevel ?? this.zoomLevel,
        isPlaying: isPlaying ?? this.isPlaying,
      );
}

/// Provider for managing timeline state
@Riverpod(keepAlive: true)
class TimelineNotifier extends _$TimelineNotifier {
  @override
  TimelineState build() => const TimelineState();

  void setTimeline(UnifiedTimeline timeline) {
    state = state.copyWith(timeline: timeline);
  }

  void selectDetection(String detectionId) {
    final timeline = state.timeline;
    if (timeline != null) {
      final updated = timeline.updateDetection(detectionId, isSelected: true);
      state = state.copyWith(
        timeline: updated,
        selectedDetectionIds: {...state.selectedDetectionIds, detectionId},
      );
    } else {
      state = state.copyWith(
        selectedDetectionIds: {...state.selectedDetectionIds, detectionId},
      );
    }
  }

  void deselectDetection(String detectionId) {
    final timeline = state.timeline;
    final updatedIds = Set<String>.from(state.selectedDetectionIds)
      ..remove(detectionId);

    if (timeline != null) {
      final updated = timeline.updateDetection(detectionId, isSelected: false);
      state = state.copyWith(
        timeline: updated,
        selectedDetectionIds: updatedIds,
      );
    } else {
      state = state.copyWith(selectedDetectionIds: updatedIds);
    }
  }

  void clearSelection() {
    final timeline = state.timeline;
    if (timeline != null) {
      // Deselect all currently selected detections
      var updated = timeline;
      for (final detectionId in state.selectedDetectionIds) {
        updated = updated.updateDetection(detectionId, isSelected: false);
      }
      state = state.copyWith(timeline: updated, selectedDetectionIds: {});
    } else {
      state = state.copyWith(selectedDetectionIds: {});
    }
  }

  void confirmDetection(String detectionId) {
    final timeline = state.timeline;
    if (timeline == null) return;

    // Lock the detection to confirm it
    final updated = timeline.updateDetection(detectionId, isLocked: true);
    state = state.copyWith(timeline: updated);
  }

  void rejectDetection(String detectionId) {
    final timeline = state.timeline;
    if (timeline == null) return;

    // To reject a detection, we remove its modification (if any) and mark it
    // For now, we unlock and deselect it as a way to "reject"
    final updated = timeline.updateDetection(
      detectionId,
      isLocked: false,
      isSelected: false,
    );
    state = state.copyWith(timeline: updated);
  }

  void adjustDetectionBounds(
    String detectionId, {
    Duration? newStart,
    Duration? newEnd,
  }) {
    final timeline = state.timeline;
    if (timeline == null) return;

    final updated = timeline.updateDetection(
      detectionId,
      newStart: newStart,
      newEnd: newEnd,
    );
    state = state.copyWith(timeline: updated);
  }

  void applyModification(String detectionId, Modification modification) {
    final timeline = state.timeline;
    if (timeline == null) return;

    final updated = timeline.updateDetection(
      detectionId,
      modification: modification,
    );
    state = state.copyWith(timeline: updated);
  }

  void setPlayheadPosition(Duration position) {
    state = state.copyWith(playheadPosition: position);
  }

  void setZoomLevel(double zoom) {
    state = state.copyWith(zoomLevel: zoom.clamp(0.1, 10.0));
  }

  void setPlaying({required bool playing}) {
    state = state.copyWith(isPlaying: playing);
  }

  void reset() {
    state = const TimelineState();
  }
}
