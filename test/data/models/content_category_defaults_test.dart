import 'package:flutter_test/flutter_test.dart';
import 'package:kidslens_video_editor/data/models/content_category_defaults.dart';

void main() {
  test('normalizeCategories appends missing default model contributions', () {
    final legacyNudity = ContentCategoryDefaults.nudity.copyWith(
      modelContributions: const [
        ContentCategoryDefaults.nudity.modelContributions.first,
      ],
    );

    final normalized = ContentCategoryDefaults.normalizeCategories([
      legacyNudity,
    ]);

    final nudity = normalized.firstWhere((category) => category.id == 'nudity');
    final modelIds = nudity.modelContributions.map((model) => model.modelId).toSet();

    expect(modelIds, contains('nsfw-nudenet-detector-640'));
    expect(modelIds, contains('nsfw-nudenet-detector-640-community'));
    expect(modelIds, contains('nsfw-nudenet-detector-320'));
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
}
