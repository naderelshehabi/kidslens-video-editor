import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:kidslens_video_editor/data/models/analysis_settings.dart';
import 'package:kidslens_video_editor/data/models/frame_analysis_result.dart';
import 'package:kidslens_video_editor/data/models/frame_data.dart';
import 'package:kidslens_video_editor/data/models/visual_content_category.dart';
import 'package:kidslens_video_editor/native/bindings/onnx_bindings.dart';
import 'package:kidslens_video_editor/services/clip_service.dart';
import 'package:kidslens_video_editor/services/model_manager_service.dart';
import 'package:kidslens_video_editor/services/nudenet_service.dart';
import 'package:kidslens_video_editor/services/visual_analysis_service.dart';

// ==========================================================================
// Mock Classes
// ==========================================================================

/// Mock ONNX bindings that tracks calls and returns configurable results.
class MockONNXBindings extends ONNXBindings {
  /// Scores returned by [runInference]. Configurable per test.
  Map<String, double> scoresToReturn = {
    'porn': 0.0,
    'sexy': 0.0,
    'hentai': 0.0,
    'drawings': 0.0,
    'neutral': 1.0,
  };

  /// Whether [runInference] should throw an exception.
  bool shouldThrowOnInference = false;

  /// Number of times [runInference] was called.
  int runInferenceCallCount = 0;

  /// Number of times [initialize] was called.
  int initializeCallCount = 0;

  /// Number of times [loadModel] was called.
  int loadModelCallCount = 0;

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
    if (shouldThrowOnInference) {
      throw ONNXInferenceException('Mock inference exception');
    }
    return Map<String, double>.from(scoresToReturn);
  }

  @override
  void unloadModel(String modelPath) {}

  @override
  void releaseNative() {}
}

/// Mock model manager that returns configurable model paths.
class MockModelManagerService extends ModelManagerService {
  /// Map of model ID to file path.
  Map<String, String> modelPaths = {};

  @override
  Future<String?> getModelPath(String modelId) async => modelPaths[modelId];

  @override
  Future<String> get modelsDirectory async => '/fake/models';
}

/// Mock NudeNet service that tracks calls and returns configurable regions.
class MockNudeNetService extends NudeNetService {
  MockNudeNetService({
    required super.onnx,
    required super.modelManager,
  });

  /// Number of times [detectRegions] was called.
  int detectRegionsCallCount = 0;

  /// Regions returned by [detectRegions].
  List<DetectedRegion> regionsToReturn = [];

  /// Path returned by [getModelPath].
  String? modelPathToReturn = '/fake/nudenet/model.onnx';

  @override
  Future<String?> getModelPath([String modelId = 'nudenet-v3-medium']) async => modelPathToReturn;

  @override
  Future<List<DetectedRegion>> detectRegions({
    required String modelPath,
    required Uint8List rgbData,
    required int width,
    required int height,
    List<VisualContentCategory>? categories,
    double confidenceThreshold = NudeNetService.defaultConfidenceThreshold,
    int inputSize = NudeNetService.defaultInputSize,
  }) async {
    detectRegionsCallCount++;
    return regionsToReturn;
  }
}

/// Mock CLIP service that tracks calls and returns configurable scores.
class MockClipService extends ClipService {
  MockClipService({
    required super.onnx,
    required super.modelManager,
  });

  /// Number of times [classifyFrame] was called.
  int classifyFrameCallCount = 0;

  /// Scores returned by [classifyFrame].
  Map<String, double> scoresToReturn = {};

  /// Embeddings returned by [precomputePromptEmbeddings].
  Map<String, CategoryEmbeddings> embeddingsToReturn = {};

  @override
  Future<Map<String, double>> classifyFrame(
    Uint8List rgbData,
    int width,
    int height,
    Map<String, CategoryEmbeddings> textEmbeddings,
  ) async {
    classifyFrameCallCount++;
    return Map<String, double>.from(scoresToReturn);
  }

