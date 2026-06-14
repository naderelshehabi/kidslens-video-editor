import 'package:kidslens_video_editor/data/models/family_safety_policy.dart';

enum ModelBundleRole {
  vlm,
  grounding,
  embedding,
}

enum ModelBundleApprovalStatus {
  productionApproved,
  evaluationOnly,
  watchlist,
  blocked,
}

enum ModelBundleArtifactType {
  officialWeights,
  officialOnnx,
  internalQuantizedArtifact,
  disabledReference,
}

enum ModelBundleRuntime {
  cudaVllm,
  cudaTransformersHelper,
  cudaTensorRt,
  directmlOnnx,
  cpuLightweight,
  notYetValidated,
}

enum ModelBundleLicense {
  apache20,
  mit,
  nvidiaOpenModelLicense,
  llama4Community,
  nonCommercial,
  reviewRequired,
}

enum CommercialUseStatus {
  allowed,
  allowedWithTerms,
  reviewRequired,
  blocked,
}

enum ModelBundleQuantization {
  bf16,
  fp8,
  nvfp4,
  int4,
  onnxFp16,
  none,
}

class ModelBundleManifest {
  const ModelBundleManifest({
    required this.modelId,
    required this.displayName,
    required this.vendor,
    required this.officialSourceRepo,
    required this.officialRevision,
    required this.license,
    required this.commercialUse,
    required this.acceptedTermsRequired,
    required this.artifactType,
    required this.artifactUri,
    required this.sha256,
    required this.conversionRecipeId,
    required this.runtime,
    required this.minVramGb,
    required this.recommendedVramGb,
    required this.targetGpuClass,
    required this.maxValidatedVramGb,
    required this.quantization,
    required this.fitsRtx5070Validated,
    required this.supportsVideoInput,
    required this.supportsImageInput,
    required this.supportsBoundingBoxes,
    required this.supportsMasks,
    required this.supportsPointLocalization,
    required this.maxFramesPerChunk,
    required this.maxContextTokens,
    required this.recommendedChunkSeconds,
    required this.knownFailureModes,
    required this.roles,
    required this.approvalStatus,
    required this.reviewNotes,
    this.leaderboardSourcesReviewed = const <String>[],
    this.scorecard,
  });

  final String modelId;
  final String displayName;
  final String vendor;
  final String officialSourceRepo;
  final String officialRevision;
  final ModelBundleLicense license;
  final CommercialUseStatus commercialUse;
  final bool acceptedTermsRequired;
  final ModelBundleArtifactType artifactType;
  final String artifactUri;
  final String? sha256;
  final String? conversionRecipeId;
  final ModelBundleRuntime runtime;
  final double minVramGb;
  final double recommendedVramGb;
  final String targetGpuClass;
  final double maxValidatedVramGb;
  final ModelBundleQuantization quantization;
  final bool fitsRtx5070Validated;
  final bool supportsVideoInput;
  final bool supportsImageInput;
  final bool supportsBoundingBoxes;
  final bool supportsMasks;
  final bool supportsPointLocalization;
  final int maxFramesPerChunk;
  final int maxContextTokens;
  final int recommendedChunkSeconds;
  final List<String> knownFailureModes;
  final List<ModelBundleRole> roles;
  final ModelBundleApprovalStatus approvalStatus;
  final String reviewNotes;
  final List<String> leaderboardSourcesReviewed;
  final KidsLensModelScorecard? scorecard;

  String get officialOrganization => officialSourceRepo.split('/').first;

  bool get isProductionSelectable =>
      approvalStatus == ModelBundleApprovalStatus.productionApproved;

  List<String> validateForCatalog() {
    final issues = <String>[];
    _validateRequiredFields(issues);
    _validateOfficialSource(issues);
    _validateRuntime(issues);
    _validateArtifactUri(issues);
    _validateCapabilities(issues);
    _validateVram(issues);

    if (license == ModelBundleLicense.reviewRequired &&
        approvalStatus != ModelBundleApprovalStatus.watchlist &&
        approvalStatus != ModelBundleApprovalStatus.blocked) {
      issues.add('license review must be completed');
    }
    if (license == ModelBundleLicense.nonCommercial &&
        approvalStatus != ModelBundleApprovalStatus.blocked) {
      issues.add('non-commercial models must be marked blocked');
    }
    if (commercialUse == CommercialUseStatus.blocked &&
        approvalStatus != ModelBundleApprovalStatus.blocked) {
      issues.add('commercially blocked models must be marked blocked');
    }
    if (approvalStatus == ModelBundleApprovalStatus.productionApproved) {
      issues.addAll(validateForProductionSelection());
    }

    return issues.toSet().toList();
  }

