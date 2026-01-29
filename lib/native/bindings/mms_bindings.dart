import 'dart:ffi';
import 'dart:io';

import 'package:kidslens_video_editor/data/models/transcript.dart';
import 'package:kidslens_video_editor/native/resource_manager.dart';

/// Language detection result with confidence score
class LanguageDetectionResult {
  const LanguageDetectionResult({
    required this.languageCode,
    required this.confidence,
    this.languageName,
    this.alternativeLanguages = const [],
  });

  /// ISO 639-3 language code (e.g., 'eng', 'spa', 'fra')
  final String languageCode;
  
  /// Confidence score between 0.0 and 1.0
  final double confidence;
  
  /// Human-readable language name (e.g., 'English', 'Spanish')
  final String? languageName;
  
  /// Alternative detected languages sorted by confidence (descending)
  final List<LanguageDetectionResult> alternativeLanguages;
  
  @override
  String toString() => 
      'LanguageDetectionResult($languageCode, confidence: ${(confidence * 100).toStringAsFixed(1)}%)';
}

/// Supported language information
class MMSLanguageInfo {
  const MMSLanguageInfo({
    required this.code,
    required this.name,
    required this.nativeName,
    this.script,
    this.region,
  });

  /// ISO 639-3 language code
  final String code;
  
  /// English name of the language
  final String name;
  
  /// Native name of the language
  final String nativeName;
  
  /// Writing script (e.g., 'Latin', 'Arabic', 'Devanagari')
  final String? script;
  
  /// Geographic region where primarily spoken
  final String? region;
}

/// FFI bindings for Meta MMS (Massively Multilingual Speech)
class MMSBindings extends NativeResource {
  // ignore: unused_field - Will be used when FFI is fully implemented
  DynamicLibrary? _lib;
  bool _initialized = false;
  
  /// Cached supported languages list
  List<MMSLanguageInfo>? _supportedLanguagesCache;

  /// Initialize MMS bindings
  /// 
  /// Implementation Plan:
  /// 1. Load MMS wrapper shared library
  /// 2. Initialize PyTorch/ONNX runtime for model inference
  /// 3. Set up audio processing pipeline (resampling, feature extraction)
  /// 4. Allocate memory for model caching
  /// 5. Configure language detection model if available
  Future<void> initialize() async {
    if (_initialized) return;

    try {
      _lib = _loadLibrary();
      
      // FFI Implementation Plan:
      // 1. Load mms_wrapper library with FFI
      // 2. Call mms_init() to initialize runtime
      // 3. Set up feature extractor (wav2vec2 compatible)
      // 4. Pre-load language detection model if available
      // 5. Cache common model weights if memory permits
      
      _initialized = true;
    } catch (e) {
      throw MMSInitializationException('Failed to load MMS library: $e');
    }
  }

  DynamicLibrary _loadLibrary() {
    if (Platform.isWindows) {
      return DynamicLibrary.open('mms_wrapper.dll');
    } else if (Platform.isMacOS) {
      return DynamicLibrary.open('libmms_wrapper.dylib');
    } else if (Platform.isLinux) {
      return DynamicLibrary.open('libmms_wrapper.so');
    }
    throw UnsupportedError('Platform not supported');
  }

  /// Transcribe audio file using MMS model with auto language detection
  /// 
  /// Implementation Plan:
  /// 1. Load and validate audio file:
  ///    - Support formats: WAV, MP3, FLAC, OGG
  ///    - Resample to 16kHz mono using libsamplerate
  ///    - Convert to float32 PCM
  /// 
  /// 2. Language detection (if language not specified):
  ///    - Run detectLanguage() to get most likely language
  ///    - Use result to select appropriate ASR model
  ///    - Log detected language for debugging
  /// 
  /// 3. Load appropriate MMS-ASR model:
  ///    - Model path format: mms-1b-all for multilingual
  ///    - Or language-specific: mms-1b-{lang}
  ///    - Cache loaded model for subsequent calls
  /// 
  /// 4. Run ASR inference:
  ///    - Extract audio features using processor
  ///    - Pass through wav2vec2-based encoder
  ///    - Decode with CTC to get text
  /// 
  /// 5. Post-process results:
  ///    - Apply word-piece to word conversion
  ///    - Calculate word timestamps from CTC alignment
  ///    - Estimate confidence from softmax probabilities
  ///    - Build Transcript object with segments and words
  /// 
  /// 6. Error handling:
  ///    - Wrap all operations in try-catch
  ///    - Return meaningful error messages
  ///    - Clean up temporary resources on failure
  Future<Transcript> transcribe(
    String audioPath,
    String modelPath, {
    String? language,
  }) async {
    _ensureInitialized();
    
    // Validate audio file exists
    final audioFile = File(audioPath);
    if (!audioFile.existsSync()) {
      throw MMSTranscriptionException('Audio file not found: $audioPath');
    }

    try {
      // Detect language if not provided
      var detectedLanguage = language ?? 'en';
      if (language == null) {
        final detection = await detectLanguage(audioPath, modelPath);
        detectedLanguage = detection.languageCode;
      }
      
      // Placeholder implementation - returns sample transcript
      // See implementation plan above for actual FFI integration
      return Transcript(
        segments: [
          const TranscriptSegment(
            id: 'segment_0',
            text: 'Placeholder MMS transcription',
            startTime: Duration.zero,
            endTime: Duration(seconds: 5),
            words: [
              TranscriptWord(
                word: 'Placeholder',
                startTime: Duration.zero,
                endTime: Duration(milliseconds: 500),
                confidence: 0.90,
              ),
              TranscriptWord(
                word: 'MMS',
                startTime: Duration(milliseconds: 500),
                endTime: Duration(milliseconds: 750),
                confidence: 0.88,
              ),
              TranscriptWord(
                word: 'transcription',
                startTime: Duration(milliseconds: 750),
                endTime: Duration(seconds: 1),
                confidence: 0.91,
              ),
            ],
          ),
        ],
        language: detectedLanguage,
        modelId: modelPath.split('/').last,
      );
    } catch (e) {
      throw MMSTranscriptionException('Transcription failed: $e');
    }
  }
  
