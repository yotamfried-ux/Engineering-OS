# /// script
# requires-python = ">=3.10"
# dependencies = ["mcp[cli]>=1.0", "httpx>=0.27", "pydantic>=2.0"]
# ///
"""Repo Auditor MCP Server — exposes audit_repo, audit_aspect, list_aspects as MCP tools."""
from __future__ import annotations

import sys
from pathlib import Path

# Ensure the repo-auditor package directory is importable regardless of CWD
sys.path.insert(0, str(Path(__file__).parent))

from mcp.server.fastmcp import FastMCP

from agent import ALL_ASPECTS, audit_repo as _audit_repo

mcp = FastMCP("repo-auditor")


@mcp.tool()
async def audit_repo(
    repo: str,
    aspects: list[str] | None = None,
    save_to: str | None = None,
) -> str:
    """Scan a GitHub repository and return a Markdown criticality report.

    Args:
        repo: Repository slug "owner/repo" or full GitHub URL.
        aspects: Aspects to analyze. Omit to run all five.
                 Valid values: code_quality, security, documentation, cicd, architecture
        save_to: Optional absolute file path to save the Markdown report.

    Returns:
        Markdown report grouped by CRITICAL / HIGH / MEDIUM / LOW severity with
        an Executive Summary table at the top.
    """
    result = await _audit_repo(repo, aspects)
    if save_to:
        Path(save_to).write_text(result, encoding="utf-8")
    return result


@mcp.tool()
async def audit_aspect(repo: str, aspect: str) -> str:
    """Scan a single aspect of a GitHub repository.

    Args:
        repo: Repository slug "owner/repo" or full GitHub URL.
        aspect: One of: code_quality, security, documentation, cicd, architecture

    Returns:
        Markdown report for the specified aspect only.
    """
    return await _audit_repo(repo, aspects=[aspect])


@mcp.tool()
def list_aspects() -> list[str]:
    """List all available analysis aspects for repo auditing.

    Returns:
        List of aspect names accepted by audit_repo and audit_aspect.
    """
    return ALL_ASPECTS


if __name__ == "__main__":
    mcp.run()
