# ONNX Runtime Execution Providers - Device Selection Research

**Date:** February 24, 2026  
**Purpose:** Research execution provider configuration and device selection for visual analysis GPU support  
**ONNX Runtime Version:** 1.20.1

---

## Executive Summary

ONNX Runtime supports multiple execution providers with varying device selection mechanisms:
- **CUDA**: Explicit device_id selection via `OrtCUDAProviderOptions`
- **DirectML**: Windows-only, automatic device enumeration via DXGI/DirectX
- **CoreML**: macOS, automatic GPU/Neural Engine selection
- **ROCm**: AMD GPUs with device_id selection via `OrtROCMProviderOptions`
- **TensorRT**: NVIDIA optimization layer on top of CUDA

**Key Finding:** ONNX Runtime C API 1.20.1 provides `GetAvailableProviders()` for runtime enumeration but **does NOT expose per-device capability queries**. Device selection must be done through provider-specific configuration structs.

---

## 1. CUDA Execution Provider (NVIDIA GPUs)

### 1.1 Device Selection Mechanism

Device selection is done via the `OrtCUDAProviderOptions` struct:

```c
typedef struct OrtCUDAProviderOptions {
  int device_id;                    // CUDA device Id (default: 0)
  OrtCudnnConvAlgoSearch cudnn_conv_algo_search;
  size_t gpu_mem_limit;             // Default: SIZE_MAX
  int arena_extend_strategy;        // 0=kNextPowerOfTwo, 1=kSameAsRequested
  int do_copy_in_default_stream;    // 1=same stream (default), 0=separate
  int has_user_compute_stream;
  void* user_compute_stream;
  OrtArenaCfg* default_memory_arena_cfg;
  int tunable_op_enable;            // Enable TunableOp (default: false)
  int tunable_op_tuning_enable;     // Enable tuning (default: false)
  int tunable_op_max_tuning_duration_ms;
} OrtCUDAProviderOptions;
```

### 1.2 C API Functions

```c
// Method 1: Using OrtCUDAProviderOptions struct (Recommended)
ORT_API2_STATUS(SessionOptionsAppendExecutionProvider_CUDA,
                _In_ OrtSessionOptions* options, 
                _In_ const OrtCUDAProviderOptions* cuda_options);

// Method 2: Using OrtCUDAProviderOptionsV2 (Opaque, newer)
ORT_API2_STATUS(SessionOptionsAppendExecutionProvider_CUDA_V2,
                _In_ OrtSessionOptions* options,
                _In_ const OrtCUDAProviderOptionsV2* provider_options);

// Legacy method (deprecated, simpler but limited)
ORT_API_STATUS(OrtSessionOptionsAppendExecutionProvider_CUDA,
               _In_ OrtSessionOptions* options, 
               int device_id);
```

### 1.3 Multi-GPU Support

**YES** - CUDA supports multi-GPU setups through explicit device_id specification.

**Device Enumeration:** Must be done externally via:
- **nvidia-smi**: Command-line tool (already in use in `gpu_manager.dart`)
- **CUDA Runtime API**: `cudaGetDeviceCount()`, `cudaGetDeviceProperties()`
- **Windows**: nvidia-smi.exe location: `C:\Program Files\NVIDIA Corporation\NVSMI\nvidia-smi.exe`

**Current Implementation in Codebase:**
```dart
// lib/native/gpu_manager.dart (lines 380-450)
Future<List<CudaGpuDevice>> enumerateCudaDevices() async {
  final result = await _runNvidiaSmi([
    '--query-gpu=index,name,memory.total',
    '--format=csv,noheader,nounits',
  ]);
  // Returns list with device_id, name, memoryTotalMB, computeCapability
}
```

### 1.4 Compute Capability Requirements

- **Minimum:** CUDA Compute Capability 6.0+
- **Recommended:** 7.5+ for Tensor Cores
- **Verification:** Query via `nvidia-smi --query-gpu=compute_cap`

### 1.5 Implementation Example

