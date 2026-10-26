# Two-lane fork — commands

## Classify checkout

```bash
git remote -v
git rev-parse --abbrev-ref HEAD
git log --oneline -1 --format='%H %D'
test -d docs/fork && echo archive-tree-present
```

`origin` equals the canonical URL and no `docs/fork/` ⇒ canonical clone. Write no archive content.

## Remotes (once per clone)

```bash
git remote add upstream git@github.com:<canonical-org>/<repo>.git
git remote set-url --push upstream no_push
git remote set-url origin git@github.com:<you>/<repo>.git
```

## First `local`

```bash
# only if missing; create from the current archive branch, not from a dirty main
git branch local
```

## Sync

```bash
git fetch upstream
git checkout main
git merge --ff-only upstream/main
git push origin main
git checkout local
git rebase main
```

Archive topic checked out: `git rebase local`

Upstream topic checked out: `git rebase main` — never `git rebase local`

If `--ff-only` on `main` refuses, `main` has local commits. Move them onto `local` (archive) or onto a `feat/*` from the previous `upstream/main` (upstream). Reset `main` only with explicit user consent.

## Contamination check

Execute from the repo root:

```bash
bash .cursor/skills/fork-upstream-sync/scripts/check-contamination.sh
```

Exit 0 required before drafting a canonical PR. The script diffs `upstream/main...HEAD` (falls back to `origin/main`) and fails on archive paths:

- `docs/fork/`
- `.cursor/skills/fork-upstream-sync/`
- `.cursor/rules/fork-upstream-sync.mdc`

## Extract an upstream-lane branch

```bash
git fetch upstream
git checkout main
git merge --ff-only upstream/main
git checkout -b feat/<slug> main
git cherry-pick <sha-1> <sha-2>
git restore --source=main --staged --worktree -- \
  docs/fork .cursor/skills/fork-upstream-sync .cursor/rules/fork-upstream-sync.mdc
bash .cursor/skills/fork-upstream-sync/scripts/check-contamination.sh
```

## Tags

Archive milestones only:

```bash
git tag -a "local/<slug>-$(date +%Y%m%d)" -m "<one-line why>"
git push origin "local/<slug>-$(date +%Y%m%d)"
```

Never reuse upstream `v*`.

## Canonical PR

Allowed only when all hold:

1. User said to open a PR against the canonical repo in this conversation.
2. `scripts/check-contamination.sh` exits 0.
3. Branch was created from `main`, not `local`.
4. Push destination is `origin`. Never `git push upstream`.

Otherwise: push the topic branch to `origin` and stop.
