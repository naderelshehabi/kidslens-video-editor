import 'package:flutter_test/flutter_test.dart';
import 'package:kidslens_video_editor/data/models/models.dart';
import 'package:kidslens_video_editor/native/bindings/ffmpeg_bindings.dart';
import 'package:kidslens_video_editor/native/bindings/mms_bindings.dart';
import 'package:kidslens_video_editor/native/bindings/onnx_bindings.dart';
import 'package:kidslens_video_editor/native/bindings/whisper_bindings.dart';
import 'package:kidslens_video_editor/native/gpu_manager.dart';
import 'package:kidslens_video_editor/services/analysis_service.dart';
import 'package:kidslens_video_editor/services/detection/detection_pipeline.dart';
import 'package:kidslens_video_editor/services/detection/detection_pipeline_profile.dart';
import 'package:kidslens_video_editor/services/detection/detection_pipeline_registry.dart';
import 'package:kidslens_video_editor/services/detection/detection_pipeline_rollout.dart';
import 'package:kidslens_video_editor/services/model_manager_service.dart';
import 'package:kidslens_video_editor/services/nsfw_onnx_service.dart';
import 'package:kidslens_video_editor/services/profanity_service.dart';

void main() {
  group('AnalysisService pipeline routing', () {
    test('dispatches analyze requests through the configured registry',
        () async {
      final stubPipeline = _RecordingPipeline();
      final registry = DetectionPipelineRegistry(
        pipelines: [stubPipeline],
        defaultPipelineId: DetectionPipelineIds.legacyNsfwRegionV8,
      );
      final service = AnalysisService(
        ffmpeg: FFmpegBindings(),
        whisper: WhisperBindings(),
        mms: MMSBindings(),
        nsfwOnnx: NsfwOnnxService(
          onnx: ONNXBindings(),
          gpuConfig: const GpuConfig(),
          gpuManager: GPUAccelerationManager(),
        ),
        modelManager: ModelManagerService(),
        profanity: ProfanityService(),
        detectionPipelineRegistry: registry,
      );
      final settings = AnalysisSettings.defaults().copyWith(
        analysisPipelineId: DetectionPipelineIds.legacyNsfwRegionV8,
      );

      final progress = await service.analyze('fixture.mp4', settings).toList();

      expect(progress, hasLength(1));
      expect(stubPipeline.requestedMediaPath, 'fixture.mp4');
      expect(stubPipeline.requestedPipelineId, settings.analysisPipelineId);
    });

    test('routes the VSS family-safety pipeline by default', () async {
      final legacyPipeline = _RecordingPipeline(
        DetectionPipelineProfile.legacyNsfwRegionV8,
      );
      final vssPipeline = _RecordingPipeline(
        DetectionPipelineProfile.vssFamilySafetyV1,
      );
      final registry = DetectionPipelineRegistry(
        pipelines: [legacyPipeline, vssPipeline],
      );
      final service = _service(
        registry,
        rolloutConfig: const DetectionPipelineRolloutConfig(
          state: DetectionPipelineRolloutState.defaultProfile,
        ),
      );

      await service
          .analyze('fixture.mp4', AnalysisSettings.defaults())
          .toList();

      expect(
        vssPipeline.requestedPipelineId,
        DetectionPipelineIds.vssFamilySafetyV1,
      );
      expect(legacyPipeline.requestedPipelineId, isNull);
    });

    test('records local telemetry when a pipeline throws', () async {
      final telemetryStore = InMemoryDetectionPipelineTelemetryStore();
      final registry = DetectionPipelineRegistry(
        pipelines: const [_ThrowingPipeline()],
        defaultPipelineId: DetectionPipelineIds.legacyNsfwRegionV8,
      );
      final service = _service(
        registry,
        detectionTelemetryStore: telemetryStore,
      );

      await expectLater(
        service.analyze('fixture.mp4', AnalysisSettings.defaults()).toList(),
        throwsA(isA<FormatException>()),
      );
      await Future<void>.delayed(Duration.zero);

      expect(telemetryStore.events, hasLength(1));
      expect(
        telemetryStore.events.single.kind,
        DetectionPipelineFailureKind.schema,
      );
      expect(
        telemetryStore.events.single.activePipelineId,
        DetectionPipelineIds.legacyNsfwRegionV8,
      );
    });
  });
}

AnalysisService _service(
  DetectionPipelineRegistry registry, {
  DetectionPipelineRolloutConfig rolloutConfig =
      const DetectionPipelineRolloutConfig(),
  DetectionPipelineTelemetryStore? detectionTelemetryStore,
}) =>
    AnalysisService(
      ffmpeg: FFmpegBindings(),
      whisper: WhisperBindings(),
      mms: MMSBindings(),
      nsfwOnnx: NsfwOnnxService(
        onnx: ONNXBindings(),
        gpuConfig: const GpuConfig(),
        gpuManager: GPUAccelerationManager(),
      ),
      modelManager: ModelManagerService(),
      profanity: ProfanityService(),
      detectionPipelineRegistry: registry,
      rolloutConfig: rolloutConfig,
      detectionTelemetryStore: detectionTelemetryStore,
    );

class _RecordingPipeline implements DetectionPipeline {
  _RecordingPipeline([
    this.profile = DetectionPipelineProfile.legacyNsfwRegionV8,
  ]);

  String? requestedMediaPath;
  String? requestedPipelineId;

  @override
  final DetectionPipelineProfile profile;

  @override
  Stream<AnalysisProgress> analyze(DetectionPipelineRequest request) {
    requestedMediaPath = request.mediaPath;
    requestedPipelineId = request.settings.analysisPipelineId;
    return Stream.value(
      const AnalysisProgress(
        stepName: 'stub complete',
        currentStep: 1,
        totalSteps: 1,
        stepProgress: 1,
      ),
    );
  }
}

class _ThrowingPipeline implements DetectionPipeline {
  const _ThrowingPipeline();

  @override
  DetectionPipelineProfile get profile =>
      DetectionPipelineProfile.legacyNsfwRegionV8;

  @override
  Stream<AnalysisProgress> analyze(DetectionPipelineRequest request) =>
      Stream.error(const FormatException('schema parse failed'));
}
