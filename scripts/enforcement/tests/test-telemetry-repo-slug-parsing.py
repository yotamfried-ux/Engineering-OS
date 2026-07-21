#!/usr/bin/env python3
"""Regression tests for git-remote-URL -> owner/repo slug extraction."""
from __future__ import annotations

import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[3]
sys.path.insert(0, str(ROOT / "scripts" / "monitoring"))

import telemetry_handoff as handoff
import telemetry_repo_discovery as discovery


def main() -> int:
    url_cases = [
        ("https://github.com/owner/repo.git", "owner/repo"),
        ("https://github.com/owner/repo", "owner/repo"),
        ("https://github.com/owner/repo/", "owner/repo"),
        ("git@github.com:owner/repo.git", "owner/repo"),
        ("github.com:owner/repo.git", "owner/repo"),  # scp-style, no user@
        ("alice@github.com:owner/repo.git", "owner/repo"),  # scp-style, non-git user
        ("ssh://git@github.com/owner/repo.git", "owner/repo"),
        (
            "http://local_proxy@127.0.0.1:41729/git/yotamfried-ux/Engineering-OS",
            "yotamfried-ux/Engineering-OS",
        ),
        ("https://gitlab.com/group/subgroup/repo.git", "subgroup/repo"),
    ]
    for raw, expected in url_cases:
        got = handoff.parse_repo_slug_from_remote(raw)
        assert got == expected, f"{raw!r}: expected {expected!r}, got {got!r}"
        got_discovery = discovery._normalize_repo_slug(raw)
        assert got_discovery == expected.casefold(), (
            f"{raw!r}: expected {expected.casefold()!r}, got {got_discovery!r}"
        )

    # Case must be preserved by the shared helper (downstream `gh` calls are
    # case-sensitive), but casefolded by telemetry_repo_discovery's wrapper.
    mixed_case = "https://github.com/Owner/Repo.git"
    assert handoff.parse_repo_slug_from_remote(mixed_case) == "Owner/Repo"
    assert discovery._normalize_repo_slug(mixed_case) == "owner/repo"

    invalid_cases = [
        "",
        "   ",
        "git@invalid",
        "git@host:onlyonepart",
        "not a url at all",
        "https://",
        "https://github.com",
        "other/example/repo-a",  # bare 3-component slug must stay rejected
    ]
    for raw in invalid_cases:
        assert handoff.parse_repo_slug_from_remote(raw) is None, raw
        assert discovery._normalize_repo_slug(raw) is None, raw

    # Bare 2-component slugs (not URLs) must still work.
    assert handoff.parse_repo_slug_from_remote("owner/repo") == "owner/repo"
    assert discovery._normalize_repo_slug("owner/repo") == "owner/repo"
    assert discovery._normalize_repo_slug("Owner/Repo") == "owner/repo"

    print("telemetry repo slug parsing regressions passed")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
