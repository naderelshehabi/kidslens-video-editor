import 'dart:convert';
import 'dart:ffi';
import 'dart:io';
import 'dart:isolate';
import 'dart:typed_data';

import 'package:ffi/ffi.dart';
import 'package:kidslens_video_editor/data/models/transcript.dart';
import 'package:kidslens_video_editor/native/bindings/whisper_bindings.dart';
import 'package:path/path.dart' as p;

// ============================================================================
// Safe UTF-8 helper
// ============================================================================

/// Decode a native UTF-8 pointer without throwing on malformed bytes.
///
/// Whisper may return strings containing partial multi-byte sequences
/// (especially for auto-detected language codes from English-only models).
/// This replaces invalid bytes with the Unicode replacement character instead
/// of throwing a [FormatException].
String _safeUtf8(Pointer<Utf8> ptr) {
  // Walk the null-terminated string to find its length.
  var len = 0;
  while ((ptr.cast<Uint8>() + len).value != 0) {
    len++;
  }
  final bytes = ptr.cast<Uint8>().asTypedList(len);
  return utf8.decode(bytes, allowMalformed: true);
}

/// Format milliseconds as a human-readable ETA string.
String _formatEta(int ms) {
  if (ms <= 0) return '< 1s';
  final seconds = ms ~/ 1000;
  if (seconds < 60) return '${seconds}s';
  final minutes = seconds ~/ 60;
  final secs = seconds % 60;
  return '${minutes}m ${secs}s';
}

// ============================================================================
// Configuration
// ============================================================================

/// Duration of each audio chunk in seconds.
const int kChunkDurationSec = 30;

/// Overlap between adjacent chunks in seconds.
/// Must be large enough that no word straddles the boundary undetected.
const int kOverlapDurationSec = 3;

/// Sample rate expected by Whisper (16 kHz).
const int kSampleRate = 16000;

// ============================================================================
// Parameters
// ============================================================================

/// Parameters for running transcription in a background isolate.
///
/// All fields must be sendable across isolates (primitives/strings only).
class TranscriptionIsolateParams {
  const TranscriptionIsolateParams({
    required this.libraryPath,
    required this.audioPath,
    required this.modelPath,
    this.language,
    this.translateToEnglish = false,
    this.asrGpuEnabled = true,
    this.asrGpuDevice = 0,
    this.nThreads = 0,
    this.beamSize = 5,
  });

  final String libraryPath;
  final String audioPath;
  final String modelPath;
  final String? language;
  final bool translateToEnglish;

  /// Whether to use GPU acceleration for ASR.
  final bool asrGpuEnabled;
  
  /// GPU device index for ASR.
  final int asrGpuDevice;

  /// Number of CPU threads for inference. 0 means auto-detect.
  final int nThreads;

  /// Beam search beam size. Smaller = faster, larger = more accurate.
  final int beamSize;
}

// ============================================================================
// Isolate-local globals for the native progress callback
// ============================================================================

/// The [SendPort] used by the native callback to push updates to the main
/// isolate.  Set once per isolate lifetime before transcription begins.
SendPort? _gSendPort;

/// Progress fraction already accounted for by previous chunks.
double _gChunkBaseProgress = 0;

/// How much of the 0–1 progress range this chunk is responsible for.
double _gChunkProgressRange = 0;

/// Absolute millisecond offset of the current chunk within the full audio.
int _gChunkOffsetMs = 0;

/// Duration of the current chunk in milliseconds.
int _gChunkDurationMs = 0;

/// Current chunk index (1-based for display)
int _gCurrentChunkIndex = 0;

/// Total number of chunks
int _gTotalChunks = 0;

/// Native progress callback invoked by whisper.cpp during transcription.
///
/// Called synchronously on the isolate thread from within `whisper_full`.
/// Since [SendPort.send] only *enqueues* a message, the main-isolate event
/// loop can pick it up while the background isolate continues processing.
void _nativeProgressCallback(int progress, Pointer<Void> userData) {
  final port = _gSendPort;
  if (port == null) return;
  final pct = _gChunkBaseProgress + (progress / 100.0) * _gChunkProgressRange;
  final tsMs = _gChunkOffsetMs + (progress * _gChunkDurationMs ~/ 100);
  final chunkInfo = _gTotalChunks > 1
      ? 'Transcribing chunk $_gCurrentChunkIndex/$_gTotalChunks ($progress%)'
      : 'Transcribing... ($progress%)';
  port.send({
    'type': 'progress',
    'progress': pct.clamp(0.0, 1.0),
    'timestampMs': tsMs,
    'message': chunkInfo,
  });
}

