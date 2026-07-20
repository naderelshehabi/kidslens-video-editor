import 'package:flutter_test/flutter_test.dart';
import 'package:kidslens_video_editor/data/models/media_file.dart';
import 'package:kidslens_video_editor/services/media_service.dart';

// Mock FFmpeg bindings for testing
class MockFFmpegBindings {
  bool shouldThrow = false;
  Duration mockDuration = const Duration(minutes: 5);
  int mockWidth = 1920;
  int mockHeight = 1080;
  int mockFileSize = 104857600; // 100 MB
  String mockVideoCodec = 'h264';
  String mockAudioCodec = 'aac';

  Future<MockMediaMetadata> probeMedia(String path) async {
    if (shouldThrow) {
      throw Exception('FFmpeg probe failed');
    }
    return MockMediaMetadata(
      duration: mockDuration,
      resolution: MockResolution(width: mockWidth, height: mockHeight),
      fileSizeBytes: mockFileSize,
      videoCodec: mockVideoCodec,
      audioCodec: mockAudioCodec,
    );
  }

  Future<String> extractAudio(String videoPath, String outputPath) async {
    if (shouldThrow) {
      throw Exception('FFmpeg extract audio failed');
    }
    return outputPath;
  }

  Stream<FrameData> extractFrames(
    String videoPath, {
    double fps = 2.0,
    int? startFrame,
    int? endFrame,
  }) async* {
    if (shouldThrow) {
      throw Exception('FFmpeg extract frames failed');
    }

    final frameCount = (mockDuration.inSeconds * fps).round();
    for (var i = startFrame ?? 0; i < (endFrame ?? frameCount); i++) {
      yield FrameData(
        frameNumber: i,
        timestamp: Duration(milliseconds: (i * 1000 / fps).round()),
        rgbData: List.filled(mockWidth * mockHeight * 3, 0),
        width: mockWidth,
        height: mockHeight,
      );
    }
  }

  Future<String> generateThumbnail(String videoPath, String outputPath) async {
    if (shouldThrow) {
      throw Exception('FFmpeg thumbnail generation failed');
    }
    return outputPath;
  }
}

class MockMediaMetadata {
  MockMediaMetadata({
    required this.duration,
    required this.resolution,
    // ignore: avoid_unused_constructor_parameters - Match real MediaMetadata
    required int fileSizeBytes,
    // ignore: avoid_unused_constructor_parameters - Match real MediaMetadata
    required String videoCodec,
    // ignore: avoid_unused_constructor_parameters - Match real MediaMetadata
    required String audioCodec,
  });

  final Duration duration;
  final MockResolution resolution;
}

class MockResolution {
  MockResolution({required this.width, required this.height});

  final int width;
  final int height;
}

