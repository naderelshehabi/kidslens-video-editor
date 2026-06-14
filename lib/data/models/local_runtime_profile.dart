import 'dart:convert';

import 'package:kidslens_video_editor/data/models/model_bundle_manifest.dart';

enum LocalRuntimeId {
  cudaLlamaCpp('cuda_llamacpp'),
  vulkanLlamaCpp('vulkan_llamacpp'),
  cudaTensorRt('cuda_tensorrt'),
  cudaVllm('cuda_vllm'),
  cudaTransformersHelper('cuda_transformers_helper'),
  directmlOnnx('directml_onnx'),
  cpuLightweight('cpu_lightweight');

  const LocalRuntimeId(this.jsonValue);

  final String jsonValue;

  static LocalRuntimeId fromJson(String value) =>
      LocalRuntimeId.values.firstWhere(
        (runtime) => runtime.jsonValue == value,
        orElse: () => throw ArgumentError('Unknown runtime ID: $value'),
      );
}

enum LocalRuntimeSelectionStatus {
  selected,
  fallbackSelected,
  rejected,
}

class LocalRuntimeProfile {
  const LocalRuntimeProfile({
    required this.id,
    required this.displayName,
    required this.modelRuntime,
    required this.preferredExecutionProviders,
    required this.supportsGpu,
    required this.supportsCpu,
    required this.requiresCuda,
    required this.requiresOnnx,
    required this.usesLoopbackServer,
    this.description = '',
  });

  final LocalRuntimeId id;
  final String displayName;
  final ModelBundleRuntime modelRuntime;
  final List<String> preferredExecutionProviders;
  final bool supportsGpu;
  final bool supportsCpu;
  final bool requiresCuda;
  final bool requiresOnnx;
  final bool usesLoopbackServer;
  final String description;

  Map<String, dynamic> toJson() => {
        'id': id.jsonValue,
        'displayName': displayName,
        'modelRuntime': modelRuntime.name,
        'preferredExecutionProviders': preferredExecutionProviders,
        'supportsGpu': supportsGpu,
        'supportsCpu': supportsCpu,
        'requiresCuda': requiresCuda,
        'requiresOnnx': requiresOnnx,
        'usesLoopbackServer': usesLoopbackServer,
        'description': description,
      };

  static const profiles = <LocalRuntimeProfile>[
    LocalRuntimeProfile(
      id: LocalRuntimeId.cudaLlamaCpp,
      displayName: 'Local llama.cpp server (CUDA)',
      modelRuntime: ModelBundleRuntime.llamaCppServer,
      preferredExecutionProviders: <String>['CUDAExecutionProvider'],
      supportsGpu: true,
      supportsCpu: false,
      requiresCuda: true,
      requiresOnnx: false,
      usesLoopbackServer: true,
      description: 'Bundled local llama.cpp server using CUDA on loopback.',
    ),
    LocalRuntimeProfile(
      id: LocalRuntimeId.vulkanLlamaCpp,
      displayName: 'Local llama.cpp server (Vulkan)',
      modelRuntime: ModelBundleRuntime.llamaCppServer,
      preferredExecutionProviders: <String>['Vulkan'],
      supportsGpu: true,
      supportsCpu: false,
      requiresCuda: false,
      requiresOnnx: false,
      usesLoopbackServer: true,
      description:
          'Bundled local llama.cpp server using Vulkan GPU acceleration on loopback.',
    ),
    LocalRuntimeProfile(
      id: LocalRuntimeId.cudaTensorRt,
      displayName: 'CUDA TensorRT',
      modelRuntime: ModelBundleRuntime.cudaTensorRt,
      preferredExecutionProviders: <String>['CUDAExecutionProvider'],
      supportsGpu: true,
      supportsCpu: false,
      requiresCuda: true,
      requiresOnnx: false,
      usesLoopbackServer: false,
      description: 'Local NVIDIA CUDA/TensorRT runtime.',
    ),
    LocalRuntimeProfile(
      id: LocalRuntimeId.cudaVllm,
      displayName: 'CUDA vLLM',
      modelRuntime: ModelBundleRuntime.cudaVllm,
      preferredExecutionProviders: <String>['CUDAExecutionProvider'],
      supportsGpu: true,
      supportsCpu: false,
      requiresCuda: true,
      requiresOnnx: false,
      usesLoopbackServer: true,
      description: 'Local vLLM server bound to loopback.',
    ),
    LocalRuntimeProfile(
      id: LocalRuntimeId.cudaTransformersHelper,
      displayName: 'CUDA Transformers Helper',
      modelRuntime: ModelBundleRuntime.cudaTransformersHelper,
      preferredExecutionProviders: <String>['CUDAExecutionProvider'],
      supportsGpu: true,
      supportsCpu: false,
      requiresCuda: true,
      requiresOnnx: false,
      usesLoopbackServer: true,
      description: 'Local Python/Transformers helper bound to loopback.',
    ),
    LocalRuntimeProfile(
      id: LocalRuntimeId.directmlOnnx,
      displayName: 'DirectML ONNX',
      modelRuntime: ModelBundleRuntime.directmlOnnx,
      preferredExecutionProviders: <String>['DmlExecutionProvider'],
      supportsGpu: true,
      supportsCpu: false,
      requiresCuda: false,
      requiresOnnx: true,
      usesLoopbackServer: false,
      description: 'Local ONNX Runtime DirectML runtime.',
    ),
    LocalRuntimeProfile(
      id: LocalRuntimeId.cpuLightweight,
      displayName: 'CPU Lightweight',
      modelRuntime: ModelBundleRuntime.cpuLightweight,
      preferredExecutionProviders: <String>['CPUExecutionProvider'],
      supportsGpu: false,
      supportsCpu: true,
      requiresCuda: false,
      requiresOnnx: false,
      usesLoopbackServer: false,
      description: 'Local CPU-only runtime for lightweight profiles.',
    ),
  ];

