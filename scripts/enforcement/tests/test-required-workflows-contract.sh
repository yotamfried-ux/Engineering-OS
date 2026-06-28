#!/usr/bin/env bash
# test-required-workflows-contract.sh — keep the documented required status checks
# for `main` in sync with the deterministic merge gate.
#
# Source of truth: REQUIRED_WORKFLOWS_DEFAULT in check-merge-readiness.sh.
# Mirror:          the <!-- required-checks:begin/end --> block in
#                  docs/operations/main-required-checks.md.
# This test fails if the two sets differ.
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)"
MERGE_CHECK="$ROOT/scripts/enforcement/check-merge-readiness.sh"
DOC="$ROOT/docs/operations/main-required-checks.md"

[ -f "$MERGE_CHECK" ] || { echo "❌ missing $MERGE_CHECK"; exit 1; }
[ -f "$DOC" ] || { echo "❌ missing $DOC"; exit 1; }

# Required set from the checker (the authoritative source).
checker_set="$(
  awk -F'"' '/^REQUIRED_WORKFLOWS_DEFAULT=/ { print $2; exit }' "$MERGE_CHECK" \
    | tr ' ' '\n' | sed '/^$/d' | sort -u
)"

# Documented set from the fenced contract block.
doc_set="$(
  awk '
    /required-checks:begin/ { capture = 1; next }
    /required-checks:end/   { capture = 0 }
    capture {
      gsub(/^[ \t]+|[ \t]+$/, "")
      if ($0 != "") print
    }
  ' "$DOC" | sort -u
)"

if [ -z "$checker_set" ]; then
  echo "❌ could not parse REQUIRED_WORKFLOWS_DEFAULT from check-merge-readiness.sh"
  exit 1
fi
if [ -z "$doc_set" ]; then
  echo "❌ could not parse required-checks block from main-required-checks.md"
  exit 1
fi

if [ "$checker_set" != "$doc_set" ]; then
  echo "❌ required-checks doc is out of sync with check-merge-readiness.sh"
  echo "--- checker (REQUIRED_WORKFLOWS_DEFAULT) ---"; echo "$checker_set"
  echo "--- doc (required-checks block) ---"; echo "$doc_set"
  echo "ACTION: update docs/operations/main-required-checks.md to match the checker exactly."
  exit 1
fi

echo "✅ required-checks doc matches check-merge-readiness.sh:"
echo "$checker_set" | sed 's/^/   - /'
