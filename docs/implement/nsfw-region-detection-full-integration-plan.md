# NSFW Region Detection — Full Integration Plan

Date: 2026-03-01  
Status: Proposed (execution-ready)  
Owner: Visual moderation pipeline

---

## 1) Objective

Implement **true NSFW region detection** end-to-end so visual moderation can target local regions (bounding boxes) instead of only full-frame decisions, while preserving current product behavior and safety guarantees.

This plan upgrades the current NSFW classifier-only flow to a hybrid moderation pipeline:
- **Region-capable detector** for localization (boxes)
- **Classifier signal** for global confidence and fallback
- **Temporal region tracking** for stable remediation actions

---

## 2) Current Reality (in this repo)

1. NSFW model path is classification only (`drawings/hentai/neutral/porn/sexy`).
2. NSFW detections are generated as timeline segments without region metadata.
3. Region infrastructure exists (`VisualContentResult.detectedRegions`, `RegionTemporalAggregator`) but is not wired into production analysis orchestration.
4. Region UI support exists (`DetectionRegionOverlay`, `Detection.hasBoundingBox`) but is mostly unpopulated because detection metadata lacks `boundingBox`.
5. Default NSFW remediation is full-frame blur.

So the system is **functionally correct for classifier moderation** but **not integrated for region-level NSFW remediation**.

---

## 3) Scope and Non-Goals

### In scope

- Integrate region-capable NSFW visual detection into the production analysis path.
- Populate detection metadata with normalized bounding boxes and category IDs.
- Use `RegionTemporalAggregator` in production for temporally stable region tracks.
- Convert tracked regions into region-level remediation actions (blur/pixelate/black-box).
- Keep existing full-frame fallback for unsupported/overload conditions.
- Add migration-safe settings and model management support.
- Add quality/performance gates and rollout controls.

### Out of scope (this wave)

- Training custom models.
- New moderation taxonomies beyond existing categories.
- Mobile/macOS/Linux hardening (Windows-first delivery).
- Major UX redesign.

---

## 4) Target Architecture

## 4.1 Inference sources

### A) Region detector (primary for localization)
- ONNX detection model (e.g., NudeNet-style labels) returns box list:
  - label, confidence, x, y, width, height
- Output mapped to `DetectedRegion`.

### B) NSFW classifier (global safety/fallback)
- Existing ONNX ViT classifier remains active for:
  - whole-frame risk trend
  - fallback when detector unavailable
  - confidence blending and policy thresholding

## 4.2 Fusion

For each sampled frame:
- Build `FrameAnalysisResult` with:
  - `nsfw` (classifier)
  - `visualContent.detectedRegions` (detector)
  - optional `visualContent.clipScores` for CLIP-only/both categories

Then aggregate:
- `RegionTemporalAggregator.aggregate(frameResults, categories)`
- Output:
  - `trackedRegions` → region actions
  - `sceneActions` → cut/full-frame actions

## 4.3 Fallback policy

Fallback to full-frame for any of:
- detector model missing/invalid
- runtime inference failure
- category configured without region support
- region explosion over cap (`maxConcurrentRegions`)
- low-confidence or unstable tracks below temporal gate

---

## 5) Data Contract Changes

## 5.1 Content category defaults

Update built-in visual categories to explicitly indicate region capabilities.

For `nsfw` default category:
- set `supportsRegions: true`
- prefer region action default (`blurRegion`) for region-capable mode
- preserve `blurFullFrame` as fallback action

## 5.2 Detection metadata standardization

For region detections, always include:

```json
{
  "visualContentCategory": "nudity",
  "action": "blurRegion",
  "boundingBox": {
    "x": 0.12,
    "y": 0.21,
    "width": 0.25,
    "height": 0.31
  },
  "confidenceSource": "region_temporal_aggregator"
}
```

All coordinates normalized `[0,1]` and clamped.

## 5.3 Analysis checkpoint version

Bump `AnalysisService.pipelineVersion` and include detector configuration hash:
- detector model id + sha
- detector threshold config
- region aggregation config

Reject resume if incompatible.

---

## 6) Implementation Phases

## Phase 0 — Contracts & Safety Policy Freeze

Deliverables:
- Final detector label map and category mapping table.
- Region fallback policy decision table.
- KPI/SLO gates and rollout ownership.

Exit gate:
- Signed-off contract and safety policy document.

---

## Phase 1 — Model Registry & Provenance

Files:
- `lib/services/huggingface_model_registry.dart`
- `lib/data/models/huggingface_model.dart`
- `lib/services/model_manager_service.dart`

Tasks:
1. Add region detector model entries (id, file path, size, accuracy, type).
2. Implement `getNudeNetModels()` and/or dedicated detector model type.
3. Add approved manifest/spec with SHA256 and license checks.
4. Ensure model manager downloads nested ONNX files and verifies checksums.

Exit gate:
- Detector model can be discovered, downloaded, validated, and loaded.

---

## Phase 2 — ONNX Detection Runtime (real, non-simulated)

Files:
- `lib/native/bindings/onnx_bindings.dart`
- optional: `lib/services/<new detection service>.dart`

Tasks:
1. Replace `runDetectionInference` simulation path with actual ONNX output decode.
2. Add model-specific decoder(s) for detection tensor formats.
3. Apply confidence filtering and NMS in deterministic order.
4. Return `DetectionResult` with stable, normalized boxes.
5. Add robust error surfaces (`ONNXInferenceException`) and provider fallback.

Exit gate:
- Golden inference fixtures produce deterministic box outputs.

---

## Phase 3 — Analysis Pipeline Wiring

Files:
- `lib/services/analysis_service.dart`
- `lib/services/nsfw_onnx_service.dart` (keep classifier path)

Tasks:
1. During visual analysis, run both:
   - classifier batch (`nsfwOnnx.runBatchInference`)
   - detector per-frame/batch (new detection service)
2. Populate each `FrameAnalysisResult.visualContent` with `detectedRegions`.
3. Remove `VisualContentResult.safe()` placeholder assignment in visual loop.
4. Build visual detections from region aggregation output:
   - region tracks -> detection items with bounding boxes
   - scene actions -> full-frame or cut detections
5. Keep classifier-only fallback path operational.

Exit gate:
- Production analysis emits region metadata when detector available.

---

## Phase 4 — Region Aggregation to Remediation Actions

Files:
- `lib/services/region_temporal_aggregator.dart` (if needed adjustments)
- `lib/state/providers/analysis_provider.dart`
- `lib/services/export_service.dart`

Tasks:
1. Convert `TrackedRegion` keyframes into `EditAction`/`Modification` region ops.
2. Ensure action routing respects category action:
   - `blurRegion`, `pixelateRegion`, `blackBoxRegion`
   - scene-level `cutScene` / full-frame blur fallback
3. Maintain region cap and fallback to full-frame under saturation.

Exit gate:
- Export pipeline receives valid region modifications and renders correctly.

---

## Phase 5 — Settings, Migration, and UX Consistency

Files:
- `lib/data/models/content_category_defaults.dart`
- `lib/data/models/analysis_settings_migration.dart`
- `lib/presentation/screens/analysis_settings/content_detection_tab.dart`

Tasks:
1. Migrate existing settings to region-capable defaults without breaking legacy projects.
2. Add/confirm UI affordances for region support and action compatibility.
3. Keep backward compatibility for projects created before region rollout.

Exit gate:
- Old settings load correctly; no user-facing config regressions.

---

## Phase 6 — Testing and Quality Gates

Add/update tests:

### Unit
- detector decoder correctness
- NMS/filtering determinism
- region metadata schema generation
- migration behavior

### Service/Integration
- `analysis_service` visual run creates region detections
- region fallback behavior on detector failure
- region cap conversion to scene-level action

### Existing suites to extend
- `test/services/region_temporal_aggregator_test.dart`
- `test/integration/visual_analysis_e2e_test.dart`

### Performance/stability gates
- warm detector inference p95 budget
- no unbounded memory growth in long video runs
- checkpoint resume consistency

Exit gate:
- Quality gates pass in CI and Windows debug/release runs.

---

## Phase 7 — Rollout Strategy

Feature flag states:
- `off` -> `shadow` -> `canary` -> `enforce`

Rollout controls:
- per-model kill switch
- automatic fallback to full-frame on detector health degradation
- telemetry alerting on inference failures and latency spikes

Promotion requirements:
- safety KPI pass
- perf KPI pass
- no critical crash or export correctness regressions

---

## 7) PR Slicing (Recommended Execution Order)

1. **PR-1 Contracts + models**
   - registry/model types/manifest/checksum
2. **PR-2 ONNX detection runtime**
   - real detector output parsing + tests
3. **PR-3 Analysis wiring**
   - populate `visualContent.detectedRegions`
   - invoke `RegionTemporalAggregator` in production flow
4. **PR-4 Detection/remediation mapping**
   - metadata bounding boxes + action generation
5. **PR-5 Settings migration + UI alignment**
6. **PR-6 Perf + rollout controls + docs finalization**

Each PR must be independently shippable with fallback to full-frame.

---

## 8) Risks and Mitigations

1. **Model output format mismatch**
   - Mitigation: strict model spec + shape assertions + decoder tests.

2. **High false positives in detector boxes**
   - Mitigation: confidence threshold tuning + temporal persistence gate + classifier confirmation for `both` categories.

3. **Performance regression on long videos**
   - Mitigation: micro-batching, frame-rate controls, region cap fallback, telemetry-driven tuning.

4. **Inconsistent behavior between analysis and export**
   - Mitigation: canonical region metadata schema + E2E tests from detection to export output.

5. **Migration regressions for existing users**
   - Mitigation: schema-version migration tests and compatibility mapping.

---

## 9) Acceptance Criteria (Definition of Done)

Integration is complete when all are true:

1. NSFW analysis produces region detections (with bounding boxes) on region-capable content.
2. Detection review UI displays region overlays from production data.
3. Export applies region-level modifications in the correct frame areas.
4. Full-frame fallback still works and triggers automatically on detector/path failures.
5. Existing non-region projects/settings remain functional without manual intervention.
6. CI tests and performance gates pass.

---

## 10) Immediate Next Step (execution kickoff)

Start with **PR-1 (contracts + model plumbing)**, because the rest of integration depends on stable detector model identity and validation.

PR-1 task checklist:
- Add detector model entries to registry.
- Add model type + visual model classification helpers.
- Add manifest/spec + checksum verification hooks.
- Add tests for registry and model-manager path resolution.

---

## 11) Notes on Model Selection

The currently configured NSFW ViT model is an image-classification model and should remain as a global confidence signal. Region detection must come from a dedicated detection model and cannot be inferred from current 5-class logits alone.