```c
// Pseudocode for ONNX Runtime CUDA setup
OrtCUDAProviderOptions cuda_options;
memset(&cuda_options, 0, sizeof(cuda_options));
cuda_options.device_id = 1;  // Select GPU 1
cuda_options.gpu_mem_limit = SIZE_MAX;  // Use all available VRAM
cuda_options.arena_extend_strategy = 0;  // kNextPowerOfTwo
cuda_options.cudnn_conv_algo_search = OrtCudnnConvAlgoSearchHeuristic;

OrtStatus* status = api->SessionOptionsAppendExecutionProvider_CUDA(
    session_options, 
    &cuda_options
);
```

---

## 2. DirectML Execution Provider (Windows: NVIDIA, AMD, Intel)

### 2.1 Device Selection Mechanism

**DirectML uses DXGI (DirectX Graphics Infrastructure) for device enumeration.**

**Key Characteristics:**
- Supports NVIDIA, AMD, and Intel GPUs on Windows
- Automatic device enumeration via DirectX
- Device selection done via config keys (key-value pairs)
- No explicit struct like CUDA

### 2.2 C API Functions

```c
// Generic provider addition with config keys
ORT_API2_STATUS(SessionOptionsAppendExecutionProvider,
                _In_ OrtSessionOptions* options,
                _In_ const char* provider_name,  // "DML"
                _In_reads_(num_keys) const char* const* provider_options_keys,
                _In_reads_(num_keys) const char* const* provider_options_values,
                _In_ size_t num_keys);
```

### 2.3 DirectML Configuration Keys

From `onnxruntime_session_options_config_keys.h` investigation:
- Default behavior when DirectML is registered: `disable_memory_arena = "1"`
- Device selection: **Not explicitly documented in headers**

**Microsoft Documentation (external):**
- DirectML uses DXGI adapter ordinal
- Config key: `"device_id"` (DXGI adapter index, default: 0)
- Config key: `"disable_metacommands"` (default: false)
- Config key: `"enable_graph_capture"` (default: true)

### 2.4 Multi-GPU Support

**YES** - DirectML supports multi-GPU via DXGI adapter enumeration.

**Device Enumeration:** Must be done via:
- **DXGI API**: `IDXGIFactory::EnumAdapters()`
- **Windows Management Instrumentation (WMI)**: Query `Win32_VideoController`
- **PowerShell**: `Get-WmiObject Win32_VideoController`

**Not Currently Implemented in Codebase**

### 2.5 Windows Version Requirements

- **Minimum:** Windows 10 version 1903 (May 2019 Update)
- **Recommended:** Windows 10 21H1+ or Windows 11
- DirectX 12 feature level 11_0+

### 2.6 Implementation Example

```c
// Pseudocode for DirectML setup
const char* keys[] = {"device_id"};
const char* values[] = {"1"};  // Select GPU 1

OrtStatus* status = api->SessionOptionsAppendExecutionProvider(
    session_options,
    "DML",
    keys,
    values,
    1  // num_keys
);
```

---

## 3. CoreML Execution Provider (macOS)

### 3.1 Device Selection Mechanism

**CoreML automatically selects between Neural Engine, GPU, and CPU.**

**Key Characteristics:**
- Apple's ML framework for macOS/iOS
- Automatic device selection (no manual GPU selection)
- Optimized for Apple Silicon (M1/M2/M3) Neural Engine
- Supports Intel Mac GPU acceleration via Metal

### 3.2 C API Functions

```c
// Generic provider with config keys
ORT_API2_STATUS(SessionOptionsAppendExecutionProvider,
                _In_ OrtSessionOptions* options,
                _In_ const char* provider_name,  // "CoreML"
                ...);
```

### 3.3 CoreML Configuration

**Config keys (from Apple documentation):**
- `"MLComputeUnits"`: Device preference
  - `"CPU"`: Force CPU
  - `"CPUAndGPU"`: Allow GPU (default)
  - `"All"`: Allow Neural Engine + GPU + CPU
- `"RequireEagerExecution"`: `"1"` or `"0"`

### 3.4 Neural Engine vs GPU

