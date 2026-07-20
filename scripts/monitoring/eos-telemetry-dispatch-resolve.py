#!/usr/bin/env python3
"""Resolve which managed repositories a dispatched hook event applies to.

The resolver reads one Claude hook payload from stdin, maintains a per-session
cache of discovered repositories and a host correlation id, and prints zero or
more repository roots followed by ``CORRELATION:<id>``.
"""
from __future__ import annotations

import hashlib
import json
import os
import secrets
import sys
import time
from pathlib import Path
from typing import Any

sys.path.insert(0, str(Path(__file__).resolve().parent))

from telemetry_repo_discovery import (
    RepoInfo,
    attribute_event,
    discover_managed_repos,
    has_conflicting_project_local_hooks,
    managed_repo_for_cwd,
)

FANOUT_EVENTS = {"session_start", "stop", "stop_failure", "session_end"}
CACHE_DIR = Path(
    os.environ.get(
        "EOS_DISPATCH_CACHE_DIR",
        str(
            Path(os.environ.get("EOS_DISPATCH_HOME", str(Path.home())))
            / ".engineering-os"
            / "telemetry"
            / "dispatch-sessions"
        ),
    )
)
DEFAULT_CACHE_MAX_AGE_SECONDS = 30 * 24 * 60 * 60


def session_hash(payload: dict[str, Any]) -> str:
    """Return a privacy-preserving cache key for one Claude session."""

    session_id = str(payload.get("session_id") or "")
    if not session_id:
        return "unknown-session"
    return hashlib.sha256(session_id.encode("utf-8", errors="replace")).hexdigest()[:32]


def cache_path(session_key: str) -> Path:
    """Return the cache file for session_key."""

    return CACHE_DIR / f"{session_key}.json"


def load_cache(session_key: str) -> dict[str, Any] | None:
    """Load and minimally validate an existing session cache."""

    path = cache_path(session_key)
    if not path.is_file():
        return None
    try:
        data = json.loads(path.read_text(encoding="utf-8"))
    except Exception:
        return None
    if not isinstance(data, dict) or "repos" not in data or "correlation_id" not in data:
        return None
    return data


def write_cache(session_key: str, repos: list[RepoInfo], correlation_id: str) -> None:
    """Atomically persist one session's repository set and correlation id."""

    CACHE_DIR.mkdir(parents=True, exist_ok=True)
    path = cache_path(session_key)
    tmp = path.with_name(f".{path.name}.tmp-{os.getpid()}-{time.time_ns()}")
    payload = {
        "schema_version": "eos.dispatch.session_cache.v2",
        "correlation_id": correlation_id,
        "repos": sorted(str(repo.root) for repo in repos),
        "updated_at": time.time(),
    }
    tmp.write_text(json.dumps(payload), encoding="utf-8")
    tmp.replace(path)


def prune_expired_cache() -> None:
    """Delete stale dispatch-session cache files on SessionStart only."""

    raw_max_age = os.environ.get(
        "EOS_DISPATCH_CACHE_MAX_AGE_SECONDS",
        str(DEFAULT_CACHE_MAX_AGE_SECONDS),
    )
    try:
        max_age = max(0, int(raw_max_age))
    except ValueError:
        max_age = DEFAULT_CACHE_MAX_AGE_SECONDS

    if not CACHE_DIR.is_dir():
        return

    cutoff = time.time() - max_age
    for path in CACHE_DIR.glob("*.json"):
        try:
            if path.stat().st_mtime < cutoff:
                path.unlink()
        except OSError:
            continue


def ensure_correlation_id(existing: dict[str, Any] | None) -> str:
    """Reuse a cached correlation id or generate a new one."""

    if existing and existing.get("correlation_id"):
        return str(existing["correlation_id"])
    return secrets.token_hex(16)


def discovery_for_event(event_name: str, event_cwd: Path) -> list[RepoInfo]:
    """Discover repos and suppress only an actually active native direct install.

    Project-local settings are loaded only for the repository in which an actual
    SessionStart occurs. A sibling repository may have direct hooks on disk but
    those hooks are not active in a parent-started session, so siblings must never
    be removed merely because their settings file exists.
    """

    all_managed = discover_managed_repos(event_cwd)
    if event_name != "session_start":
        return all_managed

    native = managed_repo_for_cwd(event_cwd)
    if native is None or not has_conflicting_project_local_hooks(native.root):
        return all_managed

    return [repo for repo in all_managed if repo.root != native.root]


def main() -> int:
    """Resolve the current event and print repository roots plus correlation."""

    event_name = sys.argv[1] if len(sys.argv) > 1 else "unknown"
    raw = sys.stdin.read()
    try:
        payload = json.loads(raw) if raw.strip() else {}
    except Exception:
        payload = {}
    if not isinstance(payload, dict):
        payload = {}

    key = session_hash(payload)
    cached = load_cache(key)
    correlation_id = ensure_correlation_id(cached)

    event_cwd_raw = str(payload.get("cwd") or os.getcwd())
    event_cwd = Path(event_cwd_raw)
    is_fanout = event_name in FANOUT_EVENTS
    is_session_start = event_name == "session_start"

    if is_session_start:
        prune_expired_cache()

    if cached is not None and not is_session_start:
        discovered = [RepoInfo(Path(path)) for path in cached.get("repos", [])]
    else:
        discovered = discovery_for_event(event_name, event_cwd)
        write_cache(key, discovered, correlation_id)

    if is_fanout:
        for repo in discovered:
            print(str(repo.root))
    else:
        target = attribute_event(payload, discovered)
        if target is not None:
            print(str(target.root))

    print(f"CORRELATION:{correlation_id}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
