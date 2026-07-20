#!/usr/bin/env python3
"""Safely manage Engineering OS telemetry hooks in Claude settings."""
from __future__ import annotations

import argparse
from collections import Counter
import json
import os
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
    """Raised when settings cannot be changed safely."""


def home_placeholder() -> str:
    return "${ENGINEERING_OS_HOME:-$(pwd)}"


def command_set(mode: str, home: str | None = None) -> dict[str, str]:
    runtime_home = home or home_placeholder()
    if mode == "direct":
        return {
            "guard": f'bash "{runtime_home}/scripts/monitoring/require-telemetry-session.sh"',
            "session_start": f'bash "{runtime_home}/scripts/monitoring/eos-telemetry-session-start.sh"',
            "recorder": f'bash "{runtime_home}/scripts/monitoring/eos-telemetry-event.sh"',
            "boundary": f'bash "{runtime_home}/scripts/monitoring/record-and-sync-telemetry.sh"',
        }
    if mode == "dispatcher":
        dispatch = f'bash "{runtime_home}/scripts/monitoring/eos-telemetry-dispatch.sh"'
        return {
            "guard": f"{dispatch} guard",
            "session_start": f"{dispatch} session_start",
            "recorder": dispatch,
            "boundary": dispatch,
        }
    raise PatchError(f"unknown mode: {mode}")


def desired_hooks(
    mode: str,
    home: str | None = None,
) -> list[tuple[str, str | None, str, str, bool]]:
    commands = command_set(mode, home)
    guard_marker = (
        "require-telemetry-session.sh"
        if mode == "direct"
        else 'eos-telemetry-dispatch.sh" guard'
    )
    session_marker = (
        "eos-telemetry-session-start.sh"
        if mode == "direct"
        else "eos-telemetry-dispatch.sh"
    )
    boundary_marker = (
        "record-and-sync-telemetry.sh"
        if mode == "direct"
        else "eos-telemetry-dispatch.sh"
    )
    recorder = commands["recorder"]
    boundary = commands["boundary"]
    return [
        ("PreToolUse", ".*", guard_marker, commands["guard"], True),
        ("PreToolUse", ".*", "pre_tool_use", f"{recorder} pre_tool_use", False),
        ("PostToolUse", ".*", "post_tool_use", f"{recorder} post_tool_use", False),
        (
            "PostToolUseFailure",
            ".*",
            "post_tool_use_failure",
            f"{recorder} post_tool_use_failure",
            False,
        ),
        (
            "PermissionDenied",
            ".*",
            "permission_denied",
            f"{recorder} permission_denied",
            False,
        ),
        ("SessionStart", None, session_marker, commands["session_start"], True),
        (
            "UserPromptSubmit",
            None,
            "user_prompt_submit",
            f"{recorder} user_prompt_submit",
            False,
        ),
        (
            "InstructionsLoaded",
            None,
            "instructions_loaded",
            f"{recorder} instructions_loaded",
            False,
        ),
        ("SubagentStart", ".*", "subagent_start", f"{recorder} subagent_start", False),
        ("SubagentStop", ".*", "subagent_stop", f"{recorder} subagent_stop", False),
        ("TaskCreated", None, "task_created", f"{recorder} task_created", False),
        ("TaskCompleted", None, "task_completed", f"{recorder} task_completed", False),
        ("PostCompact", None, "post_compact", f"{recorder} post_compact", False),
        ("Stop", None, boundary_marker, f"{boundary} stop", False),
        (
            "StopFailure",
            None,
            boundary_marker,
            f"{boundary} stop_failure",
            False,
        ),
        ("SessionEnd", None, boundary_marker, f"{boundary} session_end", False),
    ]


def is_marker_owned(command: str) -> bool:
    return any(marker in command for marker in MARKERS)


def is_owned_declaration(command: str, marker: str) -> bool:
    return is_marker_owned(command) and marker in command


def load_settings(path: Path) -> dict[str, Any]:
    if not path.is_file():
        return {}
    try:
        data = json.loads(path.read_text(encoding="utf-8"))
    except Exception as exc:
        raise PatchError(
            "existing settings file is not valid JSON, refusing to overwrite "
            f"silently: {path}: {exc}"
        ) from exc
    if not isinstance(data, dict):
        raise PatchError(f"settings root must be a JSON object: {path}")
    return data


