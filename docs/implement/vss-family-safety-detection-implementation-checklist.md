# VSS-Style Local Family Safety Detection Implementation Checklist

Date: 2026-06-07

Companion plan: `docs/implement/vss-family-safety-detection-revamp-plan.md`

This checklist is ordered for implementation. Each phase should be merged behind feature flags unless the exit gate says otherwise.

## Phase 0: Policy, Scope, and Model Governance

- [ ] Confirm the hard product rule: all inference is local-only.
- [ ] Remove any planned dependency on hosted VLM, LLM, embedding, reranking, or moderation APIs.
- [ ] Define approved inference transport:
  - [ ] In-process native runtime.
  - [ ] Local helper process.
  - [ ] Local loopback server on `localhost` or `127.0.0.1`.
  - [ ] Explicitly reject non-loopback URLs.
- [ ] Define v1 policy taxonomy:
  - [ ] `explicit_nudity`
  - [ ] `sexual_content`
  - [ ] `suggestive_content`
  - [ ] `immodest_female_clothing`
  - [ ] `violence`
  - [ ] `gore`
  - [ ] `blood`
  - [ ] `weapons`
  - [ ] `substances`
  - [ ] `profanity`
- [ ] Define default action per category:
  - [ ] region blur
  - [ ] full-frame blur
  - [ ] cut scene
  - [ ] beep/mute
  - [ ] review only
- [ ] Define per-category severity levels:
  - [ ] `none`
  - [ ] `low`
  - [ ] `medium`
  - [ ] `high`
  - [ ] `critical`
- [ ] Define per-category enforcement mode:
  - [ ] review-first
  - [ ] enforce when high confidence
  - [ ] always manual review
- [ ] Define category-specific boundary requirements:
  - [ ] explicit nudity should use region bounds when available.
  - [ ] immodest female clothing should use region bounds when available.
  - [ ] blood/gore should use region bounds when available.
  - [ ] weapons should use object bounds when available.
  - [ ] violence may be scene-level when no object-level boundary is meaningful.
- [ ] Define explainability requirements:
  - [ ] user-facing category
  - [ ] severity
  - [ ] confidence
  - [ ] short rationale
  - [ ] timestamp range
  - [ ] region/scene-level status
  - [ ] source model names
  - [ ] supporting evidence IDs
- [ ] Define prohibited model sources:
  - [ ] community ports
  - [ ] unofficial quantizations
  - [ ] hosted inference providers
  - [ ] model files without checksums
  - [ ] model files without license metadata
- [ ] Define accepted official source organizations:
  - [ ] `nvidia`
  - [ ] `Qwen` / Alibaba
  - [ ] `google`
  - [ ] `microsoft`
  - [ ] `meta-llama`
  - [ ] `mistralai` only as an optional major-provider watchlist vendor.
  - [ ] other future major providers only after review.
- [ ] Define internal conversion policy:
  - [ ] conversion must start from official weights.
  - [ ] conversion recipe must be committed or versioned.
  - [ ] output artifact must include checksum.
  - [ ] artifact must be published to a KidsLens-owned Hugging Face repo or controlled release bucket.
  - [ ] model manifest must link official source revision to converted artifact revision.
  - [ ] quantized artifacts must be reproducible from official weights.
  - [ ] quantized artifacts must be validated on an RTX 5070 12 GB profile before app selection.
- [ ] Create a model-approval record template.
- [ ] Create a policy-review record template.
- [ ] Exit gate: policy taxonomy, local-only rule, model-source rule, and explainability contract are approved.

## Phase 1: Model Bundle Manifest

