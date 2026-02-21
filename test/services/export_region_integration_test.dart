import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:kidslens_video_editor/data/models/models.dart';
import 'package:kidslens_video_editor/native/bindings/ffmpeg_bindings.dart';
import 'package:kidslens_video_editor/services/export_service.dart';
import 'package:kidslens_video_editor/services/media_service.dart';

// =============================================================================
// Mock FFmpegBindings
// =============================================================================

/// A mock [FFmpegBindings] that records all arguments passed to
/// [runFilterComplex], yields configurable progress events, and creates a
/// dummy output file so that [ExportService.export] passes its post-export
/// verification checks.
class _MockFFmpegBindings extends FFmpegBindings {
  _MockFFmpegBindings() {
    // Mark as initialized with a fake path so isAvailable returns true.
    setFFmpegPathForTesting('mock_ffmpeg');
  }

  final int probeWidth = 1920;
  final int probeHeight = 1080;
  final Duration probeDuration = const Duration(minutes: 5);

  /// Progress values to yield from [runFilterComplex].
  final List<double> progressSteps = const [0.0, 0.25, 0.5, 0.75, 1.0];

  /// All arguments captured from the most recent [runFilterComplex] call.
  String? capturedInputPath;
  String? capturedOutputPath;
  String? capturedFilterComplex;
  Map<String, String>? capturedOutputSettings;
  Duration? capturedTotalDuration;

  /// Number of times [runFilterComplex] was called.
  int runFilterComplexCallCount = 0;

  /// Number of times [probeMedia] was called.
  int probeMediaCallCount = 0;

  @override
  Future<void> initialize() async {
    // Already initialized via setFFmpegPathForTesting in the constructor.
  }

  @override
  Future<MediaMetadata> probeMedia(String path) async {
    probeMediaCallCount++;
    return MediaMetadata(
      duration: probeDuration,
      fileSizeBytes: 10000000,
      resolution: Resolution(width: probeWidth, height: probeHeight),
      frameRate: 30,
      videoCodec: 'h264',
      audioCodec: 'aac',
    );
  }

  @override
  Stream<double> runFilterComplex({
    required String inputPath,
    required String outputPath,
    required String filterComplex,
    Map<String, String>? outputSettings,
    Duration? totalDuration,
  }) async* {
    runFilterComplexCallCount++;
    capturedInputPath = inputPath;
    capturedOutputPath = outputPath;
    capturedFilterComplex = filterComplex;
    capturedOutputSettings = outputSettings;
    capturedTotalDuration = totalDuration;

    // Create a non-empty output file so ExportService verification succeeds.
    final file = File(outputPath);
    file.parent.createSync(recursive: true);
    file.writeAsStringSync('mock exported video content');

    // Yield progress steps in order.
    for (final step in progressSteps) {
      yield step;
    }
  }
}

// =============================================================================
// Mock MediaService
// =============================================================================

/// A minimal [MediaService] backed by the mock FFmpeg bindings.
class _MockMediaService extends MediaService {
  _MockMediaService(_MockFFmpegBindings super.ffmpeg);
}

// =============================================================================
// Helper functions
// =============================================================================

/// Creates a video [TimelineSegment] with the given modification and time range.
TimelineSegment _videoSegment({
  required Modification modification,
  Duration start = const Duration(seconds: 2),
  Duration end = const Duration(seconds: 5),
  String? id,
}) => TimelineSegment(
    id: id ?? 'seg_v_${start.inMilliseconds}_${end.inMilliseconds}',
    start: start,
    end: end,
    type: ContentType.nsfw,
    confidence: 0.95,
    modification: modification,
  );

/// Creates an audio [TimelineSegment] with the given modification and time range.
TimelineSegment _audioSegment({
  required Modification modification,
  Duration start = const Duration(seconds: 2),
  Duration end = const Duration(seconds: 5),
  String? id,
}) => TimelineSegment(
    id: id ?? 'seg_a_${start.inMilliseconds}_${end.inMilliseconds}',
    start: start,
    end: end,
    type: ContentType.profanity,
    confidence: 0.9,
    modification: modification,
  );

