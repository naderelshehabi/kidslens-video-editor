# KidsLens Revamp Plan (v3 — Consolidated)

**Status:** Approved for implementation
**Date:** 2026-07-13 (rev 2: speech-safety modernization + pro-editor features folded in)
**Companion:** [revamp-checklist.md](revamp-checklist.md) — the step-by-step implementation checklist. This document is the *why and what*; the checklist is the *how and in what order*.
**Supersedes:** every prior document in `docs/implement/` (see Appendix G for the ledger). `docs/implement/` now contains only this plan, the checklist, and `validation-reports/` (the output directory of `scripts/vss_validation_runner.dart`).

---

## 1. Vision

KidsLens is a **local-only, single-purpose desktop video editor** whose job is to make any video safe for children:

1. **Detect** — a local vision-language model (VLM) scans the video and finds unsuitable content: explicit nudity, sexual/suggestive content, kissing/romance, immodest female clothing, violence, gore, blood, weapons, substances, and unsafe speech (profanity, sexual talk, threats) — the speech side combining fast lexical matching with a context-aware local-LLM judge.
2. **Review** — findings appear on the timeline and in a fast, keyboard-driven review queue, each with a rationale, severity, confidence, and — where the model can localize — a bounding-box region tracked over time.
3. **Remediate** — the user blurs, pixelates, black-boxes, or cuts flagged scenes (or mutes/beeps audio with word-accurate spans), previews the result live, and exports a clean file where every edit is *actually applied*.

Everything runs on the user's machine (high-end consumer GPU, RTX 5070-class / 12 GB VRAM target). No frames, audio, or metadata ever leave the device.

## 2. Current state (audit summary, 2026-07-13)

The codebase is a Flutter/Riverpod Windows desktop app (~229 Dart files) with whisper.cpp ASR (FFI), FFmpeg CLI media handling, media_kit playback, and two visual pipelines:

**What already works**
- The VSS engine is real end-to-end (mock-tested): `ChunkPlanner` (8 s scene-snapped chunks) → JPEG frame extraction (≤8 frames/chunk, 768 px, q85) → `OpenAiCompatVlmProvider` (base64 frames to a pinned llama.cpp `llama-server` b9628 on loopback, strict `response_format: json_schema`, repair retry) → `PolicyEngine` → `TemporalFusion` → `Detection`s/timeline → local search index (Qwen3-Embedding or hash fallback).
- Runtime/bundle management: pinned llama.cpp binaries (CUDA 13.3 / Vulkan) with SHA-256 verification; official Qwen3-VL 8B/4B GGUF bundles; first-run download UX; checkpoint/resume; loopback-only enforcement.
- ASR core: whisper.cpp v1.7.3 FFI in a background isolate, 30 s chunks with 3 s overlap and midpoint stitching, streaming WAV reader, GPU→CPU retry, result cache.
- Editor: 3-pane layout, zoomable multi-lane timeline, undo/redo (snapshot-based), live blur-region preview, FFmpeg export with progress.

**What is broken or missing (the reasons for this revamp)**
1. **Cut is never applied on export.** `EditActionType.cut` maps to `Modification.videoSkip`, which compiles to an empty FFmpeg filter (`export_service.dart`). Cut scenes remain in the exported file — a child-safety correctness bug.
2. **Region blur from the timeline exports as full-frame blur.** `export_dialog._actionToModification` drops `action.boundingBox`; the region-blur FFmpeg machinery exists but is never fed from that path.
3. **VSS bounding boxes are discarded.** The VLM's `groundedRegions` are parsed then thrown away (`vlm_provider.dart` `_buildResponse`), the pipeline ignores the returned `VlmSegmentResponse`, and `GroundingProvider`/the grounding prompt are never invoked. Every VSS detection is scene-level; the preview box overlays are fed only by legacy NudeNet.
4. **Silent legacy fallback.** Any VSS startup failure silently runs the legacy ONNX pipeline; no bundle is production-selectable (`fitsRtx5070Validated: false`), so in practice legacy still runs by default.
5. **Legacy pipeline debt.** NudeNet is AGPL-3.0 (license conflict with the MIT app), ONNX Runtime DLLs bloat the build, and legacy concepts leak into settings, models tabs, debug overlays, evidence types, and docs.
6. **Speech safety is dictionary-only and built on broken timestamps.** Profanity detection is purely lexical (wordlists + leetspeak + Double Metaphone/Levenshtein) with no context awareness — no multi-word phrases, phonetics that silently no-op on non-Latin scripts, every loaded language's wordlist scanned for every word (cross-language false positives, O(N·M)), severity/category never populated, and most `ProfanityConfig` flags defined but never read. Worse, the "word" timestamps it consumes are actually whisper **BPE token** fragments (`whisper_wrapper.cpp` loops tokens, not words) — profanity split across tokens is missed and beep spans are token-aligned. Auto language detection never returns the detected language (the wrapper echoes the input, defaulting `"en"`). The catalog carries **10 Whisper models** (five English-only, several sizes nobody should use) with three competing "default model" code paths, and Meta MMS is a dead FFI stub behind an unreachable branch that README still advertises ("100+ languages with Meta MMS").
7. **UX gaps vs a modern editor:** synthetic (fake) audio waveform, no frame stepping / J-K-L / snapping / markers, wheel hijacked for zoom, memory-heavy whole-project undo snapshots, duplicated settings sources, unwired autosave, two 2,500+-line god widgets, dead alternate widget sets, no proxy playback for 4K sources.
8. **No CI**, and large untested areas: `lib/jobs/`, FFI bindings, export dialog mapping, editor screens/widgets.