// ============================================================================
// FFI typedefs for kl_whisper_set_progress_callback
// ============================================================================

/// `void (*KLWhisperProgressCallback)(int progress, void* user_data)`
typedef WhisperProgressCallbackNative = Void Function(
  Int32 progress,
  Pointer<Void> userData,
);

/// `void kl_whisper_set_progress_callback(handle, callback, user_data)`
typedef WhisperSetProgressCallbackNative = Void Function(
  Pointer handle,
  Pointer<NativeFunction<WhisperProgressCallbackNative>> callback,
  Pointer<Void> userData,
);
typedef WhisperSetProgressCallbackDart = void Function(
  Pointer handle,
  Pointer<NativeFunction<WhisperProgressCallbackNative>> callback,
  Pointer<Void> userData,
);

// ============================================================================
// FFI typedefs for kl_whisper_cancel
// ============================================================================

/// `void kl_whisper_cancel(KLWhisperHandle handle)`
typedef WhisperCancelNative = Void Function(Pointer handle);
typedef WhisperCancelDart = void Function(Pointer handle);

// ============================================================================
// Entry point – chunked transcription with progress reporting
// ============================================================================

/// Entry point for the chunked transcription isolate.
///
/// Receives `(params, sendPort)`.  Sends maps back via [sendPort]:
///
/// * `{'type': 'progress', 'progress': double, 'timestampMs': int, 'message': String}`
/// * `{'type': 'result', 'transcript': Transcript}`
/// * `{'type': 'error', 'message': String}`
void chunkedTranscriptionEntry(
  (TranscriptionIsolateParams, SendPort) args,
) {
  final (params, sendPort) = args;
  _gSendPort = sendPort;

  try {
    // ── 1. Open the native library ──────────────────────────────────────
    final lib = DynamicLibrary.open(params.libraryPath);

    // ── 2. Bind FFI functions ───────────────────────────────────────────
    final whisperInit = lib
        .lookup<NativeFunction<WhisperInitNative>>('kl_whisper_init')
        .asFunction<WhisperInitDart>();

    WhisperInitWithConfigDart? whisperInitWithConfig;
    try {
      whisperInitWithConfig = lib
          .lookup<NativeFunction<WhisperInitWithConfigNative>>(
              'kl_whisper_init_with_config',)
          .asFunction<WhisperInitWithConfigDart>();
    } catch (_) {
      // Optional in older builds
    }

    final whisperFree = lib
        .lookup<NativeFunction<WhisperFreeNative>>('kl_whisper_free')
        .asFunction<WhisperFreeDart>();

    final whisperTranscribePcm = lib
        .lookup<NativeFunction<WhisperTranscribePcmNative>>(
            'kl_whisper_transcribe_pcm',)
        .asFunction<WhisperTranscribePcmDart>();

    final whisperFreeResult = lib
        .lookup<NativeFunction<WhisperFreeResultNative>>(
            'kl_whisper_free_result',)
        .asFunction<WhisperFreeResultDart>();

    WhisperSetProgressCallbackDart? whisperSetProgressCallback;
    try {
      whisperSetProgressCallback = lib
          .lookup<NativeFunction<WhisperSetProgressCallbackNative>>(
              'kl_whisper_set_progress_callback',)
          .asFunction<WhisperSetProgressCallbackDart>();
    } catch (_) {
      // Progress callback may not be available in all builds
    }

    WhisperGetErrorDart? whisperGetError;
    try {
      whisperGetError = lib
          .lookup<NativeFunction<WhisperGetErrorNative>>(
              'kl_whisper_get_error',)
          .asFunction<WhisperGetErrorDart>();
    } catch (_) {
      // Optional
    }

    // ── 3. Load the model ───────────────────────────────────────────────
    sendPort.send({
      'type': 'progress',
      'progress': 0.05,
      'timestampMs': 0,
      'message': 'Loading model...',
    });

    final modelPathPtr = params.modelPath.toNativeUtf8();
    final initConfigPtr = calloc<WhisperConfigNative>();
    Pointer modelHandle;
    try {
      final initConfig = initConfigPtr.ref
        ..nThreads = params.nThreads > 0
            ? params.nThreads.clamp(1, 32)
            : Platform.numberOfProcessors.clamp(1, 16)
        ..useGpu = params.asrGpuEnabled
        ..gpuDevice = params.asrGpuDevice < 0 ? 0 : params.asrGpuDevice
        ..language = nullptr
        ..translate = params.translateToEnglish
        ..wordTimestamps = true
        ..wordThreshold = 0.01
        ..maxSegmentLength = 0
        ..splitOnWord = true
        ..temperature = 0.0
        ..beamSize = params.beamSize
        ..entropyThreshold = 2.4
        ..suppressBlank = true
        ..suppressNonSpeech = true
        ..noSpeechThreshold = 0.6;

      modelHandle = whisperInitWithConfig != null
          ? whisperInitWithConfig(modelPathPtr, initConfigPtr)
          : whisperInit(modelPathPtr);
    } finally {
      malloc.free(modelPathPtr);
      calloc.free(initConfigPtr);
    }

    if (modelHandle == nullptr) {
      final errorPtr = whisperGetError?.call();
      final error = errorPtr != null && errorPtr != nullptr
          ? errorPtr.toDartString()
          : 'Unknown error';
      throw WhisperModelLoadException(
          'Failed to load model in isolate: $error',);
    }

    // Register native progress callback (if available)
    if (whisperSetProgressCallback != null) {
      final callbackPtr =
          Pointer.fromFunction<WhisperProgressCallbackNative>(
              _nativeProgressCallback,);
      whisperSetProgressCallback(modelHandle, callbackPtr, nullptr);
    }

    try {
      // ── 4. Open WAV file for streaming reads ──────────────────────────
      sendPort.send({
        'type': 'progress',
        'progress': 0.08,
        'timestampMs': 0,
        'message': 'Reading audio header...',
      });

      final wavReader = _WavReader(params.audioPath);
      try {
      wavReader.parseHeader();
      final totalSamples = wavReader.totalSamples;
      final totalDurationMs = (totalSamples / kSampleRate * 1000).round();

      // ── 5. Compute chunk boundaries ───────────────────────────────────
      const chunkSamples = kChunkDurationSec * kSampleRate;
      const overlapSamples = kOverlapDurationSec * kSampleRate;
      const stepSamples = chunkSamples - overlapSamples;

      // Build chunk descriptors (offsets only — no audio data yet)
      final chunkDescs = <({int offset, int length, bool isFirst, bool isLast})>[];
      if (totalSamples <= chunkSamples) {
        chunkDescs.add((
          offset: 0,
          length: totalSamples,
          isFirst: true,
          isLast: true,
        ),);
      } else {
        var offset = 0;
        while (offset < totalSamples) {
          final end = (offset + chunkSamples).clamp(0, totalSamples);
          chunkDescs.add((
            offset: offset,
            length: end - offset,
            isFirst: offset == 0,
            isLast: end >= totalSamples,
          ),);
          offset += stepSamples;
          if (end >= totalSamples) break;
        }
      }

      // ── 6. Process each chunk ─────────────────────────────────────────
      const progressBase = 0.10; // 10 % spent on setup
      const progressEnd = 0.95; // 95 % when done transcribing
      const progressRange = progressEnd - progressBase;

      final allSegments = <TranscriptSegment>[];
      String? detectedLanguage;
      final stopwatch = Stopwatch()..start();

      for (var ci = 0; ci < chunkDescs.length; ci++) {
        final desc = chunkDescs[ci];
        final chunkOffsetMs =
            (desc.offset / kSampleRate * 1000).round();
        final chunkDurMs =
            (desc.length / kSampleRate * 1000).round();

        // Update globals for the native progress callback
        _gChunkBaseProgress =
            progressBase + (ci / chunkDescs.length) * progressRange;
        _gChunkProgressRange = progressRange / chunkDescs.length;
        _gChunkOffsetMs = chunkOffsetMs;
        _gChunkDurationMs = chunkDurMs;
        _gCurrentChunkIndex = ci + 1;
        _gTotalChunks = chunkDescs.length;

        sendPort.send({
          'type': 'progress',
          'progress': _gChunkBaseProgress,
          'timestampMs': chunkOffsetMs,
          'message': 'Transcribing chunk ${ci + 1}/${chunkDescs.length}...',
        });

        // Allocate native float buffer for this chunk
        // Read only this chunk's samples from disk (streaming)
        final chunkSamples = wavReader.readSamples(desc.offset, desc.length);
        final nativeSamples = malloc<Float>(chunkSamples.length);
        try {
          nativeSamples
              .asTypedList(chunkSamples.length)
              .setAll(0, chunkSamples);

          // Configure whisper
          final configPtr = calloc<WhisperConfigNative>();
          Pointer<Utf8>? languagePtr;

          try {
            final config = configPtr.ref
              ..nThreads = params.nThreads > 0
                  ? params.nThreads.clamp(1, 32)
                  : Platform.numberOfProcessors.clamp(1, 16)
              ..useGpu = params.asrGpuEnabled
              ..gpuDevice = params.asrGpuDevice < 0
                  ? 0
                  : params.asrGpuDevice
              ..translate = params.translateToEnglish
              ..wordTimestamps = true
              ..wordThreshold = 0.01
              ..maxSegmentLength = 0
              ..splitOnWord = true
              ..temperature = 0.0
              ..beamSize = params.beamSize
              ..entropyThreshold = 2.4
              ..suppressBlank = true
              ..suppressNonSpeech = true
              ..noSpeechThreshold = 0.6;

            if (params.language != null && params.language != 'auto') {
              languagePtr = params.language!.toNativeUtf8();
              config.language = languagePtr;
            } else {
              config.language = nullptr;
            }

            // Run the (blocking) transcription for this chunk
            final resultPtr = whisperTranscribePcm(
              modelHandle,
              nativeSamples,
              chunkSamples.length,
              configPtr,
            );

            if (resultPtr == nullptr) {
              final errorPtr = whisperGetError?.call();
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

              // Grab detected language from the first chunk
              if (detectedLanguage == null &&
                  result.detectedLanguage != nullptr) {
                detectedLanguage =
                    _safeUtf8(result.detectedLanguage);
              }

              // Extract segments with timestamps adjusted by chunk offset
              final chunkSegments = _extractSegments(
                resultPtr,
                chunkOffsetMs,
                ci,
              );

              // Trim segments in the overlap region so each absolute
              // timestamp is owned by exactly one chunk.
              const overlapMs = kOverlapDurationSec * 1000;
              final trimmed = _trimOverlap(
                chunkSegments,
                chunkOffsetMs: chunkOffsetMs,
                chunkDurationMs: chunkDurMs,
                overlapMs: overlapMs,
                isFirst: desc.isFirst,
                isLast: desc.isLast,
              );

              allSegments.addAll(trimmed);

              // Stream completed segments progressively
              for (final seg in trimmed) {
                sendPort.send({
                  'type': 'segment',
                  'segment': {
                    'id': seg.id,
                    'text': seg.text,
                    'startTimeMs': seg.startTime.inMilliseconds,
                    'endTimeMs': seg.endTime.inMilliseconds,
                  },
                });
              }

              // Send ETA-enriched progress update after this chunk completes
              final elapsed = stopwatch.elapsedMilliseconds;
              final chunksRemaining = chunkDescs.length - (ci + 1);
              final msPerChunk = elapsed / (ci + 1);
              final etaMs = (msPerChunk * chunksRemaining).round();
              final segCount = allSegments.length;

              final etaMessage = chunksRemaining > 0
                  ? 'Chunk ${ci + 1}/${chunkDescs.length} — $segCount segments — ETA: ${_formatEta(etaMs)}'
                  : 'Finalizing... ($segCount segments)';

              sendPort.send({
                'type': 'progress',
                'progress': (progressBase + ((ci + 1) / chunkDescs.length) * progressRange).clamp(0.0, 1.0),
                'timestampMs': chunkOffsetMs + chunkDurMs,
                'message': etaMessage,
              });
            } finally {
              whisperFreeResult(resultPtr);
            }
          } finally {
            calloc.free(configPtr);
            if (languagePtr != null) malloc.free(languagePtr);
          }
        } finally {
          malloc.free(nativeSamples);
        }
      }

      // ── 7. Re-number segment IDs sequentially ────────────────────────
      final finalSegments = <TranscriptSegment>[
        for (int i = 0; i < allSegments.length; i++)
          TranscriptSegment(
            id: 'segment_$i',
            text: allSegments[i].text,
            startTime: allSegments[i].startTime,
            endTime: allSegments[i].endTime,
            words: allSegments[i].words,
          ),
      ];

      final transcript = Transcript(
        segments: finalSegments,
        language: detectedLanguage ?? 'en',
        modelId: p.basename(params.modelPath),
      );

      sendPort
        ..send({
          'type': 'progress',
          'progress': 1.0,
          'timestampMs': totalDurationMs,
          'message': 'Complete!',
        })
        ..send({'type': 'result', 'transcript': transcript});
      } finally {
        wavReader.close();
      }
    } finally {
      whisperFree(modelHandle);
    }
  } catch (e) {
    sendPort.send({'type': 'error', 'message': e.toString()});
  } finally {
    _gSendPort = null;
  }
}

