# VSS-Style Local Family Safety Detection Implementation Checklist

Date: 2026-06-07

Companion plan: `docs/implement/vss-family-safety-detection-revamp-plan.md`

This checklist is ordered for implementation. Each phase should be merged behind feature flags unless the exit gate says otherwise.

## Phase 0: Policy, Scope, and Model Governance

- [x] Confirm the hard product rule: all inference is local-only.
- [x] Remove any planned dependency on hosted VLM, LLM, embedding, reranking, or moderation APIs.
- [x] Define approved inference transport:
  - [x] In-process native runtime.
  - [x] Local helper process.
  - [x] Local loopback server on `localhost` or `127.0.0.1`.
  - [x] Explicitly reject non-loopback URLs.
- [x] Define v1 policy taxonomy:
  - [x] `explicit_nudity`
  - [x] `sexual_content`
  - [x] `suggestive_content`
  - [x] `immodest_female_clothing`
  - [x] `violence`
  - [x] `gore`
  - [x] `blood`
  - [x] `weapons`
  - [x] `substances`
  - [x] `profanity`
- [x] Define default action per category:
  - [x] region blur
  - [x] full-frame blur
  - [x] cut scene
  - [x] beep/mute
  - [x] review only
- [x] Define per-category severity levels:
  - [x] `none`
  - [x] `low`
  - [x] `medium`
  - [x] `high`
  - [x] `critical`
- [x] Define per-category enforcement mode:
  - [x] review-first
  - [x] enforce when high confidence
  - [x] always manual review
- [x] Define category-specific boundary requirements:
  - [x] explicit nudity should use region bounds when available.
  - [x] immodest female clothing should use region bounds when available.
  - [x] blood/gore should use region bounds when available.
  - [x] weapons should use object bounds when available.
  - [x] violence may be scene-level when no object-level boundary is meaningful.
- [x] Define explainability requirements:
  - [x] user-facing category
  - [x] severity
  - [x] confidence
  - [x] short rationale
  - [x] timestamp range
  - [x] region/scene-level status
  - [x] source model names
  - [x] supporting evidence IDs
- [x] Define prohibited model sources:
  - [x] community ports
  - [x] unofficial quantizations
  - [x] hosted inference providers
  - [x] model files without checksums
  - [x] model files without license metadata
- [x] Define accepted official source organizations:
  - [x] `nvidia`
  - [x] `Qwen` / Alibaba
  - [x] `google`
  - [x] `microsoft`
  - [x] `meta-llama`
  - [x] `mistralai` only as an optional major-provider watchlist vendor.
  - [x] other future major providers only after review.
- [x] Define internal conversion policy:
  - [x] conversion must start from official weights.
  - [x] conversion recipe must be committed or versioned.
  - [x] output artifact must include checksum.
  - [x] artifact must be published to a KidsLens-owned Hugging Face repo or controlled release bucket.
  - [x] model manifest must link official source revision to converted artifact revision.
  - [x] quantized artifacts must be reproducible from official weights.
  - [x] quantized artifacts must be validated on an RTX 5070 12 GB profile before app selection.
- [x] Create a model-approval record template.
- [x] Create a policy-review record template.
- [x] Exit gate: policy taxonomy, local-only rule, model-source rule, and explainability contract are approved.

## Phase 1: Model Bundle Manifest

- [x] Add a model bundle manifest model under `lib/data/models/model_bundle_manifest.dart`.
- [x] Include required fields:
  - [x] `modelId`
  - [x] `displayName`
  - [x] `vendor`
  - [x] `officialSourceRepo`
  - [x] `officialRevision`
  - [x] `license`
  - [x] `acceptedTermsRequired`
  - [x] `artifactType`
  - [x] `artifactUri`
  - [x] `sha256`
  - [x] `conversionRecipeId`
  - [x] `runtime`
  - [x] `minVramGb`
  - [x] `recommendedVramGb`
  - [x] `targetGpuClass`, initially `rtx_5070_12gb`
  - [x] `maxValidatedVramGb`, initially `12`
  - [x] `quantization`
  - [x] `fitsRtx5070Validated`
  - [x] `supportsVideoInput`
  - [x] `supportsImageInput`
  - [x] `supportsBoundingBoxes`
  - [x] `supportsMasks`
  - [x] `supportsPointLocalization`
  - [x] `maxFramesPerChunk`
  - [x] `maxContextTokens`
  - [x] `recommendedChunkSeconds`
  - [x] `knownFailureModes`
- [x] Add approved initial VLM candidates sized for RTX 5070-class GPUs:
  - [x] `nvidia/Cosmos-Reason1-7B`
  - [x] `nvidia/NVIDIA-Nemotron-Nano-12B-v2-VL-FP8` only after RTX 5070 validation.
  - [x] KidsLens-owned NVFP4/4-bit Nemotron artifact if FP8 does not leave enough VRAM headroom.
  - [x] `Qwen/Qwen3.5-4B`
  - [x] `Qwen/Qwen3.5-2B` as an optional lightweight fallback if quality is acceptable.
  - [x] `google/gemma-4-E4B-it`
  - [x] `google/gemma-4-12B-it` only as a tight 4-bit profile after RTX 5070 validation.
  - [x] `microsoft/Phi-4-multimodal-instruct`
  - [x] `microsoft/Phi-4-multimodal-instruct-onnx`
  - [x] `meta-llama/Llama-4-Scout-17B-16E-Instruct` only after license acceptance and RTX 5070 validation.
  - [x] `nvidia/Llama-4-Scout-17B-16E-Instruct-FP8` as an official-derived R&D reference only until RTX 5070 fit is proven.
