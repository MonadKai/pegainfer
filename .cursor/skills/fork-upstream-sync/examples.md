# Two-lane cases

## Archive record

Input: 把这次 y108p62 对比测记录到 fork，不给上游提 PR.

```
Lane: archive
Branch: from local (or stay on the existing archive topic)
Write: docs/fork/benchmarks/… + a row in docs/fork/index.md
Do not: edit docs/index.md or docs/playbooks/bench-vs-vllm.md
Push: origin
Canonical PR: no
```

## Upstream-shaped, PR later

Input: 修 scheduler 这个 bug，先推到我的 fork，先不要给上游提 PR.

```
Lane: upstream
Branch: git checkout -b fix/<slug> main   # after main == upstream/main
Write: crate files only
Do not: add docs/fork/ "so we have a record" on this branch
Push: origin
Check: bash .cursor/skills/fork-upstream-sync/scripts/check-contamination.sh  → 0
Canonical PR: not yet
```

## User asks for the canonical PR

Input: 可以给 pegainfer-project 提 PR 了.

```
Run: bash .cursor/skills/fork-upstream-sync/scripts/check-contamination.sh
If non-zero: refuse; extract (SKILL.md §6)
If 0 and user named the canonical repo: gh pr create against that repo
```

## Mixed request

Input: 记录这次实验，顺便把 TTFT 回归修掉.

```
Two units of work. Ask which lane the TTFT fix is.
Archive branch: the write-up only.
If fix is upstream: second branch from main, code only.
If fix is archive-only: it lives on local, not in docs/fork/, and must not appear in a later canonical PR.
```

## Wrong

```
❌ one commit adds docs/fork/benchmarks/… and patches src/
❌ git checkout -b feat/fix local   then later PR that branch
❌ gh pr create from local or from docs/qwen35-…
❌ promote a campaign snapshot into an upstream playbook edit
❌ rebase an upstream topic onto local
```
