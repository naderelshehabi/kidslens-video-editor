import 'package:flutter_test/flutter_test.dart';
import 'package:kidslens_video_editor/data/models/analysis_result.dart';
import 'package:kidslens_video_editor/data/models/analysis_settings.dart';
import 'package:kidslens_video_editor/data/models/media_file.dart';
import 'package:kidslens_video_editor/state/providers/analysis_provider.dart';

void main() {
  group('AnalysisState', () {
    group('creation', () {
      test('should create initial state', () {
        final state = AnalysisState.initial();

        expect(state.status, equals(AnalysisStatus.idle));
        expect(state.mediaFile, isNull);
        expect(state.settings, isNull);
        expect(state.result, isNull);
        expect(state.progress, isNull);
        expect(state.error, isNull);
      });

      test('should create with required fields', () {
        final mediaFile = MediaFile.video(
          id: 'video-123',
          path: '/path/to/video.mp4',
          name: 'video.mp4',
          duration: const Duration(minutes: 5),
          width: 1920,
          height: 1080,
          fileSize: 104857600,
          codec: 'h264',
          container: 'mp4',
        );
        final settings = AnalysisSettings.defaults();

        final state = AnalysisState(
          status: AnalysisStatus.analyzing,
          mediaFile: mediaFile,
          settings: settings,
        );

        expect(state.status, equals(AnalysisStatus.analyzing));
        expect(state.mediaFile, equals(mediaFile));
        expect(state.settings, equals(settings));
      });
    });

    group('status checks', () {
      test('isIdle should return true for idle state', () {
        final state = AnalysisState.initial();

        expect(state.isIdle, isTrue);
        expect(state.isAnalyzing, isFalse);
        expect(state.isComplete, isFalse);
      });

      test('isAnalyzing should return true for analyzing state', () {
        final state = AnalysisState(
          status: AnalysisStatus.analyzing,
        );

        expect(state.isAnalyzing, isTrue);
        expect(state.isIdle, isFalse);
        expect(state.isComplete, isFalse);
      });

      test('isComplete should return true for completed state', () {
        final state = AnalysisState(
          status: AnalysisStatus.completed,
        );

        expect(state.isComplete, isTrue);
        expect(state.isIdle, isFalse);
        expect(state.isAnalyzing, isFalse);
      });

      test('isPaused should return true for paused state', () {
        final state = AnalysisState(
          status: AnalysisStatus.paused,
        );

        expect(state.isPaused, isTrue);
      });

      test('isCancelled should return true for cancelled state', () {
        final state = AnalysisState(
          status: AnalysisStatus.cancelled,
        );

        expect(state.isCancelled, isTrue);
      });

      test('isFailed should return true for failed state', () {
        final state = AnalysisState(
          status: AnalysisStatus.failed,
          error: 'Analysis failed',
        );

        expect(state.isFailed, isTrue);
        expect(state.error, equals('Analysis failed'));
      });
    });

    group('progress tracking', () {
      test('should track progress percentage', () {
        final progress = AnalysisProgress(
          currentStage: 'transcription',
          stageProgress: 0.5,
          overallProgress: 0.25,
        );

        final state = AnalysisState(
          status: AnalysisStatus.analyzing,
          progress: progress,
        );

        expect(state.progress?.overallProgress, equals(0.25));
        expect(state.progress?.stageProgress, equals(0.5));
        expect(state.progress?.currentStage, equals('transcription'));
      });

      test('should track estimated time remaining', () {
        final progress = AnalysisProgress(
          currentStage: 'detection',
          stageProgress: 0.5,
          overallProgress: 0.5,
          estimatedTimeRemaining: const Duration(minutes: 2),
        );

        final state = AnalysisState(
          status: AnalysisStatus.analyzing,
          progress: progress,
        );

        expect(
          state.progress?.estimatedTimeRemaining,
          equals(const Duration(minutes: 2)),
        );
      });

      test('should track elapsed time', () {
        final progress = AnalysisProgress(
          currentStage: 'detection',
          stageProgress: 0.5,
          overallProgress: 0.5,
          elapsedTime: const Duration(minutes: 5),
        );

        final state = AnalysisState(
          status: AnalysisStatus.analyzing,
          progress: progress,
        );

        expect(
          state.progress?.elapsedTime,
          equals(const Duration(minutes: 5)),
        );
      });
    });

    group('copyWith', () {
      test('should copy with new status', () {
        final state = AnalysisState.initial();
        final newState = state.copyWith(status: AnalysisStatus.analyzing);

        expect(newState.status, equals(AnalysisStatus.analyzing));
        expect(state.status, equals(AnalysisStatus.idle)); // Original unchanged
      });

      test('should copy with new progress', () {
        final state = AnalysisState(status: AnalysisStatus.analyzing);
        final progress = AnalysisProgress(
          currentStage: 'test',
          stageProgress: 0.5,
          overallProgress: 0.5,
        );
        final newState = state.copyWith(progress: progress);

        expect(newState.progress, equals(progress));
      });

      test('should copy with result', () {
        final state = AnalysisState(status: AnalysisStatus.analyzing);
        final result = AnalysisResult.empty();
        final newState = state.copyWith(
          status: AnalysisStatus.completed,
          result: result,
        );

        expect(newState.status, equals(AnalysisStatus.completed));
        expect(newState.result, equals(result));
      });
    });

    group('equality', () {
      test('should be equal with same values', () {
        final state1 = AnalysisState(status: AnalysisStatus.idle);
        final state2 = AnalysisState(status: AnalysisStatus.idle);

        expect(state1, equals(state2));
      });

      test('should not be equal with different status', () {
        final state1 = AnalysisState(status: AnalysisStatus.idle);
        final state2 = AnalysisState(status: AnalysisStatus.analyzing);

        expect(state1, isNot(equals(state2)));
      });
    });
  });

  group('AnalysisNotifier', () {
    late AnalysisNotifier notifier;

    setUp(() {
      notifier = AnalysisNotifier();
    });

    group('initialization', () {
      test('should start with initial state', () {
        expect(notifier.state.isIdle, isTrue);
        expect(notifier.state.mediaFile, isNull);
        expect(notifier.state.settings, isNull);
      });
    });

    group('setMediaFile', () {
      test('should update media file', () {
        final mediaFile = MediaFile.video(
          id: 'video-123',
          path: '/path/to/video.mp4',
          name: 'video.mp4',
          duration: const Duration(minutes: 5),
          width: 1920,
          height: 1080,
          fileSize: 104857600,
          codec: 'h264',
          container: 'mp4',
        );

        notifier.setMediaFile(mediaFile);

        expect(notifier.state.mediaFile, equals(mediaFile));
      });

      test('should reset previous analysis', () {
        final oldFile = MediaFile.video(
          id: 'old-video',
          path: '/path/to/old.mp4',
          name: 'old.mp4',
          duration: const Duration(minutes: 2),
          width: 1280,
          height: 720,
          fileSize: 52428800,
          codec: 'h264',
          container: 'mp4',
        );

        final newFile = MediaFile.video(
          id: 'new-video',
          path: '/path/to/new.mp4',
          name: 'new.mp4',
          duration: const Duration(minutes: 5),
          width: 1920,
          height: 1080,
          fileSize: 104857600,
          codec: 'h264',
          container: 'mp4',
        );

        notifier.setMediaFile(oldFile);
        notifier.setMediaFile(newFile);

        expect(notifier.state.mediaFile, equals(newFile));
        expect(notifier.state.result, isNull);
      });
    });

    group('setSettings', () {
      test('should update analysis settings', () {
        final settings = AnalysisSettings.defaults();

        notifier.setSettings(settings);

        expect(notifier.state.settings, equals(settings));
      });

      test('should accept different settings configurations', () {
        final strictSettings = AnalysisSettings.strict();

        notifier.setSettings(strictSettings);

        expect(notifier.state.settings?.profanityConfig.strictMode, isTrue);
      });
    });

    group('startAnalysis', () {
      test('should transition to analyzing state', () async {
        final mediaFile = MediaFile.video(
          id: 'video-123',
          path: '/path/to/video.mp4',
          name: 'video.mp4',
          duration: const Duration(minutes: 5),
          width: 1920,
          height: 1080,
          fileSize: 104857600,
          codec: 'h264',
          container: 'mp4',
        );
        final settings = AnalysisSettings.defaults();

        notifier.setMediaFile(mediaFile);
        notifier.setSettings(settings);

        // Just test state transition, not actual analysis
        notifier.startAnalysis();

        expect(notifier.state.isAnalyzing, isTrue);
      });

      test('should not start without media file', () {
        final settings = AnalysisSettings.defaults();
        notifier.setSettings(settings);

        notifier.startAnalysis();

        expect(notifier.state.isIdle, isTrue);
      });

      test('should not start without settings', () {
        final mediaFile = MediaFile.video(
          id: 'video-123',
          path: '/path/to/video.mp4',
          name: 'video.mp4',
          duration: const Duration(minutes: 5),
          width: 1920,
          height: 1080,
          fileSize: 104857600,
          codec: 'h264',
          container: 'mp4',
        );
        notifier.setMediaFile(mediaFile);

        notifier.startAnalysis();

        expect(notifier.state.isIdle, isTrue);
      });
    });

    group('updateProgress', () {
      test('should update progress during analysis', () {
        final mediaFile = MediaFile.video(
          id: 'video-123',
          path: '/path/to/video.mp4',
          name: 'video.mp4',
          duration: const Duration(minutes: 5),
          width: 1920,
          height: 1080,
          fileSize: 104857600,
          codec: 'h264',
          container: 'mp4',
        );
        final settings = AnalysisSettings.defaults();

        notifier.setMediaFile(mediaFile);
        notifier.setSettings(settings);
        notifier.startAnalysis();

        final progress = AnalysisProgress(
          currentStage: 'transcription',
          stageProgress: 0.5,
          overallProgress: 0.25,
        );

        notifier.updateProgress(progress);

        expect(notifier.state.progress, equals(progress));
      });

      test('should not update progress when not analyzing', () {
        final progress = AnalysisProgress(
          currentStage: 'transcription',
          stageProgress: 0.5,
          overallProgress: 0.25,
        );

        notifier.updateProgress(progress);

        expect(notifier.state.progress, isNull);
      });
    });

    group('pause', () {
      test('should pause ongoing analysis', () {
        final mediaFile = MediaFile.video(
          id: 'video-123',
          path: '/path/to/video.mp4',
          name: 'video.mp4',
          duration: const Duration(minutes: 5),
          width: 1920,
          height: 1080,
          fileSize: 104857600,
          codec: 'h264',
          container: 'mp4',
        );
        final settings = AnalysisSettings.defaults();

        notifier.setMediaFile(mediaFile);
        notifier.setSettings(settings);
        notifier.startAnalysis();
        notifier.pause();

        expect(notifier.state.isPaused, isTrue);
      });

      test('should not pause if not analyzing', () {
        notifier.pause();

        expect(notifier.state.isIdle, isTrue);
        expect(notifier.state.isPaused, isFalse);
      });
    });

    group('resume', () {
      test('should resume paused analysis', () {
        final mediaFile = MediaFile.video(
          id: 'video-123',
          path: '/path/to/video.mp4',
          name: 'video.mp4',
          duration: const Duration(minutes: 5),
          width: 1920,
          height: 1080,
          fileSize: 104857600,
          codec: 'h264',
          container: 'mp4',
        );
        final settings = AnalysisSettings.defaults();

        notifier.setMediaFile(mediaFile);
        notifier.setSettings(settings);
        notifier.startAnalysis();
        notifier.pause();
        notifier.resume();

        expect(notifier.state.isAnalyzing, isTrue);
      });

      test('should not resume if not paused', () {
        notifier.resume();

        expect(notifier.state.isIdle, isTrue);
      });
    });

    group('cancel', () {
      test('should cancel ongoing analysis', () {
        final mediaFile = MediaFile.video(
          id: 'video-123',
          path: '/path/to/video.mp4',
          name: 'video.mp4',
          duration: const Duration(minutes: 5),
          width: 1920,
          height: 1080,
          fileSize: 104857600,
          codec: 'h264',
          container: 'mp4',
        );
        final settings = AnalysisSettings.defaults();

        notifier.setMediaFile(mediaFile);
        notifier.setSettings(settings);
        notifier.startAnalysis();
        notifier.cancel();

        expect(notifier.state.isCancelled, isTrue);
      });

      test('should cancel paused analysis', () {
        final mediaFile = MediaFile.video(
          id: 'video-123',
          path: '/path/to/video.mp4',
          name: 'video.mp4',
          duration: const Duration(minutes: 5),
          width: 1920,
          height: 1080,
          fileSize: 104857600,
          codec: 'h264',
          container: 'mp4',
        );
        final settings = AnalysisSettings.defaults();

        notifier.setMediaFile(mediaFile);
        notifier.setSettings(settings);
        notifier.startAnalysis();
        notifier.pause();
        notifier.cancel();

        expect(notifier.state.isCancelled, isTrue);
      });
    });

    group('complete', () {
      test('should complete with result', () {
        final mediaFile = MediaFile.video(
          id: 'video-123',
          path: '/path/to/video.mp4',
          name: 'video.mp4',
          duration: const Duration(minutes: 5),
          width: 1920,
          height: 1080,
          fileSize: 104857600,
          codec: 'h264',
          container: 'mp4',
        );
        final settings = AnalysisSettings.defaults();
        final result = AnalysisResult.empty();

        notifier.setMediaFile(mediaFile);
        notifier.setSettings(settings);
        notifier.startAnalysis();
        notifier.complete(result);

        expect(notifier.state.isComplete, isTrue);
        expect(notifier.state.result, equals(result));
      });
    });

    group('fail', () {
      test('should transition to failed state with error', () {
        final mediaFile = MediaFile.video(
          id: 'video-123',
          path: '/path/to/video.mp4',
          name: 'video.mp4',
          duration: const Duration(minutes: 5),
          width: 1920,
          height: 1080,
          fileSize: 104857600,
          codec: 'h264',
          container: 'mp4',
        );
        final settings = AnalysisSettings.defaults();

        notifier.setMediaFile(mediaFile);
        notifier.setSettings(settings);
        notifier.startAnalysis();
        notifier.fail('Analysis error occurred');

        expect(notifier.state.isFailed, isTrue);
        expect(notifier.state.error, equals('Analysis error occurred'));
      });
    });

    group('reset', () {
      test('should reset to initial state', () {
        final mediaFile = MediaFile.video(
          id: 'video-123',
          path: '/path/to/video.mp4',
          name: 'video.mp4',
          duration: const Duration(minutes: 5),
          width: 1920,
          height: 1080,
          fileSize: 104857600,
          codec: 'h264',
          container: 'mp4',
        );
        final settings = AnalysisSettings.defaults();

        notifier.setMediaFile(mediaFile);
        notifier.setSettings(settings);
        notifier.startAnalysis();
        notifier.reset();

        expect(notifier.state.isIdle, isTrue);
        expect(notifier.state.mediaFile, isNull);
        expect(notifier.state.settings, isNull);
        expect(notifier.state.result, isNull);
        expect(notifier.state.progress, isNull);
      });

      test('should reset from failed state', () {
        final mediaFile = MediaFile.video(
          id: 'video-123',
          path: '/path/to/video.mp4',
          name: 'video.mp4',
          duration: const Duration(minutes: 5),
          width: 1920,
          height: 1080,
          fileSize: 104857600,
          codec: 'h264',
          container: 'mp4',
        );
        final settings = AnalysisSettings.defaults();

        notifier.setMediaFile(mediaFile);
        notifier.setSettings(settings);
        notifier.startAnalysis();
        notifier.fail('Error');
        notifier.reset();

        expect(notifier.state.isIdle, isTrue);
        expect(notifier.state.error, isNull);
      });
    });

    group('canStart', () {
      test('should return true when media and settings are set', () {
        final mediaFile = MediaFile.video(
          id: 'video-123',
          path: '/path/to/video.mp4',
          name: 'video.mp4',
          duration: const Duration(minutes: 5),
          width: 1920,
          height: 1080,
          fileSize: 104857600,
          codec: 'h264',
          container: 'mp4',
        );
        final settings = AnalysisSettings.defaults();

        notifier.setMediaFile(mediaFile);
        notifier.setSettings(settings);

        expect(notifier.canStart, isTrue);
      });

      test('should return false without media file', () {
        final settings = AnalysisSettings.defaults();
        notifier.setSettings(settings);

        expect(notifier.canStart, isFalse);
      });

      test('should return false without settings', () {
        final mediaFile = MediaFile.video(
          id: 'video-123',
          path: '/path/to/video.mp4',
          name: 'video.mp4',
          duration: const Duration(minutes: 5),
          width: 1920,
          height: 1080,
          fileSize: 104857600,
          codec: 'h264',
          container: 'mp4',
        );
        notifier.setMediaFile(mediaFile);

        expect(notifier.canStart, isFalse);
      });

      test('should return false when already analyzing', () {
        final mediaFile = MediaFile.video(
          id: 'video-123',
          path: '/path/to/video.mp4',
          name: 'video.mp4',
          duration: const Duration(minutes: 5),
          width: 1920,
          height: 1080,
          fileSize: 104857600,
          codec: 'h264',
          container: 'mp4',
        );
        final settings = AnalysisSettings.defaults();

        notifier.setMediaFile(mediaFile);
        notifier.setSettings(settings);
        notifier.startAnalysis();

        expect(notifier.canStart, isFalse);
      });
    });
  });
}