| Device | Available On | Use Case |
|--------|-------------|----------|
| Neural Engine | Apple Silicon (M1+) | Best for inference, very efficient |
| GPU (Metal) | Intel Mac + Apple Silicon | Good for mixed workloads |
| CPU | All Macs | Fallback |

**CoreML Decision Logic:**
- Neural Engine: Preferred for supported ops on Apple Silicon
- GPU: Used when Neural Engine unavailable or op unsupported
- CPU: Final fallback

### 3.5 M-Series GPU Cores

- **M1**: 7-8 GPU cores
- **M2**: 8-10 GPU cores
- **M3**: 10-40+ GPU cores (varies by model)
- These are accessed automatically via CoreML's Metal backend

### 3.6 Device Capability Query

**No direct per-GPU query in ONNX Runtime CoreML provider.**

**Alternative:** Use Apple's Metal API directly:
```swift
import Metal
let device = MTLCreateSystemDefaultDevice()
print(device?.name)
```

### 3.7 Implementation Example

```c
// Pseudocode for CoreML setup
const char* keys[] = {"MLComputeUnits"};
const char* values[] = {"All"};  // Allow Neural Engine

OrtStatus* status = api->SessionOptionsAppendExecutionProvider(
    session_options,
    "CoreML",
    keys,
    values,
    1
);
```

---

## 4. ROCm Execution Provider (AMD GPUs)

### 4.1 Device Selection Mechanism

Similar to CUDA, ROCm uses `OrtROCMProviderOptions` struct:

```c
typedef struct OrtROCMProviderOptions {
  int device_id;                    // ROCm device Id (default: 0)
  int miopen_conv_exhaustive_search;
  size_t gpu_mem_limit;
  int arena_extend_strategy;
  int do_copy_in_default_stream;
  int has_user_compute_stream;
  void* user_compute_stream;
  OrtArenaCfg* default_memory_arena_cfg;
  int enable_hip_graph;             // HIP graph optimization
  int tunable_op_enable;
  int tunable_op_tuning_enable;
  int tunable_op_max_tuning_duration_ms;
} OrtROCMProviderOptions;
```

### 4.2 C API Functions

```c
ORT_API2_STATUS(SessionOptionsAppendExecutionProvider_ROCM,
                _In_ OrtSessionOptions* options,
                _In_ const OrtROCMProviderOptions* rocm_options);
```

### 4.3 Multi-GPU Support

**YES** - via explicit device_id.

**Device Enumeration:** Use `rocm-smi` (AMD System Management Interface)
```bash
rocm-smi --showproductname        # List GPU names
rocm-smi --showmeminfo vram       # Show VRAM info
```

**Current Implementation in Codebase:**
```dart
// lib/native/gpu_manager.dart (lines 244-250)
Future<AcceleratorInfo?> _tryAmdRocm() async {
  final result = await Process.run('rocm-smi', ['--showproductname', '--showmeminfo', 'vram']);
  // Parse output to detect AMD GPU
}
```

### 4.4 Implementation Example

```c
// Pseudocode for ROCm setup
OrtROCMProviderOptions rocm_options;
memset(&rocm_options, 0, sizeof(rocm_options));
rocm_options.device_id = 0;
rocm_options.gpu_mem_limit = SIZE_MAX;

OrtStatus* status = api->SessionOptionsAppendExecutionProvider_ROCM(
    session_options,
    &rocm_options
);
```

---

## 5. TensorRT Execution Provider (NVIDIA Optimization Layer)

### 5.1 Overview

TensorRT is **not a replacement for CUDA** but an **optimization layer on top of CUDA**.

**Relationship:**
- TensorRT **requires CUDA** as a dependency
- Provides additional optimizations (kernel fusion, precision calibration, layer fusion)
- Use cases: Production inference where maximum performance is critical

### 5.2 Device Selection

```c
typedef struct OrtTensorRTProviderOptions {
  int device_id;                    // CUDA device id (0 = default)
  int has_user_compute_stream;
  void* user_compute_stream;
  int trt_max_partition_iterations;
  int trt_min_subgraph_size;
  size_t trt_max_workspace_size;
  int trt_fp16_enable;              // FP16 precision
  int trt_int8_enable;              // INT8 quantization
  const char* trt_int8_calibration_table_name;
  int trt_int8_use_native_calibration_table;
  int trt_dla_enable;               // Deep Learning Accelerator
  int trt_dla_core;
  int trt_dump_subgraphs;
  int trt_engine_cache_enable;
  const char* trt_engine_cache_path;
  // ... more options
} OrtTensorRTProviderOptions;
```