  /// Transcribe audio with explicit language specification
  /// 
  /// Use this when you know the exact language of the audio.
  /// More efficient than auto-detection as it skips language identification.
  /// 
  /// [audioPath] Path to the audio file
  /// [modelPath] Path to the MMS model directory
  /// [languageCode] ISO 639-3 language code (e.g., 'eng', 'spa', 'ara')
  /// 
  /// Implementation Plan:
  /// 1. Validate languageCode is supported:
  ///    - Check against getSupportedLanguages() list
  ///    - Throw MMSUnsupportedLanguageException if not found
  /// 
  /// 2. Load language-specific model adapter:
  ///    - MMS uses adapters for each language
  ///    - Load adapter weights from modelPath/adapters/{lang}.bin
  ///    - Cache adapter for reuse
  /// 
  /// 3. Configure vocabulary for language:
  ///    - Load character/token vocabulary for target language
  ///    - Set up CTC decoder with language-specific tokens
  /// 
  /// 4. Run transcription pipeline:
  ///    - Pre-process audio (same as transcribe())
  ///    - Forward through shared encoder
  ///    - Apply language-specific adapter
  ///    - Decode with language vocabulary
  /// 
  /// 5. Return transcript with specified language
  Future<Transcript> transcribeWithLanguage(
    String audioPath,
    String modelPath,
    String languageCode,
  ) async {
    _ensureInitialized();
    
    // Validate language is supported
    final supported = await getSupportedLanguages(modelPath);
    final isSupported = supported.any((lang) => lang.code == languageCode);
    if (!isSupported) {
      throw MMSUnsupportedLanguageException(
        'Language not supported: $languageCode. '
        'Use getSupportedLanguages() to see available languages.',
      );
    }
    
    // Use main transcribe with explicit language
    return transcribe(audioPath, modelPath, language: languageCode);
  }

  /// Get list of all supported languages (MMS supports 1,100+)
  /// 
  /// Returns cached list on subsequent calls.
  /// 
  /// Implementation Plan:
  /// 1. Check if _supportedLanguagesCache is populated
  /// 2. If not, query model for supported languages:
  ///    - Read languages.json from model directory
  ///    - Parse language metadata (code, name, native name)
  ///    - Build MMSLanguageInfo list
  /// 3. Cache result for future calls
  /// 4. Return sorted by language name
  Future<List<MMSLanguageInfo>> getSupportedLanguages(String modelPath) async {
    _ensureInitialized();
    
    // Return cached list if available
    if (_supportedLanguagesCache != null) {
      return _supportedLanguagesCache!;
    }

    // FFI Implementation Plan:
    // 1. Read modelPath/languages.json or query model metadata
    // 2. Parse JSON to extract language entries
    // 3. Build MMSLanguageInfo objects with full metadata
    // 4. Sort by language name for consistent ordering

    // Placeholder: return common languages with full info
    _supportedLanguagesCache = [
      const MMSLanguageInfo(code: 'eng', name: 'English', nativeName: 'English', script: 'Latin'),
      const MMSLanguageInfo(code: 'spa', name: 'Spanish', nativeName: 'Español', script: 'Latin'),
      const MMSLanguageInfo(code: 'fra', name: 'French', nativeName: 'Français', script: 'Latin'),
      const MMSLanguageInfo(code: 'deu', name: 'German', nativeName: 'Deutsch', script: 'Latin'),
      const MMSLanguageInfo(code: 'ita', name: 'Italian', nativeName: 'Italiano', script: 'Latin'),
      const MMSLanguageInfo(code: 'por', name: 'Portuguese', nativeName: 'Português', script: 'Latin'),
      const MMSLanguageInfo(code: 'rus', name: 'Russian', nativeName: 'Русский', script: 'Cyrillic'),
      const MMSLanguageInfo(code: 'zho', name: 'Chinese', nativeName: '中文', script: 'Han'),
      const MMSLanguageInfo(code: 'jpn', name: 'Japanese', nativeName: '日本語', script: 'Kana/Kanji'),
      const MMSLanguageInfo(code: 'kor', name: 'Korean', nativeName: '한국어', script: 'Hangul'),
      const MMSLanguageInfo(code: 'ara', name: 'Arabic', nativeName: 'العربية', script: 'Arabic'),
      const MMSLanguageInfo(code: 'hin', name: 'Hindi', nativeName: 'हिन्दी', script: 'Devanagari'),
      const MMSLanguageInfo(code: 'ben', name: 'Bengali', nativeName: 'বাংলা', script: 'Bengali'),
      const MMSLanguageInfo(code: 'pan', name: 'Punjabi', nativeName: 'ਪੰਜਾਬੀ', script: 'Gurmukhi'),
      const MMSLanguageInfo(code: 'jav', name: 'Javanese', nativeName: 'Basa Jawa', script: 'Latin'),
      const MMSLanguageInfo(code: 'tel', name: 'Telugu', nativeName: 'తెలుగు', script: 'Telugu'),
      const MMSLanguageInfo(code: 'mar', name: 'Marathi', nativeName: 'मराठी', script: 'Devanagari'),
      const MMSLanguageInfo(code: 'tam', name: 'Tamil', nativeName: 'தமிழ்', script: 'Tamil'),
      const MMSLanguageInfo(code: 'urd', name: 'Urdu', nativeName: 'اردو', script: 'Arabic'),
      const MMSLanguageInfo(code: 'tur', name: 'Turkish', nativeName: 'Türkçe', script: 'Latin'),
    ];
    
    return _supportedLanguagesCache!;
  }

