import 'dart:async';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:kidslens_video_editor/data/models/frame_data.dart';
import 'package:kidslens_video_editor/native/bindings/onnx_bindings.dart';
import 'package:kidslens_video_editor/services/model_manager_service.dart';
import 'package:kidslens_video_editor/services/visual_analysis_service.dart';

// ==========================================================================
// Mock Classes
// ==========================================================================

/// Mock ONNX bindings that returns safe scores and tracks call counts.
class MockONNXBindings extends ONNXBindings {
  int initializeCallCount = 0;
  int loadModelCallCount = 0;
  int runInferenceCallCount = 0;

  @override
  Future<void> initialize({List<String>? executionProviders}) async {
    initializeCallCount++;
  }

  @override
  Future<void> loadModel(String modelPath) async {
    loadModelCallCount++;
  }

  @override
  Future<Map<String, double>> runInference(
    String modelPath,
    List<int> rgbData,
    int width,
    int height,
  ) async {
    runInferenceCallCount++;
    return {
      'porn': 0.0,
      'sexy': 0.0,
      'hentai': 0.0,
      'drawings': 0.0,
      'neutral': 1.0,
    };
  }

  @override
  void unloadModel(String modelPath) {}

  @override
  void releaseNative() {}
}

/// Mock model manager that returns configurable model paths.
class MockModelManagerService extends ModelManagerService {
  Map<String, String> modelPaths = {};

  @override
  Future<String?> getModelPath(String modelId) async {
    return modelPaths[modelId];
  }

  @override
  Future<String> get modelsDirectory async => '/fake/models';
}

// ==========================================================================
// Test Helpers
// ==========================================================================

/// Creates a valid 10x10 RGB test frame.
FrameData _createTestFrame({
  int width = 10,
  int height = 10,
  Duration timestamp = Duration.zero,
  int frameNumber = 0,
}) {
  return FrameData(
    data: Uint8List(width * height * 3),
    width: width,
    height: height,
    timestamp: timestamp,
    frameNumber: frameNumber,
  );
}

/// Creates a list of sequential test frames.
List<FrameData> _createTestFrames(int count) {
  return List.generate(
    count,
    (i) => _createTestFrame(
      frameNumber: i,
      timestamp: Duration(milliseconds: i * 500),
    ),
  );
}

/// Creates settings for cancellation tests with the given batch size.
///
/// Only NSFW is enabled (the simplest path through _processBatch) to keep
/// the tests focused on cancellation semantics rather than multi-model
/// interactions.
VisualAnalysisSettings _cancellationSettings({int batchSize = 1}) {
  return VisualAnalysisSettings(
    enableNsfw: true,
    enableViolence: false,
    enableBlood: false,
    enableWeapons: false,
    batchSize: batchSize,
  );
}

