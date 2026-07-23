#!/usr/bin/env bash
set -euo pipefail

settings="${1:-.claude/settings.json}"
[ -f "$settings" ] || { echo "settings file not found" >&2; exit 1; }

python3 - "$settings" <<'PY'
import json
import sys
from pathlib import Path

p = Path(sys.argv[1])
d = json.loads(p.read_text(encoding="utf-8"))
hooks = d.setdefault("hooks", {})
base = "${ENGINEERING_OS_HOME:-$(pwd)}"


def hard_command(event: str, matcher: str, unit: str, *args: str) -> str:
    suffix = "" if not args else " -- " + " ".join(args)
    return (
        f'GATE="{base}/scripts/enforcement/lib/hook-gate.sh"; '
        f'[ -r "$GATE" ] || {{ echo "ERROR_FOR_AGENT: Engineering OS hard-hook wrapper missing: $GATE" >&2; exit 2; }}; '
        f'bash "$GATE" --event {event} --matcher \'{matcher}\' --unit "{base}/{unit}"{suffix}'
    )


def soft_command(event: str, unit: str, *args: str) -> str:
    suffix = "" if not args else " -- " + " ".join(args)
    return (
        f'SOFT="{base}/scripts/enforcement/lib/soft-hook-gate.sh"; '
        f'if [ -r "$SOFT" ]; then bash "$SOFT" --event {event} --unit "{base}/{unit}"{suffix}; '
        f'else echo "WARNING_FOR_AGENT: Engineering OS soft-hook wrapper missing: $SOFT" >&2; exit 0; fi'
    )


def matching_blocks(event: str, matcher: str | None):
    for block in hooks.setdefault(event, []):
        if isinstance(block, dict) and block.get("matcher") == matcher:
            yield block


def ensure_hook(event: str, matcher: str | None, script_name: str, command: str, index: int = 0) -> None:
    blocks = list(matching_blocks(event, matcher))
    block = blocks[0] if blocks else None
    if block is None:
        block = {"hooks": []}
        if matcher is not None:
            block["matcher"] = matcher
        hooks[event].insert(index, block)
    entries = block.setdefault("hooks", [])
    found = None
    for entry in entries:
        if isinstance(entry, dict) and script_name in entry.get("command", ""):
            found = entry
            break
    if found is None:
        found = {"type": "command", "command": command}
        entries.insert(index, found)
    else:
        found["type"] = "command"
        found["command"] = command
        if index == 0:
            entries.remove(found)
            entries.insert(0, found)


write = "Write|Edit|MultiEdit|NotebookEdit"
ensure_hook("PreToolUse", write, "pre-tool-use-json-guard.sh", hard_command("PreToolUse", write, "scripts/enforcement/pre-tool-use-json-guard.sh"), index=0)
ensure_hook("PreToolUse", write, "pre-tool-use-runtime-evidence.sh", hard_command("PreToolUse", write, "scripts/enforcement/pre-tool-use-runtime-evidence.sh"), index=1)
ensure_hook("PreToolUse", write, "pre-tool-use-connector-selection.sh", hard_command("PreToolUse", write, "scripts/enforcement/pre-tool-use-connector-selection.sh"), index=2)
ensure_hook("PreToolUse", write, "pre-tool-use-template-selection.sh", hard_command("PreToolUse", write, "scripts/enforcement/pre-tool-use-template-selection.sh"), index=3)
ensure_hook("PreToolUse", write, "check-plan-scope.sh", hard_command("PreToolUse", write, "scripts/enforcement/check-plan-scope.sh"), index=4)

ensure_hook("PreToolUse", ".*", "pre-tool-use-json-guard.sh", hard_command("PreToolUse", ".*", "scripts/enforcement/pre-tool-use-json-guard.sh"), index=0)
ensure_hook("PreToolUse", ".*", "require-telemetry-session.sh", hard_command("PreToolUse", ".*", "scripts/monitoring/require-telemetry-session.sh"), index=1)
ensure_hook("PreToolUse", ".*", "eos-telemetry-event.sh", soft_command("PreToolUse", "scripts/monitoring/eos-telemetry-event.sh", "pre_tool_use"), index=2)

ensure_hook("PostToolUse", "mcp__.*", "post-tool-use-mcp.sh", soft_command("PostToolUse", "scripts/enforcement/post-tool-use-mcp.sh"), index=0)
ensure_hook("PostToolUse", "Read", "post-tool-use-read-evidence.sh", soft_command("PostToolUse", "scripts/enforcement/post-tool-use-read-evidence.sh"), index=1)
ensure_hook(
    "PostToolUse",
    "mcp__Notion__.*",
    "notion-progress-evidence",
    f'bash -c \'. "{base}/scripts/enforcement/lib/evidence.sh" 2>/dev/null && '
    'evidence_record connector_used notion && evidence_record notion_progress_validated\' '
    '2>/dev/null || { echo "WARNING_FOR_AGENT: Notion progress evidence recorder failed open." >&2; exit 0; }',
    index=0,
)

ensure_hook("Stop", None, "post-stop-hook.sh", hard_command("Stop", "*", "scripts/enforcement/post-stop-hook.sh"), index=0)

p.write_text(json.dumps(d, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
PY
