import 'dart:io';
import 'dart:math';

import 'package:kidslens_video_editor/data/models/models.dart';
import 'package:kidslens_video_editor/native/gpu_manager.dart';

class LocalRuntimeEndpointPolicy {
  const LocalRuntimeEndpointPolicy();

  static const _hostedEndpointFragments = <String>[
    'api-inference.huggingface.co',
    'huggingface.co/inference',
    'openai.com',
    'api.openai.com',
    'replicate.com',
    'modal.run',
    'together.ai',
    'fireworks.ai',
    'anthropic.com',
    'googleapis.com',
    'azure.com',
  ];

  List<String> validate(LocalRuntimeConfig config) {
    final issues = <String>[];
    final endpoint = config.endpointUri?.trim();
    if (endpoint != null && endpoint.isNotEmpty) {
      final uri = Uri.tryParse(endpoint);
      if (uri == null || !uri.hasScheme) {
        issues.add('runtime endpoint must be an absolute loopback URL');
      } else if (uri.scheme != 'http' && uri.scheme != 'https') {
        issues.add('runtime endpoint must use http or https on loopback');
      } else if (!_isLoopbackHost(uri.host)) {
        issues.add('runtime endpoint must be localhost, 127.0.0.1, or ::1');
      }
      if (_looksHosted(endpoint)) {
        issues.add('hosted inference endpoints are not allowed');
      }
    }

    final modelReference = config.modelReference?.trim();
    if (modelReference != null && modelReference.isNotEmpty) {
      final uri = Uri.tryParse(modelReference);
      if (uri != null && (uri.scheme == 'http' || uri.scheme == 'https')) {
        issues.add('runtime model reference cannot be an http(s) URL');
      }
      if (_looksHosted(modelReference)) {
        issues.add('hosted model names or inference endpoints are not allowed');
      }
    }

    return issues.toSet().toList(growable: false);
  }

  bool _isLoopbackHost(String host) {
    final normalized = host.toLowerCase();
    return normalized == 'localhost' ||
        normalized == '127.0.0.1' ||
        normalized == '::1' ||
        normalized == '[::1]';
  }

  bool _looksHosted(String value) {
    final normalized = value.toLowerCase();
    return _hostedEndpointFragments.any(normalized.contains);
  }
}

class LocalRuntimeManager {
  LocalRuntimeManager({
    GPUAccelerationManager? gpuManager,
    LocalRuntimeEndpointPolicy endpointPolicy =
        const LocalRuntimeEndpointPolicy(),
  })  : _gpuManager = gpuManager ?? GPUAccelerationManager(),
        _endpointPolicy = endpointPolicy;

  final GPUAccelerationManager _gpuManager;
  final LocalRuntimeEndpointPolicy _endpointPolicy;

  Future<LocalRuntimeHardware> discoverHardware({
    LocalRuntimeConfig config = const LocalRuntimeConfig(),
  }) async {
    final providers = await _gpuManager.queryAvailableProviders();
    final cudaDevices = await _gpuManager.getCudaDevices();
    final directMlDevices = await _gpuManager.getDirectMLDevices();
    final runtimeIds = <LocalRuntimeId>{
      ...config.installedRuntimeIds,
      if (providers.contains('CUDAExecutionProvider')) ...{
        LocalRuntimeId.cudaLlamaCpp,
        LocalRuntimeId.cudaVllm,
        LocalRuntimeId.cudaTransformersHelper,
      },
      if (cudaDevices.isNotEmpty || directMlDevices.isNotEmpty)
        LocalRuntimeId.vulkanLlamaCpp,
      if (providers.contains('DmlExecutionProvider'))
        LocalRuntimeId.directmlOnnx,
      if (providers.contains('CPUExecutionProvider'))
        LocalRuntimeId.cpuLightweight,
    };

    final gpuDevices = <LocalRuntimeGpuDevice>[
      for (final device in cudaDevices)
        LocalRuntimeGpuDevice(
          index: device.index,
          name: device.name,
          vramMb: device.memoryTotalMB ?? 0,
          provider: 'cuda',
          computeCapability: device.computeCapability,
        ),
      for (final device in directMlDevices)
        LocalRuntimeGpuDevice(
          index: device.deviceId,
          name: device.name,
          vramMb: device.vramMB,
          provider: 'directml',
        ),
    ];

    return LocalRuntimeHardware(
      availableExecutionProviders: providers,
      gpuDevices: gpuDevices,
      availableRuntimeIds: runtimeIds.toList(growable: false),
    );
  }