/// Builds a [UnifiedTimeline] from video and audio segments.
UnifiedTimeline _buildTimeline({
  List<TimelineSegment> videoSegments = const [],
  List<TimelineSegment> audioSegments = const [],
  Duration mediaDuration = const Duration(minutes: 5),
}) => UnifiedTimeline(
    id: 'test_timeline',
    mediaDuration: mediaDuration,
    tracks: [
      TimelineTrack(
        id: 'track_video',
        type: TrackType.video,
        name: 'Video',
        segments: videoSegments,
      ),
      TimelineTrack(
        id: 'track_audio',
        type: TrackType.audio,
        name: 'Audio',
        segments: audioSegments,
      ),
    ],
  );

// =============================================================================
// Tests
// =============================================================================

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late _MockFFmpegBindings mockFFmpeg;
  late ExportService exportService;
  late Directory tempDir;

  setUp(() {
    mockFFmpeg = _MockFFmpegBindings();
    exportService = ExportService(
      ffmpeg: mockFFmpeg,
      mediaService: _MockMediaService(mockFFmpeg),
    );
    tempDir = Directory.systemTemp.createTempSync('export_region_integration_');
  });

  tearDown(() {
    if (tempDir.existsSync()) {
      tempDir.deleteSync(recursive: true);
    }
  });

  // ==========================================================================
  // Group 1: Export with region modifications
  // ==========================================================================
  group('Export with region modifications', () {
    test(
        'timeline with 2 video region blur segments and 1 audio mute yields '
        'progress events from 0 to 1', () async {
      final timeline = _buildTimeline(
        videoSegments: [
          _videoSegment(
            id: 'seg_v_1',
            modification: const Modification.videoRegionBlur(
              region: RegionBounds(x: 0.1, y: 0.2, width: 0.3, height: 0.4),
            ),
            start: const Duration(seconds: 1),
            end: const Duration(seconds: 4),
          ),
          _videoSegment(
            id: 'seg_v_2',
            modification: const Modification.videoRegionBlur(
              intensity: 70,
              region: RegionBounds(x: 0.5, y: 0.5, width: 0.2, height: 0.2),
            ),
            start: const Duration(seconds: 3),
            end: const Duration(seconds: 7),
          ),
        ],
        audioSegments: [
          _audioSegment(
            modification: const Modification.audioMute(),
            end: const Duration(seconds: 6),
          ),
        ],
      );

      final inputPath = '${tempDir.path}${Platform.pathSeparator}input.mp4';
      final outputPath = '${tempDir.path}${Platform.pathSeparator}output.mp4';

      final progressEvents = <ExportProgress>[];
      await exportService.export(
        inputPath: inputPath,
        outputPath: outputPath,
        timeline: timeline,
      ).forEach(progressEvents.add);

      // Verify progress starts at 0 and ends at 1.
      expect(progressEvents.first.progress, 0.0);
      expect(progressEvents.last.progress, 1.0);

      // Verify progress is monotonically non-decreasing.
      for (var i = 1; i < progressEvents.length; i++) {
        expect(
          progressEvents[i].progress,
          greaterThanOrEqualTo(progressEvents[i - 1].progress),
        );
      }

      // Verify FFmpeg received a non-empty filter complex with region patterns.
      final filter = mockFFmpeg.capturedFilterComplex ?? '';
      expect(filter, isNotEmpty);
      expect(filter, contains('split=2'));
      expect(filter, contains('crop='));
      expect(filter, contains('gblur=sigma='));
      expect(filter, contains('overlay='));
    });

    test('filter complex contains region-chained blur filters for both regions',
        () async {
      final timeline = _buildTimeline(
        videoSegments: [
          _videoSegment(
            id: 'seg_v_1',
            modification: const Modification.videoRegionBlur(
              region: RegionBounds(x: 0.1, y: 0.2, width: 0.3, height: 0.4),
            ),
            start: const Duration(seconds: 1),
            end: const Duration(seconds: 4),
          ),
          _videoSegment(
            id: 'seg_v_2',
            modification: const Modification.videoRegionBlur(
              intensity: 70,
              region: RegionBounds(x: 0.5, y: 0.5, width: 0.2, height: 0.2),
            ),
            start: const Duration(seconds: 3),
            end: const Duration(seconds: 7),
          ),
        ],
        audioSegments: [
          _audioSegment(
            modification: const Modification.audioMute(),
            end: const Duration(seconds: 6),
          ),
        ],
      );

      final inputPath = '${tempDir.path}${Platform.pathSeparator}input.mp4';
      final outputPath = '${tempDir.path}${Platform.pathSeparator}output.mp4';

      await exportService
          .export(
            inputPath: inputPath,
            outputPath: outputPath,
            timeline: timeline,
          )
          .drain<void>();

      final filter = mockFFmpeg.capturedFilterComplex ?? '';

      // First region: [0:v] -> split -> crop -> gblur -> overlay -> [rv0]
      expect(filter, contains('[0:v]split=2[base0][c0]'));
      // sigma for intensity 50: 5 + ((50-1)*45~/99) = 27
      expect(filter, contains('gblur=sigma=27'));
      expect(filter, contains('[rv0]'));

      // Second region chains from [rv0] -> split -> crop -> gblur -> overlay -> [rv1]
      expect(filter, contains('[rv0]split=2[base1][c1]'));
      // sigma for intensity 70: 5 + ((70-1)*45~/99) = 36
      expect(filter, contains('gblur=sigma=36'));
      expect(filter, contains('[rv1]'));

      // Audio mute filter present.
      expect(filter, contains('[0:a]'));
      expect(filter, contains("volume=enable='between(t,2.0,6.0)':volume=0"));
    });

    test('output file is created and non-empty after export', () async {
      final timeline = _buildTimeline(
        videoSegments: [
          _videoSegment(
            modification: const Modification.videoRegionBlur(
              region: RegionBounds(x: 0.1, y: 0.2, width: 0.3, height: 0.4),
            ),
          ),
        ],
      );

      final inputPath = '${tempDir.path}${Platform.pathSeparator}input.mp4';
      final outputPath = '${tempDir.path}${Platform.pathSeparator}output.mp4';

      await exportService
          .export(
            inputPath: inputPath,
            outputPath: outputPath,
            timeline: timeline,
          )
          .drain<void>();

      final outputFile = File(outputPath);
      expect(outputFile.existsSync(), isTrue);
      expect(outputFile.lengthSync(), greaterThan(0));
    });
  });

  // ==========================================================================
  // Group 2: Export with mixed modifications
  // ==========================================================================
  group('Export with mixed modifications', () {
    test(
        'timeline with VideoRegionBlur + VideoRegionPixelate + VideoBlur '
        'produces filter containing all modification types', () async {
      final timeline = _buildTimeline(
        videoSegments: [
          _videoSegment(
            id: 'seg_region_blur',
            modification: const Modification.videoRegionBlur(
              region: RegionBounds(x: 0.1, y: 0.1, width: 0.2, height: 0.2),
            ),
            start: const Duration(seconds: 1),
            end: const Duration(seconds: 3),
          ),
          _videoSegment(
            id: 'seg_region_pixelate',
            modification: const Modification.videoRegionPixelate(
              region: RegionBounds(x: 0.5, y: 0.5, width: 0.3, height: 0.3),
            ),
          ),
          _videoSegment(
            id: 'seg_linear_blur',
            modification: const Modification.videoBlur(),
            start: Duration.zero,
            end: const Duration(seconds: 10),
          ),
        ],
      );

      final inputPath = '${tempDir.path}${Platform.pathSeparator}input.mp4';
      final outputPath = '${tempDir.path}${Platform.pathSeparator}output.mp4';

      await exportService
          .export(
            inputPath: inputPath,
            outputPath: outputPath,
            timeline: timeline,
          )
          .drain<void>();

      final filter = mockFFmpeg.capturedFilterComplex ?? '';

      // Region blur filter (split->crop->gblur->overlay chain).
      expect(filter, contains('gblur=sigma='));
      expect(filter, contains('split=2[base0][c0]'));
      expect(filter, contains('overlay='));

      // Region pixelate filter (split->crop->scale down->scale up->overlay).
      // For region at 0.5,0.5 with 0.3x0.3 on 1920x1080:
      // crop: w=576, h=324, x=960, y=540
      // downW = 576 ~/ 10 = 57, downH = 324 ~/ 10 = 32
      expect(filter, contains('scale=57:32,scale=576:324:flags=neighbor'));

      // Linear full-frame blur applied after region chain.
      // sigma for intensity 20: 5 + ((20-1)*45~/99) = 13
      expect(filter, contains("gblur=sigma=13:enable='between(t,0.0,10.0)'"));
    });

    test('region mods are processed before linear mods in filter chain',
        () async {
      final timeline = _buildTimeline(
        videoSegments: [
          _videoSegment(
            id: 'seg_region',
            modification: const Modification.videoRegionBlur(
              region: RegionBounds(x: 0.1, y: 0.2, width: 0.3, height: 0.4),
            ),
          ),
          _videoSegment(
            id: 'seg_linear',
            modification: const Modification.videoBlur(),
            start: Duration.zero,
            end: const Duration(seconds: 10),
          ),
        ],
      );

      final inputPath = '${tempDir.path}${Platform.pathSeparator}input.mp4';
      final outputPath = '${tempDir.path}${Platform.pathSeparator}output.mp4';

      await exportService
          .export(
            inputPath: inputPath,
            outputPath: outputPath,
            timeline: timeline,
          )
          .drain<void>();

      final filter = mockFFmpeg.capturedFilterComplex ?? '';

      // Region chain output label appears before linear filter.
      final regionOutputIndex = filter.indexOf('[rv0]');
      final linearFilterIndex = filter.indexOf('gblur=sigma=13');
      expect(regionOutputIndex, greaterThan(-1));
      expect(linearFilterIndex, greaterThan(-1));
      expect(regionOutputIndex, lessThan(linearFilterIndex));
    });

    test('progress events are yielded for mixed modification export',
        () async {
      final timeline = _buildTimeline(
        videoSegments: [
          _videoSegment(
            id: 'seg_region_blur',
            modification: const Modification.videoRegionBlur(
              region: RegionBounds(x: 0.1, y: 0.1, width: 0.2, height: 0.2),
            ),
            start: const Duration(seconds: 1),
            end: const Duration(seconds: 3),
          ),
          _videoSegment(
            id: 'seg_linear_blur',
            modification: const Modification.videoBlur(),
            start: Duration.zero,
            end: const Duration(seconds: 10),
          ),
        ],
      );

      final inputPath = '${tempDir.path}${Platform.pathSeparator}input.mp4';
      final outputPath = '${tempDir.path}${Platform.pathSeparator}output.mp4';

      final progressValues = <double>[];
      await for (final event in exportService.export(
        inputPath: inputPath,
        outputPath: outputPath,
        timeline: timeline,
      )) {
        progressValues.add(event.progress);
      }

      // Verify all progress values are between 0 and 1.
      for (final p in progressValues) {
        expect(p, greaterThanOrEqualTo(0.0));
        expect(p, lessThanOrEqualTo(1.0));
      }

      // Starts at 0, ends at 1.
      expect(progressValues.first, 0.0);
      expect(progressValues.last, 1.0);
    });
  });

  // ==========================================================================
  // Group 3: Export with only drawbox modifications
  // ==========================================================================
  group('Export with only drawbox modifications', () {
    test('VideoRegionBlackBox produces drawbox pattern in filter', () async {
      final timeline = _buildTimeline(
        videoSegments: [
          _videoSegment(
            modification: const Modification.videoRegionBlackBox(
              color: '#FF0000',
              opacity: 0.8,
              region: RegionBounds(x: 0.1, y: 0.1, width: 0.2, height: 0.3),
            ),
            start: const Duration(seconds: 3),
            end: const Duration(seconds: 7),
          ),
        ],
      );

      final inputPath = '${tempDir.path}${Platform.pathSeparator}input.mp4';
      final outputPath = '${tempDir.path}${Platform.pathSeparator}output.mp4';

      await exportService
          .export(
            inputPath: inputPath,
            outputPath: outputPath,
            timeline: timeline,
          )
          .drain<void>();

      final filter = mockFFmpeg.capturedFilterComplex ?? '';

      // Drawbox filter with pixel coordinates.
      // px=192, py=108, pw=384, ph=324
      expect(filter, contains('drawbox='));
      expect(filter, contains('x=192'));
      expect(filter, contains('y=108'));
      expect(filter, contains('w=384'));
      expect(filter, contains('h=324'));

      // Color: 0xFF0000cc (0.8 * 255 = 204 = 0xcc).
      expect(filter, contains('c=0xFF0000cc'));
      expect(filter, contains('t=fill'));
      expect(filter, contains("enable='between(t,3.0,7.0)'"));

      // Drawbox does NOT use split/crop/overlay chain.
      expect(filter, isNot(contains('split=2')));
      expect(filter, isNot(contains('crop=')));
      expect(filter, isNot(contains('overlay=')));
    });

    test('multiple drawbox modifications are comma-chained', () async {
      final timeline = _buildTimeline(
        videoSegments: [
          _videoSegment(
            id: 'seg_db_1',
            modification: const Modification.videoRegionBlackBox(
              region: RegionBounds(x: 0, y: 0, width: 0.1, height: 0.1),
            ),
            start: const Duration(seconds: 1),
            end: const Duration(seconds: 3),
          ),
          _videoSegment(
            id: 'seg_db_2',
            modification: const Modification.videoRegionBlackBox(
              color: '#FF0000',
              opacity: 0.5,
              region: RegionBounds(x: 0.5, y: 0.5, width: 0.2, height: 0.2),
            ),
            start: const Duration(seconds: 4),
            end: const Duration(seconds: 8),
          ),
        ],
      );

      final inputPath = '${tempDir.path}${Platform.pathSeparator}input.mp4';
      final outputPath = '${tempDir.path}${Platform.pathSeparator}output.mp4';

      await exportService
          .export(
            inputPath: inputPath,
            outputPath: outputPath,
            timeline: timeline,
          )
          .drain<void>();

      final filter = mockFFmpeg.capturedFilterComplex ?? '';

      // Both drawbox filters present.
      expect(filter, contains('c=0x000000ff'));
      expect(filter, contains('c=0xFF000080'));

      // Both time ranges present.
      expect(filter, contains("enable='between(t,1.0,3.0)'"));
      expect(filter, contains("enable='between(t,4.0,8.0)'"));
    });

    test('drawbox export produces valid progress events', () async {
      final timeline = _buildTimeline(
        videoSegments: [
          _videoSegment(
            modification: const Modification.videoRegionBlackBox(
              region: RegionBounds(x: 0.1, y: 0.1, width: 0.2, height: 0.2),
            ),
          ),
        ],
      );

      final inputPath = '${tempDir.path}${Platform.pathSeparator}input.mp4';
      final outputPath = '${tempDir.path}${Platform.pathSeparator}output.mp4';

      final progressEvents = <ExportProgress>[];
      await exportService.export(
        inputPath: inputPath,
        outputPath: outputPath,
        timeline: timeline,
      ).forEach(progressEvents.add);

      expect(progressEvents.first.progress, 0.0);
      expect(progressEvents.last.progress, 1.0);
      expect(progressEvents.length, greaterThan(2));
    });
  });

  // ==========================================================================
  // Group 4: Export with no modifications
  // ==========================================================================
  group('Export with no modifications', () {
    test('empty timeline produces empty filter complex', () async {
      final timeline = _buildTimeline(
        videoSegments: [],
        audioSegments: [],
      );

      final inputPath = '${tempDir.path}${Platform.pathSeparator}input.mp4';
      final outputPath = '${tempDir.path}${Platform.pathSeparator}output.mp4';

      await exportService
          .export(
            inputPath: inputPath,
            outputPath: outputPath,
            timeline: timeline,
          )
          .drain<void>();

      final filter = mockFFmpeg.capturedFilterComplex ?? '';
      expect(filter, isEmpty);
    });

    test('empty timeline still produces progress events from 0 to 1',
        () async {
      final timeline = _buildTimeline(
        videoSegments: [],
        audioSegments: [],
      );

      final inputPath = '${tempDir.path}${Platform.pathSeparator}input.mp4';
      final outputPath = '${tempDir.path}${Platform.pathSeparator}output.mp4';

      final progressEvents = <ExportProgress>[];
      await exportService.export(
        inputPath: inputPath,
        outputPath: outputPath,
        timeline: timeline,
      ).forEach(progressEvents.add);

      expect(progressEvents.first.progress, 0.0);
      expect(progressEvents.last.progress, 1.0);
    });

    test('empty timeline does not invoke probeMedia for region resolution',
        () async {
      final timeline = _buildTimeline(
        videoSegments: [],
        audioSegments: [],
      );

      final inputPath = '${tempDir.path}${Platform.pathSeparator}input.mp4';
      final outputPath = '${tempDir.path}${Platform.pathSeparator}output.mp4';

      await exportService
          .export(
            inputPath: inputPath,
            outputPath: outputPath,
            timeline: timeline,
          )
          .drain<void>();

      // probeMedia is not called when there are no region mods.
      expect(mockFFmpeg.probeMediaCallCount, 0);
    });

    test('timeline with no video mods but audio-only mods has audio filter',
        () async {
      final timeline = _buildTimeline(
        videoSegments: [],
        audioSegments: [
          _audioSegment(
            modification: const Modification.audioMute(),
            start: const Duration(seconds: 1),
            end: const Duration(seconds: 3),
          ),
        ],
      );

      final inputPath = '${tempDir.path}${Platform.pathSeparator}input.mp4';
      final outputPath = '${tempDir.path}${Platform.pathSeparator}output.mp4';

      await exportService
          .export(
            inputPath: inputPath,
            outputPath: outputPath,
            timeline: timeline,
          )
          .drain<void>();

      final filter = mockFFmpeg.capturedFilterComplex ?? '';

      // Audio filter present.
      expect(filter, contains('[0:a]'));
      expect(
        filter,
        contains("volume=enable='between(t,1.0,3.0)':volume=0"),
      );

      // No video filter chain.
      expect(filter, isNot(contains('[0:v]')));
      expect(filter, isNot(contains('split=2')));
      expect(filter, isNot(contains('overlay=')));
    });
  });

  // ==========================================================================
  // Group 5: Cut duration validation (VideoSkip segments)
  // ==========================================================================
  group('Cut duration validation', () {
    test('timeline with VideoSkip segments still produces export output',
        () async {
      final timeline = _buildTimeline(
        videoSegments: [
          _videoSegment(
            id: 'seg_skip_1',
            modification: const Modification.videoSkip(),
            start: const Duration(seconds: 5),
            end: const Duration(seconds: 10),
          ),
          _videoSegment(
            id: 'seg_skip_2',
            modification: const Modification.videoSkip(),
            start: const Duration(seconds: 20),
            end: const Duration(seconds: 25),
          ),
        ],
        mediaDuration: const Duration(minutes: 1),
      );

      final inputPath = '${tempDir.path}${Platform.pathSeparator}input.mp4';
      final outputPath = '${tempDir.path}${Platform.pathSeparator}output.mp4';

      final progressEvents = <ExportProgress>[];
      await exportService.export(
        inputPath: inputPath,
        outputPath: outputPath,
        timeline: timeline,
      ).forEach(progressEvents.add);

      // Export completes successfully.
      expect(progressEvents.last.progress, 1.0);

      // Output file exists.
      expect(File(outputPath).existsSync(), isTrue);
      expect(File(outputPath).lengthSync(), greaterThan(0));

      // FFmpeg was invoked.
      expect(mockFFmpeg.runFilterComplexCallCount, 1);
    });

    test('VideoSkip produces empty video filter string (handled elsewhere)',
        () async {
      final timeline = _buildTimeline(
        videoSegments: [
          _videoSegment(
            modification: const Modification.videoSkip(),
            start: const Duration(seconds: 5),
            end: const Duration(seconds: 10),
          ),
        ],
      );

      final inputPath = '${tempDir.path}${Platform.pathSeparator}input.mp4';
      final outputPath = '${tempDir.path}${Platform.pathSeparator}output.mp4';

      await exportService
          .export(
            inputPath: inputPath,
            outputPath: outputPath,
            timeline: timeline,
          )
          .drain<void>();

      // VideoSkip maps to an empty filter string in _videoModToFilter,
      // so the filter complex should be empty (no non-empty video filters).
      final filter = mockFFmpeg.capturedFilterComplex ?? '';
      expect(filter, isEmpty);
    });

    test('timeline with VideoSkip and region mods processes both', () async {
      final timeline = _buildTimeline(
        videoSegments: [
          _videoSegment(
            id: 'seg_skip',
            modification: const Modification.videoSkip(),
            start: const Duration(seconds: 5),
            end: const Duration(seconds: 10),
          ),
          _videoSegment(
            id: 'seg_region',
            modification: const Modification.videoRegionBlur(
              region: RegionBounds(x: 0.1, y: 0.2, width: 0.3, height: 0.4),
            ),
          ),
        ],
      );

      final inputPath = '${tempDir.path}${Platform.pathSeparator}input.mp4';
      final outputPath = '${tempDir.path}${Platform.pathSeparator}output.mp4';

      await exportService
          .export(
            inputPath: inputPath,
            outputPath: outputPath,
            timeline: timeline,
          )
          .drain<void>();

      final filter = mockFFmpeg.capturedFilterComplex ?? '';

      // Region blur chain present.
      expect(filter, contains('split=2'));
      expect(filter, contains('crop='));
      expect(filter, contains('gblur=sigma='));
      expect(filter, contains('overlay='));

      // Export completed successfully.
      expect(File(outputPath).existsSync(), isTrue);
    });
  });
}