- [ ] Add a model bundle manifest model, likely under `lib/data/models/`.
- [ ] Include required fields:
  - [ ] `modelId`
  - [ ] `displayName`
  - [ ] `vendor`
  - [ ] `officialSourceRepo`
  - [ ] `officialRevision`
  - [ ] `license`
  - [ ] `acceptedTermsRequired`
  - [ ] `artifactType`
  - [ ] `artifactUri`
  - [ ] `sha256`
  - [ ] `conversionRecipeId`
  - [ ] `runtime`
  - [ ] `minVramGb`
  - [ ] `recommendedVramGb`
  - [ ] `targetGpuClass`, initially `rtx_5070_12gb`
  - [ ] `maxValidatedVramGb`, initially `12`
  - [ ] `quantization`
  - [ ] `fitsRtx5070Validated`
  - [ ] `supportsVideoInput`
  - [ ] `supportsImageInput`
  - [ ] `supportsBoundingBoxes`
  - [ ] `supportsMasks`
  - [ ] `supportsPointLocalization`
  - [ ] `maxFramesPerChunk`
  - [ ] `maxContextTokens`
  - [ ] `recommendedChunkSeconds`
  - [ ] `knownFailureModes`
- [ ] Add approved initial VLM candidates sized for RTX 5070-class GPUs:
  - [ ] `nvidia/Cosmos-Reason1-7B`
  - [ ] `nvidia/NVIDIA-Nemotron-Nano-12B-v2-VL-FP8` only after RTX 5070 validation.
  - [ ] KidsLens-owned NVFP4/4-bit Nemotron artifact if FP8 does not leave enough VRAM headroom.
  - [ ] `Qwen/Qwen3.5-4B`
  - [ ] `Qwen/Qwen3.5-2B` as an optional lightweight fallback if quality is acceptable.
  - [ ] `google/gemma-4-E4B-it`
  - [ ] `google/gemma-4-12B-it` only as a tight 4-bit profile after RTX 5070 validation.
  - [ ] `microsoft/Phi-4-multimodal-instruct`
  - [ ] `microsoft/Phi-4-multimodal-instruct-onnx`
  - [ ] `meta-llama/Llama-4-Scout-17B-16E-Instruct` only after license acceptance and RTX 5070 validation.
  - [ ] `nvidia/Llama-4-Scout-17B-16E-Instruct-FP8` as an official-derived R&D reference only until RTX 5070 fit is proven.
- [ ] Add license/commercial-use review for each model:
  - [ ] NVIDIA Cosmos Reason1: NVIDIA Open Model License, commercial-use check.
  - [ ] NVIDIA Nemotron Nano VL: NVIDIA Open Model License, commercial-use check.
  - [ ] NVIDIA LocateAnything: current non-commercial license blocks production use; keep optional/disabled by default.
  - [ ] Alibaba Qwen3.5: Apache 2.0 check.
  - [ ] Google Gemma 4: Apache 2.0 check.
  - [ ] Microsoft Phi-4 multimodal: MIT check.
  - [ ] Microsoft Phi-4 multimodal ONNX: MIT check.
  - [ ] Meta Llama 4 Scout: Llama 4 Community License, 700M MAU and acceptable-use checks.
  - [ ] NVIDIA Llama 4 Scout FP8: NVIDIA Open Model License plus upstream Llama 4 obligation review.
- [ ] Add approved initial grounding candidates:
  - [ ] `nvidia/LocateAnything-3B` as optional grounding evaluation only; disabled by default unless the license permits production use.
  - [ ] official grounding/localization models from approved vendors only after validation.
- [ ] Add optional major-provider watchlist candidates for evaluation, not default selection:
  - [ ] `mistralai/Pixtral-12B-*` only if 4-bit conversion and RTX 5070 validation pass.
- [ ] Explicitly exclude from RTX 5070 production candidates until proven otherwise:
  - [ ] `nvidia/Cosmos-Reason2-32B`
  - [ ] Gemma 4 26B/31B variants
  - [ ] unvalidated large Qwen3.5 variants
  - [ ] Qwen 14B/32B+ VL variants
  - [ ] `microsoft/Phi-4-vision-reasoning-15B`
  - [ ] Meta Llama 4 Maverick
  - [ ] unvalidated Meta Llama 4 Scout artifacts
  - [ ] OpenGVLab InternVL variants
  - [ ] AllenAI Molmo variants
  - [ ] community quantizations or ports for any model.
