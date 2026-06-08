import 'package:flutter_test/flutter_test.dart';
import 'package:kidslens_video_editor/data/models/huggingface_model.dart';
import 'package:kidslens_video_editor/data/models/content_category_defaults.dart';

void main() {
  test('normalizeCategories appends missing default model contributions', () {
    final legacyNudity = ContentCategoryDefaults.nudity.copyWith(
      modelContributions: [
        ContentCategoryDefaults.nudity.modelContributions.first,
      ],
    );

    final normalized = ContentCategoryDefaults.normalizeCategories([
      legacyNudity,
    ]);

    final nudity = normalized.firstWhere((category) => category.id == 'nudity');
    final modelIds =
        nudity.modelContributions.map((model) => model.modelId).toSet();

    expect(modelIds, contains('nsfw-nudenet-detector-640'));
    expect(modelIds, contains('nsfw-nudenet-detector-320'));
    expect(modelIds, isNot(contains('nsfw-nudenet-detector-640-community')));
  });

  test('normalizeCategories preserves existing model enablement', () {
    final legacyNudity = ContentCategoryDefaults.nudity.copyWith(
      modelContributions: [
        ContentCategoryDefaults.nudity.modelContributions.first
            .copyWith(enabled: false),
      ],
    );

    final normalized = ContentCategoryDefaults.normalizeCategories([
      legacyNudity,
    ]);

    final nudity = normalized.firstWhere((category) => category.id == 'nudity');
    final detector640 = nudity.modelContributions.firstWhere(
      (model) => model.modelId == 'nsfw-nudenet-detector-640',
    );

    expect(detector640.enabled, isFalse);
  });

  test('normalizeCategories collapses legacy community detector ids', () {
    final legacyNudity = ContentCategoryDefaults.nudity.copyWith(
      modelContributions: [
        ContentCategoryDefaults.nudity.modelContributions.first.copyWith(
          modelId: 'nsfw-nudenet-detector-640-community',
          displayName: 'NudeNet Detector 640m (Community)',
          enabled: true,
        ),
      ],
    );

    final normalized =
        ContentCategoryDefaults.normalizeCategories([legacyNudity]);
    final nudity = normalized.firstWhere((category) => category.id == 'nudity');
    final detector640 = nudity.modelContributions.firstWhere(
      (model) => model.modelId == 'nsfw-nudenet-detector-640',
    );

    expect(
      nudity.modelContributions.any(
        (model) => model.modelId == 'nsfw-nudenet-detector-640-community',
      ),
      isFalse,
    );
    expect(detector640.enabled, isTrue);
  });

  test('normalizeCategories appends new modesty policy categories', () {
    final normalized = ContentCategoryDefaults.normalizeCategories([
      ContentCategoryDefaults.nsfw,
      ContentCategoryDefaults.nudity,
      ContentCategoryDefaults.profanity,
    ]);

    final ids = normalized.map((category) => category.id).toSet();

    expect(ids, contains('female_chest_exposure'));
    expect(ids, contains('female_abdomen_exposure'));
    expect(ids, contains('female_arms_exposure'));
    expect(ids, contains('female_legs_exposure'));
    expect(ids, contains('male_buttocks_exposure'));
    expect(ids, contains('male_genitals_exposure'));
  });

  test('parser-backed modesty defaults use the parser model type', () {
    final armsContribution =
        ContentCategoryDefaults.femaleArmsExposure.modelContributions.single;
    final legsContribution =
        ContentCategoryDefaults.femaleLegsExposure.modelContributions.single;

    expect(armsContribution.modelType, HuggingFaceModelType.parser);
    expect(legsContribution.modelType, HuggingFaceModelType.parser);
  });
}
