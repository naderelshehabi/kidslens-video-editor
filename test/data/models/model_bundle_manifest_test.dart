import 'package:flutter_test/flutter_test.dart';
import 'package:kidslens_video_editor/data/models/model_bundle_manifest.dart';

void main() {
  group('ModelBundleCatalog', () {
    test('records the RTX 5070 target profile', () {
      expect(ModelBundleCatalog.targetGpuClass, 'rtx_5070_12gb');
      expect(ModelBundleCatalog.targetGpuVramGb, 12);
    });

    test('contains the approved initial VLM candidates', () {
      final ids = ModelBundleCatalog.candidatesForRole(
        ModelBundleRole.vlm,
      ).map((candidate) => candidate.modelId);

      expect(
        ids,
        containsAll(const [
          'nvidia_cosmos_reason1_7b',
          'nvidia_cosmos_reason2_8b',
          'nvidia_nemotron_nano_12b_v2_vl_fp8',
          'kidslens_nemotron_nano_12b_v2_vl_int4',
          'qwen_3_5_4b',
          'qwen_3_5_2b',
          'google_gemma_4_e4b_it',
          'google_gemma_4_12b_it_int4',
          'microsoft_phi_4_multimodal_instruct',
          'microsoft_phi_4_multimodal_instruct_onnx',
          'meta_llama_4_scout_17b_16e_instruct',
          'nvidia_llama_4_scout_17b_16e_instruct_fp8',
        ]),
      );
    });

    test('keeps LocateAnything optional and blocked for commercial builds', () {
      final locateAnything = ModelBundleCatalog.byModelId(
        'nvidia_locateanything_3b',
      );

      expect(locateAnything.roles, contains(ModelBundleRole.grounding));
      expect(locateAnything.approvalStatus, ModelBundleApprovalStatus.blocked);
      expect(locateAnything.commercialUse, CommercialUseStatus.blocked);
      expect(locateAnything.validateForCatalog(), isEmpty);
    });

    test('contains the official local embedding candidate', () {
      final embedding = ModelBundleCatalog.byModelId('qwen3_embedding_0_6b');

      expect(embedding.roles, [ModelBundleRole.embedding]);
      expect(embedding.officialSourceRepo, 'Qwen/Qwen3-Embedding-0.6B');
      expect(embedding.license, ModelBundleLicense.apache20);
      expect(embedding.commercialUse, CommercialUseStatus.allowed);
      expect(embedding.supportsImageInput, isFalse);
      expect(embedding.supportsVideoInput, isFalse);
      expect(embedding.validateForCatalog(), isEmpty);
      expect(
        ModelBundleCatalog.approvedEmbeddingCandidates.map((m) => m.modelId),
        contains('qwen3_embedding_0_6b'),
      );
    });

    test('does not expose production-selectable models without checksums', () {
      expect(ModelBundleCatalog.productionSelectable, isEmpty);
      for (final candidate in ModelBundleCatalog.initialCandidates) {
        expect(candidate.validateForCatalog(), isEmpty);
        expect(
          candidate.validateForProductionSelection(),
          contains('model is not production approved'),
        );
      }
    });

    test('records reviewed leaderboard sources', () {
      expect(
        ModelBundleCatalog.reviewedLeaderboardSources,
        containsAll(const [
          'Open VLM Leaderboard',
          'Vision Arena',
          'MMBench Leaderboard',
          'SEED-Bench Leaderboard',
          'retrieval/document leaderboards',
        ]),
      );

      for (final candidate in ModelBundleCatalog.initialCandidates) {
        expect(
          candidate.leaderboardSourcesReviewed,
          ModelBundleCatalog.reviewedLeaderboardSources,
        );
      }
    });

    test('records explicitly excluded large and community candidates', () {
      expect(
        ModelBundleCatalog.explicitlyExcludedModelIds,
        containsAll(const [
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
        ]),
      );
    });
  });

  group('ModelBundleManifest validation', () {
    test('accepts a complete production-approved local bundle', () {
      const manifest = ModelBundleManifest(
        modelId: 'kidslens_gemma_4_e4b_it_int4',
        displayName: 'KidsLens Gemma 4 E4B IT INT4',
        vendor: 'KidsLens / Google',
        officialSourceRepo: 'google/gemma-4-E4B-it',
        officialRevision: 'abc123',
        license: ModelBundleLicense.apache20,
        commercialUse: CommercialUseStatus.allowed,
        acceptedTermsRequired: false,
        artifactType: ModelBundleArtifactType.internalQuantizedArtifact,
        artifactUri: 'kidslens-model://gemma-4-e4b-it-int4',
        sha256:
            '0123456789abcdef0123456789abcdef0123456789abcdef0123456789abcdef',
        conversionRecipeId: 'gemma-4-e4b-it-int4-v1',
        runtime: ModelBundleRuntime.cudaTransformersHelper,
        minVramGb: 6,
        recommendedVramGb: 8,
        targetGpuClass: ModelBundleCatalog.targetGpuClass,
        maxValidatedVramGb: ModelBundleCatalog.targetGpuVramGb,
        quantization: ModelBundleQuantization.int4,
        fitsRtx5070Validated: true,
        supportsVideoInput: true,
        supportsImageInput: true,
        supportsBoundingBoxes: true,
        supportsMasks: false,
        supportsPointLocalization: true,
        maxFramesPerChunk: 16,
        maxContextTokens: 32768,
        recommendedChunkSeconds: 8,
        knownFailureModes: <String>[
          'May miss subtle immodest clothing without second-pass review.',
        ],
        roles: <ModelBundleRole>[ModelBundleRole.vlm],
        approvalStatus: ModelBundleApprovalStatus.productionApproved,
        reviewNotes: 'Validated local bundle.',
      );

      expect(manifest.validateForCatalog(), isEmpty);
      expect(manifest.validateForProductionSelection(), isEmpty);
    });

    test('rejects community source repositories', () {
      final manifest = _validManifest(
        officialSourceRepo: 'random-user/Qwen3.5-4B-GGUF',
      );

      expect(
        manifest.validateForCatalog(),
        contains('official source organization is not approved'),
      );
    });

    test('rejects missing checksums for production selection', () {
      final manifest = _validManifest(sha256: null);

      expect(
        manifest.validateForProductionSelection(),
        contains('sha256 must be a 64-character lowercase hex digest'),
      );
    });

    test('rejects cloud or hosted inference artifact URIs', () {
      final manifest = _validManifest(
        artifactUri: 'https://api-inference.huggingface.co/models/google/gemma',
      );

      expect(
        manifest.validateForCatalog(),
        contains(
          'artifactUri must be a local/downloadable model artifact URI',
        ),
      );
    });

    test('rejects cloud-only or unvalidated runtime for production', () {
      final manifest = _validManifest(
        runtime: ModelBundleRuntime.notYetValidated,
      );

      expect(
        manifest.validateForProductionSelection(),
        contains('runtime must be validated before production selection'),
      );
    });

    test('rejects unsupported license states for production', () {
      final manifest = _validManifest(
        license: ModelBundleLicense.reviewRequired,
        commercialUse: CommercialUseStatus.reviewRequired,
      );

      expect(
        manifest.validateForCatalog(),
        contains('license review must be completed'),
      );
      expect(
        manifest.validateForProductionSelection(),
        contains('commercial use is not approved'),
      );
    });

    test('rejects grounding entries without localizable output', () {
      final manifest = _validManifest(
        roles: const <ModelBundleRole>[ModelBundleRole.grounding],
        supportsBoundingBoxes: false,
        supportsPointLocalization: false,
      );

      expect(
        manifest.validateForCatalog(),
        contains('grounding models must expose a localizable output'),
      );
    });

    test('accepts text-only embedding manifests', () {
      final manifest = _validManifest(
        officialSourceRepo: 'Qwen/Qwen3-Embedding-0.6B',
        artifactUri: 'hf://Qwen/Qwen3-Embedding-0.6B',
        roles: const <ModelBundleRole>[ModelBundleRole.embedding],
        supportsImageInput: false,
        supportsVideoInput: false,
        supportsBoundingBoxes: false,
        supportsPointLocalization: false,
      );

      expect(manifest.validateForCatalog(), isEmpty);
    });
  });

  group('KidsLensModelScorecard', () {
    test('accepts complete 0-5 scorecards', () {
      const scorecard = KidsLensModelScorecard(
        familySafetyRecall: 4,
        falsePositiveBurden: 3,
        temporalLocalizationQuality: 4,
        boxMaskQuality: 3,
        explanationQuality: 5,
        localGpuThroughput: 4,
        vramFit: 5,
        windowsRuntimeReadiness: 4,
        licenseTermsFit: 5,
        notes: 'Strong RTX 5070 candidate.',
      );

      expect(scorecard.validate(), isEmpty);
    });

    test('rejects out-of-range scorecards', () {
      const scorecard = KidsLensModelScorecard(
        familySafetyRecall: 6,
        falsePositiveBurden: -1,
        temporalLocalizationQuality: 4,
        boxMaskQuality: 3,
        explanationQuality: 5,
        localGpuThroughput: 4,
        vramFit: 5,
        windowsRuntimeReadiness: 4,
        licenseTermsFit: 5,
        notes: '',
      );

      expect(scorecard.validate(), hasLength(3));
    });
  });
}

