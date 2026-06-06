# VSS-Style Family Safety Detection Revamp Plan

Date: 2026-06-07

## 1. Goal

Revamp KidsLens visual detection from a low-accuracy, model-specific NSFW/NudeNet flow into a modular family-safety video understanding pipeline inspired by NVIDIA Video Search and Summarization (VSS).

The new default pipeline should:

- Segment videos into semantically useful chunks.
- Use a local, open-weight vision-language model (VLM) as the primary reasoning layer for family-safety analysis.
- Store timestamped multimodal evidence for search, review, and aggregation.
- Dynamically identify unsafe or family-inappropriate content including violence, gore, blood, nudity, sexualized scenes, and immodest female clothing.
- Produce item/region boundaries when the selected model or an auxiliary model supports grounding, segmentation, or bounding boxes.
- Explain each detection to the user with the detected category, evidence, confidence, source model, and rationale.
- Preserve the existing NSFW, NudeNet, and parser-backed modesty pipelines as legacy/auxiliary plugins until they are intentionally deprecated.
- Run all inference locally. Cloud models, hosted inference APIs, and remote VLM/LLM services are out of scope for this pipeline.
- Use only official upstream open-weight model releases or internally converted ports derived from official weights. Community ports are not allowed in production.
- Leverage GPU acceleration when available, with a CPU fallback only when the selected profile is explicitly marked CPU-capable.

## 2. Research Basis

Primary references reviewed:

- NVIDIA Build demo: https://build.nvidia.com/nvidia/video-search-and-summarization
- NVIDIA VSS 3.0 overview: https://docs.nvidia.com/vss/3.0.0/overview/latest/index.html
- NVIDIA VSS architecture: https://docs.nvidia.com/vss/2.2.0/content/architecture.html
- NVIDIA VSS GA technical blog: https://developer.nvidia.com/blog/advance-video-analytics-ai-agents-using-the-nvidia-ai-blueprint-for-video-search-and-summarization/
- NVIDIA VSS VLM configuration: https://docs.nvidia.com/vss/latest/vss-agent/configure-vlm.html
- NVIDIA VSS agent evaluation: https://docs.nvidia.com/vss/3.0.0/vssnext-docs/3.0.0/vss-agent/VSS-Agent-Evaluation.html
- NVIDIA Cosmos Reason 1 official weights: https://huggingface.co/nvidia/Cosmos-Reason1-7B
- NVIDIA Nemotron Nano VL official weights: https://huggingface.co/nvidia/NVIDIA-Nemotron-Nano-12B-v2-VL-FP8
- NVIDIA RTX 5070 official specs: https://www.nvidia.com/en-us/geforce/graphics-cards/50-series/rtx-5070-family/
- Alibaba Qwen3.5 4B official weights: https://huggingface.co/Qwen/Qwen3.5-4B
- Google Gemma 4 official weights: https://huggingface.co/google/gemma-4-E4B
- Google Gemma 4 12B official weights: https://huggingface.co/google/gemma-4-12B-it
- Microsoft Phi-4 multimodal official weights: https://huggingface.co/microsoft/Phi-4-multimodal-instruct
- Microsoft Phi-4 multimodal ONNX official weights: https://huggingface.co/microsoft/Phi-4-multimodal-instruct-onnx
- Meta Llama 4 Scout official weights: https://huggingface.co/meta-llama/Llama-4-Scout-17B-16E-Instruct
- NVIDIA Llama 4 Scout FP8 official-derived artifact: https://huggingface.co/nvidia/Llama-4-Scout-17B-16E-Instruct-FP8
- NVIDIA LocateAnything-3B official grounding model: https://huggingface.co/nvidia/LocateAnything-3B
- Hugging Face Vision Language Leaderboards collection: https://huggingface.co/collections/merve/vision-language-leaderboards

Key NVIDIA VSS ideas to adapt:

- Split the system into an ingestion pipeline and a retrieval pipeline.
- Process long videos as small chunks, sample a limited number of frames per chunk, and analyze chunks independently.
- Generate dense VLM captions and structured metadata for each chunk.
- Store caption text, timestamps, object/CV metadata, audio transcript, and embeddings for retrieval.
- Use retrieval, reranking, summarization, and graph-style relationships for Q&A, alerts, and long-video reasoning.
- Keep VLM/LLM runtime boundaries flexible while enforcing local-only inference. The app can use local model servers such as vLLM, llama.cpp-compatible runtimes where supported, TensorRT-LLM, ONNX Runtime, or a bundled helper process, but it must not call hosted inference endpoints.
- Evaluate outputs with task-specific metrics, not only generic model confidence.

Important adaptation: NVIDIA VSS supports cloud/API deployment modes, but KidsLens should not. This project handles sensitive family videos, so the target architecture must keep video frames, audio, transcripts, embeddings, and inference prompts on the user's machine.

## 3. Current Repo State

Relevant existing components:

- `lib/services/analysis_service.dart`
  - Current orchestration point.
  - Pipeline version is `8`.
  - Runs profanity, NSFW classifier, NudeNet detector, and modesty/parser-backed paths.
  - Builds `Detection` objects and timeline output.
- `lib/services/frame_sampling_service.dart`
  - Provides FFmpeg-backed frame extraction and scene-change helpers.
  - Current streaming extractor uses fixed FPS and does not yet build VSS-style semantic chunks.
- `lib/services/nsfw_onnx_service.dart`
  - Generic ONNX execution service for classification, object detection, labeled classification, and binary segmentation.
  - Useful as a legacy/auxiliary evidence provider.