- [ ] Record Hugging Face leaderboard sources reviewed:
  - [ ] Open VLM Leaderboard
  - [ ] Vision Arena
  - [ ] MMBench Leaderboard
  - [ ] SEED-Bench Leaderboard
  - [ ] retrieval/document leaderboards when considering embedding/OCR-heavy models.
- [ ] Create an internal KidsLens model scorecard:
  - [ ] family-safety category recall
  - [ ] false positive burden
  - [ ] temporal localization quality
  - [ ] box/mask quality
  - [ ] explanation quality
  - [ ] local GPU throughput
  - [ ] VRAM fit
  - [ ] Windows runtime readiness
  - [ ] license/terms fit
- [ ] Add approved local embedding candidates only after official-source review.
- [ ] Add approved grounding candidates only after official-source review.
- [ ] Add manifest validation:
  - [ ] reject missing official source.
  - [ ] reject missing checksum.
  - [ ] reject community source.
  - [ ] reject unsupported license.
  - [ ] reject cloud-only runtime.
  - [ ] reject non-local artifact URI.
- [ ] Add tests for manifest validation.
- [ ] Exit gate: invalid/community/cloud manifest entries fail tests.

## Phase 2: Pipeline Registry and Legacy Wrapping

- [ ] Add `lib/services/detection/` namespace.
- [ ] Add `DetectionPipeline` interface.
- [ ] Add `DetectionPipelineRegistry`.
- [ ] Add `DetectionPipelineProfile`.
- [ ] Add profile IDs:
  - [ ] `vss_family_safety_v1`
  - [ ] `legacy_nsfw_region_v8`
  - [ ] `audio_only`
  - [ ] `fast_preview`
- [ ] Wrap existing `AnalysisService` visual logic as `LegacyNsfwPipelineAdapter`.
- [ ] Keep current user-facing detections unchanged for `legacy_nsfw_region_v8`.
- [ ] Add `AnalysisSettings.analysisPipelineId`.
- [ ] Route `AnalysisService.analyze()` through the registry.
- [ ] Add tests proving legacy profile output remains compatible.
- [ ] Exit gate: existing tests pass with legacy profile selected.

## Phase 3: Chunked Ingestion

- [ ] Add `VideoChunk` model.
- [ ] Add `SampledFrameRef` model.
- [ ] Add `AnalysisRunManifest` model.
- [ ] Add `ChunkPlanner`.
- [ ] Implement fixed-duration chunking.
- [ ] Implement scene-aware chunking using existing scene detection.
- [ ] Add overlap handling.
- [ ] Add deterministic chunk IDs.
- [ ] Add deterministic frame IDs.
- [ ] Extend `FrameSamplingService` with chunk-aware selection.
- [ ] Support VLM frame selection:
  - [ ] scene start
  - [ ] scene middle
  - [ ] scene end
  - [ ] motion/scene-change frames
  - [ ] max frame limit from model bundle manifest
- [ ] Support legacy fixed-FPS frame selection.
- [ ] Add checkpoint metadata:
  - [ ] pipeline ID
  - [ ] chunk planner hash
  - [ ] model bundle IDs
  - [ ] policy profile hash
  - [ ] sampling hash
- [ ] Add chunk planner unit tests.
- [ ] Add frame selection unit tests.
- [ ] Exit gate: fixed fixture media produces stable chunk/frame plans.

## Phase 4: Evidence Store

- [ ] Add `EvidenceRecord` model.
- [ ] Add evidence types:
  - [ ] `vlm_caption`
  - [ ] `vlm_policy_json`
  - [ ] `grounded_region`
  - [ ] `legacy_nsfw_score`
  - [ ] `legacy_nudenet_region`
  - [ ] `modesty_parser_signal`
  - [ ] `transcript_span`
  - [ ] `profanity_match`
  - [ ] `embedding_record`
