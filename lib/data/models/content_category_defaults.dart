import 'package:kidslens_video_editor/data/models/content_category.dart';
import 'package:kidslens_video_editor/data/models/huggingface_model.dart';

/// Default built-in content categories for the analysis pipeline.
///
/// Each category defines sensible model contributions, thresholds, and
/// remediation actions. Users can toggle individual models on/off and
/// adjust thresholds via the Content Detection settings tab.
class ContentCategoryDefaults {
  ContentCategoryDefaults._();

  /// All built-in categories (visual + audio).
  static List<ContentCategory> get allCategories => [
        ...visualCategories,
        ...audioCategories,
      ];

  /// Visual detection categories.
  static final List<ContentCategory> visualCategories = [
    nsfw,
    violence,
    blood,
    weapons,
    nudity,
    sexualContent,
    kissing,
    immodestDress,
  ];

  /// Audio detection categories.
  static final List<ContentCategory> audioCategories = [
    profanity,
  ];

  // ─────────────────────────────────────────────────────────────────
  // Visual Categories
  // ─────────────────────────────────────────────────────────────────

  /// NSFW — explicit adult content detected by classifiers.
  static const nsfw = ContentCategory(
    id: 'nsfw',
    name: 'NSFW',
    description: 'Explicit adult content and pornography',
    type: CategoryType.visual,
    threshold: 0.6,
    action: RemediationAction.blurFullFrame,
    iconName: 'no_adult_content',
    modelContributions: [
      ModelContribution(
        modelId: 'nsfw-vit-base-quantized',
        displayName: 'NSFW ViT-Base (Quantized)',
        modelType: HuggingFaceModelType.nsfw,
      ),
      ModelContribution(
        modelId: 'nsfw-vit-base-fp16',
        displayName: 'NSFW ViT-Base (FP16)',
        modelType: HuggingFaceModelType.nsfw,
        enabled: false,
      ),
      ModelContribution(
        modelId: 'nudenet-v3-medium',
        displayName: 'NudeNet v3 (inferred from nudity)',
        modelType: HuggingFaceModelType.nudeNet,
        enabled: false,
        detectionLabels: [
          'FEMALE_BREAST_EXPOSED',
          'FEMALE_GENITALIA_EXPOSED',
          'MALE_GENITALIA_EXPOSED',
          'ANUS_EXPOSED',
          'BUTTOCKS_EXPOSED',
        ],
      ),
      ModelContribution(
        modelId: 'clip-vit-b32-vision-fp16',
        displayName: 'CLIP Zero-Shot',
        modelType: HuggingFaceModelType.clip,
        enabled: false,
        clipPrompts: ['explicit adult content', 'pornographic image'],
        clipNegativePrompts: ['safe for work image', 'family photo'],
      ),
    ],
  );

  /// Violence — fighting, assault, physical harm.
  static const violence = ContentCategory(
    id: 'violence',
    name: 'Violence',
    description: 'Violent actions, fighting, assault',
    type: CategoryType.visual,
    threshold: 0.6,
    action: RemediationAction.cutScene,
    iconName: 'sports_mma',
    modelContributions: [
      ModelContribution(
        modelId: 'violence-mobilenet',
        displayName: 'Violence Classifier',
        modelType: HuggingFaceModelType.violence,
      ),
      ModelContribution(
        modelId: 'clip-vit-b32-vision-fp16',
        displayName: 'CLIP Zero-Shot',
        modelType: HuggingFaceModelType.clip,
        enabled: false,
        clipPrompts: [
          'violent fight scene',
          'person punching',
          'physical assault',
        ],
        clipNegativePrompts: [
          'people dancing',
          'sports competition',
          'friendly hug',
        ],
      ),
    ],
  );

  /// Blood/gore — graphic injuries and blood.
  static const blood = ContentCategory(
    id: 'blood',
    name: 'Blood/Gore',
    description: 'Blood, gore, graphic injuries',
    type: CategoryType.visual,
    threshold: 0.6,
    action: RemediationAction.blurFullFrame,
    iconName: 'water_drop',
    modelContributions: [
      ModelContribution(
        modelId: 'gore-efficientnet-b2',
        displayName: 'Gore Classifier',
        modelType: HuggingFaceModelType.blood,
      ),
      ModelContribution(
        modelId: 'clip-vit-b32-vision-fp16',
        displayName: 'CLIP Zero-Shot',
        modelType: HuggingFaceModelType.clip,
        enabled: false,
        clipPrompts: ['bloody wound', 'graphic injury', 'gore'],
        clipNegativePrompts: [
          'red paint',
          'tomato sauce',
          'normal medical procedure',
        ],
      ),
    ],
  );

