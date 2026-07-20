#!/usr/bin/env bash
set -euo pipefail

block() {
  echo "ERROR_FOR_AGENT: $1" >&2
  [ -z "${2:-}" ] || echo "ACTION: $2" >&2
  exit 2
}

warn() {
  echo "WARNING_FOR_AGENT: $1" >&2
  [ -z "${2:-}" ] || echo "ACTION: $2" >&2
}

if [ "${EOS_TELEMETRY_DISABLED:-0}" = "1" ]; then
  block "Engineering OS telemetry is disabled for this session." \
    "start a fresh Claude session with telemetry enabled before continuing the experiment."
fi

ROOT="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"
EVENTS="${EOS_TELEMETRY_FILE:-$ROOT/.engineering-os/telemetry/events.jsonl}"
RUN_ID_FILE="${EOS_TELEMETRY_RUN_ID_FILE:-$ROOT/.engineering-os/telemetry/run_id}"
SETTINGS="${EOS_CLAUDE_SETTINGS_FILE:-$ROOT/.claude/settings.json}"
HOOK_MODE="${EOS_TELEMETRY_HOOK_MODE:-direct}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SYNC="$SCRIPT_DIR/sync-telemetry-run.py"

case "$HOOK_MODE" in
  direct|dispatcher) ;;
  *) block "unknown telemetry hook mode '$HOOK_MODE'." \
       "repair the hook dispatcher configuration before continuing." ;;
esac

POLICY_MODE="$(python3 - "$ROOT" "$SCRIPT_DIR" <<'PY'
from pathlib import Path
import sys
root = Path(sys.argv[1])
sys.path.insert(0, sys.argv[2])
from telemetry_handoff import load_policy
print(load_policy(root)["mode"])
PY
)"

[ -f "$SETTINGS" ] || block "Claude settings are missing; telemetry hooks cannot be active." \
  "install the current Engineering OS hooks, then restart Claude."
[ -s "$RUN_ID_FILE" ] || block "telemetry run_id is missing; the SessionStart hook did not initialize this session." \
  "restart Claude in this repository and verify the SessionStart hook runs."
[ -s "$EVENTS" ] || block "telemetry events are missing; no current-session evidence exists." \
  "restart Claude after installing the telemetry hooks."

if [ ! -f "$SYNC" ]; then
  if [ "$POLICY_MODE" = "required" ]; then
    block "telemetry remote handoff runtime is missing." \
      "update Engineering OS and re-run the installer before restarting Claude."
  fi
  warn "telemetry remote handoff runtime is missing; local telemetry remains available." \
    "update Engineering OS and re-run the installer before a required-handoff experiment."
fi

if ! python3 - "$EVENTS" "$RUN_ID_FILE" "$SETTINGS" "$HOOK_MODE" <<'PY'
from __future__ import annotations

import json
import sys
from pathlib import Path

events_path, run_id_path, settings_path = map(Path, sys.argv[1:4])
hook_mode = sys.argv[4]
run_id = run_id_path.read_text(encoding="utf-8", errors="replace").splitlines()[0].strip()
if not run_id:
    raise SystemExit("ERROR_FOR_AGENT: telemetry run_id is empty")

try:
    settings = json.loads(settings_path.read_text(encoding="utf-8"))
except Exception as exc:
    raise SystemExit(f"ERROR_FOR_AGENT: Claude settings are not valid JSON: {exc}") from exc

hooks = settings.get("hooks") if isinstance(settings, dict) else None
if not isinstance(hooks, dict):
    raise SystemExit("ERROR_FOR_AGENT: Claude settings do not contain a hooks object")

commands: list[str] = []
for blocks in hooks.values():
    if not isinstance(blocks, list):
        continue
    for block in blocks:
        if not isinstance(block, dict):
            continue
        entries = block.get("hooks")
        if not isinstance(entries, list):
            continue
        for entry in entries:
            if isinstance(entry, dict) and isinstance(entry.get("command"), str):
                commands.append(entry["command"])

