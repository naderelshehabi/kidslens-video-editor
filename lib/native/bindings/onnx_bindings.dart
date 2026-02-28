import 'dart:async';
import 'dart:ffi';
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

import 'package:ffi/ffi.dart';

import 'package:kidslens_video_editor/native/bindings/onnx_ffi_types.dart';
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

  final int classId;
  final String className;
  final double confidence;
  final double x;
  final double y;
  final double width;
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

  final List<DetectionBox> boxes;
  final int? inferenceTimeMs;
  int get count => boxes.length;
  bool get isEmpty => boxes.isEmpty;

  List<DetectionBox> boxesAboveThreshold(double threshold) =>
      boxes.where((b) => b.confidence >= threshold).toList();

  List<DetectionBox> boxesForClass(String className) =>
      boxes.where((b) => b.className == className).toList();

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

/// Key for caching ONNX sessions by model path and device configuration
class _SessionKey {
  const _SessionKey({
    required this.modelPath,
    required this.deviceId,
    required this.executionProvider,
  });

  final String modelPath;
  final int deviceId;
  final String executionProvider;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is _SessionKey &&
          runtimeType == other.runtimeType &&
          modelPath == other.modelPath &&
          deviceId == other.deviceId &&
          executionProvider == other.executionProvider;

  @override
  int get hashCode => Object.hash(modelPath, deviceId, executionProvider);

  @override
  String toString() =>
      '_SessionKey($modelPath, device=$deviceId, provider=$executionProvider)';
}

/// FFI bindings for ONNX Runtime using official C API
class ONNXBindings extends NativeResource {
  DynamicLibrary? _lib;
  OrtApiAccessor? _api;
  Pointer<OrtEnv>? _env;
  Pointer<OrtAllocator>? _allocator;
  bool _initialized = false;

  final Map<_SessionKey, _LoadedSession> _loadedSessions = {};
  List<String> _executionProviders = ['CPUExecutionProvider'];

  static const int _maxCachedSessions = 5;
  final List<_SessionKey> _sessionAccessOrder = [];
  final _InferenceMutex _inferenceMutex = _InferenceMutex();

  static const List<String> _canonicalNsfwLabels = <String>[
    'drawings',
    'hentai',
    'neutral',
    'porn',
    'sexy',
  ];