  LocalRuntimeSelectionResult selectRuntime({
    required ModelBundleManifest model,
    required LocalRuntimeHardware hardware,
    required LocalRuntimeWorkload workload,
    LocalRuntimeConfig config = const LocalRuntimeConfig(),
    Rtx5070ValidationRecord? validationRecord,
  }) {
    final logs = <RuntimeResolutionLogEntry>[];
    final endpointIssues = _endpointPolicy.validate(config);
    final candidateGpu = _selectGpuForRuntime(
      LocalRuntimeProfile.byModelRuntime(model.runtime),
      hardware,
    );
    final initialEstimate = estimateVram(
      model: model,
      workload: workload,
      availableGpu: candidateGpu,
      runtimeId: LocalRuntimeProfile.byModelRuntime(model.runtime)?.id,
    );

    if (endpointIssues.isNotEmpty) {
      logs.add(
        RuntimeResolutionLogEntry(
          step: 'endpoint_policy',
          decision: 'reject',
          reason: endpointIssues.join('; '),
        ),
      );
      return LocalRuntimeSelectionResult(
        status: LocalRuntimeSelectionStatus.rejected,
        rejectionReasons: endpointIssues,
        logs: logs,
        vramEstimate: initialEstimate,
      );
    }

    if (validationRecord != null) {
      final validation = validateRtx5070Fit(
        model: model,
        record: validationRecord,
      );
      logs.add(
        RuntimeResolutionLogEntry(
          step: 'rtx_5070_validation',
          decision: validation.passed ? 'accept' : 'warn',
          reason: validation.passed
              ? 'RTX 5070 validation record passed'
              : validation.issues.join('; '),
          metadata: validation.record.toJson(),
        ),
      );
    }

    final preferredProfile = LocalRuntimeProfile.byModelRuntime(model.runtime);
    if (preferredProfile == null) {
      logs.add(
        RuntimeResolutionLogEntry(
          step: 'manifest_runtime',
          decision: 'reject',
          reason: 'model runtime is not yet validated',
          metadata: {'modelRuntime': model.runtime.name},
        ),
      );
    } else {
      logs.add(
        RuntimeResolutionLogEntry(
          step: 'manifest_runtime',
          decision: 'prefer',
          reason: 'using manifest runtime preference',
          runtimeId: preferredProfile.id,
        ),
      );
    }

    final candidates = _candidateProfiles(model);
    final unavailableReasons = <String>[];
    for (final profile in candidates) {
      final availability = _profileAvailability(
        model: model,
        profile: profile,
        hardware: hardware,
        config: config,
      );
      logs.add(
        RuntimeResolutionLogEntry(
          step: 'profile_availability',
          decision: availability.isEmpty ? 'available' : 'skip',
          reason: availability.isEmpty
              ? 'runtime profile is available'
              : availability.join('; '),
          runtimeId: profile.id,
        ),
      );
      if (availability.isNotEmpty) {
        unavailableReasons.addAll(availability);
        continue;
      }

      final gpu = _selectGpuForRuntime(profile, hardware);
      final estimate = estimateVram(
        model: model,
        workload: workload,
        availableGpu: gpu,
        runtimeId: profile.id,
      );
      logs.add(
        RuntimeResolutionLogEntry(
          step: 'vram_estimate',
          decision: estimate.hasSufficientVram || !profile.supportsGpu
              ? 'accept'
              : 'skip',
          reason: estimate.hasSufficientVram || !profile.supportsGpu
              ? 'VRAM estimate fits selected device'
              : 'estimated VRAM exceeds available device memory',
          runtimeId: profile.id,
          metadata: estimate.toJson(),
        ),
      );
      if (profile.supportsGpu && !estimate.hasSufficientVram) {
        unavailableReasons.add(
          '${profile.id.jsonValue} needs ${estimate.requiredGb.toStringAsFixed(2)} GB VRAM '
          'but only ${estimate.availableGb.toStringAsFixed(2)} GB is available',
        );
        continue;
      }

      final fallbackReason = preferredProfile == null
          ? 'manifest runtime is not yet validated'
          : profile.id == preferredProfile.id
              ? null
              : 'preferred runtime ${preferredProfile.id.jsonValue} was unavailable';

      return LocalRuntimeSelectionResult(
        status: fallbackReason == null
            ? LocalRuntimeSelectionStatus.selected
            : LocalRuntimeSelectionStatus.fallbackSelected,
        profile: profile,
        gpuDevice: gpu,
        fallbackReason: fallbackReason,
        logs: logs,
        vramEstimate: estimate,
      );
    }

    final reasons = unavailableReasons.isEmpty
        ? <String>['no local runtime profile is compatible with this model']
        : unavailableReasons.toSet().toList(growable: false);
    logs.add(
      RuntimeResolutionLogEntry(
        step: 'runtime_selection',
        decision: 'reject',
        reason: reasons.join('; '),
      ),
    );
    return LocalRuntimeSelectionResult(
      status: LocalRuntimeSelectionStatus.rejected,
      rejectionReasons: reasons,
      logs: logs,
      vramEstimate: initialEstimate,
    );
  }

