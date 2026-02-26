import 'dart:async';
import 'dart:convert';
import 'dart:ffi';
import 'dart:io';

import 'package:ffi/ffi.dart';
import 'package:flutter/foundation.dart';
import 'package:kidslens_video_editor/data/models/transcript.dart';
import 'package:kidslens_video_editor/native/resource_manager.dart';
import 'package:path/path.dart' as p;

// ============================================================================
// FFI Struct Definitions
// ============================================================================

/// Native word-level timestamp info
final class WhisperWordNative extends Struct {
  @Int64()
  external int startMs;

  @Int64()
  external int endMs;

  external Pointer<Utf8> text;

  @Float()
  external double probability;
}

/// Native segment with word timestamps
final class WhisperSegmentNative extends Struct {
  @Int64()
  external int startMs;

  @Int64()
  external int endMs;

  external Pointer<Utf8> text;

  @Float()
  external double probability;

  @Int32()
  external int numWords;

  external Pointer<WhisperWordNative> words;
}

/// Native transcription result
final class WhisperResultNative extends Struct {
  @Int32()
  external int numSegments;

  external Pointer<WhisperSegmentNative> segments;

  external Pointer<Utf8> detectedLanguage;

  @Float()
  external double languageProbability;

  @Int64()
  external int processingTimeMs;

  @Bool()
  external bool success;

  external Pointer<Utf8> errorMessage;
}

/// Native configuration struct
final class WhisperConfigNative extends Struct {
  @Int32()
  external int nThreads;

  @Bool()
  external bool useGpu;

  @Int32()
  external int gpuDevice;

  external Pointer<Utf8> language;

  @Bool()
  external bool translate;

  @Bool()
  external bool wordTimestamps;

  @Float()
  external double wordThreshold;

  @Int32()
  external int maxSegmentLength;

  @Bool()
  external bool splitOnWord;

  @Float()
  external double temperature;

  @Int32()
  external int beamSize;

  @Float()
  external double entropyThreshold;

  @Bool()
  external bool suppressBlank;

  @Bool()
  external bool suppressNonSpeech;

  @Float()
  external double noSpeechThreshold;
}

/// Native model info struct
final class WhisperModelInfoNative extends Struct {
  external Pointer<Utf8> modelType;

  @Bool()
  external bool isMultilingual;

  @Bool()
  external bool usingGpu;

  @Int32()
  external int nVocab;

  @Int32()
  external int nAudioCtx;

  @Int32()
  external int nTextCtx;
}

// ============================================================================
// FFI Function Typedefs
// ============================================================================

// whisper_init
typedef WhisperInitNative = Pointer Function(Pointer<Utf8> modelPath);
typedef WhisperInitDart = Pointer Function(Pointer<Utf8> modelPath);

// whisper_init_with_config
typedef WhisperInitWithConfigNative = Pointer Function(
  Pointer<Utf8> modelPath,
  Pointer<WhisperConfigNative> config,
);
typedef WhisperInitWithConfigDart = Pointer Function(
  Pointer<Utf8> modelPath,
  Pointer<WhisperConfigNative> config,
);

// whisper_free
typedef WhisperFreeNative = Void Function(Pointer handle);
typedef WhisperFreeDart = void Function(Pointer handle);

// whisper_default_config
typedef WhisperDefaultConfigNative = WhisperConfigNative Function();
typedef WhisperDefaultConfigDart = WhisperConfigNative Function();

// whisper_transcribe_file
typedef WhisperTranscribeFileNative = Pointer<WhisperResultNative> Function(
  Pointer handle,
  Pointer<Utf8> audioPath,
  Pointer<WhisperConfigNative> config,
);
typedef WhisperTranscribeFileDart = Pointer<WhisperResultNative> Function(
  Pointer handle,
  Pointer<Utf8> audioPath,
  Pointer<WhisperConfigNative> config,
);