- `lib/services/modesty_analysis_service.dart`
  - Parser-backed modesty scaffold for arms/legs exposure.
  - Current rules are heuristic and should become one evidence source rather than the main policy engine.
- `lib/data/models/analysis_settings.dart`
  - Existing settings are category/model oriented and can be migrated to pipeline profiles.
- `lib/data/models/detection.dart`
  - `ContentType` currently only has `nsfw` and `profanity`.
  - More precise visual policy categories are stored indirectly in metadata.
- `lib/data/models/frame_analysis_result.dart`
  - Already has fields for NSFW, violence, blood, weapons, and visual regions.
  - Needs a richer evidence/event model for VLM captions, policy findings, grounding, and provider provenance.

The main architectural problem is that detection is tied to model-specific outputs too early. NSFW scores and NudeNet labels are being promoted directly to user-facing detections, which makes it difficult to reason about broader family-safety policy, ambiguous scenes, or temporal context.

## 4. Target Architecture

Use a layered, evidence-first architecture:

```text
Media file
  -> MediaIngestionService
  -> ChunkPlanner
  -> Frame/Audio Samplers
  -> Evidence Providers
       - VLM segment analyzer
       - ASR transcript provider
       - Legacy NSFW classifier adapter
       - Legacy NudeNet region adapter
       - Modesty parser adapter
       - Optional object/pose/segmentation adapters
  -> Evidence Store
       - chunk records
       - sampled frame records
       - captions
       - transcript spans
       - policy observations
       - regions/object tracks
       - embeddings/search index
  -> Policy Engine
  -> Temporal Fusion
  -> Detection Builder
  -> Timeline / review UI / export actions
```

The rule is: providers emit evidence, not final app detections. Final detections are produced only by the policy and temporal-fusion layers.

## 5. Core Interfaces To Add

Add these interfaces under a new namespace, for example `lib/services/detection/`.

### `DetectionPipeline`

Owns orchestration for a complete detection run.

Responsibilities:

- Declare capabilities, required models, privacy mode, provider requirements, and output schema version.
- Run ingestion, evidence generation, policy evaluation, temporal fusion, and detection building.
- Support progress, cancellation, checkpointing, and partial results.

Example implementations:

- `VssFamilySafetyPipeline` as the new default.
- `LegacyNsfwPipelineAdapter` wrapping the current NSFW/NudeNet flow.
- `AudioProfanityPipeline` or an audio stage inside the default pipeline.

### `ChunkPlanner`

Converts a media duration and scene-change data into chunk windows.

Initial policy:

- Start with 4 to 8 second chunks for high-risk analysis.
- Expand to 15 to 30 seconds for search/summarization-only profiles.
- Hard-cut on scene changes when they are close to a boundary.
- Add overlap, initially 0.5 to 1.0 seconds, to avoid missing unsafe transitions.
- Mark chunk confidence lower when frame coverage is sparse.

### `FrameSelectionStrategy`

Selects frames per chunk based on the provider and risk mode.

Initial policy:

- For VLM: 8 to 16 frames per chunk, biased toward scene starts, middles, ends, and motion/scene-change points.
- For legacy ONNX: fixed FPS micro-batches where throughput is acceptable.
- For escalation: resample flagged or ambiguous chunks at higher density.

### `EvidenceProvider`

Provider contract for model-specific evidence generation.

Provider outputs must include:

- Provider ID and version.
- Model ID, checksum, and local runtime model name.
- Input chunk/frame IDs.
- Timestamp range.
- Structured evidence payload.
- Confidence and calibration metadata.
- Failure mode if inference failed or returned invalid output.

Initial providers:

- `VlmSegmentProvider`
- `TranscriptProvider`
- `LegacyNsfwEvidenceProvider`
- `NudeNetRegionEvidenceProvider`
- `ModestyParserEvidenceProvider`

### `VlmProvider`

Runtime-neutral, local-only VLM boundary.

Methods:

- `analyzeSegment(VideoSegmentRequest request)`
- `captionSegment(VideoSegmentRequest request)`
- `answerSegmentQuestions(VideoSegmentRequest request, List<String> questions)`

Supported local provider modes:

- Local vLLM server bound to `localhost` only.
- Local NVIDIA NIM container or local TensorRT-LLM runtime when the official model supports it.
- Local Transformers/PyTorch helper process for development and model validation.
- ONNX Runtime or TensorRT-converted artifacts produced from official upstream weights.
- Future llama.cpp/MLX/other local runtime adapters only when official or internally converted artifacts pass the same provenance checks.

The app should not require NVIDIA hardware, but NVIDIA GPUs should be the primary acceleration target on Windows when CUDA/TensorRT is available. DirectML can be used as a fallback for compatible ONNX/local models. CPU mode is acceptable only for lightweight profiles because long-video VLM inference on CPU will usually be too slow.

Disallowed provider modes:

- Hosted cloud VLM/LLM APIs.
- Hugging Face Inference Providers or hosted Inference Endpoints.
- External OpenAI-compatible endpoints not running on the user's machine.
- Community-converted model ports in production.

### `GroundingProvider`

Local provider contract for item boundary detection.

Responsibilities:

- Return bounding boxes, masks, points, or object IDs for policy-relevant items when supported.
- Normalize all coordinates to frame-relative `[0, 1]` boxes and optionally preserve source masks.
- Link each boundary to an evidence ID, frame ID, chunk ID, policy category, and rationale.
- Support female-modesty boundaries such as exposed legs, arms, abdomen, chest, or other configured policy regions when the selected model can localize them.

