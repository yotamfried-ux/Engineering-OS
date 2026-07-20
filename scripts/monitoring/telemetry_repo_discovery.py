#!/usr/bin/env python3
"""Discover managed repositories and attribute hook events safely.

This module is used by the user-level telemetry dispatcher. Its responsibility
ends at resolving a hook payload to zero or one managed repository root;
downstream recording, handoff, and PR matching remain in the existing
per-repository telemetry scripts.
"""
from __future__ import annotations

import json
import re
import subprocess
from pathlib import Path
from typing import Any, Callable
from urllib.parse import urlparse

from telemetry_handoff import load_policy

MARKER_RELATIVE_PATH = Path(".engineering-os") / "telemetry-policy.json"
_REPO_COMPONENT_RE = re.compile(r"^[A-Za-z0-9_.-]+$")
_REPOSITORY_SIGNAL_KEYS = (
    "repository_full_name",
    "repo_full_name",
    "repository",
    "owner",
    "org",
    "repo",
    "repository_name",
)


class RepoInfo:
    """Resolved identity for one discovered managed repository."""

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
    """Return the resolved Git root containing path, or None."""

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
    """Return whether repo_root carries a valid, non-escaping policy marker."""

    marker = repo_root / MARKER_RELATIVE_PATH
    if not marker.is_file():
        return False
    try:
        resolved_marker = marker.resolve(strict=True)
        resolved_marker.relative_to(repo_root)
    except (OSError, ValueError):
        return False
    try:
        load_policy(repo_root, resolved_marker)
    except Exception:
        return False
    return True


def managed_repo_for_root(candidate: Path) -> RepoInfo | None:
    """Validate that candidate is still an opted-in Git root."""

    try:
        resolved = candidate.resolve(strict=True)
    except OSError:
        return None
    if not resolved.is_dir():
        return None
    root = _git_toplevel(resolved)
    if root is None or root != resolved or not _has_valid_marker(root):
        return None
    return RepoInfo(root)


def managed_repo_for_cwd(start_cwd: Path) -> RepoInfo | None:
    """Return the managed Git repository containing start_cwd, if any."""

    try:
        resolved_cwd = start_cwd.resolve()
    except OSError:
        return None
    root = _git_toplevel(resolved_cwd)
    if root is None or not _has_valid_marker(root):
        return None
    return RepoInfo(root)


def _commands_for_event(
    hooks: dict[str, Any],
    event: str,
    *,
    catch_all_only: bool = False,
) -> list[str]:
    """Return commands registered for event, optionally only catch-all blocks."""

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
    """Return whether a complete direct project-local installation is active.

    A partial or stale settings file must not suppress the user-level dispatcher:
    doing so would leave the missing guard, recorder, or boundary hooks absent for
    the rest of the session.
    """

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

    session_commands = _commands_for_event(hooks, "SessionStart")
    pre_commands = _commands_for_event(hooks, "PreToolUse", catch_all_only=True)
    boundaries = {
        "Stop": "stop",
        "StopFailure": "stop_failure",
        "SessionEnd": "session_end",
    }

    if not _has_command(
        session_commands,
        lambda command: "eos-telemetry-session-start.sh" in command,
    ):
        return False
    if not _has_command(
        pre_commands,
        lambda command: "require-telemetry-session.sh" in command,
    ):
        return False
    if not _has_command(
        pre_commands,
        lambda command: (
            "eos-telemetry-event.sh" in command
            and command.rstrip().endswith(" pre_tool_use")
        ),
    ):
        return False

    for event, suffix in boundaries.items():
        if not _has_command(
            _commands_for_event(hooks, event),
            lambda command, suffix=suffix: (
                "record-and-sync-telemetry.sh" in command
                and command.rstrip().endswith(f" {suffix}")
            ),
        ):
            return False
    return True


def discover_managed_repos(start_cwd: Path) -> list[RepoInfo]:
    """Discover managed repositories without recursively scanning the host."""

    try:
        start_cwd = start_cwd.resolve()
    except OSError:
        return []

    native = managed_repo_for_cwd(start_cwd)
    if native is not None:
        return [native]

    try:
        children = sorted(
            path for path in start_cwd.iterdir()
            if path.is_dir() and not path.is_symlink()
        )
    except OSError:
        children = []

    found: list[RepoInfo] = []
    seen: set[Path] = set()
    for child in children:
        managed = managed_repo_for_root(child)
        if managed is None or managed.root in seen:
            continue
        seen.add(managed.root)
        found.append(managed)

    found.sort(key=lambda repo: str(repo.root))
    return found


