const List<String> kCanonicalNudeNetLabels = <String>[
  'FEMALE_GENITALIA_COVERED',
  'FACE_FEMALE',
  'BUTTOCKS_EXPOSED',
  'FEMALE_BREAST_EXPOSED',
  'FEMALE_GENITALIA_EXPOSED',
  'MALE_BREAST_EXPOSED',
  'ANUS_EXPOSED',
  'FEET_EXPOSED',
  'BELLY_COVERED',
  'FEET_COVERED',
  'ARMPITS_COVERED',
  'ARMPITS_EXPOSED',
  'FACE_MALE',
  'BELLY_EXPOSED',
  'MALE_GENITALIA_EXPOSED',
  'ANUS_COVERED',
  'FEMALE_BREAST_COVERED',
  'BUTTOCKS_COVERED',
];

const List<String> kDefaultNudityDetectionLabels = <String>[
  'FEMALE_BREAST_EXPOSED',
  'FEMALE_BREAST_COVERED',
  'FEMALE_GENITALIA_EXPOSED',
  'FEMALE_GENITALIA_COVERED',
  'MALE_GENITALIA_EXPOSED',
  'ANUS_EXPOSED',
  'ANUS_COVERED',
  'BUTTOCKS_EXPOSED',
  'BUTTOCKS_COVERED',
];

class NsfwRegionModelSpec {
  const NsfwRegionModelSpec({
    required this.modelId,
    required this.sourceUrl,
    required this.classLabels,
    required this.inputSize,
    required this.confidenceThreshold,
    required this.iouThreshold,
    required this.maxDetections,
    this.sha256,
    this.license,
  });

  final String modelId;
  final String sourceUrl;
  final String? sha256;
  final String? license;
  final List<String> classLabels;
  final int inputSize;
  final double confidenceThreshold;
  final double iouThreshold;
  final int maxDetections;
}

class NsfwRegionModelManifest {
  NsfwRegionModelManifest._();

  static const Map<String, String> _legacyModelAliases = <String, String>{
    'nsfw-nudenet-detector-640-community': 'nsfw-nudenet-detector-640',
  };

  static const Set<String> _allowedLicenses = <String>{
    'mit',
  };

  static const Map<String, NsfwRegionModelSpec> byModelId =
      <String, NsfwRegionModelSpec>{
        'nsfw-nudenet-detector-640': NsfwRegionModelSpec(
          modelId: 'nsfw-nudenet-detector-640',
          sourceUrl:
              'https://huggingface.co/notAI-tech/NudeNet-onnx/resolve/main/model.onnx',
          sha256: null,
          license: 'MIT',
          classLabels: kCanonicalNudeNetLabels,
          inputSize: 640,
          confidenceThreshold: 0.35,
          iouThreshold: 0.45,
          maxDetections: 100,
        ),
        'nsfw-nudenet-detector-320': NsfwRegionModelSpec(
          modelId: 'nsfw-nudenet-detector-320',
          sourceUrl:
              'https://huggingface.co/SimonJoz/nudenet/resolve/main/320n.onnx',
          sha256: null,
          license: null,
          classLabels: kCanonicalNudeNetLabels,
          inputSize: 320,
          confidenceThreshold: 0.35,
          iouThreshold: 0.45,
          maxDetections: 100,
        ),
      };

  static NsfwRegionModelSpec? findById(String id) =>
      byModelId[_legacyModelAliases[id] ?? id];

  static bool isLicenseAllowed(String? license) {
    if (license == null || license.trim().isEmpty) {
      return true;
    }
    return _allowedLicenses.contains(license.toLowerCase());
  }
}
