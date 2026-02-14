# Whisper Native Library

This directory contains the C wrapper for whisper.cpp, providing FFI bindings
for real-time speech recognition in KidsLens Video Editor.

## Overview

The whisper_wrapper library wraps [whisper.cpp](https://github.com/ggml-org/whisper.cpp)
and exposes a clean C API that can be called from Dart via FFI.

## Automatic Build (Recommended)

The whisper_wrapper library is **automatically built** as part of the Flutter build process.

Simply run:

```bash
# Windows
flutter build windows

# Or for debug
flutter run -d windows
```

The library will be built and placed in the correct location automatically.

### Build Options

You can customize the build by setting CMake options:

```bash
# Enable CUDA GPU acceleration (requires NVIDIA GPU + CUDA Toolkit)
flutter build windows --dart-define=WHISPER_USE_CUDA=ON

# Enable Vulkan GPU acceleration
flutter build windows --dart-define=WHISPER_USE_VULKAN=ON

# Disable whisper_wrapper build (uses placeholder mode)
flutter build windows --dart-define=BUILD_WHISPER_WRAPPER=OFF
```

Or edit `windows/CMakeLists.txt` directly:
```cmake
option(WHISPER_USE_CUDA "Enable CUDA GPU acceleration for Whisper" ON)
```

## Manual Build (Alternative)

If you need to build separately:

```bash
# Create build directory
mkdir build && cd build

# Configure (whisper.cpp will be downloaded automatically)
cmake .. -DWHISPER_USE_BUNDLED=ON

# Build
cmake --build . --config Release
```

### Windows (Visual Studio)

```powershell
# Using Visual Studio 2022
cmake -B build -G "Visual Studio 17 2022" -DWHISPER_USE_BUNDLED=ON
cmake --build build --config Release

# Output: build/Release/whisper_wrapper.dll
```

### macOS

```bash
# Build with Metal GPU acceleration
cmake -B build -DWHISPER_USE_BUNDLED=ON -DWHISPER_USE_METAL=ON
cmake --build build

# Output: build/libwhisper_wrapper.dylib
```

### Linux

```bash
cmake -B build -DWHISPER_USE_BUNDLED=ON
cmake --build build

# Output: build/libwhisper_wrapper.so
```

### GPU Acceleration

Enable GPU support with these options:

```bash
# CUDA (NVIDIA GPUs)
cmake -B build -DWHISPER_USE_CUDA=ON

# Metal (Apple Silicon/AMD on macOS)
cmake -B build -DWHISPER_USE_METAL=ON

# Vulkan (Cross-platform)
cmake -B build -DWHISPER_USE_VULKAN=ON
```

## Installation

Copy the built library to the appropriate location:

### Windows
```powershell
# Copy to app directory
copy build\Release\whisper_wrapper.dll ..\..\..\build\windows\x64\runner\Release\
```

### macOS
```bash
# Copy to Frameworks
cp build/libwhisper_wrapper.dylib ../../build/macos/Build/Products/Release/YourApp.app/Contents/Frameworks/
```

### Linux
```bash
# Copy to lib directory
cp build/libwhisper_wrapper.so ../../build/linux/x64/release/bundle/lib/
```

## API Overview

### Initialization

```c
// Load a model
WhisperHandle handle = whisper_init("path/to/model.bin");

// Get model info
WhisperModelInfo info = whisper_get_model_info(handle);

// Check GPU availability
bool hasGpu = whisper_gpu_available();
const char* gpuName = whisper_gpu_name();
```

### Transcription

```c
// Create config
WhisperConfig config = whisper_default_config();
config.language = "en";  // or NULL for auto-detect
config.word_timestamps = true;

// Transcribe audio file
WhisperResult* result = whisper_transcribe_file(handle, "audio.wav", &config);

// Or transcribe PCM data directly
WhisperResult* result = whisper_transcribe_pcm(handle, samples, numSamples, &config);

// Process results
for (int i = 0; i < result->num_segments; i++) {
    WhisperSegment* seg = &result->segments[i];
    printf("[%lld-%lld] %s\n", seg->start_ms, seg->end_ms, seg->text);
}

// Free result
whisper_free_result(result);
```

### Cleanup

```c
// Free model
whisper_free(handle);
```

## Model Files

Download GGML-format Whisper models from HuggingFace:

| Model | Size | Languages | Speed | Download |
|-------|------|-----------|-------|----------|
| tiny | 75MB | 99 | ~10x | [Link](https://huggingface.co/ggerganov/whisper.cpp/blob/main/ggml-tiny.bin) |
| base | 142MB | 99 | ~7x | [Link](https://huggingface.co/ggerganov/whisper.cpp/blob/main/ggml-base.bin) |
| small | 466MB | 99 | ~4x | [Link](https://huggingface.co/ggerganov/whisper.cpp/blob/main/ggml-small.bin) |
| medium | 1.5GB | 99 | ~2x | [Link](https://huggingface.co/ggerganov/whisper.cpp/blob/main/ggml-medium.bin) |
| large-v3 | 3GB | 99 | ~1x | [Link](https://huggingface.co/ggerganov/whisper.cpp/blob/main/ggml-large-v3.bin) |

The app automatically downloads models via ModelManagerService.

## Audio Format

The native library accepts:
- WAV files (16kHz mono recommended)
- PCM float32 samples at 16kHz

For other formats, convert using FFmpeg:
```bash
ffmpeg -i input.mp3 -ar 16000 -ac 1 -c:a pcm_s16le output.wav
```

## Error Handling

```c
// Check for errors
const char* error = whisper_get_error();
if (error) {
    printf("Error: %s\n", error);
    whisper_clear_error();
}
```

## Thread Safety

- Each WhisperHandle is NOT thread-safe
- Create separate handles for concurrent transcription
- The error string is thread-local

## License

The wrapper code is MIT licensed.
whisper.cpp is MIT licensed.
Whisper models are MIT licensed.