  List<String> validateForProductionSelection() {
    final issues = <String>[];
    _validateRequiredFields(issues);
    _validateOfficialSource(issues);
    _validateRuntime(issues);
    _validateArtifactUri(issues);
    _validateCapabilities(issues);
    _validateVram(issues);

    if (approvalStatus != ModelBundleApprovalStatus.productionApproved) {
      issues.add('model is not production approved');
    }
    if (!_hasValidSha256) {
      issues.add('sha256 must be a 64-character lowercase hex digest');
    }
    if (commercialUse != CommercialUseStatus.allowed &&
        commercialUse != CommercialUseStatus.allowedWithTerms) {
      issues.add('commercial use is not approved');
    }
    if (acceptedTermsRequired &&
        commercialUse != CommercialUseStatus.allowedWithTerms) {
      issues.add('terms-gated models require allowedWithTerms status');
    }
    if (!fitsRtx5070Validated) {
      issues.add('RTX 5070 12 GB validation is required');
    }
    if (runtime == ModelBundleRuntime.notYetValidated) {
      issues.add('runtime must be validated before production selection');
    }
    if (artifactType == ModelBundleArtifactType.disabledReference) {
      issues.add('disabled reference artifacts are not production selectable');
    }

    return issues.toSet().toList();
  }

  bool get _hasValidSha256 =>
      sha256 != null && RegExp(r'^[a-f0-9]{64}$').hasMatch(sha256 ?? '');

  void _validateRequiredFields(List<String> issues) {
    final requiredStrings = <String, String>{
      'modelId': modelId,
      'displayName': displayName,
      'vendor': vendor,
      'officialSourceRepo': officialSourceRepo,
      'officialRevision': officialRevision,
      'artifactUri': artifactUri,
      'targetGpuClass': targetGpuClass,
      'reviewNotes': reviewNotes,
    };

    for (final entry in requiredStrings.entries) {
      if (entry.value.trim().isEmpty) {
        issues.add('${entry.key} is required');
      }
    }
    if (roles.isEmpty) {
      issues.add('at least one role is required');
    }
    if (knownFailureModes.isEmpty) {
      issues.add('knownFailureModes must be documented');
    }
  }

  void _validateOfficialSource(List<String> issues) {
    if (!officialSourceRepo.contains('/')) {
      issues.add('officialSourceRepo must be an owner/repo identifier');
      return;
    }
    if (!ModelSourceGovernance.isAcceptedOfficialOrganization(
      officialOrganization,
    )) {
      issues.add('official source organization is not approved');
    }
  }

  void _validateRuntime(List<String> issues) {
    if (runtime == ModelBundleRuntime.cpuLightweight && minVramGb > 0) {
      issues.add('CPU-only runtime cannot require VRAM');
    }
  }

  void _validateArtifactUri(List<String> issues) {
    final uri = Uri.tryParse(artifactUri);
    if (uri == null || !uri.hasScheme) {
      issues.add('artifactUri must include a scheme');
      return;
    }

    final allowedSchemes = <String>{'hf', 'file', 'kidslens-model'};
    if (!allowedSchemes.contains(uri.scheme)) {
      issues.add('artifactUri must be a local/downloadable model artifact URI');
    }
    if (uri.scheme == 'hf' && uri.host.isEmpty) {
      issues.add('hf artifactUri must include an owner/repo host');
    }
    if (uri.scheme == 'file' && uri.path.trim().isEmpty) {
      issues.add('file artifactUri must include a path');
    }
  }

  void _validateCapabilities(List<String> issues) {
    final requiresVisualInput = roles.any(
      (role) =>
          role == ModelBundleRole.vlm || role == ModelBundleRole.grounding,
    );
    if (requiresVisualInput && !supportsVideoInput && !supportsImageInput) {
      issues.add('model must support image or video input');
    }
    if (roles.contains(ModelBundleRole.grounding) &&
        !supportsBoundingBoxes &&
        !supportsMasks &&
        !supportsPointLocalization) {
      issues.add('grounding models must expose a localizable output');
    }
    if (maxFramesPerChunk < 1) {
      issues.add('maxFramesPerChunk must be positive');
    }
    if (maxContextTokens < 1) {
      issues.add('maxContextTokens must be positive');
    }
    if (recommendedChunkSeconds < 1) {
      issues.add('recommendedChunkSeconds must be positive');
    }
  }

  void _validateVram(List<String> issues) {
    if (minVramGb < 0 || recommendedVramGb < 0 || maxValidatedVramGb < 0) {
      issues.add('VRAM fields cannot be negative');
    }
    if (recommendedVramGb < minVramGb) {
      issues.add('recommendedVramGb cannot be lower than minVramGb');
    }
    if (targetGpuClass == ModelBundleCatalog.targetGpuClass &&
        maxValidatedVramGb > ModelBundleCatalog.targetGpuVramGb) {
      issues.add('maxValidatedVramGb exceeds RTX 5070 target budget');
    }
  }
}

class KidsLensModelScorecard {
  const KidsLensModelScorecard({
    required this.familySafetyRecall,
    required this.falsePositiveBurden,
    required this.temporalLocalizationQuality,
    required this.boxMaskQuality,
    required this.explanationQuality,
    required this.localGpuThroughput,
    required this.vramFit,
    required this.windowsRuntimeReadiness,
    required this.licenseTermsFit,
    required this.notes,
  });

