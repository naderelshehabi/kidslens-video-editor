import 'package:flutter_test/flutter_test.dart';
import 'package:kidslens_video_editor/data/models/huggingface_model.dart';
import 'package:kidslens_video_editor/services/huggingface_model_registry.dart';

void main() {
  final registry = HuggingFaceModelRegistry.instance;

  test('registry exposes ASR and NSFW models', () {
    final all = registry.getAllModels();
    expect(all, isNotEmpty);
    expect(
      all.any((m) => m.modelType == HuggingFaceModelType.asr),
      isTrue,
    );
    expect(
      all.any((m) => m.modelType == HuggingFaceModelType.nsfw),
      isTrue,
    );
    expect(registry.getVisualModels(), isNotEmpty);
  });

  test('recommended ASR model exists', () {
    expect(registry.getRecommendedModel(HuggingFaceModelType.asr), isNotNull);
  });

  test('recommended NSFW model exists', () {
    expect(registry.getRecommendedModel(HuggingFaceModelType.nsfw), isNotNull);
  });
}
