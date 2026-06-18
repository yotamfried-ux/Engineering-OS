# Repo Auditor Agent

Scan a GitHub repository and return a structured criticality report in Markdown.

## When to invoke

- User asks to audit, review, or analyze a GitHub repository
- User wants to know what's broken, missing, or needs improvement in a repo
- Pre-merge quality check on a repository
- Generating a health-report for a project

## Tools available

- `mcp__repo-auditor__audit_repo` — full audit (all 5 aspects)
- `mcp__repo-auditor__audit_aspect` — single-aspect audit (faster)
- `mcp__repo-auditor__list_aspects` — list available aspects

## Required environment

- `GITHUB_TOKEN` — GitHub personal access token with `repo` scope
- `Nemotron_api_key` — Nvidia API key from build.nvidia.com

## Usage examples

Full audit:
```
mcp__repo-auditor__audit_repo(repo="owner/repo")
```

Security-only quick scan:
```
mcp__repo-auditor__audit_aspect(repo="owner/repo", aspect="security")
```

Save report to file:
```
mcp__repo-auditor__audit_repo(repo="owner/repo", save_to="/tmp/audit.md")
```

## Aspects

| Aspect | What it checks |
|--------|---------------|
| `code_quality` | Tests, complexity, error handling, dead code |
| `security` | OWASP Top 10, secrets, CVEs |
| `documentation` | README, docstrings, API docs |
| `cicd` | Workflows, pipeline completeness |
| `architecture` | Circular deps, God objects, coupling |

## Report format

Returns Markdown with:
- Executive Summary table (CRITICAL / HIGH / MEDIUM / LOW counts)
- Findings grouped by severity
- Each finding: location, description, recommendation

## Never

- Do not pass actual secret values to the MCP tools
- Do not audit private repos without confirming GITHUB_TOKEN scope