  /// Weapons — guns, knives, and other weapons.
  static const weapons = ContentCategory(
    id: 'weapons',
    name: 'Weapons',
    description: 'Guns, knives, and other weapons',
    type: CategoryType.visual,
    threshold: 0.6,
    action: RemediationAction.blurRegion,
    iconName: 'gpp_bad',
    supportsRegions: true,
    modelContributions: [
      ModelContribution(
        modelId: 'weapons-yolov8-small',
        displayName: 'Weapons Detector',
        modelType: HuggingFaceModelType.weapons,
      ),
      ModelContribution(
        modelId: 'clip-vit-b32-vision-fp16',
        displayName: 'CLIP Zero-Shot',
        modelType: HuggingFaceModelType.clip,
        enabled: false,
        clipPrompts: ['person holding gun', 'knife weapon', 'firearm'],
        clipNegativePrompts: [
          'toy gun',
          'kitchen knife cooking',
          'water gun',
        ],
      ),
    ],
  );

  /// Nudity — exposed body parts detected by NudeNet bounding boxes.
  static const nudity = ContentCategory(
    id: 'nudity',
    name: 'Nudity',
    description: 'Exposed body parts (breasts, genitalia, buttocks)',
    type: CategoryType.visual,
    threshold: 0.45,
    action: RemediationAction.blurRegion,
    iconName: 'visibility_off',
    supportsRegions: true,
    modelContributions: [
      ModelContribution(
        modelId: 'nudenet-v3-medium',
        displayName: 'NudeNet v3 Medium',
        modelType: HuggingFaceModelType.nudeNet,
        detectionLabels: [
          'FEMALE_BREAST_EXPOSED',
          'FEMALE_GENITALIA_EXPOSED',
          'MALE_GENITALIA_EXPOSED',
          'ANUS_EXPOSED',
          'BUTTOCKS_EXPOSED',
        ],
      ),
    ],
  );

  /// Sexual content — explicit sexual acts, detected via CLIP + NudeNet.
  static const sexualContent = ContentCategory(
    id: 'sexual_content',
    name: 'Sexual Content',
    description: 'Explicit sexual acts and situations',
    type: CategoryType.visual,
    action: RemediationAction.cutScene,
    iconName: 'block',
    supportsRegions: true,
    modelContributions: [
      ModelContribution(
        modelId: 'clip-vit-b32-vision-fp16',
        displayName: 'CLIP Scene Classification',
        modelType: HuggingFaceModelType.clip,
        clipPrompts: ['explicit sexual act', 'sexual intercourse'],
        clipNegativePrompts: ['people exercising', 'wrestling match'],
      ),
      ModelContribution(
        modelId: 'nudenet-v3-medium',
        displayName: 'NudeNet Region Detection',
        modelType: HuggingFaceModelType.nudeNet,
        detectionLabels: [
          'FEMALE_BREAST_EXPOSED',
          'FEMALE_GENITALIA_EXPOSED',
          'MALE_GENITALIA_EXPOSED',
          'ANUS_EXPOSED',
          'BUTTOCKS_EXPOSED',
        ],
      ),
    ],
  );

  /// Kissing — romantic kissing scenes, detected via CLIP zero-shot.
  static const kissing = ContentCategory(
    id: 'kissing',
    name: 'Kissing',
    description: 'Romantic kissing scenes',
    type: CategoryType.visual,
    action: RemediationAction.cutScene,
    iconName: 'favorite',
    modelContributions: [
      ModelContribution(
        modelId: 'clip-vit-b32-vision-fp16',
        displayName: 'CLIP Scene Classification',
        modelType: HuggingFaceModelType.clip,
        clipPrompts: ['two people kissing', 'romantic kiss on the lips'],
        clipNegativePrompts: [
          'two people talking face to face',
          'people hugging',
        ],
      ),
    ],
  );

  /// Immodest dress — revealing or immodest clothing, detected via CLIP.
  static const immodestDress = ContentCategory(
    id: 'immodest_dress',
    name: 'Immodest Dress',
    description: 'Revealing or immodest clothing',
    type: CategoryType.visual,
    threshold: 0.4,
    action: RemediationAction.blurFullFrame,
    iconName: 'checkroom',
    modelContributions: [
      ModelContribution(
        modelId: 'clip-vit-b32-vision-fp16',
        displayName: 'CLIP Scene Classification',
        modelType: HuggingFaceModelType.clip,
        clipPrompts: [
          'woman in revealing clothing',
          'woman wearing bikini',
          'person in underwear',
        ],
        clipNegativePrompts: [
          'person wearing normal clothing',
          'person in business attire',
        ],
      ),
    ],
  );

  // ─────────────────────────────────────────────────────────────────
  // Audio Categories
  // ─────────────────────────────────────────────────────────────────

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