// ============================================================================
// Legacy single-shot entry point (kept for backward compatibility / tests)
// ============================================================================

/// Performs whisper transcription entirely within an isolate (single chunk,
/// no progress reporting).
///
/// This is a **top-level function** so it can be used with [Isolate.run].
Transcript performTranscriptionInIsolate(TranscriptionIsolateParams params) {
  // Open the native library in this isolate
  final lib = DynamicLibrary.open(params.libraryPath);

  final whisperInit = lib
      .lookup<NativeFunction<WhisperInitNative>>('kl_whisper_init')
      .asFunction<WhisperInitDart>();

  WhisperInitWithConfigDart? whisperInitWithConfig;
  try {
    whisperInitWithConfig = lib
        .lookup<NativeFunction<WhisperInitWithConfigNative>>(
            'kl_whisper_init_with_config',)
        .asFunction<WhisperInitWithConfigDart>();
  } catch (_) {
    // Optional in older builds
  }

  final whisperFree = lib
      .lookup<NativeFunction<WhisperFreeNative>>('kl_whisper_free')
      .asFunction<WhisperFreeDart>();

  final whisperTranscribeFile = lib
      .lookup<NativeFunction<WhisperTranscribeFileNative>>(
          'kl_whisper_transcribe_file',)
      .asFunction<WhisperTranscribeFileDart>();

  final whisperFreeResult = lib
      .lookup<NativeFunction<WhisperFreeResultNative>>(
          'kl_whisper_free_result',)
      .asFunction<WhisperFreeResultDart>();

  WhisperGetErrorDart? whisperGetError;
  try {
    whisperGetError = lib
        .lookup<NativeFunction<WhisperGetErrorNative>>('kl_whisper_get_error')
        .asFunction<WhisperGetErrorDart>();
  } catch (_) {}

  final modelPathPtr = params.modelPath.toNativeUtf8();
  final initConfigPtr = calloc<WhisperConfigNative>();
  Pointer modelHandle;
  try {
    final initConfig = initConfigPtr.ref
      ..nThreads = params.nThreads > 0
          ? params.nThreads.clamp(1, 32)
          : Platform.numberOfProcessors.clamp(1, 16)
      ..useGpu = params.asrGpuEnabled
      ..gpuDevice = params.asrGpuDevice < 0 ? 0 : params.asrGpuDevice
      ..language = nullptr
      ..translate = params.translateToEnglish
      ..wordTimestamps = true
      ..wordThreshold = 0.01
      ..maxSegmentLength = 0
      ..splitOnWord = true
      ..temperature = 0.0
      ..beamSize = params.beamSize
      ..entropyThreshold = 2.4
      ..suppressBlank = true
      ..suppressNonSpeech = true
      ..noSpeechThreshold = 0.6;

    modelHandle = whisperInitWithConfig != null
        ? whisperInitWithConfig(modelPathPtr, initConfigPtr)
        : whisperInit(modelPathPtr);
  } finally {
    malloc.free(modelPathPtr);
    calloc.free(initConfigPtr);
  }

  if (modelHandle == nullptr) {
    final errorPtr = whisperGetError?.call();
    final error = errorPtr != null && errorPtr != nullptr
        ? errorPtr.toDartString()
        : 'Unknown error';
    throw WhisperModelLoadException(
        'Failed to load model in isolate: $error',);
  }

  final configPtr = calloc<WhisperConfigNative>();
  final audioPathPtr = params.audioPath.toNativeUtf8();
  Pointer<Utf8>? languagePtr;

  try {
    final config = configPtr.ref
      ..nThreads = params.nThreads > 0
          ? params.nThreads.clamp(1, 32)
          : Platform.numberOfProcessors.clamp(1, 16)
      ..useGpu = params.asrGpuEnabled
      ..gpuDevice = params.asrGpuDevice < 0 ? 0 : params.asrGpuDevice
      ..translate = params.translateToEnglish
      ..wordTimestamps = true
      ..wordThreshold = 0.01
      ..maxSegmentLength = 0
      ..splitOnWord = true
      ..temperature = 0.0
      ..beamSize = params.beamSize
      ..entropyThreshold = 2.4
      ..suppressBlank = true
      ..suppressNonSpeech = true
      ..noSpeechThreshold = 0.6;

    if (params.language != null && params.language != 'auto') {
      languagePtr = params.language!.toNativeUtf8();
      config.language = languagePtr;
    } else {
      config.language = nullptr;
    }

    final resultPtr = whisperTranscribeFile(
      modelHandle,
      audioPathPtr,
      configPtr,
    );

    if (resultPtr == nullptr) {
      final errorPtr = whisperGetError?.call();
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

      return _convertNativeResult(resultPtr, params.modelPath);
    } finally {
      whisperFreeResult(resultPtr);
    }
  } finally {
    calloc.free(configPtr);
    malloc.free(audioPathPtr);
    if (languagePtr != null) malloc.free(languagePtr);
    whisperFree(modelHandle);
  }
}

