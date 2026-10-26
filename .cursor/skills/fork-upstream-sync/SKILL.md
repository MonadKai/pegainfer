---
name: fork-upstream-sync
description: Separates archive-lane fork records from upstream-lane contributions so a later canonical PR never carries local experiments. Use when the repo is a fork (upstream remote, docs/fork/, or non-canonical origin), or the user mentions 二次开发, 存档, 本地实验, 同步上游, 给上游提PR, archive vs upstream, rebase onto upstream, gh pr create, or editing docs/index.md / playbooks / AGENTS.md on a fork.
---

# Two-lane fork work

A fork holds two lanes. They must not share a branch, a commit, or a PR.

| Lane | Meaning | Canonical PR |
| --- | --- | --- |
| **archive** | Experiments, measurements, host notes, fork Cursor skills/rules. Record only. | Never |
| **upstream** | A change written so it can land on the canonical project | Only if the user said to open that PR in this conversation. Keep the branch PR-shaped until then. |

Lane belongs to **this unit of work**, not to the repo. Do not infer it from "this looks useful".

## Quick start

```
- [ ] Checkout is a fork (`git remote -v`), not the canonical clone
- [ ] Lane named: archive | upstream | asked the user
- [ ] One branch = one lane
- [ ] Archive: new paths, from `local`, topic `archive/<slug>`
- [ ] Upstream: from `main`, contribution diff only
- [ ] Canonical PR: user asked in this conversation AND scripts/check-contamination.sh exits 0
```

## 1. Classify the checkout

```bash
git remote -v
git rev-parse --abbrev-ref HEAD
```

| Signal | Tree | Action |
| --- | --- | --- |
| `origin` is the canonical project (e.g. `pegainfer-project/pegainfer`) and there is no `docs/fork/` | Canonical clone | Write no archive content here. If a fork clone exists, do upstream-lane edits there. |
| `origin` is a personal/org fork, or remote `upstream` exists, or `docs/fork/` exists | Fork | Classify the lane, then edit. |
| Neither | Ordinary repo | Stop. This skill does not apply. |

## 2. Classify the lane — before the first edit

| User signal | Lane |
| --- | --- |
| 存档 / 记录 / 本地实验 / 不会提 PR / campaign | **archive** |
| 给上游提 PR / 给 canonical 提 / 准备贡献 | **upstream** |
| New doc under `docs/fork/`, host note, bench snapshot, fork Cursor skill | **archive** |
| Edit to existing crate source or an upstream-owned doc, lane not named | **Ask.** One question: archive (from `local`, never PR) or upstream (from `main`, may PR later). Do not pick. |

Do not promote archive work because it looks like a good contribution. Do not bury an upstream-lane code fix in an archive commit.

If one request records a run **and** changes engine code: split after the user names the code's lane.

## 3. Archive lane

- Branch from `local`. Name new topics `archive/<slug>` (not `docs/*` — the canonical repo already uses `docs/` branches).
- Merge back to `local`. Never open a canonical PR from this branch.
- New paths only. Do not edit a path that exists on `upstream/main`.
- Docs: `docs/fork/…` + a row in `docs/fork/index.md`. Never register them in `docs/index.md`.
- Fork Cursor files may live under `.cursor/skills/`, `.cursor/rules/`.
- Push `origin` only. Tags: `local/<slug>-<YYYYMMDD>`. Never `v*`.

If the user says "update the playbook" / "add a row to `docs/index.md`" on the archive lane: copy the lesson into `docs/fork/` and leave the upstream-owned file untouched.

## 4. Upstream lane

- Branch from **`main`** after it fast-forwards `upstream/main`. Never from `local`.
- Editing upstream-owned files is expected. Keep the diff to the contribution.
- Do not add `docs/fork/`, fork skills/rules, or campaign JSON on this branch. Record those on an archive branch; mention the SHA if needed.
- Push `origin` and stop. `gh pr create` against the canonical repo requires an explicit 给上游提 PR (or equivalent) **in this conversation**.
- Until that sentence exists, the branch must still pass `scripts/check-contamination.sh`.

## 5. Contamination check

Execute, do not re-implement:

```bash
bash .cursor/skills/fork-upstream-sync/scripts/check-contamination.sh
# fallback: bash ~/.cursor/skills/fork-upstream-sync/scripts/check-contamination.sh
```

- Exit 0: file list is contribution-only. Still need the user's PR sentence.
- Non-zero: refuse to draft the canonical PR. Extract per §6.
- Do not "explain away" extra files in the PR body.

## 6. Lane change (archive history → later upstream PR)

New upstream-lane branch. Do not `gh pr create` from `local`.

1. Name the contribution commits (code only).
2. `git checkout -b feat/<slug> main` (`main` == `upstream/main`).
3. Cherry-pick; drop archive hunks.
4. Re-run `scripts/check-contamination.sh`.
5. Push `origin`. Open the canonical PR only if the user asked in this conversation.

## 7. Refs and sync

| Ref | Role |
| --- | --- |
| `origin` | Fork. Push here. |
| `upstream` | Canonical remote. Fetch only (`push = no_push`). |
| `main` | Fast-forward of `upstream/main`. No local commits. |
| `local` | Archive integration. Never PR this ref. |
| `archive/*` | Archive topics, from `local`. |
| `feat/*` `fix/*` `chore/*` | Upstream topics, from `main`. |

Sync: ff `main` from `upstream/main`, rebase `local` onto `main`, rebase live `archive/*` onto `local`. Never rebase an upstream topic onto `local`.

## Additional resources

- Commands: [reference.md](reference.md)
- Cases: [examples.md](examples.md)
