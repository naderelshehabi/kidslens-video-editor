import 'dart:convert';
import 'dart:io';

import 'package:freezed_annotation/freezed_annotation.dart';

import 'package:kidslens_video_editor/data/models/analysis_result.dart';
import 'package:kidslens_video_editor/data/models/analysis_settings.dart';
import 'package:kidslens_video_editor/data/models/frame_analysis_result.dart';
import 'package:kidslens_video_editor/data/models/media_file.dart';
import 'package:kidslens_video_editor/data/models/profanity_match.dart';
import 'package:kidslens_video_editor/data/models/timeline.dart';
import 'package:kidslens_video_editor/data/models/transcript.dart';

part 'artifact.freezed.dart';
part 'artifact.g.dart';

/// Media metadata stored in artifact for validation
@freezed
class ArtifactMediaInfo with _$ArtifactMediaInfo {
  const factory ArtifactMediaInfo({
    /// Duration of the media in microseconds
    required int durationMicroseconds,

    /// File size in bytes
    required int fileSize,

    /// Width of video (0 for audio)
    required int width,

    /// Height of video (0 for audio)
    required int height,

    /// Codec used
    String? codec,

    /// Container format
    String? container,
  }) = _ArtifactMediaInfo;

  factory ArtifactMediaInfo.fromJson(Map<String, dynamic> json) =>
      _$ArtifactMediaInfoFromJson(json);

  /// Creates from a MediaFile
  factory ArtifactMediaInfo.fromMediaFile(MediaFile file) => ArtifactMediaInfo(
        durationMicroseconds: file.duration.inMicroseconds,
        fileSize: file.fileSize,
        width: file.width,
        height: file.height,
        codec: file.codec,
        container: file.container,
      );
}

/// Versioned analysis artifact for caching and resume
@freezed
class AnalysisArtifact with _$AnalysisArtifact {
  const factory AnalysisArtifact({
    /// SHA-256 hash of the source media file
    required String mediaHash,

    /// Media file information
    required ArtifactMediaInfo mediaInfo,

    /// Settings used for this analysis
    required AnalysisSettings settingsUsed,

    /// Unified timeline with all detections and modifications
    required UnifiedTimeline timeline,

    /// When the analysis was started
    required DateTime createdAt,

    /// Current status of the analysis
    required AnalysisStatus status,

    /// Version of the artifact format
    @Default(1) int version,

    /// Transcript if ASR was performed
    Transcript? transcript,

    /// Profanity matches found
    @Default([]) List<ProfanityMatch> profanityMatches,

    /// Frame analysis results
    @Default([]) List<FrameAnalysisResult> frameResults,

    /// When the analysis was completed
    DateTime? completedAt,

    /// Error message if failed
    String? errorMessage,
  }) = _AnalysisArtifact;

  const AnalysisArtifact._();
  
  factory AnalysisArtifact.fromJson(Map<String, dynamic> json) =>
      _$AnalysisArtifactFromJson(json);
  
  /// Save artifact to JSON file
  Future<void> save(String path) async {
    final json = toJson();
    final file = File(path);
    await file.writeAsString(
      const JsonEncoder.withIndent('  ').convert(json),
    );
  }
  
  /// Load artifact from JSON file
  static Future<AnalysisArtifact?> load(String path) async {
    final file = File(path);
    if (!file.existsSync()) return null;
    
    try {
      final content = await file.readAsString();
      final json = jsonDecode(content) as Map<String, dynamic>;
      return AnalysisArtifact.fromJson(json);
    } catch (_) {
      return null;
    }
  }
  
  /// Check if artifact can be reused for given media and settings
  bool isCompatibleWith({
    required String newMediaHash,
    required AnalysisSettings newSettings,
  }) {
    // Must be same media file
    if (newMediaHash != mediaHash) return false;
    
    // Must be completed
    if (status != AnalysisStatus.completed) return false;
    
    // Check if model config matches
    if (newSettings.modelConfig.asrModelId != settingsUsed.modelConfig.asrModelId) {
      return false;
    }
    if (newSettings.modelConfig.visualModelId != settingsUsed.modelConfig.visualModelId) {
      return false;
    }
    
    return true;
  }

  /// Whether this artifact is complete and usable
  bool get isComplete => status == AnalysisStatus.completed && completedAt != null;

  /// Whether this artifact represents a failed analysis
  bool get isFailed => status == AnalysisStatus.failed;
}
