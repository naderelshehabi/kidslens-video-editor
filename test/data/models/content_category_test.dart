import 'package:flutter_test/flutter_test.dart';
import 'package:kidslens_video_editor/data/models/content_category.dart';
import 'package:kidslens_video_editor/data/models/huggingface_model.dart';

void main() {
  test('content category derives enabled models and required ids', () {
    const category = ContentCategory(
      id: 'profanity',
      name: 'Profanity',
      description: 'Audio profanity detection',
      type: CategoryType.audio,
      action: RemediationAction.beep,
      modelContributions: [
        ModelContribution(
          modelId: 'whisper-small',
          displayName: 'Whisper Small',
          modelType: HuggingFaceModelType.asr,
        ),
        ModelContribution(
          modelId: 'whisper-base',
          displayName: 'Whisper Base',
          modelType: HuggingFaceModelType.asr,
          enabled: false,
        ),
      ],
    );

    expect(category.isAudio, isTrue);
    expect(category.isVisual, isFalse);
    expect(category.hasEnabledModels, isTrue);
    expect(category.enabledModels.length, 1);
    expect(category.requiredModelIds, {'whisper-small'});
  });
}
