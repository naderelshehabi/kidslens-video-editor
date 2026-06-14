import 'package:flutter_test/flutter_test.dart';
import 'package:kidslens_video_editor/data/models/models.dart';
import 'package:kidslens_video_editor/services/detection/model_bundle_selection_policy.dart';

void main() {
  group('ModelBundleSelectionPolicy', () {
    test('allows production-approved bundles for matching roles and runtime',
        () {
      final manifest = _manifest();
      final policy = ModelBundleSelectionPolicy(catalog: [manifest]);

      expect(
        policy.canSelect(
          manifest: manifest,
          role: ModelBundleRole.vlm,
          localRuntimeId: LocalRuntimeId.cudaTransformersHelper.jsonValue,
          acceptedTerms: const <String>{},
        ),
        isTrue,
      );
      expect(
        policy.selectableForRole(
          role: ModelBundleRole.vlm,
          localRuntimeId: LocalRuntimeId.cudaTransformersHelper.jsonValue,
          acceptedTerms: const <String>{},
        ),
        [manifest],
      );
    });

    test('blocks catalog candidates that are not production approved', () {
      const policy = ModelBundleSelectionPolicy();
      final candidate = ModelBundleCatalog.byModelId('google_gemma_4_e4b_it');

      expect(
        policy.blockers(
          manifest: candidate,
          role: ModelBundleRole.vlm,
          localRuntimeId: LocalRuntimeId.cudaTransformersHelper.jsonValue,
          acceptedTerms: const <String>{},
        ),
        contains('Not production approved.'),
      );
    });

    test('blocks LocateAnything for commercial production selection', () {
      const policy = ModelBundleSelectionPolicy();
      final locateAnything = ModelBundleCatalog.byModelId(
        'nvidia_locateanything_3b',
      );

      final blockers = policy.blockers(
        manifest: locateAnything,
        role: ModelBundleRole.grounding,
        localRuntimeId: LocalRuntimeId.cudaTransformersHelper.jsonValue,
        acceptedTerms: const <String>{},
      );

      expect(blockers, contains('Not production approved.'));
      expect(blockers, contains('Commercial use is blocked.'));
    });

    test('requires terms acceptance before selecting terms-gated models', () {
      final manifest = _manifest(
        acceptedTermsRequired: true,
        commercialUse: CommercialUseStatus.allowedWithTerms,
      );
      final policy = ModelBundleSelectionPolicy(catalog: [manifest]);

      expect(
        policy.blockers(
          manifest: manifest,
          role: ModelBundleRole.vlm,
          localRuntimeId: LocalRuntimeId.cudaTransformersHelper.jsonValue,
          acceptedTerms: const <String>{},
        ),
        contains('Terms must be accepted before selection.'),
      );
      expect(
        policy.blockers(
          manifest: manifest,
          role: ModelBundleRole.vlm,
          localRuntimeId: LocalRuntimeId.cudaTransformersHelper.jsonValue,
          acceptedTerms: {manifest.modelId},
        ),
        isEmpty,
      );
    });

    test('blocks runtime mismatches', () {
      final manifest = _manifest();
      final policy = ModelBundleSelectionPolicy(catalog: [manifest]);

      expect(
        policy.blockers(
          manifest: manifest,
          role: ModelBundleRole.vlm,
          localRuntimeId: LocalRuntimeId.cudaVllm.jsonValue,
          acceptedTerms: const <String>{},
        ),
        contains('Requires CUDA Transformers Helper.'),
      );
    });

    test('accepts either llama.cpp runtime for llama server bundles', () {
      final manifest = _manifest(
        runtime: ModelBundleRuntime.llamaCppServer,
        artifactType: ModelBundleArtifactType.officialGguf,
        artifactFiles: const <ModelBundleArtifactFile>[
          ModelBundleArtifactFile(
            path: 'model.gguf',
            sizeBytes: 2,
            sha256:
                '0123456789abcdef0123456789abcdef0123456789abcdef0123456789abcdef',
          ),
          ModelBundleArtifactFile(
            path: 'mmproj.gguf',
            sizeBytes: 3,
            sha256:
                'abcdef0123456789abcdef0123456789abcdef0123456789abcdef0123456789',
          ),
        ],
      );
      final policy = ModelBundleSelectionPolicy(catalog: [manifest]);

      expect(
        policy.blockers(
          manifest: manifest,
          role: ModelBundleRole.vlm,
          localRuntimeId: LocalRuntimeId.cudaLlamaCpp.jsonValue,
          acceptedTerms: const <String>{},
        ),
        isEmpty,
      );
      expect(
        policy.blockers(
          manifest: manifest,
          role: ModelBundleRole.vlm,
          localRuntimeId: LocalRuntimeId.vulkanLlamaCpp.jsonValue,
          acceptedTerms: const <String>{},
        ),
        isEmpty,
      );
    });
  });
}

ModelBundleManifest _manifest({
  bool acceptedTermsRequired = false,
  CommercialUseStatus commercialUse = CommercialUseStatus.allowed,
  ModelBundleRuntime runtime = ModelBundleRuntime.cudaTransformersHelper,
  ModelBundleArtifactType artifactType =
      ModelBundleArtifactType.internalQuantizedArtifact,
  List<ModelBundleArtifactFile> artifactFiles =
      const <ModelBundleArtifactFile>[],
}) =>
    ModelBundleManifest(
      modelId: 'kidslens_gemma_4_e4b_it_int4',
      displayName: 'KidsLens Gemma 4 E4B IT INT4',
      vendor: 'KidsLens / Google',
      officialSourceRepo: 'google/gemma-4-E4B-it',
      officialRevision: 'abc123',
      license: ModelBundleLicense.apache20,
      commercialUse: commercialUse,
      acceptedTermsRequired: acceptedTermsRequired,
      artifactType: artifactType,
      artifactUri: 'kidslens-model://gemma-4-e4b-it-int4',
      sha256:
          '0123456789abcdef0123456789abcdef0123456789abcdef0123456789abcdef',
      conversionRecipeId: 'gemma-4-e4b-it-int4-v1',
      runtime: runtime,
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
      knownFailureModes: const <String>[
        'May miss subtle immodest clothing without second-pass review.',
      ],
      roles: const <ModelBundleRole>[ModelBundleRole.vlm],
      approvalStatus: ModelBundleApprovalStatus.productionApproved,
      reviewNotes: 'Validated local bundle.',
      artifactFiles: artifactFiles,
    );
