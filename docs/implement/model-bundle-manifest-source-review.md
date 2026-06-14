# Model Bundle Manifest Source Review

Date: 2026-06-07

This review backs the Phase 1 model bundle catalog in
`lib/data/models/model_bundle_manifest.dart`.

## Rules Applied

- Inference must be local-only.
- Production selection requires an official source repo, a local/downloadable
  artifact URI, a 64-character SHA-256 checksum, commercial-use approval, and
  RTX 5070 12 GB validation.
- Catalog/evaluation entries may exist before checksum and RTX validation, but
  they must not be production-selectable.
- Community ports, unofficial quantizations, hosted inference endpoints, and
  non-commercial-only models are blocked from production.

## Source And License Review

| Manifest ID | Official source | License review | Commercial status | Manifest status |
| --- | --- | --- | --- | --- |
| `nvidia_cosmos_reason1_7b` | `nvidia/Cosmos-Reason1-7B` | NVIDIA Open Model License; model card states commercial use is allowed. | Superseded by Cosmos Reason2 for future evaluation. | Evaluation only |
| `nvidia_cosmos_reason2_8b` | `nvidia/Cosmos-Reason2-8B` | NVIDIA Open Model License; commercial use allowed per model card review. | Watchlist only until a KidsLens-owned <=12 GB quantized artifact exists and runtime validation passes. | Watchlist |
| `nvidia_nemotron_nano_12b_v2_vl_fp8` | `nvidia/NVIDIA-Nemotron-Nano-12B-v2-VL-FP8` | NVIDIA Open Model License. | FP8 artifact exceeds the RTX 5070 12 GB target; NVFP4-QAD path requires TensorRT-LLM/vLLM and is not available for the Windows desktop runtime direction. | Watchlist |
| `kidslens_nemotron_nano_12b_v2_vl_int4` | Derived from `nvidia/NVIDIA-Nemotron-Nano-12B-v2-VL-FP8` | Must inherit NVIDIA Open Model License obligations and use a committed conversion recipe. | Allowed only after reproducible KidsLens artifact, checksum, and RTX 5070 validation. | Evaluation only |
| `qwen_3_5_4b` | `Qwen/Qwen3.5-4B` | Apache 2.0. | Allowed after checksum and RTX 5070 validation. | Evaluation only |
| `qwen_3_5_2b` | `Qwen/Qwen3.5-2B` | Apache 2.0. | Allowed after checksum, quality review, and RTX 5070 validation. | Evaluation only |
| `qwen3_vl_8b_instruct_gguf_q4km` | `Qwen/Qwen3-VL-8B-Instruct-GGUF` | Apache 2.0. | Primary v2 GGUF candidate; not production-selectable until per-file checksums and RTX 5070 validation are recorded. | Evaluation only |
| `qwen3_vl_4b_instruct_gguf_q4km` | `Qwen/Qwen3-VL-4B-Instruct-GGUF` | Apache 2.0. | Lightweight v2 GGUF candidate; not production-selectable until per-file checksums and RTX 5070 validation are recorded. | Evaluation only |
| `qwen3_embedding_0_6b_gguf_q8` | `Qwen/Qwen3-Embedding-0.6B-GGUF` | Apache 2.0. | Text-evidence search embedding candidate; not production-selectable until checksum and local smoke validation are recorded. | Evaluation only |
| `google_gemma_4_e4b_it` | `google/gemma-4-E4B-it` | Apache 2.0. | Allowed after checksum and RTX 5070 validation. | Evaluation only |
| `google_gemma_4_12b_it_int4` | Derived from `google/gemma-4-12B-it` | Apache 2.0. | Allowed only after reproducible KidsLens 4-bit artifact, checksum, and RTX 5070 validation. | Evaluation only |
| `microsoft_phi_4_multimodal_instruct` | `microsoft/Phi-4-multimodal-instruct` | MIT. | Allowed after checksum and runtime validation. | Evaluation only |
| `microsoft_phi_4_multimodal_instruct_onnx` | `microsoft/Phi-4-multimodal-instruct-onnx` | MIT. | Allowed after checksum and DirectML/ONNX validation. | Evaluation only |
| `meta_llama_4_scout_17b_16e_instruct` | `meta-llama/Llama-4-Scout-17B-16E-Instruct` | Llama 4 Community License. | Blocked for this target: 109B-total MoE cannot fit a 12 GB consumer GPU. | Blocked |
| `nvidia_llama_4_scout_17b_16e_instruct_fp8` | `nvidia/Llama-4-Scout-17B-16E-Instruct-FP8` | NVIDIA Open Model License plus upstream Llama 4 obligation review. | Blocked for this target: even FP8 estimates are far above the RTX 5070 12 GB budget. | Blocked |
| `nvidia_locateanything_3b` | `nvidia/LocateAnything-3B` | NVIDIA non-commercial license. | Commercial production blocked. | Blocked |
| `mistral_pixtral_12b_watchlist` | `mistralai/Pixtral-12B` | Requires separate license and RTX 5070 review. | Review required. | Watchlist |

## Leaderboards Reviewed

These sources are recorded as reviewed in the manifest catalog:

- Open VLM Leaderboard
- Vision Arena
- MMBench Leaderboard
- SEED-Bench Leaderboard
- Retrieval/document leaderboards for future embedding/OCR-heavy models