- [x] Add license/commercial-use review for each model:
  - [x] NVIDIA Cosmos Reason1: NVIDIA Open Model License, commercial-use check.
  - [x] NVIDIA Nemotron Nano VL: NVIDIA Open Model License, commercial-use check.
  - [x] NVIDIA LocateAnything: current non-commercial license blocks production use; keep optional/disabled by default.
  - [x] Alibaba Qwen3.5: Apache 2.0 check.
  - [x] Google Gemma 4: Apache 2.0 check.
  - [x] Microsoft Phi-4 multimodal: MIT check.
  - [x] Microsoft Phi-4 multimodal ONNX: MIT check.
  - [x] Meta Llama 4 Scout: Llama 4 Community License, 700M MAU and acceptable-use checks.
  - [x] NVIDIA Llama 4 Scout FP8: NVIDIA Open Model License plus upstream Llama 4 obligation review.
- [x] Add approved initial grounding candidates:
  - [x] `nvidia/LocateAnything-3B` as optional grounding evaluation only; disabled by default unless the license permits production use.
  - [x] official grounding/localization models from approved vendors only after validation.
- [x] Add optional major-provider watchlist candidates for evaluation, not default selection:
  - [x] `mistralai/Pixtral-12B-*` only if 4-bit conversion and RTX 5070 validation pass.
- [x] Explicitly exclude from RTX 5070 production candidates until proven otherwise:
  - [x] `nvidia/Cosmos-Reason2-32B`
  - [x] Gemma 4 26B/31B variants
  - [x] unvalidated large Qwen3.5 variants
  - [x] Qwen 14B/32B+ VL variants
  - [x] `microsoft/Phi-4-vision-reasoning-15B`
  - [x] Meta Llama 4 Maverick
  - [x] unvalidated Meta Llama 4 Scout artifacts
  - [x] OpenGVLab InternVL variants
  - [x] AllenAI Molmo variants
  - [x] community quantizations or ports for any model.
- [x] Record Hugging Face leaderboard sources reviewed:
  - [x] Open VLM Leaderboard
  - [x] Vision Arena
  - [x] MMBench Leaderboard
  - [x] SEED-Bench Leaderboard
  - [x] retrieval/document leaderboards when considering embedding/OCR-heavy models.
- [x] Create an internal KidsLens model scorecard:
  - [x] family-safety category recall
  - [x] false positive burden
  - [x] temporal localization quality
  - [x] box/mask quality
  - [x] explanation quality
  - [x] local GPU throughput
  - [x] VRAM fit
  - [x] Windows runtime readiness
  - [x] license/terms fit
- [x] Add approved local embedding candidates only after official-source review. Phase 1 review approved none for production yet.
- [x] Add approved grounding candidates only after official-source review. `nvidia/LocateAnything-3B` is present as optional/evaluation-only and production-blocked.
- [x] Add manifest validation:
  - [x] reject missing official source.
  - [x] reject missing checksum for production selection.
  - [x] reject community source.
  - [x] reject unsupported license.
  - [x] reject cloud-only runtime.
  - [x] reject non-local artifact URI.
- [x] Add tests for manifest validation.
- [x] Exit gate: invalid/community/cloud manifest entries fail tests.

Phase 1 implementation note: `ModelBundleCatalog.productionSelectable` is intentionally empty until a model bundle has a validated checksum, local artifact, accepted terms record where required, and RTX 5070 12 GB runtime evidence.

## Phase 2: Pipeline Registry and Legacy Wrapping

- [x] Add `lib/services/detection/` namespace.
- [x] Add `DetectionPipeline` interface.
- [x] Add `DetectionPipelineRegistry`.
- [x] Add `DetectionPipelineProfile`.
- [x] Add profile IDs:
  - [x] `vss_family_safety_v1`
  - [x] `legacy_nsfw_region_v8`
  - [x] `audio_only`
  - [x] `fast_preview`
- [x] Wrap existing `AnalysisService` visual logic as `LegacyNsfwPipelineAdapter`.
- [x] Keep current user-facing detections unchanged for `legacy_nsfw_region_v8`.
- [x] Add `AnalysisSettings.analysisPipelineId`.
- [x] Route `AnalysisService.analyze()` through the registry.
- [x] Add tests proving legacy profile output remains compatible.
- [x] Exit gate: existing tests pass with legacy profile selected.

Phase 2 implementation note: `vss_family_safety_v1`, `audio_only`, and `fast_preview` are registered profiles. `vss_family_safety_v1` now resolves as the default profile; `audio_only` and `fast_preview` remain future profiles until their provider stages are implemented.

Phase 2 update, 2026-06-08: `vss_family_safety_v1` is now the registered default
profile for new analyses. The legacy adapter remains selectable through
`legacy_nsfw_region_v8`.

## Phase 3: Chunked Ingestion

