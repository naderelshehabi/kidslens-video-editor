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
    test('defaults enable audio + visual detection', () {
      final settings = AnalysisSettings.defaults();
      expect(settings.hasVisualDetection, isTrue);
      expect(settings.hasAudioDetection, isTrue);
    });

    test('videoOnly keeps visual detections enabled and disables audio', () {
      final settings = AnalysisSettings.videoOnly();
      expect(settings.hasVisualDetection, isTrue);
      expect(settings.hasAudioDetection, isFalse);
      expect(settings.hasAnyDetection, isTrue);
    });

    test('json round-trip', () {
      final original = AnalysisSettings.defaults().copyWith(
        modelConfig: const ModelConfig(asrModelId: 'whisper-small'),
      );
      final restored = AnalysisSettings.fromJson(
        jsonDecode(jsonEncode(original.toJson())) as Map<String, dynamic>,
      );
      expect(restored.modelConfig.asrModelId, 'whisper-small');
      expect(restored.hasVisualDetection, isTrue);
    });
  });
}
