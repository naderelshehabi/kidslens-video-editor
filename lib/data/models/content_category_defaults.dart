import 'package:kidslens_video_editor/data/models/content_category.dart';
import 'package:kidslens_video_editor/data/models/huggingface_model.dart';

/// Default built-in content categories for the analysis pipeline.
///
/// Each category defines sensible model contributions, thresholds, and
/// remediation actions. Users can toggle individual models on/off and
/// adjust thresholds via the Content Detection settings tab.
class ContentCategoryDefaults {
  ContentCategoryDefaults._();

  /// All built-in categories.
  static List<ContentCategory> get allCategories => [
        ...visualCategories,
        ...audioCategories,
      ];

  /// Visual detection categories.
  static final List<ContentCategory> visualCategories = [
    nsfw,
  ];

  /// Audio detection categories.
  static final List<ContentCategory> audioCategories = [
    profanity,
  ];

  /// NSFW visual category using canonical nsfw_model semantics.
  static const nsfw = ContentCategory(
    id: 'nsfw',
    name: 'NSFW',
    description: 'Sexual content classifier using porn/hentai/sexy signals',
    type: CategoryType.visual,
    action: RemediationAction.blurFullFrame,
    iconName: 'no_adult_content',
  );

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