- [x] Add `VideoChunk` model.
- [x] Add `SampledFrameRef` model.
- [x] Add `AnalysisRunManifest` model.
- [x] Add `ChunkPlanner`.
- [x] Implement fixed-duration chunking.
- [x] Implement scene-aware chunking using existing scene detection.
- [x] Add overlap handling.
- [x] Add deterministic chunk IDs.
- [x] Add deterministic frame IDs.
- [x] Extend `FrameSamplingService` with chunk-aware selection.
- [x] Support VLM frame selection:
  - [x] scene start
  - [x] scene middle
  - [x] scene end
  - [x] motion/scene-change frames
  - [x] max frame limit from model bundle manifest
- [x] Support legacy fixed-FPS frame selection.
- [x] Add checkpoint metadata:
  - [x] pipeline ID
  - [x] chunk planner hash
  - [x] model bundle IDs
  - [x] policy profile hash
  - [x] sampling hash
- [x] Add chunk planner unit tests.
- [x] Add frame selection unit tests.
- [x] Exit gate: fixed fixture media produces stable chunk/frame plans.

Phase 3 implementation note: chunked ingestion is metadata-first. `ChunkPlanner` creates deterministic windows, `FrameSamplingService` creates deterministic frame references for VLM and legacy providers, and actual chunk-aware provider execution starts in the evidence/runtime phases.

## Phase 4: Evidence Store

- [x] Add `EvidenceRecord` model.
- [x] Add evidence types:
  - [x] `vlm_caption`
  - [x] `vlm_policy_json`
  - [x] `grounded_region`
  - [x] `legacy_nsfw_score`
  - [x] `legacy_nudenet_region`
  - [x] `modesty_parser_signal`
  - [x] `transcript_span`
  - [x] `profanity_match`
  - [x] `embedding_record`
- [x] Add evidence provenance fields:
  - [x] provider ID
  - [x] provider version
  - [x] model bundle ID
  - [x] model checksum
  - [x] runtime
  - [x] GPU provider
  - [x] input IDs
  - [x] timestamp range
  - [x] schema version
- [x] Add JSON-backed evidence store first.
- [x] Add SQLite-backed evidence store if project persistence needs query speed. Phase 4 decision: not added yet because the current requirement is deterministic append/read/replay and JSON is sufficient until query speed is measured.
- [x] Add evidence replay API.
- [x] Convert existing NSFW classifier output into evidence records.
- [x] Convert existing NudeNet output into evidence records.
- [x] Convert existing modesty parser output into evidence records.
- [x] Convert transcript/profanity output into evidence records.
- [x] Add tests that replay evidence into the same findings without rerunning models.
- [x] Exit gate: analysis can be resumed/replayed from evidence records.

Phase 4 implementation note: evidence storage is JSON-backed and deterministic. `EvidenceRecord` captures provenance and payloads, `JsonEvidenceStore` persists records with ID deduplication, and `EvidenceReplayService` rebuilds frame results, transcript spans, profanity matches, region detections, and UI-compatible timelines without invoking models.

## Phase 5: Local Runtime Management

- [x] Add `LocalRuntimeProfile`.
- [x] Add runtime IDs:
  - [x] `cuda_tensorrt`
  - [x] `cuda_vllm`
  - [x] `cuda_transformers_helper`
  - [x] `directml_onnx`
  - [x] `cpu_lightweight`
- [x] Add GPU discovery integration using existing GPU services.
- [x] Add VRAM estimate checks.
- [x] Add RTX 5070 12 GB fit validation:
  - [x] target GPU profile is `rtx_5070_12gb`.
  - [x] validation uses the configured chunk length.
  - [x] validation uses the configured frame count.
  - [x] validation uses the configured frame resolution.
  - [x] validation uses the configured max output tokens.
  - [x] validation includes first pass and second pass.
  - [x] record peak VRAM.
  - [x] record p50/p95 chunk latency.
  - [x] record output schema failure rate.
  - [x] record model/runtime crash rate.
  - [x] reject profiles that require sustained CPU offload.
- [x] Add runtime selection:
  - [x] prefer model manifest runtime.
  - [x] prefer CUDA/TensorRT when supported.
  - [x] fallback to CUDA vLLM/helper.
  - [x] fallback to DirectML/ONNX for compatible artifacts.
  - [x] fallback to CPU only for lightweight profiles.
- [x] Add loopback-only local server validation.
- [x] Reject non-loopback URLs in runtime config.
- [x] Reject hosted model names or inference endpoints.
- [x] Add structured provider-resolution logs.
- [x] Add UI-visible runtime status:
  - [x] runtime name
  - [x] model name
  - [x] GPU device
  - [x] VRAM estimate
  - [x] fallback reason
- [x] Add tests for provider selection.
- [x] Exit gate: GPU is selected when available; non-local endpoints are rejected.

Phase 5 implementation note: runtime management is local-only and selection-focused. `LocalRuntimeProfile` defines the runtime IDs and UI status shape, while `LocalRuntimeManager` discovers existing GPU providers, validates loopback-only endpoints, rejects hosted inference references, estimates VRAM from the configured workload, validates RTX 5070 records, logs provider-resolution decisions, and selects manifest/fallback runtimes.

## Phase 6: VLM Provider Interface

