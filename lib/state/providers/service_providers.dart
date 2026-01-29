import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kidslens_video_editor/native/bindings/ffmpeg_bindings.dart';
import 'package:kidslens_video_editor/native/bindings/mms_bindings.dart';
import 'package:kidslens_video_editor/native/bindings/onnx_bindings.dart';
import 'package:kidslens_video_editor/native/bindings/whisper_bindings.dart';
import 'package:kidslens_video_editor/native/gpu_manager.dart';
import 'package:kidslens_video_editor/services/analysis_service.dart';
import 'package:kidslens_video_editor/services/asr_service.dart';
import 'package:kidslens_video_editor/services/beep_audio_service.dart';
import 'package:kidslens_video_editor/services/export_service.dart';
import 'package:kidslens_video_editor/services/frame_sampling_service.dart';
import 'package:kidslens_video_editor/services/media_service.dart';
import 'package:kidslens_video_editor/services/model_manager_service.dart';
import 'package:kidslens_video_editor/services/performance_monitor.dart';
import 'package:kidslens_video_editor/services/profanity_service.dart';
import 'package:kidslens_video_editor/services/project_service.dart';
import 'package:kidslens_video_editor/services/sample_analysis_service.dart';
import 'package:kidslens_video_editor/services/temporal_aggregator.dart';
import 'package:kidslens_video_editor/services/thumbnail_service.dart';
import 'package:kidslens_video_editor/services/visual_analysis_service.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'service_providers.g.dart';

// Native bindings (singletons)
@Riverpod(keepAlive: true)
FFmpegBindings ffmpegBindings(Ref ref) => FFmpegBindings();

@Riverpod(keepAlive: true)
WhisperBindings whisperBindings(Ref ref) => WhisperBindings();

@Riverpod(keepAlive: true)
MMSBindings mmsBindings(Ref ref) => MMSBindings();

@Riverpod(keepAlive: true)
ONNXBindings onnxBindings(Ref ref) => ONNXBindings();

// GPU Manager
@Riverpod(keepAlive: true)
GPUAccelerationManager gpuAccelerationManager(Ref ref) =>
    GPUAccelerationManager();

// Services
@Riverpod(keepAlive: true)
ProjectService projectService(Ref ref) => ProjectService();

@Riverpod(keepAlive: true)
MediaService mediaService(Ref ref) =>
    MediaService(ref.watch(ffmpegBindingsProvider));

@Riverpod(keepAlive: true)
ModelManagerService modelManagerService(Ref ref) => ModelManagerService();

@Riverpod(keepAlive: true)
ProfanityService profanityService(Ref ref) => ProfanityService();

@Riverpod(keepAlive: true)
AnalysisService analysisService(Ref ref) => AnalysisService(
      ffmpeg: ref.watch(ffmpegBindingsProvider),
      whisper: ref.watch(whisperBindingsProvider),
      mms: ref.watch(mmsBindingsProvider),
      onnx: ref.watch(onnxBindingsProvider),
      modelManager: ref.watch(modelManagerServiceProvider),
      profanity: ref.watch(profanityServiceProvider),
    );

@Riverpod(keepAlive: true)
SampleAnalysisService sampleAnalysisService(Ref ref) => SampleAnalysisService(
      analysisService: ref.watch(analysisServiceProvider),
      mediaService: ref.watch(mediaServiceProvider),
    );

@Riverpod(keepAlive: true)
ExportService exportService(Ref ref) => ExportService(
      ffmpeg: ref.watch(ffmpegBindingsProvider),
      mediaService: ref.watch(mediaServiceProvider),
    );

@Riverpod(keepAlive: true)
ThumbnailService thumbnailService(Ref ref) =>
    ThumbnailService(ref.watch(ffmpegBindingsProvider));

@Riverpod(keepAlive: true)
BeepAudioService beepAudioService(Ref ref) => BeepAudioService();

@Riverpod(keepAlive: true)
AsrService asrService(Ref ref) => AsrService(
      whisper: ref.watch(whisperBindingsProvider),
      modelManager: ref.watch(modelManagerServiceProvider),
    );

@Riverpod(keepAlive: true)
VisualAnalysisService visualAnalysisService(Ref ref) => VisualAnalysisService(
      onnx: ref.watch(onnxBindingsProvider),
      modelManager: ref.watch(modelManagerServiceProvider),
    );

@Riverpod(keepAlive: true)
TemporalAggregatorService temporalAggregatorService(Ref ref) =>
    TemporalAggregatorService();

@Riverpod(keepAlive: true)
FrameSamplingService frameSamplingService(Ref ref) => FrameSamplingService(
      ffmpeg: ref.watch(ffmpegBindingsProvider),
    );

@Riverpod(keepAlive: true)
PerformanceMonitor performanceMonitor(Ref ref) => PerformanceMonitor.instance();
