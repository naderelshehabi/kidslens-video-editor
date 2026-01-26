# KidsLens - AI Models Technical Reference v2.0

## Overview

This document provides detailed technical specifications for all AI models used in KidsLens, including integration patterns, performance characteristics, and implementation guidelines. All integrations use custom FFI bindings - no third-party Flutter packages.

---

## 1. Speech Recognition (ASR)

### 1.1 OpenAI Whisper via whisper.cpp

#### Model Specifications

| Model | Parameters | RAM | Disk | Speed | English WER | Use Case |
|-------|------------|-----|------|-------|-------------|----------|
| tiny | 39M | ~1GB | 75MB | ~10x | ~10.0% | Quick preview |
| tiny.en | 39M | ~1GB | 75MB | ~10x | ~8.0% | English only, fast |
| base | 74M | ~1GB | 142MB | ~7x | ~7.0% | Balanced low-end |
| base.en | 74M | ~1GB | 142MB | ~7x | ~5.5% | English only |
| small | 244M | ~2GB | 466MB | ~4x | ~5.0% | **Recommended default** |
| small.en | 244M | ~2GB | 466MB | ~4x | ~4.0% | English only |
| medium | 769M | ~5GB | 1.5GB | ~2x | ~4.5% | High accuracy |
| medium.en | 769M | ~5GB | 1.5GB | ~2x | ~3.5% | English only |
| large-v3 | 1550M | ~10GB | 2.9GB | 1x | ~2.5% | Maximum accuracy |
| large-v3-turbo | 809M | ~6GB | 1.6GB | ~4x | ~3.0% | **Best speed/accuracy** |

#### Hardware Acceleration Support

| Backend | Platforms | Notes |
|---------|-----------|-------|
| CPU (AVX/AVX2/AVX512) | All | Default, optimized SIMD |
| CUDA | Windows, Linux | NVIDIA GPUs (Compute 6.0+) |
| cuBLAS | Windows, Linux | NVIDIA matrix acceleration |
| Metal | macOS | Apple Silicon/Intel |
| Vulkan | All | Cross-platform GPU |
| CoreML | macOS | Apple Neural Engine |

#### Model Download URLs

```
https://huggingface.co/ggerganov/whisper.cpp/resolve/main/ggml-{model}.bin
```

Where `{model}` is: `tiny`, `tiny.en`, `base`, `base.en`, `small`, `small.en`, `medium`, `medium.en`, `large-v3`, `large-v3-turbo`

#### whisper.cpp FFI Wrapper

```c
// native/whisper/whisper_wrapper.h

#ifndef WHISPER_WRAPPER_H
#define WHISPER_WRAPPER_H

#include <stdint.h>
#include <stdbool.h>

#ifdef _WIN32
  #define EXPORT __declspec(dllexport)
#else
  #define EXPORT __attribute__((visibility("default")))
#endif

#ifdef __cplusplus
extern "C" {
#endif

// Opaque handle
typedef struct whisper_context* WhisperHandle;

// Word-level timestamp info
typedef struct {
    int64_t t0_ms;        // Start timestamp (milliseconds)
    int64_t t1_ms;        // End timestamp (milliseconds)
    const char* text;     // Word text (null-terminated)
    float probability;    // Confidence 0.0-1.0
} WhisperWord;

// Segment with word timestamps
typedef struct {
    int64_t t0_ms;
    int64_t t1_ms;
    const char* text;
    float probability;
    int num_words;
    WhisperWord* words;
} WhisperSegment;

// Transcription result
typedef struct {
    int num_segments;
    WhisperSegment* segments;
    const char* detected_language;
    float language_probability;
    int64_t processing_time_ms;
} WhisperResult;

// Configuration
typedef struct {
    int n_threads;           // CPU threads (0 = auto)
    bool use_gpu;            // Enable GPU acceleration
    int gpu_device;          // GPU device index
    const char* language;    // Language code or "auto"
    bool translate;          // Translate to English
    bool word_timestamps;    // Enable word-level timestamps
    float word_thold;        // Word probability threshold
    int max_len;             // Max segment length (chars)
    bool split_on_word;      // Split on word boundaries
    float temperature;       // Sampling temperature
    int beam_size;           // Beam search width (1 = greedy)
    float entropy_thold;     // Entropy threshold for fallback
} WhisperConfig;

// API Functions
EXPORT WhisperHandle whisper_init(const char* model_path);
EXPORT void whisper_free(WhisperHandle handle);
EXPORT WhisperConfig whisper_default_config(void);

// Transcribe from file
EXPORT WhisperResult* whisper_transcribe_file(
    WhisperHandle handle,
    const char* audio_path,
    WhisperConfig* config
);

// Transcribe from PCM buffer (16kHz, mono, float32)
EXPORT WhisperResult* whisper_transcribe_pcm(
    WhisperHandle handle,
    const float* samples,
    int num_samples,
    WhisperConfig* config
);

// Free result
EXPORT void whisper_free_result(WhisperResult* result);

// Get last error
EXPORT const char* whisper_get_error(void);

// Check GPU availability
EXPORT bool whisper_gpu_available(void);
EXPORT const char* whisper_gpu_name(void);

#ifdef __cplusplus
}
#endif

#endif // WHISPER_WRAPPER_H
```

#### Dart FFI Bindings

