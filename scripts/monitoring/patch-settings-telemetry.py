#!/usr/bin/env python3
"""Merge Engineering OS telemetry hooks into a Claude settings file.

Direct mode preserves the existing project-local installation contract.
Dispatcher mode installs user-level hooks that resolve each event to a managed
repository before invoking the existing per-repository telemetry runtime.
"""
from __future__ import annotations

import argparse
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
    """Raised when settings cannot be patched safely."""


def home_placeholder() -> str:
    """Return the legacy project-local runtime placeholder."""

    return "${ENGINEERING_OS_HOME:-$(pwd)}"


def command_set(mode: str, home: str | None = None) -> dict[str, str]:
    """Build the commands owned by one installation mode."""

    runtime_home = home or home_placeholder()
    if mode == "direct":
        guard = f'bash "{runtime_home}/scripts/monitoring/require-telemetry-session.sh"'
        session_start = (
            f'bash "{runtime_home}/scripts/monitoring/eos-telemetry-session-start.sh"'
        )
        recorder = f'bash "{runtime_home}/scripts/monitoring/eos-telemetry-event.sh"'
        boundary = (
            f'bash "{runtime_home}/scripts/monitoring/record-and-sync-telemetry.sh"'
        )
    elif mode == "dispatcher":
        dispatch = f'bash "{runtime_home}/scripts/monitoring/eos-telemetry-dispatch.sh"'
        guard = f"{dispatch} guard"
        session_start = f"{dispatch} session_start"
        recorder = dispatch
        boundary = dispatch
    else:
        raise PatchError(f"unknown mode: {mode}")

    return {
        "guard": guard,
        "session_start": session_start,
        "recorder": recorder,
        "boundary": boundary,
    }


def desired_hooks(
    mode: str,
    home: str | None = None,
) -> list[tuple[str, str | None, str, str, bool]]:
    """Return owned hook declarations as event/matcher/marker/command/prepend."""

    commands = command_set(mode, home)
    guard_marker = (
        "require-telemetry-session.sh"
        if mode == "direct"
        else 'eos-telemetry-dispatch.sh" guard'
    )
    session_start_marker = (
        "eos-telemetry-session-start.sh"
        if mode == "direct"
        else "eos-telemetry-dispatch.sh"
    )
    boundary_marker = (
        "record-and-sync-telemetry.sh"
        if mode == "direct"
        else "eos-telemetry-dispatch.sh"
    )

    return [
        ("PreToolUse", ".*", guard_marker, commands["guard"], True),
        (
            "PreToolUse",
            ".*",
            "pre_tool_use",
            f'{commands["recorder"]} pre_tool_use',
            False,
        ),
        (
            "PostToolUse",
            ".*",
            "post_tool_use",
            f'{commands["recorder"]} post_tool_use',
            False,
        ),
        (
            "PostToolUseFailure",
            ".*",
            "post_tool_use_failure",
            f'{commands["recorder"]} post_tool_use_failure',
            False,
        ),
        (
            "PermissionDenied",
            ".*",
            "permission_denied",
            f'{commands["recorder"]} permission_denied',
            False,
        ),
        ("SessionStart", None, session_start_marker, commands["session_start"], True),
        (
            "UserPromptSubmit",
            None,
            "user_prompt_submit",
            f'{commands["recorder"]} user_prompt_submit',
            False,
        ),
        (
            "InstructionsLoaded",
            None,
            "instructions_loaded",
            f'{commands["recorder"]} instructions_loaded',
            False,
        ),
        (
            "SubagentStart",
            ".*",
            "subagent_start",
            f'{commands["recorder"]} subagent_start',
            False,
        ),
        (
            "SubagentStop",
            ".*",
            "subagent_stop",
            f'{commands["recorder"]} subagent_stop',
            False,
        ),
        (
            "TaskCreated",
            None,
            "task_created",
            f'{commands["recorder"]} task_created',
            False,
        ),
        (
            "TaskCompleted",
            None,
            "task_completed",
            f'{commands["recorder"]} task_completed',
            False,
        ),
        (
            "PostCompact",
            None,
            "post_compact",
            f'{commands["recorder"]} post_compact',
            False,
        ),
        ("Stop", None, boundary_marker, f'{commands["boundary"]} stop', False),
        (
            "StopFailure",
            None,
            boundary_marker,
            f'{commands["boundary"]} stop_failure',
            False,
        ),
        (
            "SessionEnd",
            None,
            boundary_marker,
            f'{commands["boundary"]} session_end',
            False,
        ),
    ]


