import 'dart:async';
import 'dart:io';
import 'dart:isolate';

import 'package:flutter/foundation.dart';
import 'package:kidslens_video_editor/data/models/models.dart';
import 'package:kidslens_video_editor/native/bindings/ffmpeg_bindings.dart';
import 'package:kidslens_video_editor/services/asr_cache_service.dart';
import 'package:kidslens_video_editor/native/bindings/whisper_bindings.dart';
import 'package:kidslens_video_editor/services/model_manager_service.dart';
import 'package:kidslens_video_editor/services/transcription_isolate.dart';
import 'package:path/path.dart' as p;

/// Service for orchestrating ASR (Automatic Speech Recognition) transcription
///
/// Provides high-level transcription functionality with progress tracking,
/// model selection, and hardware-aware recommendations.
class AsrService {
  AsrService({
    required this.whisper,
    required this.modelManager,
    required this.ffmpeg,
    this.cache,
  });

  final WhisperBindings whisper;
  final ModelManagerService modelManager;
  final FFmpegBindings ffmpeg;
  final AsrCacheService? cache;

  /// File extensions that are video formats requiring audio extraction
  static const _videoExtensions = {
    '.mp4',
    '.mkv',
    '.mov',
    '.avi',
    '.webm',
    '.wmv',
    '.flv',
    '.m4v',
  };

  /// File extensions that need conversion to 16kHz mono WAV
  static const _nonWavAudioExtensions = {
    '.mp3',
    '.aac',
    '.m4a',
    '.ogg',
    '.flac',
    '.opus',
    '.wma',
  };

  /// Temporary file used for audio extraction (cleaned up after transcription)
  String? _tempAudioPath;

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
  /// [audioPath] - Path to the audio/video file to transcribe
  /// [language] - Optional language code (e.g., 'en', 'es'). Use 'auto' for detection.
  /// [preferredModel] - Optional model ID to use. Falls back to recommended model.
  Stream<TranscriptionProgress> transcribe(
    String audioPath, {
    String? language,
    String? preferredModel,
  }) async* {
    _progressController = StreamController<TranscriptionProgress>.broadcast();
    String? preparedAudioPath;

    try {
      // Phase 1: Initialization
      yield const TranscriptionProgress(
        progress: 0,
      );

      // Phase 1.5: Prepare audio (extract if video, convert to WAV if needed)
      yield const TranscriptionProgress(
        progress: 0.02,
        phase: TranscriptionPhase.extractingAudio,
      );
      preparedAudioPath = await _prepareAudioForWhisper(audioPath);

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

      // Perform transcription with prepared audio
      final transcript = await whisper.transcribe(
        preparedAudioPath,
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
        currentSegment:
            transcript.segments.isNotEmpty ? transcript.segments.last : null,
        estimatedTimeRemaining: Duration.zero,
      );

      debugPrint('Transcription completed in ${processingTime.inSeconds}s');
    } catch (e) {
      yield TranscriptionProgress.error(e.toString());
    } finally {
      await _cleanupTempAudio();
      await _progressController?.close();
      _progressController = null;
    }
  }

  /// Transcribe and return the transcript directly
  ///
  /// Convenience method for when progress tracking is not needed.
  /// Automatically extracts audio from video files and converts to proper format.
  /// [mediaDuration] can be passed to help with placeholder generation.
  Future<Transcript> transcribeToResult(
    String audioPath, {
    String? language,
    String? preferredModel,
    Duration? mediaDuration,
  }) async {
    try {
      // Prepare audio (extract if video, convert to WAV if needed)
      final preparedAudioPath = await _prepareAudioForWhisper(audioPath);

      final modelId = preferredModel ?? await _selectModel();
      final modelPath = await _ensureModelLoaded(modelId);
      if (modelPath == null) {
        throw AsrException('Failed to load model: $modelId');
      }

      return await whisper.transcribe(
        preparedAudioPath,
        modelPath,
        language: language,
        mediaDuration: mediaDuration,
      );
    } finally {
      await _cleanupTempAudio();
    }
  }