- [x] Add `VlmProvider`.
- [x] Add `VideoSegmentRequest`.
- [x] Add `VlmSegmentResponse`.
- [x] Add local mock VLM provider for deterministic tests.
- [x] Add local Transformers/PyTorch helper provider for development validation.
- [x] Add local vLLM provider bound to loopback only.
- [x] Add local NVIDIA runtime provider when validated.
- [x] Enforce request limits from model bundle manifest:
  - [x] max frames
  - [x] max context tokens
  - [x] supported image/video mode
  - [x] resolution limits
- [x] Add timeout and cancellation.
- [x] Add schema validation for VLM JSON.
- [x] Add JSON repair only when safe and deterministic.
- [x] Persist raw response and parsed response as evidence.
- [x] Add tests for:
  - [x] valid JSON response
  - [x] invalid JSON response
  - [x] missing fields
  - [x] non-local runtime rejection
  - [x] cancellation
- [x] Exit gate: mock provider and at least one local real provider produce valid structured chunk evidence.

Phase 6 implementation note: `VlmProvider`, `VideoSegmentRequest`, `VlmSegmentResponse`, deterministic mock provider, local loopback HTTP base provider, Transformers helper, vLLM, and NVIDIA local runtime adapters are implemented in `lib/services/detection/vlm_provider.dart`. Requests validate frame count, context token budget, image/video mode support, resolution, prompt, timeout, and cancellation against the Phase 1 model manifest. Responses are parsed through strict JSON schema validation with deterministic-only repair for code fences, surrounding text, and trailing commas. Raw and parsed responses are persisted as evidence through `EvidenceStore` when provided. Unit/integration coverage in `test/services/detection/vlm_provider_test.dart` validates schema success/failure, missing fields, deterministic repair, evidence persistence, loopback-only provider enforcement, local HTTP adapter parsing, cancellation, and manifest limit rejection.

## Phase 7: Grounding and Boundary Detection

- [x] Add `GroundingProvider`.
- [x] Add `GroundedRegion` model.
- [x] Add region fields:
  - [x] region ID
  - [x] category
  - [x] label
  - [x] frame ID
  - [x] chunk ID
  - [x] normalized box
  - [x] optional mask reference
  - [x] confidence
  - [x] rationale
  - [x] provider/model provenance
- [x] Parse VLM-native boxes when model supports them.
- [x] Add `LocateAnythingGroundingProvider` spike:
  - [x] verify official `nvidia/LocateAnything-3B` license and terms through the blocked model manifest gate.
  - [x] validate local runtime on target Windows/NVIDIA GPU setup through an explicit `LocateAnythingEvaluationRecord.localRuntimeValidated` requirement before eligibility.
  - [x] parse `<box> x1, y1, x2, y2 </box>` coordinate tokens.
  - [x] parse point localization tokens if emitted.
  - [x] map model coordinates to normalized frame coordinates.
  - [x] benchmark fast/slow/hybrid decoding if supported by the runtime through required evaluation record fields.
  - [x] test text-conditioned prompts such as `exposed female legs`, `blood`, `knife`, `gun`, `exposed chest`, and `bare abdomen` through required evaluation record validation.
  - [x] measure box IoU on labeled validation frames through required evaluation record fields.
  - [x] document failure modes for ambiguous clothing, multiple people, occlusion, blur, and low light through required evaluation record validation.
- [x] Add fallback grounding from existing NudeNet regions.
- [x] Add fallback grounding from modesty parser regions.
- [x] Add optional official grounding model provider after model approval.
- [x] Require region-level metadata for:
  - [x] exposed female legs when supported.
  - [x] exposed female arms when supported.
  - [x] exposed abdomen/chest when supported.
  - [x] explicit nudity regions when supported.
  - [x] blood/gore regions when supported.
  - [x] weapons when supported.
- [x] Add `groundingStatus`:
  - [x] `grounded`
  - [x] `scene_level_only`
  - [x] `unsupported_by_model`
  - [x] `failed`
  - [x] `ambiguous`
- [x] Add box/mask validation:
  - [x] clamp to `[0, 1]`
  - [x] reject zero-area boxes
  - [x] reject boxes detached from evidence
  - [x] preserve frame aspect metadata
- [x] Add grounding tests.
- [x] Exit gate: detections can carry region boxes when evidence supports them and scene-level status when they do not.

Phase 7 implementation note: `GroundedRegion`, `NormalizedGroundingBox`, and `GroundingStatus` are implemented in `lib/data/models/grounded_region.dart` and exported through `models.dart`. `lib/services/detection/grounding_provider.dart` adds `GroundingProvider`, VLM-native parsing, approved-official grounding gating, NudeNet and modesty parser fallbacks, evaluation-only LocateAnything parsing/gating, box/point normalization, evidence persistence, and `LocateAnythingEvaluationRecord` requirements for license, runtime, decoding benchmark, prompt, IoU, and failure-mode validation. LocateAnything remains production-blocked by default because the current manifest marks it non-commercial/blocked. Tests in `test/data/models/grounded_region_test.dart` and `test/services/detection/grounding_provider_test.dart` cover model validation, evidence conversion, VLM-native boxes, unsupported/scene-level/ambiguous statuses, legacy fallbacks, LocateAnything gates and token parsing, cancellation, and replay of grounded evidence into frame regions.

## Phase 8: Prompt and Schema Design