### 5.3 C API Functions

```c
// V2 API (recommended)
ORT_API2_STATUS(SessionOptionsAppendExecutionProvider_TensorRT_V2,
                _In_ OrtSessionOptions* options,
                _In_ const OrtTensorRTProviderOptionsV2* tensorrt_options);

// V1 API
ORT_API2_STATUS(SessionOptionsAppendExecutionProvider_TensorRT,
                _In_ OrtSessionOptions* options,
                _In_ const OrtTensorRTProviderOptions* tensorrt_options);
```

### 5.4 When to Use TensorRT

**Use TensorRT when:**
- Maximum inference speed is critical
- Model is stable (TensorRT builds optimized engines at first run)
- Targeting production deployment
- Have NVIDIA GPU with Compute Capability 6.0+

**Don't use TensorRT when:**
- Rapid prototyping (engine building adds overhead)
- Model changes frequently
- CUDA provider is fast enough

---

## 6. Runtime Provider Enumeration

### 6.1 GetAvailableProviders API

```c
/** Get the names of all available providers
 * 
 * The providers in the list are not guaranteed to be usable.
 * They may fail to load due to missing system dependencies.
 */
ORT_API2_STATUS(GetAvailableProviders, 
                _Outptr_ char*** out_ptr, 
                _Out_ int* provider_length);

ORT_API2_STATUS(ReleaseAvailableProviders, 
                _In_ char** ptr,
                _In_ int providers_length);
```

### 6.2 Usage Example (C++)

```cpp
#include <onnxruntime/core/session/onnxruntime_cxx_api.h>

std::vector<std::string> GetAvailableProviders() {
  char** providers;
  int provider_length;
  
  Ort::Status status = Ort::GetApi().GetAvailableProviders(&providers, &provider_length);
  if (!status.IsOK()) {
    return {};
  }
  
  std::vector<std::string> result;
  for (int i = 0; i < provider_length; i++) {
    result.push_back(providers[i]);
  }
  
  Ort::GetApi().ReleaseAvailableProviders(providers, provider_length);
  return result;
}
```

### 6.3 Expected Provider Names

Common provider names returned by `GetAvailableProviders()`:
- `"CPUExecutionProvider"` (always available)
- `"CUDAExecutionProvider"`
- `"DmlExecutionProvider"` (Windows)
- `"CoreMLExecutionProvider"` (macOS)
- `"ROCMExecutionProvider"`
- `"TensorRTExecutionProvider"`
- `"OpenVINOExecutionProvider"`

**Important:** Presence in the list doesn't guarantee usability. Provider may still fail during session creation due to missing drivers, libraries, or hardware.

---

## 7. Best Practices & Recommended Implementation

### 7.1 Default Device Selection Strategy

**Recommended Fallback Chain:**

```
1. Try GPU (CUDA/DirectML/CoreML/ROCm)
   - Select device_id = 0 (primary GPU)
   - If fails, try device_id = 1, 2, etc.
   
2. Try CPU
   - Always available as final fallback
```

### 7.2 Provider Priority Order

**For Visual Analysis (NSFW/Violence Detection):**

| Platform | Priority 1 | Priority 2 | Priority 3 | Fallback |
|----------|-----------|-----------|-----------|----------|
| Windows (NVIDIA) | CUDA | DirectML | TensorRT | CPU |
| Windows (AMD) | DirectML | ROCm | - | CPU |
| Windows (Intel) | DirectML | - | - | CPU |
| macOS | CoreML | - | - | CPU |
| Linux (NVIDIA) | CUDA | TensorRT | - | CPU |
| Linux (AMD) | ROCm | - | - | CPU |

### 7.3 Detection Logic Pseudocode