```dart
// lib/native/bindings/whisper_bindings.dart

import 'dart:ffi';
import 'dart:io';
import 'package:ffi/ffi.dart';

// Load native library
DynamicLibrary _loadWhisperLib() {
  if (Platform.isWindows) {
    return DynamicLibrary.open('whisper_wrapper.dll');
  } else if (Platform.isMacOS) {
    return DynamicLibrary.open('libwhisper_wrapper.dylib');
  } else if (Platform.isLinux) {
    return DynamicLibrary.open('libwhisper_wrapper.so');
  }
  throw UnsupportedError('Platform not supported');
}

// FFI Type Definitions
final class WhisperWordNative extends Struct {
  @Int64()
  external int t0Ms;
  
  @Int64()
  external int t1Ms;
  
  external Pointer<Utf8> text;
  
  @Float()
  external double probability;
}

final class WhisperSegmentNative extends Struct {
  @Int64()
  external int t0Ms;
  
  @Int64()
  external int t1Ms;
  
  external Pointer<Utf8> text;
  
  @Float()
  external double probability;
  
  @Int32()
  external int numWords;
  
  external Pointer<WhisperWordNative> words;
}

final class WhisperResultNative extends Struct {
  @Int32()
  external int numSegments;
  
  external Pointer<WhisperSegmentNative> segments;
  
  external Pointer<Utf8> detectedLanguage;
  
  @Float()
  external double languageProbability;
  
  @Int64()
  external int processingTimeMs;
}

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
  external double wordThold;
  
  @Int32()
  external int maxLen;
  
  @Bool()
  external bool splitOnWord;
  
  @Float()
  external double temperature;
  
  @Int32()
  external int beamSize;
  
  @Float()
  external double entropyThold;
}

// Function signatures
typedef WhisperInitNative = Pointer Function(Pointer<Utf8> modelPath);
typedef WhisperInit = Pointer Function(Pointer<Utf8> modelPath);

typedef WhisperFreeNative = Void Function(Pointer handle);
typedef WhisperFree = void Function(Pointer handle);

typedef WhisperTranscribeFileNative = Pointer<WhisperResultNative> Function(
  Pointer handle,
  Pointer<Utf8> audioPath,
  Pointer<WhisperConfigNative> config,
);
typedef WhisperTranscribeFile = Pointer<WhisperResultNative> Function(
  Pointer handle,
  Pointer<Utf8> audioPath,
  Pointer<WhisperConfigNative> config,
);

typedef WhisperFreeResultNative = Void Function(Pointer<WhisperResultNative> result);
typedef WhisperFreeResult = void Function(Pointer<WhisperResultNative> result);

typedef WhisperGpuAvailableNative = Bool Function();
typedef WhisperGpuAvailable = bool Function();

/// Whisper FFI bindings
class WhisperBindings {
  late final DynamicLibrary _lib;
  late final WhisperInit _init;
  late final WhisperFree _free;
  late final WhisperTranscribeFile _transcribeFile;
  late final WhisperFreeResult _freeResult;
  late final WhisperGpuAvailable _gpuAvailable;
  
  WhisperBindings() {
    _lib = _loadWhisperLib();
    
    _init = _lib
        .lookup<NativeFunction<WhisperInitNative>>('whisper_init')
        .asFunction();
    
    _free = _lib
        .lookup<NativeFunction<WhisperFreeNative>>('whisper_free')
        .asFunction();
    
    _transcribeFile = _lib
        .lookup<NativeFunction<WhisperTranscribeFileNative>>('whisper_transcribe_file')
        .asFunction();
    
    _freeResult = _lib
        .lookup<NativeFunction<WhisperFreeResultNative>>('whisper_free_result')
        .asFunction();
    
    _gpuAvailable = _lib
        .lookup<NativeFunction<WhisperGpuAvailableNative>>('whisper_gpu_available')
        .asFunction();
  }
  
  Pointer init(String modelPath) {
    final pathPtr = modelPath.toNativeUtf8();
    try {
      return _init(pathPtr);
    } finally {
      malloc.free(pathPtr);
    }
  }
  
  void free(Pointer handle) => _free(handle);
  
  bool get gpuAvailable => _gpuAvailable();
  
  Pointer<WhisperResultNative> transcribeFile(
    Pointer handle,
    String audioPath,
    WhisperConfigNative config,
  ) {
    final pathPtr = audioPath.toNativeUtf8();
    final configPtr = malloc<WhisperConfigNative>();
    configPtr.ref = config;
    
    try {
      return _transcribeFile(handle, pathPtr, configPtr);
    } finally {
      malloc.free(pathPtr);
      malloc.free(configPtr);
    }
  }
  
  void freeResult(Pointer<WhisperResultNative> result) => _freeResult(result);
}
```

---

### 1.2 Meta MMS (Massively Multilingual Speech)

Meta's MMS supports 1,100+ languages, far exceeding Whisper's 99 languages. Essential for low-resource language support.

#### Model Specifications

| Model | Languages | Parameters | Disk | RAM | Speed | Notes |
|-------|-----------|------------|------|-----|-------|-------|
| MMS-1B-all | 1,100+ | 1B | 4GB | ~8GB | ~2x | Best coverage |
| MMS-1B-fl102 | 102 | 1B | 4GB | ~8GB | ~2x | Common languages |
| MMS-300M | 1,100+ | 300M | 1.2GB | ~3GB | ~4x | Lighter weight |

#### MMS vs Whisper Comparison

| Aspect | Whisper | MMS |
|--------|---------|-----|
| Languages | 99 | 1,100+ |
| English accuracy | Better | Good |
| Low-resource languages | Limited | **Excellent** |
| Word timestamps | Native | Requires alignment |
| License | MIT | MIT |
| Speed | Faster | Moderate |

#### MMS Integration (via fairseq2)

MMS uses fairseq2 which requires Python/PyTorch. We embed a Python subprocess or use a pre-compiled native binary.

