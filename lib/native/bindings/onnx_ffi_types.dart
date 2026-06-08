// ignore_for_file: non_constant_identifier_names, camel_case_types

import 'dart:ffi';

import 'package:ffi/ffi.dart';

/// ONNX Runtime FFI type definitions
///
/// These map directly to the C API from onnxruntime_c_api.h
/// Based on ONNX Runtime v1.20.1

// ============================================================================
// Opaque handle types
// ============================================================================

/// OrtEnv - Environment handle
final class OrtEnv extends Opaque {}

/// OrtSession - Session handle
final class OrtSession extends Opaque {}

/// OrtSessionOptions - Session options
final class OrtSessionOptions extends Opaque {}

/// OrtRunOptions - Run options
final class OrtRunOptions extends Opaque {}

/// OrtValue - Tensor/sequence value
final class OrtValue extends Opaque {}

/// OrtMemoryInfo - Memory allocator info
final class OrtMemoryInfo extends Opaque {}

/// OrtAllocator - Memory allocator
final class OrtAllocator extends Opaque {}

/// OrtStatus - Status object (null = success)
final class OrtStatus extends Opaque {}

/// OrtTensorTypeAndShapeInfo - Tensor type/shape info
final class OrtTensorTypeAndShapeInfo extends Opaque {}

/// OrtTypeInfo - Type information
final class OrtTypeInfo extends Opaque {}

/// OrtCUDAProviderOptionsV2 - CUDA provider options (opaque)
final class OrtCUDAProviderOptionsV2 extends Opaque {}

/// OrtROCMProviderOptions - ROCm provider options (opaque)
final class OrtROCMProviderOptions extends Opaque {}

/// OrtApiBase - Base API for getting versioned API
final class OrtApiBase extends Struct {
  external Pointer<NativeFunction<Pointer<Void> Function(Uint32)>> GetApi;
  external Pointer<NativeFunction<Pointer<Utf8> Function()>> GetVersionString;
}

// ============================================================================
// Enums
// ============================================================================

/// ORT_API_VERSION - API version to request.
///
/// The bundled Windows ONNX Runtime in this repo currently exposes API 17.
/// Requesting a newer API returns null from OrtGetApiBase.GetApi.
const int ORT_API_VERSION = 17;

/// OrtLoggingLevel
abstract class OrtLoggingLevel {
  static const int ORT_LOGGING_LEVEL_VERBOSE = 0;
  static const int ORT_LOGGING_LEVEL_INFO = 1;
  static const int ORT_LOGGING_LEVEL_WARNING = 2;
  static const int ORT_LOGGING_LEVEL_ERROR = 3;
  static const int ORT_LOGGING_LEVEL_FATAL = 4;
}

/// GraphOptimizationLevel
abstract class GraphOptimizationLevel {
  static const int ORT_DISABLE_ALL = 0;
  static const int ORT_ENABLE_BASIC = 1;
  static const int ORT_ENABLE_EXTENDED = 2;
  static const int ORT_ENABLE_ALL = 99;
}

/// ONNXTensorElementDataType
abstract class ONNXTensorElementDataType {
  static const int ONNX_TENSOR_ELEMENT_DATA_TYPE_UNDEFINED = 0;
  static const int ONNX_TENSOR_ELEMENT_DATA_TYPE_FLOAT = 1;
  static const int ONNX_TENSOR_ELEMENT_DATA_TYPE_UINT8 = 2;
  static const int ONNX_TENSOR_ELEMENT_DATA_TYPE_INT8 = 3;
  static const int ONNX_TENSOR_ELEMENT_DATA_TYPE_UINT16 = 4;
  static const int ONNX_TENSOR_ELEMENT_DATA_TYPE_INT16 = 5;
  static const int ONNX_TENSOR_ELEMENT_DATA_TYPE_INT32 = 6;
  static const int ONNX_TENSOR_ELEMENT_DATA_TYPE_INT64 = 7;
  static const int ONNX_TENSOR_ELEMENT_DATA_TYPE_STRING = 8;
  static const int ONNX_TENSOR_ELEMENT_DATA_TYPE_BOOL = 9;
  static const int ONNX_TENSOR_ELEMENT_DATA_TYPE_FLOAT16 = 10;
  static const int ONNX_TENSOR_ELEMENT_DATA_TYPE_DOUBLE = 11;
  static const int ONNX_TENSOR_ELEMENT_DATA_TYPE_UINT32 = 12;
  static const int ONNX_TENSOR_ELEMENT_DATA_TYPE_UINT64 = 13;
}