```dart
// Dart implementation strategy
class ONNXExecutionProviderManager {
  Future<ExecutionProviderConfig> detectBestProvider() async {
    // 1. Query available providers from ONNX Runtime
    final availableProviders = await _getAvailableProviders();
    
    // 2. Enumerate devices based on platform
    if (Platform.isWindows) {
      // Check for CUDA first
      final cudaDevices = await gpuManager.enumerateCudaDevices();
      if (cudaDevices.isNotEmpty && availableProviders.contains('CUDAExecutionProvider')) {
        return ExecutionProviderConfig.cuda(deviceId: 0);
      }
      
      // Fallback to DirectML
      if (availableProviders.contains('DmlExecutionProvider')) {
        final dxgiDevices = await _enumerateDXGIDevices();
        if (dxgiDevices.isNotEmpty) {
          return ExecutionProviderConfig.directML(deviceId: 0);
        }
      }
    } else if (Platform.isMacOS) {
      if (availableProviders.contains('CoreMLExecutionProvider')) {
        return ExecutionProviderConfig.coreML(computeUnits: 'All');
      }
    } else if (Platform.isLinux) {
      final cudaDevices = await gpuManager.enumerateCudaDevices();
      if (cudaDevices.isNotEmpty && availableProviders.contains('CUDAExecutionProvider')) {
        return ExecutionProviderConfig.cuda(deviceId: 0);
      }
      
      // Try ROCm
      if (availableProviders.contains('ROCMExecutionProvider')) {
        return ExecutionProviderConfig.rocm(deviceId: 0);
      }
    }
    
    // Final fallback
    return ExecutionProviderConfig.cpu();
  }
}
```

### 7.4 Error Handling Strategy

```dart
Future<ONNXSession> createSessionWithFallback(String modelPath) async {
  final providerChain = await _getProviderChain();
  
  for (final providerConfig in providerChain) {
    try {
      final session = await _createSession(modelPath, providerConfig);
      print('Successfully created session with ${providerConfig.name}');
      return session;
    } catch (e) {
      print('Failed to create session with ${providerConfig.name}: $e');
      // Try next provider
      continue;
    }
  }
  
  throw Exception('Failed to create ONNX session with any provider');
}
```

### 7.5 Performance Characteristics

| Provider | Typical Latency | Memory Usage | Power Consumption |
|----------|----------------|--------------|-------------------|
| CPU | Baseline (1.0x) | Baseline | Low |
| CUDA | 0.1-0.2x | High (VRAM) | High |
| DirectML | 0.15-0.3x | Medium-High | Medium-High |
| CoreML (Neural Engine) | 0.1-0.15x | Low | Very Low |
| CoreML (GPU) | 0.2-0.3x | Medium | Low-Medium |
| ROCm | 0.15-0.25x | High (VRAM) | High |
| TensorRT | 0.08-0.15x | High (VRAM) | High |

---

## 8. Known Limitations & Gotchas

### 8.1 Provider-Specific Issues

**CUDA:**
- Requires CUDA Toolkit installation (runtime libraries)
- cuDNN required for convolution layers
- Large VRAM requirements for vision models (2-8GB per model)
- Driver version must match CUDA version

**DirectML:**
- Windows 10 1903+ only
- Performance varies significantly between GPU vendors
- AMD GPUs: Generally good DirectML support
- Intel iGPUs: Slower than discrete GPUs but better than CPU
- Some operators not supported (fallback to CPU for specific layers)

**CoreML:**
- Model conversion overhead at first run
- Limited operator coverage (some ONNX ops unsupported)
- Neural Engine availability limited to Apple Silicon
- Intel Mac CoreML uses Metal (slower than Neural Engine)

**ROCm:**
- Linux-only (no Windows support in ONNX Runtime 1.20.1)
- Limited GPU compatibility (RX 5000+ series, Radeon VII, etc.)
- rocm-smi must be in PATH
- May require specific kernel versions

**TensorRT:**
- First-run engine building can take 1-10 minutes
- Engine files are GPU-specific (not portable)
- Requires large disk space for engine cache
- INT8 calibration requires representative data

### 8.2 ONNX Runtime C API Limitations

