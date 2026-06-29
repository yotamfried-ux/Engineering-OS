#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)"
CHECK="$ROOT/scripts/enforcement/check-required-skills.sh"
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT
LOG_FILE="$TMP/check.log"

pass() { local name="$1"; shift; "$@" >"$LOG_FILE" 2>&1 || { echo "fail: $name"; cat "$LOG_FILE"; exit 1; }; echo "ok: $name"; }
failcase() { local name="$1"; shift; if "$@" >"$LOG_FILE" 2>&1; then echo "unexpected pass: $name"; cat "$LOG_FILE"; exit 1; else echo "ok: $name"; fi; }

cat >"$TMP/missing.md" <<'EOF'
# Plan
| Field | Value |
|---|---|
| Task class | context_or_large_repo_work |
| Domain tags | context-heavy, large-repo |
| Skills | graphify |
EOF

failcase missing_rtk_blocked bash "$CHECK" --plan "$TMP/missing.md" --target "src/large-repo/refactor.ts"
grep -q 'rtk' "$LOG_FILE" || { echo "fail: missing_rtk_blocked — gate output does not mention rtk"; cat "$LOG_FILE"; exit 1; }
echo "ok: missing_rtk_output_mentions_rtk"

cat >"$TMP/present.md" <<'EOF'
# Plan
| Field | Value |
|---|---|
| Task class | context_or_large_repo_work |
| Domain tags | context-heavy, large-repo |
| Skills | graphify, rtk |
EOF
pass rtk_present_passes bash "$CHECK" --plan "$TMP/present.md" --target "src/large-repo/refactor.ts"

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
pass rtk_waiver_passes bash "$CHECK" --plan "$TMP/waiver.md" --target "src/large-repo/refactor.ts"

echo "context skill selection checks passed"