// ==========================================================================
// Tests
// ==========================================================================

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late MockONNXBindings mockOnnx;
  late MockModelManagerService mockModelManager;
  late VisualAnalysisService service;

  setUp(() {
    mockOnnx = MockONNXBindings();
    mockModelManager = MockModelManagerService()
      ..modelPaths = {
          'nsfw-mobilenet-v2': '/fake/nsfw/model.onnx',
        };
    service = VisualAnalysisService(
      onnx: mockOnnx,
      modelManager: mockModelManager,
    );
  });

  group('VisualAnalysisService - cancellation behaviour', () {
    // ----------------------------------------------------------------
    // Group 1: Cancellation between frames
    // ----------------------------------------------------------------
    group('Cancellation between frames', () {
      test('cancelling after first progress event stops processing early',
          () async {
        final frames = Stream.fromIterable(_createTestFrames(10));
        final settings = _cancellationSettings(batchSize: 1);

        final progress = <VisualAnalysisProgress>[];
        await for (final p in service.analyzeFrames(frames, settings)) {
          progress.add(p);
          if (progress.length == 1) {
            service.cancelAnalysis();
          }
        }

        // After cancelling at the first yield the cancellation check fires
        // before the next frame is added to the batch, so at most one
        // additional progress event could sneak through (unlikely with
        // synchronous Stream.fromIterable, but we allow it defensively).
        expect(progress.length, lessThanOrEqualTo(2));
        expect(progress.length, greaterThan(0));
        expect(service.isRunning, isFalse);
      });

      test('cancelling after second progress yields fewer than total events',
          () async {
        final frames = Stream.fromIterable(_createTestFrames(10));
        final settings = _cancellationSettings(batchSize: 1);

        final progress = <VisualAnalysisProgress>[];
        await for (final p in service.analyzeFrames(frames, settings)) {
          progress.add(p);
          if (progress.length == 2) {
            service.cancelAnalysis();
          }
        }

        expect(progress.length, lessThanOrEqualTo(3));
        expect(progress.length, greaterThanOrEqualTo(2));
        expect(service.isRunning, isFalse);
      });

      test('without cancellation all frames are processed', () async {
        final frames = Stream.fromIterable(_createTestFrames(5));
        final settings = _cancellationSettings(batchSize: 1);

        final progress = <VisualAnalysisProgress>[];
        await for (final p in service.analyzeFrames(frames, settings)) {
          progress.add(p);
        }

        expect(progress.length, equals(5));
        expect(progress.last.framesProcessed, equals(5));
        expect(service.isRunning, isFalse);
      });
    });

    // ----------------------------------------------------------------
    // Group 2: Cancellation flag reset
    // ----------------------------------------------------------------
    group('Cancellation flag reset', () {
      test('new analysis resets _isCancelled from previous cancellation',
          () async {
        // First analysis: cancel immediately on first yield.
        final frames1 = Stream.fromIterable(_createTestFrames(5));
        final settings = _cancellationSettings(batchSize: 1);

        await for (final _ in service.analyzeFrames(frames1, settings)) {
          service.cancelAnalysis();
        }
        expect(service.isRunning, isFalse);

        // Second analysis: _isCancelled should be reset to false at the
        // start of analyzeFrames, so all frames should be processed.
        final frames2 = Stream.fromIterable(_createTestFrames(3));
        final progress = <VisualAnalysisProgress>[];
        await for (final p in service.analyzeFrames(frames2, settings)) {
          progress.add(p);
        }

        expect(progress.length, equals(3));
        expect(progress.last.framesProcessed, equals(3));
      });

      test('calling cancelAnalysis before starting does not affect the next run',
          () async {
        // Cancel before any analysis has ever started.
        service.cancelAnalysis();

        final frames = Stream.fromIterable(_createTestFrames(4));
        final settings = _cancellationSettings(batchSize: 1);

        final progress = <VisualAnalysisProgress>[];
        await for (final p in service.analyzeFrames(frames, settings)) {
          progress.add(p);
        }

        expect(
          progress.length,
          equals(4),
          reason: '_isCancelled is reset to false at the start of '
              'analyzeFrames, so a prior cancelAnalysis call has no effect',
        );
        expect(progress.last.framesProcessed, equals(4));
      });
    });

    // ----------------------------------------------------------------
    // Group 3: isRunning state
    // ----------------------------------------------------------------
    group('isRunning state', () {
      test('isRunning is false before analysis starts', () {
        expect(service.isRunning, isFalse);
      });

      test('isRunning is true during analysis (checked between yields)',
          () async {
        final frames = Stream.fromIterable(_createTestFrames(5));
        final settings = _cancellationSettings(batchSize: 1);

        var checkedDuringAnalysis = false;
        await for (final _ in service.analyzeFrames(frames, settings)) {
          expect(service.isRunning, isTrue);
          checkedDuringAnalysis = true;
        }

        expect(
          checkedDuringAnalysis,
          isTrue,
          reason: 'Should have verified isRunning at least once while '
              'the analysis stream was active',
        );
      });

      test('isRunning is false after analysis completes normally', () async {
        final frames = Stream.fromIterable(_createTestFrames(3));
        final settings = _cancellationSettings(batchSize: 1);

        await for (final _ in service.analyzeFrames(frames, settings)) {
          // consume all events
        }

        expect(service.isRunning, isFalse);
      });

      test('isRunning is false after cancellation', () async {
        final frames = Stream.fromIterable(_createTestFrames(10));
        final settings = _cancellationSettings(batchSize: 1);

        await for (final _ in service.analyzeFrames(frames, settings)) {
          service.cancelAnalysis();
        }

        expect(service.isRunning, isFalse);
      });
    });

    // ----------------------------------------------------------------
    // Group 4: Partial results are valid
    // ----------------------------------------------------------------
    group('Partial results are valid', () {
      test('progress events received before cancellation have valid data',
          () async {
        final frames = Stream.fromIterable(_createTestFrames(5));
        final settings = _cancellationSettings(batchSize: 1);

        final progress = <VisualAnalysisProgress>[];
        await for (final p in service.analyzeFrames(frames, settings)) {
          progress.add(p);
          if (progress.length == 2) {
            service.cancelAnalysis();
          }
        }

        expect(progress.length, greaterThanOrEqualTo(2));

        for (var i = 0; i < progress.length; i++) {
          final p = progress[i];
          expect(
            p.framesProcessed,
            greaterThan(0),
            reason: 'Progress event $i should have framesProcessed > 0',
          );
          expect(
            p.currentResult.frameNumber,
            greaterThanOrEqualTo(0),
            reason: 'Progress event $i should have a non-negative frame number',
          );
          expect(
            p.currentResult.nsfw.neutral,
            greaterThanOrEqualTo(0),
            reason: 'Partial result $i should contain a valid NSFW score',
          );
        }
      });

      test('framesProcessed increments correctly in partial results',
          () async {
        final frames = Stream.fromIterable(_createTestFrames(10));
        final settings = _cancellationSettings(batchSize: 1);

        final progress = <VisualAnalysisProgress>[];
        await for (final p in service.analyzeFrames(frames, settings)) {
          progress.add(p);
          if (progress.length == 3) {
            service.cancelAnalysis();
          }
        }

        // With batchSize 1, framesProcessed should increment by 1 each yield.
        for (var i = 0; i < progress.length; i++) {
          expect(
            progress[i].framesProcessed,
            equals(i + 1),
            reason: 'framesProcessed should be ${i + 1} for event $i',
          );
        }
      });

      test('each partial result has a distinct timestamp', () async {
        final frames = Stream.fromIterable(_createTestFrames(10));
        final settings = _cancellationSettings(batchSize: 1);

        final progress = <VisualAnalysisProgress>[];
        await for (final p in service.analyzeFrames(frames, settings)) {
          progress.add(p);
          if (progress.length == 4) {
            service.cancelAnalysis();
          }
        }

        // Each frame was created with timestamp = i * 500ms, so each
        // currentResult should have a unique, increasing timestamp.
        final timestamps =
            progress.map((p) => p.currentResult.timestamp).toList();
        for (var i = 1; i < timestamps.length; i++) {
          expect(
            timestamps[i],
            greaterThan(timestamps[i - 1]),
            reason: 'Timestamps should be strictly increasing',
          );
        }
      });
    });

    // ----------------------------------------------------------------
    // Group 5: Cancellation before any frames
    // ----------------------------------------------------------------
    group('Cancellation before any frames', () {
      test(
          'cancelAnalysis() before starting is reset, '
          'all frames are processed', () async {
        // Set the cancellation flag before starting.
        service.cancelAnalysis();

        final frames = Stream.fromIterable(_createTestFrames(5));
        final settings = _cancellationSettings(batchSize: 1);

        final progress = <VisualAnalysisProgress>[];
        await for (final p in service.analyzeFrames(frames, settings)) {
          progress.add(p);
        }

        expect(
          progress.length,
          equals(5),
          reason: '_isCancelled is reset to false at the start of '
              'analyzeFrames, so a prior call has no effect',
        );
        expect(service.isRunning, isFalse);
      });

      test('empty frame stream completes immediately', () async {
        final frames = Stream<FrameData>.fromIterable([]);
        final settings = _cancellationSettings(batchSize: 1);

        final progress = <VisualAnalysisProgress>[];
        await for (final p in service.analyzeFrames(frames, settings)) {
          progress.add(p);
        }

        expect(progress, isEmpty);
        expect(service.isRunning, isFalse);
      });
    });

    // ----------------------------------------------------------------
    // Group 6: Remaining batch handling
    // ----------------------------------------------------------------
    group('Remaining batch handling', () {
      test(
          'without cancellation remaining frames in a partial batch '
          'are processed', () async {
        // 3 frames with batchSize 2:
        //   Batch [0,1] -> yield (framesProcessed=2)
        //   Remaining [2] -> yield (framesProcessed=3)
        final frames = Stream.fromIterable(_createTestFrames(3));
        final settings = _cancellationSettings(batchSize: 2);

        final progress = <VisualAnalysisProgress>[];
        await for (final p in service.analyzeFrames(frames, settings)) {
          progress.add(p);
        }

        expect(
          progress.length,
          equals(2),
          reason: 'Should get 2 yields: one for batch [0,1] '
              'and one for remaining [2]',
        );
        expect(progress[0].framesProcessed, equals(2));
        expect(progress[1].framesProcessed, equals(3));
      });

      test(
          'with cancellation after first batch the remaining frame '
          'is not processed', () async {
        // 3 frames with batchSize 2:
        //   Batch [0,1] -> yield (framesProcessed=2) -> cancel
        //   Frame 2: _isCancelled=true -> break
        //   Batch is empty, so no remaining-batch yield
        final frames = Stream.fromIterable(_createTestFrames(3));
        final settings = _cancellationSettings(batchSize: 2);

        final progress = <VisualAnalysisProgress>[];
        await for (final p in service.analyzeFrames(frames, settings)) {
          progress.add(p);
          if (progress.length == 1) {
            service.cancelAnalysis();
          }
        }

        expect(
          progress.length,
          equals(1),
          reason: 'Only the first full batch should be processed; '
              'the remaining frame is skipped after cancellation',
        );
        expect(progress[0].framesProcessed, equals(2));
        expect(service.isRunning, isFalse);
      });

      test(
          'cancellation prevents remaining partial batch from being processed '
          'with larger batch size', () async {
        // 5 frames with batchSize 3:
        //   Batch [0,1,2] -> yield (framesProcessed=3) -> cancel
        //   Frame 3: _isCancelled=true -> break
        //   Frames 3 and 4 never enter the batch
        final frames = Stream.fromIterable(_createTestFrames(5));
        final settings = _cancellationSettings(batchSize: 3);

        final progress = <VisualAnalysisProgress>[];
        await for (final p in service.analyzeFrames(frames, settings)) {
          progress.add(p);
          service.cancelAnalysis();
        }

        expect(progress.length, equals(1));
        expect(progress[0].framesProcessed, equals(3));
        expect(service.isRunning, isFalse);
      });

      test(
          'without cancellation all batches including remainder are emitted',
          () async {
        // 7 frames with batchSize 3:
        //   Batch [0,1,2] -> yield (framesProcessed=3)
        //   Batch [3,4,5] -> yield (framesProcessed=6)
        //   Remaining [6] -> yield (framesProcessed=7)
        final frames = Stream.fromIterable(_createTestFrames(7));
        final settings = _cancellationSettings(batchSize: 3);

        final progress = <VisualAnalysisProgress>[];
        await for (final p in service.analyzeFrames(frames, settings)) {
          progress.add(p);
        }

        expect(progress.length, equals(3));
        expect(progress[0].framesProcessed, equals(3));
        expect(progress[1].framesProcessed, equals(6));
        expect(progress[2].framesProcessed, equals(7));
      });
    });

    // ----------------------------------------------------------------
    // Group 7: StreamController-based cancellation
    // ----------------------------------------------------------------
    group('StreamController-based cancellation', () {
      test('cancellation with a manually controlled stream', () async {
        final controller = StreamController<FrameData>();
        final settings = _cancellationSettings(batchSize: 1);

        final progress = <VisualAnalysisProgress>[];
        final subscription = service
            .analyzeFrames(controller.stream, settings)
            .listen((p) {
          progress.add(p);
          if (progress.length == 2) {
            service.cancelAnalysis();
            // Add more frames after cancellation to prove they
            // are not processed.
            controller
              ..add(_createTestFrame(frameNumber: 10))
              ..add(_createTestFrame(frameNumber: 11))
              ..close();
          }
        });

        // Feed frames one at a time.
        controller.add(
          _createTestFrame(
            frameNumber: 0,
            timestamp: Duration.zero,
          ),
        );
        controller.add(
          _createTestFrame(
            frameNumber: 1,
            timestamp: const Duration(milliseconds: 500),
          ),
        );

        await subscription.asFuture<void>();
        await subscription.cancel();

        expect(
          progress.length,
          lessThanOrEqualTo(3),
          reason: 'Cancellation should stop processing even though '
              'more frames were added to the stream',
        );
        expect(service.isRunning, isFalse);
      });
    });
  });
}