## Production Selection Status

No model is production-selectable in Phase 1. This is intentional: production
selection is blocked until a bundle has a verified checksum, a committed
conversion recipe when applicable, and RTX 5070 validation evidence.

## 2026-06-12 VSS v2 Corrections

- `Qwen/Qwen3-VL-8B-Instruct-GGUF`,
  `Qwen/Qwen3-VL-4B-Instruct-GGUF`, and
  `Qwen/Qwen3-Embedding-0.6B-GGUF` are the v2 runtime targets because they are
  official Qwen-published GGUF artifacts, Apache-2.0, and compatible with the
  llama.cpp server direction. They are added in Phase 1 with explicit per-file
  artifact metadata.
- `nvidia/Cosmos-Reason2-8B` supersedes `nvidia/Cosmos-Reason1-7B` for future
  NVIDIA VLM evaluation, but remains watchlist-only until an official or
  KidsLens-owned quantized artifact fits the 12 GB target.
- `nvidia/NVIDIA-Nemotron-Nano-12B-v2-VL-FP8` is demoted to watchlist because
  the FP8 artifact is too large for the RTX 5070 12 GB target. The smaller
  NVFP4-QAD direction depends on TensorRT-LLM/vLLM, which the v2 plan excludes
  for Windows desktop shipping.
- Llama 4 Scout entries are blocked for this target rather than evaluated:
  109B-total MoE sizing is incompatible with the 12 GB consumer GPU target.
- `nvidia/LocateAnything-3B` remains optional/blocked for commercial builds
  because its license is non-commercial.

## 2026-06-14 Runtime Binary Pin

Phase 2 pins official llama.cpp release `b9628` for Windows desktop local
inference. The runtime downloader verifies each zip independently before
extraction and records provenance metadata under the app support runtime cache.

| Runtime | Official asset | Size | SHA-256 |
| --- | --- | ---: | --- |
| CUDA llama.cpp | `llama-b9628-bin-win-cuda-13.3-x64.zip` | 159,018,881 | `3762ce9bcdadf3ba3bafd98f5dc5addc2520c9f94b672d91086496934ddb4c1e` |
| CUDA runtime DLLs | `cudart-llama-bin-win-cuda-13.3-x64.zip` | 390,970,417 | `1462a050eb4c684921ba51dcc4cc488a036674c3e73e9945ee705b854808d03e` |
| Vulkan llama.cpp | `llama-b9628-bin-win-vulkan-x64.zip` | 38,546,148 | `0545d862acf0940288a13cd4eb1e9c995fb0c42db86d011eabc54fd886cd044e` |

## Sources

- NVIDIA Cosmos Reason1 7B Hugging Face model card:
  https://huggingface.co/nvidia/Cosmos-Reason1-7B
- NVIDIA Cosmos Reason2 8B Hugging Face model card:
  https://huggingface.co/nvidia/Cosmos-Reason2-8B
- NVIDIA Nemotron Nano 12B v2 VL FP8 Hugging Face model card:
  https://huggingface.co/nvidia/NVIDIA-Nemotron-Nano-12B-v2-VL-FP8
- Qwen3 VL 8B Instruct GGUF Hugging Face model card:
  https://huggingface.co/Qwen/Qwen3-VL-8B-Instruct-GGUF
- Qwen3 VL 4B Instruct GGUF Hugging Face model card:
  https://huggingface.co/Qwen/Qwen3-VL-4B-Instruct-GGUF
- Qwen3 Embedding 0.6B GGUF Hugging Face model card:
  https://huggingface.co/Qwen/Qwen3-Embedding-0.6B-GGUF
- Qwen 3.5 4B license:
  https://huggingface.co/Qwen/Qwen3.5-4B/blame/851bf6e806efd8d0a36b00ddf55e13ccb7b8cd0a/LICENSE
- Qwen 3.5 2B license:
  https://huggingface.co/Qwen/Qwen3.5-2B/blob/main/LICENSE
- Google Gemma 4 E4B IT Hugging Face model card:
  https://huggingface.co/google/gemma-4-E4B-it
- Google Gemma 4 12B IT Hugging Face model card:
  https://huggingface.co/google/gemma-4-12B-it
- Microsoft Phi-4 multimodal instruct Hugging Face model card:
  https://huggingface.co/microsoft/Phi-4-multimodal-instruct
- Microsoft Phi-4 multimodal instruct ONNX Hugging Face model card:
  https://huggingface.co/microsoft/Phi-4-multimodal-instruct-onnx
- Meta Llama 4 Scout Hugging Face model card:
  https://huggingface.co/meta-llama/Llama-4-Scout-17B-16E-Instruct
- NVIDIA Llama 4 Scout FP8 Hugging Face model card:
  https://huggingface.co/nvidia/Llama-4-Scout-17B-16E-Instruct-FP8
- NVIDIA LocateAnything 3B Hugging Face model card:
  https://huggingface.co/nvidia/LocateAnything-3B
- llama.cpp b9628 GitHub release:
  https://github.com/ggml-org/llama.cpp/releases/tag/b9628
- llama.cpp b9628 GitHub release API metadata:
  https://api.github.com/repos/ggml-org/llama.cpp/releases/tags/b9628
