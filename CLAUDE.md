# KidsLens Video Editor — Agent Instructions

Local-only Flutter **Windows desktop** app that detects unsuitable content in videos with a local VLM (llama.cpp + Qwen3-VL GGUF) and helps the user blur, box, or cut it. MIT-licensed. Nothing ever leaves the user's machine.

## Current mission

The repo is mid-revamp. The authoritative plan is `docs/implement/revamp-plan.md` (decisions D1–D10, binding appendices) and the work queue is `docs/implement/revamp-checklist.md`. **Work the checklist in phase order; check boxes with commit references as you complete tasks.** Do not resurrect anything listed in the plan's Appendix G (superseded documents) or reintroduce the legacy ONNX/NudeNet pipeline in any form.

## Hard invariants (never weaken)

1. **Local-only inference**: model servers bind `127.0.0.1` only; hosted endpoints are rejected; no API keys in project files. Enforced by `LocalRuntimeEndpointPolicy` — keep its tests passing.
2. **Official model sources only**: bundles come from official provider repos with pinned revision + SHA-256 (plan Appendix C). Community ports are never selectable. NudeNet (AGPL) and LocateAnything (non-commercial) are permanently rejected.
3. **Evidence-first detection**: providers emit `EvidenceRecord`s; only `PolicyEngine` + `TemporalFusion` produce `Detection`s. Don't shortcut providers directly into detections.
4. **Fail-visible**: detection never silently degrades or switches pipelines. Unavailability surfaces as `DetectionAvailability` with an actionable reason.
5. **Taxonomy/policy changes** (categories, default actions, thresholds, enforcement) require a Policy Review Record (plan Appendix E) in the PR description. New model bundles require a Model Approval Record (Appendix D).
6. **Unsafe evaluation clips are never committed** — only aggregate reports under `docs/implement/validation-reports/`.

## Commands

```powershell
flutter pub get
dart run build_runner build --delete-conflicting-outputs   # after touching freezed/riverpod/json annotated files
flutter analyze --fatal-infos
flutter test                                               # unit + widget
flutter test --coverage                                    # coverage/lcov.info
flutter test integration_test                              # e2e (needs a Windows desktop session)
flutter build windows                                      # also builds whisper_wrapper via CMake
scripts\build_windows_vs2022.ps1 -Configuration Release    # full VS build + install target
node test\opencode\block_generated_files.test.mjs          # smoke test for .opencode/plugins hook logic
```

## Architecture map

- `lib/services/detection/` — VSS pipeline: `vss_family_safety_pipeline.dart` (orchestrator), `chunk_planner.dart`, `vlm_provider.dart` (`OpenAiCompatVlmProvider` → llama-server), `family_safety_prompt_templates.dart` (prompts + JSON schema — a binding contract, see plan Appendix B), `policy_engine.dart`, `temporal_fusion.dart`, `grounding_provider.dart`, `llama_server_manager.dart`, `runtime_binary_manager.dart` (pinned llama.cpp b9628), `local_runtime_manager.dart` (GPU discovery, RTX gate), `local_search_index.dart`.
- `lib/services/` — `analysis_service.dart` (stage host: probe/ASR/speech safety), `export_service.dart` (FFmpeg filtergraph compiler), `asr_service.dart` (whisper.cpp FFI via isolate), `profanity_service.dart` (being modernized per checklist Phase 4: lexical candidate tier + `SpeechPolicyAnalyzer` LLM judge on the same llama-server), `frame_sampling_service.dart`.
- `lib/data/models/` — freezed models; `family_safety_policy.dart` (11-category taxonomy), `model_bundle_manifest.dart` (bundle catalog), `evidence_record.dart`, `grounded_region.dart`, `policy_finding.dart`.
- `lib/state/providers/` — Riverpod (generated); `lib/jobs/` — job system with cancellation + checkpoints.
- `lib/presentation/` — `screens/editor_screen.dart`, `widgets/editor/{timeline_panel,preview_panel,detection_panel}.dart`, `screens/analysis_settings/` (6 tabs).
- `lib/native/bindings/` — dart:ffi for whisper/MMS; `ffmpeg_bindings.dart` shells out to bundled FFmpeg CLI (not FFI).
- `native/` — whisper.cpp built from source via CMake (`flutter build windows` triggers it); FFmpeg prebuilt binaries.
- Media playback is `media_kit`; thumbnails/probe/export go through the FFmpeg CLI.

## Conventions

- Never hand-edit `*.g.dart` / `*.freezed.dart` (a hook blocks this) — edit the source and rerun build_runner; commit generated output.
  - **opencode** (this repo's primary harness): the blocker is `.opencode/plugins/block_generated_files.js` (`tool.execute.before` hook), and auto-formatting of `.dart` files is enabled via the built-in `dart` formatter in `opencode.json`. The node smoke test at `test/opencode/block_generated_files.test.mjs` exercises the hook's regex/iopath logic and is wired into CI.
  - **Claude Code** (cross-tool portability): `.claude/settings.json` carries PreToolUse + PostToolUse PowerShell hooks mirroring the same logic; keep both files in sync if you touch either.
- Riverpod codegen style (`@riverpod`), freezed for models, `Result`/typed exceptions from `lib/core/`.
- Tests mirror `lib/` structure under `test/`; process boundaries (FFmpeg, llama-server) are faked, not mocked ad hoc — see `test/support/` once Phase 8 lands.
- Keep files under ~800 lines; the editor/timeline god-widgets are being decomposed (checklist 6.1) — don't grow them further.
- ASR catalog is being curated to two multilingual Whisper models (`whisper-large-v3-turbo` default, `whisper-small` fallback — Decision D12); Meta MMS is removed (D13) — don't reference or re-add either.
- UI text is family-friendly; detection category colors come from `AppTheme.getDetectionColor`.

## Skills

- `/quality-gates` — run the full local gate sequence (format, codegen diff check, analyze, tests) before committing.
- `/implement-next` — pick up the next unchecked task from `docs/implement/revamp-checklist.md` and drive it to done.
