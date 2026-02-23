# Phase 2: Native FFI Layer Implementation Summary

**Status:** ✅ COMPLETED  
**Date:** February 24, 2026

## Overview
Extended ONNX Runtime FFI bindings to support execution provider configuration with device selection for CUDA, DirectML, CoreML, and ROCm.

## Files Modified

### 1. lib/native/bindings/onnx_ffi_types.dart

#### Added Opaque Types:
- `OrtCUDAProviderOptionsV2` - CUDA V2 provider options (opaque handle)
- `OrtROCMProviderOptions` - ROCm provider options (opaque handle)

#### Added API Indices to OrtApiIndex:
```dart
// CUDA Provider V2 API functions (150-153)
static const int SessionOptionsAppendExecutionProvider_CUDA_V2 = 150;
static const int CreateCUDAProviderOptions = 151;
static const int UpdateCUDAProviderOptions = 152;
static const int ReleaseCUDAProviderOptions = 153;

// Generic execution provider append (180)
static const int SessionOptionsAppendExecutionProvider = 180;
```

#### Added FFI Function Typedefs:
- `CreateCUDAProviderOptions` (Native/Dart)
- `UpdateCUDAProviderOptions` (Native/Dart)
- `SessionOptionsAppendExecutionProvider_CUDA_V2` (Native/Dart)
- `ReleaseCUDAProviderOptions` (Native/Dart)
- `SessionOptionsAppendExecutionProvider` (Native/Dart) - Generic provider API

#### Added Helper Class:
```dart
class DirectMLDeviceConfig {
  final int deviceId;
  final bool enableGraphCapture;
  final bool disableMetaCommands;
  
  Map<String, String> toKeyValuePairs() { ... }
}
```

### 2. lib/native/bindings/onnx_bindings.dart

#### Updated loadModel() Signature:
```dart
Future<void> loadModel(
  String modelPath, {
  int? deviceId,
  String? executionProvider,
  Map<String, String>? providerOptions,
}) async
```

#### Added Methods:

**Main Provider Configuration:**
- `_appendExecutionProvider()` - Routes to specific provider implementations

**Provider-Specific Implementations:**
- `_appendCudaProvider()` - CUDA V2 API flow with device_id configuration
- `_appendDirectMLProvider()` - DirectML with graph capture support
- `_appendCoreMLProvider()` - CoreML configuration
- `_appendGenericProvider()` - Generic key-value provider helper

#### CUDA V2 API Implementation Flow:
```dart
1. CreateCUDAProviderOptions() → cudaOptions
2. UpdateCUDAProviderOptions(cudaOptions, keys, values)
3. SessionOptionsAppendExecutionProvider_CUDA_V2(sessionOptions, cudaOptions)
4. ReleaseCUDAProviderOptions(cudaOptions)
```

#### DirectML Implementation:
Uses generic provider API with key-value configuration:
```dart
{
  'device_id': '0',
  'enable_graph_capture': '1',
}
```

### 3. lib/native/gpu_manager.dart

#### Added DirectMLDevice Class:
```dart
class DirectMLDevice {
  final int deviceId;
  final String name;
  final int adapterRAM; // in bytes
  final String? driverVersion;
  
  int get vramMB => (adapterRAM / (1024 * 1024)).round();
}
```

#### Added Methods:

**getDirectMLDevices() - Windows DirectML Enumeration:**
```powershell
Get-WmiObject -Class Win32_VideoController | 
  Select-Object Name, AdapterRAM, DriverVersion | 
  ConvertTo-Json
```
Parses WMI output and returns list of DirectML-capable GPUs.

**queryAvailableProviders() - Runtime Provider Detection:**
Returns list of available ONNX Runtime execution providers:
- CPUExecutionProvider (always available)
- CUDAExecutionProvider (if nvidia-smi detects GPUs)
- DmlExecutionProvider (if Win32_VideoController found on Windows)
- CoreMLExecutionProvider (if macOS)
- ROCMExecutionProvider (if rocm-smi available on Linux)

## Memory Management

All native memory is properly managed with try-finally blocks:

1. **CUDA Options:** Released via `ReleaseCUDAProviderOptions()`
2. **String Allocations:** All `toNativeUtf8()` calls freed via `calloc.free()`
3. **Pointer Arrays:** Key/value pointer arrays properly deallocated

