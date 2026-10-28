#!/usr/bin/env bash
# Reconcile .github/workflows after an upstream merge.
#
# VansRouter keeps only fork-owned workflows: upstream-sync.yml and
# deploy-verify.yml. Every other upstream workflow (ci, build-matrix, release,
# gitbook-pages, and any new ones upstream adds later) is removed so they never
# run on the fork and never conflict again.
#
# Called by .github/workflows/upstream-sync.yml after `git merge`.
set -euo pipefail

cd "$(git rev-parse --show-toplevel)"

shopt -s nullglob
for f in .github/workflows/*.yml .github/workflows/*.yaml; do
  base="$(basename "$f")"
  case "$base" in
    upstream-sync.yml|deploy-verify.yml) ;;   # keep: fork-owned
    *) git rm -f -- "$f" ;;
  esac
done

echo "Workflow reconciliation done. Remaining:"
ls .github/workflows/ 2>/dev/null || true
