import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:kidslens_video_editor/data/models/visual_content_category.dart';
import 'package:kidslens_video_editor/native/bindings/onnx_bindings.dart';
import 'package:kidslens_video_editor/services/clip_service.dart';
import 'package:kidslens_video_editor/services/clip_tokenizer.dart';
import 'package:kidslens_video_editor/services/model_manager_service.dart';

// ---------------------------------------------------------------------------
// Mock classes
// ---------------------------------------------------------------------------

class MockONNXBindings extends ONNXBindings {
  /// The embedding vector returned by [runEmbeddingInference].
  List<double> embeddingResult = List<double>.filled(512, 0);

  @override
  Future<void> initialize({List<String>? executionProviders}) async {
    // no-op
  }

  @override
  Future<List<double>> runEmbeddingInference(
    String modelPath, {
    List<int>? rgbData,
    int? width,
    int? height,
    Int32List? tokenIds,
    bool isVisionModel = true,
  }) async =>
      List<double>.from(embeddingResult);

  @override
  void releaseNative() {
    // no-op
  }
}

class MockModelManagerService extends ModelManagerService {
  MockModelManagerService({required String tempDir}) : _tempDir = tempDir;

  final String _tempDir;

  /// Map from model ID to path (or null if not downloaded).
  final Map<String, String?> modelPaths = {};

  @override
  Future<String?> getModelPath(String modelId) async => modelPaths[modelId];

  @override
  Future<String> get modelsDirectory async => _tempDir;
}

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

/// Create a 512-dim vector that is zero everywhere except at [nonZeroIndex].
List<double> _makeUnitVector(int dim, int nonZeroIndex,
    [double value = 1.0,]) {
  final v = List<double>.filled(dim, 0);
  v[nonZeroIndex] = value;
  return v;
}

/// L2-normalise a vector.
List<double> _l2Normalize(List<double> v) {
  var norm = 0.0;
  for (final x in v) {
    norm += x * x;
  }
  norm = sqrt(norm);
  if (norm < 1e-12) return List<double>.from(v);
  return v.map((x) => x / norm).toList();
}

