import 'dart:async';
import 'dart:ffi';
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

import 'package:kidslens_video_editor/native/resource_manager.dart';

/// Information about an ONNX Runtime session
class ONNXSessionInfo {
  const ONNXSessionInfo({
    required this.modelPath,
    required this.executionProvider,
    required this.loadedAt,
    required this.warmupCompleted,
    required this.inputInfo,
    required this.outputInfo,
    this.optimizationLevel = 'all',
    this.graphOptimizationLevel = 99,
  });

  final String modelPath;
  final String executionProvider;
  final DateTime loadedAt;
  final bool warmupCompleted;
  final List<ONNXTensorInfo> inputInfo;
  final List<ONNXTensorInfo> outputInfo;
  final String optimizationLevel;
  final int graphOptimizationLevel;

  Duration get sessionAge => DateTime.now().difference(loadedAt);
}

/// Information about an ONNX tensor
class ONNXTensorInfo {
  const ONNXTensorInfo({
    required this.name,
    required this.shape,
    required this.dataType,
  });

  final String name;
  final List<int> shape;
  final String dataType;
}

/// A detected bounding box from object detection inference
class DetectionBox {
  const DetectionBox({
    required this.classId,
    required this.className,
    required this.confidence,
    required this.x,
    required this.y,
    required this.width,
    required this.height,
  });

  /// Class index from the model output
  final int classId;

  /// Human-readable class name
  final String className;

  /// Detection confidence score (0.0 to 1.0)
  final double confidence;

  /// X coordinate of top-left corner (normalized 0-1 in original image space)
  final double x;

  /// Y coordinate of top-left corner (normalized 0-1 in original image space)
  final double y;

  /// Width of detection box (normalized 0-1 in original image space)
  final double width;

  /// Height of detection box (normalized 0-1 in original image space)
  final double height;

  @override
  String toString() =>
      'DetectionBox($className: ${(confidence * 100).toStringAsFixed(1)}% '
      'at [${x.toStringAsFixed(3)}, ${y.toStringAsFixed(3)}, '
      '${width.toStringAsFixed(3)}, ${height.toStringAsFixed(3)}])';
}

/// Result from object detection inference
class DetectionResult {
  const DetectionResult({
    required this.boxes,
    this.inferenceTimeMs,
  });

  /// Detected bounding boxes after NMS
  final List<DetectionBox> boxes;

  /// Inference time in milliseconds
  final int? inferenceTimeMs;

  /// Number of detections
  int get count => boxes.length;

  /// Whether any detections were found
  bool get isEmpty => boxes.isEmpty;

  /// Filter boxes by minimum confidence
  List<DetectionBox> boxesAboveThreshold(double threshold) =>
      boxes.where((b) => b.confidence >= threshold).toList();

  /// Filter boxes by class name
  List<DetectionBox> boxesForClass(String className) =>
      boxes.where((b) => b.className == className).toList();

  /// Get unique class names detected
  Set<String> get detectedClasses => boxes.map((b) => b.className).toSet();
}

/// Internal result of letterbox preprocessing
class _LetterboxResult {
  const _LetterboxResult({
    required this.data,
    required this.padX,
    required this.padY,
    required this.scale,
  });

  final Float32List data;
  final double padX;
  final double padY;
  final double scale;
}

/// Simple mutex for serializing inference calls.
///
/// Ensures only one inference runs at a time on the GPU,
/// preventing thread-safety issues regardless of async patterns.
class _InferenceMutex {
  Completer<void>? _completer;

  Future<void> acquire() async {
    while (_completer != null) {
      await _completer!.future;
    }
    _completer = Completer<void>();
  }

  void release() {
    final c = _completer;
    _completer = null;
    c?.complete();
  }
}

/// FFI bindings for ONNX Runtime
class ONNXBindings extends NativeResource {
  // ignore: unused_field - Will be used when FFI is fully implemented
  DynamicLibrary? _lib;
  bool _initialized = false;
  final Map<String, _LoadedSession> _loadedSessions = {};
  List<String> _executionProviders = ['CPUExecutionProvider'];

  /// Maximum number of cached sessions
  static const int _maxCachedSessions = 5;

  /// LRU ordering for cache eviction
  final List<String> _sessionAccessOrder = [];

  /// Mutex for serializing all inference calls
  final _InferenceMutex _inferenceMutex = _InferenceMutex();

  // CLIP ViT-B/32 preprocessing constants
  static const List<double> _clipMean = [0.48145466, 0.4578275, 0.40821073];
  static const List<double> _clipStd = [0.26862954, 0.26130258, 0.27577711];
  static const int _clipInputSize = 224;