// whisper_transcribe_pcm
typedef WhisperTranscribePcmNative = Pointer<WhisperResultNative> Function(
  Pointer handle,
  Pointer<Float> samples,
  Int32 numSamples,
  Pointer<WhisperConfigNative> config,
);
typedef WhisperTranscribePcmDart = Pointer<WhisperResultNative> Function(
  Pointer handle,
  Pointer<Float> samples,
  int numSamples,
  Pointer<WhisperConfigNative> config,
);

// whisper_free_result
typedef WhisperFreeResultNative = Void Function(
  Pointer<WhisperResultNative> result,
);
typedef WhisperFreeResultDart = void Function(
  Pointer<WhisperResultNative> result,
);

// whisper_get_model_info
typedef WhisperGetModelInfoNative = WhisperModelInfoNative Function(
  Pointer handle,
);
typedef WhisperGetModelInfoDart = WhisperModelInfoNative Function(
  Pointer handle,
);

// whisper_get_error
typedef WhisperGetErrorNative = Pointer<Utf8> Function();
typedef WhisperGetErrorDart = Pointer<Utf8> Function();

// whisper_gpu_available
typedef WhisperGpuAvailableNative = Bool Function();
typedef WhisperGpuAvailableDart = bool Function();

// whisper_gpu_name
typedef WhisperGpuNameNative = Pointer<Utf8> Function();
typedef WhisperGpuNameDart = Pointer<Utf8> Function();

// whisper_version
typedef WhisperVersionNative = Pointer<Utf8> Function();
typedef WhisperVersionDart = Pointer<Utf8> Function();

// whisper_supported_languages
typedef WhisperSupportedLanguagesNative = Pointer<Utf8> Function(
  Pointer handle,
);
typedef WhisperSupportedLanguagesDart = Pointer<Utf8> Function(Pointer handle);

// ============================================================================
// Metadata Classes
// ============================================================================

/// Metadata about a loaded Whisper model
class WhisperModelInfo {
  const WhisperModelInfo({
    required this.modelPath,
    required this.modelType,
    required this.languageCount,
    required this.isMultilingual,
    required this.usingGpu,
    required this.vocabSize,
    required this.nMels,
    required this.loadedAt,
  });

  final String modelPath;
  final String modelType;
  final int languageCount;
  final bool isMultilingual;
  final bool usingGpu;
  final int vocabSize;
  final int nMels;
  final DateTime loadedAt;

  @override
  String toString() =>
      'WhisperModelInfo(type: $modelType, gpu: $usingGpu, multilingual: $isMultilingual, languages: $languageCount)';
}

/// A single transcription segment for streaming
class TranscriptionSegment {
  const TranscriptionSegment({
    required this.text,
    required this.startTime,
    required this.endTime,
    required this.isFinal,
    this.language,
    this.probability = 1.0,
  });

  final String text;
  final Duration startTime;
  final Duration endTime;
  final bool isFinal;
  final String? language;
  final double probability;
}

// ============================================================================
// WhisperBindings - FFI-based Whisper Integration
// ============================================================================

/// FFI bindings for whisper.cpp native library.
/// Provides direct integration with Whisper speech recognition without CLI tools.
class WhisperBindings extends NativeResource {
  DynamicLibrary? _lib;
  bool _initialized = false;
  Pointer? _modelHandle;
  String? _loadedModelPath;
  WhisperModelInfo? _modelInfo;

  /// The resolved path to the native library, set after successful loading
  String? _nativeLibraryPath;

  /// Get the resolved native library path (available after [initialize])
  String? get nativeLibraryPath => _nativeLibraryPath;

  // FFI function pointers
  WhisperInitDart? _whisperInit;
  WhisperFreeDart? _whisperFree;
  WhisperTranscribeFileDart? _whisperTranscribeFile;
  WhisperFreeResultDart? _whisperFreeResult;
  WhisperGetModelInfoDart? _whisperGetModelInfo;
  WhisperGetErrorDart? _whisperGetError;
  WhisperGpuAvailableDart? _whisperGpuAvailable;
  WhisperGpuNameDart? _whisperGpuName;
  WhisperVersionDart? _whisperVersion;
  WhisperSupportedLanguagesDart? _whisperSupportedLanguages;

  /// Stream controller for streaming transcription segments
  StreamController<TranscriptionSegment>? _streamController;

  /// Whether FFI library is loaded and available
  bool get hasNativeSupport => _lib != null && _whisperInit != null;

  /// Whether GPU acceleration is available in the loaded native library
  bool get isGpuAvailable => _whisperGpuAvailable?.call() ?? false;

  /// GPU backend name reported by native library (e.g., CUDA, Vulkan, Metal)
  String? get gpuBackendName {
    final ptr = _whisperGpuName?.call();
    if (ptr == null || ptr == nullptr) return null;
    return ptr.toDartString();
  }

  /// Initialize Whisper bindings by loading the native library
  Future<void> initialize() async {
    if (_initialized) return;

    try {
      _lib = _loadNativeLibrary();

      if (_lib != null) {
        _bindFunctions();
        debugPrint('Whisper FFI library loaded successfully');
        debugPrint('Whisper native library path: ${_nativeLibraryPath ?? 'unknown'}');
        debugPrint('GPU available: ${_whisperGpuAvailable?.call() ?? false}');

        final gpuName = _whisperGpuName?.call();
        if (gpuName != null && gpuName != nullptr) {
          debugPrint('GPU: ${gpuName.toDartString()}');
        }

        final version = _whisperVersion?.call();
        if (version != null && version != nullptr) {
          debugPrint('Whisper version: ${version.toDartString()}');
        }
      }

      _initialized = true;
    } catch (e) {
      // Library not found - will use fallback mode
      debugPrint('Whisper native library not found: $e');
      _initialized = true; // Still mark as initialized for fallback mode
    }
  }

  /// Load the native whisper wrapper library
  DynamicLibrary? _loadNativeLibrary() {
    try {
      if (Platform.isWindows) {
        final cwd = Directory.current.path;
        final exeDir = p.dirname(Platform.resolvedExecutable);

        // Try to find library in various locations
        final possiblePaths = [
          p.join(cwd, 'build', 'windows', 'x64-vs17', 'runner', 'Debug', 'whisper_wrapper.dll'),
          p.join(cwd, 'build', 'windows', 'x64-vs17', 'runner', 'Release', 'whisper_wrapper.dll'),
          p.join(exeDir, '..', '..', '..', 'x64-vs17', 'runner', 'Debug', 'whisper_wrapper.dll'),
          p.join(exeDir, '..', '..', '..', 'x64-vs17', 'runner', 'Release', 'whisper_wrapper.dll'),
          'whisper_wrapper.dll',
          'data/flutter_assets/native/whisper_wrapper.dll',
          '$exeDir/whisper_wrapper.dll',
          '$exeDir/data/flutter_assets/native/whisper_wrapper.dll',
        ];

        for (final libPath in possiblePaths) {
          try {
            final lib = DynamicLibrary.open(libPath);
            _nativeLibraryPath = libPath;
            return lib;
          } catch (_) {
            continue;
          }
        }
        return null;
      } else if (Platform.isMacOS) {
        final possiblePaths = [
          'libwhisper_wrapper.dylib',
          '@executable_path/../Frameworks/libwhisper_wrapper.dylib',
          '/usr/local/lib/libwhisper_wrapper.dylib',
        ];

        for (final libPath in possiblePaths) {
          try {
            final lib = DynamicLibrary.open(libPath);
            _nativeLibraryPath = libPath;
            return lib;
          } catch (_) {
            continue;
          }
        }
        return null;
      } else if (Platform.isLinux) {
        final possiblePaths = [
          'libwhisper_wrapper.so',
          './lib/libwhisper_wrapper.so',
          '/usr/local/lib/libwhisper_wrapper.so',
          '/usr/lib/libwhisper_wrapper.so',
        ];

        for (final libPath in possiblePaths) {
          try {
            final lib = DynamicLibrary.open(libPath);
            _nativeLibraryPath = libPath;
            return lib;
          } catch (_) {
            continue;
          }
        }
        return null;
      }
    } catch (e) {
      debugPrint('Failed to load Whisper native library: $e');
    }
    return null;
  }

  /// Bind all FFI functions from the library
  void _bindFunctions() {
    if (_lib == null) return;

    // All functions use 'kl_whisper_' prefix to avoid conflicts with whisper.cpp
    _whisperInit = _lib!
        .lookup<NativeFunction<WhisperInitNative>>('kl_whisper_init')
        .asFunction();

    _whisperFree = _lib!
        .lookup<NativeFunction<WhisperFreeNative>>('kl_whisper_free')
        .asFunction();

    _whisperTranscribeFile = _lib!
        .lookup<NativeFunction<WhisperTranscribeFileNative>>(
            'kl_whisper_transcribe_file',)
        .asFunction();

    _whisperFreeResult = _lib!
        .lookup<NativeFunction<WhisperFreeResultNative>>(
            'kl_whisper_free_result',)
        .asFunction();

    _whisperGetModelInfo = _lib!
        .lookup<NativeFunction<WhisperGetModelInfoNative>>(
            'kl_whisper_get_model_info',)
        .asFunction();

    _whisperGetError = _lib!
        .lookup<NativeFunction<WhisperGetErrorNative>>('kl_whisper_get_error')
        .asFunction();

    _whisperGpuAvailable = _lib!
        .lookup<NativeFunction<WhisperGpuAvailableNative>>(
            'kl_whisper_gpu_available',)
        .asFunction();

    _whisperGpuName = _lib!
        .lookup<NativeFunction<WhisperGpuNameNative>>('kl_whisper_gpu_name')
        .asFunction();

    _whisperVersion = _lib!
        .lookup<NativeFunction<WhisperVersionNative>>('kl_whisper_version')
        .asFunction();

    _whisperSupportedLanguages = _lib!
        .lookup<NativeFunction<WhisperSupportedLanguagesNative>>(
            'kl_whisper_supported_languages',)
        .asFunction();
  }

  /// Load a Whisper model into memory for reuse
  ///
  /// [modelPath] Path to the Whisper model file (.bin/.ggml)
  Future<void> loadModel(String modelPath) async {
    _ensureInitialized();

    if (_loadedModelPath == modelPath && _modelHandle != null) return;

    // Unload any existing model first
    if (_loadedModelPath != null) {
      await unloadModel();
    }

    // Validate model file exists
    final modelFile = File(modelPath);
    if (!modelFile.existsSync()) {
      throw WhisperModelLoadException('Model file not found: $modelPath');
    }

    // Use FFI if available
    if (hasNativeSupport && _whisperInit != null) {
      final modelPathPtr = modelPath.toNativeUtf8();
      try {
        _modelHandle = _whisperInit!(modelPathPtr);

        if (_modelHandle == null || _modelHandle == nullptr) {
          final errorPtr = _whisperGetError?.call();
          final error = errorPtr != null && errorPtr != nullptr
              ? errorPtr.toDartString()
              : 'Unknown error';
          throw WhisperModelLoadException('Failed to load model: $error');
        }

        // Get model info from native
        if (_whisperGetModelInfo != null) {
          final nativeInfo = _whisperGetModelInfo!(_modelHandle!);
          final modelType = nativeInfo.modelType != nullptr
              ? nativeInfo.modelType.toDartString()
              : _inferModelType(modelPath);

          _modelInfo = WhisperModelInfo(
            modelPath: modelPath,
            modelType: modelType,
            languageCount: nativeInfo.isMultilingual ? 99 : 1,
            isMultilingual: nativeInfo.isMultilingual,
            usingGpu: nativeInfo.usingGpu,
            vocabSize: nativeInfo.nVocab,
            nMels: 80, // Standard for all Whisper models
            loadedAt: DateTime.now(),
          );
        } else {
          _modelInfo = _createFallbackModelInfo(modelPath);
        }

        _loadedModelPath = modelPath;
        debugPrint('Model loaded: ${_modelInfo?.modelType} (GPU: ${_modelInfo?.usingGpu})');
      } finally {
        malloc.free(modelPathPtr);
      }
    } else {
      // Fallback: just validate file and create metadata
      _loadedModelPath = modelPath;
      _modelInfo = _createFallbackModelInfo(modelPath);
    }
  }

