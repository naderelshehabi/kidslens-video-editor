import 'package:kidslens_video_editor/data/models/video_chunk.dart';

/// Deterministic metadata for a chunk-aware analysis run.
class AnalysisRunManifest {
  const AnalysisRunManifest({
    required this.runId,
    required this.mediaId,
    required this.pipelineId,
    required this.pipelineVersion,
    required this.createdAt,
    required this.chunkPlannerHash,
    required this.samplingHash,
    required this.policyProfileHash,
    this.modelBundleIds = const {},
    this.chunks = const [],
  });

  factory AnalysisRunManifest.fromJson(Map<String, dynamic> json) =>
      AnalysisRunManifest(
        runId: json['runId'] as String,
        mediaId: json['mediaId'] as String,
        pipelineId: json['pipelineId'] as String,
        pipelineVersion: (json['pipelineVersion'] as num).toInt(),
        createdAt: DateTime.parse(json['createdAt'] as String),
        chunkPlannerHash: json['chunkPlannerHash'] as String,
        samplingHash: json['samplingHash'] as String,
        policyProfileHash: json['policyProfileHash'] as String,
        modelBundleIds: Map<String, String>.from(
          json['modelBundleIds'] as Map? ?? const {},
        ),
        chunks: (json['chunks'] as List<dynamic>? ?? const [])
            .map((value) => VideoChunk.fromJson(value as Map<String, dynamic>))
            .toList(growable: false),
      );

  final String runId;
  final String mediaId;
  final String pipelineId;
  final int pipelineVersion;
  final DateTime createdAt;
  final String chunkPlannerHash;
  final String samplingHash;
  final String policyProfileHash;
  final Map<String, String> modelBundleIds;
  final List<VideoChunk> chunks;

  Map<String, dynamic> toJson() => {
        'runId': runId,
        'mediaId': mediaId,
        'pipelineId': pipelineId,
        'pipelineVersion': pipelineVersion,
        'createdAt': createdAt.toIso8601String(),
        'chunkPlannerHash': chunkPlannerHash,
        'samplingHash': samplingHash,
        'policyProfileHash': policyProfileHash,
        'modelBundleIds': modelBundleIds,
        'chunks': chunks.map((chunk) => chunk.toJson()).toList(growable: false),
      };
}
