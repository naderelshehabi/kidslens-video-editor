import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:kidslens_video_editor/data/models/models.dart';
import 'package:kidslens_video_editor/services/detection/detection_pipeline_profile.dart';

void main() {
  group('AnalysisSettings pipeline selection', () {
    test('defaults to the VSS family-safety pipeline', () {
      final settings = AnalysisSettings.defaults();

      expect(
        settings.analysisPipelineId,
        DetectionPipelineIds.vssFamilySafetyV1,
      );
      expect(settings.isValid, isTrue);
    });

    test('serializes and deserializes analysisPipelineId', () {
      final settings = AnalysisSettings.defaults().copyWith(
        analysisPipelineId: DetectionPipelineIds.fastPreview,
      );

      final persistedJson =
          jsonDecode(jsonEncode(settings.toJson())) as Map<String, dynamic>;
      final restored = AnalysisSettings.fromJson(persistedJson);

      expect(restored.analysisPipelineId, DetectionPipelineIds.fastPreview);
    });

    test('restores VSS default when loading older JSON', () {
      final json = jsonDecode(jsonEncode(AnalysisSettings.defaults().toJson()))
          as Map<String, dynamic>
        ..remove('analysisPipelineId');

      final restored = AnalysisSettings.fromJson(json);

      expect(
        restored.analysisPipelineId,
        DetectionPipelineIds.vssFamilySafetyV1,
      );
    });

    test('rejects unsupported pipeline IDs', () {
      final settings = AnalysisSettings.defaults().copyWith(
        analysisPipelineId: 'community_cloud_pipeline',
      );

      expect(settings.isValid, isFalse);
      expect(
        settings.validate(),
        contains('Unsupported analysis pipeline: community_cloud_pipeline'),
      );
    });
  });

  group('AnalysisCheckpoint', () {
    test('uses the legacy pipeline version when older JSON omits it', () {
      final checkpoint = AnalysisCheckpoint.fromJson({
        'timestamp': DateTime.utc(2026, 6, 7).toIso8601String(),
      });

      expect(
        checkpoint.pipelineVersion,
        AnalysisCheckpoint.defaultPipelineVersion,
      );
    });
  });
}