- [ ] Add evidence provenance fields:
  - [ ] provider ID
  - [ ] provider version
  - [ ] model bundle ID
  - [ ] model checksum
  - [ ] runtime
  - [ ] GPU provider
  - [ ] input IDs
  - [ ] timestamp range
  - [ ] schema version
- [ ] Add JSON-backed evidence store first.
- [ ] Add SQLite-backed evidence store if project persistence needs query speed.
- [ ] Add evidence replay API.
- [ ] Convert existing NSFW classifier output into evidence records.
- [ ] Convert existing NudeNet output into evidence records.
- [ ] Convert existing modesty parser output into evidence records.
- [ ] Convert transcript/profanity output into evidence records.
- [ ] Add tests that replay evidence into the same findings without rerunning models.
- [ ] Exit gate: analysis can be resumed/replayed from evidence records.

## Phase 5: Local Runtime Management

- [ ] Add `LocalRuntimeProfile`.
- [ ] Add runtime IDs:
  - [ ] `cuda_tensorrt`
  - [ ] `cuda_vllm`
  - [ ] `cuda_transformers_helper`
  - [ ] `directml_onnx`
  - [ ] `cpu_lightweight`
- [ ] Add GPU discovery integration using existing GPU services.
- [ ] Add VRAM estimate checks.
- [ ] Add RTX 5070 12 GB fit validation:
  - [ ] target GPU profile is `rtx_5070_12gb`.
  - [ ] validation uses the configured chunk length.
  - [ ] validation uses the configured frame count.
  - [ ] validation uses the configured frame resolution.
  - [ ] validation uses the configured max output tokens.
  - [ ] validation includes first pass and second pass.
  - [ ] record peak VRAM.
  - [ ] record p50/p95 chunk latency.
  - [ ] record output schema failure rate.
  - [ ] record model/runtime crash rate.
  - [ ] reject profiles that require sustained CPU offload.
- [ ] Add runtime selection:
  - [ ] prefer model manifest runtime.
  - [ ] prefer CUDA/TensorRT when supported.
  - [ ] fallback to CUDA vLLM/helper.
  - [ ] fallback to DirectML/ONNX for compatible artifacts.
  - [ ] fallback to CPU only for lightweight profiles.
- [ ] Add loopback-only local server validation.
- [ ] Reject non-loopback URLs in runtime config.
- [ ] Reject hosted model names or inference endpoints.
- [ ] Add structured provider-resolution logs.
- [ ] Add UI-visible runtime status:
  - [ ] runtime name
  - [ ] model name
  - [ ] GPU device
  - [ ] VRAM estimate
  - [ ] fallback reason
- [ ] Add tests for provider selection.
- [ ] Exit gate: GPU is selected when available; non-local endpoints are rejected.

## Phase 6: VLM Provider Interface

- [ ] Add `VlmProvider`.
- [ ] Add `VideoSegmentRequest`.
- [ ] Add `VlmSegmentResponse`.
- [ ] Add local mock VLM provider for deterministic tests.
- [ ] Add local Transformers/PyTorch helper provider for development validation.
- [ ] Add local vLLM provider bound to loopback only.
- [ ] Add local NVIDIA runtime provider when validated.
- [ ] Enforce request limits from model bundle manifest:
  - [ ] max frames
  - [ ] max context tokens
  - [ ] supported image/video mode
  - [ ] resolution limits
- [ ] Add timeout and cancellation.
- [ ] Add schema validation for VLM JSON.
- [ ] Add JSON repair only when safe and deterministic.
- [ ] Persist raw response and parsed response as evidence.
- [ ] Add tests for:
  - [ ] valid JSON response
  - [ ] invalid JSON response
  - [ ] missing fields
  - [ ] non-local runtime rejection
  - [ ] cancellation