## 3. Target architecture

### 3.1 One detection pipeline, fail-visible availability

The legacy pipeline (`legacy_nsfw_region_v8`, NudeNet, NSFW ONNX, modesty parser, ONNX Runtime FFI) is **removed entirely** (Decision D1). The rollout state machine and its legacy-fallback machinery are replaced by a simple, honest availability model:

```
DetectionAvailability
├── ready            → VSS runs (runtime installed + model bundle installed + GPU backend available)
├── setupRequired    → guided first-run flow (download runtime + bundle); analysis blocked until done
└── degradedAudioOnly→ audio_only profile runs (transcription + lexical speech safety); visual analysis
                       and the LLM speech tier clearly reported as unavailable with reason and fix
```

- `audio_only` becomes a **real, implemented profile** (transcription + speech-safety stages) — the degraded mode for machines without CUDA/Vulkan or before model download. `fast_preview` and `legacy_nsfw_region_v8` profiles are deleted.
- There is **no silent pipeline switching**. If VSS cannot start, the user sees the reason (missing runtime, missing bundle, no compatible GPU, server crash) and an action button. Failure classification telemetry (JSONL) is retained.
- Old analysis results and evidence files that contain legacy evidence types remain **readable**: the evidence store and replay tolerate unknown evidence types by skipping them gracefully (no legacy code kept for compatibility).

### 3.2 Visual detection pipeline (VSS v3)

Stages, per media file:

```
1. Probe (ffprobe) ──► 2. Speech safety (see §3.4): transcribe + lexical tier + LLM tier
3. Scene detection (FFmpeg scene scores) ──► ChunkPlanner (8s target, 4–12s, 750ms overlap, scene-snapped)
4. Frame sampling: ≤8 frames/chunk, 768px JPEG q85
5. VLM policy pass: OpenAiCompatVlmProvider → llama-server (Qwen3-VL GGUF), strict JSON schema
   └─► NEW: VlmSegmentResponse captured; groundedRegions persisted as EvidenceRecord.groundedRegion
6. NEW — Grounding pass: for findings in region-preferring categories whose groundingStatus ≠ grounded,
   send the grounding prompt for the finding's frames; parse boxes; pixel→normalized repair
7. NEW — Refinement pass (optional, default on): chunks with high-severity or high-uncertainty findings
   are re-analyzed at 2× frame density with sub-chunks to tighten start/end boundaries
8. NEW — Region tracking: associate boxes across frames per finding (IoU ≥ 0.3 greedy matching)
   into RegionTrack { regionId, category, keyframes: [(t, NormalizedGroundingBox)] }
9. PolicyEngine (single-provider mode) → TemporalFusion → Detections with boundingBoxKeyframes metadata
10. Search indexing (captions, findings, transcript, regions) — embedding server when installed
```

Key contracts preserved from the prior plans (Appendices A–B): the 11-category taxonomy, the strict VLM JSON output schema, evidence-first architecture (providers emit evidence; only PolicyEngine + TemporalFusion produce `Detection`s), high-recall thresholds for nudity/gore/blood/weapons, review-first for immodesty and kissing/romance, loopback-only inference, official-weights-only sourcing.

