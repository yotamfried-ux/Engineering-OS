# Design Spec: Repo Auditor Agent

**Date:** 2026-06-18  
**Status:** Approved  
**Experiment:** #2 — Python Orchestrator + LLM Analyzer + MCP Wrapper  

---

## Problem

No automated way to scan a GitHub repository and get a prioritized report of
what works, what's broken, and what needs improvement. Manual code review is
slow and inconsistent across aspects (security, tests, docs, CI/CD, architecture).

## Solution

An AI agent (`repo-auditor`) that:
1. Fetches repository files via GitHub REST API (no cloning needed)
2. Sends batches to Nemotron Ultra for analysis across 5 aspects
3. Returns a Markdown report structured by CRITICAL / HIGH / MEDIUM / LOW severity
4. Exposes the pipeline as a FastMCP server for cross-session reuse

---

## Architecture

```
CLI: uv run python agent.py owner/repo
MCP: mcp__repo-auditor__audit_repo(repo="owner/repo")
           ↓
       agent.py          — asyncio orchestrator
           ↓
   github_client.py      — GitHub REST API (GITHUB_TOKEN)
           ↓
   analyzers/ (x5)       — parallel, each returns list[Finding]
           ↓
   Nemotron Ultra         — LLM analysis (Nemotron_api_key)
           ↓
   report.py             — Markdown output
```

## Aspects Analyzed

| Aspect | Data fetched | Key checks |
|--------|-------------|------------|
| `code_quality` | Source + test files | Test coverage, complexity, dead code |
| `security` | Source files + deps | OWASP Top 10, hardcoded secrets, CVEs |
| `documentation` | README, docs/, source | README completeness, missing docstrings |
| `cicd` | `.github/workflows/` | CI existence, test/lint/security steps |
| `architecture` | Source files | Circular deps, God objects, mixed concerns |

## Data Model

```python
@dataclass
class Finding:
    severity: Literal["CRITICAL", "HIGH", "MEDIUM", "LOW"]
    aspect: str
    title: str
    location: str   # "path/to/file.py:42" or ""
    description: str
    recommendation: str
```

## MCP Interface

```python
audit_repo(repo: str, aspects: list[str] | None, save_to: str | None) -> str
audit_aspect(repo: str, aspect: str) -> str
list_aspects() -> list[str]
```

## Report Format

```markdown
# 🔍 Repo Audit: `owner/repo`
*Generated: YYYY-MM-DD HH:MM UTC*

## Executive Summary
| Severity | Count |
...

## 🔴 CRITICAL
### [security] Hardcoded API key
**Location:** `src/config.py:43`
...
```

## Security Constraints

- Credentials read from environment only (never hard-coded)
- `.env` files of target repo never forwarded to LLM
- File size cap: 100 KB per file
- Only source files sent to Nemotron — no actual secret values

## Files Created

```
repo-auditor/
├── agent.py              # CLI + orchestrator
├── mcp_server.py         # FastMCP (3 tools)
├── github_client.py      # GitHub REST API
├── report.py             # Markdown generator
├── pyproject.toml        # uv config
└── analyzers/
    ├── __init__.py
    ├── base.py           # Finding + BaseAnalyzer
    ├── code_quality.py
    ├── security.py
    ├── documentation.py
    ├── cicd.py
    └── architecture.py
```

## Definition of Done

- [ ] `uv run python agent.py owner/repo` returns valid Markdown
- [ ] MCP server starts and lists 3 tools
- [ ] All 5 analyzers return findings (even if empty)
- [ ] Report has Executive Summary table
- [ ] Credentials never appear in output
- [ ] `patterns/ai-agents/README.md` updated
