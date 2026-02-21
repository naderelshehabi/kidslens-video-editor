import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:kidslens_video_editor/data/models/visual_content_category.dart';
import 'package:kidslens_video_editor/native/bindings/onnx_bindings.dart';
import 'package:kidslens_video_editor/services/model_manager_service.dart';
import 'package:kidslens_video_editor/services/nudenet_service.dart';

// ---------------------------------------------------------------------------
// Mock implementations (no mockito)
// ---------------------------------------------------------------------------

/// Mock ONNXBindings that records calls and returns configurable results.
class MockONNXBindings extends ONNXBindings {
  bool initializeCalled = false;
  int runDetectionInferenceCallCount = 0;

  /// The result that [runDetectionInference] will return.
  DetectionResult nextDetectionResult =
      const DetectionResult(boxes: []);

  /// If non-null, [runDetectionInference] will throw this instead.
  Object? detectionError;

  /// Captured arguments from the most recent [runDetectionInference] call.
  String? lastModelPath;
  List<int>? lastRgbData;
  int? lastWidth;
  int? lastHeight;
  List<String>? lastClassNames;
  double? lastConfidenceThreshold;
  double? lastIouThreshold;
  int? lastInputSize;

  @override
  Future<void> initialize({List<String>? executionProviders}) async {
    initializeCalled = true;
  }

  @override
  Future<DetectionResult> runDetectionInference(
    String modelPath,
    List<int> rgbData,
    int width,
    int height, {
    required List<String> classNames,
    double confidenceThreshold = 0.25,
    double iouThreshold = 0.45,
    int inputSize = 640,
    int maxDetections = 30,
  }) async {
    runDetectionInferenceCallCount++;
    lastModelPath = modelPath;
    lastRgbData = rgbData;
    lastWidth = width;
    lastHeight = height;
    lastClassNames = classNames;
    lastConfidenceThreshold = confidenceThreshold;
    lastIouThreshold = iouThreshold;
    lastInputSize = inputSize;

    if (detectionError != null) {
      throw detectionError!;
    }
    return nextDetectionResult;
  }

  @override
  void releaseNative() {
    // no-op for tests
  }
}

/// Mock ModelManagerService that returns a configurable model path.
class MockModelManagerService extends ModelManagerService {
  MockModelManagerService() : super(customModelsPath: '.');

  String? nextModelPath = '/fake/models/nudenet.onnx';

  @override
  Future<String?> getModelPath(String modelId) async => nextModelPath;
}

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

/// Create a small valid RGB buffer of the given dimensions.
Uint8List _makeRgb(int width, int height) =>
    Uint8List(width * height * 3);