  final int familySafetyRecall;
  final int falsePositiveBurden;
  final int temporalLocalizationQuality;
  final int boxMaskQuality;
  final int explanationQuality;
  final int localGpuThroughput;
  final int vramFit;
  final int windowsRuntimeReadiness;
  final int licenseTermsFit;
  final String notes;

  List<String> validate() {
    final issues = <String>[];
    final scores = <String, int>{
      'familySafetyRecall': familySafetyRecall,
      'falsePositiveBurden': falsePositiveBurden,
      'temporalLocalizationQuality': temporalLocalizationQuality,
      'boxMaskQuality': boxMaskQuality,
      'explanationQuality': explanationQuality,
      'localGpuThroughput': localGpuThroughput,
      'vramFit': vramFit,
      'windowsRuntimeReadiness': windowsRuntimeReadiness,
      'licenseTermsFit': licenseTermsFit,
    };

    for (final entry in scores.entries) {
      if (entry.value < 0 || entry.value > 5) {
        issues.add('${entry.key} must be between 0 and 5');
      }
    }
    if (notes.trim().isEmpty) {
      issues.add('scorecard notes are required');
    }
    return issues;
  }
}

class ModelBundleCatalog {
  ModelBundleCatalog._();

  static const targetGpuClass = 'rtx_5070_12gb';
  static const targetGpuVramGb = 12.0;

  static const reviewedLeaderboardSources = <String>[
    'Open VLM Leaderboard',
    'Vision Arena',
    'MMBench Leaderboard',
    'SEED-Bench Leaderboard',
    'retrieval/document leaderboards',
  ];

