import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kidslens_video_editor/data/models/detection.dart';
import 'package:kidslens_video_editor/data/models/modification.dart';
import 'package:kidslens_video_editor/data/models/timeline.dart';
import 'package:kidslens_video_editor/state/providers/timeline_provider.dart';

void main() {
  group('TimelineState', () {
    group('creation', () {
      test('should create initial state', () {
        const state = TimelineState();

        expect(state.timeline, isNull);
        expect(state.playheadPosition, equals(Duration.zero));
        expect(state.selectedDetectionIds, isEmpty);
        expect(state.zoomLevel, equals(1.0));
        expect(state.isPlaying, isFalse);
      });

      test('should create with timeline', () {
        const timeline = UnifiedTimeline(
          id: 'timeline-1',
          mediaDuration: Duration(minutes: 5),
          tracks: [],
        );

        const state = TimelineState(
          timeline: timeline,
        );

        expect(state.timeline, equals(timeline));
        expect(
          state.timeline?.mediaDuration,
          equals(const Duration(minutes: 5)),
        );
      });
    });

    group('computed properties', () {
      test('timeline should not be null when timeline exists', () {
        const timeline = UnifiedTimeline(
          id: 'timeline-1',
          mediaDuration: Duration(minutes: 5),
          tracks: [],
        );

        const state = TimelineState(
          timeline: timeline,
        );

        expect(state.timeline != null, isTrue);
      });

      test('timeline should be null when timeline is null', () {
        const state = TimelineState();

        expect(state.timeline != null, isFalse);
      });

      test('mediaDuration should return timeline duration', () {
        const timeline = UnifiedTimeline(
          id: 'timeline-1',
          mediaDuration: Duration(minutes: 10),
          tracks: [],
        );

        const state = TimelineState(
          timeline: timeline,
        );

        expect(
          state.timeline?.mediaDuration,
          equals(const Duration(minutes: 10)),
        );
      });

      test('mediaDuration should return null when no timeline', () {
        const state = TimelineState();

        expect(state.timeline?.mediaDuration, isNull);
      });

      test(
        'selectedDetectionIds should not be empty when detections selected',
        () {
          const state = TimelineState(
            selectedDetectionIds: {'detection-1'},
          );

          expect(state.selectedDetectionIds.isNotEmpty, isTrue);
        },
      );

      test('selectedDetectionIds should be empty when no selection', () {
        const state = TimelineState();

        expect(state.selectedDetectionIds.isEmpty, isTrue);
      });
    });

    group('copyWith', () {
      test('should copy with new playhead position', () {
        const state = TimelineState();
        final newState = state.copyWith(
          playheadPosition: const Duration(seconds: 30),
        );

        expect(newState.playheadPosition, equals(const Duration(seconds: 30)));
        // Original unchanged
        expect(state.playheadPosition, equals(Duration.zero));
      });

      test('should copy with new zoomLevel', () {
        const state = TimelineState();
        final newState = state.copyWith(zoomLevel: 2);

        expect(newState.zoomLevel, equals(2));
      });

      test('should copy with playing state', () {
        const state = TimelineState();
        final newState = state.copyWith(isPlaying: true);

        expect(newState.isPlaying, isTrue);
      });
    });
  });

  group('TimelineNotifier', () {
    late ProviderContainer container;
    late TimelineNotifier notifier;

    setUp(() {
      container = ProviderContainer();
      notifier = container.read(timelineNotifierProvider.notifier);
    });

    tearDown(() {
      container.dispose();
    });

    group('initialization', () {
      test('should start with initial state', () {
        expect(notifier.state.timeline, isNull);
        expect(notifier.state.playheadPosition, equals(Duration.zero));
        expect(notifier.state.isPlaying, isFalse);
      });
    });

    group('setTimeline', () {
      test('should set timeline', () {
        const timeline = UnifiedTimeline(
          id: 'timeline-1',
          mediaDuration: Duration(minutes: 5),
          tracks: [],
        );

        notifier.setTimeline(timeline);

        expect(notifier.state.timeline, equals(timeline));
      });
    });

    group('playhead control', () {
      test('should set playhead position', () {
        const timeline = UnifiedTimeline(
          id: 'timeline-1',
          mediaDuration: Duration(minutes: 5),
          tracks: [],
        );
        notifier
          ..setTimeline(timeline)
          ..setPlayheadPosition(const Duration(seconds: 30));

        expect(
          notifier.state.playheadPosition,
          equals(const Duration(seconds: 30)),
        );
      });
    });

    group('playback control', () {
      test('should start playback', () {
        const timeline = UnifiedTimeline(
          id: 'timeline-1',
          mediaDuration: Duration(minutes: 5),
          tracks: [],
        );
        notifier
          ..setTimeline(timeline)
          ..setPlaying(playing: true);

        expect(notifier.state.isPlaying, isTrue);
      });

      test('should pause playback', () {
        const timeline = UnifiedTimeline(
          id: 'timeline-1',
          mediaDuration: Duration(minutes: 5),
          tracks: [],
        );
        notifier
          ..setTimeline(timeline)
          ..setPlaying(playing: true)
          ..setPlaying(playing: false);

        expect(notifier.state.isPlaying, isFalse);
      });
    });

    group('selection', () {
      test('should select detection', () {
        notifier.selectDetection('detection-1');

        expect(
          notifier.state.selectedDetectionIds,
          contains('detection-1'),
        );
      });

      test('should clear selection', () {
        notifier
          ..selectDetection('detection-1')
          ..clearSelection();

        expect(notifier.state.selectedDetectionIds, isEmpty);
      });

      test('should add to selection', () {
        notifier
          ..selectDetection('detection-1')
          ..selectDetection('detection-2');

        expect(notifier.state.selectedDetectionIds, contains('detection-1'));
        expect(notifier.state.selectedDetectionIds, contains('detection-2'));
      });

      test('should deselect detection', () {
        notifier
          ..selectDetection('detection-1')
          ..selectDetection('detection-2')
          ..deselectDetection('detection-1');

        expect(
          notifier.state.selectedDetectionIds,
          isNot(contains('detection-1')),
        );
        expect(notifier.state.selectedDetectionIds, contains('detection-2'));
      });
    });

    group('zoom control', () {
      test('should set zoom level', () {
        notifier.setZoomLevel(2);

        expect(notifier.state.zoomLevel, equals(2));
      });

      test('should clamp zoom to minimum', () {
        notifier.setZoomLevel(0.01);

        expect(notifier.state.zoomLevel, greaterThanOrEqualTo(0.1));
      });

      test('should clamp zoom to maximum', () {
        notifier.setZoomLevel(100);

        expect(notifier.state.zoomLevel, lessThanOrEqualTo(10));
      });
    });

    group('modification management', () {
      late UnifiedTimeline timeline;

      setUp(() {
        timeline = const UnifiedTimeline(
          id: 'timeline-1',
          mediaDuration: Duration(minutes: 5),
          tracks: [
            TimelineTrack(
              id: 'track-1',
              type: TrackType.audio,
              name: 'Audio',
              segments: [
                TimelineSegment(
                  id: 'segment-1',
                  start: Duration(seconds: 10),
                  end: Duration(seconds: 12),
                  type: ContentType.profanity,
                  confidence: 0.95,
                  detectionId: 'detection-1',
                ),
              ],
            ),
          ],
        );

        notifier.setTimeline(timeline);
      });

      test('should apply modification for detection', () {
        const modification = Modification.audioMute();

        notifier.applyModification('detection-1', modification);

        // Find the segment with detectionId 'detection-1'
        final segment = notifier.state.timeline?.tracks
            .expand((t) => t.segments)
            .firstWhere((s) => s.detectionId == 'detection-1');

        expect(segment?.modification, equals(modification));
      });
    });

    group('detection status', () {
      late UnifiedTimeline timeline;

      setUp(() {
        timeline = const UnifiedTimeline(
          id: 'timeline-1',
          mediaDuration: Duration(minutes: 5),
          tracks: [
            TimelineTrack(
              id: 'track-1',
              type: TrackType.audio,
              name: 'Audio',
              segments: [
                TimelineSegment(
                  id: 'segment-1',
                  start: Duration(seconds: 10),
                  end: Duration(seconds: 12),
                  type: ContentType.profanity,
                  confidence: 0.95,
                  detectionId: 'detection-1',
                ),
              ],
            ),
          ],
        );

        notifier.setTimeline(timeline);
      });

      test('should confirm detection (lock it)', () {
        notifier.confirmDetection('detection-1');

        final segment = notifier.state.timeline?.tracks
            .expand((t) => t.segments)
            .firstWhere((s) => s.detectionId == 'detection-1');

        expect(segment?.isLocked, isTrue);
      });

      test('should reject detection (unlock and deselect)', () {
        notifier
          ..selectDetection('detection-1')
          ..rejectDetection('detection-1');

        final segment = notifier.state.timeline?.tracks
            .expand((t) => t.segments)
            .firstWhere((s) => s.detectionId == 'detection-1');

        expect(segment?.isLocked, isFalse);
        expect(segment?.isSelected, isFalse);
      });
    });

    group('adjustDetectionBounds', () {
      late UnifiedTimeline timeline;

      setUp(() {
        timeline = const UnifiedTimeline(
          id: 'timeline-1',
          mediaDuration: Duration(minutes: 5),
          tracks: [
            TimelineTrack(
              id: 'track-1',
              type: TrackType.audio,
              name: 'Audio',
              segments: [
                TimelineSegment(
                  id: 'segment-1',
                  start: Duration(seconds: 10),
                  end: Duration(seconds: 12),
                  type: ContentType.profanity,
                  confidence: 0.95,
                  detectionId: 'detection-1',
                ),
              ],
            ),
          ],
        );

        notifier.setTimeline(timeline);
      });

      test('should adjust detection start time', () {
        notifier.adjustDetectionBounds(
          'detection-1',
          newStart: const Duration(seconds: 8),
        );

        final segment = notifier.state.timeline?.tracks
            .expand((t) => t.segments)
            .firstWhere((s) => s.detectionId == 'detection-1');

        expect(segment?.start, equals(const Duration(seconds: 8)));
        expect(segment?.end, equals(const Duration(seconds: 12)));
      });

      test('should adjust detection end time', () {
        notifier.adjustDetectionBounds(
          'detection-1',
          newEnd: const Duration(seconds: 15),
        );

        final segment = notifier.state.timeline?.tracks
            .expand((t) => t.segments)
            .firstWhere((s) => s.detectionId == 'detection-1');

        expect(segment?.start, equals(const Duration(seconds: 10)));
        expect(segment?.end, equals(const Duration(seconds: 15)));
      });

      test('should adjust both start and end time', () {
        notifier.adjustDetectionBounds(
          'detection-1',
          newStart: const Duration(seconds: 5),
          newEnd: const Duration(seconds: 20),
        );

        final segment = notifier.state.timeline?.tracks
            .expand((t) => t.segments)
            .firstWhere((s) => s.detectionId == 'detection-1');

        expect(segment?.start, equals(const Duration(seconds: 5)));
        expect(segment?.end, equals(const Duration(seconds: 20)));
      });
    });

    group('reset', () {
      test('should reset to initial state', () {
        const timeline = UnifiedTimeline(
          id: 'timeline-1',
          mediaDuration: Duration(minutes: 5),
          tracks: [],
        );
        notifier
          ..setTimeline(timeline)
          ..setPlayheadPosition(const Duration(seconds: 30))
          ..setZoomLevel(2)
          ..selectDetection('detection-1')
          ..setPlaying(playing: true)
          ..reset();

        expect(notifier.state.timeline, isNull);
        expect(notifier.state.playheadPosition, equals(Duration.zero));
        expect(notifier.state.zoomLevel, equals(1));
        expect(notifier.state.selectedDetectionIds, isEmpty);
        expect(notifier.state.isPlaying, isFalse);
      });
    });

    group('edge cases', () {
      test('should handle empty timeline', () {
        const timeline = UnifiedTimeline(
          id: 'timeline-1',
          mediaDuration: Duration.zero,
          tracks: [],
        );
        notifier.setTimeline(timeline);

        expect(notifier.state.timeline?.mediaDuration, equals(Duration.zero));
      });

      test('should handle operations without timeline', () {
        // These should not throw
        notifier
          ..confirmDetection('detection-1')
          ..rejectDetection('detection-1')
          ..applyModification(
            'detection-1',
            const Modification.audioMute(),
          )
          ..adjustDetectionBounds(
            'detection-1',
            newStart: Duration.zero,
            newEnd: const Duration(seconds: 1),
          );
      });
    });
  });
}
