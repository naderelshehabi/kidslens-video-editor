# VSS RTX Validation Reports

Generated Phase 10 reports are written here by:

```bash
dart run scripts/vss_validation_runner.dart \
  --dataset-root /path/to/validation-clips \
  --manifest /path/to/validation-clips/manifest.json \
  --predictions /path/to/validation-clips/predictions.json
```

Use `--analysis-command` instead of `--predictions` when a real local pipeline
harness is available. The command is invoked once per profile and clip and must
emit `EvaluationAnnotation` JSON to stdout. The runner validates clip files,
records latency, schema failures, crashes, peak VRAM samples from `nvidia-smi`,
and adds grounding localization metrics.

Do not commit unsafe validation clips. Commit only reviewed aggregate reports
that are safe to publish.