// ============================================================================
// WAV reader
// ============================================================================

/// Streaming WAV reader that reads samples on demand from disk.
///
/// Instead of loading the entire WAV file into memory, this class
/// parses the header once and then reads only the samples needed
/// for each chunk via [RandomAccessFile] seeks.
///
/// This reduces peak memory from ~460 MB (2-hour file) to ~4 MB
/// (one 30-second chunk at a time).
class _WavReader {
  _WavReader(String filePath) : _raf = File(filePath).openSync();

  final RandomAccessFile _raf;
  int _dataOffset = -1;
  int _totalSamples = 0;

  /// Total number of PCM samples in the file.
  int get totalSamples => _totalSamples;

  /// Parse the WAV header and locate the data chunk.
  ///
  /// Must be called before [readSamples]. Throws on invalid WAV.
  void parseHeader() {
    _raf.setPositionSync(0);
    final header = _raf.readSync(12);
    if (header.length < 12) {
      throw WhisperTranscriptionException('WAV file too short');
    }

    final riff = String.fromCharCodes(header.sublist(0, 4));
    if (riff != 'RIFF') {
      throw WhisperTranscriptionException(
          'Not a valid WAV file (no RIFF header)',);
    }

    final wave = String.fromCharCodes(header.sublist(8, 12));
    if (wave != 'WAVE') {
      throw WhisperTranscriptionException(
          'Not a valid WAV file (no WAVE tag)',);
    }

    // Walk chunks to find "data"
    var offset = 12;
    final fileLength = _raf.lengthSync();

    while (offset + 8 <= fileLength) {
      _raf.setPositionSync(offset);
      final chunkHeader = _raf.readSync(8);
      if (chunkHeader.length < 8) break;

      final chunkId = String.fromCharCodes(chunkHeader.sublist(0, 4));
      final bd = ByteData.sublistView(Uint8List.fromList(chunkHeader));
      final chunkSize = bd.getUint32(4, Endian.little);

      if (chunkId == 'data') {
        _dataOffset = offset + 8;
        _totalSamples = chunkSize ~/ 2; // 16-bit PCM → 2 bytes per sample
        return;
      }

      // Advance to next chunk; chunks are word-aligned
      offset += 8 + chunkSize;
      if (chunkSize.isOdd) offset++;
    }

    throw WhisperTranscriptionException('WAV file has no data chunk');
  }