```c
// native/mms/mms_wrapper.h

#ifndef MMS_WRAPPER_H
#define MMS_WRAPPER_H

#include <stdint.h>
#include <stdbool.h>

#ifdef _WIN32
  #define EXPORT __declspec(dllexport)
#else
  #define EXPORT __attribute__((visibility("default")))
#endif

#ifdef __cplusplus
extern "C" {
#endif

typedef struct mms_context* MMSHandle;

// Word with timing (after forced alignment)
typedef struct {
    int64_t t0_ms;
    int64_t t1_ms;
    const char* text;
    float confidence;
} MMSWord;

// Transcription segment
typedef struct {
    int64_t t0_ms;
    int64_t t1_ms;
    const char* text;
    int num_words;
    MMSWord* words;
} MMSSegment;

// Result
typedef struct {
    int num_segments;
    MMSSegment* segments;
    const char* detected_language;
    int64_t processing_time_ms;
} MMSResult;

// Configuration
typedef struct {
    const char* language;       // ISO 639-3 code or "auto"
    bool use_gpu;
    int gpu_device;
    int n_threads;
    bool compute_word_timestamps;  // Requires MMS-FA model
} MMSConfig;

// API
EXPORT MMSHandle mms_init(const char* model_path, const char* alignment_model_path);
EXPORT void mms_free(MMSHandle handle);
EXPORT MMSConfig mms_default_config(void);

EXPORT MMSResult* mms_transcribe(
    MMSHandle handle,
    const float* samples,
    int num_samples,
    int sample_rate,
    MMSConfig* config
);

EXPORT void mms_free_result(MMSResult* result);

// Language detection
EXPORT const char* mms_detect_language(
    MMSHandle handle,
    const float* samples,
    int num_samples,
    int sample_rate
);

// List supported languages
EXPORT int mms_num_languages(MMSHandle handle);
EXPORT const char* mms_get_language(MMSHandle handle, int index);

EXPORT const char* mms_get_error(void);
EXPORT bool mms_gpu_available(void);

#ifdef __cplusplus
}
#endif

#endif // MMS_WRAPPER_H
```

#### MMS Dart Bindings

```dart
// lib/native/bindings/mms_bindings.dart

import 'dart:ffi';
import 'dart:io';
import 'package:ffi/ffi.dart';

DynamicLibrary _loadMMSLib() {
  if (Platform.isWindows) {
    return DynamicLibrary.open('mms_wrapper.dll');
  } else if (Platform.isMacOS) {
    return DynamicLibrary.open('libmms_wrapper.dylib');
  } else if (Platform.isLinux) {
    return DynamicLibrary.open('libmms_wrapper.so');
  }
  throw UnsupportedError('Platform not supported');
}

final class MMSWordNative extends Struct {
  @Int64()
  external int t0Ms;
  
  @Int64()
  external int t1Ms;
  
  external Pointer<Utf8> text;
  
  @Float()
  external double confidence;
}

final class MMSSegmentNative extends Struct {
  @Int64()
  external int t0Ms;
  
  @Int64()
  external int t1Ms;
  
  external Pointer<Utf8> text;
  
  @Int32()
  external int numWords;
  
  external Pointer<MMSWordNative> words;
}

final class MMSResultNative extends Struct {
  @Int32()
  external int numSegments;
  
  external Pointer<MMSSegmentNative> segments;
  
  external Pointer<Utf8> detectedLanguage;
  
  @Int64()
  external int processingTimeMs;
}

final class MMSConfigNative extends Struct {
  external Pointer<Utf8> language;
  
  @Bool()
  external bool useGpu;
  
  @Int32()
  external int gpuDevice;
  
  @Int32()
  external int nThreads;
  
  @Bool()
  external bool computeWordTimestamps;
}

class MMSBindings {
  late final DynamicLibrary _lib;
  // ... function pointers similar to WhisperBindings
  
  MMSBindings() {
    _lib = _loadMMSLib();
    // Initialize function pointers
  }
}
```

#### ASR Service with Model Selection

```dart
// lib/services/asr_service.dart

import 'dart:async';
import '../native/bindings/whisper_bindings.dart';
import '../native/bindings/mms_bindings.dart';
import '../data/models/transcript.dart';

enum ASREngine {
  whisper,
  mms,
}

enum WhisperModel {
  tiny('tiny', 75),
  tinyEn('tiny.en', 75),
  base('base', 142),
  baseEn('base.en', 142),
  small('small', 466),
  smallEn('small.en', 466),
  medium('medium', 1500),
  mediumEn('medium.en', 1500),
  largeV3('large-v3', 2900),
  largeV3Turbo('large-v3-turbo', 1600);
  
  final String id;
  final int sizeMB;
  const WhisperModel(this.id, this.sizeMB);
}

enum MMSModel {
  mms1bAll('mms-1b-all', 4000, 1100),
  mms1bFl102('mms-1b-fl102', 4000, 102),
  mms300m('mms-300m', 1200, 1100);
  
  final String id;
  final int sizeMB;
  final int languageCount;
  const MMSModel(this.id, this.sizeMB, this.languageCount);
}

class ASRConfig {
  final ASREngine engine;
  final WhisperModel? whisperModel;
  final MMSModel? mmsModel;
  final String? language;
  final bool wordTimestamps;
  final bool useGpu;
  
  ASRConfig({
    required this.engine,
    this.whisperModel,
    this.mmsModel,
    this.language,
    this.wordTimestamps = true,
    this.useGpu = true,
  }) : assert(
    (engine == ASREngine.whisper && whisperModel != null) ||
    (engine == ASREngine.mms && mmsModel != null),
    'Model must be specified for selected engine',
  );
  
  static ASRConfig whisperDefault() => ASRConfig(
    engine: ASREngine.whisper,
    whisperModel: WhisperModel.small,
  );
  
  static ASRConfig mmsDefault() => ASRConfig(
    engine: ASREngine.mms,
    mmsModel: MMSModel.mms1bAll,
  );
}

class ASRService {
  final WhisperBindings _whisper = WhisperBindings();
  final MMSBindings _mms = MMSBindings();
  
  Pointer? _whisperHandle;
  Pointer? _mmsHandle;
  ASRConfig? _currentConfig;
  
  Future<void> initialize(ASRConfig config) async {
    _currentConfig = config;
    
    switch (config.engine) {
      case ASREngine.whisper:
        final modelPath = await _getModelPath(config.whisperModel!);
        _whisperHandle = _whisper.init(modelPath);
        break;
        
      case ASREngine.mms:
        final modelPath = await _getModelPath(config.mmsModel!);
        final alignPath = await _getAlignmentModelPath();
        _mmsHandle = _mms.init(modelPath, alignPath);
        break;
    }
  }
  
  Future<Transcript> transcribe(
    String audioPath, {
    StreamController<double>? progress,
  }) async {
    switch (_currentConfig!.engine) {
      case ASREngine.whisper:
        return _transcribeWithWhisper(audioPath, progress);
      case ASREngine.mms:
        return _transcribeWithMMS(audioPath, progress);
    }
  }
  
  Future<Transcript> _transcribeWithWhisper(
    String audioPath,
    StreamController<double>? progress,
  ) async {
    final config = WhisperConfigNative()
      ..nThreads = 0  // Auto
      ..useGpu = _currentConfig!.useGpu && _whisper.gpuAvailable
      ..gpuDevice = 0
      ..wordTimestamps = _currentConfig!.wordTimestamps
      ..wordThold = 0.6
      ..maxLen = 0
      ..splitOnWord = true
      ..temperature = 0.0
      ..beamSize = 5
      ..entropyThold = 2.4;
    
    if (_currentConfig!.language != null) {
      config.language = _currentConfig!.language!.toNativeUtf8();
    }
    
    final result = _whisper.transcribeFile(
      _whisperHandle!,
      audioPath,
      config,
    );
    
    try {
      return _convertWhisperResult(result);
    } finally {
      _whisper.freeResult(result);
    }
  }
  
  Future<Transcript> _transcribeWithMMS(
    String audioPath,
    StreamController<double>? progress,
  ) async {
    // Load audio, convert to PCM
    final samples = await _loadAudioAsPCM(audioPath);
    
    final config = MMSConfigNative()
      ..useGpu = _currentConfig!.useGpu && _mms.gpuAvailable
      ..gpuDevice = 0
      ..nThreads = 0
      ..computeWordTimestamps = _currentConfig!.wordTimestamps;
    
    if (_currentConfig!.language != null) {
      config.language = _currentConfig!.language!.toNativeUtf8();
    }
    
    final result = _mms.transcribe(
      _mmsHandle!,
      samples.data,
      samples.length,
      16000,
      config,
    );
    
    try {
      return _convertMMSResult(result);
    } finally {
      _mms.freeResult(result);
    }
  }
  
  void dispose() {
    if (_whisperHandle != null) {
      _whisper.free(_whisperHandle!);
      _whisperHandle = null;
    }
    if (_mmsHandle != null) {
      _mms.free(_mmsHandle!);
      _mmsHandle = null;
    }
  }
}
```

