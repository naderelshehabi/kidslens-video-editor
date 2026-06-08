# Model Approval Record Template

Use this record before adding any model bundle to the KidsLens local family-safety pipeline.

## Summary

- Model ID:
- Provider / organization:
- Model role:
  - Main VLM
  - Grounding provider
  - Embedding provider
  - Auxiliary classifier/detector
- Proposed pipeline profile:
- Reviewer:
- Review date:
- Decision:
  - Approved candidate
  - R&D only
  - Rejected
  - Pending more evidence

## Source And License

- Official source repository:
- Official revision / commit:
- License name:
- License URL:
- Terms acceptance required:
- Commercial app use permitted:
- Redistribution permitted:
- Derivative / quantized artifact permitted:
- Output ownership restrictions:
- Trademark / attribution requirements:
- Legal review owner:
- Legal review notes:

## Local-Only Compliance

- Inference runs locally:
- Hosted API dependency:
- Inference transport:
  - In-process native runtime
  - Local helper process
  - Local loopback server
- Non-loopback endpoints rejected:
- Model files available without hosted inference:
- Evidence/prompts/frames remain local:

## Model Artifact

- Artifact type:
  - Official weights
  - Official quantized artifact
  - KidsLens-owned converted artifact
- Artifact URI:
- SHA256:
- File list pinned:
- Conversion recipe ID:
- Conversion recipe source:
- Conversion starts from official weights:
- Converted artifact published to KidsLens-owned Hugging Face repo or release bucket:
- Source revision linked to converted artifact:

## Hardware Fit

- Target GPU profile: `rtx_5070_12gb`
- Precision / quantization:
- Minimum VRAM:
- Recommended VRAM:
- Peak VRAM measured:
- CPU offload required:
- Sustained CPU offload rejected:
- p50 chunk latency:
- p95 chunk latency:
- Failure rate:
- Output-schema validity rate:

## Capabilities

- Supports video input:
- Supports image input:
- Supports bounding boxes:
- Supports masks:
- Supports point localization:
- Supports timestamps:
- Max frames per chunk:
- Max context tokens:
- Recommended chunk seconds:
- Known failure modes:

## Safety Validation

- Validation dataset version:
- Explicit nudity recall:
- Gore/blood recall:
- High-severity violence recall:
- Immodest clothing review recall:
- False positive rate:
- Review burden:
- Temporal IoU:
- Box/mask IoU:
- Explanation completeness:

## Final Decision

- Approved status:
- Blocking issues:
- Follow-up requirements:
- Expiration / re-review date:

