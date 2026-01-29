import 'dart:async';
import 'dart:ffi';
import 'dart:io';

import 'package:kidslens_video_editor/data/models/transcript.dart';
import 'package:kidslens_video_editor/native/resource_manager.dart';

/// Metadata about a loaded Whisper model
class WhisperModelInfo {
  const WhisperModelInfo({
    required this.modelPath,
    required this.modelType,
    required this.languageCount,
    required this.isMultilingual,
    required this.vocabSize,
    required this.nMels,
    required this.loadedAt,
  });

  final String modelPath;
  final String modelType;
  final int languageCount;
  final bool isMultilingual;
  final int vocabSize;
  final int nMels;
  final DateTime loadedAt;

  @override
  String toString() =>
      'WhisperModelInfo(type: $modelType, multilingual: $isMultilingual, languages: $languageCount)';
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

/// FFI bindings for whisper.cpp
class WhisperBindings extends NativeResource {
  // ignore: unused_field - Will be used when FFI is fully implemented
  DynamicLibrary? _lib;
  bool _initialized = false;
  String? _loadedModelPath;
  WhisperModelInfo? _modelInfo;
  
  /// Stream controller for streaming transcription segments
  StreamController<TranscriptionSegment>? _streamController;

  /// Initialize Whisper bindings
  Future<void> initialize() async {
    if (_initialized) return;

    try {
      _lib = _loadLibrary();
      _initialized = true;
    } catch (e) {
      throw WhisperInitializationException('Failed to load Whisper library: $e');
    }
  }

  DynamicLibrary _loadLibrary() {
    if (Platform.isWindows) {
      return DynamicLibrary.open('whisper_wrapper.dll');
    } else if (Platform.isMacOS) {
      return DynamicLibrary.open('libwhisper_wrapper.dylib');
    } else if (Platform.isLinux) {
      return DynamicLibrary.open('libwhisper_wrapper.so');
    }
    throw UnsupportedError('Platform not supported');
  }

  /// Load a Whisper model into memory for reuse
  /// 
  /// [modelPath] Path to the Whisper model file (.bin)
  /// 
  /// Implementation Plan:
  /// 1. Validate model file exists and has correct format
  /// 2. Call whisper_init_from_file() FFI function
  /// 3. Store context pointer in _modelContext field
  /// 4. Query model metadata (type, multilingual, vocab size)
  /// 5. Cache model info for getModelInfo() calls
  /// 6. Handle OOM by throwing WhisperModelLoadException
  Future<void> loadModel(String modelPath) async {
    _ensureInitialized();
    
    if (_loadedModelPath == modelPath) return;
    
    // Unload any existing model first
    if (_loadedModelPath != null) {
      await unloadModel();
    }
    
    // Validate model file exists
    final modelFile = File(modelPath);
    if (!modelFile.existsSync()) {
      throw WhisperModelLoadException('Model file not found: $modelPath');
    }
    
    try {
      // FFI Implementation Plan:
      // 1. Call: whisper_init_from_file(modelPath.toNativeUtf8())
      // 2. Check returned context is not nullptr
      // 3. Store context pointer: _modelContext = ctx
      // 4. Query model properties via whisper_model_* functions
      // 5. Build WhisperModelInfo from native metadata
      
      // Placeholder until FFI is implemented
      _loadedModelPath = modelPath;
      _modelInfo = WhisperModelInfo(
        modelPath: modelPath,
        modelType: _inferModelType(modelPath),
        languageCount: 99,
        isMultilingual: !modelPath.contains('.en.'),
        vocabSize: 51865,
        nMels: 80,
        loadedAt: DateTime.now(),
      );
    } catch (e) {
      throw WhisperModelLoadException('Failed to load model: $e');
    }
  }
  