- [ ] Exit gate: mock provider and at least one local real provider produce valid structured chunk evidence.

## Phase 7: Grounding and Boundary Detection

- [ ] Add `GroundingProvider`.
- [ ] Add `GroundedRegion` model.
- [ ] Add region fields:
  - [ ] region ID
  - [ ] category
  - [ ] label
  - [ ] frame ID
  - [ ] chunk ID
  - [ ] normalized box
  - [ ] optional mask reference
  - [ ] confidence
  - [ ] rationale
  - [ ] provider/model provenance
- [ ] Parse VLM-native boxes when model supports them.
- [ ] Add `LocateAnythingGroundingProvider` spike:
  - [ ] verify official `nvidia/LocateAnything-3B` license and terms.
  - [ ] validate local runtime on target Windows/NVIDIA GPU setup.
  - [ ] parse `<box> x1, y1, x2, y2 </box>` coordinate tokens.
  - [ ] parse point localization tokens if emitted.
  - [ ] map model coordinates to normalized frame coordinates.
  - [ ] benchmark fast/slow/hybrid decoding if supported by the runtime.
  - [ ] test text-conditioned prompts such as `exposed female legs`, `blood`, `knife`, `gun`, `exposed chest`, and `bare abdomen`.
  - [ ] measure box IoU on labeled validation frames.
  - [ ] document failure modes for ambiguous clothing, multiple people, occlusion, blur, and low light.
- [ ] Add fallback grounding from existing NudeNet regions.
- [ ] Add fallback grounding from modesty parser regions.
- [ ] Add optional official grounding model provider after model approval.
- [ ] Require region-level metadata for:
  - [ ] exposed female legs when supported.
  - [ ] exposed female arms when supported.
  - [ ] exposed abdomen/chest when supported.
  - [ ] explicit nudity regions when supported.
  - [ ] blood/gore regions when supported.
  - [ ] weapons when supported.
- [ ] Add `groundingStatus`:
  - [ ] `grounded`
  - [ ] `scene_level_only`
  - [ ] `unsupported_by_model`
  - [ ] `failed`
  - [ ] `ambiguous`
- [ ] Add box/mask validation:
  - [ ] clamp to `[0, 1]`
  - [ ] reject zero-area boxes
  - [ ] reject boxes detached from evidence
  - [ ] preserve frame aspect metadata
- [ ] Add grounding tests.
- [ ] Exit gate: detections can carry region boxes when evidence supports them and scene-level status when they do not.

## Phase 8: Prompt and Schema Design

- [ ] Add caption prompt template.
- [ ] Add policy prompt template.
- [ ] Add grounding prompt template for grounding-capable models.
- [ ] Keep prompts factual and category-specific.
- [ ] Require JSON-only output for policy pass.
- [ ] Require rationale for every unsafe finding.
- [ ] Require uncertainty list.
- [ ] Require region IDs for localizable findings.
- [ ] Add examples for:
  - [ ] safe beach/swimwear
  - [ ] bikini or revealing clothing
  - [ ] exposed female legs
  - [ ] explicit nudity
  - [ ] romantic kissing
  - [ ] sexualized behavior
  - [ ] sports contact vs violence
  - [ ] medical blood vs gore
  - [ ] Halloween makeup vs gore
  - [ ] weapons/toy weapons ambiguity
- [ ] Add prompt golden tests using mock responses.
- [ ] Exit gate: prompts and schema produce stable, parseable, explainable findings in fixtures.

## Phase 9: Policy Engine

