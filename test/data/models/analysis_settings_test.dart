import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:kidslens_video_editor/data/models/analysis_settings.dart';

void main() {
  group('ModelConfig', () {
    test('defaults are ASR-only aligned', () {
      final config = ModelConfig.defaults();
      expect(config.asrModelId, 'whisper-base');
      expect(config.asrLanguage, 'en');
    });

    test('json round-trip', () {
      const original = ModelConfig(asrModelId: 'whisper-small');
      final restored = ModelConfig.fromJson(
        jsonDecode(jsonEncode(original.toJson())) as Map<String, dynamic>,
      );
      expect(restored, original);
    });
  });

  group('AnalysisSettings', () {
    test('defaults are audio-focused', () {
      final settings = AnalysisSettings.defaults();
      expect(settings.hasVisualDetection, isFalse);
      expect(settings.hasAudioDetection, isTrue);
    });

    test('videoOnly disables all detections', () {
      final settings = AnalysisSettings.videoOnly();
      expect(settings.hasAnyDetection, isFalse);
    });

    test('json round-trip', () {
      final original = AnalysisSettings.defaults().copyWith(
        modelConfig: const ModelConfig(asrModelId: 'whisper-small'),
      );
      final restored = AnalysisSettings.fromJson(
        jsonDecode(jsonEncode(original.toJson())) as Map<String, dynamic>,
      );
      expect(restored.modelConfig.asrModelId, 'whisper-small');
      expect(restored.hasVisualDetection, isFalse);
    });
  });
}