  /// Create fallback model info when FFI is not available
  WhisperModelInfo _createFallbackModelInfo(String modelPath) => WhisperModelInfo(
      modelPath: modelPath,
      modelType: _inferModelType(modelPath),
      languageCount: 99,
      isMultilingual: !modelPath.contains('.en.'),
      usingGpu: false, // Fallback mode doesn't use GPU
      vocabSize: 51865,
      nMels: 80,
      loadedAt: DateTime.now(),
    );

  /// Unload the currently loaded model and free resources
  Future<void> unloadModel() async {
    if (_modelHandle != null && _whisperFree != null) {
      _whisperFree!(_modelHandle!);
    }

    _modelHandle = null;
    _loadedModelPath = null;
    _modelInfo = null;
  }

  /// Check if a model is currently loaded
  bool isModelLoaded() => _loadedModelPath != null && _modelInfo != null;

  /// Get information about the currently loaded model
  WhisperModelInfo? getModelInfo() => _modelInfo;

  String _inferModelType(String modelPath) {
    final filename = modelPath.split(Platform.pathSeparator).last.toLowerCase();
    if (filename.contains('tiny')) return 'tiny';
    if (filename.contains('base')) return 'base';
    if (filename.contains('small')) return 'small';
    if (filename.contains('medium')) return 'medium';
    if (filename.contains('large-v3')) return 'large-v3';
    if (filename.contains('large-v2')) return 'large-v2';
    if (filename.contains('large')) return 'large';
    return 'unknown';
  }

  /// Transcribe audio file using Whisper model via FFI
  ///
  /// [audioPath] Path to the audio file (WAV format preferred, 16kHz mono)
  /// [modelPath] Path to the Whisper model
  /// [language] Language code (e.g., 'en', 'es') or null for auto-detect
  /// [translateToEnglish] If true, translates non-English to English
  Future<Transcript> transcribe(
    String audioPath,
    String modelPath, {
    String? language,
    bool translateToEnglish = false,
    Duration? mediaDuration,
    bool useGpu = true,
    int gpuDeviceIndex = 0,
    int nThreads = 0,
    int beamSize = 5,
  }) async {
    _ensureInitialized();

    // Ensure model is loaded
    if (!isModelLoaded() || _loadedModelPath != modelPath) {
      await loadModel(modelPath);
    }

    // Validate audio file exists
    final audioFile = File(audioPath);
    if (!audioFile.existsSync()) {
      throw WhisperTranscriptionException('Audio file not found: $audioPath');
    }

    // Use FFI transcription if available
    if (hasNativeSupport &&
        _modelHandle != null &&
        _whisperTranscribeFile != null) {
      return _transcribeWithFfi(
        audioPath,
        language: language,
        translateToEnglish: translateToEnglish,
        useGpu: useGpu,
        gpuDeviceIndex: gpuDeviceIndex,
        nThreads: nThreads,
        beamSize: beamSize,
      );
    }

    // Fall back to placeholder if FFI is not available
    return _generatePlaceholderTranscript(
      audioPath,
      modelPath,
      language: language,
      mediaDuration: mediaDuration,
    );
  }

