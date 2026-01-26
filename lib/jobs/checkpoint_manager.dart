import 'dart:convert';
import 'dart:io';

import 'package:kidslens_video_editor/data/models/artifact.dart';
import 'package:kidslens_video_editor/services/analysis_service.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

/// Manages checkpoints and artifacts for resumable operations
class CheckpointManager {
  static const String _checkpointSubdir = 'kidslens_checkpoints';
  static const String _artifactSubdir = 'kidslens_artifacts';

  String? _checkpointDir;
  String? _artifactDir;

  /// Get the checkpoints directory
  Future<String> get checkpointsDirectory async {
    _checkpointDir ??= await _initDir(_checkpointSubdir);
    return _checkpointDir!;
  }

  /// Get the artifacts directory
  Future<String> get artifactsDirectory async {
    _artifactDir ??= await _initDir(_artifactSubdir);
    return _artifactDir!;
  }

  Future<String> _initDir(String subdir) async {
    final appDir = await getApplicationSupportDirectory();
    final dir = Directory(p.join(appDir.path, subdir));
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
    return dir.path;
  }

  /// Save a checkpoint for a job
  Future<void> saveCheckpoint(
    String jobId,
    AnalysisCheckpoint checkpoint,
  ) async {
    final dir = await checkpointsDirectory;
    final file = File(p.join(dir, '$jobId.json'));
    await file.writeAsString(
      const JsonEncoder.withIndent('  ').convert(checkpoint.toJson()),
    );
  }

  /// Load a checkpoint for a job
  Future<AnalysisCheckpoint?> loadCheckpoint(String jobId) async {
    final dir = await checkpointsDirectory;
    final file = File(p.join(dir, '$jobId.json'));
    
    if (!await file.exists()) return null;
    
    try {
      final content = await file.readAsString();
      final json = jsonDecode(content) as Map<String, dynamic>;
      return AnalysisCheckpoint.fromJson(json);
    } catch (_) {
      return null;
    }
  }

  /// Delete a checkpoint
  Future<void> deleteCheckpoint(String jobId) async {
    final dir = await checkpointsDirectory;
    final file = File(p.join(dir, '$jobId.json'));
    if (await file.exists()) {
      await file.delete();
    }
  }

  /// List all checkpoints
  Future<List<String>> listCheckpoints() async {
    final dir = await checkpointsDirectory;
    final checkpointDir = Directory(dir);
    final checkpoints = <String>[];
    
    await for (final entity in checkpointDir.list()) {
      if (entity is File && entity.path.endsWith('.json')) {
        checkpoints.add(p.basenameWithoutExtension(entity.path));
      }
    }
    
    return checkpoints;
  }

  /// Save an analysis artifact
  Future<void> saveArtifact(
    String mediaHash,
    AnalysisArtifact artifact,
  ) async {
    final dir = await artifactsDirectory;
    final file = File(p.join(dir, '$mediaHash.json'));
    await artifact.save(file.path);
  }

  /// Load an analysis artifact
  Future<AnalysisArtifact?> loadArtifact(String mediaHash) async {
    final dir = await artifactsDirectory;
    final file = File(p.join(dir, '$mediaHash.json'));
    return AnalysisArtifact.load(file.path);
  }

  /// Check if an artifact exists for a media file
  Future<bool> hasArtifact(String mediaHash) async {
    final dir = await artifactsDirectory;
    final file = File(p.join(dir, '$mediaHash.json'));
    return file.exists();
  }

  /// Delete an artifact
  Future<void> deleteArtifact(String mediaHash) async {
    final dir = await artifactsDirectory;
    final file = File(p.join(dir, '$mediaHash.json'));
    if (await file.exists()) {
      await file.delete();
    }
  }

  /// Clean up old checkpoints and artifacts
  Future<void> cleanup({
    Duration maxAge = const Duration(days: 7),
  }) async {
    final checkpointDir = await checkpointsDirectory;
    final artifactDir = await artifactsDirectory;
    
    await _cleanDirectory(Directory(checkpointDir), maxAge);
    await _cleanDirectory(Directory(artifactDir), maxAge);
  }

  Future<void> _cleanDirectory(Directory dir, Duration maxAge) async {
    final cutoff = DateTime.now().subtract(maxAge);
    
    await for (final entity in dir.list()) {
      if (entity is File) {
        final stat = await entity.stat();
        if (stat.modified.isBefore(cutoff)) {
          await entity.delete();
        }
      }
    }
  }
}
