#!/usr/bin/env python3
"""Repo Auditor — AI agent that scans GitHub repos and returns criticality reports."""
from __future__ import annotations

import asyncio
import os
import sys

from analyzers.architecture import ArchitectureAnalyzer
from analyzers.base import Finding
from analyzers.cicd import CICDAnalyzer
from analyzers.code_quality import CodeQualityAnalyzer
from analyzers.documentation import DocumentationAnalyzer
from analyzers.security import SecurityAnalyzer
from github_client import GitHubClient
from report import build_report

ALL_ASPECTS = ["code_quality", "security", "documentation", "cicd", "architecture"]

_ANALYZER_MAP = {
    "code_quality": CodeQualityAnalyzer,
    "security": SecurityAnalyzer,
    "documentation": DocumentationAnalyzer,
    "cicd": CICDAnalyzer,
    "architecture": ArchitectureAnalyzer,
}


async def audit_repo(
    repo: str,
    aspects: list[str] | None = None,
    github_token: str | None = None,
    nemotron_key: str | None = None,
) -> str:
    token = github_token or os.environ.get("GITHUB_TOKEN", "")
    nkey = nemotron_key or os.environ.get("Nemotron_api_key", "")

    if not token:
        raise ValueError("GITHUB_TOKEN not set. Export it or pass github_token=.")
    if not nkey:
        raise ValueError("Nemotron_api_key not set. Add it to Claude Code secrets.")

    # Normalize GitHub URL → owner/repo
    if repo.startswith("https://github.com/"):
        repo = repo.removeprefix("https://github.com/").rstrip("/")

    selected = [a for a in (aspects or ALL_ASPECTS) if a in _ANALYZER_MAP]
    if not selected:
        raise ValueError(f"No valid aspects. Choose from: {ALL_ASPECTS}")

    github = GitHubClient(token)
    tasks = [_ANALYZER_MAP[asp](github, nkey).analyze(repo) for asp in selected]
    results = await asyncio.gather(*tasks, return_exceptions=True)

    all_findings: list[Finding] = []
    for asp, result in zip(selected, results):
        if isinstance(result, Exception):
            all_findings.append(Finding(
                severity="HIGH",
                aspect=asp,
                title=f"Analyzer error: {asp}",
                location="",
                description=str(result),
                recommendation="Check GITHUB_TOKEN scope and Nemotron_api_key validity.",
            ))
        else:
            all_findings.extend(result)  # type: ignore[arg-type]

    return build_report(repo, all_findings)


def main() -> None:
    if len(sys.argv) < 2:
        print("Usage: python agent.py owner/repo [aspect1 aspect2 ...]")
        print(f"Aspects: {ALL_ASPECTS}")
        sys.exit(1)

    repo = sys.argv[1]
    aspects = sys.argv[2:] or None
    print(asyncio.run(audit_repo(repo, aspects)))


if __name__ == "__main__":
    main()
