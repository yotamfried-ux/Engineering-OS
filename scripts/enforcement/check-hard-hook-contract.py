#!/usr/bin/env python3
"""Validate the canonical hard-hook chain against Claude Code settings and files."""
from __future__ import annotations

import argparse
import json
import os
import re
import sys
from dataclasses import dataclass
from pathlib import Path
from typing import Iterable, NoReturn

COLUMNS = 10
VALID_CLASSES = {"hard", "advisory", "recorder", "lifecycle"}
VALID_WIRING = {"direct", "nested", "inline"}
VALID_SURFACES = {"both", "source", "installed"}
BLOCKABLE_EVENTS = {"PreToolUse", "Stop"}


@dataclass(frozen=True)
class Row:
    event: str
    matcher: str
    unit: str
    klass: str
    semantics: str
    wiring: str
    parent: str
    surface: str
    requires: tuple[str, ...]
    deny_mode: str
    line: int

    def applies(self, surface: str) -> bool:
        return self.surface in {"both", surface}


def fail(message: str) -> NoReturn:
    raise ValueError(message)


def read_registry(path: Path) -> list[Row]:
    if not path.is_file() or path.is_symlink():
        fail(f"hard-hook registry is missing or not a regular file: {path}")
    rows: list[Row] = []
    for number, raw in enumerate(path.read_text(encoding="utf-8").splitlines(), 1):
        if not raw.strip() or raw.startswith("#"):
            continue
        parts = raw.split("\t")
        if len(parts) != COLUMNS:
            fail(f"malformed hook-criticality row {number}: expected {COLUMNS} columns, got {len(parts)}")
        event, matcher, unit, klass, semantics, wiring, parent, surface, requires_raw, deny_mode = parts
        if klass not in VALID_CLASSES:
            fail(f"row {number}: invalid class {klass!r}")
        if wiring not in VALID_WIRING:
            fail(f"row {number}: invalid wiring {wiring!r}")
        if surface not in VALID_SURFACES:
            fail(f"row {number}: invalid surface {surface!r}")
        if klass == "hard" and semantics != "fail_closed":
            fail(f"row {number}: hard unit must use fail_closed semantics")
        if klass == "advisory" and semantics != "soft_guidance_only":
            fail(f"row {number}: advisory unit must use soft_guidance_only semantics")
        if klass == "recorder" and semantics != "false_evidence_safe":
            fail(f"row {number}: recorder unit must use false_evidence_safe semantics")
        if wiring == "nested" and parent == "-":
            fail(f"row {number}: nested unit requires a parent")
        if wiring != "nested" and parent != "-":
            fail(f"row {number}: only nested units may declare a parent")
        requirements = tuple(v.strip() for v in requires_raw.split(",") if v.strip() and v.strip() != "-")
        rows.append(Row(event, matcher, unit, klass, semantics, wiring, parent, surface, requirements, deny_mode, number))
    if not rows:
        fail("hard-hook registry contains no rows")
    keys: set[tuple[str, str, str, str, str]] = set()
    for row in rows:
        key = (row.event, row.matcher, row.unit, row.wiring, row.surface)
        if key in keys:
            fail(f"duplicate hook-criticality row for {key}")
        keys.add(key)
    return rows


def load_settings(path: Path) -> dict:
    if not path.is_file() or path.is_symlink():
        fail(f"settings file is missing or not a regular file: {path}")
    try:
        data = json.loads(path.read_text(encoding="utf-8"))
    except Exception as exc:
        fail(f"settings JSON is malformed: {exc}")
    if not isinstance(data, dict) or not isinstance(data.get("hooks"), dict):
        fail("settings JSON must contain a hooks object")
    return data


def block_matches(actual: object, expected: str) -> bool:
    if expected == "*":
        return actual in (None, "*")
    return actual == expected


def commands_for(settings: dict, event: str, matcher: str) -> list[tuple[int, str]]:
    blocks = settings["hooks"].get(event)
    if not isinstance(blocks, list):
        return []
    found: list[tuple[int, str]] = []
    for block in blocks:
        if not isinstance(block, dict) or not block_matches(block.get("matcher"), matcher):
            continue
        hooks = block.get("hooks")
        if not isinstance(hooks, list):
            continue
        for hook_index, hook in enumerate(hooks):
            if isinstance(hook, dict) and isinstance(hook.get("command"), str):
                found.append((hook_index, hook["command"]))
    return found


def path_ok(root: Path, rel: str) -> bool:
    root_resolved = root.resolve()
    rel_path = Path(rel)
    if rel_path.is_absolute() or ".." in rel_path.parts:
        return False
    unresolved = root_resolved
    for part in rel_path.parts:
        unresolved /= part
        if unresolved.is_symlink():
            return False
    candidate = unresolved.resolve()
    try:
        candidate.relative_to(root_resolved)
    except ValueError:
        return False
    return candidate.is_file() and os.access(candidate, os.R_OK)


def expected_mode(event: str) -> str:
    if event == "PreToolUse":
        return "pretool_json"
    if event == "Stop":
        return "stop_json"
    return "exit2"