  /// Transcribe in a background isolate so the UI thread is never blocked.
  ///
  /// Audio extraction (FFmpeg) runs on the main thread (async, non-blocking).
  /// The heavy FFI transcription runs in a dedicated [Isolate] using
  /// overlapping audio chunks for accurate progress reporting.
  ///
  /// [onProgress] is called with (phase, progress 0.0-1.0, message,
  /// currentTimestamp) where [currentTimestamp] is the audio position
  /// currently being transcribed.
  ///
  /// [cancelToken] can be completed to abort.  The background isolate will
  /// be killed immediately.
  Future<Transcript> transcribeInBackground(
    String audioPath, {
    String? language,
    String? preferredModel,
    Duration? mediaDuration,
    bool? useGpu,
    int? nThreads,
    int? beamSize,
    void Function(
      TranscriptionPhase phase,
      double progress,
      String message,
      Duration? currentTimestamp,
    )? onProgress,
    Completer<void>? cancelToken,
  }) async {
    try {
      void checkCancelled() {
        if (cancelToken != null && cancelToken.isCompleted) {
          throw AsrCancelledException();
        }
      }

      // Phase 1: Extract / convert audio (async, non-blocking)
      onProgress?.call(
        TranscriptionPhase.extractingAudio,
        0.0,
        'Extracting audio...',
        null,
      );
      final preparedAudioPath = await _prepareAudioForWhisper(audioPath);
      checkCancelled();
      onProgress?.call(
        TranscriptionPhase.extractingAudio,
        0.05,
        'Audio extracted',
        null,
      );

      // Phase 2: Resolve model path
      onProgress?.call(
        TranscriptionPhase.loadingModel,
        0.05,
        'Preparing model...',
        null,
      );
      final modelId = preferredModel ?? await _selectModel();
      final modelPath = await _ensureModelLoaded(modelId);
      if (modelPath == null) {
        throw AsrException('Model not found: $modelId. Please download it.');
      }
      checkCancelled();
      onProgress?.call(
        TranscriptionPhase.loadingModel,
        0.10,
        'Model ready',
        null,
      );

      // Check cache before starting heavy transcription
      if (cache != null) {
        final cached = await cache!.lookup(
          audioPath: preparedAudioPath,
          modelId: modelId,
          language: language,
        );
        if (cached != null) {
          onProgress?.call(
            TranscriptionPhase.complete,
            1.0,
            'Loaded from cache',
            mediaDuration,
          );
          return cached;
        }
      }

      // Check if native library is available
      final libraryPath = whisper.nativeLibraryPath;
      if (libraryPath == null || !whisper.hasNativeSupport) {
        // Fallback: placeholder mode runs instantly, no isolate needed
        onProgress?.call(
          TranscriptionPhase.transcribing,
          0.50,
          'Generating placeholder subtitles...',
          null,
        );
        final transcript = await whisper.transcribe(
          preparedAudioPath,
          modelPath,
          language: language,
          mediaDuration: mediaDuration,
        );
        onProgress?.call(
          TranscriptionPhase.complete,
          1.0,
          'Complete!',
          mediaDuration,
        );
        return transcript;
      }

      // Phase 3: Chunked transcription in background isolate
      onProgress?.call(
        TranscriptionPhase.transcribing,
        0.10,
        'Starting transcription...',
        Duration.zero,
      );

      final params = TranscriptionIsolateParams(
        libraryPath: libraryPath,
        audioPath: preparedAudioPath,
        modelPath: modelPath,
        language: language,
        useGpu: useGpu ?? true,
        nThreads: nThreads ?? 0,
        beamSize: beamSize ?? adaptiveBeamSize(modelId),
      );

      checkCancelled();

      Transcript transcript;
      try {
        transcript = await _runChunkedInIsolate(
          params,
          onProgress: onProgress,
          cancelToken: cancelToken,
        );
      } catch (e) {
        // If the user explicitly cancelled, don't retry
        if (e is AsrCancelledException) rethrow;

        // If GPU was enabled, retry once with CPU-only as a fallback
        if (params.useGpu) {
          debugPrint(
            'Transcription failed with GPU enabled, retrying with CPU: $e',
          );
          onProgress?.call(
            TranscriptionPhase.transcribing,
            0.10,
            'GPU error — retrying with CPU...',
            Duration.zero,
          );

          final cpuParams = TranscriptionIsolateParams(
            libraryPath: params.libraryPath,
            audioPath: params.audioPath,
            modelPath: params.modelPath,
            language: params.language,
            translateToEnglish: params.translateToEnglish,
            useGpu: false,
            nThreads: params.nThreads,
            beamSize: params.beamSize,
          );

          transcript = await _runChunkedInIsolate(
            cpuParams,
            onProgress: onProgress,
            cancelToken: cancelToken,
          );
        } else {
          rethrow;
        }
      }

      checkCancelled();

      // Cache the result for future re-use
      if (cache != null) {
        await cache!.store(
          audioPath: preparedAudioPath,
          modelId: modelId,
          language: language,
          transcript: transcript,
        );
      }

      // Phase 4: Done
      onProgress?.call(
        TranscriptionPhase.complete,
        1.0,
        'Complete!',
        mediaDuration,
      );
      debugPrint(
        'Background transcription complete: '
        '${transcript.segments.length} segments',
      );
      return transcript;
    } finally {
      await _cleanupTempAudio();
    }
  }

