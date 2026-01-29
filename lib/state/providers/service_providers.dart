import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kidslens_video_editor/native/bindings/ffmpeg_bindings.dart';
import 'package:kidslens_video_editor/native/bindings/mms_bindings.dart';
import 'package:kidslens_video_editor/native/bindings/onnx_bindings.dart';
import 'package:kidslens_video_editor/native/bindings/whisper_bindings.dart';
import 'package:kidslens_video_editor/services/analysis_service.dart';
import 'package:kidslens_video_editor/services/beep_audio_service.dart';
import 'package:kidslens_video_editor/services/export_service.dart';
import 'package:kidslens_video_editor/services/media_service.dart';
import 'package:kidslens_video_editor/services/model_manager_service.dart';
import 'package:kidslens_video_editor/services/profanity_service.dart';
import 'package:kidslens_video_editor/services/project_service.dart';
import 'package:kidslens_video_editor/services/sample_analysis_service.dart';
import 'package:kidslens_video_editor/services/thumbnail_service.dart';
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

// Services
@Riverpod(keepAlive: true)
ProjectService projectService(Ref ref) => ProjectService();

@Riverpod(keepAlive: true)
MediaService mediaService(Ref ref) =>
    MediaService(ref.watch(ffmpegBindingsProvider));

@Riverpod(keepAlive: true)
ModelManagerService modelManagerService(Ref ref) =>
    ModelManagerService();

@Riverpod(keepAlive: true)
ProfanityService profanityService(Ref ref) =>
    ProfanityService();

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
SampleAnalysisService sampleAnalysisService(Ref ref) =>
    SampleAnalysisService(
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
    ThumbnailService();

@Riverpod(keepAlive: true)
BeepAudioService beepAudioService(Ref ref) =>
    BeepAudioService();