PolicyEngine changes: with legacy evidence gone, the VLM↔legacy agreement machinery is removed. `needsReview` is driven by category policy, confidence bands, and the model's own `uncertainty` output. The generic `PolicyFindingOrigin`/evidence-provenance plumbing stays (it is how a future second provider would plug in), but agreement-state code paths that can no longer occur are deleted, not kept "just in case".

### 3.3 Runtime and models (unchanged spine, hardened)

- **Runtime:** llama.cpp `llama-server` pinned release **b9628** (CUDA 13.3 build + Vulkan fallback), spawned on `127.0.0.1:<dynamic port>`, health-polled, ref-counted, idle-shutdown, stale-child ledger. Non-CUDA/Vulkan machines get `degradedAudioOnly` with guidance.
- **VLM models (official vendor GGUF only):** `Qwen/Qwen3-VL-8B-Instruct-GGUF` (Q4_K_M + mmproj F16, default), `Qwen3-VL-4B-Instruct-GGUF` (lightweight), `Qwen3-Embedding-0.6B-GGUF` (search, CPU). **All model artifact files get pinned SHA-256 checksums** verified at download (currently `sha256: null` — gap).
- **ASR models curated to two multilingual entries** (Decision D12): `whisper-large-v3-turbo` (default — 809M params, ~1.6 GB, 99 languages, best speed/quality on consumer GPUs) and `whisper-small` (466 MB, CPU/low-VRAM fallback). The other eight catalog entries (all `.en` English-only variants, tiny, base, medium, large-v3) are removed with settings migration to the nearest kept model. Both files get pinned SHA-256 from the official `ggerganov/whisper.cpp` HF repo. One default-selection path (currently there are three).
- **Approval gating reworked (Decision D3):** with no legacy fallback, blocking selection until an RTX validation run would brick the app. `approvalStatus: evaluationOnly` becomes **selectable with a persistent "not yet validated on this hardware class" warning banner**; the `rtxValidationGate` (comparison gates, p95 chunk latency ≤ 8000 ms, peak VRAM ≤ 12288 MB, zero schema failures/crashes) remains the **release gate**: a passing dated report in `docs/implement/validation-reports/` is required before a tagged release and before removing the warning banner.
- Model sourcing/porting governance rules are preserved verbatim in Appendix C.

### 3.4 Speech safety (ASR + profanity) — modernized two-tier framework

Replaces the dictionary-only profanity path (Decision D11). Foundation fixes first, then intelligence:

**Foundation (correctness + performance)**
- **True word timestamps:** whisper token fragments are aggregated into words in Dart (merge consecutive tokens that don't begin with whitespace; per-token fallback for unspaced scripts) — fixes split-token misses and gives word-accurate beep spans (Decision D14). Beeps get configurable padding (default ±120 ms).
- **Real language detection:** the native wrapper returns whisper's detected language (`whisper_full_lang_id`) instead of echoing the input; the detected language selects which wordlists load and is stored on the transcript/cache.
- **MMS removed** (Decision D13): the dead FFI stub, its unreachable branch in `AnalysisService`, and the README claim go away. Whisper's 99-language support is the multilingual story.
- **Silence skipping:** an FFmpeg `silencedetect` prepass lets the transcription chunker skip silent stretches — a large speedup on typical family footage. (Optional stretch: bump the whisper.cpp pin for built-in Silero VAD, only if the wrapper builds cleanly.)

**Tier 1 — lexical candidate generator (`LexicalProfanityMatcher`)**
- Aho-Corasick automaton per language over normalized wordlists + custom words → single-pass matching, **multi-word phrase support**, no per-word full-list scans.
- Loads **only the detected language** (plus configured extras) — ends cross-language homograph false positives.
- Leetspeak normalization kept; phonetic tier restricted to Latin-script languages with code-bucketed candidates (Levenshtein only within a bucket). All `ProfanityConfig` flags actually honored; dead config removed.
- Output: *candidates* with word spans, match type, lexical confidence — not final detections.

**Tier 2 — context-aware LLM judge (`SpeechPolicyAnalyzer`)**
- Reuses the **already-running local llama-server** (Qwen3-VL is a strong multilingual text model; text-only chat completions, zero extra VRAM, loopback-only invariant intact). Runs when `DetectionAvailability == ready`; otherwise the system degrades **visibly** to lexical-only.
- Transcript is sliced into ~45 s windows (5 s overlap) with Tier-1 candidates marked inline. A strict JSON schema (`SpeechPolicyOutputSchema`, sibling of the VLM schema) returns: per-candidate verdicts (confirm/reject + severity + rationale — kills homograph/false-positive beeps) **and additional findings the dictionary can't see** — innuendo, sexual talk, threats, drug references — each with a quote, time span, category, severity, confidence, rationale.
- Findings map into the **existing taxonomy** (profanity, sexual_content, suggestive_content, violence, substances) — no taxonomy change, so no Policy Review Record is required. Evidence-first: a new `EvidenceType.speechPolicyFinding` feeds `PolicyEngine`; confirmed profanity → word-span beep; sexual/threat/substance speech → scene-level review findings.
- Explainability: rejected candidates are recorded as evidence too, so the review UI can show *why* a word was not flagged.

### 3.5 Export engine (correctness first)

A new **ExportPlan compiler** replaces the ad-hoc dialog→modification mapping:

- Input: media + edit actions (with region keyframes) + subtitle options. Output: a validated FFmpeg invocation.
- **Cuts actually cut:** time-based visual/audio filters (`enable='between(t,…)'`) are applied on the source timeline first, then kept intervals are `trim`/`atrim` + `concat`-ed (filters before `setpts`, so filter times stay in source coordinates — no remapping bugs). Audio always mirrors video cuts.
- **Region edits are region edits:** `EditAction.boundingBox` / region tracks flow into `Modification.videoRegionBlur|Pixelate|BlackBox`; keyframed tracks compile to piecewise-constant per-keyframe-segment `crop→gblur/scale→overlay` chains (bounded segment count; long graphs already spill to `-filter_complex_script`).
- **Smooth audio remediation:** mute/beep intervals get short (~50 ms) volume ramps instead of hard cuts, so remediated audio sounds professional.
- One `ExportFormat`/`ExportQuality` enum pair in `lib/data/models/`, shared by settings and the export dialog; named **export presets** on top.
- Verified by golden filtergraph tests plus real-FFmpeg integration tests on tiny synthesized clips (assert duration shrinks after cuts, blur region differs from full-frame).

### 3.6 Editor UX revamp

- **Decompose the god widgets:** `editor_screen.dart` (~2,700 lines) → `EditorShell` + `EditorMenuBar` + Intent/Action-based `EditorShortcuts`; `timeline_panel.dart` (~2,600 lines) → per-track widgets + painter files. Delete the unused alternate widget sets (`widgets/timeline/*`, `widgets/player/*`) after confirming no imports.
- **Command-based undo/redo** (`EditorCommand { apply(); revert(); }` + history) replacing 50-deep whole-`Project` snapshots; every mutating action goes through it.
- **Real audio waveform:** `WaveformService` decodes PCM peaks via FFmpeg once per media, caches per-project, renders min/max buckets.
- **Professional transport & timeline:** frame-accurate stepping (←/→, fps from probe), J/K/L shuttle, Space, I/O, S split-at-playhead, M markers, Home/End, timecode `HH:MM:SS:FF`; wheel scrolls / Ctrl+wheel zooms / zoom-to-fit; snapping to detections, markers, playhead, clip edges.
- **Detection-first review workflow:** revamped review queue — filmstrip per finding, rationale + severity + confidence + region badge, keyboard accept/reject (A/R, arrows), bulk actions per category, "apply all recommended actions" respecting per-category defaults; before/after preview toggle.
- **VSS regions on the preview:** interpolated bounding box rendered at the playhead for the selected/active detection; applying a region action prefills the blur/pixelate/box overlay from the region track.
- **Housekeeping:** autosave timer actually wired (interval from settings, dirty-flag, crash recovery on open); settings unified behind the Riverpod settings repository (no direct SharedPreferences writes from screens); panel layout persistence; Material 3 polish.

### 3.7 User features (scope-fit)

1. **Safety search panel** — surface the already-built local semantic index: search "kissing scene", "gun" → ranked moments, click to seek. (Index exists; only UI + provider wiring is new.)
2. **Sensitivity profiles** — Strict / Standard / Custom presets (age-oriented) mapping per-category thresholds + default actions; one dropdown for parents, full control for power users; re-evaluation from stored evidence without re-inference.
3. **Batch analysis queue** — queue multiple files through the job system; review each when done.
4. **Safety report export** — HTML/JSON summary (categories found, timestamps, actions applied, model/runtime provenance) written next to the exported video.
5. **Subtitle sanitization** — censor matched profanity in generated/exported subtitles (`f***`), consistent with audio beeps.
6. **Proxy playback** — auto-generated low-res proxy for smooth scrubbing of 4K sources; analysis and export always use the original.
7. **Hover scrubbing** — skim clip content by moving the mouse across media-bin cards and the timeline filmstrip (Final Cut-style skimmer) — ideal for eyeballing flagged scenes fast.
8. **Beep/mute ramps** — 50 ms fades on audio remediation boundaries (see §3.5).
9. **Export presets** — named, persisted format/quality/subtitle/report combinations.
10. **Detection heatmap** — severity-weighted density strip on the timeline ruler showing where findings cluster in a long video; click to jump.
11. **Range re-analysis** — select a timeline range → re-analyze just that section at 2× frame density (manual complement to the automatic refinement pass).

Deferred to the post-release backlog (Appendix H): synced transcript panel, smooth cut transitions, source in/out trim before analysis, relink-missing-media.

### 3.8 Testing & CI

- **GitHub Actions** (`windows-latest`): `dart format --set-exit-if-changed` → `build_runner` (fail on diff) → `flutter analyze` → `flutter test --coverage` with a ratcheting coverage floor (baseline at adoption, target ≥ 80% line coverage by Phase 8).
- **Fakes over mocks for process boundaries:** `FakeProcessRunner` for FFmpeg/ffprobe/llama-server; `MockVlmProvider` (exists) + a mock chat client for the speech tier; tiny synthesized clips for real-FFmpeg integration tests; labeled transcript fixtures for speech-safety accuracy.
- **Every phase ships with its tests** — a checklist phase is not complete until its listed tests pass in CI. Current blind spots called out explicitly in the checklist: `lib/jobs/`, FFI bindings, export dialog mapping, editor widgets, providers.

## 4. Decisions (ADR summary)

| # | Decision | Rationale |
|---|----------|-----------|
| D1 | **Remove the legacy pipeline now**, superseding the 30-day deprecation gate and "legacy as auxiliary evidence" policy | Product owner directive; AGPL NudeNet cannot ship in an MIT app; silent fallback hides safety-critical failures; carrying two pipelines is the project's largest debt |
| D2 | **Fail-visible availability model** with real `audio_only` degraded mode | Silent fallback is unacceptable for a safety product; audio-only preserves value on unsupported hardware |
| D3 | **Warn-don't-block model approval; `rtxValidationGate` becomes the release gate** | With no fallback pipeline, hard-blocking selection would brick the app; the gate still protects releases |
| D4 | **Keep llama.cpp b9628 + Qwen3-VL GGUF spine** | Only viable Windows desktop runtime (vLLM/TensorRT-LLM/NIM eliminated previously); official Apache-2.0 weights; native 2D grounding |
| D5 | **Keep evidence-first architecture** (evidence → PolicyEngine → detections) | Explainability, replay, search, and future providers depend on it |
| D6 | **Grounding completed in-pipeline**: capture policy-pass regions + targeted second grounding pass + IoU region tracks | Boxes are the core promised UX; a second pass only for ungrounded high-priority findings bounds cost |
| D7 | **ExportPlan compiler with trim/concat cuts, filters-before-setpts** | Fixes both export correctness bugs structurally, not with patches |
| D8 | **Command-pattern undo/redo** | Snapshot-per-edit is memory-heavy and inconsistently applied; commands make every mutation undoable by construction |
| D9 | **SHA-256 pinning for all model artifacts** (VLM, embedding, ASR — not just runtime binaries) | Supply-chain integrity for a child-safety product |
| D10 | **Old results readable via tolerant deserialization**, not retained legacy code | Honors the compatibility requirement with zero legacy surface |
| D11 | **Two-tier speech safety: lexical candidate generator + local-LLM judge on the same llama-server** | Dictionary-only matching has no context (homograph FPs, zero innuendo/threat coverage); the LLM tier adds intelligence with zero extra VRAM, no new runtime, no taxonomy change, and the loopback invariant intact; the lexical tier keeps word-span precision for beeps and full function when the GPU runtime is absent |
| D12 | **ASR catalog curated to `whisper-large-v3-turbo` (default) + `whisper-small` (fallback), multilingual only** | English-only variants are redundant with multilingual models; tiny/base underperform for a safety product; medium/large-v3 are dominated by turbo on consumer GPUs; ten models with three competing default-selection paths is debt |
| D13 | **Remove Meta MMS entirely** | It is a placeholder FFI stub with no native library, no model, an unreachable call site, and a false README claim; whisper's built-in 99-language detection (fixed by D14's wrapper work) covers the multilingual story |
| D14 | **Token→word aggregation in Dart, not C++** | The wrapper's per-token output stays as-is (renamed for honesty); Dart-side aggregation is unit-testable without a native rebuild and keeps the C++ surface minimal — only the detected-language fix touches C++ |

