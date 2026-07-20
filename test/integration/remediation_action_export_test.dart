import 'package:flutter_test/flutter_test.dart';
import 'package:kidslens_video_editor/data/models/content_category.dart';
import 'package:kidslens_video_editor/data/models/modification.dart';
import 'package:kidslens_video_editor/services/export_service.dart';

void main() {
  const testRegion = RegionBounds(
    x: 0.1,
    y: 0.2,
    width: 0.3,
    height: 0.4,
  );

  const testStart = Duration(seconds: 10);
  const testEnd = Duration(seconds: 15);

  group('ExportService.modificationFromRemediationAction', () {
    // ─────────────────────────────────────────────────────────────
    // Full-frame / scene-level actions (no region required)
    // ─────────────────────────────────────────────────────────────

    test('blurFullFrame produces Modification.videoBlur', () {
      final mod = ExportService.modificationFromRemediationAction(
        action: RemediationAction.blurFullFrame,
        startTime: testStart,
        endTime: testEnd,
      );

      expect(mod, isA<VideoBlur>());
      expect(mod.isVideoModification, true);
      expect(mod.isRegionModification, false);
    });

    test('cutScene produces Modification.videoSkip', () {
      final mod = ExportService.modificationFromRemediationAction(
        action: RemediationAction.cutScene,
        startTime: testStart,
        endTime: testEnd,
      );

      expect(mod, isA<VideoSkip>());
      expect(mod.isVideoModification, true);
      expect(mod.isDestructive, true);
    });

    test('mute produces Modification.audioMute', () {
      final mod = ExportService.modificationFromRemediationAction(
        action: RemediationAction.mute,
        startTime: testStart,
        endTime: testEnd,
      );

      expect(mod, isA<AudioMute>());
      expect(mod.isAudioModification, true);
      expect(mod.isDestructive, true);
    });

    test('beep produces Modification.audioBeep', () {
      final mod = ExportService.modificationFromRemediationAction(
        action: RemediationAction.beep,
        startTime: testStart,
        endTime: testEnd,
      );

      expect(mod, isA<AudioBeep>());
      expect(mod.isAudioModification, true);
      expect(mod.isDestructive, false);
    });

    // ─────────────────────────────────────────────────────────────
    // Region-level actions (region required)
    // ─────────────────────────────────────────────────────────────

    test('blurRegion with region produces Modification.videoRegionBlur', () {
      final mod = ExportService.modificationFromRemediationAction(
        action: RemediationAction.blurRegion,
        startTime: testStart,
        endTime: testEnd,
        region: testRegion,
      );

      expect(mod, isA<VideoRegionBlur>());
      expect(mod.isRegionModification, true);
      final regionBlur = mod as VideoRegionBlur;
      expect(regionBlur.region.x, testRegion.x);
      expect(regionBlur.region.y, testRegion.y);
      expect(regionBlur.region.width, testRegion.width);
      expect(regionBlur.region.height, testRegion.height);
    });

    test('pixelateRegion with region produces Modification.videoRegionPixelate',
        () {
      final mod = ExportService.modificationFromRemediationAction(
        action: RemediationAction.pixelateRegion,
        startTime: testStart,
        endTime: testEnd,
        region: testRegion,
      );

      expect(mod, isA<VideoRegionPixelate>());
      expect(mod.isRegionModification, true);
      final regionPixelate = mod as VideoRegionPixelate;
      expect(regionPixelate.region.x, testRegion.x);
      expect(regionPixelate.region.y, testRegion.y);
    });

    test('blackBoxRegion with region produces Modification.videoRegionBlackBox',
        () {
      final mod = ExportService.modificationFromRemediationAction(
        action: RemediationAction.blackBoxRegion,
        startTime: testStart,
        endTime: testEnd,
        region: testRegion,
      );

      expect(mod, isA<VideoRegionBlackBox>());
      expect(mod.isRegionModification, true);
      final regionBlackBox = mod as VideoRegionBlackBox;
      expect(regionBlackBox.region.x, testRegion.x);
      expect(regionBlackBox.region.y, testRegion.y);
    });

    // ─────────────────────────────────────────────────────────────
    // Error cases: region required but missing
    // ─────────────────────────────────────────────────────────────

    test('blurRegion without region throws ArgumentError', () {
      expect(
        () => ExportService.modificationFromRemediationAction(
          action: RemediationAction.blurRegion,
          startTime: testStart,
          endTime: testEnd,
        ),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('pixelateRegion without region throws ArgumentError', () {
      expect(
        () => ExportService.modificationFromRemediationAction(
          action: RemediationAction.pixelateRegion,
          startTime: testStart,
          endTime: testEnd,
        ),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('blackBoxRegion without region throws ArgumentError', () {
      expect(
        () => ExportService.modificationFromRemediationAction(
          action: RemediationAction.blackBoxRegion,
          startTime: testStart,
          endTime: testEnd,
        ),
        throwsA(isA<ArgumentError>()),
      );
    });

    // ─────────────────────────────────────────────────────────────
    // Non-region actions with superfluous region (should still work)
    // ─────────────────────────────────────────────────────────────

    test('blurFullFrame ignores optional region parameter', () {
      final mod = ExportService.modificationFromRemediationAction(
        action: RemediationAction.blurFullFrame,
        startTime: testStart,
        endTime: testEnd,
        region: testRegion,
      );

      expect(mod, isA<VideoBlur>());
      expect(mod.isRegionModification, false);
    });

    test('cutScene ignores optional region parameter', () {
      final mod = ExportService.modificationFromRemediationAction(
        action: RemediationAction.cutScene,
        startTime: testStart,
        endTime: testEnd,
        region: testRegion,
      );

      expect(mod, isA<VideoSkip>());
    });

    test('mute ignores optional region parameter', () {
      final mod = ExportService.modificationFromRemediationAction(
        action: RemediationAction.mute,
        startTime: testStart,
        endTime: testEnd,
        region: testRegion,
      );

      expect(mod, isA<AudioMute>());
    });

    test('beep ignores optional region parameter', () {
      final mod = ExportService.modificationFromRemediationAction(
        action: RemediationAction.beep,
        startTime: testStart,
        endTime: testEnd,
        region: testRegion,
      );

      expect(mod, isA<AudioBeep>());
    });
  });

  group('RemediationAction → Modification property consistency', () {
    test('visual RemediationActions produce video Modifications', () {
      final visualActions = [
        RemediationAction.blurRegion,
        RemediationAction.pixelateRegion,
        RemediationAction.blackBoxRegion,
        RemediationAction.blurFullFrame,
        RemediationAction.cutScene,
      ];

      for (final action in visualActions) {
        final needsRegion = action.isRegionLevel;
        final mod = ExportService.modificationFromRemediationAction(
          action: action,
          startTime: testStart,
          endTime: testEnd,
          region: needsRegion ? testRegion : null,
        );

        expect(
          mod.isVideoModification,
          true,
          reason: '${action.name} should produce a video modification',
        );
        expect(
          action.isVisual,
          true,
          reason: '${action.name} should be a visual action',
        );
      }
    });

    test('audio RemediationActions produce audio Modifications', () {
      final audioActions = [
        RemediationAction.mute,
        RemediationAction.beep,
      ];

      for (final action in audioActions) {
        final mod = ExportService.modificationFromRemediationAction(
          action: action,
          startTime: testStart,
          endTime: testEnd,
        );

        expect(
          mod.isAudioModification,
          true,
          reason: '${action.name} should produce an audio modification',
        );
        expect(
          action.isAudio,
          true,
          reason: '${action.name} should be an audio action',
        );
      }
    });

    test('region-level actions produce region Modifications', () {
      final regionActions = [
        RemediationAction.blurRegion,
        RemediationAction.pixelateRegion,
        RemediationAction.blackBoxRegion,
      ];

      for (final action in regionActions) {
        final mod = ExportService.modificationFromRemediationAction(
          action: action,
          startTime: testStart,
          endTime: testEnd,
          region: testRegion,
        );

        expect(
          action.isRegionLevel,
          true,
          reason: '${action.name} should be region-level',
        );
        expect(
          mod.isRegionModification,
          true,
          reason: '${action.name} should produce a region modification',
        );
      }
    });
  });

  group('Modification FFmpeg filter generation', () {
    test('all 7 RemediationActions produce valid Modifications with filters',
        () {
      const allActions = RemediationAction.values;
      expect(allActions.length, 7);

      for (final action in allActions) {
        final needsRegion = action.isRegionLevel;
        final mod = ExportService.modificationFromRemediationAction(
          action: action,
          startTime: testStart,
          endTime: testEnd,
          region: needsRegion ? testRegion : null,
        );

        // Every modification should have a non-null filter string
        // (region-based filters return '' since they use a separate chain)
        final filter = mod.toFFmpegFilter();
        expect(
          filter,
          isA<String>(),
          reason: '${action.name} should produce a filter string',
        );

        if (!mod.isRegionModification) {
          expect(
            filter.isNotEmpty,
            true,
            reason: '${action.name} non-region filter should be non-empty',
          );
        }
      }
    });

    test('videoBlur produces boxblur filter', () {
      final mod = ExportService.modificationFromRemediationAction(
        action: RemediationAction.blurFullFrame,
        startTime: testStart,
        endTime: testEnd,
      );

      expect(mod.toFFmpegFilter(), contains('boxblur'));
    });

    test('audioMute produces volume=0 filter', () {
      final mod = ExportService.modificationFromRemediationAction(
        action: RemediationAction.mute,
        startTime: testStart,
        endTime: testEnd,
      );

      expect(mod.toFFmpegFilter(), 'volume=0');
    });

    test('audioBeep produces sine wave filter', () {
      final mod = ExportService.modificationFromRemediationAction(
        action: RemediationAction.beep,
        startTime: testStart,
        endTime: testEnd,
      );

      expect(mod.toFFmpegFilter(), contains('sine'));
      expect(mod.toFFmpegFilter(), contains('frequency=1000'));
    });

    test('videoSkip produces select=0 filter', () {
      final mod = ExportService.modificationFromRemediationAction(
        action: RemediationAction.cutScene,
        startTime: testStart,
        endTime: testEnd,
      );

      expect(mod.toFFmpegFilter(), 'select=0');
    });
  });
}