  /// Read [count] PCM samples starting at [offsetSamples] and return
  /// as Float32 in [-1.0, 1.0].
  ///
  /// Only the requested samples are read from disk — the rest of the
  /// file is never touched.
  Float32List readSamples(int offsetSamples, int count) {
    if (_dataOffset < 0) {
      throw StateError('parseHeader() must be called before readSamples()');
    }
    final actualCount = count.clamp(0, _totalSamples - offsetSamples);
    if (actualCount <= 0) return Float32List(0);

    final byteOffset = _dataOffset + offsetSamples * 2;
    _raf.setPositionSync(byteOffset);
    final rawBytes = _raf.readSync(actualCount * 2);

    final int16View = rawBytes.buffer.asInt16List(
      rawBytes.offsetInBytes,
      rawBytes.lengthInBytes ~/ 2,
    );
    final samples = Float32List(int16View.length);
    for (var i = 0; i < int16View.length; i++) {
      samples[i] = int16View[i] / 32768.0;
    }
    return samples;
  }

  /// Close the underlying file handle.
  void close() {
    _raf.closeSync();
  }
}

// ============================================================================
// Segment extraction with offset adjustment
// ============================================================================

/// Extracts [TranscriptSegment]s from a native result, shifting every
/// timestamp by [offsetMs] so they become absolute within the full audio.
List<TranscriptSegment> _extractSegments(
  Pointer<WhisperResultNative> resultPtr,
  int offsetMs,
  int chunkIndex,
) {
  final result = resultPtr.ref;
  final segments = <TranscriptSegment>[];

  for (var i = 0; i < result.numSegments; i++) {
    final nativeSeg = (result.segments + i).ref;

    final words = <TranscriptWord>[];
    for (var j = 0; j < nativeSeg.numWords; j++) {
      final nativeWord = (nativeSeg.words + j).ref;
      words.add(
        TranscriptWord(
          word: nativeWord.text != nullptr
              ? _safeUtf8(nativeWord.text)
              : '',
          startTime: Duration(milliseconds: nativeWord.startMs + offsetMs),
          endTime: Duration(milliseconds: nativeWord.endMs + offsetMs),
          confidence: nativeWord.probability,
        ),
      );
    }

    segments.add(
      TranscriptSegment(
        id: 'chunk${chunkIndex}_seg_$i',
        text: nativeSeg.text != nullptr ? _safeUtf8(nativeSeg.text) : '',
        startTime: Duration(milliseconds: nativeSeg.startMs + offsetMs),
        endTime: Duration(milliseconds: nativeSeg.endMs + offsetMs),
        words: words,
      ),
    );
  }

  return segments;
}