/// OrtAllocatorType
abstract class OrtAllocatorType {
  static const int OrtInvalidAllocator = -1;
  static const int OrtDeviceAllocator = 0;
  static const int OrtArenaAllocator = 1;
}

/// OrtMemType
abstract class OrtMemType {
  static const int OrtMemTypeCPUInput = -2;
  static const int OrtMemTypeCPUOutput = -1;
  static const int OrtMemTypeCPU = -1;
  static const int OrtMemTypeDefault = 0;
}

// ============================================================================
// OrtApi function indices - based on onnxruntime_c_api.h v1.20.1
// ============================================================================

/// Function indices for OrtApi struct.
/// The OrtApi is a struct of function pointers.
abstract class OrtApiIndex {
  // Status functions (0-2)
  static const int CreateStatus = 0;
  static const int GetErrorCode = 1;
  static const int GetErrorMessage = 2;

  // Env functions (3-6)
  static const int CreateEnv = 3;
  static const int CreateEnvWithCustomLogger = 4;
  static const int EnableTelemetryEvents = 5;
  static const int DisableTelemetryEvents = 6;

  // Session functions (7-9)
  static const int CreateSession = 7;
  static const int CreateSessionFromArray = 8;
  static const int Run = 9;

  // SessionOptions functions (10-25)
  static const int CreateSessionOptions = 10;
  static const int SetOptimizedModelFilePath = 11;
  static const int CloneSessionOptions = 12;
  static const int SetSessionExecutionMode = 13;
  static const int EnableProfiling = 14;
  static const int DisableProfiling = 15;
  static const int EnableMemPattern = 16;
  static const int DisableMemPattern = 17;
  static const int EnableCpuMemArena = 18;
  static const int DisableCpuMemArena = 19;
  static const int SetSessionLogId = 20;
  static const int SetSessionLogVerbosityLevel = 21;
  static const int SetSessionLogSeverityLevel = 22;
  static const int SetSessionGraphOptimizationLevel = 23;
  static const int SetIntraOpNumThreads = 24;
  static const int SetInterOpNumThreads = 25;

  // CustomOp functions (26-29)
  static const int CreateCustomOpDomain = 26;
  static const int CustomOpDomain_Add = 27;
  static const int AddCustomOpDomain = 28;
  static const int RegisterCustomOpsLibrary = 29;

  // Session info functions (30-38)
  static const int SessionGetInputCount = 30;
  static const int SessionGetOutputCount = 31;
  static const int SessionGetOverridableInitializerCount = 32;
  static const int SessionGetInputTypeInfo = 33;
  static const int SessionGetOutputTypeInfo = 34;
  static const int SessionGetOverridableInitializerTypeInfo = 35;
  static const int SessionGetInputName = 36;
  static const int SessionGetOutputName = 37;
  static const int SessionGetOverridableInitializerName = 38;

  // RunOptions functions (39-47)
  static const int CreateRunOptions = 39;
  static const int RunOptionsSetRunLogVerbosityLevel = 40;
  static const int RunOptionsSetRunLogSeverityLevel = 41;
  static const int RunOptionsSetRunTag = 42;
  static const int RunOptionsGetRunLogVerbosityLevel = 43;
  static const int RunOptionsGetRunLogSeverityLevel = 44;
  static const int RunOptionsGetRunTag = 45;
  static const int RunOptionsSetTerminate = 46;
  static const int RunOptionsUnsetTerminate = 47;

  // Tensor functions (48-54)
  static const int CreateTensorAsOrtValue = 48;
  static const int CreateTensorWithDataAsOrtValue = 49;
  static const int IsTensor = 50;
  static const int GetTensorMutableData = 51;
  static const int FillStringTensor = 52;
  static const int GetStringTensorDataLength = 53;
  static const int GetStringTensorContent = 54;

  // TypeInfo functions (55-67)
  static const int CastTypeInfoToTensorInfo = 55;
  static const int GetOnnxTypeFromTypeInfo = 56;
  static const int CreateTensorTypeAndShapeInfo = 57;
  static const int SetTensorElementType = 58;
  static const int SetDimensions = 59;
  static const int GetTensorElementType = 60;
  static const int GetDimensionsCount = 61;
  static const int GetDimensions = 62;
  static const int GetSymbolicDimensions = 63;
  static const int GetTensorShapeElementCount = 64;
  static const int GetTensorTypeAndShape = 65;
  static const int GetTypeInfo = 66;
  static const int GetValueType = 67;