def backup_path(path: Path) -> Path:
    stamp = time.strftime("%Y%m%dT%H%M%SZ", time.gmtime())
    return path.with_name(f"{path.name}.backup.{stamp}")


def atomic_write(path: Path, data: dict[str, Any]) -> None:
    """Create the temporary file with its final mode before writing content."""

    serialized = json.dumps(data, ensure_ascii=False, indent=2) + "\n"
    json.loads(serialized)
    path.parent.mkdir(parents=True, exist_ok=True)
    try:
        mode = stat.S_IMODE(path.stat().st_mode) if path.exists() else 0o600
    except OSError:
        mode = 0o600

    tmp = path.with_name(f".{path.name}.tmp-{os.getpid()}-{time.time_ns()}")
    fd = -1
    try:
        fd = os.open(tmp, os.O_WRONLY | os.O_CREAT | os.O_EXCL, mode)
        os.fchmod(fd, mode)
        stream = os.fdopen(fd, "w", encoding="utf-8")
        fd = -1
        with stream:
            stream.write(serialized)
            stream.flush()
            os.fsync(stream.fileno())
        tmp.replace(path)
    finally:
        if fd >= 0:
            os.close(fd)
        try:
            tmp.unlink()
        except FileNotFoundError:
            pass


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


def iter_hook_commands(hooks: dict[str, Any]):
    for event, blocks in hooks.items():
        if not isinstance(blocks, list):
            continue
        for block in blocks:
            if not isinstance(block, dict):
                continue
            matcher = block.get("matcher")
            entries = block.get("hooks")
            if not isinstance(entries, list):
                continue
            for hook in entries:
                if isinstance(hook, dict) and isinstance(hook.get("command"), str):
                    yield event, matcher, hook, hook["command"]


def remove_owned_hooks(hooks: dict[str, Any]) -> bool:
    changed = False
    for event in list(hooks):
        blocks = hooks.get(event)
        if not isinstance(blocks, list):
            continue
        kept_blocks: list[Any] = []
        for block in blocks:
            if not isinstance(block, dict):
                kept_blocks.append(block)
                continue
            entries = block.get("hooks")
            if not isinstance(entries, list):
                kept_blocks.append(block)
                continue
            kept_entries = [
                hook
                for hook in entries
                if not (
                    isinstance(hook, dict)
                    and is_marker_owned(str(hook.get("command") or ""))
                )
            ]
            if len(kept_entries) != len(entries):
                changed = True
            block["hooks"] = kept_entries
            if kept_entries:
                kept_blocks.append(block)
        if kept_blocks:
            hooks[event] = kept_blocks
        else:
            del hooks[event]
    return changed


def ensure_hook(
    hooks: dict[str, Any],
    event: str,
    matcher: str | None,
    command: str,
    *,
    prepend: bool,
) -> None:
    sequence = hooks.setdefault(event, [])
    if not isinstance(sequence, list):
        raise PatchError(f"settings hooks.{event} must be an array")
    block = next(
        (
            item
            for item in sequence
            if isinstance(item, dict) and item.get("matcher") == matcher
        ),
        None,
    )
    if block is None:
        block = {"hooks": []}
        if matcher is not None:
            block["matcher"] = matcher
        sequence.append(block)
    entries = block.setdefault("hooks", [])
    if not isinstance(entries, list):
        raise PatchError(f"hooks for {event}/{matcher} must be an array")
    entry = {"type": "command", "command": command}
    entries.insert(0, entry) if prepend else entries.append(entry)


def apply_install(data: dict[str, Any], mode: str, home: str | None = None) -> bool:
    hooks = data.setdefault("hooks", {})
    if not isinstance(hooks, dict):
        raise PatchError("settings hooks must be a JSON object")
    before = json.dumps(hooks, ensure_ascii=False, sort_keys=True)
    remove_owned_hooks(hooks)
    for event, matcher, _marker, command, prepend in desired_hooks(mode, home):
        ensure_hook(hooks, event, matcher, command, prepend=prepend)
    return before != json.dumps(hooks, ensure_ascii=False, sort_keys=True)


