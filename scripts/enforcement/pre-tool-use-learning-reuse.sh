#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
INPUT="$(cat 2>/dev/null || true)"

FILE="$(printf '%s' "$INPUT" | python3 -c 'import json,sys
try:
    d=json.load(sys.stdin); t=d.get("tool_input", d); print(t.get("file_path", "") or "")
except Exception:
    print("")' 2>/dev/null || true)"

[ -n "$FILE" ] || exit 0
case "$FILE" in .claude/plans/*.md|*/.claude/plans/*.md) exit 0 ;; esac

PLAN="$(ls -t .claude/plans/*.md 2>/dev/null | head -1 || true)"
[ -n "$PLAN" ] || exit 0

CHECK="$SCRIPT_DIR/check-learning-reuse.sh"
[ -f "$CHECK" ] || exit 0

if ! out="$(bash "$CHECK" --plan "$PLAN" --target "$FILE" 2>&1)"; then
  echo "learning reuse gate failed: $out" >&2
  echo "Add relevant lessons and failed-solutions under ## Lessons Reused in the active Route Plan before editing this area." >&2
  exit 1
fi
