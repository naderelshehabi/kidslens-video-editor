import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:kidslens_video_editor/data/models/media_file.dart';

void main() {
  group('MediaType enum', () {
    test('should have video and audio values', () {
      expect(MediaType.values, contains(MediaType.video));
      expect(MediaType.values, contains(MediaType.audio));
    });

    test('should have correct JSON values', () {
      expect(MediaType.video.name, equals('video'));
      expect(MediaType.audio.name, equals('audio'));
    });
  });

  group('MediaFile', () {
    group('creation', () {
      test('should create a video media file with all required fields', () {
        const mediaFile = MediaFile(
          id: 'test-id',
          path: '/path/to/video.mp4',
          name: 'video.mp4',
          duration: Duration(minutes: 5),
          width: 1920,
          height: 1080,
          fileSize: 1024 * 1024 * 100, // 100 MB
          mediaType: MediaType.video,
        );

        expect(mediaFile.id, equals('test-id'));
        expect(mediaFile.path, equals('/path/to/video.mp4'));
        expect(mediaFile.name, equals('video.mp4'));
        expect(mediaFile.duration, equals(const Duration(minutes: 5)));
        expect(mediaFile.width, equals(1920));
        expect(mediaFile.height, equals(1080));
        expect(mediaFile.fileSize, equals(1024 * 1024 * 100));
        expect(mediaFile.mediaType, equals(MediaType.video));
      });

      test('should create a media file with optional codec and container', () {
        const mediaFile = MediaFile(
          id: 'test-id',
          path: '/path/to/video.mp4',
          name: 'video.mp4',
          duration: Duration(minutes: 5),
          width: 1920,
          height: 1080,
          fileSize: 1024 * 1024 * 100,
          mediaType: MediaType.video,
          codec: 'h264',
          container: 'mp4',
        );

        expect(mediaFile.codec, equals('h264'));
        expect(mediaFile.container, equals('mp4'));
      });
    });

    group('MediaFile.video factory', () {
      test('should create a video media file with correct type', () {
        final mediaFile = MediaFile.video(
          id: 'video-id',
          path: '/videos/test.mkv',
          name: 'test.mkv',
          duration: const Duration(hours: 1, minutes: 30),
          width: 3840,
          height: 2160,
          fileSize: 1024 * 1024 * 1024 * 5, // 5 GB
          codec: 'hevc',
          container: 'mkv',
        );

        expect(mediaFile.mediaType, equals(MediaType.video));
        expect(mediaFile.isVideo, isTrue);
        expect(mediaFile.isAudio, isFalse);
      });
    });

    group('MediaFile.audio factory', () {
      test('should create an audio media file with zero dimensions', () {
        final mediaFile = MediaFile.audio(
          id: 'audio-id',
          path: '/audio/podcast.mp3',
          name: 'podcast.mp3',
          duration: const Duration(minutes: 45),
          fileSize: 1024 * 1024 * 50, // 50 MB
          codec: 'mp3',
          container: 'mp3',
        );

        expect(mediaFile.mediaType, equals(MediaType.audio));
        expect(mediaFile.isAudio, isTrue);
        expect(mediaFile.isVideo, isFalse);
        expect(mediaFile.width, equals(0));
        expect(mediaFile.height, equals(0));
      });
    });

    group('computed properties', () {
      test('isVideo should return true for video files', () {
        const video = MediaFile(
          id: 'id',
          path: '/path',
          name: 'video.mp4',
          duration: Duration(minutes: 1),
          width: 1920,
          height: 1080,
          fileSize: 1000,
          mediaType: MediaType.video,
        );

        expect(video.isVideo, isTrue);
        expect(video.isAudio, isFalse);
      });

      test('isAudio should return true for audio files', () {
        const audio = MediaFile(
          id: 'id',
          path: '/path',
          name: 'audio.mp3',
          duration: Duration(minutes: 1),
          width: 0,
          height: 0,
          fileSize: 1000,
          mediaType: MediaType.audio,
        );

        expect(audio.isAudio, isTrue);
        expect(audio.isVideo, isFalse);
      });

      test('aspectRatio should calculate correctly', () {
        const widescreen = MediaFile(
          id: 'id',
          path: '/path',
          name: 'video.mp4',
          duration: Duration(minutes: 1),
          width: 1920,
          height: 1080,
          fileSize: 1000,
          mediaType: MediaType.video,
        );

        expect(widescreen.aspectRatio, closeTo(16 / 9, 0.01));
      });

      test('aspectRatio should return 0 for zero height', () {
        const noHeight = MediaFile(
          id: 'id',
          path: '/path',
          name: 'audio.mp3',
          duration: Duration(minutes: 1),
          width: 0,
          height: 0,
          fileSize: 1000,
          mediaType: MediaType.audio,
        );

        expect(noHeight.aspectRatio, equals(0));
      });

      group('fileSizeFormatted', () {
        test('should format bytes correctly', () {
          const file = MediaFile(
            id: 'id',
            path: '/path',
            name: 'small.txt',
            duration: Duration.zero,
            width: 0,
            height: 0,
            fileSize: 500,
            mediaType: MediaType.audio,
          );

          expect(file.fileSizeFormatted, equals('500 B'));
        });

        test('should format kilobytes correctly', () {
          const file = MediaFile(
            id: 'id',
            path: '/path',
            name: 'small.txt',
            duration: Duration.zero,
            width: 0,
            height: 0,
            fileSize: 1024 * 5, // 5 KB
            mediaType: MediaType.audio,
          );

          expect(file.fileSizeFormatted, equals('5.0 KB'));
        });

        test('should format megabytes correctly', () {
          const file = MediaFile(
            id: 'id',
            path: '/path',
            name: 'medium.mp3',
            duration: Duration.zero,
            width: 0,
            height: 0,
            fileSize: 1024 * 1024 * 25, // 25 MB
            mediaType: MediaType.audio,
          );

          expect(file.fileSizeFormatted, equals('25.0 MB'));
        });

        test('should format gigabytes correctly', () {
          const file = MediaFile(
            id: 'id',
            path: '/path',
            name: 'large.mp4',
            duration: Duration.zero,
            width: 1920,
            height: 1080,
            fileSize: 1024 * 1024 * 1024 * 2, // 2 GB
            mediaType: MediaType.video,
          );

          expect(file.fileSizeFormatted, equals('2.00 GB'));
        });
      });
    });

    group('JSON serialization', () {
      test('should serialize to JSON correctly', () {
        const mediaFile = MediaFile(
          id: 'test-id',
          path: '/path/to/video.mp4',
          name: 'video.mp4',
          duration: Duration(seconds: 300),
          width: 1920,
          height: 1080,
          fileSize: 104857600,
          mediaType: MediaType.video,
          codec: 'h264',
          container: 'mp4',
        );

        final json = mediaFile.toJson();

        expect(json['id'], equals('test-id'));
        expect(json['path'], equals('/path/to/video.mp4'));
        expect(json['name'], equals('video.mp4'));
        expect(json['duration'], equals(300000000)); // microseconds
        expect(json['width'], equals(1920));
        expect(json['height'], equals(1080));
        expect(json['fileSize'], equals(104857600));
        expect(json['mediaType'], equals('video'));
        expect(json['codec'], equals('h264'));
        expect(json['container'], equals('mp4'));
      });

      test('should deserialize from JSON correctly', () {
        final json = {
          'id': 'json-id',
          'path': '/path/to/audio.mp3',
          'name': 'audio.mp3',
          'duration': 180000000, // 3 minutes in microseconds
          'width': 0,
          'height': 0,
          'fileSize': 5242880, // 5 MB
          'mediaType': 'audio',
          'codec': 'mp3',
          'container': 'mp3',
        };

        final mediaFile = MediaFile.fromJson(json);

        expect(mediaFile.id, equals('json-id'));
        expect(mediaFile.path, equals('/path/to/audio.mp3'));
        expect(mediaFile.name, equals('audio.mp3'));
        expect(mediaFile.duration, equals(const Duration(minutes: 3)));
        expect(mediaFile.width, equals(0));
        expect(mediaFile.height, equals(0));
        expect(mediaFile.fileSize, equals(5242880));
        expect(mediaFile.mediaType, equals(MediaType.audio));
        expect(mediaFile.codec, equals('mp3'));
        expect(mediaFile.container, equals('mp3'));
      });

      test('should round-trip through JSON correctly', () {
        final original = MediaFile.video(
          id: 'roundtrip-id',
          path: '/path/to/movie.mp4',
          name: 'movie.mp4',
          duration: const Duration(hours: 2, minutes: 15, seconds: 30),
          width: 3840,
          height: 2160,
          fileSize: 1024 * 1024 * 1024 * 8,
          codec: 'hevc',
          container: 'mp4',
        );

        final json = original.toJson();
        final jsonString = jsonEncode(json);
        final decoded = jsonDecode(jsonString) as Map<String, dynamic>;
        final restored = MediaFile.fromJson(decoded);

        expect(restored.id, equals(original.id));
        expect(restored.path, equals(original.path));
        expect(restored.name, equals(original.name));
        expect(restored.duration, equals(original.duration));
        expect(restored.width, equals(original.width));
        expect(restored.height, equals(original.height));
        expect(restored.fileSize, equals(original.fileSize));
        expect(restored.mediaType, equals(original.mediaType));
        expect(restored.codec, equals(original.codec));
        expect(restored.container, equals(original.container));
      });

      test('should handle null optional fields', () {
        final json = {
          'id': 'null-id',
          'path': '/path/to/file.mp4',
          'name': 'file.mp4',
          'duration': 60000000,
          'width': 1280,
          'height': 720,
          'fileSize': 1000000,
          'mediaType': 'video',
        };

        final mediaFile = MediaFile.fromJson(json);

        expect(mediaFile.codec, isNull);
        expect(mediaFile.container, isNull);
      });
    });

    group('equality', () {
      test('should be equal when all fields match', () {
        const file1 = MediaFile(
          id: 'same-id',
          path: '/same/path.mp4',
          name: 'path.mp4',
          duration: Duration(seconds: 60),
          width: 1920,
          height: 1080,
          fileSize: 1000,
          mediaType: MediaType.video,
        );

        const file2 = MediaFile(
          id: 'same-id',
          path: '/same/path.mp4',
          name: 'path.mp4',
          duration: Duration(seconds: 60),
          width: 1920,
          height: 1080,
          fileSize: 1000,
          mediaType: MediaType.video,
        );

        expect(file1, equals(file2));
        expect(file1.hashCode, equals(file2.hashCode));
      });

      test('should not be equal when any field differs', () {
        const file1 = MediaFile(
          id: 'id-1',
          path: '/path.mp4',
          name: 'path.mp4',
          duration: Duration(seconds: 60),
          width: 1920,
          height: 1080,
          fileSize: 1000,
          mediaType: MediaType.video,
        );

        const file2 = MediaFile(
          id: 'id-2', // Different ID
          path: '/path.mp4',
          name: 'path.mp4',
          duration: Duration(seconds: 60),
          width: 1920,
          height: 1080,
          fileSize: 1000,
          mediaType: MediaType.video,
        );

        expect(file1, isNot(equals(file2)));
      });
    });

    group('copyWith', () {
      test('should create a copy with modified fields', () {
        const original = MediaFile(
          id: 'original-id',
          path: '/original/path.mp4',
          name: 'path.mp4',
          duration: Duration(minutes: 5),
          width: 1920,
          height: 1080,
          fileSize: 1000,
          mediaType: MediaType.video,
        );

        final copy = original.copyWith(
          name: 'new-name.mp4',
          codec: 'h265',
        );

        expect(copy.id, equals(original.id));
        expect(copy.path, equals(original.path));
        expect(copy.name, equals('new-name.mp4'));
        expect(copy.codec, equals('h265'));
      });
    });
  });
}