def is_marker_owned(command: str) -> bool:
    """Return whether a command belongs to Engineering OS telemetry."""

    return any(marker in command for marker in MARKERS)


def is_owned_declaration(command: str, marker: str) -> bool:
    """Match one declaration without claiming unrelated action-named hooks."""

    return is_marker_owned(command) and marker in command


def load_settings(path: Path) -> dict[str, Any]:
    """Load a settings object without silently replacing malformed JSON."""

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
    """Return a timestamped settings backup path."""

    stamp = time.strftime("%Y%m%dT%H%M%SZ", time.gmtime())
    return path.with_name(f"{path.name}.backup.{stamp}")


def atomic_write(path: Path, data: dict[str, Any]) -> None:
    """Validate and atomically replace settings without weakening permissions."""

    serialized = json.dumps(data, ensure_ascii=False, indent=2) + "\n"
    json.loads(serialized)
    path.parent.mkdir(parents=True, exist_ok=True)
    try:
        mode = stat.S_IMODE(path.stat().st_mode) if path.exists() else 0o600
    except OSError:
        mode = 0o600

    tmp = path.with_name(f".{path.name}.tmp-{time.time_ns()}")
    try:
        tmp.write_text(serialized, encoding="utf-8")
        os.chmod(tmp, mode)
        tmp.replace(path)
    finally:
        try:
            tmp.unlink()
        except FileNotFoundError:
            pass


class Blocks:
    """Typed access to Claude settings hook blocks."""

    def __init__(self, hooks: dict[str, Any]) -> None:
        self.hooks = hooks

    def get(self, event: str) -> list[dict[str, Any]]:
        """Return dictionary blocks for event."""

        value = self.hooks.setdefault(event, [])
        if not isinstance(value, list):
            raise PatchError(f"settings hooks.{event} must be an array")
        return [item for item in value if isinstance(item, dict)]

    def find(self, event: str, matcher: str | None) -> dict[str, Any] | None:
        """Find the block with the exact matcher."""

        for block in self.get(event):
            if block.get("matcher") == matcher:
                return block
        return None


def ensure_hook(
    blocks: Blocks,
    event: str,
    matcher: str | None,
    marker: str,
    command: str,
    *,
    prepend: bool,
) -> bool:
    """Add or update one owned hook and return whether settings changed."""

    sequence = blocks.hooks.setdefault(event, [])
    if not isinstance(sequence, list):
        raise PatchError(f"settings hooks.{event} must be an array")
    block = blocks.find(event, matcher)
    if block is None:
        block = {"hooks": []}
        if matcher is not None:
            block["matcher"] = matcher
        sequence.append(block)

    hook_list = block.setdefault("hooks", [])
    if not isinstance(hook_list, list):
        raise PatchError(f"hooks for {event}/{matcher} must be an array")

    for hook in hook_list:
        if not isinstance(hook, dict):
            continue
        installed = str(hook.get("command") or "")
        if not is_owned_declaration(installed, marker):
            continue
        if installed == command:
            return False
        hook["command"] = command
        return True

    entry = {"type": "command", "command": command}
    hook_list.insert(0, entry) if prepend else hook_list.append(entry)
    return True


