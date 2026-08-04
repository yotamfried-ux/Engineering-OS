#!/usr/bin/env python3
"""Safely manage Engineering OS telemetry hooks in Claude settings."""
from __future__ import annotations

import argparse
from collections import Counter
import json
import os
import re
import shutil
import stat
import sys
import time
from pathlib import Path
from typing import Any

REGISTRY_RELATIVE = "scripts/enforcement/hook-criticality.tsv"
REGISTRY_COLUMNS = 10
# Only telemetry units are owned by this patcher; enforcement units are wired by the
# checked-in settings and by install-policy-gates.sh.
OWNED_UNIT_PREFIX = "scripts/monitoring/"
# Units whose exit status must reach Claude Code unwrapped.
PROPAGATE_FAILURE = "propagate_failure"
# Units that receive no per-event argument. Everything else is called with the
# snake_case form of its event name.
ARGLESS_UNITS = (
    "scripts/monitoring/require-telemetry-session.sh",
    "scripts/monitoring/eos-telemetry-session-start.sh",
)
# In dispatcher mode one scope-resolving unit fronts every telemetry unit. The registry
# cannot express this as rows, because a single unit would then serve two roles on
# PreToolUse and collide on the registry's (event, matcher, unit, wiring, surface) key.
DISPATCH_UNIT = "scripts/monitoring/eos-telemetry-dispatch.sh"
DISPATCH_SUBCOMMANDS = {
    "scripts/monitoring/require-telemetry-session.sh": "guard",
    "scripts/monitoring/eos-telemetry-session-start.sh": "session_start",
}
# Fallback ownership markers, used only for --uninstall when the registry is gone.
# The installed set is derived from the registry; see owned_markers().
FALLBACK_MARKERS = (
    "require-telemetry-session.sh",
    "eos-telemetry-session-start.sh",
    "eos-telemetry-event.sh",
    "record-and-sync-telemetry.sh",
    "eos-telemetry-dispatch.sh",
)


class PatchError(ValueError):
    """Raised when settings cannot be changed safely."""


def home_placeholder() -> str:
    return "${ENGINEERING_OS_HOME:-$(pwd)}"


def registry_path() -> Path:
    """Resolve the canonical registry from this script's own checkout.

    Deliberately not derived from --home or $HOME: the registry that governs a settings
    file must be the one shipped alongside the runtime that will execute those hooks.
    """

    return Path(__file__).resolve().parent.parent.parent / REGISTRY_RELATIVE


def event_argument(event: str) -> str:
    return re.sub(r"(?<!^)(?=[A-Z])", "_", event).lower()


def read_registry(path: Path) -> list[tuple[str, str, str, str, str]]:
    """Return the (event, matcher, unit, class, failure_semantics) rows this patcher owns."""

    if path.is_symlink() or not path.is_file():
        raise PatchError(f"required hook registry is missing or not a regular file: {path}")
    rows: list[tuple[str, str, str, str, str]] = []
    for number, raw in enumerate(path.read_text(encoding="utf-8").splitlines(), 1):
        if not raw.strip() or raw.startswith("#"):
            continue
        parts = raw.split("\t")
        if len(parts) != REGISTRY_COLUMNS:
            raise PatchError(
                f"malformed hook registry row {number}: expected {REGISTRY_COLUMNS} "
                f"columns, got {len(parts)}"
            )
        event, matcher, unit, klass, semantics, wiring, _parent, surface = parts[:8]
        if wiring != "direct" or not unit.startswith(OWNED_UNIT_PREFIX):
            continue
        # Dispatcher rows exist so hook-gate.sh accepts the scope resolver as a canonical
        # hard unit; the wiring itself is rendered from the source rows below.
        if surface == "dispatcher":
            continue
        rows.append((event, matcher, unit, klass, semantics))
    if not rows:
        raise PatchError(f"hook registry declares no telemetry units: {path}")
    return rows


