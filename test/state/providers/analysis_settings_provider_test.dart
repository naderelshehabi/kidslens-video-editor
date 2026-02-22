import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kidslens_video_editor/state/providers/analysis_settings_provider.dart';

void main() {
  test('defaults are ASR-focused', () {
    const state = AnalysisSettingsState();
    expect(state.asrModelId, 'whisper-small');
    expect(state.enableProfanity, isTrue);
  });

  test('provider exposes current analysis settings', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    final settings = container.read(currentAnalysisSettingsProvider);
    expect(settings.modelConfig.asrModelId, isNotEmpty);
    expect(settings.hasVisualDetection, isFalse);
  });
}
