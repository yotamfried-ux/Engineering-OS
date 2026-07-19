#!/usr/bin/env python3
"""Merge Engineering OS telemetry hooks into a Claude settings file.

Custom hooks are preserved. Legacy telemetry handlers are normalized into one
metadata-only all-tools stream, while missing lifecycle hooks, durable handoff,
and the fail-closed session guard are added idempotently.

Default invocation (`patch-settings-telemetry.py <settings.json>`) is
byte-for-byte the same "direct" project-local install this script has always
done — install-policy-gates.sh calls it exactly this way and its behavior is
unchanged. `--mode dispatcher` (used only by
install-user-level-telemetry-hooks.sh, for $HOME/.claude/settings.json) wires
the same lifecycle events to scripts/monitoring/eos-telemetry-dispatch.sh
instead of directly to the per-repo scripts, since a user-level settings file
is not scoped to any single repository.

`--dry-run`, `--verify`, and `--uninstall` operate on either mode. All writes
are atomic (temp file + validate + rename) and a timestamped backup of the
previous file is written before any in-place modification of a
pre-existing file.
"""
from __future__ import annotations

import argparse
import json
import shutil
import stat
import sys
import time
from pathlib import Path
from typing import Any

MARKERS = (
    "require-telemetry-session.sh",
    "eos-telemetry-session-start.sh",
    "eos-telemetry-event.sh",
    "record-and-sync-telemetry.sh",
    "eos-telemetry-dispatch.sh",
)

EVENTS_WITH_MATCHER = (
    "PreToolUse",
    "PostToolUse",
    "PostToolUseFailure",
    "PermissionDenied",
    "SubagentStart",
    "SubagentStop",
)
EVENTS_WITHOUT_MATCHER = (
    "SessionStart",
    "UserPromptSubmit",
    "InstructionsLoaded",
    "TaskCreated",
    "TaskCompleted",
    "PostCompact",
    "Stop",
    "StopFailure",
    "SessionEnd",
)
ALL_EVENTS = EVENTS_WITH_MATCHER + EVENTS_WITHOUT_MATCHER


class PatchError(ValueError):
    pass


def home_placeholder() -> str:
    return "${ENGINEERING_OS_HOME:-$(pwd)}"


def command_set(mode: str, home: str | None = None) -> dict[str, str]:
    # A caller that already knows the concrete, absolute Engineering OS path
    # (the user-level installer does — a user-level settings file has no
    # project cwd for a ${ENGINEERING_OS_HOME:-$(pwd)} fallback to resolve
    # against) can bake it in directly here, in one pass, instead of writing
    # the placeholder and rewriting it in a separate step afterwards. Two
    # separate passes made re-running the installer look non-idempotent: the
    # patcher would always see "placeholder != already-rewritten-absolute"
    # and treat it as a version update on every run.
    home = home or home_placeholder()
    if mode == "direct":
        guard = f'bash "{home}/scripts/monitoring/require-telemetry-session.sh"'
        session_start = f'bash "{home}/scripts/monitoring/eos-telemetry-session-start.sh"'
        recorder = f'bash "{home}/scripts/monitoring/eos-telemetry-event.sh"'
        boundary = f'bash "{home}/scripts/monitoring/record-and-sync-telemetry.sh"'
    elif mode == "dispatcher":
        dispatch = f'bash "{home}/scripts/monitoring/eos-telemetry-dispatch.sh"'
        guard = f'bash "{home}/scripts/monitoring/require-telemetry-session.sh"'
        session_start = f'{dispatch} session_start'
        recorder = dispatch
        boundary = dispatch
    else:
        raise PatchError(f"unknown mode: {mode}")
    return {"guard": guard, "session_start": session_start, "recorder": recorder, "boundary": boundary}