// ============================================================================
// Overlap trimming / stitching
// ============================================================================

/// Trims segments so each chunk only keeps segments in its "owned" region.
///
/// For two adjacent chunks that share an overlap of duration *O*, the owned
/// boundary sits at the midpoint of the overlap:
///
/// ```
/// Chunk i  :  [────────────────────|===]      overlap region ===
/// Chunk i+1:                   [===|────────────────────]
///                                  ^ midpoint
/// ```
///
/// * Chunk *i* keeps segments whose [startTime] < midpoint.
/// * Chunk *i+1* keeps segments whose [startTime] >= midpoint.
List<TranscriptSegment> _trimOverlap(
  List<TranscriptSegment> segments, {
  required int chunkOffsetMs,
  required int chunkDurationMs,
  required int overlapMs,
  required bool isFirst,
  required bool isLast,
}) {
  final halfOverlap = overlapMs ~/ 2;

  // Absolute timestamp range this chunk "owns"
  final ownedStart = Duration(
    milliseconds: isFirst ? chunkOffsetMs : chunkOffsetMs + halfOverlap,
  );
  final ownedEnd = Duration(
    milliseconds: isLast
        ? chunkOffsetMs + chunkDurationMs
        : chunkOffsetMs + chunkDurationMs - halfOverlap,
  );

  return segments
      .where((s) => s.startTime >= ownedStart && s.startTime < ownedEnd)
      .toList();
}

// ============================================================================
// Legacy helpers
// ============================================================================

/// Convert native WhisperResult to a Dart [Transcript] (no offset adjustment).
Transcript _convertNativeResult(
  Pointer<WhisperResultNative> resultPtr,
  String modelPath,
) {
  final result = resultPtr.ref;
  final segments = <TranscriptSegment>[];

  for (var i = 0; i < result.numSegments; i++) {
    final nativeSeg = (result.segments + i).ref;

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
