# KidsLens Revamp — Implementation Checklist

**Companion to:** [revamp-plan.md](revamp-plan.md). Read the plan first; this file assumes its decisions (D1–D14) and appendices.

**How to work this checklist**
- Execute phases in order. Within a phase, tasks are ordered by dependency.
- A task is done only when: code compiles, `dart format` + `flutter analyze` are clean, `dart run build_runner build --delete-conflicting-outputs` produces no uncommitted diff, its listed tests pass, and the box is checked with a commit reference.
- A phase is done only when its **Exit criteria** all hold in CI.
- Never hand-edit `*.g.dart` / `*.freezed.dart` — edit sources and regenerate.
- Tasks marked **HUMAN-GATED** require the project owner (hardware, dataset curation, or judgment calls) — do not fake or skip their outputs.
- When a change touches the taxonomy/actions/enforcement (Appendix A) or adds a model bundle, produce the record from Appendix D/E in the PR description.
- Line references were verified 2026-07-13; if the code has moved, follow the task's intent and note the divergence in the commit message.

---

## Phase 0 — Guardrails & CI

- [x] **0.1 Create GitHub Actions workflow** `.github/workflows/ci.yml`, `windows-latest` (current commit):
  1. `flutter pub get`
  2. `dart format --output=none --set-exit-if-changed .` (exclude `**/*.g.dart`, `**/*.freezed.dart` if needed via `dart format` on `lib test integration_test scripts` source globs)
  3. `dart run build_runner build --delete-conflicting-outputs` then `git diff --exit-code` (generated code must be committed and current)
  4. `flutter analyze --fatal-infos`
  5. `flutter test --coverage`
  6. Coverage floor check (task 0.2). Cache pub + build_runner outputs.
- [ ] **0.2 Coverage ratchet**: add `scripts/check_coverage.dart` — parses `coverage/lcov.info`, fails if line coverage < floor stored in `coverage_floor.txt`. Seed the floor with the current measured value. Raising the floor accompanies each later phase.
- [ ] **0.3 Repo hygiene**: delete `flutter.log`, `rebuild_vs2026.log`, empty dirs `native/sherpa_onnx/`, `native/vibevoice/`; add `*.log`, `coverage/` to `.gitignore`. Verify `build/` is ignored.
- [ ] **0.4 Verify agent tooling** (added with this plan): `CLAUDE.md` at repo root, `.claude/settings.json` hooks (generated-file guard + dart format), `.claude/skills/quality-gates/`, `.claude/skills/implement-next/`. Adjust hook commands if they misbehave on this machine.
- [ ] **0.5 Baseline green**: run the full CI locally once (`scripts/` equivalents) and fix any pre-existing analyze/test failures so Phase 1 starts from green (known: some ONNX API-version test failures may exist — if they block, note them; they are deleted in Phase 2).

**Exit criteria:** CI runs on push/PR and is green on `main`; coverage floor enforced; repo has no stray logs/empty native dirs.

---

## Phase 1 — Export correctness (safety-critical bug fixes)

> Do this before the big refactors: exported videos currently still contain "cut" scenes, and manual region blurs export as full-frame blur.

- [ ] **1.1 Introduce `ExportPlan` compiler** — new `lib/services/export/export_plan.dart`:
  - Input: source media info (duration, fps, resolution from ffprobe), `List<EditAction>`, subtitle options, format/quality.
  - Normalizes edit actions → `Modification`s **without losing data** (regions, keyframes) and computes `keptIntervals` (source-time intervals surviving cuts, merged/sorted, invariant-checked: non-overlapping, within duration).
  - Output: an FFmpeg argument list + filtergraph string (or `-filter_complex_script` file when > 6000 chars — reuse existing spill logic in `export_service.dart`).
- [ ] **1.2 Implement real cuts (trim/concat)** in `lib/services/export_service.dart`:
  - Order of operations in the graph: (a) apply all time-based visual filters on `[0:v]` with `enable='between(t,start,end)'` in **source** time; (b) for each kept interval `i`: `trim=start:end,setpts=PTS-STARTPTS` → `[vI]`, same with `atrim/asetpts` → `[aI]`; (c) `concat=n=K:v=1:a=1`. Audio filters (mute volume / beep mix) also applied pre-trim in source time.
  - Delete the `VideoSkip() => ''` dead mapping; `EditActionType.cut` now feeds `keptIntervals` instead of a no-op filter.
  - Handle edge cases: cut at 0/at end, adjacent cuts, cut-everything (error with message), audio-only export with cuts, subtitle burn-in applied post-concat with remapped times (shift subtitle timestamps by cumulative cut offsets — implement `SubtitleTimeRemapper`).
- [ ] **1.3 Fix region loss in the dialog**: `lib/presentation/widgets/dialogs/export_dialog.dart` `_actionToModification` — when `action.boundingBox != null`, map `EditActionType.blur` → `Modification.videoRegionBlur` (and pixelate/blackbox variants once distinct `EditActionType`s exist — see 5.2); only fall back to full-frame when no region exists.
- [ ] **1.4 Unify export enums**: single `ExportFormat`/`ExportQuality` in `lib/data/models/export_options.dart`; delete the duplicate pair (settings screen vs export dialog); migrate `SettingsKeys` values; update both screens.
- [ ] **1.5 Tests**:
  - Unit: `test/services/export/export_plan_test.dart` — kept-interval math (all edge cases in 1.2), golden filtergraph strings for cut-only, blur+cut, region-blur, beep+cut, subtitle remap.
  - Integration: `test/integration/export_cut_integration_test.dart` — synthesize a 10 s test clip with FFmpeg (`testsrc2` + `sine`), apply a 2 s cut + a region blur, run the real export, assert via ffprobe: output duration ≈ 8 s, streams intact; assert region blur ≠ full-frame by sampling pixel differences of extracted frames inside vs outside the region.
  - Update `test/integration/export_service_test.dart`, `test/services/export_region_*_test.dart` for the new compiler.

**Exit criteria:** exporting a project with cuts produces a shorter file; a drawn region blur exports as a region blur; CI green; coverage floor raised to include the new module.

---

## Phase 2 — Legacy pipeline removal (Decision D1)

> Work top-down: first make VSS/availability not need legacy (2.1–2.4), then delete (2.5–2.8), then sweep (2.9–2.12). Keep commits small; run `flutter analyze` after each step.

### 2.A Redesign the seams

