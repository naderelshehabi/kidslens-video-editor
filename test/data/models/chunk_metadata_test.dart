import 'package:flutter_test/flutter_test.dart';
import 'package:kidslens_video_editor/data/models/models.dart';

void main() {
  group('chunk metadata models', () {
    test('VideoChunk round-trips through JSON', () {
      final chunk = VideoChunk(
        id: VideoChunk.deterministicId(
          mediaId: 'media-a',
          index: 1,
          startTime: const Duration(seconds: 5),
          endTime: const Duration(seconds: 12),
        ),
        mediaId: 'media-a',
        index: 1,
        startTime: const Duration(seconds: 5),
        endTime: const Duration(seconds: 12),
        overlapBefore: const Duration(milliseconds: 750),
        overlapAfter: const Duration(milliseconds: 750),
        sceneChangeTimestamps: const [Duration(seconds: 8)],
      );

      final restored = VideoChunk.fromJson(chunk.toJson());

      expect(restored.id, chunk.id);
      expect(restored.mediaId, 'media-a');
      expect(restored.duration, const Duration(seconds: 7));
      expect(restored.sceneChangeTimestamps, chunk.sceneChangeTimestamps);
    });

    test('SampledFrameRef round-trips through JSON', () {
      final ref = SampledFrameRef(
        id: SampledFrameRef.deterministicId(
          mediaId: 'media-a',
          chunkId: 'chunk-a',
          frameIndex: 2,
          timestamp: const Duration(seconds: 4),
        ),
        mediaId: 'media-a',
        chunkId: 'chunk-a',
        frameIndex: 2,
        timestamp: const Duration(seconds: 4),
        selectionReasons: const ['scene_change', 'motion'],
        sourceFrameNumber: 120,
        cachePath: r'C:\cache\frame.raw',
      );

      final restored = SampledFrameRef.fromJson(ref.toJson());

      expect(restored.id, ref.id);
      expect(restored.selectionReasons, ['scene_change', 'motion']);
      expect(restored.sourceFrameNumber, 120);
      expect(restored.cachePath, ref.cachePath);
    });

    test('AnalysisRunManifest includes chunk and resume metadata', () {
      const chunk = VideoChunk(
        id: 'chunk-a',
        mediaId: 'media-a',
        index: 0,
        startTime: Duration.zero,
        endTime: Duration(seconds: 8),
      );
      final manifest = AnalysisRunManifest(
        runId: 'run-a',
        mediaId: 'media-a',
        pipelineId: 'vss_family_safety_v1',
        pipelineVersion: 9,
        createdAt: DateTime.utc(2026, 6, 7),
        chunkPlannerHash: 'planner-hash',
        samplingHash: 'sampling-hash',
        policyProfileHash: 'policy-hash',
        modelBundleIds: const {'vlm': 'qwen_3_5_4b'},
        chunks: [chunk],
      );

      final restored = AnalysisRunManifest.fromJson(manifest.toJson());

      expect(restored.runId, 'run-a');
      expect(restored.modelBundleIds['vlm'], 'qwen_3_5_4b');
      expect(restored.chunks.single.id, 'chunk-a');
      expect(restored.chunkPlannerHash, 'planner-hash');
    });

    test('AnalysisCheckpoint persists chunked resume metadata', () {
      final checkpoint = AnalysisCheckpoint(
        timestamp: DateTime.utc(2026, 6, 7),
        pipelineId: 'vss_family_safety_v1',
        chunkPlannerHash: 'planner-hash',
        modelBundleIds: const {'vlm': 'qwen_3_5_4b'},
        policyProfileHash: 'policy-hash',
        samplingConfigHash: 'sampling-hash',
      );

      final restored = AnalysisCheckpoint.fromJson(checkpoint.toJson());

      expect(restored.pipelineId, 'vss_family_safety_v1');
      expect(restored.chunkPlannerHash, 'planner-hash');
      expect(restored.modelBundleIds['vlm'], 'qwen_3_5_4b');
      expect(restored.policyProfileHash, 'policy-hash');
      expect(restored.samplingConfigHash, 'sampling-hash');
    });
  });
}