  LocalRuntimeVramEstimate estimateVram({
    required ModelBundleManifest model,
    required LocalRuntimeWorkload workload,
    LocalRuntimeGpuDevice? availableGpu,
    LocalRuntimeId? runtimeId,
  }) {
    final passMultiplier =
        (workload.firstPass ? 1 : 0) + (workload.secondPass ? 1 : 0);
    final frameGb = workload.frameCount *
        workload.frameWidth *
        workload.frameHeight *
        3 /
        pow(1024, 3) *
        max(passMultiplier, 1) *
        1.5;
    final tokenGb = workload.maxOutputTokens / 16384 * 0.25;
    final chunkOverrunGb = max(
          0,
          workload.chunkSeconds - model.recommendedChunkSeconds,
        ) *
        0.1;
    final runtimeOverheadGb = switch (runtimeId) {
      LocalRuntimeId.cudaLlamaCpp => 0.75,
      LocalRuntimeId.vulkanLlamaCpp => 0.75,
      LocalRuntimeId.cudaTensorRt => 1.5,
      LocalRuntimeId.cudaVllm => 1.25,
      LocalRuntimeId.cudaTransformersHelper => 0.75,
      LocalRuntimeId.directmlOnnx => 0.5,
      LocalRuntimeId.cpuLightweight => 0.0,
      null => 0.75,
    };
    final requiredGb = _roundGb(
      model.minVramGb + frameGb + tokenGb + chunkOverrunGb + runtimeOverheadGb,
    );
    final availableGb = _roundGb(availableGpu?.vramGb ?? 0);
    return LocalRuntimeVramEstimate(
      requiredGb: requiredGb,
      availableGb: availableGb,
      hasSufficientVram: requiredGb <= availableGb ||
          runtimeId == LocalRuntimeId.cpuLightweight,
      workload: workload,
      components: {
        'modelMinGb': model.minVramGb,
        'frameBufferGb': _roundGb(frameGb),
        'outputTokenGb': _roundGb(tokenGb),
        'chunkOverrunGb': _roundGb(chunkOverrunGb),
        'runtimeOverheadGb': runtimeOverheadGb,
      },
    );
  }

