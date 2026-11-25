#!/usr/bin/env python3
"""Install curated third-party agent skills into Claude Code from canonical GitHub sources.

A Git checkout is immutable until explicitly replaced by the owner. Skills are
linked (not copied) into ~/.claude/skills. This does NOT provision SaaS servers,
model weights, paid APIs, secrets, or a usable Claude Code subscription.
"""
from __future__ import annotations

import os
import re
import shutil
import subprocess
from pathlib import Path

HOME = Path.home()
CHECKOUTS = HOME / ".local" / "share" / "engineering-os" / "reel-skills"
CLAUDE_SKILLS = HOME / ".claude" / "skills"


def _repo_url(tool: dict) -> str:
    slug = tool.get("repository", "")
    if not re.fullmatch(r"[A-Za-z0-9_.-]+/[A-Za-z0-9_.-]+", slug):
        raise RuntimeError("Invalid canonical repository slug")
    return "https://github.com/" + slug + ".git"


def _checkout(name: str) -> Path:
    if not re.fullmatch(r"[a-z0-9][a-z0-9-]*", name):
        raise RuntimeError("Invalid capability name")
    return CHECKOUTS / name


def _origin_ok(root: Path, tool: dict) -> bool:
    if not (root / ".git").is_dir():
        return False
    result = subprocess.run(
        ["git", "-C", str(root), "remote", "get-url", "origin"],
        capture_output=True, text=True, check=False
    )
    actual = result.stdout.strip().removesuffix(".git").lower()
    expected = _repo_url(tool).removesuffix(".git").lower()
    return result.returncode == 0 and actual == expected


def _sources(root: Path, tool: dict) -> list[tuple[str, Path]]:
    paths = []
    for pattern in tool.get("skill_globs", []):
        if pattern.startswith("/") or ".." in Path(pattern).parts:
            raise RuntimeError("Unsafe skill glob")
        for source in sorted(root.glob(pattern)):
            if source.is_file() and source.name == "SKILL.md":
                # README is never a skill; only genuine SKILL.md is adopted.
                name = source.parent.name if source.parent != root else tool.get("primary_skill_name")
                if not name or not re.fullmatch(r"[a-z0-9][a-z0-9-]*", name):
                    raise RuntimeError("Invalid or missing skill name")
                paths.append((name, source.parent))
    seen = {}
    for name, directory in paths:
        if name in seen and seen[name] != directory:
            raise RuntimeError(f"Duplicate skill name in source: {name}")
        seen[name] = directory
    if not seen:
        raise RuntimeError("No skills found at expected upstream paths")
    return sorted(seen.items())


def _links_ready(name: str, tool: dict) -> tuple[bool, str]:
    if not shutil.which("claude"):
        return False, "Claude Code CLI not found on this host"
    if not shutil.which("git"):
        return False, "git unavailable"
    for cmd in tool.get("runtime_commands", []):
        if not shutil.which(cmd):
            return False, f"runtime prerequisite missing: {cmd}"
    root = _checkout(name)
    if not root.is_dir() or not _origin_ok(root, tool):
        return False, "canonical source checkout absent or origin mismatch"
    try:
        sources = _sources(root, tool)
    except RuntimeError as exc:
        return False, str(exc)
    for skill, source in sources:
        dest = CLAUDE_SKILLS / skill
        if not dest.is_symlink() or dest.resolve() != source.resolve():
            return False, f"skill link missing or points elsewhere: {skill}"
        if not (dest / "SKILL.md").is_file():
            return False, f"skill file missing: {skill}"
    return True, f"{len(sources)} skill(s) linked to Claude Code; task-level qualification not proven"


def status(name: str, tool: dict) -> dict:
    ready, detail = _links_ready(name, tool)
    return {"ready": ready, "detail": detail}


def ensure(name: str, tool: dict, dry_run: bool = False) -> None:
    ready, detail = _links_ready(name, tool)
    if ready:
        print(f"SKIP   {name}: {detail}")
        return
    if dry_run:
        print(f"CHANGE {name}: clone canonical {_repo_url(tool)} and link skills to {CLAUDE_SKILLS}")
        return
    if not shutil.which("git"):
        raise RuntimeError("git required to install curated skills")
    if not shutil.which("claude"):
        raise RuntimeError("Claude Code CLI required to activate curated skills")
    root = _checkout(name)
    if root.exists() and not _origin_ok(root, tool):
        raise RuntimeError(f"Unsafe existing checkout (origin mismatch): {root}")
    if not root.exists():
        CHECKOUTS.mkdir(parents=True, exist_ok=True)
        partial = CHECKOUTS / (name + ".partial")
        if partial.exists():
            raise RuntimeError(f"Stale partial clone requires manual review: {partial}")
        try:
            subprocess.run(["git", "clone", "--depth", "1", "--", _repo_url(tool), str(partial)],
                           check=True)
            if not _origin_ok(partial, tool):
                raise RuntimeError("Cloned checkout origin not verified")
            partial.rename(root)
        except Exception:
            if partial.exists():
                shutil.rmtree(partial)
            raise
    sources = _sources(root, tool)
    for skill, source in sources:
        dest = CLAUDE_SKILLS / skill
        if dest.exists() or dest.is_symlink():
            if not dest.is_symlink() or dest.resolve() != source.resolve():
                raise RuntimeError(f"Refusing to overwrite pre-existing Claude skill: {dest}")
    CLAUDE_SKILLS.mkdir(parents=True, exist_ok=True)
    for skill, source in sources:
        dest = CLAUDE_SKILLS / skill
        if not dest.is_symlink():
            dest.symlink_to(source, target_is_directory=True)
    ready, detail = _links_ready(name, tool)
    if not ready:
        raise RuntimeError(f"Post-install verification failed: {detail}")
    print(f"READY  {name}: {detail}")
