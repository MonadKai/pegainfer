# Qwen3.5 text-only prefix-cache-off vs vLLM on y108p62

> **TL;DR:** Confirmed 2026-10-26 replay of the aligned text-only `/v1/completions` load: Qwen3.5-2B/4B/9B, prefix cache off, frozen 256→64, `max_num_batched_tokens=2048`, conc 1/2/4/8/10/12/16/32, 48/48 rungs. Low-conc pegainfer TTFT is shorter; TPOT is tied; high-conc Gen crosses to vLLM (2B ~c16, 4B ~c12 TTFT / c32 Gen, 9B ~c8). Repeat vs 2026-10-15 is within ~1% Gen. `run_class=load`, not a capacity winner.

Authoritative numbers: this doc and the sibling `qwen35-text-cacheoff-vllm-vs-pegainfer-y108p62.json`. Host-local raw logs (not in git): `/tmp/y108p62-qwen35-text-b2048-20261026/`. This snapshot is archive-lane: it lives under `docs/fork/`, is not registered in upstream `docs/index.md`, and is not for a PR to `pegainfer-project/pegainfer`.

## Scheme

Same-GPU sequential A/B. Three models in parallel on GPU0/1/2; each model runs pegainfer then vLLM on that GPU. Ports `[38000,39000)` (this run: 38502/38504/38509). No global `CUDA_VISIBLE_DEVICES`; pegainfer `--device-ordinal`, vLLM `--gpus device=N`.

### Pins

| Item | Value |
| --- | --- |
| Host | y108p62, 8× RTX 5090 32 GiB |
| pegainfer | commit `da39fbc8`, native `--release` + `qwen35` |
| vLLM | `vllm/vllm-openai:v0.29.0` digest `sha256:082ca6f035279109041ffd3fe0695cb568b29bc580b35c4f297a66a08b216c1b` |
| Weights | SeaweedFS `…/ms-mirrors/Qwen3.5-{2B,4B,9B}/release.20260304` |
| Client | `/v1/completions` integer token ids, seed 42, warmup 16 discarded (ids disjoint from scored), 64 scored |
| Shape | input 256, output 64, `temperature=0`, `ignore_eos` |
| Concurrency | 1, 2, 4, 8, 10, 12, 16, 32 |
| pegainfer argv | `--no-prefix-cache --max-batch 64 --max-prefill-tokens 2048` |
| vLLM argv | `--language-model-only --no-enable-prefix-caching --max-model-len 8192 --max-num-seqs 64 --max-num-batched-tokens 2048 --max-cudagraph-capture-size 64 --gpu-memory-utilization 0.90 --dtype bfloat16 --trust-remote-code` |

`2048` is vLLM v0.29.0's OpenAI-server default on `<70 GiB` non-A100 GPUs (`EngineArgs.get_batch_defaults`). `max_num_seqs` stays 64 because pegainfer `MAX_DECODE_BATCH=64`; conc≤32 does not bind 64 vs 256.

### Fail-closed

Refuse the rung if any of these fail:

- probe `prompt_tokens=256`, `completion_tokens=8`, `finish=length`
- scored mean input 256.0, mean output 64.0, completed 64/64, finish=length
- warmup fail=0
- vLLM log: `language_model_only=True`, `enable_prefix_caching=False`, `max_num_batched_tokens=2048`, **no** `Multi-modal warmup completed` (registry still prints `MMEncoderAttention`; ignore that)
- pegainfer: `no_prefix_cache` in user-set flags, prefix snapshots 0 slots
- prefix cache hit rate 0.0% on both

Do not use EvalScope chat or random string prompts: Qwen3.5 on stock vLLM takes the VL path and tokenizers drift (~256 vs ~266).

### Isolation and class

- Isolation: same GPU sequential per model. CPU and SeaweedFS FUSE are shared.
- `run_class=load`, single attempt. Not a capacity winner. Not a 3-retest median.

### Replay

The scored matrix is the sibling JSON. The host orchestrator and `bench_completions.py` that produced it lived under `/tmp/y108p62-qwen35-text-b2048-20261026/` and are not a repo asset. Re-running needs that client (httpx streaming `/v1/completions` token ids), the pins above, and the fail-closed checks.

## Alignment

| Item | Status |
| --- | --- |
| Text-only | PASS |
| Prefix cache off | PASS (hit rate 0.0%) |
| Completions token-id prompts | PASS |
| Frozen 256/64 | PASS, 48/48 |
| dtype / TP / spec / quant | PASS: bf16, TP1, none |
| max_batch / max_num_seqs | PASS: 64 |
| batched / prefill tokens | PASS: 2048 |
| KV / max_model_len | NOT ALIGNED. pegainfer fills remainder (2B 19935 MB / 1.70M tok; 4B 11678 MB / 373696; 9B 3428 MB / 109696). vLLM `--max-model-len 8192` (2B 1,596,146 tok 195×; 4B 495,400 60×; 9B 238,861 29×). Workload 320 tokens fits both. |
| max_num_seqs 256 | NOT ALIGNED (left at 64). vLLM OpenAI default on this GPU is 256. |
| gpu_memory_utilization | LEFT at 0.90 (help default 0.92). |
| CUDA graphs / kernels | NOT ALIGNED (implementation). |

## Confirmed results (2026-10-26)

Mean TTFT / TPOT in ms. Gen is scored-window output tok/s. TTFT/TPOT ratio is vLLM/pegainfer (>1 = vLLM slower). Gen ratio is pegainfer/vLLM.

### Qwen3.5-2B