  static LocalRuntimeProfile byId(LocalRuntimeId id) =>
      profiles.firstWhere((profile) => profile.id == id);

  static LocalRuntimeProfile? byModelRuntime(ModelBundleRuntime runtime) {
    for (final profile in profiles) {
      if (profile.modelRuntime == runtime) {
        return profile;
      }
    }
    return null;
  }
}

class LocalRuntimeGpuDevice {
  const LocalRuntimeGpuDevice({
    required this.index,
    required this.name,
    required this.vramMb,
    required this.provider,
    this.computeCapability,
  });

  final int index;
  final String name;
  final int vramMb;
  final String provider;
  final String? computeCapability;

  double get vramGb => vramMb / 1024.0;

  Map<String, dynamic> toJson() => {
        'index': index,
        'name': name,
        'vramMb': vramMb,
        'provider': provider,
        if (computeCapability != null) 'computeCapability': computeCapability,
      };
}

class LocalRuntimeHardware {
  const LocalRuntimeHardware({
    required this.availableExecutionProviders,
    required this.gpuDevices,
    required this.availableRuntimeIds,
  });

  final List<String> availableExecutionProviders;
  final List<LocalRuntimeGpuDevice> gpuDevices;
  final List<LocalRuntimeId> availableRuntimeIds;

  bool get hasCuda =>
      availableExecutionProviders.contains('CUDAExecutionProvider') ||
      gpuDevices.any((device) => device.provider == 'cuda');

  bool get hasDirectMl =>
      availableExecutionProviders.contains('DmlExecutionProvider') ||
      gpuDevices.any((device) => device.provider == 'directml');

  LocalRuntimeGpuDevice? get bestGpu {
    if (gpuDevices.isEmpty) {
      return null;
    }
    final sorted = [...gpuDevices]..sort((a, b) {
        final vramCompare = b.vramMb.compareTo(a.vramMb);
        if (vramCompare != 0) {
          return vramCompare;
        }
        return a.index.compareTo(b.index);
      });
    return sorted.first;
  }
}

class LocalRuntimeWorkload {
  const LocalRuntimeWorkload({
    required this.chunkSeconds,
    required this.frameCount,
    required this.frameWidth,
    required this.frameHeight,
    required this.maxOutputTokens,
    this.firstPass = true,
    this.secondPass = true,
  });

  final int chunkSeconds;
  final int frameCount;
  final int frameWidth;
  final int frameHeight;
  final int maxOutputTokens;
  final bool firstPass;
  final bool secondPass;

  Map<String, dynamic> toJson() => {
        'chunkSeconds': chunkSeconds,
        'frameCount': frameCount,
        'frameWidth': frameWidth,
        'frameHeight': frameHeight,
        'maxOutputTokens': maxOutputTokens,
        'firstPass': firstPass,
        'secondPass': secondPass,
      };
}

class LocalRuntimeVramEstimate {
  const LocalRuntimeVramEstimate({
    required this.requiredGb,
    required this.availableGb,
    required this.hasSufficientVram,
    required this.workload,
    required this.components,
  });

  final double requiredGb;
  final double availableGb;
  final bool hasSufficientVram;
  final LocalRuntimeWorkload workload;
  final Map<String, double> components;

