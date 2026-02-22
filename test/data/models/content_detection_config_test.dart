import 'package:flutter_test/flutter_test.dart';
import 'package:kidslens_video_editor/data/models/analysis_settings.dart';
import 'package:kidslens_video_editor/data/models/content_category.dart';
import 'package:kidslens_video_editor/data/models/huggingface_model.dart';

void main() {
  const profanity = ContentCategory(
    id: 'profanity',
    name: 'Profanity',
    description: 'Audio profanity detection',
    type: CategoryType.audio,
    action: RemediationAction.beep,
    modelContributions: [
      ModelContribution(
        modelId: 'whisper-small',
        displayName: 'Whisper',
        modelType: HuggingFaceModelType.asr,
      ),
    ],
  );

  test('enabled/audio category filtering works', () {
    const config = ContentDetectionConfig(categories: [profanity]);
    expect(config.enabledCategories.length, 1);
    expect(config.enabledAudioCategories.length, 1);
    expect(config.enabledVisualCategories, isEmpty);
    expect(config.requiredModelIds, {'whisper-small'});
  });
}