  /// Transcribe using FFI (native library)
  Future<Transcript> _transcribeWithFfi(
    String audioPath, {
    String? language,
    bool translateToEnglish = false,
    bool useGpu = true,
    int gpuDeviceIndex = 0,
    int nThreads = 0,
    int beamSize = 5,
  }) async {
    // Create config
    final configPtr = calloc<WhisperConfigNative>();
    final audioPathPtr = audioPath.toNativeUtf8();
    Pointer<Utf8>? languagePtr;

    try {
      // Fill config
      final config = configPtr.ref
        ..nThreads = nThreads > 0 ? nThreads : Platform.numberOfProcessors.clamp(1, 8)
        ..useGpu = useGpu
        ..gpuDevice = gpuDeviceIndex < 0 ? 0 : gpuDeviceIndex
        ..translate = translateToEnglish
        ..wordTimestamps = true
        ..wordThreshold = 0.01
        ..maxSegmentLength = 0
        ..splitOnWord = true
        ..temperature = 0.0
        ..beamSize = beamSize
        ..entropyThreshold = 2.4
        ..suppressBlank = true
        ..suppressNonSpeech = true
        ..noSpeechThreshold = 0.6;

      if (language != null && language != 'auto') {
        languagePtr = language.toNativeUtf8();
        config.language = languagePtr;
      } else {
        config.language = nullptr;
      }

      debugPrint('Transcribing: $audioPath');
      final stopwatch = Stopwatch()..start();

      // Call native transcription
      final resultPtr = _whisperTranscribeFile!(
        _modelHandle!,
        audioPathPtr,
        configPtr,
      );

      stopwatch.stop();
      debugPrint('Transcription completed in ${stopwatch.elapsedMilliseconds}ms');

      if (resultPtr == nullptr) {
        final errorPtr = _whisperGetError?.call();
        final error = errorPtr != null && errorPtr != nullptr
            ? errorPtr.toDartString()
            : 'Unknown transcription error';
        throw WhisperTranscriptionException(error);
      }

      try {
        final result = resultPtr.ref;

        if (!result.success) {
          final error = result.errorMessage != nullptr
              ? result.errorMessage.toDartString()
              : 'Transcription failed';
          throw WhisperTranscriptionException(error);
        }

        // Convert native result to Transcript
        return _convertNativeResult(resultPtr, _loadedModelPath!);
      } finally {
        // Free native result
        _whisperFreeResult?.call(resultPtr);
      }
    } finally {
      calloc.free(configPtr);
      malloc.free(audioPathPtr);
      if (languagePtr != null) {
        malloc.free(languagePtr);
      }
    }
  }

  /// Convert native WhisperResult to Dart Transcript
  Transcript _convertNativeResult(
    Pointer<WhisperResultNative> resultPtr,
    String modelPath,
  ) {
    final result = resultPtr.ref;
    final segments = <TranscriptSegment>[];

    for (var i = 0; i < result.numSegments; i++) {
      final nativeSeg = (result.segments + i).ref;

      // Extract words
      final words = <TranscriptWord>[];
      for (var j = 0; j < nativeSeg.numWords; j++) {
        final nativeWord = (nativeSeg.words + j).ref;
        words.add(
          TranscriptWord(
            word: nativeWord.text != nullptr
                ? _safeUtf8(nativeWord.text)
                : '',
            startTime: Duration(milliseconds: nativeWord.startMs),
            endTime: Duration(milliseconds: nativeWord.endMs),
            confidence: nativeWord.probability,
          ),
        );
      }

      segments.add(
        TranscriptSegment(
          id: 'segment_$i',
          text: nativeSeg.text != nullptr ? _safeUtf8(nativeSeg.text) : '',
          startTime: Duration(milliseconds: nativeSeg.startMs),
          endTime: Duration(milliseconds: nativeSeg.endMs),
          words: words,
        ),
      );
    }

    final detectedLanguage = result.detectedLanguage != nullptr
        ? _safeUtf8(result.detectedLanguage)
        : 'en';

    return Transcript(
      segments: segments,
      language: detectedLanguage,
      modelId: p.basename(modelPath),
    );
  }