  // MemoryInfo functions (68-74)
  static const int CreateMemoryInfo = 68;
  static const int CreateCpuMemoryInfo = 69;
  static const int CompareMemoryInfo = 70;
  static const int MemoryInfoGetName = 71;
  static const int MemoryInfoGetId = 72;
  static const int MemoryInfoGetMemType = 73;
  static const int MemoryInfoGetType = 74;

  // Allocator functions (75-78)
  static const int AllocatorAlloc = 75;
  static const int AllocatorFree = 76;
  static const int AllocatorGetInfo = 77;
  static const int GetAllocatorWithDefaultOptions = 78;

  // Various value functions (79-91)
  static const int AddFreeDimensionOverride = 79;
  static const int GetValue = 80;
  static const int GetValueCount = 81;
  static const int CreateValue = 82;
  static const int CreateOpaqueValue = 83;
  static const int GetOpaqueValue = 84;
  static const int KernelInfoGetAttribute_float = 85;
  static const int KernelInfoGetAttribute_int64 = 86;
  static const int KernelInfoGetAttribute_string = 87;
  static const int KernelContext_GetInputCount = 88;
  static const int KernelContext_GetOutputCount = 89;
  static const int KernelContext_GetInput = 90;
  static const int KernelContext_GetOutput = 91;

  // Release functions (92-101)
  static const int ReleaseEnv = 92;
  static const int ReleaseStatus = 93;
  static const int ReleaseMemoryInfo = 94;
  static const int ReleaseSession = 95;
  static const int ReleaseValue = 96;
  static const int ReleaseRunOptions = 97;
  static const int ReleaseTypeInfo = 98;
  static const int ReleaseTensorTypeAndShapeInfo = 99;
  static const int ReleaseSessionOptions = 100;
  static const int ReleaseCustomOpDomain = 101;

  // CUDA Provider V2 API functions (150-153)
  static const int SessionOptionsAppendExecutionProvider_CUDA_V2 = 150;
  static const int CreateCUDAProviderOptions = 151;
  static const int UpdateCUDAProviderOptions = 152;
  static const int ReleaseCUDAProviderOptions = 153;

  // Generic execution provider append (180)
  static const int SessionOptionsAppendExecutionProvider = 180;
}

// ============================================================================
// Helper to access OrtApi functions by index
// ============================================================================

/// Helper class to access OrtApi function pointers dynamically by index.
/// The OrtApi is essentially an array of function pointers.
class OrtApiAccessor {
  final Pointer<Void> _apiPtr;

  OrtApiAccessor(this._apiPtr);

  /// Get a typed function pointer at the given index.
  /// T should be the native function type (e.g., CreateEnvNative).
  Pointer<NativeFunction<T>> getFunction<T extends Function>(int index) {
    // OrtApi is an array of function pointers (each 8 bytes on 64-bit)
    // Read the pointer at the given index
    final ptrArray = _apiPtr.cast<Pointer<Void>>();
    final funcPtr = ptrArray.elementAt(index).value;
    return funcPtr.cast<NativeFunction<T>>();
  }
}

// ============================================================================
// Native function types for the functions we use
// ============================================================================

// Status functions
typedef GetErrorCodeNative = Uint32 Function(Pointer<OrtStatus>);
typedef GetErrorCodeDart = int Function(Pointer<OrtStatus>);

typedef GetErrorMessageNative = Pointer<Utf8> Function(Pointer<OrtStatus>);
typedef GetErrorMessageDart = Pointer<Utf8> Function(Pointer<OrtStatus>);

// Env functions
typedef CreateEnvNative = Pointer<OrtStatus> Function(
  Int32 loggingLevel,
  Pointer<Utf8> logId,
  Pointer<Pointer<OrtEnv>> outEnv,
);
typedef CreateEnvDart = Pointer<OrtStatus> Function(
  int loggingLevel,
  Pointer<Utf8> logId,
  Pointer<Pointer<OrtEnv>> outEnv,
);

// Session functions (Windows uses wide chars for paths)
typedef CreateSessionNative = Pointer<OrtStatus> Function(
  Pointer<OrtEnv> env,
  Pointer<Utf16> modelPath,
  Pointer<OrtSessionOptions> options,
  Pointer<Pointer<OrtSession>> outSession,
);
typedef CreateSessionDart = Pointer<OrtStatus> Function(
  Pointer<OrtEnv> env,
  Pointer<Utf16> modelPath,
  Pointer<OrtSessionOptions> options,
  Pointer<Pointer<OrtSession>> outSession,
);