def render_command(
    unit: str, event: str, matcher: str, klass: str, semantics: str, mode: str, home: str
) -> str:
    """Render one settings command, keeping criticality identical across surfaces."""

    if mode == "direct":
        target, argument = unit, "" if unit in ARGLESS_UNITS else event_argument(event)
    elif mode == "dispatcher":
        target = DISPATCH_UNIT
        argument = DISPATCH_SUBCOMMANDS.get(unit, event_argument(event))
    else:
        raise PatchError(f"unknown mode: {mode}")

    unit_path = f"{home}/{target}"
    suffix = f" -- {argument}" if argument else ""
    if semantics == PROPAGATE_FAILURE:
        # Terminal boundaries run unwrapped on purpose. soft-hook-gate.sh always exits 0,
        # so gating these would turn a failed required durable handoff into a session
        # that looks cleanly closed while no bundle was ever produced.
        argv = f" {argument}" if argument else ""
        return f'bash "{unit_path}"{argv}'
    if klass == "hard":
        gate = f"{home}/scripts/enforcement/lib/hook-gate.sh"
        return (
            f'GATE="{gate}"; [ -r "$GATE" ] || {{ echo "ERROR_FOR_AGENT: Engineering OS '
            f'hard-hook wrapper missing: $GATE" >&2; exit 2; }}; bash "$GATE" --event '
            f"{event} --matcher '{matcher}' --unit \"{unit_path}\"{suffix}"
        )
    gate = f"{home}/scripts/enforcement/lib/soft-hook-gate.sh"
    return (
        f'SOFT="{gate}"; if [ -r "$SOFT" ]; then bash "$SOFT" --event {event} --unit '
        f'"{unit_path}"{suffix}; else echo "WARNING_FOR_AGENT: Engineering OS soft-hook '
        f'wrapper missing: $SOFT" >&2; exit 0; fi'
    )


def desired_hooks(
    mode: str,
    home: str | None = None,
) -> list[tuple[str, str | None, str]]:
    """Derive the required hook set from the canonical registry.

    Returns (event, settings_matcher, command) in registry order. A registry matcher of
    "*" means the event carries no matcher in settings, which Claude Code represents as
    an absent key.

    Registry order is the wiring order: within an event the guard row precedes the
    recorder rows it guards, and appending preserves that while leaving any pre-existing
    unowned hook (notably the PreToolUse JSON guard) ahead of everything this patcher
    owns. Prepending here would place the telemetry guard before the JSON guard and
    break the hard-hook contract.
    """

    runtime_home = home or home_placeholder()
    hooks: list[tuple[str, str | None, str]] = []
    for event, matcher, unit, klass, semantics in read_registry(registry_path()):
        command = render_command(unit, event, matcher, klass, semantics, mode, runtime_home)
        hooks.append((event, None if matcher == "*" else matcher, command))
    return hooks


def owned_markers() -> tuple[str, ...]:
    """Ownership markers derived from the registry, so there is one source of truth.

    A new scripts/monitoring/ unit added to the registry is owned automatically. With a
    hardcoded list, such a unit would leave its previous command behind on reinstall and
    then be reported both missing and duplicated.
    """

    try:
        units = {unit for _e, _m, unit, _k, _s in read_registry(registry_path())}
    except PatchError:
        return FALLBACK_MARKERS
    units.add(DISPATCH_UNIT)
    return tuple(sorted({Path(unit).name for unit in units}))


def is_marker_owned(command: str) -> bool:
    return any(marker in command for marker in owned_markers())


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
    entries.append({"type": "command", "command": command})


def apply_install(data: dict[str, Any], mode: str, home: str | None = None) -> bool:
    hooks = data.setdefault("hooks", {})
    if not isinstance(hooks, dict):
        raise PatchError("settings hooks must be a JSON object")
    before = json.dumps(hooks, ensure_ascii=False, sort_keys=True)
    remove_owned_hooks(hooks)
    for event, matcher, command in desired_hooks(mode, home):
        ensure_hook(hooks, event, matcher, command)
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

    try:
        desired = desired_hooks(mode, home)
    except PatchError as exc:
        return [str(exc)]
    problems: list[str] = []
    blocks = Blocks(hooks)
    for event, matcher, command in desired:
        block = blocks.find(event, matcher)
        if block is None:
            problems.append(f"missing hook block for {event}/{matcher}")
            continue
        entries = block.get("hooks")
        entries = entries if isinstance(entries, list) else []
        owned = [
            str(hook.get("command") or "")
            for hook in entries
            if isinstance(hook, dict) and is_marker_owned(str(hook.get("command") or ""))
        ]
        exact = [installed for installed in owned if installed == command]
        if not exact:
            problems.append(
                f"missing required hook for {event}/{matcher}"
                if not owned
                else f"mismatched required hook for {event}/{matcher} (mode={mode})"
            )
            continue
        if len(exact) > 1:
            problems.append(
                f"duplicate required hook for {event}/{matcher}: {len(exact)} entries"
            )

    # Anything owned by this patcher that the registry does not declare is a legacy or
    # unregistered command and must fail rather than linger.
    expected_counts = Counter(command for _e, _m, command in desired)
    actual_counts = Counter(
        command
        for _event, _matcher, _hook, command in iter_hook_commands(hooks)
        if is_marker_owned(command)
    )
    for command, count in sorted((actual_counts - expected_counts).items()):
        problems.append(f"unregistered or legacy owned hook ({count} entries): {command}")
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
