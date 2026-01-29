import 'package:flutter_test/flutter_test.dart';
import 'package:kidslens_video_editor/data/models/analysis_result.dart';
import 'package:kidslens_video_editor/data/models/analysis_settings.dart';
import 'package:kidslens_video_editor/state/providers/analysis_provider.dart';

void main() {
  group('AnalysisState', () {
    group('creation', () {
      test('should create default state', () {
        const state = AnalysisState();

        expect(state.status, equals(AnalysisStatus.pending));
        expect(state.progress, equals(0.0));
        expect(state.currentStep, isNull);
        expect(state.result, isNull);
        expect(state.errorMessage, isNull);
        expect(state.isPaused, isFalse);
        expect(state.detections, isEmpty);
      });

      test('should create with required fields', () {
        const state = AnalysisState(
          status: AnalysisStatus.running,
          progress: 0.5,
          currentStep: 'Processing...',
        );

        expect(state.status, equals(AnalysisStatus.running));
        expect(state.progress, equals(0.5));
        expect(state.currentStep, equals('Processing...'));
      });
    });

    group('status checks', () {
      test('should identify pending state', () {
        const state = AnalysisState();

        expect(state.status, equals(AnalysisStatus.pending));
      });

      test('should identify running state', () {
        const state = AnalysisState(
          status: AnalysisStatus.running,
        );

        expect(state.status, equals(AnalysisStatus.running));
      });

      test('should identify completed state', () {
        const state = AnalysisState(
          status: AnalysisStatus.completed,
        );

        expect(state.status, equals(AnalysisStatus.completed));
      });

      test('isPaused should return true when paused', () {
        const state = AnalysisState(
          status: AnalysisStatus.running,
          isPaused: true,
        );

        expect(state.isPaused, isTrue);
      });

      test('should identify cancelled state', () {
        const state = AnalysisState(
          status: AnalysisStatus.cancelled,
        );

        expect(state.status, equals(AnalysisStatus.cancelled));
      });

      test('should identify failed state with error message', () {
        const state = AnalysisState(
          status: AnalysisStatus.failed,
          errorMessage: 'Analysis failed',
        );

        expect(state.status, equals(AnalysisStatus.failed));
        expect(state.errorMessage, equals('Analysis failed'));
      });
    });

    group('progress tracking', () {
      test('should track progress as double', () {
        const state = AnalysisState(
          status: AnalysisStatus.running,
          progress: 0.25,
          currentStep: 'Transcribing audio...',
        );

        expect(state.progress, equals(0.25));
        expect(state.currentStep, equals('Transcribing audio...'));
      });

      test('should track estimated time remaining', () {
        const state = AnalysisState(
          status: AnalysisStatus.running,
          progress: 0.5,
          estimatedSecondsRemaining: 120,
        );

        expect(state.estimatedSecondsRemaining, equals(120));
      });
    });

    group('copyWith', () {
      test('should copy with new status', () {
        const state = AnalysisState();
        final newState = state.copyWith(status: AnalysisStatus.running);

        expect(newState.status, equals(AnalysisStatus.running));
        expect(
            state.status, equals(AnalysisStatus.pending),); // Original unchanged
      });

      test('should copy with new progress', () {
        const state = AnalysisState(status: AnalysisStatus.running);
        final newState = state.copyWith(progress: 0.75);

        expect(newState.progress, equals(0.75));
      });

      test('should copy with result', () {
        const state = AnalysisState(status: AnalysisStatus.running);
        final result = AnalysisResult.empty(id: 'result-123');
        final newState = state.copyWith(
          status: AnalysisStatus.completed,
          result: result,
        );

        expect(newState.status, equals(AnalysisStatus.completed));
        expect(newState.result, equals(result));
      });

      test('should clear error when clearError is true', () {
        const state = AnalysisState(
          status: AnalysisStatus.failed,
          errorMessage: 'Some error',
        );
        final newState = state.copyWith(
          status: AnalysisStatus.running,
          clearError: true,
        );

        expect(newState.errorMessage, isNull);
      });
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

      test('should create initial progress', () {
        final progress = AnalysisProgress.initial();

        expect(progress.stepName, equals('Starting'));
        expect(progress.currentStep, equals(0));
        expect(progress.totalSteps, equals(4));
        expect(progress.stepProgress, equals(0));
      });
    });

    group('overallProgress', () {
      test('should calculate overall progress correctly', () {
        const progress = AnalysisProgress(
          stepName: 'Analyzing',
          currentStep: 2,
          totalSteps: 4,
          stepProgress: 0.5,
        );

        // At step 2 of 4, with 50% of current step done
        // = (1 completed step / 4) + (0.5 * 1/4) = 0.25 + 0.125 = 0.375
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
    });

    group('formatting', () {
      test('should format estimated time as seconds', () {
        const progress = AnalysisProgress(
          stepName: 'Test',
          currentStep: 1,
          totalSteps: 4,
          stepProgress: 0.5,
          estimatedSecondsRemaining: 45,
        );

        expect(progress.estimatedTimeFormatted, equals('45s remaining'));
      });

      test('should format estimated time as minutes and seconds', () {
        const progress = AnalysisProgress(
          stepName: 'Test',
          currentStep: 1,
          totalSteps: 4,
          stepProgress: 0.5,
          estimatedSecondsRemaining: 125,
        );

        expect(progress.estimatedTimeFormatted, equals('2m 5s remaining'));
      });

      test('should show calculating when no estimated time', () {
        const progress = AnalysisProgress(
          stepName: 'Test',
          currentStep: 1,
          totalSteps: 4,
          stepProgress: 0.5,
        );

        expect(progress.estimatedTimeFormatted, equals('Calculating...'));
      });
    });
  });

  group('AnalysisStatus', () {
    test('should have all expected values', () {
      expect(AnalysisStatus.values, contains(AnalysisStatus.pending));
      expect(AnalysisStatus.values, contains(AnalysisStatus.running));
      expect(AnalysisStatus.values, contains(AnalysisStatus.completed));
      expect(AnalysisStatus.values, contains(AnalysisStatus.failed));
      expect(AnalysisStatus.values, contains(AnalysisStatus.cancelled));
    });
  });

  group('AnalysisSettings', () {
    test('should create with defaults', () {
      final settings = AnalysisSettings.defaults();

      expect(settings.enableProfanity, isTrue);
      expect(settings.enableNsfw, isTrue);
      expect(settings.enableViolence, isTrue);
      expect(settings.enableBlood, isTrue);
      expect(settings.enableWeapons, isTrue);
    });

    test('should create strict settings', () {
      final settings = AnalysisSettings.strict();

      expect(settings.nsfwThreshold, equals(0.4));
      expect(settings.violenceThreshold, equals(0.4));
      expect(settings.frameSamplingRate, equals(3));
    });

    test('should create permissive settings', () {
      final settings = AnalysisSettings.permissive();

      expect(settings.nsfwThreshold, equals(0.8));
      expect(settings.violenceThreshold, equals(0.8));
      expect(settings.frameSamplingRate, equals(10));
    });
  });

  group('AnalysisResult', () {
    test('should create empty result', () {
      final result = AnalysisResult.empty(id: 'test-id');

      expect(result.id, equals('test-id'));
      expect(result.status, equals(AnalysisStatus.pending));
      expect(result.isPending, isTrue);
    });

    test('should create running result', () {
      final result = AnalysisResult.running(id: 'test-id');

      expect(result.id, equals('test-id'));
      expect(result.status, equals(AnalysisStatus.running));
      expect(result.isRunning, isTrue);
      expect(result.startedAt, isNotNull);
    });

    test('should create failed result', () {
      final result = AnalysisResult.failed(
        id: 'test-id',
        errorMessage: 'Test error',
      );

      expect(result.id, equals('test-id'));
      expect(result.status, equals(AnalysisStatus.failed));
      expect(result.isFailed, isTrue);
      expect(result.errorMessage, equals('Test error'));
    });

    test('should check if finished', () {
      final completedResult = AnalysisResult.empty(id: 'test')
          .copyWith(status: AnalysisStatus.completed);
      final failedResult = AnalysisResult.failed(
        id: 'test',
        errorMessage: 'Error',
      );
      final cancelledResult = AnalysisResult.empty(id: 'test')
          .copyWith(status: AnalysisStatus.cancelled);

      expect(completedResult.isFinished, isTrue);
      expect(failedResult.isFinished, isTrue);
      expect(cancelledResult.isFinished, isTrue);
    });
  });
}