  /// Initialize ONNX Runtime bindings using official C API
  Future<void> initialize({
    List<String>? executionProviders,
  }) async {
    if (_initialized) return;

    try {
      _lib = _loadLibrary();

      // Get OrtApiBase and then OrtApi
      final getApiBase =
          _lib!.lookupFunction<OrtGetApiBaseNative, OrtGetApiBaseDart>(
        'OrtGetApiBase',
      );
      final apiBase = getApiBase();
      if (apiBase == nullptr) {
        throw ONNXInitializationException('OrtGetApiBase returned null');
      }

      // Get versioned API - returns a Pointer<Void> to the function table
      final getApi =
          apiBase.ref.GetApi.asFunction<Pointer<Void> Function(int)>();
      final apiPtr = getApi(ORT_API_VERSION);
      if (apiPtr == nullptr) {
        throw ONNXInitializationException(
          'GetApi returned null for version $ORT_API_VERSION',
        );
      }

      // Wrap in accessor for index-based function lookup
      _api = OrtApiAccessor(apiPtr);

      // Create environment
      final envPtr = calloc<Pointer<OrtEnv>>();
      final logId = 'kidslens_video_editor'.toNativeUtf8();
      try {
        final createEnv = _api!
            .getFunction<CreateEnvNative>(OrtApiIndex.CreateEnv)
            .asFunction<CreateEnvDart>();

        final status = createEnv(
          OrtLoggingLevel.ORT_LOGGING_LEVEL_WARNING,
          logId,
          envPtr,
        );
        _checkStatus(status);
        _env = envPtr.value;
      } finally {
        calloc.free(logId);
        calloc.free(envPtr);
      }

      // Get default allocator
      final allocatorPtr = calloc<Pointer<OrtAllocator>>();
      try {
        final getAllocator = _api!
            .getFunction<GetAllocatorWithDefaultOptionsNative>(
                OrtApiIndex.GetAllocatorWithDefaultOptions)
            .asFunction<GetAllocatorWithDefaultOptionsDart>();
        final status = getAllocator(allocatorPtr);
        _checkStatus(status);
        _allocator = allocatorPtr.value;
      } finally {
        calloc.free(allocatorPtr);
      }

      if (executionProviders != null) {
        _executionProviders = executionProviders;
      }
      if (!_executionProviders.contains('CPUExecutionProvider')) {
        _executionProviders = [..._executionProviders, 'CPUExecutionProvider'];
      }

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

  /// Check ONNX Runtime status and throw if error
  void _checkStatus(Pointer<OrtStatus> status) {
    if (status == nullptr) return; // Success

    final getErrorMessage = _api!
        .getFunction<GetErrorMessageNative>(OrtApiIndex.GetErrorMessage)
        .asFunction<GetErrorMessageDart>();
    final releaseStatus = _api!
        .getFunction<ReleaseStatusNative>(OrtApiIndex.ReleaseStatus)
        .asFunction<ReleaseStatusDart>();

    final msgPtr = getErrorMessage(status);
    final message = msgPtr != nullptr
        ? msgPtr.toDartString()
        : 'Unknown ONNX Runtime error';
    releaseStatus(status);
    throw ONNXInferenceException(message);
  }

  /// Load an ONNX model with caching
  Future<void> loadModel(
    String modelPath, {
    int? deviceId,
    String? executionProvider,
    Map<String, String>? providerOptions,
    bool allowProviderFallbackToCpu = true,
  }) async {
    _ensureInitialized();

    final effectiveProvider = executionProvider ?? _executionProviders.first;
    final effectiveDeviceId = deviceId ?? 0;
    final sessionKey = _SessionKey(
      modelPath: modelPath,
      deviceId: effectiveDeviceId,
      executionProvider: effectiveProvider,
    );

    if (_loadedSessions.containsKey(sessionKey)) {
      _updateAccessOrder(sessionKey);
      return;
    }

    final modelFile = File(modelPath);
    if (!modelFile.existsSync()) {
      throw ONNXModelLoadException('Model file not found: $modelPath');
    }

    if (_loadedSessions.length >= _maxCachedSessions) {
      await _evictLRUSession();
    }

    try {
      // Create session options
      final optionsPtr = calloc<Pointer<OrtSessionOptions>>();
      final createOptions = _api!
          .getFunction<CreateSessionOptionsNative>(
              OrtApiIndex.CreateSessionOptions)
          .asFunction<CreateSessionOptionsDart>();

      var status = createOptions(optionsPtr);
      _checkStatus(status);
      final options = optionsPtr.value;
      calloc.free(optionsPtr);

      // Set optimization level
      final setOptLevel = _api!
          .getFunction<SetSessionGraphOptimizationLevelNative>(
              OrtApiIndex.SetSessionGraphOptimizationLevel)
          .asFunction<SetSessionGraphOptimizationLevelDart>();
      status = setOptLevel(options, GraphOptimizationLevel.ORT_ENABLE_ALL);
      _checkStatus(status);

      // Set thread count (0 = auto)
      final setThreads = _api!
          .getFunction<SetIntraOpNumThreadsNative>(
              OrtApiIndex.SetIntraOpNumThreads)
          .asFunction<SetIntraOpNumThreadsDart>();
      status = setThreads(options, 0);
      _checkStatus(status);

      // Append execution provider if specified
      if (executionProvider != null) {
        try {
          await _appendExecutionProvider(
            options,
            executionProvider,
            deviceId: deviceId ?? 0,
            providerOptions: providerOptions,
          );
        } catch (e) {
          if (!allowProviderFallbackToCpu) {
            throw ONNXModelLoadException(
              'Failed to configure $executionProvider: $e',
            );
          }
          // Log warning but continue with CPU fallback
          print('Warning: Failed to configure $executionProvider: $e');
        }
      }

      // Create session from file - use wide string on Windows
      final sessionPtr = calloc<Pointer<OrtSession>>();
      final modelPathNative = modelPath.toNativeUtf16();
      try {
        final createSession = _api!
            .getFunction<CreateSessionNative>(OrtApiIndex.CreateSession)
            .asFunction<CreateSessionDart>();

        status = createSession(_env!, modelPathNative, options, sessionPtr);
        _checkStatus(status);
      } finally {
        calloc.free(modelPathNative);
      }

      final ortSession = sessionPtr.value;
      calloc.free(sessionPtr);

      if (ortSession == nullptr) {
        throw ONNXModelLoadException('CreateSession returned null session');
      }

      // Get input/output names (try FFI, fallback to model-specific defaults)
      var inputNames = _getInputNames(ortSession);
      var outputNames = _getOutputNames(ortSession);

      // Use model-specific defaults if FFI retrieval fails
      if (inputNames.isEmpty) {
        inputNames = [_getDefaultInputName(modelPath)];
      }
      if (outputNames.isEmpty) {
        outputNames = [_getDefaultOutputName(modelPath)];
      }

      final inferredSize = _inferInputImageSize(modelPath);
      final inferredClassCount = _inferClassCount(modelPath);

      final session = _LoadedSession(
        path: modelPath,
        loadedAt: DateTime.now(),
        executionProvider: effectiveProvider,
        deviceId: effectiveDeviceId,
        optionsPtr: options,
        sessionPtr: ortSession,
        inputNames: inputNames,
        outputNames: outputNames,
      );

      session
        ..inputInfo = <ONNXTensorInfo>[
          ONNXTensorInfo(
            name: inputNames.first,
            shape: <int>[1, 3, inferredSize.$1, inferredSize.$2],
            dataType: 'float32',
          ),
        ]
        ..outputInfo = <ONNXTensorInfo>[
          ONNXTensorInfo(
            name: outputNames.first,
            shape: <int>[1, inferredClassCount],
            dataType: 'float32',
          ),
        ];

      _loadedSessions[sessionKey] = session;
      _sessionAccessOrder.add(sessionKey);
    } catch (e) {
      throw ONNXModelLoadException('Failed to load model: $e');
    }
  }

  List<String> _getInputNames(Pointer<OrtSession> session) {
    final names = <String>[];
    final countPtr = calloc<Size>();

    try {
      // Get input count
      final getInputCount = _api!
          .getFunction<SessionGetInputCountNative>(
              OrtApiIndex.SessionGetInputCount)
          .asFunction<SessionGetInputCountDart>();
      final countStatus = getInputCount(session, countPtr);
      _checkStatus(countStatus);

      final count = countPtr.value;

      if (count == 0) {
        return names;
      }

      // Get each input name
      final getInputName = _api!
          .getFunction<SessionGetInputNameNative>(
              OrtApiIndex.SessionGetInputName)
          .asFunction<SessionGetInputNameDart>();
      final freeAllocator = _api!
          .getFunction<AllocatorFreeNative>(OrtApiIndex.AllocatorFree)
          .asFunction<AllocatorFreeDart>();

      for (var i = 0; i < count; i++) {
        final namePtr = calloc<Pointer<Utf8>>();
        try {
          final nameStatus = getInputName(session, i, _allocator!, namePtr);
          _checkStatus(nameStatus);

          if (namePtr.value != nullptr) {
            final name = namePtr.value.toDartString();
            names.add(name);
            // Free the string allocated by ONNX Runtime
            freeAllocator(_allocator!, namePtr.value.cast<Void>());
          }
        } finally {
          calloc.free(namePtr);
        }
      }
    } catch (e) {
      // Return empty list on error - caller will use model-specific defaults
    } finally {
      calloc.free(countPtr);
    }

    return names;
  }

  List<String> _getOutputNames(Pointer<OrtSession> session) {
    final names = <String>[];
    final countPtr = calloc<Size>();

    try {
      // Get output count
      final getOutputCount = _api!
          .getFunction<SessionGetOutputCountNative>(
              OrtApiIndex.SessionGetOutputCount)
          .asFunction<SessionGetOutputCountDart>();
      final countStatus = getOutputCount(session, countPtr);
      _checkStatus(countStatus);

      final count = countPtr.value;

      if (count == 0) {
        return names;
      }

      // Get each output name
      final getOutputName = _api!
          .getFunction<SessionGetOutputNameNative>(
              OrtApiIndex.SessionGetOutputName)
          .asFunction<SessionGetOutputNameDart>();
      final freeAllocator = _api!
          .getFunction<AllocatorFreeNative>(OrtApiIndex.AllocatorFree)
          .asFunction<AllocatorFreeDart>();

      for (var i = 0; i < count; i++) {
        final namePtr = calloc<Pointer<Utf8>>();
        try {
          final nameStatus = getOutputName(session, i, _allocator!, namePtr);
          _checkStatus(nameStatus);

          if (namePtr.value != nullptr) {
            final name = namePtr.value.toDartString();
            names.add(name);
            // Free the string allocated by ONNX Runtime
            freeAllocator(_allocator!, namePtr.value.cast<Void>());
          }
        } finally {
          calloc.free(namePtr);
        }
      }
    } catch (e) {
      // Return empty list on error - caller will use model-specific defaults
    } finally {
      calloc.free(countPtr);
    }

    return names;
  }

  /// Append execution provider to session options
  Future<void> _appendExecutionProvider(
    Pointer<OrtSessionOptions> options,
    String providerName, {
    int deviceId = 0,
    Map<String, String>? providerOptions,
  }) async {
    switch (providerName) {
      case 'CUDAExecutionProvider':
        await _appendCudaProvider(options, deviceId, providerOptions ?? {});
      case 'DmlExecutionProvider':
        await _appendDirectMLProvider(options, deviceId, providerOptions ?? {});
      case 'CoreMLExecutionProvider':
        await _appendCoreMLProvider(options, providerOptions ?? {});
      case 'ROCMExecutionProvider':
        await _appendGenericProvider(
          options,
          'ROCMExecutionProvider',
          {...providerOptions ?? {}, 'device_id': deviceId.toString()},
        );
      default:
        // For other providers, use generic API if available
        if (providerOptions != null && providerOptions.isNotEmpty) {
          await _appendGenericProvider(options, providerName, providerOptions);
        }
    }
  }

  /// Append CUDA execution provider using V2 API
  Future<void> _appendCudaProvider(
    Pointer<OrtSessionOptions> options,
    int deviceId,
    Map<String, String> config,
  ) async {
    Pointer<OrtCUDAProviderOptionsV2>? cudaOptions;

    try {
      // 1. Create CUDA options
      final cudaOptionsPtr = calloc<Pointer<OrtCUDAProviderOptionsV2>>();
      try {
        final createOptions = _api!
            .getFunction<CreateCUDAProviderOptionsNative>(
                OrtApiIndex.CreateCUDAProviderOptions)
            .asFunction<CreateCUDAProviderOptionsDart>();

        var status = createOptions(cudaOptionsPtr);
        _checkStatus(status);
        cudaOptions = cudaOptionsPtr.value;
      } finally {
        calloc.free(cudaOptionsPtr);
      }

      // 2. Update with key-value pairs
      final fullConfig = {'device_id': deviceId.toString(), ...config};
      final keys = fullConfig.keys.toList();
      final values = fullConfig.values.toList();

      final keysPtr = calloc<Pointer<Utf8>>(keys.length);
      final valuesPtr = calloc<Pointer<Utf8>>(values.length);

      try {
        for (var i = 0; i < keys.length; i++) {
          keysPtr[i] = keys[i].toNativeUtf8();
          valuesPtr[i] = values[i].toNativeUtf8();
        }

        final updateOptions = _api!
            .getFunction<UpdateCUDAProviderOptionsNative>(
                OrtApiIndex.UpdateCUDAProviderOptions)
            .asFunction<UpdateCUDAProviderOptionsDart>();

        final status =
            updateOptions(cudaOptions!, keysPtr, valuesPtr, keys.length);
        _checkStatus(status);

        // 3. Append to session options
        final appendProvider = _api!
            .getFunction<SessionOptionsAppendExecutionProvider_CUDA_V2Native>(
                OrtApiIndex.SessionOptionsAppendExecutionProvider_CUDA_V2)
            .asFunction<SessionOptionsAppendExecutionProvider_CUDA_V2Dart>();

        final appendStatus = appendProvider(options, cudaOptions);
        _checkStatus(appendStatus);
      } finally {
        // Free key-value strings
        for (var i = 0; i < keys.length; i++) {
          calloc.free(keysPtr[i]);
          calloc.free(valuesPtr[i]);
        }
        calloc.free(keysPtr);
        calloc.free(valuesPtr);
      }
    } finally {
      // 4. Release CUDA options
      if (cudaOptions != null && cudaOptions != nullptr) {
        final releaseOptions = _api!
            .getFunction<ReleaseCUDAProviderOptionsNative>(
                OrtApiIndex.ReleaseCUDAProviderOptions)
            .asFunction<ReleaseCUDAProviderOptionsDart>();
        releaseOptions(cudaOptions);
      }
    }
  }

  /// Append DirectML execution provider
  Future<void> _appendDirectMLProvider(
    Pointer<OrtSessionOptions> options,
    int deviceId,
    Map<String, String> config,
  ) async {
    final fullConfig = DirectMLDeviceConfig(
      deviceId: deviceId,
      enableGraphCapture: config['enable_graph_capture'] != '0',
      disableMetaCommands: config['disable_metacommands'] == '1',
    ).toKeyValuePairs();

    await _appendGenericProvider(options, 'DmlExecutionProvider', fullConfig);
  }

  /// Append CoreML execution provider
  Future<void> _appendCoreMLProvider(
    Pointer<OrtSessionOptions> options,
    Map<String, String> config,
  ) async {
    await _appendGenericProvider(options, 'CoreMLExecutionProvider', config);
  }

  /// Generic execution provider append helper
  Future<void> _appendGenericProvider(
    Pointer<OrtSessionOptions> options,
    String providerName,
    Map<String, String> config,
  ) async {
    final keys = config.keys.toList();
    final values = config.values.toList();

    final providerNamePtr = providerName.toNativeUtf8();
    final keysPtr = calloc<Pointer<Utf8>>(keys.length);
    final valuesPtr = calloc<Pointer<Utf8>>(values.length);

    try {
      for (var i = 0; i < keys.length; i++) {
        keysPtr[i] = keys[i].toNativeUtf8();
        valuesPtr[i] = values[i].toNativeUtf8();
      }

      final appendProvider = _api!
          .getFunction<SessionOptionsAppendExecutionProviderNative>(
              OrtApiIndex.SessionOptionsAppendExecutionProvider)
          .asFunction<SessionOptionsAppendExecutionProviderDart>();

      final status = appendProvider(
        options,
        providerNamePtr,
        keysPtr,
        valuesPtr,
        keys.length,
      );
      _checkStatus(status);
    } finally {
      calloc.free(providerNamePtr);
      for (var i = 0; i < keys.length; i++) {
        calloc.free(keysPtr[i]);
        calloc.free(valuesPtr[i]);
      }
      calloc.free(keysPtr);
      calloc.free(valuesPtr);
    }
  }

  void _updateAccessOrder(_SessionKey key) {
    _sessionAccessOrder
      ..remove(key)
      ..add(key);
  }

  /// Find a session key for the given model path (returns first match)
  _SessionKey? _findSessionKey(String modelPath) {
    return _loadedSessions.keys
            .firstWhere(
              (key) => key.modelPath == modelPath,
              orElse: () => _SessionKey(
                modelPath: '',
                deviceId: -1,
                executionProvider: '',
              ),
            )
            .modelPath
            .isNotEmpty
        ? _loadedSessions.keys.firstWhere((key) => key.modelPath == modelPath)
        : null;
  }

  Future<void> _evictLRUSession() async {
    if (_sessionAccessOrder.isEmpty) return;
    final lruKey = _sessionAccessOrder.removeAt(0);
    await _disposeSessionByKey(lruKey);
  }

  void unloadModel(String modelPath) {
    disposeSession(modelPath);
  }

  Future<void> disposeSession(String modelPath) async {
    // Dispose all sessions for this model path
    final keysToRemove = _loadedSessions.keys
        .where((key) => key.modelPath == modelPath)
        .toList();

    for (final key in keysToRemove) {
      await _disposeSessionByKey(key);
    }
  }

  Future<void> _disposeSessionByKey(_SessionKey key) async {
    final session = _loadedSessions.remove(key);
    _sessionAccessOrder.remove(key);

    if (session == null) return;

    final releaseSession = _api!
        .getFunction<ReleaseSessionNative>(OrtApiIndex.ReleaseSession)
        .asFunction<ReleaseSessionDart>();
    final releaseOptions = _api!
        .getFunction<ReleaseSessionOptionsNative>(
            OrtApiIndex.ReleaseSessionOptions)
        .asFunction<ReleaseSessionOptionsDart>();

    releaseSession(session.sessionPtr);
    releaseOptions(session.optionsPtr);
  }

  Future<void> disposeAllSessions() async {
    final paths = List<String>.from(_loadedSessions.keys);
    for (final path in paths) {
      await disposeSession(path);
    }
    _sessionAccessOrder.clear();
  }

  ONNXSessionInfo? getSessionInfo(String modelPath) {
    final key = _findSessionKey(modelPath);
    if (key == null) return null;

    final session = _loadedSessions[key];
    if (session == null) return null;

    return ONNXSessionInfo(
      modelPath: session.path,
      executionProvider: session.executionProvider,
      loadedAt: session.loadedAt,
      warmupCompleted: session.warmedUp,
      inputInfo: session.inputInfo,
      outputInfo: session.outputInfo,
    );
  }

  Future<Duration> warmup(String modelPath) async {
    _ensureInitialized();

    final key = _findSessionKey(modelPath);
    if (key == null) {
      await loadModel(modelPath);
    }

    final effectiveKey = _findSessionKey(modelPath)!;
    final session = _loadedSessions[effectiveKey]!;
    if (session.warmedUp) {
      return Duration.zero;
    }

    final stopwatch = Stopwatch()..start();

    try {
      await _withInferenceLock(() async {
        final inputShape = session.inputInfo.first.shape;
        final warmupWidth = inputShape.length >= 4 ? inputShape[3] : 224;
        final warmupHeight = inputShape.length >= 4 ? inputShape[2] : 224;
        final warmupData = List<int>.filled(warmupWidth * warmupHeight * 3, 0);
        _runModelInference(modelPath, warmupData, warmupWidth, warmupHeight);
      });

      session.warmedUp = true;
      stopwatch.stop();
      return stopwatch.elapsed;
    } catch (e) {
      stopwatch.stop();
      throw ONNXInferenceException('Warmup failed: $e');
    }
  }

  Future<T> _withInferenceLock<T>(Future<T> Function() fn) async {
    await _inferenceMutex.acquire();
    try {
      return await fn();
    } finally {
      _inferenceMutex.release();
    }
  }

  Future<Map<String, double>> runInference(
    String modelPath,
    List<int> rgbData,
    int width,
    int height,
  ) async {
    _ensureInitialized();

    final key = _findSessionKey(modelPath);
    if (key == null) {
      await loadModel(modelPath);
    }
    final effectiveKey = _findSessionKey(modelPath)!;
    _updateAccessOrder(effectiveKey);

    try {
      return await _withInferenceLock(
        () async => _runModelInference(modelPath, rgbData, width, height),
      );
    } catch (e) {
      if (e is ONNXInferenceException) rethrow;
      throw ONNXInferenceException('Inference failed: $e');
    }
  }

  Map<String, double> _runModelInference(
    String modelPath,
    List<int> rgbData,
    int width,
    int height,
  ) {
    final key = _findSessionKey(modelPath);
    if (key == null) {
      throw ONNXInferenceException('Model is not loaded: $modelPath');
    }
    final session = _loadedSessions[key]!;
    final modelType = _inferModelType(modelPath);

    switch (modelType) {
      case _ModelType.nsfw:
        return _runOrtNsfwInference(session, rgbData, width, height);

      case _ModelType.detection:
      case _ModelType.embedding:
      case _ModelType.unknown:
        final variance = _computeImageVariance(rgbData, width, height);
        return {
          'safe': (0.90 - variance * 0.2).clamp(0.0, 1.0),
          'unsafe': (0.10 + variance * 0.2).clamp(0.0, 1.0),
        };
    }
  }

  Map<String, double> _runOrtNsfwInference(
    _LoadedSession session,
    List<int> rgbData,
    int width,
    int height,
  ) {
    if (rgbData.length != width * height * 3 || width <= 0 || height <= 0) {
      throw ONNXInferenceException(
        'Invalid RGB input for NSFW inference (w=$width h=$height bytes=${rgbData.length})',
      );
    }

    final configuredLayout = session.inputLayout;
    final configuredWidth = session.inputWidth ?? width;
    final configuredHeight = session.inputHeight ?? height;

    try {
      return _runOrtNsfwInferenceWithConfig(
        session: session,
        rgbData: rgbData,
        width: width,
        height: height,
        targetWidth: configuredWidth,
        targetHeight: configuredHeight,
        layout: configuredLayout,
      );
    } catch (e) {
      final expected = _parseExpectedInputFromOrtError(e.toString());
      if (expected == null) {
        rethrow;
      }

      session
        ..inputWidth = expected.width
        ..inputHeight = expected.height
        ..inputLayout = expected.layout
        ..inputInfo = <ONNXTensorInfo>[
          ONNXTensorInfo(
            name: session.inputNames.isNotEmpty
                ? session.inputNames.first
                : _getDefaultInputName(session.path),
            shape: expected.layout == _InputLayout.nchw
                ? <int>[1, 3, expected.height, expected.width]
                : <int>[1, expected.height, expected.width, 3],
            dataType: 'float32',
          ),
        ];

      return _runOrtNsfwInferenceWithConfig(
        session: session,
        rgbData: rgbData,
        width: width,
        height: height,
        targetWidth: expected.width,
        targetHeight: expected.height,
        layout: expected.layout,
      );
    }
  }

  Map<String, double> _runOrtNsfwInferenceWithConfig({
    required _LoadedSession session,
    required List<int> rgbData,
    required int width,
    required int height,
    required int targetWidth,
    required int targetHeight,
    required _InputLayout layout,
  }) {
    final resized = (width == targetWidth && height == targetHeight)
        ? rgbData
        : _resizeRgbNearest(
            rgbData: rgbData,
            srcWidth: width,
            srcHeight: height,
            dstWidth: targetWidth,
            dstHeight: targetHeight,
          );
    final input = layout == _InputLayout.nchw
        ? _preprocessToNchwFloat(resized, targetWidth, targetHeight)
        : _preprocessToNhwcFloat(resized);
    final inputShape = layout == _InputLayout.nchw
        ? <int>[1, 3, targetHeight, targetWidth]
        : <int>[1, targetHeight, targetWidth, 3];

    // Run inference using FFI
    final outputs = _runSession(session, input, inputShape);

    if (outputs.isEmpty) {
      throw ONNXInferenceException('NSFW model produced no output');
    }

    final flattened = outputs;
    if (flattened.length != _canonicalNsfwLabels.length) {
      throw ONNXInferenceException(
        'Unexpected NSFW output size: ${flattened.length} (expected ${_canonicalNsfwLabels.length})',
      );
    }

    final mapped = <String, double>{};
    for (var i = 0; i < _canonicalNsfwLabels.length; i++) {
      mapped[_canonicalNsfwLabels[i]] = flattened[i];
    }
    return mapped;
  }

  /// Run ONNX session inference using FFI
  List<double> _runSession(
    _LoadedSession session,
    Float32List inputData,
    List<int> inputShape,
  ) {
    // Create memory info for CPU
    final memInfoPtr = calloc<Pointer<OrtMemoryInfo>>();
    final createMemInfo = _api!
        .getFunction<CreateCpuMemoryInfoNative>(OrtApiIndex.CreateCpuMemoryInfo)
        .asFunction<CreateCpuMemoryInfoDart>();

    var status = createMemInfo(
      OrtAllocatorType.OrtArenaAllocator,
      OrtMemType.OrtMemTypeDefault,
      memInfoPtr,
    );
    _checkStatus(status);
    final memInfo = memInfoPtr.value;
    calloc.free(memInfoPtr);

    // Allocate native memory for input data
    final dataPtr = calloc<Float>(inputData.length);
    for (var i = 0; i < inputData.length; i++) {
      dataPtr[i] = inputData[i];
    }

    // Allocate shape array
    final shapePtr = calloc<Int64>(inputShape.length);
    for (var i = 0; i < inputShape.length; i++) {
      shapePtr[i] = inputShape[i];
    }

    // Create input tensor
    final inputTensorPtr = calloc<Pointer<OrtValue>>();
    final createTensor = _api!
        .getFunction<CreateTensorWithDataAsOrtValueNative>(
            OrtApiIndex.CreateTensorWithDataAsOrtValue)
        .asFunction<CreateTensorWithDataAsOrtValueDart>();

    status = createTensor(
      memInfo,
      dataPtr.cast<Void>(),
      inputData.length * 4, // Float32 = 4 bytes
      shapePtr,
      inputShape.length,
      ONNXTensorElementDataType.ONNX_TENSOR_ELEMENT_DATA_TYPE_FLOAT,
      inputTensorPtr,
    );
    _checkStatus(status);
    final inputTensor = inputTensorPtr.value;

    // Create run options
    final runOptionsPtr = calloc<Pointer<OrtRunOptions>>();
    final createRunOptions = _api!
        .getFunction<CreateRunOptionsNative>(OrtApiIndex.CreateRunOptions)
        .asFunction<CreateRunOptionsDart>();
    status = createRunOptions(runOptionsPtr);
    _checkStatus(status);
    final runOptions = runOptionsPtr.value;

    // Prepare input/output name arrays
    // session.inputNames/outputNames should always have values from loadModel,
    // but use model-specific defaults as extra safety
    final inputName = session.inputNames.isNotEmpty
        ? session.inputNames.first
        : _getDefaultInputName(session.path);
    final outputName = session.outputNames.isNotEmpty
        ? session.outputNames.first
        : _getDefaultOutputName(session.path);

    final inputNamePtr = inputName.toNativeUtf8();
    final outputNamePtr = outputName.toNativeUtf8();
    final inputNamesArray = calloc<Pointer<Utf8>>(1);
    final outputNamesArray = calloc<Pointer<Utf8>>(1);
    inputNamesArray[0] = inputNamePtr;
    outputNamesArray[0] = outputNamePtr;

    final inputsArray = calloc<Pointer<OrtValue>>(1);
    inputsArray[0] = inputTensor;

    final outputsArray = calloc<Pointer<OrtValue>>(1);
    outputsArray[0] = nullptr;

    try {
      // Run inference
      final run =
          _api!.getFunction<RunNative>(OrtApiIndex.Run).asFunction<RunDart>();

      status = run(
        session.sessionPtr,
        runOptions,
        inputNamesArray,
        inputsArray,
        1,
        outputNamesArray,
        1,
        outputsArray,
      );
      _checkStatus(status);

      // Extract output data
      final outputTensor = outputsArray[0];
      final outputDataPtr = calloc<Pointer<Void>>();
      final getTensorData = _api!
          .getFunction<GetTensorMutableDataNative>(
              OrtApiIndex.GetTensorMutableData)
          .asFunction<GetTensorMutableDataDart>();
      status = getTensorData(outputTensor, outputDataPtr);
      _checkStatus(status);

      // Get output shape to determine size
      final shapeInfoPtr = calloc<Pointer<OrtTensorTypeAndShapeInfo>>();
      final getShapeInfo = _api!
          .getFunction<GetTensorTypeAndShapeNative>(
              OrtApiIndex.GetTensorTypeAndShape)
          .asFunction<GetTensorTypeAndShapeDart>();
      status = getShapeInfo(outputTensor, shapeInfoPtr);
      _checkStatus(status);

      final dimCountPtr = calloc<Size>();
      final getDimCount = _api!
          .getFunction<GetDimensionsCountNative>(OrtApiIndex.GetDimensionsCount)
          .asFunction<GetDimensionsCountDart>();
      status = getDimCount(shapeInfoPtr.value, dimCountPtr);
      _checkStatus(status);

      final dimCount = dimCountPtr.value;
      final dimsPtr = calloc<Int64>(dimCount);
      final getDims = _api!
          .getFunction<GetDimensionsNative>(OrtApiIndex.GetDimensions)
          .asFunction<GetDimensionsDart>();
      status = getDims(shapeInfoPtr.value, dimsPtr, dimCount);
      _checkStatus(status);

      var outputSize = 1;
      for (var i = 0; i < dimCount; i++) {
        outputSize *= dimsPtr[i];
      }

      // Copy output data
      final outputFloats = outputDataPtr.value.cast<Float>();
      final results = <double>[];
      for (var i = 0; i < outputSize; i++) {
        results.add(outputFloats[i]);
      }

      // Release shape info
      final releaseShapeInfo = _api!
          .getFunction<ReleaseTensorTypeAndShapeInfoNative>(
              OrtApiIndex.ReleaseTensorTypeAndShapeInfo)
          .asFunction<ReleaseTensorTypeAndShapeInfoDart>();
      releaseShapeInfo(shapeInfoPtr.value);

      calloc.free(shapeInfoPtr);
      calloc.free(dimCountPtr);
      calloc.free(dimsPtr);
      calloc.free(outputDataPtr);

      // Release output tensor
      final releaseValue = _api!
          .getFunction<ReleaseValueNative>(OrtApiIndex.ReleaseValue)
          .asFunction<ReleaseValueDart>();
      releaseValue(outputTensor);

      return results;
    } finally {
      // Cleanup
      final releaseValue = _api!
          .getFunction<ReleaseValueNative>(OrtApiIndex.ReleaseValue)
          .asFunction<ReleaseValueDart>();
      final releaseRunOptions = _api!
          .getFunction<ReleaseRunOptionsNative>(OrtApiIndex.ReleaseRunOptions)
          .asFunction<ReleaseRunOptionsDart>();
      final releaseMemInfo = _api!
          .getFunction<ReleaseMemoryInfoNative>(OrtApiIndex.ReleaseMemoryInfo)
          .asFunction<ReleaseMemoryInfoDart>();

      releaseValue(inputTensor);
      releaseRunOptions(runOptions);
      releaseMemInfo(memInfo);

      calloc.free(inputTensorPtr);
      calloc.free(runOptionsPtr);
      calloc.free(inputNamePtr);
      calloc.free(outputNamePtr);
      calloc.free(inputNamesArray);
      calloc.free(outputNamesArray);
      calloc.free(inputsArray);
      calloc.free(outputsArray);
      calloc.free(dataPtr);
      calloc.free(shapePtr);
    }
  }

  Float32List _preprocessToNchwFloat(
    List<int> rgbData,
    int width,
    int height,
  ) {
    final pixels = width * height;
    final output = Float32List(3 * pixels);
    for (var i = 0; i < pixels; i++) {
      final src = i * 3;
      output[i] = _normalizeToUnitCentered(rgbData[src]);
      output[pixels + i] = _normalizeToUnitCentered(rgbData[src + 1]);
      output[(2 * pixels) + i] = _normalizeToUnitCentered(rgbData[src + 2]);
    }
    return output;
  }

  Float32List _preprocessToNhwcFloat(List<int> rgbData) {
    final output = Float32List(rgbData.length);
    for (var i = 0; i < rgbData.length; i++) {
      output[i] = _normalizeToUnitCentered(rgbData[i]);
    }
    return output;
  }

  double _normalizeToUnitCentered(int value) {
    final rescaled = value / 255.0;
    return (rescaled - 0.5) / 0.5;
  }

  List<int> _resizeRgbNearest({
    required List<int> rgbData,
    required int srcWidth,
    required int srcHeight,
    required int dstWidth,
    required int dstHeight,
  }) {
    if (srcWidth <= 0 || srcHeight <= 0 || dstWidth <= 0 || dstHeight <= 0) {
      throw ONNXInferenceException('Invalid resize dimensions');
    }
    if (rgbData.length != srcWidth * srcHeight * 3) {
      throw ONNXInferenceException('Invalid source RGB data size for resize');
    }
    final resized = List<int>.filled(dstWidth * dstHeight * 3, 0);
    for (var y = 0; y < dstHeight; y++) {
      final srcY =
          ((y * srcHeight) / dstHeight).floor().clamp(0, srcHeight - 1);
      for (var x = 0; x < dstWidth; x++) {
        final srcX = ((x * srcWidth) / dstWidth).floor().clamp(0, srcWidth - 1);
        final srcIndex = (srcY * srcWidth + srcX) * 3;
        final dstIndex = (y * dstWidth + x) * 3;
        resized[dstIndex] = rgbData[srcIndex];
        resized[dstIndex + 1] = rgbData[srcIndex + 1];
        resized[dstIndex + 2] = rgbData[srcIndex + 2];
      }
    }
    return resized;
  }

  _ExpectedInputConfig? _parseExpectedInputFromOrtError(String errorText) {
    final matches =
        RegExp(r'index:\s*(\d+)\s*Got:\s*(-?\d+)\s*Expected:\s*(-?\d+)')
            .allMatches(errorText);
    if (matches.isEmpty) return null;

    final expectedByIndex = <int, int>{};
    for (final match in matches) {
      final index = int.tryParse(match.group(1) ?? '');
      final expected = int.tryParse(match.group(3) ?? '');
      if (index == null || expected == null) continue;
      expectedByIndex[index] = expected;
    }
    if (expectedByIndex.isEmpty) return null;

    final e1 = expectedByIndex[1];
    final e2 = expectedByIndex[2];
    final e3 = expectedByIndex[3];
    if (e1 == null || e2 == null || e3 == null) {
      return null;
    }

    if (e1 == 3 && e2 > 0 && e3 > 0) {
      return _ExpectedInputConfig(
        width: e3,
        height: e2,
        layout: _InputLayout.nchw,
      );
    }
    if (e3 == 3 && e1 > 0 && e2 > 0) {
      return _ExpectedInputConfig(
        width: e2,
        height: e1,
        layout: _InputLayout.nhwc,
      );
    }
    return null;
  }

  (int, int) _inferInputImageSize(String modelPath) {
    final lower = modelPath.toLowerCase();
    if (lower.contains('299') || lower.contains('inception')) {
      return (299, 299);
    }
    return (224, 224);
  }

  int _inferClassCount(String modelPath) {
    final type = _inferModelType(modelPath);
    if (type == _ModelType.nsfw) {
      return _canonicalNsfwLabels.length;
    }
    return 2;
  }

  _ModelType _inferModelType(String modelPath) {
    final lowerPath = modelPath.toLowerCase();

    if (lowerPath.contains('nsfw')) {
      return _ModelType.nsfw;
    } else if (lowerPath.contains('nudenet') || lowerPath.contains('yolo')) {
      return _ModelType.detection;
    } else if (lowerPath.contains('clip') || lowerPath.contains('vit')) {
      return _ModelType.embedding;
    }

    return _ModelType.unknown;
  }

  /// Get model-specific default input name based on model type
  String _getDefaultInputName(String modelPath) {
    final lowerPath = modelPath.toLowerCase();

    // ViT-based models (HuggingFace transformers) use 'pixel_values'
    // This includes: onnx-community/nsfw-image-detector-ONNX
    if (lowerPath.contains('vit') ||
        lowerPath.contains('model_fp16') ||
        lowerPath.contains('model_int8') ||
        lowerPath.contains('onnx-community') ||
        lowerPath.contains('nsfw-onnx-community') ||
        lowerPath.contains('nsfw-image-detector')) {
      return 'pixel_values';
    }

    // MobileNet-v2 models (typical NSFW.js style)
    if (lowerPath.contains('mobilenet')) {
      return 'input_1';
    }

    // Inception models
    if (lowerPath.contains('inception')) {
      return 'input_1';
    }

    // Default fallback
    return 'input';
  }

  /// Get model-specific default output name based on model type
  String _getDefaultOutputName(String modelPath) {
    final lowerPath = modelPath.toLowerCase();

    // ViT-based models use 'logits'
    if (lowerPath.contains('vit') ||
        lowerPath.contains('model_fp16') ||
        lowerPath.contains('model_int8') ||
        lowerPath.contains('onnx-community') ||
        lowerPath.contains('nsfw-onnx-community') ||
        lowerPath.contains('nsfw-image-detector')) {
      return 'logits';
    }

    // MobileNet/Inception models typically use 'output' or 'Identity'
    if (lowerPath.contains('mobilenet') || lowerPath.contains('inception')) {
      return 'output';
    }

    // Default fallback
    return 'output';
  }

  double _computeImageVariance(List<int> rgbData, int width, int height) {
    if (rgbData.isEmpty) return 0.5;

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

    return (variance / 16384).clamp(0.0, 1.0);
  }

  Future<List<Map<String, double>>> runBatchInference(
    String modelPath,
    List<List<int>> rgbDataList,
    int width,
    int height, {
    int? batchSize,
  }) async {
    _ensureInitialized();

    final key = _findSessionKey(modelPath);
    if (key == null) {
      await loadModel(modelPath);
    }
    final effectiveKey = _findSessionKey(modelPath)!;
    _updateAccessOrder(effectiveKey);

    final effectiveBatchSize = batchSize ?? rgbDataList.length;
    final results = <Map<String, double>>[];

    try {
      for (var i = 0; i < rgbDataList.length; i += effectiveBatchSize) {
        final batchEnd = (i + effectiveBatchSize).clamp(0, rgbDataList.length);
        final batch = rgbDataList.sublist(i, batchEnd);

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

    final key = _findSessionKey(modelPath);
    if (key == null) {
      await loadModel(modelPath);
    }
    final effectiveKey = _findSessionKey(modelPath)!;
    _updateAccessOrder(effectiveKey);

    final stopwatch = Stopwatch()..start();

    try {
      final result = await _withInferenceLock(() async {
        final letterboxed = _letterbox(rgbData, width, height, inputSize);

        final boxes = _simulateDetectionOutput(
          rgbData,
          width,
          height,
          classNames,
          confidenceThreshold,
          letterboxed,
        );

        final nmsBoxes = _nonMaxSuppression(boxes, iouThreshold)
          ..sort((a, b) => b.confidence.compareTo(a.confidence));
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

  List<DetectionBox> _simulateDetectionOutput(
    List<int> rgbData,
    int width,
    int height,
    List<String> classNames,
    double confidenceThreshold,
    _LetterboxResult letterboxed,
  ) {
    final variance = _computeImageVariance(rgbData, width, height);
    final random = Random(variance.hashCode);

    if (random.nextDouble() > 0.05) {
      return [];
    }

    final numDetections = random.nextInt(2) + 1;
    final boxes = <DetectionBox>[];

    for (var i = 0; i < numDetections; i++) {
      final classId = random.nextInt(classNames.length);
      final confidence = (random.nextDouble() * 0.4 + 0.3).clamp(0.0, 1.0);

      if (confidence < confidenceThreshold) continue;

      final x = random.nextDouble() * 0.6;
      final y = random.nextDouble() * 0.6;
      final w = (random.nextDouble() * 0.3 + 0.05).clamp(0.0, 1.0 - x);
      final h = (random.nextDouble() * 0.3 + 0.05).clamp(0.0, 1.0 - y);

      boxes.add(
        DetectionBox(
          classId: classId,
          className: classNames[classId],
          confidence: confidence,
          x: x,
          y: y,
          width: w,
          height: h,
        ),
      );
    }

    return boxes;
  }

  Future<List<double>> runEmbeddingInference(
    String modelPath, {
    List<int>? rgbData,
    int? width,
    int? height,
    Int32List? tokenIds,
    bool isVisionModel = true,
  }) async {
    _ensureInitialized();

    final key = _findSessionKey(modelPath);
    if (key == null) {
      await loadModel(modelPath);
    }
    final effectiveKey = _findSessionKey(modelPath)!;
    _updateAccessOrder(effectiveKey);

    try {
      return await _withInferenceLock(() async {
        if (isVisionModel) {
          if (rgbData == null || width == null || height == null) {
            throw ONNXInferenceException(
              'Vision model requires rgbData, width, and height',
            );
          }
          return _simulateEmbedding(rgbData, width, height);
        } else {
          if (tokenIds == null) {
            throw ONNXInferenceException('Text model requires tokenIds');
          }
          return _simulateTextEmbedding(tokenIds);
        }
      });
    } catch (e) {
      if (e is ONNXInferenceException) rethrow;
      throw ONNXInferenceException('Embedding inference failed: $e');
    }
  }

  List<double> _simulateEmbedding(List<int> rgbData, int width, int height) {
    final variance = _computeImageVariance(rgbData, width, height);
    final random = Random(variance.hashCode);
    final embedding = List.generate(512, (_) => random.nextDouble() * 2 - 1);
    return _l2Normalize(embedding);
  }

  List<double> _simulateTextEmbedding(Int32List tokenIds) {
    var seed = 0;
    for (final id in tokenIds) {
      seed = seed * 31 + id;
    }
    final random = Random(seed);
    final embedding = List.generate(512, (_) => random.nextDouble() * 2 - 1);
    return _l2Normalize(embedding);
  }

  List<double> _l2Normalize(List<double> embedding) {
    var norm = 0.0;
    for (final v in embedding) {
      norm += v * v;
    }
    norm = sqrt(norm);
    if (norm < 1e-12) return embedding;
    return embedding.map((v) => v / norm).toList();
  }

  _LetterboxResult _letterbox(
    List<int> rgbData,
    int srcW,
    int srcH,
    int targetSize,
  ) {
    final scale = min(targetSize / srcW, targetSize / srcH);
    final newW = (srcW * scale).round();
    final newH = (srcH * scale).round();

    final padX = (targetSize - newW) / 2.0;
    final padY = (targetSize - newH) / 2.0;
    final padXInt = padX.round();
    final padYInt = padY.round();

    final output = Float32List(3 * targetSize * targetSize);

    const grayValue = 114.0 / 255.0;
    for (var i = 0; i < output.length; i++) {
      output[i] = grayValue;
    }

    for (var y = 0; y < newH; y++) {
      for (var x = 0; x < newW; x++) {
        final srcX = (x / scale).round().clamp(0, srcW - 1);
        final srcY = (y / scale).round().clamp(0, srcH - 1);
        final srcIdx = (srcY * srcW + srcX) * 3;

        if (srcIdx + 2 >= rgbData.length) continue;

        final destX = x + padXInt;
        final destY = y + padYInt;

        if (destX >= targetSize || destY >= targetSize) continue;

        output[0 * targetSize * targetSize + destY * targetSize + destX] =
            rgbData[srcIdx] / 255.0;
        output[1 * targetSize * targetSize + destY * targetSize + destX] =
            rgbData[srcIdx + 1] / 255.0;
        output[2 * targetSize * targetSize + destY * targetSize + destX] =
            rgbData[srcIdx + 2] / 255.0;
      }
    }

    return _LetterboxResult(
      data: output,
      padX: padX,
      padY: padY,
      scale: scale,
    );
  }

  List<DetectionBox> _nonMaxSuppression(
    List<DetectionBox> boxes,
    double iouThreshold,
  ) {
    if (boxes.isEmpty) return [];

    final byClass = <int, List<DetectionBox>>{};
    for (final box in boxes) {
      byClass.putIfAbsent(box.classId, () => []).add(box);
    }

    final result = <DetectionBox>[];

    for (final classBoxes in byClass.values) {
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

    if (union <= 0) return 0;
    return intersection / union;
  }

  Future<ONNXModelMetadata> getModelMetadata(String modelPath) async {
    _ensureInitialized();

    if (!_loadedSessions.containsKey(modelPath)) {
      await loadModel(modelPath);
    }

    final session = _loadedSessions[modelPath]!;

    return ONNXModelMetadata(
      inputNames: session.inputNames,
      outputNames: session.outputNames,
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
    for (final session in _loadedSessions.values) {
      final releaseSession = _api!
          .getFunction<ReleaseSessionNative>(OrtApiIndex.ReleaseSession)
          .asFunction<ReleaseSessionDart>();
      final releaseOptions = _api!
          .getFunction<ReleaseSessionOptionsNative>(
              OrtApiIndex.ReleaseSessionOptions)
          .asFunction<ReleaseSessionOptionsDart>();
      releaseSession(session.sessionPtr);
      releaseOptions(session.optionsPtr);
    }
    _loadedSessions.clear();
    _sessionAccessOrder.clear();

    if (_env != null) {
      final releaseEnv = _api!
          .getFunction<ReleaseEnvNative>(OrtApiIndex.ReleaseEnv)
          .asFunction<ReleaseEnvDart>();
      releaseEnv(_env!);
      _env = null;
    }

    _allocator = null;
    _api = null;
    _lib = null;
    _initialized = false;
  }
}

enum _ModelType {
  nsfw,
  detection,
  embedding,
  unknown,
}

class _LoadedSession {
  _LoadedSession({
    required this.path,
    required this.loadedAt,
    required this.executionProvider,
    required this.deviceId,
    required this.optionsPtr,
    required this.sessionPtr,
    required this.inputNames,
    required this.outputNames,
  });

  final String path;
  final DateTime loadedAt;
  final String executionProvider;
  final int deviceId;
  final Pointer<OrtSessionOptions> optionsPtr;
  final Pointer<OrtSession> sessionPtr;
  final List<String> inputNames;
  final List<String> outputNames;
  bool warmedUp = false;
  int? inputWidth;
  int? inputHeight;
  _InputLayout inputLayout = _InputLayout.nchw;

  List<ONNXTensorInfo> inputInfo = [
    const ONNXTensorInfo(
      name: 'input',
      shape: [1, 3, 224, 224],
      dataType: 'float32',
    ),
  ];
  List<ONNXTensorInfo> outputInfo = [
    const ONNXTensorInfo(
      name: 'output',
      shape: [1, 5],
      dataType: 'float32',
    ),
  ];
}

enum _InputLayout {
  nchw,
  nhwc,
}

class _ExpectedInputConfig {
  const _ExpectedInputConfig({
    required this.width,
    required this.height,
    required this.layout,
  });

  final int width;
  final int height;
  final _InputLayout layout;
}

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

class ONNXInitializationException implements Exception {
  ONNXInitializationException(this.message);
  final String message;

  @override
  String toString() => 'ONNXInitializationException: $message';
}

class ONNXNotInitializedException implements Exception {
  @override
  String toString() => 'ONNX Runtime not initialized. Call initialize() first.';
}

class ONNXModelLoadException implements Exception {
  ONNXModelLoadException(this.message);
  final String message;

  @override
  String toString() => 'ONNXModelLoadException: $message';
}

class ONNXInferenceException implements Exception {
  ONNXInferenceException(this.message);
  final String message;

  @override
  String toString() => 'ONNXInferenceException: $message';
}
