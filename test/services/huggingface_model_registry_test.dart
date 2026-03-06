import 'package:flutter_test/flutter_test.dart';
import 'package:kidslens_video_editor/data/models/huggingface_model.dart';
import 'package:kidslens_video_editor/services/huggingface_model_registry.dart';

void main() {
  final registry = HuggingFaceModelRegistry.instance;

  test('registry exposes ASR, NSFW, parser, and gender helper models', () {
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
    expect(
      all.any((m) => m.modelType == HuggingFaceModelType.parser),
      isTrue,
    );
    expect(
      all.any((m) => m.modelType == HuggingFaceModelType.genderHelper),
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

  test('nsfw type list excludes NudeNet detectors', () {
    final models = registry.getModelsByType(HuggingFaceModelType.nsfw);

    expect(models, isNotEmpty);
    expect(models.any((model) => model.id.contains('nudenet')), isFalse);
  });

  test('nudenet detector list contains canonical models only', () {
    final detectorIds = registry.getNudeNetModels().map((model) => model.id).toSet();

    expect(detectorIds, contains('nsfw-nudenet-detector-640'));
    expect(detectorIds, contains('nsfw-nudenet-detector-320'));
    expect(detectorIds, isNot(contains('nsfw-nudenet-detector-640-community')));
  });

  test('recommended parser and gender helper models exist', () {
    expect(registry.getRecommendedModel(HuggingFaceModelType.parser), isNotNull);
    expect(
      registry.getRecommendedModel(HuggingFaceModelType.genderHelper),
      isNotNull,
    );
  });

  test('parser and gender helper models use ONNX assets', () {
    final parserModel = registry.getModelById('modesty-parser-birefnet-clothes');
    final genderModel =
        registry.getModelById('gender-classification-onnx-community');

    expect(parserModel, isNotNull);
    expect(genderModel, isNotNull);
    expect(parserModel!.fileName, endsWith('.onnx'));
    expect(genderModel!.fileName, endsWith('.onnx'));
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

  test('legacy community NudeNet id resolves to canonical 640 model', () {
    final model = registry.getModelById('nsfw-nudenet-detector-640-community');
    expect(model, isNotNull);
    expect(model!.id, equals('nsfw-nudenet-detector-640'));

    final urls = registry.getDownloadUrlsForFile(model, model.fileName);
    expect(urls.length, greaterThanOrEqualTo(2));
    expect(urls.first, contains('notAI-tech/NudeNet-onnx'));
  });
}