Initial grounding sources:

- VLM-native grounding from models that can return 2D bounding boxes or point localization.
- NVIDIA `nvidia/LocateAnything-3B` as an optional grounding evaluation candidate for text-conditioned boxes/points after local runtime validation. Production use requires a compatible commercial license, so it must remain disabled by default for now.
- Official object/grounding models such as Grounding DINO-family or Florence/OWL-style models only if official weights and licenses are approved.
- Existing NudeNet detector and modesty parser as legacy auxiliary grounding providers.

Boundary rule:

- If a model can localize a policy finding, the final `Detection` should carry one or more `Detection.boundingBoxKey` entries or a future `DetectedRegionRef`.
- If no boundary is available, the detection must clearly say it is scene-level and should use full-frame blur/cut/review actions rather than pretending to have region precision.

### `EvidenceStore`

Persistent, queryable analysis artifact store.

Minimum v1 storage:

- JSON records in the project analysis cache for deterministic replay.
- SQLite tables for chunks, evidence, detections, and model provenance.
- Text search over captions/transcripts.
- Pluggable vector index interface for embeddings.

Do not start with a heavy graph database inside the desktop app. Model graph-like relationships as typed edges in SQLite first:

- `person appears_in chunk`
- `object appears_in region`
- `event involves person/object`
- `policy_finding supported_by evidence`

This gives most of the VSS GraphRAG value without adding operational complexity.

### `EmbeddingProvider` and `SemanticSearchIndex`

Index:

- VLM captions.
- Structured policy observations.
- Transcript spans.
- User-reviewed corrections.

Use cases:

- Search the video for "blood", "fight", "revealing clothing", "female in bikini", "weapon", "kissing", "screaming", or "unsafe for children".
- Retrieve context for an LLM/VLM second-pass review.
- Build user-facing "why was this flagged?" explanations.

### `PolicyEngine`

Maps evidence to family-safety findings.

Inputs:

- VLM structured observations.
- Caption/search retrieval hits.
- Audio transcript/profanity evidence.
- Legacy classifier/region detections.
- User policy settings.
- Calibration profiles.

Outputs:

- `PolicyFinding` records, not final `Detection` records.
- Each finding must include category, severity, confidence, supporting evidence IDs, timestamp range, and suggested action.
- Each finding must include an explanation payload with a short user-facing rationale and a developer-facing evidence trace.

### `TemporalFusion`

Converts per-chunk/per-frame findings into stable detection segments.

Rules:

- Merge adjacent findings when category, severity, and evidence source agree.
- Preserve short high-severity spikes like nudity, gore, or weapons.
- Require stronger temporal confirmation for vague categories like "immodest clothing" or "suggestive scene".
- Track uncertainty explicitly and send ambiguous segments to review instead of silently allowing them.

## 6. Default Pipeline: `vss_family_safety_v1`

This should become the default detection pipeline while current pipelines remain selectable as legacy profiles.

### Stage 0: Run Setup

Inputs:

- Media path.
- Analysis settings.
- Pipeline profile.
- Local runtime profile:
  - `cuda_tensorrt`
  - `cuda_vllm`
  - `directml_onnx`
  - `cpu_lightweight`
- Local model bundle IDs and resolved cache paths.
- Privacy mode: always `localOnly`.

Outputs:

- `AnalysisRunManifest`
- media metadata
- model/provider manifest
- deterministic settings hash

Acceptance:

- No frame, audio, transcript, prompt, caption, embedding, or detection evidence leaves the machine.
- If no local VLM is available, fall back to legacy providers plus a warning that VLM safety analysis is unavailable.
- If GPU is available and compatible with the selected model/runtime, use it by default.
- If GPU setup fails, record the provider-resolution failure and either fall back to another local GPU backend or require explicit user approval for CPU-lightweight mode.

### Stage 1: Media Ingestion

Work:

- Probe media using existing FFmpeg bindings.
- Extract audio if transcript/profanity is enabled.
- Detect scene changes.
- Build chunk windows.
- Generate sampled frames per chunk.
- Assign stable IDs:
  - `mediaId`
  - `chunkId`
  - `frameId`
  - `transcriptSpanId`

Implementation notes:

- Extend `FrameSamplingService` rather than replacing it.
- Add chunk-aware sampling instead of only global fixed FPS.
- Persist sampled-frame metadata, not necessarily image bytes unless cache mode requires it.

### Stage 2: Fast Local Evidence Pass

Purpose:

- Keep existing investments useful.
- Provide cheap spatial hints to the VLM and policy engine.
- Reduce false negatives from VLM caption omissions.

Run, when enabled and models are available:

- NudeNet explicit body-part regions.
- Existing NSFW classifier.
- Parser-backed modesty signals.
- Audio transcription and profanity detection.

Output:

- `RawEvidence` records with provider provenance.
- No direct timeline detections yet.

### Stage 3: VLM Segment Analysis

For each chunk, ask the VLM for both dense captioning and structured family-safety analysis.

Use official open-weight models from major providers only. Target hardware for the default pipeline is an NVIDIA RTX 5070-class consumer GPU with 12 GB GDDR7 VRAM. That target is intentionally conservative: if a model cannot run within that budget with bounded frame count, KV cache, and decoder overhead, it is not an included production candidate.

Included candidate model families:

- NVIDIA:
  - `nvidia/Cosmos-Reason1-7B` as the NVIDIA reasoning VLM candidate. Use a KidsLens-owned 4-bit or FP8 artifact if the official precision does not fit the RTX 5070 budget.
  - `nvidia/NVIDIA-Nemotron-Nano-12B-v2-VL-FP8` only as a quantized/tight RTX 5070 profile after measured local validation. Prefer NVFP4 or internal 4-bit conversion if FP8 leaves insufficient headroom for video frames and KV cache.
  - `nvidia/LocateAnything-3B` as an optional grounding evaluation candidate, subject to license restrictions and local runtime validation. It must not ship in production unless its license permits the intended use.
- Alibaba:
  - `Qwen/Qwen3.5-4B` as the primary Qwen candidate for RTX 5070 evaluation.
  - `Qwen/Qwen3.5-2B` as an optional lightweight fallback if quality is acceptable.
  - Larger `Qwen/Qwen3.5-*` variants are excluded from the default profile unless a KidsLens-owned quantized artifact proves stable within 12 GB VRAM.
- Google:
  - `google/gemma-4-E4B-it` as a primary RTX 5070 candidate.
  - `google/gemma-4-12B-it` only as a tight 4-bit profile after measured local validation.
- Microsoft:
  - `microsoft/Phi-4-multimodal-instruct` as a lightweight local profile.
  - `microsoft/Phi-4-multimodal-instruct-onnx` as the preferred Microsoft deployment artifact when ONNX Runtime GPU acceleration works on Windows.
- Meta:
  - `meta-llama/Llama-4-Scout-17B-16E-Instruct` replaces Llama 3.2. It is not selectable for the RTX 5070 default profile unless a KidsLens-owned quantized/distilled artifact proves it fits 12 GB VRAM without sustained CPU offload.
  - `nvidia/Llama-4-Scout-17B-16E-Instruct-FP8` can be used as an official-derived reference artifact for R&D, but it is not approved for RTX 5070 production until measured fit is proven.

Excluded from included production candidates for RTX 5070:

- `nvidia/Cosmos-Reason2-32B`, Gemma 4 26B/31B, Llama 4 Maverick, unvalidated Llama 4 Scout artifacts, Qwen3.5 large variants that exceed the RTX 5070 fit gate, Qwen 14B/32B+ VL variants, Phi-4 15B vision-reasoning, and similar large models unless a future official or KidsLens-owned quantized artifact proves stable within 12 GB VRAM. Until then, they belong in research notes, not the shipped model list.
- OpenGVLab InternVL and AllenAI Molmo are not included because this plan now limits production candidates to major providers such as Alibaba, Microsoft, NVIDIA, Google, Meta, and similar major model vendors.

Optional major-provider watchlist:

- Mistral Pixtral 12B can be tracked as a major-provider candidate only if licensing, 4-bit conversion, and RTX 5070 validation pass. It should not be a default profile until it beats the Alibaba/Google/Microsoft/NVIDIA/Meta candidates on KidsLens validation.

Leaderboard policy:

- Hugging Face leaderboards such as Open VLM Leaderboard, Vision Arena, MMBench, SEED-Bench, and task-specific retrieval/document leaderboards should inform the candidate shortlist, not automatically select models.
- The final KidsLens default must be chosen by our own validation clips because family-safety detection needs category recall, temporal localization, grounding quality, and review burden metrics that generic VLM leaderboards do not measure directly.
- Keep separate rankings for:
  - main safety reasoning VLM
  - video understanding
  - grounding/bounding boxes
  - local GPU performance
  - small-device fallback
  - explanation quality

Model inclusion rules:

- Download only from the official organization or vendor repository.
- Pin exact revision, file list, checksums, license, context limits, image/video support, grounding support, and runtime compatibility.
- If conversion is required, convert from official weights in our controlled build pipeline and publish the converted artifact to our own Hugging Face organization/repository with provenance metadata.
- Quantized artifacts must be owned by KidsLens, reproducible from official source weights, and validated on an RTX 5070 12 GB profile before they can be selected by the app.
- Do not use community GGUF/AWQ/MLX/ONNX/TensorRT ports in production. They can be used only as temporary developer references and must never be selected by default.

### Approved Model And License Table

This is the current model approval table for the local-only RTX 5070 target. "Approved candidate" means the model is from an approved major provider and may be implemented behind validation gates. It does not mean the model is already the production default.