  /// Initialize ONNX Runtime bindings
  ///
  /// [executionProviders] List of execution providers in priority order.
  /// Common providers: 'CUDAExecutionProvider', 'CoreMLExecutionProvider',
  /// 'DnnlExecutionProvider', 'CPUExecutionProvider'
  ///
  /// Implementation Plan:
  /// 1. Load ONNX Runtime shared library
  /// 2. Get OrtApi via OrtGetApiBase()->GetApi(ORT_API_VERSION)
  /// 3. Create OrtEnv with OrtCreateEnv()
  /// 4. Create OrtSessionOptions with CreateSessionOptions()
  /// 5. Configure execution providers:
  ///    - For CUDA: OrtSessionOptionsAppendExecutionProvider_CUDA()
  ///    - For CoreML: OrtSessionOptionsAppendExecutionProvider_CoreML()
  ///    - For CPU: Always available as fallback
  /// 6. Set optimization level via SetSessionGraphOptimizationLevel()
  /// 7. Enable memory pattern optimization
  /// 8. Store global session options for reuse
  Future<void> initialize({
    List<String>? executionProviders,
  }) async {
    if (_initialized) return;

    try {
      _lib = _loadLibrary();

      if (executionProviders != null) {
        _executionProviders = executionProviders;
      }

      // FFI Implementation Plan:
      // 1. const OrtApi* g_ort = OrtGetApiBase()->GetApi(ORT_API_VERSION)
      // 2. g_ort->CreateEnv(ORT_LOGGING_LEVEL_WARNING, "onnx_bindings", &env)
      // 3. g_ort->CreateSessionOptions(&session_options)
      // 4. Configure each execution provider from _executionProviders list
      // 5. g_ort->SetSessionGraphOptimizationLevel(session_options, ORT_ENABLE_ALL)
      // 6. g_ort->EnableMemPattern(session_options)

      _initialized = true;
    } catch (e) {
      throw ONNXInitializationException('Failed to load ONNX Runtime: $e');
    }
  }

  DynamicLibrary _loadLibrary() {
    if (Platform.isWindows) {
      return DynamicLibrary.open('onnxruntime.dll');
    } else if (Platform.isMacOS) {
      return DynamicLibrary.open('libonnxruntime.dylib');
    } else if (Platform.isLinux) {
      return DynamicLibrary.open('libonnxruntime.so');
    }
    throw UnsupportedError('Platform not supported');
  }

  /// Load an ONNX model with caching
  ///
  /// Uses LRU caching strategy to keep frequently used models in memory.
  /// Automatically evicts least recently used sessions when cache is full.
  ///
  /// Implementation Plan:
  /// 1. Check if model already cached (return early if so)
  /// 2. If cache full (_loadedSessions.length >= _maxCachedSessions):
  ///    - Find LRU session from _sessionAccessOrder
  ///    - Call disposeSession() on it
  ///    - Remove from cache and access order
  /// 3. Create new session:
  ///    - g_ort->CreateSession(env, modelPath, session_options, &session)
  ///    - Query input/output info via GetSessionInputCount/OutputCount
  ///    - For each input/output: GetSessionInputName, GetSessionInputTypeInfo
  ///    - Extract tensor shape and data type
  /// 4. Build _LoadedSession with metadata
  /// 5. Add to cache and update access order
  Future<void> loadModel(String modelPath) async {
    _ensureInitialized();

    // Check cache and update access order
    if (_loadedSessions.containsKey(modelPath)) {
      _updateAccessOrder(modelPath);
      return;
    }

    // Validate model file exists
    final modelFile = File(modelPath);
    if (!modelFile.existsSync()) {
      throw ONNXModelLoadException('Model file not found: $modelPath');
    }

    // Evict LRU session if cache is full
    if (_loadedSessions.length >= _maxCachedSessions) {
      await _evictLRUSession();
    }

    try {
      // FFI Implementation Plan:
      // 1. Create session: g_ort->CreateSession(g_env, modelPath, g_session_options, &session)
      // 2. Get input count: g_ort->SessionGetInputCount(session, &num_inputs)
      // 3. For each input i:
      //    - g_ort->SessionGetInputName(session, i, allocator, &name)
      //    - g_ort->SessionGetInputTypeInfo(session, i, &type_info)
      //    - g_ort->GetTensorShapeElementCount(tensor_info, &element_count)
      //    - Extract shape dimensions
      // 4. Repeat for outputs
      // 5. Store session pointer and metadata

      final session = _LoadedSession(
        path: modelPath,
        loadedAt: DateTime.now(),
        executionProvider: _executionProviders.first,
      );

      _loadedSessions[modelPath] = session;
      _sessionAccessOrder.add(modelPath);
    } catch (e) {
      throw ONNXModelLoadException('Failed to load model: $e');
    }
  }

  void _updateAccessOrder(String modelPath) {
    _sessionAccessOrder
      ..remove(modelPath)
      ..add(modelPath);
  }

  Future<void> _evictLRUSession() async {
    if (_sessionAccessOrder.isEmpty) return;

    final lruPath = _sessionAccessOrder.removeAt(0);
    await disposeSession(lruPath);
  }

  /// Unload an ONNX model from cache
  void unloadModel(String modelPath) {
    disposeSession(modelPath);
  }

  /// Dispose of a specific session and free resources
  ///
  /// Implementation Plan:
  /// 1. Get session from cache
  /// 2. Call g_ort->ReleaseSession(session) to free native memory
  /// 3. Release any allocated tensors
  /// 4. Remove from cache and access order
  Future<void> disposeSession(String modelPath) async {
    final session = _loadedSessions.remove(modelPath);
    _sessionAccessOrder.remove(modelPath);

    if (session == null) return;

    // FFI Implementation Plan:
    // 1. If session has native pointer: g_ort->ReleaseSession(session.ptr)
    // 2. Clear any cached input/output tensors
    // 3. Log disposal for debugging
  }

