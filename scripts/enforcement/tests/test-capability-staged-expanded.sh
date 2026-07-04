#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)"
CHECK="$ROOT/scripts/enforcement/check-capability-staged-changes.sh"
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT

plan() {
  local cap="$1"
  cat > "$TMP/plan.md" <<EOF
# Route Plan

## Capability Evidence

- \`$cap\` — checked.
EOF
}

must_pass() {
  local file="$1" cap="$2"
  printf '%s\n' "$file" > "$TMP/files.txt"
  plan "$cap"
  bash "$CHECK" --files-from "$TMP/files.txt" --plan "$TMP/plan.md" >/tmp/staged-expanded.out
}

must_fail() {
  local file="$1"
  printf '%s\n' "$file" > "$TMP/files.txt"
  plan 'routing.task-router-read'
  if bash "$CHECK" --files-from "$TMP/files.txt" --plan "$TMP/plan.md" >/tmp/staged-expanded-fail.out 2>&1; then
    echo "expected $file to require mapped capability" >&2
    exit 1
  fi
}

must_pass 'core/workflow.md' 'validation.policy-change-has-validator'
must_fail 'core/workflow.md'
must_pass 'templates/web-app/README.md' 'template.project-template-checked'
must_fail 'templates/web-app/README.md'
must_pass 'patterns/api/README.md' 'pattern.relevant-patterns-checked'
must_fail 'patterns/api/README.md'

echo "expanded staged capability map simulations passed"
