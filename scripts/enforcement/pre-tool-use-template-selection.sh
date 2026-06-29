#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
INPUT="$(cat 2>/dev/null || true)"

json_field() {
  local field="$1"
  printf '%s' "$INPUT" | python3 -c "
import json, sys
try:
    d=json.load(sys.stdin)
except Exception:
    print(''); sys.exit(0)
t=d.get('tool_input', d)
field='$field'
if field == 'tool': print(d.get('tool_name', d.get('tool', '')) or '')
elif field == 'file_path': print(t.get('file_path', '') or '')
" 2>/dev/null || true
}

select_plan() {
  local target="${1:-}"
  case "$target" in .claude/plans/*.md|*/.claude/plans/*.md)
    [ -f "$target" ] && { printf '%s\n' "$target"; return 0; }
    ;;
  esac
  if [ -n "${EOS_ACTIVE_PLAN:-}" ] && [ -f "${EOS_ACTIVE_PLAN:-}" ]; then printf '%s\n' "$EOS_ACTIVE_PLAN"; return 0; fi
  if [ -f .claude/plans/active.md ]; then printf '%s\n' .claude/plans/active.md; return 0; fi
  ls -t .claude/plans/*.md 2>/dev/null | head -1 || true
}

TOOL="$(json_field tool)"
case "$TOOL" in Write|Edit|MultiEdit|NotebookEdit) ;; *) exit 0 ;; esac
FILE="$(json_field file_path)"
[ -n "$FILE" ] || exit 0

PLAN="$(select_plan "$FILE")"
[ -n "$PLAN" ] && [ -f "$PLAN" ] || exit 0
CHECK="$SCRIPT_DIR/check-required-templates.sh"
[ -f "$CHECK" ] || exit 0

if ! out="$(bash "$CHECK" --plan "$PLAN" --target "$FILE" 2>&1)"; then
  echo "template selection gate failed: $out" >&2
  exit 1
fi

echo "template selection checks passed"
