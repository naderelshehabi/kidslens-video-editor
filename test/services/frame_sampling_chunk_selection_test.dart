import 'package:flutter_test/flutter_test.dart';
import 'package:kidslens_video_editor/data/models/models.dart';
import 'package:kidslens_video_editor/native/bindings/ffmpeg_bindings.dart';
import 'package:kidslens_video_editor/services/frame_sampling_service.dart';

void main() {
  group('FrameSamplingService chunk-aware selection', () {
    late FrameSamplingService service;
    late VideoChunk chunk;

    setUp(() {
      service = FrameSamplingService(ffmpeg: FFmpegBindings());
      chunk = VideoChunk(
        id: VideoChunk.deterministicId(
          mediaId: 'media-a',
          index: 0,
          startTime: Duration.zero,
          endTime: const Duration(seconds: 10),
        ),
        mediaId: 'media-a',
        index: 0,
        startTime: Duration.zero,
        endTime: const Duration(seconds: 10),
        sceneChangeTimestamps: const [
          Duration(seconds: 2),
          Duration(seconds: 6),
        ],
      );
    });

    test('selects start, middle, end, scene, and motion references', () {
      final refs = service.selectFrameRefsForChunks(
        [chunk],
        motionTimestampsByChunkId: {
          chunk.id: const [Duration(seconds: 5)],
        },
      );

      expect(
        refs.map((ref) => ref.timestamp),
        containsAll([
          Duration.zero,
          const Duration(seconds: 2),
          const Duration(seconds: 5),
          const Duration(seconds: 6),
          const Duration(milliseconds: 9999),
        ]),
      );
      expect(
        refs
            .singleWhere((ref) => ref.timestamp == const Duration(seconds: 5))
            .selectionReasons,
        containsAll(['chunk_middle', 'motion']),
      );
      expect(refs.every((ref) => ref.id.startsWith('frame_')), isTrue);
    });

    test('limits selected references deterministically', () {
      final refs = service.selectFrameRefsForChunks(
        [chunk],
        config: const ChunkFrameSelectionConfig(maxFramesPerChunk: 3),
        motionTimestampsByChunkId: {
          chunk.id: const [Duration(seconds: 3), Duration(seconds: 4)],
        },
      );

      expect(refs, hasLength(3));
      final timestamps = refs.map((ref) => ref.timestamp).toList();
      expect(timestamps, [...timestamps]..sort());

      final repeated = service.selectFrameRefsForChunks(
        [chunk],
        config: const ChunkFrameSelectionConfig(maxFramesPerChunk: 3),
        motionTimestampsByChunkId: {
          chunk.id: const [Duration(seconds: 3), Duration(seconds: 4)],
        },
      );
      expect(
        repeated.map((ref) => ref.id),
        refs.map((ref) => ref.id),
      );
    });

    test('builds legacy fixed-FPS references per chunk', () {
      final refs = service.selectLegacyFixedFpsFrameRefs(
        const [
          VideoChunk(
            id: 'chunk-fixed',
            mediaId: 'media-a',
            index: 0,
            startTime: Duration.zero,
            endTime: Duration(seconds: 2),
          ),
        ],
        fps: 2,
      );

      expect(
        refs.map((ref) => ref.timestamp).toList(),
        const [
          Duration.zero,
          Duration(milliseconds: 500),
          Duration(seconds: 1),
          Duration(milliseconds: 1500),
        ],
      );
      expect(
        refs.map((ref) => ref.selectionReasons.single).toSet(),
        {'legacy_fixed_fps'},
      );
    });

    test('rejects invalid selection parameters', () {
      expect(
        () => service.selectFrameRefsForChunks(
          [chunk],
          config: const ChunkFrameSelectionConfig(maxFramesPerChunk: 0),
        ),
        throwsArgumentError,
      );
      expect(
        () => service.selectLegacyFixedFpsFrameRefs([chunk], fps: 0),
        throwsArgumentError,
      );
    });
  });
}
