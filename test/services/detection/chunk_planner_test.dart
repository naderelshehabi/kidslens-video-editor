import 'package:flutter_test/flutter_test.dart';
import 'package:kidslens_video_editor/services/detection/chunk_planner.dart';

void main() {
  group('ChunkPlanner', () {
    test('creates deterministic overlapping fixed-duration chunks', () {
      const planner = ChunkPlanner(
        config: ChunkPlannerConfig(
          targetChunkDuration: Duration(seconds: 6),
          minChunkDuration: Duration(seconds: 3),
          maxChunkDuration: Duration(seconds: 9),
          overlap: Duration(seconds: 1),
          useSceneBoundaries: false,
        ),
      );

      final chunks = planner.planChunks(
        mediaId: 'media-a',
        mediaDuration: const Duration(seconds: 14),
      );

      expect(chunks, hasLength(3));
      expect(chunks[0].startTime, Duration.zero);
      expect(chunks[0].endTime, const Duration(seconds: 6));
      expect(chunks[1].startTime, const Duration(seconds: 5));
      expect(chunks[1].endTime, const Duration(seconds: 11));
      expect(chunks[2].startTime, const Duration(seconds: 10));
      expect(chunks[2].endTime, const Duration(seconds: 14));
      expect(chunks[0].id, startsWith('chunk_'));

      final repeated = planner.planChunks(
        mediaId: 'media-a',
        mediaDuration: const Duration(seconds: 14),
      );
      expect(
        repeated.map((chunk) => chunk.id),
        chunks.map((chunk) => chunk.id),
      );
    });

    test('hard-cuts on nearby scene boundaries inside configured tolerance',
        () {
      const planner = ChunkPlanner(
        config: ChunkPlannerConfig(
          targetChunkDuration: Duration(seconds: 7),
          minChunkDuration: Duration(seconds: 3),
          maxChunkDuration: Duration(seconds: 10),
          overlap: Duration(seconds: 1),
          sceneBoundaryTolerance: Duration(seconds: 2),
        ),
      );

      final chunks = planner.planChunks(
        mediaId: 'media-b',
        mediaDuration: const Duration(seconds: 20),
        sceneChanges: const [
          Duration(milliseconds: 7500),
          Duration(seconds: 16),
        ],
      );

      expect(chunks.first.endTime, const Duration(milliseconds: 7500));
      expect(
        chunks.first.sceneChangeTimestamps,
        contains(const Duration(milliseconds: 7500)),
      );
      expect(chunks[1].startTime, const Duration(milliseconds: 6500));
    });

    test('ignores duplicate and out-of-range scene changes', () {
      const planner = ChunkPlanner();

      final chunks = planner.planChunks(
        mediaId: 'media-c',
        mediaDuration: const Duration(seconds: 10),
        sceneChanges: const [
          Duration.zero,
          Duration(seconds: 5),
          Duration(seconds: 5),
          Duration(seconds: 10),
        ],
      );

      final sceneChanges =
          chunks.expand((chunk) => chunk.sceneChangeTimestamps).toList();
      expect(sceneChanges, contains(const Duration(seconds: 5)));
      expect(
        sceneChanges
            .where((timestamp) => timestamp == const Duration(seconds: 5)),
        hasLength(1),
      );
    });

    test('rejects invalid config', () {
      const planner = ChunkPlanner(
        config: ChunkPlannerConfig(
          minChunkDuration: Duration(seconds: 2),
          overlap: Duration(seconds: 2),
        ),
      );

      expect(
        () => planner.planChunks(
          mediaId: 'media-d',
          mediaDuration: const Duration(seconds: 10),
        ),
        throwsArgumentError,
      );
    });
  });
}
