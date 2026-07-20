#!/usr/bin/env python3
"""Discover opted-in repositories and attribute hook events without guessing."""
from __future__ import annotations

import json
import subprocess
from pathlib import Path
from typing import Any, Callable

from telemetry_handoff import load_policy, parse_repo_slug_from_remote

MARKER_RELATIVE_PATH = Path(".engineering-os") / "telemetry-policy.json"
_REPOSITORY_SIGNAL_KEYS = (
    "repository_full_name",
    "repo_full_name",
    "repository",
    "owner",
    "org",
    "repo",
    "repository_name",
)
_PATH_SIGNAL_KEYS = ("file_path", "path")


class RepoInfo:
    __slots__ = ("root",)

    def __init__(self, root: Path) -> None:
        self.root = root

    def __eq__(self, other: object) -> bool:
        return isinstance(other, RepoInfo) and self.root == other.root

    def __hash__(self) -> int:
        return hash(self.root)

    def __repr__(self) -> str:
        return f"RepoInfo({self.root})"


def _git_toplevel(path: Path) -> Path | None:
    try:
        output = subprocess.check_output(
            ["git", "-C", str(path), "rev-parse", "--show-toplevel"],
            text=True,
            stderr=subprocess.DEVNULL,
        ).strip()
    except Exception:
        return None
    return Path(output).resolve() if output else None


def _has_valid_marker(repo_root: Path) -> bool:
    marker = repo_root / MARKER_RELATIVE_PATH
    if not marker.is_file():
        return False
    try:
        resolved = marker.resolve(strict=True)
        resolved.relative_to(repo_root)
        load_policy(repo_root, resolved)
    except Exception:
        return False
    return True


def managed_repo_for_root(candidate: Path) -> RepoInfo | None:
    try:
        resolved = candidate.resolve(strict=True)
    except OSError:
        return None
    if not resolved.is_dir():
        return None
    root = _git_toplevel(resolved)
    if root != resolved or not _has_valid_marker(resolved):
        return None
    return RepoInfo(resolved)


def managed_repo_for_cwd(start_cwd: Path) -> RepoInfo | None:
    try:
        resolved = start_cwd.resolve()
    except OSError:
        return None
    root = _git_toplevel(resolved)
    if root is None or not _has_valid_marker(root):
        return None
    return RepoInfo(root)


def _commands_for_event(
    hooks: dict[str, Any],
    event: str,
    *,
    catch_all_only: bool = False,
) -> list[str]:
    blocks = hooks.get(event)
    if not isinstance(blocks, list):
        return []
    commands: list[str] = []
    for block in blocks:
        if not isinstance(block, dict):
            continue
        if catch_all_only and block.get("matcher") not in (None, ".*"):
            continue
        entries = block.get("hooks")
        if not isinstance(entries, list):
            continue
        for entry in entries:
            if isinstance(entry, dict) and isinstance(entry.get("command"), str):
                commands.append(entry["command"])
    return commands


def _has_command(commands: list[str], predicate: Callable[[str], bool]) -> bool:
    return any(predicate(command) for command in commands)


def has_conflicting_project_local_hooks(repo_root: Path) -> bool:
    """Require a complete direct install before suppressing user-level dispatch."""

    settings_path = repo_root / ".claude" / "settings.json"
    if not settings_path.is_file():
        return False
    try:
        settings = json.loads(settings_path.read_text(encoding="utf-8"))
    except Exception:
        return False
    hooks = settings.get("hooks") if isinstance(settings, dict) else None
    if not isinstance(hooks, dict):
        return False

    session = _commands_for_event(hooks, "SessionStart")
    pretool = _commands_for_event(hooks, "PreToolUse", catch_all_only=True)
    if not _has_command(session, lambda command: "eos-telemetry-session-start.sh" in command):
        return False
    if not _has_command(pretool, lambda command: "require-telemetry-session.sh" in command):
        return False
    if not _has_command(
        pretool,
        lambda command: (
            "eos-telemetry-event.sh" in command
            and command.rstrip().endswith(" pre_tool_use")
        ),
    ):
        return False

    for event, suffix in (
        ("Stop", "stop"),
        ("StopFailure", "stop_failure"),
        ("SessionEnd", "session_end"),
    ):
        commands = _commands_for_event(hooks, event)
        if not _has_command(
            commands,
            lambda command, suffix=suffix: (
                "record-and-sync-telemetry.sh" in command
                and command.rstrip().endswith(f" {suffix}")
            ),
        ):
            return False
    return True


def discover_managed_repos(start_cwd: Path) -> list[RepoInfo]:
    try:
        start = start_cwd.resolve()
    except OSError:
        return []
    native = managed_repo_for_cwd(start)
    if native is not None:
        return [native]

    try:
        children = sorted(
            child for child in start.iterdir()
            if child.is_dir() and not child.is_symlink()
        )
    except OSError:
        return []

    found: list[RepoInfo] = []
    seen: set[Path] = set()
    for child in children:
        repo = managed_repo_for_root(child)
        if repo is None or repo.root in seen:
            continue
        seen.add(repo.root)
        found.append(repo)
    found.sort(key=lambda repo: str(repo.root))
    return found