  Map<String, dynamic> toJson() => {
        'requiredGb': requiredGb,
        'availableGb': availableGb,
        'hasSufficientVram': hasSufficientVram,
        'workload': workload.toJson(),
        'components': components,
      };
}

class Rtx5070ValidationRecord {
  const Rtx5070ValidationRecord({
    required this.targetGpuClass,
    required this.workload,
    required this.peakVramGb,
    required this.p50ChunkLatencyMs,
    required this.p95ChunkLatencyMs,
    required this.outputSchemaFailureRate,
    required this.modelRuntimeCrashRate,
    required this.requiresSustainedCpuOffload,
  });

  final String targetGpuClass;
  final LocalRuntimeWorkload workload;
  final double peakVramGb;
  final int p50ChunkLatencyMs;
  final int p95ChunkLatencyMs;
  final double outputSchemaFailureRate;
  final double modelRuntimeCrashRate;
  final bool requiresSustainedCpuOffload;

  Map<String, dynamic> toJson() => {
        'targetGpuClass': targetGpuClass,
        'workload': workload.toJson(),
        'peakVramGb': peakVramGb,
        'p50ChunkLatencyMs': p50ChunkLatencyMs,
        'p95ChunkLatencyMs': p95ChunkLatencyMs,
        'outputSchemaFailureRate': outputSchemaFailureRate,
        'modelRuntimeCrashRate': modelRuntimeCrashRate,
        'requiresSustainedCpuOffload': requiresSustainedCpuOffload,
      };
}

class Rtx5070ValidationResult {
  const Rtx5070ValidationResult({
    required this.passed,
    required this.issues,
    required this.record,
  });

  final bool passed;
  final List<String> issues;
  final Rtx5070ValidationRecord record;
}

class LocalRuntimeConfig {
  const LocalRuntimeConfig({
    this.endpointUri,
    this.modelReference,
    this.installedRuntimeIds = const <LocalRuntimeId>[],
  });

  final String? endpointUri;
  final String? modelReference;
  final List<LocalRuntimeId> installedRuntimeIds;
}

class RuntimeResolutionLogEntry {
  const RuntimeResolutionLogEntry({
    required this.step,
    required this.decision,
    required this.reason,
    this.runtimeId,
    this.metadata = const <String, dynamic>{},
  });

  final String step;
  final String decision;
  final String reason;
  final LocalRuntimeId? runtimeId;
  final Map<String, dynamic> metadata;

  Map<String, dynamic> toJson() => {
        'step': step,
        'decision': decision,
        'reason': reason,
        if (runtimeId != null) 'runtimeId': runtimeId!.jsonValue,
        if (metadata.isNotEmpty) 'metadata': metadata,
      };
}

class LocalRuntimeStatus {
  const LocalRuntimeStatus({
    required this.runtimeName,
    required this.modelName,
    required this.gpuDevice,
    required this.vramEstimate,
    this.fallbackReason,
  });

  final String runtimeName;
  final String modelName;
  final String gpuDevice;
  final LocalRuntimeVramEstimate vramEstimate;
  final String? fallbackReason;

  Map<String, dynamic> toJson() => {
        'runtimeName': runtimeName,
        'modelName': modelName,
        'gpuDevice': gpuDevice,
        'vramEstimate': vramEstimate.toJson(),
        if (fallbackReason != null) 'fallbackReason': fallbackReason,
      };
}

class LocalRuntimeSelectionResult {
  const LocalRuntimeSelectionResult({
    required this.status,
    required this.logs,
    required this.vramEstimate,
    this.profile,
    this.gpuDevice,
    this.fallbackReason,
    this.rejectionReasons = const <String>[],
  });

  final LocalRuntimeSelectionStatus status;
  final LocalRuntimeProfile? profile;
  final LocalRuntimeGpuDevice? gpuDevice;
  final String? fallbackReason;
  final List<String> rejectionReasons;
  final List<RuntimeResolutionLogEntry> logs;
  final LocalRuntimeVramEstimate vramEstimate;

  bool get isSelected =>
      status == LocalRuntimeSelectionStatus.selected ||
      status == LocalRuntimeSelectionStatus.fallbackSelected;

  LocalRuntimeStatus toUiStatus(ModelBundleManifest model) =>
      LocalRuntimeStatus(
        runtimeName: profile?.displayName ?? 'No local runtime selected',
        modelName: model.displayName,
        gpuDevice: gpuDevice?.name ?? 'CPU',
        vramEstimate: vramEstimate,
        fallbackReason: fallbackReason,
      );

  String logsAsJsonLines() =>
      logs.map((entry) => jsonEncode(entry.toJson())).join('\n');
}