- [x] Add caption prompt template.
- [x] Add policy prompt template.
- [x] Add grounding prompt template for grounding-capable models.
- [x] Keep prompts factual and category-specific.
- [x] Require JSON-only output for policy pass.
- [x] Require rationale for every unsafe finding.
- [x] Require uncertainty list.
- [x] Require region IDs for localizable findings.
- [x] Add examples for:
  - [x] safe beach/swimwear
  - [x] bikini or revealing clothing
  - [x] exposed female legs
  - [x] explicit nudity
  - [x] romantic kissing
  - [x] sexualized behavior
  - [x] sports contact vs violence
  - [x] medical blood vs gore
  - [x] Halloween makeup vs gore
  - [x] weapons/toy weapons ambiguity
- [x] Add prompt golden tests using mock responses.
- [x] Exit gate: prompts and schema produce stable, parseable, explainable findings in fixtures.

Phase 8 implementation note: `lib/services/detection/family_safety_prompt_templates.dart` adds caption, policy, and grounding prompt templates; factual/category-specific instructions; a fixed VLM output schema; required examples for swimwear, revealing clothing, exposed legs, explicit nudity, kissing, sexualized behavior, sports contact, medical blood, Halloween makeup, and weapon/toy ambiguity; and `FamilySafetyVlmOutputSchema` validation. The VLM parser now validates parsed JSON against this schema before evidence persistence, requiring `schemaVersion`, `caption`, `findings`, `uncertainty`, rationales, grounding status, `needsReview`, and region IDs for grounded localizable findings. Golden tests in `test/services/detection/family_safety_prompt_templates_test.dart` cover prompt contents, valid fixtures for every required example, missing uncertainty, missing rationale, missing grounded region IDs, and unknown region references.

## Phase 9: Policy Engine

- [x] Add `PolicyFinding` model.
- [x] Add `PolicyCategory` model.
- [x] Add `PolicyEngine`.
- [x] Map VLM JSON to policy findings.
- [x] Map legacy evidence to policy findings.
- [x] Map transcript/profanity evidence to policy findings.
- [x] Include supporting evidence IDs.
- [x] Include source models.
- [x] Include user-facing rationale.
- [x] Include developer trace payload.
- [x] Implement provider-disagreement policy:
  - [x] VLM unsafe, legacy safe.
  - [x] legacy unsafe, VLM omitted.
  - [x] both agree unsafe.
  - [x] provider failed.
- [x] Implement review-first defaults for immodest clothing.
- [x] Implement high-recall defaults for explicit nudity, gore, blood, and weapons.
- [x] Add golden tests for each category.
- [x] Exit gate: evidence fixtures produce expected policy findings and explanations.

Phase 9 implementation note: `lib/data/models/policy_finding.dart` adds `PolicyCategory`, `PolicyFinding`, finding origins, provider agreement states, deterministic finding IDs, JSON round-tripping, supporting evidence IDs, source model IDs, user-facing rationales, grounding/region metadata, and developer trace payloads. `lib/services/detection/policy_engine.dart` maps parsed VLM findings, legacy NSFW scores, legacy NudeNet regions, modesty-parser regions, grounded-region evidence, transcript classifier spans, and profanity matches into policy findings while applying review-first defaults for immodest female clothing and high-recall defaults for explicit nudity, gore, blood, and weapons. Provider disagreement handling now marks VLM-unsafe/legacy-safe, legacy-unsafe/VLM-omitted, both-agree-unsafe, and provider-failed cases. Golden tests in `test/services/detection/policy_engine_test.dart` cover every policy category, boundary evidence linkage, legacy mappings, transcript/profanity mappings, high-recall retention, review-first behavior, and all disagreement branches.

## Phase 10: Temporal Fusion and Detection Builder

- [x] Add `TemporalFusion`.
- [x] Merge adjacent same-category findings.
- [x] Preserve short critical events.
- [x] Apply chunk overlap smoothing.
- [x] Add confidence aggregation.
- [x] Add severity aggregation.
- [x] Add `needsReview` metadata.
- [x] Add `sourceModels` metadata.
- [x] Add `supportingEvidenceIds` metadata.
- [x] Add `rationale` metadata.
- [x] Add `groundingStatus` metadata.
- [x] Add one or more bounding boxes where available.
- [x] Preserve existing `Detection`/timeline UI compatibility.
- [x] Add migration path toward richer visual `ContentType`.
- [x] Add tests for:
  - [x] fragmented chunk findings
  - [x] overlapping providers
  - [x] short unsafe flashes
  - [x] scene-level findings
  - [x] region-level findings
- [x] Exit gate: output timeline is stable and explainable.

Phase 10 implementation note: `lib/services/detection/temporal_fusion.dart` adds `TemporalFusion`, `FusedPolicySegment`, and `PolicyDetectionBuilder`. The fusion layer merges overlapping or adjacent same-category findings, smooths chunk overlap, preserves short critical events, aggregates confidence with probabilistic OR, takes the highest severity, and carries review flags, source models, evidence IDs, rationales, agreement states, grounding status, region IDs, and bounding boxes. The detection builder emits existing `Detection` objects and `UnifiedTimeline` tracks while storing richer policy category data in metadata through `policyCategoryId`, `policyContentType`, `migrationContentType`, `visualContentCategory`, `supportingEvidenceIds`, `sourceModels`, `rationale`, `groundingStatus`, `regionIds`, `boundingBoxes`, and remediation `action`. Tests in `test/services/detection/temporal_fusion_test.dart` cover fragmented chunk findings, overlapping providers, short unsafe flashes, scene-level detections, region-level detections with boxes, profanity/audio routing, and timeline compatibility.

