import 'dart:ffi';
import 'dart:io';

import '../../data/models/transcript.dart';
import '../resource_manager.dart';

/// FFI bindings for whisper.cpp
class WhisperBindings extends NativeResource {
  DynamicLibrary? _lib;
  bool _initialized = false;

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

  /// Transcribe audio file using Whisper model
  Future<Transcript> transcribe(
    String audioPath,
    String modelPath, {
    String? language,
    bool translateToEnglish = false,
  }) async {
    _ensureInitialized();

    // TODO: Implement actual Whisper transcription via FFI
    // For now, return placeholder transcript
    final detectedLanguage = language ?? 'en';
    return Transcript(
      segments: [
        TranscriptSegment(
          id: 'segment_0',
          text: 'Placeholder transcription',
          startTime: Duration.zero,
          endTime: const Duration(seconds: 5),
          words: [
            const TranscriptWord(
              word: 'Placeholder',
              startTime: Duration.zero,
              endTime: Duration(milliseconds: 500),
              confidence: 0.95,
            ),
            const TranscriptWord(
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
    _lib = null;
    _initialized = false;
  }
}

/// Exception thrown when Whisper initialization fails
class WhisperInitializationException implements Exception {
  final String message;
  WhisperInitializationException(this.message);

  @override
  String toString() => 'WhisperInitializationException: $message';
}

/// Exception thrown when Whisper is not initialized
class WhisperNotInitializedException implements Exception {
  @override
  String toString() => 'Whisper bindings not initialized. Call initialize() first.';
}
