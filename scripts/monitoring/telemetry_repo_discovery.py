#!/usr/bin/env python3
"""Repository discovery and per-event attribution for multi-repo Claude Code
sessions (user-level telemetry dispatch).

Used by eos-telemetry-dispatch.sh. Kept separate from telemetry_handoff.py
(which owns the push/handoff/PR-matching pipeline, unmodified by this module)
because this module's job ends once it has resolved "which repository root,
if any" — everything downstream reuses the existing per-repo scripts.
"""
from __future__ import annotations

import json
import os
import subprocess
from pathlib import Path
from typing import Any

from telemetry_handoff import HandoffError, load_policy

MARKER_RELATIVE_PATH = Path(".engineering-os") / "telemetry-policy.json"


class RepoInfo:
    __slots__ = ("root",)

    def __init__(self, root: Path) -> None:
        self.root = root

    def __eq__(self, other: object) -> bool:
        return isinstance(other, RepoInfo) and self.root == other.root

    def __hash__(self) -> int:
        return hash(self.root)

    def __repr__(self) -> str:  # pragma: no cover - debugging aid only
        return f"RepoInfo({self.root})"


def _git_toplevel(path: Path) -> Path | None:
    try:
        out = subprocess.check_output(
            ["git", "-C", str(path), "rev-parse", "--show-toplevel"],
            text=True,
            stderr=subprocess.DEVNULL,
        ).strip()
    except Exception:
        return None
    if not out:
        return None
    return Path(out).resolve()


def _has_valid_marker(repo_root: Path) -> bool:
    """A repo is "managed" only if its own marker is a real (non-symlink,
    non-escaping) regular file under its own resolved root and parses as a
    valid telemetry policy per the schema telemetry_handoff.py already
    enforces. Reuses load_policy() rather than re-deriving schema rules."""
    marker = repo_root / MARKER_RELATIVE_PATH
    if not marker.is_file():
        return False
    try:
        resolved_marker = marker.resolve(strict=True)
    except OSError:
        return False
    # Reject a marker whose real target escapes the repo's own resolved tree
    # (symlink pointing outside repo_root) — prefix-check on resolved paths.
    try:
        resolved_marker.relative_to(repo_root)
    except ValueError:
        return False
    try:
        load_policy(repo_root, resolved_marker)
    except HandoffError:
        return False
    except Exception:
        return False
    return True


def discover_managed_repos(start_cwd: Path) -> list[RepoInfo]:
    """Discovery algorithm (Route Plan: remote-multirepo-telemetry-hooks.md):

    1. If start_cwd itself resolves to a git repo root with a valid marker,
       that is the only repo — no further scan.
    2. Otherwise, list *immediate* child directories of start_cwd only (never
       recursive) and keep the ones that are themselves git repo roots with a
       valid marker.

    Results are deduplicated by resolved real path and sorted deterministically.
    """
    start_cwd = start_cwd.resolve()
    found: list[RepoInfo] = []

    own_root = _git_toplevel(start_cwd)
    if own_root is not None and _has_valid_marker(own_root):
        return [RepoInfo(own_root)]

    try:
        children = sorted(p for p in start_cwd.iterdir() if p.is_dir() and not p.is_symlink())
    except OSError:
        children = []

    seen: set[Path] = set()
    for child in children:
        child_root = _git_toplevel(child)
        if child_root is None or child_root != child.resolve():
            # Only treat the child itself as a candidate root — a child that
            # merely lives *inside* some deeper/unrelated repo is not a
            # sibling repo by this algorithm's one-level contract.
            continue
        if not _has_valid_marker(child_root):
            continue
        if child_root in seen:
            continue
        seen.add(child_root)
        found.append(RepoInfo(child_root))

    found.sort(key=lambda r: str(r.root))
    return found


def _resolve_path_field(value: str, event_cwd: Path | None) -> Path | None:
    if not value:
        return None
    p = Path(value)
    if not p.is_absolute():
        if event_cwd is None:
            return None
        p = event_cwd / p
    try:
        return p.resolve(strict=False)
    except OSError:
        return None


def _repo_for_path(resolved_path: Path, discovered: list[RepoInfo]) -> RepoInfo | None:
    best: RepoInfo | None = None
    for repo in discovered:
        try:
            resolved_path.relative_to(repo.root)
        except ValueError:
            continue
        if best is None or len(str(repo.root)) > len(str(best.root)):
            best = repo
    return best


def attribute_event(payload: dict[str, Any], discovered: list[RepoInfo]) -> RepoInfo | None:
    """Per-event attribution algorithm, in strength order. Returns None
    (unattributed) rather than guessing when no tier resolves a single,
    provable repository — never falls back to "the last repo seen"."""
    if not discovered:
        return None

    event_cwd_raw = str(payload.get("cwd") or "")
    event_cwd = Path(event_cwd_raw).resolve() if event_cwd_raw else None

    tool_input = payload.get("tool_input") if isinstance(payload.get("tool_input"), dict) else {}

    # Tier 1: explicit file path from tool input.
    for key in ("file_path", "path", "pattern"):
        raw = tool_input.get(key) if isinstance(tool_input, dict) else None
        if not raw:
            continue
        resolved = _resolve_path_field(str(raw), event_cwd)
        if resolved is None:
            continue
        repo = _repo_for_path(resolved, discovered)
        if repo is not None:
            return repo

    # Tier 2: explicit tool/command working directory (top-level cwd field).
    if event_cwd is not None:
        repo = _repo_for_path(event_cwd, discovered)
        if repo is not None:
            return repo

    # Tier 3: single unambiguous discovered repo, only when tiers 1-2 gave no
    # in-repo signal at all (e.g. a tool with no path-like input).
    if len(discovered) == 1:
        return discovered[0]

    # Tier 4 (MCP/GitHub explicit repo identifier) is handled by the caller
    # before invoking this function, since it needs repo-slug comparison
    # against each discovered repo's own git remote — this module only knows
    # filesystem paths.

    return None