- [ ] Add `PolicyFinding` model.
- [ ] Add `PolicyCategory` model.
- [ ] Add `PolicyEngine`.
- [ ] Map VLM JSON to policy findings.
- [ ] Map legacy evidence to policy findings.
- [ ] Map transcript/profanity evidence to policy findings.
- [ ] Include supporting evidence IDs.
- [ ] Include source models.
- [ ] Include user-facing rationale.
- [ ] Include developer trace payload.
- [ ] Implement provider-disagreement policy:
  - [ ] VLM unsafe, legacy safe.
  - [ ] legacy unsafe, VLM omitted.
  - [ ] both agree unsafe.
  - [ ] provider failed.
- [ ] Implement review-first defaults for immodest clothing.
- [ ] Implement high-recall defaults for explicit nudity, gore, blood, and weapons.
- [ ] Add golden tests for each category.
- [ ] Exit gate: evidence fixtures produce expected policy findings and explanations.

## Phase 10: Temporal Fusion and Detection Builder

- [ ] Add `TemporalFusion`.
- [ ] Merge adjacent same-category findings.
- [ ] Preserve short critical events.
- [ ] Apply chunk overlap smoothing.
- [ ] Add confidence aggregation.
- [ ] Add severity aggregation.
- [ ] Add `needsReview` metadata.
- [ ] Add `sourceModels` metadata.
- [ ] Add `supportingEvidenceIds` metadata.
- [ ] Add `rationale` metadata.
- [ ] Add `groundingStatus` metadata.
- [ ] Add one or more bounding boxes where available.
- [ ] Preserve existing `Detection`/timeline UI compatibility.
- [ ] Add migration path toward richer visual `ContentType`.
- [ ] Add tests for:
  - [ ] fragmented chunk findings
  - [ ] overlapping providers
  - [ ] short unsafe flashes
  - [ ] scene-level findings
  - [ ] region-level findings
- [ ] Exit gate: output timeline is stable and explainable.

## Phase 11: Search and Local Retrieval

- [ ] Add local search index interface.
- [ ] Add lexical caption/transcript search.
- [ ] Add local embedding provider interface.
- [ ] Add official-source embedding model manifest.
- [ ] Add vector index storage under project cache.
- [ ] Index:
  - [ ] captions
  - [ ] VLM findings
  - [ ] rationales
  - [ ] transcript spans
  - [ ] region labels
  - [ ] user review corrections
- [ ] Add search filters:
  - [ ] category
  - [ ] severity
  - [ ] reviewed/unreviewed
  - [ ] source model
  - [ ] timestamp range
- [ ] Add queries for fixtures:
  - [ ] `blood`
  - [ ] `fight`
  - [ ] `weapon`
  - [ ] `revealing clothes`
  - [ ] `exposed legs`
  - [ ] `nudity`
- [ ] Exit gate: local search returns timestamped chunks without reanalysis.

## Phase 12: User-Facing Explainability

- [ ] Update detection panel to show policy category.
- [ ] Show severity.
- [ ] Show confidence.
- [ ] Show short rationale.
- [ ] Show whether detection is region-level or scene-level.
- [ ] Show source model names.
- [ ] Show reviewed status.
- [ ] Show suggested action.
- [ ] Show supporting thumbnail/frame if available.
- [ ] Show bounding box overlay for selected detection.
- [ ] Add accessible copy text for rationale.
- [ ] Avoid exposing raw model dumps in release UI.
- [ ] Add UI tests for detection metadata rendering.
- [ ] Exit gate: a user can understand what was flagged and why without opening debug tools.

## Phase 13: Debug-Only Detection Overlay

- [ ] Add debug overlay widget behind `kDebugMode`.
- [ ] Ensure overlay cannot appear in release builds.
- [ ] Add debug settings toggle hidden in release builds.
- [ ] Draw chunk boundaries on the timeline.
- [ ] Draw sampled frame markers.
- [ ] Draw bounding boxes.
- [ ] Draw masks if present.
- [ ] Draw point localization if present.
- [ ] Draw scene-level detection bands.
- [ ] Color-code category and severity.
- [ ] Show selected detection rationale.
- [ ] Show raw parsed provider JSON.
- [ ] Show supporting evidence IDs.
- [ ] Show first-pass vs second-pass changes.
- [ ] Show provider disagreement.
- [ ] Show schema repair warnings.
- [ ] Show runtime/GPU/fallback status.
- [ ] Add local debug bundle export:
  - [ ] analysis manifest
  - [ ] model manifest
  - [ ] chunk plan
  - [ ] evidence records
  - [ ] parsed VLM JSON
  - [ ] timing metrics
  - [ ] redacted prompts