## 5. Non-goals

- Cloud/hosted inference of any kind (hard invariant: loopback-only).
- General-purpose NLE features beyond the safety mission (multi-sequence editing, transitions library, color grading, titling/motion graphics, keyframed effects unrelated to remediation).
- macOS/Linux parity in this revamp (architecture stays portable; Windows is the validated target).
- Mobile (out of scope; previously tracked in a separate future note, dropped).
- Training or fine-tuning models; community model ports.

## 6. Risks

| Risk | Mitigation |
|------|------------|
| Qwen3-VL grounding quality insufficient for tight boxes | Grounding pass measured by box-IoU in the validation runner; category policy already degrades to scene-level (`scene_level_only`) with full-frame remediation defaults |
| Legacy removal breaks hidden consumers | Removal inventory in the checklist is exhaustive (from a full-repo sweep); CI + analyzer gate every step; work in small reviewed commits |
| trim/concat export re-encodes and is slower | Acceptable: correctness over speed; quality presets already exist; document expectation |
| RTX validation (human/hardware-gated) delays release | Explicitly isolated as the final phase; everything else lands independently behind the warning banner |
| VLM latency on 12 GB VRAM misses p95 ≤ 8 s/chunk | 4B bundle as fallback; refinement pass is optional; frame budget already capped; batch extraction task if measured over budget |
| LLM speech tier adds analysis time | Text-only inference is fast (a 2 h movie ≈ ~160 small windows); budget instrumented at ≤ 15% of total wall time; tier is toggleable and degrades to lexical-only |
| whisper.cpp version bump (optional VAD stretch) breaks the wrapper | The bump is explicitly optional; FFmpeg `silencedetect` prepass delivers the silence-skip win on the pinned v1.7.3; upgrade only if the `/WX` build and ASR tests stay green |
| Token→word aggregation wrong for unspaced scripts (CJK/Thai) | Explicit per-token fallback for scripts without word spacing; fixture tests per script family |