def remove_owned_recorder_hooks(blocks: Blocks, event: str) -> bool:
    """Remove Engineering-OS-owned hooks from one event."""

    changed = False
    for block in blocks.get(event):
        existing = block.get("hooks", [])
        if not isinstance(existing, list):
            continue
        kept = [
            hook
            for hook in existing
            if not (
                isinstance(hook, dict)
                and is_marker_owned(str(hook.get("command") or ""))
            )
        ]
        changed = changed or len(kept) != len(existing)
        block["hooks"] = kept
    return changed


def prune_empty(hooks: dict[str, Any]) -> None:
    """Remove empty hook blocks and events."""

    for event in list(hooks):
        blocks_list = hooks.get(event)
        if not isinstance(blocks_list, list):
            continue
        pruned = [
            block
            for block in blocks_list
            if not (isinstance(block, dict) and not block.get("hooks"))
        ]
        if pruned:
            hooks[event] = pruned
        else:
            del hooks[event]


def apply_install(
    data: dict[str, Any],
    mode: str,
    home: str | None = None,
) -> bool:
    """Install the exact desired telemetry hook set for mode."""

    hooks = data.setdefault("hooks", {})
    if not isinstance(hooks, dict):
        raise PatchError("settings hooks must be a JSON object")
    blocks = Blocks(hooks)
    changed = False
    for event in ALL_EVENTS:
        changed = remove_owned_recorder_hooks(blocks, event) or changed
    prune_empty(hooks)
    for event, matcher, marker, command, prepend in desired_hooks(mode, home):
        changed = (
            ensure_hook(
                blocks,
                event,
                matcher,
                marker,
                command,
                prepend=prepend,
            )
            or changed
        )
    return changed


def apply_uninstall(data: dict[str, Any]) -> bool:
    """Remove only Engineering-OS-owned telemetry entries."""

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
    """Describe owned hook commands for dry-run output."""

    hooks = data.get("hooks")
    if not isinstance(hooks, dict):
        return []
    found: list[str] = []
    for event, blocks_list in hooks.items():
        if not isinstance(blocks_list, list):
            continue
        for block in blocks_list:
            if not isinstance(block, dict):
                continue
            for hook in block.get("hooks", []):
                if (
                    isinstance(hook, dict)
                    and is_marker_owned(str(hook.get("command") or ""))
                ):
                    found.append(f"{event}: {hook.get('command')}")
    return found


def verify(path: Path, mode: str, home: str | None = None) -> list[str]:
    """Return installation problems, including stale mode or runtime paths."""

    if not path.is_file():
        return [f"settings file does not exist: {path}"]
    try:
        data = load_settings(path)
    except PatchError as exc:
        return [str(exc)]

    hooks = data.get("hooks")
    if not isinstance(hooks, dict):
        return ["no hooks object present"]

    problems: list[str] = []
    blocks = Blocks(hooks)
    for event, matcher, marker, command, _prepend in desired_hooks(mode, home):
        block = blocks.find(event, matcher)
        if block is None:
            problems.append(f"missing hook block for {event}/{matcher}")
            continue

        matches = [
            hook
            for hook in block.get("hooks", [])
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
    return problems


def main() -> int:
    """Parse arguments and apply, verify, or remove telemetry hooks."""

    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("settings", type=Path)
    parser.add_argument(
        "--mode",
        choices=("direct", "dispatcher"),
        default="direct",
    )
    parser.add_argument(
        "--home",
        default=None,
        help=(
            "bake this absolute Engineering OS path directly into commands "
            "instead of the project-local placeholder"
        ),
    )
    parser.add_argument("--dry-run", action="store_true")
    parser.add_argument("--verify", action="store_true")
    parser.add_argument("--uninstall", action="store_true")
    parser.add_argument(
        "--no-backup",
        action="store_true",
        help="skip writing a backup file (testing only)",
    )
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
    print(
        f"{verb} Engineering OS telemetry hooks: "
        f"{args.settings} (mode={args.mode})"
    )
    return 0


if __name__ == "__main__":
    try:
        raise SystemExit(main())
    except PatchError as exc:
        print(f"ERROR_FOR_AGENT: {exc}", file=sys.stderr)
        raise SystemExit(1)