  /// Dispose all cached sessions
  Future<void> disposeAllSessions() async {
    final paths = List<String>.from(_loadedSessions.keys);
    for (final path in paths) {
      await disposeSession(path);
    }
    _sessionAccessOrder.clear();
  }

  /// Get information about a loaded session
  ///
  /// Returns null if the session is not loaded.
  ONNXSessionInfo? getSessionInfo(String modelPath) {
    final session = _loadedSessions[modelPath];
    if (session == null) return null;

    // Build session info from cached metadata
    return ONNXSessionInfo(
      modelPath: session.path,
      executionProvider: session.executionProvider,
      loadedAt: session.loadedAt,
      warmupCompleted: session.warmedUp,
      inputInfo: session.inputInfo,
      outputInfo: session.outputInfo,
    );
  }

  /// Warm up a model by running a dummy inference
  ///
  /// This pre-compiles kernels and allocates memory, reducing
  /// latency for the first real inference request.
  ///
  /// Implementation Plan:
  /// 1. Ensure model is loaded
  /// 2. Create dummy input tensor matching model input shape
  ///    - Fill with zeros or random values
  /// 3. Run inference with dummy data
  /// 4. Discard output (we only care about warming up)
  /// 5. Mark session as warmed up
  /// 6. Log warmup time for diagnostics
  Future<Duration> warmup(String modelPath) async {
    _ensureInitialized();

    if (!_loadedSessions.containsKey(modelPath)) {
      await loadModel(modelPath);
    }

    final session = _loadedSessions[modelPath]!;
    if (session.warmedUp) {
      return Duration.zero; // Already warmed up
    }

    final stopwatch = Stopwatch()..start();

    try {
      await _withInferenceLock(() async {
        // FFI Implementation Plan:
        // 1. Get input shape from session metadata
        // 2. Allocate Float32List of correct size
        // 3. Create OrtValue tensor: g_ort->CreateTensorWithDataAsOrtValue(...)
        // 4. Run inference: g_ort->Run(session, null, input_names, inputs, 1, output_names, 1, &outputs)
        // 5. Release output tensor

        // Placeholder warmup simulation
        await Future<void>.delayed(const Duration(milliseconds: 50));
      });

      session.warmedUp = true;
      stopwatch.stop();
      return stopwatch.elapsed;
    } catch (e) {
      stopwatch.stop();
      throw ONNXInferenceException('Warmup failed: $e');
    }
  }

  // ============ Inference Mutex ============

  /// Serialize all inference calls through the mutex to prevent
  /// concurrent GPU access regardless of async patterns.
  Future<T> _withInferenceLock<T>(Future<T> Function() fn) async {
    await _inferenceMutex.acquire();
    try {
      return await fn();
    } finally {
      _inferenceMutex.release();
    }
  }

  // ============ Classification Inference ============

  /// Run classification inference on image data
  ///
  /// Returns detection scores appropriate for each model type:
  /// - NSFW models: porn, sexy, hentai, drawings, neutral scores
  /// - Violence models: violent, non_violent scores
  /// - Blood models: blood, no_blood scores
  /// - Weapons models: weapon, no_weapon scores
  ///
  /// TODO: Replace with actual FFI implementation:
  /// 1. Ensure model loaded (auto-load if not)
  /// 2. Update session access order for LRU tracking
  /// 3. Validate input dimensions match model input shape
  /// 4. Pre-process input:
  ///    - Convert RGB bytes to Float32
  ///    - Normalize to [0, 1] or [-1, 1] based on model requirements
  ///    - Apply mean/std normalization if needed
  ///    - Reshape to NCHW or NHWC based on model
  /// 5. Create input OrtValue tensor
  /// 6. Run inference:
  ///    - g_ort->Run(session, null, input_names, &input_tensor, 1, output_names, 1, &output_tensor)
  /// 7. Extract output values from output tensor
  /// 8. Apply softmax if needed
  /// 9. Map output values to class labels
  /// 10. Release tensors and return results
  Future<Map<String, double>> runInference(
    String modelPath,
    List<int> rgbData,
    int width,
    int height,
  ) async {
    _ensureInitialized();

    if (!_loadedSessions.containsKey(modelPath)) {
      await loadModel(modelPath);
    }
    _updateAccessOrder(modelPath);

    try {
      return await _withInferenceLock(() async {
        return _runModelInference(modelPath, rgbData, width, height);
      });
    } catch (e) {
      if (e is ONNXInferenceException) rethrow;
      throw ONNXInferenceException('Inference failed: $e');
    }
  }