def _resolve_path_field(value: str, event_cwd: Path | None) -> Path | None:
    """Resolve one path-like tool field relative to event_cwd when needed."""

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


def _repo_for_path(resolved_path: Path, discovered: list[RepoInfo]) -> RepoInfo | None:
    """Return the deepest discovered repository containing resolved_path."""

    best: RepoInfo | None = None
    for repo in discovered:
        try:
            resolved_path.relative_to(repo.root)
        except ValueError:
            continue
        if best is None or len(str(repo.root)) > len(str(best.root)):
            best = repo
    return best


def _normalize_repo_slug(value: str) -> str | None:
    """Normalize an exact owner/repo identity or supported Git remote URL."""

    raw = value.strip()
    if not raw:
        return None

    if raw.startswith("git@"):
        if ":" not in raw:
            return None
        raw = raw.split(":", 1)[1]
    elif "://" in raw:
        parsed = urlparse(raw)
        if not parsed.scheme or not parsed.netloc:
            return None
        raw = parsed.path

    raw = raw.strip().strip("/")
    if raw.endswith(".git"):
        raw = raw[:-4]
    parts = [part for part in raw.split("/") if part]
    if len(parts) != 2 or not all(_REPO_COMPONENT_RE.fullmatch(part) for part in parts):
        return None
    return f"{parts[0]}/{parts[1]}".casefold()


def _repo_remote_slug(repo_root: Path) -> str | None:
    """Read and normalize the repository's origin remote slug."""

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


def _payload_repo_target(payload: dict[str, Any]) -> tuple[bool, str | None]:
    """Return whether repository evidence exists and its agreed normalized slug.

    Every present repository identity form is authoritative. A malformed signal,
    incomplete owner/repo pair, or disagreement among forms returns ``(True,
    None)`` so cwd and sole-repository fallback cannot hide the conflict.
    """

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
        value = tool_input.get(key)
        slug = _normalize_repo_slug(value) if isinstance(value, str) else None
        if slug is None:
            invalid = True
        else:
            normalized.append(slug)

    owner_values = [
        tool_input[key]
        for key in ("owner", "org")
        if key in tool_input and tool_input.get(key) not in (None, "")
    ]
    repo_values = [
        tool_input[key]
        for key in ("repo", "repository_name")
        if key in tool_input and tool_input.get(key) not in (None, "")
    ]
    if owner_values or repo_values:
        if not owner_values or not repo_values:
            invalid = True
        else:
            for owner in owner_values:
                for repo in repo_values:
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
    matches = [
        repo for repo in discovered
        if _repo_remote_slug(repo.root) == slug
    ]
    return matches[0] if len(matches) == 1 else None


def attribute_event(payload: dict[str, Any], discovered: list[RepoInfo]) -> RepoInfo | None:
    """Attribute one hook event without guessing.

    Explicit filesystem and repository targets are authoritative and must agree.
    Cwd is considered only when no explicit target exists. A sole-repository
    fallback is allowed only when the payload contains no routing signal.
    """

    if not discovered:
        return None

    event_cwd_raw = str(payload.get("cwd") or "")
    try:
        event_cwd = Path(event_cwd_raw).resolve() if event_cwd_raw else None
    except OSError:
        event_cwd = None

    tool_input = _tool_input(payload)

    # Only actual path fields are filesystem targets. Grep/Glob search patterns
    # are expressions, not paths; their optional `path` field carries location.
    explicit_paths = [
        str(tool_input[key])
        for key in ("file_path", "path")
        if tool_input.get(key)
    ]
    path_target: RepoInfo | None = None
    if explicit_paths:
        matched: list[RepoInfo] = []
        for raw in explicit_paths:
            resolved = _resolve_path_field(raw, event_cwd)
            if resolved is None:
                return None
            repo = _repo_for_path(resolved, discovered)
            if repo is None:
                return None
            matched.append(repo)
        path_target = matched[0]
        if not all(repo == path_target for repo in matched):
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

    if len(discovered) == 1:
        return discovered[0]

    return None
