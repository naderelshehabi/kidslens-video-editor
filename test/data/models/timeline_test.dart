import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:kidslens_video_editor/data/models/detection.dart';
import 'package:kidslens_video_editor/data/models/modification.dart';
import 'package:kidslens_video_editor/data/models/timeline.dart';

void main() {
  group('TrackType enum', () {
    test('should have all expected values', () {
      expect(TrackType.values, hasLength(4));
      expect(TrackType.values, contains(TrackType.audio));
      expect(TrackType.values, contains(TrackType.video));
      expect(TrackType.values, contains(TrackType.detection));
      expect(TrackType.values, contains(TrackType.custom));
    });
  });

  group('TimelineSegment', () {
    group('creation', () {
      test('should create a segment with required fields', () {
        final segment = TimelineSegment(
          id: 'seg-1',
          start: const Duration(seconds: 10),
          end: const Duration(seconds: 20),
          type: ContentType.nsfw,
          confidence: 0.95,
        );

        expect(segment.id, equals('seg-1'));
        expect(segment.start, equals(const Duration(seconds: 10)));
        expect(segment.end, equals(const Duration(seconds: 20)));
        expect(segment.type, equals(ContentType.nsfw));
        expect(segment.confidence, equals(0.95));
        expect(segment.isSelected, isFalse);
        expect(segment.isLocked, isFalse);
      });

      test('should create with optional modification', () {
        final segment = TimelineSegment(
          id: 'seg-1',
          start: Duration.zero,
          end: const Duration(seconds: 5),
          type: ContentType.profanity,
          confidence: 1.0,
          modification: const AudioMute(),
        );

        expect(segment.modification, isNotNull);
        expect(segment.modification, isA<AudioMute>());
      });
    });

    group('TimelineSegment.fromDetection factory', () {
      test('should create segment from detection', () {
        final detection = Detection(
          id: 'det-1',
          type: ContentType.violence,
          startTime: const Duration(minutes: 1),
          endTime: const Duration(minutes: 1, seconds: 30),
          confidence: 0.85,
          description: 'Violence detected',
        );

        final segment = TimelineSegment.fromDetection(detection);

        expect(segment.id, equals('seg_det-1'));
        expect(segment.start, equals(detection.startTime));
        expect(segment.end, equals(detection.endTime));
        expect(segment.type, equals(detection.type));
        expect(segment.confidence, equals(detection.confidence));
        expect(segment.detectionId, equals('det-1'));
      });

      test('should include modification if provided', () {
        final detection = Detection(
          id: 'det-1',
          type: ContentType.profanity,
          startTime: Duration.zero,
          endTime: const Duration(seconds: 2),
          confidence: 0.99,
          description: 'Bad word',
        );

        final segment = TimelineSegment.fromDetection(
          detection,
          modification: const AudioBeep(frequency: 500),
        );

        expect(segment.modification, isA<AudioBeep>());
      });
    });

    group('computed properties', () {
      test('duration should calculate correctly', () {
        final segment = TimelineSegment(
          id: 'seg-1',
          start: const Duration(seconds: 10),
          end: const Duration(seconds: 25),
          type: ContentType.blood,
          confidence: 0.7,
        );

        expect(segment.duration, equals(const Duration(seconds: 15)));
      });

      test('hasModification should return correct value', () {
        final segWithMod = TimelineSegment(
          id: 'seg-1',
          start: Duration.zero,
          end: const Duration(seconds: 5),
          type: ContentType.nsfw,
          confidence: 0.9,
          modification: const VideoBlur(),
        );

        final segWithoutMod = TimelineSegment(
          id: 'seg-2',
          start: Duration.zero,
          end: const Duration(seconds: 5),
          type: ContentType.nsfw,
          confidence: 0.9,
        );

        expect(segWithMod.hasModification, isTrue);
        expect(segWithoutMod.hasModification, isFalse);
      });
    });

    group('overlap detection', () {
      test('overlapsWithRange should detect overlap', () {
        final segment = TimelineSegment(
          id: 'seg-1',
          start: const Duration(seconds: 10),
          end: const Duration(seconds: 20),
          type: ContentType.nsfw,
          confidence: 0.9,
        );

        expect(
          segment.overlapsWithRange(
            const Duration(seconds: 15),
            const Duration(seconds: 25),
          ),
          isTrue,
        );

        expect(
          segment.overlapsWithRange(
            const Duration(seconds: 0),
            const Duration(seconds: 5),
          ),
          isFalse,
        );
      });

      test('overlapsWith should detect overlapping segments', () {
        final seg1 = TimelineSegment(
          id: 'seg-1',
          start: const Duration(seconds: 10),
          end: const Duration(seconds: 20),
          type: ContentType.nsfw,
          confidence: 0.9,
        );

        final seg2 = TimelineSegment(
          id: 'seg-2',
          start: const Duration(seconds: 15),
          end: const Duration(seconds: 25),
          type: ContentType.violence,
          confidence: 0.8,
        );

        expect(seg1.overlapsWith(seg2), isTrue);
      });

      test('containsTime should check if time is within segment', () {
        final segment = TimelineSegment(
          id: 'seg-1',
          start: const Duration(seconds: 10),
          end: const Duration(seconds: 20),
          type: ContentType.nsfw,
          confidence: 0.9,
        );

        expect(segment.containsTime(const Duration(seconds: 15)), isTrue);
        expect(segment.containsTime(const Duration(seconds: 10)), isTrue);
        expect(segment.containsTime(const Duration(seconds: 20)), isFalse);
        expect(segment.containsTime(const Duration(seconds: 5)), isFalse);
      });
    });

    group('JSON serialization', () {
      test('should serialize and deserialize correctly', () {
        final original = TimelineSegment(
          id: 'seg-1',
          start: const Duration(seconds: 30),
          end: const Duration(seconds: 45),
          type: ContentType.weapons,
          confidence: 0.88,
          modification: const VideoPixelate(blockSize: 24),
          isSelected: true,
          isLocked: false,
          detectionId: 'det-123',
        );

        final jsonString = jsonEncode(original.toJson());
        final restored = TimelineSegment.fromJson(
          jsonDecode(jsonString) as Map<String, dynamic>,
        );

        expect(restored.id, equals(original.id));
        expect(restored.start, equals(original.start));
        expect(restored.end, equals(original.end));
        expect(restored.type, equals(original.type));
        expect(restored.confidence, equals(original.confidence));
        expect(restored.modification, isA<VideoPixelate>());
        expect(restored.isSelected, equals(original.isSelected));
        expect(restored.detectionId, equals(original.detectionId));
      });
    });
  });

  group('TimelineTrack', () {
    group('creation', () {
      test('should create a track with required fields', () {
        final track = TimelineTrack(
          id: 'track-1',
          type: TrackType.video,
          name: 'Video Track',
          segments: const [],
        );

        expect(track.id, equals('track-1'));
        expect(track.type, equals(TrackType.video));
        expect(track.name, equals('Video Track'));
        expect(track.segments, isEmpty);
        expect(track.isVisible, isTrue);
        expect(track.isMuted, isFalse);
        expect(track.isLocked, isFalse);
        expect(track.height, equals(40));
      });
    });

    group('factory constructors', () {
      test('TimelineTrack.audio should create audio track', () {
        final track = TimelineTrack.audio();

        expect(track.id, equals('track_audio'));
        expect(track.type, equals(TrackType.audio));
        expect(track.name, equals('Audio'));
        expect(track.color, equals('#4CAF50'));
      });

      test('TimelineTrack.video should create video track', () {
        final track = TimelineTrack.video();

        expect(track.id, equals('track_video'));
        expect(track.type, equals(TrackType.video));
        expect(track.name, equals('Video'));
        expect(track.color, equals('#2196F3'));
      });

      test('TimelineTrack.detection should create detection track', () {
        final track = TimelineTrack.detection();

        expect(track.id, equals('track_detection'));
        expect(track.type, equals(TrackType.detection));
        expect(track.name, equals('Detections'));
        expect(track.color, equals('#FF5722'));
      });

      test('should accept custom name', () {
        final track = TimelineTrack.audio(name: 'Custom Audio');
        expect(track.name, equals('Custom Audio'));
      });
    });

    group('computed properties', () {
      test('segmentCount should return correct count', () {
        final track = TimelineTrack(
          id: 'track-1',
          type: TrackType.video,
          name: 'Test',
          segments: [
            TimelineSegment(
              id: 'seg-1',
              start: Duration.zero,
              end: const Duration(seconds: 5),
              type: ContentType.nsfw,
              confidence: 0.9,
            ),
            TimelineSegment(
              id: 'seg-2',
              start: const Duration(seconds: 10),
              end: const Duration(seconds: 15),
              type: ContentType.violence,
              confidence: 0.8,
            ),
          ],
        );

        expect(track.segmentCount, equals(2));
      });

      test('hasSegments should return correct value', () {
        final emptyTrack = TimelineTrack.video();
        final trackWithSegments = TimelineTrack(
          id: 'track-1',
          type: TrackType.video,
          name: 'Test',
          segments: [
            TimelineSegment(
              id: 'seg-1',
              start: Duration.zero,
              end: const Duration(seconds: 5),
              type: ContentType.nsfw,
              confidence: 0.9,
            ),
          ],
        );

        expect(emptyTrack.hasSegments, isFalse);
        expect(trackWithSegments.hasSegments, isTrue);
      });
    });

    group('getSegmentsInRange', () {
      test('should return segments overlapping with range', () {
        final track = TimelineTrack(
          id: 'track-1',
          type: TrackType.video,
          name: 'Test',
          segments: [
            TimelineSegment(
              id: 'seg-1',
              start: Duration.zero,
              end: const Duration(seconds: 10),
              type: ContentType.nsfw,
              confidence: 0.9,
            ),
            TimelineSegment(
              id: 'seg-2',
              start: const Duration(seconds: 20),
              end: const Duration(seconds: 30),
              type: ContentType.violence,
              confidence: 0.8,
            ),
            TimelineSegment(
              id: 'seg-3',
              start: const Duration(seconds: 40),
              end: const Duration(seconds: 50),
              type: ContentType.blood,
              confidence: 0.7,
            ),
          ],
        );

        final result = track.getSegmentsInRange(
          const Duration(seconds: 5),
          const Duration(seconds: 25),
        );

        expect(result, hasLength(2));
        expect(result.map((s) => s.id), containsAll(['seg-1', 'seg-2']));
      });
    });

    group('getSegmentAt', () {
      test('should return segment containing time', () {
        final track = TimelineTrack(
          id: 'track-1',
          type: TrackType.video,
          name: 'Test',
          segments: [
            TimelineSegment(
              id: 'seg-1',
              start: Duration.zero,
              end: const Duration(seconds: 10),
              type: ContentType.nsfw,
              confidence: 0.9,
            ),
            TimelineSegment(
              id: 'seg-2',
              start: const Duration(seconds: 20),
              end: const Duration(seconds: 30),
              type: ContentType.violence,
              confidence: 0.8,
            ),
          ],
        );

        final segment = track.getSegmentAt(const Duration(seconds: 5));
        expect(segment?.id, equals('seg-1'));

        final noSegment = track.getSegmentAt(const Duration(seconds: 15));
        expect(noSegment, isNull);
      });
    });

    group('modifiedSegments', () {
      test('should return only segments with modifications', () {
        final track = TimelineTrack(
          id: 'track-1',
          type: TrackType.video,
          name: 'Test',
          segments: [
            TimelineSegment(
              id: 'seg-1',
              start: Duration.zero,
              end: const Duration(seconds: 5),
              type: ContentType.nsfw,
              confidence: 0.9,
              modification: const VideoBlur(),
            ),
            TimelineSegment(
              id: 'seg-2',
              start: const Duration(seconds: 10),
              end: const Duration(seconds: 15),
              type: ContentType.violence,
              confidence: 0.8,
            ),
            TimelineSegment(
              id: 'seg-3',
              start: const Duration(seconds: 20),
              end: const Duration(seconds: 25),
              type: ContentType.blood,
              confidence: 0.7,
              modification: const VideoPixelate(),
            ),
          ],
        );

        final modified = track.modifiedSegments;
        expect(modified, hasLength(2));
        expect(modified.map((s) => s.id), containsAll(['seg-1', 'seg-3']));
      });
    });
  });

  group('ConflictType enum', () {
    test('should have all expected values', () {
      expect(ConflictType.values, hasLength(3));
      expect(ConflictType.values, contains(ConflictType.overlap));
      expect(
        ConflictType.values,
        contains(ConflictType.multipleModifications),
      );
      expect(
        ConflictType.values,
        contains(ConflictType.incompatibleModifications),
      );
    });
  });

  group('TimelineConflict', () {
    test('should create a conflict correctly', () {
      final seg1 = TimelineSegment(
        id: 'seg-1',
        start: const Duration(seconds: 10),
        end: const Duration(seconds: 20),
        type: ContentType.nsfw,
        confidence: 0.9,
      );

      final seg2 = TimelineSegment(
        id: 'seg-2',
        start: const Duration(seconds: 15),
        end: const Duration(seconds: 25),
        type: ContentType.violence,
        confidence: 0.8,
      );

      final conflict = TimelineConflict(
        segment1: seg1,
        segment2: seg2,
        conflictType: ConflictType.overlap,
        description: 'Segments overlap',
      );

      expect(conflict.segment1.id, equals('seg-1'));
      expect(conflict.segment2.id, equals('seg-2'));
      expect(conflict.conflictType, equals(ConflictType.overlap));
      expect(conflict.description, equals('Segments overlap'));
    });
  });

  group('UnifiedTimeline', () {
    group('creation', () {
      test('should create a timeline with required fields', () {
        final timeline = UnifiedTimeline(
          id: 'timeline-1',
          mediaDuration: const Duration(hours: 1),
          tracks: [TimelineTrack.video(), TimelineTrack.audio()],
        );

        expect(timeline.id, equals('timeline-1'));
        expect(timeline.mediaDuration, equals(const Duration(hours: 1)));
        expect(timeline.tracks, hasLength(2));
      });
    });

    group('UnifiedTimeline.empty factory', () {
      test('should create an empty timeline with default tracks', () {
        final timeline = UnifiedTimeline.empty(
          mediaDuration: const Duration(minutes: 30),
        );

        expect(timeline.tracks, hasLength(3));
        expect(timeline.videoTrack, isNotNull);
        expect(timeline.audioTrack, isNotNull);
        expect(timeline.detectionTrack, isNotNull);
        expect(timeline.createdAt, isNotNull);
      });
    });

    group('UnifiedTimeline.fromDetections factory', () {
      test('should create timeline from detections', () {
        final detections = [
          Detection(
            id: 'det-1',
            type: ContentType.nsfw,
            startTime: const Duration(seconds: 10),
            endTime: const Duration(seconds: 20),
            confidence: 0.9,
            description: 'NSFW',
          ),
          Detection(
            id: 'det-2',
            type: ContentType.profanity,
            startTime: const Duration(seconds: 30),
            endTime: const Duration(seconds: 32),
            confidence: 0.95,
            description: 'Profanity',
          ),
        ];

        final timeline = UnifiedTimeline.fromDetections(
          mediaDuration: const Duration(minutes: 5),
          detections: detections,
        );

        expect(timeline.videoTrack?.segments, hasLength(1));
        expect(timeline.audioTrack?.segments, hasLength(1));
      });
    });

    group('track getters', () {
      test('should return correct tracks', () {
        final timeline = UnifiedTimeline.empty(
          mediaDuration: const Duration(minutes: 10),
        );

        expect(timeline.audioTrack?.type, equals(TrackType.audio));
        expect(timeline.videoTrack?.type, equals(TrackType.video));
        expect(timeline.detectionTrack?.type, equals(TrackType.detection));
      });
    });

    group('getSegmentsAt', () {
      test('should return segments at specific time', () {
        final timeline = UnifiedTimeline(
          id: 'timeline-1',
          mediaDuration: const Duration(minutes: 5),
          tracks: [
            TimelineTrack(
              id: 'video',
              type: TrackType.video,
              name: 'Video',
              segments: [
                TimelineSegment(
                  id: 'seg-1',
                  start: const Duration(seconds: 10),
                  end: const Duration(seconds: 20),
                  type: ContentType.nsfw,
                  confidence: 0.9,
                ),
              ],
            ),
            TimelineTrack(
              id: 'audio',
              type: TrackType.audio,
              name: 'Audio',
              segments: [
                TimelineSegment(
                  id: 'seg-2',
                  start: const Duration(seconds: 15),
                  end: const Duration(seconds: 25),
                  type: ContentType.profanity,
                  confidence: 0.95,
                ),
              ],
            ),
          ],
        );

        final segments = timeline.getSegmentsAt(const Duration(seconds: 17));
        expect(segments, hasLength(2));
      });
    });

    group('updateDetection', () {
      test('should update detection properties', () {
        final timeline = UnifiedTimeline(
          id: 'timeline-1',
          mediaDuration: const Duration(minutes: 5),
          tracks: [
            TimelineTrack(
              id: 'video',
              type: TrackType.video,
              name: 'Video',
              segments: [
                TimelineSegment(
                  id: 'seg-1',
                  start: const Duration(seconds: 10),
                  end: const Duration(seconds: 20),
                  type: ContentType.nsfw,
                  confidence: 0.9,
                  detectionId: 'det-1',
                ),
              ],
            ),
          ],
        );

        final updated = timeline.updateDetection(
          'det-1',
          newStart: const Duration(seconds: 12),
          newEnd: const Duration(seconds: 18),
          isSelected: true,
        );

        final segment = updated.tracks.first.segments.first;
        expect(segment.start, equals(const Duration(seconds: 12)));
        expect(segment.end, equals(const Duration(seconds: 18)));
        expect(segment.isSelected, isTrue);
      });
    });

    group('addModification', () {
      test('should add modification to segment', () {
        final timeline = UnifiedTimeline(
          id: 'timeline-1',
          mediaDuration: const Duration(minutes: 5),
          tracks: [
            TimelineTrack(
              id: 'video',
              type: TrackType.video,
              name: 'Video',
              segments: [
                TimelineSegment(
                  id: 'seg-1',
                  start: const Duration(seconds: 10),
                  end: const Duration(seconds: 20),
                  type: ContentType.nsfw,
                  confidence: 0.9,
                ),
              ],
            ),
          ],
        );

        final updated = timeline.addModification(
          'seg-1',
          const VideoBlur(intensity: 50),
        );

        final segment = updated.tracks.first.segments.first;
        expect(segment.modification, isA<VideoBlur>());
        expect((segment.modification as VideoBlur).intensity, equals(50));
      });
    });

    group('removeModification', () {
      test('should remove modification from segment', () {
        final timeline = UnifiedTimeline(
          id: 'timeline-1',
          mediaDuration: const Duration(minutes: 5),
          tracks: [
            TimelineTrack(
              id: 'video',
              type: TrackType.video,
              name: 'Video',
              segments: [
                TimelineSegment(
                  id: 'seg-1',
                  start: const Duration(seconds: 10),
                  end: const Duration(seconds: 20),
                  type: ContentType.nsfw,
                  confidence: 0.9,
                  modification: const VideoBlur(),
                ),
              ],
            ),
          ],
        );

        final updated = timeline.removeModification('seg-1');

        final segment = updated.tracks.first.segments.first;
        expect(segment.modification, isNull);
      });
    });

    group('findConflicts', () {
      test('should detect overlapping segments', () {
        final timeline = UnifiedTimeline(
          id: 'timeline-1',
          mediaDuration: const Duration(minutes: 5),
          tracks: [
            TimelineTrack(
              id: 'video',
              type: TrackType.video,
              name: 'Video',
              segments: [
                TimelineSegment(
                  id: 'seg-1',
                  start: const Duration(seconds: 10),
                  end: const Duration(seconds: 25),
                  type: ContentType.nsfw,
                  confidence: 0.9,
                ),
                TimelineSegment(
                  id: 'seg-2',
                  start: const Duration(seconds: 20),
                  end: const Duration(seconds: 35),
                  type: ContentType.violence,
                  confidence: 0.8,
                ),
              ],
            ),
          ],
        );

        final conflicts = timeline.findConflicts();
        expect(conflicts, isNotEmpty);
        expect(
          conflicts.any((c) => c.conflictType == ConflictType.overlap),
          isTrue,
        );
      });
    });

    group('computed statistics', () {
      test('totalSegmentCount should sum all segments', () {
        final timeline = UnifiedTimeline(
          id: 'timeline-1',
          mediaDuration: const Duration(minutes: 5),
          tracks: [
            TimelineTrack(
              id: 'video',
              type: TrackType.video,
              name: 'Video',
              segments: [
                TimelineSegment(
                  id: 'seg-1',
                  start: Duration.zero,
                  end: const Duration(seconds: 5),
                  type: ContentType.nsfw,
                  confidence: 0.9,
                ),
                TimelineSegment(
                  id: 'seg-2',
                  start: const Duration(seconds: 10),
                  end: const Duration(seconds: 15),
                  type: ContentType.violence,
                  confidence: 0.8,
                ),
              ],
            ),
            TimelineTrack(
              id: 'audio',
              type: TrackType.audio,
              name: 'Audio',
              segments: [
                TimelineSegment(
                  id: 'seg-3',
                  start: const Duration(seconds: 20),
                  end: const Duration(seconds: 22),
                  type: ContentType.profanity,
                  confidence: 0.95,
                ),
              ],
            ),
          ],
        );

        expect(timeline.totalSegmentCount, equals(3));
      });

      test('totalModificationCount should count modified segments', () {
        final timeline = UnifiedTimeline(
          id: 'timeline-1',
          mediaDuration: const Duration(minutes: 5),
          tracks: [
            TimelineTrack(
              id: 'video',
              type: TrackType.video,
              name: 'Video',
              segments: [
                TimelineSegment(
                  id: 'seg-1',
                  start: Duration.zero,
                  end: const Duration(seconds: 5),
                  type: ContentType.nsfw,
                  confidence: 0.9,
                  modification: const VideoBlur(),
                ),
                TimelineSegment(
                  id: 'seg-2',
                  start: const Duration(seconds: 10),
                  end: const Duration(seconds: 15),
                  type: ContentType.violence,
                  confidence: 0.8,
                ),
              ],
            ),
          ],
        );

        expect(timeline.totalModificationCount, equals(1));
      });
    });

    group('JSON serialization', () {
      test('should serialize and deserialize correctly', () {
        final original = UnifiedTimeline.empty(
          id: 'test-timeline',
          mediaDuration: const Duration(minutes: 10),
        );

        final jsonString = jsonEncode(original.toJson());
        final restored = UnifiedTimeline.fromJson(
          jsonDecode(jsonString) as Map<String, dynamic>,
        );

        expect(restored.id, equals(original.id));
        expect(restored.mediaDuration, equals(original.mediaDuration));
        expect(restored.tracks.length, equals(original.tracks.length));
      });
    });
  });
}
