import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:kidslens_video_editor/data/models/detection.dart';

void main() {
  group('ContentType enum', () {
    test('should have all expected values', () {
      expect(ContentType.values, hasLength(2));
      expect(ContentType.values, contains(ContentType.nsfw));
      expect(ContentType.values, contains(ContentType.profanity));
    });

    test('should have correct JSON values', () {
      expect(ContentType.nsfw.name, equals('nsfw'));
      expect(ContentType.profanity.name, equals('profanity'));
    });
  });

  group('DetectionUserStatus enum', () {
    test('should have all expected values', () {
      expect(DetectionUserStatus.values, hasLength(4));
      expect(DetectionUserStatus.values, contains(DetectionUserStatus.pending));
      expect(DetectionUserStatus.values, contains(DetectionUserStatus.confirmed));
      expect(DetectionUserStatus.values, contains(DetectionUserStatus.rejected));
      expect(DetectionUserStatus.values, contains(DetectionUserStatus.adjusted));
    });
  });

  group('Detection', () {
    group('creation', () {
      test('should create a detection with all required fields', () {
        const detection = Detection(
          id: 'det-1',
          mediaId: 'media-1',
          type: ContentType.nsfw,
          startTime: Duration(seconds: 10),
          endTime: Duration(seconds: 15),
          confidence: 0.95,
          description: 'NSFW content detected',
        );

        expect(detection.id, equals('det-1'));
        expect(detection.type, equals(ContentType.nsfw));
        expect(detection.startTime, equals(const Duration(seconds: 10)));
        expect(detection.endTime, equals(const Duration(seconds: 15)));
        expect(detection.confidence, equals(0.95));
        expect(detection.description, equals('NSFW content detected'));
        expect(detection.userStatus, equals(DetectionUserStatus.pending));
      });

      test('should have pending status by default', () {
        const detection = Detection(
          id: 'det-1',
          mediaId: 'media-1',
          type: ContentType.nsfw,
          startTime: Duration.zero,
          endTime: Duration(seconds: 5),
          confidence: 0.8,
          description: 'NSFW detected',
        );

        expect(detection.userStatus, equals(DetectionUserStatus.pending));
      });
    });

    group('Detection.profanity factory', () {
      test('should create a profanity detection with correct defaults', () {
        final detection = Detection.profanity(
          id: 'prof-1',
          mediaId: 'media-1',
          startTime: const Duration(seconds: 30),
          endTime: const Duration(seconds: 31),
          confidence: 0.99,
          word: 'badword',
        );

        expect(detection.type, equals(ContentType.profanity));
        expect(detection.source, equals('asr'));
        expect(detection.description, contains('badword'));
        expect(detection.metadata?['word'], equals('badword'));
      });
    });

    group('Detection.visual factory', () {
      test('should create a visual detection with default description', () {
        final detection = Detection.visual(
          id: 'vis-1',
          mediaId: 'media-1',
          type: ContentType.nsfw,
          startTime: const Duration(minutes: 1),
          endTime: const Duration(minutes: 1, seconds: 5),
          confidence: 0.85,
        );

        expect(detection.type, equals(ContentType.nsfw));
        expect(detection.source, equals('visual'));
        expect(detection.description, equals('NSFW content detected'));
      });

      test('should use provided description if given', () {
        final detection = Detection.visual(
          id: 'vis-2',
          mediaId: 'media-1',
          type: ContentType.nsfw,
          startTime: Duration.zero,
          endTime: const Duration(seconds: 10),
          confidence: 0.75,
          description: 'Custom visual description',
        );

        expect(detection.description, equals('Custom visual description'));
      });
    });

    group('computed properties', () {
      test('duration should calculate correctly', () {
        const detection = Detection(
          id: 'det-1',
          mediaId: 'media-1',
          type: ContentType.nsfw,
          startTime: Duration(seconds: 10),
          endTime: Duration(seconds: 25),
          confidence: 0.9,
          description: 'Test',
        );

        expect(detection.duration, equals(const Duration(seconds: 15)));
      });

      group('review status checks', () {
        test('isReviewed should return false for pending', () {
          const detection = Detection(
            id: 'det-1',
            mediaId: 'media-1',
            type: ContentType.nsfw,
            startTime: Duration.zero,
            endTime: Duration(seconds: 5),
            confidence: 0.9,
            description: 'Test',
          );

          expect(detection.isReviewed, isFalse);
        });

        test('isReviewed should return true for confirmed', () {
          const detection = Detection(
            id: 'det-1',
            mediaId: 'media-1',
            type: ContentType.nsfw,
            startTime: Duration.zero,
            endTime: Duration(seconds: 5),
            confidence: 0.9,
            description: 'Test',
            userStatus: DetectionUserStatus.confirmed,
          );

          expect(detection.isReviewed, isTrue);
          expect(detection.isConfirmed, isTrue);
        });

        test('isRejected should return true for rejected status', () {
          const detection = Detection(
            id: 'det-1',
            mediaId: 'media-1',
            type: ContentType.nsfw,
            startTime: Duration.zero,
            endTime: Duration(seconds: 5),
            confidence: 0.9,
            description: 'Test',
            userStatus: DetectionUserStatus.rejected,
          );

          expect(detection.isRejected, isTrue);
        });

        test('isAdjusted should return true for adjusted status', () {
          const detection = Detection(
            id: 'det-1',
            mediaId: 'media-1',
            type: ContentType.nsfw,
            startTime: Duration.zero,
            endTime: Duration(seconds: 5),
            confidence: 0.9,
            description: 'Test',
            userStatus: DetectionUserStatus.adjusted,
          );

          expect(detection.isAdjusted, isTrue);
        });
      });

      group('detection type checks', () {
        test('isAudioDetection should return true for profanity', () {
          const detection = Detection(
            id: 'det-1',
            mediaId: 'media-1',
            type: ContentType.profanity,
            startTime: Duration.zero,
            endTime: Duration(seconds: 1),
            confidence: 0.9,
            description: 'Test',
          );

          expect(detection.isAudioDetection, isTrue);
          expect(detection.isVisualDetection, isFalse);
        });

        test('isVisualDetection should return true for non-profanity types', () {
          for (final type in [ContentType.nsfw]) {
            final detection = Detection(
              id: 'det-1',
              mediaId: 'media-1',
              type: type,
              startTime: Duration.zero,
              endTime: const Duration(seconds: 1),
              confidence: 0.9,
              description: 'Test',
            );

            expect(detection.isVisualDetection, isTrue);
            expect(detection.isAudioDetection, isFalse);
          }
        });
      });

      group('confidence checks', () {
        test('isHighConfidence should return true for >= 0.9', () {
          const high = Detection(
            id: 'det-1',
            mediaId: 'media-1',
            type: ContentType.nsfw,
            startTime: Duration.zero,
            endTime: Duration(seconds: 1),
            confidence: 0.9,
            description: 'Test',
          );

          expect(high.isHighConfidence, isTrue);
        });

        test('isLowConfidence should return true for < 0.7', () {
          const low = Detection(
            id: 'det-1',
            mediaId: 'media-1',
            type: ContentType.nsfw,
            startTime: Duration.zero,
            endTime: Duration(seconds: 1),
            confidence: 0.65,
            description: 'Test',
          );

          expect(low.isLowConfidence, isTrue);
        });
      });

      group('typeDisplayName', () {
        test('should return correct display names', () {
          expect(
            const Detection(
              id: 'id',
              mediaId: 'media-1',
              type: ContentType.nsfw,
              startTime: Duration.zero,
              endTime: Duration(seconds: 1),
              confidence: 0.9,
              description: 'Test',
            ).typeDisplayName,
            equals('NSFW'),
          );

          expect(
            const Detection(
              id: 'id',
              mediaId: 'media-1',
              type: ContentType.profanity,
              startTime: Duration.zero,
              endTime: Duration(seconds: 1),
              confidence: 0.9,
              description: 'Test',
            ).typeDisplayName,
            equals('Profanity'),
          );
        });

        test('should prefer visual category display name when present', () {
          expect(
            Detection(
              id: 'id',
              mediaId: 'media-1',
              type: ContentType.nsfw,
              startTime: Duration.zero,
              endTime: const Duration(seconds: 1),
              confidence: 0.9,
              description: 'Test',
              metadata: {
                Detection.visualContentCategoryKey: 'sexual_content',
              },
            ).typeDisplayName,
            equals('Sexual Content'),
          );
        });
      });
    });

    group('overlap detection', () {
      test('overlapsWithRange should detect overlapping ranges', () {
        const detection = Detection(
          id: 'det-1',
          mediaId: 'media-1',
          type: ContentType.nsfw,
          startTime: Duration(seconds: 10),
          endTime: Duration(seconds: 20),
          confidence: 0.9,
          description: 'Test',
        );

        // Overlapping range
        expect(
          detection.overlapsWithRange(
            const Duration(seconds: 15),
            const Duration(seconds: 25),
          ),
          isTrue,
        );

        // Non-overlapping range (before)
        expect(
          detection.overlapsWithRange(
            const Duration(),
            const Duration(seconds: 10),
          ),
          isFalse,
        );

        // Non-overlapping range (after)
        expect(
          detection.overlapsWithRange(
            const Duration(seconds: 20),
            const Duration(seconds: 30),
          ),
          isFalse,
        );
      });

      test('overlapsWith should detect overlapping detections', () {
        const det1 = Detection(
          id: 'det-1',
          mediaId: 'media-1',
          type: ContentType.nsfw,
          startTime: Duration(seconds: 10),
          endTime: Duration(seconds: 20),
          confidence: 0.9,
          description: 'Test',
        );

        const det2 = Detection(
          id: 'det-2',
          mediaId: 'media-1',
          type: ContentType.nsfw,
          startTime: Duration(seconds: 15),
          endTime: Duration(seconds: 25),
          confidence: 0.8,
          description: 'Test',
        );

        expect(det1.overlapsWith(det2), isTrue);
        expect(det2.overlapsWith(det1), isTrue);
      });

      test('containsTime should check if time is within detection', () {
        const detection = Detection(
          id: 'det-1',
          mediaId: 'media-1',
          type: ContentType.nsfw,
          startTime: Duration(seconds: 10),
          endTime: Duration(seconds: 20),
          confidence: 0.9,
          description: 'Test',
        );

        expect(detection.containsTime(const Duration(seconds: 15)), isTrue);
        expect(detection.containsTime(const Duration(seconds: 10)), isTrue);
        expect(detection.containsTime(const Duration(seconds: 20)), isFalse);
        expect(detection.containsTime(const Duration(seconds: 5)), isFalse);
      });
    });

    group('user actions', () {
      test('confirm should set status to confirmed', () {
        const detection = Detection(
          id: 'det-1',
          mediaId: 'media-1',
          type: ContentType.nsfw,
          startTime: Duration.zero,
          endTime: Duration(seconds: 5),
          confidence: 0.9,
          description: 'Test',
        );

        final confirmed = detection.confirm(note: 'Looks correct');

        expect(confirmed.userStatus, equals(DetectionUserStatus.confirmed));
        expect(confirmed.userNote, equals('Looks correct'));
      });

      test('reject should set status to rejected', () {
        const detection = Detection(
          id: 'det-1',
          mediaId: 'media-1',
          type: ContentType.nsfw,
          startTime: Duration.zero,
          endTime: Duration(seconds: 5),
          confidence: 0.9,
          description: 'Test',
        );

        final rejected = detection.reject(note: 'False positive');

        expect(rejected.userStatus, equals(DetectionUserStatus.rejected));
        expect(rejected.userNote, equals('False positive'));
      });

      test('adjustTimeRange should update times and set adjusted status', () {
        const detection = Detection(
          id: 'det-1',
          mediaId: 'media-1',
          type: ContentType.nsfw,
          startTime: Duration(seconds: 10),
          endTime: Duration(seconds: 20),
          confidence: 0.9,
          description: 'Test',
        );

        final adjusted = detection.adjustTimeRange(
          newStartTime: const Duration(seconds: 12),
          newEndTime: const Duration(seconds: 18),
        );

        expect(adjusted.startTime, equals(const Duration(seconds: 12)));
        expect(adjusted.endTime, equals(const Duration(seconds: 18)));
        expect(adjusted.originalStartTime, equals(const Duration(seconds: 10)));
        expect(adjusted.originalEndTime, equals(const Duration(seconds: 20)));
        expect(adjusted.userStatus, equals(DetectionUserStatus.adjusted));
      });
    });

    group('JSON serialization', () {
      test('should serialize to JSON correctly', () {
        const detection = Detection(
          id: 'det-1',
          mediaId: 'media-1',
          type: ContentType.nsfw,
          startTime: Duration(seconds: 30),
          endTime: Duration(seconds: 45),
          confidence: 0.87,
          description: 'NSFW detected',
          userStatus: DetectionUserStatus.confirmed,
          source: 'visual',
        );

        final json = detection.toJson();

        expect(json['id'], equals('det-1'));
        expect(json['type'], equals('nsfw'));
        expect(json['startTime'], equals(30000000)); // microseconds
        expect(json['endTime'], equals(45000000));
        expect(json['confidence'], equals(0.87));
        expect(json['description'], equals('NSFW detected'));
        expect(json['userStatus'], equals('confirmed'));
        expect(json['source'], equals('visual'));
      });

      test('should deserialize from JSON correctly', () {
        final json = {
          'id': 'json-det',
          'mediaId': 'media-1',
          'type': 'nsfw',
          'startTime': 60000000,
          'endTime': 75000000,
          'confidence': 0.75,
          'description': 'NSFW detected',
          'userStatus': 'pending',
        };

        final detection = Detection.fromJson(json);

        expect(detection.id, equals('json-det'));
        expect(detection.type, equals(ContentType.nsfw));
        expect(detection.startTime, equals(const Duration(seconds: 60)));
        expect(detection.endTime, equals(const Duration(seconds: 75)));
        expect(detection.confidence, equals(0.75));
      });

      test('should round-trip through JSON correctly', () {
        final original = Detection.visual(
          id: 'roundtrip-det',
          mediaId: 'media-1',
          type: ContentType.nsfw,
          startTime: const Duration(minutes: 5),
          endTime: const Duration(minutes: 5, seconds: 10),
          confidence: 0.92,
        );

        final jsonString = jsonEncode(original.toJson());
        final restored = Detection.fromJson(
          jsonDecode(jsonString) as Map<String, dynamic>,
        );

        expect(restored.id, equals(original.id));
        expect(restored.type, equals(original.type));
        expect(restored.startTime, equals(original.startTime));
        expect(restored.endTime, equals(original.endTime));
        expect(restored.confidence, equals(original.confidence));
      });
    });
  });
}
