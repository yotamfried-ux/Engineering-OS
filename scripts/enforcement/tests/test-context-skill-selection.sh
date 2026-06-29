#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)"
CHECK="$ROOT/scripts/enforcement/check-required-skills.sh"
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT

cat >"$TMP/missing.md" <<'EOF'
# Plan
| Field | Value |
|---|---|
| Task class | context_or_large_repo_work |
| Domain tags | context-heavy, large-repo |
| Skills | graphify |
EOF

if bash "$CHECK" --plan "$TMP/missing.md" --target "src/large-repo/refactor.ts" >/tmp/context-missing.out 2>&1; then
  echo "expected missing context optimizer to fail"
  exit 1
fi
grep -q 'rtk' /tmp/context-missing.out

cat >"$TMP/present.md" <<'EOF'
# Plan
| Field | Value |
|---|---|
| Task class | context_or_large_repo_work |
| Domain tags | context-heavy, large-repo |
| Skills | graphify, rtk |
EOF
bash "$CHECK" --plan "$TMP/present.md" --target "src/large-repo/refactor.ts"

cat >"$TMP/waiver.md" <<'EOF'
# Plan
| Field | Value |
|---|---|
| Task class | context_or_large_repo_work |
| Domain tags | context-heavy, large-repo |
| Skills | graphify |

## Skill Selection Waiver

rtk unavailable in this environment.
EOF
bash "$CHECK" --plan "$TMP/waiver.md" --target "src/large-repo/refactor.ts"

echo "context skill selection checks passed"
