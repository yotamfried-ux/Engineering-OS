#!/usr/bin/env bash
set -euo pipefail

INPUT="$(cat 2>/dev/null || true)"

printf '%s' "$INPUT" | python3 -m json.tool >/dev/null 2>&1 || {
  echo "ERROR_FOR_AGENT: PreToolUse JSON could not be parsed."
  exit 1
}

read_field() {
  local field="$1"
  printf '%s' "$INPUT" | python3 -c "import json,sys; d=json.load(sys.stdin); t=d.get('tool_input',d); f='$field'; print((d.get('tool_name') or d.get('tool') or '') if f=='tool' else (t.get(f,'') if isinstance(t,dict) else ''))" 2>/dev/null || true
}

TOOL="$(read_field tool)"
FILE="$(read_field file_path)"
CMD="$(read_field command)"

case "$TOOL" in
  Write|Edit|MultiEdit|NotebookEdit)
    [ -n "$FILE" ] || { echo "ERROR_FOR_AGENT: write event is missing tool_input.file_path."; exit 1; }
    ;;
  Bash)
    [ -n "$CMD" ] || { echo "ERROR_FOR_AGENT: Bash event is missing tool_input.command."; exit 1; }
    ;;
  Agent|Task)
    exit 0
    ;;
  "")
    echo "ERROR_FOR_AGENT: PreToolUse event is missing tool_name."
    exit 1
    ;;
esac

exit 0
