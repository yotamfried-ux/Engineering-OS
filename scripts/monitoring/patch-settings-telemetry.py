#!/usr/bin/env python3
"""Merge Engineering OS telemetry hooks into a Claude settings file.

Custom hooks are preserved. Missing telemetry hooks and the fail-closed session
preflight guard are added idempotently.
"""

from __future__ import annotations

import json
import sys
from pathlib import Path
from typing import Any


if len(sys.argv) != 2:
    raise SystemExit("usage: patch-settings-telemetry.py <settings.json>")

path = Path(sys.argv[1])
if not path.is_file():
    raise SystemExit(f"settings file not found: {path}")

data = json.loads(path.read_text(encoding="utf-8"))
if not isinstance(data, dict):
    raise SystemExit("settings root must be a JSON object")

hooks = data.setdefault("hooks", {})
if not isinstance(hooks, dict):
    raise SystemExit("settings hooks must be a JSON object")

HOME = '${ENGINEERING_OS_HOME:-$(pwd)}'
GUARD = f'bash "{HOME}/scripts/monitoring/require-telemetry-session.sh"'
SESSION_START = f'bash "{HOME}/scripts/monitoring/eos-telemetry-session-start.sh"'
RECORDER = f'bash "{HOME}/scripts/monitoring/eos-telemetry-event.sh"'


def blocks(event: str) -> list[dict[str, Any]]:
    value = hooks.setdefault(event, [])
    if not isinstance(value, list):
        raise SystemExit(f"settings hooks.{event} must be an array")
    return [item for item in value if isinstance(item, dict)]


def find_block(event: str, matcher: str | None) -> dict[str, Any] | None:
    for block in blocks(event):
        if block.get("matcher") == matcher:
            return block
    return None


def ensure_hook(
    event: str,
    matcher: str | None,
    marker: str,
    command: str,
    *,
    prepend: bool = False,
) -> None:
    seq = hooks.setdefault(event, [])
    block = find_block(event, matcher)
    if block is None:
        block = {"hooks": []}
        if matcher is not None:
            block["matcher"] = matcher
        seq.append(block)
    hook_list = block.setdefault("hooks", [])
    if not isinstance(hook_list, list):
        raise SystemExit(f"hooks for {event}/{matcher} must be an array")
    for hook in hook_list:
        if isinstance(hook, dict) and marker in str(hook.get("command") or ""):
            return
    entry = {"type": "command", "command": command}
    if prepend:
        hook_list.insert(0, entry)
    else:
        hook_list.append(entry)


def replace_legacy_session_start() -> None:
    for block in blocks("SessionStart"):
        for hook in block.get("hooks", []):
            if not isinstance(hook, dict):
                continue
            command = str(hook.get("command") or "")
            if "eos-telemetry-event.sh" in command and "session_start" in command:
                hook["command"] = SESSION_START


replace_legacy_session_start()

for matcher in ("Bash", "Read|Glob", "Write|Edit|MultiEdit|NotebookEdit", "Agent"):
    ensure_hook("PreToolUse", matcher, "require-telemetry-session.sh", GUARD, prepend=True)

ensure_hook("PreToolUse", "Bash", "pre_tool_use_bash", f"{RECORDER} pre_tool_use_bash")
ensure_hook("PreToolUse", "Read|Glob", "pre_tool_use_read_glob", f"{RECORDER} pre_tool_use_read_glob")
ensure_hook("PreToolUse", "Write|Edit|MultiEdit|NotebookEdit", "pre_tool_use_write_edit", f"{RECORDER} pre_tool_use_write_edit")
ensure_hook("PreToolUse", "Agent", "pre_tool_use_agent", f"{RECORDER} pre_tool_use_agent")

ensure_hook("PostToolUse", "mcp__.*", "post_tool_use_mcp", f"{RECORDER} post_tool_use_mcp")
ensure_hook("PostToolUse", "Bash", "post_tool_use_bash", f"{RECORDER} post_tool_use_bash")
ensure_hook("PostToolUse", "Read", "post_tool_use_read", f"{RECORDER} post_tool_use_read")

ensure_hook("SessionStart", None, "eos-telemetry-session-start.sh", SESSION_START, prepend=True)
ensure_hook("Stop", None, "eos-telemetry-event.sh", f"{RECORDER} stop")

path.write_text(json.dumps(data, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