---

## 2. Visual Content Detection

### 2.1 NSFW/Nudity Detection

#### Model Options

| Model | Architecture | Input Size | Accuracy | Speed | Size | License |
|-------|--------------|------------|----------|-------|------|---------|
| nsfw-mobilenet-v2 | MobileNetV2 | 224×224 | 91% | Fast | 20MB | MIT |
| nsfw-inception-v3 | InceptionV3 | 299×299 | 93% | Medium | 95MB | MIT |
| nsfw-efficientnet-b4 | EfficientNet-B4 | 380×380 | 95% | Slow | 75MB | Apache 2.0 |

#### Output Categories

```dart
enum NSFWCategory {
  drawings,   // Anime/cartoon content
  hentai,     // Animated adult content
  neutral,    // Safe content
  porn,       // Explicit content
  sexy,       // Suggestive but not explicit
}

class NSFWResult {
  final Map<NSFWCategory, double> scores;
  
  double get safeScore => scores[NSFWCategory.neutral] ?? 0.0;
  double get unsafeScore => 1.0 - safeScore;
  
  bool get isUnsafe => unsafeScore > 0.6;
  
  NSFWCategory get dominantCategory =>
      scores.entries.reduce((a, b) => a.value > b.value ? a : b).key;
}
```

#### ONNX FFI Wrapper

```c
// native/onnx/onnx_wrapper.h

#ifndef ONNX_WRAPPER_H
#define ONNX_WRAPPER_H

#include <stdint.h>
#include <stdbool.h>

#ifdef _WIN32
  #define EXPORT __declspec(dllexport)
#else
  #define EXPORT __attribute__((visibility("default")))
#endif

#ifdef __cplusplus
extern "C" {
#endif

typedef struct onnx_session* ONNXSession;

// Tensor info
typedef struct {
    const char* name;
    int num_dims;
    int64_t* dims;
    int dtype;  // 0=float, 1=int64, 2=int32, etc.
} TensorInfo;

// Session configuration
typedef struct {
    int num_threads;
    bool use_gpu;
    int gpu_device;
    const char* execution_provider;  // "cpu", "cuda", "coreml", "rocm"
    int optimization_level;  // 0-3
} ONNXConfig;

// Create/destroy session
EXPORT ONNXSession onnx_create_session(const char* model_path, ONNXConfig* config);
EXPORT void onnx_destroy_session(ONNXSession session);

// Get model info
EXPORT int onnx_num_inputs(ONNXSession session);
EXPORT int onnx_num_outputs(ONNXSession session);
EXPORT TensorInfo* onnx_get_input_info(ONNXSession session, int index);
EXPORT TensorInfo* onnx_get_output_info(ONNXSession session, int index);
EXPORT void onnx_free_tensor_info(TensorInfo* info);

// Run inference
EXPORT int onnx_run(
    ONNXSession session,
    const char** input_names,
    const float** input_data,
    const int64_t** input_shapes,
    const int* input_num_dims,
    int num_inputs,
    const char** output_names,
    float** output_data,
    int64_t** output_shapes,
    int* output_num_dims,
    int num_outputs
);

// Batch inference
EXPORT int onnx_run_batch(
    ONNXSession session,
    const float* batch_data,
    int batch_size,
    const int64_t* input_shape,
    int input_num_dims,
    float* output_data,
    int64_t* output_shape,
    int* output_num_dims
);

// Error handling
EXPORT const char* onnx_get_error(void);

// GPU detection
EXPORT bool onnx_cuda_available(void);
EXPORT bool onnx_coreml_available(void);
EXPORT bool onnx_rocm_available(void);
EXPORT const char* onnx_gpu_name(void);

#ifdef __cplusplus
}
#endif

#endif // ONNX_WRAPPER_H
```

