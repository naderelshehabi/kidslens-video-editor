import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:kidslens_video_editor/data/models/frame_analysis_result.dart';

void main() {
  group('DetectedRegion', () {
    group('creation', () {
      test('should create with all fields', () {
        const region = DetectedRegion(
          label: 'FEMALE_BREAST_EXPOSED',
          confidence: 0.95,
          x: 0.1,
          y: 0.2,
          width: 0.3,
          height: 0.4,
        );

        expect(region.label, equals('FEMALE_BREAST_EXPOSED'));
        expect(region.confidence, equals(0.95));
        expect(region.x, equals(0.1));
        expect(region.y, equals(0.2));
        expect(region.width, equals(0.3));
        expect(region.height, equals(0.4));
      });
    });

    group('JSON serialization', () {
      test('should serialize and deserialize', () {
        const original = DetectedRegion(
          label: 'BUTTOCKS_EXPOSED',
          confidence: 0.87,
          x: 0.15,
          y: 0.25,
          width: 0.35,
          height: 0.45,
        );

        final jsonString = jsonEncode(original.toJson());
        final restored = DetectedRegion.fromJson(
          jsonDecode(jsonString) as Map<String, dynamic>,
        );

        expect(restored.label, equals(original.label));
        expect(restored.confidence, equals(original.confidence));
        expect(restored.x, equals(original.x));
        expect(restored.y, equals(original.y));
        expect(restored.width, equals(original.width));
        expect(restored.height, equals(original.height));
      });
    });
  });

  group('VisualContentResult', () {
    group('creation', () {
      test('should create with defaults', () {
        const result = VisualContentResult();

        expect(result.detectedRegions, isEmpty);
        expect(result.clipScores, isEmpty);
      });

      test('should create safe result', () {
        final result = VisualContentResult.safe();

        expect(result.detectedRegions, isEmpty);
        expect(result.clipScores, isEmpty);
      });

      test('should create with regions and scores', () {
        const result = VisualContentResult(
          detectedRegions: [
            DetectedRegion(
              label: 'FEMALE_BREAST_EXPOSED',
              confidence: 0.9,
              x: 0.1,
              y: 0.2,
              width: 0.3,
              height: 0.4,
            ),
          ],
          clipScores: {'kissing': 5.2, 'immodest_dress': 2.1},
        );

        expect(result.detectedRegions, hasLength(1));
        expect(result.clipScores, hasLength(2));
        expect(result.clipScores['kissing'], equals(5.2));
      });
    });

    group('JSON serialization', () {
      test('should serialize and deserialize with regions', () {
        const original = VisualContentResult(
          detectedRegions: [
            DetectedRegion(
              label: 'ANUS_EXPOSED',
              confidence: 0.75,
              x: 0.3,
              y: 0.4,
              width: 0.1,
              height: 0.15,
            ),
            DetectedRegion(
              label: 'FEMALE_GENITALIA_EXPOSED',
              confidence: 0.88,
              x: 0.5,
              y: 0.6,
              width: 0.2,
              height: 0.25,
            ),
          ],
          clipScores: {'sexual_content': 7.5},
        );

        final jsonString = jsonEncode(original.toJson());
        final restored = VisualContentResult.fromJson(
          jsonDecode(jsonString) as Map<String, dynamic>,
        );

        expect(restored.detectedRegions, hasLength(2));
        expect(restored.detectedRegions[0].label, equals('ANUS_EXPOSED'));
        expect(restored.detectedRegions[1].confidence, equals(0.88));
        expect(restored.clipScores['sexual_content'], equals(7.5));
      });

      test('should serialize and deserialize empty result', () {
        const original = VisualContentResult();

        final jsonString = jsonEncode(original.toJson());
        final restored = VisualContentResult.fromJson(
          jsonDecode(jsonString) as Map<String, dynamic>,
        );

        expect(restored.detectedRegions, isEmpty);
        expect(restored.clipScores, isEmpty);
      });
    });
  });

  group('FrameAnalysisResult with visualContent', () {
    test('should create with visualContent field', () {
      const result = FrameAnalysisResult(
        frameNumber: 42,
        timestamp: Duration(seconds: 5),
        nsfw: NsfwResult(
          porn: 0.8,
          sexy: 0.1,
          hentai: 0,
          drawings: 0,
          neutral: 0.1,
        ),
        violence: ViolenceResult(violent: 0.1, nonViolent: 0.9),
        visualContent: VisualContentResult(
          detectedRegions: [
            DetectedRegion(
              label: 'FEMALE_BREAST_EXPOSED',
              confidence: 0.9,
              x: 0.1,
              y: 0.2,
              width: 0.3,
              height: 0.4,
            ),
          ],
        ),
      );

      expect(result.visualContent, isNotNull);
      expect(result.visualContent!.detectedRegions, hasLength(1));
    });

    test('safe factory should have null visualContent', () {
      final result = FrameAnalysisResult.safe(
        frameNumber: 0,
        timestamp: Duration.zero,
      );

      // visualContent can be null in safe result
      expect(result.nsfw.isSafe, isTrue);
      expect(result.violence.isSafe, isTrue);
    });

    test('should roundtrip with visualContent via JSON', () {
      const original = FrameAnalysisResult(
        frameNumber: 10,
        timestamp: Duration(milliseconds: 1500),
        nsfw: NsfwResult(
          porn: 0,
          sexy: 0,
          hentai: 0,
          drawings: 0,
          neutral: 1,
        ),
        violence: ViolenceResult(violent: 0, nonViolent: 1),
        visualContent: VisualContentResult(
          detectedRegions: [
            DetectedRegion(
              label: 'MALE_GENITALIA_EXPOSED',
              confidence: 0.6,
              x: 0.4,
              y: 0.5,
              width: 0.1,
              height: 0.15,
            ),
          ],
          clipScores: {'nudity': 4.5},
        ),
        isSceneChange: true,
      );

      final jsonString = jsonEncode(original.toJson());
      final restored = FrameAnalysisResult.fromJson(
        jsonDecode(jsonString) as Map<String, dynamic>,
      );

      expect(restored.frameNumber, equals(10));
      expect(restored.isSceneChange, isTrue);
      expect(restored.visualContent, isNotNull);
      expect(restored.visualContent!.detectedRegions, hasLength(1));
      expect(
        restored.visualContent!.detectedRegions.first.label,
        equals('MALE_GENITALIA_EXPOSED'),
      );
      expect(restored.visualContent!.clipScores['nudity'], equals(4.5));
    });
  });
}
