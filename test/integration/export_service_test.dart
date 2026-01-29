
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:kidslens_video_editor/native/bindings/ffmpeg_bindings.dart';
import 'package:kidslens_video_editor/services/export_service.dart';
import 'package:kidslens_video_editor/services/media_service.dart';
import 'package:kidslens_video_editor/data/models/models.dart';
import 'package:kidslens_video_editor/data/models/timeline.dart';

// Helper to create a dummy video file
Future<void> createDummyVideo(String path, String ffmpegPath) async {
  // Generate video with audio
  final result = await Process.run(ffmpegPath, [
    '-f', 'lavfi',
    '-i', 'testsrc=duration=10:size=1280x720:rate=30',
    '-f', 'lavfi',
    '-i', 'sine=frequency=440:duration=10',
    '-c:v', 'libopenh264',
    '-c:a', 'aac',
    '-y',
    path
  ]);
  
  if (result.exitCode != 0) {
    throw Exception('Failed to create dummy video: ${result.stderr}');
  }
}

void main() {
  test('ExportService should successfully export with video/audio modifications', () async {
    // 1. Setup Bindings with real path
    final ffmpegPath = '${Directory.current.path}\\native\\ffmpeg\\binaries\\windows-x64\\ffmpeg.exe';
    
    if (!File(ffmpegPath).existsSync()) {
      print('Skipping test: FFmpeg binary not found at $ffmpegPath');
      return; 
    }

    final bindings = FFmpegBindings();
    bindings.setFFmpegPathForTesting(ffmpegPath);

    // 2. Setup Services
    final mediaService = MediaService(bindings);
    final exportService = ExportService(
      ffmpeg: bindings,
      mediaService: mediaService,
    );

    // 3. Setup Temp Files
    final tempDir = Directory.systemTemp.createTempSync('export_test_');
    final inputPath = '${tempDir.path}\\input.mp4';
    final outputPath = '${tempDir.path}\\output.mp4';

    try {
      print('Creating input video...');
      await createDummyVideo(inputPath, ffmpegPath);

      // 4. Create Timeline
      
      final segVideo = TimelineSegment(
        id: 'seg_v1',
        start: Duration.zero,
        end: Duration(seconds: 10),
        type: ContentType.nsfw, // Just a placeholder type
        confidence: 1.0,
        modification: const Modification.videoBlur(intensity: 50),
      );
      
      final segAudio = TimelineSegment(
        id: 'seg_a1',
        start: Duration.zero,
        end: Duration(seconds: 10),
        type: ContentType.profanity, // Just a placeholder type
        confidence: 1.0,
        modification: const Modification.audioBeep(frequency: 800, volume: 0.5),
      );

      // Create tracks
      final videoTrack = TimelineTrack(
        id: 'video_track',
        type: TrackType.video,
        segments: [segVideo],
        name: 'Video',
        color: '#000000'
      );

      final audioTrack = TimelineTrack(
        id: 'audio_track',
        type: TrackType.audio,
        segments: [segAudio],
        name: 'Audio',
         color: '#000000'
      );

      final timeline = UnifiedTimeline(
         id: 'test_timeline',
         mediaDuration: Duration(seconds: 10),
         tracks: [videoTrack, audioTrack],
         createdAt: DateTime.now(),
      );

      // 5. Run Export
      print('Starting export...');
      final stream = exportService.export(
        inputPath: inputPath,
        outputPath: outputPath,
        timeline: timeline,
        settings: const ExportSettings(
          videoCodec: 'libopenh264', // Valid codec
          audioCodec: 'aac',
          preset: null, // Clear preset for libopenh264
        ),
      );

      await for (final progress in stream) {
        print('Export Progress: ${progress.phase} ${(progress.progress * 100).toStringAsFixed(1)}%');
      }

      // 6. Verify Output
      final outputFile = File(outputPath);
      expect(outputFile.existsSync(), isTrue);
      expect(outputFile.lengthSync(), greaterThan(0));
      print('Export verified successful. Size: ${outputFile.lengthSync()}');

    } catch (e, st) {
      print('Error during test: $e');
      print(st);
      rethrow;
    } finally {
      tempDir.deleteSync(recursive: true);
    }
  });
}