  /// Spawn a background isolate that processes audio in overlapping chunks
  /// and streams progress updates back via [ReceivePort].
  static Future<Transcript> _runChunkedInIsolate(
    TranscriptionIsolateParams params, {
    void Function(
      TranscriptionPhase phase,
      double progress,
      String message,
      Duration? currentTimestamp,
    )? onProgress,
    Completer<void>? cancelToken,
  }) async {
    final receivePort = ReceivePort();
    late final Isolate isolate;

    try {
      isolate = await Isolate.spawn(
        chunkedTranscriptionEntry,
        (params, receivePort.sendPort),
      );
    } catch (e) {
      receivePort.close();
      rethrow;
    }

    // If cancellation is requested, kill the isolate immediately.
    StreamSubscription<void>? cancelSub;
    if (cancelToken != null && !cancelToken.isCompleted) {
      cancelSub = cancelToken.future.asStream().listen((_) {
        isolate.kill(priority: Isolate.beforeNextEvent);
        receivePort.close();
      });
    }

    try {
      Transcript? result;
      String? error;

      await for (final msg in receivePort) {
        if (msg is Map) {
          final type = msg['type'] as String;

          if (type == 'progress') {
            final progress = (msg['progress'] as num).toDouble();
            final timestampMs = msg['timestampMs'] as int;
            final message = msg['message'] as String;
            onProgress?.call(
              TranscriptionPhase.transcribing,
              progress,
              message,
              Duration(milliseconds: timestampMs),
            );
          } else if (type == 'result') {
            result = msg['transcript'] as Transcript;
            break;
          } else if (type == 'error') {
            error = msg['message'] as String;
            break;
          }
        }
      }

      if (cancelToken != null && cancelToken.isCompleted) {
        throw AsrCancelledException();
      }

      if (error != null) {
        throw AsrException(error);
      }

      if (result == null) {
        throw AsrException(
          'Transcription isolate ended without returning a result.',
        );
      }

      return result;
    } finally {
      await cancelSub?.cancel();
      receivePort.close();
      isolate.kill(priority: Isolate.beforeNextEvent);
    }
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
      'he',
      'uk',
      'el',
      'ms',
      'cs',
      'ro',
      'da',
      'hu',
      'ta',
      'no',
      'th',
      'ur',
      'hr',
      'bg',
      'lt',
      'la',
      'mi',
      'ml',
      'cy',
      'sk',
      'te',
      'fa',
      'lv',
      'bn',
      'sr',
      'az',
      'sl',
      'kn',
      'et',
      'mk',
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
    _cleanupTempAudio();
    _loadedModelPath = null;
  }