  @override
  Future<Map<String, CategoryEmbeddings>> precomputePromptEmbeddings(
    List<VisualContentCategory> categories,
  ) async => embeddingsToReturn;
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
}) => FrameData(
    data: Uint8List(width * height * 3),
    width: width,
    height: height,
    timestamp: timestamp,
    frameNumber: frameNumber,
  );

/// Creates a NudeNet-only visual content category.
VisualContentCategory _nudeNetCategory({
  String id = 'nudity',
  bool enabled = true,
}) => VisualContentCategory(
    id: id,
    name: 'Nudity Detection',
    description: 'Detects exposed body parts',
    detectionLabels: const ['FEMALE_BREAST_EXPOSED', 'BUTTOCKS_EXPOSED'],
    detectionSource: CategoryDetectionSource.nudeNet,
    enabled: enabled,
  );

/// Creates a CLIP-only visual content category.
VisualContentCategory _clipCategory({
  String id = 'violence-scene',
  bool enabled = true,
}) => VisualContentCategory(
    id: id,
    name: 'Violence Scene',
    description: 'Detects violent scenes via CLIP',
    clipPrompts: const ['a photo of a violent fight'],
    clipNegativePrompts: const ['a photo of people relaxing'],
    detectionSource: CategoryDetectionSource.clip,
    enabled: enabled,
  );

/// Creates [VisualAnalysisSettings] with only NSFW enabled plus a
/// configurable [VisualContentConfig].
VisualAnalysisSettings _settings({
  bool enableNudeNet = true,
  bool enableClip = true,
  bool useNsfwPreFilter = true,
  double preFilterThreshold = 0.30,
  List<VisualContentCategory>? categories,
}) {
  final cats = categories ??
      [
        if (enableNudeNet) _nudeNetCategory(),
        if (enableClip) _clipCategory(),
      ];

  return VisualAnalysisSettings(
    enableViolence: false,
    visualContentConfig: VisualContentConfig(
      enableNudeNetDetection: enableNudeNet,
      enableClipClassification: enableClip,
      useNsfwPreFilter: useNsfwPreFilter,
      preFilterThreshold: preFilterThreshold,
      categories: cats,
    ),
  );
}

// ==========================================================================
// Tests
// ==========================================================================