def _resolve_path_field(value: str, event_cwd: Path | None) -> Path | None:
    if not value:
        return None
    path = Path(value)
    if not path.is_absolute():
        if event_cwd is None:
            return None
        path = event_cwd / path
    try:
        return path.resolve(strict=False)
    except OSError:
        return None


def _repo_for_path(path: Path, discovered: list[RepoInfo]) -> RepoInfo | None:
    matches: list[RepoInfo] = []
    for repo in discovered:
        try:
            path.relative_to(repo.root)
        except ValueError:
            continue
        matches.append(repo)
    if not matches:
        return None
    return max(matches, key=lambda repo: len(str(repo.root)))


def _normalize_repo_slug(value: str) -> str | None:
    slug = parse_repo_slug_from_remote(value)
    return slug.casefold() if slug else None


def _repo_remote_slug(repo_root: Path) -> str | None:
    try:
        remote = subprocess.check_output(
            ["git", "-C", str(repo_root), "config", "--get", "remote.origin.url"],
            text=True,
            stderr=subprocess.DEVNULL,
        ).strip()
    except Exception:
        return None
    return _normalize_repo_slug(remote)


def _tool_input(payload: dict[str, Any]) -> dict[str, Any]:
    value = payload.get("tool_input")
    return value if isinstance(value, dict) else {}


def _payload_path_targets(payload: dict[str, Any]) -> tuple[bool, list[str] | None]:
    """Return present path evidence, rejecting non-string or empty values."""

    tool_input = _tool_input(payload)
    present = any(key in tool_input for key in _PATH_SIGNAL_KEYS)
    if not present:
        return False, []
    values: list[str] = []
    for key in _PATH_SIGNAL_KEYS:
        if key not in tool_input:
            continue
        value = tool_input[key]
        if not isinstance(value, str) or not value.strip():
            return True, None
        values.append(value)
    return True, values


def _payload_repo_target(payload: dict[str, Any]) -> tuple[bool, str | None]:
    tool_input = _tool_input(payload)
    present = any(
        key in tool_input and tool_input.get(key) not in (None, "")
        for key in _REPOSITORY_SIGNAL_KEYS
    )
    if not present:
        return False, None

    normalized: list[str] = []
    invalid = False
    for key in ("repository_full_name", "repo_full_name", "repository"):
        if key not in tool_input or tool_input.get(key) in (None, ""):
            continue
        value = tool_input[key]
        slug = _normalize_repo_slug(value) if isinstance(value, str) else None
        if slug is None:
            invalid = True
        else:
            normalized.append(slug)

    owners = [
        tool_input[key]
        for key in ("owner", "org")
        if key in tool_input and tool_input.get(key) not in (None, "")
    ]
    repos = [
        tool_input[key]
        for key in ("repo", "repository_name")
        if key in tool_input and tool_input.get(key) not in (None, "")
    ]
    if owners or repos:
        if not owners or not repos:
            invalid = True
        else:
            for owner in owners:
                for repo in repos:
                    slug = (
                        _normalize_repo_slug(f"{owner}/{repo}")
                        if isinstance(owner, str) and isinstance(repo, str)
                        else None
                    )
                    if slug is None:
                        invalid = True
                    else:
                        normalized.append(slug)

    if invalid or not normalized or len(set(normalized)) != 1:
        return True, None
    return True, normalized[0]


def _repo_for_slug(slug: str, discovered: list[RepoInfo]) -> RepoInfo | None:
    matches = [repo for repo in discovered if _repo_remote_slug(repo.root) == slug]
    return matches[0] if len(matches) == 1 else None


def attribute_event(payload: dict[str, Any], discovered: list[RepoInfo]) -> RepoInfo | None:
    """Reconcile every explicit target before considering cwd or fallback."""

    if not discovered:
        return None
    cwd_raw = payload.get("cwd")
    if cwd_raw not in (None, "") and not isinstance(cwd_raw, str):
        return None
    event_cwd_raw = cwd_raw if isinstance(cwd_raw, str) else ""
    try:
        event_cwd = Path(event_cwd_raw).resolve() if event_cwd_raw else None
    except OSError:
        event_cwd = None

    path_signal, explicit_paths = _payload_path_targets(payload)
    if path_signal and explicit_paths is None:
        return None
    path_target: RepoInfo | None = None
    if explicit_paths:
        matches: list[RepoInfo] = []
        for raw in explicit_paths:
            resolved = _resolve_path_field(raw, event_cwd)
            if resolved is None:
                return None
            repo = _repo_for_path(resolved, discovered)
            if repo is None:
                return None
            matches.append(repo)
        path_target = matches[0]
        if any(repo != path_target for repo in matches[1:]):
            return None

    repo_signal, slug = _payload_repo_target(payload)
    repo_target: RepoInfo | None = None
    if repo_signal:
        if slug is None:
            return None
        repo_target = _repo_for_slug(slug, discovered)
        if repo_target is None:
            return None

    if path_target is not None and repo_target is not None:
        return path_target if path_target == repo_target else None
    if path_target is not None:
        return path_target
    if repo_target is not None:
        return repo_target
    if event_cwd_raw:
        if event_cwd is None:
            return None
        return _repo_for_path(event_cwd, discovered)
    if not path_signal and not repo_signal and len(discovered) == 1:
        return discovered[0]
    return None
