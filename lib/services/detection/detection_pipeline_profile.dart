/// Stable IDs for detection pipeline profiles.
class DetectionPipelineIds {
  DetectionPipelineIds._();

  static const vssFamilySafetyV1 = 'vss_family_safety_v1';
  static const legacyNsfwRegionV8 = 'legacy_nsfw_region_v8';
  static const audioOnly = 'audio_only';
  static const fastPreview = 'fast_preview';
}

/// User-selectable detection pipeline profile metadata.
class DetectionPipelineProfile {
  const DetectionPipelineProfile({
    required this.id,
    required this.displayName,
    required this.description,
    required this.isDefaultForNewProjects,
    required this.isImplemented,
    required this.isLegacy,
    this.fallbackPipelineId,
  });

  final String id;
  final String displayName;
  final String description;
  final bool isDefaultForNewProjects;
  final bool isImplemented;
  final bool isLegacy;
  final String? fallbackPipelineId;

  bool get canRun => isImplemented;

  static const vssFamilySafetyV1 = DetectionPipelineProfile(
    id: DetectionPipelineIds.vssFamilySafetyV1,
    displayName: 'VSS Family Safety',
    description:
        'Default local VLM-oriented family-safety pipeline. It is registered '
        'as the default development pipeline while model bundles and runtime '
        'validation are completed.',
    isDefaultForNewProjects: true,
    isImplemented: true,
    isLegacy: false,
    fallbackPipelineId: DetectionPipelineIds.legacyNsfwRegionV8,
  );

  static const legacyNsfwRegionV8 = DetectionPipelineProfile(
    id: DetectionPipelineIds.legacyNsfwRegionV8,
    displayName: 'Legacy NSFW Region',
    description: 'Legacy optional NSFW classifier, NudeNet region detector, '
        'parser-backed modesty, and profanity pipeline.',
    isDefaultForNewProjects: false,
    isImplemented: true,
    isLegacy: true,
  );

  static const audioOnly = DetectionPipelineProfile(
    id: DetectionPipelineIds.audioOnly,
    displayName: 'Audio Only',
    description: 'Audio profanity analysis without visual providers.',
    isDefaultForNewProjects: false,
    isImplemented: false,
    isLegacy: false,
    fallbackPipelineId: DetectionPipelineIds.legacyNsfwRegionV8,
  );

  static const fastPreview = DetectionPipelineProfile(
    id: DetectionPipelineIds.fastPreview,
    displayName: 'Fast Preview',
    description:
        'Lightweight preview profile for estimates before full analysis.',
    isDefaultForNewProjects: false,
    isImplemented: false,
    isLegacy: false,
    fallbackPipelineId: DetectionPipelineIds.legacyNsfwRegionV8,
  );

  static const builtInProfiles = <DetectionPipelineProfile>[
    vssFamilySafetyV1,
    legacyNsfwRegionV8,
    audioOnly,
    fastPreview,
  ];
}