  /// Unload the currently loaded model and free resources
  /// 
  /// Implementation Plan:
  /// 1. Check if model is loaded (_modelContext != null)
  /// 2. Call whisper_free(_modelContext) FFI function
  /// 3. Set _modelContext to null
  /// 4. Clear cached model info
  Future<void> unloadModel() async {
    if (_loadedModelPath == null) return;
    
    // FFI Implementation Plan:
    // 1. Call: whisper_free(_modelContext)
    // 2. Set _modelContext = nullptr
    
    _loadedModelPath = null;
    _modelInfo = null;
  }
  
  /// Check if a model is currently loaded
  bool isModelLoaded() => _loadedModelPath != null && _modelInfo != null;
  
  /// Get information about the currently loaded model
  /// 
  /// Returns null if no model is loaded
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

  /// Transcribe audio file using Whisper model
  /// 
  /// [audioPath] Path to the audio file (WAV, MP3, etc.)
  /// [modelPath] Path to the Whisper model (optional if model pre-loaded)
  /// [language] Language code (e.g., 'en', 'es') or null for auto-detect
  /// [translateToEnglish] If true, translates non-English to English
  /// 
  /// Implementation Plan:
  /// 1. Pre-processing:
  ///    - Load audio file using whisper_load_wav_file() or decode via FFmpeg
  ///    - Resample to 16kHz mono if necessary
  ///    - Convert to float32 PCM format
  /// 
  /// 2. Model loading:
  ///    - If modelPath provided and different from loaded, call loadModel()
  ///    - Verify model is loaded, throw if not
  /// 
  /// 3. Configure transcription parameters:
  ///    - Create whisper_full_params with whisper_full_default_params()
  ///    - Set language code if provided (params.language = language)
  ///    - Set translate flag (params.translate = translateToEnglish)
  ///    - Enable word timestamps (params.token_timestamps = true)
  ///    - Set n_threads based on CPU cores
  /// 
  /// 4. Run transcription:
  ///    - Call whisper_full(_modelContext, params, samples, n_samples)
  ///    - Check return code for errors
  /// 
  /// 5. Extract results:
  ///    - Get segment count: whisper_full_n_segments(_modelContext)
  ///    - For each segment:
  ///      - Get text: whisper_full_get_segment_text(_modelContext, i)
  ///      - Get timing: whisper_full_get_segment_t0/t1(_modelContext, i)
  ///      - Get tokens for word-level timing
  ///    - Build Transcript object from segments
  /// 
  /// 6. Error handling:
  ///    - Wrap all FFI calls in try-catch
  ///    - Convert native errors to WhisperTranscriptionException
  ///    - Clean up temporary buffers on error
  Future<Transcript> transcribe(
    String audioPath,
    String modelPath, {
    String? language,
    bool translateToEnglish = false,
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

    try {
      // Placeholder implementation - returns sample transcript
      // See implementation plan above for actual FFI integration
      final detectedLanguage = language ?? 'en';
      return Transcript(
        segments: [
          const TranscriptSegment(
            id: 'segment_0',
            text: 'Placeholder transcription',
            startTime: Duration.zero,
            endTime: Duration(seconds: 5),
            words: [
              TranscriptWord(
                word: 'Placeholder',
                startTime: Duration.zero,
                endTime: Duration(milliseconds: 500),
                confidence: 0.95,
              ),
              TranscriptWord(
                word: 'transcription',
                startTime: Duration(milliseconds: 500),
                endTime: Duration(seconds: 1),
                confidence: 0.92,
              ),
            ],
          ),
        ],
        language: detectedLanguage,
        modelId: modelPath.split('/').last,
      );
    } catch (e) {
      throw WhisperTranscriptionException('Transcription failed: $e');
    }
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

    // Whisper supports 99 languages
    return [
      'en', 'zh', 'de', 'es', 'ru', 'ko', 'fr', 'ja', 'pt', 'tr',
      'pl', 'ca', 'nl', 'ar', 'sv', 'it', 'id', 'hi', 'fi', 'vi',
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
    
    // Unload model synchronously
    _loadedModelPath = null;
    _modelInfo = null;
    
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
  String toString() => 'Whisper bindings not initialized. Call initialize() first.';
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
