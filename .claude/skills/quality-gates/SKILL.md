---
name: quality-gates
description: Run the full local quality gate sequence for this repo (format, codegen freshness, analyze, tests, coverage floor) and fix anything that fails before committing.
---

# Quality gates

Run these from the repo root, in order. Fix failures at each step before moving on — never skip a gate or weaken a check to get past it.

1. **Format** — `dart format lib test integration_test scripts` (the PostToolUse hook formats files you edit, but run this to catch stragglers).
2. **Codegen freshness** — `dart run build_runner build --delete-conflicting-outputs`, then `git status --porcelain -- "*.g.dart" "*.freezed.dart"`. Any diff means generated files were stale: commit the regenerated output with your change.
3. **Analyze** — `flutter analyze --fatal-infos`. Zero issues.
4. **Tests** — `flutter test`. For detection/export/pipeline changes also run the relevant `test/integration/` files explicitly.
5. **Coverage floor** (once Phase 0 of the revamp checklist lands) — `flutter test --coverage` then `dart run scripts/check_coverage.dart`. If you added code, add tests; never lower the floor.
6. **Legacy grep gate** (during/after Phase 2 of the revamp) — `grep -riE "nudenet|legacy_nsfw|onnxruntime|nsfw_onnx|modesty_analysis|onnx_bindings" lib test docs windows scripts README.md` must return zero hits outside `docs/implement/revamp-*.md`.

Report the outcome of every gate honestly, including which ones you had to fix and how.