- [ ] **2.1 Availability model**: new `lib/services/detection/detection_availability.dart` — `DetectionAvailability { ready, setupRequired(missing: runtime|bundle|gpuBackend), degradedAudioOnly(reason) }` computed from `LocalRuntimeManager` + bundle install state. Replace `DetectionPipelineRolloutConfig/State/Decision` and `resolveRollout` in `lib/services/detection/detection_pipeline_registry.dart` with `resolvePipeline(settings) → DetectionPipeline` that throws typed `PipelineUnavailableException(availability)` — **no fallback pipeline id anywhere**. Keep the JSONL failure-classification telemetry (schema/gpu/modelLoad/crash) from `detection_pipeline_rollout.dart`, relocated to `detection_failure_telemetry.dart`; delete the rest of the rollout state machine and `DetectionPipelineShadowComparisonRunner`.
- [ ] **2.2 Implement `audio_only` for real**: new `lib/services/detection/audio_only_pipeline.dart` implementing `DetectionPipeline` using only `AnalysisStageHost.probeMedia/transcribeAudio/detectProfanity` + existing profanity→Detection building (Phase 4 upgrades this stage in place). Set `isImplemented: true` in `detection_pipeline_profile.dart`. Delete the `fast_preview` profile.
- [ ] **2.3 VSS startup failure behavior**: in `lib/services/detection/vss_family_safety_pipeline.dart` (~lines 147–180) replace `yield* stageHost.runLegacyAnalysis(request)` with: emit a structured failure progress event + rethrow `VssPipelineStartupException`; `AnalysisService` catches it, records telemetry, and surfaces `DetectionAvailability` to the UI (banner + "Fix setup" CTA + offer to run audio-only). Remove `enableLegacyAuxiliarySignals`, `_visualAuxiliaryEvidence`, and the 7-vs-6 step arithmetic.
- [ ] **2.4 First-run flow without legacy**: `lib/presentation/widgets/dialogs/vss_first_run_dialog.dart` — remove `VssFirstRunAction.useLegacy`; actions become Download / Run audio-only / Cancel. Update `editor_screen._ensureVssFirstRunReady()` (~line 949) and its `useLegacy` branch (~989–993). On unsupported GPU (no CUDA/Vulkan), the dialog explains and offers audio-only.

### 2.B Excise legacy code

- [ ] **2.5 `AnalysisService` excision** (`lib/services/analysis_service.dart`): delete `_runLegacyAnalysis`, `runLegacyAnalysis`, `runVisualAuxiliarySignals`, `_runVisualAnalysis`, `_resolveVisualContext`, `_VisualContext`, `_VisualOutput`, `_VisualProgressUpdate`, `_buildVisualDetectionsFromFrames`, `_buildDetectorRegionsBatch`, `_buildModestyRegionsForFrame`, `_normalizeLegacyModelId`, `_resolveClassifierModelId/_resolveDetectorModelId/_resolveParserModelId/_resolveGenderModelId`, legacy model-resolution loops, the `nsfwOnnx` ctor param/field, `LegacyNsfwPipelineAdapter` registration, and legacy imports. Keep audio/transcription/profanity stages, timeline building, telemetry. Prune `runLegacyAnalysis`/`runVisualAuxiliarySignals` (+ `AnalysisVisualAuxiliaryResult/ProgressUpdate`) from `lib/services/detection/analysis_stage_host.dart`.
- [ ] **2.6 Delete legacy-only files** (each with its imports; run analyzer after each batch):
  - `lib/services/detection/legacy_nsfw_pipeline_adapter.dart`, `lib/services/detection/legacy_deprecation_readiness.dart`
  - `lib/services/nsfw_onnx_service.dart`, `lib/services/nsfw_model_adapter.dart`, `lib/services/nsfw_region_model_manifest.dart`, `lib/services/modesty_analysis_service.dart`, `lib/services/region_temporal_aggregator.dart`, `lib/services/clip_tokenizer.dart`, `lib/services/temporal_aggregator.dart` (verify orphan status first: only its provider registration references it)
  - `lib/native/bindings/onnx_bindings.dart`, `lib/native/bindings/onnx_ffi_types.dart`
  - `native/onnxruntime/` (entire dir), `scripts/download_onnxruntime.ps1`
- [ ] **2.7 Evidence & policy prune**:
  - `lib/data/models/evidence_record.dart`: remove `EvidenceType.legacyNsfwScore`, `legacyNudenetRegion`, `modestyParserSignal` + factories. Add **tolerant deserialization** (D10): unknown `EvidenceType` strings parse to a skipped/ignored record, with a unit test reading a fixture containing legacy evidence JSON.
  - `lib/services/detection/policy_engine.dart`: remove legacy evidence cases (~80–89) and the VLM↔legacy agreement logic; `needsReview` now derives from category policy + confidence bands + VLM `uncertainty`. Keep `PolicyFindingOrigin`/provenance plumbing. Update `PolicyEngineOptions.vssDefault()`.
  - `lib/services/detection/evidence_replay_service.dart` (~77, 87–88, 191, 255–256) and `lib/services/detection/local_search_index.dart` (~577–581): remove legacy cases; replay skips unknown types.
  - `lib/services/detection/grounding_provider.dart`: delete `LegacyNudenetGroundingProvider`, `ModestyParserGroundingProvider`, `_LegacyRegionGroundingProvider`, `GroundingSourceKind.legacyNudenet/modestyParser`, `GroundingRequest.legacyNudenetRegionsByFrame/modestyParserRegionsByFrame`. Keep `VlmNativeGroundingProvider` (wired in Phase 3). Delete `LocateAnythingGroundingProvider` + evaluation record (blocked license, dead code).
  - `lib/data/models/model_bundle_manifest.dart` (~652): rewrite the "validate against NudeNet auxiliary regions" note to reference box-IoU vs dataset ground truth.