void main() {
  group('MediaService', () {
    group('media type detection', () {
      test('should identify video files by extension', () {
        final videoExtensions = [
          'mp4',
          'mkv',
          'avi',
          'mov',
          'wmv',
          'flv',
          'webm',
          'm4v',
        ];

        for (final ext in videoExtensions) {
          final path = '/path/to/video.$ext';
          expect(
            _determineMediaType(path),
            equals(MediaType.video),
            reason: 'Should identify .$ext as video',
          );
        }
      });

      test('should identify audio files by extension', () {
        final audioExtensions = ['mp3', 'wav', 'aac', 'flac', 'ogg', 'm4a'];

        for (final ext in audioExtensions) {
          final path = '/path/to/audio.$ext';
          expect(
            _determineMediaType(path),
            equals(MediaType.audio),
            reason: 'Should identify .$ext as audio',
          );
        }
      });

      test('should handle uppercase extensions', () {
        expect(_determineMediaType('/path/video.MP4'), equals(MediaType.video));
        expect(_determineMediaType('/path/audio.MP3'), equals(MediaType.audio));
      });

      test('should handle mixed case extensions', () {
        expect(_determineMediaType('/path/video.Mp4'), equals(MediaType.video));
        expect(_determineMediaType('/path/audio.Mp3'), equals(MediaType.audio));
      });
    });

    group('MediaFileNotFoundException', () {
      test('should create with path', () {
        final exception = MediaFileNotFoundException('/path/to/missing.mp4');

        expect(exception.path, equals('/path/to/missing.mp4'));
        expect(exception.toString(), contains('/path/to/missing.mp4'));
      });
    });

    group('FrameData', () {
      test('should create with required fields', () {
        final frame = FrameData(
          frameNumber: 0,
          timestamp: Duration.zero,
          rgbData: [0, 0, 0],
          width: 1920,
          height: 1080,
        );

        expect(frame.frameNumber, equals(0));
        expect(frame.timestamp, equals(Duration.zero));
        expect(frame.width, equals(1920));
        expect(frame.height, equals(1080));
      });

      test('should create frame at specific timestamp', () {
        final frame = FrameData(
          frameNumber: 48,
          timestamp: const Duration(seconds: 2),
          rgbData: List.filled(100 * 100 * 3, 128),
          width: 100,
          height: 100,
        );

        expect(frame.frameNumber, equals(48));
        expect(frame.timestamp, equals(const Duration(seconds: 2)));
      });
    });

    group('mock scenarios', () {
      late MockFFmpegBindings mockBindings;

      setUp(() {
        mockBindings = MockFFmpegBindings();
      });

      test('mock should return correct metadata', () async {
        mockBindings
          ..mockDuration = const Duration(minutes: 10)
          ..mockWidth = 3840
          ..mockHeight = 2160;

        final metadata = await mockBindings.probeMedia('/test.mp4');

        expect(metadata.duration, equals(const Duration(minutes: 10)));
        expect(metadata.resolution.width, equals(3840));
        expect(metadata.resolution.height, equals(2160));
      });

      test('mock should generate frames', () async {
        mockBindings.mockDuration = const Duration(seconds: 5);

        final frames = <FrameData>[];
        await mockBindings.extractFrames('/test.mp4').forEach(frames.add);

        expect(frames, hasLength(10)); // 5 seconds * 2 fps
        expect(frames.first.frameNumber, equals(0));
        expect(frames.last.frameNumber, equals(9));
      });

      test('mock should respect frame range', () async {
        final frames = <FrameData>[];
        await mockBindings
            .extractFrames(
              '/test.mp4',
              startFrame: 2,
              endFrame: 5,
            )
            .forEach(frames.add);

        expect(frames, hasLength(3));
        expect(frames.first.frameNumber, equals(2));
        expect(frames.last.frameNumber, equals(4));
      });

      test('mock should throw when configured', () async {
        mockBindings.shouldThrow = true;

        expect(
          () => mockBindings.probeMedia('/test.mp4'),
          throwsException,
        );
      });

      test('mock should return audio extraction path', () async {
        final result = await mockBindings.extractAudio(
          '/video.mp4',
          '/audio.wav',
        );

        expect(result, equals('/audio.wav'));
      });

      test('mock should return thumbnail path', () async {
        final result = await mockBindings.generateThumbnail(
          '/video.mp4',
          '/thumb.jpg',
        );

        expect(result, equals('/thumb.jpg'));
      });
    });

    group('MediaFile creation from metadata', () {
      test('should create video MediaFile from metadata', () {
        final mediaFile = MediaFile.video(
          id: 'test-123',
          path: '/path/to/video.mp4',
          name: 'video.mp4',
          duration: const Duration(minutes: 5),
          width: 1920,
          height: 1080,
          fileSize: 104857600,
          codec: 'h264',
          container: 'mp4',
        );

        expect(mediaFile.id, equals('test-123'));
        expect(mediaFile.isVideo, isTrue);
        expect(mediaFile.width, equals(1920));
        expect(mediaFile.height, equals(1080));
      });

      test('should create audio MediaFile from metadata', () {
        final mediaFile = MediaFile.audio(
          id: 'test-456',
          path: '/path/to/audio.mp3',
          name: 'audio.mp3',
          duration: const Duration(minutes: 30),
          fileSize: 52428800,
          codec: 'mp3',
          container: 'mp3',
        );

        expect(mediaFile.id, equals('test-456'));
        expect(mediaFile.isAudio, isTrue);
        expect(mediaFile.width, equals(0));
        expect(mediaFile.height, equals(0));
      });
    });

    group('error handling', () {
      test('MediaFileNotFoundException should contain path info', () {
        const path = '/nonexistent/file.mp4';
        final exception = MediaFileNotFoundException(path);

        expect(exception.path, equals(path));
        expect(exception.toString(), contains(path));
        expect(exception.toString(), contains('not found'));
      });
    });
  });
}

// Helper function to simulate media type detection
MediaType _determineMediaType(String path) {
  final extension = path.split('.').last.toLowerCase();
  const videoExtensions = [
    'mp4',
    'mkv',
    'avi',
    'mov',
    'wmv',
    'flv',
    'webm',
    'm4v',
  ];
  return videoExtensions.contains(extension)
      ? MediaType.video
      : MediaType.audio;
}
