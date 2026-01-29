import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:kidslens_video_editor/data/models/transcript.dart';

void main() {
  group('TranscriptWord', () {
    group('creation', () {
      test('should create a word with required fields', () {
        const word = TranscriptWord(
          word: 'hello',
          startTime: Duration(seconds: 1),
          endTime: Duration(seconds: 2),
          confidence: 0.95,
        );

        expect(word.word, equals('hello'));
        expect(word.startTime, equals(const Duration(seconds: 1)));
        expect(word.endTime, equals(const Duration(seconds: 2)));
        expect(word.confidence, equals(0.95));
      });
    });

    group('computed properties', () {
      test('duration should calculate correctly', () {
        const word = TranscriptWord(
          word: 'test',
          startTime: Duration(milliseconds: 500),
          endTime: Duration(milliseconds: 800),
          confidence: 0.9,
        );

        expect(word.duration, equals(const Duration(milliseconds: 300)));
      });

      test('isHighConfidence should return true for >= 0.9', () {
        const high = TranscriptWord(
          word: 'confident',
          startTime: Duration.zero,
          endTime: Duration(milliseconds: 200),
          confidence: 0.92,
        );

        expect(high.isHighConfidence, isTrue);
      });

      test('isLowConfidence should return true for < 0.7', () {
        const low = TranscriptWord(
          word: 'uncertain',
          startTime: Duration.zero,
          endTime: Duration(milliseconds: 200),
          confidence: 0.65,
        );

        expect(low.isLowConfidence, isTrue);
      });

      test('should return false for medium confidence', () {
        const medium = TranscriptWord(
          word: 'okay',
          startTime: Duration.zero,
          endTime: Duration(milliseconds: 200),
          confidence: 0.8,
        );

        expect(medium.isHighConfidence, isFalse);
        expect(medium.isLowConfidence, isFalse);
      });
    });

    group('JSON serialization', () {
      test('should serialize to JSON correctly', () {
        const word = TranscriptWord(
          word: 'testing',
          startTime: Duration(seconds: 5),
          endTime: Duration(seconds: 6),
          confidence: 0.88,
        );

        final json = word.toJson();

        expect(json['word'], equals('testing'));
        expect(json['startTime'], equals(5000000)); // microseconds
        expect(json['endTime'], equals(6000000));
        expect(json['confidence'], equals(0.88));
      });

      test('should deserialize from JSON correctly', () {
        final json = {
          'word': 'deserialized',
          'startTime': 10000000,
          'endTime': 11500000,
          'confidence': 0.75,
        };

        final word = TranscriptWord.fromJson(json);

        expect(word.word, equals('deserialized'));
        expect(word.startTime, equals(const Duration(seconds: 10)));
        expect(
          word.endTime,
          equals(const Duration(seconds: 11, milliseconds: 500)),
        );
        expect(word.confidence, equals(0.75));
      });

      test('should round-trip through JSON correctly', () {
        const original = TranscriptWord(
          word: 'roundtrip',
          startTime: Duration(seconds: 15, milliseconds: 500),
          endTime: Duration(seconds: 16, milliseconds: 200),
          confidence: 0.99,
        );

        final jsonString = jsonEncode(original.toJson());
        final restored = TranscriptWord.fromJson(
          jsonDecode(jsonString) as Map<String, dynamic>,
        );

        expect(restored.word, equals(original.word));
        expect(restored.startTime, equals(original.startTime));
        expect(restored.endTime, equals(original.endTime));
        expect(restored.confidence, equals(original.confidence));
      });
    });

    group('equality', () {
      test('should be equal when all fields match', () {
        const word1 = TranscriptWord(
          word: 'same',
          startTime: Duration(seconds: 1),
          endTime: Duration(seconds: 2),
          confidence: 0.9,
        );

        const word2 = TranscriptWord(
          word: 'same',
          startTime: Duration(seconds: 1),
          endTime: Duration(seconds: 2),
          confidence: 0.9,
        );

        expect(word1, equals(word2));
      });

      test('should not be equal when fields differ', () {
        const word1 = TranscriptWord(
          word: 'different',
          startTime: Duration(seconds: 1),
          endTime: Duration(seconds: 2),
          confidence: 0.9,
        );

        const word2 = TranscriptWord(
          word: 'other',
          startTime: Duration(seconds: 1),
          endTime: Duration(seconds: 2),
          confidence: 0.9,
        );

        expect(word1, isNot(equals(word2)));
      });
    });
  });

  group('TranscriptSegment', () {
    late List<TranscriptWord> sampleWords;

    setUp(() {
      sampleWords = [
        const TranscriptWord(
          word: 'Hello',
          startTime: Duration.zero,
          endTime: Duration(milliseconds: 300),
          confidence: 0.95,
        ),
        const TranscriptWord(
          word: 'world',
          startTime: Duration(milliseconds: 300),
          endTime: Duration(milliseconds: 600),
          confidence: 0.92,
        ),
        const TranscriptWord(
          word: 'today',
          startTime: Duration(milliseconds: 600),
          endTime: Duration(milliseconds: 900),
          confidence: 0.88,
        ),
      ];
    });

    group('creation', () {
      test('should create a segment with required fields', () {
        final segment = TranscriptSegment(
          id: 'seg-1',
          startTime: Duration.zero,
          endTime: const Duration(seconds: 1),
          text: 'Hello world today',
          words: sampleWords,
        );

        expect(segment.id, equals('seg-1'));
        expect(segment.startTime, equals(Duration.zero));
        expect(segment.endTime, equals(const Duration(seconds: 1)));
        expect(segment.text, equals('Hello world today'));
        expect(segment.words, hasLength(3));
      });
    });

    group('computed properties', () {
      test('duration should calculate correctly', () {
        const segment = TranscriptSegment(
          id: 'seg-1',
          startTime: Duration(seconds: 10),
          endTime: Duration(seconds: 15),
          text: 'Test segment',
          words: [],
        );

        expect(segment.duration, equals(const Duration(seconds: 5)));
      });

      test('averageConfidence should calculate correctly', () {
        final segment = TranscriptSegment(
          id: 'seg-1',
          startTime: Duration.zero,
          endTime: const Duration(seconds: 1),
          text: 'Hello world today',
          words: sampleWords,
        );

        // (0.95 + 0.92 + 0.88) / 3 = 0.9166...
        expect(segment.averageConfidence, closeTo(0.917, 0.001));
      });

      test('averageConfidence should return 0 for empty words', () {
        const segment = TranscriptSegment(
          id: 'seg-1',
          startTime: Duration.zero,
          endTime: Duration(seconds: 1),
          text: '',
          words: [],
        );

        expect(segment.averageConfidence, equals(0.0));
      });

      test('wordCount should return correct count', () {
        final segment = TranscriptSegment(
          id: 'seg-1',
          startTime: Duration.zero,
          endTime: const Duration(seconds: 1),
          text: 'Hello world today',
          words: sampleWords,
        );

        expect(segment.wordCount, equals(3));
      });
    });

    group('getWordsInRange', () {
      test('should return words overlapping with range', () {
        final segment = TranscriptSegment(
          id: 'seg-1',
          startTime: Duration.zero,
          endTime: const Duration(milliseconds: 900),
          text: 'Hello world today',
          words: sampleWords,
        );

        final result = segment.getWordsInRange(
          const Duration(milliseconds: 200),
          const Duration(milliseconds: 700),
        );

        expect(result, hasLength(3)); // All words overlap with this range
      });

      test('should return empty list when no words in range', () {
        final segment = TranscriptSegment(
          id: 'seg-1',
          startTime: Duration.zero,
          endTime: const Duration(milliseconds: 900),
          text: 'Hello world today',
          words: sampleWords,
        );

        final result = segment.getWordsInRange(
          const Duration(seconds: 10),
          const Duration(seconds: 15),
        );

        expect(result, isEmpty);
      });
    });

    group('overlapsWithRange', () {
      test('should detect overlapping range', () {
        const segment = TranscriptSegment(
          id: 'seg-1',
          startTime: Duration(seconds: 10),
          endTime: Duration(seconds: 20),
          text: 'Test',
          words: [],
        );

        expect(
          segment.overlapsWithRange(
            const Duration(seconds: 15),
            const Duration(seconds: 25),
          ),
          isTrue,
        );
      });

      test('should not detect non-overlapping range', () {
        const segment = TranscriptSegment(
          id: 'seg-1',
          startTime: Duration(seconds: 10),
          endTime: Duration(seconds: 20),
          text: 'Test',
          words: [],
        );

        expect(
          segment.overlapsWithRange(
            const Duration(seconds: 25),
            const Duration(seconds: 30),
          ),
          isFalse,
        );
      });
    });

    group('JSON serialization', () {
      test('should serialize and deserialize correctly', () {
        final original = TranscriptSegment(
          id: 'seg-json',
          startTime: const Duration(seconds: 5),
          endTime: const Duration(seconds: 10),
          text: 'Hello world today',
          words: sampleWords,
        );

        final jsonString = jsonEncode(original.toJson());
        final restored = TranscriptSegment.fromJson(
          jsonDecode(jsonString) as Map<String, dynamic>,
        );

        expect(restored.id, equals(original.id));
        expect(restored.startTime, equals(original.startTime));
        expect(restored.endTime, equals(original.endTime));
        expect(restored.text, equals(original.text));
        expect(restored.words.length, equals(original.words.length));
      });
    });
  });

  group('Transcript', () {
    late List<TranscriptSegment> sampleSegments;

    setUp(() {
      sampleSegments = [
        const TranscriptSegment(
          id: 'seg-1',
          startTime: Duration.zero,
          endTime: Duration(seconds: 5),
          text: 'First sentence here',
          words: [
            TranscriptWord(
              word: 'First',
              startTime: Duration.zero,
              endTime: Duration(seconds: 1),
              confidence: 0.9,
            ),
            TranscriptWord(
              word: 'sentence',
              startTime: Duration(seconds: 1),
              endTime: Duration(seconds: 2),
              confidence: 0.85,
            ),
            TranscriptWord(
              word: 'here',
              startTime: Duration(seconds: 2),
              endTime: Duration(seconds: 3),
              confidence: 0.92,
            ),
          ],
        ),
        const TranscriptSegment(
          id: 'seg-2',
          startTime: Duration(seconds: 5),
          endTime: Duration(seconds: 10),
          text: 'Second sentence there',
          words: [
            TranscriptWord(
              word: 'Second',
              startTime: Duration(seconds: 5),
              endTime: Duration(seconds: 6),
              confidence: 0.88,
            ),
            TranscriptWord(
              word: 'sentence',
              startTime: Duration(seconds: 6),
              endTime: Duration(seconds: 7),
              confidence: 0.94,
            ),
            TranscriptWord(
              word: 'there',
              startTime: Duration(seconds: 7),
              endTime: Duration(seconds: 8),
              confidence: 0.87,
            ),
          ],
        ),
      ];
    });

    group('creation', () {
      test('should create a transcript with required fields', () {
        final transcript = Transcript(
          segments: sampleSegments,
          language: 'en',
        );

        expect(transcript.segments, hasLength(2));
        expect(transcript.language, equals('en'));
      });

      test('should include optional fields', () {
        final now = DateTime.now();
        final transcript = Transcript(
          segments: sampleSegments,
          language: 'en',
          languageDisplayName: 'English',
          generatedAt: now,
          modelId: 'whisper-base',
        );

        expect(transcript.languageDisplayName, equals('English'));
        expect(transcript.generatedAt, equals(now));
        expect(transcript.modelId, equals('whisper-base'));
      });
    });

    group('Transcript.empty factory', () {
      test('should create an empty transcript', () {
        final transcript = Transcript.empty();

        expect(transcript.segments, isEmpty);
        expect(transcript.language, equals('en'));
      });

      test('should accept custom language', () {
        final transcript = Transcript.empty(language: 'es');

        expect(transcript.language, equals('es'));
      });
    });

    group('computed properties', () {
      test('totalDuration should return last segment end time', () {
        final transcript = Transcript(
          segments: sampleSegments,
          language: 'en',
        );

        expect(transcript.totalDuration, equals(const Duration(seconds: 10)));
      });

      test('totalDuration should return zero for empty transcript', () {
        final transcript = Transcript.empty();

        expect(transcript.totalDuration, equals(Duration.zero));
      });

      test('totalWordCount should sum all words', () {
        final transcript = Transcript(
          segments: sampleSegments,
          language: 'en',
        );

        expect(transcript.totalWordCount, equals(6));
      });

      test('overallConfidence should calculate average', () {
        final transcript = Transcript(
          segments: sampleSegments,
          language: 'en',
        );

        // Average of all 6 word confidences
        const expectedAvg = (0.9 + 0.85 + 0.92 + 0.88 + 0.94 + 0.87) / 6;
        expect(transcript.overallConfidence, closeTo(expectedAvg, 0.001));
      });

      test('overallConfidence should return 0 for empty transcript', () {
        final transcript = Transcript.empty();

        expect(transcript.overallConfidence, equals(0.0));
      });

      test('fullText should concatenate all segment texts', () {
        final transcript = Transcript(
          segments: sampleSegments,
          language: 'en',
        );

        expect(
          transcript.fullText,
          equals('First sentence here Second sentence there'),
        );
      });
    });

    group('getSegmentAt', () {
      test('should return segment containing time', () {
        final transcript = Transcript(
          segments: sampleSegments,
          language: 'en',
        );

        final segment = transcript.getSegmentAt(const Duration(seconds: 7));

        expect(segment?.id, equals('seg-2'));
      });

      test('should return null for time outside segments', () {
        final transcript = Transcript(
          segments: sampleSegments,
          language: 'en',
        );

        final segment = transcript.getSegmentAt(const Duration(seconds: 20));

        expect(segment, isNull);
      });
    });

    group('getWordAt', () {
      test('should return word at specific time', () {
        final transcript = Transcript(
          segments: sampleSegments,
          language: 'en',
        );

        final word = transcript.getWordAt(const Duration(milliseconds: 6500));

        expect(word?.word, equals('sentence'));
      });

      test('should return null for time between words', () {
        final transcript = Transcript(
          segments: sampleSegments,
          language: 'en',
        );

        final word = transcript.getWordAt(const Duration(seconds: 15));

        expect(word, isNull);
      });
    });

    group('getSegmentsInRange', () {
      test('should return segments overlapping with range', () {
        final transcript = Transcript(
          segments: sampleSegments,
          language: 'en',
        );

        final result = transcript.getSegmentsInRange(
          const Duration(seconds: 3),
          const Duration(seconds: 7),
        );

        expect(result, hasLength(2));
      });
    });

    group('getWordsInRange', () {
      test('should return words overlapping with range', () {
        final transcript = Transcript(
          segments: sampleSegments,
          language: 'en',
        );

        final result = transcript.getWordsInRange(
          const Duration(seconds: 1),
          const Duration(seconds: 3),
        );

        // Should get words from first segment that overlap
        expect(result, isNotEmpty);
      });
    });

    group('JSON serialization', () {
      test('should serialize to JSON correctly', () {
        final transcript = Transcript(
          segments: sampleSegments,
          language: 'en',
          languageDisplayName: 'English',
          modelId: 'whisper-base',
        );

        final json = transcript.toJson();

        expect(json['language'], equals('en'));
        expect(json['languageDisplayName'], equals('English'));
        expect(json['modelId'], equals('whisper-base'));
        expect((json['segments'] as List).length, equals(2));
      });

      test('should deserialize from JSON correctly', () {
        final json = {
          'segments': [
            {
              'id': 'seg-1',
              'startTime': 0,
              'endTime': 5000000,
              'text': 'Test segment',
              'words': [
                {
                  'word': 'Test',
                  'startTime': 0,
                  'endTime': 2000000,
                  'confidence': 0.9,
                },
                {
                  'word': 'segment',
                  'startTime': 2000000,
                  'endTime': 5000000,
                  'confidence': 0.85,
                },
              ],
            },
          ],
          'language': 'en',
          'languageDisplayName': 'English',
        };

        final transcript = Transcript.fromJson(json);

        expect(transcript.segments, hasLength(1));
        expect(transcript.language, equals('en'));
        expect(transcript.languageDisplayName, equals('English'));
      });

      test('should round-trip through JSON correctly', () {
        final original = Transcript(
          segments: sampleSegments,
          language: 'es',
          languageDisplayName: 'Spanish',
          generatedAt: DateTime(2024, 1, 15),
          modelId: 'whisper-large',
        );

        final jsonString = jsonEncode(original.toJson());
        final restored = Transcript.fromJson(
          jsonDecode(jsonString) as Map<String, dynamic>,
        );

        expect(restored.segments.length, equals(original.segments.length));
        expect(restored.language, equals(original.language));
        expect(restored.languageDisplayName, equals(original.languageDisplayName));
        expect(restored.modelId, equals(original.modelId));
        expect(restored.totalWordCount, equals(original.totalWordCount));
      });
    });

    group('equality', () {
      test('should be equal when all fields match', () {
        const transcript1 = Transcript(
          segments: [],
          language: 'en',
        );

        const transcript2 = Transcript(
          segments: [],
          language: 'en',
        );

        expect(transcript1, equals(transcript2));
      });
    });
  });
}
