import 'dart:io';

import 'package:flutter/foundation.dart';
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

    test('extracts chunk JPEG frames for VLM image payloads', () async {
      final ffmpegPath = _bundledFfmpegPath();
      if (!File(ffmpegPath).existsSync()) {
        debugPrint('Skipping test: FFmpeg binary not found at $ffmpegPath.');
        return;
      }
      final bindings = FFmpegBindings()..setFFmpegPathForTesting(ffmpegPath);
      service = FrameSamplingService(ffmpeg: bindings);

      final tempDir =
          await Directory.systemTemp.createTemp('kidslens_jpeg_frames_');
      addTearDown(() async {
        if (tempDir.existsSync()) {
          await tempDir.delete(recursive: true);
        }
      });
      final videoPath =
          '${tempDir.path}${Platform.pathSeparator}input_extract.mp4';
      await _createVideoFixture(videoPath, ffmpegPath);

      final refs = service.selectFrameRefsForChunks(
        [chunk],
        config: const ChunkFrameSelectionConfig(
          maxFramesPerChunk: 3,
          includeSceneChanges: false,
          includeMotionTimestamps: false,
        ),
      );

      final images = await service.extractChunkJpegFrames(
        videoPath: videoPath,
        chunk: chunk,
        frameRefs: refs,
        maxLongSide: 320,
      );

      expect(images, hasLength(refs.length));
      for (var index = 0; index < images.length; index++) {
        final image = images[index];
        expect(image.frameRef.id, refs[index].id);
        expect(image.jpegBytes[0], 0xff);
        expect(image.jpegBytes[1], 0xd8);
        expect(image.sha256, isNotEmpty);
        expect(image.jpegBytes.length, greaterThan(256));

        final dimensions = _readJpegDimensions(image.jpegBytes);
        expect(dimensions.longSide, lessThanOrEqualTo(320));
        expect(dimensions.width, image.width);
        expect(dimensions.height, image.height);
      }
    });
  });
}

String _bundledFfmpegPath() {
  final root = Directory.current.path;
  if (Platform.isWindows) {
    return '$root\\native\\ffmpeg\\binaries\\windows-x64\\ffmpeg.exe';
  }
  if (Platform.isMacOS) {
    return '$root/native/ffmpeg/binaries/macos-universal/ffmpeg';
  }
  return '$root/native/ffmpeg/binaries/linux-x64/ffmpeg';
}

Future<void> _createVideoFixture(String path, String ffmpegPath) async {
  final result = await Process.run(
    ffmpegPath,
    [
      '-f',
      'lavfi',
      '-i',
      'testsrc=duration=10:size=640x360:rate=10',
      '-c:v',
      'libopenh264',
      '-pix_fmt',
      'yuv420p',
      '-y',
      path,
    ],
  );
  if (result.exitCode != 0) {
    throw StateError('Failed to create video fixture: ${result.stderr}');
  }
}

_JpegDimensions _readJpegDimensions(List<int> bytes) {
  if (bytes.length < 4 || bytes[0] != 0xff || bytes[1] != 0xd8) {
    throw const FormatException('Not a JPEG image');
  }
  var offset = 2;
  while (offset + 9 < bytes.length) {
    if (bytes[offset] != 0xff) {
      offset++;
      continue;
    }
    final marker = bytes[offset + 1];
    offset += 2;
    if (marker == 0xd8 || marker == 0xd9) {
      continue;
    }
    if (offset + 2 > bytes.length) {
      break;
    }
    final segmentLength = (bytes[offset] << 8) | bytes[offset + 1];
    if (segmentLength < 2 || offset + segmentLength > bytes.length) {
      break;
    }
    if (_isStartOfFrameMarker(marker)) {
      final height = (bytes[offset + 3] << 8) | bytes[offset + 4];
      final width = (bytes[offset + 5] << 8) | bytes[offset + 6];
      return _JpegDimensions(width: width, height: height);
    }
    offset += segmentLength;
  }
  throw const FormatException('JPEG dimensions not found');
}

bool _isStartOfFrameMarker(int marker) =>
    marker == 0xc0 ||
    marker == 0xc1 ||
    marker == 0xc2 ||
    marker == 0xc3 ||
    marker == 0xc5 ||
    marker == 0xc6 ||
    marker == 0xc7 ||
    marker == 0xc9 ||
    marker == 0xca ||
    marker == 0xcb ||
    marker == 0xcd ||
    marker == 0xce ||
    marker == 0xcf;

class _JpegDimensions {
  const _JpegDimensions({
    required this.width,
    required this.height,
  });

  final int width;
  final int height;

  int get longSide => width > height ? width : height;
}
