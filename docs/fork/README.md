# Fork archive tree

> **TL;DR:** Archive-lane records for this fork. Never part of a PR to `pegainfer-project/pegainfer`. Upstream-lane work lives on a different branch created from `main`.

This tree is the durable place for local experiments, measurements, and host notes. It is **not** listed in upstream `docs/index.md`. Routing is `docs/fork/index.md`.

## Lane

| This tree | Not this tree |
| --- | --- |
| 存档 / 记录 / 不会给上游提 PR | A change written to land on the canonical repo |

Today's campaign snapshots stay here. A later engine fix that *might* go upstream does not start here and does not share a commit with files here. That work branches from `main` after it fast-forwards `upstream/main`. See `.cursor/skills/fork-upstream-sync/`.

## Why a separate tree

Editing an upstream-owned file for archive reasons (`docs/index.md`, playbooks, `AGENTS.md`) turns every later fetch into a conflict **and** contaminates any future PR that branched off the same history. New paths do not.

## Next

Register new archive docs in `docs/fork/index.md`. Keep fork skills/rules on `local`. New archive topics are `archive/<slug>`. Keep `feat/*` / `fix/*` that might go upstream off `main` and out of this directory.