| Provider | Model or artifact | Role | License | Commercial app use | Current status |
| --- | --- | --- | --- | --- | --- |
| NVIDIA | `nvidia/Cosmos-Reason1-7B` | Main VLM reasoning candidate | NVIDIA Open Model License; model card also references Apache 2.0 information | Yes, per NVIDIA model card, with NVIDIA Open Model License conditions | Approved candidate; needs RTX 5070 validation and likely KidsLens-owned quantization |
| NVIDIA | `nvidia/NVIDIA-Nemotron-Nano-12B-v2-VL-FP8` | Main VLM candidate, image/text first | NVIDIA Open Model License | Yes, subject to NVIDIA Open Model License | Approved candidate only after RTX 5070 validation |
| NVIDIA | `nvidia/LocateAnything-3B` | Optional grounding/bounding-box evaluation | NVIDIA License, non-commercial research terms on current model card | No for production/commercial app under current terms | Optional evaluation only; disabled by default |
| Alibaba/Qwen | `Qwen/Qwen3.5-4B` | Main Qwen VLM candidate | Apache 2.0 | Yes | Approved candidate; needs RTX 5070 validation |
| Alibaba/Qwen | `Qwen/Qwen3.5-2B` | Lightweight Qwen fallback | Apache 2.0 | Yes | Optional candidate if validation quality is acceptable |
| Google | `google/gemma-4-E4B-it` / `google/gemma-4-E4B` | Main VLM candidate | Apache 2.0 | Yes | Approved candidate; E4B is preferred for RTX 5070 evaluation |
| Google | `google/gemma-4-12B-it` | Higher-capability VLM candidate | Apache 2.0 | Yes | Approved candidate only as tight 4-bit/quantized RTX 5070 profile |
| Microsoft | `microsoft/Phi-4-multimodal-instruct` | Lightweight multimodal VLM candidate | MIT | Yes | Approved candidate |
| Microsoft | `microsoft/Phi-4-multimodal-instruct-onnx` | Preferred Windows ONNX deployment candidate | MIT | Yes | Approved candidate; validate CUDA/DirectML locally |
| Meta | `meta-llama/Llama-4-Scout-17B-16E-Instruct` | Meta Llama 4 candidate | Llama 4 Community License | Yes for commercial/research use, with custom terms including 700M MAU threshold and acceptable-use obligations | Approved by provider/license class, but not RTX 5070-selectable until fit is proven |
| NVIDIA / Meta-derived | `nvidia/Llama-4-Scout-17B-16E-Instruct-FP8` | Official-derived Llama 4 FP8 R&D artifact | NVIDIA Open Model License on the artifact; verify upstream Llama 4 obligations before production | Likely yes with NVIDIA and upstream Llama terms, but legal review required | R&D/reference only until RTX 5070 fit and license chain are verified |

Use a strict JSON schema. Example fields:

```json
{
  "chunkId": "chunk_00042",
  "summary": "brief factual description",
  "visiblePeople": [
    {
      "id": "person_1",
      "apparentGenderPresentation": "female|male|unclear|not_applicable",
      "clothing": "factual clothing description",
      "exposureSignals": ["cleavage", "bare_midriff", "bare_legs"],
      "confidence": 0.0
    }
  ],
  "groundedRegions": [
    {
      "regionId": "region_1",
      "label": "exposed female legs",
      "category": "immodest_female_clothing",
      "frameId": "frame_00042_03",
      "box": {"x": 0.25, "y": 0.48, "width": 0.32, "height": 0.42},
      "maskRef": null,
      "confidence": 0.0,
      "rationale": "Visible bare legs below short clothing."
    }
  ],
  "unsafeFindings": [
    {
      "category": "nudity|sexual_content|immodest_female_clothing|violence|gore|blood|weapon|substance|other",
      "severity": "none|low|medium|high|critical",
      "confidence": 0.0,
      "startOffsetMs": 0,
      "endOffsetMs": 0,
      "evidence": "short factual rationale",
      "regionIds": ["region_1"],
      "needsReview": true
    }
  ],
  "searchTerms": ["fight", "blood", "bikini"],
  "uncertainties": ["low light", "motion blur"]
}
```

Prompt constraints:

- Ask for factual observations, not moralizing labels.
- Require "unclear" when the model cannot see enough.
- Require separate categories for explicit nudity, sexualized behavior, immodest clothing, violence, gore, blood, and weapons.
- Require timestamps relative to the chunk where possible.
- Require bounding boxes or region IDs whenever the model can localize the item. If localization is unsupported or uncertain, require `groundingStatus: scene_level_only`.
- Require conservative review for ambiguous child-safety relevant visual findings.
- Prohibit age inference unless explicitly needed for a future, separately governed policy. The current use case is family-safety content filtering, not age classification.
- Require a short rationale for every finding. The rationale should describe visible evidence, not just restate the category.

Second-pass strategy:

- Re-query only chunks with high risk, disagreement, or uncertainty.
- Use higher frame density and include relevant neighboring chunks.
- Include local CV regions as visual hints where the local provider supports image overlays or structured context.
- Escalate to a grounding-capable local model when the first-pass VLM detects a region-relevant category but cannot provide reliable boundaries.

### Stage 4: Embedding and Search Indexing

Index:

- Chunk summaries.
- Full VLM captions.
- Transcript spans.
- Unsafe finding rationales.
- Object/region labels.
- User-confirmed/rejected corrections.

Default search behavior:

- Hybrid lexical + vector retrieval.
- Rerank search results by timestamp overlap, severity, provider confidence, and user-review status.
- Store search index under the project cache so a video can be searched without reanalysis.
- Embeddings must be generated locally with official open-weight embedding models or internally converted artifacts from official weights.
- Candidate local embedding/reranking models should be tracked in the same model manifest as VLMs, with official source, license, checksum, runtime, and GPU support.

### Stage 5: Policy Evaluation

Add a policy taxonomy separate from model labels.

Recommended v1 categories:

- `explicit_nudity`
- `sexual_content`
- `suggestive_content`
- `immodest_female_clothing`
- `violence`
- `gore`
- `blood`
- `weapons`
- `substances`
- `profanity`

Each category should define:

- Default action.
- Severity mapping.
- Confidence thresholds.
- Evidence requirements.
- Whether bounding boxes are required or optional.
- Whether manual review is required below enforce threshold.

Example policy:

- Explicit nudity: blur region if region exists, otherwise blur full frame, high recall priority.
- Gore/blood: blur or cut scene depending severity, high recall priority.
- Violence: cut scene for high severity, review for medium severity.
- Immodest female clothing: review or blur region by default, because this is culturally/policy sensitive and more context-dependent.
- Profanity: beep or mute, using existing audio path.

