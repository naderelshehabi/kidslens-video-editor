import 'package:kidslens_video_editor/data/models/visual_content_category.dart';

/// Default built-in visual content detection categories
class VisualContentDefaults {
  VisualContentDefaults._();

  /// All built-in categories
  static final List<VisualContentCategory> builtInCategories = [
    nudity,
    sexualContent,
    kissing,
    immodestDress,
  ];

  /// Nudity detection via NudeNet bounding boxes
  static const nudity = VisualContentCategory(
    id: 'nudity',
    name: 'Nudity',
    description: 'Detects exposed body parts (breasts, genitalia, buttocks)',
    detectionSource: CategoryDetectionSource.nudeNet,
    detectionLabels: [
      'FEMALE_BREAST_EXPOSED',
      'FEMALE_GENITALIA_EXPOSED',
      'MALE_GENITALIA_EXPOSED',
      'ANUS_EXPOSED',
      'BUTTOCKS_EXPOSED',
    ],
    threshold: 0.45,
    iconName: 'visibility_off',
  );

  /// Sexual content detection via both CLIP and NudeNet
  static const sexualContent = VisualContentCategory(
    id: 'sexual_content',
    name: 'Sexual Content',
    description: 'Detects explicit sexual acts and situations',
    detectionSource: CategoryDetectionSource.both,
    detectionLabels: [
      'FEMALE_BREAST_EXPOSED',
      'FEMALE_GENITALIA_EXPOSED',
      'MALE_GENITALIA_EXPOSED',
      'ANUS_EXPOSED',
      'BUTTOCKS_EXPOSED',
    ],
    clipPrompts: [
      'explicit sexual act',
      'sexual intercourse',
    ],
    clipNegativePrompts: [
      'people exercising',
      'wrestling match',
    ],
    threshold: 0.40,
    clipThreshold: 4,
    action: VisualContentAction.cutScene,
    iconName: 'block',
  );

  /// Kissing detection via CLIP zero-shot classification
  static const kissing = VisualContentCategory(
    id: 'kissing',
    name: 'Kissing',
    description: 'Detects romantic kissing scenes',
    detectionSource: CategoryDetectionSource.clip,
    clipPrompts: [
      'two people kissing',
      'romantic kiss on the lips',
    ],
    clipNegativePrompts: [
      'two people talking face to face',
      'people hugging',
    ],
    action: VisualContentAction.cutScene,
    iconName: 'favorite',
  );

  /// Immodest dress detection via CLIP zero-shot classification
  static const immodestDress = VisualContentCategory(
    id: 'immodest_dress',
    name: 'Immodest Dress',
    description: 'Detects revealing or immodest clothing',
    detectionSource: CategoryDetectionSource.clip,
    clipPrompts: [
      'woman in revealing clothing',
      'woman wearing bikini',
      'person in underwear',
    ],
    clipNegativePrompts: [
      'person wearing normal clothing',
      'person in business attire',
    ],
    clipThreshold: 2.5,
    iconName: 'checkroom',
  );
}