def desired_hooks(mode: str, home: str | None = None) -> list[tuple[str, str | None, str, str, bool]]:
    """(event, matcher, marker, command, prepend) tuples this installer owns."""
    c = command_set(mode, home)
    # Markers must be literal substrings of their own command (ensure_hook's
    # dedup check is `marker in command`) — the filename that actually
    # appears differs by mode (direct points at the dedicated per-event
    # script; dispatcher points at eos-telemetry-dispatch.sh for all of
    # them), so these three are mode-aware rather than fixed strings.
    session_start_marker = "eos-telemetry-session-start.sh" if mode == "direct" else "eos-telemetry-dispatch.sh"
    boundary_marker = "record-and-sync-telemetry.sh" if mode == "direct" else "eos-telemetry-dispatch.sh"
    rows: list[tuple[str, str | None, str, str, bool]] = [
        ("PreToolUse", ".*", "require-telemetry-session.sh", c["guard"], True),
        ("PreToolUse", ".*", "pre_tool_use", f'{c["recorder"]} pre_tool_use', False),
        ("PostToolUse", ".*", "post_tool_use", f'{c["recorder"]} post_tool_use', False),
        ("PostToolUseFailure", ".*", "post_tool_use_failure", f'{c["recorder"]} post_tool_use_failure', False),
        ("PermissionDenied", ".*", "permission_denied", f'{c["recorder"]} permission_denied', False),
        ("SessionStart", None, session_start_marker, c["session_start"], True),
        ("UserPromptSubmit", None, "user_prompt_submit", f'{c["recorder"]} user_prompt_submit', False),
        ("InstructionsLoaded", None, "instructions_loaded", f'{c["recorder"]} instructions_loaded', False),
        ("SubagentStart", ".*", "subagent_start", f'{c["recorder"]} subagent_start', False),
        ("SubagentStop", ".*", "subagent_stop", f'{c["recorder"]} subagent_stop', False),
        ("TaskCreated", None, "task_created", f'{c["recorder"]} task_created', False),
        ("TaskCompleted", None, "task_completed", f'{c["recorder"]} task_completed', False),
        ("PostCompact", None, "post_compact", f'{c["recorder"]} post_compact', False),
        ("Stop", None, boundary_marker, f'{c["boundary"]} stop', False),
        ("StopFailure", None, boundary_marker, f'{c["boundary"]} stop_failure', False),
        ("SessionEnd", None, boundary_marker, f'{c["boundary"]} session_end', False),
    ]
    return rows


def is_marker_owned(command: str) -> bool:
    return any(marker in command for marker in MARKERS)


def load_settings(path: Path) -> dict[str, Any]:
    if not path.is_file():
        return {}
    try:
        data = json.loads(path.read_text(encoding="utf-8"))
    except Exception as exc:
        raise PatchError(
            f"existing settings file is not valid JSON, refusing to overwrite silently: {path}: {exc}"
        ) from exc
    if not isinstance(data, dict):
        raise PatchError(f"settings root must be a JSON object: {path}")
    return data


def backup_path(path: Path) -> Path:
    stamp = time.strftime("%Y%m%dT%H%M%SZ", time.gmtime())
    return path.with_name(f"{path.name}.backup.{stamp}")


def atomic_write(path: Path, data: dict[str, Any]) -> None:
    serialized = json.dumps(data, ensure_ascii=False, indent=2) + "\n"
    # Validate round-trip before ever touching the real path.
    json.loads(serialized)
    path.parent.mkdir(parents=True, exist_ok=True)
    tmp = path.with_name(f".{path.name}.tmp-{time.time_ns()}")
    tmp.write_text(serialized, encoding="utf-8")
    tmp.replace(path)


class Blocks:
    def __init__(self, hooks: dict[str, Any]) -> None:
        self.hooks = hooks

    def get(self, event: str) -> list[dict[str, Any]]:
        value = self.hooks.setdefault(event, [])
        if not isinstance(value, list):
            raise PatchError(f"settings hooks.{event} must be an array")
        return [item for item in value if isinstance(item, dict)]

    def find(self, event: str, matcher: str | None) -> dict[str, Any] | None:
        for block in self.get(event):
            if block.get("matcher") == matcher:
                return block
        return None