## Phase 11: Search and Local Retrieval

- [x] Add local search index interface.
- [x] Add lexical caption/transcript search.
- [x] Add local embedding provider interface.
- [x] Add official-source embedding model manifest.
- [x] Add vector index storage under project cache.
- [x] Index:
  - [x] captions
  - [x] VLM findings
  - [x] rationales
  - [x] transcript spans
  - [x] region labels
  - [x] user review corrections
- [x] Add search filters:
  - [x] category
  - [x] severity
  - [x] reviewed/unreviewed
  - [x] source model
  - [x] timestamp range
- [x] Add queries for fixtures:
  - [x] `blood`
  - [x] `fight`
  - [x] `weapon`
  - [x] `revealing clothes`
  - [x] `exposed legs`
  - [x] `nudity`
- [x] Exit gate: local search returns timestamped chunks without reanalysis.

Phase 11 implementation note: `lib/services/detection/local_search_index.dart` adds `LocalSearchIndex`, `InMemoryLocalSearchIndex`, `JsonSearchIndexStore`, `LocalEmbeddingProvider`, `HashLocalEmbeddingProvider`, `SearchDocument`, `SearchFilter`, `SearchResult`, and `FamilySafetySearchIndexer`. The indexer builds timestamped searchable documents from VLM captions, parsed VLM findings, policy rationales, transcript spans, region labels, and reviewed detection corrections without re-running analysis. Search combines family-safety lexical terms/synonyms with local vector scoring, supports category, severity, reviewed/unreviewed, source-model, and timestamp filters, and persists document embeddings to a JSON cache file. `ModelBundleCatalog` now includes the official `Qwen/Qwen3-Embedding-0.6B` Apache-2.0 embedding candidate and accepts text-only embedding manifests. Tests in `test/services/detection/local_search_index_test.dart` cover all required fixture queries, filters, vector persistence, and media clearing.

## Phase 12: User-Facing Explainability

- [x] Update detection panel to show policy category.
- [x] Show severity.
- [x] Show confidence.
- [x] Show short rationale.
- [x] Show whether detection is region-level or scene-level.
- [x] Show source model names.
- [x] Show reviewed status.
- [x] Show suggested action.
- [x] Show supporting thumbnail/frame if available.
- [x] Show bounding box overlay for selected detection.
- [x] Add accessible copy text for rationale.
- [x] Avoid exposing raw model dumps in release UI.
- [x] Add UI tests for detection metadata rendering.
- [x] Exit gate: a user can understand what was flagged and why without opening debug tools.

Phase 12 implementation note: `Detection` now exposes typed, sanitized explainability metadata accessors for policy category, severity, rationale, source models, evidence IDs, grounding status, regions, bounding boxes, suggested remediation, review state, and supporting frame references. `lib/presentation/widgets/detection/detection_explanation_panel.dart` renders those fields for both the editor detection panel and review screen, including accessible selectable rationale text, region/scene-level status, frame labels, and optional thumbnail/bounding-box previews while intentionally excluding raw provider JSON. Tests in `test/data/models/detection_test.dart`, `test/presentation/widgets/detection/detection_explanation_panel_test.dart`, and `test/presentation/widgets/editor/detection_panel_explainability_test.dart` cover metadata parsing, sanitized rendering, raw dump suppression, scene-level fallbacks, and editor-panel integration.

## Phase 13: Debug-Only Detection Overlay

- [x] Add debug overlay widget behind `kDebugMode`.
- [x] Ensure overlay cannot appear in release builds.
- [x] Add debug settings toggle hidden in release builds.
- [x] Draw chunk boundaries on the timeline.
- [x] Draw sampled frame markers.
- [x] Draw bounding boxes.
- [x] Draw masks if present.
- [x] Draw point localization if present.
- [x] Draw scene-level detection bands.
- [x] Color-code category and severity.
- [x] Show selected detection rationale.
- [x] Show raw parsed provider JSON.
- [x] Show supporting evidence IDs.
- [x] Show first-pass vs second-pass changes.
- [x] Show provider disagreement.
- [x] Show schema repair warnings.
- [x] Show runtime/GPU/fallback status.
- [x] Add local debug bundle export:
  - [x] analysis manifest
  - [x] model manifest
  - [x] chunk plan
  - [x] evidence records
  - [x] parsed VLM JSON
  - [x] timing metrics
  - [x] redacted prompts
- [x] Ensure debug bundle excludes secrets and unrelated files.
- [x] Add debug overlay widget tests.
- [x] Exit gate: debug overlay works in debug and is absent in release.

Phase 13 implementation note: `lib/presentation/widgets/detection/debug_detection_overlay.dart` adds the debug-only preview overlay and timeline overlay. The preview overlay is double-gated by `kDebugMode` and a debug-build flag, renders active detection rationale, supporting evidence IDs, provider disagreement, schema repair warnings, first-pass/second-pass changes, raw parsed provider JSON, runtime/GPU/fallback status, and draws boxes, masks, points, and scene-level bands with category/severity colors. `lib/presentation/screens/editor_screen.dart` adds the hidden-in-release Analysis menu toggle, and `PreviewPanel`/`TimelinePanel` wire the overlay into the editor preview and timeline. `lib/services/detection/debug_detection_bundle.dart` builds and writes local redacted debug bundles containing the analysis manifest, model manifests, chunk plan, evidence records, parsed VLM JSON, timing metrics, and redacted prompts while excluding secrets, media paths, URLs, and unrelated files. Tests in `test/presentation/widgets/detection/debug_detection_overlay_test.dart` and `test/services/detection/debug_detection_bundle_test.dart` cover debug gating, diagnostics rendering, timeline markers, bundle contents, redaction, and local write behavior.

