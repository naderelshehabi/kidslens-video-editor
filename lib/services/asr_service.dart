import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:kidslens_video_editor/data/models/models.dart';
import 'package:kidslens_video_editor/native/bindings/whisper_bindings.dart';
import 'package:kidslens_video_editor/services/model_manager_service.dart';

/// Service for orchestrating ASR (Automatic Speech Recognition) transcription
///
/// Provides high-level transcription functionality with progress tracking,
/// model selection, and hardware-aware recommendations.
class AsrService {
  AsrService({
    required this.whisper,
    required this.modelManager,
  });

  final WhisperBindings whisper;
  final ModelManagerService modelManager;

  /// Controller for progress updates
  StreamController<TranscriptionProgress>? _progressController;

  /// Currently loaded model path
  String? _loadedModelPath;

  /// Transcribe an audio file and return a stream of progress updates
  ///
  /// The stream yields progress updates during transcription and completes
  /// with the final result. Access the transcript through the last progress
  /// event or use [transcribeToResult] for direct access.
  ///
  /// [audioPath] - Path to the audio file to transcribe
  /// [language] - Optional language code (e.g., 'en', 'es'). Use 'auto' for detection.
  /// [preferredModel] - Optional model ID to use. Falls back to recommended model.
  Stream<TranscriptionProgress> transcribe(
    String audioPath, {
    String? language,
    String? preferredModel,
  }) async* {
    _progressController = StreamController<TranscriptionProgress>.broadcast();

    try {
      // Phase 1: Initialization
      yield const TranscriptionProgress(
        progress: 0,
      );

      // Phase 2: Load model
      yield const TranscriptionProgress(
        progress: 0.05,
        phase: TranscriptionPhase.loadingModel,
      );

      final modelId = preferredModel ?? await _selectModel();
      final modelPath = await _ensureModelLoaded(modelId);
      if (modelPath == null) {
        yield TranscriptionProgress.error('Failed to load model: $modelId');
        return;
      }

      // Phase 3: Transcribe
      yield const TranscriptionProgress(
        progress: 0.1,
        phase: TranscriptionPhase.transcribing,
      );

      final startTime = DateTime.now();
      
      // Perform transcription
      final transcript = await whisper.transcribe(
        audioPath,
        modelPath,
        language: language,
      );

      final processingTime = DateTime.now().difference(startTime);

      // Phase 4: Post-processing
      yield TranscriptionProgress(
        progress: 0.95,
        phase: TranscriptionPhase.postProcessing,
        segmentsProcessed: transcript.segments.length,
        totalSegments: transcript.segments.length,
      );

      // Complete
      yield TranscriptionProgress(
        progress: 1,
        phase: TranscriptionPhase.complete,
        isComplete: true,
        segmentsProcessed: transcript.segments.length,
        totalSegments: transcript.segments.length,
        currentSegment: transcript.segments.isNotEmpty 
            ? transcript.segments.last 
            : null,
        estimatedTimeRemaining: Duration.zero,
      );

      debugPrint('Transcription completed in ${processingTime.inSeconds}s');
    } catch (e) {
      yield TranscriptionProgress.error(e.toString());
    } finally {
      await _progressController?.close();
      _progressController = null;
    }
  }

  /// Transcribe and return the transcript directly
  ///
  /// Convenience method for when progress tracking is not needed.
  Future<Transcript> transcribeToResult(
    String audioPath, {
    String? language,
    String? preferredModel,
  }) async {
    final modelId = preferredModel ?? await _selectModel();
    final modelPath = await _ensureModelLoaded(modelId);
    if (modelPath == null) {
      throw AsrException('Failed to load model: $modelId');
    }

    return whisper.transcribe(
      audioPath,
      modelPath,
      language: language,
    );
  }

  /// Get the recommended model based on hardware capabilities
  ///
  /// Returns the model ID best suited for the current system,
  /// balancing accuracy and performance.
  Future<String> getRecommendedModel() async => _selectModel();

  /// Get list of supported languages for transcription
  ///
  /// Returns language codes supported by the currently loaded model,
  /// or a default list if no model is loaded.
  Future<List<String>> getSupportedLanguages() async {
    if (_loadedModelPath != null) {
      return whisper.getSupportedLanguages(_loadedModelPath!);
    }

    // Default supported languages for Whisper models
    return [
      'en', 'zh', 'de', 'es', 'ru', 'ko', 'fr', 'ja', 'pt', 'tr',
      'pl', 'ca', 'nl', 'ar', 'sv', 'it', 'id', 'hi', 'fi', 'vi',
      'he', 'uk', 'el', 'ms', 'cs', 'ro', 'da', 'hu', 'ta', 'no',
      'th', 'ur', 'hr', 'bg', 'lt', 'la', 'mi', 'ml', 'cy', 'sk',
      'te', 'fa', 'lv', 'bn', 'sr', 'az', 'sl', 'kn', 'et', 'mk',
    ];
  }

  /// Get language name for a language code
  String getLanguageName(String code) {
    const languageNames = {
      'en': 'English',
      'zh': 'Chinese',
      'de': 'German',
      'es': 'Spanish',
      'ru': 'Russian',
      'ko': 'Korean',
      'fr': 'French',
      'ja': 'Japanese',
      'pt': 'Portuguese',
      'tr': 'Turkish',
      'pl': 'Polish',
      'nl': 'Dutch',
      'ar': 'Arabic',
      'sv': 'Swedish',
      'it': 'Italian',
      'id': 'Indonesian',
      'hi': 'Hindi',
      'fi': 'Finnish',
      'vi': 'Vietnamese',
      'auto': 'Auto-detect',
    };
    return languageNames[code] ?? code.toUpperCase();
  }

  /// Select the best model based on hardware
  Future<String> _selectModel() async {
    final models = await modelManager.getAvailableModels();
    final downloaded = await modelManager.getDownloadedModels();

    // Filter to ASR models that are downloaded
    final asrModels = models
        .where((m) => m.modelType == HuggingFaceModelType.asr)
        .where((m) => downloaded.contains(m.id))
        .toList();

    if (asrModels.isEmpty) {
      // Return default model if none downloaded
      return 'whisper-base';
    }

    // Sort by accuracy (prefer higher accuracy if system can handle it)
    asrModels.sort((a, b) => b.accuracyPercent.compareTo(a.accuracyPercent));

    // Return the best available model
    return asrModels.first.id;
  }

  /// Ensure model is loaded and return its path
  Future<String?> _ensureModelLoaded(String modelId) async {
    // Check if already downloaded
    final path = await modelManager.getModelPath(modelId);
    if (path != null) {
      _loadedModelPath = path;
      return path;
    }

    // Model not downloaded
    debugPrint('Model $modelId not found. Please download it first.');
    return null;
  }

  /// Cancel any ongoing transcription
  void cancel() {
    _progressController?.close();
    _progressController = null;
  }

  /// Release resources
  void dispose() {
    cancel();
    _loadedModelPath = null;
  }
}

/// Exception thrown by ASR service
class AsrException implements Exception {
  AsrException(this.message);

  final String message;

  @override
  String toString() => 'AsrException: $message';
}
