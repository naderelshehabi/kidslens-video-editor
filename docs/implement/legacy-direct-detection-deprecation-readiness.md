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