ModelBundleManifest _validManifest({
  String officialSourceRepo = 'google/gemma-4-E4B-it',
  String artifactUri = 'kidslens-model://gemma-4-e4b-it-int4',
  String? sha256 =
      '0123456789abcdef0123456789abcdef0123456789abcdef0123456789abcdef',
  ModelBundleRuntime runtime = ModelBundleRuntime.cudaTransformersHelper,
  ModelBundleLicense license = ModelBundleLicense.apache20,
  CommercialUseStatus commercialUse = CommercialUseStatus.allowed,
  List<ModelBundleRole> roles = const <ModelBundleRole>[ModelBundleRole.vlm],
  bool supportsBoundingBoxes = true,
  bool supportsMasks = false,
  bool supportsPointLocalization = true,
  bool supportsImageInput = true,
  bool supportsVideoInput = true,
}) =>
    ModelBundleManifest(
      modelId: 'test_model',
      displayName: 'Test Model',
      vendor: 'Test Vendor',
      officialSourceRepo: officialSourceRepo,
      officialRevision: 'abc123',
      license: license,
      commercialUse: commercialUse,
      acceptedTermsRequired: false,
      artifactType: ModelBundleArtifactType.internalQuantizedArtifact,
      artifactUri: artifactUri,
      sha256: sha256,
      conversionRecipeId: 'conversion-v1',
      runtime: runtime,
      minVramGb: 6,
      recommendedVramGb: 8,
      targetGpuClass: ModelBundleCatalog.targetGpuClass,
      maxValidatedVramGb: ModelBundleCatalog.targetGpuVramGb,
      quantization: ModelBundleQuantization.int4,
      fitsRtx5070Validated: true,
      supportsVideoInput: supportsVideoInput,
      supportsImageInput: supportsImageInput,
      supportsBoundingBoxes: supportsBoundingBoxes,
      supportsMasks: supportsMasks,
      supportsPointLocalization: supportsPointLocalization,
      maxFramesPerChunk: 16,
      maxContextTokens: 32768,
      recommendedChunkSeconds: 8,
      knownFailureModes: const <String>['Known test failure mode.'],
      roles: roles,
      approvalStatus: ModelBundleApprovalStatus.productionApproved,
      reviewNotes: 'Test manifest.',
    );