## 7. Phase overview

See [revamp-checklist.md](revamp-checklist.md) for full detail. Order is deliberate: safety-correctness first, then removal, then detection completion (visual, then speech), then polish.

| Phase | Title | Outcome |
|-------|-------|---------|
| 0 | Guardrails & CI | CI pipeline live; repo hygiene; agent tooling verified |
| 1 | Export correctness | Cuts cut, region blurs stay regional — verified by integration tests |
| 2 | Legacy pipeline removal | Zero legacy references in code/UI/build/docs; availability model in place |
| 3 | Visual detection completion | Grounded regions captured/tracked; refinement pass; checksums; approval rework |
| 4 | Speech safety modernization | Curated 2-model ASR catalog; true word timestamps + language detect; MMS gone; two-tier lexical+LLM speech analysis |
| 5 | Region UX & remediation | Boxes on preview; region-prefilled actions; keyframed region export |
| 6 | Editor UX revamp | Decomposed UI, command undo, real waveform, pro transport, review queue |
| 7 | User features | Search, sensitivity profiles, batch queue, safety report, subtitle sanitization, proxy, hover scrub, beep ramps, export presets, heatmap, range re-analysis |
| 8 | Test completion & hardening | Coverage ≥ 80%, e2e smoke with mock VLM, fakes for all process boundaries |
| 9 | Validation & release (**human-gated**) | RTX validation report recorded; banner removed; release tagged |

---

## Appendix A — Policy taxonomy and defaults (binding contract)

Categories (`FamilySafetyPolicyCategory`, 11): `explicit_nudity`, `sexual_content`, `suggestive_content`, `kissing_romance`, `immodest_female_clothing`, `violence`, `gore`, `blood`, `weapons`, `substances`, `profanity`.

| Category | Default action | Enforcement | Boundary requirement |
|----------|----------------|-------------|----------------------|
| explicit_nudity | blurRegion | enforceWhenHighConfidence | regionWhenAvailable |
| sexual_content | cutScene | reviewFirst | sceneLevel |
| suggestive_content | blurRegion | reviewFirst | regionWhenAvailable |
| kissing_romance | cutScene | reviewFirst | sceneLevel |
| immodest_female_clothing | blurRegion | reviewFirst | regionWhenAvailable |
| violence | cutScene | reviewFirst (enforce at high severity+confidence) | sceneLevel |
| gore | cutScene | enforceWhenHighConfidence | sceneLevel |
| blood | blurRegion | reviewFirst | regionWhenAvailable |
| weapons | reviewOnly (cut when aimed/in-use) | reviewFirst | regionWhenAvailable |
| substances | reviewOnly | reviewFirst | sceneLevel |
| profanity | beep | enforceWhenHighConfidence | wordSpan |