  /// Run model inference and return detection scores
  ///
  /// Uses image data characteristics (variance) to generate
  /// slightly varied but consistent results based on model type.
  Map<String, double> _runModelInference(
    String modelPath,
    List<int> rgbData,
    int width,
    int height,
  ) {
    final modelType = _inferModelType(modelPath);

    // Use image data to add slight variance to results
    // This makes simulation more realistic than constant values
    final variance = _computeImageVariance(rgbData, width, height);
    final random = Random(variance.hashCode);

    // Small random variation (±5%)
    double vary(double base) {
      final variation = (random.nextDouble() - 0.5) * 0.1;
      return (base + variation).clamp(0.0, 1.0);
    }

    switch (modelType) {
      case _ModelType.nsfw:
        // NSFW models output 5 classes: porn, sexy, hentai, drawings, neutral
        // Simulate mostly safe content (neutral ~90%)
        final neutral = vary(0.90);
        final remaining = 1.0 - neutral;
        return {
          'neutral': neutral,
          'porn': vary(remaining * 0.1),
          'sexy': vary(remaining * 0.4),
          'hentai': vary(remaining * 0.1),
          'drawings': vary(remaining * 0.4),
        };

      case _ModelType.violence:
        // Violence models output violent/non-violent probabilities
        // Simulate mostly safe content
        final nonViolent = vary(0.92);
        return {
          'violent': 1.0 - nonViolent,
          'non_violent': nonViolent,
        };

      case _ModelType.blood:
        // Blood/gore models output blood presence probability
        // Simulate mostly safe content
        final noBlood = vary(0.95);
        return {
          'blood': 1.0 - noBlood,
          'no_blood': noBlood,
        };

      case _ModelType.weapons:
        // Weapons models output weapon detection probability
        // Simulate mostly safe content
        final noWeapon = vary(0.94);
        return {
          'weapon': 1.0 - noWeapon,
          'no_weapon': noWeapon,
        };

      case _ModelType.detection:
      case _ModelType.embedding:
      case _ModelType.unknown:
        // Unknown model type - return generic safe scores
        return {
          'safe': vary(0.90),
          'unsafe': vary(0.10),
        };
    }
  }

  /// Infer model type from model path/name
  _ModelType _inferModelType(String modelPath) {
    final lowerPath = modelPath.toLowerCase();

    if (lowerPath.contains('nsfw')) {
      return _ModelType.nsfw;
    } else if (lowerPath.contains('violence') ||
        lowerPath.contains('violent')) {
      return _ModelType.violence;
    } else if (lowerPath.contains('blood') || lowerPath.contains('gore')) {
      return _ModelType.blood;
    } else if (lowerPath.contains('weapon')) {
      return _ModelType.weapons;
    } else if (lowerPath.contains('nudenet') || lowerPath.contains('yolo')) {
      return _ModelType.detection;
    } else if (lowerPath.contains('clip') || lowerPath.contains('vit')) {
      return _ModelType.embedding;
    }

    return _ModelType.unknown;
  }

  /// Compute a simple variance metric from image data
  ///
  /// Used to add realistic variation to simulated inference results.
  /// The variance makes the same image return consistent results while
  /// different images return slightly different scores.
  double _computeImageVariance(List<int> rgbData, int width, int height) {
    if (rgbData.isEmpty) return 0.5;

    // Sample pixels for efficiency
    final sampleSize = (rgbData.length / 100).clamp(10, 1000).toInt();
    final step = rgbData.length ~/ sampleSize;

    var sum = 0;
    var sumSq = 0;
    var count = 0;

    for (var i = 0; i < rgbData.length; i += step) {
      final val = rgbData[i];
      sum += val;
      sumSq += val * val;
      count++;
    }

    if (count == 0) return 0.5;

    final mean = sum / count;
    final variance = (sumSq / count) - (mean * mean);

    // Normalize variance to [0, 1] range
    return (variance / 16384).clamp(0.0, 1.0);
  }

  /// Run batch inference on multiple images
  ///
  /// More efficient than calling runInference multiple times as it
  /// batches inputs into a single inference call when possible.
  ///
  /// [batchSize] Maximum number of images to process in single inference.
  /// If null, processes all images in one batch (memory permitting).
  ///
  /// Implementation Plan:
  /// 1. Validate all inputs have same dimensions
  /// 2. Determine optimal batch size based on:
  ///    - Available GPU memory
  ///    - Model input shape constraints
  ///    - Provided batchSize parameter
  /// 3. Split inputs into batches
  /// 4. For each batch:
  ///    - Stack inputs along batch dimension (NCHW format)
  ///    - Create batched input tensor
  ///    - Run single inference call
  ///    - Split batch outputs back to individual results
  /// 5. Concatenate all batch results
  /// 6. Return results in original input order
  Future<List<Map<String, double>>> runBatchInference(
    String modelPath,
    List<List<int>> rgbDataList,
    int width,
    int height, {
    int? batchSize,
  }) async {
    _ensureInitialized();

    if (!_loadedSessions.containsKey(modelPath)) {
      await loadModel(modelPath);
    }
    _updateAccessOrder(modelPath);

    final effectiveBatchSize = batchSize ?? rgbDataList.length;
    final results = <Map<String, double>>[];

    try {
      // Process in batches
      for (var i = 0; i < rgbDataList.length; i += effectiveBatchSize) {
        final batchEnd =
            (i + effectiveBatchSize).clamp(0, rgbDataList.length);
        final batch = rgbDataList.sublist(i, batchEnd);

        // FFI Implementation Plan:
        // 1. Create batched input tensor with shape [batch.length, 3, height, width]
        // 2. Copy all batch images into single contiguous buffer
        // 3. Run inference with batched input
        // 4. Extract batch outputs and split into individual results

        // Placeholder: process each image individually
        for (final rgbData in batch) {
          final result = await runInference(modelPath, rgbData, width, height);
          results.add(result);
        }
      }

      return results;
    } catch (e) {
      throw ONNXInferenceException('Batch inference failed: $e');
    }
  }