/// Build a [VisualContentCategory] for testing.
VisualContentCategory _category({
  required String id,
  required List<String> detectionLabels,
  CategoryDetectionSource detectionSource = CategoryDetectionSource.nudeNet,
  bool enabled = true,
}) =>
    VisualContentCategory(
      id: id,
      name: id,
      description: 'test category $id',
      detectionLabels: detectionLabels,
      detectionSource: detectionSource,
      enabled: enabled,
    );

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  // ========================================================================
  // NudeNetLabels constants
  // ========================================================================
  group('NudeNetLabels', () {
    test('classNames contains exactly 18 entries', () {
      expect(NudeNetLabels.classNames.length, 18);
    });

    test('exposedLabels is a subset of classNames', () {
      for (final label in NudeNetLabels.exposedLabels) {
        expect(NudeNetLabels.classNames, contains(label));
      }
    });

    test('coveredLabels is a subset of classNames', () {
      for (final label in NudeNetLabels.coveredLabels) {
        expect(NudeNetLabels.classNames, contains(label));
      }
    });

    test('nonSensitiveLabels is a subset of classNames', () {
      for (final label in NudeNetLabels.nonSensitiveLabels) {
        expect(NudeNetLabels.classNames, contains(label));
      }
    });

    test('exposed, covered, and nonSensitive sets do not overlap', () {
      final exposedCovered =
          NudeNetLabels.exposedLabels.intersection(NudeNetLabels.coveredLabels);
      final exposedNonSensitive = NudeNetLabels.exposedLabels
          .intersection(NudeNetLabels.nonSensitiveLabels);
      final coveredNonSensitive = NudeNetLabels.coveredLabels
          .intersection(NudeNetLabels.nonSensitiveLabels);

      expect(exposedCovered, isEmpty);
      expect(exposedNonSensitive, isEmpty);
      expect(coveredNonSensitive, isEmpty);
    });

    test('the three label sets together cover all 18 classNames', () {
      final allCategorized = <String>{
        ...NudeNetLabels.exposedLabels,
        ...NudeNetLabels.coveredLabels,
        ...NudeNetLabels.nonSensitiveLabels,
      };
      expect(allCategorized.length, 18);
      for (final name in NudeNetLabels.classNames) {
        expect(allCategorized, contains(name));
      }
    });
  });

  // ========================================================================
  // detectRegions
  // ========================================================================
  group('detectRegions', () {
    late MockONNXBindings mockOnnx;
    late MockModelManagerService mockModelManager;
    late NudeNetService service;

    setUp(() {
      mockOnnx = MockONNXBindings();
      mockModelManager = MockModelManagerService();
      service = NudeNetService(onnx: mockOnnx, modelManager: mockModelManager);
    });

    test('returns empty list when rgbData length does not match dimensions',
        () async {
      // 2x2 image expects 12 bytes; supply 5 instead
      final result = await service.detectRegions(
        modelPath: '/model.onnx',
        rgbData: Uint8List(5),
        width: 2,
        height: 2,
      );

      expect(result, isEmpty);
      // ONNX should never be called for invalid data
      expect(mockOnnx.runDetectionInferenceCallCount, 0);
    });

    test('returns detected regions from ONNX inference', () async {
      const box1 = DetectionBox(
        classId: 3,
        className: 'FEMALE_BREAST_EXPOSED',
        confidence: 0.85,
        x: 0.1,
        y: 0.2,
        width: 0.3,
        height: 0.4,
      );
      const box2 = DetectionBox(
        classId: 12,
        className: 'FACE_MALE',
        confidence: 0.70,
        x: 0.5,
        y: 0.5,
        width: 0.1,
        height: 0.1,
      );

      mockOnnx.nextDetectionResult =
          const DetectionResult(boxes: [box1, box2]);

      final regions = await service.detectRegions(
        modelPath: '/model.onnx',
        rgbData: _makeRgb(4, 4),
        width: 4,
        height: 4,
      );

      expect(regions.length, 2);
      expect(regions[0].label, 'FEMALE_BREAST_EXPOSED');
      expect(regions[0].confidence, 0.85);
      expect(regions[0].x, 0.1);
      expect(regions[0].y, 0.2);
      expect(regions[0].width, 0.3);
      expect(regions[0].height, 0.4);

      expect(regions[1].label, 'FACE_MALE');
      expect(regions[1].confidence, 0.70);
    });

    test('filters regions by category detection labels', () async {
      const box1 = DetectionBox(
        classId: 3,
        className: 'FEMALE_BREAST_EXPOSED',
        confidence: 0.90,
        x: 0.1,
        y: 0.1,
        width: 0.2,
        height: 0.2,
      );
      const box2 = DetectionBox(
        classId: 12,
        className: 'FACE_MALE',
        confidence: 0.80,
        x: 0.5,
        y: 0.5,
        width: 0.1,
        height: 0.1,
      );

      mockOnnx.nextDetectionResult =
          const DetectionResult(boxes: [box1, box2]);

      // Only ask for FEMALE_BREAST_EXPOSED via a category
      final categories = [
        _category(
          id: 'nudity',
          detectionLabels: ['FEMALE_BREAST_EXPOSED'],
        ),
      ];

      final regions = await service.detectRegions(
        modelPath: '/model.onnx',
        rgbData: _makeRgb(4, 4),
        width: 4,
        height: 4,
        categories: categories,
      );

      expect(regions.length, 1);
      expect(regions.first.label, 'FEMALE_BREAST_EXPOSED');
    });

    test('accepts all labels when no categories are provided', () async {
      const box = DetectionBox(
        classId: 12,
        className: 'FACE_MALE',
        confidence: 0.60,
        x: 0,
        y: 0,
        width: 0.5,
        height: 0.5,
      );

      mockOnnx.nextDetectionResult = const DetectionResult(boxes: [box]);

      final regions = await service.detectRegions(
        modelPath: '/model.onnx',
        rgbData: _makeRgb(2, 2),
        width: 2,
        height: 2,
        // categories intentionally omitted
      );

      expect(regions.length, 1);
      expect(regions.first.label, 'FACE_MALE');
    });

    test('returns empty list when ONNX throws an exception', () async {
      mockOnnx.detectionError = Exception('GPU out of memory');

      final regions = await service.detectRegions(
        modelPath: '/model.onnx',
        rgbData: _makeRgb(4, 4),
        width: 4,
        height: 4,
      );

      expect(regions, isEmpty);
    });

    test('passes correct parameters to ONNX inference', () async {
      mockOnnx.nextDetectionResult = const DetectionResult(boxes: []);

      await service.detectRegions(
        modelPath: '/my/model.onnx',
        rgbData: _makeRgb(8, 6),
        width: 8,
        height: 6,
        confidenceThreshold: 0.5,
        inputSize: 320,
      );

      expect(mockOnnx.lastModelPath, '/my/model.onnx');
      expect(mockOnnx.lastWidth, 8);
      expect(mockOnnx.lastHeight, 6);
      expect(mockOnnx.lastConfidenceThreshold, 0.5);
      expect(mockOnnx.lastIouThreshold, NudeNetService.defaultIouThreshold);
      expect(mockOnnx.lastInputSize, 320);
      expect(mockOnnx.lastClassNames, NudeNetLabels.classNames);
    });
  });

  // ========================================================================
  // _collectRelevantLabels (tested indirectly via detectRegions)
  // ========================================================================
  group('_collectRelevantLabels (indirect)', () {
    late MockONNXBindings mockOnnx;
    late MockModelManagerService mockModelManager;
    late NudeNetService service;

    setUp(() {
      mockOnnx = MockONNXBindings();
      mockModelManager = MockModelManagerService();
      service = NudeNetService(onnx: mockOnnx, modelManager: mockModelManager);
    });

    test('disabled categories are excluded from relevant labels', () async {
      const box = DetectionBox(
        classId: 3,
        className: 'FEMALE_BREAST_EXPOSED',
        confidence: 0.95,
        x: 0.1,
        y: 0.1,
        width: 0.2,
        height: 0.2,
      );

      mockOnnx.nextDetectionResult = const DetectionResult(boxes: [box]);

      // Category is disabled; its labels should not be collected,
      // resulting in null relevant labels (accept all).
      // But wait -- if the only category is disabled AND is the only one,
      // _collectRelevantLabels returns null, meaning all labels accepted.
      // So we add a second *enabled* category with different labels to
      // verify the disabled one's labels are truly excluded.
      final categories = [
        _category(
          id: 'nudity',
          detectionLabels: ['FEMALE_BREAST_EXPOSED'],
          enabled: false, // disabled
        ),
        _category(
          id: 'face',
          detectionLabels: ['FACE_MALE'],
        ),
      ];

      final regions = await service.detectRegions(
        modelPath: '/model.onnx',
        rgbData: _makeRgb(4, 4),
        width: 4,
        height: 4,
        categories: categories,
      );

      // FEMALE_BREAST_EXPOSED should be filtered out because the 'nudity'
      // category is disabled; only FACE_MALE labels are collected.
      expect(regions, isEmpty);
    });

    test('non-NudeNet categories are excluded from relevant labels', () async {
      const box = DetectionBox(
        classId: 3,
        className: 'FEMALE_BREAST_EXPOSED',
        confidence: 0.90,
        x: 0.1,
        y: 0.1,
        width: 0.2,
        height: 0.2,
      );

      mockOnnx.nextDetectionResult = const DetectionResult(boxes: [box]);

      // Category uses CLIP only, so its labels should not appear.
      final categories = [
        _category(
          id: 'clip-only',
          detectionLabels: ['FEMALE_BREAST_EXPOSED'],
          detectionSource: CategoryDetectionSource.clip,
        ),
        _category(
          id: 'face',
          detectionLabels: ['FACE_MALE'],
        ),
      ];

      final regions = await service.detectRegions(
        modelPath: '/model.onnx',
        rgbData: _makeRgb(4, 4),
        width: 4,
        height: 4,
        categories: categories,
      );

      // Only FACE_MALE is relevant; FEMALE_BREAST_EXPOSED comes from a
      // CLIP-only category and should be filtered out.
      expect(regions, isEmpty);
    });

    test('empty categories list results in null (accept all)', () async {
      const box = DetectionBox(
        classId: 7,
        className: 'FEET_EXPOSED',
        confidence: 0.55,
        x: 0,
        y: 0,
        width: 0.1,
        height: 0.1,
      );

      mockOnnx.nextDetectionResult = const DetectionResult(boxes: [box]);

      final regions = await service.detectRegions(
        modelPath: '/model.onnx',
        rgbData: _makeRgb(4, 4),
        width: 4,
        height: 4,
        categories: [], // empty list
      );

      // With empty categories, all labels are accepted.
      expect(regions.length, 1);
      expect(regions.first.label, 'FEET_EXPOSED');
    });

    test('categories with detectionSource "both" are included', () async {
      const box = DetectionBox(
        classId: 2,
        className: 'BUTTOCKS_EXPOSED',
        confidence: 0.75,
        x: 0.3,
        y: 0.3,
        width: 0.2,
        height: 0.2,
      );

      mockOnnx.nextDetectionResult = const DetectionResult(boxes: [box]);

      final categories = [
        _category(
          id: 'buttocks',
          detectionLabels: ['BUTTOCKS_EXPOSED'],
          detectionSource: CategoryDetectionSource.both,
        ),
      ];

      final regions = await service.detectRegions(
        modelPath: '/model.onnx',
        rgbData: _makeRgb(4, 4),
        width: 4,
        height: 4,
        categories: categories,
      );

      expect(regions.length, 1);
      expect(regions.first.label, 'BUTTOCKS_EXPOSED');
    });
  });

  // ========================================================================
  // getModelPath
  // ========================================================================
  group('getModelPath', () {
    late MockONNXBindings mockOnnx;
    late MockModelManagerService mockModelManager;
    late NudeNetService service;

    setUp(() {
      mockOnnx = MockONNXBindings();
      mockModelManager = MockModelManagerService();
      service = NudeNetService(onnx: mockOnnx, modelManager: mockModelManager);
    });

    test('delegates to modelManager with default model id', () async {
      mockModelManager.nextModelPath = '/models/nudenet-v3-medium.onnx';

      final path = await service.getModelPath();

      expect(path, '/models/nudenet-v3-medium.onnx');
    });

    test('delegates to modelManager with custom model id', () async {
      mockModelManager.nextModelPath = '/models/custom.onnx';

      final path = await service.getModelPath('custom-model');

      expect(path, '/models/custom.onnx');
    });

    test('returns null when modelManager returns null', () async {
      mockModelManager.nextModelPath = null;

      final path = await service.getModelPath();

      expect(path, isNull);
    });
  });

  // ========================================================================
  // initialize
  // ========================================================================
  group('initialize', () {
    late MockONNXBindings mockOnnx;
    late MockModelManagerService mockModelManager;
    late NudeNetService service;

    setUp(() {
      mockOnnx = MockONNXBindings();
      mockModelManager = MockModelManagerService();
      service = NudeNetService(onnx: mockOnnx, modelManager: mockModelManager);
    });

    test('calls onnx.initialize on first call', () async {
      await service.initialize();
      expect(mockOnnx.initializeCalled, isTrue);
    });

    test('does not call onnx.initialize on subsequent calls', () async {
      await service.initialize();
      mockOnnx.initializeCalled = false;

      await service.initialize();
      expect(mockOnnx.initializeCalled, isFalse);
    });
  });
}
