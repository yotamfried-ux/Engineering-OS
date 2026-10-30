# Graphify — Policy

## Classification

| Field | Value |
|---|---|
| Type tags | `context-optimization`, `code-intelligence` |
| Execution level | **Level 1 — situational** for non-trivial codebase navigation |
| Composition role | Optional, reusable context-optimization layer |

## Activation and token budget

Graphify is a **navigation accelerator, not a mandatory per-session startup task**. Use it when the task needs cross-file code understanding or impact analysis, the repository is large/unfamiliar, and the graph exists or is worth building. For a tiny project, known file path, text-only question, or straightforward edit, narrow source reads can be cheaper. Do not run `graphify extract .` or `/graphify .` at every session start by default.

- On a persistent machine, install the CLI and Claude skill **once**. The CLI+skill do not require MCP. Register a per-project MCP only if its graph-query tools are actually useful.
- On a relevant task, use an **existing fresh graph** first. Prefer focused `graphify query`/MCP subgraph queries over printing the entire report or repeatedly reading large files.
- Rebuild or incrementally refresh only when the graph is missing, incompatible, or stale against the task-relevant source changes. If freshness is uncertain, verify with actual source, rather than treating an old graph as ground truth.
- Graphify analysis guides navigation; verify any security, functional, testing or release conclusion against current source and live tests.
- Prefer keyless `--code-only` extraction when appropriate. Semantic extraction of docs/media can call hosted models and consume tokens/credits; enable it only deliberately.
- If a post-commit hook conflicts with repository rules or writes tracked files, choose a safer explicit refresh strategy rather than modifying that repository without authorization.
- Disabling Graphify does not disable the underlying project workflow, security requirements, or tests.

## Qualification

A CLI version check or graph file alone does **not** establish that the installed skill, MCP, and graph correspond to the current project. A representative qualification includes a scoped graph query with source verification; if MCP is used, also test the actual server connection. See [the Claude host setup guide](../../docs/CLAUDE-TOKEN-EFFICIENCY.md) for session and upgrade checks.

## Upstream

https://github.com/Graphify-Labs/graphify