#### ONNX Dart Bindings

```dart
// lib/native/bindings/onnx_bindings.dart

import 'dart:ffi';
import 'dart:io';
import 'dart:typed_data';
import 'package:ffi/ffi.dart';

DynamicLibrary _loadONNXLib() {
  if (Platform.isWindows) {
    return DynamicLibrary.open('onnx_wrapper.dll');
  } else if (Platform.isMacOS) {
    return DynamicLibrary.open('libonnx_wrapper.dylib');
  } else if (Platform.isLinux) {
    return DynamicLibrary.open('libonnx_wrapper.so');
  }
  throw UnsupportedError('Platform not supported');
}

final class TensorInfoNative extends Struct {
  external Pointer<Utf8> name;
  
  @Int32()
  external int numDims;
  
  external Pointer<Int64> dims;
  
  @Int32()
  external int dtype;
}

final class ONNXConfigNative extends Struct {
  @Int32()
  external int numThreads;
  
  @Bool()
  external bool useGpu;
  
  @Int32()
  external int gpuDevice;
  
  external Pointer<Utf8> executionProvider;
  
  @Int32()
  external int optimizationLevel;
}

class ONNXBindings {
  late final DynamicLibrary _lib;
  late final Pointer Function(Pointer<Utf8>, Pointer<ONNXConfigNative>) _createSession;
  late final void Function(Pointer) _destroySession;
  late final int Function(Pointer, Pointer<Pointer<Utf8>>, Pointer<Pointer<Float>>,
      Pointer<Pointer<Int64>>, Pointer<Int32>, int,
      Pointer<Pointer<Utf8>>, Pointer<Pointer<Float>>,
      Pointer<Pointer<Int64>>, Pointer<Int32>, int) _run;
  late final bool Function() _cudaAvailable;
  late final bool Function() _coremlAvailable;
  
  ONNXBindings() {
    _lib = _loadONNXLib();
    // Initialize function pointers...
  }
  
  Pointer createSession(String modelPath, ONNXConfig config) {
    final pathPtr = modelPath.toNativeUtf8();
    final configPtr = malloc<ONNXConfigNative>();
    configPtr.ref.numThreads = config.numThreads;
    configPtr.ref.useGpu = config.useGpu;
    configPtr.ref.gpuDevice = config.gpuDevice;
    configPtr.ref.executionProvider = config.executionProvider.toNativeUtf8();
    configPtr.ref.optimizationLevel = config.optimizationLevel;
    
    try {
      return _createSession(pathPtr, configPtr);
    } finally {
      malloc.free(pathPtr);
      malloc.free(configPtr);
    }
  }
  
  void destroySession(Pointer session) => _destroySession(session);
  
  bool get cudaAvailable => _cudaAvailable();
  bool get coremlAvailable => _coremlAvailable();
}

class ONNXConfig {
  final int numThreads;
  final bool useGpu;
  final int gpuDevice;
  final String executionProvider;
  final int optimizationLevel;
  
  const ONNXConfig({
    this.numThreads = 0,
    this.useGpu = true,
    this.gpuDevice = 0,
    this.executionProvider = 'cpu',
    this.optimizationLevel = 3,
  });
}
```

#### Visual Analysis Service

