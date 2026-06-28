#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)"
CHECKER="$ROOT/scripts/enforcement/check-merge-readiness.sh"
DOC="$ROOT/docs/operations/main-required-checks.md"

required="$(grep '^REQUIRED_WORKFLOWS_DEFAULT=' "$CHECKER" | sed -E 's/^REQUIRED_WORKFLOWS_DEFAULT="//; s/"$//')"
[ -n "$required" ] || { echo "missing REQUIRED_WORKFLOWS_DEFAULT"; exit 1; }

echo "required workflow contract"
for name in $required; do
  grep -q -- "- $name" "$DOC" || { echo "  ❌ docs missing required workflow: $name"; exit 1; }
  case "$name" in
    enforcement-tests) test -f "$ROOT/.github/workflows/enforcement-tests.yml" ;;
    *) test -f "$ROOT/.github/workflows/${name}.yml" ;;
  esac || { echo "  ❌ workflow file missing for: $name"; exit 1; }
  echo "  ✅ $name"
done

# Ensure the docs do not list extra required workflow bullets that the checker does not know.
extra="$(grep '^- ' "$DOC" | sed 's/^- //' | while read -r name; do
  printf '%s\n' "$required" | tr ' ' '\n' | grep -qx "$name" || printf '%s\n' "$name"
done)"
[ -z "$extra" ] || { echo "  ❌ docs list unknown required workflow(s): $extra"; exit 1; }

echo "required workflow contract passed"
