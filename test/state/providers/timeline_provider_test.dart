import 'package:flutter_test/flutter_test.dart';
import 'package:kidslens_video_editor/data/models/detection.dart';
import 'package:kidslens_video_editor/data/models/modification.dart';
import 'package:kidslens_video_editor/data/models/timeline.dart';
import 'package:kidslens_video_editor/state/providers/timeline_provider.dart';

void main() {
  group('TimelineState', () {
    group('creation', () {
      test('should create initial state', () {
        final state = TimelineState.initial();

        expect(state.timeline, isNull);
        expect(state.playheadPosition, equals(Duration.zero));
        expect(state.selectedSegmentId, isNull);
        expect(state.zoom, equals(1.0));
        expect(state.isPlaying, isFalse);
      });

      test('should create with timeline', () {
        final timeline = UnifiedTimeline(
          duration: const Duration(minutes: 5),
          tracks: [],
        );

        final state = TimelineState(
          timeline: timeline,
          playheadPosition: Duration.zero,
          zoom: 1.0,
          isPlaying: false,
        );

        expect(state.timeline, equals(timeline));
        expect(state.duration, equals(const Duration(minutes: 5)));
      });
    });

    group('computed properties', () {
      test('hasTimeline should return true when timeline exists', () {
        final timeline = UnifiedTimeline(
          duration: const Duration(minutes: 5),
          tracks: [],
        );

        final state = TimelineState(
          timeline: timeline,
          playheadPosition: Duration.zero,
          zoom: 1.0,
          isPlaying: false,
        );

        expect(state.hasTimeline, isTrue);
      });

      test('hasTimeline should return false when timeline is null', () {
        final state = TimelineState.initial();

        expect(state.hasTimeline, isFalse);
      });

      test('duration should return timeline duration', () {
        final timeline = UnifiedTimeline(
          duration: const Duration(minutes: 10),
          tracks: [],
        );

        final state = TimelineState(
          timeline: timeline,
          playheadPosition: Duration.zero,
          zoom: 1.0,
          isPlaying: false,
        );

        expect(state.duration, equals(const Duration(minutes: 10)));
      });

      test('duration should return zero when no timeline', () {
        final state = TimelineState.initial();

        expect(state.duration, equals(Duration.zero));
      });

      test('hasSelection should return true when segment is selected', () {
        final state = TimelineState(
          playheadPosition: Duration.zero,
          selectedSegmentId: 'segment-1',
          zoom: 1.0,
          isPlaying: false,
        );

        expect(state.hasSelection, isTrue);
      });

      test('hasSelection should return false when no selection', () {
        final state = TimelineState.initial();

        expect(state.hasSelection, isFalse);
      });
    });

    group('copyWith', () {
      test('should copy with new playhead position', () {
        final state = TimelineState.initial();
        final newState = state.copyWith(
          playheadPosition: const Duration(seconds: 30),
        );

        expect(newState.playheadPosition, equals(const Duration(seconds: 30)));
        expect(state.playheadPosition, equals(Duration.zero)); // Original unchanged
      });

      test('should copy with new zoom', () {
        final state = TimelineState.initial();
        final newState = state.copyWith(zoom: 2.0);

        expect(newState.zoom, equals(2.0));
      });

      test('should copy with playing state', () {
        final state = TimelineState.initial();
        final newState = state.copyWith(isPlaying: true);

        expect(newState.isPlaying, isTrue);
      });
    });

    group('equality', () {
      test('should be equal with same values', () {
        final state1 = TimelineState(
          playheadPosition: const Duration(seconds: 10),
          zoom: 1.5,
          isPlaying: false,
        );
        final state2 = TimelineState(
          playheadPosition: const Duration(seconds: 10),
          zoom: 1.5,
          isPlaying: false,
        );

        expect(state1, equals(state2));
      });

      test('should not be equal with different values', () {
        final state1 = TimelineState(
          playheadPosition: const Duration(seconds: 10),
          zoom: 1.0,
          isPlaying: false,
        );
        final state2 = TimelineState(
          playheadPosition: const Duration(seconds: 20),
          zoom: 1.0,
          isPlaying: false,
        );

        expect(state1, isNot(equals(state2)));
      });
    });
  });

  group('TimelineNotifier', () {
    late TimelineNotifier notifier;

    setUp(() {
      notifier = TimelineNotifier();
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
        final timeline = UnifiedTimeline(
          duration: const Duration(minutes: 5),
          tracks: [],
        );

        notifier.setTimeline(timeline);

        expect(notifier.state.timeline, equals(timeline));
      });

      test('should reset playhead when setting new timeline', () {
        notifier.setPlayheadPosition(const Duration(seconds: 30));

        final timeline = UnifiedTimeline(
          duration: const Duration(minutes: 5),
          tracks: [],
        );

        notifier.setTimeline(timeline);

        expect(notifier.state.playheadPosition, equals(Duration.zero));
      });

      test('should clear selection when setting new timeline', () {
        notifier.selectSegment('segment-1');

        final timeline = UnifiedTimeline(
          duration: const Duration(minutes: 5),
          tracks: [],
        );

        notifier.setTimeline(timeline);

        expect(notifier.state.selectedSegmentId, isNull);
      });
    });

    group('playhead control', () {
      test('should set playhead position', () {
        final timeline = UnifiedTimeline(
          duration: const Duration(minutes: 5),
          tracks: [],
        );
        notifier.setTimeline(timeline);

        notifier.setPlayheadPosition(const Duration(seconds: 30));

        expect(notifier.state.playheadPosition, equals(const Duration(seconds: 30)));
      });

      test('should clamp playhead to timeline bounds', () {
        final timeline = UnifiedTimeline(
          duration: const Duration(minutes: 1),
          tracks: [],
        );
        notifier.setTimeline(timeline);

        // Try to set beyond duration
        notifier.setPlayheadPosition(const Duration(minutes: 5));

        expect(notifier.state.playheadPosition, equals(const Duration(minutes: 1)));
      });

      test('should not allow negative playhead position', () {
        final timeline = UnifiedTimeline(
          duration: const Duration(minutes: 5),
          tracks: [],
        );
        notifier.setTimeline(timeline);

        notifier.setPlayheadPosition(const Duration(seconds: -10));

        expect(notifier.state.playheadPosition, equals(Duration.zero));
      });

      test('should seek forward', () {
        final timeline = UnifiedTimeline(
          duration: const Duration(minutes: 5),
          tracks: [],
        );
        notifier.setTimeline(timeline);
        notifier.setPlayheadPosition(const Duration(seconds: 10));

        notifier.seekForward(const Duration(seconds: 5));

        expect(notifier.state.playheadPosition, equals(const Duration(seconds: 15)));
      });

      test('should seek backward', () {
        final timeline = UnifiedTimeline(
          duration: const Duration(minutes: 5),
          tracks: [],
        );
        notifier.setTimeline(timeline);
        notifier.setPlayheadPosition(const Duration(seconds: 30));

        notifier.seekBackward(const Duration(seconds: 10));

        expect(notifier.state.playheadPosition, equals(const Duration(seconds: 20)));
      });

      test('should seek to start', () {
        final timeline = UnifiedTimeline(
          duration: const Duration(minutes: 5),
          tracks: [],
        );
        notifier.setTimeline(timeline);
        notifier.setPlayheadPosition(const Duration(seconds: 30));

        notifier.seekToStart();

        expect(notifier.state.playheadPosition, equals(Duration.zero));
      });

      test('should seek to end', () {
        final timeline = UnifiedTimeline(
          duration: const Duration(minutes: 5),
          tracks: [],
        );
        notifier.setTimeline(timeline);

        notifier.seekToEnd();

        expect(notifier.state.playheadPosition, equals(const Duration(minutes: 5)));
      });
    });

    group('playback control', () {
      test('should start playback', () {
        final timeline = UnifiedTimeline(
          duration: const Duration(minutes: 5),
          tracks: [],
        );
        notifier.setTimeline(timeline);

        notifier.play();

        expect(notifier.state.isPlaying, isTrue);
      });

      test('should pause playback', () {
        final timeline = UnifiedTimeline(
          duration: const Duration(minutes: 5),
          tracks: [],
        );
        notifier.setTimeline(timeline);
        notifier.play();

        notifier.pause();

        expect(notifier.state.isPlaying, isFalse);
      });

      test('should toggle playback', () {
        final timeline = UnifiedTimeline(
          duration: const Duration(minutes: 5),
          tracks: [],
        );
        notifier.setTimeline(timeline);

        notifier.togglePlayback();
        expect(notifier.state.isPlaying, isTrue);

        notifier.togglePlayback();
        expect(notifier.state.isPlaying, isFalse);
      });

      test('should not play without timeline', () {
        notifier.play();

        expect(notifier.state.isPlaying, isFalse);
      });
    });

    group('selection', () {
      test('should select segment', () {
        notifier.selectSegment('segment-1');

        expect(notifier.state.selectedSegmentId, equals('segment-1'));
      });

      test('should clear selection', () {
        notifier.selectSegment('segment-1');
        notifier.clearSelection();

        expect(notifier.state.selectedSegmentId, isNull);
      });

      test('should replace selection', () {
        notifier.selectSegment('segment-1');
        notifier.selectSegment('segment-2');

        expect(notifier.state.selectedSegmentId, equals('segment-2'));
      });
    });

    group('zoom control', () {
      test('should set zoom level', () {
        notifier.setZoom(2.0);

        expect(notifier.state.zoom, equals(2.0));
      });

      test('should clamp zoom to minimum', () {
        notifier.setZoom(0.01);

        expect(notifier.state.zoom, greaterThanOrEqualTo(0.1));
      });

      test('should clamp zoom to maximum', () {
        notifier.setZoom(100.0);

        expect(notifier.state.zoom, lessThanOrEqualTo(10.0));
      });

      test('should zoom in', () {
        notifier.setZoom(1.0);
        notifier.zoomIn();

        expect(notifier.state.zoom, greaterThan(1.0));
      });

      test('should zoom out', () {
        notifier.setZoom(2.0);
        notifier.zoomOut();

        expect(notifier.state.zoom, lessThan(2.0));
      });

      test('should reset zoom', () {
        notifier.setZoom(3.0);
        notifier.resetZoom();

        expect(notifier.state.zoom, equals(1.0));
      });
    });

    group('modification management', () {
      late UnifiedTimeline timeline;
      late Detection detection;

      setUp(() {
        detection = Detection.profanity(
          id: 'detection-1',
          startTime: const Duration(seconds: 10),
          endTime: const Duration(seconds: 12),
          matchedWord: 'badword',
          confidence: 0.95,
        );

        timeline = UnifiedTimeline(
          duration: const Duration(minutes: 5),
          tracks: [
            TimelineTrack.detections(
              segments: [
                TimelineSegment(
                  id: 'segment-1',
                  startTime: const Duration(seconds: 10),
                  endTime: const Duration(seconds: 12),
                  detection: detection,
                ),
              ],
            ),
          ],
        );

        notifier.setTimeline(timeline);
      });

      test('should add modification for detection', () {
        final modification = Modification.audioMute(
          id: 'mod-1',
          startTime: const Duration(seconds: 10),
          endTime: const Duration(seconds: 12),
          detectionId: 'detection-1',
        );

        notifier.addModification(modification);

        expect(notifier.state.timeline?.modifications, contains(modification));
      });

      test('should remove modification', () {
        final modification = Modification.audioMute(
          id: 'mod-1',
          startTime: const Duration(seconds: 10),
          endTime: const Duration(seconds: 12),
          detectionId: 'detection-1',
        );

        notifier.addModification(modification);
        notifier.removeModification('mod-1');

        expect(
          notifier.state.timeline?.modifications
              .where((m) => m.id == 'mod-1'),
          isEmpty,
        );
      });

      test('should update modification', () {
        final modification = Modification.audioMute(
          id: 'mod-1',
          startTime: const Duration(seconds: 10),
          endTime: const Duration(seconds: 12),
          detectionId: 'detection-1',
        );

        notifier.addModification(modification);

        final updated = Modification.audioBeep(
          id: 'mod-1',
          startTime: const Duration(seconds: 10),
          endTime: const Duration(seconds: 12),
          detectionId: 'detection-1',
          beepFrequency: 1000,
        );

        notifier.updateModification(updated);

        final mods = notifier.state.timeline?.modifications
            .where((m) => m.id == 'mod-1');
        expect(mods, isNotEmpty);
        expect(mods?.first, isA<AudioBeep>());
      });

      test('should clear all modifications', () {
        final mod1 = Modification.audioMute(
          id: 'mod-1',
          startTime: const Duration(seconds: 10),
          endTime: const Duration(seconds: 12),
          detectionId: 'detection-1',
        );
        final mod2 = Modification.videoBlur(
          id: 'mod-2',
          startTime: const Duration(seconds: 10),
          endTime: const Duration(seconds: 12),
          detectionId: 'detection-1',
          blurStrength: 20,
        );

        notifier.addModification(mod1);
        notifier.addModification(mod2);
        notifier.clearModifications();

        expect(notifier.state.timeline?.modifications, isEmpty);
      });
    });

    group('detection status', () {
      late UnifiedTimeline timeline;

      setUp(() {
        final detection = Detection.profanity(
          id: 'detection-1',
          startTime: const Duration(seconds: 10),
          endTime: const Duration(seconds: 12),
          matchedWord: 'badword',
          confidence: 0.95,
        );

        timeline = UnifiedTimeline(
          duration: const Duration(minutes: 5),
          tracks: [
            TimelineTrack.detections(
              segments: [
                TimelineSegment(
                  id: 'segment-1',
                  startTime: const Duration(seconds: 10),
                  endTime: const Duration(seconds: 12),
                  detection: detection,
                ),
              ],
            ),
          ],
        );

        notifier.setTimeline(timeline);
      });

      test('should mark detection as approved', () {
        notifier.approveDetection('detection-1');

        final segment = notifier.state.timeline?.tracks
            .expand((t) => t.segments)
            .firstWhere((s) => s.detection?.id == 'detection-1');

        expect(segment?.detection?.userStatus, equals(DetectionUserStatus.approved));
      });

      test('should mark detection as rejected', () {
        notifier.rejectDetection('detection-1');

        final segment = notifier.state.timeline?.tracks
            .expand((t) => t.segments)
            .firstWhere((s) => s.detection?.id == 'detection-1');

        expect(segment?.detection?.userStatus, equals(DetectionUserStatus.rejected));
      });

      test('should reset detection status', () {
        notifier.approveDetection('detection-1');
        notifier.resetDetectionStatus('detection-1');

        final segment = notifier.state.timeline?.tracks
            .expand((t) => t.segments)
            .firstWhere((s) => s.detection?.id == 'detection-1');

        expect(segment?.detection?.userStatus, equals(DetectionUserStatus.pending));
      });
    });

    group('segment navigation', () {
      late UnifiedTimeline timeline;

      setUp(() {
        timeline = UnifiedTimeline(
          duration: const Duration(minutes: 5),
          tracks: [
            TimelineTrack.detections(
              segments: [
                TimelineSegment(
                  id: 'segment-1',
                  startTime: const Duration(seconds: 10),
                  endTime: const Duration(seconds: 12),
                  detection: Detection.profanity(
                    id: 'detection-1',
                    startTime: const Duration(seconds: 10),
                    endTime: const Duration(seconds: 12),
                    matchedWord: 'word1',
                    confidence: 0.9,
                  ),
                ),
                TimelineSegment(
                  id: 'segment-2',
                  startTime: const Duration(seconds: 30),
                  endTime: const Duration(seconds: 35),
                  detection: Detection.profanity(
                    id: 'detection-2',
                    startTime: const Duration(seconds: 30),
                    endTime: const Duration(seconds: 35),
                    matchedWord: 'word2',
                    confidence: 0.95,
                  ),
                ),
                TimelineSegment(
                  id: 'segment-3',
                  startTime: const Duration(minutes: 1),
                  endTime: const Duration(minutes: 1, seconds: 5),
                  detection: Detection.profanity(
                    id: 'detection-3',
                    startTime: const Duration(minutes: 1),
                    endTime: const Duration(minutes: 1, seconds: 5),
                    matchedWord: 'word3',
                    confidence: 0.85,
                  ),
                ),
              ],
            ),
          ],
        );

        notifier.setTimeline(timeline);
      });

      test('should navigate to next detection', () {
        notifier.setPlayheadPosition(const Duration(seconds: 5));

        notifier.goToNextDetection();

        expect(notifier.state.playheadPosition, equals(const Duration(seconds: 10)));
      });

      test('should navigate to previous detection', () {
        notifier.setPlayheadPosition(const Duration(seconds: 40));

        notifier.goToPreviousDetection();

        expect(notifier.state.playheadPosition, equals(const Duration(seconds: 30)));
      });

      test('should wrap around to first detection', () {
        notifier.setPlayheadPosition(const Duration(minutes: 2));

        notifier.goToNextDetection();

        expect(notifier.state.playheadPosition, equals(const Duration(seconds: 10)));
      });

      test('should select detection when navigating', () {
        notifier.goToNextDetection();

        expect(notifier.state.selectedSegmentId, equals('segment-1'));
      });
    });

    group('reset', () {
      test('should reset to initial state', () {
        final timeline = UnifiedTimeline(
          duration: const Duration(minutes: 5),
          tracks: [],
        );
        notifier.setTimeline(timeline);
        notifier.setPlayheadPosition(const Duration(seconds: 30));
        notifier.setZoom(2.0);
        notifier.selectSegment('segment-1');
        notifier.play();

        notifier.reset();

        expect(notifier.state.timeline, isNull);
        expect(notifier.state.playheadPosition, equals(Duration.zero));
        expect(notifier.state.zoom, equals(1.0));
        expect(notifier.state.selectedSegmentId, isNull);
        expect(notifier.state.isPlaying, isFalse);
      });
    });

    group('edge cases', () {
      test('should handle empty timeline', () {
        final timeline = UnifiedTimeline(
          duration: Duration.zero,
          tracks: [],
        );
        notifier.setTimeline(timeline);

        expect(notifier.state.duration, equals(Duration.zero));
      });

      test('should handle operations without timeline', () {
        // These should not throw
        notifier.goToNextDetection();
        notifier.goToPreviousDetection();
        notifier.addModification(Modification.audioMute(
          id: 'mod-1',
          startTime: Duration.zero,
          endTime: const Duration(seconds: 1),
          detectionId: 'det-1',
        ));
      });

      test('should handle removing non-existent modification', () {
        final timeline = UnifiedTimeline(
          duration: const Duration(minutes: 5),
          tracks: [],
        );
        notifier.setTimeline(timeline);

        // Should not throw
        notifier.removeModification('non-existent');
      });
    });
  });
}
