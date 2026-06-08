# Official Model Source and Porting Plan

Date: 2026-06-08

Scope: local-only family-safety detection models for the `vss_family_safety_v1`
pipeline. Production candidates must come from official major-provider
repositories or from KidsLens-owned converted artifacts that are reproducible
from official weights. Community ports are not selectable.

## Source Table

| Model | Provider | Role | Official source | License | Commercial use | RTX 5070 status |
| --- | --- | --- | --- | --- | --- | --- |
| Cosmos Reason1 7B | NVIDIA | Primary video reasoning VLM candidate | `nvidia/Cosmos-Reason1-7B` | NVIDIA Open Model License, with Apache 2.0 information on the card | Allowed by the model card, subject to NVIDIA terms | Evaluation only; likely needs reduced frames or KidsLens quantization |
| Nemotron Nano 12B v2 VL FP8 | NVIDIA | Image/text VLM candidate | `nvidia/NVIDIA-Nemotron-Nano-12B-v2-VL-FP8` | NVIDIA Open Model License | Allowed, subject to NVIDIA terms | Evaluation only; tight 12 GB fit |
| Qwen3.5 4B | Alibaba/Qwen | Primary lightweight VLM candidate | `Qwen/Qwen3.5-4B` | Apache 2.0 | Allowed | Evaluation only; preferred Qwen fit target |
| Qwen3.5 2B | Alibaba/Qwen | Lightweight fallback VLM candidate | `Qwen/Qwen3.5-2B` | Apache 2.0 | Allowed | Evaluation only; quality gate required |
| Qwen3 Embedding 0.6B | Alibaba/Qwen | Local search embeddings | `Qwen/Qwen3-Embedding-0.6B` | Apache 2.0 | Allowed | Evaluation only; small local retrieval model |
| Gemma 4 E4B IT | Google | Primary Gemma VLM candidate | `google/gemma-4-E4B-it` | Apache 2.0 | Allowed | Evaluation only; preferred Gemma fit target |
| Gemma 4 12B IT | Google | Higher-capability Gemma candidate | `google/gemma-4-12B-it` | Apache 2.0 | Allowed | Evaluation only as a KidsLens 4-bit/tight profile |
| Phi-4 Multimodal Instruct | Microsoft | Lightweight multimodal VLM candidate | `microsoft/Phi-4-multimodal-instruct` | MIT | Allowed | Evaluation only |
| Phi-4 Multimodal Instruct ONNX | Microsoft | Windows ONNX deployment candidate | `microsoft/Phi-4-multimodal-instruct-onnx` | MIT | Allowed | Evaluation only; DirectML/CUDA operator validation required |
| Llama 4 Scout 17B-16E Instruct | Meta | Meta VLM candidate | `meta-llama/Llama-4-Scout-17B-16E-Instruct` | Llama 4 Community License | Allowed with Meta terms, acceptable-use duties, and scale threshold review | Not default-selectable until a 12 GB fit is proven |
| Llama 4 Scout 17B-16E Instruct FP8 | NVIDIA / Meta-derived | R&D reference artifact | `nvidia/Llama-4-Scout-17B-16E-Instruct-FP8` | NVIDIA Open Model License plus upstream Llama term review | Legal review required before production | Watchlist only |
| LocateAnything 3B | NVIDIA | Optional grounding evaluation | `nvidia/LocateAnything-3B` | NVIDIA non-commercial license | Blocked for commercial production under current terms | Optional evaluation only; disabled by default |

## Porting Rules

- Start from the exact official source revision and file list.
- Record the upstream license, model card URL, revision, conversion recipe,
  runtime, target GPU profile, and expected quantization.
- Convert only in a controlled KidsLens build pipeline.
- Publish converted artifacts to a KidsLens-owned Hugging Face repo or release
  bucket with provenance metadata and SHA-256 checksums.
- Validate on the RTX 5070 12 GB target with configured chunk length, frame
  count, resolution, max output tokens, and second-pass settings.
- Reject artifacts that require sustained CPU offload during normal analysis.
- Keep converted artifacts disabled until checksum, license review, runtime
  validation, and KidsLens evaluation gates all pass.

## Runtime Download Automation

The app can download official model bundles directly from Hugging Face at
runtime when the manifest uses an `hf://owner/repo` artifact URI.

Runtime download rules:

- Resolve files only from `officialSourceRepo` and `officialRevision`.
- Use Hugging Face repository metadata and file downloads, not hosted inference.
- Allow only approved official organizations from the manifest governance list.
- Reject community ports and non-`hf://` official-download requests.
- Reject blocked or non-commercial bundles such as LocateAnything for
  commercial production builds.
- Require terms acceptance before downloading gated bundles such as Meta Llama
  profiles.
- Support `HF_TOKEN` or `HUGGINGFACE_TOKEN` from the local process environment
  for private/gated official repos without storing secrets in project files.
- Store downloaded files under the local model cache and write
  `model_bundle_metadata.json` with source repo, revision, artifact URI, license,
  commercial-use state, file list, total bytes, and download timestamp.
- Downloading a bundle does not make it production-selectable. Production
  selection still requires checksum, license, runtime, RTX 5070, and evaluation
  gates.

## LocateAnything Decision

LocateAnything remains useful because it supports open-set object detection,
phrase grounding, dense multi-object detection, and point-style localization.
It is not production selectable today because the current NVIDIA model card
states that commercial use is not permitted. It stays in the manifest as a
blocked, optional grounding evaluation candidate so we can measure whether it
improves boundary quality before seeking a commercial alternative or terms.
