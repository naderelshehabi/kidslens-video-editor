# Family Safety Evaluation Dataset

This document describes the local-only evaluation fixture manifest implemented in `EvaluationDataset.familySafetyV1Smoke`.

## Dataset

- ID: `kidslens_family_safety_v1_smoke`
- Version: `2026-06-08`
- Media paths are relative fixture references. The evaluation runner only requires the manifest and pipeline detections; real media files can be attached later without changing metric semantics.

## Required Coverage

The smoke manifest includes:

- Safe controls: `safe_kitchen_001`, `ambiguous_sports_contact_001`
- Category positives: nudity/immodest clothing, violence, blood, weapons, gore
- Ambiguous/boundary examples: sports contact that should remain safe
- Low-light/motion blur: `violence_shadow_001`
- Short unsafe flash: `blood_flash_001`
- Long-video temporal context: `weapon_context_001`
- Immodest female clothing: `nudity_beach_legs_001`
- Bounding-box ground truth: exposed legs, blood flash, weapon context

## Metrics

`EvaluationRunner` computes:

- recall
- precision
- false negative rate
- false positive rate on safe-control clips
- temporal IoU
- box IoU
- mask IoU when mask hints are provided
- review burden per hour
- explanation completeness
- chunk latency p50/p95
- peak memory and VRAM usage

## Profile Comparison

The runner compares:

- `legacy_only`
- `vlm_only`
- `vlm_plus_legacy_evidence`
- `vlm_plus_grounding`
- runtime-specific profiles when predictions are supplied with runtime IDs

The default profile must beat legacy recall while staying under false-positive and review-burden thresholds. Category gates are stricter for explicit nudity, gore/blood, and high-severity violence.