### Stage 6: Temporal Fusion

Convert policy findings into final `Detection` objects.

Fusion must:

- Use chunk overlap to avoid gaps.
- Merge nearby same-category segments.
- Preserve separate categories in metadata.
- Carry evidence IDs for traceability.
- Set `needsReview` in metadata when confidence is below enforce threshold or providers disagree.
- Use existing `Detection` and `UnifiedTimeline` temporarily for UI compatibility.
- Attach explanation metadata to every emitted detection:
  - `policyCategory`
  - `severity`
  - `rationale`
  - `supportingEvidenceIds`
  - `sourceModels`
  - `isSceneLevel`
  - `groundingStatus`
  - `debugTraceId` in debug builds

Short-term compatibility:

- Continue using `ContentType.nsfw` for visual detections.
- Store precise category in `Detection.visualContentCategoryKey`.

Medium-term migration:

- Expand `ContentType` to include `visualPolicy` or add a richer `DetectionCategory` model.
- Avoid forcing all visual policy categories into `nsfw`.

### Stage 7: Review and Feedback Loop

Every detection should be explainable:

- Show category.
- Show confidence and severity.
- Show the caption/rationale.
- Show local CV regions when available.
- Show supporting frame thumbnails.
- Show provider/model provenance.

User actions:

- Confirm.
- Reject.
- Adjust range.
- Adjust category/action.

Persist user feedback:

- Feed into calibration reports.
- Improve thresholds per category.
- Allow a future local preference model or prompt tuning layer.

## 7. Pipeline Profiles

### `vss_family_safety_v1` default

Hybrid VSS-style analysis:

- VLM segment analysis.
- Transcript/profanity.
- Legacy NudeNet/NSFW/parser evidence as auxiliary signals.
- Search index.
- Policy engine and temporal fusion.
- GPU-first local inference.
- Official open-weight model bundles only.

### `legacy_nsfw_region_v8`

Current implementation:

- NSFW ONNX classifier.
- NudeNet region detector.
- Parser-backed modesty if configured.
- Profanity.

Use when:

- No VLM is configured.
- User selects fully local lightweight mode.
- Regression comparison is needed.

### `audio_only`

Current audio/profanity flow, preserved.

### `fast_preview`

Use lightweight sampling and either:

- A cheap VLM pass on a few representative chunks, or
- Existing local classifiers only.

This is for estimates, not enforce-mode safety.

## 8. Data Model Additions

Add new Freezed models:

- `AnalysisRunManifest`
- `VideoChunk`
- `SampledFrameRef`
- `EvidenceRecord`
- `VlmSegmentAnalysis`
- `PolicyFinding`
- `PolicyCategory`
- `DetectionPipelineProfile`
- `ModelProviderConfig`
- `SearchIndexRecord`

Important fields:

- Stable IDs.
- Timestamp ranges.
- Provider/model provenance.
- Schema version.
- Confidence and severity.
- Supporting evidence IDs.
- Raw JSON payload for forward compatibility.

Avoid putting all new fields into `FrameAnalysisResult`. Frame-level results are still useful, but VLM and retrieval evidence are chunk/event-level concepts.

## 9. Settings Migration

Add:

- `analysisPipelineId`
- `localRuntimeProfileId`
- `vlmModelBundleId`
- `groundingModelBundleId`
- `embeddingModelBundleId`
- `policyProfileId`
- `enableLegacyAuxiliarySignals`
- `enableSearchIndex`
- `secondPassMode`
- `preferGpu`
- `allowCpuFallbackForLightweightProfiles`
- `enableDebugDetectionOverlay` gated to debug builds only

Migration behavior:

- Existing users keep current behavior unless a migration explicitly opts them into the new default for new projects.
- New installs use `vss_family_safety_v1`.
- Existing category thresholds map into policy thresholds where possible.
- Legacy category settings remain visible under "Legacy model signals" or an advanced section.
- Existing model IDs are migrated to legacy auxiliary providers, not to VLM model bundles.
- Any previous remote/API settings must be ignored or removed because the new policy is local-only inference.

## 10. Implementation Phases

### Phase 0: Contracts and Governance

Deliver:

- Freeze v1 policy taxonomy and category definitions.
- Define the JSON schema for VLM outputs.
- Define provider privacy rules.
- Define evaluation dataset requirements and owners.

Exit gate:

- Policy schema, provider contracts, and evaluation metrics are documented and reviewed.

### Phase 1: Pipeline Plugin Shell

Deliver:

- Add `DetectionPipeline` interface.
- Add pipeline registry/factory.
- Wrap current `AnalysisService` visual logic as `legacy_nsfw_region_v8`.
- Route `AnalysisService.analyze()` through selected pipeline without changing UI output.

Exit gate:

- Existing tests pass and current detection behavior is unchanged when legacy profile is selected.

### Phase 2: Chunked Ingestion

Deliver:

- Add `VideoChunk` and chunk planner.
- Extend frame sampling with chunk-aware frame selection.
- Persist run/chunk/frame metadata.
- Add checkpoint compatibility for chunk profiles.

Exit gate:

- Deterministic chunk plans for fixed media fixtures.
- Long videos can resume from checkpoints by chunk ID.

### Phase 3: Evidence Store

Deliver:

- Add JSON/SQLite-backed evidence persistence.
- Convert legacy NSFW/NudeNet/parser outputs to `EvidenceRecord`.
- Keep current detection building from legacy evidence for compatibility.

