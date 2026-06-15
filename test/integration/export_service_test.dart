import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kidslens_video_editor/data/models/models.dart';
import 'package:kidslens_video_editor/native/bindings/ffmpeg_bindings.dart';
import 'package:kidslens_video_editor/services/detection/temporal_fusion.dart';
import 'package:kidslens_video_editor/services/export_service.dart';
import 'package:kidslens_video_editor/services/media_service.dart';

// Helper to create a dummy video file
Future<void> createDummyVideo(String path, String ffmpegPath) async {
  // Generate video with audio
  final result = await Process.run(ffmpegPath, [
    '-f',
    'lavfi',
    '-i',
    'testsrc=duration=10:size=1280x720:rate=30',
    '-f',
    'lavfi',
    '-i',
    'sine=frequency=440:duration=10',
    '-c:v',
    'libopenh264',
    '-c:a',
    'aac',
    '-y',
    path,
  ]);

  if (result.exitCode != 0) {
    throw Exception('Failed to create dummy video: ${result.stderr}');
  }
}

void main() {
  test(
      'ExportService should successfully export with video/audio modifications',
      () async {
    // 1. Setup Bindings with real path
    final ffmpegPath =
        '${Directory.current.path}\\native\\ffmpeg\\binaries\\windows-x64\\ffmpeg.exe';

    if (!File(ffmpegPath).existsSync()) {
      debugPrint('Skipping test: FFmpeg binary not found at $ffmpegPath');
      return;
    }

    final bindings = FFmpegBindings()..setFFmpegPathForTesting(ffmpegPath);

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
      debugPrint('Creating input video...');
      await createDummyVideo(inputPath, ffmpegPath);

      // 4. Create Timeline

      const segVideo = TimelineSegment(
        id: 'seg_v1',
        start: Duration.zero,
        end: Duration(seconds: 10),
        type: ContentType.nsfw, // Just a placeholder type
        confidence: 1,
        modification: Modification.videoBlur(intensity: 50),
      );

      const segAudio = TimelineSegment(
        id: 'seg_a1',
        start: Duration.zero,
        end: Duration(seconds: 10),
        type: ContentType.profanity, // Just a placeholder type
        confidence: 1,
        modification: Modification.audioBeep(frequency: 800),
      );

      // Create tracks
      const videoTrack = TimelineTrack(
        id: 'video_track',
        type: TrackType.video,
        segments: [segVideo],
        name: 'Video',
        color: '#000000',
      );

      const audioTrack = TimelineTrack(
        id: 'audio_track',
        type: TrackType.audio,
        segments: [segAudio],
        name: 'Audio',
        color: '#000000',
      );

      final timeline = UnifiedTimeline(
        id: 'test_timeline',
        mediaDuration: const Duration(seconds: 10),
        tracks: [videoTrack, audioTrack],
        createdAt: DateTime.now(),
      );

      // 5. Run Export
      debugPrint('Starting export...');
      final stream = exportService.export(
        inputPath: inputPath,
        outputPath: outputPath,
        timeline: timeline,
        settings: const ExportSettings(
          videoCodec: 'libopenh264', // Valid codec
          audioCodec: 'aac',
        ),
      );

      await for (final progress in stream) {
        debugPrint(
          'Export Progress: ${progress.phase} '
          '${(progress.progress * 100).toStringAsFixed(1)}%',
        );
      }

      // 6. Verify Output
      final outputFile = File(outputPath);
      expect(outputFile.existsSync(), isTrue);
      expect(outputFile.lengthSync(), greaterThan(0));
      debugPrint(
        'Export verified successful. Size: ${outputFile.lengthSync()}',
      );
    } catch (e, st) {
      debugPrint('Error during test: $e');
      debugPrint('$st');
      rethrow;
    } finally {
      tempDir.deleteSync(recursive: true);
    }
  });

  test('exports region blur from grounded VSS policy detection', () async {
    final ffmpegPath =
        '${Directory.current.path}\\native\\ffmpeg\\binaries\\windows-x64\\ffmpeg.exe';

    if (!File(ffmpegPath).existsSync()) {
      debugPrint('Skipping test: FFmpeg binary not found at $ffmpegPath');
      return;
    }

    final bindings = FFmpegBindings()..setFFmpegPathForTesting(ffmpegPath);
    final mediaService = MediaService(bindings);
    final exportService = ExportService(
      ffmpeg: bindings,
      mediaService: mediaService,
    );
    final tempDir = Directory.systemTemp.createTempSync('vss_region_export_');
    final inputPath = '${tempDir.path}\\input.mp4';
    final outputPath = '${tempDir.path}\\output.mp4';

    try {
      await createDummyVideo(inputPath, ffmpegPath);
      final buildResult = const PolicyDetectionBuilder().build(
        mediaId: 'media_vss_region_export',
        mediaDuration: const Duration(seconds: 10),
        findings: [
          PolicyFinding(
            id: 'finding_vss_grounded_legs',
            mediaId: 'media_vss_region_export',
            category: FamilySafetyPolicyCategory.immodestFemaleClothing,
            severity: FamilySafetySeverity.medium,
            confidence: 0.88,
            startTime: const Duration(seconds: 1),
            endTime: const Duration(seconds: 4),
            recommendedAction: RemediationAction.blurRegion,
            needsReview: true,
            rationale: 'Visible exposed legs were localized by the VSS VLM.',
            supportingEvidenceIds: const ['grounded_region_ev_1'],
            sourceModels: const ['qwen3_vl_8b_instruct_gguf_q4km'],
            origins: const [PolicyFindingOrigin.vlm],
            groundingStatus: GroundingStatus.grounded.jsonValue,
            regionIds: const ['region_legs'],
            developerTracePayload: const {
              'groundedRegion': {
                'box': {
                  'x': 0.25,
                  'y': 0.35,
                  'width': 0.22,
                  'height': 0.38,
                },
              },
            },
          ),
        ],
      );
      final detection = buildResult.detections.single;
      final box = detection.boundingBox!;
      final action = detection.suggestedRemediationAction!;
      final modification = ExportService.modificationFromRemediationAction(
        action: action,
        startTime: detection.startTime,
        endTime: detection.endTime,
        region: RegionBounds(
          x: box['x']!,
          y: box['y']!,
          width: box['width']!,
          height: box['height']!,
        ),
      );
      final timeline = UnifiedTimeline(
        id: 'timeline_vss_region_export',
        mediaDuration: const Duration(seconds: 10),
        tracks: [
          TimelineTrack.video().copyWith(
            segments: [
              TimelineSegment.fromDetection(
                detection,
                modification: modification,
              ),
            ],
          ),
          TimelineTrack.audio(),
          TimelineTrack.detection(),
        ],
        createdAt: DateTime.now(),
      );

      await for (final _ in exportService.export(
        inputPath: inputPath,
        outputPath: outputPath,
        timeline: timeline,
        settings: const ExportSettings(
          videoCodec: 'libopenh264',
          audioCodec: 'aac',
        ),
      )) {}

      final outputFile = File(outputPath);
      expect(detection.hasBoundingBox, isTrue);
      expect(action, RemediationAction.blurRegion);
      expect(outputFile.existsSync(), isTrue);
      expect(outputFile.lengthSync(), greaterThan(0));
    } finally {
      tempDir.deleteSync(recursive: true);
    }
  });
}