- [ ] **2.8 Settings, models, registry cleanup**:
  - `lib/data/models/analysis_settings.dart`: remove `ModelConfig.nsfwModelId/parserModelId/genderModelId/onnxExecutionProvider`; `supportedPipelineIds` = {vss_family_safety_v1, audio_only}. `lib/data/models/analysis_settings_migration.dart`: migrate persisted settings (strip removed keys; `legacy_nsfw_region_v8`/`fast_preview` → `vss_family_safety_v1`).
  - `lib/data/models/gpu_config.dart`: remove `onnxExecutionProvider(s)` accessors only (whisper/ASR GPU config is shared — keep the rest).
  - `lib/services/huggingface_model_registry.dart`: remove `getNudeNetModels/getParserModels/getGenderHelperModels/getNsfwClassifierModels`, nudenet catalog entries (~252–280, 498–511), alias map entries; fix `getModelById` switch. `lib/services/model_manager_service.dart`: remove nudenet aliases (~122–123) + NSFW/parser bookkeeping. `lib/data/models/huggingface_model.dart`: remove `parser`/`genderHelper`/nsfw-classifier enum values if now unused.
  - `lib/data/models/content_category_defaults.dart`: remove NudeNet/modesty model contributions (~12–16, 188–189, 240–413). `lib/data/models/visual_content_category.dart` + `visual_content_defaults.dart`: remove `usesNudeNet`, `CategoryDetectionSource.nudeNet/clip`, `detectionLabels` if unused after sweep — verify no VSS consumer first; if `VisualContentCategory` becomes redundant with `FamilySafetyPolicyCategory`, delete it and migrate consumers.
  - `lib/data/models/frame_analysis_result.dart`: **shared** — keep `FrameAnalysisResult`/`DetectedRegion` types (evidence replay, export, checkpoints use them); prune `NsfwResult`/`clipScores`/NudeNet-flavored fields only where no longer referenced.
  - `lib/state/providers/service_providers.dart`: remove `onnxBindings`, `nsfwOnnxService`, `temporalAggregatorService` providers + `nsfwOnnx:` arg. `settings_provider.dart` / `model_provider.dart` / `analysis_settings_provider.dart`: remove nsfw/parser/gender setters. Regenerate all `.g.dart`.
  - `lib/jobs/analysis_job.dart` + `lib/jobs/checkpoint_manager.dart` + `lib/data/models/analysis_checkpoint.dart`: bump `pipelineVersion` 8 → 9; old visual checkpoints invalidate gracefully (fresh analysis, no crash); update the version comment.
- [ ] **2.9 UI sweep**:
  - `models_management_tab.dart`: remove "Nudity Detector" section (~178–208), `_isNudityModelSelected/_selectNudityModel`, NSFW-classifier/parser/gender sections (tab now covers ASR models only — retitle accordingly).
  - `local_model_bundles_tab.dart`: pipeline dropdown (~450–468) now lists VSS + audio-only; remove `isLegacy` branch in `_pipelineLabel` (~871–878).
  - `editor_screen.dart`: remove `_nudenetDebugModeEnabled` (58, 71, 185, 267, 348–351, 1072–1078). `preview_panel.dart`: remove NudeNet debug overlay params/rendering (`_nudenetRegionColor`, `_nudenetShortLabel`). `timeline_panel.dart`: remove "NudeNet" debug track (448, 1021) and NSFW-score/modesty debug tracks.
- [ ] **2.10 Build sweep**: `windows/CMakeLists.txt` — remove ONNX Runtime download/verify block (~21–49) and DLL install rules (~206–213). Whisper block stays. Verify `flutter build windows` succeeds and the installed app contains no `onnxruntime*.dll`.
- [ ] **2.11 Test sweep**: delete legacy tests (`test/services/detection/legacy_deprecation_readiness_test.dart`, `test/native/onnx_*_test.dart` ×3, `test/services/nms_test.dart`, `test/services/clip_tokenizer_test.dart`, `test/services/region_temporal_aggregator_test.dart`, `test/services/temporal_aggregator_test.dart`, `test/integration/visual_analysis_e2e_test.dart`). Edit mixed tests per the inventory: `analysis_service_pipeline_routing_test.dart` (now: availability routing + audio-only + VSS-unavailable error surface), `detection_pipeline_registry_test.dart`, `detection_pipeline_rollout_test.dart` (→ telemetry-only), `policy_engine_test.dart` (drop `_legacyNsfwRecord`/modesty fixtures; keep golden findings), `grounding_provider_test.dart`, `evidence_store_replay_test.dart` (+ new tolerant-deserialization fixture test), `evidence_record_test.dart`, `local_search_index_test.dart`, `huggingface_model_registry_test.dart`, `model_manager_service_test.dart`, `content_category_defaults_test.dart`, `visual_content_category_test.dart`, `detected_region_test.dart`, `analysis_settings_test.dart` + `_migration_test.dart` (new migration cases), provider tests, `local_model_bundles_tab_test.dart` (drop `legacyNsfwRegionV8` assertion, line ~123), `vss_first_run_dialog_test.dart` (no useLegacy).
- [ ] **2.12 Docs & metadata sweep**: remove every legacy mention from `README.md` (features table, "Legacy Visual Detection Option" bullet, `legacy_nsfw_region_v8` fallback paragraph), `docs/architecture.md` (fallback routing diagram → availability model), `docs/TECHNICAL_REFERENCE.md`, `docs/api-reference.md`, `docs/native-integration.md` (ONNX FFI sections), `docs/getting-started.md`, `docs/deployment.md`, `docs/testing.md` if touched. Grep gate: `grep -riE "nudenet|legacy_nsfw|onnxruntime|nsfw_onnx|modesty_analysis|onnx_bindings" lib test docs windows scripts README.md` returns **zero hits** (allow historical mentions only in `docs/implement/revamp-*.md`).

**Exit criteria:** grep gate passes; `flutter build windows` ships no ONNX DLLs; analysis on a machine without the VSS runtime shows the availability banner and offers audio-only (no silent behavior); old evidence JSON loads without crash; CI green.

---

## Phase 3 — Visual detection completion