typedef CreateSessionFromArrayNative = Pointer<OrtStatus> Function(
  Pointer<OrtEnv> env,
  Pointer<Void> modelData,
  Size modelDataLength,
  Pointer<OrtSessionOptions> options,
  Pointer<Pointer<OrtSession>> outSession,
);
typedef CreateSessionFromArrayDart = Pointer<OrtStatus> Function(
  Pointer<OrtEnv> env,
  Pointer<Void> modelData,
  int modelDataLength,
  Pointer<OrtSessionOptions> options,
  Pointer<Pointer<OrtSession>> outSession,
);

typedef RunNative = Pointer<OrtStatus> Function(
  Pointer<OrtSession> session,
  Pointer<OrtRunOptions> runOptions,
  Pointer<Pointer<Utf8>> inputNames,
  Pointer<Pointer<OrtValue>> inputs,
  Size inputLen,
  Pointer<Pointer<Utf8>> outputNames,
  Size outputNamesLen,
  Pointer<Pointer<OrtValue>> outputs,
);
typedef RunDart = Pointer<OrtStatus> Function(
  Pointer<OrtSession> session,
  Pointer<OrtRunOptions> runOptions,
  Pointer<Pointer<Utf8>> inputNames,
  Pointer<Pointer<OrtValue>> inputs,
  int inputLen,
  Pointer<Pointer<Utf8>> outputNames,
  int outputNamesLen,
  Pointer<Pointer<OrtValue>> outputs,
);

// SessionOptions functions
typedef CreateSessionOptionsNative = Pointer<OrtStatus> Function(
  Pointer<Pointer<OrtSessionOptions>> outOptions,
);
typedef CreateSessionOptionsDart = Pointer<OrtStatus> Function(
  Pointer<Pointer<OrtSessionOptions>> outOptions,
);

typedef SetSessionGraphOptimizationLevelNative = Pointer<OrtStatus> Function(
  Pointer<OrtSessionOptions> options,
  Int32 level,
);
typedef SetSessionGraphOptimizationLevelDart = Pointer<OrtStatus> Function(
  Pointer<OrtSessionOptions> options,
  int level,
);

typedef SetIntraOpNumThreadsNative = Pointer<OrtStatus> Function(
  Pointer<OrtSessionOptions> options,
  Int32 numThreads,
);
typedef SetIntraOpNumThreadsDart = Pointer<OrtStatus> Function(
  Pointer<OrtSessionOptions> options,
  int numThreads,
);

// Session info functions
typedef SessionGetInputCountNative = Pointer<OrtStatus> Function(
  Pointer<OrtSession> session,
  Pointer<Size> outCount,
);
typedef SessionGetInputCountDart = Pointer<OrtStatus> Function(
  Pointer<OrtSession> session,
  Pointer<Size> outCount,
);

typedef SessionGetOutputCountNative = Pointer<OrtStatus> Function(
  Pointer<OrtSession> session,
  Pointer<Size> outCount,
);
typedef SessionGetOutputCountDart = Pointer<OrtStatus> Function(
  Pointer<OrtSession> session,
  Pointer<Size> outCount,
);

typedef SessionGetInputNameNative = Pointer<OrtStatus> Function(
  Pointer<OrtSession> session,
  Size index,
  Pointer<OrtAllocator> allocator,
  Pointer<Pointer<Utf8>> outName,
);
typedef SessionGetInputNameDart = Pointer<OrtStatus> Function(
  Pointer<OrtSession> session,
  int index,
  Pointer<OrtAllocator> allocator,
  Pointer<Pointer<Utf8>> outName,
);

typedef SessionGetOutputNameNative = Pointer<OrtStatus> Function(
  Pointer<OrtSession> session,
  Size index,
  Pointer<OrtAllocator> allocator,
  Pointer<Pointer<Utf8>> outName,
);
typedef SessionGetOutputNameDart = Pointer<OrtStatus> Function(
  Pointer<OrtSession> session,
  int index,
  Pointer<OrtAllocator> allocator,
  Pointer<Pointer<Utf8>> outName,
);

// RunOptions functions
typedef CreateRunOptionsNative = Pointer<OrtStatus> Function(
  Pointer<Pointer<OrtRunOptions>> outOptions,
);
typedef CreateRunOptionsDart = Pointer<OrtStatus> Function(
  Pointer<Pointer<OrtRunOptions>> outOptions,
);