1. **No per-device capability query**: Cannot query VRAM, compute capability, or utilization from ONNX Runtime API
2. **No device count API**: Must use external tools (nvidia-smi, rocm-smi, DXGI)
3. **No automatic GPU selection**: Must manually specify device_id
4. **Provider order matters**: First provider to claim an operator wins (cannot mix)

### 8.3 Visual Analysis Specific Considerations

**Model Requirements (NSFW detection):**
- Input: 224x224 or 299x299 RGB images
- Batch size: 1-32 (depending on VRAM)
- Float32 inference: 4 bytes per pixel × W × H × 3 channels
- Example: 224×224×3 = ~600KB per image (uncompressed)

**Recommended VRAM:**
- Minimum: 2GB (batch_size=1)
- Recommended: 4GB (batch_size=4-8)
- Optimal: 6GB+ (batch_size=16-32)

**Fallback Strategy:**
- If GPU OOM: Reduce batch size or fallback to CPU
- If specific provider fails: Try next in chain
- If all GPU providers fail: CPU is acceptable for low frame rates

---

## 9. Implementation Roadmap

### Phase 1: Provider Enumeration (Week 1)
1. Implement `GetAvailableProviders()` FFI bindings
2. Create `ExecutionProviderDetector` service
3. Test on Windows (CUDA, DirectML), macOS (CoreML), Linux (CUDA, ROCm)

### Phase 2: Device Enumeration (Week 1-2)
1. **Windows**: Implement DXGI device enumeration for DirectML
2. **macOS**: Query Metal devices (though CoreML auto-selects)
3. **Linux**: Extend existing CUDA/ROCm enumeration in `gpu_manager.dart`

### Phase 3: Provider Configuration (Week 2)
1. Create provider config classes:
   - `CUDAProviderConfig(deviceId, memLimit)`
   - `DirectMLProviderConfig(deviceId)`
   - `CoreMLProviderConfig(computeUnits)`
   - `ROCMProviderConfig(deviceId)`
2. Implement FFI structs and marshalling

### Phase 4: Session Creation with Fallback (Week 2-3)
1. Implement `createSessionWithFallback()`
2. Add error handling and logging
3. Test provider chain on all platforms

### Phase 5: Visual Analysis Integration (Week 3)
1. Integrate into `VisualAnalysisService`
2. Add user-selectable device preference in settings
3. Performance benchmarking

### Phase 6: Optimization & Testing (Week 4)
1. Batch size optimization based on VRAM
2. Multi-GPU support (CUDA with device_id 1, 2, ...)
3. Comprehensive error handling

---

## 10. Code Examples

### 10.1 FFI Bindings (C API)

```dart
// lib/native/bindings/onnx_bindings.dart

import 'dart:ffi';
import 'package:ffi/ffi.dart';

// Native structs
final class OrtCUDAProviderOptionsNative extends Struct {
  @Int32()
  external int deviceId;
  
  @Int32()
  external int cudnnConvAlgoSearch;
  
  @Size()
  external int gpuMemLimit;
  
  @Int32()
  external int arenaExtendStrategy;
  
  @Int32()
  external int doCopyInDefaultStream;
  
  // ... rest of fields
}

final class OrtROCMProviderOptionsNative extends Struct {
  @Int32()
  external int deviceId;
  
  @Int32()
  external int miopenConvExhaustiveSearch;
  
  @Size()
  external int gpuMemLimit;
  
  // ... rest
}

// FFI function signatures
typedef GetAvailableProvidersNative = Pointer<Pointer<Char>> Function(
  Pointer<Pointer<Pointer<Char>>> outPtr,
  Pointer<Int32> providerLength,
);

typedef SessionOptionsAppendExecutionProvider_CUDANative = Pointer<Void> Function(
  Pointer<Void> options,
  Pointer<OrtCUDAProviderOptionsNative> cudaOptions,
);

class ONNXBindings {
  late final DynamicLibrary _lib;
  
  late final Pointer<Void> Function(
    Pointer<Pointer<Pointer<Char>>>, 
    Pointer<Int32>
  ) _getAvailableProviders;
  
  late final Pointer<Void> Function(
    Pointer<Void>,
    Pointer<OrtCUDAProviderOptionsNative>
  ) _appendCUDAProvider;
  
  ONNXBindings() {
    _lib = _loadLib();
    
    final api = _lib.lookup<Pointer<Void>>('OrtGetApiBase').cast<Pointer<Void>>();
    // Access OrtApi struct and lookup functions
    _getAvailableProviders = _lib.lookup<NativeFunction<GetAvailableProvidersNative>>(
      'OrtGetAvailableProviders'
    ).asFunction();
    
    _appendCUDAProvider = _lib.lookup<NativeFunction<SessionOptionsAppendExecutionProvider_CUDANative>>(
      'SessionOptionsAppendExecutionProvider_CUDA'
    ).asFunction();
  }
  
  List<String> getAvailableProviders() {
    final outPtr = calloc<Pointer<Pointer<Char>>>();
    final length = calloc<Int32>();
    
    try {
      final status = _getAvailableProviders(outPtr, length);
      if (status.address != 0) {
        // Handle error
        return [];
      }
      
      final providers = <String>[];
      final array = outPtr.value;
      for (var i = 0; i < length.value; i++) {
        providers.add(array[i].cast<Utf8>().toDartString());
      }
      
      return providers;
    } finally {
      calloc.free(outPtr);
      calloc.free(length);
    }
  }
}
```

