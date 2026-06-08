import 'package:kidslens_video_editor/data/models/frame_analysis_result.dart';
import 'package:kidslens_video_editor/data/models/profanity_match.dart';
import 'package:kidslens_video_editor/data/models/transcript.dart';

/// Checkpoint for resuming analysis.
class AnalysisCheckpoint {
  AnalysisCheckpoint({
    required this.timestamp,
    this.transcript,
    this.profanityMatches,
    this.lastAnalyzedFrame = 0,
    this.frameResults,
    this.pipelineVersion = defaultPipelineVersion,
    this.modelId,
    this.modelSha256,
    this.pipelineId,
    this.chunkPlannerHash,
    this.modelBundleIds = const {},
    this.policyProfileHash,
    this.samplingConfigHash,
    this.thresholdConfigHash,
  });

  factory AnalysisCheckpoint.fromJson(Map<String, dynamic> json) =>
      AnalysisCheckpoint(
        transcript: json['transcript'] != null
            ? Transcript.fromJson(json['transcript'] as Map<String, dynamic>)
            : null,
        profanityMatches: json['profanityMatches'] != null
            ? (json['profanityMatches'] as List)
                .map((e) => ProfanityMatch.fromJson(e as Map<String, dynamic>))
                .toList()
            : null,
        lastAnalyzedFrame: json['lastAnalyzedFrame'] as int? ?? 0,
        frameResults: json['frameResults'] != null
            ? (json['frameResults'] as List)
                .map(
                  (e) =>
                      FrameAnalysisResult.fromJson(e as Map<String, dynamic>),
                )
                .toList()
            : null,
        pipelineVersion:
            json['pipelineVersion'] as int? ?? defaultPipelineVersion,
        modelId: json['modelId'] as String?,
        modelSha256: json['modelSha256'] as String?,
        pipelineId: json['pipelineId'] as String?,
        chunkPlannerHash: json['chunkPlannerHash'] as String?,
        modelBundleIds: Map<String, String>.from(
          json['modelBundleIds'] as Map? ?? const {},
        ),
        policyProfileHash: json['policyProfileHash'] as String?,
        samplingConfigHash: json['samplingConfigHash'] as String?,
        thresholdConfigHash: json['thresholdConfigHash'] as String?,
        timestamp: DateTime.parse(json['timestamp'] as String),
      );

  /// Legacy direct-detection pipeline version used by existing checkpoints.
  static const int defaultPipelineVersion = 8;

  final Transcript? transcript;
  final List<ProfanityMatch>? profanityMatches;
  final int lastAnalyzedFrame;
  final List<FrameAnalysisResult>? frameResults;
  final DateTime timestamp;
  final int pipelineVersion;
  final String? modelId;
  final String? modelSha256;
  final String? pipelineId;
  final String? chunkPlannerHash;
  final Map<String, String> modelBundleIds;
  final String? policyProfileHash;
  final String? samplingConfigHash;
  final String? thresholdConfigHash;

  Map<String, dynamic> toJson() => {
        'transcript': transcript?.toJson(),
        'profanityMatches': profanityMatches?.map((e) => e.toJson()).toList(),
        'lastAnalyzedFrame': lastAnalyzedFrame,
        'frameResults': frameResults?.map((e) => e.toJson()).toList(),
        'timestamp': timestamp.toIso8601String(),
        'pipelineVersion': pipelineVersion,
        'modelId': modelId,
        'modelSha256': modelSha256,
        'pipelineId': pipelineId,
        'chunkPlannerHash': chunkPlannerHash,
        'modelBundleIds': modelBundleIds,
        'policyProfileHash': policyProfileHash,
        'samplingConfigHash': samplingConfigHash,
        'thresholdConfigHash': thresholdConfigHash,
      };
}