Rules preserved: high-recall thresholds (0.2) for `explicit_nudity`/`gore`/`blood`/`weapons`; VLM confidence threshold 0.35 elsewhere; profanity 0.7; kissing→sexual escalation on severity; weapon-state guidance (in_hand/aimed/worn/displayed/toy — toy/prop downgrades); graded immodesty via `exposureSignals` count; provider failure ⇒ fail-to-review, never fail-silent; no age inference by the model. Speech findings from the LLM tier map into these same categories (spoken sexual content → `sexual_content`, threats → `violence`, drug talk → `substances`, slurs/profanity → `profanity`); no new categories are introduced. Changes to this table require a Policy Review Record (Appendix E).

## Appendix B — Model output schemas (binding contracts)

**Visual (policy pass):** JSON conforming to `FamilySafetyVlmOutputSchema` (`family_safety_prompt_templates.dart`): `schemaVersion`, `caption`, `groundedRegions[] { regionId, frameTimestampMs, box (normalized [0,1] or pixel — pixel auto-repaired), label, confidence }`, `findings[] { category, severity, confidence, startMs, endMs, rationale, regionIds[], groundingStatus, needsReview }`, `searchTerms[]`, `uncertainty`. Enforced via `response_format: json_schema` (fallback `json_object` + repair retry). `groundingStatus` ∈ grounded | scene_level_only | unsupported_by_model | failed | ambiguous. Prompts: factual, per-category, "unclear" allowed and required when uncertain, timestamps + rationales mandatory.

**Speech (LLM tier):** JSON conforming to the new `SpeechPolicyOutputSchema`: `schemaVersion`, `candidateVerdicts[] { candidateId, verdict: confirm|reject, severity, category, rationale }`, `additionalFindings[] { quote, startMs, endMs, category ∈ {profanity, sexual_content, suggestive_content, violence, substances}, severity, confidence, rationale }`, `uncertainty`. Same enforcement/repair machinery as the visual schema. Both prompts obey the same constraints: factual, no age inference, "unclear" over guessing.

## Appendix C — Model sourcing & runtime governance (binding rules)