- [ ] Ensure debug bundle excludes secrets and unrelated files.
- [ ] Add debug overlay widget tests.
- [ ] Exit gate: debug overlay works in debug and is absent in release.

## Phase 14: Settings and Model Management UI

- [ ] Add pipeline selector.
- [ ] Add local runtime selector.
- [ ] Add model bundle selector.
- [ ] Show model source and license.
- [ ] Show official-source badge.
- [ ] Show checksum verification status.
- [ ] Show terms acceptance where required.
- [ ] Show GPU compatibility status.
- [ ] Show estimated VRAM requirement.
- [ ] Show whether model supports:
  - [ ] video input
  - [ ] image input
  - [ ] bounding boxes
  - [ ] masks
  - [ ] point localization
- [ ] Add model download/install flow.
- [ ] Add internal converted-artifact install flow.
- [ ] Block community model selection in production.
- [ ] Add tests for settings migration and UI state.
- [ ] Exit gate: users can select only approved local model bundles.

## Phase 15: Evaluation Dataset and Metrics

- [ ] Create labeled validation clip set.
- [ ] Include safe controls.
- [ ] Include category positives.
- [ ] Include ambiguous/boundary examples.
- [ ] Include low-light/motion blur clips.
- [ ] Include short unsafe flashes.
- [ ] Include long-video temporal context clips.
- [ ] Include immodest clothing examples with clear policy labels.
- [ ] Include bounding-box ground truth where applicable.
- [ ] Define metrics:
  - [ ] recall
  - [ ] precision
  - [ ] false negative rate
  - [ ] false positive rate
  - [ ] temporal IoU
  - [ ] box IoU
  - [ ] mask IoU
  - [ ] review burden
  - [ ] explanation completeness
  - [ ] chunk latency p50/p95
  - [ ] memory and VRAM usage
- [ ] Build evaluation runner.
- [ ] Compare:
  - [ ] legacy only
  - [ ] VLM only
  - [ ] VLM plus legacy evidence
  - [ ] VLM plus grounding
  - [ ] each runtime profile
- [ ] Exit gate: default profile beats legacy recall without unacceptable false positives or review burden.

## Phase 16: Rollout

- [ ] Add feature flag states:
  - [ ] `off`
  - [ ] `shadow`
  - [ ] `preview`
  - [ ] `default`
  - [ ] `enforce`
- [ ] Shadow-run new pipeline beside legacy on test fixtures.
- [ ] Store comparison reports.
- [ ] Add fallback to legacy profile.
- [ ] Add crash/failure telemetry locally.
- [ ] Add model load failure handling.
- [ ] Add schema failure handling.
- [ ] Add GPU fallback handling.
- [ ] Add checkpoint compatibility handling.
- [ ] Exit gate: new projects can default to `vss_family_safety_v1`; existing projects remain compatible.

## Phase 17: Deprecation Readiness

- [ ] Confirm legacy NSFW classifier still available as auxiliary evidence.
- [ ] Confirm NudeNet still available as auxiliary grounding.
- [ ] Confirm parser modesty path still available if it improves measured performance.
- [ ] Stop promoting legacy scores directly to detections in the new default pipeline.
- [ ] Keep old analysis results readable.
- [ ] Keep export/remediation behavior compatible.
- [ ] Document deprecation criteria.
- [ ] Exit gate: legacy direct-detection path can be deprecated only after measured stability window.
