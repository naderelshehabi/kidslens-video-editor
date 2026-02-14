# KidsLens Video Editor - Native Integration Guide

This document covers the FFI (Foreign Function Interface) integration with native libraries including FFmpeg, whisper.cpp, ONNX Runtime, and Meta MMS.

## Table of Contents

- [Overview](#overview)
- [Native Library Requirements](#native-library-requirements)
- [FFI Architecture](#ffi-architecture)
- [Binding Generation](#binding-generation)
- [Memory Management](#memory-management)
- [Error Handling](#error-handling)
- [Platform-Specific Notes](#platform-specific-notes)
- [Debugging Native Code](#debugging-native-code)

---

## Overview

KidsLens uses Dart's FFI (Foreign Function Interface) to interact with native C/C++ libraries for:

| Library | Purpose | Features |
|---------|---------|----------|
| **FFmpeg** | Media processing | Decoding, encoding, filtering, transcoding |
| **whisper.cpp** | Speech recognition | OpenAI Whisper model inference |
| **ONNX Runtime** | ML inference | Visual content analysis models |
| **Meta MMS** | Multilingual ASR | 1000+ language support |

### Why FFI?

- **Performance**: Native code runs at full speed
- **Existing Libraries**: Leverage mature, battle-tested libraries
- **No Package Dependency**: Custom bindings for full control
- **Cross-Platform**: Same Dart code, platform-specific libraries

---

## Native Library Requirements

### FFmpeg 6.x

**Purpose**: All media processing operations

**Required Components**:
- libavcodec - Encoding/decoding
- libavformat - Container formats
- libavutil - Utility functions
- libavfilter - Video/audio filtering
- libswscale - Image scaling
- libswresample - Audio resampling

**Supported Codecs**:
```
Video: H.264, H.265/HEVC, VP8, VP9, AV1, MPEG-4
Audio: AAC, MP3, Opus, Vorbis, FLAC, PCM
Containers: MP4, MKV, AVI, MOV, WebM, WAV, MP3
```

**Custom Wrapper Required**: Yes - `ffmpeg_wrapper.dll/.so/.dylib`

### whisper.cpp

**Purpose**: Whisper ASR model inference

**Models Supported**:
| Model | Size | Memory | Speed | Accuracy |
|-------|------|--------|-------|----------|
| tiny | 75MB | ~1GB | 10x | Basic |
| base | 142MB | ~1GB | 7x | Good |
| small | 466MB | ~2GB | 4x | **Recommended** |
| medium | 1.5GB | ~5GB | 2x | High |
| large-v3 | 2.9GB | ~10GB | 1x | Best |

**Hardware Acceleration**:
- CPU: AVX/AVX2/AVX512 (always available)
- Vulkan: Cross-platform GPU (Windows, Linux)
- CUDA: NVIDIA GPUs (Compute 6.0+)
- Metal: Apple Silicon/Intel Mac

**GPU Auto-Fallback**: The library automatically tries GPU acceleration first, and gracefully falls back to CPU if:
- No GPU is available
- GPU drivers are outdated
- Vulkan SDK was not installed at build time

**Build Integration**: whisper_wrapper is automatically built as part of `flutter build windows`. No manual compilation required.

**Custom Wrapper**: `whisper_wrapper.dll/.so/.dylib` - Auto-generated during build

### ONNX Runtime 1.16+

**Purpose**: Visual AI model inference

**Execution Providers**:
| Provider | Platform | Notes |
|----------|----------|-------|
| CPU | All | Default, always available |
| CUDA | Windows/Linux | NVIDIA GPUs |
| DirectML | Windows | AMD/Intel/NVIDIA GPUs |
| CoreML | macOS | Apple Neural Engine |
| TensorRT | Windows/Linux | NVIDIA optimized |

**Model Format**: ONNX (.onnx files)

**No Custom Wrapper**: Direct ONNX Runtime C API usage

### Meta MMS (fairseq2)

**Purpose**: Multilingual ASR for 1000+ languages

**Models**:
- mms-1b-fl102 - 102 languages
- mms-1b-l1107 - 1107 languages
- mms-1b-all - All supported languages

**Custom Wrapper Required**: Yes - `mms_wrapper.dll/.so/.dylib`

---

## FFI Architecture

### Layer Structure

```
┌─────────────────────────────────────────────────────────────────┐
│                         Dart Services                           │
│  ┌─────────────┐  ┌──────────────┐  ┌─────────────────────────┐ │
│  │MediaService │  │AnalysisService│  │    ExportService        │ │
│  └──────┬──────┘  └──────┬───────┘  └───────────┬─────────────┘ │
└─────────┼────────────────┼──────────────────────┼───────────────┘
          │                │                      │
          ▼                ▼                      ▼
┌─────────────────────────────────────────────────────────────────┐
│                      Dart FFI Bindings                          │
│  ┌─────────────┐  ┌──────────────┐  ┌─────────────────────────┐ │
│  │FFmpegBindings│  │WhisperBindings│ │    ONNXBindings         │ │
│  │ • probeMedia │  │ • transcribe │  │    • runInference       │ │
│  │ • extractFrame│ │ • getSupportedLangs│ • loadModel          │ │
│  └──────┬──────┘  └──────┬───────┘  └───────────┬─────────────┘ │
└─────────┼────────────────┼──────────────────────┼───────────────┘
          │                │                      │
          ▼                ▼                      ▼
┌─────────────────────────────────────────────────────────────────┐
│                    Native C Wrappers                            │
│  ┌─────────────┐  ┌──────────────┐  ┌─────────────────────────┐ │
│  │ffmpeg_wrapper│  │whisper_wrapper│ │   onnxruntime.dll       │ │
│  │   .dll       │  │    .dll       │ │   (direct API)          │ │
│  └──────┬──────┘  └──────┬───────┘  └───────────┬─────────────┘ │
└─────────┼────────────────┼──────────────────────┼───────────────┘
          │                │                      │
          ▼                ▼                      ▼
┌─────────────────────────────────────────────────────────────────┐
│                   Native Libraries                              │
│  ┌─────────────┐  ┌──────────────┐  ┌─────────────────────────┐ │
│  │ FFmpeg libs │  │ whisper.cpp  │  │   ONNX Runtime          │ │
│  │ avcodec,etc │  │ + ggml       │  │   + execution providers │ │
│  └─────────────┘  └──────────────┘  └─────────────────────────┘ │
└─────────────────────────────────────────────────────────────────┘
```

### Binding Class Structure

```dart
// lib/native/bindings/ffmpeg_bindings.dart

import 'dart:ffi';
import 'dart:io';
import '../resource_manager.dart';

/// FFI bindings for FFmpeg operations
class FFmpegBindings extends NativeResource {
  DynamicLibrary? _lib;
  bool _initialized = false;

  // Late-initialized function pointers
  late final int Function(Pointer<Utf8> path) _probeMedia;
  late final int Function(Pointer<Utf8> input, Pointer<Utf8> output) _extractAudio;
  // ... more function pointers

  /// Initialize FFmpeg bindings
  Future<void> initialize() async {
    if (_initialized) return;

    try {
      _lib = _loadLibrary();
      _bindFunctions();
      _initialized = true;
    } catch (e) {
      throw FFmpegInitializationException('Failed to load FFmpeg: $e');
    }
  }

  DynamicLibrary _loadLibrary() {
    if (Platform.isWindows) {
      return DynamicLibrary.open('ffmpeg_wrapper.dll');
    } else if (Platform.isMacOS) {
      return DynamicLibrary.open('libffmpeg_wrapper.dylib');
    } else if (Platform.isLinux) {
      return DynamicLibrary.open('libffmpeg_wrapper.so');
    }
    throw UnsupportedError('Platform not supported');
  }

  void _bindFunctions() {
    _probeMedia = _lib!
        .lookup<NativeFunction<Int32 Function(Pointer<Utf8>)>>('ffmpeg_probe')
        .asFunction();
    // ... bind more functions
  }

  @override
  void releaseNative() {
    _lib = null;
    _initialized = false;
  }
}
```

---

## Binding Generation

### C API Design Principles

When creating wrapper libraries, follow these principles:

1. **Simple types**: Use primitive types that map easily to Dart
2. **Opaque handles**: Return handles instead of raw pointers
3. **Error codes**: Return error codes, provide separate error message function
4. **Allocator control**: Provide explicit alloc/free functions

### Example C Header

```c
// native/ffmpeg/ffmpeg_wrapper.h

#ifndef FFMPEG_WRAPPER_H
#define FFMPEG_WRAPPER_H

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

// Opaque handle type
typedef struct FFmpegContext* FFmpegHandle;

// Result structure for media probing
typedef struct {
    int64_t duration_ms;
    int32_t width;
    int32_t height;
    double frame_rate;
    int64_t file_size;
    const char* video_codec;
    const char* audio_codec;
    const char* container;
} MediaInfo;

// Frame data structure
typedef struct {
    int32_t frame_number;
    int64_t timestamp_ms;
    int32_t width;
    int32_t height;
    uint8_t* rgb_data;      // Caller must free
    int32_t rgb_data_size;
} FrameData;

// Initialize/cleanup
EXPORT FFmpegHandle ffmpeg_init(void);
EXPORT void ffmpeg_free(FFmpegHandle handle);

// Media operations
EXPORT int32_t ffmpeg_probe(FFmpegHandle handle, const char* path, MediaInfo* out);
EXPORT int32_t ffmpeg_extract_audio(FFmpegHandle handle, const char* input, const char* output);
EXPORT int32_t ffmpeg_extract_frame(FFmpegHandle handle, const char* path, int64_t timestamp_ms, FrameData* out);
EXPORT void ffmpeg_free_frame(FrameData* frame);

// Error handling
EXPORT const char* ffmpeg_get_error(FFmpegHandle handle);
EXPORT int32_t ffmpeg_get_error_code(FFmpegHandle handle);

#ifdef __cplusplus
}
#endif

#endif
```

### Dart Bindings

```dart
// lib/native/bindings/ffmpeg_bindings.dart

import 'dart:ffi';
import 'package:ffi/ffi.dart';

// Native struct definitions
final class MediaInfoNative extends Struct {
  @Int64()
  external int durationMs;
  
  @Int32()
  external int width;
  
  @Int32()
  external int height;
  
  @Double()
  external double frameRate;
  
  @Int64()
  external int fileSize;
  
  external Pointer<Utf8> videoCodec;
  external Pointer<Utf8> audioCodec;
  external Pointer<Utf8> container;
}

final class FrameDataNative extends Struct {
  @Int32()
  external int frameNumber;
  
  @Int64()
  external int timestampMs;
  
  @Int32()
  external int width;
  
  @Int32()
  external int height;
  
  external Pointer<Uint8> rgbData;
  
  @Int32()
  external int rgbDataSize;
}

// Function typedefs
typedef FFmpegInitNative = Pointer<Void> Function();
typedef FFmpegInitDart = Pointer<Void> Function();

typedef FFmpegProbeNative = Int32 Function(
  Pointer<Void> handle,
  Pointer<Utf8> path,
  Pointer<MediaInfoNative> out,
);
typedef FFmpegProbeDart = int Function(
  Pointer<Void> handle,
  Pointer<Utf8> path,
  Pointer<MediaInfoNative> out,
);

// Binding class
class FFmpegBindings extends NativeResource {
  late final DynamicLibrary _lib;
  late final FFmpegInitDart _init;
  late final FFmpegProbeDart _probe;
  // ... more functions

  Pointer<Void> _handle = nullptr;

  Future<void> initialize() async {
    _lib = DynamicLibrary.open(_libraryPath);
    
    _init = _lib.lookupFunction<FFmpegInitNative, FFmpegInitDart>('ffmpeg_init');
    _probe = _lib.lookupFunction<FFmpegProbeNative, FFmpegProbeDart>('ffmpeg_probe');
    
    _handle = _init();
    if (_handle == nullptr) {
      throw FFmpegInitializationException('Failed to initialize FFmpeg');
    }
  }

  Future<MediaMetadata> probeMedia(String path) async {
    final pathPtr = path.toNativeUtf8();
    final infoPtr = calloc<MediaInfoNative>();
    
    try {
      final result = _probe(_handle, pathPtr, infoPtr);
      if (result != 0) {
        throw FFmpegException(_getErrorMessage());
      }
      
      return MediaMetadata(
        duration: Duration(milliseconds: infoPtr.ref.durationMs),
        width: infoPtr.ref.width,
        height: infoPtr.ref.height,
        frameRate: infoPtr.ref.frameRate,
        fileSize: infoPtr.ref.fileSize,
        videoCodec: infoPtr.ref.videoCodec.toDartString(),
        audioCodec: infoPtr.ref.audioCodec.toDartString(),
      );
    } finally {
      calloc.free(pathPtr);
      calloc.free(infoPtr);
    }
  }
}
```

---

## Memory Management

### Resource Manager

The `NativeResourceManager` provides centralized tracking and cleanup of FFI resources.

```dart
// lib/native/resource_manager.dart

import 'dart:async';

/// Manages all native FFI resources with deterministic cleanup
class NativeResourceManager {
  static final NativeResourceManager instance = NativeResourceManager._();
  NativeResourceManager._();

  final Map<int, WeakReference<NativeResource>> _resources = {};
  final Finalizer<int> _finalizer = Finalizer((id) {
    instance._cleanupResource(id);
  });

  int _nextId = 0;

  /// Register a native resource for tracking
  T register<T extends NativeResource>(T resource) {
    final id = _nextId++;
    _resources[id] = WeakReference(resource);
    _finalizer.attach(resource, id, detach: resource);
    return resource;
  }

  /// Explicitly release a resource
  void release(NativeResource resource) {
    resource.dispose();
    _finalizer.detach(resource);
  }

  void _cleanupResource(int id) {
    final weak = _resources.remove(id);
    weak?.target?.releaseNative();
  }

  /// Force cleanup of all resources (app shutdown)
  Future<void> disposeAll() async {
    for (final weak in _resources.values) {
      weak.target?.dispose();
    }
    _resources.clear();
  }
}

/// Base class for FFI-backed resources
abstract class NativeResource {
  bool _disposed = false;

  bool get isDisposed => _disposed;

  void dispose() {
    if (_disposed) return;
    _disposed = true;
    releaseNative();
  }

  /// Override to release native resources
  void releaseNative();
}
```

### Frame Buffer Pool

Manages frame buffers to prevent memory overflow during video processing.

```dart
// lib/native/frame_buffer_pool.dart

import 'dart:collection';
import 'dart:ffi';
import 'package:ffi/ffi.dart';

class FrameBufferPool {
  static const int maxBuffers = 30;
  static const int maxBufferSize = 1920 * 1080 * 4; // RGBA 1080p

  final Queue<Pointer<Uint8>> _available = Queue();
  final Set<Pointer<Uint8>> _inUse = {};
  int _allocatedCount = 0;

  /// Acquire a buffer, blocking if at capacity
  Future<Pointer<Uint8>> acquire() async {
    // Try to get an available buffer
    if (_available.isNotEmpty) {
      final buffer = _available.removeFirst();
      _inUse.add(buffer);
      return buffer;
    }

    // Allocate new if under limit
    if (_allocatedCount < maxBuffers) {
      final buffer = calloc<Uint8>(maxBufferSize);
      _allocatedCount++;
      _inUse.add(buffer);
      return buffer;
    }

    // Wait for a buffer to be released (backpressure)
    while (_available.isEmpty) {
      await Future.delayed(const Duration(milliseconds: 10));
    }

    return acquire();
  }

  /// Release a buffer back to the pool
  void release(Pointer<Uint8> buffer) {
    if (_inUse.remove(buffer)) {
      _available.add(buffer);
    }
  }

  /// Clean up all buffers
  void dispose() {
    for (final buffer in _available) {
      calloc.free(buffer);
    }
    for (final buffer in _inUse) {
      calloc.free(buffer);
    }
    _available.clear();
    _inUse.clear();
    _allocatedCount = 0;
  }

  int get availableCount => _available.length;
  int get inUseCount => _inUse.length;
  int get totalAllocated => _allocatedCount;
}
```

### Memory Monitor

Monitors system memory and triggers cleanup when needed.

```dart
// lib/native/memory_monitor.dart

import 'dart:async';
import 'dart:io';

enum MemoryPressureLevel { normal, warning, critical }

typedef MemoryPressureCallback = void Function(MemoryPressureLevel level);

class MemoryMonitor {
  static const Duration checkInterval = Duration(seconds: 5);
  static const double warningThreshold = 0.8;  // 80%
  static const double criticalThreshold = 0.9; // 90%

  Timer? _timer;
  final List<MemoryPressureCallback> _callbacks = [];

  void start() {
    _timer?.cancel();
    _timer = Timer.periodic(checkInterval, (_) => _checkMemory());
  }

  void stop() {
    _timer?.cancel();
    _timer = null;
  }

  void onMemoryPressure(MemoryPressureCallback callback) {
    _callbacks.add(callback);
  }

  Future<void> _checkMemory() async {
    final (total, available) = await _getMemoryInfo();
    if (total == 0) return;

    final usedRatio = 1.0 - (available / total);

    if (usedRatio >= criticalThreshold) {
      _notify(MemoryPressureLevel.critical);
    } else if (usedRatio >= warningThreshold) {
      _notify(MemoryPressureLevel.warning);
    }
  }

  void _notify(MemoryPressureLevel level) {
    for (final callback in _callbacks) {
      callback(level);
    }
  }

  Future<(int, int)> _getMemoryInfo() async {
    if (Platform.isWindows) {
      return _getWindowsMemory();
    } else if (Platform.isMacOS) {
      return _getMacOSMemory();
    } else if (Platform.isLinux) {
      return _getLinuxMemory();
    }
    return (0, 0);
  }

  // Platform-specific implementations...
}
```

---

## Error Handling

### Native Error Codes

Define consistent error codes across all native wrappers:

```c
// native/common/error_codes.h

#define SUCCESS                  0
#define ERROR_INVALID_ARGUMENT  -1
#define ERROR_FILE_NOT_FOUND    -2
#define ERROR_UNSUPPORTED_FORMAT -3
#define ERROR_OUT_OF_MEMORY     -4
#define ERROR_INITIALIZATION    -5
#define ERROR_PROCESSING        -6
#define ERROR_GPU_UNAVAILABLE   -7
#define ERROR_MODEL_INVALID     -8
```

### Dart Exception Hierarchy

```dart
// lib/native/bindings/exceptions.dart

/// Base exception for native binding errors
sealed class NativeException implements Exception {
  final int errorCode;
  final String message;
  final String? nativeMessage;

  const NativeException(this.errorCode, this.message, [this.nativeMessage]);
}

class FFmpegException extends NativeException {
  const FFmpegException(super.errorCode, super.message, [super.nativeMessage]);

  factory FFmpegException.fromCode(int code, String nativeMsg) {
    final message = switch (code) {
      -1 => 'Invalid argument',
      -2 => 'File not found',
      -3 => 'Unsupported format',
      -4 => 'Out of memory',
      -5 => 'Initialization failed',
      -6 => 'Processing error',
      _ => 'Unknown error',
    };
    return FFmpegException(code, message, nativeMsg);
  }
}

class WhisperException extends NativeException {
  const WhisperException(super.errorCode, super.message, [super.nativeMessage]);
}

class ONNXException extends NativeException {
  const ONNXException(super.errorCode, super.message, [super.nativeMessage]);
}
```

### Error Checking Pattern

```dart
int _checkResult(int result, String operation) {
  if (result < 0) {
    final errorMsg = _getErrorMessage();
    throw FFmpegException.fromCode(result, errorMsg);
  }
  return result;
}

Future<String> extractAudio(String input, String output) async {
  final inputPtr = input.toNativeUtf8();
  final outputPtr = output.toNativeUtf8();

  try {
    final result = _extractAudio(_handle, inputPtr, outputPtr);
    _checkResult(result, 'extractAudio');
    return output;
  } finally {
    calloc.free(inputPtr);
    calloc.free(outputPtr);
  }
}
```

---

## Platform-Specific Notes

### Windows

**Library Extensions**: `.dll`

**Library Location**:
- Development: Project root or `windows/` folder
- Release: Same directory as `.exe`

**Dependencies**:
```
ffmpeg_wrapper.dll
├── avcodec-60.dll
├── avformat-60.dll
├── avutil-58.dll
├── avfilter-9.dll
├── swscale-7.dll
└── swresample-4.dll

whisper_wrapper.dll
└── (self-contained, whisper.cpp linked statically)
    └── vulkan-1.dll (optional, for GPU acceleration)

onnxruntime.dll
└── onnxruntime_providers_*.dll (optional GPU)
```

**Visual C++ Redistributable**: Required for end users

### macOS

**Library Extensions**: `.dylib`

**Library Location**:
- Development: `/usr/local/lib` or project folder
- Release: Inside `.app/Contents/Frameworks`

**Code Signing**: Libraries must be signed for distribution

**Universal Binaries**: Support both Intel and Apple Silicon

```bash
# Create universal binary
lipo -create -output libffmpeg.dylib \
  libffmpeg_x86_64.dylib \
  libffmpeg_arm64.dylib
```

### Linux

**Library Extensions**: `.so`

**Library Location**:
- Development: `/usr/lib` or `LD_LIBRARY_PATH`
- Release: Bundle with app or expect system installation

**Dependencies**: Link against specific versions

```bash
# Check library dependencies
ldd libffmpeg_wrapper.so
```

---

## Debugging Native Code

### Enabling Debug Output

```dart
// Enable verbose FFmpeg logging
class FFmpegBindings {
  void setLogLevel(int level) {
    _setLogLevel(_handle, level);
  }

  void setLogCallback(void Function(String) callback) {
    // Set up native callback...
  }
}

// Usage
ffmpeg.setLogLevel(FFmpegLogLevel.verbose);
ffmpeg.setLogCallback((msg) => debugPrint('[FFmpeg] $msg'));
```

### Common Issues

#### Library Not Found

```dart
// Add diagnostic logging
try {
  _lib = DynamicLibrary.open(libraryPath);
} on ArgumentError catch (e) {
  print('Failed to load $libraryPath');
  print('Current directory: ${Directory.current.path}');
  print('Error: $e');
  rethrow;
}
```

#### Symbol Not Found

```dart
// Check for symbol existence
bool hasSymbol(String name) {
  try {
    _lib.lookup(name);
    return true;
  } catch (_) {
    return false;
  }
}
```

#### Memory Corruption

1. Check pointer lifetimes
2. Verify struct alignment
3. Use AddressSanitizer in native builds

```cmake
# Enable AddressSanitizer
set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -fsanitize=address")
```

### Native Debugging Tools

| Platform | Tool | Purpose |
|----------|------|---------|
| Windows | WinDbg / VS Debugger | Attach to process |
| macOS | lldb | Native debugging |
| Linux | gdb / valgrind | Memory analysis |
| All | AddressSanitizer | Memory errors |
| All | ThreadSanitizer | Race conditions |

### Attaching Debugger

1. Build native library with debug symbols (`-g`)
2. Run Flutter app in debug mode
3. Attach native debugger to process
4. Set breakpoints in native code

```bash
# macOS/Linux - attach lldb
lldb -p $(pgrep -f kidslens_video_editor)

# Windows - attach VS debugger via Debug > Attach to Process
```
