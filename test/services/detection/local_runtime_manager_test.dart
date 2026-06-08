import 'package:flutter_test/flutter_test.dart';
import 'package:kidslens_video_editor/data/models/models.dart';
import 'package:kidslens_video_editor/native/gpu_manager.dart';
import 'package:kidslens_video_editor/services/detection/local_runtime_manager.dart';

void main() {
  group('LocalRuntimeEndpointPolicy', () {
    test('accepts loopback runtime endpoints', () {
      final issues = const LocalRuntimeEndpointPolicy().validate(
        const LocalRuntimeConfig(
          endpointUri: 'http://127.0.0.1:8000/v1',
          modelReference: 'kidslens-model://local/model',
        ),
      );

      expect(issues, isEmpty);
    });

    test('rejects non-loopback and hosted endpoints', () {
      final issues = const LocalRuntimeEndpointPolicy().validate(
        const LocalRuntimeConfig(
          endpointUri: 'https://api-inference.huggingface.co/models/foo',
          modelReference: 'https://api.openai.com/v1/models/gpt',
        ),
      );

      expect(
        issues,
        contains('runtime endpoint must be localhost, 127.0.0.1, or ::1'),
      );
      expect(issues, contains('hosted inference endpoints are not allowed'));
      expect(
        issues,
        contains('runtime model reference cannot be an http(s) URL'),
      );
      expect(
        issues,
        contains('hosted model names or inference endpoints are not allowed'),
      );
    });
  });

  group('LocalRuntimeManager', () {
    test('discovers runtime ids from existing GPU manager providers', () async {
      final manager = LocalRuntimeManager(
        gpuManager: _FakeGpuManager(
          providers: const [
            'CPUExecutionProvider',
            'CUDAExecutionProvider',
            'DmlExecutionProvider',
          ],
          cudaDevices: const [
            CudaGpuDevice(
              index: 0,
              name: 'NVIDIA RTX',
              memoryTotalMB: 12288,
              computeCapability: '12.0',
            ),
          ],
          directMlDevices: const [
            DirectMLDevice(
              deviceId: 1,
              name: 'NVIDIA RTX DirectML',
              adapterRAM: 12 * 1024 * 1024 * 1024,
            ),
          ],
        ),
      );

      final hardware = await manager.discoverHardware(
        config: const LocalRuntimeConfig(
          installedRuntimeIds: [LocalRuntimeId.cudaTensorRt],
        ),
      );

      expect(hardware.hasCuda, isTrue);
      expect(hardware.hasDirectMl, isTrue);
      expect(
        hardware.availableRuntimeIds,
        contains(LocalRuntimeId.cudaTensorRt),
      );
      expect(
        hardware.availableRuntimeIds,
        containsAll([
          LocalRuntimeId.cudaVllm,
          LocalRuntimeId.cudaTransformersHelper,
          LocalRuntimeId.directmlOnnx,
          LocalRuntimeId.cpuLightweight,
        ]),
      );
      expect(hardware.bestGpu?.vramMb, 12288);
    });

    test('selects the manifest runtime when CUDA and VRAM are available', () {
      final result = LocalRuntimeManager().selectRuntime(
        model: _manifest(),
        hardware: _hardware(
          cudaVramMb: 12288,
        ),
        workload: _workload(),
      );

      expect(result.status, LocalRuntimeSelectionStatus.selected);
      expect(result.profile?.id, LocalRuntimeId.cudaTransformersHelper);
      expect(result.gpuDevice?.provider, 'cuda');
      expect(
        result.toUiStatus(_manifest()).runtimeName,
        'CUDA Transformers Helper',
      );
      expect(result.logs, isNotEmpty);
    });

    test(
        'falls back from CUDA TensorRT to CUDA vLLM when TensorRT is unavailable',
        () {
      final result = LocalRuntimeManager().selectRuntime(
        model: _manifest(runtime: ModelBundleRuntime.cudaTensorRt),
        hardware: _hardware(
          runtimeIds: const [LocalRuntimeId.cudaVllm],
          cudaVramMb: 12288,
        ),
        workload: _workload(),
      );

      expect(result.status, LocalRuntimeSelectionStatus.fallbackSelected);
      expect(result.profile?.id, LocalRuntimeId.cudaVllm);
      expect(
        result.fallbackReason,
        contains('preferred runtime cuda_tensorrt'),
      );
    });

    test('falls back to DirectML ONNX for compatible artifacts', () {
      final result = LocalRuntimeManager().selectRuntime(
        model: _manifest(
          artifactType: ModelBundleArtifactType.officialOnnx,
          quantization: ModelBundleQuantization.onnxFp16,
        ),
        hardware: _hardware(
          providers: const ['CPUExecutionProvider', 'DmlExecutionProvider'],
          runtimeIds: const [LocalRuntimeId.directmlOnnx],
          directMlVramMb: 12288,
        ),
        workload: _workload(),
      );

      expect(result.status, LocalRuntimeSelectionStatus.fallbackSelected);
      expect(result.profile?.id, LocalRuntimeId.directmlOnnx);
      expect(result.gpuDevice?.provider, 'directml');
    });

    test('rejects CPU fallback for non-lightweight models', () {
      final result = LocalRuntimeManager().selectRuntime(
        model: _manifest(runtime: ModelBundleRuntime.cudaVllm),
        hardware: _hardware(
          providers: const ['CPUExecutionProvider'],
          runtimeIds: const [LocalRuntimeId.cpuLightweight],
        ),
        workload: _workload(),
      );

      expect(result.status, LocalRuntimeSelectionStatus.rejected);
      expect(
        result.rejectionReasons,
        contains('CPU fallback is only allowed for lightweight profiles'),
      );
    });

    test('selects CPU only for lightweight profiles', () {
      final result = LocalRuntimeManager().selectRuntime(
        model: _manifest(
          runtime: ModelBundleRuntime.cpuLightweight,
          minVramGb: 0,
          recommendedVramGb: 0,
        ),
        hardware: _hardware(
          providers: const ['CPUExecutionProvider'],
          runtimeIds: const [LocalRuntimeId.cpuLightweight],
        ),
        workload: _workload(),
      );

      expect(result.status, LocalRuntimeSelectionStatus.selected);
      expect(result.profile?.id, LocalRuntimeId.cpuLightweight);
      expect(result.toUiStatus(_manifest()).gpuDevice, 'CPU');
    });

    test('rejects runtimes when VRAM estimate exceeds the available GPU', () {
      final result = LocalRuntimeManager().selectRuntime(
        model: _manifest(
          minVramGb: 10,
          recommendedVramGb: 12,
        ),
        hardware: _hardware(
          cudaVramMb: 6144,
        ),
        workload: _workload(frameCount: 16, maxOutputTokens: 32768),
      );

      expect(result.status, LocalRuntimeSelectionStatus.rejected);
      expect(result.rejectionReasons.join('\n'), contains('needs'));
      expect(result.logsAsJsonLines(), contains('"step":"vram_estimate"'));
    });

    test('validates RTX 5070 fit records and rejects CPU offload', () {
      final result = LocalRuntimeManager().validateRtx5070Fit(
        model: _manifest(),
        record: Rtx5070ValidationRecord(
          targetGpuClass: ModelBundleCatalog.targetGpuClass,
          workload: _workload(secondPass: false),
          peakVramGb: 13,
          p50ChunkLatencyMs: 1000,
          p95ChunkLatencyMs: 900,
          outputSchemaFailureRate: 0.01,
          modelRuntimeCrashRate: 0,
          requiresSustainedCpuOffload: true,
        ),
      );

      expect(result.passed, isFalse);
      expect(
        result.issues,
        contains('validation must include first pass and second pass'),
      );
      expect(
        result.issues,
        contains('peak VRAM exceeds RTX 5070 12 GB target'),
      );
      expect(
        result.issues,
        contains('p95 chunk latency cannot be lower than p50 latency'),
      );
      expect(
        result.issues,
        contains('profiles requiring sustained CPU offload are rejected'),
      );
    });
  });
}

