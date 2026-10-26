# Fork archive index

> **TL;DR:** Routing table for **archive-lane** docs on this fork. Do not add these rows to upstream `docs/index.md`. Do not include these files in a PR to `pegainfer-project/pegainfer`.

| Path | TL;DR |
| --- | --- |
| `README.md` | Archive-lane contract: local records only; never in a canonical PR; upstream-lane work branches from `main`. |
| `benchmarks/qwen35-text-cacheoff-vllm-vs-pegainfer-y108p62.md` | y108p62 Qwen3.5-2B/4B/9B text-only prefix-cache-off vs vLLM v0.29.0: confirmed 2026-10-26 replay, 48/48 at conc 1–32, batched tokens 2048, frozen 256/64. Low-conc pegainfer TTFT; high-conc Gen crosses to vLLM. |