```dart
// lib/services/visual_analysis_service.dart

import 'dart:typed_data';
import '../native/bindings/onnx_bindings.dart';
import '../data/models/frame_result.dart';

enum VisualModel {
  nsfwMobileNet('nsfw-mobilenet-v2', 224, 20),
  nsfwInception('nsfw-inception-v3', 299, 95),
  nsfwEfficientNet('nsfw-efficientnet-b4', 380, 75),
  violenceViT('violence-vit-base', 224, 330),
  violenceMobileNet('violence-mobilenet', 224, 15),
  bloodEfficientNet('blood-efficientnet-b2', 260, 35),
  weaponsYolo('weapons-yolov8s', 640, 22);
  
  final String id;
  final int inputSize;
  final int sizeMB;
  const VisualModel(this.id, this.inputSize, this.sizeMB);
}

class VisualAnalysisConfig {
  final VisualModel nsfwModel;
  final VisualModel violenceModel;
  final VisualModel? bloodModel;
  final VisualModel? weaponsModel;
  final bool useGpu;
  final int batchSize;
  
  const VisualAnalysisConfig({
    this.nsfwModel = VisualModel.nsfwInception,
    this.violenceModel = VisualModel.violenceViT,
    this.bloodModel,
    this.weaponsModel,
    this.useGpu = true,
    this.batchSize = 8,
  });
}

class VisualAnalysisService {
  final ONNXBindings _onnx = ONNXBindings();
  
  Pointer? _nsfwSession;
  Pointer? _violenceSession;
  Pointer? _bloodSession;
  Pointer? _weaponsSession;
  
  VisualAnalysisConfig? _config;
  
  Future<void> initialize(VisualAnalysisConfig config) async {
    _config = config;
    
    final onnxConfig = ONNXConfig(
      useGpu: config.useGpu && (_onnx.cudaAvailable || _onnx.coremlAvailable),
      executionProvider: _selectProvider(),
      optimizationLevel: 3,
    );
    
    _nsfwSession = _onnx.createSession(
      await _getModelPath(config.nsfwModel),
      onnxConfig,
    );
    
    _violenceSession = _onnx.createSession(
      await _getModelPath(config.violenceModel),
      onnxConfig,
    );
    
    if (config.bloodModel != null) {
      _bloodSession = _onnx.createSession(
        await _getModelPath(config.bloodModel!),
        onnxConfig,
      );
    }
    
    if (config.weaponsModel != null) {
      _weaponsSession = _onnx.createSession(
        await _getModelPath(config.weaponsModel!),
        onnxConfig,
      );
    }
  }
  
  String _selectProvider() {
    if (_onnx.cudaAvailable) return 'cuda';
    if (_onnx.coremlAvailable) return 'coreml';
    return 'cpu';
  }
  
  Future<FrameAnalysisResult> analyzeFrame(Uint8List frameData) async {
    // Preprocess frame for each model
    final nsfwInput = _preprocessFrame(
      frameData,
      _config!.nsfwModel.inputSize,
    );
    
    final violenceInput = _preprocessFrame(
      frameData,
      _config!.violenceModel.inputSize,
    );
    
    // Run inference
    final nsfwResult = await _runNSFW(nsfwInput);
    final violenceResult = await _runViolence(violenceInput);
    
    BloodResult? bloodResult;
    if (_bloodSession != null) {
      final bloodInput = _preprocessFrame(
        frameData,
        _config!.bloodModel!.inputSize,
      );
      bloodResult = await _runBlood(bloodInput);
    }
    
    WeaponsResult? weaponsResult;
    if (_weaponsSession != null) {
      final weaponsInput = _preprocessFrame(
        frameData,
        _config!.weaponsModel!.inputSize,
      );
      weaponsResult = await _runWeapons(weaponsInput);
    }
    
    return FrameAnalysisResult(
      nsfw: nsfwResult,
      violence: violenceResult,
      blood: bloodResult,
      weapons: weaponsResult,
    );
  }
  
  /// Batch analysis for efficiency
  Future<List<FrameAnalysisResult>> analyzeFrameBatch(
    List<Uint8List> frames,
  ) async {
    final batchSize = _config!.batchSize;
    final results = <FrameAnalysisResult>[];
    
    for (var i = 0; i < frames.length; i += batchSize) {
      final batch = frames.sublist(
        i,
        (i + batchSize).clamp(0, frames.length),
      );
      
      // Process batch in parallel across models
      final batchResults = await Future.wait([
        _runNSFWBatch(batch),
        _runViolenceBatch(batch),
        if (_bloodSession != null) _runBloodBatch(batch),
        if (_weaponsSession != null) _runWeaponsBatch(batch),
      ]);
      
      // Combine results
      for (var j = 0; j < batch.length; j++) {
        results.add(FrameAnalysisResult(
          nsfw: batchResults[0][j],
          violence: batchResults[1][j],
          blood: batchResults.length > 2 ? batchResults[2][j] : null,
          weapons: batchResults.length > 3 ? batchResults[3][j] : null,
        ));
      }
    }
    
    return results;
  }
  
  Float32List _preprocessFrame(Uint8List frameData, int targetSize) {
    // Resize, normalize, convert to CHW format
    // Implementation depends on image format
    // Returns float32 tensor [1, 3, targetSize, targetSize]
    throw UnimplementedError();
  }
  
  void dispose() {
    if (_nsfwSession != null) _onnx.destroySession(_nsfwSession!);
    if (_violenceSession != null) _onnx.destroySession(_violenceSession!);
    if (_bloodSession != null) _onnx.destroySession(_bloodSession!);
    if (_weaponsSession != null) _onnx.destroySession(_weaponsSession!);
  }
}
```

### 2.2 Violence Detection

#### Model Options

| Model | Architecture | Accuracy | Speed | Size |
|-------|--------------|----------|-------|------|
| violence-vit-base | ViT-base-patch16 | 98.8% | Medium | 330MB |
| violence-mobilenet | MobileNetV3 | 94% | Fast | 15MB |
| violence-convnext | ConvNeXt-Tiny | 97% | Medium | 110MB |

#### Output Format

```dart
class ViolenceResult {
  final double violentScore;
  final double nonViolentScore;
  
  bool get isViolent => violentScore > 0.6;
  
  ViolenceResult({
    required this.violentScore,
    required this.nonViolentScore,
  });
}
```

### 2.3 Blood/Gore Detection

#### Model Options

| Model | Architecture | Accuracy | Size |
|-------|--------------|----------|------|
| gore-efficientnet | EfficientNet-B2 | 96% | 35MB |
| blood-yolo | YOLOv8-nano | 92% | 12MB |

```dart
class BloodResult {
  final double bloodScore;
  final List<BoundingBox>? regions;  // For YOLO-based detection
  
  bool get hasBlood => bloodScore > 0.5;
}
```

### 2.4 Weapons Detection

Object detection models for identifying weapons.

| Model | Architecture | mAP | Size |
|-------|--------------|-----|------|
| weapons-yolov8s | YOLOv8-small | 78% | 22MB |
| weapons-detr | DETR-ResNet50 | 82% | 160MB |

```dart
class WeaponsResult {
  final List<DetectedObject> detections;
  
  bool get hasWeapons => detections.isNotEmpty;
}

class DetectedObject {
  final String label;  // "handgun", "rifle", "knife", etc.
  final BoundingBox box;
  final double confidence;
}

class BoundingBox {
  final double x, y, width, height;
  
  BoundingBox({
    required this.x,
    required this.y,
    required this.width,
    required this.height,
  });
}
```

---

## 3. Profanity Word Lists

### LDNOOBW (List of Dirty, Naughty, Obscene, and Otherwise Bad Words)

**License:** CC-BY-4.0  
**Source:** https://github.com/LDNOOBW/List-of-Dirty-Naughty-Obscene-and-Otherwise-Bad-Words

#### Supported Languages (29)

| Language | Code | Words | Notes |
|----------|------|-------|-------|
| Arabic | ar | 400+ | Regional variants |
| Chinese | zh | 300+ | Simplified |
| Czech | cs | 200+ | |
| Danish | da | 150+ | |
| Dutch | nl | 300+ | |
| English | en | 700+ | Comprehensive |
| Esperanto | eo | 50+ | |
| Filipino | fil | 200+ | |
| Finnish | fi | 200+ | |
| French | fr | 500+ | |
| German | de | 400+ | |
| Hindi | hi | 300+ | Devanagari |
| Hungarian | hu | 200+ | |
| Indonesian | id | 200+ | |
| Italian | it | 400+ | |
| Japanese | ja | 300+ | Hiragana/Katakana/Kanji |
| Klingon | tlh | 20+ | |
| Korean | ko | 200+ | Hangul |
| Norwegian | no | 150+ | |
| Persian | fa | 200+ | |
| Polish | pl | 300+ | |
| Portuguese | pt | 400+ | Brazilian + European |
| Russian | ru | 400+ | Cyrillic |
| Spanish | es | 500+ | Latin American + European |
| Swedish | sv | 200+ | |
| Thai | th | 200+ | |
| Turkish | tr | 300+ | |
| Ukrainian | uk | 200+ | Cyrillic |
| Vietnamese | vi | 200+ | |