def ensure_hook(blocks: Blocks, event: str, matcher: str | None, marker: str, command: str, *, prepend: bool) -> bool:
    """Returns True if this call changed the settings (added or updated)."""
    seq = blocks.hooks.setdefault(event, [])
    block = blocks.find(event, matcher)
    if block is None:
        block = {"hooks": []}
        if matcher is not None:
            block["matcher"] = matcher
        seq.append(block)
    hook_list = block.setdefault("hooks", [])
    if not isinstance(hook_list, list):
        raise PatchError(f"hooks for {event}/{matcher} must be an array")
    for hook in hook_list:
        if isinstance(hook, dict) and marker in str(hook.get("command") or ""):
            if hook.get("command") == command:
                return False
            hook["command"] = command  # version update: replace in place, never duplicate
            return True
    entry = {"type": "command", "command": command}
    hook_list.insert(0, entry) if prepend else hook_list.append(entry)
    return True


def remove_owned_recorder_hooks(blocks: Blocks, event: str) -> bool:
    changed = False
    for block in blocks.get(event):
        existing = block.get("hooks", [])
        if not isinstance(existing, list):
            continue
        kept = [
            hook for hook in existing
            if not (isinstance(hook, dict) and is_marker_owned(str(hook.get("command") or "")))
        ]
        if len(kept) != len(existing):
            changed = True
        block["hooks"] = kept
    return changed


def replace_legacy_session_start(blocks: Blocks, session_start_command: str) -> bool:
    changed = False
    for block in blocks.get("SessionStart"):
        for hook in block.get("hooks", []):
            if not isinstance(hook, dict):
                continue
            command = str(hook.get("command") or "")
            if "eos-telemetry-event.sh" in command and "session_start" in command:
                if hook.get("command") != session_start_command:
                    hook["command"] = session_start_command
                    changed = True
    return changed


def prune_empty(hooks: dict[str, Any]) -> None:
    for event in list(hooks.keys()):
        blocks_list = hooks.get(event)
        if not isinstance(blocks_list, list):
            continue
        pruned = []
        for block in blocks_list:
            if isinstance(block, dict) and not block.get("hooks"):
                continue
            pruned.append(block)
        if pruned:
            hooks[event] = pruned
        else:
            del hooks[event]


def apply_install(data: dict[str, Any], mode: str, home: str | None = None) -> bool:
    hooks = data.setdefault("hooks", {})
    if not isinstance(hooks, dict):
        raise PatchError("settings hooks must be a JSON object")
    blocks = Blocks(hooks)
    c = command_set(mode, home)
    changed = replace_legacy_session_start(blocks, c["session_start"])
    for event in ("PreToolUse", "PostToolUse", "PostToolUseFailure", "Stop", "StopFailure", "SessionEnd"):
        changed = remove_owned_recorder_hooks(blocks, event) or changed
    for event, matcher, marker, command, prepend in desired_hooks(mode, home):
        changed = ensure_hook(blocks, event, matcher, marker, command, prepend=prepend) or changed
    return changed


def apply_uninstall(data: dict[str, Any]) -> bool:
    hooks = data.get("hooks")
    if not isinstance(hooks, dict):
        return False
    blocks = Blocks(hooks)
    changed = False
    for event in ALL_EVENTS:
        changed = remove_owned_recorder_hooks(blocks, event) or changed
    prune_empty(hooks)
    if not hooks:
        del data["hooks"]
        changed = True
    return changed


def describe_owned(data: dict[str, Any]) -> list[str]:
    hooks = data.get("hooks")
    if not isinstance(hooks, dict):
        return []
    found = []
    for event, blocks_list in hooks.items():
        if not isinstance(blocks_list, list):
            continue
        for block in blocks_list:
            if not isinstance(block, dict):
                continue
            for hook in block.get("hooks", []):
                if isinstance(hook, dict) and is_marker_owned(str(hook.get("command") or "")):
                    found.append(f"{event}: {hook.get('command')}")
    return found


