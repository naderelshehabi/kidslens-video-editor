import 'package:flutter_test/flutter_test.dart';
import 'package:kidslens_video_editor/data/models/huggingface_model.dart';
import 'package:kidslens_video_editor/services/huggingface_model_registry.dart';

void main() {
  final registry = HuggingFaceModelRegistry.instance;

  test('registry is ASR-only', () {
    final all = registry.getAllModels();
    expect(all, isNotEmpty);
    expect(all.every((m) => m.modelType == HuggingFaceModelType.asr), isTrue);
    expect(registry.getVisualModels(), isEmpty);
  });

  test('recommended ASR model exists', () {
    expect(registry.getRecommendedModel(HuggingFaceModelType.asr), isNotNull);
  });
}