| conc | pega TTFT | vLLM TTFT | TTFT v/p | pega TPOT | vLLM TPOT | TPOT v/p | pega Gen | vLLM Gen | Gen p/v |
| ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: |
| 1 | 9.41 | 38.90 | 4.13 | 3.10 | 3.11 | 1.00 | 312 | 273 | 1.14 |
| 2 | 15.59 | 76.14 | 4.89 | 3.71 | 3.72 | 1.00 | 513 | 412 | 1.25 |
| 4 | 26.89 | 76.44 | 2.84 | 3.81 | 3.83 | 1.00 | 958 | 805 | 1.19 |
| 8 | 47.89 | 78.65 | 1.64 | 4.11 | 3.90 | 0.95 | 1664 | 1574 | 1.06 |
| 10 | 61.94 | 111.43 | 1.80 | 4.27 | 3.99 | 0.93 | 1794 | 1628 | 1.10 |
| 12 | 67.50 | 113.41 | 1.68 | 4.43 | 4.06 | 0.92 | 2019 | 1876 | 1.08 |
| 16 | 87.16 | 120.45 | 1.38 | 4.66 | 4.19 | 0.90 | 2680 | 2653 | 1.01 |
| 32 | 134.72 | 184.12 | 1.37 | 5.79 | 4.34 | 0.75 | 4060 | 4430 | 0.92 |

### Qwen3.5-4B

| conc | pega TTFT | vLLM TTFT | TTFT v/p | pega TPOT | vLLM TPOT | TPOT v/p | pega Gen | vLLM Gen | Gen p/v |
| ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: |
| 1 | 16.31 | 45.62 | 2.80 | 6.04 | 6.02 | 1.00 | 161 | 151 | 1.07 |
| 2 | 28.13 | 91.71 | 3.26 | 6.65 | 6.84 | 1.03 | 286 | 245 | 1.17 |
| 4 | 52.15 | 92.47 | 1.77 | 6.86 | 7.05 | 1.03 | 528 | 477 | 1.11 |
| 8 | 104.56 | 117.16 | 1.12 | 7.21 | 8.01 | 1.11 | 915 | 823 | 1.11 |
| 10 | 121.44 | 125.12 | 1.03 | 7.79 | 8.00 | 1.03 | 972 | 944 | 1.03 |
| 12 | 131.58 | 129.61 | 0.99 | 8.09 | 8.37 | 1.04 | 1094 | 1064 | 1.03 |
| 16 | 169.46 | 152.39 | 0.90 | 8.54 | 9.02 | 1.06 | 1444 | 1415 | 1.02 |
| 32 | 257.62 | 228.50 | 0.89 | 11.89 | 10.65 | 0.90 | 2018 | 2255 | 0.90 |

### Qwen3.5-9B

| conc | pega TTFT | vLLM TTFT | TTFT v/p | pega TPOT | vLLM TPOT | TPOT v/p | pega Gen | vLLM Gen | Gen p/v |
| ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: |
| 1 | 25.79 | 44.40 | 1.72 | 10.52 | 10.41 | 0.99 | 93 | 91 | 1.02 |
| 2 | 46.60 | 91.97 | 1.97 | 11.12 | 11.14 | 1.00 | 171 | 161 | 1.06 |
| 4 | 87.28 | 104.20 | 1.19 | 11.38 | 11.79 | 1.04 | 318 | 302 | 1.05 |
| 8 | 176.04 | 166.03 | 0.94 | 11.77 | 11.68 | 0.99 | 558 | 567 | 0.98 |
| 10 | 203.81 | 168.47 | 0.83 | 12.49 | 12.34 | 0.99 | 600 | 625 | 0.96 |
| 12 | 219.88 | 184.24 | 0.84 | 12.99 | 12.81 | 0.99 | 674 | 702 | 0.96 |
| 16 | 283.72 | 231.76 | 0.82 | 13.70 | 13.64 | 1.00 | 891 | 935 | 0.95 |
| 32 | 427.18 | 388.18 | 0.91 | 19.11 | 16.64 | 0.87 | 1246 | 1412 | 0.88 |

## Repeatability

Same knobs as 2026-10-15. Gen delta vs that run is within ±1% on every shared cell. TTFT/TPOT move by a few milliseconds. The crossover story is the same, so the earlier tables were not a one-off.

## Conclusions

1. **Decode step is not the gap.** c=1 TPOT matches to two decimals on 2B (3.10 vs 3.11) and to ~1% on 4B/9B.
2. **pegainfer's advantage is short-queue first token.** c=1 TTFT: 9.4 vs 38.9 (2B), 16.3 vs 45.6 (4B), 25.8 vs 44.4 (9B).
3. **vLLM uses the 2048 token budget better at high conc.** 256-token prompts: 2048 admits 8 whole prefills per step. 2B Gen ties at c16 (2680 vs 2653) and vLLM leads at c32 (4430 vs 4060). 4B TTFT crosses at c12; c32 Gen 2255 vs 2018. 9B TTFT/Gen cross at c≥8; c32 Gen 1412 vs 1246.
4. **Raising the budget is not free TTFT for pegainfer.** The 1024→2048 change (2026-10-15) barely moved pegainfer Gen and made high-conc TTFT worse; vLLM 2B/4B Gen rose. This confirm run keeps the 2048 alignment.
5. **Still unalignable without product work:** pegainfer `--max-model-len` (KV), `MAX_DECODE_BATCH` 64 vs vLLM default 256. A vLLM-256 arm would be a production-default comparison, not an aligned A/B.

## Debrief

- **Outcome:** Confirm replay closed. 48/48 frozen. Serving torn down; GPU0–7 idle.
- **Pitfalls:** Fail-closed on `Multi-modal warmup completed`, not the `MMEncoderAttention` import. Token-id completions required.
- **Follow-ups:** pegainfer `--max-model-len`; optional production-default arm; not done: 3-retest median, longer prompts, prefix-cache-on, multimodal.