#### Integration

```dart
// lib/services/profanity_service.dart

class ProfanityWordListService {
  final Map<String, Set<String>> _wordLists = {};
  
  Future<void> loadWordList(String languageCode) async {
    if (_wordLists.containsKey(languageCode)) return;
    
    final assetPath = 'assets/wordlists/$languageCode.txt';
    final content = await rootBundle.loadString(assetPath);
    
    final words = content
        .split('\n')
        .map((line) => line.trim().toLowerCase())
        .where((line) => line.isNotEmpty && !line.startsWith('#'))
        .toSet();
    
    _wordLists[languageCode] = words;
  }
  
  bool isProfane(String word, String languageCode) {
    final list = _wordLists[languageCode];
    if (list == null) return false;
    
    return list.contains(word.toLowerCase());
  }
  
  Set<String> getSupportedLanguages() {
    return {
      'ar', 'cs', 'da', 'de', 'en', 'eo', 'es', 'fa', 'fi', 'fil',
      'fr', 'hi', 'hu', 'id', 'it', 'ja', 'ko', 'nl', 'no', 'pl',
      'pt', 'ru', 'sv', 'th', 'tlh', 'tr', 'uk', 'vi', 'zh',
    };
  }
}
```

---

## 4. Model Manager Service

Handles downloading, caching, and validating models.

```dart
// lib/services/model_manager_service.dart

import 'dart:io';
import 'dart:convert';
import 'package:crypto/crypto.dart';

class ModelInfo {
  final String id;
  final String displayName;
  final String description;
  final String downloadUrl;
  final int sizeBytes;
  final String sha256;
  final ModelType type;
  final String? license;
  final String? author;
  final String? projectUrl;
  
  const ModelInfo({
    required this.id,
    required this.displayName,
    required this.description,
    required this.downloadUrl,
    required this.sizeBytes,
    required this.sha256,
    required this.type,
    this.license,
    this.author,
    this.projectUrl,
  });
}

enum ModelType {
  whisper,
  mms,
  nsfw,
  violence,
  blood,
  weapons,
}

class ModelManagerService {
  final String _modelsDir;
  final Map<String, ModelInfo> _registry = {};
  
  ModelManagerService(this._modelsDir);
  
  Future<void> loadRegistry() async {
    // Load bundled registry
    final registryJson = await File('$_modelsDir/registry.json').readAsString();
    final List<dynamic> models = jsonDecode(registryJson);
    
    for (final model in models) {
      final info = ModelInfo(
        id: model['id'],
        displayName: model['displayName'],
        description: model['description'],
        downloadUrl: model['downloadUrl'],
        sizeBytes: model['sizeBytes'],
        sha256: model['sha256'],
        type: ModelType.values.byName(model['type']),
        license: model['license'],
        author: model['author'],
        projectUrl: model['projectUrl'],
      );
      _registry[info.id] = info;
    }
  }
  
  List<ModelInfo> getModelsOfType(ModelType type) {
    return _registry.values
        .where((m) => m.type == type)
        .toList();
  }
  
  Future<bool> isModelDownloaded(String modelId) async {
    final info = _registry[modelId];
    if (info == null) return false;
    
    final modelPath = _getModelPath(modelId);
    final file = File(modelPath);
    
    if (!await file.exists()) return false;
    
    // Verify integrity
    return await _verifyChecksum(file, info.sha256);
  }
  
  Future<String> downloadModel(
    String modelId, {
    Function(double)? onProgress,
  }) async {
    final info = _registry[modelId]!;
    final modelPath = _getModelPath(modelId);
    final file = File(modelPath);
    
    // Create directory
    await file.parent.create(recursive: true);
    
    // Download with progress
    final client = HttpClient();
    final request = await client.getUrl(Uri.parse(info.downloadUrl));
    final response = await request.close();
    
    if (response.statusCode != 200) {
      throw ModelDownloadError(modelId, httpStatusCode: response.statusCode);
    }
    
    final totalBytes = response.contentLength;
    var downloadedBytes = 0;
    
    final sink = file.openWrite();
    
    await for (final chunk in response) {
      sink.add(chunk);
      downloadedBytes += chunk.length;
      
      if (totalBytes > 0) {
        onProgress?.call(downloadedBytes / totalBytes);
      }
    }
    
    await sink.close();
    client.close();
    
    // Verify checksum
    if (!await _verifyChecksum(file, info.sha256)) {
      await file.delete();
      throw ModelDownloadError(modelId, technicalDetails: 'Checksum mismatch');
    }
    
    return modelPath;
  }
  
  Future<bool> _verifyChecksum(File file, String expectedSha256) async {
    final bytes = await file.readAsBytes();
    final digest = sha256.convert(bytes);
    return digest.toString() == expectedSha256;
  }
  
  String _getModelPath(String modelId) {
    return '$_modelsDir/$modelId.onnx';
  }
  
  Future<int> getTotalDownloadedSize() async {
    var total = 0;
    
    for (final id in _registry.keys) {
      if (await isModelDownloaded(id)) {
        total += _registry[id]!.sizeBytes;
      }
    }
    
    return total;
  }
  
  Future<void> deleteModel(String modelId) async {
    final modelPath = _getModelPath(modelId);
    final file = File(modelPath);
    
    if (await file.exists()) {
      await file.delete();
    }
  }
}
```

---

## 5. Model Attribution Data

