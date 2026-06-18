# AI Agents — Patterns

Patterns for building AI agents: multi-agent orchestration, tool-calling loops,
and the "Python Orchestrator + LLM Analyzer + MCP Wrapper" architecture.

---

## Pattern: Python Orchestrator + LLM Analyzer + MCP Wrapper

**Status:** Active | **Reference implementation:** [`repo-auditor/`](../../repo-auditor/)

### When to use

When you need an agent that:
1. Fetches data from an external source (GitHub, DB, API)
2. Sends batches of data to an LLM for analysis
3. Aggregates structured findings
4. Exposes the whole pipeline as an MCP tool for use from other Claude sessions

### Architecture

```
CLI / MCP call
      ↓
  agent.py      ← orchestrator (Python asyncio)
      ↓
  github_client / external_client  ← data fetcher
      ↓
  analyzers/    ← domain-specific analysis modules
      ↓
  LLM API (Nemotron / Claude)  ← analysis engine
      ↓
  report.py     ← structured output
      ↓
  mcp_server.py ← FastMCP wrapper (exposes tools)
```

### Key design principles

**Separation of concerns:**
- `agent.py` — orchestrates but does not analyze
- `analyzers/*.py` — each owns one domain, same interface (`async analyze(repo) → list[Finding]`)
- `github_client.py` — all I/O isolated here (swap GitHub for GitLab without touching analyzers)
- `mcp_server.py` — thin wrapper, no business logic

**Contract-first analyzers:**

Every analyzer implements the same interface:
```python
class BaseAnalyzer:
    aspect: str
    aspect_instructions: str

    async def analyze(self, repo: str) -> list[Finding]: ...
    async def _call_nemotron(self, files: dict[str, str]) -> list[Finding]: ...
```

Adding a new analyzer = one new file in `analyzers/`, zero changes elsewhere.

**MCP dual-registration:**

```json
{
  "mcpServers": {
    "repo-auditor": {
      "command": "uv",
      "args": ["run", "repo-auditor/mcp_server.py"]
    }
  }
}
```

The same agent is both:
- CLI: `uv run python agent.py owner/repo`
- MCP tool: `mcp__repo-auditor__audit_repo(repo="owner/repo")`

**Inline script dependencies (`# /// script`):**

`mcp_server.py` uses PEP 723 inline dependencies so it can be invoked as
`uv run repo-auditor/mcp_server.py` from the project root without a separate install step.

**Smart file sampling:**

For large repos, the client applies `_smart_sample()` — prioritizes entrypoints
and shallow files over deep nested utilities. Prevents context overflow without
losing the most important signals.

**Parallel analyzers:**

```python
results = await asyncio.gather(*[analyzer.analyze(repo) for analyzer in analyzers])
```

All 5 aspects run concurrently. Total latency ≈ slowest single analyzer, not the sum.

**Graceful degradation:**

If Nemotron fails, analyzers return a single HIGH finding with the error rather
than crashing. The report always completes.

### Finding schema

```python
@dataclass
class Finding:
    severity: Literal["CRITICAL", "HIGH", "MEDIUM", "LOW"]
    aspect: str       # which analyzer produced this
    title: str
    location: str     # "path/to/file.py:42" or ""
    description: str
    recommendation: str
```

### Security constraints

- `GITHUB_TOKEN` and `Nemotron_api_key` read from environment only — never hard-coded
- `.env` files of the target repo are never forwarded to the LLM
- File size cap: files >100 KB are skipped
- Token budget: ~3000 chars per file to stay within 128K context

### Extending the pattern

To add a new aspect (e.g. `performance`):
1. Create `analyzers/performance.py` extending `BaseAnalyzer`
2. Set `aspect = "performance"` and `aspect_instructions = "..."`
3. Implement `async def analyze(self, repo: str) -> list[Finding]`
4. Add to `_ANALYZER_MAP` in `agent.py`

Zero other changes required.

---

## Related patterns

- [`patterns/ai/README.md`](../ai/README.md) — foundational LLM patterns (prompt chaining, tool use, streaming)
- [`external-skills/nemotron/`](../../external-skills/nemotron/) — Nemotron MCP server integration
- [`external-systems/mcp-sdk/`](../../external-systems/mcp-sdk/) — MCP server SDK reference