  Rtx5070ValidationResult validateRtx5070Fit({
    required ModelBundleManifest model,
    required Rtx5070ValidationRecord record,
  }) {
    final issues = <String>[];
    if (record.targetGpuClass != ModelBundleCatalog.targetGpuClass) {
      issues.add(
        'target GPU profile must be ${ModelBundleCatalog.targetGpuClass}',
      );
    }
    if (model.targetGpuClass != ModelBundleCatalog.targetGpuClass) {
      issues.add(
        'model target GPU class must be ${ModelBundleCatalog.targetGpuClass}',
      );
    }
    if (record.workload.chunkSeconds < 1) {
      issues.add('validation chunk length must be configured');
    }
    if (record.workload.frameCount < 1) {
      issues.add('validation frame count must be configured');
    }
    if (record.workload.frameWidth < 1 || record.workload.frameHeight < 1) {
      issues.add('validation frame resolution must be configured');
    }
    if (record.workload.maxOutputTokens < 1 ||
        record.workload.maxOutputTokens > model.maxContextTokens) {
      issues.add(
        'validation max output tokens must be configured within model context',
      );
    }
    if (!record.workload.firstPass || !record.workload.secondPass) {
      issues.add('validation must include first pass and second pass');
    }
    if (record.peakVramGb > ModelBundleCatalog.targetGpuVramGb) {
      issues.add('peak VRAM exceeds RTX 5070 12 GB target');
    }
    if (record.p50ChunkLatencyMs < 1 || record.p95ChunkLatencyMs < 1) {
      issues.add('p50 and p95 chunk latency must be recorded');
    }
    if (record.p95ChunkLatencyMs < record.p50ChunkLatencyMs) {
      issues.add('p95 chunk latency cannot be lower than p50 latency');
    }
    if (record.outputSchemaFailureRate < 0 ||
        record.outputSchemaFailureRate > 1) {
      issues.add('output schema failure rate must be between 0 and 1');
    }
    if (record.modelRuntimeCrashRate < 0 || record.modelRuntimeCrashRate > 1) {
      issues.add('model/runtime crash rate must be between 0 and 1');
    }
    if (record.requiresSustainedCpuOffload) {
      issues.add('profiles requiring sustained CPU offload are rejected');
    }
    return Rtx5070ValidationResult(
      passed: issues.isEmpty,
      issues: issues,
      record: record,
    );
  }

  List<LocalRuntimeProfile> _candidateProfiles(ModelBundleManifest model) {
    final preferred = LocalRuntimeProfile.byModelRuntime(model.runtime);
    final candidates = <LocalRuntimeProfile>[
      if (preferred != null) preferred,
    ];

    void add(LocalRuntimeId id) {
      final profile = LocalRuntimeProfile.byId(id);
      if (!candidates.any((candidate) => candidate.id == id)) {
        candidates.add(profile);
      }
    }

    switch (model.runtime) {
      case ModelBundleRuntime.llamaCppServer:
        add(LocalRuntimeId.cudaLlamaCpp);
        add(LocalRuntimeId.vulkanLlamaCpp);
      case ModelBundleRuntime.cudaTensorRt:
        add(LocalRuntimeId.cudaVllm);
        add(LocalRuntimeId.cudaTransformersHelper);
      case ModelBundleRuntime.cudaVllm:
        add(LocalRuntimeId.cudaTransformersHelper);
      case ModelBundleRuntime.cudaTransformersHelper:
        add(LocalRuntimeId.cudaVllm);
      case ModelBundleRuntime.directmlOnnx:
        if (model.artifactType == ModelBundleArtifactType.officialOnnx ||
            model.quantization == ModelBundleQuantization.onnxFp16) {
          add(LocalRuntimeId.directmlOnnx);
        }
      case ModelBundleRuntime.cpuLightweight:
        add(LocalRuntimeId.cpuLightweight);
      case ModelBundleRuntime.notYetValidated:
        add(LocalRuntimeId.cudaLlamaCpp);
        add(LocalRuntimeId.vulkanLlamaCpp);
        add(LocalRuntimeId.cudaTensorRt);
        add(LocalRuntimeId.cudaVllm);
        add(LocalRuntimeId.cudaTransformersHelper);
    }

    if (_isDirectMlCompatible(model)) {
      add(LocalRuntimeId.directmlOnnx);
    }
    add(LocalRuntimeId.cpuLightweight);
    return candidates;
  }