```dart
// lib/data/models/attribution.dart

class ModelAttribution {
  final String name;
  final String description;
  final String license;
  final String licenseUrl;
  final String? author;
  final String projectUrl;
  
  const ModelAttribution({
    required this.name,
    required this.description,
    required this.license,
    required this.licenseUrl,
    this.author,
    required this.projectUrl,
  });
}

const modelAttributions = [
  ModelAttribution(
    name: 'OpenAI Whisper',
    description: 'Automatic Speech Recognition',
    license: 'MIT License',
    licenseUrl: 'https://github.com/openai/whisper/blob/main/LICENSE',
    author: 'OpenAI',
    projectUrl: 'https://github.com/openai/whisper',
  ),
  ModelAttribution(
    name: 'whisper.cpp',
    description: 'C++ implementation of Whisper',
    license: 'MIT License',
    licenseUrl: 'https://github.com/ggerganov/whisper.cpp/blob/master/LICENSE',
    author: 'Georgi Gerganov',
    projectUrl: 'https://github.com/ggerganov/whisper.cpp',
  ),
  ModelAttribution(
    name: 'Meta MMS',
    description: 'Massively Multilingual Speech recognition (1100+ languages)',
    license: 'MIT License',
    licenseUrl: 'https://github.com/facebookresearch/fairseq/blob/main/LICENSE',
    author: 'Meta AI',
    projectUrl: 'https://github.com/facebookresearch/fairseq/tree/main/examples/mms',
  ),
  ModelAttribution(
    name: 'NSFW Detection Model',
    description: 'Content classification for images',
    license: 'MIT License',
    licenseUrl: 'https://github.com/GantMan/nsfw_model/blob/master/LICENSE',
    author: 'GantMan',
    projectUrl: 'https://github.com/GantMan/nsfw_model',
  ),
  ModelAttribution(
    name: 'Violence Detection (ViT)',
    description: 'Vision Transformer for violence classification',
    license: 'Apache 2.0',
    licenseUrl: 'https://huggingface.co/jaranohaal/vit-base-violence-detection',
    author: 'jaranohaal',
    projectUrl: 'https://huggingface.co/jaranohaal/vit-base-violence-detection',
  ),
  ModelAttribution(
    name: 'LDNOOBW Profanity Lists',
    description: 'Multilingual profanity word lists (29 languages)',
    license: 'CC-BY-4.0',
    licenseUrl: 'https://github.com/LDNOOBW/List-of-Dirty-Naughty-Obscene-and-Otherwise-Bad-Words/blob/master/LICENSE',
    author: 'Shutterstock',
    projectUrl: 'https://github.com/LDNOOBW/List-of-Dirty-Naughty-Obscene-and-Otherwise-Bad-Words',
  ),
  ModelAttribution(
    name: 'ONNX Runtime',
    description: 'Cross-platform ML inference engine',
    license: 'MIT License',
    licenseUrl: 'https://github.com/microsoft/onnxruntime/blob/main/LICENSE',
    author: 'Microsoft',
    projectUrl: 'https://github.com/microsoft/onnxruntime',
  ),
  ModelAttribution(
    name: 'FFmpeg',
    description: 'Media processing toolkit',
    license: 'LGPL 2.1+ / GPL 2+',
    licenseUrl: 'https://ffmpeg.org/legal.html',
    projectUrl: 'https://ffmpeg.org',
  ),
];
```

---

## 6. Native Build Instructions

### Building whisper.cpp

```powershell
# Windows (PowerShell)
git clone https://github.com/ggerganov/whisper.cpp
cd whisper.cpp
mkdir build; cd build
cmake .. -DBUILD_SHARED_LIBS=ON -DWHISPER_CUDA=ON
cmake --build . --config Release
```

```bash
# macOS
git clone https://github.com/ggerganov/whisper.cpp
cd whisper.cpp
mkdir build && cd build
cmake .. -DBUILD_SHARED_LIBS=ON -DWHISPER_METAL=ON
cmake --build . --config Release
```

```bash
# Linux
git clone https://github.com/ggerganov/whisper.cpp
cd whisper.cpp
mkdir build && cd build
cmake .. -DBUILD_SHARED_LIBS=ON -DWHISPER_CUDA=ON
cmake --build . --config Release
```

### Building ONNX Runtime

Pre-built binaries are recommended:
- https://github.com/microsoft/onnxruntime/releases

Download the appropriate package:
- Windows: `Microsoft.ML.OnnxRuntime.Gpu.{version}.nupkg`
- macOS: `onnxruntime-osx-{arch}-{version}.tgz`
- Linux: `onnxruntime-linux-{arch}-gpu-{version}.tgz`

### Building FFmpeg

```powershell
# Windows - use pre-built or vcpkg
vcpkg install ffmpeg[core,avcodec,avformat,avfilter,swscale,swresample]:x64-windows
```

```bash
# macOS
brew install ffmpeg

# Or build from source for static linking
git clone https://git.ffmpeg.org/ffmpeg.git
cd ffmpeg
./configure --enable-shared --enable-gpl --enable-libx264 --enable-libx265
make -j$(nproc)
```

---

## 7. Performance Benchmarks

### Target Performance (Recommended Hardware)

| Operation | Target | Measurement Method |
|-----------|--------|-------------------|
| Whisper small transcription | 4x realtime | 30s audio in < 7.5s |
| Frame NSFW analysis | < 50ms | Per 224x224 frame |
| Frame Violence analysis | < 50ms | Per 224x224 frame |
| Batch analysis (8 frames) | < 200ms | 8 frames total |
| Full 1-min video analysis | < 3 min | All detection types |

### Memory Budgets

| Component | Budget | Notes |
|-----------|--------|-------|
| Whisper model (small) | 2GB | Runtime memory |
| ONNX models (all loaded) | 500MB | Combined |
| Frame buffer pool | 750MB | 4K, 30 frames |
| Audio buffer | 200MB | Streaming decode |
| **Total runtime** | **< 4GB** | Recommended config |

---

*Document Version: 2.0*  
*Last Updated: January 2025*
