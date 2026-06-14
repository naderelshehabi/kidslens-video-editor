# VSS Family Safety v2: Local VLM Execution Plan

Date: 2026-06-12
Supersedes the open work in: `docs/implement/vss-family-safety-detection-revamp-plan.md` and `docs/implement/vss-family-safety-detection-implementation-checklist.md` (governance/contract content in those documents remains valid; this plan replaces their runtime-integration direction).

This plan is written to be executed by an agent with no access to this planning session. Every task lists the exact files, classes, and behavior required. Web-verified facts are cited with URLs and the date verified (2026-06-12).

---

## 1. Why this plan exists: the real state of the codebase

The 18-phase checklist in `vss-family-safety-detection-implementation-checklist.md` is marked complete, but a code audit (2026-06-12) shows the production analysis path never executes any of the new VSS machinery:

- `lib/services/detection/vss_family_safety_pipeline_adapter.dart:34` — the "VSS pipeline" yields one status message, then `yield* _runAnalysis(request)`.
- `lib/services/analysis_service.dart:124` — that runner is bound to `_runLegacyAnalysis`, i.e. the **exact legacy NSFW/NudeNet flow** (`analysis_service.dart:248`). Selecting `vss_family_safety_v1` changes nothing except a log line.
- `VlmProvider.analyzeSegment()` (`lib/services/detection/vlm_provider.dart:136`) is **never called outside tests**. The HTTP adapters POST `VideoSegmentRequest.toProviderJson()` (`vlm_provider.dart:93-102`), which contains **frame IDs and timestamps but zero image pixel data**. No real VLM server could answer such a request.
- No code anywhere spawns, bundles, or manages a local model server process. `LocalRuntimeManager` (`lib/services/detection/local_runtime_manager.dart`) only validates config objects and queries GPU info.
- `ChunkPlanner`, `EvidenceStore`, `PolicyEngine`, `TemporalFusion`, `PolicyDetectionBuilder`, `GroundingProvider`, `LocalSearchIndex` are complete, tested implementations that are **dead code in production** — instantiated only by tests.
- `ModelManagerService.downloadModelBundle()` (uncommitted changes in working tree) can download files from official HF repos but downloads **every file matching artifact extensions** — unusable for GGUF repos where you need exactly one quant file + one mmproj file. Nothing loads or serves a downloaded VLM.
- Frame extraction (`FrameSamplingService.sampleFrames`, `frame_sampling_service.dart:164`) is real and works (FFmpeg streaming → raw RGB), but only feeds the legacy ONNX path. `selectFrameRefsForChunks` (`frame_sampling_service.dart:217`) produces metadata-only refs, never pixels.

**Conclusion: the project has excellent contracts, governance, policy, fusion, and explainability layers — and no engine.** This plan builds the engine and wires the existing layers to it. Roughly 70% of the remaining work is integration, not new design.

---

## 2. Direction changes (research-verified, replaces prior runtime/model assumptions)

### 2.1 Runtime: bundled `llama-server` replaces the vLLM/TensorRT-LLM/NIM direction

The previous plan listed `cuda_vllm`, `cuda_tensorrt` (NIM/TensorRT-LLM), and a Transformers helper as the local runtimes. Verified 2026-06-12, none of these are shippable inside a consumer Windows desktop app:

- **vLLM**: still no native Windows support, no roadmap for it; WSL2 or community forks only (https://docs.vllm.ai/en/latest/getting_started/installation/gpu/). Not viable to silently install for end users.
- **TensorRT-LLM**: Windows support **formally deprecated as of v0.18.0**, code being removed (https://nvidia.github.io/TensorRT-LLM/0.19.0/release-notes.html). Eliminated.
- **llama.cpp `llama-server`**: MIT license; official Windows CUDA prebuilt binaries published per release (e.g. `llama-<tag>-bin-win-cuda-13.3-x64.zip` + `cudart-llama-bin-win-cuda-13.3-x64.zip`, the latter bundling CUDA runtime DLLs so users need no CUDA toolkit); multimodal VLM support via the `mtmd` library with `--mmproj`; **Qwen3-VL supported since 2025-10-30** (https://github.com/ggml-org/llama.cpp/pull/16780); OpenAI-compatible `/v1/chat/completions` accepting multiple base64 `image_url` content parts; `response_format` JSON enforcement backed by GBNF grammar; `/health` endpoint; official Vulkan build as the vendor-neutral GPU fallback (llama.cpp has no DirectML backend) (https://github.com/ggml-org/llama.cpp/blob/master/docs/multimodal.md, https://github.com/ggml-org/llama.cpp/blob/master/tools/server/README.md, https://github.com/ggml-org/llama.cpp/releases).

**Decision: the production VLM runtime is `llama-server.exe` spawned by the app as a child process bound to `127.0.0.1` on a dynamically chosen port.** CUDA build for NVIDIA GPUs (RTX 50-series requires the CUDA ≥12.8-based build, use the CUDA 13.x build), Vulkan build as fallback for non-NVIDIA/driver-broken machines. This is the same pattern LM Studio/Jan use, gives crash isolation for free (CUDA OOM kills the child, not the app), needs no FFI, and satisfies the existing loopback-only policy (`LocalRuntimeEndpointPolicy`).

`cpu_lightweight` (legacy ONNX path) and `directml_onnx` remain for the legacy/auxiliary models. `cuda_vllm`/`cuda_tensorrt`/`cuda_transformers_helper` runtime IDs stay defined for manifest compatibility but become non-selectable on Windows (see Phase 1). ONNX Runtime GenAI + `microsoft/Phi-4-multimodal-instruct-onnx` is kept in the catalog as a future DirectML/NPU contingency only — llama.cpp does not support Phi-4-multimodal (Mixture-of-LoRAs design; https://huggingface.co/microsoft/Phi-4-multimodal-instruct/discussions/7), and building a Dart FFI layer for onnxruntime-genai is not justified while the llama.cpp path works.

### 2.2 Primary model: Qwen3-VL-8B-Instruct (official vendor GGUF)

Verified 2026-06-12 on Hugging Face:

| Model | License | Why |
|---|---|---|
| `Qwen/Qwen3-VL-8B-Instruct` + official `Qwen/Qwen3-VL-8B-Instruct-GGUF` | Apache 2.0 | **Primary.** Official *vendor-published* GGUF (satisfies the official-artifacts-only rule with no KidsLens conversion needed): `Qwen3VL-8B-Instruct-Q4_K_M.gguf` (5,027,784,800 bytes) + `mmproj-Qwen3VL-8B-Instruct-F16.gguf` (1,159,029,824 bytes). Q4_K_M + mmproj + 16K KV ≈ 7–9 GB VRAM → fits RTX 5070 12 GB. Native 2D grounding (bounding-box output) per model card. Qwen3-VL-8B is competitive with Qwen2.5-VL-72B on video understanding per the Qwen3-VL technical report (https://arxiv.org/abs/2511.21631). |
| `Qwen/Qwen3-VL-4B-Instruct` + official GGUF | Apache 2.0 | **Lightweight profile** (8 GB cards / headroom mode): `Qwen3VL-4B-Instruct-Q4_K_M.gguf` (2,497,281,664 bytes) + `mmproj-Qwen3VL-4B-Instruct-F16.gguf` (836,180,256 bytes). |
| `Qwen/Qwen3-Embedding-0.6B-GGUF` | Apache 2.0 | **Search embeddings**: `Qwen3-Embedding-0.6B-Q8_0.gguf` (639,150,592 bytes), runs on CPU in a second llama-server instance with `--embedding --pooling last`. |

Catalog corrections required (verified against live HF, 2026-06-12):

- `nvidia/NVIDIA-Nemotron-Nano-12B-v2-VL` (non-FP8) does not exist; the BF16 repo is `nvidia/NVIDIA-Nemotron-Nano-12B-v2-VL-BF16`. The FP8 variant needs ~13 GB weights — **does not fit 12 GB**; only `nvidia/NVIDIA-Nemotron-Nano-12B-v2-VL-NVFP4-QAD` (~6.5–7 GB) fits, but requires TensorRT-LLM/vLLM NVFP4 support → not runnable under llama.cpp → demote to R&D watchlist.
- `nvidia/Cosmos-Reason1-7B` is superseded by **`nvidia/Cosmos-Reason2-8B`** (released 2025-12-19, NVIDIA Open Model License, commercial use permitted; https://huggingface.co/nvidia/Cosmos-Reason2-8B). No official quant fits 12 GB → R&D watchlist until a KidsLens-owned quant exists.
- `meta-llama/Llama-4-Scout-17B-16E-Instruct` is a 109B-total MoE; even FP8 needs ~55 GB. **Remove from candidates entirely** (move to excluded).
- `Qwen/Qwen3.5-4B` exists (released 2026-02-16, Apache 2.0, natively multimodal early-fusion), but has **no official GGUF** and llama.cpp support is unverified → watchlist, not a v2 target.
- `google/gemma-4-E4B-it` and `google/gemma-4-12B-it` exist (Gemma 4, Apache 2.0 — verified), but Google publishes **no official quantized artifacts**, and gemma-4-12B caps video at 60 s @ 1 fps → keep as approved candidates requiring KidsLens-owned GGUF conversion; not v2 targets.
- `nvidia/LocateAnything-3B` confirmed **non-commercial license** → stays production-blocked (already correct in the catalog).

### 2.3 Pipeline parameters (adapted from NVIDIA VSS, verified docs)

NVIDIA VSS uses 10–30 s chunks with 8–10 uniformly sampled frames per chunk and optional chunk overlap (https://docs.nvidia.com/vss/2.3.1/content/architecture.html, https://nvidia-cosmos.github.io/cosmos-cookbook/recipes/inference/reason2/vss/inference.html). The existing `ChunkPlannerConfig` defaults (8 s target / 4–12 s bounds / 0.75 s overlap, `chunk_planner.dart:8-15`) are consistent with this for fast-event recall — **keep them**.

Frame budget per chunk (Qwen3-VL dynamic resolution ≈ H×W/1024 tokens per frame; a 768×432 frame ≈ 324 tokens):
- First pass: **8 frames**, long side ≤ 768 px → ≈ 2.6K image tokens + ~1.2K prompt ≈ well within a 16K context.
- Second pass (escalation): **16 frames**, long side ≤ 768 px.

**VLM runs on every chunk by default.** Research shows cheap gates (NudeNet ~74–78% measured accuracy; https://arxiv.org/pdf/2506.02761) create false negatives that defeat the high-recall objective. Gating by legacy classifiers is allowed only in the `fast_preview` profile.

### 2.4 Taxonomy additions

The product objective explicitly includes kissing and substances. Amazon Rekognition v7 has a dedicated "Kissing" node; Sightengine grades immodesty/suggestiveness in tiers (https://docs.aws.amazon.com/rekognition/latest/dg/moderation-api.html, https://sightengine.com/docs/image-video-moderation-classes-and-concepts). Add one category and enrich prompt guidance (Phase 6):

- New policy category `kissing_romance` (review-first, scene-level, default action `review`).
- Weapon prompt guidance distinguishes state: `in_hand / aimed / worn / displayed / toy` (Hive-style state-aware classes).
- Immodesty prompt guidance enumerates graded exposure signals (cleavage, bare midriff, bare legs, bare arms, swimwear, lingerie, miniskirt/minishort), mapped to severity by the policy engine — the schema's `exposureSignals` field already supports this.

### 2.5 Licensing flag: NudeNet is AGPL-3.0

NudeNet (code; weights status murky — treat as AGPL) is AGPL-3.0 (https://github.com/notAI-tech/NudeNet). This repo is MIT. Treat NudeNet as a legacy auxiliary only: (a) record the AGPL status in the NudeNet registry entry metadata, (b) do not bundle NudeNet weights in the installer, (c) keep NudeNet disabled by default in commercial/release builds unless legal approves the exact distribution and invocation model, and (d) plan replacement of region grounding with Qwen3-VL native grounding (Phase 7).

### 2.6 Execution hardening added after plan review

The following constraints are mandatory implementation details:

- **Runtime spike before broad refactor.** Before building the full runtime manager and orchestrator, run a tiny local smoke harness against the exact pinned llama.cpp release and Qwen3-VL GGUF/mmproj files. It must prove: process startup, `/health`, multi-image OpenAI-compatible request shape, JSON response handling, and approximate VRAM footprint.
- **Per-file artifact integrity.** `artifactFiles` must not be raw strings long term. Use structured artifact metadata (`path`, `sizeBytes`, `sha256`, `required`) so every official GGUF/mmproj/runtime zip is verified independently.
- **Local-only analysis boundary.** Model/runtime download may use the public internet. Once analysis starts, network access must be loopback-only. Add a guard test that fails if the VSS analysis path opens non-loopback HTTP(S) endpoints.
- **Fallback must be visible.** Registry/UI preflight decides whether VSS is runnable before analysis starts. The VSS pipeline may fall back to legacy only for startup failure or mid-run runtime crash, and that fallback must be recorded as a degraded run.
- **Frame extraction must be measured.** Per-frame FFmpeg extraction is allowed for the first deterministic implementation only if an exit gate measures it. If frame extraction exceeds 10-15% of wall time on a representative sample, switch to per-chunk batch extraction before Phase 5.
- **Process hardening.** Runtime management must handle stale child cleanup on app startup, one active VLM server per GPU, loopback port race retries, stderr/stdout ring-buffer diagnostics, and clear provenance for downloaded executables.

---

## 3. Target architecture (end state of this plan)

```
AnalysisService.analyze()  [pipeline = vss_family_safety_v1]
  └─ VssFamilySafetyPipeline (NEW, real orchestrator — replaces delegation to _runLegacyAnalysis)
       Stage 0  Run setup: resolve model bundle + runtime, start/attach LlamaServerManager,
                write AnalysisRunManifest, open JsonEvidenceStore (project cache)
       Stage 1  Ingestion: probe media, detectSceneChanges (existing FFmpeg),
                ChunkPlanner.planChunks (existing), selectFrameRefsForChunks (existing)
       Stage 2  Audio: transcription + profanity (existing stages, refactored to be shared)
                → EvidenceRecords (transcript_span, profanity_match)
       Stage 3  Auxiliary visual pass (optional, default ON): legacy NSFW/NudeNet/parser
                via existing _runVisualAnalysis machinery → EvidenceRecords (auxiliary only)
       Stage 4  VLM first pass, per chunk: extractChunkJpegFrames (NEW) →
                OpenAiCompatVlmProvider.analyzeSegment (NEW concrete provider, base64 JPEG)
                → schema-validated JSON → EvidenceRecords (vlm_policy_json, vlm_caption)
                → checkpoint after each chunk
       Stage 5  Second pass: escalate uncertain/high-risk chunks (16 frames + grounding prompt)
                → grounded_region EvidenceRecords via existing VLM-native grounding parser
       Stage 6  PolicyEngine.forPipeline('vss_family_safety_v1') over the evidence store (existing)
       Stage 7  TemporalFusion + PolicyDetectionBuilder (existing) → Detection / UnifiedTimeline
       Stage 8  FamilySafetySearchIndexer (existing) → JSON search index in project cache
  └─ legacy_nsfw_region_v8 → unchanged _runLegacyAnalysis

LlamaServerManager (NEW)
  ├─ RuntimeBinaryManager (NEW): downloads pinned llama.cpp release zips (CUDA 13.x + Vulkan
  │   + cudart) from github.com/ggml-org/llama.cpp/releases, sha256-verified, unzipped under
  │   <appSupport>/kidslens_runtimes/llamacpp/<tag>/
  ├─ spawns llama-server.exe on 127.0.0.1:<dynamic port>, polls GET /health
  ├─ one VLM instance (GPU); optional second embedding instance (CPU)
  └─ kills children on app exit / analysis cancel / idle timeout
```

---

## 4. Implementation checklist

Phases are ordered for execution. Each has an exit gate. Run `flutter analyze` and `flutter test` after every phase. The repo builds on Windows; FFmpeg and whisper integrations already work — do not touch them except where stated.

### Phase 0 — Housekeeping (commit in-flight work, fix wrong model IDs)

- [x] 0.1 Commit the current working-tree changes (`lib/services/model_manager_service.dart`, `test/services/model_manager_service_test.dart`). They are coherent and complete: HEAD-request file-size resolution for HF repos, gated-repo (401/403) error messaging with `HF_TOKEN` guidance, 404 handling, progress-percentage test. Verified with `flutter test test/services/model_manager_service_test.dart`. Commit: `c044424 feat(models): resolve HF file sizes via HEAD and report gated-repo token guidance`.
- [x] 0.2 In `lib/data/models/model_bundle_manifest.dart`, fix `nvidia_nemotron_nano_12b_v2_vl_fp8` notes/status: FP8 weights ≈ 13 GB do **not** fit the 12 GB target; set its status to the same evaluation/R&D-blocked status used for the Llama-4 entries (it must not be production-selectable), and update `knownFailureModes` to say "FP8 weights exceed 12GB VRAM; NVFP4-QAD variant requires TensorRT-LLM/vLLM (not available on Windows)". The `kidslens_nemotron_nano_12b_v2_vl_int4` internal-artifact placeholder stays as-is (future).
- [x] 0.3 Same file: move `meta_llama_4_scout_17b_16e_instruct` and `nvidia_llama_4_scout_17b_16e_instruct_fp8` to excluded/blocked status (109B-total MoE cannot run on consumer 12 GB; keep the manifest entries for record, status = blocked, with that rationale in notes).
- [x] 0.4 Same file: add a watchlist (non-selectable) entry for `nvidia/Cosmos-Reason2-8B` (`modelId: 'nvidia_cosmos_reason2_8b'`, NVIDIA Open Model License, commercial use allowed, supersedes Cosmos-Reason1; `runtime: ModelBundleRuntime.notYetValidated`; note: "no official ≤12GB quant; requires KidsLens-owned quantized artifact"). Mark `nvidia_cosmos_reason1_7b` notes as superseded by Reason2.
- [x] 0.5 Update `docs/implement/model-bundle-manifest-source-review.md` with the verification notes from §2.2 of this plan (dates + URLs).
- [x] 0.6 Add a Phase 0.5 runtime smoke-spike task file or script stub that documents the exact manual command flow for pinned llama.cpp + Qwen3-VL. This is a gate before Phase 2/3 implementation; it may skip execution when the large model/runtime artifacts are absent, but it must define inputs, expected outputs, and failure signals.
- [x] Exit gate: `flutter test test/data/models/` and `test/services/detection/model_bundle_selection_policy_test.dart` pass after catalog edits (adjust test fixtures that reference moved statuses). Verified 2026-06-14; analyzer clean for touched Dart files; smoke-spike help command runs.

### Phase 1 — Model catalog: GGUF bundles, explicit artifact file lists, llama.cpp runtime enums

- [ ] 1.1 `lib/data/models/model_bundle_manifest.dart`:
  - Add enum value `ModelBundleRuntime.llamaCppServer`.
  - Add enum value `ModelBundleArtifactType.officialGguf`.
  - Add `ModelBundleArtifactFile` with `path`, `sizeBytes`, `sha256`, and `required`, then add `final List<ModelBundleArtifactFile> artifactFiles;` (default `const []`) to `ModelBundleManifest` — when non-empty, the downloader fetches **exactly these repo paths** instead of all artifact-extension matches. Include in JSON serialization and tests.
  - Update manifest validation: `officialGguf` + `llamaCppServer` is a valid production combination; `artifactFiles` must be non-empty for `officialGguf` bundles; every production-selectable artifact file must have a verified size and sha256.
- [ ] 1.2 `lib/data/models/local_runtime_profile.dart`: add `LocalRuntimeId.cudaLlamaCpp('cuda_llamacpp')` and `LocalRuntimeId.vulkanLlamaCpp('vulkan_llamacpp')` with corresponding `LocalRuntimeProfile` entries (display names "Local llama.cpp server (CUDA)" / "(Vulkan)"). Keep existing IDs for compatibility.
- [ ] 1.3 `lib/services/detection/local_runtime_manager.dart`: runtime selection order on Windows becomes: manifest runtime → `cudaLlamaCpp` (when an NVIDIA GPU is discovered) → `vulkanLlamaCpp` (any GPU) → `directmlOnnx` (legacy ONNX models only) → `cpuLightweight` (only when explicitly permitted). `cuda_vllm` / `cuda_tensorrt` / `cuda_transformers_helper` must resolve as unavailable on Windows with a structured fallback reason ("runtime not supported on Windows desktop").
- [ ] 1.4 Add three catalog entries to `ModelBundleCatalog` (exact values; sha256 must be filled at implementation time by downloading each file once and hashing it — record in the manifest and in `docs/implement/model-bundle-manifest-source-review.md`):

  | field | primary VLM | lightweight VLM | embedding |
  |---|---|---|---|
  | modelId | `qwen3_vl_8b_instruct_gguf_q4km` | `qwen3_vl_4b_instruct_gguf_q4km` | `qwen3_embedding_0_6b_gguf_q8` |
  | officialSourceRepo | `Qwen/Qwen3-VL-8B-Instruct-GGUF` | `Qwen/Qwen3-VL-4B-Instruct-GGUF` | `Qwen/Qwen3-Embedding-0.6B-GGUF` |
  | artifactUri | `hf://Qwen/Qwen3-VL-8B-Instruct-GGUF` | `hf://Qwen/Qwen3-VL-4B-Instruct-GGUF` | `hf://Qwen/Qwen3-Embedding-0.6B-GGUF` |
  | artifactFiles | `['Qwen3VL-8B-Instruct-Q4_K_M.gguf', 'mmproj-Qwen3VL-8B-Instruct-F16.gguf']` | `['Qwen3VL-4B-Instruct-Q4_K_M.gguf', 'mmproj-Qwen3VL-4B-Instruct-F16.gguf']` | `['Qwen3-Embedding-0.6B-Q8_0.gguf']` |
  | license | Apache 2.0 | Apache 2.0 | Apache 2.0 |
  | artifactType | officialGguf | officialGguf | officialGguf |
  | runtime | llamaCppServer | llamaCppServer | llamaCppServer |
  | quantization | `Q4_K_M` | `Q4_K_M` | `Q8_0` |
  | minVramGb / recommendedVramGb | 8 / 10 | 5 / 6 | 0 (CPU) / 1 |
  | supportsVideoInput / ImageInput | false / true (frames-as-images) | false / true | n/a |
  | supportsBoundingBoxes | true (Qwen3-VL native 2D grounding) | true | n/a |
  | maxFramesPerChunk | 16 | 16 | n/a |
  | maxContextTokens | 16384 (serving config; model supports 256K) | 16384 | 8192 |
  | recommendedChunkSeconds | 8 | 8 | n/a |
  | acceptedTermsRequired | false (Apache 2.0, ungated) | false | false |
  | fitsRtx5070Validated | false until Phase 10 validation run recorded | false | true after CPU smoke run |

  (File names/sizes verified 2026-06-12 via the HF API: 8B Q4_K_M = 5,027,784,800 B; 8B mmproj F16 = 1,159,029,824 B; 4B Q4_K_M = 2,497,281,664 B; 4B mmproj F16 = 836,180,256 B; embedding Q8_0 = 639,150,592 B. Note the file names spell `Qwen3VL` without a hyphen.)
- [ ] 1.5 `lib/services/model_manager_service.dart` → `downloadModelBundle()`: when `manifest.artifactFiles` is non-empty, skip extension-based sibling filtering and download exactly those paths (still resolving missing sizes via the existing HEAD logic, still recording metadata, and verifying per-file sha256 when provided). Add a test downloading a 2-file fake GGUF bundle from the local fake HF server (mirror the existing gemma test pattern in `test/services/model_manager_service_test.dart`).
- [ ] 1.6 Record NudeNet's AGPL-3.0 license in its `HuggingFaceModelRegistry` entry metadata (license field/comment) so the settings UI can display it; do not change its behavior.
- [ ] Exit gate: catalog tests pass; `ModelBundleCatalog.byModelId('qwen3_vl_8b_instruct_gguf_q4km')` validates; bundle download test with explicit `artifactFiles` passes.

### Phase 2 — Runtime binaries and `LlamaServerManager`

New file `lib/services/detection/runtime_binary_manager.dart`:

- [ ] 2.1 `RuntimeBinaryManager` downloads and verifies the llama.cpp server binaries:
  - Pin one release tag in a const config (choose the latest release at implementation time from https://github.com/ggml-org/llama.cpp/releases; record tag + per-zip sha256 in the const and in `docs/implement/model-bundle-manifest-source-review.md`).
  - Three assets: `llama-<tag>-bin-win-cuda-13.3-x64.zip` (or current CUDA-13.x asset name), `cudart-llama-bin-win-cuda-13.3-x64.zip`, `llama-<tag>-bin-win-vulkan-x64.zip`. Asset names change across releases — resolve them by pattern (`bin-win-cuda-1[23]`, `cudart-llama-bin-win-cuda`, `bin-win-vulkan-x64`) against the pinned tag's asset list at implementation time, then hardcode the resolved names + checksums.
  - Download URL shape: `https://github.com/ggml-org/llama.cpp/releases/download/<tag>/<asset>`.
  - Extract under `<getApplicationSupportDirectory()>/kidslens_runtimes/llamacpp/<tag>/cuda/` and `/vulkan/` (cudart DLLs extracted into the `cuda/` directory beside `llama-server.exe`).
  - Expose `Future<RuntimeBinaryStatus> status()`, `Stream<DownloadProgress> ensureInstalled(RuntimeFlavor flavor)`, `String? serverExePath(RuntimeFlavor flavor)`. sha256-verify each zip before extraction; refuse to run unverified binaries.
  - Use Dart's `package:archive`? **No new heavyweight deps**: prefer invoking PowerShell `Expand-Archive` via `Process.run` (Windows-only app) or add `archive` to pubspec — implementer's choice; document the choice in code.
- [ ] 2.2 New file `lib/services/detection/llama_server_manager.dart` — `LlamaServerManager`:
  - `Future<LlamaServerHandle> startVlm({required ModelBundleManifest bundle, required RuntimeFlavor flavor, required String modelDir})`:
    - Resolve model + mmproj paths from the downloaded bundle files.
    - Pick a free loopback port (bind a `ServerSocket` to port 0, read the port, close it).
    - Spawn: `llama-server.exe -m <model.gguf> --mmproj <mmproj.gguf> --host 127.0.0.1 --port <port> -ngl 99 --ctx-size 16384 --parallel 1 --flash-attn on --jinja --no-webui` (verify the flash-attn flag spelling against the pinned release's `llama-server --help`; older builds use `-fa`). For the Vulkan flavor, same flags.
    - Poll `GET http://127.0.0.1:<port>/health` until HTTP 200 (timeout 120 s — first load maps the model into VRAM), capturing stderr to a ring buffer for diagnostics.
    - On failure with CUDA flavor (process exit, OOM string in stderr, health timeout): kill, retry once with `--ctx-size 8192`, then fall back to Vulkan flavor, then surface a structured `LocalRuntimeStatus` failure (existing type) — never silently fall back to CPU.
  - `Future<LlamaServerHandle> startEmbedding({...})`: spawn a second instance with `-m Qwen3-Embedding-0.6B-Q8_0.gguf --embedding --pooling last -ngl 0 --host 127.0.0.1 --port <port> --no-webui` (CPU; embeddings are cheap).
  - `LlamaServerHandle` carries `port`, `process`, `flavor`, `bundleId`, `Future<void> dispose()` (graceful kill + wait). Manager tracks handles, kills all on `dispose()`; register cleanup with `AppLifecycleListener`/app shutdown hook in `lib/app.dart` and on analysis cancellation.
  - Idle shutdown: stop the VLM instance after N minutes with no requests (default 10) to release VRAM; restart lazily.
  - Hardening: clean stale child processes started by KidsLens on app startup, keep at most one active VLM instance per GPU, retry port allocation if the selected loopback port is stolen before spawn, and retain stderr/stdout ring-buffer diagnostics for UI/debug overlay and failure reports.
- [ ] 2.3 Unit tests (`test/services/detection/llama_server_manager_test.dart`): spawn-arg construction, port allocation, health-poll loop against a fake local HTTP server, fallback ordering, dispose kills process (use a stub executable, e.g. a tiny PowerShell/cmd script that serves nothing — assert process kill semantics only). The real-binary integration test lives in Phase 10.
- [ ] Exit gate: all unit tests pass; manual smoke (`dart run` harness or debug menu) can start/stop a real llama-server when binaries+model are present.

### Phase 3 — VLM provider that actually sends frames (OpenAI-compatible)

Modify `lib/services/detection/vlm_provider.dart`:

- [ ] 3.1 Add a frame-image payload type and extend the request:
  ```dart
  class VlmFrameImage {
    const VlmFrameImage({required this.frameRef, required this.jpegBytes});
    final SampledFrameRef frameRef;
    final Uint8List jpegBytes;
  }
  ```
  Add `final List<VlmFrameImage> frameImages;` (default `const []`) to `VideoSegmentRequest`. Validation (`validateAgainstManifest`): when the provider requires pixels (see 3.2), `frameImages.length` must equal `frames.length` and be ≥ 1; each `jpegBytes` non-empty. Keep `toProviderJson()` for the legacy/test providers, but it must never include raw bytes.
- [ ] 3.2 Add concrete provider `OpenAiCompatVlmProvider` (same file or new `lib/services/detection/openai_compat_vlm_provider.dart`):
  - Constructor: `{required Uri endpoint, required LocalRuntimeProfile runtimeProfile, String providerId = 'local_llamacpp_server', http.Client? client, VlmJsonParser parser = const VlmJsonParser()}`. Reuse the loopback validation from `LocalHttpVlmProvider` (extract that check into a shared helper rather than subclassing, because the request body differs).
  - `analyzeSegment`: POST `<endpoint>/v1/chat/completions` with body:
    ```json
    {
      "model": "<bundle.modelId>",
      "messages": [
        {"role": "system", "content": "<FamilySafetyPromptTemplates system text>"},
        {"role": "user", "content": [
          {"type": "text", "text": "<request.prompt — includes chunk timing context>"},
          {"type": "image_url", "image_url": {"url": "data:image/jpeg;base64,<frame 1>"}},
          ... one part per frame, in timestamp order, each preceded by a short text part "frame i/N at <mm:ss.mmm>" ...
        ]}
      ],
      "max_tokens": <request.maxOutputTokens>,
      "temperature": 0.1,
      "response_format": {"type": "json_object"}
    }
    ```
    Extract `choices[0].message.content`, run the existing `VlmJsonParser.parse` (schema validation + deterministic repair), then reuse the existing `_buildResponse` evidence path unchanged.
    Note: llama-server also supports `response_format: {"type":"json_schema","json_schema":{...}}` (grammar-enforced). Implement `json_object` first (universally supported), then attempt `json_schema` with `FamilySafetyVlmOutputSchema` expressed as JSON Schema and keep it behind a provider option `enforceJsonSchema` (default true, auto-fallback to `json_object` on HTTP 400).
  - Retry policy: on `VlmSchemaException`, retry once appending `"Your previous reply was not valid JSON matching the schema. Reply with ONLY the JSON object."`; on second failure record an evidence-level provider failure (the policy engine already maps provider failure → review finding).
  - Local-only guard: provider construction and tests must reject every non-loopback endpoint. The VSS analysis path must be covered by a test that fails if analysis tries to call a non-loopback HTTP(S) URL after model/runtime installation.
  - Timeout/cancellation: reuse `_withCancellation`.
- [ ] 3.3 Map `LocalRuntimeId.cudaLlamaCpp`/`vulkanLlamaCpp` → this provider in whatever factory Phase 5 builds (`VlmProviderFactory.forRuntime(...)`, new small file `lib/services/detection/vlm_provider_factory.dart`).
- [ ] 3.4 Tests (`test/services/detection/openai_compat_vlm_provider_test.dart`): fake loopback HTTP server asserting (a) base64 JPEG data URLs present, one per frame, correct order; (b) `response_format` passed; (c) OpenAI envelope parsed; (d) schema-retry happens exactly once; (e) evidence records persisted via the existing in-memory store; (f) non-loopback endpoint rejected.
- [ ] Exit gate: provider tests pass; existing `vlm_provider_test.dart` still passes.

### Phase 4 — Chunk-aware JPEG frame extraction

Modify `lib/services/frame_sampling_service.dart`:

- [ ] 4.1 Add:
  ```dart
  Future<List<VlmFrameImage>> extractChunkJpegFrames({
    required String videoPath,
    required VideoChunk chunk,
    required List<SampledFrameRef> frameRefs, // from selectFrameRefsForChunks
    int maxLongSide = 768,
    int jpegQuality = 85, // ffmpeg -q:v 4
    CancellationToken? cancellationToken,
  })
  ```
  Implementation baseline: one FFmpeg invocation **per frame ref** using fast input seeking, writing JPEG to stdout (no temp files):
  `ffmpeg -ss <ts> -i <video> -frames:v 1 -vf "scale='min(768,iw)':-2" -q:v 4 -f image2 pipe:1`
  Collect stdout bytes per call. Add timing instrumentation around extraction. If this stage exceeds 10-15% of wall time on a representative sample, switch before Phase 5 to a single `-ss <chunkStart> -to <chunkEnd>` invocation with a `select='eq(n,..)+..'` filter writing numbered JPEGs to a temp dir.
  Reuse the existing FFmpeg path-resolution used by `_extractFrame` (`frame_sampling_service.dart:598`). Throw `FrameSamplingException` on non-zero exit with stderr tail.
- [ ] 4.2 Tests: against the existing video fixture used by `frame_sampling_service` tests — assert JPEG magic bytes (`FF D8`), count == refs count, decoded dimensions ≤ 768 long side (dimension check can parse the JPEG SOF header or just assert byte size sanity if no decoder dep exists).
- [ ] Exit gate: extraction test passes on the fixture video.

### Phase 5 — The real `VssFamilySafetyPipeline` orchestrator (core of this plan)

- [ ] 5.1 Refactor `lib/services/analysis_service.dart` to expose its reusable stages without changing legacy behavior:
  - Extract the audio stage (`_transcribeAudio` at :634, `_detectProfanity` at :700) and the visual-auxiliary machinery (`_resolveVisualContext` :717, `_runVisualAnalysis` :998) so the new pipeline class can call them. Mechanism: pass `AnalysisService` itself (or a thin `AnalysisStageHost` interface exposing those four methods + `_checkState`) into the new pipeline's constructor. Do NOT copy/paste the stage bodies.
- [ ] 5.2 New file `lib/services/detection/vss_family_safety_pipeline.dart` — class `VssFamilySafetyPipeline implements DetectionPipeline` (profile: `DetectionPipelineProfile.vssFamilySafetyV1`). Constructor dependencies: stage host, `FrameSamplingService`, `ChunkPlanner`, `LlamaServerManager`, `RuntimeBinaryManager`, `ModelManagerService`, `LocalRuntimeManager`, `VlmProviderFactory`, `PolicyEngine.forPipeline(DetectionPipelineIds.vssFamilySafetyV1)`, `TemporalFusion`, `PolicyDetectionBuilder`, `FamilySafetySearchIndexer`, settings snapshot.
  `analyze(DetectionPipelineRequest request)` emits `AnalysisProgress` through these stages (progress step numbering must be stable and human-readable; reuse existing `AnalysisProgress` shape):
  1. **Setup**: resolve selected VLM bundle from settings (`SettingsState` role-based bundle IDs from Phase 14 work). Check bundle downloaded (`ModelManagerService`), runtime binaries installed (`RuntimeBinaryManager`), GPU available (`LocalRuntimeManager`). Registry/UI preflight should normally prevent VSS from starting when these are absent. If startup fails after preflight (server crash, OOM, health timeout) → emit a clear warning progress message, record a degraded-run fallback event, and fall back to the legacy runner. Start the server via `LlamaServerManager.startVlm`. Create `JsonEvidenceStore` at `<project analysis cache dir>/<mediaId>/evidence.jsonl` (use the same cache root the legacy checkpoints use — find it in the checkpoint persistence code and reuse). Write `AnalysisRunManifest` JSON next to it.
  2. **Ingestion**: probe duration/metadata (existing media probing), `detectSceneChanges` (existing, `frame_sampling_service.dart:416`), `ChunkPlanner.planChunks`, `selectFrameRefsForChunks` with `maxFrames: 8` for first pass.
  3. **Audio** (if profanity enabled in settings): run extracted audio stage; convert transcript spans + profanity matches to `EvidenceRecord`s (the converters exist — used by `EvidenceReplayService` tests; if they live only in tests, move them into `lib/services/detection/evidence_converters.dart`).
  4. **Auxiliary visual pass** (if `enableLegacyAuxiliarySignals` setting true, default true): run the extracted `_runVisualAnalysis` and convert NSFW scores / NudeNet regions / parser signals to auxiliary `EvidenceRecord`s. These are auxiliary-only — `PolicyEngineOptions.vssDefault()` already enforces that.
  5. **VLM first pass**: for each chunk (sequential — one GPU): cancellation check → `extractChunkJpegFrames` → build prompt via `FamilySafetyPromptTemplates` policy prompt with chunk timing → `provider.analyzeSegment` (evidence store attached so records persist automatically) → after each chunk append the chunk ID to a checkpoint file `vss_checkpoint.json` (fields: pipelineId, chunkPlannerHash, modelBundleId, completed chunk IDs — the checkpoint metadata fields from Phase 3 of the old checklist exist on `AnalysisRunManifest`). **Resume**: on start, if a checkpoint with matching hashes exists, skip chunks whose evidence is already in the store. Emit progress per chunk: `"VLM analysis: chunk i/N (mm:ss–mm:ss)"`, plus elapsed/ETA (the analysis dialog already displays elapsed time).
  6. **Second pass** (if `secondPassMode` setting != off): select chunks where first-pass findings have `needsReview == true`, confidence in [0.3, 0.8], any category in {explicit_nudity, gore, blood, weapons} at any confidence, or VLM-safe-but-auxiliary-unsafe disagreement (compare against stage-4 evidence). Re-run with 16 frames and the grounding prompt template; parse boxes with the existing VLM-native grounded-region path (`grounding_provider.dart`) producing `grounded_region` evidence.
  7. **Policy + fusion**: read all evidence from the store → `PolicyEngine.evaluate` → `TemporalFusion` → `PolicyDetectionBuilder` → final `Detection` list + `UnifiedTimeline` — yield exactly the same completion progress/result shape `_runLegacyAnalysis` yields so UI code is untouched (inspect how `_runLegacyAnalysis` returns its final `AnalysisResult` and mirror it).
  8. **Search index**: `FamilySafetySearchIndexer` over evidence + findings → `JsonSearchIndexStore` under the same cache dir. Failures here are non-fatal (log + continue).
  9. **Teardown**: release server handle to idle pool; close stores. On exception anywhere: record telemetry via the existing rollout telemetry, rethrow so `AnalysisService._recordFailure` handles it (existing fallback machinery applies).
- [ ] 5.3 Wire it in `lib/services/analysis_service.dart:124`: replace `VssFamilySafetyPipelineAdapter(runAnalysis: _runLegacyAnalysis)` with construction of the real `VssFamilySafetyPipeline` (inject dependencies; `AnalysisService` already constructs most of them). Keep `VssFamilySafetyPipelineAdapter` deleted or repurposed — prefer **delete** the adapter file and its tests; the registry resolves the new class. Update `DetectionPipelineProfile.vssFamilySafetyV1.canRun`/`isImplemented` logic so "directly runnable" = bundle + runtime present (used by shadow/rollout resolution).
- [ ] 5.4 Tests (`test/services/detection/vss_family_safety_pipeline_test.dart`): run the full pipeline against the existing small video fixture with: `MockVlmProvider` injected via `VlmProviderFactory` override (no real server), fake `LlamaServerManager` (no-op), audio disabled. Assert: chunk plan persisted, evidence records for vlm_policy_json per chunk, policy findings produced, detections emitted, timeline built, checkpoint written, resume skips completed chunks, cancellation mid-pass leaves a resumable checkpoint, unavailable-VLM falls back to legacy with a warning.
- [ ] 5.5 Add a no-network analysis guard test: with models/runtime marked installed and providers mocked on loopback, the VSS pipeline must not open any non-loopback HTTP(S) endpoint during analysis.
- [ ] Exit gate: full deterministic pipeline test passes end-to-end with the mock provider; all existing tests pass; selecting `legacy_nsfw_region_v8` is byte-identical to before.

### Phase 6 — Taxonomy and prompt enrichment

- [ ] 6.1 `lib/data/models/family_safety_policy.dart` (Phase 0 source of truth): add category `kissing_romance` — default action `review`, enforcement review-first, scene-level (no boundary requirement), severity mapping: peck/brief = low, prolonged/passionate = medium, with sexualized context escalating to `sexual_content` instead. Add to `PolicyCategory` wrapper and `PolicyEngine` mapping (VLM category string `kissing_romance` in the schema enum).
- [ ] 6.2 `lib/services/detection/family_safety_prompt_templates.dart`:
  - Add `kissing_romance` to the category enum in the policy prompt + schema validation (`FamilySafetyVlmOutputSchema`), with the existing "romantic kissing" example mapped to it.
  - Weapon guidance: require the evidence rationale to state weapon state (`in_hand`, `aimed`, `worn/holstered`, `displayed`, `toy/prop`); `toy/prop` with high confidence maps to severity `none`/`low`.
  - Immodesty guidance: enumerate graded exposure signals (cleavage, bare_midriff, bare_legs, bare_arms, swimwear, lingerie, miniskirt_minishort, sheer_clothing) in `exposureSignals`; policy engine maps signal count/type to severity (1 mild signal = low, multiple or swimwear/lingerie = medium+) — implement that mapping in `PolicyEngine`'s immodesty handler.
  - Substances guidance: distinguish alcohol consumption, smoking/vaping, illegal drugs, drug paraphernalia in rationale text (single `substances` category retained).
- [ ] 6.3 Update golden tests in `test/services/detection/family_safety_prompt_templates_test.dart` and `policy_engine_test.dart` for the new category and severity mappings.
- [ ] Exit gate: schema/prompt/policy golden tests pass.

### Phase 7 — Grounding via Qwen3-VL native boxes (NudeNet demotion path)

- [ ] 7.1 The second-pass grounding prompt must ask Qwen3-VL for normalized bounding boxes in the JSON `groundedRegions` field (the schema already defines it). Verify Qwen3-VL's grounding output convention (it emits absolute pixel coords against the supplied image by default) — the prompt must explicitly demand normalized `[0,1]` x/y/width/height in the JSON, and the parser must clamp + validate (existing `NormalizedGroundingBox` validation). Add a coordinate-sanity heuristic: if all box values > 1, divide by the frame's sent resolution and record a `schemaRepairWarnings` entry.
- [ ] 7.2 Wire grounded regions into detections (the fusion layer already carries `boundingBoxes`); confirm region blur export works from a VSS detection by extending the existing export-integration test to use a policy-built detection with boxes.
- [ ] 7.3 Settings: NudeNet auxiliary signals remain default-ON until Phase 10 eval shows VLM grounding parity; add the eval comparison "VLM grounding vs NudeNet regions" to the Phase 10 task list (box IoU on the labeled frames). Document the AGPL motivation in `docs/implement/legacy-direct-detection-deprecation-readiness.md`.
- [ ] Exit gate: grounding parse tests with realistic Qwen-style box outputs (both normalized and pixel-coord replies) pass; export test with region-blur from a grounded VSS detection passes.

### Phase 8 — Search embeddings via the embedding server (optional but cheap)

- [ ] 8.1 Add `LlamaServerEmbeddingProvider implements LocalEmbeddingProvider` (`lib/services/detection/local_search_index.dart` defines the interface): POST `/v1/embeddings` `{"model": "qwen3-embedding", "input": ["..."]}` to the embedding server handle; batch ≤ 32 texts per call. Query-side texts get the Qwen3-Embedding instruction prefix (`"Instruct: Given a family-safety video search query, retrieve relevant scene descriptions\nQuery: <q>"` — per the model card guidance).
- [ ] 8.2 `VssFamilySafetyPipeline` stage 8: if `qwen3_embedding_0_6b_gguf_q8` is downloaded, start the embedding instance and use it; otherwise fall back to the existing `HashLocalEmbeddingProvider` (already implemented) with a log line. Never block analysis on embeddings.
- [ ] 8.3 Tests with a fake embeddings endpoint (assert request shape, pooling of results into the existing JSON vector store).
- [ ] Exit gate: search over an analyzed fixture returns timestamped hits with either provider.

### Phase 9 — Settings, first-run experience, and UI status

- [ ] 9.1 Settings (`SettingsState` + Local Model Bundles tab `lib/presentation/screens/analysis_settings/local_model_bundles_tab.dart`): the three new GGUF bundles appear automatically from the catalog; ensure the role selectors offer `qwen3_vl_8b_instruct_gguf_q4km` (VLM role), `qwen3_vl_4b_instruct_gguf_q4km` (VLM lightweight), `qwen3_embedding_0_6b_gguf_q8` (embedding role). Default `vlmModelBundleId` to the 8B bundle **only after** Phase 10 flips `fitsRtx5070Validated: true`; until then the UI shows it as "ready to validate".
- [ ] 9.2 Add runtime install/download UX: in the Local Model Bundles tab, a "Local AI runtime" card showing llama.cpp install state (tag, flavor, size ≈ 0.5 GB CUDA / 0.1 GB Vulkan), with install/update buttons driving `RuntimeBinaryManager.ensureInstalled` with progress. Reuse the existing model-download progress widgets.
- [ ] 9.3 First-run flow: when a user starts an analysis with `vss_family_safety_v1` and bundle/runtime are missing, show a dialog: "Family-safety AI analysis needs a one-time download (~5.8 GB model + ~0.5 GB runtime). Download now / Use legacy analysis instead." Wire "Download now" to the existing download queue; persist the choice.
- [ ] 9.4 Analysis dialog: surface `LocalRuntimeStatus` (existing type) — runtime flavor, model name, GPU device, VRAM estimate, fallback reason — during VSS runs; show per-chunk progress and second-pass count. The debug overlay (Phase 13 work, exists) needs no changes — it reads evidence that now actually exists.
- [ ] 9.5 Widget tests for the runtime card and first-run dialog states.
- [ ] Exit gate: a fresh profile can go from zero → downloaded runtime+model → VSS analysis through UI alone (manually verified); widget tests pass.

### Phase 10 — Real-model validation on RTX hardware (gates production default)

These tasks require a machine with an NVIDIA GPU (the dev machine: see `docs/dev-machine-setup.md`) and the downloaded artifacts. Build a small driver, not CI tests:

- [ ] 10.1 Add `scripts/vss_validation_runner.dart` (Dart CLI, run with `dart run`): takes a directory of labeled validation clips + a manifest JSON conforming to `EvaluationDataset` (`lib/services/detection/evaluation_dataset.dart`), runs the real pipeline (real llama-server, real model) per profile (VLM-only / VLM+aux / VLM+grounding / legacy-only), and feeds results to the existing `EvaluationRunner`, writing the comparison report JSON to `docs/implement/validation-reports/<date>-rtx-validation.json`. Record peak VRAM (poll `nvidia-smi --query-gpu=memory.used --format=csv,noheader` during the run), p50/p95 chunk latency, schema-failure rate, crash count — the fields `LocalRuntimeManager`'s RTX validation record requires.
- [ ] 10.2 **Validation clip set is a data dependency the user must supply** (cannot be committed: contains unsafe content). Required composition is already documented in `docs/implement/family-safety-evaluation-dataset.md` — follow it; minimum ~10 clips/category + safe controls. The runner must work with whatever directory the user points it at.
- [ ] 10.3 After a passing run: set `fitsRtx5070Validated: true` on the validated bundle(s), record the `LocalRuntimeManager` validation record, set the bundle production-selectable, and make `qwen3_vl_8b_instruct_gguf_q4km` the default VLM bundle in `AnalysisSettings.defaults()`.
- [ ] 10.4 Performance expectation to verify (not assume): ~8 s chunks → ~450 chunks/hour of video; Qwen3-VL-8B Q4_K_M on RTX 5070 ≈ 3–6 s/chunk (≈ 3K-token prefill + ≤512-token decode) → 25–45 min per video-hour first pass. If measured p95 exceeds 8 s/chunk, reduce first-pass frames to 6 and/or long side to 640 and re-measure before changing architecture.
- [ ] 10.5 Exit gates (from the original plan §15, unchanged): explicit nudity recall ≥ 0.97, gore/blood ≥ 0.95, high-severity violence ≥ 0.93 on the validation set; VSS beats legacy recall in every category without unacceptable safe-control false positives; immodesty optimizes review-recall, not auto-enforcement.

### Phase 11 — Rollout and documentation

- [ ] 11.1 Rollout flag stays `default` (already is); after Phase 10 passes, the "directly runnable" check makes VSS actually execute for new analyses. `enforce` mode remains opt-in until a stability window passes (existing `LegacyDeprecationReadinessChecker` 30-day gate governs legacy deprecation).
- [ ] 11.2 Update `docs/architecture.md`, `docs/TECHNICAL_REFERENCE.md`, and `README.md`: VSS pipeline architecture diagram (§3 above), llama.cpp runtime, model bundles, disk/VRAM requirements.
- [ ] 11.3 Mark the old checklist (`vss-family-safety-detection-implementation-checklist.md`) header with: "Phases 6/18 runtime-integration items superseded by `vss-family-safety-v2-local-vlm-execution-plan.md`".
- [ ] 11.4 Append the per-phase completion notes to THIS file as phases land (same convention the old checklist used).

---

## 5. Deferred / explicitly out of scope for v2

- **TransNetV2 shot detection** (MIT, tiny 100×48×27 input, F1 ≈ 0.96 vs FFmpeg-filter heuristics; https://github.com/soCzech/TransNetV2): better chunk boundaries, but the official artifact is TensorFlow — an ONNX conversion would be community/KidsLens-owned. Defer to v3; the FFmpeg scene filter is adequate for chunk alignment.
- **Cheap frame-gate upgrade** (`Marqo/nsfw-image-detection-384`, Apache 2.0, 5.6M params, claims 98.6% — https://huggingface.co/Marqo/nsfw-image-detection-384): candidate replacement for the legacy NSFW classifier in `fast_preview`; requires ONNX conversion validation. Defer to v3.
- **Dedicated grounding models** (Florence-2 MIT / Grounding DINO Apache 2.0): only if Phase 10 shows Qwen3-VL native grounding is insufficient for region blur quality.
- **ONNX Runtime GenAI + Phi-4-multimodal** DirectML path: contingency only (see §2.1).
- **SQLite evidence store / graph edges**: JSON remains sufficient until measured otherwise (original Phase 4 decision stands).
- **Video-segment input mode** (`VlmInputMode.videoSegment`): llama-server has no video-container input; frames-as-images is the mode for all v2 bundles.
- **KidsLens-owned quantization pipeline** (for Gemma 4 / Cosmos-Reason2 / Nemotron NVFP4): needed only when a non-Qwen model wins on eval; requires deciding the hosting org — open question parked with the project owner, not blocking v2.

## 6. Risk register

| Risk | Mitigation |
|---|---|
| llama.cpp release asset names/flags drift | Pin one tag + sha256s (Phase 2.1); verify `--help` output for flag spellings at implementation time |
| Qwen3-VL grounding returns pixel coords instead of normalized | Dual-convention parser + clamp (Phase 7.1) |
| Schema non-compliance from the model | grammar-backed `json_schema` enforcement + 1 retry + provider-failure → review finding (Phase 3.2) |
| VRAM OOM on 12 GB with other apps running | ctx 8192 retry → Vulkan fallback → clear failure status; never silent CPU (Phase 2.2) |
| 1-hour video ≈ 30–45 min analysis surprises users | ETA display (Phase 5 step 5), `fast_preview` profile, resume-from-checkpoint |
| NudeNet AGPL in an MIT app | do not bundle; disabled by default in commercial/release builds unless legal approves; replacement path via VLM grounding (Phase 7.3) |
| Validation clips unavailable | Phase 10 explicitly blocks production-default flip, not development; everything through Phase 9 is mock-testable |
| Runtime assumptions discovered late | Phase 0.5 llama.cpp + Qwen3-VL smoke spike must pass before Phase 2/3 implementation proceeds |
| Frame extraction dominates runtime | timing instrumentation in Phase 4; switch to per-chunk batch extraction before Phase 5 if extraction exceeds 10-15% wall time |

## 7. Source list (all verified 2026-06-12)

- Code audit: this repo at commit `10fe20c` + working tree.
- llama.cpp multimodal/server/releases: https://github.com/ggml-org/llama.cpp/blob/master/docs/multimodal.md · https://github.com/ggml-org/llama.cpp/blob/master/tools/server/README.md · https://github.com/ggml-org/llama.cpp/releases · Qwen3-VL support PR https://github.com/ggml-org/llama.cpp/pull/16780
- Models: https://huggingface.co/Qwen/Qwen3-VL-8B-Instruct · https://huggingface.co/Qwen/Qwen3-VL-8B-Instruct-GGUF · https://huggingface.co/Qwen/Qwen3-VL-4B-Instruct-GGUF · https://huggingface.co/Qwen/Qwen3-Embedding-0.6B-GGUF · https://huggingface.co/nvidia/Cosmos-Reason2-8B · https://huggingface.co/nvidia/NVIDIA-Nemotron-Nano-12B-v2-VL-BF16 · https://huggingface.co/microsoft/Phi-4-multimodal-instruct-onnx · Qwen3-VL tech report https://arxiv.org/abs/2511.21631
- Runtime non-viability: vLLM Windows https://docs.vllm.ai/en/latest/getting_started/installation/gpu/ · TensorRT-LLM Windows deprecation https://nvidia.github.io/TensorRT-LLM/0.19.0/release-notes.html
- NVIDIA VSS parameters: https://docs.nvidia.com/vss/2.3.1/content/architecture.html · https://nvidia-cosmos.github.io/cosmos-cookbook/recipes/inference/reason2/vss/inference.html · https://developer.nvidia.com/blog/build-a-video-search-and-summarization-agent-with-nvidia-ai-blueprint/
- Taxonomy references: https://docs.aws.amazon.com/rekognition/latest/dg/moderation-api.html · https://sightengine.com/docs/image-video-moderation-classes-and-concepts · https://docs.thehive.ai/docs/visual-content-moderation
- NudeNet license + accuracy: https://github.com/notAI-tech/NudeNet · https://arxiv.org/pdf/2506.02761