/// Dot product of two equal-length vectors.
double _dot(List<double> a, List<double> b) {
  var result = 0.0;
  for (var i = 0; i < a.length; i++) {
    result += a[i] * b[i];
  }
  return result;
}

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late MockONNXBindings mockOnnx;
  late MockModelManagerService mockModelManager;
  late ClipService clipService;
  late Directory tempDir;

  setUp(() async {
    tempDir = Directory.systemTemp.createTempSync('clip_service_test_');
    mockOnnx = MockONNXBindings();
    mockModelManager = MockModelManagerService(tempDir: tempDir.path);
    clipService = ClipService(onnx: mockOnnx, modelManager: mockModelManager);
    await clipService.initialize();
  });

  tearDown(() {
    clipService.dispose();
    if (tempDir.existsSync()) {
      tempDir.deleteSync(recursive: true);
    }
  });

  // =========================================================================
  // CategoryEmbeddings
  // =========================================================================
  group('CategoryEmbeddings', () {
    test('creation with positive and negative embeddings', () {
      final positive = [
        List<double>.filled(512, 0.1),
        List<double>.filled(512, 0.2),
      ];
      final negative = [
        List<double>.filled(512, 0.3),
      ];

      final ce = CategoryEmbeddings(
        positiveEmbeddings: positive,
        negativeEmbeddings: negative,
      );

      expect(ce.positiveEmbeddings, positive);
      expect(ce.negativeEmbeddings, negative);
      expect(ce.positiveEmbeddings.length, 2);
      expect(ce.negativeEmbeddings.length, 1);
    });
  });

  // =========================================================================
  // logitScale and embeddingDim constants
  // =========================================================================
  group('ClipService constants', () {
    test('logitScale is 100.0', () {
      expect(ClipService.logitScale, 100.0);
    });

    test('embeddingDim is 512', () {
      expect(ClipService.embeddingDim, 512);
    });
  });

  // =========================================================================
  // classifyFrame
  // =========================================================================
  group('classifyFrame', () {
    setUp(() {
      // Provide a vision model path so classifyFrame does not throw by default.
      mockModelManager.modelPaths['clip-vit-b32-vision-fp16'] =
          '${tempDir.path}/vision_model.onnx';
    });

    test('returns empty map for empty textEmbeddings', () async {
      final result = await clipService.classifyFrame(
        Uint8List(100),
        10,
        10,
        {},
      );
      expect(result, isEmpty);
    });

    test('throws when vision model not downloaded', () async {
      mockModelManager.modelPaths.remove('clip-vit-b32-vision-fp16');

      expect(
        () => clipService.classifyFrame(
          Uint8List(100),
          10,
          10,
          {
            'cat': CategoryEmbeddings(
              positiveEmbeddings: [List<double>.filled(512, 0.1)],
              negativeEmbeddings: [],
            ),
          },
        ),
        throwsA(isA<StateError>()),
      );
    });

    test('computes correct discriminative score', () async {
      const dim = 512;

      // Image embedding: unit vector along dimension 0 -> [1, 0, 0, ..., 0]
      final imageEmbedding = _makeUnitVector(dim, 0);
      mockOnnx.embeddingResult = imageEmbedding;

      // Positive embedding (pre-normalisation): [0.9, 0.436, 0, ..., 0]
      final posRaw = List<double>.filled(dim, 0);
      posRaw[0] = 0.9;
      posRaw[1] = 0.436;
      final posNorm = _l2Normalize(posRaw);

      // Negative embedding (pre-normalisation): [0.1, 0.995, 0, ..., 0]
      final negRaw = List<double>.filled(dim, 0);
      negRaw[0] = 0.1;
      negRaw[1] = 0.995;
      final negNorm = _l2Normalize(negRaw);

      final textEmbeddings = {
        'test_cat': CategoryEmbeddings(
          positiveEmbeddings: [posNorm],
          negativeEmbeddings: [negNorm],
        ),
      };

      final result = await clipService.classifyFrame(
        Uint8List(100),
        10,
        10,
        textEmbeddings,
      );

      // Expected computation:
      //   cosineSim(image, pos) = dot(image, posNorm)  (both L2-normalised)
      //   cosineSim(image, neg) = dot(image, negNorm)
      //   maxPositive = cosineSim(image, pos) * 100.0
      //   maxNegative = cosineSim(image, neg) * 100.0
      //   score = maxPositive - maxNegative
      final expectedMaxPositive =
          _dot(imageEmbedding, posNorm) * ClipService.logitScale;
      final expectedMaxNegative =
          _dot(imageEmbedding, negNorm) * ClipService.logitScale;
      final expectedScore = expectedMaxPositive - expectedMaxNegative;

      expect(result.containsKey('test_cat'), isTrue);
      expect(result['test_cat'], closeTo(expectedScore, 0.001));
      // Sanity: positive component is much larger, so score should be positive.
      expect(result['test_cat'], greaterThan(0));
    });

    test('handles no negative prompts (maxNegative should be 0)', () async {
      const dim = 512;
      final imageEmbedding = _makeUnitVector(dim, 0);
      mockOnnx.embeddingResult = imageEmbedding;

      final posRaw = List<double>.filled(dim, 0);
      posRaw[0] = 0.9;
      posRaw[1] = 0.436;
      final posNorm = _l2Normalize(posRaw);

      final textEmbeddings = {
        'test_cat': CategoryEmbeddings(
          positiveEmbeddings: [posNorm],
          negativeEmbeddings: [],
        ),
      };

      final result = await clipService.classifyFrame(
        Uint8List(100),
        10,
        10,
        textEmbeddings,
      );

      // maxNegative is 0.0 when there are no negative embeddings.
      final expectedMaxPositive =
          _dot(imageEmbedding, posNorm) * ClipService.logitScale;
      final expectedScore = expectedMaxPositive - 0.0;

      expect(result['test_cat'], closeTo(expectedScore, 0.001));
    });

    test('handles no positive prompts (score should be 0)', () async {
      const dim = 512;
      final imageEmbedding = _makeUnitVector(dim, 0);
      mockOnnx.embeddingResult = imageEmbedding;

      final negRaw = List<double>.filled(dim, 0);
      negRaw[0] = 0.1;
      negRaw[1] = 0.995;
      final negNorm = _l2Normalize(negRaw);

      final textEmbeddings = {
        'test_cat': CategoryEmbeddings(
          positiveEmbeddings: [],
          negativeEmbeddings: [negNorm],
        ),
      };

      final result = await clipService.classifyFrame(
        Uint8List(100),
        10,
        10,
        textEmbeddings,
      );

      // When there are no positive embeddings the service returns 0.0.
      expect(result['test_cat'], 0.0);
    });

    test('handles multiple categories', () async {
      const dim = 512;
      final imageEmbedding = _makeUnitVector(dim, 0);
      mockOnnx.embeddingResult = imageEmbedding;

      // Category A: has both positive and negative embeddings.
      final posA = _l2Normalize(
        List<double>.filled(dim, 0)..[0] = 0.9..[1] = 0.436,
      );
      final negA = _l2Normalize(
        List<double>.filled(dim, 0)..[0] = 0.1..[1] = 0.995,
      );

      // Category B: positive only.
      final posB = _l2Normalize(
        List<double>.filled(dim, 0)..[0] = 0.5..[1] = 0.866,
      );

      final textEmbeddings = {
        'cat_a': CategoryEmbeddings(
          positiveEmbeddings: [posA],
          negativeEmbeddings: [negA],
        ),
        'cat_b': CategoryEmbeddings(
          positiveEmbeddings: [posB],
          negativeEmbeddings: [],
        ),
      };

      final result = await clipService.classifyFrame(
        Uint8List(100),
        10,
        10,
        textEmbeddings,
      );

      expect(result.length, 2);
      expect(result.containsKey('cat_a'), isTrue);
      expect(result.containsKey('cat_b'), isTrue);

      // Category A: maxPositive - maxNegative
      final expectedA =
          _dot(imageEmbedding, posA) * ClipService.logitScale -
          _dot(imageEmbedding, negA) * ClipService.logitScale;
      expect(result['cat_a'], closeTo(expectedA, 0.001));

      // Category B: maxPositive - 0.0 (no negatives)
      final expectedB =
          _dot(imageEmbedding, posB) * ClipService.logitScale;
      expect(result['cat_b'], closeTo(expectedB, 0.001));
    });
  });

  // =========================================================================
  // precomputePromptEmbeddings
  // =========================================================================
  group('precomputePromptEmbeddings', () {
    setUp(() {
      mockModelManager.modelPaths['clip-vit-b32-text-fp16'] =
          '${tempDir.path}/text_model.onnx';
    });

    test('returns empty for no CLIP categories', () async {
      const nonClipCategory = VisualContentCategory(
        id: 'nudenet-only',
        name: 'NudeNet Only',
        description: 'Uses NudeNet detection source only',
        detectionSource: CategoryDetectionSource.nudeNet,
      );

      final result =
          await clipService.precomputePromptEmbeddings([nonClipCategory]);
      expect(result, isEmpty);
    });

    test('returns empty for empty category list', () async {
      final result = await clipService.precomputePromptEmbeddings([]);
      expect(result, isEmpty);
    });

    test('skips disabled categories', () async {
      const disabledCategory = VisualContentCategory(
        id: 'disabled-clip',
        name: 'Disabled CLIP',
        description: 'A disabled CLIP category',
        detectionSource: CategoryDetectionSource.clip,
        enabled: false,
        clipPrompts: ['two people kissing'],
      );

      final result =
          await clipService.precomputePromptEmbeddings([disabledCategory]);
      expect(result, isEmpty);
    });

    test('throws when text model not downloaded', () async {
      mockModelManager.modelPaths.remove('clip-vit-b32-text-fp16');

      const category = VisualContentCategory(
        id: 'test-clip',
        name: 'Test CLIP',
        description: 'Test category',
        detectionSource: CategoryDetectionSource.clip,
        clipPrompts: ['two people kissing'],
      );

      expect(
        () => clipService.precomputePromptEmbeddings([category]),
        throwsA(isA<StateError>()),
      );
    });
  });

  // =========================================================================
  // ClipBuiltInTokens
  // =========================================================================
  group('ClipBuiltInTokens', () {
    final allBuiltInPrompts = <String>[
      'explicit sexual act',
      'sexual intercourse',
      'people exercising',
      'wrestling match',
      'two people kissing',
      'romantic kiss on the lips',
      'two people talking face to face',
      'people hugging',
      'woman in revealing clothing',
      'woman wearing bikini',
      'person in underwear',
      'person wearing normal clothing',
      'person in business attire',
    ];

    test('getPreTokenized returns non-null for all built-in prompts', () {
      for (final prompt in allBuiltInPrompts) {
        final result = ClipBuiltInTokens.getPreTokenized(prompt);
        expect(result, isNotNull,
            reason: 'Expected non-null for built-in prompt "$prompt"',);
      }
    });

    test('getPreTokenized returns null for unknown prompt', () {
      final result =
          ClipBuiltInTokens.getPreTokenized('completely unknown prompt xyz');
      expect(result, isNull);
    });

    test('all built-in tokens start with 49406 (SOT) and have length 77', () {
      for (final prompt in allBuiltInPrompts) {
        final tokens = ClipBuiltInTokens.getPreTokenized(prompt)!;
        expect(tokens.length, 77,
            reason: 'Token list length should be 77 for "$prompt"',);
        expect(tokens[0], 49406,
            reason: 'First token should be SOT (49406) for "$prompt"',);
      }
    });
  });
}