def apply_uninstall(data: dict[str, Any]) -> bool:
    hooks = data.get("hooks")
    if not isinstance(hooks, dict):
        return False
    changed = remove_owned_hooks(hooks)
    if not hooks:
        del data["hooks"]
    return changed


def describe_owned(data: dict[str, Any]) -> list[str]:
    hooks = data.get("hooks")
    if not isinstance(hooks, dict):
        return []
    return [
        f"{event}: {command}"
        for event, _matcher, _hook, command in iter_hook_commands(hooks)
        if is_marker_owned(command)
    ]


def verify(path: Path, mode: str, home: str | None = None) -> list[str]:
    if not path.is_file():
        return [f"settings file does not exist: {path}"]
    try:
        data = load_settings(path)
    except PatchError as exc:
        return [str(exc)]
    hooks = data.get("hooks")
    if not isinstance(hooks, dict):
        return ["no hooks object present"]

    desired = desired_hooks(mode, home)
    problems: list[str] = []
    blocks = Blocks(hooks)
    for event, matcher, marker, command, _prepend in desired:
        block = blocks.find(event, matcher)
        if block is None:
            problems.append(f"missing hook block for {event}/{matcher}")
            continue
        entries = block.get("hooks")
        entries = entries if isinstance(entries, list) else []
        matches = [
            hook
            for hook in entries
            if isinstance(hook, dict)
            and is_owned_declaration(str(hook.get("command") or ""), marker)
        ]
        if not matches:
            problems.append(f"missing owned hook for {event} (marker={marker})")
            continue
        if len(matches) > 1:
            problems.append(
                f"duplicate owned hooks for {event} "
                f"(marker={marker}): {len(matches)} entries"
            )
        for hook in matches:
            installed = str(hook.get("command") or "")
            if installed != command:
                problems.append(
                    f"stale owned hook for {event} (marker={marker}): "
                    f"installed command does not match mode={mode}"
                )

    expected_counts = Counter(command for _e, _m, _k, command, _p in desired)
    actual_counts = Counter(
        command
        for _event, _matcher, _hook, command in iter_hook_commands(hooks)
        if is_marker_owned(command)
    )
    for command, count in sorted((actual_counts - expected_counts).items()):
        problems.append(f"unexpected owned hook ({count} entries): {command}")
    for command, count in sorted((expected_counts - actual_counts).items()):
        problems.append(f"missing expected owned command ({count} entries): {command}")
    return problems


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("settings", type=Path)
    parser.add_argument("--mode", choices=("direct", "dispatcher"), default="direct")
    parser.add_argument("--home", default=None)
    parser.add_argument("--dry-run", action="store_true")
    parser.add_argument("--verify", action="store_true")
    parser.add_argument("--uninstall", action="store_true")
    parser.add_argument("--no-backup", action="store_true")
    args = parser.parse_args()

    if args.verify:
        problems = verify(args.settings, args.mode, args.home)
        if problems:
            for problem in problems:
                print(f"ERROR_FOR_AGENT: {problem}", file=sys.stderr)
            return 1
        print(f"verified: {args.settings} (mode={args.mode})")
        return 0

    existed_before = args.settings.is_file()
    try:
        data = load_settings(args.settings)
    except PatchError as exc:
        print(f"ERROR_FOR_AGENT: {exc}", file=sys.stderr)
        print(
            "ACTION: repair or remove the malformed settings file manually "
            "before retrying; no changes were made.",
            file=sys.stderr,
        )
        return 1

    before = json.dumps(data, ensure_ascii=False, sort_keys=True)
    action = "uninstall" if args.uninstall else "install"
    if args.uninstall:
        apply_uninstall(data)
    else:
        apply_install(data, args.mode, args.home)
    changed = before != json.dumps(data, ensure_ascii=False, sort_keys=True)

    if args.dry_run:
        if changed:
            print(
                f"dry-run: would {action} Engineering OS telemetry hooks "
                f"in {args.settings} (mode={args.mode})"
            )
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
    verb = "uninstalled" if args.uninstall else "installed/verified"
    print(f"{verb} Engineering OS telemetry hooks: {args.settings} (mode={args.mode})")
    return 0


if __name__ == "__main__":
    try:
        raise SystemExit(main())
    except PatchError as exc:
        print(f"ERROR_FOR_AGENT: {exc}", file=sys.stderr)
        raise SystemExit(1)
