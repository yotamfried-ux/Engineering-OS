#!/usr/bin/env bash
set -euo pipefail

block() {
  echo "ERROR_FOR_AGENT: $1" >&2
  [ -z "${2:-}" ] || echo "ACTION: $2" >&2
  # Claude Code PreToolUse hooks block only on exit code 2. Exit code 1 is a
  # non-blocking hook error, so every telemetry preflight failure must use 2.
  exit 2
}

if [ "${EOS_TELEMETRY_DISABLED:-0}" = "1" ]; then
  block "Engineering OS telemetry is disabled for this session." \
    "start a fresh Claude session with telemetry enabled before continuing the experiment."
fi

ROOT="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"
EVENTS="${EOS_TELEMETRY_FILE:-$ROOT/.engineering-os/telemetry/events.jsonl}"
RUN_ID_FILE="${EOS_TELEMETRY_RUN_ID_FILE:-$ROOT/.engineering-os/telemetry/run_id}"
SETTINGS="${EOS_CLAUDE_SETTINGS_FILE:-$ROOT/.claude/settings.json}"

[ -f "$SETTINGS" ] || block ".claude/settings.json is missing; telemetry hooks cannot be active." \
  "re-run the current Engineering OS installer, then restart Claude."
[ -s "$RUN_ID_FILE" ] || block "telemetry run_id is missing; the SessionStart hook did not initialize this session." \
  "restart Claude in this repository and verify the SessionStart hook runs."
[ -s "$EVENTS" ] || block "telemetry events are missing; no current-session evidence exists." \
  "restart Claude after installing the telemetry hooks."

if ! python3 - "$EVENTS" "$RUN_ID_FILE" "$SETTINGS" <<'PY'
from __future__ import annotations

import json
import sys
from pathlib import Path

events_path, run_id_path, settings_path = map(Path, sys.argv[1:4])
run_id = run_id_path.read_text(encoding="utf-8", errors="replace").splitlines()[0].strip()
if not run_id:
    raise SystemExit("ERROR_FOR_AGENT: telemetry run_id is empty")

settings_text = settings_path.read_text(encoding="utf-8", errors="replace")
for required in ("eos-telemetry-session-start.sh", "eos-telemetry-event.sh", "require-telemetry-session.sh"):
    if required not in settings_text:
        raise SystemExit(f"ERROR_FOR_AGENT: telemetry settings are incomplete; missing {required}")

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
    if str(record.get("trace_id") or "") == run_id and (event_name == "session_start" or record_name == "eos.session_start"):
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
