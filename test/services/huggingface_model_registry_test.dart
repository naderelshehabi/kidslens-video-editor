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

  test('nudenet model provides fallback download URLs', () {
    final model = registry.getModelById('nsfw-nudenet-detector-640');
    expect(model, isNotNull);

    final urls = registry.getDownloadUrlsForFile(model!, model.fileName);
    expect(urls.length, greaterThanOrEqualTo(2));
    expect(urls.first, contains('notAI-tech/NudeNet-onnx'));
    expect(urls.any((u) => u.contains('zhangsongbo365/nudenet_onnx')), isTrue);
  });

  test('nudenet 320 model exists and has fallback URLs', () {
    final model = registry.getModelById('nsfw-nudenet-detector-320');
    expect(model, isNotNull);
    expect(model!.fileName, equals('320n.onnx'));

    final urls = registry.getDownloadUrlsForFile(model, model.fileName);
    expect(urls.length, greaterThanOrEqualTo(2));
    expect(urls.first, contains('SimonJoz/nudenet'));
  });

  test('nudenet 640 community model exists and has fallback URLs', () {
    final model = registry.getModelById('nsfw-nudenet-detector-640-community');
    expect(model, isNotNull);
    expect(model!.fileName, equals('640m.onnx'));

    final urls = registry.getDownloadUrlsForFile(model, model.fileName);
    expect(urls.length, greaterThanOrEqualTo(2));
    expect(urls.first, contains('SimonJoz/nudenet'));
  });
}