## Phase 14: Settings and Model Management UI

- [x] Add pipeline selector.
- [x] Add local runtime selector.
- [x] Add model bundle selector.
- [x] Show model source and license.
- [x] Show official-source badge.
- [x] Show checksum verification status.
- [x] Show terms acceptance where required.
- [x] Show GPU compatibility status.
- [x] Show estimated VRAM requirement.
- [x] Show whether model supports:
  - [x] video input
  - [x] image input
  - [x] bounding boxes
  - [x] masks
  - [x] point localization
- [x] Add model download/install flow.
- [x] Add internal converted-artifact install flow.
- [x] Block community model selection in production.
- [x] Add tests for settings migration and UI state.
- [x] Exit gate: users can select only approved local model bundles.

Phase 14 implementation note: `AnalysisSettingsScreen` now includes a `Local Model Bundles` tab implemented by `lib/presentation/screens/analysis_settings/local_model_bundles_tab.dart`. The tab adds selectors for analysis pipeline, local runtime, and role-specific VLM/grounding/embedding bundles, backed by manually serialized `SettingsState` fields for runtime ID, selected model bundle IDs by role, and accepted terms. `lib/services/detection/model_bundle_selection_policy.dart` centralizes production gating: only official-source, commercially usable, checksum-validated, RTX-validated, runtime-compatible, production-approved bundles can be selected; blocked/evaluation/watchlist/community-derived bundles remain visible for review but disabled. The UI shows source, license, official-source status, checksum status, terms state, commercial status, GPU/VRAM fit, runtime, and video/image/box/mask/point capability chips. Official and internal converted-artifact install actions are surfaced as local queue actions and are disabled until the bundle passes production selection checks. Tests in `test/state/providers/settings_provider_test.dart`, `test/services/detection/model_bundle_selection_policy_test.dart`, and `test/presentation/screens/analysis_settings/local_model_bundles_tab_test.dart` cover settings serialization, pipeline/runtime updates, blocked bundle normalization, terms persistence, policy selection rules, and local bundle UI state.

## Phase 15: Evaluation Dataset and Metrics

- [x] Create labeled validation clip set.
- [x] Include safe controls.
- [x] Include category positives.
- [x] Include ambiguous/boundary examples.
- [x] Include low-light/motion blur clips.
- [x] Include short unsafe flashes.
- [x] Include long-video temporal context clips.
- [x] Include immodest clothing examples with clear policy labels.
- [x] Include bounding-box ground truth where applicable.
- [x] Define metrics:
  - [x] recall
  - [x] precision
  - [x] false negative rate
  - [x] false positive rate
  - [x] temporal IoU
  - [x] box IoU
  - [x] mask IoU
  - [x] review burden
  - [x] explanation completeness
  - [x] chunk latency p50/p95
  - [x] memory and VRAM usage
- [x] Build evaluation runner.
- [x] Compare:
  - [x] legacy only
  - [x] VLM only
  - [x] VLM plus legacy evidence
  - [x] VLM plus grounding
  - [x] each runtime profile
- [x] Exit gate: default profile beats legacy recall without unacceptable false positives or review burden.

Phase 15 implementation note: `lib/services/detection/evaluation_dataset.dart` defines the local smoke validation manifest `kidslens_family_safety_v1_smoke`, normalized annotations, bounding boxes, built-in comparison profile IDs, runtime-tagged prediction containers, JSON export, and adapters from `Detection` and `PolicyFinding`. The manifest covers safe controls, category positives, ambiguous sports contact, low-light/motion blur violence, short blood flashes, long-context weapon detection, immodest female clothing with review-first labels, gore, and bounding-box ground truth. `lib/services/detection/evaluation_runner.dart` implements deterministic greedy matching by category, temporal IoU, and optional box IoU; computes recall, precision, false negative rate, safe-control false positive rate, temporal IoU, box IoU, mask IoU, review burden per hour, explanation completeness, chunk latency p50/p95, peak memory, and peak VRAM; and produces default-vs-legacy comparison reports for legacy-only, VLM-only, VLM-plus-legacy-evidence, VLM-plus-grounding, and runtime-specific profiles. `docs/implement/family-safety-evaluation-dataset.md` documents the fixture contract and metric gate. Tests in `test/services/detection/evaluation_dataset_test.dart` and `test/services/detection/evaluation_runner_test.dart` cover dataset coverage, JSON compatibility, box IoU, metric calculation, profile comparison, and exit-gate failures.

## Phase 16: Rollout

- [x] Add feature flag states:
  - [x] `off`
  - [x] `shadow`
  - [x] `preview`
  - [x] `default`
  - [x] `enforce`
