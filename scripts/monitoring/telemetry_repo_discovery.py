#!/usr/bin/env python3
"""Discover managed repositories and attribute hook events safely.

This module is used by the user-level telemetry dispatcher. Its responsibility
ends at resolving a hook payload to zero or one managed repository root;
downstream recording, handoff, and PR matching remain in the existing
per-repository telemetry scripts.
"""
from __future__ import annotations

import subprocess
from pathlib import Path
from typing import Any
from urllib.parse import urlparse

from telemetry_handoff import load_policy

MARKER_RELATIVE_PATH = Path(".engineering-os") / "telemetry-policy.json"

_OWNED_HOOK_MARKERS = (
    "require-telemetry-session.sh",
    "eos-telemetry-session-start.sh",
    "eos-telemetry-event.sh",
    "record-and-sync-telemetry.sh",
    "eos-telemetry-dispatch.sh",
)
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


def has_conflicting_project_local_hooks(repo_root: Path) -> bool:
    """Return whether repo_root has direct Engineering-OS hooks on disk.

    Presence alone does not prove those hooks are active in the current session.
    The resolver uses this result only for the native repository of an actual
    SessionStart event.
    """

    settings_path = repo_root / ".claude" / "settings.json"
    if not settings_path.is_file():
        return False
    try:
        text = settings_path.read_text(encoding="utf-8")
    except OSError:
        return False
    return any(marker in text for marker in _OWNED_HOOK_MARKERS)


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
        child_root = _git_toplevel(child)
        if child_root is None or child_root != child.resolve():
            continue
        if not _has_valid_marker(child_root) or child_root in seen:
            continue
        seen.add(child_root)
        found.append(RepoInfo(child_root))

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
    """Normalize a Git remote or explicit repository value to owner/repo."""

    raw = value.strip()
    if not raw:
        return None

    if raw.startswith("git@") and ":" in raw:
        raw = raw.split(":", 1)[1]
    elif "://" in raw:
        parsed = urlparse(raw)
        raw = parsed.path

    raw = raw.strip().strip("/")
    if raw.endswith(".git"):
        raw = raw[:-4]
    parts = [part for part in raw.split("/") if part]
    if len(parts) < 2:
        return None
    return f"{parts[-2]}/{parts[-1]}".casefold()


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
    """Return whether a repo signal exists and its normalized slug.

    A present but malformed signal returns ``(True, None)`` so cwd cannot hide
    the invalid explicit target.
    """

    tool_input = _tool_input(payload)
    present = any(
        key in tool_input and tool_input.get(key) not in (None, "")
        for key in _REPOSITORY_SIGNAL_KEYS
    )
    if not present:
        return False, None

    for key in ("repository_full_name", "repo_full_name"):
        value = tool_input.get(key)
        if isinstance(value, str):
            normalized = _normalize_repo_slug(value)
            if normalized:
                return True, normalized
            return True, None

    owner = tool_input.get("owner") or tool_input.get("org")
    repo = tool_input.get("repo") or tool_input.get("repository_name")
    if owner is not None or repo is not None:
        if isinstance(owner, str) and isinstance(repo, str):
            return True, _normalize_repo_slug(f"{owner}/{repo}")
        return True, None

    repository = tool_input.get("repository")
    if isinstance(repository, str):
        return True, _normalize_repo_slug(repository)
    return True, None


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
