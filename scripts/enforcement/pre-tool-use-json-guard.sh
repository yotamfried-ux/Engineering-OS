#!/usr/bin/env bash
set -euo pipefail

INPUT="$(cat 2>/dev/null || true)"

python3 - <<'PY' <<<"$INPUT"
import json
import sys

raw = sys.stdin.read()
try:
    event = json.loads(raw)
except Exception as exc:
    print(f"ERROR_FOR_AGENT: PreToolUse JSON could not be parsed: {exc}")
    print("ACTION: retry with valid hook JSON before continuing.")
    sys.exit(1)

if not isinstance(event, dict):
    print("ERROR_FOR_AGENT: PreToolUse JSON must be an object.")
    sys.exit(1)

tool = event.get("tool_name") or event.get("tool") or ""
tool_input = event.get("tool_input", event)
if not isinstance(tool_input, dict):
    print("ERROR_FOR_AGENT: PreToolUse tool_input must be an object.")
    sys.exit(1)

if tool in {"Write", "Edit", "MultiEdit", "NotebookEdit"}:
    if not str(tool_input.get("file_path") or "").strip():
        print("ERROR_FOR_AGENT: write event is missing tool_input.file_path.")
        sys.exit(1)
elif tool == "Bash":
    if not str(tool_input.get("command") or "").strip():
        print("ERROR_FOR_AGENT: Bash event is missing tool_input.command.")
        sys.exit(1)
elif tool in {"Agent", "Task"}:
    pass
elif not tool:
    print("ERROR_FOR_AGENT: PreToolUse event is missing tool_name.")
    sys.exit(1)

sys.exit(0)
PY
