import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../data/models/models.dart';
import '../services/analysis_service.dart';
import 'job_system.dart';

/// Analysis job with checkpoint/resume support
class AnalysisJob extends Job<AnalysisResult> {
  final MediaFile media;
  final AnalysisSettings settings;
  final AnalysisService analysisService;

  AnalysisCheckpoint? _checkpoint;
  String? _checkpointPath;
  DateTime? _startTime;

  AnalysisJob({
    required super.id,
    required this.media,
    required this.settings,
    required this.analysisService,
    super.cancellationToken,
  });

  @override
  Future<AnalysisResult> execute() async {
    _startTime = DateTime.now();

    // Load checkpoint if exists
    _checkpoint = await _loadCheckpoint();

    final detections = <Detection>[];
    final profanityMatches = <ProfanityMatch>[];
    final frameResults = <FrameAnalysisResult>[];
    AnalysisProgress? lastProgress;

    // Run analysis with progress reporting
    await for (final progress in analysisService.analyze(
      media.path,
      settings,
      checkpoint: _checkpoint,
    )) {
      // Check for cancellation/pause
      await cancellationToken.checkState();

      lastProgress = progress;
      reportProgress(progress.overallProgress, progress.stepName);

      // Save checkpoint periodically
      if (progress.overallProgress > 0 &&
          (progress.overallProgress * 100).toInt() % 10 == 0) {
        await _saveCheckpoint(AnalysisCheckpoint(
          lastAnalyzedFrame: progress.itemsProcessed ?? 0,
          timestamp: DateTime.now(),
        ));
      }
    }

    final endTime = DateTime.now();
    final processingTime = endTime.difference(_startTime!);

    // Build timeline from detections
    final timeline = UnifiedTimeline.fromDetections(
      mediaDuration: media.duration,
      detections: detections,
    );

    // Build final result
    return AnalysisResult(
      id: id,
      status: AnalysisStatus.completed,
      mediaFileId: media.id,
      timeline: timeline,
      profanityMatches: profanityMatches,
      frameResults: frameResults,
      processingTime: processingTime,
      startedAt: _startTime,
      completedAt: endTime,
      progress: lastProgress,
      settings: settings.toJson(),
    );
  }

  Future<void> _saveCheckpoint(AnalysisCheckpoint checkpoint) async {
    _checkpoint = checkpoint;
    _checkpointPath ??= await _getCheckpointPath();

    final json = checkpoint.toJson();
    final file = File(_checkpointPath!);
    await file.writeAsString(jsonEncode(json));
  }

  Future<AnalysisCheckpoint?> _loadCheckpoint() async {
    _checkpointPath ??= await _getCheckpointPath();

    final file = File(_checkpointPath!);
    if (!await file.exists()) return null;

    try {
      final content = await file.readAsString();
      final json = jsonDecode(content) as Map<String, dynamic>;
      return AnalysisCheckpoint.fromJson(json);
    } catch (_) {
      return null;
    }
  }

  Future<String> _getCheckpointPath() async {
    final cacheDir = await getTemporaryDirectory();
    return p.join(cacheDir.path, 'kidslens', '${id}_checkpoint.json');
  }

  /// Delete checkpoint after successful completion
  Future<void> clearCheckpoint() async {
    if (_checkpointPath != null) {
      final file = File(_checkpointPath!);
      if (await file.exists()) {
        await file.delete();
      }
    }
  }
}
