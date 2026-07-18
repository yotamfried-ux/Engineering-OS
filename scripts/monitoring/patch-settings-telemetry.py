#!/usr/bin/env python3
"""Merge Engineering OS telemetry hooks into a Claude settings file.

Custom hooks are preserved. Legacy telemetry handlers are normalized into one
metadata-only all-tools stream, while missing lifecycle hooks, durable handoff,
and the fail-closed session guard are added idempotently.
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
BOUNDARY = f'bash "{HOME}/scripts/monitoring/record-and-sync-telemetry.sh"'


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


def ensure_hook(event: str, matcher: str | None, marker: str, command: str, *, prepend: bool = False) -> None:
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
    hook_list.insert(0, entry) if prepend else hook_list.append(entry)


def remove_recorder_hooks(event: str) -> None:
    for block in blocks(event):
        existing = block.get("hooks", [])
        if not isinstance(existing, list):
            continue
        block["hooks"] = [
            hook for hook in existing
            if not (
                isinstance(hook, dict)
                and (
                    "eos-telemetry-event.sh" in str(hook.get("command") or "")
                    or "record-and-sync-telemetry.sh" in str(hook.get("command") or "")
                )
            )
        ]


def replace_legacy_session_start() -> None:
    for block in blocks("SessionStart"):
        for hook in block.get("hooks", []):
            if not isinstance(hook, dict):
                continue
            command = str(hook.get("command") or "")
            if "eos-telemetry-event.sh" in command and "session_start" in command:
                hook["command"] = SESSION_START


replace_legacy_session_start()
for event in ("PreToolUse", "PostToolUse", "PostToolUseFailure", "Stop", "StopFailure", "SessionEnd"):
    remove_recorder_hooks(event)

ensure_hook("PreToolUse", ".*", "require-telemetry-session.sh", GUARD, prepend=True)
ensure_hook("PreToolUse", ".*", "pre_tool_use", f"{RECORDER} pre_tool_use")
ensure_hook("PostToolUse", ".*", "post_tool_use", f"{RECORDER} post_tool_use")
ensure_hook("PostToolUseFailure", ".*", "post_tool_use_failure", f"{RECORDER} post_tool_use_failure")
ensure_hook("PermissionDenied", ".*", "permission_denied", f"{RECORDER} permission_denied")
ensure_hook("SessionStart", None, "eos-telemetry-session-start.sh", SESSION_START, prepend=True)
ensure_hook("UserPromptSubmit", None, "user_prompt_submit", f"{RECORDER} user_prompt_submit")
ensure_hook("InstructionsLoaded", None, "instructions_loaded", f"{RECORDER} instructions_loaded")
ensure_hook("SubagentStart", ".*", "subagent_start", f"{RECORDER} subagent_start")
ensure_hook("SubagentStop", ".*", "subagent_stop", f"{RECORDER} subagent_stop")
ensure_hook("TaskCreated", None, "task_created", f"{RECORDER} task_created")
ensure_hook("TaskCompleted", None, "task_completed", f"{RECORDER} task_completed")
ensure_hook("PostCompact", None, "post_compact", f"{RECORDER} post_compact")
ensure_hook("Stop", None, "record-and-sync-telemetry.sh", f"{BOUNDARY} stop")
ensure_hook("StopFailure", None, "record-and-sync-telemetry.sh", f"{BOUNDARY} stop_failure")
ensure_hook("SessionEnd", None, "record-and-sync-telemetry.sh", f"{BOUNDARY} session_end")

path.write_text(json.dumps(data, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
