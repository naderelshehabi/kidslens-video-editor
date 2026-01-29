import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:kidslens_video_editor/native/bindings/ffmpeg_bindings.dart';
import 'package:kidslens_video_editor/native/bindings/mms_bindings.dart';
import 'package:kidslens_video_editor/native/bindings/onnx_bindings.dart';
import 'package:kidslens_video_editor/native/bindings/whisper_bindings.dart';
import 'package:kidslens_video_editor/services/analysis_service.dart';
import 'package:kidslens_video_editor/services/export_service.dart';
import 'package:kidslens_video_editor/services/media_service.dart';
import 'package:kidslens_video_editor/services/model_manager_service.dart';
import 'package:kidslens_video_editor/services/profanity_service.dart';
import 'package:kidslens_video_editor/services/project_service.dart';
import 'package:kidslens_video_editor/services/sample_analysis_service.dart';
import 'package:kidslens_video_editor/services/thumbnail_service.dart';
import 'package:kidslens_video_editor/services/beep_audio_service.dart';

part 'service_providers.g.dart';

// Native bindings (singletons)
@Riverpod(keepAlive: true)
FFmpegBindings ffmpegBindings(FfmpegBindingsRef ref) => FFmpegBindings();

@Riverpod(keepAlive: true)
WhisperBindings whisperBindings(WhisperBindingsRef ref) => WhisperBindings();

@Riverpod(keepAlive: true)
MMSBindings mmsBindings(MmsBindingsRef ref) => MMSBindings();

@Riverpod(keepAlive: true)
ONNXBindings onnxBindings(OnnxBindingsRef ref) => ONNXBindings();

// Services
@Riverpod(keepAlive: true)
ProjectService projectService(ProjectServiceRef ref) {
  return ProjectService();
}

@Riverpod(keepAlive: true)
MediaService mediaService(MediaServiceRef ref) {
  return MediaService(ref.watch(ffmpegBindingsProvider));
}

@Riverpod(keepAlive: true)
ModelManagerService modelManagerService(ModelManagerServiceRef ref) {
  return ModelManagerService();
}

@Riverpod(keepAlive: true)
ProfanityService profanityService(ProfanityServiceRef ref) {
  return ProfanityService();
}

@Riverpod(keepAlive: true)
AnalysisService analysisService(AnalysisServiceRef ref) {
  return AnalysisService(
    ffmpeg: ref.watch(ffmpegBindingsProvider),
    whisper: ref.watch(whisperBindingsProvider),
    mms: ref.watch(mmsBindingsProvider),
    onnx: ref.watch(onnxBindingsProvider),
    modelManager: ref.watch(modelManagerServiceProvider),
    profanity: ref.watch(profanityServiceProvider),
  );
}

@Riverpod(keepAlive: true)
SampleAnalysisService sampleAnalysisService(SampleAnalysisServiceRef ref) {
  return SampleAnalysisService(
    analysisService: ref.watch(analysisServiceProvider),
    mediaService: ref.watch(mediaServiceProvider),
  );
}

@Riverpod(keepAlive: true)
ExportService exportService(ExportServiceRef ref) {
  return ExportService(
    ffmpeg: ref.watch(ffmpegBindingsProvider),
    mediaService: ref.watch(mediaServiceProvider),
  );
}

@Riverpod(keepAlive: true)
ThumbnailService thumbnailService(ThumbnailServiceRef ref) {
  return ThumbnailService();
}

@Riverpod(keepAlive: true)
BeepAudioService beepAudioService(BeepAudioServiceRef ref) {
  return BeepAudioService();
}