def verify(path: Path, mode: str, home: str | None = None) -> list[str]:
    problems: list[str] = []
    if not path.is_file():
        return [f"settings file does not exist: {path}"]
    try:
        data = load_settings(path)
    except PatchError as exc:
        return [str(exc)]
    hooks = data.get("hooks")
    if not isinstance(hooks, dict):
        return ["no hooks object present"]
    blocks = Blocks(hooks)
    seen_commands: dict[str, int] = {}
    for event, matcher, marker, command, _prepend in desired_hooks(mode, home):
        block = blocks.find(event, matcher)
        if block is None:
            problems.append(f"missing hook block for {event}/{matcher}")
            continue
        matches = [
            hook for hook in block.get("hooks", [])
            if isinstance(hook, dict) and marker in str(hook.get("command") or "")
        ]
        if not matches:
            problems.append(f"missing owned hook for {event} (marker={marker})")
        elif len(matches) > 1:
            problems.append(f"duplicate owned hooks for {event} (marker={marker}): {len(matches)} entries")
        for hook in matches:
            cmd = str(hook.get("command") or "")
            seen_commands[cmd] = seen_commands.get(cmd, 0) + 1
    return problems


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("settings", type=Path)
    parser.add_argument("--mode", choices=("direct", "dispatcher"), default="direct")
    parser.add_argument("--home", default=None, help="bake this absolute Engineering OS path directly into commands instead of the ${ENGINEERING_OS_HOME:-$(pwd)} placeholder")
    parser.add_argument("--dry-run", action="store_true")
    parser.add_argument("--verify", action="store_true")
    parser.add_argument("--uninstall", action="store_true")
    parser.add_argument("--no-backup", action="store_true", help="skip writing a .backup.<timestamp> file (testing only)")
    args = parser.parse_args()

    if args.verify:
        problems = verify(args.settings, args.mode, args.home)
        if problems:
            for p in problems:
                print(f"ERROR_FOR_AGENT: {p}", file=sys.stderr)
            return 1
        print(f"verified: {args.settings} (mode={args.mode})")
        return 0

    existed_before = args.settings.is_file()
    try:
        data = load_settings(args.settings)
    except PatchError as exc:
        print(f"ERROR_FOR_AGENT: {exc}", file=sys.stderr)
        print("ACTION: repair or remove the malformed settings file manually before retrying; no changes were made.", file=sys.stderr)
        return 1

    # apply_install/apply_uninstall remove-then-readd owned entries (to clean
    # up legacy/duplicate shapes), so their own return value is not a
    # reliable "did anything actually change" signal — compare serialized
    # before/after instead. This is what makes re-running the installer a
    # true no-op (no backup, no write) when settings are already current.
    before_serialized = json.dumps(data, ensure_ascii=False, sort_keys=True)
    if args.uninstall:
        apply_uninstall(data)
        action = "uninstall"
    else:
        apply_install(data, args.mode, args.home)
        action = "install"
    after_serialized = json.dumps(data, ensure_ascii=False, sort_keys=True)
    changed = before_serialized != after_serialized

    if args.dry_run:
        if changed:
            print(f"dry-run: would {action} Engineering OS telemetry hooks in {args.settings} (mode={args.mode})")
            for line in describe_owned(data):
                print(f"  {line}")
        else:
            print(f"dry-run: no changes needed for {args.settings}")
        return 0

    if not changed:
        print(f"no changes needed (already up to date): {args.settings}")
        return 0

    if existed_before and not args.no_backup:
        backup = backup_path(args.settings)
        shutil.copy2(args.settings, backup)
        print(f"backed up existing settings to {backup}")

    atomic_write(args.settings, data)
    print(f"{'uninstalled' if args.uninstall else 'installed/verified'} Engineering OS telemetry hooks: {args.settings} (mode={args.mode})")
    return 0


if __name__ == "__main__":
    try:
        raise SystemExit(main())
    except PatchError as exc:
        print(f"ERROR_FOR_AGENT: {exc}", file=sys.stderr)
        raise SystemExit(1)