  static const initialCandidates = <ModelBundleManifest>[
    ModelBundleManifest(
      modelId: 'nvidia_cosmos_reason1_7b',
      displayName: 'NVIDIA Cosmos Reason1 7B',
      vendor: 'NVIDIA',
      officialSourceRepo: 'nvidia/Cosmos-Reason1-7B',
      officialRevision: 'main',
      license: ModelBundleLicense.nvidiaOpenModelLicense,
      commercialUse: CommercialUseStatus.allowed,
      acceptedTermsRequired: false,
      artifactType: ModelBundleArtifactType.officialWeights,
      artifactUri: 'hf://nvidia/Cosmos-Reason1-7B',
      sha256: null,
      conversionRecipeId: null,
      runtime: ModelBundleRuntime.cudaVllm,
      minVramGb: 10,
      recommendedVramGb: 12,
      targetGpuClass: targetGpuClass,
      maxValidatedVramGb: 12,
      quantization: ModelBundleQuantization.bf16,
      fitsRtx5070Validated: false,
      supportsVideoInput: true,
      supportsImageInput: true,
      supportsBoundingBoxes: false,
      supportsMasks: false,
      supportsPointLocalization: false,
      maxFramesPerChunk: 32,
      maxContextTokens: 32768,
      recommendedChunkSeconds: 8,
      knownFailureModes: <String>[
        'Superseded by Cosmos Reason2 8B for future evaluation.',
        'BF16 fit on RTX 5070 requires validation and may need reduced frames.',
        'No native box output; requires grounding fallback.',
        'Windows runtime path is not vendor-validated.',
      ],
      roles: <ModelBundleRole>[ModelBundleRole.vlm],
      approvalStatus: ModelBundleApprovalStatus.evaluationOnly,
      reviewNotes:
          'Official NVIDIA VLM, commercially usable, but superseded by Cosmos Reason2 8B for future evaluation.',
      leaderboardSourcesReviewed: reviewedLeaderboardSources,
    ),
    ModelBundleManifest(
      modelId: 'nvidia_cosmos_reason2_8b',
      displayName: 'NVIDIA Cosmos Reason2 8B',
      vendor: 'NVIDIA',
      officialSourceRepo: 'nvidia/Cosmos-Reason2-8B',
      officialRevision: 'main',
      license: ModelBundleLicense.nvidiaOpenModelLicense,
      commercialUse: CommercialUseStatus.allowed,
      acceptedTermsRequired: false,
      artifactType: ModelBundleArtifactType.officialWeights,
      artifactUri: 'hf://nvidia/Cosmos-Reason2-8B',
      sha256: null,
      conversionRecipeId: null,
      runtime: ModelBundleRuntime.notYetValidated,
      minVramGb: 12,
      recommendedVramGb: 12,
      targetGpuClass: targetGpuClass,
      maxValidatedVramGb: 12,
      quantization: ModelBundleQuantization.bf16,
      fitsRtx5070Validated: false,
      supportsVideoInput: true,
      supportsImageInput: true,
      supportsBoundingBoxes: false,
      supportsMasks: false,
      supportsPointLocalization: false,
      maxFramesPerChunk: 16,
      maxContextTokens: 32768,
      recommendedChunkSeconds: 8,
      knownFailureModes: <String>[
        'No official quantized artifact is validated for the 12 GB target.',
        'Requires a KidsLens-owned quantized artifact before RTX 5070 evaluation.',
        'Runtime support must be validated before production selection.',
      ],
      roles: <ModelBundleRole>[ModelBundleRole.vlm],
      approvalStatus: ModelBundleApprovalStatus.watchlist,
      reviewNotes:
          'Cosmos Reason2 supersedes Reason1 for future NVIDIA VLM evaluation, but no official <=12 GB quantized artifact is available.',
      leaderboardSourcesReviewed: reviewedLeaderboardSources,
    ),
    ModelBundleManifest(
      modelId: 'nvidia_nemotron_nano_12b_v2_vl_fp8',
      displayName: 'NVIDIA Nemotron Nano 12B v2 VL FP8',
      vendor: 'NVIDIA',
      officialSourceRepo: 'nvidia/NVIDIA-Nemotron-Nano-12B-v2-VL-FP8',
      officialRevision: 'main',
      license: ModelBundleLicense.nvidiaOpenModelLicense,
      commercialUse: CommercialUseStatus.allowed,
      acceptedTermsRequired: false,
      artifactType: ModelBundleArtifactType.officialWeights,
      artifactUri: 'hf://nvidia/NVIDIA-Nemotron-Nano-12B-v2-VL-FP8',
      sha256: null,
      conversionRecipeId: null,
      runtime: ModelBundleRuntime.cudaVllm,
      minVramGb: 13,
      recommendedVramGb: 13,
      targetGpuClass: targetGpuClass,
      maxValidatedVramGb: 12,
      quantization: ModelBundleQuantization.fp8,
      fitsRtx5070Validated: false,
      supportsVideoInput: false,
      supportsImageInput: true,
      supportsBoundingBoxes: false,
      supportsMasks: false,
      supportsPointLocalization: false,
      maxFramesPerChunk: 8,
      maxContextTokens: 32768,
      recommendedChunkSeconds: 4,
      knownFailureModes: <String>[
        'FP8 weights exceed the 12 GB VRAM target.',
        'NVFP4-QAD variant requires TensorRT-LLM/vLLM, which is not available for the Windows desktop target.',
        'May need KidsLens-owned NVFP4 or int4 conversion before local evaluation.',
        'Image-first model path needs chunk frame packing validation.',
      ],
      roles: <ModelBundleRole>[ModelBundleRole.vlm],
      approvalStatus: ModelBundleApprovalStatus.watchlist,
      reviewNotes:
          'Official NVIDIA FP8 VLM candidate, but current FP8 artifact exceeds the RTX 5070 12 GB budget and is R&D-only.',
      leaderboardSourcesReviewed: reviewedLeaderboardSources,
    ),
    ModelBundleManifest(
      modelId: 'kidslens_nemotron_nano_12b_v2_vl_int4',
      displayName: 'KidsLens Nemotron Nano 12B v2 VL 4-bit',
      vendor: 'KidsLens / NVIDIA',
      officialSourceRepo: 'nvidia/NVIDIA-Nemotron-Nano-12B-v2-VL-FP8',
      officialRevision: 'main',
      license: ModelBundleLicense.nvidiaOpenModelLicense,
      commercialUse: CommercialUseStatus.allowed,
      acceptedTermsRequired: false,
      artifactType: ModelBundleArtifactType.internalQuantizedArtifact,
      artifactUri: 'kidslens-model://nemotron-nano-12b-v2-vl-int4',
      sha256: null,
      conversionRecipeId: 'nemotron-nano-v2-vl-int4-v1',
      runtime: ModelBundleRuntime.cudaVllm,
      minVramGb: 8,
      recommendedVramGb: 10,
      targetGpuClass: targetGpuClass,
      maxValidatedVramGb: 12,
      quantization: ModelBundleQuantization.int4,
      fitsRtx5070Validated: false,
      supportsVideoInput: false,
      supportsImageInput: true,
      supportsBoundingBoxes: false,
      supportsMasks: false,
      supportsPointLocalization: false,
      maxFramesPerChunk: 8,
      maxContextTokens: 32768,
      recommendedChunkSeconds: 4,
      knownFailureModes: <String>[
        'Internal conversion has not been produced or checksummed.',
        'Quality loss from 4-bit quantization must be measured.',
      ],
      roles: <ModelBundleRole>[ModelBundleRole.vlm],
      approvalStatus: ModelBundleApprovalStatus.evaluationOnly,
      reviewNotes:
          'Potential KidsLens-owned conversion from official NVIDIA weights; not selectable until reproducible artifact exists.',
      leaderboardSourcesReviewed: reviewedLeaderboardSources,
    ),
    ModelBundleManifest(
      modelId: 'qwen_3_5_4b',
      displayName: 'Qwen 3.5 4B',
      vendor: 'Alibaba / Qwen',
      officialSourceRepo: 'Qwen/Qwen3.5-4B',
      officialRevision: 'main',
      license: ModelBundleLicense.apache20,
      commercialUse: CommercialUseStatus.allowed,
      acceptedTermsRequired: false,
      artifactType: ModelBundleArtifactType.officialWeights,
      artifactUri: 'hf://Qwen/Qwen3.5-4B',
      sha256: null,
      conversionRecipeId: null,
      runtime: ModelBundleRuntime.cudaTransformersHelper,
      minVramGb: 6,
      recommendedVramGb: 8,
      targetGpuClass: targetGpuClass,
      maxValidatedVramGb: 12,
      quantization: ModelBundleQuantization.bf16,
      fitsRtx5070Validated: false,
      supportsVideoInput: false,
      supportsImageInput: true,
      supportsBoundingBoxes: false,
      supportsMasks: false,
      supportsPointLocalization: false,
      maxFramesPerChunk: 8,
      maxContextTokens: 32768,
      recommendedChunkSeconds: 4,
      knownFailureModes: <String>[
        'Model card capability must be validated for family-safety vision tasks.',
        'No native region output in manifest.',
      ],
      roles: <ModelBundleRole>[ModelBundleRole.vlm],
      approvalStatus: ModelBundleApprovalStatus.evaluationOnly,
      reviewNotes:
          'Apache-licensed major-provider lightweight candidate; requires capability and checksum validation.',
      leaderboardSourcesReviewed: reviewedLeaderboardSources,
    ),
    ModelBundleManifest(
      modelId: 'qwen_3_5_2b',
      displayName: 'Qwen 3.5 2B',
      vendor: 'Alibaba / Qwen',
      officialSourceRepo: 'Qwen/Qwen3.5-2B',
      officialRevision: 'main',
      license: ModelBundleLicense.apache20,
      commercialUse: CommercialUseStatus.allowed,
      acceptedTermsRequired: false,
      artifactType: ModelBundleArtifactType.officialWeights,
      artifactUri: 'hf://Qwen/Qwen3.5-2B',
      sha256: null,
      conversionRecipeId: null,
      runtime: ModelBundleRuntime.cudaTransformersHelper,
      minVramGb: 4,
      recommendedVramGb: 6,
      targetGpuClass: targetGpuClass,
      maxValidatedVramGb: 12,
      quantization: ModelBundleQuantization.bf16,
      fitsRtx5070Validated: false,
      supportsVideoInput: false,
      supportsImageInput: true,
      supportsBoundingBoxes: false,
      supportsMasks: false,
      supportsPointLocalization: false,
      maxFramesPerChunk: 6,
      maxContextTokens: 32768,
      recommendedChunkSeconds: 3,
      knownFailureModes: <String>[
        'Quality may be insufficient for default family-safety review.',
        'No native region output in manifest.',
      ],
      roles: <ModelBundleRole>[ModelBundleRole.vlm],
      approvalStatus: ModelBundleApprovalStatus.evaluationOnly,
      reviewNotes:
          'Optional lightweight fallback only if measured quality is acceptable.',
      leaderboardSourcesReviewed: reviewedLeaderboardSources,
    ),
    ModelBundleManifest(
      modelId: 'qwen3_embedding_0_6b',
      displayName: 'Qwen3 Embedding 0.6B',
      vendor: 'Alibaba / Qwen',
      officialSourceRepo: 'Qwen/Qwen3-Embedding-0.6B',
      officialRevision: 'main',
      license: ModelBundleLicense.apache20,
      commercialUse: CommercialUseStatus.allowed,
      acceptedTermsRequired: false,
      artifactType: ModelBundleArtifactType.officialWeights,
      artifactUri: 'hf://Qwen/Qwen3-Embedding-0.6B',
      sha256: null,
      conversionRecipeId: null,
      runtime: ModelBundleRuntime.cudaTransformersHelper,
      minVramGb: 1,
      recommendedVramGb: 2,
      targetGpuClass: targetGpuClass,
      maxValidatedVramGb: 12,
      quantization: ModelBundleQuantization.bf16,
      fitsRtx5070Validated: false,
      supportsVideoInput: false,
      supportsImageInput: false,
      supportsBoundingBoxes: false,
      supportsMasks: false,
      supportsPointLocalization: false,
      maxFramesPerChunk: 1,
      maxContextTokens: 32768,
      recommendedChunkSeconds: 1,
      knownFailureModes: <String>[
        'Text-only retrieval model; cannot inspect frames directly.',
        'Checksum and local throughput validation are required before production selection.',
      ],
      roles: <ModelBundleRole>[ModelBundleRole.embedding],
      approvalStatus: ModelBundleApprovalStatus.evaluationOnly,
      reviewNotes:
          'Official Qwen text embedding candidate for local retrieval; Apache-2.0 and small enough for high-end consumer GPUs.',
      leaderboardSourcesReviewed: reviewedLeaderboardSources,
    ),
    ModelBundleManifest(
      modelId: 'google_gemma_4_e4b_it',
      displayName: 'Google Gemma 4 E4B IT',
      vendor: 'Google',
      officialSourceRepo: 'google/gemma-4-E4B-it',
      officialRevision: 'main',
      license: ModelBundleLicense.apache20,
      commercialUse: CommercialUseStatus.allowed,
      acceptedTermsRequired: false,
      artifactType: ModelBundleArtifactType.officialWeights,
      artifactUri: 'hf://google/gemma-4-E4B-it',
      sha256: null,
      conversionRecipeId: null,
      runtime: ModelBundleRuntime.cudaTransformersHelper,
      minVramGb: 8,
      recommendedVramGb: 10,
      targetGpuClass: targetGpuClass,
      maxValidatedVramGb: 12,
      quantization: ModelBundleQuantization.bf16,
      fitsRtx5070Validated: false,
      supportsVideoInput: true,
      supportsImageInput: true,
      supportsBoundingBoxes: true,
      supportsMasks: false,
      supportsPointLocalization: true,
      maxFramesPerChunk: 16,
      maxContextTokens: 131072,
      recommendedChunkSeconds: 8,
      knownFailureModes: <String>[
        'Box/point output quality needs local family-safety validation.',
        'Large context can exceed VRAM without frame/token caps.',
      ],
      roles: <ModelBundleRole>[ModelBundleRole.vlm],
      approvalStatus: ModelBundleApprovalStatus.evaluationOnly,
      reviewNotes:
          'Apache-licensed major-provider candidate with image/video support; requires checksum and RTX 5070 validation.',
      leaderboardSourcesReviewed: reviewedLeaderboardSources,
    ),
    ModelBundleManifest(
      modelId: 'google_gemma_4_12b_it_int4',
      displayName: 'Google Gemma 4 12B IT 4-bit',
      vendor: 'Google',
      officialSourceRepo: 'google/gemma-4-12B-it',
      officialRevision: 'main',
      license: ModelBundleLicense.apache20,
      commercialUse: CommercialUseStatus.allowed,
      acceptedTermsRequired: false,
      artifactType: ModelBundleArtifactType.internalQuantizedArtifact,
      artifactUri: 'kidslens-model://gemma-4-12b-it-int4',
      sha256: null,
      conversionRecipeId: 'gemma-4-12b-it-int4-v1',
      runtime: ModelBundleRuntime.cudaTransformersHelper,
      minVramGb: 10,
      recommendedVramGb: 12,
      targetGpuClass: targetGpuClass,
      maxValidatedVramGb: 12,
      quantization: ModelBundleQuantization.int4,
      fitsRtx5070Validated: false,
      supportsVideoInput: true,
      supportsImageInput: true,
      supportsBoundingBoxes: true,
      supportsMasks: false,
      supportsPointLocalization: true,
      maxFramesPerChunk: 12,
      maxContextTokens: 65536,
      recommendedChunkSeconds: 6,
      knownFailureModes: <String>[
        'Tight 12 GB profile; CPU offload must be rejected.',
        'Internal quantized artifact has not been produced.',
      ],
      roles: <ModelBundleRole>[ModelBundleRole.vlm],
      approvalStatus: ModelBundleApprovalStatus.evaluationOnly,
      reviewNotes:
          'Tight 4-bit profile only; not selectable until conversion, checksum, and GPU validation are complete.',
      leaderboardSourcesReviewed: reviewedLeaderboardSources,
    ),
    ModelBundleManifest(
      modelId: 'microsoft_phi_4_multimodal_instruct',
      displayName: 'Microsoft Phi-4 Multimodal Instruct',
      vendor: 'Microsoft',
      officialSourceRepo: 'microsoft/Phi-4-multimodal-instruct',
      officialRevision: 'main',
      license: ModelBundleLicense.mit,
      commercialUse: CommercialUseStatus.allowed,
      acceptedTermsRequired: false,
      artifactType: ModelBundleArtifactType.officialWeights,
      artifactUri: 'hf://microsoft/Phi-4-multimodal-instruct',
      sha256: null,
      conversionRecipeId: null,
      runtime: ModelBundleRuntime.cudaTransformersHelper,
      minVramGb: 6,
      recommendedVramGb: 8,
      targetGpuClass: targetGpuClass,
      maxValidatedVramGb: 12,
      quantization: ModelBundleQuantization.bf16,
      fitsRtx5070Validated: false,
      supportsVideoInput: false,
      supportsImageInput: true,
      supportsBoundingBoxes: false,
      supportsMasks: false,
      supportsPointLocalization: false,
      maxFramesPerChunk: 8,
      maxContextTokens: 131072,
      recommendedChunkSeconds: 4,
      knownFailureModes: <String>[
        'Vision safety recall must be measured; no native boxes listed.',
        'Custom code path must be pinned before production.',
      ],
      roles: <ModelBundleRole>[ModelBundleRole.vlm],
      approvalStatus: ModelBundleApprovalStatus.evaluationOnly,
      reviewNotes:
          'MIT-licensed Microsoft multimodal candidate; checksum and runtime pinning required.',
      leaderboardSourcesReviewed: reviewedLeaderboardSources,
    ),
    ModelBundleManifest(
      modelId: 'microsoft_phi_4_multimodal_instruct_onnx',
      displayName: 'Microsoft Phi-4 Multimodal Instruct ONNX',
      vendor: 'Microsoft',
      officialSourceRepo: 'microsoft/Phi-4-multimodal-instruct-onnx',
      officialRevision: 'main',
      license: ModelBundleLicense.mit,
      commercialUse: CommercialUseStatus.allowed,
      acceptedTermsRequired: false,
      artifactType: ModelBundleArtifactType.officialOnnx,
      artifactUri: 'hf://microsoft/Phi-4-multimodal-instruct-onnx',
      sha256: null,
      conversionRecipeId: null,
      runtime: ModelBundleRuntime.directmlOnnx,
      minVramGb: 6,
      recommendedVramGb: 8,
      targetGpuClass: targetGpuClass,
      maxValidatedVramGb: 12,
      quantization: ModelBundleQuantization.onnxFp16,
      fitsRtx5070Validated: false,
      supportsVideoInput: false,
      supportsImageInput: true,
      supportsBoundingBoxes: false,
      supportsMasks: false,
      supportsPointLocalization: false,
      maxFramesPerChunk: 8,
      maxContextTokens: 32768,
      recommendedChunkSeconds: 4,
      knownFailureModes: <String>[
        'DirectML operator compatibility must be tested on Windows.',
        'No native grounding metadata in manifest.',
      ],
      roles: <ModelBundleRole>[ModelBundleRole.vlm],
      approvalStatus: ModelBundleApprovalStatus.evaluationOnly,
      reviewNotes:
          'Official ONNX artifact candidate for Windows runtime evaluation.',
      leaderboardSourcesReviewed: reviewedLeaderboardSources,
    ),
    ModelBundleManifest(
      modelId: 'meta_llama_4_scout_17b_16e_instruct',
      displayName: 'Meta Llama 4 Scout 17B-16E Instruct',
      vendor: 'Meta',
      officialSourceRepo: 'meta-llama/Llama-4-Scout-17B-16E-Instruct',
      officialRevision: 'main',
      license: ModelBundleLicense.llama4Community,
      commercialUse: CommercialUseStatus.allowedWithTerms,
      acceptedTermsRequired: true,
      artifactType: ModelBundleArtifactType.officialWeights,
      artifactUri: 'hf://meta-llama/Llama-4-Scout-17B-16E-Instruct',
      sha256: null,
      conversionRecipeId: null,
      runtime: ModelBundleRuntime.notYetValidated,
      minVramGb: 12,
      recommendedVramGb: 12,
      targetGpuClass: targetGpuClass,
      maxValidatedVramGb: 12,
      quantization: ModelBundleQuantization.bf16,
      fitsRtx5070Validated: false,
      supportsVideoInput: false,
      supportsImageInput: true,
      supportsBoundingBoxes: false,
      supportsMasks: false,
      supportsPointLocalization: false,
      maxFramesPerChunk: 4,
      maxContextTokens: 32768,
      recommendedChunkSeconds: 3,
      knownFailureModes: <String>[
        '109B-total MoE cannot run on the 12 GB consumer GPU target.',
        'Even FP8 estimates are far above the RTX 5070 target budget.',
        'Terms and acceptable-use obligations must be accepted.',
        '700M MAU threshold review is required for commercial distribution.',
      ],
      roles: <ModelBundleRole>[ModelBundleRole.vlm],
      approvalStatus: ModelBundleApprovalStatus.blocked,
      reviewNotes:
          'Record-only Meta candidate; blocked because Llama 4 Scout 17B-16E is a 109B-total MoE that cannot fit the RTX 5070 12 GB target.',
      leaderboardSourcesReviewed: reviewedLeaderboardSources,
    ),
    ModelBundleManifest(
      modelId: 'nvidia_llama_4_scout_17b_16e_instruct_fp8',
      displayName: 'NVIDIA Llama 4 Scout 17B-16E Instruct FP8',
      vendor: 'NVIDIA / Meta',
      officialSourceRepo: 'nvidia/Llama-4-Scout-17B-16E-Instruct-FP8',
      officialRevision: 'main',
      license: ModelBundleLicense.nvidiaOpenModelLicense,
      commercialUse: CommercialUseStatus.blocked,
      acceptedTermsRequired: true,
      artifactType: ModelBundleArtifactType.officialWeights,
      artifactUri: 'hf://nvidia/Llama-4-Scout-17B-16E-Instruct-FP8',
      sha256: null,
      conversionRecipeId: null,
      runtime: ModelBundleRuntime.notYetValidated,
      minVramGb: 12,
      recommendedVramGb: 12,
      targetGpuClass: targetGpuClass,
      maxValidatedVramGb: 12,
      quantization: ModelBundleQuantization.fp8,
      fitsRtx5070Validated: false,
      supportsVideoInput: false,
      supportsImageInput: true,
      supportsBoundingBoxes: false,
      supportsMasks: false,
      supportsPointLocalization: false,
      maxFramesPerChunk: 4,
      maxContextTokens: 32768,
      recommendedChunkSeconds: 3,
      knownFailureModes: <String>[
        '109B-total MoE cannot run on the 12 GB consumer GPU target.',
        'FP8 weights are estimated far above the RTX 5070 target budget.',
        'Upstream Llama 4 obligations need review.',
      ],
      roles: <ModelBundleRole>[ModelBundleRole.vlm],
      approvalStatus: ModelBundleApprovalStatus.blocked,
      reviewNotes:
          'Record-only NVIDIA/Meta candidate; blocked because even FP8 Llama 4 Scout is not viable on the RTX 5070 12 GB target.',
      leaderboardSourcesReviewed: reviewedLeaderboardSources,
    ),
    ModelBundleManifest(
      modelId: 'nvidia_locateanything_3b',
      displayName: 'NVIDIA LocateAnything 3B',
      vendor: 'NVIDIA',
      officialSourceRepo: 'nvidia/LocateAnything-3B',
      officialRevision: 'main',
      license: ModelBundleLicense.nonCommercial,
      commercialUse: CommercialUseStatus.blocked,
      acceptedTermsRequired: false,
      artifactType: ModelBundleArtifactType.disabledReference,
      artifactUri: 'hf://nvidia/LocateAnything-3B',
      sha256: null,
      conversionRecipeId: null,
      runtime: ModelBundleRuntime.notYetValidated,
      minVramGb: 6,
      recommendedVramGb: 8,
      targetGpuClass: targetGpuClass,
      maxValidatedVramGb: 12,
      quantization: ModelBundleQuantization.bf16,
      fitsRtx5070Validated: false,
      supportsVideoInput: false,
      supportsImageInput: true,
      supportsBoundingBoxes: true,
      supportsMasks: false,
      supportsPointLocalization: true,
      maxFramesPerChunk: 1,
      maxContextTokens: 8192,
      recommendedChunkSeconds: 1,
      knownFailureModes: <String>[
        'Current license blocks commercial production use.',
        'Keep disabled by default unless license terms change.',
      ],
      roles: <ModelBundleRole>[ModelBundleRole.grounding],
      approvalStatus: ModelBundleApprovalStatus.blocked,
      reviewNotes:
          'Optional grounding evaluation reference only; not available for commercial production selection.',
      leaderboardSourcesReviewed: reviewedLeaderboardSources,
    ),
    ModelBundleManifest(
      modelId: 'mistral_pixtral_12b_watchlist',
      displayName: 'Mistral Pixtral 12B Watchlist',
      vendor: 'Mistral AI',
      officialSourceRepo: 'mistralai/Pixtral-12B',
      officialRevision: 'main',
      license: ModelBundleLicense.reviewRequired,
      commercialUse: CommercialUseStatus.reviewRequired,
      acceptedTermsRequired: false,
      artifactType: ModelBundleArtifactType.disabledReference,
      artifactUri: 'hf://mistralai/Pixtral-12B',
      sha256: null,
      conversionRecipeId: null,
      runtime: ModelBundleRuntime.notYetValidated,
      minVramGb: 12,
      recommendedVramGb: 12,
      targetGpuClass: targetGpuClass,
      maxValidatedVramGb: 12,
      quantization: ModelBundleQuantization.int4,
      fitsRtx5070Validated: false,
      supportsVideoInput: false,
      supportsImageInput: true,
      supportsBoundingBoxes: false,
      supportsMasks: false,
      supportsPointLocalization: false,
      maxFramesPerChunk: 4,
      maxContextTokens: 32768,
      recommendedChunkSeconds: 3,
      knownFailureModes: <String>[
        'License and official artifact status require review.',
        'RTX 5070 4-bit conversion is unvalidated.',
      ],
      roles: <ModelBundleRole>[ModelBundleRole.vlm],
      approvalStatus: ModelBundleApprovalStatus.watchlist,
      reviewNotes:
          'Major-provider watchlist only; not part of default production selection.',
      leaderboardSourcesReviewed: reviewedLeaderboardSources,
    ),
  ];