if hook_mode == "direct":
    requirements = {
        "SessionStart": lambda command: "eos-telemetry-session-start.sh" in command,
        "PreToolUse guard": lambda command: "require-telemetry-session.sh" in command,
        "event recorder": lambda command: "eos-telemetry-event.sh" in command,
    }
else:
    requirements = {
        "dispatcher SessionStart": lambda command: (
            "eos-telemetry-dispatch.sh" in command and command.rstrip().endswith(" session_start")
        ),
        "dispatcher PreToolUse guard": lambda command: (
            "eos-telemetry-dispatch.sh" in command and command.rstrip().endswith(" guard")
        ),
        "dispatcher event recorder": lambda command: (
            "eos-telemetry-dispatch.sh" in command and command.rstrip().endswith(" pre_tool_use")
        ),
    }

for label, predicate in requirements.items():
    if not any(predicate(command) for command in commands):
        raise SystemExit(f"ERROR_FOR_AGENT: telemetry settings are incomplete; missing {label}")

count = 0
has_current_start = False
for raw in events_path.read_text(encoding="utf-8", errors="replace").splitlines():
    if not raw.strip():
        continue
    try:
        record = json.loads(raw)
    except Exception:
        continue
    if not isinstance(record, dict):
        continue
    count += 1
    attrs = record.get("attributes") if isinstance(record.get("attributes"), dict) else {}
    event_name = str(attrs.get("eos.event.name") or "")
    record_name = str(record.get("name") or "")
    if str(record.get("trace_id") or "") == run_id and (
        event_name == "session_start" or record_name == "eos.session_start"
    ):
        has_current_start = True
if not has_current_start:
    raise SystemExit(
        "ERROR_FOR_AGENT: current telemetry run has no matching session_start event; "
        "settings were probably installed after this Claude session began. Restart Claude before continuing."
    )
print(f"telemetry session ready: events={count}")
PY
then
  exit 2
fi

BOUNDARY_READY="$(python3 - "$SETTINGS" "$HOOK_MODE" <<'PY'
import json
import sys
from pathlib import Path

settings = json.loads(Path(sys.argv[1]).read_text(encoding="utf-8"))
hook_mode = sys.argv[2]
commands = []
for blocks in settings.get("hooks", {}).values():
    if not isinstance(blocks, list):
        continue
    for block in blocks:
        if not isinstance(block, dict):
            continue
        for entry in block.get("hooks", []):
            if isinstance(entry, dict) and isinstance(entry.get("command"), str):
                commands.append(entry["command"])
if hook_mode == "direct":
    ready = any("record-and-sync-telemetry.sh" in command for command in commands)
else:
    ready = any(
        "eos-telemetry-dispatch.sh" in command and command.rstrip().endswith(" stop")
        for command in commands
    )
print("1" if ready else "0")
PY
)"

if [ "$BOUNDARY_READY" != "1" ]; then
  if [ "$POLICY_MODE" = "required" ]; then
    block "telemetry settings do not register durable Stop/SessionEnd handoff hooks." \
      "re-run the current Engineering OS installer, then restart Claude before required-handoff work."
  fi
  warn "telemetry settings use incomplete or legacy boundary hooks; research tools remain available." \
    "re-run the current Engineering OS installer before a required-handoff experiment."
fi

case "$POLICY_MODE" in
  disabled)
    exit 0
    ;;
  best_effort)
    if [ -f "$SYNC" ] && ! python3 "$SYNC" --check; then
      warn "best-effort telemetry handoff is not ready; local telemetry remains available."
    fi
    exit 0
    ;;
  required)
    python3 "$SYNC" --check || block \
      "current telemetry session has not completed the required durable GitHub handoff." \
      "verify GitHub authentication and the telemetry policy, then restart or retry the session."
    ;;
  *)
    block "unknown telemetry policy mode '$POLICY_MODE'." \
      "repair .engineering-os/telemetry-policy.json before continuing."
    ;;
esac