  /// Generate placeholder transcript when FFI is not available
  Transcript _generatePlaceholderTranscript(
    String audioPath,
    String modelPath, {
    String? language,
    Duration? mediaDuration,
  }) {
    final audioFile = File(audioPath);
    final detectedLanguage = language ?? 'en';

    // Estimate duration from file size if not provided
    Duration estimatedDuration;
    if (mediaDuration != null && mediaDuration.inSeconds > 0) {
      estimatedDuration = mediaDuration;
    } else {
      final fileSize = audioFile.lengthSync();
      final estimatedSeconds = (fileSize / 16000).clamp(5, 3600).toInt();
      estimatedDuration = Duration(seconds: estimatedSeconds);
    }

    // Generate placeholder segments (one every ~5 seconds)
    const segmentDuration = Duration(seconds: 5);
    final segments = <TranscriptSegment>[];
    final placeholderTexts = [
      '[Native library not loaded - placeholder mode]',
      'Build whisper_wrapper native library for real transcription.',
      'See native/whisper/README.md for build instructions.',
      'Audio content would be transcribed here.',
      'Speech recognition requires the native whisper_wrapper library.',
    ];

    var currentTime = Duration.zero;
    var segmentIndex = 0;

    while (currentTime < estimatedDuration) {
      final segmentEnd = currentTime + segmentDuration;
      final actualEnd =
          segmentEnd > estimatedDuration ? estimatedDuration : segmentEnd;

      if (actualEnd.inMilliseconds - currentTime.inMilliseconds >= 500) {
        final text = placeholderTexts[segmentIndex % placeholderTexts.length];
        segments.add(
          TranscriptSegment(
            id: 'segment_$segmentIndex',
            text: text,
            startTime: currentTime,
            endTime: actualEnd,
            words: _generatePlaceholderWords(text, currentTime, actualEnd),
          ),
        );
      }

      currentTime = segmentEnd;
      segmentIndex++;
    }

    if (segments.isEmpty) {
      segments.add(
        TranscriptSegment(
          id: 'segment_0',
          text: '[Native library not loaded - build for real transcription]',
          startTime: Duration.zero,
          endTime: estimatedDuration,
          words: const [],
        ),
      );
    }

    return Transcript(
      segments: segments,
      language: detectedLanguage,
      modelId: p.basename(modelPath),
    );
  }

  /// Generate placeholder words for a segment
  List<TranscriptWord> _generatePlaceholderWords(
    String text,
    Duration startTime,
    Duration endTime,
  ) {
    final words = text.split(' ');
    if (words.isEmpty) return const [];

    final totalDuration = endTime - startTime;
    final wordDuration = totalDuration ~/ words.length;

    return List.generate(words.length, (index) {
      final wordStart = startTime + (wordDuration * index);
      final wordEnd =
          index == words.length - 1 ? endTime : wordStart + wordDuration;

      return TranscriptWord(
        word: words[index],
        startTime: wordStart,
        endTime: wordEnd,
        confidence: 0.9,
      );
    });
  }

  /// Transcribe audio with streaming results
  ///
  /// Yields TranscriptionSegment objects as they become available.
  /// This enables real-time display of transcription progress.
  ///
  /// [audioPath] Path to the audio file
  /// [modelPath] Path to the Whisper model
  /// [language] Language code or null for auto-detect
  ///
  /// Implementation Plan:
  /// 1. Set up streaming callback:
  ///    - Create whisper_full_params with segment callback
  ///    - Register Dart callback via NativeCallable
  ///    - Callback receives segment data as it's processed
  ///
  /// 2. Callback handling:
  ///    - On each segment callback from whisper.cpp:
  ///      - Extract segment text and timing
  ///      - Create TranscriptionSegment with isFinal = true for completed
  ///      - Add to StreamController
  ///
  /// 3. Run transcription in isolate:
  ///    - Use compute() or Isolate.spawn() to avoid blocking UI
  ///    - Pass stream controller sink to isolate
  ///    - Isolate runs whisper_full() with streaming params
  ///
  /// 4. Stream management:
  ///    - Return stream that client can listen to
  ///    - Handle cancellation via stream subscription
  ///    - Close stream controller when transcription completes
  ///
  /// 5. Error handling:
  ///    - Add errors to stream via addError()
  ///    - Clean up resources on error or cancellation
  Stream<TranscriptionSegment> transcribeStream(
    String audioPath,
    String modelPath, {
    String? language,
  }) async* {
    _ensureInitialized();

    // Ensure model is loaded
    if (!isModelLoaded() || _loadedModelPath != modelPath) {
      await loadModel(modelPath);
    }

    // Validate audio file exists
    final audioFile = File(audioPath);
    if (!audioFile.existsSync()) {
      throw WhisperTranscriptionException('Audio file not found: $audioPath');
    }

    // Create stream controller for yielding segments
    _streamController = StreamController<TranscriptionSegment>();

    try {
      // Placeholder: Simulate streaming transcription
      // In real implementation, this would use FFI callbacks
      final segments = [
        TranscriptionSegment(
          text: 'Hello',
          startTime: Duration.zero,
          endTime: const Duration(milliseconds: 500),
          isFinal: true,
          language: language ?? 'en',
          probability: 0.95,
        ),
        TranscriptionSegment(
          text: 'world',
          startTime: const Duration(milliseconds: 500),
          endTime: const Duration(seconds: 1),
          isFinal: true,
          language: language ?? 'en',
          probability: 0.92,
        ),
      ];

      for (final segment in segments) {
        yield segment;
        await Future<void>.delayed(const Duration(milliseconds: 100));
      }
    } finally {
      await _streamController?.close();
      _streamController = null;
    }
  }