class _FakeGpuManager extends GPUAccelerationManager {
  _FakeGpuManager({
    required this.providers,
    required this.cudaDevices,
    required this.directMlDevices,
  });

  final List<String> providers;
  final List<CudaGpuDevice> cudaDevices;
  final List<DirectMLDevice> directMlDevices;

  @override
  Future<List<String>> queryAvailableProviders() async => providers;

  @override
  Future<List<CudaGpuDevice>> getCudaDevices() async => cudaDevices;

  @override
  Future<List<DirectMLDevice>> getDirectMLDevices() async => directMlDevices;
}

LocalRuntimeHardware _hardware({
  List<String> providers = const [
    'CPUExecutionProvider',
    'CUDAExecutionProvider',
  ],
  List<LocalRuntimeId> runtimeIds = const [
    LocalRuntimeId.cudaTransformersHelper,
  ],
  int cudaVramMb = 0,
  int directMlVramMb = 0,
}) =>
    LocalRuntimeHardware(
      availableExecutionProviders: providers,
      availableRuntimeIds: runtimeIds,
      gpuDevices: [
        if (cudaVramMb > 0)
          LocalRuntimeGpuDevice(
            index: 0,
            name: 'NVIDIA RTX',
            vramMb: cudaVramMb,
            provider: 'cuda',
          ),
        if (directMlVramMb > 0)
          LocalRuntimeGpuDevice(
            index: 1,
            name: 'NVIDIA RTX DirectML',
            vramMb: directMlVramMb,
            provider: 'directml',
          ),
      ],
    );

