import 'dart:async';

import '../data/models/media_file.dart';
import '../data/models/timeline.dart';
import '../services/export_service.dart';
import 'job_system.dart';

/// Export job for applying modifications and saving output
class ExportJob extends Job<String> {
  final MediaFile media;
  final UnifiedTimeline timeline;
  final String outputPath;
  final ExportSettings exportSettings;
  final ExportService exportService;

  ExportJob({
    required super.id,
    required this.media,
    required this.timeline,
    required this.outputPath,
    required this.exportService,
    this.exportSettings = const ExportSettings(),
    super.cancellationToken,
  });

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
