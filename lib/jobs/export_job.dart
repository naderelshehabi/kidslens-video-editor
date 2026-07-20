import 'dart:async';

import 'package:kidslens_video_editor/data/models/media_file.dart';
import 'package:kidslens_video_editor/data/models/timeline.dart';
import 'package:kidslens_video_editor/jobs/job_system.dart';
import 'package:kidslens_video_editor/services/export_service.dart';

/// Export job for applying modifications and saving output
class ExportJob extends Job<String> {
  ExportJob({
    required super.id,
    required this.media,
    required this.timeline,
    required this.outputPath,
    required this.exportService,
    this.exportSettings = const ExportSettings(),
    super.cancellationToken,
  });

  final MediaFile media;
  final UnifiedTimeline timeline;
  final String outputPath;
  final ExportSettings exportSettings;
  final ExportService exportService;

  @override
  Future<String> execute() async {
    await for (final progress in exportService.export(
      inputPath: media.path,
      outputPath: outputPath,
      timeline: timeline,
      settings: exportSettings,
    )) {
      // Check for cancellation
      await cancellationToken.checkState();

      reportProgress(progress.progress, progress.phase);
    }

    return outputPath;
  }
}