- [ ] **3.1 Capture the VLM response**: `lib/services/detection/vlm_provider.dart` `_buildResponse` (~747–780) — parse and persist `groundedRegions` as `EvidenceRecord.groundedRegion` (linked to finding ids via `regionIds`), include them in the returned `VlmSegmentResponse`. `vss_family_safety_pipeline.dart` (~327) — capture the returned response instead of discarding it; thread regions into the evidence store and policy stage. Apply `NormalizedGroundingBox` pixel→normalized repair + clamp to [0,1]; drop degenerate boxes (area < 0.5% or > 98% of frame → treat as scene-level).
- [ ] **3.2 Grounding second pass**: wire `VlmNativeGroundingProvider` (`grounding_provider.dart`) into the pipeline: for findings in region-preferring categories (Appendix A: regionWhenAvailable) whose `groundingStatus != grounded`, send `FamilySafetyPromptTemplates.grounding` for the finding's top-K frames (K=4) to the same server; parse/repair boxes; persist as grounded-region evidence; update finding `groundingStatus`. Budget: grounding pass total ≤ 25% of policy-pass wall time (measure + log).
- [ ] **3.3 Region tracks**: new `lib/services/detection/region_track_builder.dart` — greedy IoU ≥ 0.3 association of same-category boxes across consecutive sampled frames within a finding window → `RegionTrack { regionId, category, keyframes: [(tMs, box)] }`; single-frame boxes become 1-keyframe tracks padded ±350 ms. `PolicyDetectionBuilder` (`temporal_fusion.dart`) populates `FusedPolicySegment.boundingBoxes` and writes `Detection.metadata.boundingBoxKeyframes` (JSON) + a union `boundingBox` for simple consumers + `boundingBoxKey`.
- [ ] **3.4 Refinement pass** (new `AnalysisSettings.refinementPassEnabled`, default true): after the first policy pass, chunks containing findings with severity ≥ high or `uncertainty` above threshold are re-planned into sub-chunks at 2× frame density and re-analyzed; merged findings get tightened start/end (temporal-IoU improvement measured by the validation runner). Checkpoint-aware (resume skips completed refinements).
- [ ] **3.5 Model artifact SHA-256 pinning**: record official checksums for all `ModelBundleArtifactFile` entries in `lib/data/models/model_bundle_manifest.dart` (Qwen3-VL 8B Q4_K_M + mmproj, 4B variant, Qwen3-Embedding 0.6B). **HUMAN-GATED** if hashes must be fetched/verified against the official HF repos on a trusted connection. Downloader verifies on completion (reuse runtime-binary verification path); mismatch ⇒ delete + actionable error.
- [ ] **3.6 Approval gating rework (D3)**: `approvalStatus: evaluationOnly` bundles become selectable; add `ValidationBadge` UI state (validated / not-yet-validated) sourced from recorded validation reports; persistent warning banner in analysis settings + first-run dialog until a passing report exists for the bundle+hardware class. `LocalRuntimeManager.validateRtx5070Fit` and `rtxValidationGate` unchanged as release gate.
- [ ] **3.7 Policy engine single-provider tuning**: re-derive `needsReview` bands (Appendix A) now that agreement signals are gone; unit-test the matrix category × severity × confidence × uncertainty → (action, needsReview). Update the golden findings test.
- [ ] **3.8 Frame extraction budget**: instrument per-chunk extraction wall time; if > 10–15% of total, switch `extractChunkJpegFrames` (`frame_sampling_service.dart` ~368) to one batched FFmpeg invocation per chunk (single seek + fps/select filter) behind the same API. Keep the measurement in telemetry either way.
- [ ] **3.9 Tests**: pipeline e2e with `MockVlmProvider` returning grounded regions → assert detections carry keyframed boxes; grounding-pass unit tests (ungrounded finding triggers exactly one grounding call; grounded ones don't); region-track builder (association, gaps, degenerate boxes); refinement pass (boundary tightening on synthetic findings, checkpoint resume); checksum verification (tamper test); availability badge widget test.

**Exit criteria:** with the mock provider, an analyzed clip produces detections with region keyframes end-to-end; grounding/refinement measurable in telemetry; all bundle artifacts checksum-verified; CI green; coverage floor raised.

---

## Phase 4 — Speech safety modernization (Decisions D11–D14)

> Foundation first (4.1–4.5: catalog, timestamps, language, MMS removal, silence skip), then the two-tier intelligence (4.6–4.7), then UI/docs (4.8–4.9). Audit facts referenced below were verified 2026-07-13.

### 4.A Foundation

- [ ] **4.1 Curate the ASR model catalog (D12)** — `lib/services/huggingface_model_registry.dart` `_asrModels` (lines 20–174):
  - Keep exactly two entries: `whisper-large-v3-turbo` (`ggml-large-v3-turbo.bin`, 809M, ~1638 MB — badge "Recommended") and `whisper-small` (`ggml-small.bin`, 244M, 466 MB — badge "Lightweight / CPU"). Delete the other eight (`whisper-tiny`, `whisper-tiny.en`, `whisper-base`, `whisper-base.en`, `whisper-small.en`, `whisper-medium`, `whisper-medium.en`, `whisper-large-v3`). Both kept entries stay multilingual (99-language `_multilingualLanguages` list). Remove now-unused `getEnglishOnlyAsrModels()` (registry lines ~581–585) and `isEnglishOnly` usages if orphaned.
  - Add a `sha256` field to `HuggingFaceModel` (`lib/data/models/huggingface_model.dart`) and populate it for both files from the official `ggerganov/whisper.cpp` HF repo (**HUMAN-GATED**: fetch hashes over a trusted connection, or compute from freshly downloaded artifacts and cross-check against the repo's LFS metadata). `ModelManagerService` verifies after download; mismatch ⇒ delete + actionable error (reuse the runtime-binary verification pattern per D9).
  - **Unify default selection to ONE path**: `ModelConfig.defaults()` (`analysis_settings.dart` ~34–36) → `asrModelId: 'whisper-large-v3-turbo'`; delete the accuracy-heuristic third path in `AsrService._selectModel()` (`asr_service.dart` ~644–664) — replace with: use configured id if downloaded, else `whisper-small` if downloaded, else placeholder mode; the registry "recommended badge" path (`getRecommendedModel`, ~536–542) must agree with the config default.
  - Migration in `analysis_settings_migration.dart`: `whisper-tiny|tiny.en|base|base.en|small.en → whisper-small`; `whisper-medium|medium.en|large-v3 → whisper-large-v3-turbo`. Already-downloaded removed models: offer cleanup in the models tab (list as "deprecated — delete").
  - Update `adaptiveBeamSize` (`asr_service.dart` ~823–831) for the two-model world (small→4, turbo→5).
  - Tests: `huggingface_model_registry_test.dart` (exactly 2 ASR entries, both multilingual, checksums present), `model_manager_service_test.dart` (verification, tamper), `analysis_settings_migration_test.dart` (all 8 mappings), models tab widget test.
- [ ] **4.2 True word timestamps (D14)** — aggregate whisper BPE tokens into words **in Dart**:
  - Facts: the native wrapper returns per-TOKEN `KLWhisperWord`s (`whisper_wrapper.cpp:361-382` loops `whisper_full_n_tokens`); config already sets `wordTimestamps=true, splitOnWord=true` everywhere.
  - Implement `aggregateTokensToWords(List<TranscriptWord> tokens) → List<TranscriptWord>` in a new `lib/services/asr/token_word_aggregator.dart`: merge a token into the current word when its text does **not** begin with whitespace (whisper emits leading-space tokens at word starts); standalone punctuation tokens attach to the previous word; word start = first token `startTime`, end = last token `endTime`, confidence = min of token probabilities. **Unspaced-script fallback**: if a segment's text contains no ASCII spaces and its language ∈ {zh, ja, th, ko(partial)}, keep per-token granularity (each token = one "word").
  - Call it from both conversion sites: `transcription_isolate.dart` `_extractSegments` (~812–850) and `whisper_bindings.dart` `_convertNativeResult`. Rename Dart-side raw structures to `tokens` for honesty (`WhisperTokenNative`); `TranscriptWord` remains the public word type.
  - Wire the existing-but-ignored `ModelConfig.wordLevelTimestamps` toggle: it now controls whether word arrays are retained on segments (native request stays always-on; it's cheap).
  - Tests (`test/services/asr/token_word_aggregator_test.dart`): "fu"+"ck" merges to "fuck" with span = union; " hello"+" world" → two words; punctuation attach; CJK fallback; empty/whitespace tokens; confidence propagation.
- [ ] **4.3 Real language detection** — small C++ change + plumbing:
  - `native/whisper/whisper_wrapper.cpp` `create_result_from_context` (~341–343): when the requested language was null/auto, call `whisper_full_lang_id(ctx)` → `whisper_lang_str(id)` and set `detected_language` from it; populate `language_probability` from `whisper_lang_auto_detect` probabilities when available, else leave 1.0. Header unchanged (`KLWhisperResult` already carries both fields).
  - Dart: `Transcript.language` = detected language (stop defaulting `"en"`); `AsrCacheService` key already includes language — verify auto-detect runs store under the *detected* language so re-runs hit cache; pass detected language downstream to the speech-safety stage (4.6) and `SubtitleTrack`.
  - Rebuild via `flutter build windows`; keep `/W4 /WX` clean.
  - Tests: binding-level integration test tagged to skip when the native lib is absent (existing pattern); Dart unit test that the transcript propagates a non-"en" detected language from a faked native result.
- [ ] **4.4 Remove Meta MMS (D13)**:
  - Delete `lib/native/bindings/mms_bindings.dart`. Remove the `mms` field/param from `AnalysisService` (`analysis_service.dart:113,144`) and delete the entire non-whisper transcription branch (~927–947, the only call site — unreachable since every ASR id starts with `whisper-`). Remove from `service_providers.dart` + regenerate; update `analysis_service_pipeline_routing_test.dart` fixtures.
  - Docs: README — replace "Multi-language Support: … Meta MMS" bullet with "99-language transcription and auto language detection via Whisper"; sweep `docs/architecture.md`, `docs/native-integration.md`, `docs/api-reference.md`.
  - Grep gate: `grep -riE "\bmms\b|mms_bindings|mms_wrapper" lib test docs README.md windows native` → zero hits (excluding revamp docs).
- [ ] **4.5 Silence skipping**:
  - New prepass in `AsrService`: run bundled FFmpeg `-af silencedetect=noise=-35dB:d=2.0 -f null -` on the prepared 16 kHz WAV; parse `silence_start`/`silence_end` from stderr into silent intervals.
  - `transcription_isolate.dart` chunker (~314–340): skip chunks fully inside a silent interval; for partially silent chunks keep as-is (whisper handles them). Report skipped time in progress + telemetry.
  - New `AnalysisSettings.skipSilence` (default true) surfaced in the Performance tab.
  - **Optional stretch (separate commit, revert-friendly):** bump `native/whisper/CMakeLists.txt` FetchContent tag from `v1.7.3` to the latest stable v1.8.x and enable whisper.cpp's built-in Silero VAD; proceed ONLY if the `/WX` build passes and all ASR tests stay green — otherwise stay pinned and rely on the prepass.
  - Tests: silencedetect stderr parser (fixture strings); chunker skip logic over a synthetic silence map (all-silent, no-silent, straddling-boundary cases); integration test with a generated clip containing 5 s of silence (assert fewer chunks transcribed).

### 4.B Two-tier intelligence

- [ ] **4.6 Tier 1 — `LexicalProfanityMatcher`** (rewrite the matching internals of `lib/services/profanity_service.dart`; keep the public service as the orchestrator):
  - **Aho-Corasick automaton** (new `lib/services/speech/aho_corasick.dart`, pure Dart, unit-tested standalone) built per language over normalized wordlist entries + custom words. Match over the normalized word stream joined with single spaces → **multi-word phrase support** (wordlist lines containing spaces become phrases; today they silently can't match). Candidate spans map back to word indices → `TranscriptWord` time spans.
  - **Language isolation**: load only the transcript's detected language (from 4.3) plus `ProfanityConfig.extraLanguages` (new field, default `['en']`); stop iterating all 29 wordlists per word (fixes cross-language homograph FPs and the O(N·M) scan in `_matchWord` lines 133–194).
  - Keep leetspeak table (`_normalizeLeetspeak` ~199–216) as a normalization pre-pass. **Phonetic tier**: only for Latin-script languages; precompute Double Metaphone code→words buckets at wordlist load; Levenshtein runs only within the matching bucket (cap 32 candidates) — never over the full list.
  - **Honor the config flags** that are currently ignored: `detectLeetspeak`, `detectPhonetic`, `detectFuzzy`, `minWordLength`; delete dead `wordlistIds` and `useContextAnalysis`/`detectObfuscated` from `ProfanityConfig` (`analysis_settings.dart` ~67–95) with migration. Fix custom/excluded set accumulation: `configure()` resets `_customWords`/`_excludedWords` each run.
  - Output type change: emits `ProfanityCandidate { span, surface, matchedEntry, matchType, lexicalConfidence, language }` — **candidates, not final matches**. `ProfanityMatch` remains as the post-verdict record (add `verdictSource: lexical|llm` and populate `severity`/`category` from the verdict instead of the hardcoded 3/null).
  - Tests: phrase match ("son of a …"), homograph FP eliminated by language isolation (fixture: benign English word present in another language's list), all four flags on/off, bucketed fuzzy still catches 1-edit obfuscations, reset-on-configure, performance smoke (10k-word transcript, 3 languages loaded, < 1 s).
- [ ] **4.7 Tier 2 — `SpeechPolicyAnalyzer`** (new `lib/services/detection/speech_policy_analyzer.dart`):
  - **Shared chat client refactor**: extract `OpenAiCompatChatClient` from `OpenAiCompatVlmProvider` (`vlm_provider.dart`) — owns HTTP to `127.0.0.1:<port>/v1/chat/completions`, `response_format: json_schema` with `json_object` fallback, temperature 0, markdown/JSON repair + one-shot repair retry. `OpenAiCompatVlmProvider` and `SpeechPolicyAnalyzer` both consume it (VLM adds image parts; speech is text-only).
  - **Windowing**: transcript sliced into ~45 s windows with 5 s overlap, each rendered as numbered lines `[mm:ss.mmm] text` with Tier-1 candidates marked inline (`⟦candidate #id: "word"⟧`). One request per window; dedupe findings in overlap zones by span-IoU > 0.5 (keep higher confidence).
  - **Schema & prompt**: new `SpeechPolicyOutputSchema` + prompt in `family_safety_prompt_templates.dart` (sibling of the visual templates, same constraints: factual, per-category, no age inference, "unclear" over guessing). Output per Appendix B: `candidateVerdicts[]` (confirm/reject + severity 1–5 + category + rationale) and `additionalFindings[]` (quote, startMs, endMs, category ∈ {profanity, sexual_content, suggestive_content, violence, substances}, severity, confidence, rationale). Map `additionalFindings` quotes to word-accurate spans by fuzzy-locating the quote in the window's words; fall back to the window's line span. **No new taxonomy categories — no Policy Review Record needed** (state this in the PR).
  - **Server lease**: acquire the running llama-server via `LlamaServerManager` (same key/lease mechanism as the VLM pipeline; in the VSS pipeline the server is already up — reuse the lease; in `audio_only` with `DetectionAvailability == ready`, start one). When availability ≠ ready: skip the tier, mark the analysis summary "speech intelligence unavailable — lexical matching only (<reason>)" — fail-visible per D2.
  - **Evidence-first integration**: add `EvidenceType.speechPolicyFinding`; persist confirmed verdicts, rejections (explainability: the UI can show why a candidate wasn't flagged), and additional findings as evidence with provenance (model id, window id). `PolicyEngine` maps: confirmed profanity → `PolicyFinding(category: profanity)` with word span padded by new `ProfanityConfig.beepPaddingMs` (default 120); sexual/suggestive/violence/substances speech → scene-level findings with `needsReview: true`; rejected candidates suppress the lexical detection. Lexical-only mode (tier unavailable): candidates with `lexicalConfidence ≥ fuzzyThreshold` become profanity findings directly (current behavior, preserved).
  - Wire into both pipelines: `vss_family_safety_pipeline.dart` audio stage and `audio_only_pipeline.dart` (from 2.2). Instrument wall time; budget ≤ 15% of total analysis (log + telemetry).
  - Tests (mock chat client): verdict parsing incl. repair path; homograph rejection suppresses the beep; additional-finding quote→span mapping (exact, fuzzy, fallback); overlap dedupe; unavailable→lexical-only with visible reason; padding applied; evidence records carry provenance; PolicyEngine mapping matrix for all five speech categories.

### 4.C Surface & docs

- [ ] **4.8 Speech settings & UI**:
  - New "Speech Safety" section in `content_detection_tab.dart` (or a dedicated tab if it crowds): "Speech intelligence (local LLM)" toggle (default on, disabled+explained when availability ≠ ready), beep padding slider (0–500 ms), language override dropdown (default "Auto (detected)"), extra-languages multi-select.
  - **Custom/excluded word editor** (today the fields exist but have no UI): chip-input lists for `ProfanityConfig.customWords`/`excludedWords`, persisted via the settings provider.
  - `thresholds_tab.dart`: keep the fuzzy slider (now labeled "Lexical match threshold"), gated on `enableProfanity`.
  - Detection panel / review queue: profanity detections show matched word + verdict source + rationale; speech scene-findings show the quote + rationale.
  - Widget tests for the new controls + persistence round-trip.
- [ ] **4.9 Docs + coverage**: update `docs/TECHNICAL_REFERENCE.md` (ASR section: 2-model catalog, word aggregation, language detect, silence skip; new speech-safety architecture diagram) and README features ("Context-aware speech safety (local LLM) with word-accurate beeps"). Add labeled transcript fixture suite `test/fixtures/speech/` (synthetic transcripts + expected candidates/verdicts — no real unsafe media, plain text only) exercised by an accuracy regression test. Raise the coverage floor.

**Exit criteria:** catalog has exactly 2 multilingual ASR models with verified checksums and one default path; beeps land on word-accurate padded spans (split-token profanity fixture passes); auto-detected language is real and drives wordlist loading; MMS grep gate passes; LLM tier confirms/rejects candidates and finds non-lexical speech issues end-to-end with the mock client, and degrades visibly to lexical-only; CI green.

---

## Phase 5 — Region UX & remediation

- [ ] **5.1 Boxes on the preview**: `preview_panel.dart` renders the interpolated (linear between keyframes) box for detections active at the playhead — outline + category color (`AppTheme.getDetectionColor`), label chip with category/severity; toggle in the view menu. Selected-detection box is emphasized.
- [ ] **5.2 Distinct region actions**: split `EditActionType.blur` into `blurRegion`, `pixelateRegion`, `blackBoxRegion`, `blurFrame` (migration for saved projects in `project_service.dart`). `_onApplyAction` (`editor_screen.dart`) prefills the action's region track from `Detection.metadata.boundingBoxKeyframes`; `BlurRegionOverlay` edits become keyframe edits at the current playhead time (add/adjust keyframe), with "apply to whole detection" default.
- [ ] **5.3 Keyframed region export**: `ExportPlan` compiles `RegionTrack` keyframes into piecewise-constant per-segment region filter chains (segment per keyframe interval, min segment 250 ms, cap 64 segments/track — log if capped); reuse Phase 1 region chain builder. Integration test: moving box on synthesized clip — sampled frames show blur following the box.
- [ ] **5.4 Before/after toggle**: preview button + shortcut (Shift+B) that bypasses all remediation overlays/audio effects to compare original vs edited at the playhead.
- [ ] **5.5 Tests**: widget tests for overlay interpolation and toggle; mapping tests for action-type migration; export integration test in 5.3.

**Exit criteria:** a nudity-style mock detection shows a tracked box in preview, one click applies a region blur that follows the subject, and the export contains it; CI green.

---

## Phase 6 — Editor UX revamp

- [ ] **6.1 Decompose god widgets** (pure refactor, no behavior change; do first so later tasks land in clean files):
  - `editor_screen.dart` → `editor_shell.dart` (layout + panels), `editor_menu_bar.dart`, `editor_shortcuts.dart` (Intent/Action pattern), `editor_controller.dart` (orchestration now in setState soup).
  - `timeline_panel.dart` → `timeline_view.dart` + `tracks/{video_track,audio_track,detections_track,edits_track,subtitles_track}.dart` + `painters/{ruler,thumbnail_strip,waveform}.dart`.
  - Delete unused alternate sets after verifying zero imports: `lib/presentation/widgets/timeline/*`, `lib/presentation/widgets/player/*`.
  - Guard: existing widget tests still pass unchanged (they pin behavior through the refactor).
- [ ] **6.2 Command-based undo/redo**: `lib/state/commands/` — `EditorCommand { String label; void apply(ProjectNotifier); void revert(ProjectNotifier); }`, `CommandHistory` (undo/redo stacks, coalescing for drags). Migrate every mutation (add/move/resize/delete edit action, detection accept/reject/delete, subtitle ops, marker ops) — including ones that today skip undo (e.g. `addDetection`). Remove `Project` snapshot stacks from `project_provider.dart`. Undo depth 200. Tests: every command round-trips apply→revert to deep-equal state.
- [ ] **6.3 Real waveform**: `lib/services/waveform_service.dart` — one FFmpeg pass to 8 kHz mono PCM, min/max peaks per bucket (~2000 buckets/min), cached under the project dir keyed by media hash; timeline audio track renders real peaks (loading shimmer until ready). Delete `_MiniWaveformPainter` synthetic data. Test: peaks for a generated sine sweep match expected envelope.
- [ ] **6.4 Pro transport & timeline behavior**:
  - fps from probe → frame stepping ←/→ (±1 frame), Shift+←/→ (±1 s); J/K/L shuttle (reverse ×1/×2 if media_kit supports negative rate — otherwise step-based reverse scrub, pause, forward ×1/×2/×4); Space play/pause; Home/End; I/O (exists); **S** split edit-action at playhead; **M** add marker (new `Marker` model on project, rendered on ruler, snap target).
  - Wheel semantics: wheel = horizontal scroll, Ctrl+wheel = zoom at cursor, Shift+wheel = vertical; zoom-to-fit button + `Shift+Z`.
  - Snapping (toggle, `N`): drag/resize of edit actions snaps to playhead, markers, detection edges, other action edges (±5 px threshold).
  - Timecode display `HH:MM:SS:FF` next to the transport; click-to-type seek.
  - Keyboard shortcuts registered via 6.1's Intent/Action layer; shortcut help dialog auto-generated from registrations.
- [ ] **6.5 Review queue revamp** (`detection_review_screen.dart`): ordered queue (severity desc, then time) with filmstrip (3–5 thumbs across the finding), rationale/severity/confidence/region badge + speech quote/verdict source for audio findings, recommended action; keys: A accept(+apply recommended), R reject, ↑↓ navigate, Enter jump-to-timeline; bulk bar: accept/reject all in category; progress indicator (n of m reviewed). Accepting applies the category's default remediation via the command system.
- [ ] **6.6 Autosave + crash recovery**: `Timer.periodic` from settings interval, fires only when dirty; writes `<project>.autosave.json`; on open, newer autosave than saved file ⇒ recovery prompt. Test with fake clock.
- [ ] **6.7 Settings unification**: all reads/writes through `settingsNotifierProvider` (one repository over SharedPreferences); `settings_screen.dart` stops touching SharedPreferences directly; delete duplicated keys/enums (finishes 1.4).
- [ ] **6.8 Layout & polish**: persist panel sizes/visibility per project; restore on open; consistent Material 3 spacing/typography pass over editor + settings; empty states for panels.
- [ ] **6.9 Tests**: widget tests per new track widget (marker drag, snap, split); shortcut → Intent dispatch tests; review-queue keyboard flow; autosave; settings repository round-trip. Raise coverage floor.

**Exit criteria:** editor behaves like a modern NLE for the safety workflow (frame stepping, J/K/L, snapping, markers, real waveform, keyboard review); no file > 800 lines in `lib/presentation/`; CI green.

---

## Phase 7 — User features

- [ ] **7.1 Safety search panel**: dockable panel (left rail tab next to media bin) with query box → `LocalSearchIndex.search` (already hybrid lexical+embedding) → ranked results (time, kind badge, snippet, score); click seeks + highlights on timeline. Indexing status chip (hash-fallback vs embedding server). Provider + widget tests with a seeded index.
- [ ] **7.2 Sensitivity profiles**: `lib/data/models/sensitivity_profile.dart` — `strict` (all categories enforce, low thresholds), `standard` (Appendix A defaults), `custom` (editable). One dropdown in analysis settings + shown in the pre-analysis dialog; maps to per-category thresholds + default actions consumed by `PolicyEngineOptions`. Changing profile after analysis re-runs only the policy stage from stored evidence (no re-inference — expose as "Re-evaluate findings"). Tests: profile → options mapping; re-evaluate uses stored evidence only.
- [ ] **7.3 Batch analysis queue**: extend the job system (`lib/jobs/`) with a `BatchAnalysisJob` queue UI (add files → sequential analysis with per-file progress, failures don't abort the queue); results land as per-file projects/review queues. Tests with fake pipeline.
- [ ] **7.4 Safety report export**: on export, optionally write `<output>.safety-report.html` (+ `.json`): categories found, counts, timestamps, actions taken, reviewer decisions, speech findings with quotes, model/runtime/bundle provenance + checksums, app version. No thumbnails of unsafe content in the report. Golden HTML test with fixed fixture.
- [ ] **7.5 Subtitle sanitization**: confirmed profanity spans (from the Phase 4 verdict flow) censor matched words in generated subtitle tracks and exports (`f***` style, configurable), consistent with beeped audio. Unit tests incl. multi-word phrases and overlapping spans.
- [ ] **7.6 Proxy playback**: new `lib/services/proxy_service.dart` — for sources with height > 1080 (or bitrate > 20 Mbps), background FFmpeg transcode to 960-height H.264 CRF 28 + AAC 128k, stored in the project cache keyed by media hash; runs as a job (cancellable, progress in media bin). `PreviewPanel` swaps to the proxy when ready **preserving position/play state**, with a "Proxy" badge; scrubbing/thumbnails/waveform may source from the proxy; **analysis and export always use the original** (assert in `ExportPlan`). Setting: Auto (default) / Always / Off. Tests: service unit with `FakeProcessRunner` (command shape, cache key, cancellation); provider swap widget test (position preserved).
- [ ] **7.7 Hover scrubbing**: on the video-track filmstrip and media-bin cards — `MouseRegion` maps local x → time; shows the nearest cached `ThumbnailService` frame (LRU cache, 80 ms debounce, no main-player seek): bin cards swap the card image + time tooltip; the filmstrip shows a floating preview above the cursor. Widget tests with fake thumbnail bytes.
- [ ] **7.8 Beep/mute ramps**: replace hard `volume=0:enable=…` with a smooth per-interval envelope, ramp r = 0.05 s: for each remediated interval with midpoint m and half-width h, `factor(t) = clip((|t - m| - (h - r)) / r, 0, 1)`; final volume expression = product of factors, applied with `volume=volume='<expr>':eval=frame` (pre-trim, source time — composes with Phase 1 cuts). Beep tone gain uses the complementary envelope `1 - factor(t)` on the `aevalsrc` branch before `amix`. Live preview approximates with a fast volume ramp in `preview_panel`/`BeepAudioService`. Tests: golden filtergraph; integration test asserting RMS ramps (extract 20 ms windows around a boundary via FFmpeg `astats`, assert monotonic level change rather than a step).
- [ ] **7.9 Export presets**: `ExportPreset` freezed model { name, format, quality, subtitleMode, includeSafetyReport }; persisted list in the settings repository; export dialog: preset dropdown + "Save current as preset" + manage (rename/delete); ships with built-ins "Family archive (H.265 high)" and "Quick share (H.264 medium)". Tests: repo round-trip; dialog widget test.
- [ ] **7.10 Detection heatmap**: ~8 px painter strip attached to the timeline ruler; buckets of 4 px; bucket weight = Σ severity × confidence of overlapping active detections; color = dominant category's `getDetectionColor` with alpha ∝ normalized weight; click seeks bucket center; repaints on detection changes (listen to project provider). Golden test with a fixed detection fixture.
- [ ] **7.11 Range re-analysis**: timeline selection context menu "Re-analyze range (high density)": invalidates chunk checkpoints intersecting [in, out], re-plans that range into sub-chunks at 2× frame density (reuse the Phase 3.4 refinement machinery), re-runs VLM + speech tiers for the range, then merges evidence — findings fully inside the range are replaced, straddling findings re-fused; progress toast + cancellable job. Tests: checkpoint invalidation bounds; merge semantics (inside replaced / outside untouched / straddling re-fused) with the mock provider.

**Exit criteria:** all eleven features usable end-to-end with tests; CI green; coverage floor raised.

---

## Phase 8 — Test completion & hardening

- [ ] **8.1 Process-boundary fakes**: `test/support/fake_process_runner.dart` injected into `FFmpegBindings`, `ThumbnailService`, `WaveformService`, `ProxyService`, `LlamaServerManager` (constructor-injected `ProcessRunner` abstraction — small refactor). Contract tests for ffprobe JSON parsing, progress parsing, silencedetect parsing, server health polling, stale-ledger cleanup.
- [ ] **8.2 `lib/jobs/` suite**: `job_system`, `analysis_job`, `export_job`, `checkpoint_manager`, `cancellation_token`, `BatchAnalysisJob` — happy path, cancel mid-stage, checkpoint resume, failure propagation.
- [ ] **8.3 Provider suite**: `media_provider`, `playback_provider`, `project_provider` (post-command refactor), `derived_providers`, `service_providers` wiring smoke test.
- [ ] **8.4 Widget/golden pass**: remaining editor widgets (preview overlays, transport, export dialog, availability banner, first-run dialog states, speech settings); add golden tests for the timeline tracks, heatmap, and review queue (deterministic fixtures, `matchesGoldenFile`).
- [ ] **8.5 E2E smoke** (`integration_test/`): launch app → open synthesized clip → run analysis with `MockVlmProvider` + mock chat client (DI overrides) → visual and speech detections appear → accept one of each → region blur + word beep applied → export → ffprobe assertions. Runs in CI.
- [ ] **8.6 Coverage ≥ 80%** line coverage; floor set to the achieved value; `docs/testing.md` rewritten to match reality (commands, structure, fakes, goldens, fixtures, CI).

**Exit criteria:** coverage ≥ 80% enforced in CI; e2e smoke green in CI; no `lib/` top-level area with zero tests.

---

## Phase 9 — Validation & release (**HUMAN-GATED**)

- [ ] **9.1 Curate the evaluation dataset** per Appendix F on the owner's machine (unsafe clips never committed): safe controls, per-category positives (incl. kissing, immodest clothing, weapons states), ambiguous sports contact, low-light/motion-blur, short flashes, long-context, box ground truth, **speech positives** (clear profanity, split-token profanity, homograph traps, innuendo/threats, non-English profanity). Manifest JSON per `EvaluationDataset` schema.
- [ ] **9.2 Run RTX validation** on RTX 5070-class hardware with real downloaded artifacts: `dart run scripts/vss_validation_runner.dart --dataset-root … --manifest … --analysis-command … --fail-on-validation-gate`. Extend the runner to record the speech metrics from Appendix F (word-span alignment error, candidate-verdict precision/recall). Iterate (prompts/thresholds/refinement settings) until `rtxValidationGate` passes. Commit the aggregate report to `docs/implement/validation-reports/`.
- [ ] **9.3 Flip validation state**: set `fitsRtx5070Validated: true` for the passing bundle(s), record the Model Approval Record (Appendix D) in the PR, remove the not-yet-validated warning banner for that bundle+hardware class, set Qwen3-VL-8B as the `AnalysisSettings.defaults()` bundle.
- [ ] **9.4 Release pass**: version bump; `docs/` final sweep (architecture.md, TECHNICAL_REFERENCE.md, README feature list reflect the shipped app — no legacy, no MMS, no aspirational features); packaging per `docs/deployment.md`; tag.

**Exit criteria:** a committed passing RTX validation report (incl. speech metrics); validated default bundle; docs truthful; tagged release build produced by `scripts/build_windows_vs2022.ps1`.

---

## Standing quality gates (every task, every phase)

1. `dart format` clean (hook-enforced) • 2. `flutter analyze --fatal-infos` clean • 3. `build_runner` output committed and diff-free • 4. tests for the change pass; full suite green in CI • 5. no new file > 800 lines; no new TODOs without a checklist reference • 6. loopback-only and official-source invariants never weakened (Appendix C) • 7. taxonomy/policy changes carry a Policy Review Record (Appendix E).