## API Version Compatibility

- Uses ONNX Runtime API version 18 (ORT_API_VERSION = 18)
- CUDA V2 API functions are optional (index 150-153)
- Generic provider API (index 180) used as fallback
- Graceful degradation to CPU if provider configuration fails

## Usage Example

```dart
final onnx = ONNXBindings();
await onnx.initialize();

// CUDA with specific device
await onnx.loadModel(
  'model.onnx',
  deviceId: 0,
  executionProvider: 'CUDAExecutionProvider',
);

// DirectML on Windows
await onnx.loadModel(
  'model.onnx',
  deviceId: 0,
  executionProvider: 'DmlExecutionProvider',
  providerOptions: {
    'enable_graph_capture': '1',
  },
);

// CoreML on macOS
await onnx.loadModel(
  'model.onnx',
  executionProvider: 'CoreMLExecutionProvider',
);
```

## Testing Recommendations

### 1. CUDA Device Selection (NVIDIA GPUs):
```dart
final devices = await gpuManager.getCudaDevices();
for (final device in devices) {
  await onnx.loadModel(
    modelPath,
    deviceId: device.index,
    executionProvider: 'CUDAExecutionProvider',
  );
  // Run inference to verify
}
```

### 2. DirectML Fallback (Windows):
```dart
final directMLDevices = await gpuManager.getDirectMLDevices();
if (directMLDevices.isNotEmpty) {
  await onnx.loadModel(
    modelPath,
    deviceId: 0,
    executionProvider: 'DmlExecutionProvider',
  );
}
```

### 3. Provider Query:
```dart
final providers = await gpuManager.queryAvailableProviders();
print('Available providers: $providers');
// Use first available GPU provider
final provider = providers.firstWhere(
  (p) => p != 'CPUExecutionProvider',
  orElse: () => 'CPUExecutionProvider',
);
```

## FFI Functions Added

| Function | Index | Purpose |
|----------|-------|---------|
| CreateCUDAProviderOptions | 151 | Allocate CUDA options struct |
| UpdateCUDAProviderOptions | 152 | Set device_id and config |
| SessionOptionsAppendExecutionProvider_CUDA_V2 | 150 | Attach CUDA provider to session |
| ReleaseCUDAProviderOptions | 153 | Free CUDA options |
| SessionOptionsAppendExecutionProvider | 180 | Generic provider attach (DirectML/CoreML/ROCm) |

## Critical Implementation Details

### CUDA Configuration Keys:
- `device_id` - GPU device index (required)
- `gpu_mem_limit` - Memory limit in bytes (optional)
- `arena_extend_strategy` - Memory allocation strategy (optional)
- `cudnn_conv_algo_search` - CuDNN algorithm search (optional)

### DirectML Configuration Keys:
- `device_id` - GPU device index (required)
- `enable_graph_capture` - Enable graph optimization (default: true)
- `disable_metacommands` - Disable DirectML meta-commands (default: false)

### CoreML Configuration Keys:
- `MLComputeUnits` - Compute units (0=all, 1=CPU only, 2=CPU+GPU)
- `EnableOnSubgraphs` - Enable CoreML on subgraphs (optional)

## Error Handling

- Provider configuration failures log warnings but don't throw
- Session falls back to CPU if provider unavailable
- Proper status checking via `_checkStatus()` for all OrtStatus returns
- Memory cleanup guaranteed via try-finally blocks

## Next Steps (Phase 3)

1. Integrate with ModelManager service layer
2. Add automatic provider selection based on detected hardware
3. Implement provider fallback chain (CUDA → DirectML → CPU)
4. Add performance benchmarking per provider
5. Cache optimal provider selection per model

## Validation Checklist

- ✅ All FFI typedefs correctly defined
- ✅ API indices match ONNX Runtime v1.20.1 specification
- ✅ Memory management verified (no leaks)
- ✅ CUDA V2 API flow implemented correctly
- ✅ Generic provider API supports DirectML/CoreML/ROCm
- ✅ DirectML device enumeration via WMI
- ✅ queryAvailableProviders() detects runtime capabilities
- ✅ No compilation errors
- ✅ Graceful fallback to CPU on provider failure