  List<String> _profileAvailability({
    required ModelBundleManifest model,
    required LocalRuntimeProfile profile,
    required LocalRuntimeHardware hardware,
    required LocalRuntimeConfig config,
  }) {
    final issues = <String>[];
    final availableRuntimeIds = {
      ...hardware.availableRuntimeIds,
      ...config.installedRuntimeIds,
    };

    if (Platform.isWindows && _isUnsupportedWindowsRuntime(profile.id)) {
      issues.add('runtime not supported on Windows desktop');
    }
    if (!availableRuntimeIds.contains(profile.id)) {
      issues.add('${profile.id.jsonValue} is not installed or discoverable');
    }
    if (profile.requiresCuda && !hardware.hasCuda) {
      issues.add('CUDA GPU/provider is unavailable');
    }
    if (profile.id == LocalRuntimeId.vulkanLlamaCpp &&
        hardware.gpuDevices.isEmpty) {
      issues.add('GPU device is unavailable for Vulkan llama.cpp runtime');
    }
    if (profile.id == LocalRuntimeId.directmlOnnx) {
      if (!hardware.hasDirectMl) {
        issues.add('DirectML provider is unavailable');
      }
      if (!_isDirectMlCompatible(model)) {
        issues.add('model artifact is not DirectML/ONNX compatible');
      }
    }
    if (profile.id == LocalRuntimeId.cpuLightweight &&
        model.runtime != ModelBundleRuntime.cpuLightweight) {
      issues.add('CPU fallback is only allowed for lightweight profiles');
    }
    if (profile.usesLoopbackServer &&
        config.endpointUri != null &&
        _endpointPolicy.validate(config).isNotEmpty) {
      issues.add('loopback server configuration is invalid');
    }
    return issues.toSet().toList(growable: false);
  }

  LocalRuntimeGpuDevice? _selectGpuForRuntime(
    LocalRuntimeProfile? profile,
    LocalRuntimeHardware hardware,
  ) {
    if (profile == null || !profile.supportsGpu) {
      return null;
    }
    final provider = switch (profile.id) {
      LocalRuntimeId.cudaLlamaCpp ||
      LocalRuntimeId.cudaTensorRt ||
      LocalRuntimeId.cudaVllm ||
      LocalRuntimeId.cudaTransformersHelper =>
        'cuda',
      LocalRuntimeId.directmlOnnx => 'directml',
      LocalRuntimeId.vulkanLlamaCpp => null,
      LocalRuntimeId.cpuLightweight => null,
    };
    final candidates = hardware.gpuDevices
        .where((device) => provider == null || device.provider == provider)
        .toList(growable: false);
    if (candidates.isEmpty) {
      return hardware.bestGpu;
    }
    candidates.sort((a, b) => b.vramMb.compareTo(a.vramMb));
    return candidates.first;
  }

  bool _isDirectMlCompatible(ModelBundleManifest model) =>
      model.runtime == ModelBundleRuntime.directmlOnnx ||
      model.artifactType == ModelBundleArtifactType.officialOnnx ||
      model.quantization == ModelBundleQuantization.onnxFp16;

  bool _isUnsupportedWindowsRuntime(LocalRuntimeId runtimeId) =>
      runtimeId == LocalRuntimeId.cudaVllm ||
      runtimeId == LocalRuntimeId.cudaTensorRt ||
      runtimeId == LocalRuntimeId.cudaTransformersHelper;

  double _roundGb(num value) => (value * 100).roundToDouble() / 100;
}