LocalRuntimeWorkload _workload({
  int frameCount = 8,
  int maxOutputTokens = 4096,
  bool secondPass = true,
}) =>
    LocalRuntimeWorkload(
      chunkSeconds: 8,
      frameCount: frameCount,
      frameWidth: 768,
      frameHeight: 432,
      maxOutputTokens: maxOutputTokens,
      secondPass: secondPass,
    );

ModelBundleManifest _manifest({
  ModelBundleRuntime runtime = ModelBundleRuntime.cudaTransformersHelper,
  ModelBundleArtifactType artifactType =
      ModelBundleArtifactType.officialWeights,
  ModelBundleQuantization quantization = ModelBundleQuantization.bf16,
  double minVramGb = 6,
  double recommendedVramGb = 8,
}) =>
    ModelBundleManifest(
      modelId: 'test_model',
      displayName: 'Test Model',
      vendor: 'NVIDIA',
      officialSourceRepo: 'nvidia/test-model',
      officialRevision: 'main',
      license: ModelBundleLicense.nvidiaOpenModelLicense,
      commercialUse: CommercialUseStatus.allowed,
      acceptedTermsRequired: false,
      artifactType: artifactType,
      artifactUri: 'hf://nvidia/test-model',
      sha256: null,
      conversionRecipeId: null,
      runtime: runtime,
      minVramGb: minVramGb,
      recommendedVramGb: recommendedVramGb,
      targetGpuClass: ModelBundleCatalog.targetGpuClass,
      maxValidatedVramGb: ModelBundleCatalog.targetGpuVramGb,
      quantization: quantization,
      fitsRtx5070Validated: false,
      supportsVideoInput: true,
      supportsImageInput: true,
      supportsBoundingBoxes: false,
      supportsMasks: false,
      supportsPointLocalization: false,
      maxFramesPerChunk: 8,
      maxContextTokens: 32768,
      recommendedChunkSeconds: 8,
      knownFailureModes: const ['test fixture'],
      roles: const [ModelBundleRole.vlm],
      approvalStatus: ModelBundleApprovalStatus.evaluationOnly,
      reviewNotes: 'test fixture',
    );
