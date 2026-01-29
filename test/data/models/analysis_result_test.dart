import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:kidslens_video_editor/data/models/analysis_result.dart';
import 'package:kidslens_video_editor/data/models/profanity_match.dart';
import 'package:kidslens_video_editor/data/models/transcript.dart';

void main() {
  group('AnalysisStatus enum', () {
    test('should have all expected values', () {
      expect(AnalysisStatus.values, hasLength(5));
      expect(AnalysisStatus.values, contains(AnalysisStatus.pending));
      expect(AnalysisStatus.values, contains(AnalysisStatus.running));
      expect(AnalysisStatus.values, contains(AnalysisStatus.completed));
      expect(AnalysisStatus.values, contains(AnalysisStatus.failed));
      expect(AnalysisStatus.values, contains(AnalysisStatus.cancelled));
    });

    test('should have correct JSON values', () {
      expect(AnalysisStatus.pending.name, equals('pending'));
      expect(AnalysisStatus.running.name, equals('running'));
      expect(AnalysisStatus.completed.name, equals('completed'));
      expect(AnalysisStatus.failed.name, equals('failed'));
      expect(AnalysisStatus.cancelled.name, equals('cancelled'));
    });
  });

  group('AnalysisProgress', () {
    group('creation', () {
      test('should create with required fields', () {
        const progress = AnalysisProgress(
          stepName: 'Transcribing',
          currentStep: 1,
          totalSteps: 4,
          stepProgress: 0.5,
        );

        expect(progress.stepName, equals('Transcribing'));
        expect(progress.currentStep, equals(1));
        expect(progress.totalSteps, equals(4));
        expect(progress.stepProgress, equals(0.5));
      });

      test('should include optional fields', () {
        const progress = AnalysisProgress(
          stepName: 'Analyzing frames',
          currentStep: 2,
          totalSteps: 4,
          stepProgress: 0.75,
          estimatedSecondsRemaining: 120,
          itemsProcessed: 50,
          totalItems: 200,
        );

        expect(progress.estimatedSecondsRemaining, equals(120));
        expect(progress.itemsProcessed, equals(50));
        expect(progress.totalItems, equals(200));
      });
    });

    group('AnalysisProgress.initial factory', () {
      test('should create initial progress', () {
        final progress = AnalysisProgress.initial();

        expect(progress.stepName, equals('Starting'));
        expect(progress.currentStep, equals(0));
        expect(progress.totalSteps, equals(4));
        expect(progress.stepProgress, equals(0.0));
      });
    });

    group('overallProgress', () {
      test('should calculate overall progress correctly', () {
        const progress = AnalysisProgress(
          stepName: 'Step 2',
          currentStep: 2,
          totalSteps: 4,
          stepProgress: 0.5,
        );

        // Step 1 complete (25%) + half of step 2 (12.5%) = 37.5%
        // (2-1) * 0.25 + 0.5 * 0.25 = 0.25 + 0.125 = 0.375
        expect(progress.overallProgress, closeTo(0.375, 0.01));
      });

      test('should return 0 when totalSteps is 0', () {
        const progress = AnalysisProgress(
          stepName: 'Test',
          currentStep: 1,
          totalSteps: 0,
          stepProgress: 0.5,
        );

        expect(progress.overallProgress, equals(0.0));
      });

      test('should clamp to 0-1 range', () {
        const completed = AnalysisProgress(
          stepName: 'Complete',
          currentStep: 4,
          totalSteps: 4,
          stepProgress: 1,
        );

        expect(completed.overallProgress, lessThanOrEqualTo(1.0));
        expect(completed.overallProgress, greaterThanOrEqualTo(0.0));
      });
    });

    group('overallPercentage', () {
      test('should return percentage as integer', () {
        const progress = AnalysisProgress(
          stepName: 'Test',
          currentStep: 2,
          totalSteps: 4,
          stepProgress: 0,
        );

        expect(progress.overallPercentage, equals(25));
      });
    });

    group('estimatedTimeFormatted', () {
      test('should return "Calculating..." when null', () {
        const progress = AnalysisProgress(
          stepName: 'Test',
          currentStep: 1,
          totalSteps: 4,
          stepProgress: 0,
        );

        expect(progress.estimatedTimeFormatted, equals('Calculating...'));
      });

      test('should format seconds correctly', () {
        const progress = AnalysisProgress(
          stepName: 'Test',
          currentStep: 1,
          totalSteps: 4,
          stepProgress: 0.5,
          estimatedSecondsRemaining: 45,
        );

        expect(progress.estimatedTimeFormatted, equals('45s remaining'));
      });

      test('should format minutes and seconds correctly', () {
        const progress = AnalysisProgress(
          stepName: 'Test',
          currentStep: 1,
          totalSteps: 4,
          stepProgress: 0.5,
          estimatedSecondsRemaining: 125,
        );

        expect(progress.estimatedTimeFormatted, equals('2m 5s remaining'));
      });
    });

    group('itemProgressDescription', () {
      test('should return empty string when items are null', () {
        const progress = AnalysisProgress(
          stepName: 'Test',
          currentStep: 1,
          totalSteps: 4,
          stepProgress: 0.5,
        );

        expect(progress.itemProgressDescription, isEmpty);
      });

      test('should format items correctly', () {
        const progress = AnalysisProgress(
          stepName: 'Test',
          currentStep: 1,
          totalSteps: 4,
          stepProgress: 0.5,
          itemsProcessed: 25,
          totalItems: 100,
        );

        expect(progress.itemProgressDescription, equals('25 / 100'));
      });
    });

    group('JSON serialization', () {
      test('should serialize and deserialize correctly', () {
        const original = AnalysisProgress(
          stepName: 'Detecting profanity',
          currentStep: 3,
          totalSteps: 4,
          stepProgress: 0.8,
          estimatedSecondsRemaining: 30,
          itemsProcessed: 80,
          totalItems: 100,
        );

        final jsonString = jsonEncode(original.toJson());
        final restored = AnalysisProgress.fromJson(
          jsonDecode(jsonString) as Map<String, dynamic>,
        );

        expect(restored.stepName, equals(original.stepName));
        expect(restored.currentStep, equals(original.currentStep));
        expect(restored.totalSteps, equals(original.totalSteps));
        expect(restored.stepProgress, equals(original.stepProgress));
        expect(
          restored.estimatedSecondsRemaining,
          equals(original.estimatedSecondsRemaining),
        );
      });
    });
  });

  group('AnalysisResult', () {
    group('creation', () {
      test('should create with required fields', () {
        const result = AnalysisResult(id: 'analysis-1');

        expect(result.id, equals('analysis-1'));
        expect(result.status, equals(AnalysisStatus.pending));
        expect(result.profanityMatches, isEmpty);
        expect(result.frameResults, isEmpty);
      });
    });

    group('factory constructors', () {
      test('AnalysisResult.empty should create pending result', () {
        final result = AnalysisResult.empty(
          id: 'empty-1',
          mediaFileId: 'media-123',
        );

        expect(result.id, equals('empty-1'));
        expect(result.status, equals(AnalysisStatus.pending));
        expect(result.mediaFileId, equals('media-123'));
      });

      test('AnalysisResult.running should create running result', () {
        final result = AnalysisResult.running(
          id: 'running-1',
          mediaFileId: 'media-123',
        );

        expect(result.status, equals(AnalysisStatus.running));
        expect(result.startedAt, isNotNull);
        expect(result.progress, isNotNull);
      });

      test('AnalysisResult.failed should create failed result', () {
        final result = AnalysisResult.failed(
          id: 'failed-1',
          errorMessage: 'Something went wrong',
          mediaFileId: 'media-123',
        );

        expect(result.status, equals(AnalysisStatus.failed));
        expect(result.errorMessage, equals('Something went wrong'));
        expect(result.completedAt, isNotNull);
      });
    });

    group('status checks', () {
      test('isPending should return true for pending status', () {
        const result = AnalysisResult(id: 'test');
        expect(result.isPending, isTrue);
      });

      test('isRunning should return true for running status', () {
        const result = AnalysisResult(
          id: 'test',
          status: AnalysisStatus.running,
        );
        expect(result.isRunning, isTrue);
      });

      test('isCompleted should return true for completed status', () {
        const result = AnalysisResult(
          id: 'test',
          status: AnalysisStatus.completed,
        );
        expect(result.isCompleted, isTrue);
      });

      test('isFailed should return true for failed status', () {
        const result = AnalysisResult(
          id: 'test',
          status: AnalysisStatus.failed,
        );
        expect(result.isFailed, isTrue);
      });

      test('isCancelled should return true for cancelled status', () {
        const result = AnalysisResult(
          id: 'test',
          status: AnalysisStatus.cancelled,
        );
        expect(result.isCancelled, isTrue);
      });

      test('isFinished should return true for terminal states', () {
        expect(
          const AnalysisResult(id: 'test', status: AnalysisStatus.completed)
              .isFinished,
          isTrue,
        );
        expect(
          const AnalysisResult(id: 'test', status: AnalysisStatus.failed).isFinished,
          isTrue,
        );
        expect(
          const AnalysisResult(id: 'test', status: AnalysisStatus.cancelled)
              .isFinished,
          isTrue,
        );
        expect(
          const AnalysisResult(id: 'test', status: AnalysisStatus.running).isFinished,
          isFalse,
        );
      });
    });

    group('content checks', () {
      test('hasTranscript should return correct value', () {
        final withTranscript = AnalysisResult(
          id: 'test',
          transcript: Transcript.empty(),
        );
        const withoutTranscript = AnalysisResult(id: 'test');

        expect(withTranscript.hasTranscript, isTrue);
        expect(withoutTranscript.hasTranscript, isFalse);
      });
    });

    group('profanity counts', () {
      test('profanityCount should return total count', () {
        const word = TranscriptWord(
          word: 'test',
          startTime: Duration.zero,
          endTime: Duration(seconds: 1),
          confidence: 0.9,
        );

        const result = AnalysisResult(
          id: 'test',
          profanityMatches: [
            ProfanityMatch(
              id: 'match-1',
              word: word,
              matchedProfanity: 'test',
              confidence: 1,
              type: MatchType.exact,
            ),
            ProfanityMatch(
              id: 'match-2',
              word: word,
              matchedProfanity: 'test',
              confidence: 0.8,
              type: MatchType.fuzzy,
            ),
          ],
        );

        expect(result.profanityCount, equals(2));
      });

      test('validProfanityCount should exclude false positives', () {
        const word = TranscriptWord(
          word: 'test',
          startTime: Duration.zero,
          endTime: Duration(seconds: 1),
          confidence: 0.9,
        );

        const result = AnalysisResult(
          id: 'test',
          profanityMatches: [
            ProfanityMatch(
              id: 'match-1',
              word: word,
              matchedProfanity: 'test',
              confidence: 1,
              type: MatchType.exact,
            ),
            ProfanityMatch(
              id: 'match-2',
              word: word,
              matchedProfanity: 'test',
              confidence: 0.8,
              type: MatchType.fuzzy,
              isFalsePositive: true,
            ),
          ],
        );

        expect(result.validProfanityCount, equals(1));
      });
    });

    group('processingTimeFormatted', () {
      test('should return "Unknown" when null', () {
        const result = AnalysisResult(id: 'test');
        expect(result.processingTimeFormatted, equals('Unknown'));
      });

      test('should format seconds correctly', () {
        const result = AnalysisResult(
          id: 'test',
          processingTime: Duration(seconds: 45),
        );
        expect(result.processingTimeFormatted, equals('45s'));
      });

      test('should format minutes and seconds correctly', () {
        const result = AnalysisResult(
          id: 'test',
          processingTime: Duration(minutes: 2, seconds: 30),
        );
        expect(result.processingTimeFormatted, equals('2m 30s'));
      });
    });

    group('result mutations', () {
      test('complete should update status and data', () {
        final startTime = DateTime.now();
        final result = AnalysisResult(
          id: 'test',
          status: AnalysisStatus.running,
          startedAt: startTime,
        );

        final completed = result.complete(
          transcript: Transcript.empty(),
        );

        expect(completed.status, equals(AnalysisStatus.completed));
        expect(completed.completedAt, isNotNull);
        expect(completed.transcript, isNotNull);
        expect(completed.processingTime, isNotNull);
        expect(completed.progress, isNull);
      });

      test('cancel should update status', () {
        const result = AnalysisResult(
          id: 'test',
          status: AnalysisStatus.running,
        );

        final cancelled = result.cancel();

        expect(cancelled.status, equals(AnalysisStatus.cancelled));
        expect(cancelled.completedAt, isNotNull);
        expect(cancelled.progress, isNull);
      });

      test('withProgress should update progress', () {
        const result = AnalysisResult(
          id: 'test',
          status: AnalysisStatus.running,
        );

        const progress = AnalysisProgress(
          stepName: 'Processing',
          currentStep: 2,
          totalSteps: 4,
          stepProgress: 0.5,
        );

        final updated = result.withProgress(progress);

        expect(updated.progress?.stepName, equals('Processing'));
        expect(updated.progress?.currentStep, equals(2));
      });
    });

    group('JSON serialization', () {
      test('should serialize basic result', () {
        const result = AnalysisResult(
          id: 'json-test',
          status: AnalysisStatus.completed,
        );

        final json = result.toJson();

        expect(json['id'], equals('json-test'));
        expect(json['status'], equals('completed'));
      });

      test('should deserialize basic result', () {
        final json = {
          'id': 'deserialized',
          'status': 'running',
          'profanityMatches': <dynamic>[],
          'frameResults': <dynamic>[],
        };

        final result = AnalysisResult.fromJson(json);

        expect(result.id, equals('deserialized'));
        expect(result.status, equals(AnalysisStatus.running));
      });

      test('should round-trip through JSON', () {
        const original = AnalysisResult(
          id: 'roundtrip',
          status: AnalysisStatus.completed,
          processingTime: Duration(minutes: 5),
          mediaFileId: 'media-file-1',
        );

        final jsonString = jsonEncode(original.toJson());
        final restored = AnalysisResult.fromJson(
          jsonDecode(jsonString) as Map<String, dynamic>,
        );

        expect(restored.id, equals(original.id));
        expect(restored.status, equals(original.status));
        expect(restored.processingTime, equals(original.processingTime));
        expect(restored.mediaFileId, equals(original.mediaFileId));
      });
    });
  });
}
