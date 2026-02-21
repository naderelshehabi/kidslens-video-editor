import 'dart:io';
import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';
import 'package:kidslens_video_editor/data/models/modification.dart';
import 'package:kidslens_video_editor/data/models/timeline.dart';
import 'package:kidslens_video_editor/data/models/detection.dart';
import 'package:kidslens_video_editor/native/bindings/ffmpeg_bindings.dart';
import 'package:kidslens_video_editor/services/export_service.dart';
import 'package:kidslens_video_editor/services/media_service.dart';

/// A fake [FFmpegBindings] that captures the filter complex string
/// passed to [runFilterComplex] without executing any real FFmpeg commands.
///
/// Also creates a dummy output file so that [ExportService.export] passes
/// its post-export verification checks.
class _CapturingFFmpegBindings extends FFmpegBindings {
  _CapturingFFmpegBindings({
    this.probeWidth = 1920,
    this.probeHeight = 1080,
  }) {
    // Mark as initialized with a fake path so isAvailable returns true.
    setFFmpegPathForTesting('fake_ffmpeg');
  }

  final int probeWidth;
  final int probeHeight;

  /// The filter complex string captured from the last [runFilterComplex] call.
  String? capturedFilterComplex;

  /// The output settings captured from the last [runFilterComplex] call.
  Map<String, String>? capturedOutputSettings;

  @override
  Future<void> initialize() async {
    // Already initialized via setFFmpegPathForTesting in constructor.
  }