### 10.2 Provider Selection Service

```dart
// lib/services/onnx_provider_service.dart

enum ExecutionProviderType {
  cpu,
  cuda,
  directML,
  coreML,
  rocm,
  tensorrt,
}

class ExecutionProviderConfig {
  final ExecutionProviderType type;
  final int? deviceId;
  final Map<String, String>? options;
  
  const ExecutionProviderConfig.cpu()
      : type = ExecutionProviderType.cpu,
        deviceId = null,
        options = null;
  
  const ExecutionProviderConfig.cuda({required int deviceId, int? memLimitMB})
      : type = ExecutionProviderType.cuda,
        deviceId = deviceId,
        options = memLimitMB != null ? {'gpu_mem_limit': '$memLimitMB'} : null;
  
  const ExecutionProviderConfig.directML({required int deviceId})
      : type = ExecutionProviderType.directML,
        deviceId = deviceId,
        options = null;
  
  const ExecutionProviderConfig.coreML({String computeUnits = 'All'})
      : type = ExecutionProviderType.coreML,
        deviceId = null,
        options = {'MLComputeUnits': computeUnits};
  
  String get name => type.toString().split('.').last;
}

class ONNXProviderService {
  final ONNXBindings _bindings;
  final GPUAccelerationManager _gpuManager;
  
  Future<List<ExecutionProviderConfig>> detectProviderChain() async {
    final available = _bindings.getAvailableProviders();
    final chain = <ExecutionProviderConfig>[];
    
    // Platform-specific detection
    if (Platform.isWindows) {
      chain.addAll(await _detectWindowsProviders(available));
    } else if (Platform.isMacOS) {
      chain.addAll(await _detectMacOSProviders(available));
    } else if (Platform.isLinux) {
      chain.addAll(await _detectLinuxProviders(available));
    }
    
    // Always add CPU as final fallback
    chain.add(const ExecutionProviderConfig.cpu());
    
    return chain;
  }
  
  Future<List<ExecutionProviderConfig>> _detectWindowsProviders(
    List<String> available,
  ) async {
    final providers = <ExecutionProviderConfig>[];
    
    // Priority 1: CUDA (if NVIDIA GPU present)
    if (available.contains('CUDAExecutionProvider')) {
      final cudaDevices = await _gpuManager.enumerateCudaDevices();
      for (final device in cudaDevices) {
        providers.add(ExecutionProviderConfig.cuda(deviceId: device.index));
      }
    }
    
    // Priority 2: DirectML (any GPU)
    if (available.contains('DmlExecutionProvider')) {
      final dxgiDevices = await _enumerateDXGIDevices();
      for (var i = 0; i < dxgiDevices.length && i < 3; i++) {
        providers.add(ExecutionProviderConfig.directML(deviceId: i));
      }
    }
    
    return providers;
  }
  
  Future<List<Map<String, dynamic>>> _enumerateDXGIDevices() async {
    // Use WMI or PowerShell to enumerate DXGI adapters
    final result = await Process.run('powershell', [
      '-Command',
      'Get-WmiObject Win32_VideoController | Select-Object Name, AdapterRAM, DriverVersion | ConvertTo-Json'
    ]);
    
    if (result.exitCode != 0) return [];
    
    try {
      final json = jsonDecode(result.stdout.toString());
      if (json is List) {
        return json.cast<Map<String, dynamic>>();
      } else if (json is Map) {
        return [json.cast<String, dynamic>()];
      }
    } catch (_) {}
    
    return [];
  }
}
```