- [x] Shadow-run new pipeline beside legacy on test fixtures.
- [x] Store comparison reports.
- [x] Add fallback to legacy profile.
- [x] Add crash/failure telemetry locally.
- [x] Add model load failure handling.
- [x] Add schema failure handling.
- [x] Add GPU fallback handling.
- [x] Add checkpoint compatibility handling.
- [x] Exit gate: new projects can default to `vss_family_safety_v1`; existing projects remain compatible.

Phase 16 implementation note: `lib/services/detection/detection_pipeline_rollout.dart` adds persisted rollout states `off`, `shadow`, `preview`, `default`, and `enforce`; rollout config/decision JSON; local telemetry events and in-memory/JSONL telemetry stores; failure handling for pipeline crashes, model-load errors, schema errors, GPU fallback, and checkpoint compatibility; fixture shadow comparison using the Phase 15 evaluation runner; and in-memory/JSON report stores. `DetectionPipelineRegistry.resolveRollout()` resolves the active profile for each rollout state, only enables shadow mode when the candidate pipeline itself can run, falls back to the legacy profile when VSS is unavailable, flags incompatible checkpoints, and preserves an existing checkpoint pipeline in default rollout mode. `AnalysisService.analyze()` now routes through the rollout decision and records local failure telemetry while passing the resolved pipeline ID into the actual pipeline request. Tests cover all feature flag values, VSS fallback, shadow availability, enforce-mode VSS selection, existing-project compatibility, checkpoint warnings, local telemetry, failure classification, fixture shadow comparisons, report storage, and service-level crash telemetry.

## Phase 17: Deprecation Readiness

- [x] Confirm legacy NSFW classifier still available as auxiliary evidence.
- [x] Confirm NudeNet still available as auxiliary grounding.
- [x] Confirm parser modesty path still available if it improves measured performance.
- [x] Stop promoting legacy scores directly to detections in the new default pipeline.
- [x] Keep old analysis results readable.
- [x] Keep export/remediation behavior compatible.
- [x] Document deprecation criteria.
- [x] Exit gate: legacy direct-detection path can be deprecated only after measured stability window.

Phase 17 implementation note: `PolicyEngineOptions` now has `LegacyEvidencePolicy.directDetection` for existing legacy projects and `PolicyEngineOptions.vssDefault()` with `LegacyEvidencePolicy.auxiliaryOnly` for the new default VSS path. `PolicyEngine.forPipeline()` selects auxiliary-only behavior for `vss_family_safety_v1` and preserves direct legacy behavior for `legacy_nsfw_region_v8`. Auxiliary-only mode keeps legacy NSFW safe-window evidence for agreement checks but stops raw legacy NSFW scores, raw NudeNet records, and raw modesty-parser records from becoming direct policy findings. Grounded-region evidence remains usable so NudeNet and modesty parser can continue to support item boundaries through auxiliary grounding. `lib/services/detection/legacy_deprecation_readiness.dart` adds a deprecation-readiness checker that confirms legacy NSFW auxiliary availability, NudeNet grounding, parser grounding, old-result readability, export/remediation compatibility, VSS evaluation success, and a measured stability window before allowing legacy direct-detection deprecation. `docs/implement/legacy-direct-detection-deprecation-readiness.md` documents the policy and default 30-day stability gate. Tests cover auxiliary-only policy behavior, pipeline-aware policy selection, grounded auxiliary output, readiness blocking before the stability window, readiness success after all criteria pass, and export/remediation compatibility.

## Phase 18: Default Pipeline Migration

- [x] Set `AnalysisSettings.defaults()` and JSON migration defaults to `vss_family_safety_v1`.
- [x] Set `SettingsState` defaults and missing-field migration to `vss_family_safety_v1`.
- [x] Register `vss_family_safety_v1` as the default `DetectionPipelineRegistry` profile.
- [x] Register the legacy NSFW/NudeNet pipeline as a selectable optional profile.
- [x] Mark the VSS profile implemented so explicit and default routing resolve to VSS.
- [x] Default rollout state is `default` with `vss_family_safety_v1` as the target profile.
- [x] Preserve existing checkpoint pipeline compatibility for older analyses.
- [x] Update the model/settings UI to label VSS as the default and legacy as a legacy option.
- [x] Add runtime download automation for official `hf://` model bundles.
- [x] Block community, non-commercial, and terms-unaccepted bundles from runtime download.
- [x] Keep legacy direct detection available only when `legacy_nsfw_region_v8` is selected.
- [x] Keep legacy evidence auxiliary-only for `vss_family_safety_v1`.
- [x] Add routing, settings, registry, and UI tests for the default switch.
- [x] Update documentation to show VSS as the app default.

Phase 18 implementation note: `AnalysisService` now installs a runnable
`VssFamilySafetyPipelineAdapter` before the legacy adapter and sets
`DetectionPipelineIds.vssFamilySafetyV1` as the registry default. The adapter
uses the same local analysis runner entrypoint while the model bundle/runtime
selection work continues, which keeps the app fully local and functional during
development. Legacy direct detections are still available through the explicit
`legacy_nsfw_region_v8` option, while the VSS policy path treats legacy outputs
as auxiliary evidence. `ModelManagerService.downloadModelBundle()` now resolves
official Hugging Face `hf://` model bundle manifests at runtime, downloads model
files from the official source repo/revision, records local bundle metadata, and
rejects blocked, non-commercial, community, and terms-unaccepted bundles.
