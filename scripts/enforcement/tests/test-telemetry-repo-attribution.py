#!/usr/bin/env python3
"""Focused regression tests for explicit telemetry attribution evidence."""
from __future__ import annotations

import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[3]
sys.path.insert(0, str(ROOT / "scripts" / "monitoring"))

import telemetry_repo_discovery as discovery


def main() -> int:
    repo_a = discovery.RepoInfo(Path("/workspace/repo-a"))
    repo_b = discovery.RepoInfo(Path("/workspace/repo-b"))
    repos = [repo_a, repo_b]

    original_remote_slug = discovery._repo_remote_slug
    discovery._repo_remote_slug = lambda root: {
        repo_a.root: "example/repo-a",
        repo_b.root: "example/repo-b",
    }.get(root)
    try:
        grep_payload = {
            "cwd": "/workspace",
            "tool_name": "Grep",
            "tool_input": {"pattern": "TODO", "path": "/workspace/repo-a"},
        }
        assert discovery.attribute_event(grep_payload, repos) == repo_a

        agreeing_payload = {
            "cwd": "/workspace/repo-b",
            "tool_input": {
                "file_path": "/workspace/repo-a/README.md",
                "repository_full_name": "example/repo-a",
            },
        }
        assert discovery.attribute_event(agreeing_payload, repos) == repo_a

        conflicting_payload = {
            "cwd": "/workspace/repo-a",
            "tool_input": {
                "file_path": "/workspace/repo-a/README.md",
                "repository_full_name": "example/repo-b",
            },
        }
        assert discovery.attribute_event(conflicting_payload, repos) is None

        malformed_repo_payload = {
            "cwd": "/workspace/repo-a",
            "tool_input": {"repository_full_name": "invalid"},
        }
        assert discovery.attribute_event(malformed_repo_payload, repos) is None

        outside_path_payload = {
            "cwd": "/workspace/repo-a",
            "tool_input": {"file_path": "/workspace/unmanaged/file.txt"},
        }
        assert discovery.attribute_event(outside_path_payload, repos) is None
    finally:
        discovery._repo_remote_slug = original_remote_slug

    print("telemetry repository attribution regressions passed")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