  static const explicitlyExcludedModelIds = <String>[
    'nvidia/Cosmos-Reason2-32B',
    'google/gemma-4-26B-*',
    'google/gemma-4-31B-*',
    'Qwen/Qwen3.5-14B-*',
    'Qwen/Qwen3.5-32B-*',
    'microsoft/Phi-4-vision-reasoning-15B',
    'meta-llama/Llama-4-Scout-17B-16E-Instruct',
    'nvidia/Llama-4-Scout-17B-16E-Instruct-FP8',
    'meta-llama/Llama-4-Maverick-*',
    'OpenGVLab/InternVL-*',
    'allenai/Molmo-*',
    'community/*',
  ];

  static List<ModelBundleManifest> get approvedEmbeddingCandidates =>
      candidatesForRole(ModelBundleRole.embedding);

  static List<ModelBundleManifest> candidatesForRole(ModelBundleRole role) =>
      initialCandidates
          .where((candidate) => candidate.roles.contains(role))
          .toList(growable: false);

  static List<ModelBundleManifest> get productionSelectable => initialCandidates
      .where((candidate) => candidate.isProductionSelectable)
      .toList(growable: false);

  static ModelBundleManifest byModelId(String modelId) =>
      initialCandidates.firstWhere((candidate) => candidate.modelId == modelId);
}