def validate_paths(root: Path, rows: Iterable[Row], surface: str) -> None:
    applicable = [row for row in rows if row.applies(surface)]
    by_unit = {row.unit for row in applicable if row.wiring in {"direct", "nested"}}
    for row in applicable:
        if row.wiring in {"direct", "nested"} and not path_ok(root, row.unit):
            fail(f"row {row.line}: required unit is missing, unreadable, or traverses a symlink: {row.unit}")
        for requirement in row.requires:
            if not path_ok(root, requirement):
                fail(f"row {row.line}: required dependency is missing, unreadable, or traverses a symlink: {requirement}")
        if row.wiring == "nested" and row.parent not in by_unit:
            fail(f"row {row.line}: nested parent is absent from the applicable contract: {row.parent}")

    parent_map: dict[str, list[str]] = {}
    for row in applicable:
        if row.wiring == "nested":
            parent_map.setdefault(row.parent, []).append(row.unit)

    def visit(unit: str, stack: tuple[str, ...]) -> None:
        if unit in stack:
            fail("nested hard-hook cycle: " + " -> ".join((*stack, unit)))
        for child in parent_map.get(unit, []):
            visit(child, (*stack, unit))

    for row in applicable:
        if row.wiring == "direct" and row.klass == "hard":
            visit(row.unit, ())


def validate_hard_wiring(root: Path, settings: dict, rows: list[Row], surface: str) -> None:
    direct_hard = [r for r in rows if r.applies(surface) and r.klass == "hard" and r.wiring == "direct"]
    for row in direct_hard:
        if row.event not in BLOCKABLE_EVENTS:
            fail(f"row {row.line}: hard command event is not blockable by this contract: {row.event}")
        if row.deny_mode != expected_mode(row.event):
            fail(f"row {row.line}: deny mode {row.deny_mode!r} does not match event {row.event}")
        matches = [(idx, cmd) for idx, cmd in commands_for(settings, row.event, row.matcher) if row.unit in cmd]
        if len(matches) != 1:
            fail(
                f"hard settings wiring mismatch for {row.event}/{row.matcher}/{row.unit}: "
                f"expected exactly one command, found {len(matches)}"
            )
        hook_index, command = matches[0]
        if "/lib/hook-gate.sh" not in command or "soft-hook-gate.sh" in command:
            fail(f"hard command does not use hook-gate.sh: {row.unit}")
        if "|| true" in command:
            fail(f"hard command is soft-wrapped: {row.unit}")
        if "exit 2" not in command:
            fail(f"hard command lacks a missing-wrapper exit-2 bootstrap: {row.unit}")
        for token in ("--event", row.event, "--matcher", row.matcher, "--unit"):
            if token not in command:
                fail(f"hard command for {row.unit} lacks exact wrapper token {token!r}")
        if row.event == "PreToolUse":
            block_commands = commands_for(settings, row.event, row.matcher)
            earlier = [cmd for idx, cmd in block_commands if idx <= hook_index]
            if not earlier or "scripts/enforcement/pre-tool-use-json-guard.sh" not in earlier[0]:
                fail(f"hard PreToolUse path {row.matcher}/{row.unit} does not run the JSON guard first")

    registered = {(r.event, r.matcher, r.unit) for r in direct_hard}
    path_re = re.compile(r"(?:\$\{ENGINEERING_OS_HOME[^}]*\}|[^\s\"']+)?/(scripts/(?:enforcement|monitoring)/[A-Za-z0-9_.-]+\.(?:sh|py))")
    for event in BLOCKABLE_EVENTS:
        blocks = settings["hooks"].get(event, [])
        if not isinstance(blocks, list):
            continue
        for block in blocks:
            if not isinstance(block, dict):
                continue
            matcher = block.get("matcher") if block.get("matcher") is not None else "*"
            for hook in block.get("hooks", []):
                command = hook.get("command", "") if isinstance(hook, dict) else ""
                if not isinstance(command, str):
                    continue
                for rel in path_re.findall(command):
                    if rel.endswith("lib/hook-gate.sh") or rel.endswith("lib/soft-hook-gate.sh") or rel.endswith("eos-telemetry-event.sh"):
                        continue
                    if rel.startswith("scripts/monitoring/") and rel != "scripts/monitoring/require-telemetry-session.sh":
                        continue
                    if (event, str(matcher), rel) not in registered:
                        fail(f"blockable settings command is not a registered direct hard unit: {event}/{matcher}/{rel}")


def validate_soft_rows(settings: dict, rows: list[Row], surface: str) -> None:
    for row in rows:
        if not row.applies(surface) or row.wiring != "direct" or row.klass not in {"advisory", "recorder"}:
            continue
        matches = [cmd for _, cmd in commands_for(settings, row.event, row.matcher) if row.unit in cmd]
        if not matches:
            continue
        if any("/lib/hook-gate.sh" in cmd and "soft-hook-gate.sh" not in cmd for cmd in matches):
            fail(f"soft {row.klass} unit must not use the hard hook gate: {row.unit}")


def main(argv: list[str] | None = None) -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--root", default=".")
    parser.add_argument("--settings", default=".claude/settings.json")
    parser.add_argument("--registry", default="scripts/enforcement/hook-criticality.tsv")
    parser.add_argument("--surface", choices=("source", "installed"), default="source")
    args = parser.parse_args(argv)

    root = Path(args.root).resolve()
    settings_path = Path(args.settings)
    if not settings_path.is_absolute():
        settings_path = root / settings_path
    registry_path = Path(args.registry)
    if not registry_path.is_absolute():
        registry_path = root / registry_path

    try:
        rows = read_registry(registry_path)
        settings = load_settings(settings_path)
        validate_paths(root, rows, args.surface)
        validate_hard_wiring(root, settings, rows, args.surface)
        validate_soft_rows(settings, rows, args.surface)
    except ValueError as exc:
        print(f"ERROR: {exc}", file=sys.stderr)
        return 1

    direct = sum(1 for r in rows if r.applies(args.surface) and r.klass == "hard" and r.wiring == "direct")
    nested = sum(1 for r in rows if r.applies(args.surface) and r.klass == "hard" and r.wiring == "nested")
    print(f"hard-hook contract passed: surface={args.surface} direct={direct} nested={nested}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