Exit gate:

- A completed analysis run can be replayed from evidence without re-running models.

### Phase 4: VLM Provider Abstraction

Deliver:

- Add `VlmProvider` interface.
- Add local-only runtime adapters:
  - local vLLM on loopback
  - local NVIDIA NIM/TensorRT-LLM where supported
  - local Transformers/PyTorch helper for validation
  - ONNX/TensorRT converted model bundles where feasible
- Add NVIDIA Cosmos Reason, NVIDIA Nemotron VL, optional NVIDIA LocateAnything, Alibaba Qwen3.5, Google Gemma 4, Microsoft Phi-4 multimodal, and Meta Llama 4 model-bundle manifests.
- Add strict output schema validation and retry/repair rules.
- Add local-only enforcement that rejects non-loopback endpoints and hosted model URLs.
- Add official-source provenance enforcement.

Exit gate:

- A small video fixture produces valid structured VLM chunk analysis using a local runtime and official or internally converted model bundle.

### Phase 5: Family-Safety Policy Engine

Deliver:

- Add policy taxonomy and `PolicyEngine`.
- Map VLM outputs and legacy evidence to `PolicyFinding`.
- Add uncertainty and manual-review handling.
- Add category-specific action defaults.

Exit gate:

- Golden tests convert representative evidence records into expected policy findings.

### Phase 6: Temporal Fusion and Detection Builder

Deliver:

- Add `TemporalFusion` service.
- Add evidence-backed detection metadata.
- Preserve UI compatibility with existing `Detection` and timeline models.

Exit gate:

- Fixture evidence produces stable timeline segments with no duplicate/fragmented detections.

### Phase 7: Search and Retrieval

Deliver:

- Add caption/transcript/finding index.
- Add semantic search interface.
- Add local embedding provider.
- Use retrieval for second-pass review and user search.

Exit gate:

- Searches such as "blood", "fight", "revealing clothes", and "weapon" return timestamped results from analyzed videos.

### Phase 8: Evaluation and Calibration

Deliver:

- Labeled validation clips for each category.
- Metrics per category:
  - recall
  - precision
  - false negative rate
  - false positive rate
  - temporal IoU
  - review burden
  - latency and cost
- Provider comparison reports:
  - VLM only
  - legacy only
  - VLM plus legacy auxiliary signals
  - VLM plus grounding model
  - GPU runtime variants

Suggested gates before making the VLM pipeline enforce-default:

- Explicit nudity recall >= 0.97 on validation set.
- Gore/blood recall >= 0.95 on validation set.
- High-severity violence recall >= 0.93 on validation set.
- Immodest female clothing should initially optimize for review recall, not automatic enforcement, until policy examples are well calibrated.
- P95 chunk analysis latency and cost are within the configured user profile limits.
- Region grounding quality is measured for all boundary-capable categories using temporal IoU and box/mask IoU.

### Phase 9: Default Rollout

Deliver:

- Feature flag:
  - `off`
  - `shadow`
  - `preview`
  - `default`
  - `enforce`
- Shadow comparison between legacy and VSS pipelines.
- User-visible provider/privacy status.
- User-visible local runtime/GPU status.
- One-click fallback to legacy profile.

Exit gate:

- New projects default to `vss_family_safety_v1`; existing projects retain their configured profile unless migrated by the user.

### Phase 10: Legacy Deprecation Plan

Do not remove legacy pipelines immediately.

Deprecation criteria:

- VSS pipeline has better measured recall and acceptable false-positive burden across categories.
- Offline/local fallback story is defined.
- User projects can still open old analysis results.
- Export/remediation behavior is unchanged or migrated.

Then:

- Mark legacy NSFW classifier as auxiliary-only.
- Mark NudeNet as region-localization helper.
- Keep parser-backed modesty only if it improves measured performance.
- Remove direct legacy-to-detection pathways after a stable compatibility window.

## 11. Prompting Strategy For Family Safety

Use two prompt layers.

### Caption prompt

Purpose:

- Produce dense, factual descriptions.
- Avoid final policy judgments.
- Capture people, clothing, actions, visible injuries, blood, weapons, and scene context.

### Policy prompt

Purpose:

- Convert observations to structured family-safety categories.
- Require uncertainty and evidence.
- Return JSON only.

Use examples for:

- Safe beach/swimwear vs sexualized scene.
- Medical blood vs gore.
- Sports contact vs violence.
- Halloween makeup vs gore.
- Female sleeveless clothing vs explicit nudity vs policy-specific immodesty.

Do not rely on a single broad question like "is this unsafe?" because it hides category-specific failure modes.

## 12. Accuracy Strategy

Accuracy should improve through evidence fusion, not by assuming a VLM is always right.

Use:

- Dense chunking to avoid long-video context loss.
- Second-pass analysis for uncertain/high-risk chunks.
- Local CV region hints for nudity and body exposure.
- Transcript context for threats, profanity, screams, or sexual dialogue.
- Category-specific thresholds.
- Human review for ambiguous findings.
- Continuous evaluation against labeled clips.

Provider disagreement policy:

- VLM says unsafe, legacy says safe: review unless high-severity VLM confidence is very high.
- Legacy says explicit region unsafe, VLM omits it: review or blur region depending category severity.
- Both agree: enforce according to policy.
- Provider failure: fail to review for safety-critical categories, not silent allow.

## 13. Performance Strategy

Control cost/latency with a cascade:

1. Cheap ingestion and scene-aware chunking.
2. Fast local auxiliary pass.
3. VLM first pass on representative frames.
4. VLM second pass only on high-risk or uncertain chunks.
5. Reuse cached evidence and embeddings for repeat analysis.

Important metrics:

- chunks per minute
- VLM latency per chunk
- second-pass rate
- token/input-frame cost
- evidence cache hit rate
- memory use
- user review burden
- temporal fragmentation rate

## 14. Security and Privacy

Required behavior:

- Inference is local-only; there is no setting that allows cloud inference in this pipeline.
- Reject hosted model endpoints and non-loopback inference URLs.
- No API keys in project files.
- Redact provider credentials from logs.
- Store evidence locally by default.
- Allow deletion of sampled frames/evidence cache.
- Persist provider/model provenance for each detection.
- Require license acceptance tracking for gated official weights such as Gemma or any NVIDIA model requiring terms acceptance.
- Record model source, exact revision, conversion recipe, checksum, and runtime in the analysis manifest.
- Internal converted artifacts must be reproducible from official weights and stored in a KidsLens-owned Hugging Face repository or release bucket with provenance metadata.

## 15. GPU and Runtime Strategy

GPU policy:

- Prefer CUDA/TensorRT on NVIDIA GPUs.
- Support vLLM or TensorRT-LLM local serving for large VLMs when the hardware and OS allow it.
- Support ONNX Runtime with CUDA or DirectML for smaller auxiliary models and internally converted artifacts.
- Keep CPU fallback only for lightweight profiles and tests.
- Surface the active provider, GPU device, VRAM estimate, quantization, and fallback reason in settings and debug logs.

Runtime selection order:

1. Exact model's preferred local runtime from the model manifest.
2. CUDA/TensorRT optimized artifact if available.
3. CUDA vLLM or local Transformers helper.
4. DirectML/ONNX for converted auxiliary models.
5. CPU-lightweight profile only when explicitly permitted.

RTX 5070 fit gate:

- A model profile is selectable only when it has a completed validation run on a 12 GB VRAM profile with the configured chunk length, frame count, resolution, max output tokens, and second-pass settings.
- Validation must record peak VRAM, p50/p95 chunk latency, failure rate, and output-schema validity.
- Default profiles should prefer 4B-8B models. 11B-12B models are advanced/tight profiles and must use official FP8/NVFP4 or KidsLens-owned 4-bit artifacts.
- Any model requiring sustained CPU offload for normal analysis is not considered RTX 5070-fit for the default pipeline.

Model bundle manifest must include:

- `modelId`
- `officialSourceRepo`
- `officialRevision`
- `license`
- `acceptedTermsRequired`
- `artifactType`
- `conversionRecipeId`
- `sha256`
- `runtime`
- `minVramGb`
- `supportsVideoInput`
- `supportsBoundingBoxes`
- `supportsMasks`
- `supportsPointLocalization`
- `maxFramesPerChunk`
- `maxContextTokens`
- `recommendedChunkSeconds`
- `knownFailureModes`

## 16. Debug Detection Overlay

Add a debug-only overlay for troubleshooting detection issues.

Build gating:

- The overlay must be compiled or enabled only in Flutter debug builds.
- It must be unavailable in release builds even if a persisted setting says it was enabled.
- Guard the UI and provider trace collection with `kDebugMode`.

Overlay features:

- Show sampled frame IDs and chunk boundaries on the video timeline.
- Draw bounding boxes, masks, points, and scene-level detection bands.
- Color-code categories and severity.
- Show model/provider names, runtime, GPU device, confidence, and grounding status.
- Show rationale text for the selected detection.
- Show supporting evidence IDs and raw provider output for developer inspection.
- Show first-pass vs second-pass differences.
- Show provider disagreement, fallback, schema repair, or failed-grounding warnings.
- Export a local debug bundle containing manifests, redacted prompts, parsed JSON, frame IDs, and timing metrics.

Privacy rule:

- Debug bundles stay local and should never include API keys or unrelated user files.

## 17. Immediate Engineering Tasks

Recommended first PR sequence:

1. Add planning and contract docs.
2. Add `DetectionPipeline` and registry without changing behavior.
3. Wrap the current visual path as `legacy_nsfw_region_v8`.
4. Add `VideoChunk`, `EvidenceRecord`, and `PolicyFinding` models.
5. Add chunk planner tests.
6. Add evidence-store replay tests.
7. Add local-only `VlmProvider` interface and a mock provider for deterministic tests.
8. Add official model-bundle manifest validation.
9. Add policy engine with golden fixtures.
10. Add local runtime adapters behind a feature flag.
11. Add grounding provider and boundary metadata.
12. Add debug-only detection overlay.
13. Add search index after evidence records are stable.

## 18. Main Design Decisions

- Keep current pipelines, but demote them to evidence providers in the new default path.
- Make VLM analysis the default reasoning layer only when an official local model bundle and local runtime are available.
- Use chunk-level evidence as the source of truth, not frame-level classifier scores.
- Introduce search/retrieval because it improves review, explainability, and second-pass analysis.
- Avoid an embedded graph database for v1; use typed edges in SQLite and revisit only if search/reasoning needs exceed that model.
- Treat immodest clothing as a policy profile with review-first defaults until enough validation data exists.
- Require boundaries for region-capable findings when the selected model stack can produce them.
- Provide user-facing rationales for every detection and developer-facing traces in debug builds.
- Never use cloud inference or community model ports in the default or production pipeline.
