# NSFW Analysis Pipeline Rework Plan (Windows-first, migration-only)

Date: 2026-02-22

## 1) Objective

Rework the existing analysis pipeline to restore full visual NSFW analysis using the latest `GantMan/nsfw_model` semantics, while preserving current app UX and existing detection/timeline contracts.

Canonical NSFW classes used end-to-end:
- `drawings`
- `hentai`
- `neutral`
- `porn`
- `sexy`

## 2) Current State (in this repo)

- `lib/services/analysis_service.dart` currently skips visual analysis (ASR-only flow).
- `lib/native/bindings/onnx_bindings.dart` classification path is placeholder simulation.
- `lib/services/huggingface_model_registry.dart` is ASR-only; visual model lists are empty.
- `lib/data/models/huggingface_model.dart` supports only `HuggingFaceModelType.asr` and `isVisualModel` is hardcoded false.
- `lib/data/models/analysis_settings_migration.dart` migrates to ASR-only schema behavior.

## 3) Scope and Non-Goals

### In scope (v1 migration)
- Restore visual NSFW inference pipeline.
- Integrate latest nsfw_model-compatible class semantics and model contracts.
- Keep existing UI behavior and detection/timeline interfaces unchanged.
- Ship Windows production path first.

### Out of scope (v1)
- Training/fine-tuning new NSFW models.
- Adding new moderation taxonomies or UI features.
- Multi-platform hardening beyond Windows (handled as follow-up waves).

## 4) Delivery Guardrails

- Migration, not rewrite: reuse existing services/models where possible.
- Fail-closed for child-safety critical inference failures.
- Model provenance required before runtime use (hash + approved source + license gate).
- No rollout to enforce mode without quantitative quality/performance gates.
- The NSFW classifier does not perform age inference; it must never be used to infer age/minor status.
- Any high-risk or ambiguous sexual-content result must route to conservative block/manual-review policy in enforce mode.

## 5) Approved Model Set (v1)

- Default model: MobileNet 224 variant (throughput-first).
- Fallback model: Inception 299 variant (accuracy second-pass for uncertain segments).

Reason: minimal operational complexity with clear speed/accuracy split.

## 6) Decision Policy (initial defaults)

Let:
- `unsafeCore = porn + hentai`
- `unsafeExtended = porn + hentai + sexy`

Default rule:
- `block` if `unsafeCore >= 0.30` OR `max(porn, hentai) >= 0.20`
- `review` if `unsafeCore in [0.15, 0.30)` OR `unsafeExtended >= 0.45`
- otherwise `allow`

Temporal hysteresis:
- enter unsafe state on 2 of 3 consecutive sampled frames
- clear unsafe state on 5 consecutive safe frames

Backward compatibility:
- preserve legacy single `nsfwThreshold` behavior through compatibility mapping until migration is complete.

## 7) Phase Plan with Exit Gates

## Phase 0 — Governance + Contract Freeze

Work:
- Freeze canonical labels and score semantics.
- Define class-to-action table (`drawings/hentai/neutral/porn/sexy` + unknown/invalid output handling).
- Define acceptance KPIs and owners.

Exit gate:
- Signed policy table and KPI document.

## Phase 1 — Model Provenance and Compliance Gate

Work:
- Add approved model manifest (id, source URL, SHA256, license, class order, input contract, logits/probability flag).
- Add license allowlist for v1 shipping.
- Add tamper handling policy (checksum mismatch => model rejected).

Exit gate:
- Every shippable model passes provenance + license checks.

## Phase 2 — Native ONNX Runtime Foundation (Windows)

Work:
- Replace simulated classification path in `lib/native/bindings/onnx_bindings.dart` with real ONNX execution.
- Define FFI lifecycle/ownership contract for sessions, tensors, and status objects.
- Add Windows runtime packaging/deployment updates in `windows/CMakeLists.txt` (including provider/runtime DLL copy rules).
- Implement startup self-test (CPU EP required; optional EPs probe and downgrade with reason).
- Pin ONNX Runtime ABI matrix for v1 (exact ORT version, architecture, toolchain assumptions) and enforce it in CI.
- Define ONNX runtime supply chain: source URL, hash pinning, CI artifact production, and release packaging checks.
- Define model deployment strategy for Windows (`.onnx` bundle vs first-run download), including install/cache path and rollback behavior.

Exit gate:
- Native smoke test passes on Windows release build: load model, run one inference, clean shutdown, no leak indicators.

## Phase 3 — Data Contracts and Settings Migration

Work:
- Extend `HuggingFaceModelType` beyond ASR in `lib/data/models/huggingface_model.dart`.
- Implement true `isVisualModel` behavior.
- Reintroduce visual NSFW entries in `lib/services/huggingface_model_registry.dart`.
- Upgrade schema migration from ASR-only to v3 in `lib/data/models/analysis_settings_migration.dart`.
- Ensure old settings can be safely migrated with deterministic defaults.

Exit gate:
- Migration tests pass for v1/v2 settings payloads; visual categories can be enabled via migrated config.