// Tensor functions
typedef CreateTensorWithDataAsOrtValueNative = Pointer<OrtStatus> Function(
  Pointer<OrtMemoryInfo> memInfo,
  Pointer<Void> data,
  Size dataLen,
  Pointer<Int64> shape,
  Size shapeLen,
  Int32 dataType,
  Pointer<Pointer<OrtValue>> outValue,
);
typedef CreateTensorWithDataAsOrtValueDart = Pointer<OrtStatus> Function(
  Pointer<OrtMemoryInfo> memInfo,
  Pointer<Void> data,
  int dataLen,
  Pointer<Int64> shape,
  int shapeLen,
  int dataType,
  Pointer<Pointer<OrtValue>> outValue,
);

typedef GetTensorMutableDataNative = Pointer<OrtStatus> Function(
  Pointer<OrtValue> value,
  Pointer<Pointer<Void>> outData,
);
typedef GetTensorMutableDataDart = Pointer<OrtStatus> Function(
  Pointer<OrtValue> value,
  Pointer<Pointer<Void>> outData,
);

// TypeInfo functions
typedef GetTensorTypeAndShapeNative = Pointer<OrtStatus> Function(
  Pointer<OrtValue> value,
  Pointer<Pointer<OrtTensorTypeAndShapeInfo>> outInfo,
);
typedef GetTensorTypeAndShapeDart = Pointer<OrtStatus> Function(
  Pointer<OrtValue> value,
  Pointer<Pointer<OrtTensorTypeAndShapeInfo>> outInfo,
);

typedef GetDimensionsCountNative = Pointer<OrtStatus> Function(
  Pointer<OrtTensorTypeAndShapeInfo> info,
  Pointer<Size> outCount,
);
typedef GetDimensionsCountDart = Pointer<OrtStatus> Function(
  Pointer<OrtTensorTypeAndShapeInfo> info,
  Pointer<Size> outCount,
);

typedef GetDimensionsNative = Pointer<OrtStatus> Function(
  Pointer<OrtTensorTypeAndShapeInfo> info,
  Pointer<Int64> dims,
  Size dimsLength,
);
typedef GetDimensionsDart = Pointer<OrtStatus> Function(
  Pointer<OrtTensorTypeAndShapeInfo> info,
  Pointer<Int64> dims,
  int dimsLength,
);

// MemoryInfo functions
typedef CreateCpuMemoryInfoNative = Pointer<OrtStatus> Function(
  Int32 allocatorType,
  Int32 memType,
  Pointer<Pointer<OrtMemoryInfo>> outInfo,
);
typedef CreateCpuMemoryInfoDart = Pointer<OrtStatus> Function(
  int allocatorType,
  int memType,
  Pointer<Pointer<OrtMemoryInfo>> outInfo,
);

// Allocator functions
typedef GetAllocatorWithDefaultOptionsNative = Pointer<OrtStatus> Function(
  Pointer<Pointer<OrtAllocator>> outAllocator,
);
typedef GetAllocatorWithDefaultOptionsDart = Pointer<OrtStatus> Function(
  Pointer<Pointer<OrtAllocator>> outAllocator,
);

typedef AllocatorFreeNative = Pointer<OrtStatus> Function(
  Pointer<OrtAllocator> allocator,
  Pointer<Void> ptr,
);
typedef AllocatorFreeDart = Pointer<OrtStatus> Function(
  Pointer<OrtAllocator> allocator,
  Pointer<Void> ptr,
);

// Release functions (return void)
typedef ReleaseEnvNative = Void Function(Pointer<OrtEnv>);
typedef ReleaseEnvDart = void Function(Pointer<OrtEnv>);

typedef ReleaseStatusNative = Void Function(Pointer<OrtStatus>);
typedef ReleaseStatusDart = void Function(Pointer<OrtStatus>);

typedef ReleaseMemoryInfoNative = Void Function(Pointer<OrtMemoryInfo>);
typedef ReleaseMemoryInfoDart = void Function(Pointer<OrtMemoryInfo>);

typedef ReleaseSessionNative = Void Function(Pointer<OrtSession>);
typedef ReleaseSessionDart = void Function(Pointer<OrtSession>);

typedef ReleaseValueNative = Void Function(Pointer<OrtValue>);
typedef ReleaseValueDart = void Function(Pointer<OrtValue>);

