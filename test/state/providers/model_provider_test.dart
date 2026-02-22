import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kidslens_video_editor/data/models/huggingface_model.dart';
import 'package:kidslens_video_editor/state/providers/model_provider.dart';

void main() {
  test('model state defaults are empty', () {
    const state = ModelState();
    expect(state.availableModels, isEmpty);
    expect(state.downloadedModels, isEmpty);
  });

  test('selected model map supports ASR type', () {
    const state = ModelState(
      selectedModels: {HuggingFaceModelType.asr: 'whisper-small'},
    );
    expect(state.getSelectedModelId(HuggingFaceModelType.asr), 'whisper-small');
  });

  test('notifier initializes without crash', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    final state = container.read(modelNotifierProvider);
    expect(state.isLoading, isFalse);
  });
}