---

## 11. References

### Official Documentation
- [ONNX Runtime C API](https://onnxruntime.ai/docs/api/c/index.html)
- [ONNX Runtime Execution Providers](https://onnxruntime.ai/docs/execution-providers/)
- [CUDA Provider](https://onnxruntime.ai/docs/execution-providers/CUDA-ExecutionProvider.html)
- [DirectML Provider](https://onnxruntime.ai/docs/execution-providers/DirectML-ExecutionProvider.html)
- [CoreML Provider](https://onnxruntime.ai/docs/execution-providers/CoreML-ExecutionProvider.html)
- [ROCm Provider](https://onnxruntime.ai/docs/execution-providers/ROCm-ExecutionProvider.html)
- [TensorRT Provider](https://onnxruntime.ai/docs/execution-providers/TensorRT-ExecutionProvider.html)

### System Tools
- nvidia-smi: NVIDIA System Management Interface
- rocm-smi: AMD ROCm System Management Interface
- DXGI API: DirectX Graphics Infrastructure (Windows)
- Metal API: Apple's GPU framework (macOS/iOS)

### Codebase Files Referenced
- `native/onnxruntime/include/onnxruntime_c_api.h` (lines 400-650, 2200-2650)
- `native/onnxruntime/include/provider_options.h`
- `lib/native/gpu_manager.dart` (lines 1-715)
- `lib/data/models/gpu_info.dart`
- `docs/native-integration.md`
- `docs/architecture.md`
- `docs/implement/ai-models-reference.md` (lines 980-1200)
- `docs/implement/comprehensive-implementation-plan.md` (lines 450-500)

---

## 12. Conclusion

**Key Takeaways:**

1. **Device Selection Strategy:**
   - CUDA/ROCm: Explicit device_id in provider options struct
   - DirectML: Device ID via config key-value pairs (DXGI enumeration required)
   - CoreML: Automatic selection (no per-device control)

2. **Multi-GPU Support:**
   - Fully supported by CUDA, ROCm, DirectML
   - Requires external enumeration tools (nvidia-smi, rocm-smi, DXGI)
   - CoreML: Single-device, automatic selection

3. **Runtime Detection:**
   - Use `GetAvailableProviders()` to query compiled-in providers
   - Provider presence doesn't guarantee usability
   - Implement fallback chain with error handling

4. **Implementation Priority:**
   - Phase 1: Provider enumeration and CPU fallback
   - Phase 2: CUDA support (Windows/Linux NVIDIA)
   - Phase 3: DirectML support (Windows all vendors)
   - Phase 4: CoreML support (macOS)
   - Phase 5: ROCm support (Linux AMD)

5. **Performance Expectations:**
   - GPU acceleration: 5-10x faster than CPU for visual analysis
   - Neural Engine (CoreML): Best power efficiency on Apple Silicon
   - TensorRT: Maximum performance but complex setup

**Next Steps:**
1. Implement FFI bindings for `GetAvailableProviders()`
2. Create provider configuration classes
3. Implement DXGI enumeration for Windows
4. Build session creation with automatic fallback
5. Integrate into `VisualAnalysisService`
6. Add user settings for GPU selection preferences

This research provides all necessary implementation details for robust GPU device selection across CUDA, DirectML, CoreML, and ROCm execution providers.
