#!/usr/bin/env bash
# Fail if HEAD vs the upstream mirror contains archive-lane paths.
# Execute from a git checkout. Exit 0 = contribution-only; non-zero = do not open a canonical PR.
set -euo pipefail

if ! git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
  echo "FAIL: not a git checkout" >&2
  exit 2
fi

base_ref="${1:-}"
if [[ -z "${base_ref}" ]]; then
  if git rev-parse --verify --quiet upstream/main >/dev/null; then
    base_ref=upstream/main
  elif git rev-parse --verify --quiet origin/main >/dev/null; then
    base_ref=origin/main
  else
    echo "FAIL: no upstream/main or origin/main" >&2
    exit 2
  fi
fi

if ! git rev-parse --verify --quiet "${base_ref}" >/dev/null; then
  echo "FAIL: missing ref ${base_ref}" >&2
  exit 2
fi

echo "base=${base_ref}"
echo "head=$(git rev-parse --abbrev-ref HEAD) $(git rev-parse --short HEAD)"

fail=0
while IFS= read -r path; do
  [[ -z "${path}" ]] && continue
  case "${path}" in
    docs/fork/* | .cursor/skills/fork-upstream-sync/* | .cursor/rules/fork-upstream-sync.mdc)
      echo "FAIL: archive path: ${path}" >&2
      fail=1
      ;;
    *)
      echo "ok: ${path}"
      ;;
  esac
done < <(git diff --name-only "${base_ref}...HEAD")

if git show-ref --verify --quiet refs/heads/local; then
  if [[ "$(git rev-parse local)" != "$(git rev-parse HEAD)" ]] \
    && git merge-base --is-ancestor local HEAD; then
    echo "WARN: local is an ancestor of HEAD; file list must stay contribution-only" >&2
  fi
fi

if [[ "${fail}" -ne 0 ]]; then
  echo "FAIL: contaminated — extract onto a branch from main (see SKILL.md §6)" >&2
  exit 1
fi

echo "OK: no archive paths vs ${base_ref}"
exit 0