void main() {
  group('VisualAnalysisService - visual analysis pipeline', () {
    late MockONNXBindings mockOnnx;
    late MockModelManagerService mockModelManager;
    late MockNudeNetService mockNudeNet;
    late MockClipService mockClip;

    setUp(() {
      mockOnnx = MockONNXBindings();
      mockModelManager = MockModelManagerService();
      mockNudeNet = MockNudeNetService(
        onnx: mockOnnx,
        modelManager: mockModelManager,
      );
      mockClip = MockClipService(
        onnx: mockOnnx,
        modelManager: mockModelManager,
      );

      // Ensure the NSFW model path is available so NSFW inference runs.
      mockModelManager.modelPaths = {
        'nsfw-mobilenet-v2': '/fake/nsfw/model.onnx',
      };
    });

    // ------------------------------------------------------------------
    // Group 1: Pre-filter gating
    // ------------------------------------------------------------------
    group('Pre-filter gating', () {
      test(
        'NSFW score below preFilterThreshold does not trigger NudeNet',
        () async {
          mockOnnx.scoresToReturn = {
            'porn': 0.10,
            'sexy': 0.10,
            'hentai': 0.05,
            'drawings': 0.0,
            'neutral': 0.75,
          };

          final service = VisualAnalysisService(
            onnx: mockOnnx,
            modelManager: mockModelManager,
            nudeNetService: mockNudeNet,
          );

          final frame = _createTestFrame();
          final settings = _settings(enableClip: false);

          await service.analyzeFrame(frame, settings: settings);

          expect(
            mockNudeNet.detectRegionsCallCount,
            equals(0),
            reason: 'NudeNet should not run when NSFW score (0.10) '
                'is below preFilterThreshold (0.30)',
          );
        },
      );

      test(
        'NSFW score at exactly preFilterThreshold triggers NudeNet',
        () async {
          mockOnnx.scoresToReturn = {
            'porn': 0.30,
            'sexy': 0.0,
            'hentai': 0.0,
            'drawings': 0.0,
            'neutral': 0.70,
          };

          final service = VisualAnalysisService(
            onnx: mockOnnx,
            modelManager: mockModelManager,
            nudeNetService: mockNudeNet,
          );

          final frame = _createTestFrame();
          final settings = _settings(enableClip: false);

          await service.analyzeFrame(frame, settings: settings);

          expect(
            mockNudeNet.detectRegionsCallCount,
            equals(1),
            reason: 'NudeNet should run when NSFW score (0.30) '
                'equals preFilterThreshold (0.30)',
          );
        },
      );

      test(
        'NSFW score above preFilterThreshold triggers NudeNet',
        () async {
          mockOnnx.scoresToReturn = {
            'porn': 0.70,
            'sexy': 0.0,
            'hentai': 0.0,
            'drawings': 0.0,
            'neutral': 0.30,
          };

          final service = VisualAnalysisService(
            onnx: mockOnnx,
            modelManager: mockModelManager,
            nudeNetService: mockNudeNet,
          );

          final frame = _createTestFrame();
          final settings = _settings(enableClip: false);

          await service.analyzeFrame(frame, settings: settings);

          expect(
            mockNudeNet.detectRegionsCallCount,
            equals(1),
            reason: 'NudeNet should run when NSFW score (0.70) '
                'exceeds preFilterThreshold (0.30)',
          );
        },
      );

      test(
        'Pre-filter disabled causes NudeNet to always run',
        () async {
          // Low NSFW score that would normally block NudeNet.
          mockOnnx.scoresToReturn = {
            'porn': 0.01,
            'sexy': 0.01,
            'hentai': 0.01,
            'drawings': 0.0,
            'neutral': 0.97,
          };

          final service = VisualAnalysisService(
            onnx: mockOnnx,
            modelManager: mockModelManager,
            nudeNetService: mockNudeNet,
          );

          final frame = _createTestFrame();
          final settings = _settings(
            enableClip: false,
            useNsfwPreFilter: false,
          );

          await service.analyzeFrame(frame, settings: settings);

          expect(
            mockNudeNet.detectRegionsCallCount,
            equals(1),
            reason: 'NudeNet should always run when pre-filter is disabled, '
                'regardless of NSFW score',
          );
        },
      );
    });

    // ------------------------------------------------------------------
    // Group 2: CLIP path
    // ------------------------------------------------------------------
    group('CLIP path', () {
      test(
        'CLIP runs when enabled with categories and embeddings present',
        () async {
          mockClip
            ..scoresToReturn = {'violence-scene': 5.0}
            ..embeddingsToReturn = {
              'violence-scene': CategoryEmbeddings(
                positiveEmbeddings: [List.filled(512, 0.1)],
                negativeEmbeddings: [List.filled(512, 0)],
              ),
            };

          final service = VisualAnalysisService(
            onnx: mockOnnx,
            modelManager: mockModelManager,
            clipService: mockClip,
          );

          final category = _clipCategory();
          await service.precomputeClipEmbeddings([category]);

          final frame = _createTestFrame();
          final settings = _settings(
            enableNudeNet: false,
            categories: [category],
          );

          final result = await service.analyzeFrame(frame, settings: settings);

          expect(mockClip.classifyFrameCallCount, equals(1),
              reason: 'CLIP should run when enabled, categories present, '
                  'and embeddings precomputed',);
          expect(result.visualContent, isNotNull);
          expect(result.visualContent!.clipScores, isNotEmpty);
          expect(
              result.visualContent!.clipScores['violence-scene'], equals(5.0),);
        },
      );

      test(
        'CLIP not called when all CLIP categories are disabled',
        () async {
          mockClip.embeddingsToReturn = {
            'violence-scene': CategoryEmbeddings(
              positiveEmbeddings: [List.filled(512, 0.1)],
              negativeEmbeddings: [List.filled(512, 0)],
            ),
          };

          final service = VisualAnalysisService(
            onnx: mockOnnx,
            modelManager: mockModelManager,
            clipService: mockClip,
          );

          // Precompute with a dummy enabled category so _clipEmbeddings is
          // non-empty (isolating the hasClipCategories check).
          final tempEnabled = _clipCategory(id: 'temp');
          await service.precomputeClipEmbeddings([tempEnabled]);

          final disabledClip = _clipCategory(enabled: false);
          final enabledNudeNet = _nudeNetCategory();

          final frame = _createTestFrame();
          // hasAnyEnabled is true (nudeNet category is enabled) but
          // hasClipCategories is false (CLIP category disabled).
          final settings = _settings(
            categories: [disabledClip, enabledNudeNet],
          );

          await service.analyzeFrame(frame, settings: settings);

          expect(
            mockClip.classifyFrameCallCount,
            equals(0),
            reason:
                'CLIP should not run when all CLIP categories are disabled',
          );
        },
      );

      test(
        'CLIP not called when clipService is null',
        () async {
          final service = VisualAnalysisService(
            onnx: mockOnnx,
            modelManager: mockModelManager,
            // clipService intentionally omitted (null)
          );

          final frame = _createTestFrame();
          final settings = _settings(
            enableNudeNet: false,
          );

          final result = await service.analyzeFrame(frame, settings: settings);

          // With no clipService and no nudeNetService, no visual detections
          // are produced, so visualContent is null.
          expect(
            result.visualContent,
            isNull,
            reason: 'visualContent should be null when clipService is null '
                'and no NudeNet service is available',
          );
        },
      );

      test(
        'CLIP not called when embeddings are empty',
        () async {
          mockClip.embeddingsToReturn = {};

          final service = VisualAnalysisService(
            onnx: mockOnnx,
            modelManager: mockModelManager,
            clipService: mockClip,
          );

          // Precompute with a NudeNet-only category so that
          // _clipEmbeddings becomes {} (empty map).
          await service.precomputeClipEmbeddings([_nudeNetCategory()]);

          final frame = _createTestFrame();
          final settings = _settings(
            enableNudeNet: false,
          );

          await service.analyzeFrame(frame, settings: settings);

          expect(
            mockClip.classifyFrameCallCount,
            equals(0),
            reason: 'CLIP should not run when precomputed embeddings '
                'are empty',
          );
        },
      );
    });

    // ------------------------------------------------------------------
    // Group 3: Per-frame resilience
    // ------------------------------------------------------------------
    group('Per-frame resilience', () {
      test('frame with invalid data size returns safe result', () async {
        final service = VisualAnalysisService(
          onnx: mockOnnx,
          modelManager: mockModelManager,
        );

        // 10x10 RGB needs 300 bytes; provide only 100 to trigger the
        // data-size validation in _processBatch.
        final invalidFrame = FrameData(
          data: Uint8List(100),
          width: 10,
          height: 10,
          timestamp: const Duration(seconds: 1),
          frameNumber: 42,
        );

        final settings = _settings(enableNudeNet: false, enableClip: false);
        final result =
            await service.analyzeFrame(invalidFrame, settings: settings);

        expect(result.nsfw.isSafe, isTrue,
            reason: 'Invalid frame should return a safe NSFW result',);
        expect(result.violence.isSafe, isTrue,
            reason: 'Invalid frame should return a safe violence result',);
        expect(result.frameNumber, equals(42));
        expect(
          mockOnnx.runInferenceCallCount,
          equals(0),
          reason: 'No inference should be attempted for frames with '
              'invalid data size',
        );
      });

      test('ONNX inference exception returns safe result', () async {
        mockOnnx.shouldThrowOnInference = true;

        final service = VisualAnalysisService(
          onnx: mockOnnx,
          modelManager: mockModelManager,
        );

        final frame = _createTestFrame(frameNumber: 7);
        final settings = _settings(enableNudeNet: false, enableClip: false);
        final result = await service.analyzeFrame(frame, settings: settings);

        expect(result.nsfw.isSafe, isTrue,
            reason:
                'Exception during inference should produce a safe result',);
        expect(result.frameNumber, equals(7));
      });
    });

    // ------------------------------------------------------------------
    // Group 4: Combined pipeline
    // ------------------------------------------------------------------
    group('Combined pipeline', () {
      test(
        'both CLIP and NudeNet results combined into VisualContentResult',
        () async {
          // NSFW score high enough to pass the pre-filter.
          mockOnnx.scoresToReturn = {
            'porn': 0.80,
            'sexy': 0.0,
            'hentai': 0.0,
            'drawings': 0.0,
            'neutral': 0.20,
          };

          mockNudeNet.regionsToReturn = [
            const DetectedRegion(
              label: 'FEMALE_BREAST_EXPOSED',
              confidence: 0.85,
              x: 0.1,
              y: 0.2,
              width: 0.3,
              height: 0.4,
            ),
          ];

          mockClip
            ..scoresToReturn = {'violence-scene': 7.5}
            ..embeddingsToReturn = {
              'violence-scene': CategoryEmbeddings(
                positiveEmbeddings: [List.filled(512, 0.1)],
                negativeEmbeddings: [List.filled(512, 0)],
              ),
            };

          final service = VisualAnalysisService(
            onnx: mockOnnx,
            modelManager: mockModelManager,
            nudeNetService: mockNudeNet,
            clipService: mockClip,
          );

          final nudeNetCat = _nudeNetCategory();
          final clipCat = _clipCategory();
          await service.precomputeClipEmbeddings([clipCat]);

          final frame = _createTestFrame();
          final settings = _settings(
            categories: [nudeNetCat, clipCat],
          );

          final result = await service.analyzeFrame(frame, settings: settings);

          expect(result.visualContent, isNotNull);
          expect(result.visualContent!.detectedRegions, isNotEmpty,
              reason: 'NudeNet regions should be present',);
          expect(result.visualContent!.detectedRegions.first.label,
              equals('FEMALE_BREAST_EXPOSED'),);
          expect(result.visualContent!.clipScores, isNotEmpty,
              reason: 'CLIP scores should be present',);
          expect(result.visualContent!.clipScores['violence-scene'],
              equals(7.5),);
          expect(mockNudeNet.detectRegionsCallCount, equals(1));
          expect(mockClip.classifyFrameCallCount, equals(1));
        },
      );

      test('only NudeNet results when no CLIP categories', () async {
        mockOnnx.scoresToReturn = {
          'porn': 0.80,
          'sexy': 0.0,
          'hentai': 0.0,
          'drawings': 0.0,
          'neutral': 0.20,
        };

        mockNudeNet.regionsToReturn = [
          const DetectedRegion(
            label: 'BUTTOCKS_EXPOSED',
            confidence: 0.90,
            x: 0,
            y: 0,
            width: 0.5,
            height: 0.5,
          ),
        ];

        final service = VisualAnalysisService(
          onnx: mockOnnx,
          modelManager: mockModelManager,
          nudeNetService: mockNudeNet,
          clipService: mockClip,
        );

        final frame = _createTestFrame();
        final nudeNetCat = _nudeNetCategory();
        final settings = _settings(
          enableClip: false,
          categories: [nudeNetCat],
        );

        final result = await service.analyzeFrame(frame, settings: settings);

        expect(result.visualContent, isNotNull);
        expect(result.visualContent!.detectedRegions, isNotEmpty);
        expect(result.visualContent!.clipScores, isEmpty);
        expect(mockNudeNet.detectRegionsCallCount, equals(1));
        expect(mockClip.classifyFrameCallCount, equals(0));
      });

      test('only CLIP results when no NudeNet categories', () async {
        mockClip
          ..scoresToReturn = {'violence-scene': 4.2}
          ..embeddingsToReturn = {
            'violence-scene': CategoryEmbeddings(
              positiveEmbeddings: [List.filled(512, 0.1)],
              negativeEmbeddings: [List.filled(512, 0)],
            ),
          };

        final service = VisualAnalysisService(
          onnx: mockOnnx,
          modelManager: mockModelManager,
          nudeNetService: mockNudeNet,
          clipService: mockClip,
        );

        final clipCat = _clipCategory();
        await service.precomputeClipEmbeddings([clipCat]);

        final frame = _createTestFrame();
        final settings = _settings(
          enableNudeNet: false,
          categories: [clipCat],
        );

        final result = await service.analyzeFrame(frame, settings: settings);

        expect(result.visualContent, isNotNull);
        expect(result.visualContent!.clipScores, isNotEmpty);
        expect(result.visualContent!.detectedRegions, isEmpty);
        expect(mockClip.classifyFrameCallCount, equals(1));
        expect(mockNudeNet.detectRegionsCallCount, equals(0));
      });

      test(
        'null visualContent when both paths produce empty results',
        () async {
          // Safe NSFW score blocks NudeNet via pre-filter.
          mockOnnx.scoresToReturn = {
            'porn': 0.0,
            'sexy': 0.0,
            'hentai': 0.0,
            'drawings': 0.0,
            'neutral': 1.0,
          };

          mockNudeNet.regionsToReturn = [];
          mockClip
            ..scoresToReturn = {} // CLIP returns empty scores
            ..embeddingsToReturn = {
              'violence-scene': CategoryEmbeddings(
                positiveEmbeddings: [List.filled(512, 0.1)],
                negativeEmbeddings: [List.filled(512, 0)],
              ),
            };

          final service = VisualAnalysisService(
            onnx: mockOnnx,
            modelManager: mockModelManager,
            nudeNetService: mockNudeNet,
            clipService: mockClip,
          );

          final clipCat = _clipCategory();
          final nudeNetCat = _nudeNetCategory();
          await service.precomputeClipEmbeddings([clipCat]);

          final frame = _createTestFrame();
          final settings = _settings(
            categories: [nudeNetCat, clipCat],
          );

          final result = await service.analyzeFrame(frame, settings: settings);

          expect(
            result.visualContent,
            isNull,
            reason: 'visualContent should be null when both CLIP and '
                'NudeNet produce no detections',
          );
        },
      );
    });

    // ------------------------------------------------------------------
    // Group 5: Cancellation
    // ------------------------------------------------------------------
    group('Cancellation', () {
      test('cancelAnalysis stops processing between frames', () async {
        final service = VisualAnalysisService(
          onnx: mockOnnx,
          modelManager: mockModelManager,
        );

        // batchSize 1 ensures every frame triggers a progress yield.
        const settings = VisualAnalysisSettings(
          enableViolence: false,
          batchSize: 1,
        );

        final frames = Stream.fromIterable([
          _createTestFrame(),
          _createTestFrame(
              frameNumber: 1, timestamp: const Duration(seconds: 1),),
          _createTestFrame(
              frameNumber: 2, timestamp: const Duration(seconds: 2),),
        ]);

        var progressCount = 0;

        await for (final _ in service.analyzeFrames(frames, settings)) {
          progressCount++;
          if (progressCount == 1) {
            service.cancelAnalysis();
          }
        }

        expect(
          progressCount,
          lessThan(3),
          reason: 'Cancellation should prevent all frames from being '
              'processed',
        );
        expect(
          service.isRunning,
          isFalse,
          reason: 'Service should not be running after cancellation',
        );
      });
    });
  });
}
