#!/usr/bin/env python3
"""Resolve which managed repositories a dispatched hook event applies to.

Called by eos-telemetry-dispatch.sh (the user-level hook entry point). Reads
the hook's JSON payload from stdin, reads/creates a per-session discovery
cache under $HOME/.engineering-os/telemetry/dispatch-sessions/, and prints
one absolute repo path per line for the dispatcher to cd into and delegate
to the existing, unmodified per-repo scripts.

Fan-out events (SessionStart, Stop, StopFailure, SessionEnd) print every
discovered managed repo. Per-tool-call events (PreToolUse, PostToolUse,
PostToolUseFailure, PermissionDenied) print at most one repo — the result of
the attribution algorithm — and print nothing (empty output, exit 0) when the
event cannot be safely attributed to a single repo. The caller is
responsible for logging the unattributed diagnostic; this script only
decides "which repo, if any."

The last line of output is always "CORRELATION:<id>" — a host-session
correlation id, stable for the lifetime of the Claude Code session, generated
once and cached. It never replaces any repo's own run_id.
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
)

FANOUT_EVENTS = {"session_start", "stop", "stop_failure", "session_end"}
CACHE_DIR = Path(
    os.environ.get(
        "EOS_DISPATCH_CACHE_DIR",
        str(Path(os.environ.get("EOS_DISPATCH_HOME", str(Path.home()))) / ".engineering-os" / "telemetry" / "dispatch-sessions"),
    )
)


def session_hash(payload: dict[str, Any]) -> str:
    session_id = str(payload.get("session_id") or "")
    if not session_id:
        # No session_id on this payload (should not normally happen per the
        # documented hook schema) — fail safe into a single shared bucket
        # rather than crashing; discovery just re-runs more often.
        return "unknown-session"
    return hashlib.sha256(session_id.encode("utf-8", errors="replace")).hexdigest()[:32]


def cache_path(session_key: str) -> Path:
    return CACHE_DIR / f"{session_key}.json"


def load_cache(session_key: str) -> dict[str, Any] | None:
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
    CACHE_DIR.mkdir(parents=True, exist_ok=True)
    path = cache_path(session_key)
    tmp = path.with_suffix(".tmp")
    payload = {
        "schema_version": "eos.dispatch.session_cache.v1",
        "correlation_id": correlation_id,
        "repos": sorted(str(r.root) for r in repos),
        "updated_at": time.time(),
    }
    tmp.write_text(json.dumps(payload), encoding="utf-8")
    tmp.replace(path)


def ensure_correlation_id(existing: dict[str, Any] | None) -> str:
    if existing and existing.get("correlation_id"):
        return str(existing["correlation_id"])
    return secrets.token_hex(16)


def main() -> int:
    event_name = sys.argv[1] if len(sys.argv) > 1 else "unknown"
    try:
        raw = sys.stdin.read()
    except Exception:
        raw = ""
    try:
        payload = json.loads(raw) if raw.strip() else {}
    except Exception:
        payload = {}
    if not isinstance(payload, dict):
        payload = {}

    key = session_hash(payload)
    cached = load_cache(key)
    correlation_id = ensure_correlation_id(cached)

    event_cwd = str(payload.get("cwd") or os.getcwd())
    is_fanout = event_name in FANOUT_EVENTS
    needs_fresh_discovery = is_fanout and event_name == "session_start"

    if cached is not None and not needs_fresh_discovery:
        discovered = [RepoInfo(Path(p)) for p in cached.get("repos", [])]
    else:
        all_managed = discover_managed_repos(Path(event_cwd))
        # Never dispatch to a repo that already has its own working
        # project-local hook installation — Claude Code merges hooks across
        # scopes rather than overriding, so a session that started inside
        # such a repo would already get that repo's own direct hooks firing;
        # the dispatcher recording the same event too would double-count it.
        # This repo simply isn't the dispatcher's job. See
        # has_conflicting_project_local_hooks() for the full reasoning.
        discovered = []
        for repo in all_managed:
            if has_conflicting_project_local_hooks(repo.root):
                print(f"SKIPPED_SELF_SUFFICIENT:{repo.root}", file=sys.stderr)
                continue
            discovered.append(repo)
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
