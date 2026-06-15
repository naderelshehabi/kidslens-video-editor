# Legacy Direct-Detection Deprecation Readiness

Phase 17 does not remove the legacy NSFW/NudeNet/modesty-parser code paths. It
separates legacy direct detections from auxiliary evidence so the VSS family
safety pipeline can use legacy signals for comparison, grounding, and fallback
without promoting legacy-only scores as the new default output.

## Required Compatibility

- Legacy NSFW classifier remains available as auxiliary evidence.
- NudeNet remains available as an auxiliary grounding provider.
- Modesty parser remains available as an auxiliary grounding provider when it
improves measured recall or review quality.
- Existing projects and checkpoints can still run the legacy direct-detection
profile.
- Old evidence and analysis results remain readable through replay and model
JSON compatibility.
- Export/remediation behavior continues to accept policy findings and replayed
legacy detections.

## NudeNet AGPL Motivation

NudeNet remains auxiliary because its code is AGPL-3.0 and the current app is
MIT. Until legal approves the exact distribution and invocation model, NudeNet
weights must not be bundled into commercial/release installers and NudeNet must
not be the required default grounding path. The VSS pipeline keeps NudeNet as a
local auxiliary comparison source during development so Phase 10 can measure
whether Qwen3-VL native grounded regions reach parity on labeled frames. The
demotion gate is the Phase 10 "VLM grounding vs NudeNet regions" report: VLM
native regions, NudeNet auxiliary regions, and VLM+aux fused regions are compared
with box IoU, localization recall, and missed-localization cases before NudeNet
can be disabled or removed.

## Default Pipeline Rule

The VSS default policy uses `PolicyEngineOptions.vssDefault()`, which sets
legacy evidence to `auxiliaryOnly`. `PolicyEngine.forPipeline()` selects that
policy for `vss_family_safety_v1` and keeps direct legacy behavior for
`legacy_nsfw_region_v8`. In auxiliary-only mode:

- legacy NSFW scores are retained for safe-window agreement checks;
- raw legacy NSFW scores are not promoted to policy findings;
- raw NudeNet and raw modesty-parser records are not promoted to policy
  findings;
- grounded-region records, including records produced by auxiliary grounding
  providers, can still support user-visible findings with boundaries.

The legacy direct-detection profile keeps the previous behavior with
`LegacyEvidencePolicy.directDetection` for existing projects.

## Deprecation Gate

Legacy direct detection can be deprecated only when
`LegacyDeprecationReadinessChecker` reports all criteria passing:

- default VSS evaluation beats legacy according to the Phase 15 gate;
- the measured stability window is satisfied;
- old analysis results remain readable;
- export and remediation compatibility is verified;
- legacy NSFW remains auxiliary evidence;
- NudeNet remains auxiliary grounding;
- modesty parser remains auxiliary grounding;
- the default profile uses auxiliary-only legacy evidence.

The default stability window is 30 days. Until that measured window is met,
legacy direct detection must remain selectable and cannot be removed.