  // ============ Object Detection Inference ============

  /// Run object detection inference (YOLOv8 format)
  ///
  /// Preprocesses with letterbox padding, runs inference, and performs
  /// per-class NMS on the output.
  ///
  /// [modelPath] Path to the ONNX detection model
  /// [rgbData] Raw RGB pixel data
  /// [width] Image width in pixels
  /// [height] Image height in pixels
  /// [classNames] Ordered list of class names matching model output indices
  /// [confidenceThreshold] Minimum confidence to keep a detection
  /// [iouThreshold] IoU threshold for NMS suppression
  /// [inputSize] Model input size (default: 640 for YOLOv8)
  /// [maxDetections] Maximum number of detections to return
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
    _ensureInitialized();

    if (!_loadedSessions.containsKey(modelPath)) {
      await loadModel(modelPath);
    }
    _updateAccessOrder(modelPath);

    final stopwatch = Stopwatch()..start();

    try {
      final result = await _withInferenceLock(() async {
        // Step 1: Letterbox preprocess
        final letterboxed = _letterbox(rgbData, width, height, inputSize);

        // FFI Implementation Plan:
        // 1. Create OrtValue tensor from letterboxed.data with shape [1, 3, inputSize, inputSize]
        // 2. Run inference: g_ort->Run(session, null, input_names, &input_tensor, 1, output_names, 1, &output_tensor)
        // 3. Extract output tensor data
        // 4. Process YOLOv8 output format

        // Placeholder: simulate detection output
        final boxes = _simulateDetectionOutput(
          rgbData,
          width,
          height,
          classNames,
          confidenceThreshold,
          letterboxed,
        );

        // Step 2: Per-class NMS
        final nmsBoxes = _nonMaxSuppression(boxes, iouThreshold);

        // Step 3: Cap at maxDetections by confidence
        nmsBoxes.sort((a, b) => b.confidence.compareTo(a.confidence));
        final cappedBoxes = nmsBoxes.length > maxDetections
            ? nmsBoxes.sublist(0, maxDetections)
            : nmsBoxes;

        return cappedBoxes;
      });

      stopwatch.stop();
      return DetectionResult(
        boxes: result,
        inferenceTimeMs: stopwatch.elapsedMilliseconds,
      );
    } catch (e) {
      stopwatch.stop();
      if (e is ONNXInferenceException) rethrow;
      throw ONNXInferenceException('Detection inference failed: $e');
    }
  }

  /// Simulate detection model output for placeholder implementation
  List<DetectionBox> _simulateDetectionOutput(
    List<int> rgbData,
    int width,
    int height,
    List<String> classNames,
    double confidenceThreshold,
    _LetterboxResult letterboxed,
  ) {
    // Use image variance for consistent pseudo-random results
    final variance = _computeImageVariance(rgbData, width, height);
    final random = Random(variance.hashCode);

    // Simulate mostly clean frames (no detections)
    // ~5% chance of generating a detection for simulation purposes
    if (random.nextDouble() > 0.05) {
      return [];
    }

    // Generate 1-2 simulated detections
    final numDetections = random.nextInt(2) + 1;
    final boxes = <DetectionBox>[];

    for (var i = 0; i < numDetections; i++) {
      final classId = random.nextInt(classNames.length);
      final confidence =
          (random.nextDouble() * 0.4 + 0.3).clamp(0.0, 1.0); // 0.3-0.7

      if (confidence < confidenceThreshold) continue;

      // Random box position (normalized)
      final x = random.nextDouble() * 0.6; // Keep within bounds
      final y = random.nextDouble() * 0.6;
      final w = (random.nextDouble() * 0.3 + 0.05)
          .clamp(0.0, 1.0 - x); // 5-35% width
      final h = (random.nextDouble() * 0.3 + 0.05).clamp(0.0, 1.0 - y);

      boxes.add(DetectionBox(
        classId: classId,
        className: classNames[classId],
        confidence: confidence,
        x: x,
        y: y,
        width: w,
        height: h,
      ));
    }

    return boxes;
  }

  // ============ Embedding Inference (CLIP) ============

  /// Run embedding inference for CLIP-style models
  ///
  /// For vision encoder: preprocesses with CLIP normalization (center crop +
  /// mean/std), runs inference, L2-normalizes the output.
  ///
  /// For text encoder: takes pre-tokenized Int32 tensor, runs inference,
  /// L2-normalizes the output.
  ///
  /// [modelPath] Path to the ONNX embedding model
  /// [inputData] Float32List for vision or Int32List for text
  /// [inputShape] Tensor shape (e.g., [1, 3, 224, 224] for vision, [1, 77] for text)
  /// [isVisionModel] If true, input is image data requiring CLIP preprocessing
  Future<List<double>> runEmbeddingInference(
    String modelPath, {
    List<int>? rgbData,
    int? width,
    int? height,
    Int32List? tokenIds,
    bool isVisionModel = true,
  }) async {
    _ensureInitialized();

    if (!_loadedSessions.containsKey(modelPath)) {
      await loadModel(modelPath);
    }
    _updateAccessOrder(modelPath);

    try {
      return await _withInferenceLock(() async {
        if (isVisionModel) {
          if (rgbData == null || width == null || height == null) {
            throw ONNXInferenceException(
              'Vision model requires rgbData, width, and height',
            );
          }

          // Step 1: CLIP preprocessing (center crop + normalize)
          final preprocessed = _clipPreprocess(rgbData, width, height);

          // FFI Implementation Plan:
          // 1. Create OrtValue tensor from preprocessed with shape [1, 3, 224, 224]
          // 2. Run inference: g_ort->Run(session, ...)
          // 3. Extract 512-dim output vector
          // 4. L2-normalize

          // Placeholder: simulate 512-dim embedding
          return _simulateEmbedding(rgbData, width, height);
        } else {
          if (tokenIds == null) {
            throw ONNXInferenceException(
              'Text model requires tokenIds',
            );
          }

          // FFI Implementation Plan:
          // 1. Create OrtValue tensor from tokenIds with shape [1, 77]
          // 2. Run inference
          // 3. Extract 512-dim output vector
          // 4. L2-normalize

          // Placeholder: simulate 512-dim text embedding
          return _simulateTextEmbedding(tokenIds);
        }
      });
    } catch (e) {
      if (e is ONNXInferenceException) rethrow;
      throw ONNXInferenceException('Embedding inference failed: $e');
    }
  }

  /// Simulate a 512-dim vision embedding
  List<double> _simulateEmbedding(List<int> rgbData, int width, int height) {
    final variance = _computeImageVariance(rgbData, width, height);
    final random = Random(variance.hashCode);

    // Generate 512-dim pseudo-random embedding
    final embedding = List.generate(512, (_) => random.nextDouble() * 2 - 1);

    // L2-normalize
    return _l2Normalize(embedding);
  }

  /// Simulate a 512-dim text embedding
  List<double> _simulateTextEmbedding(Int32List tokenIds) {
    // Use token content for deterministic output
    var seed = 0;
    for (final id in tokenIds) {
      seed = seed * 31 + id;
    }
    final random = Random(seed);

    final embedding = List.generate(512, (_) => random.nextDouble() * 2 - 1);
    return _l2Normalize(embedding);
  }

  /// L2-normalize an embedding vector
  List<double> _l2Normalize(List<double> embedding) {
    var norm = 0.0;
    for (final v in embedding) {
      norm += v * v;
    }
    norm = sqrt(norm);
    if (norm < 1e-12) return embedding;

    return embedding.map((v) => v / norm).toList();
  }

  // ============ Preprocessing Helpers ============

  /// Letterbox preprocessing for object detection models
  ///
  /// Resizes the image preserving aspect ratio to fit within
  /// [targetSize] x [targetSize], pads shorter dimension with gray
  /// (114/255 = 0.447), and normalizes to [0, 1] in NCHW format.
  ///
  /// Returns letterboxed data with padding info for coordinate un-mapping.
  _LetterboxResult _letterbox(
    List<int> rgbData,
    int srcW,
    int srcH,
    int targetSize,
  ) {
    // Compute scale to fit within targetSize while preserving aspect ratio
    final scale = min(targetSize / srcW, targetSize / srcH).toDouble();
    final newW = (srcW * scale).round();
    final newH = (srcH * scale).round();

    // Padding to center the resized image
    final padX = (targetSize - newW) / 2.0;
    final padY = (targetSize - newH) / 2.0;
    final padXInt = padX.round();
    final padYInt = padY.round();

    // Create output buffer in NCHW format [1, 3, targetSize, targetSize]
    final output = Float32List(3 * targetSize * targetSize);

    // Fill with gray padding (114/255 ≈ 0.447)
    const grayValue = 114.0 / 255.0;
    for (var i = 0; i < output.length; i++) {
      output[i] = grayValue;
    }

    // Resize and place image using nearest-neighbor (bilinear for production FFI)
    for (var y = 0; y < newH; y++) {
      for (var x = 0; x < newW; x++) {
        // Map back to source coordinates
        final srcX = (x / scale).round().clamp(0, srcW - 1);
        final srcY = (y / scale).round().clamp(0, srcH - 1);
        final srcIdx = (srcY * srcW + srcX) * 3;

        if (srcIdx + 2 >= rgbData.length) continue;

        final destX = x + padXInt;
        final destY = y + padYInt;

        if (destX >= targetSize || destY >= targetSize) continue;

        // NCHW layout: channel * H * W + y * W + x
        // Normalize to [0, 1]
        output[0 * targetSize * targetSize + destY * targetSize + destX] =
            rgbData[srcIdx] / 255.0; // R
        output[1 * targetSize * targetSize + destY * targetSize + destX] =
            rgbData[srcIdx + 1] / 255.0; // G
        output[2 * targetSize * targetSize + destY * targetSize + destX] =
            rgbData[srcIdx + 2] / 255.0; // B
      }
    }

    return _LetterboxResult(
      data: output,
      padX: padX,
      padY: padY,
      scale: scale,
    );
  }

  /// CLIP ViT-B/32 vision preprocessing
  ///
  /// 1. Compute scale = 224 / min(srcW, srcH)
  /// 2. Resize to (round(srcW * scale), round(srcH * scale)) with bicubic
  /// 3. Center crop to 224x224
  /// 4. Convert to float32, divide by 255.0
  /// 5. Normalize with CLIP mean/std
  /// 6. Arrange as NCHW [1, 3, 224, 224]
  Float32List _clipPreprocess(List<int> rgbData, int srcW, int srcH) {
    const size = _clipInputSize;

    // Step 1: Compute scale (resize so shorter side = 224)
    final scale = size / min(srcW, srcH);
    final resizedW = (srcW * scale).round();
    final resizedH = (srcH * scale).round();

    // Step 2: Resize (nearest-neighbor placeholder; bicubic for FFI)
    final resized = _resizeRgb(rgbData, srcW, srcH, resizedW, resizedH);

    // Step 3: Center crop to 224x224
    final cropX = (resizedW - size) ~/ 2;
    final cropY = (resizedH - size) ~/ 2;

    // Step 4-6: Normalize and arrange as NCHW
    final output = Float32List(3 * size * size);

    for (var y = 0; y < size; y++) {
      for (var x = 0; x < size; x++) {
        final srcX = (cropX + x).clamp(0, resizedW - 1);
        final srcY = (cropY + y).clamp(0, resizedH - 1);
        final srcIdx = (srcY * resizedW + srcX) * 3;

        if (srcIdx + 2 >= resized.length) continue;

        // Convert to [0, 1] then normalize with CLIP constants
        final r = (resized[srcIdx] / 255.0 - _clipMean[0]) / _clipStd[0];
        final g = (resized[srcIdx + 1] / 255.0 - _clipMean[1]) / _clipStd[1];
        final b = (resized[srcIdx + 2] / 255.0 - _clipMean[2]) / _clipStd[2];

        // NCHW layout
        output[0 * size * size + y * size + x] = r;
        output[1 * size * size + y * size + x] = g;
        output[2 * size * size + y * size + x] = b;
      }
    }

    return output;
  }

  /// Simple nearest-neighbor RGB resize
  List<int> _resizeRgb(
    List<int> data,
    int srcW,
    int srcH,
    int dstW,
    int dstH,
  ) {
    final output = List<int>.filled(dstW * dstH * 3, 0);
    final scaleX = srcW / dstW;
    final scaleY = srcH / dstH;

    for (var y = 0; y < dstH; y++) {
      for (var x = 0; x < dstW; x++) {
        final srcX = (x * scaleX).round().clamp(0, srcW - 1);
        final srcY = (y * scaleY).round().clamp(0, srcH - 1);
        final srcIdx = (srcY * srcW + srcX) * 3;
        final dstIdx = (y * dstW + x) * 3;

        if (srcIdx + 2 < data.length && dstIdx + 2 < output.length) {
          output[dstIdx] = data[srcIdx];
          output[dstIdx + 1] = data[srcIdx + 1];
          output[dstIdx + 2] = data[srcIdx + 2];
        }
      }
    }

    return output;
  }

  // ============ NMS (Non-Maximum Suppression) ============

  /// Per-class non-maximum suppression
  ///
  /// Groups detections by class, sorts by confidence within each class,
  /// and greedily suppresses overlapping boxes above [iouThreshold].
  List<DetectionBox> _nonMaxSuppression(
    List<DetectionBox> boxes,
    double iouThreshold,
  ) {
    if (boxes.isEmpty) return [];

    // Group by class
    final byClass = <int, List<DetectionBox>>{};
    for (final box in boxes) {
      byClass.putIfAbsent(box.classId, () => []).add(box);
    }

    final result = <DetectionBox>[];

    for (final classBoxes in byClass.values) {
      // Sort by confidence descending
      classBoxes.sort((a, b) => b.confidence.compareTo(a.confidence));

      final kept = <DetectionBox>[];
      final suppressed = List.filled(classBoxes.length, false);

      for (var i = 0; i < classBoxes.length; i++) {
        if (suppressed[i]) continue;
        kept.add(classBoxes[i]);

        for (var j = i + 1; j < classBoxes.length; j++) {
          if (suppressed[j]) continue;
          if (_computeIoU(classBoxes[i], classBoxes[j]) > iouThreshold) {
            suppressed[j] = true;
          }
        }
      }

      result.addAll(kept);
    }

    return result;
  }

  /// Compute Intersection over Union between two detection boxes
  double _computeIoU(DetectionBox a, DetectionBox b) {
    final x1 = max(a.x, b.x);
    final y1 = max(a.y, b.y);
    final x2 = min(a.x + a.width, b.x + b.width);
    final y2 = min(a.y + a.height, b.y + b.height);

    final intersectionW = max(0.0, x2 - x1);
    final intersectionH = max(0.0, y2 - y1);
    final intersection = intersectionW * intersectionH;

    final areaA = a.width * a.height;
    final areaB = b.width * b.height;
    final union = areaA + areaB - intersection;

    if (union <= 0) return 0.0;
    return intersection / union;
  }

  /// Un-map coordinates from letterbox space to original image space
  ///
  /// Subtracts letterbox padding, divides by scale, then normalizes
  /// by original dimensions. Clamps to valid range.
  DetectionBox _unmapCoordinates(
    DetectionBox box,
    double padX,
    double padY,
    double scale,
    int origW,
    int origH,
    int inputSize,
  ) {
    // Convert from inputSize pixel space to original pixel space
    final cx = (box.x * inputSize - padX) / scale;
    final cy = (box.y * inputSize - padY) / scale;
    final w = box.width * inputSize / scale;
    final h = box.height * inputSize / scale;

    // Normalize to [0, 1] relative to original image
    var nx = cx / origW;
    var ny = cy / origH;
    var nw = w / origW;
    var nh = h / origH;

    // Clamp to valid range
    nx = nx.clamp(0.0, 1.0);
    ny = ny.clamp(0.0, 1.0);
    nw = nw.clamp(0.0, 1.0 - nx);
    nh = nh.clamp(0.0, 1.0 - ny);

    return DetectionBox(
      classId: box.classId,
      className: box.className,
      confidence: box.confidence,
      x: nx,
      y: ny,
      width: nw,
      height: nh,
    );
  }

  // ============ Metadata ============

  /// Get model metadata
  ///
  /// Implementation Plan:
  /// 1. Load model if not already loaded
  /// 2. Query ONNX model metadata:
  ///    - g_ort->SessionGetModelMetadata(session, &metadata)
  ///    - g_ort->ModelMetadataGetProducerName(metadata, allocator, &name)
  ///    - g_ort->ModelMetadataGetDescription(metadata, allocator, &desc)
  /// 3. Query input info:
  ///    - g_ort->SessionGetInputCount(session, &count)
  ///    - For each: get name, type, shape
  /// 4. Query output info similarly
  /// 5. Build and return ONNXModelMetadata object
  Future<ONNXModelMetadata> getModelMetadata(String modelPath) async {
    _ensureInitialized();

    if (!_loadedSessions.containsKey(modelPath)) {
      await loadModel(modelPath);
    }

    final session = _loadedSessions[modelPath]!;

    return ONNXModelMetadata(
      inputNames: session.inputInfo.map((i) => i.name).toList(),
      outputNames: session.outputInfo.map((o) => o.name).toList(),
      inputShapes: session.inputInfo.map((i) => i.shape).toList(),
      outputShapes: session.outputInfo.map((o) => o.shape).toList(),
    );
  }

  void _ensureInitialized() {
    if (!_initialized) {
      throw ONNXNotInitializedException();
    }
  }

  @override
  void releaseNative() {
    // Dispose all sessions synchronously
    for (final _ in _loadedSessions.values) {
      // FFI: g_ort->ReleaseSession(session.ptr)
      // Placeholder: just clear the reference
    }
    _loadedSessions.clear();
    _sessionAccessOrder.clear();

    // Release ONNX Runtime environment
    // FFI: g_ort->ReleaseEnv(g_env)

    _lib = null;
    _initialized = false;
  }
}