  /// Detect language in audio with confidence score
  /// 
  /// Uses MMS-LID (Language Identification) model.
  /// Returns top detected language with confidence and alternatives.
  /// 
  /// Implementation Plan:
  /// 1. Pre-process audio:
  ///    - Load audio file
  ///    - Resample to 16kHz mono
  ///    - Take first 10 seconds (sufficient for LID)
  /// 
  /// 2. Run MMS-LID model:
  ///    - Load mms-lid-* model from modelPath
  ///    - Extract features using processor
  ///    - Forward through LID classifier
  ///    - Get softmax probabilities over languages
  /// 
  /// 3. Process results:
  ///    - Find argmax for primary language
  ///    - Extract confidence = max probability
  ///    - Get top-5 alternatives for alternativeLanguages
  ///    - Map language IDs to language codes/names
  /// 
  /// 4. Return LanguageDetectionResult with:
  ///    - Primary language code and confidence
  ///    - Up to 5 alternative languages
  ///    - Human-readable names
  Future<LanguageDetectionResult> detectLanguage(
    String audioPath,
    String modelPath,
  ) async {
    _ensureInitialized();
    
    // Validate audio file exists
    final audioFile = File(audioPath);
    if (!audioFile.existsSync()) {
      throw MMSTranscriptionException('Audio file not found: $audioPath');
    }

    try {
      // FFI Implementation Plan:
      // 1. Load audio and extract first 10 seconds
      // 2. Call mms_detect_language(audio_data, len, model_path)
      // 3. Parse returned probabilities array
      // 4. Map indices to language codes
      // 5. Build result with alternatives

      // Placeholder implementation
      return const LanguageDetectionResult(
        languageCode: 'eng',
        confidence: 0.87,
        languageName: 'English',
        alternativeLanguages: [
          LanguageDetectionResult(
            languageCode: 'deu',
            confidence: 0.05,
            languageName: 'German',
          ),
          LanguageDetectionResult(
            languageCode: 'nld',
            confidence: 0.03,
            languageName: 'Dutch',
          ),
        ],
      );
    } catch (e) {
      throw MMSLanguageDetectionException('Language detection failed: $e');
    }
  }

  void _ensureInitialized() {
    if (!_initialized) {
      throw MMSNotInitializedException();
    }
  }

  @override
  void releaseNative() {
    // Clear cached data
    _supportedLanguagesCache = null;
    
    // FFI: Release any loaded models and free memory
    // mms_cleanup()
    
    _lib = null;
    _initialized = false;
  }
}

/// Exception thrown when MMS initialization fails
class MMSInitializationException implements Exception {
  MMSInitializationException(this.message);

  final String message;

  @override
  String toString() => 'MMSInitializationException: $message';
}

/// Exception thrown when MMS is not initialized
class MMSNotInitializedException implements Exception {
  @override
  String toString() => 'MMS bindings not initialized. Call initialize() first.';
}

/// Exception thrown when transcription fails
class MMSTranscriptionException implements Exception {
  MMSTranscriptionException(this.message);

  final String message;

  @override
  String toString() => 'MMSTranscriptionException: $message';
}

/// Exception thrown when language detection fails
class MMSLanguageDetectionException implements Exception {
  MMSLanguageDetectionException(this.message);

  final String message;

  @override
  String toString() => 'MMSLanguageDetectionException: $message';
}

/// Exception thrown when an unsupported language is requested
class MMSUnsupportedLanguageException implements Exception {
  MMSUnsupportedLanguageException(this.message);

  final String message;

  @override
  String toString() => 'MMSUnsupportedLanguageException: $message';
}