  /// Get available languages for a model
  Future<List<String>> getSupportedLanguages(String modelPath) async {
    _ensureInitialized();

    // Try to get from native library if available
    if (hasNativeSupport &&
        _modelHandle != null &&
        _whisperSupportedLanguages != null) {
      final langsPtr = _whisperSupportedLanguages!(_modelHandle!);
      if (langsPtr != nullptr) {
        final langsStr = _safeUtf8(langsPtr);
        return langsStr.split(',').where((l) => l.isNotEmpty).toList();
      }
    }

    // Fallback: Whisper supports 99 languages
    return [
      'en',
      'zh',
      'de',
      'es',
      'ru',
      'ko',
      'fr',
      'ja',
      'pt',
      'tr',
      'pl',
      'ca',
      'nl',
      'ar',
      'sv',
      'it',
      'id',
      'hi',
      'fi',
      'vi',
    ];
  }

  void _ensureInitialized() {
    if (!_initialized) {
      throw WhisperNotInitializedException();
    }
  }

  @override
  void releaseNative() {
    // Clean up stream controller if active
    _streamController?.close();
    _streamController = null;

    // Free model via FFI if loaded
    if (_modelHandle != null && _whisperFree != null) {
      _whisperFree!(_modelHandle!);
      _modelHandle = null;
    }

    _loadedModelPath = null;
    _modelInfo = null;

    // Clear function pointers
    _whisperInit = null;
    _whisperFree = null;
    _whisperTranscribeFile = null;
    _whisperFreeResult = null;
    _whisperGetModelInfo = null;
    _whisperGetError = null;
    _whisperGpuAvailable = null;
    _whisperGpuName = null;
    _whisperVersion = null;
    _whisperSupportedLanguages = null;

    _lib = null;
    _initialized = false;
  }
}

/// Exception thrown when Whisper initialization fails
class WhisperInitializationException implements Exception {
  WhisperInitializationException(this.message);

  final String message;

  @override
  String toString() => 'WhisperInitializationException: $message';
}

/// Exception thrown when Whisper is not initialized
class WhisperNotInitializedException implements Exception {
  @override
  String toString() =>
      'Whisper bindings not initialized. Call initialize() first.';
}

/// Exception thrown when model loading fails
class WhisperModelLoadException implements Exception {
  WhisperModelLoadException(this.message);

  final String message;

  @override
  String toString() => 'WhisperModelLoadException: $message';
}

/// Exception thrown when transcription fails
class WhisperTranscriptionException implements Exception {
  WhisperTranscriptionException(this.message);

  final String message;

  @override
  String toString() => 'WhisperTranscriptionException: $message';
}

/// Decode a native UTF-8 pointer without throwing on malformed bytes.
///
/// Whisper may return strings containing partial multi-byte sequences
/// (especially for auto-detected language codes from English-only models).
/// This replaces invalid bytes with the Unicode replacement character instead
/// of throwing a [FormatException].
String _safeUtf8(Pointer<Utf8> ptr) {
  var len = 0;
  while ((ptr.cast<Uint8>() + len).value != 0) {
    len++;
  }
  final bytes = ptr.cast<Uint8>().asTypedList(len);
  return utf8.decode(bytes, allowMalformed: true);
}