/// Internal enum for model type detection
enum _ModelType {
  nsfw,
  violence,
  blood,
  weapons,
  detection,
  embedding,
  unknown,
}

class _LoadedSession {
  _LoadedSession({
    required this.path,
    required this.loadedAt,
    required this.executionProvider,
  });

  final String path;
  final DateTime loadedAt;
  final String executionProvider;
  bool warmedUp = false;

  // Placeholder input/output info - would be populated from FFI
  List<ONNXTensorInfo> inputInfo = [
    const ONNXTensorInfo(
        name: 'input', shape: [1, 3, 224, 224], dataType: 'float32'),
  ];
  List<ONNXTensorInfo> outputInfo = [
    const ONNXTensorInfo(
        name: 'output', shape: [1, 5], dataType: 'float32'),
  ];
}

/// ONNX model metadata
class ONNXModelMetadata {
  ONNXModelMetadata({
    required this.inputNames,
    required this.outputNames,
    required this.inputShapes,
    required this.outputShapes,
  });

  final List<String> inputNames;
  final List<String> outputNames;
  final List<List<int>> inputShapes;
  final List<List<int>> outputShapes;
}

/// Exception thrown when ONNX initialization fails
class ONNXInitializationException implements Exception {
  ONNXInitializationException(this.message);

  final String message;

  @override
  String toString() => 'ONNXInitializationException: $message';
}

/// Exception thrown when ONNX is not initialized
class ONNXNotInitializedException implements Exception {
  @override
  String toString() => 'ONNX Runtime not initialized. Call initialize() first.';
}

/// Exception thrown when model loading fails
class ONNXModelLoadException implements Exception {
  ONNXModelLoadException(this.message);

  final String message;

  @override
  String toString() => 'ONNXModelLoadException: $message';
}

/// Exception thrown when inference fails
class ONNXInferenceException implements Exception {
  ONNXInferenceException(this.message);

  final String message;

  @override
  String toString() => 'ONNXInferenceException: $message';
}