typedef ReleaseRunOptionsNative = Void Function(Pointer<OrtRunOptions>);
typedef ReleaseRunOptionsDart = void Function(Pointer<OrtRunOptions>);

typedef ReleaseTypeInfoNative = Void Function(Pointer<OrtTypeInfo>);
typedef ReleaseTypeInfoDart = void Function(Pointer<OrtTypeInfo>);

typedef ReleaseTensorTypeAndShapeInfoNative = Void Function(
  Pointer<OrtTensorTypeAndShapeInfo>,
);
typedef ReleaseTensorTypeAndShapeInfoDart = void Function(
  Pointer<OrtTensorTypeAndShapeInfo>,
);

typedef ReleaseSessionOptionsNative = Void Function(
  Pointer<OrtSessionOptions>,
);
typedef ReleaseSessionOptionsDart = void Function(Pointer<OrtSessionOptions>);

// OrtGetApiBase function type
typedef OrtGetApiBaseNative = Pointer<OrtApiBase> Function();
typedef OrtGetApiBaseDart = Pointer<OrtApiBase> Function();

// ============================================================================
// CUDA Provider V2 API function types
// ============================================================================

typedef CreateCUDAProviderOptionsNative = Pointer<OrtStatus> Function(
  Pointer<Pointer<OrtCUDAProviderOptionsV2>> outOptions,
);
typedef CreateCUDAProviderOptionsDart = Pointer<OrtStatus> Function(
  Pointer<Pointer<OrtCUDAProviderOptionsV2>> outOptions,
);

typedef UpdateCUDAProviderOptionsNative = Pointer<OrtStatus> Function(
  Pointer<OrtCUDAProviderOptionsV2> cudaOptions,
  Pointer<Pointer<Utf8>> providerOptionsKeys,
  Pointer<Pointer<Utf8>> providerOptionsValues,
  Size numKeys,
);
typedef UpdateCUDAProviderOptionsDart = Pointer<OrtStatus> Function(
  Pointer<OrtCUDAProviderOptionsV2> cudaOptions,
  Pointer<Pointer<Utf8>> providerOptionsKeys,
  Pointer<Pointer<Utf8>> providerOptionsValues,
  int numKeys,
);

typedef SessionOptionsAppendExecutionProvider_CUDA_V2Native = Pointer<OrtStatus>
    Function(
  Pointer<OrtSessionOptions> options,
  Pointer<OrtCUDAProviderOptionsV2> cudaOptions,
);
typedef SessionOptionsAppendExecutionProvider_CUDA_V2Dart = Pointer<OrtStatus>
    Function(
  Pointer<OrtSessionOptions> options,
  Pointer<OrtCUDAProviderOptionsV2> cudaOptions,
);

typedef ReleaseCUDAProviderOptionsNative = Void Function(
  Pointer<OrtCUDAProviderOptionsV2> cudaOptions,
);
typedef ReleaseCUDAProviderOptionsDart = void Function(
  Pointer<OrtCUDAProviderOptionsV2> cudaOptions,
);

// ============================================================================
// Generic execution provider API function types
// ============================================================================

typedef SessionOptionsAppendExecutionProviderNative = Pointer<OrtStatus>
    Function(
  Pointer<OrtSessionOptions> options,
  Pointer<Utf8> providerName,
  Pointer<Pointer<Utf8>> providerOptionsKeys,
  Pointer<Pointer<Utf8>> providerOptionsValues,
  Size numKeys,
);
typedef SessionOptionsAppendExecutionProviderDart = Pointer<OrtStatus> Function(
  Pointer<OrtSessionOptions> options,
  Pointer<Utf8> providerName,
  Pointer<Pointer<Utf8>> providerOptionsKeys,
  Pointer<Pointer<Utf8>> providerOptionsValues,
  int numKeys,
);

// ============================================================================
// DirectML device configuration helper
// ============================================================================

/// Configuration for DirectML execution provider
class DirectMLDeviceConfig {
  const DirectMLDeviceConfig({
    required this.deviceId,
    this.enableGraphCapture = true,
    this.disableMetaCommands = false,
  });

  final int deviceId;
  final bool enableGraphCapture;
  final bool disableMetaCommands;

  /// Convert configuration to key-value pairs for ONNX Runtime
  Map<String, String> toKeyValuePairs() {
    return {
      'device_id': deviceId.toString(),
      if (enableGraphCapture) 'enable_graph_capture': '1',
      if (disableMetaCommands) 'disable_metacommands': '1',
    };
  }
}
