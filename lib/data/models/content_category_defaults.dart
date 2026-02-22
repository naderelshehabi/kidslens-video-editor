import 'package:kidslens_video_editor/data/models/content_category.dart';
import 'package:kidslens_video_editor/data/models/huggingface_model.dart';

/// Default built-in content categories for the analysis pipeline.
///
/// Each category defines sensible model contributions, thresholds, and
/// remediation actions. Users can toggle individual models on/off and
/// adjust thresholds via the Content Detection settings tab.
class ContentCategoryDefaults {
  ContentCategoryDefaults._();

  /// All built-in categories (audio only).
  static List<ContentCategory> get allCategories => [
        ...audioCategories,
      ];

  /// Visual detection categories are removed in ASR-only mode.
  static final List<ContentCategory> visualCategories = [];

  /// Audio detection categories.
  static final List<ContentCategory> audioCategories = [
    profanity,
  ];

  /// Profanity — swear words and offensive language in the audio track.
  static const profanity = ContentCategory(
    id: 'profanity',
    name: 'Profanity',
    description: 'Swear words and offensive language',
    type: CategoryType.audio,
    threshold: 0.8,
    action: RemediationAction.beep,
    iconName: 'volume_off',
    modelContributions: [
      ModelContribution(
        modelId: 'whisper-small',
        displayName: 'Whisper Transcription + Word Match',
        modelType: HuggingFaceModelType.asr,
      ),
    ],
  );
}