1. Production candidates only from **official provider repositories** (or KidsLens-owned artifacts reproducible from official weights with a recorded recipe). Community ports are never selectable. The official `ggerganov/whisper.cpp` HF repo counts as official for whisper GGML conversions (it is the runtime vendor's repo).
2. Every bundle/model records: source repo + revision, license, commercial-use status, artifact file list with sizes and **SHA-256**, quantization, VRAM profile, capability flags.
3. Downloads resolve only from the recorded official source (`hf://` repo + revision), approved orgs only; gated repos require explicit terms acceptance; tokens only from env (`HF_TOKEN`/`HUGGINGFACE_TOKEN`); provenance metadata written beside artifacts. **Download ≠ selectable-without-warning** (see D3).
4. Runtime binaries pinned by release tag + per-asset SHA-256 (source of truth: `runtime_binary_manager.dart`, currently llama.cpp `b9628`; whisper.cpp pinned by git tag in `native/whisper/CMakeLists.txt`, currently `v1.7.3`).
5. Local-only invariants: inference servers bind `127.0.0.1` only; hosted endpoints rejected; no API keys in project files; per-detection provenance recorded.
6. Rejected/blocked: NudeNet (AGPL-3.0), LocateAnything-3B (non-commercial), Llama-4-Scout (size), community GGUF ports, Meta MMS (removed — stub with no viable local runtime here). Watchlist (no official GGUF yet): Qwen3.5-VL, Gemma-4, Cosmos-Reason2.

## Appendix D — Model Approval Record (template)

Required before any new model bundle becomes selectable. Store as a dated section in the validation report or PR description.

```
Model: <id> | Source: <official repo + revision> | License: <spdx> | Commercial use: <yes/no/conditions>
Artifacts: <file, bytes, sha256> ...
Local-only compliance: <how verified>
Hardware fit: <VRAM peak on RTX 5070 12GB, first/second pass>
Capabilities: <image input, grounding, video input, max frames/chunk>
Safety validation: <recall per gated category, dataset id, report path>
Decision: <approved for release | evaluation-only | rejected> — <who, date>
```

## Appendix E — Policy Review Record (template)

Required before changing the taxonomy, default actions, enforcement modes, boundary requirements, or explainability contract.

```
Change: <what> | Motivation: <why>
Local-only rule check: <unaffected/affected+how>
Taxonomy after change: <list> | Default actions after change: <table>
Explainability: <rationale/evidence/provenance still recorded? how>
Validation evidence: <eval run id/report path showing gates still pass>
Decision: <who, date>
```

## Appendix F — Evaluation dataset & release gates (binding contract)

Dataset contract (`EvaluationDataset.familySafetyV1Smoke`, id `kidslens_family_safety_v1_smoke`): must cover safe controls, positives per category, ambiguous sports contact, low-light/motion-blur, short flashes, long-context scenes, immodest clothing, bounding-box ground truth, and **speech positives** (clear profanity, split-token profanity, homograph false-positive traps, innuendo/threat clips, non-English profanity). **Unsafe clips are never committed** — only reviewed aggregate reports in `docs/implement/validation-reports/`.

Metrics: per-category recall/precision/FNR/FPR, temporal-IoU, box-IoU, review burden, explanation completeness, latency p50/p95, memory, VRAM; for speech: word-span alignment error (ms) and candidate-verdict precision/recall.

Release gates (`rtxValidationGate`, enforced by `scripts/vss_validation_runner.dart --fail-on-validation-gate`):
- explicit nudity recall ≥ 0.97; gore/blood ≥ 0.95; high-severity violence ≥ 0.93; immodesty optimizes review-recall
- default-profile p95 chunk latency ≤ 8000 ms; peak VRAM ≤ 12288 MB; zero schema failures/crashes/runtime errors; latency+VRAM samples present

## Appendix G — Superseded documents ledger

All previously in `docs/implement/`, consolidated into this plan + checklist on 2026-07-13:

| Document | Disposition |
|----------|-------------|
| vss-family-safety-detection-revamp-plan.md | Architecture/governance absorbed (§3.2, Appendices A–B); runtime direction superseded earlier by v2 |
| vss-family-safety-v2-local-vlm-execution-plan.md | Runtime spine absorbed (§3.3); open Phase 10 work re-planned as Phases 3 & 9 |
| vss-family-safety-detection-implementation-checklist.md | Historical record; open work re-planned in revamp-checklist.md |
| legacy-direct-detection-deprecation-readiness.md | **Superseded by Decision D1** (removal ordered; 30-day gate void) |
| official-model-source-and-porting-plan.md | Rules absorbed as Appendix C |
| model-bundle-manifest-source-review.md | Truth table lives in code (`model_bundle_manifest.dart`, `runtime_binary_manager.dart`); rules in Appendix C |
| model-approval-record-template.md / policy-review-record-template.md | Absorbed as Appendices D–E |
| family-safety-evaluation-dataset.md | Absorbed as Appendix F |
| comprehensive-implementation-plan.md, implementation-plan.md, ai-models-reference.md | Historical baselines; superseded |
| nsfw-pipeline-rework-plan.md, nsfw-region-detection-full-integration-plan.md, onnx-execution-providers-research.md, phase2-ffi-layer-implementation-summary.md, phase2-integration-examples.dart, phase6-validation-report.md, gpu-device-index-fix.md, gpu-fix-summary.md | Legacy-pipeline era; obsolete under D1 (GPU-discovery UX behavior they describe lives on in code/tests) |
| asr-optimization-plan.md / asr-optimization-report.md | Fully implemented; behavior documented in docs/TECHNICAL_REFERENCE.md; further ASR work re-planned as Phase 4 |
| mobile-future-plan.md | Out of scope (§5) |
| validation-reports/README.md | **Kept** — output contract for the validation runner |

## Appendix H — Post-release backlog (agreed deferrals)

Features inspired by professional editors that fit the mission but are deliberately deferred past the revamp release:

1. **Synced transcript panel** — scrollable transcript with profanity/speech findings highlighted; click a word to seek (read-only variant of Premiere's text-based editing; ASR data already exists).
2. **Smooth cut transitions** — optional short crossfade/dip-to-black at cut seams (micro-subset of NLE transitions, justified because cuts are the product's core output).
3. **Source in/out trim before analysis** — top/tail a file (skip intros/credits) to save GPU time; not multi-clip editing.
4. **Relink missing media** — prompt to relocate moved source files instead of failing to open the project.