## Phase 4 — Inference Correctness Layer

Work:
- Add `NsfwModelSpec` and `NsfwModelAdapter` (strict output size/order checks).
- Enforce preprocessing contract per model (RGB conversion, resize policy, normalization, tensor layout).
- Enforce postprocessing contract (softmax only if logits).
- Add runtime sanity checks (finite scores, non-negative, sum approximately 1).

Exit gate:
- Deterministic fixture tests and parser goldens pass for both default and fallback models.

## Phase 5 — Analysis Pipeline Rewire

Work:
- Re-enable visual stage in `lib/services/analysis_service.dart`:
  1. frame extraction/sampling
  2. micro-batch inference
  3. temporal aggregation
  4. detection generation
- Preserve existing detection/timeline output shape for UI compatibility.
- Add checkpoint versioning fields:
  - `pipelineVersion`
  - `modelId`
  - `modelSha256`
  - `samplingConfigHash`
  - `thresholdConfigHash`

Exit gate:
- End-to-end media analysis produces visual NSFW detections and resumes safely only when checkpoint compatibility matches.

## Phase 6 — Calibration, Testing, and Observability

Work:
- Build deterministic test fixtures:
  - safe controls
  - boundary clips
  - temporal flash cases
  - degraded quality variants
- Add tests:
  - unit: adapter/mapping/threshold/hysteresis/migration
  - integration: media -> detections -> timeline
  - stress: long media, repeated sessions, leak checks
- Add observability before rollout:
  - model load failures
  - frame throughput
  - queue depth/backpressure
  - inference latency p50/p95
  - decision distribution drift

Quality gates (minimums before canary):
- Child-safety KPI targets met on labeled validation set with explicit thresholds:
  - `porn+hentai` recall >= 0.96
  - `porn+hentai` false negative rate <= 0.04
  - unsafe false positive rate on designated safe set <= 0.03
  - boundary-set decision flip rate <= 0.05
- No critical regression in memory/latency SLOs.
- Runtime integrity checks remain green under stress.
- Child-safety validation slice required (including age-ambiguous and anime/drawings edge cases) with explicit policy sign-off.

Exit gate:
- All quality/perf/reliability gates green for 7 consecutive days in shadow validation.

## Phase 7 — Controlled Rollout

Flags:
- `off` -> `shadow` -> `canary` -> `enforce`

Rules:
- Shadow is for runtime/perf comparison and telemetry validation; release decisions are based on labeled evaluation gates.
- Canary promotion requires explicit gate pass and owner sign-off.
- Automatic rollback triggers on sustained KPI/SLO breach for >= 15 minutes:
  - p95 inference latency > 150ms
  - model load failure rate > 1%
  - crash-free session rate < 99.90%
  - unsafe false negative estimate above gate in continuous evaluation lane
- One-click rollback restores last-known-good flag state and model set.

Exit gate:
- Enforce mode stable through defined soak period with no gate breach.

## Phase 8 — Decommission and Documentation

Work:
- Remove simulation-only classification path.
- Remove ASR-only assumptions in migration/config paths.
- Update docs:
  - `docs/architecture.md`
  - `docs/api-reference.md`
  - this implementation plan + operational runbook

Exit gate:
- Legacy path removed after stability window and post-cutover verification.

## 8) Performance and Reliability SLO Targets (Windows reference hardware)

- Warm single-frame inference latency: p50 <= 45ms, p95 <= 120ms
- Cold model readiness: <= 2.5s
- Steady-state memory increase after model load: <= 150MB
- Leak slope under sustained run: <= 1MB/hour
- Crash-free analysis sessions: >= 99.95%

## 9) Failure Policy (must be implemented)

Fail-closed conditions:
- model checksum mismatch
- class cardinality/order mismatch
- unrecoverable runtime inference errors

Behavior:
- deny automatic allow decisions for the affected run (block or force manual review according to policy)
- emit explicit user-visible status and structured telemetry
- trigger fallback or rollback path per rollout state

## 10) Ownership and Artifacts

Owners by subsystem:
- Service orchestration: Analysis service owner
- Native runtime/packaging: Native platform owner
- Model registry/provenance: Model management owner
- Quality/safety gates: QA owner
- Documentation/runbook: Docs owner

Required artifacts:
- phase-by-phase PR checklist
- policy/KPI sign-off record
- model provenance manifest
- rollout gate dashboard and rollback runbook

## 11) Traceability Matrix (Current -> Target)

- `analysis_service.dart` (ASR-only) -> orchestrates audio + visual NSFW pipeline
- `onnx_bindings.dart` (simulated classifier) -> real ONNX classifier with strict contracts
- `huggingface_model.dart` (ASR-only type) -> visual-capable model taxonomy
- `huggingface_model_registry.dart` (ASR-only) -> includes approved NSFW model set
- `analysis_settings_migration.dart` (ASR-only migration) -> schema v3 with visual category migration

---

This plan intentionally prioritizes migration precision, child-safety gates, and rollout safety over feature expansion.