  @override
  Future<MediaMetadata> probeMedia(String path) async {
    return MediaMetadata(
      duration: const Duration(minutes: 5),
      fileSizeBytes: 1000000,
      resolution: Resolution(width: probeWidth, height: probeHeight),
      frameRate: 30.0,
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
    capturedFilterComplex = filterComplex;
    capturedOutputSettings = outputSettings;

    // Create a non-empty output file so ExportService verification succeeds.
    final file = File(outputPath);
    file.parent.createSync(recursive: true);
    file.writeAsStringSync('fake video data');

    yield 1.0;
  }
}

/// Runs an export and returns the captured filter complex string.
Future<String> _captureFilterComplex({
  required _CapturingFFmpegBindings fakeFFmpeg,
  required ExportService exportService,
  required Directory tempDir,
  required UnifiedTimeline timeline,
  ExportSettings settings = const ExportSettings(),
}) async {
  final inputPath = '${tempDir.path}${Platform.pathSeparator}input.mp4';
  final outputPath = '${tempDir.path}${Platform.pathSeparator}output.mp4';

  await exportService
      .export(
        inputPath: inputPath,
        outputPath: outputPath,
        timeline: timeline,
        settings: settings,
      )
      .drain<void>();

  return fakeFFmpeg.capturedFilterComplex ?? '';
}

/// Creates a [TimelineSegment] on a video track with the given modification.
TimelineSegment _videoSegment({
  required Modification modification,
  Duration start = const Duration(seconds: 2),
  Duration end = const Duration(seconds: 5),
  String? id,
}) {
  return TimelineSegment(
    id: id ?? 'seg_v_${start.inMilliseconds}_${end.inMilliseconds}',
    start: start,
    end: end,
    type: ContentType.nsfw,
    confidence: 0.95,
    modification: modification,
  );
}

/// Creates a [TimelineSegment] on an audio track with the given modification.
TimelineSegment _audioSegment({
  required Modification modification,
  Duration start = const Duration(seconds: 2),
  Duration end = const Duration(seconds: 5),
  String? id,
}) {
  return TimelineSegment(
    id: id ?? 'seg_a_${start.inMilliseconds}_${end.inMilliseconds}',
    start: start,
    end: end,
    type: ContentType.profanity,
    confidence: 0.9,
    modification: modification,
  );
}

/// Creates a [UnifiedTimeline] from video and audio segments.
UnifiedTimeline _buildTimeline({
  List<TimelineSegment> videoSegments = const [],
  List<TimelineSegment> audioSegments = const [],
  Duration mediaDuration = const Duration(minutes: 5),
}) {
  return UnifiedTimeline(
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
}

void main() {
  // ==========================================================================
  // Group 1: Pure formula / algorithm tests
  // ==========================================================================
  group('ExportService region filter formulas', () {
    group('intensity to blur sigma', () {
      // Formula from ExportService: 5 + ((intensity - 1) * 45 ~/ 99)
      int intensityToSigma(int intensity) =>
          5 + ((intensity - 1) * 45 ~/ 99);

      test('maps minimum intensity 1 to sigma 5', () {
        expect(intensityToSigma(1), 5);
      });

      test('maps intensity 50 to sigma 27', () {
        // (50-1) * 45 = 2205, 2205 ~/ 99 = 22, 5 + 22 = 27
        expect(intensityToSigma(50), 27);
      });

      test('maps maximum intensity 100 to sigma 50', () {
        // (100-1) * 45 = 4455, 4455 ~/ 99 = 45, 5 + 45 = 50
        expect(intensityToSigma(100), 50);
      });

      test('maps intensity 20 to sigma 13', () {
        // (20-1) * 45 = 855, 855 ~/ 99 = 8, 5 + 8 = 13
        expect(intensityToSigma(20), 13);
      });

      test('maps intensity 70 to sigma 36', () {
        // (70-1) * 45 = 3105, 3105 ~/ 99 = 31, 5 + 31 = 36
        expect(intensityToSigma(70), 36);
      });
    });

    group('normalized to pixel coordinates', () {
      test('standard region on 1920x1080', () {
        const videoWidth = 1920;
        const videoHeight = 1080;
        const region = RegionBounds(
          x: 0.1,
          y: 0.2,
          width: 0.3,
          height: 0.4,
        );

        expect((region.x * videoWidth).round(), 192);
        expect((region.y * videoHeight).round(), 216);
        expect((region.width * videoWidth).round(), 576);
        expect((region.height * videoHeight).round(), 432);
      });

      test('centered region on 1920x1080', () {
        const videoWidth = 1920;
        const videoHeight = 1080;
        const region = RegionBounds(
          x: 0.5,
          y: 0.5,
          width: 0.2,
          height: 0.2,
        );

        expect((region.x * videoWidth).round(), 960);
        expect((region.y * videoHeight).round(), 540);
        expect((region.width * videoWidth).round(), 384);
        expect((region.height * videoHeight).round(), 216);
      });

      test('full frame region on 1280x720', () {
        const videoWidth = 1280;
        const videoHeight = 720;
        const region = RegionBounds(
          x: 0.0,
          y: 0.0,
          width: 1.0,
          height: 1.0,
        );

        expect((region.x * videoWidth).round(), 0);
        expect((region.y * videoHeight).round(), 0);
        expect((region.width * videoWidth).round(), 1280);
        expect((region.height * videoHeight).round(), 720);
      });
    });

    group('pixel coordinate clamping', () {
      test('region extending beyond right and bottom edges', () {
        const videoWidth = 1920;
        const videoHeight = 1080;
        const region = RegionBounds(
          x: 0.9,
          y: 0.9,
          width: 0.3,
          height: 0.3,
        );

        final px = (region.x * videoWidth).round();
        final py = (region.y * videoHeight).round();
        final pw = (region.width * videoWidth).round();
        final ph = (region.height * videoHeight).round();

        final cropX = math.max(0, math.min(px, videoWidth - 1));
        final cropY = math.max(0, math.min(py, videoHeight - 1));
        final cropW = math.max(1, math.min(pw, videoWidth - cropX));
        final cropH = math.max(1, math.min(ph, videoHeight - cropY));

        expect(cropX, 1728);
        expect(cropY, 972);
        // min(576, 1920 - 1728) = min(576, 192) = 192
        expect(cropW, 192);
        // min(324, 1080 - 972) = min(324, 108) = 108
        expect(cropH, 108);
      });

      test('tiny region near origin clamps width and height to at least 1',
          () {
        const videoWidth = 1920;
        const videoHeight = 1080;
        const region =
            RegionBounds(x: 0.0, y: 0.0, width: 0.001, height: 0.001);

        final px = (region.x * videoWidth).round();
        final py = (region.y * videoHeight).round();
        final pw = (region.width * videoWidth).round();
        final ph = (region.height * videoHeight).round();

        final cropX = math.max(0, math.min(px, videoWidth - 1));
        final cropY = math.max(0, math.min(py, videoHeight - 1));
        final cropW = math.max(1, math.min(pw, videoWidth - cropX));
        final cropH = math.max(1, math.min(ph, videoHeight - cropY));

        expect(cropX, 0);
        expect(cropY, 0);
        expect(cropW, 2); // (0.001 * 1920).round() = 2
        expect(cropH, 1); // (0.001 * 1080).round() = 1
      });
    });

    group('pixelate scale-down dimensions', () {
      test('standard dimensions with blockSize 10', () {
        const cropW = 576;
        const cropH = 432;
        const blockSize = 10;

        final downW = math.max(1, cropW ~/ blockSize);
        final downH = math.max(1, cropH ~/ blockSize);

        expect(downW, 57);
        expect(downH, 43);
      });

      test('small crop smaller than blockSize clamps to 1', () {
        const cropW = 5;
        const cropH = 3;
        const blockSize = 10;

        final downW = math.max(1, cropW ~/ blockSize);
        final downH = math.max(1, cropH ~/ blockSize);

        // 5 ~/ 10 = 0, max(1, 0) = 1
        expect(downW, 1);
        // 3 ~/ 10 = 0, max(1, 0) = 1
        expect(downH, 1);
      });
    });

    group('enable expression format', () {
      // Formula: 'between(t,${start.inMilliseconds / 1000.0},${end.inMilliseconds / 1000.0})'
      String buildEnable(Duration start, Duration end) =>
          'between(t,${start.inMilliseconds / 1000.0},${end.inMilliseconds / 1000.0})';

      test('whole second durations', () {
        expect(
          buildEnable(
            const Duration(seconds: 2),
            const Duration(seconds: 5),
          ),
          'between(t,2.0,5.0)',
        );
      });

      test('subsecond durations', () {
        expect(
          buildEnable(
            const Duration(milliseconds: 1500),
            const Duration(milliseconds: 3750),
          ),
          'between(t,1.5,3.75)',
        );
      });

      test('zero start time', () {
        expect(
          buildEnable(Duration.zero, const Duration(seconds: 10)),
          'between(t,0.0,10.0)',
        );
      });
    });

    group('hex color to FFmpeg format', () {
      // Formula from ExportService._hexToFFmpegColor
      String hexToFFmpeg(String hexColor, double opacity) {
        final hex =
            hexColor.startsWith('#') ? hexColor.substring(1) : hexColor;
        final alphaHex =
            (opacity * 255).round().toRadixString(16).padLeft(2, '0');
        return '0x$hex$alphaHex';
      }

      test('black with full opacity', () {
        expect(hexToFFmpeg('#000000', 1.0), '0x000000ff');
      });

      test('red with half opacity', () {
        // (0.5 * 255).round() = 128 = 0x80
        expect(hexToFFmpeg('#FF0000', 0.5), '0xFF000080');
      });

      test('white with zero opacity', () {
        expect(hexToFFmpeg('#FFFFFF', 0.0), '0xFFFFFF00');
      });

      test('without hash prefix', () {
        expect(hexToFFmpeg('AABBCC', 1.0), '0xAABBCCff');
      });

      test('with 0.8 opacity', () {
        // (0.8 * 255).round() = 204 = 0xcc
        expect(hexToFFmpeg('#FF0000', 0.8), '0xFF0000cc');
      });
    });
  });

  // ==========================================================================
  // Group 2: Integration tests via ExportService.export() with captured filter
  // ==========================================================================
  group('ExportService region filter chain generation', () {
    late _CapturingFFmpegBindings fakeFFmpeg;
    late ExportService exportService;
    late Directory tempDir;

    setUp(() {
      fakeFFmpeg = _CapturingFFmpegBindings();
      exportService = ExportService(
        ffmpeg: fakeFFmpeg,
        mediaService: MediaService(fakeFFmpeg),
      );
      tempDir = Directory.systemTemp.createTempSync('export_region_test_');
    });

    tearDown(() {
      if (tempDir.existsSync()) {
        tempDir.deleteSync(recursive: true);
      }
    });

    test('single VideoRegionBlur produces split-crop-blur-overlay chain',
        () async {
      final timeline = _buildTimeline(
        videoSegments: [
          _videoSegment(
            modification: const Modification.videoRegionBlur(
              intensity: 50,
              region:
                  RegionBounds(x: 0.1, y: 0.2, width: 0.3, height: 0.4),
            ),
            start: const Duration(seconds: 2),
            end: const Duration(seconds: 5),
          ),
        ],
      );

      final filter = await _captureFilterComplex(
        fakeFFmpeg: fakeFFmpeg,
        exportService: exportService,
        tempDir: tempDir,
        timeline: timeline,
      );

      // sigma = 5 + ((50-1)*45~/99) = 27
      // crop coords: w=576, h=432, x=192, y=216
      expect(filter, contains('[0:v]split=2[base0][c0]'));
      expect(filter, contains('[c0]crop=576:432:192:216,gblur=sigma=27[b0]'));
      expect(
        filter,
        contains(
          "[base0][b0]overlay=x=192:y=216:enable='between(t,2.0,5.0)'",
        ),
      );
      expect(filter, contains('[rv0]'));
    });

    test(
        'single VideoRegionPixelate produces split-crop-scale-overlay chain',
        () async {
      final timeline = _buildTimeline(
        videoSegments: [
          _videoSegment(
            modification: const Modification.videoRegionPixelate(
              blockSize: 10,
              region:
                  RegionBounds(x: 0.5, y: 0.5, width: 0.2, height: 0.2),
            ),
            start: const Duration(seconds: 1),
            end: const Duration(seconds: 4),
          ),
        ],
      );

      final filter = await _captureFilterComplex(
        fakeFFmpeg: fakeFFmpeg,
        exportService: exportService,
        tempDir: tempDir,
        timeline: timeline,
      );

      // crop: w=384, h=216, x=960, y=540
      // downW = 384 ~/ 10 = 38, downH = 216 ~/ 10 = 21
      expect(filter, contains('[0:v]split=2[base0][c0]'));
      expect(
        filter,
        contains(
          '[c0]crop=384:216:960:540,'
          'scale=38:21,scale=384:216:flags=neighbor[b0]',
        ),
      );
      expect(
        filter,
        contains(
          "[base0][b0]overlay=x=960:y=540:enable='between(t,1.0,4.0)'",
        ),
      );
    });

    test('single VideoRegionBlackBox produces drawbox filter (no split)',
        () async {
      final timeline = _buildTimeline(
        videoSegments: [
          _videoSegment(
            modification: const Modification.videoRegionBlackBox(
              color: '#FF0000',
              opacity: 0.8,
              region:
                  RegionBounds(x: 0.1, y: 0.1, width: 0.2, height: 0.3),
            ),
            start: const Duration(seconds: 3),
            end: const Duration(seconds: 7),
          ),
        ],
      );

      final filter = await _captureFilterComplex(
        fakeFFmpeg: fakeFFmpeg,
        exportService: exportService,
        tempDir: tempDir,
        timeline: timeline,
      );

      // px=192, py=108, pw=384, ph=324
      // color = 0xFF0000cc  (0.8 * 255 = 204 = 0xcc)
      expect(filter, contains('[0:v]'));
      expect(filter, contains('drawbox=x=192:y=108:w=384:h=324'));
      expect(filter, contains('c=0xFF0000cc'));
      expect(filter, contains("t=fill:enable='between(t,3.0,7.0)'"));
      // Drawbox does NOT use split/crop/overlay
      expect(filter, isNot(contains('split=2')));
      expect(filter, isNot(contains('overlay=')));
    });

    test('multiple VideoRegionBlur mods are chained sequentially',
        () async {
      final timeline = _buildTimeline(
        videoSegments: [
          _videoSegment(
            id: 'seg_v_1',
            modification: const Modification.videoRegionBlur(
              intensity: 30,
              region:
                  RegionBounds(x: 0.1, y: 0.1, width: 0.2, height: 0.2),
            ),
            start: const Duration(seconds: 1),
            end: const Duration(seconds: 3),
          ),
          _videoSegment(
            id: 'seg_v_2',
            modification: const Modification.videoRegionBlur(
              intensity: 70,
              region:
                  RegionBounds(x: 0.5, y: 0.5, width: 0.3, height: 0.3),
            ),
            start: const Duration(seconds: 2),
            end: const Duration(seconds: 6),
          ),
        ],
      );

      final filter = await _captureFilterComplex(
        fakeFFmpeg: fakeFFmpeg,
        exportService: exportService,
        tempDir: tempDir,
        timeline: timeline,
      );

      // First region: sigma=18, crop=384:216:192:108
      expect(filter, contains('[0:v]split=2[base0][c0]'));
      expect(
          filter, contains('[c0]crop=384:216:192:108,gblur=sigma=18[b0]'));
      expect(
        filter,
        contains(
          "[base0][b0]overlay=x=192:y=108:"
          "enable='between(t,1.0,3.0)'[rv0]",
        ),
      );

      // Second region chains from [rv0]: sigma=36, crop=576:324:960:540
      expect(filter, contains('[rv0]split=2[base1][c1]'));
      expect(
        filter,
        contains('[c1]crop=576:324:960:540,gblur=sigma=36[b1]'),
      );
      expect(
        filter,
        contains(
          "[base1][b1]overlay=x=960:y=540:"
          "enable='between(t,2.0,6.0)'[rv1]",
        ),
      );
    });

    test('mixed region blur and full-frame VideoBlur: regions applied first',
        () async {
      final timeline = _buildTimeline(
        videoSegments: [
          _videoSegment(
            id: 'seg_region',
            modification: const Modification.videoRegionBlur(
              intensity: 50,
              region:
                  RegionBounds(x: 0.1, y: 0.2, width: 0.3, height: 0.4),
            ),
            start: const Duration(seconds: 2),
            end: const Duration(seconds: 5),
          ),
          _videoSegment(
            id: 'seg_linear',
            modification: const Modification.videoBlur(intensity: 20),
            start: Duration.zero,
            end: const Duration(seconds: 10),
          ),
        ],
      );

      final filter = await _captureFilterComplex(
        fakeFFmpeg: fakeFFmpeg,
        exportService: exportService,
        tempDir: tempDir,
        timeline: timeline,
      );

      // Region chain comes first with sigma=27
      expect(filter, contains('[0:v]split=2[base0][c0]'));
      expect(filter, contains('gblur=sigma=27[b0]'));
      expect(filter, contains('[rv0]'));

      // Linear full-frame blur follows, chained from [rv0]
      // sigma for intensity 20: 5 + ((20-1)*45~/99) = 5 + 8 = 13
      expect(
        filter,
        contains("[rv0]gblur=sigma=13:enable='between(t,0.0,10.0)'"),
      );
    });

    test('mixed region blur and drawbox: drawbox applied after region chain',
        () async {
      final timeline = _buildTimeline(
        videoSegments: [
          _videoSegment(
            id: 'seg_region',
            modification: const Modification.videoRegionBlur(
              intensity: 50,
              region:
                  RegionBounds(x: 0.1, y: 0.2, width: 0.3, height: 0.4),
            ),
            start: const Duration(seconds: 2),
            end: const Duration(seconds: 5),
          ),
          _videoSegment(
            id: 'seg_drawbox',
            modification: const Modification.videoRegionBlackBox(
              region:
                  RegionBounds(x: 0.5, y: 0.5, width: 0.1, height: 0.1),
            ),
            start: const Duration(seconds: 3),
            end: const Duration(seconds: 6),
          ),
        ],
      );

      final filter = await _captureFilterComplex(
        fakeFFmpeg: fakeFFmpeg,
        exportService: exportService,
        tempDir: tempDir,
        timeline: timeline,
      );

      // Region chain first
      expect(filter, contains('[0:v]split=2[base0][c0]'));
      expect(filter, contains('[rv0]'));

      // Drawbox follows using region chain output [rv0]
      // px=960, py=540, pw=192, ph=108
      expect(filter, contains('[rv0]drawbox=x=960:y=540:w=192:h=108'));
      // Default black with opacity 1.0: 0x000000ff
      expect(filter, contains('c=0x000000ff'));
    });

    test('no modifications produces empty filter complex', () async {
      final timeline = _buildTimeline(
        videoSegments: [],
        audioSegments: [],
      );

      final filter = await _captureFilterComplex(
        fakeFFmpeg: fakeFFmpeg,
        exportService: exportService,
        tempDir: tempDir,
        timeline: timeline,
      );

      expect(filter, isEmpty);
    });

    test('only audio mute produces audio-only filter', () async {
      final timeline = _buildTimeline(
        audioSegments: [
          _audioSegment(
            modification: const Modification.audioMute(),
            start: const Duration(seconds: 1),
            end: const Duration(seconds: 3),
          ),
        ],
      );

      final filter = await _captureFilterComplex(
        fakeFFmpeg: fakeFFmpeg,
        exportService: exportService,
        tempDir: tempDir,
        timeline: timeline,
      );

      expect(filter, contains('[0:a]'));
      expect(
          filter, contains("volume=enable='between(t,1.0,3.0)':volume=0"));
      // No video filters
      expect(filter, isNot(contains('[0:v]')));
    });

    test('region blur with clamped bounds produces correct crop values',
        () async {
      // Region extends beyond video edges
      final timeline = _buildTimeline(
        videoSegments: [
          _videoSegment(
            modification: const Modification.videoRegionBlur(
              intensity: 50,
              region:
                  RegionBounds(x: 0.9, y: 0.9, width: 0.3, height: 0.3),
            ),
          ),
        ],
      );

      final filter = await _captureFilterComplex(
        fakeFFmpeg: fakeFFmpeg,
        exportService: exportService,
        tempDir: tempDir,
        timeline: timeline,
      );

      // cropX=1728, cropY=972
      // cropW = min(576, 1920-1728) = 192
      // cropH = min(324, 1080-972) = 108
      expect(filter, contains('crop=192:108:1728:972'));
    });

    test('subtitle burn-in appended after region filters', () async {
      final timeline = _buildTimeline(
        videoSegments: [
          _videoSegment(
            modification: const Modification.videoRegionBlur(
              intensity: 50,
              region:
                  RegionBounds(x: 0.1, y: 0.2, width: 0.3, height: 0.4),
            ),
          ),
        ],
      );

      final filter = await _captureFilterComplex(
        fakeFFmpeg: fakeFFmpeg,
        exportService: exportService,
        tempDir: tempDir,
        timeline: timeline,
        settings: const ExportSettings(
          subtitleMode: SubtitleExportMode.burnIn,
          subtitleFilePath: '/videos/subs.srt',
        ),
      );

      // Region chain present
      expect(filter, contains('[0:v]split=2[base0][c0]'));
      // Subtitle filter applied on region chain output [rv0]
      expect(filter, contains("[rv0]subtitles='/videos/subs.srt'"));
    });

    test('region filter uses probed video resolution', () async {
      // Use a 1280x720 resolution
      fakeFFmpeg = _CapturingFFmpegBindings(
        probeWidth: 1280,
        probeHeight: 720,
      );
      exportService = ExportService(
        ffmpeg: fakeFFmpeg,
        mediaService: MediaService(fakeFFmpeg),
      );

      final timeline = _buildTimeline(
        videoSegments: [
          _videoSegment(
            modification: const Modification.videoRegionBlur(
              intensity: 50,
              region:
                  RegionBounds(x: 0.1, y: 0.2, width: 0.3, height: 0.4),
            ),
          ),
        ],
      );

      final filter = await _captureFilterComplex(
        fakeFFmpeg: fakeFFmpeg,
        exportService: exportService,
        tempDir: tempDir,
        timeline: timeline,
      );

      // On 1280x720:
      // px=128, py=144, pw=384, ph=288
      expect(filter, contains('crop=384:288:128:144'));
      expect(filter, contains('overlay=x=128:y=144'));
    });

    test('audio beep produces sine generation and amix filter', () async {
      final timeline = _buildTimeline(
        audioSegments: [
          _audioSegment(
            modification: const Modification.audioBeep(
              frequency: 1000,
              volume: 0.5,
            ),
            start: const Duration(seconds: 2),
            end: const Duration(seconds: 5),
          ),
        ],
      );

      final filter = await _captureFilterComplex(
        fakeFFmpeg: fakeFFmpeg,
        exportService: exportService,
        tempDir: tempDir,
        timeline: timeline,
      );

      expect(filter, contains('[0:a]'));
      expect(
          filter, contains("volume=enable='between(t,2.0,5.0)':volume=0"));
      expect(filter, contains('aevalsrc=sin(1000*2*PI*t)'));
      expect(filter, contains('amix=inputs=2'));
    });

    test('full-frame region produces crop covering entire video', () async {
      final timeline = _buildTimeline(
        videoSegments: [
          _videoSegment(
            modification: const Modification.videoRegionBlur(
              intensity: 50,
              region:
                  RegionBounds(x: 0.0, y: 0.0, width: 1.0, height: 1.0),
            ),
          ),
        ],
      );

      final filter = await _captureFilterComplex(
        fakeFFmpeg: fakeFFmpeg,
        exportService: exportService,
        tempDir: tempDir,
        timeline: timeline,
      );

      expect(filter, contains('crop=1920:1080:0:0'));
      expect(filter, contains('overlay=x=0:y=0'));
    });
  });
}