  /// Prepare audio file for Whisper transcription
  ///
  /// If the input is a video file, extracts audio to a temporary WAV file.
  /// If the input is a non-WAV audio file, converts to WAV format.
  /// WAV files are passed through directly (if already 16kHz mono PCM).
  ///
  /// Returns the path to the WAV file ready for Whisper.
  Future<String> _prepareAudioForWhisper(String inputPath) async {
    final extension = p.extension(inputPath).toLowerCase();
    final isVideo = _videoExtensions.contains(extension);
    final isNonWavAudio = _nonWavAudioExtensions.contains(extension);

    // If already a WAV file, use it directly
    // Note: Whisper loader will validate format internally
    if (extension == '.wav' && !isVideo && !isNonWavAudio) {
      debugPrint('Using WAV file directly: $inputPath');
      return inputPath;
    }

    // Need to extract/convert to WAV
    debugPrint(
        'Extracting audio from ${isVideo ? "video" : "audio"} file: $inputPath');

    // Create temp file path
    final tempDir = Directory.systemTemp;
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final tempWavPath = p.join(tempDir.path, 'whisper_audio_$timestamp.wav');
    _tempAudioPath = tempWavPath;

    // Use FFmpeg to extract/convert audio to 16kHz mono WAV (Whisper's required format)
    await _extractAudioToWav(inputPath, tempWavPath);

    debugPrint('Audio extracted to: $tempWavPath');
    return tempWavPath;
  }

  /// Extract audio from input file to 16kHz mono WAV format for Whisper
  Future<void> _extractAudioToWav(String inputPath, String outputPath) async {
    final ffmpegPath = ffmpeg.ffmpegPath;
    if (ffmpegPath == null) {
      throw AsrException(
        'FFmpeg not available. Cannot extract audio from video files.',
      );
    }

    final result = await Process.run(
      ffmpegPath,
      [
        '-i', inputPath, // Input file
        '-vn', // No video
        '-acodec', 'pcm_s16le', // 16-bit PCM (required by Whisper)
        '-ar', '16000', // 16kHz sample rate (required by Whisper)
        '-ac', '1', // Mono (single channel)
        '-y', // Overwrite output file
        outputPath,
      ],
    );

    if (result.exitCode != 0) {
      throw AsrException(
        'Failed to extract audio: ${result.stderr}',
      );
    }

    // Verify the output file was created
    if (!await File(outputPath).exists()) {
      throw AsrException(
        'Audio extraction completed but output file was not created.',
      );
    }
  }

  /// Clean up temporary audio file if one was created
  Future<void> _cleanupTempAudio() async {
    if (_tempAudioPath != null) {
      try {
        final tempFile = File(_tempAudioPath!);
        if (await tempFile.exists()) {
          await tempFile.delete();
          debugPrint('Cleaned up temp audio file: $_tempAudioPath');
        }
      } catch (e) {
        debugPrint('Warning: Failed to clean up temp audio file: $e');
      }
      _tempAudioPath = null;
    }
  }

  /// Compute an optimal beam size based on the model tier.
  ///
  /// Tiny/base models benefit less from wide beams (wasteful CPU), while
  /// large models can exploit extra search width for better accuracy.
  /// Returns the recommended beam size if the caller has not explicitly
  /// overridden it (i.e. when [beamSize] is null).
  static int adaptiveBeamSize(String modelId) {
    final id = modelId.toLowerCase();
    if (id.contains('tiny')) return 2;
    if (id.contains('base')) return 3;
    if (id.contains('small')) return 4;
    if (id.contains('medium')) return 5;
    // large, large-v2, large-v3
    return 5;
  }
}

/// Exception thrown by ASR service
class AsrException implements Exception {
  AsrException(this.message);

  final String message;

  @override
  String toString() => 'AsrException: $message';
}

/// Exception thrown when the user cancels transcription.
class AsrCancelledException implements Exception {
  @override
  String toString() => 'Transcription cancelled by user';
}
